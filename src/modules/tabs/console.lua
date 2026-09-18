--[[
  Console Tab - Crash & log viewer (Script section)

  Reads the in-memory ring buffers from the global CrashHandler engine and
  renders them as a scrollable report list with Copy all / Refresh / Clear.
  This tab is excluded from ui.lua's view cache, so it re-renders on every open.

  @module callback Receives container View to populate with modules
]]

return function(container)
    local function t(key, ...) return T("console." .. key, ...) end

    if not CrashHandler then
        local tv = TextView(activity)
        tv.setText(t("unavailable"))
        tv.setTextColor(UI.SUB)
        container.addView(tv)
        return
    end

    -- ── Action button (shares row width equally) ──────────────────────────────
    local function makeButton(label, onTap)
        local btn = TextView(activity)
        local lp = LinLayoutParams(0, -2, 1.0)
        lp.rightMargin = dp(6)
        btn.setLayoutParams(lp)
        btn.setText(label)
        btn.setTextColor(UI.LOGO)
        btn.setGravity(Gravity.CENTER)
        btn.setTypeface(Typeface.create("sans-serif-medium", Typeface.BOLD))
        btn.setTextSize(1, 12)
        btn.setPadding(dp(10), dp(9), dp(10), dp(9))
        btn.setBackground(getSkin(UI.ACCENT, 8))
        btn.setOnClickListener(View.OnClickListener({ onClick = function() pcall(onTap) end }))
        return btn
    end

    -- ── Entry renderers ───────────────────────────────────────────────────────
    local function crashCard(e)
        local card = LinearLayout(activity)
        card.setOrientation(1)
        setLayoutDir(card)
        local lp = LinLayoutParams(-1, -2)
        lp.bottomMargin = dp(8)
        card.setLayoutParams(lp)
        card.setPadding(dp(12), dp(10), dp(12), dp(10))
        card.setBackground(getSkin(UI.CARD, 10, 1, UI.STROKE))

        local head = TextView(activity)
        head.setText(string.format("✖ [%s]  %s", e.ts, e.tag))
        head.setTextColor(UI.CONSOLE.CRASH)
        head.setTypeface(Typeface.create("sans-serif-medium", Typeface.BOLD))
        head.setTextSize(1, 12)
        card.addView(head)

        local msg = TextView(activity)
        msg.setText(tostring(e.message))
        msg.setTextColor(UI.TEXT)
        msg.setTextSize(1, 12)
        card.addView(msg)

        -- Tap for the full report (traceback included) with a Copy action.
        card.setClickable(true)
        card.setOnClickListener(View.OnClickListener({ onClick = function()
            local detail = string.format("%s\n\n%s", e.ts, tostring(e.message))
            if e.traceback then
                detail = detail .. "\n\n" .. tostring(e.traceback)
            end
            showDialog(t("details_title", e.tag), detail,
                { t("copy"), function()
                    pcall(function()
                        local cm = activity.getSystemService("clipboard")
                        cm.setPrimaryClip(ClipData.newPlainText("VOID Crash", detail))
                    end)
                    showToast(t("copied_one"))
                end },
                { T("common.ok") })
        end }))

        if e.traceback then
            local tb = TextView(activity)
            tb.setText(tostring(e.traceback))
            tb.setTextColor(UI.SUB)
            tb.setTextSize(1, 9)
            tb.setTypeface(Typeface.create("monospace", Typeface.NORMAL))
            local tlp = LinLayoutParams(-1, -2)
            tlp.topMargin = dp(4)
            tb.setLayoutParams(tlp)
            card.addView(tb)
        end

        return card
    end

    -- Level glyph + color, both driven by UI.CONSOLE (configs/app/colors.lua).
    local function levelStyle(level)
        if level == "ERROR" or level == "FATAL" then return "✖", UI.CONSOLE.ERROR
        elseif level == "WARN"                   then return "⚠", UI.CONSOLE.WARN
        elseif level == "DEBUG"                  then return "·", UI.CONSOLE.DEBUG
        else                                          return "ℹ", UI.CONSOLE.INFO end
    end

    local function logLine(e)
        local tv = TextView(activity)
        local lp = LinLayoutParams(-1, -2)
        lp.bottomMargin = dp(4)
        tv.setLayoutParams(lp)
        local glyph, color = levelStyle(e.level)
        tv.setText(string.format("[%s] %s %s [%s] %s", e.ts, glyph, e.level, e.tag, e.message))
        tv.setTextColor(color)
        tv.setTextSize(1, 10)
        tv.setTypeface(Typeface.create("monospace", Typeface.NORMAL))
        tv.setPadding(dp(10), dp(6), dp(10), dp(6))
        tv.setBackground(getSkin(UI.BG, 8))
        tv.setClickable(true)
        -- Tap to copy this single entry.
        tv.setOnClickListener(View.OnClickListener({ onClick = function()
            local ok = pcall(function()
                local cm = activity.getSystemService("clipboard")
                cm.setPrimaryClip(ClipData.newPlainText("VOID Log",
                    string.format("[%s] [%s] %s: %s", e.ts, e.level, e.tag, e.message)))
            end)
            showToast(ok and t("copied_one") or T("common.failed"))
        end }))
        return tv
    end

    -- ── Filter chips ("all" | "logs" | "crashes") ─────────────────────────────
    local filter = "all"
    local chipRefs = {}

    -- Level chips (second row): nil = all levels.
    local levelFilter = nil
    local levelRefs   = {}
    local RENDER_CAP  = 150

    -- Forward declaration: the chip closures call populate() before its
    -- definition, which would otherwise resolve to a nil global.
    local populate

    local function refreshChips()
        for key, btn in pairs(chipRefs) do
            if key == filter then
                btn.setBackground(getSkin(UI.ACCENT, 8))
                btn.setTextColor(UI.TEXT)
            else
                btn.setBackground(getSkin(UI.BG, 8, 1, UI.STROKE))
                btn.setTextColor(UI.SUB)
            end
        end
    end

    local function makeChip(label, key)
        local btn = TextView(activity)
        local lp = LinLayoutParams(0, -2, 1.0)
        lp.rightMargin = dp(6)
        btn.setLayoutParams(lp)
        btn.setText(label)
        btn.setTextColor(UI.SUB)
        btn.setGravity(Gravity.CENTER)
        btn.setTypeface(Typeface.create("sans-serif-medium", Typeface.BOLD))
        btn.setTextSize(1, 11)
        btn.setPadding(dp(10), dp(8), dp(10), dp(8))
        btn.setBackground(getSkin(UI.BG, 8, 1, UI.STROKE))
        btn.setOnClickListener(View.OnClickListener({ onClick = function()
            if filter == key then return end
            filter = key
            refreshChips()
            populate()
        end }))
        chipRefs[key] = btn
        return btn
    end

    local function refreshLevelChips()
        for key, btn in pairs(levelRefs) do
            if key == levelFilter then
                btn.setBackground(getSkin(UI.ACCENT, 8))
                btn.setTextColor(UI.TEXT)
            else
                btn.setBackground(getSkin(UI.BG, 8, 1, UI.STROKE))
                btn.setTextColor(UI.SUB)
            end
        end
    end

    -- Tapping the active level chip again clears the filter.
    local function makeLevelChip(label, key)
        local btn = TextView(activity)
        local lp = LinLayoutParams(0, -2, 1.0)
        lp.rightMargin = dp(6)
        btn.setLayoutParams(lp)
        btn.setText(label)
        btn.setTextColor(UI.SUB)
        btn.setGravity(Gravity.CENTER)
        btn.setTypeface(Typeface.create("sans-serif-medium", Typeface.BOLD))
        btn.setTextSize(1, 11)
        btn.setPadding(dp(10), dp(8), dp(10), dp(8))
        btn.setBackground(getSkin(UI.BG, 8, 1, UI.STROKE))
        btn.setOnClickListener(View.OnClickListener({ onClick = function()
            levelFilter = (levelFilter == key) and nil or key
            refreshLevelChips()
            populate()
        end }))
        levelRefs[key] = btn
        return btn
    end

    -- ── Dynamic list (rebuilt on render / refresh / clear) ────────────────────
    local listLayout = LinearLayout(activity)
    listLayout.setOrientation(1)
    setLayoutDir(listLayout)
    listLayout.setLayoutParams(LinLayoutParams(-1, -2))

    function populate()
        listLayout.removeAllViews()

        local crashes = CrashHandler.getCrashes()
        local logs    = CrashHandler.getLogs()
        local showC   = (filter ~= "logs")
        local showL   = (filter ~= "crashes")

        -- Keep chip counts live.
        if chipRefs.all then
            chipRefs.all.setText(t("filter_all"))
            chipRefs.logs.setText(t("filter_logs", #logs))
            chipRefs.crashes.setText(t("filter_crashes", #crashes))
        end

        local rendered = false

        if showC and #crashes > 0 then
            rendered = true
            addModuleSep(listLayout, t("crashes_header", #crashes))
            for i = #crashes, 1, -1 do      -- newest first
                listLayout.addView(crashCard(crashes[i]))
            end
        end

        if showL and #logs > 0 then
            -- Level filter (nil = every level); FATAL shares the ERROR chip.
            local lvLogs = {}
            for i = #logs, 1, -1 do
                local e = logs[i]
                if not levelFilter or levelFilter == e.level
                    or (levelFilter == "ERROR" and e.level == "FATAL") then
                    lvLogs[#lvLogs + 1] = e
                end
            end

            if #lvLogs > 0 then
                rendered = true
                addModuleSep(listLayout, t("logs_header", #lvLogs))
                -- Render the newest RENDER_CAP entries only.
                local total = #lvLogs
                local from  = math.max(1, total - RENDER_CAP + 1)
                for i = from, total do
                    listLayout.addView(logLine(lvLogs[i]))
                end
                if total > RENDER_CAP then
                    local more = TextView(activity)
                    more.setText(t("capped", RENDER_CAP, total))
                    more.setTextColor(UI.SUB)
                    more.setTextSize(1, 10)
                    more.setGravity(Gravity.CENTER)
                    more.setPadding(dp(12), dp(4), dp(12), dp(4))
                    listLayout.addView(more)
                end
            end
        end

        if not rendered then
            local empty = TextView(activity)
            empty.setText(CrashHandler.isEmpty() and t("empty") or t("empty_filtered"))
            empty.setTextColor(UI.SUB)
            empty.setTextSize(1, 12)
            empty.setPadding(dp(12), dp(14), dp(12), dp(14))
            empty.setGravity(Gravity.CENTER)
            empty.setBackground(getSkin(UI.CARD, 10, 1, UI.STROKE))
            listLayout.addView(empty)
        end
    end

    local function copyAll()
        local okc = pcall(function()
            local cm = activity.getSystemService("clipboard")
            cm.setPrimaryClip(ClipData.newPlainText("VOID Console", CrashHandler.formatAll()))
        end)
        showToast(okc and t("copied") or T("common.failed"))
    end

    -- ── Layout ────────────────────────────────────────────────────────────────
    local intro = TextView(activity)
    intro.setText(t("desc"))
    intro.setTextColor(UI.SUB)
    intro.setTextSize(1, 11)
    local ilp = LinLayoutParams(-1, -2)
    ilp.bottomMargin = dp(8)
    intro.setLayoutParams(ilp)
    container.addView(intro)

    -- Filter chips row (ALL / LOGS / CRASHES) with live counts.
    local chips = LinearLayout(activity)
    chips.setOrientation(0)
    setLayoutDir(chips)
    local clp = LinLayoutParams(-1, -2)
    clp.bottomMargin = dp(8)
    chips.setLayoutParams(clp)
    chips.addView(makeChip(t("filter_all"), "all"))
    chips.addView(makeChip(t("filter_logs"), "logs"))
    chips.addView(makeChip(t("filter_crashes"), "crashes"))
    container.addView(chips)

    -- Level chips (ERROR / WARN / INFO / DEBUG) narrow the log stream.
    local lchips = LinearLayout(activity)
    lchips.setOrientation(0)
    setLayoutDir(lchips)
    local llp = LinLayoutParams(-1, -2)
    llp.bottomMargin = dp(8)
    lchips.setLayoutParams(llp)
    lchips.addView(makeLevelChip("ERROR", "ERROR"))
    lchips.addView(makeLevelChip("WARN", "WARN"))
    lchips.addView(makeLevelChip("INFO", "INFO"))
    lchips.addView(makeLevelChip("DEBUG", "DEBUG"))
    container.addView(lchips)

    local row = LinearLayout(activity)
    row.setOrientation(0)
    setLayoutDir(row)
    local rlp = LinLayoutParams(-1, -2)
    rlp.bottomMargin = dp(10)
    row.setLayoutParams(rlp)
    row.addView(makeButton(t("copy_all"), copyAll))
    row.addView(makeButton(t("refresh"),  populate))
    row.addView(makeButton(t("clear"), function()
        CrashHandler.clear()
        populate()
        showToast(t("cleared"))
    end))
    container.addView(row)

    container.addView(listLayout)
    populate()
end
