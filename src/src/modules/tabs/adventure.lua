--[[
  Adventure Tab - Adventure mode features
  Features: Auto adventure chests, Set distance (+ optional loop)

  UI wiring only. Memory ops live in modules/ops/adventure.lua.

  @module callback Receives container View to populate with modules
]]

local ops = CrashHandler.loadFeature("modules/ops/adventure.lua")

return function(container)
    local function t(key, ...) return T("adventure." .. key, ...) end

    addModule(container, "auto_adventure_chests", t("auto_adventure_chests.title"), t("auto_adventure_chests.desc"), "button", nil,
    function(done)
        ops.autoAdventureChests(function(status)
            if status == "none_found" then
                showToast(t("auto_adventure_chests.none_found"))
            else
                showToast(t("auto_adventure_chests.done"))
            end
        end)
        done()
    end)

    addArchModule(container, "set_distance", t("set_distance.title"), t("set_distance.desc"), "button", nil,
    function(done)
        -- Loop already running? Offer to stop it.
        if ops.isLoopActive() then
            local action = showDialog(
                t("set_distance.loop_active_title"),
                t("set_distance.loop_active_msg"),
                {t("set_distance.stop_loop")}, {t("set_distance.keep_running")}
            )
            if action == 1 then
                ops.stopLoop()
                showToast(t("set_distance.loop_will_stop"))
            end
            done()
            return
        end

        local result = showPrompt(t("set_distance.title"), {
            {t("set_distance.prompt_target"), "number", "5000"},
            {t("set_distance.prompt_loop"),     "switch",  "false"},
            {t("set_distance.prompt_interval"), "number", "3500"},
        })

        if not result then
            done()
            return
        end

        local target_meters = tonumber(result[1]) or 5000
        local loop_enabled  = result[2] == "true"
        local loop_interval = math.max(250, tonumber(result[3]) or 1000)

        if loop_enabled then
            local warn = showDialog(
                t("set_distance.loop_warn_title"),
                t("set_distance.loop_warn_msg", tostring(loop_interval)),
                {t("set_distance.continue_button")},
                {T("common.cancel")}
            )
            if warn ~= 1 then
                done()
                return
            end
        end

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

        ops.setDistance(
            { target_meters = target_meters, loop_enabled = loop_enabled, loop_interval = loop_interval },
            {
                onApply = function(status, phase)
                    if status == "not_in_adventure" then
                        showToast(t("set_distance.not_in_adventure"))
                    elseif status == "start_race_first" then
                        showToast(t("set_distance.start_race_first"))
                    elseif phase == "initial" then
                        showToast(t("set_distance.applied", tostring(target_meters)))
                    end
                end,
                onLoopRunning = function() showToast(t("set_distance.loop_running"), true) end,
                onLoopStopped = function() showToast(t("set_distance.loop_stopped")) end,
            }
        )
        done()
    end)
end
