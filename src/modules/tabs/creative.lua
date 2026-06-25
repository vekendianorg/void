--[[
  Creative Tab — Custom-track features
  UI wiring only. Memory ops live in modules/ops/creative.lua.

  Flow for track features (verify, set length, rename):
    depth 1 → track list   (cancel = exit)
    depth 2 → action pick  (cancel = back to track list)
    depth 3 → action input (cancel = back to action pick)
]]

local ops = CrashHandler.loadFeature("modules/ops/creative.lua")

return function(container)
    local function t(key, ...) return T("creative." .. key, ...) end

    -- ── Copy Any ─────────────────────────────────────────────────────────────
    addArchModule(container, "copy_any", t("copy_any.title"), t("copy_any.desc"), "button", nil,
    function(done)
        ops.copyAny(function(ok, errKey, count)
            if ok then
                showToast(t("copy_any.applied", tostring(count)))
            else
                showToast(T(errKey or "common.failed"), true)
            end
        end)
        done()
    end)

    -- ── Track Editor (verify / set length / rename) ───────────────────────────
    addModule(container, "track_editor", t("track_editor.title"), t("track_editor.desc"), "button", nil,
    function(done)
        -- Loading the track list is a scheduled op; we need it before showing any UI.
        -- Show a loading toast, then enter the depth loop once results arrive.
        showToast(t("track_editor.loading"))

        ops.getCustomTracks(function(ok, tracksOrErr)
            if not ok then
                showToast(T(tracksOrErr or "creative.tracks_not_found"), true)
                done(); return
            end

            local tracks = tracksOrErr
            if #tracks == 0 then
                showToast(t("track_editor.no_tracks"), true)
                done(); return
            end

            -- Build display list: "Track Name  [✓]  (500m)" or "Track Name  [?]  (500m)"
            local display = {}
            for _, tr in ipairs(tracks) do
                local verified = tr.isVerified == 1 and " [✓]" or ""
                display[#display + 1] = string.format("%s%s  (%dm)", tr.nameStr, verified, tr.length)
            end

            local actions = {
                t("action.verify"),
                t("action.set_length"),
                t("action.rename"),
            }

            -- ── Depth loop ────────────────────────────────────────────────────
            -- depth 1 = pick a track
            -- depth 2 = pick an action
            -- depth 3 = action-specific input prompt
            local depth    = 1
            local track    = nil   -- chosen tracks[i] descriptor
            local actionIdx = nil

            while true do

                -- ── Depth 1: pick track ───────────────────────────────────────
                if depth == 1 then
                    local choice = showList(t("track_editor.title"), t("track_editor.select"), display)
                    if not choice or choice == 0 then
                        done(); return
                    end
                    track = tracks[choice]
                    depth = 2

                -- ── Depth 2: pick action ──────────────────────────────────────
                elseif depth == 2 then
                    local statusLine = (track.isVerified == 1)
                        and t("track_status.verified")
                        or  t("track_status.not_verified")
                    local subtitle = string.format("%s — %s  |  %s",
                        track.nameStr, statusLine, t("track_length", tostring(track.length)))

                    local choice = showList(subtitle, t("action.select"), actions)
                    if not choice or choice == 0 then
                        depth = 1   -- back to track list
                    else
                        actionIdx = choice
                        depth = 3
                    end

                -- ── Depth 3: action input ─────────────────────────────────────
                elseif depth == 3 then

                    -- ── Verify ───────────────────────────────────────────────
                    if actionIdx == 1 then
                        if track.isVerified == 1 then
                            showToast(t("verify.already_verified"))
                            depth = 2
                        else
                            ops.verifyTrack(track.elemPtr, function(ok2, errKey)
                                if ok2 then
                                    track.isVerified = 1
                                    -- Update display entry in-place so going back shows ✓
                                    local idx = track.index + 1
                                    local verified = " [✓]"
                                    display[idx] = string.format("%s%s  (%dm)",
                                        track.nameStr, verified, track.length)
                                    showToast(t("verify.applied", track.nameStr))
                                else
                                    showToast(T(errKey or "common.failed"), true)
                                end
                            end)
                            done(); return
                        end

                    -- ── Set Length ────────────────────────────────────────────
                    elseif actionIdx == 2 then
                        local result = showPrompt(
                            t("set_length.title") .. " — " .. track.nameStr,
                            {{ t("set_length.prompt", tostring(track.length)), "number", tostring(track.length) }}
                        )
                        if not result then
                            depth = 2
                        else
                            local newLen = tonumber(result[1])
                            if not newLen or newLen < 1 then
                                showToast(t("set_length.invalid"), true)
                                -- stay at depth 3
                            else
                                ops.setTrackLength(track.elemPtr, newLen, function(ok2, errKey, applied)
                                    if ok2 then
                                        track.length = applied
                                        local idx = track.index + 1
                                        local verified = track.isVerified == 1 and " [✓]" or ""
                                        display[idx] = string.format("%s%s  (%dm)",
                                            track.nameStr, verified, track.length)
                                        showToast(t("set_length.applied", track.nameStr, tostring(applied)))
                                    else
                                        showToast(T(errKey or "common.failed"), true)
                                    end
                                end)
                                done(); return
                            end
                        end

                    -- ── Rename ────────────────────────────────────────────────
                    elseif actionIdx == 3 then
                        local result = showPrompt(
                            t("rename.title") .. " — " .. track.nameStr,
                            {{ t("rename.prompt"), "text", track.nameStr }}
                        )
                        if not result then
                            depth = 2
                        else
                            local newName = result[1]
                            if not newName or newName == "" then
                                showToast(t("rename.empty"), true)
                                -- stay at depth 3
                            else
                                ops.renameTrack(track.elemPtr, newName, function(ok2, errKey, applied)
                                    if ok2 then
                                        local idx = track.index + 1
                                        local verified = track.isVerified == 1 and " [✓]" or ""
                                        display[idx] = string.format("%s%s  (%dm)",
                                            applied, verified, track.length)
                                        track.nameStr = applied
                                        showToast(t("rename.applied", applied))
                                    else
                                        showToast(T(errKey or "common.failed"), true)
                                    end
                                end)
                                done(); return
                            end
                        end
                    end

                end -- depth 3
            end -- while true
        end) -- getCustomTracks callback
    end) -- addModule track_editor

end
