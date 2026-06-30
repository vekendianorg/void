--[[
  Account Tab - Player profile modifications
  Features: Change player name, Change GP, Fake unlock/VIP, Fake Rank

  UI wiring only. Memory ops live in modules/ops/account.lua.

  @module callback Receives container View to populate with modules
]]

local ops = CrashHandler.loadFeature("modules/ops/account.lua")

return function(container)
    local function t(key, ...) return T("account." .. key, ...) end

    addModule(container, "change_name", t("change_name.title"), t("change_name.desc"), "input", {
        { hint = t("change_name.hint"), value = "", type = "text" }
    }, function(done, val)
        ops.changeName(val, function(status)
            if status == "empty" then
                showToast(t("change_name.empty"))
            elseif status == "too_long" then
                showDialog(t("change_name.too_long_title"), t("change_name.too_long_msg"), T("common.ok"))
            elseif status == "resolve_failed" then
                showToast(t("change_name.resolve_failed"))
            else
                showToast(t("change_name.applied", val))
            end
        end)
        done()
    end)

    addModule(container, "change_gp", t("change_gp.title"), t("change_gp.desc"), "input", {
        { hint = t("change_gp.hint"), value = "8", type = "number" }
    }, function(done, val)
        ops.changeGp(val, function(status)
            if status == "max_int" then
                showDialog(t("change_gp.max_int_title"), t("change_gp.lower_value"), {T("common.ok")})
            elseif status == "too_low" then
                showDialog(t("change_gp.too_low_title"), t("change_gp.higher_value"), {T("common.ok")})
            else
                showToast(t("change_gp.applied", tostring(val)))
            end
        end)
        done()
    end)

    addModule(container, "change_ws", t("change_ws.title"), t("change_ws.desc"), "button", nil,
    function(done)
        local result = showPrompt(t("change_ws.title"), {
            { t("change_ws.prompt_best"),    "number", "1" },
            { t("change_ws.prompt_current"), "number", "1" },
        })
        if not result then done() return end

        local best    = math.floor(tonumber(result[1]) or 1)
        local current = math.floor(tonumber(result[2]) or 1)

        best    = math.max(0, math.min(2147483647, best))
        current = math.max(0, math.min(2147483647, current))

        if current > best then
            showDialog(
                t("change_ws.current_over_best_title"),
                t("change_ws.current_over_best_msg"),
                T("common.ok")
            )
            done(); return
        end

        ops.changeWinStreak(current, best, function(status)
            if status == "resolve_failed" then
                showToast(t("change_ws.resolve_failed"), true)
            else
                showToast(t("change_ws.applied", tostring(current), tostring(best)))
            end
        end)
        done()
    end)

    addArchModule(container, "fake_unlock", t("fake_unlock.title"), t("fake_unlock.desc"), "switch", nil, aobs.fakeUnlock)

    addArchModule(container, "fake_vip", t("fake_vip.title"), t("fake_vip.desc"), "switch", nil, aobs.fakeVip)

    addModule(container, "fake_rank", t("fake_rank.title"), t("fake_rank.desc"), "button", nil, function(done)
        if not ops.isCupsTab() then
            LOG.warn("FakeRank", "Not in Cups tab.")
            showToast(t("fake_rank.not_in_cups"))
            done()
            return
        end

        local confirm = showDialog(
            t("fake_rank.race_warn_title"),
            t("fake_rank.race_warn_msg"),
            {t("fake_rank.continue_button")},
            {T("common.cancel")}
        )

        if confirm ~= 1 then
            done()
            return
        end

        ops.applyFakeRank(function()
            showToast(t("fake_rank.applied"))
        end)
        done()
    end)
end
