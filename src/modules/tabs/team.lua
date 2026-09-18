--[[
  Team Tab - Team mode features
  Features: Team Size Bypass

  UI wiring only. Memory ops live in modules/ops/team.lua.
  done() is called right after dispatch (not inside the result callback) so a
  crash in the scheduled work can't leave a card stuck.

  @module callback Receives container View to populate with modules
]]

local ops = CrashHandler.loadFeature("modules/ops/team.lua")

return function(container)
    local function t(key, ...) return T("team." .. key, ...) end

    addModule(container, "team_size_bypass", t("team_size_bypass.title"),
        t("team_size_bypass.desc"), "switch", nil, function(done, state)
        ops.teamSizeBypass(state, function(status)
            showToast(t("team_size_bypass." .. status), true)
        end)
        done()
    end)

    -- "applied"/"reverted" toasts are per-card, everything else
    -- (resolve_failed | failed | nebula_unavailable | no_vehicles) is shared.
    local function epToast(card, status)
        if status == "applied" or status == "reverted" then
            showToast(t(card .. "." .. status))
        else
            showToast(t("ep." .. status), true)
        end
    end

    addModule(container, "unlimited_vehicle_usage", t("unlimited_vehicle_usage.title"),
        t("unlimited_vehicle_usage.desc"), "switch", nil, function(done, state)
        ops.unlimitedVehicleUsage(state, function(status)
            epToast("unlimited_vehicle_usage", status)
        end)
        done()
    end)

    addModule(container, "allow_all_vehicles", t("allow_all_vehicles.title"),
        t("allow_all_vehicles.desc"), "switch", nil, function(done, state)
        ops.allowAllVehicles(state, function(status)
            epToast("allow_all_vehicles", status)
        end)
        done()
    end)

    addModule(container, "free_entry_fee", t("free_entry_fee.title"),
        t("free_entry_fee.desc"), "switch", nil, function(done, state)
        ops.freeEntryFee(state, function(status)
            epToast("free_entry_fee", status)
        end)
        done()
    end)

    addModule(container, "vehicle_bonuses", t("vehicle_bonuses.title"),
        t("vehicle_bonuses.desc"), "switch", nil, function(done, state)
        ops.vehicleBonuses(state, function(status)
            epToast("vehicle_bonuses", status)
        end)
        done()
    end)

    addModule(container, "custom_participants", t("custom_participants.title"),
        t("custom_participants.desc"), "input", {
        { hint = t("custom_participants.hint"), value = "16", type = "number" },
    }, function(done, val)
        local n = math.floor(tonumber(val) or 0)
        if n < 1 then
            showToast(t("custom_participants.invalid"), true)
            done(); return
        end
        if n > 2147483647 then n = 2147483647 end
        if n > 100 then showToast(t("custom_participants.warn_big"), true) end
        ops.customParticipants(n, function(status)
            epToast("custom_participants", status)
        end)
        done()
    end)

    addModule(container, "custom_duration", t("custom_duration.title"),
        t("custom_duration.desc"), "input", {
        { hint = t("custom_duration.hint"), value = "300", type = "number" },
    }, function(done, val)
        local n = math.floor(tonumber(val) or 0)
        if n < 1 then
            showToast(t("custom_duration.invalid"), true)
            done(); return
        end
        if n > 2147483647 then n = 2147483647 end
        if n > 3600 then showToast(t("custom_duration.warn_big"), true) end
        ops.customDuration(n, function(status)
            epToast("custom_duration", status)
        end)
        done()
    end)

    addModule(container, "instant_ticket_refill", t("instant_ticket_refill.title"),
        t("instant_ticket_refill.desc"), "switch", nil, function(done, state)
        ops.instantTicketRefill(state, function(status)
            epToast("instant_ticket_refill", status)
        end)
        done()
    end)
end
