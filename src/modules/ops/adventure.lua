--[[
  modules/ops/adventure.lua — Adventure feature memory ops (no UI)
  Contract: see modules/ops/README.md.

  set_distance supports an optional re-apply loop. Because the loop must emit
  periodic UI feedback, the tab passes a small `ui` handler table; core never
  calls showToast/showDialog directly.

  Globals used: scheduler, memory, gg, BaseRegion, BaseGameStatusRaw, BaseLib,
  offsets, LOG.
]]

local raceinfo = loadModule("modules/lib/raceinfo.lua")

local M = {}

-- Auto adventure chests. status: "none_found" | "done"
function M.autoAdventureChests(cb)
    scheduler:add(function(finishTask)
        local TAG = "AutoAdventureChests"
        LOG.info(TAG, "Module activated.")

        gg.clearResults()
        gg.setRanges(BaseRegion)
        gg.searchNumber("500;500::5", 4)
        local res = gg.getResults(gg.getResultsCount())

        if #res == 0 then
            LOG.warn(TAG, "Search returned 0 results.")
            finishTask(); cb("none_found"); return
        end

        LOG.dbg(TAG, "Results found: " .. tostring(#res))

        gg.editAll("-1", 4)
        gg.clearResults()

        LOG.info(TAG, "Done.")
        finishTask()
        cb("done")
    end)
end

-- ── Set distance (+ optional re-apply loop) ──────────────────────────────────

-- Loop state helpers (synchronous; gate the loop-active dialog in the tab).
function M.isLoopActive() return memory:load("set_distance_loop") and true or false end
function M.stopLoop()     memory:save("set_distance_loop", false) end

local TAG = "SetDistance"

local function isValidDistanceBase(addr)
    local check = gg.getValues({
        { address = addr + 0x0,  flags = 4  },
        { address = addr + 0x10, flags = 16 },
        { address = addr + 0x14, flags = 16 },
    })
    if not check or #check ~= 3 then return false end

    local dist   = check[1].value
    local float1 = check[2].value
    local float2 = check[3].value

    if type(dist) ~= "number" or dist < 0 or dist > 999999 then return false end
    if type(float1) ~= "number" or float1 == 0 then return false end
    if type(float2) ~= "number" or float2 == 0 then return false end

    return true
end

-- Apply the distance once. Returns "ok" | "not_in_adventure" | "start_race_first".
local function applyDistance(target_meters)
    local activeTab = gg.getValues({{ address = BaseGameStatusRaw - 0xD4, flags = 4 }})
    local isAdventureTab = (type(activeTab) == "table" and activeTab[1] and activeTab[1].value == 0)

    if not isAdventureTab then
        LOG.warn(TAG, "Not in Adventure tab.")
        return "not_in_adventure"
    end

    -- Validator keeps a cached pointer only while a race is actually live.
    local distanceBase = raceinfo.resolve("set_distance_ptr", isValidDistanceBase)
    if not distanceBase then
        LOG.fatal(TAG, "Failed to resolve distanceBase.")
        return "start_race_first"
    end

    gg.setValues({
        { address = distanceBase + 0x0,  flags = 4,  value = target_meters },
        { address = distanceBase + 0x10, flags = 16, value = 2000000000 },
        { address = distanceBase + 0x14, flags = 16, value = 2000000000 },
    })

    LOG.info(TAG, "Distance set: " .. tostring(target_meters) .. "m")
    return "ok"
end

-- Set distance (with optional re-apply loop).
-- params = { target_meters, loop_enabled, loop_interval }
-- ui = {
--   onApply(status, phase)  -- phase: "initial" | "loop"
--   onLoopRunning()         -- every 2 loop ticks
--   onLoopStopped()         -- when the loop flag is cleared
-- }
-- The tab releases its card (done()) right after calling this; ui has no done.
function M.setDistance(params, ui)
    local target_meters = params.target_meters
    local loop_enabled  = params.loop_enabled
    local loop_interval = params.loop_interval

    scheduler:add(function(finishTask)
        local status = applyDistance(target_meters)
        ui.onApply(status, "initial")

        if status ~= "ok" then
            finishTask(); return
        end

        if not loop_enabled then
            finishTask(); return
        end

        memory:save("set_distance_loop", true)
        finishTask()

        local tickCount = 0
        local function loopTick()
            if not memory:load("set_distance_loop") then
                LOG.info(TAG, "Loop stopped.")
                ui.onLoopStopped()
                memory:delete("set_distance_ptr")
                return
            end

            gg.sleep(loop_interval)
            tickCount = tickCount + 1

            local s = applyDistance(target_meters)
            ui.onApply(s, "loop")

            if tickCount % 2 == 0 then
                ui.onLoopRunning()
            end

            scheduler:add(function(ft)
                loopTick()
                ft()
            end)
        end

        scheduler:add(function(ft)
            loopTick()
            ft()
        end)
    end)
end

-- Free Adventure Shop — makes every shop item free and purchasable without
-- the usual Adventure Rank requirement.
--
-- Resolution (heavily batched per design spec):
--   1. AOB search for the "*coll_coin_doubler\0\x18" marker → candidate item starts.
--   2. Verify each candidate: +0x18==8 and +0x1C==0 (batched read).
--   3. Pointer-search each confirmed start address → who points to it.
--   4. Verify each pointer hit: deref +0x8 → ptr; ptr+0x0==0x6C6F632A,
--      ptr+0x18==80, ptr+0x1C==0 (all batched).
--   5. From each validated pointer-search hit address, walk +0x8 forward,
--      reading a QWORD ptr at each step and editing ptr+0x18/+0x1C to 0,
--      until ptr+0x0 (read as DWORD) == 0x79747318 (also edited, then stop).
--
-- Cache: { {ptr, orig18, orig1C}, ... } — original values are saved BEFORE
-- the first edit so disable can restore them exactly. The cache is NEVER
-- cleared on disable — memory:save/load is PID-scoped so a game restart
-- already invalidates it naturally; skipping the clear avoids a full
-- re-scan on every toggle.
-- status: "resolve_failed" | "applied" | "reverted"
function M.freeAdventureShop(state, cb)
    scheduler:add(function(finishTask)
        local TAG = "FreeAdventureShop"

        local cache = memory:load("free_adventure_shop")

        if not state then
            if not cache then
                LOG.warn(TAG, "no cache to revert")
                finishTask(); cb("resolve_failed"); return
            end
            local restoreWrites = {}
            for _, e in ipairs(cache) do
                restoreWrites[#restoreWrites + 1] = { address = e.ptr + 0x18, flags = 4, value = e.orig18 }
                restoreWrites[#restoreWrites + 1] = { address = e.ptr + 0x1C, flags = 4, value = e.orig1C }
            end
            gg.setValues(restoreWrites)
            LOG.info(TAG, string.format("Reverted %d entries", #cache))
            finishTask(); cb("reverted"); return
        end

        -- ── Enable, cache hit: skip straight to the write ──────────────────────
        if cache then
            local edits = {}
            for _, e in ipairs(cache) do
                edits[#edits + 1] = { address = e.ptr + 0x18, flags = 4, value = 0 }
                edits[#edits + 1] = { address = e.ptr + 0x1C, flags = 4, value = 0 }
            end
            gg.setValues(edits)
            LOG.info(TAG, string.format("Applied from cache: %d entries", #cache))
            finishTask(); cb("applied"); return
        end

        -- ── Enable, no cache: full resolve ──────────────────────────────────────

        -- Step 1: AOB search
        gg.clearResults()
        gg.setRanges(BaseRegion)
        gg.searchNumber("h 22 63 6F 6C 6C 5F 63 6F 69 6E 5F 64 6F 75 62 6C 65 72 00 18", 1)
        gg.refineNumber("h 22", 1)
        local aobHits = gg.getResults(gg.getResultsCount())
        gg.clearResults()
        LOG.info(TAG, string.format("Step1: AOB hits=%d", #aobHits))

        if #aobHits == 0 then
            finishTask(); cb("resolve_failed"); return
        end

        -- Step 2: verify candidates (batched read of +0x18/+0x1C for all hits)
        local checkReads = {}
        for _, h in ipairs(aobHits) do
            checkReads[#checkReads + 1] = { address = h.address + 0x18, flags = 4 }
            checkReads[#checkReads + 1] = { address = h.address + 0x1C, flags = 4 }
        end
        local checkVals = gg.getValues(checkReads)

        local startAddrs = {}
        for i, h in ipairs(aobHits) do
            local v18 = checkVals[(i - 1) * 2 + 1]
            local v1C = checkVals[(i - 1) * 2 + 2]
            if v18 and v18.value == 8 and v1C and v1C.value == 0 then
                startAddrs[#startAddrs + 1] = h.address
            end
        end
        LOG.info(TAG, string.format("Step2: verified starts=%d", #startAddrs))

        if #startAddrs == 0 then
            finishTask(); cb("resolve_failed"); return
        end

        -- Step 3: pointer search for each confirmed start
        local ptrHits = {}
        for _, addr in ipairs(startAddrs) do
            gg.clearResults()
            gg.searchNumber(tostring(addr), 32)
            local hits = gg.getResults(gg.getResultsCount())
            gg.clearResults()
            for _, h in ipairs(hits) do
                ptrHits[#ptrHits + 1] = h.address
            end
        end
        LOG.info(TAG, string.format("Step3: pointer hits=%d", #ptrHits))

        if #ptrHits == 0 then
            finishTask(); cb("resolve_failed"); return
        end

        -- Step 4: verify each pointer hit (batched: read +0x8 ptr for all hits first)
        local ptrReads = {}
        for _, addr in ipairs(ptrHits) do
            ptrReads[#ptrReads + 1] = { address = addr + 0x8, flags = 32 }
        end
        local resolvedPtrs = gg.getValues(ptrReads)

        -- Batched second read: deref each resolved ptr's +0x0/+0x18/+0x1C
        local derefReads = {}
        for _, rp in ipairs(resolvedPtrs) do
            local ptr = rp and rp.value or 0
            derefReads[#derefReads + 1] = { address = ptr + 0x0,  flags = 4 }
            derefReads[#derefReads + 1] = { address = ptr + 0x18, flags = 4 }
            derefReads[#derefReads + 1] = { address = ptr + 0x1C, flags = 4 }
        end
        local derefVals = gg.getValues(derefReads)

        local walkStarts = {}
        for i, addr in ipairs(ptrHits) do
            local d0  = derefVals[(i - 1) * 3 + 1]
            local d18 = derefVals[(i - 1) * 3 + 2]
            local d1C = derefVals[(i - 1) * 3 + 3]
            if d0 and d0.value == 0x6C6F632A and d18 and d18.value == 80 and d1C and d1C.value == 0 then
                walkStarts[#walkStarts + 1] = addr
            end
        end
        LOG.info(TAG, string.format("Step4: validated walk-starts=%d", #walkStarts))

        if #walkStarts == 0 then
            finishTask(); cb("resolve_failed"); return
        end

        -- Step 5: walk each validated start, +0x8 stride, until sentinel
        local touched = {}   -- list of { ptr, orig18, orig1C }
        local SENTINEL = 0x79747318

        for _, startAddr in ipairs(walkStarts) do
            local cur = startAddr
            while true do
                local r = gg.getValues({{ address = cur, flags = 32 }})
                local ptr = r and r[1] and r[1].value or 0
                if ptr == 0 then break end

                local dv = gg.getValues({
                    { address = ptr + 0x0,  flags = 4 },
                    { address = ptr + 0x18, flags = 4 },
                    { address = ptr + 0x1C, flags = 4 },
                })
                local val0 = dv[1] and dv[1].value or 0
                local v18  = dv[2] and dv[2].value or 0
                local v1C  = dv[3] and dv[3].value or 0

                touched[#touched + 1] = { ptr = ptr, orig18 = v18, orig1C = v1C }

                if val0 == SENTINEL then
                    LOG.dbg(TAG, string.format("  sentinel hit at ptr=0x%X — stop", ptr))
                    break
                end
                cur = cur + 0x8
            end
        end

        LOG.info(TAG, string.format("Step5: touched %d entries total", #touched))

        if #touched == 0 then
            finishTask(); cb("resolve_failed"); return
        end

        -- Save originals BEFORE editing
        memory:save("free_adventure_shop", touched)

        local edits = {}
        for _, e in ipairs(touched) do
            edits[#edits + 1] = { address = e.ptr + 0x18, flags = 4, value = 0 }
            edits[#edits + 1] = { address = e.ptr + 0x1C, flags = 4, value = 0 }
        end
        gg.setValues(edits)

        LOG.info(TAG, string.format("Applied: %d entries", #touched))
        finishTask(); cb("applied")
    end)
end

return M
