--[[
  Cups Tab - Cup racing modes
  Features: Auto-win races
  
  @module callback Receives container View to populate with modules
]]

return function(container)
    local function t(key, ...) return T("cups." .. key, ...) end
    
    addModule(container, "adjust_countdown", t("adjust_countdown.title"), t("adjust_countdown.desc"), "slider",
    {title=t("slider.seconds"), min=0, max=10, current=3},
    function(done, vals)
        local countdownValue = vals

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
            
            showToast(t("adjust_countdown.applied", tostring(countdownValue)), true)
            LOG.info(TAG, "Done")
            gg.clearResults()
            finishTask()
            done()
        end)
    end)
    
    addArchModule(container, "auto_win", t("auto_win.title"), t("auto_win.desc"), "switch", nil, aobs.autoWin)
    
    addArchModule(container, "force_boss", t("force_boss.title"), t("force_boss.desc"), "switch", nil, aobs.forceBoss)
    
    addModule(container, "force_cup", t("force_cup.title"), t("force_cup.desc"), "switch", nil,
    function(done, state)
        local TAG = "ForceCup"

        scheduler:add(function(finishTask)
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
                        showToast(t("force_cup.not_found"))
                        LOG.error(TAG, "Pattern not found in memory.")
                        finishTask()
                        done()
                        return
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
                showToast(t("force_cup.enabled"))
                LOG.info(TAG, "Force Cup enabled. Items frozen.")

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

                showToast(t("force_cup.disabled"))
            end

            finishTask()
            done()
        end)
    end)
    
    addArchModule(container, "set_time", t("set_time.title"), t("set_time.desc"), "input", {
        {hint = t("set_time.hint"), type = "text"},
    }, function(done, vals)
        local TAG = "SetTime"
        LOG.info(TAG, "Module activated.")
    
        local function parseTime(str)
            str = str:match("^%s*(.-)%s*$")
            if str:find("-") then return nil, "no_negative" end
    
            if str:find(":") then
                local min, sec, ms = str:match("^(%d+):(%d+)%.(%d+)$")
                if not min then return nil, "invalid_format" end
                return tonumber(min) * 60 + tonumber(sec) + tonumber("0." .. ms), nil
            elseif str:find("%.") then
                local sec, ms = str:match("^(%d+)%.(%d+)$")
                if not sec then return nil, "invalid_format" end
                return tonumber(sec) + tonumber("0." .. ms), nil
            else
                local sec = tonumber(str)
                if not sec then return nil, "invalid_format" end
                return sec, nil
            end
        end
    
        local timeSeconds, err = parseTime(vals)
        if err == "no_negative" then
            showToast(t("set_time.no_negative"), true)
            done()
            return
        elseif err or not timeSeconds then
            showToast(t("set_time.invalid_format"), true)
            done()
            return
        end
    
        scheduler:add(function(finishTask)
            local activeTab = gg.getValues({{ address = BaseGameStatusRaw - 0xD4, flags = 4 }})
            local isCupTab = (type(activeTab) == "table" and activeTab[1] and activeTab[1].value == 1)
    
            if not isCupTab then
                showToast(t("set_time.not_in_cup"), true)
                finishTask()
                done()
                return
            end
    
            local function resolveBase()
                local cachedPtr = memory:load("set_time_ptr")
                if cachedPtr and cachedPtr ~= 0 then
                    local verify = gg.getValues({{ address = cachedPtr, flags = 32 }})
                    if verify and verify[1] and verify[1].value ~= 0 then
                        local base = verify[1].value
                        LOG.dbg(TAG, string.format("Cache hit: ptr=0x%X → base=0x%X", cachedPtr, base))
                        return base
                    else
                        LOG.warn(TAG, "ptr invalid — clearing cache")
                        memory:save("set_time_ptr", nil)
                    end
                end
    
                local anchorTarget = BaseLib + offsets.lib_setDistanceBase
                LOG.dbg(TAG, string.format("Resolving from scratch | anchor=0x%X", anchorTarget))
    
                gg.clearResults()
                gg.setRanges(BaseRegion)
                gg.searchNumber(anchorTarget, 32)
                local level1Results = gg.getResults(gg.getResultsCount())
                gg.clearResults()
    
                if #level1Results == 0 then
                    LOG.warn(TAG, "Level 1: no refs found")
                    return nil
                end
    
                local resolvedBase = nil
    
                for _, ref1 in ipairs(level1Results) do
                    gg.clearResults()
                    gg.setRanges(BaseRegion)
                    gg.searchNumber(ref1.address, 32)
                    local level2Results = gg.getResults(gg.getResultsCount())
                    gg.clearResults()
    
                    for _, ref2 in ipairs(level2Results) do
                        local offsetAddr = ref2.address - 0xAC
    
                        gg.clearResults()
                        gg.setRanges(gg.REGION_C_ALLOC)
                        gg.searchNumber(offsetAddr, 32)
                        local level3Results = gg.getResults(gg.getResultsCount())
                        gg.clearResults()
    
                        if #level3Results > 0 then
                            local pointerReads = {}
                            for _, ref3 in ipairs(level3Results) do
                                table.insert(pointerReads, { address = ref3.address, flags = 32 })
                            end
                            local resolvedPointers = gg.getValues(pointerReads)
                            if resolvedPointers then
                                for _, ptr in ipairs(resolvedPointers) do
                                    if ptr and ptr.value and ptr.value ~= 0 then
                                        memory:save("set_time_ptr", ptr.address)
                                        resolvedBase = ptr.value
                                        LOG.info(TAG, string.format("Resolved + cached: ptr=0x%X → base=0x%X", ptr.address, resolvedBase))
                                        break
                                    end
                                end
                            end
                        end
    
                        if resolvedBase then break end
                    end
    
                    if resolvedBase then break end
                end
    
                return resolvedBase
            end
    
            local base = resolveBase()
            if not base then
                showToast(t("set_time.start_race_first"), true)
                finishTask()
                done()
                return
            end
    
            gg.setValues({
                { address = base + 0x10, flags = 16, value = timeSeconds },
                { address = base + 0x14, flags = 16, value = timeSeconds },
            })
    
            LOG.info(TAG, "Time set: " .. tostring(timeSeconds) .. "s (" .. vals .. ")")
            showToast(t("set_time.applied", vals), true)
            gg.clearResults()
            finishTask()
            done()
        end)
    end)
    
    addModule(container, "unlimited_tasks", t("unlimited_tasks.title"), t("unlimited_tasks.desc"), "switch", nil,
    function(done, state)
        local TAG = "UnlimitedTasks"

        scheduler:add(function(finishTask)
            local ptr1 = gg.getValues({{ address = BaseGameStatus + 0x6F8, flags = 32 }})[1].value

            if not ptr1 or ptr1 == 0 then
                showToast(t("unlimited_tasks.resolve_failed"))
                LOG.fatal(TAG, "Ptr1 is nil or 0.")
                finishTask()
                done()
                return
            end

            local totalTasks = gg.getValues({{ address = BaseGameStatus + 0x700, flags = 4 }})[1].value

            if not totalTasks or totalTasks == 0 then
                showToast(t("unlimited_tasks.none_found"))
                LOG.warn(TAG, "totalTasks is 0.")
                finishTask()
                done()
                return
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
                    showToast(t("unlimited_tasks.enabled"))
                    LOG.info(TAG, "Enabled. Frozen " .. tostring(#freezeItems / 3) .. " tasks.")
                else
                    gg.removeListItems(freezeItems)
                    showToast(t("unlimited_tasks.disabled"))
                    LOG.info(TAG, "Disabled. Unfrozen " .. tostring(#freezeItems / 3) .. " tasks.")
                end
            else
                showToast(t("unlimited_tasks.none_to_freeze"))
                LOG.warn(TAG, "freezeItems is empty.")
            end

            finishTask()
            done()
        end)
    end)
    
    addModule(container, "rank_points_bonus", t("rank_points_bonus.title"), t("rank_points_bonus.desc"), "switch", nil,
    function(done, state)
        local TAG = "RankPointsBonus"
        LOG.info(TAG, "Module activated. state=" .. tostring(state))

        scheduler:add(function(finishTask)
            if state then
                gg.clearResults()
                gg.setRanges(BaseRegion)
                gg.searchNumber("h 1C 4C 65 61 67 75 65 54", 1)
                gg.refineNumber("h 1C", 1)
                local results = gg.getResults(gg.getResultsCount())
                gg.clearResults()

                if #results == 0 then
                    showToast(t("rank_points_bonus.none_found"))
                    LOG.warn(TAG, "Anchor search returned 0 results.")
                    finishTask()
                    done()
                    return
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
                    showToast(t("rank_points_bonus.boosted", tostring(successCount)))
                else
                    showToast(t("rank_points_bonus.no_match"))
                end
            else
                -- DISABLE: restore original values from saved data
                local saved = memory:load("rank_points_bonus")

                if not saved or #saved == 0 then
                    LOG.warn(TAG, "No saved data to restore.")
                    showToast(t("rank_points_bonus.nothing_to_restore"))
                    finishTask()
                    done()
                    return
                end

                local restoreCount = 0

                for idx, entry in ipairs(saved) do
                    local edits = {}
                    
                    table.insert(edits, { address = entry.base + 0x1C, flags = 4, value = entry.values[i] })
                    
                    gg.setValues(edits)
                    restoreCount = restoreCount + 1
                end

                memory:save("rank_points_bonus", {})
                LOG.info(TAG, "Restored: " .. tostring(restoreCount))
                showToast(t("rank_points_bonus.restored", tostring(restoreCount)))
            end

            finishTask()
            done()
        end)
    end)
end
