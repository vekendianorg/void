--[[
  Cups Tab - Cup racing modes
  Features: Adjust countdown, Auto-win, Force boss, Force cup, Set time,
            Unlimited tasks, Rank points bonus

  UI wiring only. Memory ops live in modules/ops/cups.lua.

  @module callback Receives container View to populate with modules
]]

local ops = CrashHandler.loadFeature("modules/ops/cups.lua")

return function(container)
    local function t(key, ...) return T("cups." .. key, ...) end

    addModule(container, "adjust_countdown", t("adjust_countdown.title"), t("adjust_countdown.desc"), "slider",
    {title=t("slider.seconds"), min=0, max=10, current=3},
    function(done, vals)
        ops.adjustCountdown(vals, function()
            showToast(t("adjust_countdown.applied", tostring(vals)), true)
        end)
        done()
    end)

    addArchModule(container, "auto_win", t("auto_win.title"), t("auto_win.desc"), "switch", nil, aobs.autoWin)

    addArchModule(container, "force_boss", t("force_boss.title"), t("force_boss.desc"), "switch", nil, aobs.forceBoss)

    addModule(container, "force_cup", t("force_cup.title"), t("force_cup.desc"), "switch", nil,
    function(done, state)
        ops.forceCup(state, function(status)
            if status == "not_found" then
                showToast(t("force_cup.not_found"))
            elseif status == "enabled" then
                showToast(t("force_cup.enabled"))
            else
                showToast(t("force_cup.disabled"))
            end
        end)
        done()
    end)

    addArchModule(container, "set_time", t("set_time.title"), t("set_time.desc"), "input", {
        {hint = t("set_time.hint"), type = "text"},
    }, function(done, vals)
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

        ops.setTime(timeSeconds, function(status)
            if status == "not_in_cup" then
                showToast(t("set_time.not_in_cup"), true)
            elseif status == "start_race_first" then
                showToast(t("set_time.start_race_first"), true)
            else
                showToast(t("set_time.applied", vals), true)
            end
        end)
        done()
    end)

    addModule(container, "unlimited_tasks", t("unlimited_tasks.title"), t("unlimited_tasks.desc"), "switch", nil,
    function(done, state)
        ops.unlimitedTasks(state, function(status)
            if status == "resolve_failed" then
                showToast(t("unlimited_tasks.resolve_failed"))
            elseif status == "none_found" then
                showToast(t("unlimited_tasks.none_found"))
            elseif status == "enabled" then
                showToast(t("unlimited_tasks.enabled"))
            elseif status == "disabled" then
                showToast(t("unlimited_tasks.disabled"))
            else
                showToast(t("unlimited_tasks.none_to_freeze"))
            end
        end)
        done()
    end)

    addModule(container, "rank_points_bonus", t("rank_points_bonus.title"), t("rank_points_bonus.desc"), "switch", nil,
    function(done, state)
        ops.rankPointsBonus(state, function(status, count)
            if status == "none_found" then
                showToast(t("rank_points_bonus.none_found"))
            elseif status == "boosted" then
                showToast(t("rank_points_bonus.boosted", tostring(count)))
            elseif status == "no_match" then
                showToast(t("rank_points_bonus.no_match"))
            elseif status == "nothing_to_restore" then
                showToast(t("rank_points_bonus.nothing_to_restore"))
            else
                showToast(t("rank_points_bonus.restored", tostring(count)))
            end
        end)
        done()
    end)
end
