--[[
  modules/ops/vehicle.lua — Vehicle feature memory ops (no UI)
  Contract: see modules/ops/README.md.

  Public ops are ordered to mirror the Vehicle tab: parts_slot, parts_modifier,
  fuel, unlock_vehicles, max_vehicles, max_mastery, max_parts.

  Several ops loop over every vehicle and report progress; those accept an
  optional `onProgress(i, total)` UI reporter so core stays UI-free.

  Globals used: scheduler, memory, gg, cast, aobs, json, loadModule,
  readString, BaseRegion, BaseGameStatus, BaseLib, offsets, LOG.
]]

-- ── Tuning-parts config (decoded once, shared) ───────────────────────────────

-- Part max upgrade level is derived from each part's rarity, sourced from
-- configs/tuning_parts.lua — replacing the old hardcoded name→level map.
local RARITY_CAP = {
    common    = 15,
    rare      = 10,
    epic      = 7,
    legendary = 4,
    mythic    = 3,
}

-- Decode configs/tuning_parts.lua once and cache it — the file is ~3k lines,
-- so both getPartGroups (UI) and partCaps (max_parts) share this single parse.
local _tuningData
local function tuningData()
    if _tuningData ~= nil then return _tuningData or nil end
    local ok, data = pcall(function() return json.decode(loadModule("configs/tuning_parts.lua")) end)
    if not ok or type(data) ~= "table" then
        LOG.warn("Vehicle", "tuning_parts.lua failed to decode")
        _tuningData = false
        return nil
    end
    _tuningData = data
    return data
end

-- Lazily-built map: tuning-part key → max level (by rarity).
local _partCaps
local function partCaps()
    if _partCaps then return _partCaps end
    _partCaps = {}
    local data = tuningData()
    if not data or type(data.tuningParts) ~= "table" then
        LOG.warn("MaxParts", "tuning_parts.lua unavailable — part caps fall back to default")
        return _partCaps
    end
    for key, part in pairs(data.tuningParts) do
        local cap = type(part) == "table" and part.rarity and RARITY_CAP[part.rarity]
        if cap then _partCaps[key] = cap end
    end
    return _partCaps
end

local M = {}

-- ── Internal helpers (vehicle-list resolution, zero-region scan) ─────────────

local function findZeroRegion(size)
    local ranges = gg.getRangesList()
    for _, region in ipairs(ranges) do
        if region.state == "A" then
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
    local cached = memory:load("vehicle_list_deep")
    if cached and #cached > 0 then
        local check = gg.getValues({{ address = cached[1].deepPtrAddr, flags = 32 }})
        if check and check[1] and check[1].value ~= 0 then
            LOG.dbg("VehicleList", "Cache hit: " .. tostring(#cached) .. " vehicles")
            return cached
        else
            LOG.warn("VehicleList", "Cache stale — re-resolving")
            memory:save("vehicle_list_deep", nil)
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

    -- Pattern check — 1 getValues
    local pattern = gg.getValues({
        { address = anchor.address - 0x20, flags = 4 },
        { address = anchor.address - 0x8,  flags = 4 }
    })

    if not pattern or not pattern[1] or not pattern[2]
    or pattern[1].value ~= 0x65656A08
    or pattern[2].value ~= 0x403147AE then
        LOG.warn("VehicleList", "Pattern mismatch.")
        return nil
    end

    -- Refs search
    gg.clearResults()
    gg.searchNumber(pattern[1].address, 32)
    local refResults = gg.getResults(gg.getResultsCount())
    gg.clearResults()

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

    memory:save("vehicle_list_deep", vehicles)
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

-- ── Ops ──────────────────────────────────────────────────────────────────────

-- Parts slot count (slider). status: "no_vehicles" | "no_zero_region" |
-- "applied" (data = vehicle count)
function M.partsSlot(slot, cb)
    scheduler:add(function(finishTask)
        local TAG = "PartsSlot"
        LOG.info(TAG, "Slot: " .. tostring(slot))

        local cached = memory:load("parts_slot_deep")

        -- Validate cache
        if cached and #cached > 0 then
            local check = gg.getValues({{ address = cached[1], flags = 32 }})
            if not check or not check[1] or check[1].value == 0 then
                LOG.warn(TAG, "Cache stale — re-resolving")
                cached = nil
                memory:save("parts_slot_deep", nil)
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
            memory:save("parts_slot_deep", cached)
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

-- Build tuning-part groups from configs/tuning_parts.lua (pure data, no UI).
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
        local cache = memory:load(cacheKey)

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

            memory:save(cacheKey, toEdit)
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
            memory:save(cacheKey, nil)
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
            local cache = memory:load("fuel")
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
            memory:save("fuel", nil)
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

        local cache = memory:load("fuel")
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
            memory:save("fuel", results)
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

-- Max all vehicle upgrades. onProgress(i, total) optional.
-- status: "no_vehicles" | "all_maxed" | "failed"
-- Batched: pointer reads are collapsed into a few gg.getValues calls instead of
-- one per vehicle/slot. Same write set as the original sequential version.
function M.maxVehicles(onProgress, cb)
    scheduler:add(function(finishTask)
        local TAG = "MaxVehicles"
        LOG.info(TAG, "Module activated.")

        local vehicleListPtr = gg.getValues({{ address = BaseGameStatus + 0xB8, flags = 32 }})[1].value
        local totalVehicles  = gg.getValues({{ address = BaseGameStatus + 0xC0, flags = 4  }})[1].value

        if not vehicleListPtr or vehicleListPtr == 0 then
            LOG.fatal(TAG, "vehicleListPtr is nil or 0.")
            finishTask(); cb("no_vehicles"); return
        end
        totalVehicles = totalVehicles or 0
        LOG.dbg(TAG, "Total vehicles: " .. tostring(totalVehicles))

        -- Batch 1: all vehicle pointers in one read.
        local reads = {}
        for i = 0, totalVehicles - 1 do
            reads[#reads + 1] = { address = vehicleListPtr + i * 8, flags = 32 }
        end
        local vPtrs = (#reads > 0 and gg.getValues(reads)) or {}
        local vehicles = {}
        for _, v in ipairs(vPtrs) do
            if v.value and v.value ~= 0 then vehicles[#vehicles + 1] = v.value end
        end

        -- Batch 2: namePtr (+0x18) and upgradeListPtr (+0x20) per vehicle.
        local meta = {}
        for _, vp in ipairs(vehicles) do
            meta[#meta + 1] = { address = vp + 0x18, flags = 32 }
            meta[#meta + 1] = { address = vp + 0x20, flags = 32 }
        end
        local metaVals = (#meta > 0 and gg.getValues(meta)) or {}

        -- Resolve slot count per vehicle (needs the name) and collect all
        -- upgrade-slot pointer addresses for a single batched read.
        local upReads = {}
        local n = #vehicles
        local step = math.max(1, math.floor(n / 12))
        for k, vp in ipairs(vehicles) do
            local namePtr        = metaVals[(k - 1) * 2 + 1] and metaVals[(k - 1) * 2 + 1].value
            local upgradeListPtr = metaVals[(k - 1) * 2 + 2] and metaVals[(k - 1) * 2 + 2].value
            local vehicleName  = (namePtr and namePtr ~= 0) and readString(namePtr + 1) or "unknown"
            local upgradeSlots = vehicleName:find("lowrider") and 5 or 4
            if upgradeListPtr and upgradeListPtr ~= 0 then
                for j = 0, upgradeSlots - 1 do
                    upReads[#upReads + 1] = { address = upgradeListPtr + j * 8, flags = 32 }
                end
            end
            if onProgress and (k % step == 0 or k == n) then onProgress(k, n) end
        end

        -- Batch 3: all upgrade pointers, then build the edit list.
        local upPtrs = (#upReads > 0 and gg.getValues(upReads)) or {}
        local upgradeList = {}
        for _, p in ipairs(upPtrs) do
            if p.value and p.value ~= 0 then
                upgradeList[#upgradeList + 1] = { address = p.value + 0x20, flags = 4, value = 19 }
                upgradeList[#upgradeList + 1] = { address = p.value + 0x24, flags = 4, value = 19 }
            end
        end

        if #upgradeList > 0 then
            gg.setValues(upgradeList)
            LOG.info(TAG, "Done. Total writes: " .. tostring(#upgradeList))
            finishTask(); cb("all_maxed"); return
        else
            LOG.warn(TAG, "upgradeList is empty.")
            finishTask(); cb("failed"); return
        end
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

-- Resolve a part's max level from its name via the rarity-derived caps.
-- Longest matching key wins so a specific variant beats its base name.
local function partMaxLevel(partName)
    local maxLevel, bestLen = 3, 0  -- fallback for parts with no rarity match
    for key, lvl in pairs(partCaps()) do
        if #key > bestLen and partName:find(key .. "$") then
            maxLevel = lvl
            bestLen  = #key
        end
    end
    return maxLevel
end

-- Max all parts for all vehicles. onProgress(i, total) optional.
-- status: "no_vehicles" | "all_maxed" | "failed"
-- Batched: vehicle pointers, each vehicle's parts-list header, and each
-- vehicle's part-pointer array are read in bulk. The (conditional, multi-level)
-- part-name lookup stays sequential — identical to the original.
function M.maxParts(onProgress, cb)
    scheduler:add(function(finishTask)
        local TAG = "MaxParts"
        LOG.info(TAG, "Module activated.")

        local vehicleListPtr = gg.getValues({{ address = BaseGameStatus + 0xB8, flags = 32 }})[1].value
        local totalVehicles  = gg.getValues({{ address = BaseGameStatus + 0xC0, flags = 4  }})[1].value

        if not vehicleListPtr or vehicleListPtr == 0 then
            LOG.fatal(TAG, "vehicleListPtr is nil or 0.")
            finishTask(); cb("no_vehicles"); return
        end
        totalVehicles = totalVehicles or 0
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

        -- Batch 2: partsListPtr (+0x58) and totalParts (+0x60) per vehicle.
        local meta = {}
        for _, vp in ipairs(vehicles) do
            meta[#meta + 1] = { address = vp + 0x58, flags = 32 }
            meta[#meta + 1] = { address = vp + 0x60, flags = 4 }
        end
        local metaVals = (#meta > 0 and gg.getValues(meta)) or {}

        local upgradeList = {}
        local n = #vehicles
        local step = math.max(1, math.floor((n > 0 and n or 1) / 12))
        for k, vp in ipairs(vehicles) do
            local partsListPtr = metaVals[(k - 1) * 2 + 1] and metaVals[(k - 1) * 2 + 1].value
            local totalParts   = metaVals[(k - 1) * 2 + 2] and metaVals[(k - 1) * 2 + 2].value

            if partsListPtr and partsListPtr ~= 0 and totalParts and totalParts > 0 then
                -- Batch this vehicle's part pointers in one read.
                local pReads = {}
                for j = 0, totalParts - 1 do
                    pReads[#pReads + 1] = { address = partsListPtr + j * 8, flags = 32 }
                end
                local partPtrs = gg.getValues(pReads) or {}

                for _, pp in ipairs(partPtrs) do
                    local partPtr = pp.value
                    if partPtr and partPtr ~= 0 then
                        local namePtr  = gg.getValues({{ address = partPtr + 0x18, flags = 32 }})[1].value
                        local partName = "unknown"

                        if namePtr and namePtr ~= 0 then
                            local header = gg.getValues({{ address = namePtr, flags = 4 }})[1].value
                            if header == 49 then
                                local namePtr2 = gg.getValues({{ address = namePtr + 0x10, flags = 32 }})[1].value
                                partName = namePtr2 ~= 0 and readString(namePtr2 + 1) or "unknown"
                            else
                                partName = readString(namePtr + 1)
                            end
                        end

                        local maxLevel = partMaxLevel(partName)
                        upgradeList[#upgradeList + 1] = { address = partPtr + 0x20, flags = 4, value = maxLevel }
                        upgradeList[#upgradeList + 1] = { address = partPtr + 0x34, flags = 4, value = maxLevel }
                    end
                end
            end
            if onProgress and (k % step == 0 or k == n) then onProgress(k, n) end
        end

        if #upgradeList > 0 then
            gg.setValues(upgradeList)
            LOG.info(TAG, "Done. Total writes: " .. tostring(#upgradeList))
            finishTask(); cb("all_maxed"); return
        else
            LOG.warn(TAG, "upgradeList is empty.")
            finishTask(); cb("failed"); return
        end
    end)
end

return M
