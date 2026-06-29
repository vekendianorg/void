--[[
  Settings Tab - Script settings and UI customization
  Features: Memory info, background opacity, background RGB,
            accent RGB, logo RGB, sub-text RGB

  All color preferences are saved globally (PID-independent) via
  memory:save_global so they survive game restarts without being cleared
  by a process change.
]]


-- =========================
-- Helpers
-- =========================
local function deepCopy(orig, seen)
    if type(orig) ~= "table" then
        return orig
    end
    if seen and seen[orig] then
        return seen[orig]
    end
    local copy = {}
    seen = seen or {}
    seen[orig] = copy
    for k, v in pairs(orig) do
        copy[deepCopy(k, seen)] = deepCopy(v, seen)
    end
    return copy
end

local function getFileName(path)
    path = tostring(path or "")
    local name = path:match("([^/\\]+)$") or "background image.png"
    name = name:gsub("[^%w%._%-]", "_")
    if name == "" then
        name = "background image.png"
    end
    return name
end

local function safeJoinPath(folder, name)
    folder = tostring(folder or "")
    name = getFileName(name)
    if folder:sub(-1) == "/" then
        return folder .. name
    end
    return folder .. "/" .. name
end

local function bytesToHex(data)
    if type(data) ~= "string" then
        return nil
    end
    return (data:gsub(".", function(c)
        return string.format("%02x", string.byte(c))
    end))
end

local function hexToBytes(hex)
    if type(hex) ~= "string" then
        return nil
    end
    hex = hex:gsub("%s+", "")
    if hex == "" then
        return ""
    end
    if #hex % 2 ~= 0 then
        return nil
    end
    local out = hex:gsub("..", function(cc)
        local n = tonumber(cc, 16)
        if not n then
            return ""
        end
        return string.char(n)
    end)
    return out
end

local function serializeValue(v, seen)
    local t = type(v)
    if t == "string" then
        return string.format("%q", v)
    elseif t == "number" or t == "boolean" then
        return tostring(v)
    elseif t == "table" then
        if seen and seen[v] then
            return "nil"
        end
        seen = seen or {}
        seen[v] = true
        local parts = {}
        for k, val in pairs(v) do
            local keyType = type(k)
            local keyStr
            if keyType == "string" then
                keyStr = "[" .. string.format("%q", k) .. "]"
            elseif keyType == "number" then
                keyStr = "[" .. tostring(k) .. "]"
            elseif keyType == "boolean" then
                keyStr = "[" .. tostring(k) .. "]"
            else
                goto continue
            end
            local valueStr = serializeValue(val, seen)
            if valueStr ~= nil then
                parts[#parts + 1] = keyStr .. "=" .. valueStr
            end
            ::continue::
        end
        return "{" .. table.concat(parts, ",") .. "}"
    end
    return nil
end

local function serializeTable(t)
    return "return " .. serializeValue(t)
end

-- Tears down the current menuView, rebuilds it, and switches to it.
-- The correct sequence is: remove → build → switch.
-- switchToMenu() reads the global menuView, so createMenuView() must run
-- (and set menuView) before switchToMenu() is called.
local function rebuildMenu()
    MainHandler.post(function()
        -- Remove whichever overlay is currently visible.
        if activeView then
            pcall(function() windowManager.removeView(activeView) end)
        end
        menuView   = nil
        activeView = nil

        -- Build the new menu, restoring the Settings tab.
        createMenuView("settings")

        -- Now menuView is set; switch to it.
        switchToMenu()
    end)
end

local function saveAndRefresh()
    LOG.info("Settings", "UI preferences saved and refresh triggered")
    memory:save_global("ui_prefs", UI)
    MainHandler.post(function()
        if menuView then
            menuView.setBackground(getSkin(UI.BG, 16, 0, UI.STROKE))
        end
        if activeTabView then
            loadCategory("settings", activeTabView)
        end
    end)
end

local function applyTheme(shareId)
    local TAG = "ApplyTheme"
    if shareId and shareId ~= "" then
        local rawText, err = paste.get("https://paste.rs/" .. shareId)
        if rawText then
            local ok, exportData = pcall(load(rawText))
            if ok and type(exportData) == "table" and exportData.version then
                for k, v in pairs(exportData.ui) do
                    if UI[k] ~= nil then
                        UI[k] = deepCopy(v)
                    end
                end
                if exportData.img_url then
                    showToast(t("theme_downloading_bg"))
                    local dest = gg.FILES_DIR .. "/" .. (exportData.name or "background_image_" .. tostring(os.time()) .. ".png")
                    local path, dErr = catbox.download(exportData.img_url, dest)
                    if path then
                        UI.BG_IMAGE.PATH = path
                    else
                        LOG.error(TAG, "Background image download failed")
                    end
                else
                    UI.BG_IMAGE.PATH = "no_media"
                end
                memory:save_global("ui_prefs", UI)
                saveAndRefresh()
                showDialog(T("common.success"), t("theme_imported"), T("common.ok"))
            else
                showDialog(T("common.failed"), t("theme_invalid_bundle"), T("common.ok"))
            end
        else
            showDialog(T("common.failed"), t("theme_cloud_error", tostring(err)), T("common.ok"))
        end
    end
end

return function(container)

    -- Shorthand for this tab's translation namespace: t("auto_update.title")
    -- instead of T("settings.auto_update.title").
    local function t(key, ...) return T("settings." .. key, ...) end

    -- --- Updater ────────────────────────────────────────────────────────
    
    addModuleSep(container, t("section_updates"))
    
    -- ── Auto Update switch ────────────────────────────────────────────────────────
    addModule(container, "auto_update", t("auto_update.title"), t("auto_update.desc"), "switch", nil, function(done, state)
        if IS_DEV then
            showDialog(t("dev_mode_title"), t("auto_update.dev_mode_msg"), {T("common.ok")})
        else
            memory:save_global("auto_update", state)
        end
        done()
    end)
    
    -- ── Check for Update button ───────────────────────────────────────────────────
    addModule(container, "check_updates", t("check_updates.title"), t("check_updates.desc"), "button", nil, function(done)
        if IS_DEV then
            showDialog(t("dev_mode_title"), t("check_updates.dev_mode_msg"), {T("common.ok")})
            done()
            return
        end
    
        showToast(t("check_updates.checking"))
        local remote_ver, download_url, release_body = fetchLatestVersion()

        if not remote_ver then
            showDialog(t("check_updates.failed_title"), t("check_updates.failed_msg", tostring(download_url)), {T("common.ok")})
            done()
            return
        end
    
        if not versionNewer(remote_ver, CURRENT_VERSION) then
            showDialog(t("check_updates.up_to_date_title"), t("check_updates.up_to_date_msg", CURRENT_VERSION), {T("common.ok")})
            done()
            return
        end
    
        local msg = t("check_updates.available_msg", remote_ver, CURRENT_VERSION, release_body or t("check_updates.no_changelog"))
        showDialog(T("main.update_available_title"), msg, {T("common.update_button"), function()
            if not download_url then
                showDialog(T("common.failed"), t("check_updates.no_asset_msg"), {T("common.ok")})
                return
            end
    
            showToast(T("main.downloading_version", remote_ver))
            local content, err = paste.get(download_url)
            if not content then
                showDialog(t("check_updates.download_failed_title"), tostring(err), {T("common.ok")})
                return
            end
    
            local f = io.open(SCRIPT_PATH, "w")
            if not f then
                showDialog(t("check_updates.write_failed_title"), T("main.update_write_failed_msg", SCRIPT_PATH), {T("common.ok")})
                return
            end
            f:write(content)
            f:close()
    
            showDialog(t("check_updates.done_title"), t("check_updates.done_msg", remote_ver), {t("check_updates.restart_button"), function()
                MainHandler.post(function() os.exit() end)
            end}, {T("common.later")})
        end}, {T("common.cancel")})
    
        done()
    end)
    
    -- ── Language ──────────────────────────────────────────────────────────────
    addModuleSep(container, t("section_language"))

    do
        local langOptions     = {}
        local currentIndex    = 1
        for i, lang in ipairs(LANG_AVAILABLE) do
            langOptions[i] = lang.name
            if lang.code == LANG_CODE then currentIndex = i end
        end

        addModule(container, "language", t("language.title"), t("language.desc"), "spinner",
        { options = langOptions, default = currentIndex },
        function(done, item, index)
            local lang = LANG_AVAILABLE[index]
            if lang and setLanguage(lang.code) then
                showToast(t("language.changed", lang.name))
                showDialog(T("common.success"), t("language.restart_msg"), {T("common.ok")})
                done()
                rebuildMenu()
            else
                showToast(t("language.failed"))
                done()
            end
        end)
    end
    
    -- ── Read-only info ────────────────────────────────────────────────────────

    local function regionName()
        if BaseRegion == -2080896 then return t("region.other")
        elseif BaseRegion == 4 then return t("region.cpp_alloc")
        else return t("region.unknown") end
    end
    
    addModuleSep(container, t("section_memory"))

    addModule(container, "memory_range", t("memory_range.title"), t("memory_range.desc"), "ro", regionName(), nil)
    addModule(container, "gamestatus_address", t("gamestatus.title"), t("gamestatus.desc"), "ro", string.format("0x%X", BaseGameStatus or 0), nil)
    addModule(container, "gamestatus_raw_address", t("gamestatus_raw.title"), t("gamestatus_raw.desc"), "ro", string.format("0x%X", BaseGameStatusRaw or 0), nil)
    
    -- ── Session Control ────────────────────────────────────────────────────────
    addModule(container, "clear_memory", t("clear_memory.title"), t("clear_memory.desc"), "button", nil, function(done)
        LOG.info("Settings", "User triggered clear_all()")
        memory:clear_all()
        done()
    end)
    
    -- ── Log Management & Feedback ────────────────────────────────────────────
    addModuleSep(container, t("section_log_management"))

    -- Shared rate limiter (5s cooldown across send-log and feedback)
    local _last_action_time = 0
    local RATE_LIMIT_SEC    = 5

    local function check_rate_limit()
        local now = os.time()
        if (now - _last_action_time) < RATE_LIMIT_SEC then
            local remaining = RATE_LIMIT_SEC - (now - _last_action_time)
            showToast(t("rate_limit_msg", tostring(remaining)))
            return false
        end
        _last_action_time = now
        return true
    end

    addModule(container, "send_log", t("send_log.title"), t("send_log.desc"), "button", nil, function(done)
        local TAG_WH = "SendLog"

        if not check_rate_limit() then done() return end

        showToast(t("send_log.sending"))

        local wh = webhook.new("User Log")

        LOG.flush()

        local log_content = ""
        local f = io.open(LOG.path, "r")
        if f then
            log_content = f:read("*a") or ""
            f:close()
        end

        if log_content == "" then
            showDialog(t("send_log.empty_title"), t("send_log.empty_msg"), {T("common.ok")})
            done()
            return
        end

        local ok, code = wh:file(log_content, t("send_log.caption"))
        if ok then
            LOG.info(TAG_WH, "Log uploaded to cloud (HTTP " .. tostring(code) .. ")")
            showDialog(t("send_log.success_title"), t("send_log.success_msg"), {T("common.ok")})
        else
            LOG.error(TAG_WH, "Cloud upload failed: " .. tostring(code))
            showDialog(t("send_log.failed_title"), t("send_log.failed_msg", tostring(code)), {T("common.ok")})
        end

        done()
    end)

    addModule(container, "clear_log", t("clear_log.title"), t("clear_log.desc"), "button", nil, function(done)
        local TAG_CL = "ClearLog"
        local path = LOG.path
        if not path or path == "" then
            showDialog(T("common.failed"), t("clear_log.no_path_msg"), {T("common.ok")})
            done()
            return
        end

        local f, err = io.open(path, "w")
        if f then
            f:close()
            LOG.info(TAG_CL, "Log file cleared by user")
            showDialog(t("clear_log.success_title"), t("clear_log.success_msg"), {T("common.ok")})
        else
            showDialog(T("common.failed"), t("clear_log.failed_msg", tostring(err)), {T("common.ok")})
        end

        done()
    end)

    -- ── Feedback ──────────────────────────────────────────────────────────────
    addModuleSep(container, t("section_feedback"))

    addModule(container, "send_feedback", t("feedback.title"), t("feedback.desc"), "button", nil, function(done)
        local TAG_FB = "Feedback"

        if not check_rate_limit() then done() return end

        -- Step 1: pick category
        local category_keys = { "bug_report", "feature_request", "general" }
        local category_labels = {
            t("feedback.cat_bug"),
            t("feedback.cat_feature"),
            t("feedback.cat_general"),
        }

        local cat_choice = showList(t("feedback.pick_category"), t("feedback.pick_category_desc"), category_labels)
        if not cat_choice or cat_choice == 0 then done() return end

        local category   = category_labels[cat_choice]
        local cat_color  = ({ 0xED4245, 0x5865F2, 0x57F287 })[cat_choice]
        local cat_emoji  = ({ "🐛", "✨", "💬" })[cat_choice]

        -- Step 2: type message
        local result = showPrompt(t("feedback.write_title"), {
            { t("feedback.write_hint"), "text", "" }
        })
        if not result or not result[1] or result[1] == "" then done() return end

        local message = result[1]
        if #message < 5 then
            showDialog(t("feedback.too_short_title"), t("feedback.too_short_msg"), {T("common.ok")})
            done()
            return
        end

        showToast(t("feedback.sending"))

        local wh = webhook.new("User Feedback")
        local ok, code = wh:embed({
            title       = cat_emoji .. "  " .. category,
            description = message,
            color       = cat_color,
            fields      = {
                { name = t("feedback.field_version"), value = tostring(CURRENT_VERSION or "?"), inline = true },
                { name = t("feedback.field_arch"),    value = tostring(DEVICE_ARCH     or "?"), inline = true },
            },
            footer    = { text = "VOID Feedback" },
            timestamp = true,
        })

        if ok then
            LOG.info(TAG_FB, "Feedback sent: [" .. category .. "] " .. message)
            showDialog(t("feedback.success_title"), t("feedback.success_msg"), {T("common.ok")})
        else
            LOG.error(TAG_FB, "Feedback send failed: " .. tostring(code))
            showDialog(t("feedback.failed_title"), t("feedback.failed_msg"), {T("common.ok")})
        end

        done()
    end)

    -- ── Console ───────────────────────────────────────────────────────────────
    addModuleSep(container, t("section_console"))

    do
        local crashCap, logCap = CrashHandler.getCaps()

        addModule(container, "console_crash_cap", t("console_crash_cap.title"), t("console_crash_cap.desc"),
        "slider", { min = 5, max = 500, current = crashCap, title = t("console_crash_cap.slider") },
        function(done, val)
            local n = tonumber(val) or crashCap
            CrashHandler.setCaps(n, nil)   -- nil = keep existing log cap
            showToast(t("console_cap_applied", tostring(n)))
            done()
        end)

        addModule(container, "console_log_cap", t("console_log_cap.title"), t("console_log_cap.desc"),
        "slider", { min = 5, max = 2000, current = logCap, title = t("console_log_cap.slider") },
        function(done, val)
            local n = tonumber(val) or logCap
            CrashHandler.setCaps(nil, n)   -- nil = keep existing crash cap
            showToast(t("console_cap_applied", tostring(n)))
            done()
        end)
    end

    -- ── Custom Colors Info ────────────────────────────────────────────────────
    -- Allow user to change colors of this script.
    addModuleSep(container, t("section_ui_customizations"))
    
    addModule(container, "theme_store", t("theme_store.title"), t("theme_store.desc"), "button", nil,
    function(done)
        local TAG = "ThemeStore"
        LOG.info(TAG, "Opening theme store...")

        local raw, err = paste.get("https://raw.githubusercontent.com/vekendianorg/void-themes/refs/heads/main/index.json")
        if not raw then
            showDialog(T("common.failed"), t("theme_store.unreachable_msg", tostring(err)), {T("common.ok")})
            done()
            return
        end

        local index = nil
        local ok, parseErr = pcall(function()
            index = json.decode(raw)
        end)

        if not ok or not index or not index.themes then
            showDialog(T("common.failed"), t("theme_store.parse_failed_msg"), {T("common.ok")})
            done()
            return
        end

        local allThemes = index.themes
        local currentThemes = allThemes

        local function openStore(allThemes, currentThemes)
            local isFiltered = currentThemes ~= allThemes
            local title = t("theme_store.list_title")
            local desc  = isFiltered
                and t("theme_store.search_results_desc", tostring(#currentThemes))
                or  t("theme_store.available_desc", tostring(#allThemes))
        
            local items = {}
            for _, theme in ipairs(currentThemes) do
                table.insert(items, theme.name .. " • " .. t("theme_store.by_author", theme.author))
            end
        
            -- Search as first item
            table.insert(items, 1, t("theme_store.search_item"))
            if isFiltered then
                table.insert(items, 2, t("theme_store.clear_search_item"))
            end
        
            return showList(title, desc, items)
        end

        -- Store loop
        local refreshMenu = false
        while true do
            local choice = openStore(allThemes, currentThemes)
        
            if choice == 0 then
                break -- cancelled / outside tap
        
            elseif choice == 1 then
                -- Search
                local result = showPrompt(t("theme_store.search_title"), {
                    {t("theme_store.search_hint"), "text", ""}
                })
                if result and result[1] ~= "" then
                    local q = result[1]:lower()
                    local filtered = {}
                    for _, theme in ipairs(allThemes) do
                        if theme.name:lower():find(q, 1, true)
                        or theme.author:lower():find(q, 1, true)
                        or (theme.description and theme.description:lower():find(q, 1, true)) then
                            table.insert(filtered, theme)
                        end
                    end
                    
                    currentThemes = filtered
                    
                    if #filtered == 0 then
                        showToast(t("theme_store.no_results", result[1]))
                    end
                end
        
            elseif currentThemes ~= allThemes and choice == 2 then
                -- Clear search
                currentThemes = allThemes
        
            else
                -- Theme selected — offset by search + clear buttons
                local offset = currentThemes ~= allThemes and 2 or 1
                local theme = currentThemes[choice - offset]
                if theme then
                    local choice = showDialog(
                        theme.name,
                        t("theme_store.detail_msg", theme.author, theme.description or "", theme.id),
                        {t("theme_store.install_button"), function() applyTheme(theme.id); refreshMenu = true end}, {T("common.cancel")}
                    )
                end
            end
            if refreshMenu then break end
        end
        
        done()
        rebuildMenu()
    end)
    
    addModule(container, "reset_theme", t("reset_theme.title"), t("reset_theme.desc"), "button", nil, function(done)
        local TAG = "ResetTheme"
        LOG.info(TAG, "User triggered theme reset")
        
        memory:delete_global("ui_prefs")
        UI = loadModule("configs/colors.lua")
        
        done()
        rebuildMenu()
    end)
    
    addModule(container, "import_theme", t("import_theme.title"), t("import_theme.desc"), "input", {
        { hint = t("import_theme.hint"), value = "", type = "text" }
    }, function(done, val)
        local TAG = "ImportTheme"
        local shareId = (type(val) == "table") and val[1] or val
        LOG.info(TAG, "Importing theme with share ID: " .. tostring(shareId))
        
        applyTheme(shareId)
    
        done()
        rebuildMenu()
    end)
    
    addModule(container, "export_theme", t("export_theme.title"), t("export_theme.desc"), "button", nil, function(done)
        local TAG = "ExportTheme"
        LOG.info(TAG, "User triggered theme export")
        local exportUI = deepCopy(UI)
    
        local function finalizeExport(imageUrl)
            local exportData = {
                version = 5,
                kind = "theme_bundle_url",
                name = (UI.BG_IMAGE.PATH:match("([^/\\]+)$") or "background_image_" .. tostring(os.time()).. ".png"),
                ui = exportUI,
                img_url = imageUrl
            }
    
            local payload = serializeTable(exportData)
            local link, err = paste.post(payload)
    
            if link then
                local pasteId = link:match("[^/]+$")
                gg.copyText(pasteId)
                showDialog(T("common.success"), t("export_theme.share_id_msg", pasteId), T("common.ok"))
            else
                showDialog(T("common.failed"), t("export_theme.upload_failed_msg", tostring(err)), T("common.ok"))
            end
            done()
        end
    
        if UI.BG_IMAGE and UI.BG_IMAGE.PATH and UI.BG_IMAGE.PATH ~= "no_media" then
            showDialog(t("export_theme.size_warning_title"), t("export_theme.size_warning_msg"),
            {T("common.yes"), function()
                showToast(t("export_theme.uploading_bg"))
                local url, err = catbox.upload(UI.BG_IMAGE.PATH)
                if url then finalizeExport(url) else showDialog(t("export_theme.image_upload_failed_title"), t("export_theme.image_upload_failed_msg", err), T("common.ok")); done() end
            end},
            {T("common.no")})
        else
            finalizeExport(nil)
        end
        
        done()
    end)
    
    -- Tabs icon
    addModule(container, "tabs_icon", t("tabs_icon.title"), t("tabs_icon.desc"), "input", {
        { hint = t("tabs_icon.hint"), value = UI.TABS_ICON, type = "text" }
    }, function(done, val)
        if val == nil or val == "" then
            showToast(t("tabs_icon.empty_error"))
            done()
        else
            UI.TABS_ICON = val
            saveAndRefresh()
            done()
            rebuildMenu()
        end
    end)

    -- ── Background Opacity ────────────────────────────────────────────────────
    -- Writes to the alpha byte of UI.BG; HEADER, CARD, and GLASS track it at
    -- fixed ratios so the visual hierarchy stays consistent.

    local function getAlpha(color)
        return (color >> 24) & 0xFF
    end

    local function setLayerAlpha(a)
        local function recolor(base, ratio)
            return (math.min(math.floor(a * ratio), 0xFF) << 24) | (base & 0x00FFFFFF)
        end
        UI.BG = recolor(UI.BG, 1.00)
        UI.HEADER = recolor(UI.HEADER, 1.25)
        UI.CARD = recolor(UI.CARD, 1.55)
        UI.GLASS = recolor(UI.GLASS, 0.75)
    end

    addModule(container, "bg_opacity", t("bg_opacity.title"),
        t("bg_opacity.desc"),
        "slider",
        {min = 1, max = 255, current = getAlpha(UI.BG), title = t("slider.alpha")},
        function(done, val)
            setLayerAlpha(val)
            saveAndRefresh()
            done()
        end
    )
    
    -- ── Background Image Opacity ─────────────────────
    addModule(container, "bg_image_opacity", t("bg_image_opacity.title"),
        t("bg_image_opacity.desc"),
        "slider",
        {min = 0, max = 255, current = UI.BG_IMAGE.ALPHA & 0xFF, title = t("slider.alpha")},
        function(done, val) 
            UI.BG_IMAGE.ALPHA = val & 0xFF
            
            saveAndRefresh()
            done()
            rebuildMenu()
        end
    )

    -- ── Background Image ────────────────────────────────────────────────
    -- Updates the absolute storage location path pointing to the background image image.

    addModule(container, "bg_image_picker", t("bg_image_picker.title"), t("bg_image_picker.desc"), "button", nil, function(done)
        local response = gg.prompt(
            { t("bg_image_picker.path_label"), t("bg_image_picker.remove_label") },
            { UI.BG_IMAGE.PATH == "no_media" and gg.EXT_STORAGE or UI.BG_IMAGE.PATH, false },
            { "file", "checkbox" }
        )
        
        if response then
            if response[2] == true then
                UI.BG_IMAGE.PATH = "no_media"
                saveAndRefresh()
                showDialog(t("bg_image_picker.success_title"), t("bg_image_picker.removed_msg"), {T("common.ok")})
            else
                if response[1] then
                    local parsedPath = response[1]:gsub("^%s*(.-)%s*$", "%1")
        
                    if parsedPath ~= "" then
                        local verificationHandle = io.open(parsedPath, "r")
                        
                        if verificationHandle then
                            verificationHandle:close()
                            
                            UI.BG_IMAGE.PATH = parsedPath
                            saveAndRefresh()
                            showDialog(t("bg_image_picker.success_title"), t("bg_image_picker.added_msg"), {T("common.ok")})
                        else
                            showDialog(T("common.failed"), t("bg_image_picker.not_found_msg", tostring(parsedPath)), {T("common.ok")})
                        end
                    end
                end
            end
        end
        
        done()
        rebuildMenu()
    end)

    -- ── Background RGB ────────────────────────────────────────────────────────
    -- Adjusts the R, G, B hue of UI.BG. HEADER and CARD are derived at fixed
    -- brightness ratios so the layer hierarchy stays intact. Alphas are
    -- preserved as-is (use Background Opacity to change them).

    local function setBgRgb(r, g, b)
        local function recolorRgb(base, ratio)
            local a = (base >> 24) & 0xFF
            local nr = math.min(math.floor(r * ratio), 0xFF)
            local ng = math.min(math.floor(g * ratio), 0xFF)
            local nb = math.min(math.floor(b * ratio), 0xFF)
            return (a << 24) | (nr << 16) | (ng << 8) | nb
        end
        UI.BG = recolorRgb(UI.BG, 1.00)
        UI.HEADER = recolorRgb(UI.HEADER, 1.30)
        UI.CARD = recolorRgb(UI.CARD, 1.55)
    end

    addModule(container, "bg_rgb", t("bg_rgb.title"),
        t("bg_rgb.desc"),
        "slider",
        {
            {min = 0, max = 255, current = (UI.BG >> 16) & 0xFF, title = t("slider.r")},
            {min = 0, max = 255, current = (UI.BG >> 8) & 0xFF, title = t("slider.g")},
            {min = 0, max = 255, current = UI.BG & 0xFF, title = t("slider.b")},
        },
        function(done, vals)
            setBgRgb(vals[1], vals[2], vals[3])
            saveAndRefresh()
            done()
        end
    )

    -- ── Accent RGB ────────────────────────────────────────────────────────────
    -- ACCENT uses fixed alpha 0x60 (38% opaque).
    -- MUTED is derived automatically at alpha 0x4D with each channel halved.

    local function buildAccent(r, g, b)
        UI.ACCENT = (0x60 << 24) | (r << 16) | (g << 8) | b
        UI.MUTED = (0x4D << 24) | ((r >> 1) << 16) | ((g >> 1) << 8) | (b >> 1)
    end

    addModule(container, "accent_rgb", t("accent_rgb.title"),
        t("accent_rgb.desc"),
        "slider",
        {
            {min = 0, max = 255, current = (UI.ACCENT >> 16) & 0xFF, title = t("slider.r")},
            {min = 0, max = 255, current = (UI.ACCENT >> 8) & 0xFF, title = t("slider.g")},
            {min = 0, max = 255, current = UI.ACCENT & 0xFF, title = t("slider.b")},
        },
        function(done, vals)
            buildAccent(vals[1], vals[2], vals[3])
            saveAndRefresh()
            done()
        end
    )

    -- ── Logo (Highlight) RGB ──────────────────────────────────────────────────
    -- LOGO is always fully opaque (alpha 0xFF).
    -- Used for labels, icons, slider arrows, and the wordmark.

    local function buildLogo(r, g, b)
        UI.LOGO = (0xFF << 24) | (r << 16) | (g << 8) | b
    end

    addModule(container, "logo_rgb", t("logo_rgb.title"),
        t("logo_rgb.desc"),
        "slider",
        {
            {min = 0, max = 255, current = (UI.LOGO >> 16) & 0xFF, title = t("slider.r")},
            {min = 0, max = 255, current = (UI.LOGO >> 8) & 0xFF, title = t("slider.g")},
            {min = 0, max = 255, current = UI.LOGO & 0xFF, title = t("slider.b")},
        },
        function(done, vals)
            buildLogo(vals[1], vals[2], vals[3])
            saveAndRefresh()
            done()
        end
    )

    -- ── Sub-text RGB ──────────────────────────────────────────────────────────
    -- SUB uses fixed alpha 0xDD (87% opaque).
    -- Used for descriptions and inactive tab labels.

    local function buildSub(r, g, b)
        UI.SUB = (0xDD << 24) | (r << 16) | (g << 8) | b
    end

    addModule(container, "sub_rgb", t("sub_rgb.title"),
        t("sub_rgb.desc"),
        "slider",
        {
            {min = 0, max = 255, current = (UI.SUB >> 16) & 0xFF, title = t("slider.r")},
            {min = 0, max = 255, current = (UI.SUB >> 8) & 0xFF, title = t("slider.g")},
            {min = 0, max = 255, current = UI.SUB & 0xFF, title = t("slider.b")},
        },
        function(done, vals)
            buildSub(vals[1], vals[2], vals[3])
            saveAndRefresh()
            done()
        end
    )
    
    -- ── Text RGB ──────────────────────────────────────────────────────────────
    -- Main text color used throughout the menu.
    
    local function buildText(r, g, b)
        UI.TEXT = (0xFF << 24) | (r << 16) | (g << 8) | b
        UI.LOGO = UI.TEXT
    end
    
    addModule(container, "text_rgb", t("text_rgb.title"),
        t("text_rgb.desc"),
        "slider",
        {
            {min = 0, max = 255, current = (UI.TEXT >> 16) & 0xFF, title = t("slider.r")},
            {min = 0, max = 255, current = (UI.TEXT >> 8) & 0xFF, title = t("slider.g")},
            {min = 0, max = 255, current = UI.TEXT & 0xFF, title = t("slider.b")},
        },
        function(done, vals)
            buildText(vals[1], vals[2], vals[3])
            saveAndRefresh()
            done()
        end
    )

    -- ── Window Size ───────────────────────────────────────────────────────────
    
    addModule(container, "win_width", t("win_width.title"),
        t("win_width.desc", RESIZE_MIN_W, RESIZE_MAX_W),
        "slider",
        {min = RESIZE_MIN_W, max = RESIZE_MAX_W, current = WIN_W, title = t("slider.width")},
        function(done, val)
            applyWindowResize(val, WIN_H)
            done()
        end
    )

    addModule(container, "win_height", t("win_height.title"),
        t("win_height.desc", RESIZE_MIN_H, RESIZE_MAX_H),
        "slider",
        {min = RESIZE_MIN_H, max = RESIZE_MAX_H, current = WIN_H, title = t("slider.height")},
        function(done, val)
            applyWindowResize(WIN_W, val)
            done()
        end
    )

end
