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
        head.setText(string.format("[%s]  %s", e.ts, e.tag))
        head.setTextColor(UI.RED)
        head.setTypeface(Typeface.create("sans-serif-medium", Typeface.BOLD))
        head.setTextSize(1, 12)
        card.addView(head)

        local msg = TextView(activity)
        msg.setText(tostring(e.message))
        msg.setTextColor(UI.TEXT)
        msg.setTextSize(1, 12)
        card.addView(msg)

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

    local function logLine(e)
        local tv = TextView(activity)
        local lp = LinLayoutParams(-1, -2)
        lp.bottomMargin = dp(4)
        tv.setLayoutParams(lp)
        tv.setText(string.format("[%s] %s [%s] %s", e.ts, e.level, e.tag, e.message))
        -- Color by severity: error/fatal red, warn accent, info default, debug muted.
        local color = UI.SUB
        if e.level == "ERROR" or e.level == "FATAL" then color = UI.RED
        elseif e.level == "WARN" then color = UI.LOGO
        elseif e.level == "INFO" then color = UI.TEXT end
        tv.setTextColor(color)
        tv.setTextSize(1, 10)
        tv.setPadding(dp(10), dp(6), dp(10), dp(6))
        tv.setBackground(getSkin(UI.BG, 8))
        return tv
    end

    -- ── Dynamic list (rebuilt on render / refresh / clear) ────────────────────
    local listLayout = LinearLayout(activity)
    listLayout.setOrientation(1)
    setLayoutDir(listLayout)
    listLayout.setLayoutParams(LinLayoutParams(-1, -2))

    local function populate()
        listLayout.removeAllViews()

        if CrashHandler.isEmpty() then
            local empty = TextView(activity)
            empty.setText(t("empty"))
            empty.setTextColor(UI.SUB)
            empty.setTextSize(1, 12)
            empty.setPadding(dp(12), dp(14), dp(12), dp(14))
            empty.setGravity(Gravity.CENTER)
            empty.setBackground(getSkin(UI.CARD, 10, 1, UI.STROKE))
            listLayout.addView(empty)
            return
        end

        local crashes = CrashHandler.getCrashes()
        local logs    = CrashHandler.getLogs()

        if #crashes > 0 then
            addModuleSep(listLayout, t("crashes_header", #crashes))
            for i = #crashes, 1, -1 do      -- newest first
                listLayout.addView(crashCard(crashes[i]))
            end
        end

        if #logs > 0 then
            addModuleSep(listLayout, t("logs_header", #logs))
            for i = #logs, 1, -1 do
                listLayout.addView(logLine(logs[i]))
            end
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
