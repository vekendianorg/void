--[[
  modules/tabs/race.lua - Live race tools
  Features: coins/gems/bonus-coin injectors, coin multiplier, XP and
            mastery XP injectors, race points, distance/destroy/finish
            bonuses, record editor, rank doubler refill, free respawns,
            fuel canister editor, double adventure token, live status.

  UI wiring only. Memory ops live in modules/ops/race.lua, gated through
  modules/lib/raceops.lua. Every feature only works inside an active
  race: outside a race the op returns "no_race" and the user is told to
  enter a race first, then activate the feature again.

  @module callback Receives container View to populate with modules
]]

local ops = CrashHandler.loadFeature("modules/ops/race.lua")

return function(container)
    local function t(key, ...) return T("race." .. key, ...) end

    -- Every op returns one of: "applied", "no_race",
    -- "nebula_unavailable", "failed". Map to a toast in one place.
    local function result(status, data, okFmt, failFmt)
        if status == "applied" then
            showToast(okFmt, true)
        elseif status == "no_race" then
            showToast(t("enter_race"), false)
        elseif status == "nebula_unavailable" then
            showToast(t("nebula_unavailable"), false)
        else
            showToast(failFmt or t("failed"), false)
        end
    end

    addModuleSep(container, t("sec.currency"))

    addModule(container, "race_inject_coins", t("inject_coins.title"), t("inject_coins.desc"), "input", {
        {hint = t("inject_coins.hint"), type = "number"},
    }, function(done, vals)
        ops.injectCoins(vals[1], function(status, data)
            result(status, data, t("inject_coins.applied", data and tostring(data.value) or "?"))
        end)
        done()
    end)

    addModule(container, "race_inject_gems", t("inject_gems.title"), t("inject_gems.desc"), "input", {
        {hint = t("inject_gems.hint"), type = "number"},
    }, function(done, vals)
        ops.injectGems(vals[1], function(status, data)
            result(status, data, t("inject_gems.applied", data and tostring(data.value) or "?"))
        end)
        done()
    end)

    addModule(container, "race_inject_bonus_coins", t("inject_bonus_coins.title"), t("inject_bonus_coins.desc"), "input", {
        {hint = t("inject_bonus_coins.hint"), type = "number"},
    }, function(done, vals)
        ops.injectBonusCoins(vals[1], function(status, data)
            result(status, data, t("inject_bonus_coins.applied",
                data and tostring(data.count) or "?", data and tostring(data.amount) or "?"))
        end)
        done()
    end)

    addModule(container, "race_coin_multiplier", t("coin_multiplier.title"), t("coin_multiplier.desc"), "input", {
        {hint = t("coin_multiplier.hint"), type = "number"},
    }, function(done, vals)
        ops.setCoinMultiplier(vals[1], function(status, data)
            result(status, data, t("coin_multiplier.applied", data and tostring(data.value) or "?"))
        end)
        done()
    end)

    addModuleSep(container, t("sec.xp"))

    addModule(container, "race_inject_xp", t("inject_xp.title"), t("inject_xp.desc"), "input", {
        {hint = t("inject_xp.hint"), type = "number"},
    }, function(done, vals)
        ops.injectXp(vals[1], function(status, data)
            result(status, data, t("inject_xp.applied", data and tostring(data.value) or "?"))
        end)
        done()
    end)

    addModule(container, "race_inject_mastery", t("inject_mastery.title"), t("inject_mastery.desc"), "input", {
        {hint = t("inject_mastery.hint"), type = "number"},
    }, function(done, vals)
        ops.injectMasteryXp(vals[1], function(status, data)
            result(status, data, t("inject_mastery.applied", data and tostring(data.value) or "?"))
        end)
        done()
    end)

    addModuleSep(container, t("sec.points"))

    addModule(container, "race_inject_points", t("inject_points.title"), t("inject_points.desc"), "input", {
        {hint = t("inject_points.hint"), type = "number"},
    }, function(done, vals)
        ops.injectRacePoints(vals[1], function(status, data)
            result(status, data, t("inject_points.applied", data and tostring(data.value) or "?"))
        end)
        done()
    end)

    addModule(container, "race_distance_bonus", t("distance_bonus.title"), t("distance_bonus.desc"), "input", {
        {hint = t("distance_bonus.hint"), type = "number"},
    }, function(done, vals)
        ops.injectDistanceBonus(vals[1], function(status, data)
            result(status, data, t("distance_bonus.applied", data and tostring(data.value) or "?"))
        end)
        done()
    end)

    addModule(container, "race_destroy_bonus", t("destroy_bonus.title"), t("destroy_bonus.desc"), "input", {
        {hint = t("destroy_bonus.hint"), type = "number"},
    }, function(done, vals)
        ops.injectDestroyBonus(vals[1], function(status, data)
            result(status, data, t("destroy_bonus.applied", data and tostring(data.value) or "?"))
        end)
        done()
    end)

    addModule(container, "race_finish_bonus", t("finish_bonus.title"), t("finish_bonus.desc"), "input", {
        {hint = t("finish_bonus.hint"), type = "number"},
    }, function(done, vals)
        ops.injectFinishBonus(vals[1], function(status, data)
            result(status, data, t("finish_bonus.applied", data and tostring(data.value) or "?"))
        end)
        done()
    end)

    addModule(container, "race_record_editor", t("record_editor.title"), t("record_editor.desc"), "input", {
        {hint = t("record_editor.record"), type = "text"},
        {hint = t("record_editor.stars"),   type = "text"},
        {hint = t("record_editor.rank_div"), type = "text"},
        {hint = t("record_editor.wc_rank"),  type = "text"},
    }, function(done, vals)
        ops.editRecords({
            record  = vals[1],
            stars   = vals[2],
            rankDiv = vals[3],
            wcRank  = vals[4],
        }, function(status, data)
            result(status, data, t("record_editor.applied", data and tostring(data.count) or "?"))
        end)
        done()
    end)

    addModule(container, "race_doubler_refill", t("doubler_refill.title"), t("doubler_refill.desc"), "button", nil,
    function(done)
        ops.refillRankDoublers(function(status, data)
            result(status, data, t("doubler_refill.applied"))
        end)
        done()
    end)

    addModuleSep(container, t("sec.utility"))

    addModule(container, "race_free_respawns", t("free_respawns.title"), t("free_respawns.desc"), "button", nil,
    function(done)
        ops.freeRespawns(function(status, data)
            result(status, data, t("free_respawns.applied"))
        end)
        done()
    end)

    addModule(container, "race_canister_editor", t("canister_editor.title"), t("canister_editor.desc"), "input", {
        {hint = t("canister_editor.hint"), type = "text"},
    }, function(done, vals)
        ops.editSkippedCanisters(vals[1], function(status, data)
            result(status, data, t("canister_editor.applied", data and tostring(data.value) or "?"))
        end)
        done()
    end)

    addModule(container, "race_double_token", t("double_token.title"), t("double_token.desc"), "button", nil,
    function(done)
        ops.doubleAdventureToken(function(status, data)
            result(status, data, t("double_token.applied"))
        end)
        done()
    end)

    addModule(container, "race_live_status", t("live_status.title"), t("live_status.desc"), "button", nil,
    function(done)
        ops.readStatus(function(status, data)
            if status == "applied" then
                showDialog(t("live_status.title"), t("live_status.body",
                    data.state, data.coins, data.gems, data.xp,
                    data.mastery, data.points, data.distance), {T("common.ok")})
            else
                result(status, data)
            end
        end)
        done()
    end)
end
