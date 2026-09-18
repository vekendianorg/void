--[[
  modules/ops/player.lua — Player feature memory ops (no UI)
  Contract: see modules/ops/README.md.

  Globals used: scheduler, storage, gg, BaseRegion, Nebula, LOG.
]]

local M = {}

-- No-clip toggle. status: "enabled" | "disabled"
function M.noClip(state, cb)
    scheduler:add(function(finishTask)
        local TAG = "NoClip"
        local cache = storage:load_session("no_clip")
        if cache then
            LOG.dbg(TAG, "Using cached results")
            gg.clearResults()
            gg.loadResults(cache)
            gg.getResults(gg.getResultsCount())
        else
            LOG.dbg(TAG, "No cache — scanning memory")
            gg.clearResults()
            gg.setRanges(8)
            gg.searchNumber("h 0A D7 23 3C 00 00 00 00 00 00 20 C1", 1)
            gg.refineNumber("h 0A D7 23 3C", 1)
            local results = gg.getResults(gg.getResultsCount())
            LOG.info(TAG, "Scan results: " .. tostring(#results))
            storage:save_session("no_clip", results)
        end
        if state then
            gg.editAll("h CD CC 08 C1", 1)
            LOG.info(TAG, "Enabled")
        else
            gg.editAll("h 0A D7 23 3C", 1)
            LOG.info(TAG, "Disabled")
        end
        gg.clearResults()
        finishTask()
        cb(state and "enabled" or "disabled")
    end)
end

-- Hide name toggle. status: "enabled" | "disabled"
function M.hideName(state, cb)
    scheduler:add(function(finishTask)
        local TAG = "HideName"
        local cache = storage:load_session("hide_name")
        if cache then
            LOG.dbg(TAG, "Using cached results")
            gg.clearResults()
            gg.loadResults(cache)
            gg.getResults(gg.getResultsCount())
        else
            LOG.dbg(TAG, "No cache — scanning memory")
            gg.clearResults()
            gg.setRanges(BaseRegion)
            gg.searchNumber("h BF 7D AD C1 64 CC 73 41 71 3D 0A 3F 71 3D 0A 3F", 1)
            gg.refineNumber("h 71 3D 0A 3F 71 3D 0A 3F", 1)
            local results = gg.getResults(gg.getResultsCount())
            LOG.info(TAG, "Scan results: " .. tostring(#results))
            storage:save_session("hide_name", results)
        end
        if state then
            gg.editAll("h 00 00 00 00 00 00 00 00", 1)
            LOG.info(TAG, "Enabled")
        else
            gg.editAll("h 71 3D 0A 3F 71 3D 0A 3F", 1)
            LOG.info(TAG, "Disabled")
        end
        gg.clearResults()
        finishTask()
        cb(state and "enabled" or "disabled")
    end)
end

-- Hide flag toggle (two-part scan). status: "enabled" | "disabled"
function M.hideFlag(state, cb)
    scheduler:add(function(finishTask)
        local TAG = "HideFlag"

        local cache = storage:load_session("hide_flag")
        if cache then
            LOG.dbg(TAG, "Using cached results (part 1)")
            gg.clearResults()
            gg.loadResults(cache)
            gg.getResults(gg.getResultsCount())
        else
            LOG.dbg(TAG, "No cache — scanning memory (part 1)")
            gg.clearResults()
            gg.setRanges(BaseRegion)
            gg.searchNumber("h 2E FF D7 C1 36 CD 73 41 00 00 80 3F 00 00 80 3F 00 00 00 3F 00 00 00 3F FF FF FF FF 00 00 08 42 00 00 C0 41", 1)
            gg.refineNumber("h 00 00 08 42 00 00 C0 41", 1)
            local results = gg.getResults(gg.getResultsCount())
            LOG.info(TAG, "Scan results (part 1): " .. tostring(#results))
            storage:save_session("hide_flag", results)
        end
        if state then
            gg.editAll("h 00 00 00 00 00 00 00 00", 1)
        else
            gg.editAll("h 00 00 08 42 00 00 C0 41", 1)
        end
        gg.clearResults()

        local cache2 = storage:load_session("hide_flag2")
        if cache2 then
            LOG.dbg(TAG, "Using cached results (part 2)")
            gg.clearResults()
            gg.loadResults(cache2)
            gg.getResults(gg.getResultsCount())
        else
            LOG.dbg(TAG, "No cache — scanning memory (part 2)")
            gg.clearResults()
            gg.setRanges(BaseRegion)
            gg.searchNumber("h 61 32 DB C1 02 9A 70 41 C8 07 5D 3F 63 EE 5A 3F 00 00 00 3F 00 00 00 3F FF FF FF FF 00 00 44 42 00 00 20 42", 1)
            gg.refineNumber("h FF FF FF FF", 1)
            local results = gg.getResults(gg.getResultsCount())
            LOG.info(TAG, "Scan results (part 2): " .. tostring(#results))
            storage:save_session("hide_flag2", results)
        end
        if state then
            gg.editAll("h 00 00 00 00", 1)
            LOG.info(TAG, "Enabled")
        else
            gg.editAll("h FF FF FF FF", 1)
            LOG.info(TAG, "Disabled")
        end
        gg.clearResults()

        finishTask()
        cb(state and "enabled" or "disabled")
    end)
end

---Toggle speed hack — searches REGION_CD for -1.13333332539 float,
---freezes it to -1.0 on enable, restores on disable.
---@param state boolean
---@param cb fun(ok, errKey|nil)
function M.setSpeedHack(state, cb)
    scheduler:add(function(finishTask)
        local TAG = "SpeedHack"
        local cache = storage:load_session("speed_hack")

        if state then
            if not cache then
                gg.clearResults()
                gg.setRanges(8)
                gg.searchNumber("-1.13333332539", gg.TYPE_FLOAT)
                local results = gg.getResults(gg.getResultsCount())
                gg.clearResults()
                LOG.info(TAG, string.format("Scan returned %d result(s)", #results))
                if #results == 0 then
                    finishTask(); cb(false, "player.speed_hack.not_found"); return
                end
                storage:save_session("speed_hack", results)
                cache = results
            else
                gg.clearResults()
                gg.loadResults(cache)
                gg.getResults(gg.getResultsCount())
            end
            gg.editAll("-1.0", gg.TYPE_FLOAT)
            gg.clearResults()
            LOG.info(TAG, string.format("Enabled on %d address(es)", #cache))
            finishTask(); cb(true)
        else
            if not cache then
                LOG.warn(TAG, "no cache to revert")
                finishTask(); cb(false, "player.speed_hack.no_cache"); return
            end
            gg.clearResults()
            gg.loadResults(cache)
            gg.getResults(gg.getResultsCount())
            gg.editAll("-1.13333332539", gg.TYPE_FLOAT)
            gg.clearResults()
            storage:delete_session("speed_hack")
            LOG.info(TAG, "Disabled — original value restored")
            finishTask(); cb(true)
        end
    end)
end

-- Adjust camera zoom (slider min/max). No user-facing message in the original.
-- status: "applied" | "none"
-- Adjust zoom (slider min/max). Nebula GameData camera visible range:
-- minVisibleRange (Float @0x1E4) and maxVisibleRange (Float @0x1E8).
-- vals = { minRange, maxRange }.
-- status: "applied" (data = {min, max}) | "nebula_unavailable" | "failed"
function M.setZoom(vals, cb)
    scheduler:add(function(finishTask)
        local TAG = "Zoom"
        if not (Nebula and Nebula.GameData) then
            finishTask(); cb("nebula_unavailable"); return
        end

        local minR = tonumber(vals and vals[1]) or 20
        local maxR = tonumber(vals and vals[2]) or 50
        if minR < 0 then minR = 0 end
        if maxR < minR then maxR = minR end

        -- Drop the old raw-scan cache if one is left over from a previous run.
        storage:delete_session("zoom")

        local ok, r, err = pcall(Nebula.GameData.set, "minVisibleRange", minR)
        if not ok or not r then
            LOG.error(TAG, "minVisibleRange write failed: " .. tostring(err or r))
            finishTask(); cb("failed", err or r); return
        end
        ok, r, err = pcall(Nebula.GameData.set, "maxVisibleRange", maxR)
        if not ok or not r then
            LOG.error(TAG, "maxVisibleRange write failed: " .. tostring(err or r))
            finishTask(); cb("failed", err or r); return
        end
        LOG.info(TAG, string.format("Zoom set — range %.1f-%.1f", minR, maxR))
        finishTask(); cb("applied", { minR, maxR })
    end)
end

function M.setGravity(vals, cb)
    scheduler:add(function(finishTask)
        local TAG = "Gravity"
        local allGravity = storage:load_session("gravity")

        if not allGravity then
            LOG.dbg(TAG, "No cache — running pointer walk scan")
            allGravity = { x = {}, y = {} }
            gg.clearResults()
            gg.setRanges(BaseRegion)
            gg.searchNumber("00000021h;00000000h;0000001Ah;00000000h;00000031h;00000000h;00000028h;00000000h;00000000h;00000017h;00000000h;756F4316h;7972746Eh;65646973h::81", 4)
            gg.refineNumber("00000021h", 4)

            local results = gg.getResults(gg.getResultsCount())
            gg.clearResults()
            LOG.dbg(TAG, "Initial scan hits: " .. tostring(#results))

            if #results > 0 then
                local toProcess = {}
                for _, v in ipairs(results) do
                    gg.searchNumber(v.address, 32)
                    local ptrResults = gg.getResults(gg.getResultsCount())
                    gg.clearResults()
                    for __, ptr in ipairs(ptrResults) do
                        local getPtr  = gg.getValues({{ address = ptr.address + 0x8, flags = 32 }})[1].value
                        local checkVal = gg.getValues({{ address = getPtr, flags = 4 }})[1].value
                        if checkVal == 0x74616E2A then
                            table.insert(toProcess, ptr.address)
                        end
                    end
                end
                LOG.dbg(TAG, "Validated base addresses: " .. tostring(#toProcess))

                for _, baseAddr in ipairs(toProcess) do
                    local currentAddr = baseAddr
                    while true do
                        local gravityPtr = gg.getValues({{ address = currentAddr, flags = 32 }})[1].value
                        if gravityPtr == 0 then break end
                        local region = gg.getValuesRange({{ address = gravityPtr, flags = 32 }})[1]
                        if region == "Ca" or region == "O" then
                            local check = gg.getValues({{ address = gravityPtr + 0x48, flags = 4 }})[1].value
                            if check ~= 0 then
                                table.insert(allGravity.x, {address = gravityPtr + 0x120, flags = 16})
                                table.insert(allGravity.y, {address = gravityPtr + 0x124, flags = 16})
                            else
                                break
                            end
                        else
                            break
                        end
                        currentAddr = currentAddr + 0x8
                    end
                end

                LOG.info(TAG, string.format("Gravity addresses found: %d", #allGravity.x))
                storage:save_session("gravity", allGravity)
            else
                LOG.warn(TAG, "Initial scan returned 0 results — gravity addresses not found")
            end
        else
            LOG.dbg(TAG, "Using cached gravity addresses: " .. tostring(#allGravity.x))
        end

        if #allGravity.x > 0 then
            for i = 1, #allGravity.x do
                allGravity.x[i].value = vals[1]
                allGravity.y[i].value = vals[2]
            end
            gg.setValues(allGravity.x)
            gg.setValues(allGravity.y)
            LOG.info(TAG, string.format("Gravity applied — X: %s Y: %s", tostring(vals[1]), tostring(vals[2])))
            finishTask(); cb("applied"); return
        else
            LOG.warn(TAG, "No gravity addresses to write to")
        end
        finishTask()
        cb("none")
    end)
end

return M
