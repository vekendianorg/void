--[[
  modules/ops/vehicle.lua — Vehicle feature memory ops (no UI)
  Contract: see modules/ops/README.md.

  Public ops are ordered to mirror the Vehicle tab: parts_slot, parts_modifier,
  fuel, unlock_vehicles, max_vehicles, max_mastery, max_parts, then the tuning
  parts editors (tuning_equipped / tuning_presets cards). max_parts,
  max_vehicles and the editors are Nebula-powered (PlayerInfo dotted paths),
  the rest stay raw for now.

  Several ops loop over every vehicle and report progress; those accept an
  optional `onProgress(i, total)` UI reporter so core stays UI-free.

  Globals used: scheduler, storage, gg, cast, aobs, json, loadModule,
  readString, BaseRegion, BaseGameStatus, BaseLib, offsets, LOG.
]]

-- ── Tuning-parts config (decoded once, shared) ───────────────────────────────

local _tuningData
local function tuningData()
    if _tuningData ~= nil then return _tuningData or nil end
    local ok, data = pcall(function() return json.decode(loadModule("configs/content/tuning_parts.lua")) end)
    if not ok or type(data) ~= "table" then
        LOG.warn("Vehicle", "tuning_parts.lua failed to decode")
        _tuningData = false
        return nil
    end
    _tuningData = data
    return data
end

local M = {}

-- ── Internal helpers (vehicle-list resolution, zero-region scan) ─────────────

local function findZeroRegion(size)
    local ranges = gg.getRangesList()
    for _, region in ipairs(ranges) do
        -- Own re-implementation of a "find scratch memory" scan — it never
        -- had alloc.lua's stack/heap/bss/data safety filter, so it could
        -- (and would) happily hand back a live thread stack/TLS region
        -- (or .bss/[heap]/etc.) that just happened to read zero at that
        -- instant. Reuse the shared, hardened check instead of trusting
        -- state=="A" alone.
        if region.state == "A" and not alloc.isDangerous(region) then
            local reads = {}
            for addr = region.start, region.start + size * 4, 4 do
                table.insert(reads, { address = addr, flags = 4 })
            end

            local values = gg.getValues(reads)
            if values then
                local allZero = true
                for _, v in ipairs(values) do
                    if v.value ~= 0 then
                        allZero = false
                        break
                    end
                end

                if allZero then
                    return region.start, region.start + size * 4
                end
            end
        end
    end
    return nil, nil
end

local function resolveVehicleList()
    local cached = storage:load_session("vehicle_list_deep")
    if cached and #cached > 0 then
        local check = gg.getValues({{ address = cached[1].deepPtrAddr, flags = 32 }})
        if check and check[1] and check[1].value ~= 0 then
            LOG.dbg("VehicleList", "Cache hit: " .. tostring(#cached) .. " vehicles")
            return cached
        else
            LOG.warn("VehicleList", "Cache stale — re-resolving")
            storage:delete_session("vehicle_list_deep")
        end
    end

    -- Anchor
    gg.clearResults()
    gg.setRanges(BaseRegion)
    gg.searchNumber("h 18 48 49 4C 4C 20 43 4C 49 4D 42 45", 1)
    gg.refineNumber("h 18", 1)
    local anchorResults = gg.getResults(gg.getResultsCount())
    gg.clearResults()

    if #anchorResults == 0 then
        LOG.warn("VehicleList", "Anchor search returned 0 results.")
        return nil
    end

    local anchor = anchorResults[1]

    -- Pattern check + ref search on all anchors
    local refResults
    local bestCount = 0

    for anchorIdx, anchor in ipairs(anchorResults) do
        local pattern = gg.getValues({
            { address = anchor.address - 0x20, flags = 4 },
            { address = anchor.address - 0x8,  flags = 4 }
        })
    
        if pattern and pattern[1] and pattern[2]
            and pattern[1].value == 0x65656A08
            and pattern[2].value == 0x403147AE then
    
            gg.clearResults()
            gg.searchNumber(pattern[1].address, 32)
            gg.setVisible(false)
    
            local tempResults = gg.getResults(gg.getResultsCount())
            gg.clearResults()
    
            if tempResults and #tempResults > bestCount then
                bestCount = #tempResults
                refResults = tempResults
            end
        else
            LOG.dbg("VehicleList", string.format("anchor[%d] pattern mismatch", anchorIdx))
        end
    end
    
    if not refResults or #refResults == 0 then
        LOG.warn("VehicleList", "No refs found.")
        return nil
    end
    
    -- Collect raw vehiclePtrs — sequential (unavoidable, unknown count per ref)
    local written = {}
    local rawPtrs = {}

    for refIdx, ref in ipairs(refResults) do
        local vehicleIdx = 0
        while true do
            local ptrRead = gg.getValues({{
                address = ref.address + vehicleIdx * 8,
                flags   = 32
            }})

            if not ptrRead or not ptrRead[1] or ptrRead[1].value == 0 then
                LOG.dbg("VehicleList", string.format("ref[%d] vehicleIdx[%d] stop", refIdx, vehicleIdx))
                break
            end

            local vehiclePtr = ptrRead[1].value
            if not written[vehiclePtr] then
                written[vehiclePtr] = true
                table.insert(rawPtrs, vehiclePtr)
            end

            vehicleIdx = vehicleIdx + 1
        end
    end

    if #rawPtrs == 0 then
        LOG.warn("VehicleList", "No raw ptrs collected.")
        return nil
    end

    -- Batch read all deepPtrs — 1 getValues
    local deepReads = {}
    for _, vehiclePtr in ipairs(rawPtrs) do
        table.insert(deepReads, { address = vehiclePtr + 0x530, flags = 32 })
    end
    local deepPtrs = gg.getValues(deepReads)

    if not deepPtrs then
        LOG.warn("VehicleList", "deepPtrs batch read failed.")
        return nil
    end

    -- Collect valid deepPtr values for batch verify
    local validPtrs = {}
    for i, dp in ipairs(deepPtrs) do
        if dp and dp.value ~= 0 then
            table.insert(validPtrs, {
                vehiclePtr  = rawPtrs[i],
                deepPtrAddr = rawPtrs[i] + 0x530,
                deepPtr     = dp.value,
            })
        end
    end

    if #validPtrs == 0 then
        LOG.warn("VehicleList", "No valid deepPtrs.")
        return nil
    end

    -- Batch verify all — 1 getValues
    local verifyReads = {}
    for _, v in ipairs(validPtrs) do
        table.insert(verifyReads, { address = v.deepPtr + 0x0, flags = 4 })
        table.insert(verifyReads, { address = v.deepPtr + 0x4, flags = 4 })
        table.insert(verifyReads, { address = v.deepPtr + 0x8, flags = 4 })
        table.insert(verifyReads, { address = v.deepPtr + 0xC, flags = 4 })
    end
    local verifyResults = gg.getValues(verifyReads)

    if not verifyResults then
        LOG.warn("VehicleList", "Verify batch read failed.")
        return nil
    end

    -- Filter verified vehicles
    local vehicles = {}
    for i, v in ipairs(validPtrs) do
        local base = (i - 1) * 4 + 1
        local v0 = verifyResults[base]
        local v1 = verifyResults[base + 1]
        local v2 = verifyResults[base + 2]
        local v3 = verifyResults[base + 3]

        if v0 and v1 and v2 and v3
        and v0.value == 0
        and v1.value == 18
        and v2.value == 53 then
            table.insert(vehicles, {
                vehiclePtr  = v.vehiclePtr,
                deepPtrAddr = v.deepPtrAddr,
            })
        else
            LOG.dbg("VehicleList", string.format("vehiclePtr=0x%X failed verify: %d %d %d %d",
                v.vehiclePtr,
                v0 and v0.value or -1,
                v1 and v1.value or -1,
                v2 and v2.value or -1,
                v3 and v3.value or -1))
        end
    end

    if #vehicles == 0 then
        LOG.warn("VehicleList", "No vehicles passed verification.")
        return nil
    end

    storage:save_session("vehicle_list_deep", vehicles)
    LOG.info("VehicleList", "Resolved + cached: " .. tostring(#vehicles) .. " vehicles")
    return vehicles
end

local function forEachVehicle(vehicles, cb)
    -- Batch read all deepPtrs — 1 getValues
    local reads = {}
    for _, v in ipairs(vehicles) do
        table.insert(reads, { address = v.deepPtrAddr, flags = 32 })
    end
    local deepPtrs = gg.getValues(reads)
    if not deepPtrs then
        LOG.warn("VehicleList", "forEachVehicle deepPtrs read failed.")
        return 0
    end

    local successCount = 0
    for i, v in ipairs(vehicles) do
        local dp = deepPtrs[i]
        if dp and dp.value ~= 0 then
            cb(v.vehiclePtr, dp.value, v.deepPtrAddr)
            successCount = successCount + 1
        else
            LOG.warn("VehicleList", string.format("vehiclePtr=0x%X deepPtr invalid at forEach", v.vehiclePtr))
        end
    end
    return successCount
end

-- ── Nebula helpers (PlayerInfo dotted paths) ───────────────────────────────

local MAX_VEHICLES = 300   -- sanity caps for array walks
local MAX_PARTS    = 200
local MAX_PRESETS  = 50

local function nebulaReady()
    return (Nebula and Nebula.PlayerInfo and Nebula.VERSION) and true or false
end

-- PlayerInfo.get wrapper: returns value, err (err is nil on success).
local function pget(path)
    local ok, v, err = pcall(Nebula.PlayerInfo.get, path)
    if not ok then
        return nil, "get_threw: " .. tostring(v)
    end
    return v, err
end

-- PlayerInfo.set wrapper: returns true, nil or false, err.
local function pset(path, value)
    local ok, r, err = pcall(Nebula.PlayerInfo.set, path, value)
    if not ok then
        return false, "set_threw: " .. tostring(r)
    end
    if not r then
        return false, err
    end
    return true, nil
end

local function isBoundsErr(err)
    return tostring(err):find("index_out_of_bounds", 1, true) ~= nil
end

-- Shared log tag for the Nebula-powered ops (max parts/vehicles, editors).
local TAG = "Tuning"

-- ── Ops ──────────────────────────────────────────────────────────────────────

-- Parts slot count (slider). status: "no_vehicles" | "no_zero_region" |
-- "applied" (data = vehicle count)
function M.partsSlot(slot, cb)
    scheduler:add(function(finishTask)
        local TAG = "PartsSlot"
        LOG.info(TAG, "Slot: " .. tostring(slot))

        local cached = storage:load_session("parts_slot_deep")

        -- Validate cache
        if cached and #cached > 0 then
            local check = gg.getValues({{ address = cached[1], flags = 32 }})
            if not check or not check[1] or check[1].value == 0 then
                LOG.warn(TAG, "Cache stale — re-resolving")
                cached = nil
                storage:delete_session("parts_slot_deep")
            end
        end

        if not cached then
            local vehiclePtrs = resolveVehicleList()
            if not vehiclePtrs then
                finishTask(); cb("no_vehicles"); return
            end
            cached = {}
            for _, vehiclePtr in ipairs(vehiclePtrs) do
                table.insert(cached, vehiclePtr.deepPtrAddr)
            end
            storage:save_session("parts_slot_deep", cached)
            LOG.info(TAG, "Cached " .. tostring(#cached) .. " deepPtrAddrs")
        end

        -- Read all deepPtrs in one call
        local reads = {}
        for _, deepPtrAddr in ipairs(cached) do
            table.insert(reads, { address = deepPtrAddr, flags = 32 })
        end
        local deepPtrs = gg.getValues(reads)

        local slotStart, slotEnd = findZeroRegion(slot)
        if not slotStart then
            finishTask(); cb("no_zero_region"); return
        end

        -- Batch ALL edits into one setValues call
        local edits = {}
        for _, dp in ipairs(deepPtrs) do
            if dp and dp.value ~= 0 then
                local deepPtrAddr = dp.address
                table.insert(edits, { address = deepPtrAddr + 0x0,  flags = 32, value = slotStart })
                table.insert(edits, { address = deepPtrAddr + 0x8,  flags = 32, value = slotEnd })
                table.insert(edits, { address = deepPtrAddr + 0x10, flags = 32, value = slotEnd })
            end
        end

        if #edits > 0 then
            gg.setValues(edits)
            local count = #edits / 3
            LOG.info(TAG, "Done. Edits: " .. tostring(#edits) .. " (" .. tostring(count) .. " vehicles)")
            finishTask(); cb("applied", count); return
        else
            finishTask(); cb("no_vehicles"); return
        end
    end)
end

-- Build tuning-part groups from configs/content/tuning_parts.lua (pure data, no UI).
-- Returns groupOrder (sorted labels) and groupMap (label → {variants}).
--
-- Each variant now carries a `statList` array — one entry per editable stat:
--   { label = "BOOST", from = 700.0, to = 800.0 }
--
-- The tab uses `statList` to let the user choose WHICH stat to modify before
-- showing the level prompt. `applyPartsModifier` then receives only the chosen
-- stat's from/to range, so unrelated stats on the same part are untouched.
function M.getPartGroups()
    local data = tuningData()
    local tp = (data and data.tuningParts) or {}

    local skip = { ECHO = true, ["COIN MAGNET"] = true, ["FUEL MAGNET"] = true }

    local groupMap = {}
    local groupOrder = {}

    for key, part in pairs(tp) do
        local label = part.name and part.name.value or key
        if not skip[label] then
            local statList = {}

            -- effectStats: named stats (BOOST, DURATION, TOP SPEED, …)
            for _, e in ipairs(part.effectStats or {}) do
                local stat = e.stat
                if type(stat) == "table" and stat["from"] ~= nil then
                    local statLabel = (type(e.name) == "table" and e.name.value) or "STAT"
                    statList[#statList + 1] = { label = statLabel, from = stat["from"], to = stat["to"] }
                end
            end

            -- effectDuration: top-level duration range (e.g. START BOOST)
            local ed = part.effectDuration
            if type(ed) == "table" and ed["from"] ~= nil then
                -- Only add if not already covered by a named DURATION effectStat
                local already = false
                for _, s in ipairs(statList) do
                    if s.label == "DURATION" then already = true; break end
                end
                if not already then
                    statList[#statList + 1] = { label = "DURATION", from = ed["from"], to = ed["to"] }
                end
            end

            -- effects: unnamed numeric ranges (fallback for parts with no effectStats)
            if #statList == 0 then
                for _, e in ipairs(part.effects or {}) do
                    local amt = e.amount
                    if type(amt) == "table" and amt["from"] ~= nil then
                        statList[#statList + 1] = { label = e.type or "STAT", from = amt["from"], to = amt["to"] }
                    end
                end
            end

            if #statList > 0 then
                if not groupMap[label] then
                    groupMap[label] = {}
                    table.insert(groupOrder, label)
                end
                table.insert(groupMap[label], { key = key, statList = statList })
            end
        end
    end

    table.sort(groupOrder)
    return groupOrder, groupMap
end

-- Apply (or reset) a tuning-part modifier for ONE chosen stat.
-- params:
--   variants  — variant list for the chosen part (from getPartGroups)
--   chosenStat — { label, from, to } — the single stat the user picked
--   cacheKey  — persistent key (includes stat label so per-stat caches don't collide)
--   editValue — float value to write (ignored when reset = true)
--   reset     — if true, restore the original level flag and clear cache
-- status: "not_found" | "reset" | "applied"
function M.applyPartsModifier(params, cb)
    local variants   = params.variants
    local chosenStat = params.chosenStat   -- { label, from, to }
    local cacheKey   = params.cacheKey
    local editValue  = params.editValue
    local reset      = params.reset

    scheduler:add(function(finishTask)
        local TAG = "PartsModifier"
        local cache = storage:load_session(cacheKey)

        if not cache then
            LOG.dbg(TAG, string.format("Scanning for %s [%.4g–%.4g]",
                chosenStat.label, chosenStat.from, chosenStat.to))

            local toEdit = {}

            gg.setRanges(BaseRegion)
            gg.clearResults()
            gg.searchNumber(BaseLib + offsets.vnpStats, 32)
            local refs = gg.getResults(gg.getResultsCount())
            gg.clearResults()

            for _, v in ipairs(refs) do
                local vals = gg.getValues({
                    { address = v.address + 0x8,  flags = 4  },
                    { address = v.address + 0xC,  flags = 16 },
                    { address = v.address + 0x10, flags = 16 },
                })
                if vals and vals[1].value == 0x40000000 then
                    local from, to = vals[2].value, vals[3].value
                    -- Match only the chosen stat's range, not all stats on the part.
                    -- This keeps BOOST and DURATION editable independently.
                    if from == chosenStat.from and to == chosenStat.to then
                        table.insert(toEdit, v.address + 0x8)
                    end
                end
            end

            gg.clearResults()

            if #toEdit == 0 then
                LOG.warn(TAG, "No results for: " .. cacheKey)
                finishTask(); cb("not_found"); return
            end

            storage:save_session(cacheKey, toEdit)
            cache = toEdit
            LOG.info(TAG, string.format("Cached %d addresses for %s", #toEdit, cacheKey))
        else
            LOG.dbg(TAG, "Cache hit: " .. cacheKey)
        end

        local edits = {}
        for _, addr in ipairs(cache) do
            table.insert(edits, { address = addr, flags = 16,
                value = reset and 0x40000000 or editValue })
        end
        gg.setValues(edits)
        gg.clearResults()

        if reset then
            storage:delete_session(cacheKey)
            LOG.info(TAG, "Reset: " .. cacheKey)
            finishTask(); cb("reset"); return
        end

        LOG.info(TAG, cacheKey .. " applied: " .. tostring(editValue))
        finishTask(); cb("applied"); return
    end)
end

-- Set / reset fuel (relocated from player — fuel is a vehicle attribute).
-- params = { amount = <raw string|number>, reset = <bool> }
-- status: "not_applied" | "invalid" | "reset" | "applied" (data = value)
function M.setFuel(params, cb)
    scheduler:add(function(finishTask)
        local TAG = "Fuel"

        -- Reset
        if params.reset then
            local cache = storage:load_session("fuel")
            if not cache then
                finishTask(); cb("not_applied"); return
            end
            gg.clearResults()
            gg.loadResults(cache)
            local base = gg.getResults(1)[1].address
            gg.setValues({
                {address = base + 4,  flags = 4, value = cast.arm64(0x1E22C000)},
                {address = base + 8,  flags = 4, value = cast.arm64(0x1E22C021)},
                {address = base + 12, flags = 4, value = cast.arm64(0x1F488400)},
                {address = base + 16, flags = 4, value = cast.arm64(0x1E624000)},
            })
            storage:delete_session("fuel")
            LOG.info(TAG, "Fuel reset")
            gg.clearResults()
            finishTask(); cb("reset"); return
        end

        local val = tonumber(params.amount)
        if not val or val < 0 or val > 100 then
            finishTask(); cb("invalid"); return
        end

        local b = string.pack("<f", val)
        local lo = string.unpack("<H", b:sub(1,2))
        local hi = string.unpack("<H", b:sub(3,4))
        local NOP  = 0xD503201F
        local movz = 0x52800000 | (lo << 5) | 8
        local movk = 0x72A00000 | (hi << 5) | 8
        local fmov = 0x1E270100

        local cache = storage:load_session("fuel")
        if cache then
            LOG.dbg(TAG, "Using cached results")
            gg.clearResults()
            gg.loadResults(cache)
            gg.getResults(gg.getResultsCount())
        else
            LOG.dbg(TAG, "No cache — scanning")
            gg.clearResults()
            gg.setRanges(8)
            gg.searchNumber(aobs.fuel[1].scan, 1)
            gg.refineNumber("h 61", 1)
            local results = gg.getResults(gg.getResultsCount())
            LOG.info(TAG, "Scan results: " .. tostring(#results))
            storage:save_session("fuel", results)
        end

        local base = gg.getResults(1)[1].address
        gg.setValues({
            {address = base + 4,  flags = 4, value = cast.arm64(movz)},
            {address = base + 8,  flags = 4, value = cast.arm64(movk)},
            {address = base + 12, flags = 4, value = cast.arm64(fmov)},
            {address = base + 16, flags = 4, value = cast.arm64(NOP)},
        })

        LOG.info(TAG, "Fuel set to " .. tostring(val))
        gg.clearResults()
        finishTask()
        cb("applied", val)
    end)
end

-- Unlock all vehicles. status: "no_vehicles" | "unlocked" (data=count) |
-- "none_to_unlock"
function M.unlockVehicles(cb)
    scheduler:add(function(finishTask)
        local TAG = "UnlockVehicles"
        LOG.info(TAG, "Module activated.")

        local vehiclePtrs = resolveVehicleList()
        if not vehiclePtrs then
            finishTask(); cb("no_vehicles"); return
        end

        -- Collect all edits first, one setValues at end
        local edits = {}
        -- FIX: capture the count (was discarded; the tab referenced an
        -- undefined `successCount`).
        local successCount = forEachVehicle(vehiclePtrs, function(vehiclePtr, deepPtr, deepPtrAddr)
            table.insert(edits, { address = vehiclePtr + 0x110, flags = 4, value = 1 })
            for off = 0x114, 0x14C, 4 do
                table.insert(edits, { address = vehiclePtr + off, flags = 4, value = 0 })
            end
        end)
        if #edits > 0 then gg.setValues(edits) end

        LOG.info(TAG, "Done. Success: " .. tostring(successCount))
        finishTask()
        cb(successCount > 0 and "unlocked" or "none_to_unlock", successCount)
    end)
end

-- ── Max vehicles ──────────────────────────────────────────────

-- Set level = maxLevel = 19 on every upgrade of every vehicle (same write
-- set as the raw pointer-walk version: engine/susp/tires/4wd slots, plus
-- the extra lowrider slot, which the array walk picks up automatically).
-- onProgress(upgradesDone, upgradesTotal) optional.
-- cb(status, stats) — stats = {vehicles=n, upgrades=m, written=k}
-- status: "all_maxed" | "no_vehicles" | "failed"
function M.maxVehicles(onProgress, cb)
    scheduler:add(function(finishTask)
        if not nebulaReady() then
            finishTask(); cb("failed", "nebula_unavailable"); return
        end

        -- Pass 1: collect vehicles (bounded probe walk).
        local vehicles = {}
        for i = 1, MAX_VEHICLES do
            local id, err = pget("gameStatus.vehicleStatus[" .. i .. "].vehicleId")
            if err then
                if not isBoundsErr(err) and #vehicles == 0 then
                    LOG.error(TAG, "vehicle probe failed: " .. tostring(err))
                    finishTask(); cb("failed", tostring(err)); return
                end
                break
            end
            vehicles[#vehicles + 1] = i
        end
        if #vehicles == 0 then
            finishTask(); cb("no_vehicles"); return
        end

        -- Pass 2: per vehicle, one array read for the whole upgrade list,
        -- then level/maxLevel writes only where below target.
        local TARGET = 19
        local upTotal, upDone = 0, 0
        local stats = { vehicles = #vehicles, upgrades = 0, written = 0 }

        for _, vi in ipairs(vehicles) do
            local arr, err = pget("gameStatus.vehicleStatus[" .. vi .. "].upgrades")
            if err and not isBoundsErr(err) then
                LOG.warn(TAG, "upgrades[" .. vi .. "] read failed: " .. tostring(err))
            else
                local n = math.min(#(arr or {}), MAX_PARTS)
                upTotal = upTotal + n
                for j = 1, n do
                    local u = arr[j]
                    if u and u.upgradeId then
                        local level    = tonumber(u.level) or 0
                        local maxLevel = tonumber(u.maxLevel) or 0
                        if level < TARGET or maxLevel < TARGET then
                            local ok1 = level < TARGET
                                and pset("gameStatus.vehicleStatus[" .. vi
                                    .. "].upgrades[" .. j .. "].level", TARGET)
                            local ok2 = maxLevel < TARGET
                                and pset("gameStatus.vehicleStatus[" .. vi
                                    .. "].upgrades[" .. j .. "].maxLevel", TARGET)
                            if ok1 or ok2 then stats.written = stats.written + 1 end
                        end
                    end
                    upDone = upDone + 1
                    if onProgress then onProgress(upDone, upTotal) end
                end
            end
        end

        stats.upgrades = upTotal
        LOG.info(TAG, string.format("Max vehicles done: %d vehicles, %d upgrades, %d written",
            stats.vehicles, stats.upgrades, stats.written))
        finishTask(); cb("all_maxed", stats)
    end)
end

-- ── Max parts ──────────────────────────────────────────────────

-- Set level = maxLevel on every owned part of every vehicle, entirely via
-- Nebula reads/writes (the raw version walked pointers manually and
-- sourced max level from a static rarity table; the save itself already
-- carries maxLevel per part).
-- onProgress(partsDone, partsTotal) optional.
-- cb(status, stats) — stats = {vehicles=n, parts=m, written=k}
-- status: "all_maxed" | "no_vehicles" | "failed"
function M.maxParts(onProgress, cb)
    scheduler:add(function(finishTask)
        if not nebulaReady() then
            finishTask(); cb("failed", "nebula_unavailable"); return
        end

        -- Pass 1: collect vehicles (bounded probe walk).
        local vehicles = {}
        for i = 1, MAX_VEHICLES do
            local id, err = pget("gameStatus.vehicleStatus[" .. i .. "].vehicleId")
            if err then
                if not isBoundsErr(err) and #vehicles == 0 then
                    LOG.error(TAG, "vehicle probe failed: " .. tostring(err))
                    finishTask(); cb("failed", tostring(err)); return
                end
                break
            end
            vehicles[#vehicles + 1] = i
        end
        if #vehicles == 0 then
            finishTask(); cb("no_vehicles"); return
        end

        -- Pass 2: per vehicle, one array read for the whole parts list,
        -- then a level write only where level < maxLevel.
        local partsTotal, partsDone = 0, 0
        local stats = { vehicles = #vehicles, parts = 0, written = 0 }

        for _, vi in ipairs(vehicles) do
            local arr, err = pget("gameStatus.vehicleStatus[" .. vi .. "].tuningParts")
            if err and not isBoundsErr(err) then
                LOG.warn(TAG, "tuningParts[" .. vi .. "] read failed: " .. tostring(err))
            else
                local n = math.min(#(arr or {}), MAX_PARTS)
                partsTotal = partsTotal + n
                for j = 1, n do
                    local p = arr[j]
                    if p and p.id then
                        local level    = tonumber(p.level) or 0
                        local maxLevel = tonumber(p.maxLevel) or 0
                        if maxLevel > 0 and level < maxLevel then
                            local ok, wErr = pset("gameStatus.vehicleStatus[" .. vi
                                .. "].tuningParts[" .. j .. "].level", maxLevel)
                            if ok then stats.written = stats.written + 1 end
                            if wErr then LOG.warn(TAG, "part level write failed: " .. tostring(wErr)) end
                        end
                    end
                    partsDone = partsDone + 1
                    if onProgress then onProgress(partsDone, partsTotal) end
                end
            end
        end

        stats.parts = partsTotal
        LOG.info(TAG, string.format("Max parts done: %d vehicles, %d parts, %d written",
            stats.vehicles, stats.parts, stats.written))
        finishTask(); cb("all_maxed", stats)
    end)
end

-- Max mastery for all vehicles. onProgress(i, total) optional.
-- status: "failed" | "all_maxed"
-- Batched: structural pointer reads collapsed into a few gg.getValues calls and
-- all writes flushed in one setValues. The per-vehicle name lookup (debug-log
-- only in the original) is dropped — it has no effect on what gets written.
function M.maxMastery(onProgress, cb)
    scheduler:add(function(finishTask)
        local TAG = "MaxMastery"
        LOG.info(TAG, "Module activated.")

        local masteryTimestamp = os.time(os.date("!*t"))
        local vehicleListPtr   = gg.getValues({{ address = BaseGameStatus + 0xB8, flags = 32 }})[1].value
        local totalVehicles    = gg.getValues({{ address = BaseGameStatus + 0xC0, flags = 4  }})[1].value

        if not vehicleListPtr or vehicleListPtr == 0 then
            LOG.fatal(TAG, "vehicleListPtr is nil or 0.")
            finishTask(); cb("failed"); return
        end

        if not totalVehicles or totalVehicles == 0 then
            LOG.fatal(TAG, "totalVehicles is nil or 0.")
            finishTask(); cb("failed"); return
        end

        LOG.dbg(TAG, "Total vehicles: " .. tostring(totalVehicles))

        -- Batch 1: all vehicle pointers.
        local reads = {}
        for i = 0, totalVehicles - 1 do
            reads[#reads + 1] = { address = vehicleListPtr + i * 8, flags = 32 }
        end
        local vPtrs = (#reads > 0 and gg.getValues(reads)) or {}
        local vehicles = {}
        for _, v in ipairs(vPtrs) do
            if v.value and v.value ~= 0 then vehicles[#vehicles + 1] = v.value end
        end

        -- Batch 2: masteryPtr (+0x120) per vehicle.
        local mReads = {}
        for _, vp in ipairs(vehicles) do
            mReads[#mReads + 1] = { address = vp + 0x120, flags = 32 }
        end
        local mVals = (#mReads > 0 and gg.getValues(mReads)) or {}

        -- Vehicles that actually have a mastery object, plus a batched read of
        -- their 4 CA pointers each.
        local active  = {}
        local caReads = {}
        for k, vp in ipairs(vehicles) do
            local masteryPtr = mVals[k] and mVals[k].value
            if masteryPtr and masteryPtr ~= 0 then
                active[#active + 1] = { vehiclePtr = vp, masteryPtr = masteryPtr }
                for j = 0, 3 do
                    caReads[#caReads + 1] = { address = masteryPtr + j * 8, flags = 32 }
                end
            end
        end
        local caVals = (#caReads > 0 and gg.getValues(caReads)) or {}

        -- Build all writes; flush once at the end.
        local writes       = {}
        local successCount = 0
        local skipCount    = #vehicles - #active
        local n    = #active
        local step = math.max(1, math.floor((n > 0 and n or 1) / 12))
        for a = 1, n do
            local entry = active[a]
            local base  = (a - 1) * 4
            local validPtrs = {}
            for j = 1, 4 do
                local p = caVals[base + j]
                if p and p.value and p.value ~= 0 then validPtrs[#validPtrs + 1] = p.value end
            end

            if #validPtrs == 0 then
                skipCount = skipCount + 1
            else
                for _, p in ipairs(validPtrs) do
                    writes[#writes + 1] = { address = p + 0x18, flags = 4, value = 65793 }
                    writes[#writes + 1] = { address = p + 0x1C, flags = 4, value = masteryTimestamp }
                end
                writes[#writes + 1] = { address = entry.vehiclePtr + 0x120, flags = 32, value = entry.masteryPtr }
                writes[#writes + 1] = { address = entry.vehiclePtr + 0x128, flags = 4,  value = 4 }
                writes[#writes + 1] = { address = entry.vehiclePtr + 0x12C, flags = 4,  value = 4 }
                writes[#writes + 1] = { address = entry.vehiclePtr + 0x130, flags = 4,  value = 4 }
                successCount = successCount + 1
            end
            if onProgress and (a % step == 0 or a == n) then onProgress(a, n) end
        end

        if #writes > 0 then gg.setValues(writes) end

        LOG.info(TAG, string.format("Complete. Success: %d | Skipped: %d", successCount, skipCount))
        finishTask()
        cb(successCount > 0 and "all_maxed" or "failed")
    end)
end

-- ── Tuning parts editors (Nebula PlayerInfo paths) ─────────────────────────

--[[
  Equipped Tuning Parts editor and Tuning Part Preset editor. All
  reads/writes go through Nebula.PlayerInfo dotted paths against
  gameStatus.vehicleStatus:

    vehicleStatus[i].vehicleId            String
    vehicleStatus[i].tuningParts[j]      id / level / maxLevel / ...
    vehicleStatus[i].equippedTuningParts Array<String> (live equipped)
    vehicleStatus[i].tuningPartPresets[p].equippedParts  Array<String>
    vehicleStatus[i].selectedPresetIndex  Int32

  Indexed array paths are 1-based in Nebula. Every list operation walks
  indexes until Nebula reports index_out_of_bounds, with sanity caps so
  a corrupted header can never loop forever. Preset edits stay within
  ONE vehicle on purpose: vehicles do not share the same part pool, so
  cross-vehicle preset copying is not offered.

  UI wiring lives in modules/tabs/vehicle.lua.

]]
-- ── Vehicle list ─────────────────────────────────────────────────────────────

-- cb(status, list) — list = { {index=1, id="hillclimber"}, ... }
-- status: "ok" | "no_vehicles" | "nebula_unavailable" | "failed"
function M.listVehicles(cb)
    scheduler:add(function(finishTask)
        if not nebulaReady() then
            LOG.warn(TAG, "Nebula SDK unavailable")
            finishTask(); cb("nebula_unavailable"); return
        end

        local list = {}
        for i = 1, MAX_VEHICLES do
            local id, err = pget("gameStatus.vehicleStatus[" .. i .. "].vehicleId")
            if err then
                if not isBoundsErr(err) and #list == 0 then
                    LOG.error(TAG, "vehicleStatus[1] read failed: " .. tostring(err))
                    finishTask(); cb("failed", tostring(err)); return
                end
                if not isBoundsErr(err) then
                    LOG.warn(TAG, "vehicle walk stopped at [" .. i .. "]: " .. tostring(err))
                end
                break
            end
            list[#list + 1] = { index = i, id = tostring(id) }
        end

        if #list == 0 then
            finishTask(); cb("no_vehicles"); return
        end
        LOG.info(TAG, "Vehicle walk: " .. #list .. " vehicles")
        finishTask(); cb("ok", list)
    end)
end

-- ── Owned parts inventory ───────────────────────────────────────────────────

-- cb(status, parts) — parts = { {id, level, maxLevel}, ... }
-- One array read per vehicle (TuningPartStatus is a tiny struct, so a
-- whole-array get is far cheaper than 3 scalar reads per part).
-- status: "ok" | "no_parts" | "nebula_unavailable" | "failed"
function M.listParts(vIdx, cb)
    scheduler:add(function(finishTask)
        if not nebulaReady() then
            finishTask(); cb("nebula_unavailable"); return
        end

        local arr, err = pget("gameStatus.vehicleStatus[" .. vIdx .. "].tuningParts")
        if err then
            LOG.error(TAG, "tuningParts read failed: " .. tostring(err))
            finishTask(); cb("failed", tostring(err)); return
        end

        local parts = {}
        for i = 1, math.min(#(arr or {}), MAX_PARTS) do
            local p = arr[i]
            if p and p.id then
                parts[#parts + 1] = {
                    id       = tostring(p.id),
                    level    = tonumber(p.level) or 0,
                    maxLevel = tonumber(p.maxLevel) or 0,
                }
            end
        end

        if #parts == 0 then
            finishTask(); cb("no_parts"); return
        end
        finishTask(); cb("ok", parts)
    end)
end

-- ── Equipped parts ──────────────────────────────────────────────────────────

-- cb(status, ids) — ids = { "part_engine", ... }
-- status: "ok" | "nebula_unavailable" | "failed"
function M.getEquipped(vIdx, cb)
    scheduler:add(function(finishTask)
        if not nebulaReady() then
            finishTask(); cb("nebula_unavailable"); return
        end

        local arr, err = pget("gameStatus.vehicleStatus[" .. vIdx .. "].equippedTuningParts")
        if err then
            LOG.error(TAG, "equippedTuningParts read failed: " .. tostring(err))
            finishTask(); cb("failed", tostring(err)); return
        end

        local ids = {}
        for i = 1, math.min(#(arr or {}), MAX_PARTS) do
            if arr[i] and arr[i] ~= false then
                ids[#ids + 1] = tostring(arr[i])
            end
        end
        finishTask(); cb("ok", ids)
    end)
end

-- Rewrite the equipped list. Mirrors the write into the selected preset
-- (the garage keeps equipped and the active preset in sync; writing only
-- the live list would be reverted on the next preset switch).
-- cb(status, count, mirrored) — status: "applied" | "invalid" | "failed"
function M.setEquipped(vIdx, ids, cb)
    scheduler:add(function(finishTask)
        if not nebulaReady() then
            finishTask(); cb("failed", "nebula_unavailable"); return
        end
        if type(ids) ~= "table" or #ids == 0 or #ids > MAX_PARTS then
            finishTask(); cb("invalid"); return
        end

        local ok, err = pset("gameStatus.vehicleStatus[" .. vIdx .. "].equippedTuningParts", ids)
        if not ok then
            LOG.error(TAG, "equipped write failed: " .. tostring(err))
            finishTask(); cb("failed", tostring(err)); return
        end

        -- Mirror into the selected preset when one is active.
        local mirrored = false
        local selIdx, selErr = pget("gameStatus.vehicleStatus[" .. vIdx .. "].selectedPresetIndex")
        if not selErr and selIdx ~= nil and tonumber(selIdx)
           and selIdx >= 0 and selIdx < MAX_PRESETS then
            local mOk, mErr = pset("gameStatus.vehicleStatus[" .. vIdx
                .. "].tuningPartPresets[" .. (selIdx + 1) .. "].equippedParts", ids)
            if mOk then
                mirrored = true
            else
                LOG.warn(TAG, "preset mirror skipped: " .. tostring(mErr))
            end
        end

        LOG.info(TAG, string.format("Equipped set: %d parts (preset mirror: %s)",
            #ids, tostring(mirrored)))
        finishTask(); cb("applied", #ids, mirrored)
    end)
end

-- ── Presets ──────────────────────────────────────────────────────────────────

-- cb(status, presets, selected) —
-- presets = { {index=1, parts={"id1","id2"}}, ... }; selected = Int32
-- status: "ok" | "no_presets" | "nebula_unavailable" | "failed"
function M.listPresets(vIdx, cb)
    scheduler:add(function(finishTask)
        if not nebulaReady() then
            finishTask(); cb("nebula_unavailable"); return
        end

        -- The game stores selectedPresetIndex 0-based (0 = first); the UI
        -- works 1-based, so convert. No active preset -> no marker.
        local selected = nil
        local selVal, selErr = pget("gameStatus.vehicleStatus[" .. vIdx .. "].selectedPresetIndex")
        if not selErr and selVal ~= nil then
            selected = tonumber(selVal)
            if selected then selected = selected + 1 end
        end

        local presets = {}
        for p = 1, MAX_PRESETS do
            local arr, err = pget("gameStatus.vehicleStatus[" .. vIdx
                .. "].tuningPartPresets[" .. p .. "].equippedParts")
            if err then
                if not isBoundsErr(err) and #presets == 0 then
                    LOG.error(TAG, "preset walk failed: " .. tostring(err))
                    finishTask(); cb("failed", tostring(err)); return
                end
                if not isBoundsErr(err) then
                    LOG.warn(TAG, "preset walk stopped at [" .. p .. "]: " .. tostring(err))
                end
                break
            end
            local parts = {}
            for i = 1, math.min(#(arr or {}), MAX_PARTS) do
                if arr[i] and arr[i] ~= false then
                    parts[#parts + 1] = tostring(arr[i])
                end
            end
            presets[#presets + 1] = { index = p, parts = parts }
        end

        if #presets == 0 then
            finishTask(); cb("no_presets"); return
        end
        finishTask(); cb("ok", presets, selected)
    end)
end

-- Rewrite one preset's part list (same vehicle only).
-- cb(status, count) — status: "applied" | "invalid" | "failed"
function M.setPresetParts(vIdx, pIdx, ids, cb)
    scheduler:add(function(finishTask)
        if not nebulaReady() then
            finishTask(); cb("failed", "nebula_unavailable"); return
        end
        if type(ids) ~= "table" or #ids == 0 or #ids > MAX_PARTS
           or tonumber(pIdx) == nil or pIdx < 1 or pIdx > MAX_PRESETS then
            finishTask(); cb("invalid"); return
        end

        local ok, err = pset("gameStatus.vehicleStatus[" .. vIdx
            .. "].tuningPartPresets[" .. pIdx .. "].equippedParts", ids)
        if not ok then
            LOG.error(TAG, "preset write failed: " .. tostring(err))
            finishTask(); cb("failed", tostring(err)); return
        end
        LOG.info(TAG, "Preset " .. pIdx .. " set: " .. #ids .. " parts")
        finishTask(); cb("applied", #ids)
    end)
end

-- Copy the CURRENT equipped list into a preset (same vehicle only).
-- cb(status, count) — status: "applied" | "not_equipped" | "failed"
function M.saveEquippedToPreset(vIdx, pIdx, cb)
    scheduler:add(function(finishTask)
        if not nebulaReady() then
            finishTask(); cb("failed", "nebula_unavailable"); return
        end

        local arr, err = pget("gameStatus.vehicleStatus[" .. vIdx .. "].equippedTuningParts")
        if err then
            LOG.error(TAG, "equipped read failed: " .. tostring(err))
            finishTask(); cb("failed", tostring(err)); return
        end
        local ids = {}
        for i = 1, math.min(#(arr or {}), MAX_PARTS) do
            if arr[i] and arr[i] ~= false then
                ids[#ids + 1] = tostring(arr[i])
            end
        end
        if #ids == 0 then
            finishTask(); cb("not_equipped"); return
        end

        local ok, wErr = pset("gameStatus.vehicleStatus[" .. vIdx
            .. "].tuningPartPresets[" .. pIdx .. "].equippedParts", ids)
        if not ok then
            LOG.error(TAG, "preset write failed: " .. tostring(wErr))
            finishTask(); cb("failed", tostring(wErr)); return
        end
        LOG.info(TAG, "Equipped (" .. #ids .. ") copied to preset " .. pIdx)
        finishTask(); cb("applied", #ids)
    end)
end

-- Switch the active preset (selectedPresetIndex write).
-- cb(status) — status: "applied" | "invalid" | "failed"
function M.setSelectedPreset(vIdx, pIdx, cb)
    scheduler:add(function(finishTask)
        if not nebulaReady() then
            finishTask(); cb("failed", "nebula_unavailable"); return
        end
        if tonumber(pIdx) == nil or pIdx < 1 or pIdx > MAX_PRESETS then
            finishTask(); cb("invalid"); return
        end

        -- UI is 1-based, the game field is 0-based (0 = first preset).
        local ok, err = pset("gameStatus.vehicleStatus[" .. vIdx .. "].selectedPresetIndex", pIdx - 1)
        if not ok then
            LOG.error(TAG, "selectedPresetIndex write failed: " .. tostring(err))
            finishTask(); cb("failed", tostring(err)); return
        end
        LOG.info(TAG, "Selected preset: " .. pIdx)
        finishTask(); cb("applied")
    end)
end


-- Append one empty preset by rewriting the whole tuningPartPresets array:
-- existing entries pass through untouched, the new entry is an empty
-- preset (same vehicle only). cb(status, count) —
-- status: "applied" | "max_reached" | "nebula_unavailable" | "failed"
function M.addPreset(vIdx, cb)
    scheduler:add(function(finishTask)
        if not nebulaReady() then
            finishTask(); cb("nebula_unavailable"); return
        end

        -- Count the current presets (same walk as listPresets).
        local n = 0
        for p = 1, MAX_PRESETS do
            local _, err = pget("gameStatus.vehicleStatus[" .. vIdx
                .. "].tuningPartPresets[" .. p .. "].equippedParts")
            if err then
                if not isBoundsErr(err) and n == 0 then
                    LOG.error(TAG, "preset walk failed: " .. tostring(err))
                    finishTask(); cb("failed", tostring(err)); return
                end
                if not isBoundsErr(err) then
                    LOG.warn(TAG, "preset walk stopped at [" .. p .. "]: " .. tostring(err))
                end
                break
            end
            n = n + 1
        end

        if n >= MAX_PRESETS then
            finishTask(); cb("max_reached"); return
        end

        -- Whole-array write: existing entries carry no field values, so
        -- their structs are left untouched; the new entry is an empty preset.
        local values = {}
        for i = 1, n do values[i] = {} end
        values[n + 1] = { equippedParts = {} }

        local ok, err = pset("gameStatus.vehicleStatus[" .. vIdx
            .. "].tuningPartPresets", values)
        if not ok then
            LOG.error(TAG, "add preset failed: " .. tostring(err))
            finishTask(); cb("failed", tostring(err)); return
        end
        LOG.info(TAG, "Preset added (now " .. (n + 1) .. ")")
        finishTask(); cb("applied", n + 1)
    end)
end

-- Show Hidden Vehicles (switch). PlayerInfo.showHiddenVehicles (Bool,
-- top-level @0xEA). Snapshot on first enable, restore on disable.
-- status: "applied" | "reverted" | "nebula_unavailable" | "failed"
function M.showHiddenVehicles(state, cb)
    scheduler:add(function(finishTask)
        local TAG = "HiddenVehicles"
        if not nebulaReady() then
            finishTask(); cb("nebula_unavailable"); return
        end

        if state then
            local cur, rErr = pget("showHiddenVehicles")
            if not rErr and cur ~= nil then
                storage:save_session("show_hidden_snapshot", cur)
            end
            local ok, wErr = pset("showHiddenVehicles", true)
            if not ok then
                LOG.error(TAG, "write failed: " .. tostring(wErr))
                finishTask(); cb("failed", tostring(wErr)); return
            end
            LOG.info(TAG, "ON")
            finishTask(); cb("applied")
        else
            local snap = storage:load_session("show_hidden_snapshot")
            if snap ~= nil then
                local ok, wErr = pset("showHiddenVehicles", snap)
                storage:delete_session("show_hidden_snapshot")
                if not ok then
                    LOG.error(TAG, "restore failed: " .. tostring(wErr))
                    finishTask(); cb("failed", tostring(wErr)); return
                end
            end
            LOG.info(TAG, "OFF")
            finishTask(); cb("reverted")
        end
    end)
end

return M
