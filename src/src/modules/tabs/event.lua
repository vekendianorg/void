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
    local ui = {
        onProgress = function(key) gg.toast(t(key)) end,
        chooseEvents = function(labels, titleKey, arg)
            return gg.multiChoice(labels, nil, t(titleKey, arg))
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
end
