--[[
  Event Tab - Event mode features
  Features: Patch event rewards, Restore events

  UI wiring only. The file/crypto/root pipeline lives in modules/ops/event.lua.
  This tab supplies the interaction callbacks and renders the result.

  @module callback Receives container View to populate with modules
]]

local ops = CrashHandler.loadFeature("modules/ops/event.lua")

return function(container)
    local function t(key, ...) return T("event." .. key, ...) end

    -- Interaction callbacks handed to core for the unavoidable mid-pipeline UI.
    -- chooseEvents used to call raw gg.multiChoice() -- every other picker in
    -- the app (vehicle.lua, creative.lua, settings.lua) already uses the
    -- app's own themed showList() widget, so this one stuck out (native GG
    -- dialog look/behavior instead of the app's UI). Switched to showList in
    -- multi-select mode; it returns an array of selected 1-based indices
    -- rather than gg.multiChoice's full boolean map, so we convert it back
    -- into the boolean-map shape ops/event.lua already expects -- no changes
    -- needed downstream.
    local titleForKey = {
        select_events_patch   = t("patch_rewards.title"),
        select_events_restore = t("restore_events.title"),
    }

    local ui = {
        onProgress = function(key) gg.toast(t(key)) end,
        chooseEvents = function(labels, titleKey, arg)
            local title = titleForKey[titleKey] or t(titleKey, arg)
            local picked = showList(title, t(titleKey, arg), labels, true)
            if not picked then return nil end
            local selections = {}
            for _, idx in ipairs(picked) do
                selections[idx] = true
            end
            return selections
        end,
    }

    -- Localize a failedList entry: { key, arg1, ... } → t(key, arg1, ...)
    local function localizeFail(e) return t(table.unpack(e)) end

    -- Build the success/failed dialog body from the result lists.
    local function buildResultMsg(result, successHeaderKey, successItemKey)
        local resultMsg = ""
        if #result.successList > 0 then
            resultMsg = resultMsg .. t(successHeaderKey) .. "\n"
            for _, name in ipairs(result.successList) do
                resultMsg = resultMsg .. t(successItemKey, name) .. "\n"
            end
            resultMsg = resultMsg .. "\n"
        end
        if #result.failedList > 0 then
            resultMsg = resultMsg .. t("failed_header") .. "\n"
            for _, e in ipairs(result.failedList) do
                resultMsg = resultMsg .. t("failed_item", localizeFail(e)) .. "\n"
            end
        end
        return resultMsg
    end

    -- Wait for any queued scheduler file tasks to drain, then kill + relaunch.
    local function restartGame(finishingKey)
        if scheduler:get_queue_count() > 0 or scheduler:is_processing() then
            gg.toast(t(finishingKey))
            while scheduler:get_queue_count() > 0 or scheduler:is_processing() do
                gg.sleep(100)
            end
        end
        gg.processKill()
        gg.sleep(1000)
        exitScript()
    end

    addModule(container, "patch_rewards", t("patch_rewards.title"), t("patch_rewards.desc"), "button", nil, function(done)
        ops.patchRewards(ui, function(result)
            if result.earlyExit then
                showDialog(t(result.earlyExit[1]), t(result.earlyExit[2], result.earlyExit[3]), {T("common.ok")})
                done()
                return
            end

            local resultMsg = buildResultMsg(result, "success_header", "success_item")
            showDialog(t("patch_results_title"), resultMsg, {T("common.ok")})
            done()

            if result.restart then
                print(resultMsg)
                showDialog(t("restart_required_title"), t("patch_restart_msg"), {T("common.ok")})
                restartGame("finishing_tasks_patch")
            else
                showDialog(T("common.failed"), t("patch_failed_msg"), {T("common.ok")})
            end
        end)
    end)

    addModule(container, "restore_events", t("restore_events.title"), t("restore_events.desc"), "button", nil, function(done)
        ops.restoreEvents(ui, function(result)
            if result.earlyExit then
                showDialog(t(result.earlyExit[1]), t(result.earlyExit[2], result.earlyExit[3]), {T("common.ok")})
                done()
                return
            end

            local resultMsg = buildResultMsg(result, "success_removed_header", "success_item_json")
            showDialog(t("restore_results_title"), resultMsg, {T("common.ok")})
            done()

            if result.restart then
                print(resultMsg)
                showDialog(t("restart_required_title"), t("restore_restart_msg"), {T("common.ok")})
                restartGame("finishing_tasks_restore")
            end
        end)
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
