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
                memory:save("set_distance_ptr", nil)
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

return M
