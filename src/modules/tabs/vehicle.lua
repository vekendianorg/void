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

        -- Display list (Title Case); maps index back to raw label.
        local display = {}
        for i, lbl in ipairs(groupOrder) do display[i] = titleCase(lbl) end

        -- Builds the level float string from components.
        --   lvl=1, d0="0", d1="3" → "1.3"
        --   lvl=2, d0="0", d1="3" → "1.03"
        --   lvl=3, d0="0", d1="3" → "1.003"
        local function buildValue(lvl, d0, d1)
            local p = ""
            if lvl > 1 then for _ = 1, lvl - 1 do p = p .. d0 end end
            return "1." .. p .. d1
        end

        -- ── Depth-based navigation loop ───────────────────────────────────────
        -- depth 1 = part selection  (cancel → exit)
        -- depth 2 = stat selection  (cancel → back to depth 1; skipped if 1 stat)
        -- depth 3 = level prompt    (cancel → back to depth 2 or 1)
        --
        -- State preserved across depth transitions so going back restores the
        -- previous selection rather than resetting it.
        local depth     = 1
        local label, pretty, variants, statList, chosenStat, cacheKey

        while true do

            -- ── Depth 1: pick a part ─────────────────────────────────────────
            if depth == 1 then
                local choice = showList(t("parts_modifier.title"), t("parts_modifier.select"), display)
                if not choice or choice == 0 then
                    done(); return   -- top-level cancel → exit
                end
                label    = groupOrder[choice]
                pretty   = titleCase(label)
                variants = groupMap[label]
                statList = variants[1].statList

                -- If the part has only one stat there's nothing to pick —
                -- skip depth 2 and go straight to the level prompt.
                if #statList == 1 then
                    chosenStat = statList[1]
                    cacheKey   = "parts_mod_" .. label:lower():gsub(" ", "_")
                               .. "_" .. chosenStat.label:lower():gsub(" ", "_")
                    depth = 3
                else
                    depth = 2
                end

            -- ── Depth 2: pick a stat ─────────────────────────────────────────
            elseif depth == 2 then
                local statLabels = {}
                for _, s in ipairs(statList) do
                    statLabels[#statLabels + 1] = titleCase(s.label)
                end

                local statChoice = showList(pretty, t("parts_modifier.select_stat"), statLabels)
                if not statChoice or statChoice == 0 then
                    depth = 1   -- back to part selection
                else
                    chosenStat = statList[statChoice]
                    cacheKey   = "parts_mod_" .. label:lower():gsub(" ", "_")
                               .. "_" .. chosenStat.label:lower():gsub(" ", "_")
                    depth = 3
                end

            -- ── Depth 3: level prompt ─────────────────────────────────────────
            elseif depth == 3 then
                -- Show what was previously applied for this stat (if anything).
                local cached     = memory:load(cacheKey)
                local statusLine = cached
                    and t("parts_modifier.status_cached", #cached)
                    or  t("parts_modifier.status_none")

                local promptTitle = pretty .. " — " .. titleCase(chosenStat.label)
                                  .. "  (" .. statusLine .. ")"

                local result = showPrompt(promptTitle, {
                    {t("parts_modifier.prompt_level"),  "slider:1:9", "2"},
                    {t("parts_modifier.prompt_digit0"), "slider:0:9", "0"},
                    {t("parts_modifier.prompt_digit1"), "slider:1:9", "3"},
                    {t("parts_modifier.prompt_reset"),  "checkbox",   "false"},
                })

                if not result then
                    -- Back: if we skipped depth 2 (single-stat part) go to 1,
                    -- otherwise go to 2.
                    depth = (#statList == 1) and 1 or 2
                else
                    local reset  = result[4] == "true"
                    local lvl    = tonumber(result[1]) or 2
                    local digit0 = tostring(result[2] or "0")
                    local digit1 = tostring(result[3] or "3")
                    local userEdits = buildValue(lvl, digit0, digit1)
                    local editValue = tonumber(userEdits)

                    if not reset and not editValue then
                        showToast(t("parts_modifier.invalid"), true)
                        -- Stay at depth 3 — let user try again without losing context
                    else
                        ops.applyPartsModifier({
                            variants   = variants,
                            chosenStat = chosenStat,
                            cacheKey   = cacheKey,
                            editValue  = editValue,
                            reset      = reset,
                        }, function(status)
                            if status == "not_found" then
                                showToast(t("parts_modifier.not_found"), true)
                            elseif status == "reset" then
                                showToast(t("parts_modifier.reset", pretty), true)
                            else
                                showToast(t("parts_modifier.applied",
                                    pretty .. " " .. titleCase(chosenStat.label), userEdits), true)
                            end
                        end)
                        done(); return
                    end
                end
            end

        end -- while true
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
