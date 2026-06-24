--[[
  UI Module — Interface management and component builder.
  Creates and manages all UI elements: tabs, module cards, dialogs, animations.

  Dependencies: All Android imports from main.lua, UI constants, helper functions.
  Exports: loadCategory, addTab, addModule, updateRO, createIconView, createMenuView, initUI
]]


-- ─────────────────────────────────────────────────────────────────────────────
-- HELPERS
-- ─────────────────────────────────────────────────────────────────────────────

-- RTL language codes. Layout direction is flipped for these so the sidebar
-- appears on the right and text flows right-to-left.
local RTL_CODES = { ar = true, ur = true, he = true, fa = true }

-- Returns true when the active language is right-to-left.
local function isRTL()
    return RTL_CODES[LANG_CODE] == true
end

-- Resolves the correct Gravity constant for start-of-line alignment,
-- accounting for RTL layout direction.
local function gravityStart()
    return isRTL() and Gravity.RIGHT or Gravity.LEFT
end

-- Resolves the correct Gravity constant for end-of-line alignment.
local function gravityEnd()
    return isRTL() and Gravity.LEFT or Gravity.RIGHT
end

-- Sets layout direction on a view so Android mirrors padding and drawables.
-- API 17+; silently skipped on older devices.
local function setLayoutDir(view)
    if Build.VERSION.SDK_INT >= 17 then
        local dir = isRTL() and 1 or 0  -- LAYOUT_DIRECTION_RTL = 1, LTR = 0
        view.setLayoutDirection(dir)
    end
end


-- ─────────────────────────────────────────────────────────────────────────────
-- CATEGORY MANAGEMENT
-- ─────────────────────────────────────────────────────────────────────────────

-- Sidebar tab registry: id → { container, iconTV, labelTV }
-- Keyed by tab id string so loadCategory can recolor children without
-- relying on Java object equality as table keys.
local _tabData     = {}
local _activeTabId = nil

-- Per-tab rendered view-tree cache: id → LinearLayout already populated by
-- that tab's render function. On revisit we just swap this cached subtree
-- back into moduleContainer instead of clearing+re-running the render
-- function, which used to recreate every card's Java views from scratch on
-- every single tab switch. Reset alongside _tabData whenever the menu is
-- rebuilt from scratch (see _buildMenuTabs), since a full rebuild gets a
-- fresh moduleContainer anyway.
local _tabContentCache = {}

-- Animated "Loading..." indicator shown while a tab's content is being
-- built for the first time. Returns the view plus a stop() closure so the
-- caller can halt the postDelayed loop once real content is ready, rather
-- than leaving it ticking on a detached view.
--@return View spinner, fun() stop
local _LOADING_DOTS = { "", ".", "..", "..." }
local function _createLoadingSpinner()
    local spinner = TextView(activity)
    spinner.setTextColor(UI.SUB)
    spinner.setTextSize(1, 11)
    spinner.setGravity(Gravity.CENTER)
    spinner.setLayoutParams(LinLayoutParams(-1, dp(60)))

    local state = { running = true, frame = 0 }
    local function tick()
        if not state.running then return end
        state.frame = (state.frame % #_LOADING_DOTS) + 1
        spinner.setText(T("ui.loading") .. _LOADING_DOTS[state.frame])
        spinner.postDelayed(function() tick() end, 350)
    end
    tick()

    return spinner, function() state.running = false end
end

-- Set once, the first time the menu is ever built in this script run. Gates
-- the background preload below so it only fires at true cold start, not on
-- every rebuildMenu() (e.g. a Settings change tearing down and rebuilding
-- the menu mid-session).
local _earlySessionPreloadDone = false

-- Renders one tab id per MainHandler frame straight into _tabContentCache,
-- without ever touching moduleContainer — so it can run quietly in the
-- background without disturbing whatever tab the user is actually looking
-- at. Used only for the early-session warm-up; normal tab switches still
-- render lazily on first visit via loadCategory().
--@param ids string[]  Remaining tab ids to preload (consumed front-to-back)
local function _preloadTabsInBackground(ids)
    if #ids == 0 then return end
    local id = table.remove(ids, 1)
    MainHandler.post(Runnable({ run = function()
        if not _tabContentCache[id] then
            local setCategory = categoryHandlers[id]
            if setCategory then
                local tabContent = LinearLayout(activity)
                tabContent.setOrientation(1)
                tabContent.setLayoutParams(LinLayoutParams(-1, -2))
                local ok = pcall(function() setCategory(tabContent) end)
                if ok then
                    _tabContentCache[id] = tabContent
                end
            end
        end
        _preloadTabsInBackground(ids)
    end }))
end

-- Loads and displays a category (tab content) by ID.
-- Updates active tab styling and populates moduleContainer with category modules.
-- Cached tabs swap in instantly; uncached tabs show an animated loading
-- indicator and render on the next MainHandler frame so the UI thread stays
-- responsive even when a tab has dozens of cards.
--@param id string  Tab identifier to load
--@param tabView View  The tab container that was clicked
--@return nil
function loadCategory(id, tabView)
    LOG.info("loadCategory", "id=" .. tostring(id))
    if not moduleContainer or not tabView then
        LOG.warn("loadCategory", "EARLY RETURN — moduleContainer=" .. tostring(moduleContainer) .. " tabView=" .. tostring(tabView))
        return
    end

    -- Swap active tab styling immediately (zero Java work — just background + colors).
    if _activeTabId and _tabData[_activeTabId] then
        local prev = _tabData[_activeTabId]
        prev.container.setBackground(getSkin(UI.BG, 8))
        prev.iconTV.setTextColor(UI.SUB)
        prev.labelTV.setTextColor(UI.SUB)
    end
    if _tabData[id] then
        local curr = _tabData[id]
        curr.container.setBackground(getSkin(UI.ACCENT, 8))
        curr.iconTV.setTextColor(UI.TEXT)
        curr.labelTV.setTextColor(UI.TEXT)
    end

    _activeTabId  = id
    activeTabView = tabView

    moduleContainer.removeAllViews()

    -- Already built — instant swap, no Java view recreation at all.
    -- The Console tab is never cached so it always reflects the latest reports.
    if _tabContentCache[id] and id ~= "console" then
        moduleContainer.addView(_tabContentCache[id])
        return
    end

    -- Not cached yet: show the animated spinner, defer the (potentially
    -- expensive) module render to the next frame so the tap response stays
    -- instant, then cache the resulting view tree for next time.
    local spinner, stopSpinner = _createLoadingSpinner()
    moduleContainer.addView(spinner)

    local setCategory = categoryHandlers[id]
    MainHandler.post(Runnable({ run = function()
        stopSpinner()
        moduleContainer.removeAllViews()

        local tabContent = LinearLayout(activity)
        tabContent.setOrientation(1)
        tabContent.setLayoutParams(LinLayoutParams(-1, -2))

        if setCategory then
            local ok, err = pcall(function() setCategory(tabContent) end)
            if ok then
                -- Only cache on success — a failed render should retry next time.
                -- Console is intentionally left uncached (always re-rendered).
                if id ~= "console" then _tabContentCache[id] = tabContent end
            else
                local errTxt = TextView(activity)
                errTxt.setText(T("ui.category_error", tostring(err)))
                errTxt.setTextColor(UI.RED)
                tabContent.addView(errTxt)
            end
        else
            local errTxt = TextView(activity)
            errTxt.setText(T("ui.category_not_found"))
            errTxt.setTextColor(UI.SUB)
            tabContent.addView(errTxt)
        end

        -- Bail out if the user already switched to a different tab while
        -- this frame was queued — don't stomp whatever is now showing.
        if _activeTabId ~= id then return end
        moduleContainer.removeAllViews()
        moduleContainer.addView(tabContent)
    end }))
end


-- ─────────────────────────────────────────────────────────────────────────────
-- TAB BUILDER
-- ─────────────────────────────────────────────────────────────────────────────

-- Unicode icon map keyed by tab id.
-- Basic BMP characters that render on all Android versions.
local _TAB_ICONS = {
    account   = "\xe2\x8a\x99",  -- ⊙  profile/user
    player    = "\xe2\x96\xb7",  -- ▷  play/game
    vehicle   = "\xe2\x96\xb6",  -- ▶  vehicle
    adventure = "\xe2\x97\x86",  -- ◆  quest/adventure
    cups      = "\xe2\x96\xb2",  -- ▲  trophy/cups
    team      = "\xe2\x8a\x9e",  -- ⊞  grid/team
    event     = "\xe2\x96\xa3",  -- ▣  calendar/event
    creative  = "\xe2\x98\x85",  -- ★  star/creative
    shop      = "\xe2\x97\x91",  -- ◑  coin/shop
    other     = "\xe2\x8b\xaf",  -- ⋯  ellipsis/other
    settings  = "\xe2\x9a\x99",  -- ⚙  gear/settings
    about     = "\xe2\x84\xb9",  -- ℹ  info/about
    console   = "\xe2\x9a\xa0",  -- ⚠  warning/console
}

-- Creates a sidebar tab row (icon + label) that loads a category when tapped.
-- Registers icon+label refs in _tabData[id] for later recoloring by loadCategory.
-- In RTL mode the row is reversed (label on left, icon on right).
--@param parent View  Layout to add the tab to
--@param id string  Tab identifier
--@param name string  Display label
--@return View  The created tab container
function addTab(parent, id, name)
    local icon_char = UI.TABS_ICON or (_TAB_ICONS[id] or "•")

    local container = LinearLayout(activity)
    container.setOrientation(0)
    setLayoutDir(container)
    local params = LinLayoutParams(-1, -2)
    params.bottomMargin = dp(2)
    container.setLayoutParams(params)
    container.setPadding(dp(8), dp(8), dp(6), dp(8))
    container.setGravity(Gravity.CENTER_VERTICAL)
    container.setBackground(getSkin(UI.BG, 8))

    -- Icon
    local iconTV = TextView(activity)
    local iconParams = LinLayoutParams(dp(20), dp(20))
    if isRTL() then
        iconParams.leftMargin = dp(7)
    else
        iconParams.rightMargin = dp(7)
    end
    iconTV.setLayoutParams(iconParams)
    iconTV.setText(icon_char)
    iconTV.setTextColor(UI.SUB)
    iconTV.setTextSize(1, 13)
    iconTV.setGravity(Gravity.CENTER)
    iconTV.setTypeface(Typeface.DEFAULT_BOLD)

    -- Label
    local labelTV = TextView(activity)
    labelTV.setLayoutParams(LinLayoutParams(0, -2, 1.0))
    labelTV.setText(tostring(name))
    labelTV.setTextColor(UI.SUB)
    labelTV.setTextSize(1, 9)
    labelTV.setTypeface(Typeface.create("sans-serif", Typeface.BOLD))
    labelTV.setSingleLine(false)
    labelTV.setMaxLines(2)
    if isRTL() then
        labelTV.setGravity(Gravity.RIGHT)
        -- RTL: label first, then icon
        container.addView(labelTV)
        container.addView(iconTV)
    else
        container.addView(iconTV)
        container.addView(labelTV)
    end

    container.setOnClickListener(View.OnClickListener({
        onClick = function(v) loadCategory(id, container) end
    }))

    _tabData[id] = { container = container, iconTV = iconTV, labelTV = labelTV }
    parent.addView(container)
    return container
end


-- ─────────────────────────────────────────────────────────────────────────────
-- MODULE CARD BUILDER
-- ─────────────────────────────────────────────────────────────────────────────

-- Creates an interactive module card with various modes.
--
-- Mode descriptions:
--   "switch"  — Toggle on/off (state saved)
--   "button"  — Single action button
--   "ro"      — Read-only display (clickable to copy)
--   "spinner" — Dropdown selector (state saved)
--   "slider"  — Single or multi-slider input (state saved)
--   "input"   — Single or multi-line text input (state saved)
--
--@param parent View  Container to add the card to
--@param id string  Unique module identifier
--@param title string  Display title
--@param desc string  Description text
--@param mode string  "switch" | "button" | "ro" | "spinner" | "slider" | "input"
--@param extra any  Mode-specific data
--@param callback? fun(done:fun(), ...)  Called on action; must call done() when finished
--@return nil

-- Renders text into a TextView, turning markdown links [label](url) into
-- tappable links that open in the browser. If the text has no links (or the
-- rich-text path errors on this device) it falls back to plain setText.
local function setRichText(tv, text, linkColor)
    text = tostring(text or "")
    if not text:find("%[.-%]%(.-%)") then
        tv.setText(text)
        return
    end
    local ok = pcall(function()
        local function esc(s) return (s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")) end
        local html = esc(text):gsub("%[(.-)%]%((.-)%)", function(label, url)
            return '<a href="' .. url:gsub("&amp;", "&") .. '">' .. label .. '</a>'
        end)
        html = html:gsub("\n", "<br>")
        local spanned = (Build.VERSION.SDK_INT >= 24) and Html.fromHtml(html, 0) or Html.fromHtml(html)
        tv.setText(spanned)
        tv.setMovementMethod(LinkMovementMethod.getInstance())
        if linkColor then tv.setLinkTextColor(linkColor) end
    end)
    if not ok then tv.setText(text) end
end

currentInputs = {}
function addModule(parent, id, title, desc, mode, extra, callback)
    if processingStates[id] == nil then processingStates[id] = false end
    if toggleStates[id]     == nil then toggleStates[id]     = false end
    if lastClickTimes[id]   == nil then lastClickTimes[id]   = 0     end

    local card = LinearLayout(activity)
    local cp = LinLayoutParams(-1, -2)
    cp.bottomMargin = dp(10)
    card.setLayoutParams(cp)
    card.setOrientation(1)
    card.setPadding(dp(15), dp(12), dp(15), dp(12))
    card.setBackground(getSkin(UI.CARD, 12, 1, UI.STROKE))
    card.setAlpha(1.0)
    setLayoutDir(card)

    -- Debounce + visual feedback wrapper around user callbacks.
    local function safeCallback(...)
        local args = {...}
        local now = os.clock() * 1000
        if processingStates[id] or (now - lastClickTimes[id] < CLICK_COOLDOWN) then return end

        lastClickTimes[id]   = now
        processingStates[id] = true

        card.setBackground(getSkin(UI.ACCENT, 12, 1, UI.STROKE))
        card.setAlpha(0.25)

        local function done()
            MainHandler.post(Runnable({ run = function()
                processingStates[id] = false
                card.setBackground(getSkin(UI.CARD, 12, 1, UI.STROKE))
                card.setAlpha(1.0)
            end }))
        end

        Thread(Runnable({ run = function()
            if callback then
                local tb
                local ok, err = xpcall(
                    function() callback(done, table.unpack(args)) end,
                    function(e)
                        tb = (debug and debug.traceback) and debug.traceback(tostring(e), 2) or tostring(e)
                        return e
                    end)
                memory:save("toggle_states",  toggleStates)
                memory:save("input_states",   inputStates)
                memory:save("spinner_states", spinnerStates)
                memory:save("slider_states",  sliderStates)
                if not ok then
                    -- Capture so the failure surfaces in the Console tab; the
                    -- scheduler only sees crashes inside scheduler:add, not the
                    -- synchronous part of a module callback.
                    if CrashHandler then
                        CrashHandler.capture("Module:" .. tostring(id), err, tb)
                    else
                        print("Error in callback: " .. tostring(err))
                    end
                    done()
                end
            else
                Thread.sleep(CLICK_COOLDOWN)
                done()
            end
        end })).start()
    end

    -- Top row: title+desc on the left (or right for RTL), action widget on the other side.
    local topRow = LinearLayout(activity)
    topRow.setOrientation(0)
    topRow.setGravity(Gravity.CENTER_VERTICAL)
    setLayoutDir(topRow)

    local textLayout = LinearLayout(activity)
    textLayout.setLayoutParams(LinLayoutParams(0, -2, 1.0))
    textLayout.setOrientation(1)

    local t1 = TextView(activity)
    t1.setText(title)
    t1.setTextColor(UI.TEXT)
    t1.setTextSize(1, 14)
    t1.setTypeface(Typeface.create("sans-serif-medium", Typeface.BOLD))
    if isRTL() then t1.setGravity(Gravity.RIGHT) end

    local t2 = TextView(activity)
    setRichText(t2, desc, UI.LOGO)
    t2.setTextColor(UI.SUB)
    t2.setTextSize(1, 10)
    if isRTL() then t2.setGravity(Gravity.RIGHT) end

    textLayout.addView(t1)
    textLayout.addView(t2)
    topRow.addView(textLayout)

    local actionArea = LinearLayout(activity)
    actionArea.setGravity(gravityEnd() | Gravity.CENTER_VERTICAL)

    if mode == "switch" then
        local sw = TextView(activity)
        sw.setLayoutParams(LinLayoutParams(dp(36), dp(18)))
        local function updateSw()
            sw.setBackground(getSkin(toggleStates[id] and UI.ACCENT or UI.MUTED, 20))
        end
        updateSw()
        card.setOnClickListener(View.OnClickListener({ onClick = function()
            local now = os.clock() * 1000
            if processingStates[id] or (now - lastClickTimes[id] < CLICK_COOLDOWN) then return end
            toggleStates[id] = not toggleStates[id]
            updateSw()
            safeCallback(toggleStates[id])
        end }))
        actionArea.addView(sw)

    elseif mode == "button" then
        local btn = TextView(activity)
        btn.setLayoutParams(LinLayoutParams(dp(40), dp(35)))
        btn.setText(isRTL() and "<-" or "->")
        btn.setTextColor(UI.LOGO)
        btn.setGravity(Gravity.CENTER)
        btn.setTypeface(Typeface.create("sans-serif-black", Typeface.BOLD))
        btn.setTextSize(1, 14)
        btn.setBackground(getSkin(UI.ACCENT, 8))
        local runAction = function() safeCallback() end
        card.setOnClickListener(View.OnClickListener({ onClick = runAction }))
        btn.setOnClickListener(View.OnClickListener({ onClick = runAction }))
        actionArea.addView(btn)

    elseif mode == "ro" then
        local info = TextView(activity)
        info.setText(tostring(extra or T("ui.na")))
        info.setTextColor(UI.LOGO)
        info.setTypeface(Typeface.create("sans-serif-medium", Typeface.BOLD))
        info.setFocusable(true)
        info.setClickable(true)
        info.setOnClickListener(View.OnClickListener({ onClick = function(v)
            local cm = activity.getSystemService("clipboard")
            cm.setPrimaryClip(ClipData.newPlainText("Copy", tostring(v.getText())))
        end }))
        RO_Fields[id] = info
        actionArea.addView(info)

    elseif mode == "spinner" then
        local dropdown = LinearLayout(activity)
        dropdown.setOrientation(1)
        dropdown.setVisibility(View.GONE)
        dropdown.setPadding(0, dp(5), 0, dp(5))

        local savedIdx   = spinnerStates[id]
        local defaultIdx = extra.default or 1
        local currentIdx = savedIdx or defaultIdx
        local options    = extra.options or extra
        local initialTxt = options[currentIdx] or T("ui.spinner_select")

        local val = TextView(activity)
        val.setText(tostring(initialTxt))
        val.setTextColor(UI.LOGO)
        val.setTypeface(Typeface.create("sans-serif-medium", Typeface.BOLD))
        if isRTL() then val.setGravity(Gravity.RIGHT) end
        actionArea.addView(val)

        local function buildDropdown()
            dropdown.removeAllViews()
            for i, item in ipairs(options) do
                local opt = TextView(activity)
                opt.setText(tostring(item))
                opt.setTextColor(UI.TEXT)
                opt.setPadding(dp(12), dp(10), dp(12), dp(10))
                opt.setBackground(getSkin(UI.BG, 8, 1, UI.STROKE))
                if isRTL() then opt.setGravity(Gravity.RIGHT) end
                opt.setOnClickListener(View.OnClickListener({ onClick = function()
                    val.setText(tostring(item))
                    dropdown.setVisibility(View.GONE)
                    activeSpinner = nil
                    spinnerStates[id] = i
                    safeCallback(item, i)
                end }))
                local lp = LinLayoutParams(-1, -2)
                lp.topMargin = dp(4)
                dropdown.addView(opt, lp)
            end
        end

        card.setOnClickListener(View.OnClickListener({ onClick = function()
            if processingStates[id] then return end
            if activeSpinner and activeSpinner ~= dropdown then
                activeSpinner.setVisibility(View.GONE)
            end
            if dropdown.getVisibility() == View.GONE then
                buildDropdown()
                dropdown.setVisibility(View.VISIBLE)
                activeSpinner = dropdown
            else
                dropdown.setVisibility(View.GONE)
                activeSpinner = nil
            end
        end }))
        if isRTL() then
            topRow.addView(actionArea, 0)
        else
            topRow.addView(actionArea)
        end
        card.addView(topRow)
        card.addView(dropdown)

    elseif mode == "slider" then
        local sliderContainer = LinearLayout(activity)
        sliderContainer.setOrientation(1)
        sliderContainer.setPadding(dp(5), dp(5), dp(5), dp(5))

        local isMulti    = type(extra[1]) == "table"
        local slidersData = isMulti and extra or {extra}

        if not sliderStates[id] then
            if isMulti then
                local temp = {}
                for i, cfg in ipairs(slidersData) do temp[i] = cfg.current end
                sliderStates[id] = temp
            else
                sliderStates[id] = slidersData[1].current
            end
        end

        local currentValues = isMulti and sliderStates[id] or {sliderStates[id]}

        for i, cfg in ipairs(slidersData) do
            local valTxt = TextView(activity)
            valTxt.setText((cfg.title or T("ui.slider_default_title")) .. ": " .. currentValues[i])
            valTxt.setTextColor(UI.SUB)
            valTxt.setTextSize(1, 10)
            valTxt.setPadding(dp(2), dp(5), 0, 0)
            if isRTL() then valTxt.setGravity(Gravity.RIGHT) end
            sliderContainer.addView(valTxt)

            local controlsRow = LinearLayout(activity)
            controlsRow.setOrientation(0)
            controlsRow.setGravity(Gravity.CENTER_VERTICAL)

            local isLast     = (i == #slidersData)
            local seekParams = LinLayoutParams(0, dp(35), 1.0)
            -- Reserve space matching the goBtn's width on non-last rows so all
            -- seekbars line up. The goBtn sits on the end opposite reading
            -- direction, so the reserved margin flips for RTL.
            if not isLast then
                if isRTL() then
                    seekParams.setMargins(dp(40), 0, 0, 0)
                else
                    seekParams.setMargins(0, 0, dp(40), 0)
                end
            end

            local seek = SeekBar(activity)
            seek.setLayoutParams(seekParams)
            seek.setMax(cfg.max - cfg.min)
            seek.setProgress(currentValues[i] - cfg.min)
            seek.setOnSeekBarChangeListener(SeekBar.OnSeekBarChangeListener({
                onProgressChanged = function(s, p, f)
                    local newVal = p + cfg.min
                    currentValues[i] = newVal
                    if isMulti then sliderStates[id][i] = newVal else sliderStates[id] = newVal end
                    valTxt.setText((cfg.title or T("ui.slider_default_title")) .. ": " .. newVal)
                end
            }))
            controlsRow.addView(seek)

            if isLast then
                local goBtn = TextView(activity)
                goBtn.setLayoutParams(LinLayoutParams(dp(40), dp(30)))
                goBtn.setText(isRTL() and "<-" or "->")
                goBtn.setTextColor(UI.LOGO)
                goBtn.setGravity(Gravity.CENTER)
                goBtn.setTypeface(Typeface.create("sans-serif-black", Typeface.BOLD))
                goBtn.setBackground(getSkin(UI.ACCENT, 8))
                goBtn.setOnClickListener(View.OnClickListener({
                    onClick = function() safeCallback(sliderStates[id]) end
                }))
                if isRTL() then
                    controlsRow.addView(goBtn, 0)
                else
                    controlsRow.addView(goBtn)
                end
            end
            sliderContainer.addView(controlsRow)
        end
        card.addView(sliderContainer)

    elseif mode == "input" then
        local inputs = {}

        local inputContainer = LinearLayout(activity)
        inputContainer.setOrientation(1)
        inputContainer.setLayoutParams(LinLayoutParams(-1, -2))
        inputContainer.setPadding(0, dp(8), 0, 0)

        local dataKeys = type(extra) == "table" and extra or {extra}

        if not inputStates[id] then
            if #dataKeys > 1 then
                local temp = {}
                for i, data in ipairs(dataKeys) do
                    temp[i] = type(data) == "table" and data.value or ""
                end
                inputStates[id] = temp
            else
                inputStates[id] = type(dataKeys[1]) == "table" and dataKeys[1].value or ""
            end
        end

        local function performMod()
            local results = {}
            for i, e in ipairs(inputs) do results[i] = tostring(e.getText() or "") end

            if #results == 1 then inputStates[id] = results[1]
            else                  inputStates[id] = results end

            -- Dismiss keyboard and reset window flags.
            local imm = activity.getSystemService(Context.INPUT_METHOD_SERVICE)
            if menuView then imm.hideSoftInputFromWindow(menuView.getWindowToken(), 0) end
            for _, e in ipairs(inputs) do e.clearFocus() end
            mParams.flags = 8 | 32
            windowManager.updateViewLayout(menuView, mParams)

            if #results == 1 then safeCallback(results[1])
            else                  safeCallback(results) end
        end

        for i, data in ipairs(dataKeys) do
            local row = LinearLayout(activity)
            row.setOrientation(0)
            setLayoutDir(row)
            local rp = LinLayoutParams(-1, dp(35))
            if i > 1 then rp.topMargin = dp(6) end
            row.setLayoutParams(rp)

            local edit = EditText(activity)
            local editParams = LinLayoutParams(0, -1, 1.0)
            -- Reserve space for the trailing goBtn; flips side for RTL.
            if i < #dataKeys then
                if isRTL() then
                    editParams.setMargins(dp(48), 0, 0, 0)
                else
                    editParams.setMargins(0, 0, dp(48), 0)
                end
            end
            edit.setLayoutParams(editParams)

            local h        = type(data) == "table" and data.hint or data
            local savedVal = type(inputStates[id]) == "table" and inputStates[id][i] or inputStates[id]
            local itype    = type(data) == "table" and data.type or "text"

            edit.setHint(tostring(h))
            edit.setText(tostring(savedVal))
            if Build.VERSION.SDK_INT >= 12 then edit.setTextIsSelectable(true) end

            if itype == "password" then
                edit.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_VARIATION_PASSWORD)
                edit.setTransformationMethod(PasswordTransformationMethod.getInstance())
                edit.post(Runnable({ run = function()
                    edit.setTransformationMethod(PasswordTransformationMethod.getInstance())
                end }))
            elseif itype == "number" then
                edit.setInputType(InputType.TYPE_CLASS_NUMBER | InputType.TYPE_NUMBER_FLAG_DECIMAL | InputType.TYPE_NUMBER_FLAG_SIGNED)
            elseif itype == "date" then
                edit.setInputType(InputType.TYPE_CLASS_DATETIME)
            else
                edit.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_FLAG_NO_SUGGESTIONS)
            end

            local IME_FLAG_NO_EXTRACT_UI = 16777216
            local IME_FLAG_NO_FULLSCREEN = 33554432
            local IME_ACTION_DONE        = 6
            edit.setImeOptions(IME_FLAG_NO_EXTRACT_UI | IME_FLAG_NO_FULLSCREEN | IME_ACTION_DONE)

            edit.setTextColor(UI.TEXT)
            edit.setHintTextColor(UI.SUB)
            edit.setTextSize(1, 12)
            edit.setSingleLine(true)
            edit.setPadding(dp(10), 0, dp(10), 0)
            edit.setBackground(getSkin(UI.BG, 8, 1, UI.STROKE))
            if isRTL() then edit.setGravity(Gravity.RIGHT | Gravity.CENTER_VERTICAL) end

            edit.addTextChangedListener(TextWatcher{
                onTextChanged = function(s, start, before, count)
                    if type(inputStates[id]) == "table" then
                        inputStates[id][i] = tostring(s)
                    else
                        inputStates[id] = tostring(s)
                    end
                end
            })

            edit.setOnKeyListener(View.OnKeyListener{
                onKey = function(v, keyCode, event)
                    if event.getAction() == 0 then
                        if keyCode == 66 then
                            performMod(); return true
                        elseif keyCode == 61 then
                            local next = inputs[i + 1]
                            if next then next.requestFocus() else inputs[1].requestFocus() end
                            return true
                        end
                    end
                    return false
                end
            })

            edit.setOnTouchListener(View.OnTouchListener{
                onTouch = function(v, ev)
                    if ev.getAction() == MotionEvent.ACTION_DOWN then
                        mParams.flags = WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL | WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH
                        windowManager.updateViewLayout(menuView, mParams)
                        v.requestFocus()
                        local imm = activity.getSystemService(Context.INPUT_METHOD_SERVICE)
                        v.postDelayed(function()
                            imm.showSoftInput(v, InputMethodManager.SHOW_IMPLICIT)
                        end, 80)
                    end
                    return false
                end
            })

            table.insert(inputs, edit)
            row.addView(edit)

            if i == #dataKeys then
                local goBtn = TextView(activity)
                local gbp   = LinLayoutParams(dp(40), -1)
                if isRTL() then
                    gbp.rightMargin = dp(8)
                else
                    gbp.leftMargin = dp(8)
                end
                goBtn.setLayoutParams(gbp)
                goBtn.setText(isRTL() and "<-" or "->")
                goBtn.setTextColor(UI.LOGO)
                goBtn.setGravity(Gravity.CENTER)
                goBtn.setTypeface(Typeface.DEFAULT_BOLD)
                goBtn.setBackground(getSkin(UI.ACCENT, 8))
                goBtn.setOnClickListener(View.OnClickListener{ onClick = performMod })
                if isRTL() then
                    row.addView(goBtn, 0)
                else
                    row.addView(goBtn)
                end
            end

            currentInputs = inputs
            inputContainer.addView(row)
        end
        card.addView(inputContainer)
    end

    if mode ~= "spinner" then
        -- textLayout was always added first (index 0) above. In RTL the
        -- action widget (toggle/button/info) belongs on the visual left,
        -- so it must be prepended — appending it here, as before, left it
        -- on the right in every language, which is the actual root cause
        -- of the "goBtn doesn't follow RTL" reports: switch/button/ro cards
        -- never reordered at all, only input/slider (which build their own
        -- row) did.
        if isRTL() then
            topRow.addView(actionArea, 0)
        else
            topRow.addView(actionArea)
        end
        card.addView(topRow, 0)
    end

    parent.addView(card)
end


-- ─────────────────────────────────────────────────────────────────────────────
-- SEPARATORS
-- ─────────────────────────────────────────────────────────────────────────────

-- Thin section label used in the tab sidebar.
function addTabSep(parent, text)
    local sep = TextView(activity)
    local rp  = LinLayoutParams(-1, -2)
    rp.topMargin    = dp(4)
    rp.bottomMargin = dp(2)
    sep.setLayoutParams(rp)
    sep.setText(tostring(text))
    sep.setTextColor(UI.TEXT)
    sep.setTextSize(1, 9)
    sep.setTypeface(Typeface.create("sans-serif", Typeface.BOLD))
    sep.setGravity(Gravity.CENTER)
    sep.setPadding(dp(6), dp(5), dp(6), dp(5))
    sep.setBackground(getSkin(UI.CARD, 8))
    parent.addView(sep)
end

-- Full-width section heading used between module groups in the content area.
function addModuleSep(parent, text)
    local sep = TextView(activity)
    local rp  = LinLayoutParams(-1, -2)
    rp.topMargin    = dp(6)
    rp.bottomMargin = dp(4)
    sep.setLayoutParams(rp)
    sep.setText(tostring(text))
    sep.setTextColor(UI.TEXT)
    sep.setTextSize(1, 13)
    sep.setTypeface(Typeface.create("sans-serif-medium", Typeface.NORMAL))
    sep.setGravity(Gravity.CENTER)
    sep.setPadding(dp(10), dp(5), dp(10), dp(5))
    sep.setBackground(getSkin(UI.CARD, 12, 1, UI.STROKE))
    parent.addView(sep)
end


-- ─────────────────────────────────────────────────────────────────────────────
-- READ-ONLY FIELD UPDATER
-- ─────────────────────────────────────────────────────────────────────────────

-- Updates the text of a read-only field by ID.
-- Posts to the main thread for thread safety.
--@param id string  Module identifier
--@param newText any  New text value (converted to string)
--@return nil
function updateRO(id, newText)
    MainHandler.post(function()
        if RO_Fields[id] then
            RO_Fields[id].setText(tostring(newText))
        end
    end)
end


-- ─────────────────────────────────────────────────────────────────────────────
-- ICON VIEW  (collapsed floating pill)
-- ─────────────────────────────────────────────────────────────────────────────

-- Creates the floating icon pill shown when the menu is minimised.
-- Draggable; tap expands back to the full menu.
--@return View  The icon LinearLayout
function createIconView()
    LOG.info("createIconView", "START")
    local iconRoot = LinearLayout(activity)
    iconRoot.setOrientation(0)
    iconRoot.setGravity(Gravity.BOTTOM)
    iconRoot.setBackground(getSkin(UI.HEADER, 0))
    iconRoot.setPadding(dp(15), dp(10), dp(10), dp(10))
    setLayoutDir(iconRoot)

    -- Explicit pixel width matching menuView so the pill doesn't fill the whole screen.
    -- Height is WRAP_CONTENT so it only takes the space its children need.
    local params = LayoutParams(dp(WIN_W), -2)
    iconRoot.setLayoutParams(params)

    -- Title + marquee subtitle, grouped in a single flexible-width column —
    -- same structure _buildMenuHeader uses below. This (not a separate
    -- weight-1 "end-aligned" container around the X) is what makes the X
    -- pin to the pill's true edge in both LTR and RTL: titleLayout eats all
    -- the slack space, and the X — added right after it with no weight of
    -- its own — always ends up exactly where that slack space runs out.
    -- The previous xButtonContainer (gravityEnd() inside a weight-1 box)
    -- instead left the X sitting right after the text in RTL, since
    -- gravityEnd() resolves to LEFT there and the container's own bounds
    -- start immediately after the text rather than at the pill's far edge.
    local titleLayout = LinearLayout(activity)
    titleLayout.setOrientation(0)
    titleLayout.setLayoutParams(LinLayoutParams(0, -2, 1.0))

    local title = TextView(activity)
    title.setText("VOID")
    title.setTextColor(UI.LOGO)
    title.setTextSize(1, 16)
    title.setTypeface(Typeface.create("sans-serif-black", Typeface.BOLD))
    titleLayout.addView(title)

    local sub = TextView(activity)
    sub.setText(scriptSubHeader)
    sub.setTextColor(UI.SUB)
    sub.setTextSize(1, 8)
    sub.setPadding(dp(6), 0, 0, dp(2))
    sub.setSingleLine(true)
    sub.setEllipsize(TruncateAt.MARQUEE)
    sub.setMarqueeRepeatLimit(-1)
    sub.setHorizontallyScrolling(true)
    sub.setFocusable(true)
    sub.setFocusableInTouchMode(true)
    sub.requestFocus()
    sub.setSelected(true)
    sub.setTypeface(Typeface.create("sans-serif-medium", Typeface.NORMAL))
    titleLayout.addView(sub)

    iconRoot.addView(titleLayout)

    local function addHeaderBtn(txt, color, click)
        local b = TextView(activity)
        b.setText(txt)
        b.setTextColor(color)
        b.setTextSize(1, 16)
        b.setPadding(dp(0), dp(0), dp(5), dp(0))
        b.setTypeface(Typeface.DEFAULT_BOLD)
        b.setOnClickListener(View.OnClickListener({
            onClick = function()
                Thread(Runnable({ run = function() pcall(click) end })).start()
            end
        }))
        iconRoot.addView(b)
    end

    addHeaderBtn("✕", UI.RED, function()
        showDialog(T("common.confirm_exit_title"), T("common.confirm_exit_msg"),
            {T("common.yes"), function()
                memory:save("toggle_states",  toggleStates)
                memory:save("input_states",   inputStates)
                memory:save("spinner_states", spinnerStates)
                memory:save("slider_states",  sliderStates)
                exitScript()
            end},
            {T("common.no")})
    end)

    -- Drag and click handling.
    local initialX, initialY, initialTouchX, initialTouchY
    iconRoot.setOnTouchListener(View.OnTouchListener{
        onTouch = function(v, e)
            if e.getAction() == MotionEvent.ACTION_DOWN then
                initialX      = mParams.x
                initialY      = mParams.y
                initialTouchX = e.getRawX()
                initialTouchY = e.getRawY()
                return true
            elseif e.getAction() == MotionEvent.ACTION_MOVE then
                mParams.x = initialX + (e.getRawX() - initialTouchX)
                mParams.y = initialY + (e.getRawY() - initialTouchY)
                windowManager.updateViewLayout(iconView, mParams)
                return true
            elseif e.getAction() == MotionEvent.ACTION_UP then
                if math.abs(e.getRawX() - initialTouchX) < 12 and math.abs(e.getRawY() - initialTouchY) < 12 then
                    switchToMenu()
                end
                return true
            end
            return false
        end
    })

    return iconRoot
end


-- ─────────────────────────────────────────────────────────────────────────────
-- MENU VIEW HELPERS
-- ─────────────────────────────────────────────────────────────────────────────
-- createMenuView() was a 387-line monolith with 41 locals + 503 bytecodes.
-- Every dp()/addView()/setXxx() call crosses the Lua→Java bridge and burns
-- JVM stack space. Wrapped in _safePcall the cumulative depth overflowed the
-- 8 MB stack. Fix: split into focused helpers so each frame is popped before
-- the next is pushed, keeping peak depth well below the limit.

-- Builds the draggable header row (title, subtitle, ✕ button) and adds it to root.
--@param root View  Parent LinearLayout
local function _buildMenuHeader(root)
    local headerGroup = LinearLayout(activity)
    headerGroup.setOrientation(0)
    headerGroup.setGravity(Gravity.CENTER_VERTICAL)
    headerGroup.setPadding(dp(15), dp(10), dp(10), dp(10))
    headerGroup.setBackground(getSkin(UI.HEADER, 0))
    headerGroup.setClickable(true)
    headerGroup.setFocusable(false)
    setLayoutDir(headerGroup)

    local titleLayout = LinearLayout(activity)
    titleLayout.setOrientation(0)
    titleLayout.setGravity(Gravity.BOTTOM)
    titleLayout.setLayoutParams(LinLayoutParams(0, -2, 1.0))

    local title = TextView(activity)
    title.setText("VOID")
    title.setTextColor(UI.LOGO)
    title.setTextSize(1, 16)
    title.setTypeface(Typeface.create("sans-serif-black", Typeface.BOLD))
    titleLayout.addView(title)

    local sub = TextView(activity)
    sub.setText(scriptSubHeader)
    sub.setTextColor(UI.SUB)
    sub.setTextSize(1, 8)
    sub.setPadding(dp(6), 0, 0, dp(2))
    sub.setSingleLine(true)
    sub.setEllipsize(TruncateAt.MARQUEE)
    sub.setMarqueeRepeatLimit(-1)
    sub.setHorizontallyScrolling(true)
    sub.setFocusable(true)
    sub.setFocusableInTouchMode(true)
    sub.requestFocus()
    sub.setSelected(true)
    titleLayout.addView(sub)
    headerGroup.addView(titleLayout)

    -- Drag to move + tap to minimise.
    local sx, sy, lx, ly, touchStartTime = 0, 0, 0, 0, 0
    headerGroup.setOnTouchListener(View.OnTouchListener({
        onTouch = function(v, ev)
            local action = ev.getAction()
            if action == MotionEvent.ACTION_DOWN then
                sx = ev.getRawX(); sy = ev.getRawY()
                lx = mParams.x;    ly = mParams.y
                touchStartTime = os.clock() * 1000
                return true
            elseif action == MotionEvent.ACTION_MOVE then
                mParams.x = lx + (ev.getRawX() - sx)
                mParams.y = ly + (ev.getRawY() - sy)
                windowManager.updateViewLayout(menuView, mParams)
                return true
            elseif action == MotionEvent.ACTION_UP then
                local dur  = (os.clock() * 1000) - touchStartTime
                local dist = math.abs(ev.getRawX() - sx) + math.abs(ev.getRawY() - sy)
                if dur < 300 and dist < 20 then
                    switchToIcon(); return true
                end
            end
            return false
        end
    }))

    -- ✕ close button.
    local xBtn = TextView(activity)
    xBtn.setText("✕")
    xBtn.setTextColor(UI.RED)
    xBtn.setTextSize(1, 16)
    xBtn.setPadding(dp(10), dp(0), dp(5), dp(0))
    xBtn.setTypeface(Typeface.DEFAULT_BOLD)
    xBtn.setOnClickListener(View.OnClickListener({
        onClick = function()
            Thread(Runnable({ run = function()
                pcall(function()
                    showDialog(T("common.confirm_exit_title"), T("common.confirm_exit_msg"),
                        {T("common.yes"), function()
                            memory:save("toggle_states",  toggleStates)
                            memory:save("input_states",   inputStates)
                            memory:save("spinner_states", spinnerStates)
                            memory:save("slider_states",  sliderStates)
                            exitScript()
                        end},
                        {T("common.no")})
                end)
            end })).start()
        end
    }))
    headerGroup.addView(xBtn)
    root.addView(headerGroup)
end

-- Builds the vertical sidebar and adds it to root.
-- Tab rows are built synchronously in this same frame — there are only a
-- handful (~14, including separators), each just one LinearLayout + two
-- TextViews, so the cost is negligible. This used to spread them across one
-- MainHandler frame per tab to "stay responsive", but that deferral was
-- actually unnecessary (the expensive work — module cards — is already
-- deferred separately by loadCategory) and it caused a real bug: if
-- rebuildMenu() ran again before the previous build's deferred posts had
-- all fired, the second call's `_tabData = {}` reset would race with the
-- first call's still-queued posts writing into it, corrupting the new
-- menu's tab registry with entries pointing at views from the menu that
-- was just torn down. Building synchronously removes that race entirely.
--@param root View  Parent LinearLayout (horizontal)
--@param _lastTab string|nil  Tab ID to restore as active; falls back to first tab
--@return nil
local function _buildMenuTabs(root, _lastTab)
    _tabData        = {}
    _activeTabId    = nil
    _tabContentCache = {}

    -- Sidebar: fixed width, full available height.
    -- In RTL mode the sidebar goes on the right, so we reverse the row order
    -- by adding the divider first and the sidebar second.
    local sideBar = LinearLayout(activity)
    sideBar.setOrientation(1)
    sideBar.setLayoutParams(LinLayoutParams(dp(SIDEBAR_W), -1))
    sideBar.setBackground(getSkin(UI.BG, 0))
    setLayoutDir(sideBar)

    -- 1dp divider between sidebar and content area.
    local divider = View(activity)
    divider.setLayoutParams(LinLayoutParams(dp(1), -1))
    divider.setBackgroundColor(UI.STROKE)

    if isRTL() then
        root.addView(divider)
        root.addView(sideBar)
    else
        root.addView(sideBar)
        root.addView(divider)
    end

    -- Scrollable tab list inside the sidebar.
    local tabScroll = ScrollView(activity)
    tabScroll.setVerticalScrollBarEnabled(false)
    tabScroll.setLayoutParams(LinLayoutParams(-1, -1))
    tabScroll.setPadding(dp(6), dp(8), dp(6), dp(8))

    local tabLayout = LinearLayout(activity)
    tabLayout.setOrientation(1)
    tabScroll.addView(tabLayout)
    sideBar.addView(tabScroll)

    local menuList   = tabHandlers or {{"unknown", "unknown"}}
    local firstTab, firstTabId       = nil, nil
    local targetTab, targetId        = nil, nil

    for _, m in ipairs(menuList) do
        if m[1] == "separator" then
            addTabSep(tabLayout, m[2])
        else
            local t = addTab(tabLayout, m[1], m[2])
            if not firstTab then
                firstTab, firstTabId = t, m[1]
            end
            if _lastTab and m[1] == _lastTab then
                targetTab, targetId = t, m[1]
            end
        end
    end

    if not targetTab then
        targetTab, targetId = firstTab, firstTabId
    end

    if targetTab and targetId then
        loadCategory(targetId, targetTab)
    end

    -- Early-session only: warm every other tab's cache in the background,
    -- one per frame, so by the time the user actually taps around the
    -- tabs they're instant instead of showing the loading spinner on
    -- first visit. Skipped on later rebuilds within the same session.
    if not _earlySessionPreloadDone then
        _earlySessionPreloadDone = true
        local idsToPreload = {}
        for _, m in ipairs(menuList) do
            if m[1] ~= "separator" and m[1] ~= targetId then
                table.insert(idsToPreload, m[1])
            end
        end
        _preloadTabsInBackground(idsToPreload)
    end
end

-- Builds the content ScrollView and moduleContainer, adds them to root.
--@param root View  Parent LinearLayout (horizontal inner row)
--@return View  The ScrollView (available for future use)
local function _buildMenuContent(root)
    local scroll = ScrollView(activity)
    scroll.setLayoutParams(LinLayoutParams(0, -1, 1.0))
    scroll.setVerticalScrollBarEnabled(false)
    scroll.setPadding(dp(10), dp(10), dp(10), dp(10))

    moduleContainer = LinearLayout(activity)
    moduleContainer.setOrientation(1)
    scroll.addView(moduleContainer)

    if isRTL() then
        -- In RTL the content area is on the left, so insert before the sidebar.
        root.addView(scroll, 0)
    else
        root.addView(scroll)
    end
    return scroll
end

-- Module-level upvalues captured from createMenuView so applyWindowResize
-- can reach the inner layout views without being nested inside createMenuView.
local _menuRoot   = nil
local _menuScroll = nil

-- Saves the new window dimensions and exits so the user can restart the script.
-- Direct WindowManager.updateViewLayout calls crash the Lua environment when
-- the target view is not currently attached, so a clean restart is the only
-- safe way to apply new dimensions.
--@param newW number  Target width in dp
--@param newH number  Target height in dp
function applyWindowResize(newW, newH)
    WIN_W = math.max(RESIZE_MIN_W, math.min(RESIZE_MAX_W, math.floor(newW)))
    WIN_H = math.max(RESIZE_MIN_H, math.min(RESIZE_MAX_H, math.floor(newH)))
    memory:save_global("window_size", { w = WIN_W, h = WIN_H })
    showToast(T("ui.size_saved_restart"))
    exitScript()
end

-- Wires the back-key listener and outside-tap dismissal on the menu overlay.
-- Separated so its handleBackButton closure doesn't live in createMenuView's frame.
--@param base FrameLayout  The overlay root (menuView)
local function _setupMenuInteraction(base)
    local function handleBackButton()
        local imm = activity.getSystemService(Context.INPUT_METHOD_SERVICE)
        if menuView then imm.hideSoftInputFromWindow(menuView.getWindowToken(), 0) end
        if currentInputs then
            for _, edit in ipairs(currentInputs) do edit.clearFocus() end
        end
        mParams.flags = 8 | 32
        -- Only call updateViewLayout when menuView is actually attached;
        -- calling it on a detached view throws IllegalArgumentException.
        if activeView == menuView then
            windowManager.updateViewLayout(menuView, mParams)
        end
    end

    activity.getWindow().getDecorView().setOnKeyListener(View.OnKeyListener{
        onKey = function(v, keyCode, event)
            if event.getAction() == MotionEvent.ACTION_UP and keyCode == KeyEvent.KEYCODE_BACK then
                if currentInputs and #currentInputs > 0 then
                    handleBackButton(); return true
                end
            end
            return false
        end
    })

    base.setOnTouchListener(View.OnTouchListener{
        onTouch = function(v, event)
            if event.getAction() == MotionEvent.ACTION_DOWN then
                local isTouchOnInput = false
                if currentInputs then
                    for _, edit in ipairs(currentInputs) do
                        local rect = Rect()
                        edit.getGlobalVisibleRect(rect)
                        if rect.contains(event.getRawX(), event.getRawY()) then
                            isTouchOnInput = true; break
                        end
                    end
                end
                if not isTouchOnInput then handleBackButton() end
            end
            return false
        end
    })
end


-- ─────────────────────────────────────────────────────────────────────────────
-- MENU VIEW  (expanded panel)
-- ─────────────────────────────────────────────────────────────────────────────

-- Creates the full menu view — header on top, [sidebar | content] below.
-- Delegates every major section to a helper so createMenuView itself stays
-- shallow (few locals, few bytecodes) and never overflows the JVM stack.
--@param lastTab string|nil  Tab ID to restore; defaults to the first tab
--@return View  The menu FrameLayout containing all UI elements
function createMenuView(lastTab)
    LOG.info("createMenuView", "START")

    local base = FrameLayout(activity)
    base.setLayoutParams(LayoutParams(-2, -2))

    -- Outer: vertical — header on top, content area below.
    local outer = LinearLayout(activity)
    outer.setOrientation(1)
    outer.setLayoutParams(FrameLayout.LayoutParams(dp(WIN_W), -2))
    outer.setFocusable(true)
    outer.setFocusableInTouchMode(true)
    setLayoutDir(outer)

    -- Dismiss keyboard when the user taps outside an input field.
    outer.setOnTouchListener(View.OnTouchListener{
        onTouch = function(v, e)
            if e.getAction() == 4 or e.getAction() == MotionEvent.ACTION_DOWN then
                local imm         = activity.getSystemService(Context.INPUT_METHOD_SERVICE)
                local currentFocus = activity.getCurrentFocus()
                if currentFocus then
                    currentFocus.clearFocus()
                    imm.hideSoftInputFromWindow(currentFocus.getWindowToken(), 0)
                end
                mParams.flags = 8 | 32 | 16
                windowManager.updateViewLayout(menuView, mParams)
            end
            return false
        end
    })

    _buildMenuHeader(outer)

    -- Inner FrameLayout so a background image can sit behind all other content.
    local inner = FrameLayout(activity)
    inner.setLayoutParams(LinLayoutParams(-1, dp(WIN_H)))
    _menuRoot = inner

    local isBgLoaded = false
    local targetPath = UI.BG_IMAGE.PATH

    if targetPath ~= "no_media" then
        local fileCheck = io.open(targetPath, "r")
        if fileCheck then
            fileCheck:close()
            local bitmap = BitmapFactory.decodeFile(targetPath)
            if bitmap then
                local bgImage = ImageView(activity)
                bgImage.setLayoutParams(FrameLayout.LayoutParams(-1, -1))
                bgImage.setScaleType(ScaleType.FIT_XY)
                bgImage.setImageDrawable(BitmapDrawable(activity.getResources(), bitmap))
                bgImage.setImageAlpha(UI.BG_IMAGE.ALPHA & 0xFF)
                inner.addView(bgImage)
                isBgLoaded = true
                LOG.info("createMenuView", "Background image mounted successfully.")
            else
                LOG.error("createMenuView", "Failed to decode background image.")
            end
        else
            LOG.warn("createMenuView", "Background image missing: " .. tostring(targetPath))
        end
    end

    -- Foreground content layer sits above the background image.
    local contentLayer = LinearLayout(activity)
    contentLayer.setOrientation(0)
    contentLayer.setLayoutParams(FrameLayout.LayoutParams(-1, -1))
    contentLayer.setClickable(false)
    contentLayer.setFocusable(false)
    inner.addView(contentLayer)
    contentLayer.bringToFront()

    if isBgLoaded then
        outer.setBackgroundColor(0x00000000)
    else
        outer.setBackground(getSkin(UI.BG, 16, 0, UI.STROKE))
    end

    outer.addView(inner)

    -- Build sidebar and content into the foreground layer.
    _buildMenuTabs(contentLayer, lastTab)
    local scroll = _buildMenuContent(contentLayer)
    _menuScroll = scroll

    -- _buildMenuTabs handles its own deferred first-tab load.

    base.addView(outer)
    menuView = base

    MainHandler.post(Runnable({ run = function()
        LOG.info("createMenuView", "deferred: _setupMenuInteraction")
        _setupMenuInteraction(base)
    end }))

    return base
end

function initUI()
    LOG.info("initUI", "START | WIN_W=" .. tostring(WIN_W) .. " WIN_H=" .. tostring(WIN_H) .. " SDK=" .. tostring(Build.VERSION.SDK_INT))

    windowManager = activity.getSystemService(Context.WINDOW_SERVICE)

    mParams = LayoutParams(dp(WIN_W), dp(WIN_H + UI_CHROME_H),
        Build.VERSION.SDK_INT >= 26 and 2038 or 2002, 8, -3)
    mParams.gravity  = Gravity.TOP | Gravity.LEFT
    mParams.x, mParams.y = 100, 200

    menuView = createMenuView()
    LOG.info("initUI", "menuView=" .. tostring(menuView))

    iconView = createIconView()
    LOG.info("initUI", "iconView=" .. tostring(iconView))

    switchToIcon()
    LOG.info("initUI", "DONE")
end
