--[[
  modules/ops/cups.lua — Cups feature memory ops (no UI)
  Contract: see modules/ops/README.md.

  Globals used: scheduler, memory, gg, cast, BaseRegion, BaseGameStatus,
  BaseGameStatusRaw, BaseLib, offsets, LOG.
]]

local raceinfo = loadModule("modules/lib/raceinfo.lua")

local M = {}

-- Quick synchronous read: is the game on the Cups tab? (activeTab == 1)
local function isCupTab()
    local activeTab = gg.getValues({{ address = BaseGameStatusRaw - 0xD4, flags = 4 }})
    return type(activeTab) == "table" and activeTab[1] ~= nil and activeTab[1].value == 1
end

-- Adjust race countdown. status: "applied"
function M.adjustCountdown(countdownValue, cb)
    scheduler:add(function(finishTask)
        local TAG = "AdjustCountdown"
        LOG.info(TAG, "Adjusting countdown to: " .. tostring(countdownValue) .. "s")
        local cache = memory:load("adjust_countdown")

        if cache and #cache > 0 then
            LOG.dbg(TAG, "Using cached results")
            gg.clearResults()
            gg.loadResults(cache)
            gg.getResults(gg.getResultsCount())
        else
            LOG.dbg(TAG, "No cache — scanning memory")
            gg.clearResults()
            gg.setRanges(16)
            gg.searchNumber("h 00 00 40 40 00 00 80 40 00 00 40 41", 1)
            gg.refineNumber("h 00 00 40 40", 1)
            local results = gg.getResults(gg.getResultsCount())
            LOG.info(TAG, "Scan results: " .. tostring(#results))
            memory:save("adjust_countdown", results)
        end

        gg.editAll(cast.float(countdownValue), 1)
        LOG.info(TAG, "Done")
        gg.clearResults()
        finishTask()
        cb("applied")
    end)
end

-- Force cup toggle (freeze/unfreeze list items).
-- status: "enabled" | "not_found" | "disabled"
function M.forceCup(state, cb)
    scheduler:add(function(finishTask)
        local TAG = "ForceCup"
        if state then
            LOG.info(TAG, "Enabling Force Cup...")

            local cache = memory:load("force_cup_cache")

            -- Verify cache is still valid
            if cache then
                LOG.dbg(TAG, string.format("Cache found. Verifying base address: 0x%X", cache.base))
                local verify = gg.getValues({{ address = cache.base, flags = 1 }})
                if not verify or not verify[1] or verify[1].value ~= 0xB8 then
                    LOG.warn(TAG, "Base address moved. Invalidating cache and re-searching...")
                    cache = nil
                    memory:delete("force_cup_cache")
                else
                    LOG.dbg(TAG, "Base address valid. Using cache.")
                end
            end

            -- Search if no cache
            if not cache then
                LOG.dbg(TAG, "No cache. Executing pattern search...")
                gg.clearResults()
                gg.setRanges(BaseRegion)
                gg.searchNumber("h B8 1E 85 3F CD CC 4C 3F", 1)

                local results = gg.getResults(10)
                gg.clearResults()

                if #results == 0 then
                    LOG.error(TAG, "Pattern not found in memory.")
                    finishTask(); cb("not_found"); return
                end

                local base = results[1].address
                LOG.info(TAG, string.format("Pattern found at: 0x%X", base))

                cache = {
                    base = base,
                    items = {
                        { address = base - 0x308, flags = 4, value = 1953063706 },
                        { address = base - 0x304, flags = 4, value = 1869373305 },
                        { address = base - 0x300, flags = 4, value = 1667196782 },
                        { address = base - 0x2FC, flags = 4, value = 28789     },
                        { address = base - 0x2F8, flags = 4, value = 0         },
                    }
                }

                memory:save("force_cup_cache", cache)
                LOG.info(TAG, "Cache saved.")
            end

            -- Freeze
            local freezeItems = {}
            for _, item in ipairs(cache.items) do
                table.insert(freezeItems, {
                    address = item.address,
                    flags   = item.flags,
                    value   = item.value,
                    freeze  = true
                })
            end

            gg.addListItems(freezeItems)
            LOG.info(TAG, "Force Cup enabled. Items frozen.")
            finishTask(); cb("enabled"); return
        else
            LOG.info(TAG, "Disabling Force Cup...")

            local cache = memory:load("force_cup_cache")

            if cache then
                local unfreezeItems = {}
                for _, item in ipairs(cache.items) do
                    table.insert(unfreezeItems, {
                        address = item.address,
                        flags   = item.flags,
                        value   = item.value,
                        freeze  = false
                    })
                end

                gg.removeListItems(unfreezeItems)
                LOG.info(TAG, "Force Cup disabled. Items unfrozen.")
            else
                LOG.warn(TAG, "No cache found on disable. Nothing to unfreeze.")
            end

            finishTask(); cb("disabled"); return
        end
    end)
end

-- Force the frenzy mode toggle
-- status: "enabled" | "not_found" | "disabled"
function M.forceFrenzyMode(state, cb)
    scheduler:add(function(finishTask)
        local TAG = "ForceFrenzyMode"
        if state then
            LOG.info(TAG, "Enabling Force Frenzy Mode...")
            
            -- it use the same cache as force cup
            local cache = memory:load("force_cup_cache")

            -- Verify cache is still valid
            if cache then
                LOG.dbg(TAG, string.format("Cache found. Verifying base address: 0x%X", cache.base))
                local verify = gg.getValues({{ address = cache.base, flags = 1 }})
                if not verify or not verify[1] or verify[1].value ~= 0xB8 then
                    LOG.warn(TAG, "Base address moved. Invalidating cache and re-searching...")
                    cache = nil
                    memory:delete("force_cup_cache")
                else
                    LOG.dbg(TAG, "Base address valid. Using cache.")
                end
            end

            -- Search if no cache
            if not cache then
                LOG.dbg(TAG, "No cache. Executing pattern search...")
                gg.clearResults()
                gg.setRanges(BaseRegion)
                gg.searchNumber("h B8 1E 85 3F CD CC 4C 3F", 1)

                local results = gg.getResults(10)
                gg.clearResults()
                
                gg.searchNumber(":&default_bonus_level", 1)

                local frenzyAddr = gg.getResults(10)
                gg.clearResults()

                if #results == 0 then
                    LOG.error(TAG, "Pattern not found in memory.")
                    finishTask(); cb("not_found"); return
                end
                
                if #frenzyAddr == 0 then
                    LOG.error(TAG, "Frenzy address not found in memory.")
                    finishTask(); cb("not_found"); return
                end

                local base = results[1].address
                local frenzyPtr = frenzyAddr[1].address
                LOG.info(TAG, string.format("Pattern found at: 0x%X", base))

                cache = {
                    base = base,
                    items = {
                        { address = base - 0x2B8, flags = 32, value = frenzyPtr }
                    }
                }

                memory:save("force_cup_cache", cache)
                LOG.info(TAG, "Cache saved.")
            end

            -- Freeze
            local freezeItems = {}
            for _, item in ipairs(cache.items) do
                table.insert(freezeItems, {
                    address = item.address,
                    flags   = item.flags,
                    value   = item.value,
                    freeze  = true
                })
            end

            gg.addListItems(freezeItems)
            LOG.info(TAG, "Force Frenzy Mode enabled. Items frozen.")
            finishTask(); cb("enabled"); return
        else
            LOG.info(TAG, "Disabling Frenzy Mode...")

            local cache = memory:load("force_cup_cache")

            if cache then
                local unfreezeItems = {}
                for _, item in ipairs(cache.items) do
                    table.insert(unfreezeItems, {
                        address = item.address,
                        flags   = item.flags,
                        value   = 0,
                        freeze  = false
                    })
                end

                gg.removeListItems(unfreezeItems)
                LOG.info(TAG, "Force Frozen Mode disabled. Items unfrozen.")
            else
                LOG.warn(TAG, "No cache found on disable. Nothing to unfreeze.")
            end

            finishTask(); cb("disabled"); return
        end
    end)
end

-- Set race time. `timeSeconds` is the pre-parsed numeric time (parsing/validation
-- of the user string is done in the tab).
-- status: "not_in_cup" | "start_race_first" | "applied"
function M.setTime(timeSeconds, cb)
    scheduler:add(function(finishTask)
        local TAG = "SetTime"

        if not isCupTab() then
            finishTask(); cb("not_in_cup"); return
        end

        -- Cups set-time has no "in race" precondition beyond a live pointer,
        -- so no validator is passed.
        local base = raceinfo.resolve("set_time_ptr")
        if not base then
            finishTask(); cb("start_race_first"); return
        end

        gg.setValues({
            { address = base + 0x10, flags = 16, value = timeSeconds },
            { address = base + 0x14, flags = 16, value = timeSeconds },
        })

        LOG.info(TAG, "Time set: " .. tostring(timeSeconds) .. "s")
        gg.clearResults()
        finishTask()
        cb("applied")
    end)
end

-- Unlimited tasks toggle. status: "resolve_failed" | "none_found" |
-- "none_to_freeze" | "enabled" | "disabled"
function M.unlimitedTasks(state, cb)
    scheduler:add(function(finishTask)
        local TAG = "UnlimitedTasks"
        local ptr1 = gg.getValues({{ address = BaseGameStatus + 0x6F8, flags = 32 }})[1].value

        if not ptr1 or ptr1 == 0 then
            LOG.fatal(TAG, "Ptr1 is nil or 0.")
            finishTask(); cb("resolve_failed"); return
        end

        local totalTasks = gg.getValues({{ address = BaseGameStatus + 0x700, flags = 4 }})[1].value

        if not totalTasks or totalTasks == 0 then
            LOG.warn(TAG, "totalTasks is 0.")
            finishTask(); cb("none_found"); return
        end

        LOG.dbg(TAG, "Total tasks: " .. tostring(totalTasks))

        local freezeItems = {}

        for i = 0, totalTasks - 1 do
            local ptr2 = gg.getValues({{ address = ptr1 + i * 8, flags = 32 }})[1].value

            if ptr2 and ptr2 ~= 0 then
                local completeTarget = gg.getValues({{ address = ptr2 + 0x1C, flags = 4 }})[1].value

                if completeTarget and completeTarget > 0 then
                    table.insert(freezeItems, { address = ptr2 + 0x1C, flags = 4, value = completeTarget, freeze = state })
                    table.insert(freezeItems, { address = ptr2 + 0x20, flags = 4, value = completeTarget, freeze = state })
                    table.insert(freezeItems, { address = ptr2 + 0x24, flags = 4, value = 0,             freeze = state })
                    LOG.dbg(TAG, string.format("Task [%d] queued. completeTarget: %d", i, completeTarget))
                end
            end
        end

        if #freezeItems > 0 then
            if state then
                gg.addListItems(freezeItems)
                LOG.info(TAG, "Enabled. Frozen " .. tostring(#freezeItems / 3) .. " tasks.")
                finishTask(); cb("enabled"); return
            else
                gg.removeListItems(freezeItems)
                LOG.info(TAG, "Disabled. Unfrozen " .. tostring(#freezeItems / 3) .. " tasks.")
                finishTask(); cb("disabled"); return
            end
        else
            LOG.warn(TAG, "freezeItems is empty.")
            finishTask(); cb("none_to_freeze"); return
        end
    end)
end

-- Rank points bonus toggle.
-- status (enable):  "none_found" | "boosted" (data=count) | "no_match"
-- status (disable): "nothing_to_restore" | "restored" (data=count)
function M.rankPointsBonus(state, cb)
    scheduler:add(function(finishTask)
        local TAG = "RankPointsBonus"
        LOG.info(TAG, "Module activated. state=" .. tostring(state))

        if state then
            gg.clearResults()
            gg.setRanges(BaseRegion)
            gg.searchNumber("h 1C 4C 65 61 67 75 65 54", 1)
            gg.refineNumber("h 1C", 1)
            local results = gg.getResults(gg.getResultsCount())
            gg.clearResults()

            if #results == 0 then
                LOG.warn(TAG, "Anchor search returned 0 results.")
                finishTask(); cb("none_found"); return
            end

            LOG.dbg(TAG, "Anchor results: " .. tostring(#results))

            local saved = {}
            local successCount = 0

            for idx, result in ipairs(results) do
                local check = gg.getValues({{ address = result.address + 0x1C, flags = 4 }})

                if not check or not check[1] then
                    LOG.warn(TAG, string.format("result[%d] check read failed", idx))
                    goto continueResult
                end

                if check[1].value ~= 0x3E4CCCCD then
                    LOG.dbg(TAG, string.format("result[%d] +0x1C = 0x%X, not 0.2, skipping", idx, check[1].value))
                    goto continueResult
                end

                local readAddrs = {}
                table.insert(readAddrs, { address = result.address + 0x1C, flags = 4 })

                local original = gg.getValues(readAddrs)

                local values = {}
                for i, v in ipairs(original) do
                    values[i] = v.value
                end
                table.insert(saved, { base = result.address, values = values })

                local edits = {
                    { address = result.address + 0x1C, flags = 16, value = 0.498 }
                }

                gg.setValues(edits)

                successCount = successCount + 1

                ::continueResult::
            end

            memory:save("rank_points_bonus", saved)
            LOG.info(TAG, "Done. Patched: " .. tostring(successCount))

            if successCount > 0 then
                finishTask(); cb("boosted", successCount); return
            else
                finishTask(); cb("no_match"); return
            end
        else
            -- DISABLE: restore original values from saved data
            local saved = memory:load("rank_points_bonus")

            if not saved or #saved == 0 then
                LOG.warn(TAG, "No saved data to restore.")
                finishTask(); cb("nothing_to_restore"); return
            end

            local restoreCount = 0

            for idx, entry in ipairs(saved) do
                local edits = {}

                -- FIX: was entry.values[i] (i undefined). The saved read holds a
                -- single value at index 1.
                table.insert(edits, { address = entry.base + 0x1C, flags = 4, value = entry.values[1] })

                gg.setValues(edits)
                restoreCount = restoreCount + 1
            end

            memory:save("rank_points_bonus", {})
            LOG.info(TAG, "Restored: " .. tostring(restoreCount))
            finishTask(); cb("restored", restoreCount); return
        end
    end)
end

return M
