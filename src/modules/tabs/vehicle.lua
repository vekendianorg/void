--[[
  Vehicle Tab - Vehicle modifications
  Features: Max Vehicles, Max Mastery, Max Parts
  
  @module callback Receives container View to populate with modules
]]

-- Part name → max upgrade level. Defined at module scope so it is
-- built once on first tab load, not rebuilt on every render call.
local PART_MAX_LEVEL = {
    start_boost           = 10,
    perfect_landing_boost = 7,
    jump                  = 10,
    wheelie_boost         = 10,
    afterburner           = 7,
    fume_boost            = 10,
    thrusters             = 4,
    glide                 = 15,
    fuel_boost            = 4,
    coin_boost            = 4,
    winter_tyres          = 15,
    magnet                = 15,
    spoiler               = 7,
    turbo_boost           = 7,
    flip_speed_boost      = 10,
    nitro                 = 4,
    air_control           = 15,
    heavyweight           = 15,
    rollcage              = 15,
    echo                  = 3,
    amplifier             = 3,
}

return function(container)
    local function t(key, ...) return T("vehicle." .. key, ...) end

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
    
    addModule(container, "parts_slot", t("parts_slot.title"), t("parts_slot.desc"), "slider",
    {title=t("parts_slot.slider_title"), min=1, max=15, current=3},
    function(done, vals)
        local slot = vals
        local TAG = "PartsSlot"
        LOG.info(TAG, "Slot: " .. tostring(slot))

        scheduler:add(function(finishTask)
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
                    showToast(t("common.no_vehicles"))
                    finishTask()
                    done()
                    return
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
                showToast(t("common.no_zero_region"))
                finishTask()
                done()
                return
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
                showToast(t("parts_slot.applied", count))
                LOG.info(TAG, "Done. Edits: " .. tostring(#edits) .. " (" .. tostring(count) .. " vehicles)")
            else
                showToast(t("common.no_vehicles"))
            end

            finishTask()
            done()
        end)
    end)
    
    addArchModule(container, "parts_modifier", t("parts_modifier.title"), t("parts_modifier.desc"), "button", nil,
    function(done)
        local TAG = "PartsModifier"
    
        -- Build groups from tuning_parts JSON
        local tuningData = json.decode(loadModule("configs/tuning_parts.lua"))
        local tp = tuningData.tuningParts
    
        local skip = { ECHO = true, ["COIN MAGNET"] = true, ["FUEL MAGNET"] = true }
    
        local groupMap = {}
        local groupOrder = {}
    
        for key, part in pairs(tp) do
            local label = part.name and part.name.value or key
            if not skip[label] then
                local fromVal, toVal = nil, nil
    
                for _, e in ipairs(part.effectStats or {}) do
                    local stat = e.stat
                    if type(stat) == "table" and stat["from"] ~= nil then
                        fromVal, toVal = stat["from"], stat["to"]
                        break
                    end
                end
                if fromVal == nil then
                    for _, e in ipairs(part.effects or {}) do
                        local amt = e.amount
                        if type(amt) == "table" and amt["from"] ~= nil then
                            fromVal, toVal = amt["from"], amt["to"]
                            break
                        end
                    end
                end
    
                if fromVal ~= nil then
                    if not groupMap[label] then
                        groupMap[label] = {}
                        table.insert(groupOrder, label)
                    end
                    table.insert(groupMap[label], { key = key, fromVal = fromVal, toVal = toVal })
                end
            end
        end
    
        table.sort(groupOrder)
    
        local choice = showList(t("parts_modifier.title"), t("parts_modifier.select"), groupOrder)
        if not choice or choice == 0 then done() return end
    
        local label    = groupOrder[choice]
        local variants = groupMap[label]
        local cacheKey = "parts_mod_" .. label:lower():gsub(" ", "_")
    
        local result = showPrompt(label, {
            {t("parts_modifier.prompt_level"),  "slider:1:9",},
            {t("parts_modifier.prompt_digit0"), "slider:0:9",},
            {t("parts_modifier.prompt_digit1"), "slider:1:9",},
            {t("parts_modifier.prompt_reset"),  "checkbox", "false"},
        })
    
        if not result then done() return end
    
        local reset    = result[4] == "true"
        local lvl      = tonumber(result[1]) or 2
        local digit0   = result[2] or "0"
        local digit1   = result[3] or "3"
    
        -- Build level string e.g. lvl=2, d0=0, d1=3 → "1.03"
        local power = ""
        for i = 0, lvl - 2 do power = power .. tostring(digit0) end
        local userEdits = "1." .. power .. tostring(digit1)
        local editValue = tonumber(userEdits)
    
        if not reset and not editValue then
            showToast(t("parts_modifier.invalid"), true)
            done()
            return
        end
    
        scheduler:add(function(finishTask)
            local cache = memory:load(cacheKey)
    
            if not cache then
                LOG.dbg(TAG, "Scanning variants for: " .. label)
                local toEdit = {}
    
                gg.setRanges(BaseRegion)
    
                for _, variant in ipairs(variants) do
                    local search1 = variant.fromVal
                    local search2 = variant.toVal
                    
                    gg.clearResults()
                    gg.searchNumber(BaseLib + offsets.vnpStats, 32)
                    local refs = gg.getResults(gg.getResultsCount())
                    gg.clearResults()
    
                    for _, v in ipairs(refs) do
                        local vals = gg.getValues({
                            { address = v.address + 0x8,  flags = 4 },
                            { address = v.address + 0xC,  flags = 16 },
                            { address = v.address + 0x10, flags = 16 },
                        })
                        if vals
                            and vals[1].value == 0x40000000
                            and vals[2].value == search1
                            and vals[3].value == search2
                        then
                            table.insert(toEdit, v.address + 0x8)
                            LOG.dbg(TAG, string.format("Found %s @ 0x%X", variant.key, v.address + 0x8))
                        end
                    end
                end
    
                gg.clearResults()
                
                if #toEdit == 0 then
                    showToast(t("parts_modifier.not_found"), true)
                    LOG.warn(TAG, "No results for: " .. label)
                    finishTask()
                    done()
                    return
                end
    
                memory:save(cacheKey, toEdit)
                cache = toEdit
                LOG.info(TAG, "Cached " .. #toEdit .. " addresses for " .. label)
            else
                LOG.dbg(TAG, "Cache hit for: " .. label)
            end
    
            local edits = {}
            for _, addr in ipairs(cache) do
                table.insert(edits, {
                    address = addr,
                    flags   = 16,
                    value   = reset and 0x40000000 or editValue
                })
            end
            gg.setValues(edits)
    
            if reset then
                memory:save(cacheKey, nil)
                showToast(t("parts_modifier.reset", label), true)
                LOG.info(TAG, "Reset: " .. label)
            else
                showToast(t("parts_modifier.applied", label, userEdits), true)
                LOG.info(TAG, label .. " = " .. userEdits)
            end
    
            gg.clearResults()
            finishTask()
            done()
        end)
    end)
    
    addModule(container, "unlock_vehicles", t("unlock_vehicles.title"), t("unlock_vehicles.desc"), "button", nil,
    function(done)
        local TAG = "UnlockVehicles"
        LOG.info(TAG, "Module activated.")
        scheduler:add(function(finishTask)
            local vehiclePtrs = resolveVehicleList()
            if not vehiclePtrs then
                showToast(t("common.no_vehicles"))
                finishTask()
                done()
                return
            end

            -- Collect all edits first, one setValues at end
            local edits = {}
            forEachVehicle(vehiclePtrs, function(vehiclePtr, deepPtr, deepPtrAddr)
                table.insert(edits, { address = vehiclePtr + 0x110, flags = 4, value = 1 })
                for off = 0x114, 0x14C, 4 do
                    table.insert(edits, { address = vehiclePtr + off, flags = 4, value = 0 })
                end
            end)
            if #edits > 0 then gg.setValues(edits) end

            showToast(successCount > 0 and t("unlock_vehicles.unlocked", successCount) or t("unlock_vehicles.none_to_unlock"))
            LOG.info(TAG, "Done. Success: " .. tostring(successCount))
            finishTask()
            done()
        end)
    end)

    addModule(container, "max_vehicles", t("max_vehicles.title"), t("max_vehicles.desc"), "button", nil,
    function(done)
        local TAG = "MaxVehicles"
        LOG.info(TAG, "Module activated.")

        scheduler:add(function(finishTask)
            local vehicleListPtr = gg.getValues({{ address = BaseGameStatus + 0xB8, flags = 32 }})[1].value
            local totalVehicles  = gg.getValues({{ address = BaseGameStatus + 0xC0, flags = 4  }})[1].value

            if not vehicleListPtr or vehicleListPtr == 0 then
                showToast(t("max_vehicles.no_vehicles"))
                LOG.fatal(TAG, "vehicleListPtr is nil or 0.")
                finishTask(); done(); return
            end

            LOG.dbg(TAG, "Total vehicles: " .. tostring(totalVehicles))

            local upgradeList = {}

            for i = 0, totalVehicles - 1 do
                local vehiclePtr = gg.getValues({{ address = vehicleListPtr + i * 8, flags = 32 }})[1].value
                if vehiclePtr and vehiclePtr ~= 0 then
                    local namePtr     = gg.getValues({{ address = vehiclePtr + 0x18, flags = 32 }})[1].value
                    local vehicleName = (namePtr and namePtr ~= 0) and readString(namePtr + 1) or "unknown"
                    local upgradeSlots = vehicleName:find("lowrider") and 5 or 4

                    local upgradeListPtr = gg.getValues({{ address = vehiclePtr + 0x20, flags = 32 }})[1].value
                    if upgradeListPtr and upgradeListPtr ~= 0 then
                        for j = 0, upgradeSlots - 1 do
                            local upgradePtr = gg.getValues({{ address = upgradeListPtr + j * 8, flags = 32 }})[1].value
                            if upgradePtr and upgradePtr ~= 0 then
                                table.insert(upgradeList, { address = upgradePtr + 0x20, flags = 4, value = 19 })
                                table.insert(upgradeList, { address = upgradePtr + 0x24, flags = 4, value = 19 })
                            end
                        end
                        LOG.dbg(TAG, "[" .. vehicleName .. "] queued " .. tostring(upgradeSlots) .. " upgrade slots.")
                    end
                end
                showToast(t("common.progress", i+1, totalVehicles), true)
            end

            if #upgradeList > 0 then
                gg.setValues(upgradeList)
                showToast(t("max_vehicles.all_maxed"))
                LOG.info(TAG, "Done. Total writes: " .. tostring(#upgradeList))
            else
                showToast(t("max_vehicles.failed"))
                LOG.warn(TAG, "upgradeList is empty.")
            end

            finishTask()
            done()
        end)
    end)

    addModule(container, "max_mastery", t("max_mastery.title"), t("max_mastery.desc"), "button", nil,
    function(done)
        local TAG = "MaxMastery"
        LOG.info(TAG, "Module activated.")

        scheduler:add(function(finishTask)
            local masteryTimestamp = os.time(os.date("!*t"))
            local vehicleListPtr   = gg.getValues({{ address = BaseGameStatus + 0xB8, flags = 32 }})[1].value
            local totalVehicles    = gg.getValues({{ address = BaseGameStatus + 0xC0, flags = 4  }})[1].value

            if not vehicleListPtr or vehicleListPtr == 0 then
                showToast(t("max_mastery.failed"))
                LOG.fatal(TAG, "vehicleListPtr is nil or 0.")
                finishTask(); done(); return
            end

            if not totalVehicles or totalVehicles == 0 then
                showToast(t("max_mastery.failed"))
                LOG.fatal(TAG, "totalVehicles is nil or 0.")
                finishTask(); done(); return
            end

            LOG.dbg(TAG, "Total vehicles: " .. tostring(totalVehicles))

            local successCount = 0
            local skipCount    = 0

            for i = 1, totalVehicles do
                local vehiclePtr = gg.getValues({{ address = vehicleListPtr + (i - 1) * 8, flags = 32 }})[1].value
                if not vehiclePtr or vehiclePtr == 0 then
                    skipCount = skipCount + 1; goto continue
                end

                local namePtr     = gg.getValues({{ address = vehiclePtr + 0x18, flags = 32 }})[1].value
                local vehicleName = (namePtr and namePtr ~= 0) and readString(namePtr + 1) or "Unknown"

                local masteryPtr = gg.getValues({{ address = vehiclePtr + 0x120, flags = 32 }})[1].value
                if not masteryPtr or masteryPtr == 0 then
                    LOG.dbg(TAG, "[" .. vehicleName .. "] masteryPtr is 0. Skipping (not maxed).")
                    skipCount = skipCount + 1; goto continue
                end

                -- Read up to 4 CA pointers
                local ptrReads  = {}
                for j = 0, 3 do
                    table.insert(ptrReads, { address = masteryPtr + j * 8, flags = 32 })
                end
                local rawPtrs   = gg.getValues(ptrReads)
                local validPtrs = {}
                if rawPtrs then
                    for _, p in ipairs(rawPtrs) do
                        if p and p.value and p.value ~= 0 then
                            table.insert(validPtrs, p.value)
                        end
                    end
                end

                if #validPtrs == 0 then
                    LOG.dbg(TAG, "[" .. vehicleName .. "] No valid CA pointers. Skipping.")
                    skipCount = skipCount + 1; goto continue
                end

                local writes = {}
                for _, p in ipairs(validPtrs) do
                    table.insert(writes, { address = p + 0x18, flags = 4, value = 65793 })
                    table.insert(writes, { address = p + 0x1C, flags = 4, value = masteryTimestamp })
                end

                gg.setValues({
                    { address = vehiclePtr + 0x120, flags = 32, value = masteryPtr },
                    { address = vehiclePtr + 0x128, flags = 4,  value = 4 },
                    { address = vehiclePtr + 0x12C, flags = 4,  value = 4 },
                    { address = vehiclePtr + 0x130, flags = 4,  value = 4 },
                })
                gg.setValues(writes)

                LOG.info(TAG, "[" .. vehicleName .. "] Mastery maxed.")
                successCount = successCount + 1
                
                showToast(t("common.progress", i, totalVehicles), true)
                ::continue::
            end

            LOG.info(TAG, string.format("Complete. Success: %d | Skipped: %d", successCount, skipCount))
            showToast(successCount > 0 and t("max_mastery.all_maxed") or t("max_mastery.failed"))
            finishTask()
            done()
        end)
    end)

    addModule(container, "max_parts", t("max_parts.title"), t("max_parts.desc"), "button", nil,
    function(done)
        local TAG = "MaxParts"
        LOG.info(TAG, "Module activated.")

        scheduler:add(function(finishTask)
            local vehicleListPtr = gg.getValues({{ address = BaseGameStatus + 0xB8, flags = 32 }})[1].value
            local totalVehicles  = gg.getValues({{ address = BaseGameStatus + 0xC0, flags = 4  }})[1].value

            if not vehicleListPtr or vehicleListPtr == 0 then
                showToast(t("max_parts.no_vehicles"))
                LOG.fatal(TAG, "vehicleListPtr is nil or 0.")
                finishTask(); done(); return
            end

            LOG.dbg(TAG, "Total vehicles: " .. tostring(totalVehicles))

            local upgradeList = {}

            for i = 0, totalVehicles - 1 do
                local vehiclePtr = gg.getValues({{ address = vehicleListPtr + i * 8, flags = 32 }})[1].value
                if vehiclePtr and vehiclePtr ~= 0 then
                    local partsListPtr = gg.getValues({{ address = vehiclePtr + 0x58, flags = 32 }})[1].value
                    local totalParts   = gg.getValues({{ address = vehiclePtr + 0x60, flags = 4  }})[1].value

                    if partsListPtr and partsListPtr ~= 0 and totalParts and totalParts > 0 then
                        for j = 0, totalParts - 1 do
                            local partPtr = gg.getValues({{ address = partsListPtr + j * 8, flags = 32 }})[1].value
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

                                local maxLevel = 3 -- fallback for unrecognised parts
                                
                                for key, lvl in pairs(PART_MAX_LEVEL) do
                                    -- '$' anchors the search strictly to the end of the string
                                    if partName:find(key .. "$") then 
                                        maxLevel = lvl
                                        break 
                                    end
                                end
                                
                                LOG.dbg(TAG, "[" .. partName .. "] max level: " .. tostring(maxLevel))
                                table.insert(upgradeList, { address = partPtr + 0x20, flags = 4, value = maxLevel })
                                table.insert(upgradeList, { address = partPtr + 0x34, flags = 4, value = maxLevel })
                            end
                        end
                    end
                end
                showToast(t("common.progress", i+1, totalVehicles), true)
            end

            if #upgradeList > 0 then
                gg.setValues(upgradeList)
                showToast(t("max_parts.all_maxed"))
                LOG.info(TAG, "Done. Total writes: " .. tostring(#upgradeList))
            else
                showToast(t("max_parts.failed"))
                LOG.warn(TAG, "upgradeList is empty.")
            end

            finishTask()
            done()
        end)
    end)
end