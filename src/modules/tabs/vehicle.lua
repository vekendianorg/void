--[[
  Vehicle Tab - Vehicle modifications
  Features: Parts slot, Parts modifier, Fuel, Unlock vehicles, Max vehicles,
            Max mastery, Max parts, Tuning parts editors

  UI wiring only. Memory ops live in modules/ops/vehicle.lua.

  Note: done() is called right after dispatching each op (not inside the result
  callback) so a crash inside the scheduled work can never leave a card stuck
  in its "processing" state. The result callback only renders the outcome.

  @module callback Receives container View to populate with modules
]]

local ops  = CrashHandler.loadFeature("modules/ops/vehicle.lua")

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
                local cached     = storage:load_session(cacheKey)
                local statusLine = cached
                    and t("parts_modifier.status_cached", #cached)
                    or  t("parts_modifier.status_none")

                local promptTitle = pretty .. ": " .. titleCase(chosenStat.label)
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
            function(status, stats)
                if status == "no_vehicles" then
                    showToast(t("max_vehicles.no_vehicles"))
                elseif status == "all_maxed" then
                    showToast(t("max_vehicles.applied", stats.written, stats.upgrades, stats.vehicles))
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
            function(status, stats)
                if status == "no_vehicles" then
                    showToast(t("max_parts.no_vehicles"))
                elseif status == "all_maxed" then
                    showToast(t("max_parts.applied", stats.written, stats.parts, stats.vehicles))
                else
                    showToast(t("max_parts.failed"))
                end
            end)
        done()
    end)

    -- ── Per-slot parts editor (shared by both tuning editors) ─────────────
    -- One row per filled slot plus an "Add a part" row. Tapping a row opens a
    -- single-choice picker (swap or remove that slot's part); the slot list
    -- then re-opens showing the new state. Closing the list finishes.
    -- Edits stay in memory while the list is open; the single write
    -- happens once the user closes the list (per-action writes made
    -- the prompt feel laggy).
    local function slotEditor(title, hint, ids, parts, writeFn)
        local partDisp, dispToId = {}, {}
        for _, part in ipairs(parts) do
            local d = part.id .. " (" .. part.level .. "/" .. part.maxLevel .. ")"
            partDisp[#partDisp + 1] = d
            dispToId[d] = part.id
        end

        local MAX_SLOTS = 15

        local orig = {}
        for i, id in ipairs(ids) do orig[i] = id end

        while true do
            local labels = {}
            for i, id in ipairs(ids) do
                labels[#labels + 1] = (id ~= "" and id)
                    and t("slot.filled", i, id)
                    or  t("slot.empty", i)
            end
            if #ids < MAX_SLOTS then
                labels[#labels + 1] = t("slot.add")
            end

            local pick = showList(title, hint, labels)
            if not pick or pick == 0 then
                -- Closed: flush once if anything changed.
                local changed = #orig ~= #ids
                if not changed then
                    for i = 1, #orig do
                        if orig[i] ~= ids[i] then changed = true; break end
                    end
                end
                if changed then
                    writeFn(ids, function(ok)
                        if ok then
                            showToast(t("slot.saved"))
                        else
                            for i = 1, #orig do ids[i] = orig[i] end
                            for i = #orig + 1, #ids do ids[i] = nil end
                            showToast(t("slot.write_failed"), true)
                        end
                    end)
                end
                break
            end

            if pick > #ids then
                -- Add row: any owned part, even one already in another
                -- slot (duplicates are allowed).
                local opts, optIds = {}, {}
                for _, d in ipairs(partDisp) do
                    opts[#opts + 1] = d
                    optIds[#optIds + 1] = dispToId[d]
                end
                if #opts == 0 then
                    showToast(t("slot.none_free"), true)
                else
                    local c = showList(t("slot.add_title"), t("slot.pick_part"), opts)
                    if c and c > 0 then
                        table.insert(ids, optIds[c])
                    end
                end
            else
                local slot = pick
                local cur = ids[slot]
                -- Picker: remove option first, then every owned part.
                -- Duplicates are allowed: the same part can sit in several slots.
                local opts, optIds = {}, {}
                opts[#opts + 1] = t("slot.remove"); optIds[#optIds + 1] = nil
                for _, d in ipairs(partDisp) do
                    opts[#opts + 1] = d
                    optIds[#optIds + 1] = dispToId[d]
                end

                local c = showList(t("slot.pick_title", slot), t("slot.pick_part"), opts)
                if c and c > 1 then
                    ids[slot] = optIds[c]
                elseif c == 1 then
                    table.remove(ids, slot)
                end
            end
        end
    end

    -- ── Equipped Tuning Parts editor (Nebula) ─────────────────────────────
    addModule(container, "show_hidden", t("show_hidden.title"), t("show_hidden.desc"), "switch", nil,
    function(done, state)
        ops.showHiddenVehicles(state, function(status)
            if status == "applied" then
                showToast(t("show_hidden.applied"), true)
            elseif status == "reverted" then
                showToast(t("show_hidden.reverted"), true)
            elseif status == "nebula_unavailable" then
                showToast(T("common.nebula_unavailable"))
            else
                showToast(t("show_hidden.failed"))
            end
        end)
        done()
    end)

    addModule(container, "tuning_equipped", t("tuning_equipped.title"), t("tuning_equipped.desc"), "button", nil,
    function(done)
        ops.listVehicles(function(status, vehicles)
            if status ~= "ok" then
                if status == "no_vehicles" then
                    showToast(t("common.no_vehicles"))
                elseif status == "nebula_unavailable" then
                    showToast(t("common.nebula_unavailable"), true)
                else
                    showToast(t("tuning_equipped.failed"), true)
                end
                return
            end

            local names, byName = {}, {}
            for _, v in ipairs(vehicles) do
                names[#names + 1] = v.id
                byName[v.id] = v.index
            end

            local pick = showList(t("tuning_equipped.pick_vehicle"), t("tuning_equipped.pick_vehicle_desc"), names)
            if not pick or pick == 0 then return end
            local vIdx = byName[names[pick]]

            ops.listParts(vIdx, function(pStatus, parts)
                if pStatus ~= "ok" then
                    showToast(pStatus == "no_parts" and t("tuning_equipped.no_parts") or t("tuning_equipped.failed"), true)
                    return
                end

                ops.getEquipped(vIdx, function(eStatus, equipped)
                    if eStatus ~= "ok" then
                        showToast(t("tuning_equipped.failed"), true)
                        return
                    end

                    local ids = {}
                    for _, id in ipairs(equipped) do ids[#ids + 1] = id end

                    slotEditor(t("tuning_equipped.title"), t("tuning_equipped.hint"), ids, parts,
                        function(newIds, onDone)
                            ops.setEquipped(vIdx, newIds, function(sStatus)
                                onDone(sStatus == "applied")
                            end)
                        end)
                end)
            end)
        end)
        done()
    end)

    -- ── Tuning Part Presets editor (Nebula) ────────────────────────────────
    addModule(container, "tuning_presets", t("tuning_presets.title"), t("tuning_presets.desc"), "button", nil,
    function(done)
        ops.listVehicles(function(status, vehicles)
            if status ~= "ok" then
                if status == "no_vehicles" then
                    showToast(t("common.no_vehicles"))
                elseif status == "nebula_unavailable" then
                    showToast(t("common.nebula_unavailable"), true)
                else
                    showToast(t("tuning_presets.failed"), true)
                end
                return
            end

            local names, byName = {}, {}
            for _, v in ipairs(vehicles) do
                names[#names + 1] = v.id
                byName[v.id] = v.index
            end

            local pick = showList(t("tuning_presets.pick_vehicle"), t("tuning_presets.pick_vehicle_desc"), names)
            if not pick or pick == 0 then return end
            local vIdx = byName[names[pick]]

            local function openPresetList()
                ops.listPresets(vIdx, function(psStatus, presets, selected)
                    if psStatus ~= "ok" then
                        showToast(psStatus == "no_presets" and t("tuning_presets.no_presets") or t("tuning_presets.failed"), true)
                        return
                    end

                    local labels = {}
                    for _, pr in ipairs(presets) do
                        local partsStr = #pr.parts > 0
                            and table.concat(pr.parts, ", ")
                            or  t("tuning_presets.preset_empty")
                        local lbl = t("tuning_presets.preset_label", pr.index, partsStr)
                        if pr.index == selected then lbl = lbl .. " (" .. t("tuning_presets.active") .. ")" end
                        labels[#labels + 1] = lbl
                    end
                    labels[#labels + 1] = t("tuning_presets.add")

                    local pPick = showList(t("tuning_presets.title"), t("tuning_presets.pick_preset_desc"), labels)
                    if not pPick or pPick == 0 then return end

                    -- "+ Add Preset" row: append an empty preset and reopen.
                    if pPick > #presets then
                        ops.addPreset(vIdx, function(aStatus, count)
                            if aStatus == "applied" then
                                showToast(t("tuning_presets.added", count), true)
                                openPresetList()
                            elseif aStatus == "max_reached" then
                                showToast(t("tuning_presets.max_reached"), true)
                            else
                                showToast(t("tuning_presets.failed"), true)
                            end
                        end)
                        return
                    end

                    local pIdx = presets[pPick].index

                        local actions = {
                        t("tuning_presets.action_edit"),
                        t("tuning_presets.action_activate"),
                        t("tuning_presets.action_copy_current"),
                    }
                    local aPick = showList(labels[pPick], t("tuning_presets.pick_action"), actions)
                    if not aPick or aPick == 0 then return end

                    if aPick == 1 then
                        -- Per-slot edit of this preset's parts.
                        ops.listParts(vIdx, function(lStatus, parts)
                            if lStatus ~= "ok" then
                                showToast(t("tuning_equipped.no_parts"), true)
                                return
                            end

                            local ids = {}
                            for _, pr in ipairs(presets) do
                                if pr.index == pIdx then
                                    for _, id in ipairs(pr.parts) do ids[#ids + 1] = id end
                                    break
                                end
                            end

                            slotEditor(labels[pPick], t("tuning_presets.hint"), ids, parts,
                                function(newIds, onDone)
                                    ops.setPresetParts(vIdx, pIdx, newIds, function(sStatus)
                                        onDone(sStatus == "applied")
                                    end)
                                end)
                        end)
                    elseif aPick == 2 then
                        ops.setSelectedPreset(vIdx, pIdx, function(sStatus)
                            if sStatus == "applied" then
                                showToast(t("tuning_presets.activated", pIdx), true)
                            else
                                showToast(t("tuning_presets.failed"), true)
                            end
                        end)
                    else
                        ops.saveEquippedToPreset(vIdx, pIdx, function(sStatus, count)
                            if sStatus == "applied" then
                                showToast(t("tuning_presets.copied", pIdx, count), true)
                            elseif sStatus == "not_equipped" then
                                showToast(t("tuning_presets.nothing_equipped"), true)
                            else
                                showToast(t("tuning_presets.failed"), true)
                            end
                        end)
                    end
                end)
            end
            openPresetList()
        end)
        done()
    end)
end