-- VOID test environment
-- Load order: env → imports → constants → core → patches → arch+data → modules

do
    local LOG_TO_FILE  = true
    local LOG_TO_TOAST = false
    local LOG_TO_PRINT = true
    local MAX_FILE_BYTES = 2 * 1024 * 1024

    local _log_path   = gg.getFile():match("(.*)/") .. "/void_debug.log"
    local _log_buf    = {}
    local _line_count = 0
    local _start_time = os.clock()
    local _indent     = 0

    local function _ts()
        return ("%.3f"):format(os.clock() - _start_time)
    end

    local function _write(level, tag, msg)
        local prefix = string.rep("  ", _indent)
        local line   = ("[%s] [%s] %s%s"):format(_ts(), level, prefix, tostring(msg))
        if tag and tag ~= "" then
            line = ("[%s] [%s] [%s] %s%s"):format(_ts(), level, tag, prefix, tostring(msg))
        end
        _line_count          = _line_count + 1
        _log_buf[#_log_buf + 1] = line

        if LOG_TO_TOAST then
            pcall(gg.toast, line)
        end

        -- Forward WARN+ lines to the crash handler's Console sink (if installed).
        if __log_sink then pcall(__log_sink, level, tag, msg) end

        if LOG_TO_FILE and (#_log_buf >= 20 or level == "FATAL") then
            pcall(function()
                local f = io.open(_log_path, "a")
                if f then
                    for _, l in ipairs(_log_buf) do f:write(l, "\n") end
                    f:close()
                end
            end)
            _log_buf = {}
        end
    end

    LOG = {}

    function LOG.info(tag, msg)  _write("INFO ", tag, msg) end
    function LOG.warn(tag, msg)  _write("WARN ", tag, msg) end
    function LOG.error(tag, msg) _write("ERROR", tag, msg) end
    function LOG.fatal(tag, msg) _write("FATAL", tag, msg) end
    function LOG.dbg(tag, msg)   _write("DEBUG", tag, msg) end

    function LOG.flush()
        if not LOG_TO_FILE or #_log_buf == 0 then return end
        pcall(function()
            local f = io.open(_log_path, "a")
            if f then
                for _, l in ipairs(_log_buf) do f:write(l, "\n") end
                f:close()
            end
        end)
        _log_buf = {}
    end

    function LOG.dump()
        LOG.flush()
        local recent = {}
        pcall(function()
            local f = io.open(_log_path, "r")
            if f then
                for line in f:lines() do
                    recent[#recent + 1] = line
                    if #recent > 60 then table.remove(recent, 1) end
                end
                f:close()
            end
        end)
        gg.alert("[VOID Logger] Last lines:\n" .. table.concat(recent, "\n"))
    end

    function LOG.try(tag, fn, ...)
        _indent = _indent + 1
        local ok, err = pcall(fn, ...)
        _indent = _indent - 1
        if not ok then
            LOG.error(tag, "pcall FAILED: " .. tostring(err))
            LOG.flush()
        end
        return ok, err
    end

    LOG.info("LOGGER", "══════ VOID Logger started ══════")
    LOG.info("LOGGER", "Log date: " .. os.date())
    LOG.info("LOGGER", "Log file: " .. _log_path)
    LOG.info("LOGGER", "Script started at t=0.001")

    _G.__rawLoadModule = nil

    _safePcall = pcall
end

script_dir = gg.getFile():match("(.*)/")

LOG.info("MAIN", "script_dir resolved: " .. tostring(script_dir))

-- loadModule(name [, soft])
--   Hard mode (default): a load/runtime failure is fatal (alert + os.exit) —
--     correct for core framework files that the script cannot run without.
--   Soft mode (soft == true): a failure logs + returns nil, err instead of
--     exiting. Used by CrashHandler.loadFeature for feature modules so a crash in
--     one feature doesn't take down the whole UI.
function loadModule(name, soft)
    local path = script_dir .. "/" .. name
    LOG.info("loadModule", "-> loading: " .. name)
    local chunk, err = loadfile(path)
    if not chunk then
        if soft then
            LOG.error("loadModule", "soft load FAILED: " .. name .. " | " .. tostring(err))
            return nil, err
        end
        LOG.fatal("loadModule", "FAILED: " .. name .. " | " .. tostring(err))
        LOG.flush()
        gg.alert("Load failed: " .. name .. "\n" .. tostring(err)); os.exit()
    end
    local results = table.pack(_safePcall(chunk))
    local ok = results[1]
    if not ok then
        local load_err = results[2]
        if soft then
            LOG.error("loadModule", "soft RUNTIME ERROR in: " .. name .. " | " .. tostring(load_err))
            return nil, load_err
        end
        LOG.fatal("loadModule", "RUNTIME ERROR in: " .. name .. " | " .. tostring(load_err))
        LOG.flush()
        gg.alert("Runtime error in: " .. name .. "\n" .. tostring(load_err)); os.exit()
    end
    LOG.info("loadModule", "OK loaded: " .. name .. " | returns=" .. tostring(results.n - 1))
    return table.unpack(results, 2, results.n)
end

loadModule("core/env.lua")

-- ── Java imports (global; available to all subsequently loaded modules) ──────

Build       = import("android.os.Build")
Config      = import("android.ext.Config")
Crypto      = import("org.vekendian.Crypto")
MainService = import("android.ext.MainService")
rx          = import("android.ext.rx")
Script      = import("android.ext.Script")
Tools       = import("android.ext.Tools")
Ui          = import("org.vekendian.Ui")
Shell       = import("org.vekendian.Shell")
Zip         = import("org.vekendian.Zip")

Array                       = luajava.bindClass("java.lang.reflect.Array")
Byte                        = luajava.bindClass("java.lang.Byte")
Integer                     = luajava.bindClass("java.lang.Integer")
String                      = luajava.bindClass("java.lang.String")
ClipData                    = import("android.content.ClipData")
Color                       = import("android.graphics.Color")
Context                     = import("android.content.Context")
EditText                    = import("android.widget.EditText")
File                        = import("java.io.File")
FileOutputStream            = import("java.io.FileOutputStream")
FrameLayout                 = import("android.widget.FrameLayout")
GradientDrawable            = import("android.graphics.drawable.GradientDrawable")
Gravity                     = import("android.view.Gravity")
Handler                     = import("android.os.Handler")
HorizontalScrollView        = import("android.widget.HorizontalScrollView")
InputType                   = import("android.text.InputType")
LayoutParams                = import("android.view.WindowManager$LayoutParams")
LinearLayout                = import("android.widget.LinearLayout")
LinLayoutParams             = import("android.widget.LinearLayout$LayoutParams")
Looper                      = import("android.os.Looper")
MotionEvent                 = import("android.view.MotionEvent")
PasswordTransformationMethod = import("android.text.method.PasswordTransformationMethod")
Html                        = import("android.text.Html")
LinkMovementMethod          = import("android.text.method.LinkMovementMethod")
Runnable                    = import("java.lang.Runnable")
ScrollView                  = import("android.widget.ScrollView")
SeekBar                     = import("android.widget.SeekBar")
TextWatcher                 = import("android.text.TextWatcher")
TextView                    = import("android.widget.TextView")
Thread                      = import("java.lang.Thread")
TruncateAt                  = luajava.bindClass("android.text.TextUtils$TruncateAt")
Typeface                    = import("android.graphics.Typeface")
TypedValue                  = import("android.util.TypedValue")
View                        = import("android.view.View")
WindowManager               = import("android.view.WindowManager")
ImageView                   = import("android.widget.ImageView")
ScaleType                   = import("android.widget.ImageView$ScaleType")
BitmapFactory               = import("android.graphics.BitmapFactory")
BitmapDrawable              = import("android.graphics.drawable.BitmapDrawable")
MainHandler                 = Handler(Looper.getMainLooper())


-- ── Constants ─────────────────────────────────────────────────────────────────


cast      = loadModule("core/utils/cast.lua")
json      = loadModule("core/utils/json.lua")

-- Crash capture layer — loaded early so it can sink WARN+ logs from the start
-- and so feature modules can be loaded non-fatally via CrashHandler.loadFeature.
CrashHandler = loadModule("core/engines/crash_handler.lua")

-- ── UI utilities (global; needed by modules before ui.lua loads) ──────────────

-- Cache density once so dp() is a pure Lua multiply — no Java call per use.
-- createMenuView calls dp() ~100 times; each Java crossing burns stack space.
--
-- NOTE: dp() must NOT recompute RESIZE_MAX_W/H here.  Those bounds are set
-- once in the do-block below (after memory loads) and must not be overwritten
-- by lazy dp() calls that happen later during UI construction.
local _dp_density = nil
function dp(v)
    if not _dp_density then
        _dp_density = activity.getResources().getDisplayMetrics().density
        LOG.info("dp", "density cached: " .. tostring(_dp_density))
    end
    return math.floor(v * _dp_density + 0.5)
end

function getSkin(color, radius, stroke_w, stroke_c)
    local d = GradientDrawable()
    d.setColor(color)
    d.setCornerRadius(dp(radius))
    if stroke_w and stroke_c then d.setStroke(dp(stroke_w), stroke_c) end
    return d
end

function showToast(msg, fast)
    Tools.a(msg, fast and 0 or 1)
end

function showDialog(title, msg, pos, neg, neu)
    local ctx = Tools.e()
    if not ctx then return 0 end
    local function wrap(b)
        if type(b) == "table"      then return { tostring(b[1]) }
        elseif type(b) == "string" then return { b } end
    end
    local r = Ui.showDialog(ctx, title or "", msg or "", wrap(pos), wrap(neg), wrap(neu), json.encode(UI))
    local function fire(b) if type(b) == "table" and type(b[2]) == "function" then pcall(b[2]) end end
    if r == 1 then fire(pos) elseif r == 2 then fire(neg) elseif r == 3 then fire(neu) end
    return r
end

function showPrompt(title, prompts)
    local ctx = Tools.e()
    if not ctx then return nil end
    local labels   = Array.newInstance(String, #prompts)
    local defaults = Array.newInstance(String, #prompts)
    local types    = Array.newInstance(String, #prompts)
    for i, p in ipairs(prompts) do
        Array.set(labels,   i - 1, tostring(p[1] or ""))
        Array.set(defaults, i - 1, tostring(p[3] or ""))
        Array.set(types,    i - 1, tostring(p[2] or "text"))
    end
    local result = Ui.showPrompt(ctx, title or "", labels, defaults, types, json.encode(UI))
    if not result then return nil end
    local out = {}
    for i = 1, #prompts do
        out[i] = tostring(Array.get(result, i - 1))
    end
    return out
end

function showList(title, description, items, multi)
    local ctx = Tools.e()
    if not ctx then return multi and nil or 0 end
    local arr = Array.newInstance(String, #items)
    for i, item in ipairs(items) do
        Array.set(arr, i - 1, tostring(item))
    end
    local result = Ui.showList(ctx, title or "", description or "", arr, multi == true, json.encode(UI))
    if multi then
        if not result then return nil end
        local out = {}
        for i = 0, Array.getLength(result) - 1 do
            table.insert(out, Array.get(result, i))
        end
        return out
    else
        return tonumber(tostring(result)) or 0
    end
end

--[[
-- Test showDialog
local r = showDialog(
    "Test Dialog",
    "This is a test message for showDialog.",
    {"OK"},
    {"Cancel"},
    nil
)
print("showDialog result:", r)

-- Test showPrompt with all types
local result = showPrompt("Test Prompt", {
    {"Text Field",    "text",     "hello"},
    {"Number Field",  "number",   "1234"},
    {"Password",      "password", "secret"},
    {"Checkbox",      "checkbox", "true"},
    {"Switch",        "switch",   "false"},
    {"Slider",        "slider",   "75"},
})

if result then
    print("showPrompt results:")
    print("  text:     ", result[1])
    print("  number:   ", result[2])
    print("  password: ", result[3])
    print("  checkbox: ", result[4])
    print("  switch:   ", result[5])
    print("  slider:   ", result[6])
else
    print("showPrompt: cancelled")
end

-- single
local idx = showList("Pick one", {"Option A", "Option B", "Option C"})
if idx > 0 then print("Picked:", idx) end

-- multi
local selected = showList("Pick many", {"A", "B", "C", "D"}, true)
if selected then
    for _, idx in ipairs(selected) do print("Selected:", idx) end
end

]]


function switchToMenu()
    LOG.info("switchToMenu", "called | activeView=" .. tostring(activeView) .. " menuView=" .. tostring(menuView) .. " iconView=" .. tostring(iconView))
    MainHandler.post(function()
        LOG.info("switchToMenu", "MainHandler running")
        if activeView == menuView then
            LOG.warn("switchToMenu", "EARLY RETURN — activeView is already menuView")
            return
        end
        if iconView and activeView == iconView then
            LOG.info("switchToMenu", "removing iconView from windowManager")
            pcall(function() iconView.setAlpha(0); windowManager.removeView(iconView) end)
        end
        LOG.info("switchToMenu", "attempting windowManager.addView(menuView) | menuView=" .. tostring(menuView) .. " mParams=" .. tostring(mParams) .. " windowManager=" .. tostring(windowManager))
        local ok, err = _safePcall(function()
            -- Restore full menu height (was set to -2 for the icon pill).
            mParams.height = dp(WIN_H + UI_CHROME_H)
            menuView.setAlpha(0.0); menuView.setScaleX(0.9); menuView.setScaleY(0.9)
            windowManager.addView(menuView, mParams); activeView = menuView
            menuView.animate().alpha(1.0).scaleX(1.0).scaleY(1.0).setDuration(200).start()
        end)
        if not ok then
            LOG.fatal("switchToMenu", "addView FAILED: " .. tostring(err))
            LOG.flush()
        else
            LOG.info("switchToMenu", "menuView added OK | activeView=" .. tostring(activeView))
        end
    end)
end

function switchToIcon()
    LOG.info("switchToIcon", "called | activeView=" .. tostring(activeView) .. " iconView=" .. tostring(iconView) .. " menuView=" .. tostring(menuView))
    MainHandler.post(function()
        LOG.info("switchToIcon", "MainHandler running")
        if activeView == iconView then
            LOG.warn("switchToIcon", "EARLY RETURN — activeView is already iconView")
            return
        end
        local imm = activity:getSystemService(Context.INPUT_METHOD_SERVICE)
        if menuView then pcall(function() imm.hideSoftInputFromWindow(menuView.getWindowToken(), 0) end) end
        mParams.flags = 8 | 32
        LOG.info("switchToIcon", "mParams.flags set to 8|32 | mParams=" .. tostring(mParams))
        if menuView and activeView == menuView then
            LOG.info("switchToIcon", "removing menuView (no animation) | menuView=" .. tostring(menuView))
            pcall(function() windowManager.removeView(menuView) end)
        end
        LOG.info("switchToIcon", "attempting windowManager.addView(iconView) | iconView=" .. tostring(iconView))
        local ok, err = _safePcall(function()
            -- Use WRAP_CONTENT height for the icon pill; the full menu height
            -- is restored in switchToMenu before menuView is added back.
            mParams.height = -2
            iconView.setAlpha(0.0); windowManager.addView(iconView, mParams); activeView = iconView
            iconView.animate().alpha(1.0).setDuration(180).start()
        end)
        if not ok then
            LOG.fatal("switchToIcon", "addView(iconView) FAILED: " .. tostring(err))
            LOG.flush()
        else
            LOG.info("switchToIcon", "iconView added OK | activeView=" .. tostring(activeView))
        end
    end)
end

function exitScript()
    -- FIX: use renamed public scheduler API
    local pending = scheduler:get_queue_count() or 0
    if pending > 0 or scheduler:is_processing() then
        showDialog(T("main.exit_active_ops_title"),
            T("main.exit_active_ops_msg", pending),
            {T("common.wait_safe"), function() showToast(T("common.waiting")) end},
            {T("common.force_exit"),  function()
                if activeView then pcall(function() windowManager.removeView(activeView) end) end
                exit = true
            end})
    else
        if activeView then pcall(function() windowManager.removeView(activeView) end) end
        exit = true
    end
end

-- ── Core modules ──────────────────────────────────────────────────────────────
alloc     = loadModule("core/engines/alloc.lua")
memory    = loadModule("core/engines/memory.lua")
loadModule("core/utils/lang.lua") -- sets globals: T, setLanguage, LANG_CODE, LANG_AVAILABLE
scheduler = loadModule("core/engines/scheduler.lua")
loader    = loadModule("core/utils/loader.lua")
catbox    = loadModule("core/utils/catbox.lua")
paste     = loadModule("core/utils/paste.lua")

loadModule("core/engines/patches.lua")

-- Detects arch, loads matching data from manifest → sets globals: aobs, offsets
loadModule("core/engines/arch.lua")

-- Lazy tab registry → returns {tabHandlers, categoryHandlers}
tabHandlers, categoryHandlers = loadModule("modules/registry.lua")

-- Write code here

local arr = alloc.new(4096, { flags = 32, step = 8, align = 8 })
if not arr then
    gg.toast("alloc failed: no empty region found")
    return
end

local read = arr:read()
print(read)




