--[[
  Vehicle Tab - Vehicle modifications
  Features: Parts slot, Parts modifier, Fuel, Unlock vehicles, Max vehicles,
            Max mastery, Max parts

  UI wiring only. Memory ops live in modules/ops/vehicle.lua.

  Note: done() is called right after dispatching each op (not inside the result
  callback) so a crash inside the scheduled work can never leave a card stuck
  in its "processing" state. The result callback only renders the outcome.

  @module callback Receives container View to populate with modules
]]

local ops = CrashHandler.loadFeature("modules/ops/vehicle.lua")

-- "START BOOST" -> "Start Boost" for display only (internal keys stay as-is).
local function titleCase(s)
    return (tostring(s):lower():gsub("(%a)([%w']*)", function(a, b) return a:upper() .. b end))
end

return function(container)
    local function t(key, ...) return T("vehicle." .. key, ...) end

    addModule(container, "parts_slot", t("parts_slot.title"), t("parts_slot.desc"), "slider",
    {title=t("parts_slot.slider_title"), min=1, max=15, current=3},
    function(done, vals)
        ops.partsSlot(vals, function(status, count)
            if status == "no_vehicles" then
                showToast(t("common.no_vehicles"))
            elseif status == "no_zero_region" then
                showToast(t("common.no_zero_region"))
            else
                showToast(t("parts_slot.applied", count))
            end
        end)
        done()
    end)

    addArchModule(container, "parts_modifier", t("parts_modifier.title"), t("parts_modifier.desc"), "button", nil,
    function(done)
        local groupOrder, groupMap = ops.getPartGroups()

        -- Show Title Case names; map the choice back to the raw label.
        local display = {}
        for i, lbl in ipairs(groupOrder) do display[i] = titleCase(lbl) end

        local choice = showList(t("parts_modifier.title"), t("parts_modifier.select"), display)
        if not choice or choice == 0 then done() return end

        local label    = groupOrder[choice]
        local pretty   = titleCase(label)
        local variants = groupMap[label]
        local cacheKey = "parts_mod_" .. label:lower():gsub(" ", "_")

        local result = showPrompt(pretty, {
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

        ops.applyPartsModifier(
            { variants = variants, cacheKey = cacheKey, editValue = editValue, reset = reset },
            function(status)
                if status == "not_found" then
                    showToast(t("parts_modifier.not_found"), true)
                elseif status == "reset" then
                    showToast(t("parts_modifier.reset", pretty), true)
                else
                    showToast(t("parts_modifier.applied", pretty, userEdits), true)
                end
            end)
        done()
    end)

    addArchModule(container, "fuel", t("fuel.title"), t("fuel.desc"), "button", nil, function(done)
        local input = showPrompt(t("fuel.title"), {
            {t("fuel.prompt_amount"), "number", "50"},
            {t("fuel.prompt_reset"),  "checkbox", "false"},
        })

        if not input then
            done()
            return
        end

        ops.setFuel({ amount = input[1], reset = input[2] == "true" }, function(status, val)
            if status == "not_applied" then
                showToast(t("fuel.not_applied"), true)
            elseif status == "invalid" then
                showToast(t("fuel.invalid"), true)
            elseif status == "reset" then
                showToast(t("fuel.reset"), true)
            else
                showToast(t("fuel.applied", val), true)
            end
        end)
        done()
    end)

    addModule(container, "unlock_vehicles", t("unlock_vehicles.title"), t("unlock_vehicles.desc"), "button", nil,
    function(done)
        ops.unlockVehicles(function(status, count)
            if status == "no_vehicles" then
                showToast(t("common.no_vehicles"))
            elseif status == "unlocked" then
                showToast(t("unlock_vehicles.unlocked", count))
            else
                showToast(t("unlock_vehicles.none_to_unlock"))
            end
        end)
        done()
    end)

    addModule(container, "max_vehicles", t("max_vehicles.title"), t("max_vehicles.desc"), "button", nil,
    function(done)
        ops.maxVehicles(
            function(i, total) showToast(t("common.progress", i, total), true) end,
            function(status)
                if status == "no_vehicles" then
                    showToast(t("max_vehicles.no_vehicles"))
                elseif status == "all_maxed" then
                    showToast(t("max_vehicles.all_maxed"))
                else
                    showToast(t("max_vehicles.failed"))
                end
            end)
        done()
    end)

    addModule(container, "max_mastery", t("max_mastery.title"), t("max_mastery.desc"), "button", nil,
    function(done)
        ops.maxMastery(
            function(i, total) showToast(t("common.progress", i, total), true) end,
            function(status)
                showToast(status == "all_maxed" and t("max_mastery.all_maxed") or t("max_mastery.failed"))
            end)
        done()
    end)

    addModule(container, "max_parts", t("max_parts.title"), t("max_parts.desc"), "button", nil,
    function(done)
        ops.maxParts(
            function(i, total) showToast(t("common.progress", i, total), true) end,
            function(status)
                if status == "no_vehicles" then
                    showToast(t("max_parts.no_vehicles"))
                elseif status == "all_maxed" then
                    showToast(t("max_parts.all_maxed"))
                else
                    showToast(t("max_parts.failed"))
                end
            end)
        done()
    end)
end
