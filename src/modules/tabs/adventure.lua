--[[
  Adventure Tab - Adventure mode features
  Status: Set Distance 
  
  @module callback Receives container View to populate with modules
]]

return function(container)
    local function t(key, ...) return T("adventure." .. key, ...) end

    addModule(container, "auto_adventure_chests", t("auto_adventure_chests.title"), t("auto_adventure_chests.desc"), "button", nil,
    function(done)
        local TAG = "AutoAdventureChests"
        LOG.info(TAG, "Module activated.")

        scheduler:add(function(finishTask)
            gg.clearResults()
            gg.setRanges(BaseRegion)
            gg.searchNumber("500;500::5", 4)
            local res = gg.getResults(gg.getResultsCount())

            if #res == 0 then
                showToast(t("auto_adventure_chests.none_found"))
                LOG.warn(TAG, "Search returned 0 results.")
                finishTask()
                done()
                return
            end

            LOG.dbg(TAG, "Results found: " .. tostring(count))

            gg.editAll("-1", 4)
            gg.clearResults()

            LOG.info(TAG, "Done.")
            showToast(t("auto_adventure_chests.done"))

            finishTask()
            done()
        end)
    end)
    
    addArchModule(container, "set_distance", t("set_distance.title"), t("set_distance.desc"), "button", nil,
    function(done)
        local TAG = "SetDistance"
        LOG.info(TAG, "Module activated.")
        
        if memory:load("set_distance_loop") then
            local action = showDialog(
                t("set_distance.loop_active_title"),
                t("set_distance.loop_active_msg"),
                {t("set_distance.stop_loop")}, {t("set_distance.keep_running")}
            )
            if action == 1 then
                memory:save("set_distance_loop", false)
                showToast(t("set_distance.loop_will_stop"))
            end
            done()
            return
        end

        local result = showPrompt(t("set_distance.title"), {
            {t("set_distance.prompt_target"), "number", "5000"},
            {t("set_distance.prompt_loop"),     "switch",  "false"},
            {t("set_distance.prompt_interval"), "number", "1500"},
        })

        if not result then
            done()
            return
        end

        local target_meters = tonumber(result[1]) or 5000
        local loop_enabled  = result[2] == "true"
        local loop_interval = math.max(250, tonumber(result[3]) or 1000)

        -- Warn if > 5000m — no stars, but race still counts distance
        if target_meters > 5000 then
            local warn = showDialog(
                t("set_distance.over_max_title"),
                t("set_distance.over_max_msg"),
                {t("set_distance.continue_button")}, {T("common.cancel")}
            )
            if warn ~= 1 then
                done()
                return
            end
        end

        local function isValidDistanceBase(addr)
            local check = gg.getValues({
                { address = addr + 0x0,  flags = 4  }, -- current distance (DWORD, should be >= 0)
                { address = addr + 0x10, flags = 16 }, -- float, should be a valid float
                { address = addr + 0x14, flags = 16 }, -- float, should be a valid float
            })
            if not check or #check ~= 3 then return false end
            
            local dist  = check[1].value
            local float1 = check[2].value
            local float2 = check[3].value
        
            -- Distance should be a reasonable value (0 to 999999)
            if type(dist) ~= "number" or dist < 0 or dist > 999999 then return false end
            -- Floats should be non-zero valid numbers (in an active race these are set)
            if type(float1) ~= "number" or float1 == 0 then return false end
            if type(float2) ~= "number" or float2 == 0 then return false end
        
            return true
        end
        
        local function resolveDistanceBase()
            local cachedPtr = memory:load("set_distance_ptr")
            if cachedPtr and cachedPtr ~= 0 then
                local verify = gg.getValues({{ address = cachedPtr, flags = 32 }})
                if verify and verify[1] and verify[1].value ~= 0 then
                    local distanceBase = verify[1].value
                    if isValidDistanceBase(distanceBase) then
                        LOG.dbg(TAG, string.format("Cache hit + valid: ptr=0x%X → distanceBase=0x%X", cachedPtr, distanceBase))
                        return distanceBase
                    else
                        -- Not in race — keep cache, just return nil
                        LOG.warn(TAG, "Not in race — cache kept for next run.")
                        return nil
                    end
                else
                    -- ptr.address itself gone — game restarted, clear cache
                    LOG.warn(TAG, "ptr.address invalid — clearing cache.")
                    memory:save("set_distance_ptr", nil)
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

            local distanceBase = nil

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
                                    memory:save("set_distance_ptr", ptr.address)
                                    distanceBase = ptr.value
                                    LOG.info(TAG, string.format("Resolved + cached: ptr=0x%X → distanceBase=0x%X",
                                        ptr.address, distanceBase))
                                    break
                                end
                            end
                        end
                    end

                    if distanceBase then break end
                end

                if distanceBase then break end
            end

            return distanceBase
        end

        local function apply()
            local activeTab = gg.getValues({{ address = BaseGameStatusRaw - 0xD4, flags = 4 }})
            local isAdventureTab = (type(activeTab) == "table" and activeTab[1] and activeTab[1].value == 0)

            if not isAdventureTab then
                LOG.warn(TAG, "Not in Adventure tab.")
                showToast(t("set_distance.not_in_adventure"))
                return false
            end

            local distanceBase = resolveDistanceBase()
            if not distanceBase then
                LOG.fatal(TAG, "Failed to resolve distanceBase.")
                showToast(t("set_distance.start_race_first"))
                return false
            end

            gg.setValues({
                { address = distanceBase + 0x0,  flags = 4,  value = target_meters },
                { address = distanceBase + 0x10, flags = 16, value = 2000000000 },
                { address = distanceBase + 0x14, flags = 16, value = 2000000000 },
            })

            LOG.info(TAG, "Distance set: " .. tostring(target_meters) .. "m")
            return true
        end

        scheduler:add(function(finishTask)
            local ok = apply()

            if not ok then
                finishTask()
                done() -- no deadlock — always exits
                return
            end

            showToast(t("set_distance.applied", tostring(target_meters)))

            if not loop_enabled then
                finishTask()
                done()
                return
            end

            -- Loop mode — call done() immediately so button stays clickable
            memory:save("set_distance_loop", true)
            finishTask()
            done() -- ← released here, no deadlock

            local tickCount = 0
            local function loopTick()
                if not memory:load("set_distance_loop") then
                    LOG.info(TAG, "Loop stopped.")
                    showToast(t("set_distance.loop_stopped"))
                    memory:save("set_distance_ptr", nil) -- clear cache on stop
                    return
                end

                gg.sleep(loop_interval)
                tickCount = tickCount + 1

                apply()

                -- Reminder every 2 ticks
                if tickCount % 2 == 0 then
                    showToast(t("set_distance.loop_running"), true)
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
    end)
end