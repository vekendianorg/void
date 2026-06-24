--[[
  modules/ops/event.lua — Event reward patch/restore pipeline (no UI text)
  Contract: see modules/ops/README.md.

  event is a file/crypto/root pipeline rather than a pure memory op, but the
  same split applies: core runs the whole pipeline; the tab supplies the two
  unavoidable interaction points via a `ui` table and renders the result.

    ui = {
      onProgress(key)              -- core asks the tab to toast t(key)
      chooseEvents(labels, key, p) -- core asks the tab for a multi-select
                                   --   (tab shows gg.multiChoice titled t(key, p))
                                   --   returns the selections table or nil
    }

  Each op calls cb(result) where:
    result = {
      successList = { <eventName>, ... },        -- plain names
      failedList  = { { key, arg1, ... }, ... },  -- localize as t(key, arg1, ...)
      earlyExit   = { titleKey, msgKey, arg } | nil,  -- special fatal dialog
      restart     = <bool>,                       -- true if a restart is warranted
    }

  Globals used: scheduler, memory, gg, json, loadModule, Shell, Crypto,
  game_path, LOG.
]]

local M = {}

-- ── File / shell helpers ────────────────────────────────────────────────────

local function fileSize(path)
    local f = io.open(path, "rb")
    if not f then return -1 end
    local size = f:seek("end")
    f:close()
    return size or -1
end

local function checkRoot()
    local result = Shell.su("id")
    return result and result:find("uid=0") ~= nil
end

local function fileExists(path)
    local f = io.open(path, "rb")
    if f then f:close(); return true end
    return Shell.su("[ -f \"" .. path .. "\" ] && echo yes || echo no") == "yes"
end

local function dirExists(path)
    return Shell.su("[ -d \"" .. path .. "\" ] && echo yes || echo no") == "yes"
end

-- ── Patch rewards ─────────────────────────────────────────────────────────────

function M.patchRewards(ui, cb)
    ui.onProgress("checking_permissions")
    local hasRoot = checkRoot()

    if hasRoot then
        memory:save("shell_states", {root=true})
    else
        memory:save("shell_states", {root=false})
    end

    ui.onProgress("scanning_files")

    local eventsPath = game_path .. "/files/content_cache/json/events/"

    local successList = {}
    local failedList = {}

    local custom_rewards = loadModule("configs/rewards.lua")
    local jsonMod = nil
    local ok, err = pcall(function()
        jsonMod = json.decode(custom_rewards)
    end)
    if not ok or not jsonMod then
        table.insert(failedList, {"decode_rewards_failed"})
        jsonMod = nil
    end

    -- Workspace for root file operations
    local safeWorkspace = gg.EXT_FILES_DIR .. "/.void_cache/"
    if hasRoot then
        Shell.su("mkdir -p \"" .. safeWorkspace .. "\"")
        Shell.su("chmod 777 \"" .. safeWorkspace .. "\"")
        if not dirExists(safeWorkspace) then
            table.insert(failedList, {"workspace_creation_failed", safeWorkspace})
            cb({ successList = successList, failedList = failedList,
                 earlyExit = { "patch_results_title", "workspace_creation_failed_dialog", safeWorkspace } })
            return
        end
        LOG.dbg("EventPatch", "Workspace verified: " .. safeWorkspace)
    end

    do
        local path = eventsPath
        local active = path .. "active_events.json"
        local active_decrypted = hasRoot and (safeWorkspace .. ".active_events") or (path .. ".active_events")
        local targetActivePath = active
        local activeMovedViaRoot = false

        -- Check if file is directly readable (Virtual Space)
        local testOpen = io.open(active, "r")
        if testOpen then
            testOpen:close()
        elseif hasRoot then
            local secureActiveCopy = safeWorkspace .. "active_events.json"
            Shell.su("cp \"" .. active .. "\" \"" .. secureActiveCopy .. "\"")
            Shell.su("chmod 777 \"" .. secureActiveCopy .. "\"")

            if not fileExists(secureActiveCopy) then
                LOG.warn("EventPatch", "Root copy verification FAILED for: " .. secureActiveCopy)
                table.insert(failedList, {"root_copy_failed", active})
                goto continue_path
            end

            targetActivePath = secureActiveCopy
            activeMovedViaRoot = true
        else
            table.insert(failedList, {"file_inaccessible", path})
            goto continue_path
        end

        if not fileExists(targetActivePath) then
            table.insert(failedList, {"predecrypt_not_found", targetActivePath})
            goto continue_path
        end
        if fileSize(targetActivePath) <= 0 then
            table.insert(failedList, {"predecrypt_empty", targetActivePath})
            goto continue_path
        end

        local meta = Crypto.decrypt(targetActivePath, active_decrypted)
        if activeMovedViaRoot then os.remove(targetActivePath) end

        if meta then
            local activeFile = io.open(active_decrypted, "r")
            if activeFile then
                local activeContent = activeFile:read("*a")
                activeFile:close()
                os.remove(active_decrypted)

                local jsonActive = nil
                local ok2, err2 = pcall(function()
                    jsonActive = json.decode(activeContent)
                end)
                if not ok2 or not jsonActive then
                    table.insert(failedList, {"decode_active_failed", path})
                    goto continue_path
                end

                local gameEvents = jsonActive.gameEvents or {}
                if #gameEvents == 0 then
                    table.insert(failedList, {"no_active_events", path})
                    goto continue_path
                end

                local labels = {}
                for i = 1, #gameEvents do labels[i] = tostring(gameEvents[i]) end

                local selections = ui.chooseEvents(labels, "select_events_patch", path)
                if not selections then
                    table.insert(failedList, {"user_cancelled", path})
                    goto continue_path
                end

                if not jsonMod then
                    table.insert(failedList, {"rewards_unavailable", path})
                    goto continue_path
                end
                local eventRewards = jsonMod.eventRewards

                local selectionsExist = false
                for _, selected in pairs(selections) do
                    if selected then selectionsExist = true; break end
                end

                if selectionsExist then
                    local fileTaskDone = false

                    scheduler:add(function(finishTask)
                        local loopOk, loopErr = pcall(function()
                            for idx, selected in pairs(selections) do
                                if selected then
                                    local eventName = gameEvents[idx]
                                    if eventName then
                                        local eventPath = path .. eventName .. ".json"
                                        local targetEventPath = eventPath
                                        local secureEventCopy = safeWorkspace .. eventName .. ".json"
                                        local decryptedPath = hasRoot and (safeWorkspace .. "." .. eventName) or (path .. "." .. eventName)
                                        local eventMovedViaRoot = false

                                        local testEventOpen = io.open(eventPath, "r")
                                        if testEventOpen then
                                            testEventOpen:close()
                                        elseif hasRoot then
                                            Shell.su("cp \"" .. eventPath .. "\" \"" .. secureEventCopy .. "\"")
                                            Shell.su("chmod 777 \"" .. secureEventCopy .. "\"")

                                            if not fileExists(secureEventCopy) then
                                                LOG.warn("EventPatch", "Root event copy FAILED for: " .. secureEventCopy)
                                                table.insert(failedList, {"root_copy_failed", eventPath})
                                                goto next_event
                                            end

                                            targetEventPath = secureEventCopy
                                            eventMovedViaRoot = true
                                        else
                                            table.insert(failedList, {"skipped_unreadable", eventName})
                                            goto next_event
                                        end

                                        if not fileExists(targetEventPath) then
                                            table.insert(failedList, {"predecrypt_event_not_found", targetEventPath})
                                            goto next_event
                                        end
                                        if fileSize(targetEventPath) <= 0 then
                                            table.insert(failedList, {"predecrypt_event_empty", targetEventPath})
                                            goto next_event
                                        end

                                        local eventMeta = Crypto.decrypt(targetEventPath, decryptedPath)
                                        if eventMovedViaRoot then os.remove(targetEventPath) end

                                        if eventMeta then
                                            local eventFile = io.open(decryptedPath, "r+")
                                            if eventFile then
                                                local writeOk, writeErr = pcall(function()
                                                    local eventContent = eventFile:read("*a")
                                                    local jsonEvent = json.decode(eventContent)

                                                    jsonEvent.eventRewards = eventRewards
                                                    jsonEvent.minRankToJoin = 0
                                                    jsonEvent.rankBrackets = 2

                                                    local function patchText(v)
                                                        local text = type(v) == "table" and (v.value or "") or (v or "")
                                                        local localize = type(v) == "table" and (v.localize or "") or ""
                                                        text = text:gsub("%s*%(Patched%)", "")
                                                        text = text .. " (Patched)"
                                                        return { value = text, localize = localize }
                                                    end

                                                    jsonEvent.name = patchText(jsonEvent.name)
                                                    jsonEvent.description = patchText(jsonEvent.description)

                                                    local encodedEvent = json.encode(jsonEvent)
                                                    eventFile:seek("set", 0)
                                                    eventFile:write(encodedEvent)
                                                    eventFile:flush()
                                                    eventFile:close()

                                                    if eventMovedViaRoot and hasRoot then
                                                        local secureEncryptedOut = safeWorkspace .. eventName .. "_patched.json"
                                                        Crypto.encrypt(decryptedPath, secureEncryptedOut, eventMeta)
                                                        Shell.su("cp \"" .. secureEncryptedOut .. "\" \"" .. eventPath .. "\"")
                                                        Shell.su("chmod 660 \"" .. eventPath .. "\"")
                                                        os.remove(secureEncryptedOut)
                                                    else
                                                        Crypto.encrypt(decryptedPath, eventPath, eventMeta)
                                                    end

                                                    table.insert(successList, eventName)
                                                end)

                                                if not writeOk then
                                                    pcall(function() eventFile:close() end)
                                                    table.insert(failedList, {"processing_failed", eventName, tostring(writeErr)})
                                                end
                                                os.remove(decryptedPath)
                                            else
                                                table.insert(failedList, {"cannot_open_decrypted", decryptedPath})
                                            end
                                        else
                                            table.insert(failedList, {"decrypt_event_failed", eventName})
                                        end
                                    end
                                end
                                ::next_event::
                            end
                        end)

                        if not loopOk then
                            table.insert(failedList, {"loop_crash", tostring(loopErr)})
                        end

                        finishTask()
                        fileTaskDone = true
                    end)

                    while not fileTaskDone do gg.sleep(50) end
                end
            else
                table.insert(failedList, {"cannot_open_active", path})
            end
        else
            table.insert(failedList, {"decrypt_active_failed", path})
        end
        ::continue_path::
    end

    -- Cleanup workspace
    if hasRoot then
        Shell.su("rm -rf \"" .. safeWorkspace .. "\"")
    end

    cb({ successList = successList, failedList = failedList, restart = #successList > 0 })
end

-- ── Restore events ──────────────────────────────────────────────────────────

function M.restoreEvents(ui, cb)
    ui.onProgress("checking_permissions")
    local hasRoot = checkRoot()

    if hasRoot then
        memory:save("shell_states", {root=true})
    else
        memory:save("shell_states", {root=false})
    end

    ui.onProgress("scanning_files")

    local eventsPath = game_path .. "/files/content_cache/json/events/"

    local successList = {}
    local failedList = {}

    local safeWorkspace = gg.EXT_FILES_DIR .. "/.void_cache/"
    if hasRoot then
        Shell.su("mkdir -p \"" .. safeWorkspace .. "\"")
        Shell.su("chmod 777 \"" .. safeWorkspace .. "\"")
        if not dirExists(safeWorkspace) then
            table.insert(failedList, {"workspace_creation_failed", safeWorkspace})
            cb({ successList = successList, failedList = failedList,
                 earlyExit = { "restore_results_title", "workspace_creation_failed_dialog", safeWorkspace } })
            return
        end
        LOG.dbg("EventRestore", "Workspace verified: " .. safeWorkspace)
    end

    do
        local path = eventsPath
        local active = path .. "active_events.json"
        local active_decrypted = hasRoot and (safeWorkspace .. ".active_events") or (path .. ".active_events")
        local targetActivePath = active
        local activeMovedViaRoot = false

        local testOpen = io.open(active, "r")
        if testOpen then
            testOpen:close()
        elseif hasRoot then
            local secureActiveCopy = safeWorkspace .. "active_events.json"
            Shell.su("cp \"" .. active .. "\" \"" .. secureActiveCopy .. "\"")
            Shell.su("chmod 777 \"" .. secureActiveCopy .. "\"")

            if not fileExists(secureActiveCopy) then
                LOG.warn("EventRestore", "Root copy verification FAILED for: " .. secureActiveCopy)
                table.insert(failedList, {"root_copy_failed", active})
                goto continue_path
            end

            targetActivePath = secureActiveCopy
            activeMovedViaRoot = true
        else
            table.insert(failedList, {"file_inaccessible", path})
            goto continue_path
        end

        if not fileExists(targetActivePath) then
            table.insert(failedList, {"predecrypt_not_found", targetActivePath})
            goto continue_path
        end
        if fileSize(targetActivePath) <= 0 then
            table.insert(failedList, {"predecrypt_empty", targetActivePath})
            goto continue_path
        end

        local meta = Crypto.decrypt(targetActivePath, active_decrypted)
        if activeMovedViaRoot then os.remove(targetActivePath) end

        if meta then
            local activeFile = io.open(active_decrypted, "r")
            if activeFile then
                local activeContent = activeFile:read("*a")
                activeFile:close()
                os.remove(active_decrypted)

                local jsonActive = nil
                local ok, err = pcall(function()
                    jsonActive = json.decode(activeContent)
                end)

                if ok and jsonActive then
                    local gameEvents = jsonActive.gameEvents or {}
                    if #gameEvents > 0 then
                        local labels = {}
                        for i = 1, #gameEvents do labels[i] = tostring(gameEvents[i]) end

                        local selections = ui.chooseEvents(labels, "select_events_restore", path)

                        if selections then
                            local fileTaskDone = false

                            scheduler:add(function(finishTask)
                                pcall(function()
                                    for idx, selected in pairs(selections) do
                                        if selected then
                                            local eventName = gameEvents[idx]
                                            if eventName then
                                                local eventPath = path .. eventName .. ".json"

                                                local removed, remErr = os.remove(eventPath)

                                                if not removed and hasRoot then
                                                    Shell.su("rm \"" .. eventPath .. "\"")
                                                    local check = Shell.su("[ -f \"" .. eventPath .. "\" ] && echo yes || echo no")
                                                    if check == "no" then
                                                        removed = true
                                                    else
                                                        remErr = "Root removal failed or rejected"
                                                    end
                                                end

                                                if removed then
                                                    table.insert(successList, eventName)
                                                else
                                                    table.insert(failedList, {"delete_failed", eventName, tostring(remErr)})
                                                end
                                            end
                                        end
                                    end
                                end)
                                finishTask()
                                fileTaskDone = true
                            end)

                            while not fileTaskDone do gg.sleep(50) end
                        end
                    else
                        table.insert(failedList, {"no_active_events", path})
                    end
                else
                    table.insert(failedList, {"decode_active_failed", path})
                end
            else
                table.insert(failedList, {"cannot_open_active", path})
            end
        else
            table.insert(failedList, {"decrypt_active_failed", path})
        end
        ::continue_path::
    end

    -- Cleanup workspace
    if hasRoot then
        Shell.su("rm -rf \"" .. safeWorkspace .. "\"")
    end

    cb({ successList = successList, failedList = failedList, restart = #successList > 0 })
end

return M
