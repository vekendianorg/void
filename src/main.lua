-- VOID v1 — HCR2 Modding Framework
-- Load order: env → imports → constants → core → patches → arch+data → modules → ui → init → loop

scriptSubHeader = " v1.0.23 • By Vekendian"

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

FORCE_EXIT     = false
DEFAULT_WIN_W  = 480
CLICK_COOLDOWN = 500
DEVICE_ARCH    = "unknown"
DEFAULT_ARCH   = "arm64-v8a"

SCRIPT_PATH = gg.getFile() or ""
SCRIPT_NAME = SCRIPT_PATH:match("([^/\\]+)$") or ""
IS_DEV = SCRIPT_NAME == "main.lua"
CURRENT_VERSION = scriptSubHeader:match("v([%d%.]+)") or "0.0.0"
RELEASE_API = "https://api.github.com/repos/vekendianorg/void/releases/latest"

UI = loadModule("configs/colors.lua")

-- ── Global state ──────────────────────────────────────────────────────────────

exit             = false
WIN_W            = nil    -- resolved after memory loads (see below)
WIN_H            = nil    -- resolved after memory loads (see below)
loader           = nil
menuView         = nil
iconView         = nil
activeView       = nil
windowManager    = nil
mParams          = nil
moduleContainer  = nil
activeTabView    = nil
activeSpinner    = nil
BaseGameStatusRaw = nil
BaseGameStatus   = nil
BaseRegion       = nil
BaseLib          = nil
toggleStates     = {}
inputStates      = {}
spinnerStates    = {}
sliderStates     = {}
processingStates = {}
lastClickTimes   = {}
RO_Fields        = {}

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

memory    = loadModule("core/engines/memory.lua")
loadModule("core/utils/lang.lua") -- sets globals: T, setLanguage, LANG_CODE, LANG_AVAILABLE
scheduler = loadModule("core/engines/scheduler.lua")
loader    = loadModule("core/utils/loader.lua")
catbox    = loadModule("core/utils/catbox.lua")
paste     = loadModule("core/utils/paste.lua")

local saved_prefs = memory:load_global("ui_prefs")
if saved_prefs then
    LOG.info("INIT", "User preferences RE-APPLIED")
    for k, v in pairs(saved_prefs) do
        if UI[k] ~= nil then UI[k] = v end
    end
end


-- ── Window size bounds (dp) ───────────────────────────────────────────────────
-- Referenced by applyWindowResize and settings sliders.
-- RESIZE_MAX_W/H are clamped to screen size here and must not be overwritten
-- again later (dp() lazy-init no longer touches these).
RESIZE_MIN_W = 400
RESIZE_MAX_W = 650
RESIZE_MIN_H = 200
RESIZE_MAX_H = 650
-- Sidebar width (dp). Wide enough for icon + "ADVENTURE MENU" label on 2 lines.
SIDEBAR_W = 125
-- Fixed dp overhead for header row (not part of the resizable scroll area).
-- Keeps mParams.height explicit so WindowManager doesn't expand the overlay to full screen.
-- Global so switchToMenu in main.lua can restore mParams.height correctly.
UI_CHROME_H = 55

-- Window size preferences (persisted globally across restarts)
-- WIN_W : panel width in dp
-- WIN_H : scroll-area height in dp
do
    local metrics   = activity.getResources().getDisplayMetrics()
    local screen_wdp = math.floor(metrics.widthPixels  / metrics.density)
    local screen_hdp = math.floor(metrics.heightPixels / metrics.density)

    RESIZE_MAX_W = math.min(RESIZE_MAX_W, math.floor(screen_wdp * 0.85))
    RESIZE_MAX_H = math.min(RESIZE_MAX_H, math.floor(screen_hdp * 0.75))

    local prefs = memory:load_global("window_size")
    WIN_W = math.min(math.max((prefs and prefs.w) or DEFAULT_WIN_W, RESIZE_MIN_W), RESIZE_MAX_W)
    WIN_H = math.min(math.max((prefs and prefs.h) or 333,           RESIZE_MIN_H), RESIZE_MAX_H)
end

loadModule("core/engines/patches.lua")

-- Detects arch, loads matching data from manifest → sets globals: aobs, offsets
loadModule("core/engines/arch.lua")

-- Lazy tab registry → returns {tabHandlers, categoryHandlers}
tabHandlers, categoryHandlers = loadModule("modules/registry.lua")

loadModule("ui/ui.lua")


-- ── Process attachment ────────────────────────────────────────────────────────

local PKG = "com.fingersoft.hcr2"
gg.setVisible(false)
showToast(T("main.initializing"), true)

local target_info = gg.getTargetInfo()
if not target_info then gg.alert(T("main.no_app_found")); os.exit() end
if not target_info.x64 then
    showDialog(T("main.arch_64bit_required_title"), T("main.arch_64bit_required_msg"))
    os.exit()
end

function fetchLatestVersion()
    local raw, err = paste.get(RELEASE_API)
    if not raw then return nil, nil, nil, err end
    
    local ok, data = pcall(function() return json.decode(raw) end)
    if not ok or type(data) ~= "table" then
        return nil, nil, nil, "Failed to parse release JSON"
    end
    
    local tag  = tostring(data.tag_name or ""):gsub("^v", "")
    local body = data.body
    local url  = nil
    
    if type(data.assets) == "table" then
        for _, asset in ipairs(data.assets) do
            if type(asset.browser_download_url) == "string" and asset.browser_download_url:match("%.lua$") then
                url = asset.browser_download_url
                break
            end
        end
    end
    
    if tag == "" then return nil, nil, nil, "Could not parse release tag" end
    return tag, url, body
end
    
function versionNewer(remote, current)
    local function parts(v)
        local t = {}
        for n in v:gmatch("%d+") do t[#t+1] = tonumber(n) end
        return t
    end
    local r, c = parts(remote), parts(current)
    for i = 1, math.max(#r, #c) do
        local a, b = r[i] or 0, c[i] or 0
        if a > b then return true end
        if a < b then return false end
    end
    return false
end

local auto_update = memory:load_global("auto_update")
if auto_update and not IS_DEV then
    local remote_ver, download_url, release_body = fetchLatestVersion()
    if remote_ver and versionNewer(remote_ver, CURRENT_VERSION) and download_url then
        local msg = T("main.update_available_msg", remote_ver, CURRENT_VERSION, release_body or T("main.no_changelog"))
        showDialog(T("main.update_available_title"), msg, {T("common.update_button"), function()
            showToast(T("main.downloading_version", remote_ver))
            local content, err = paste.get(download_url)
            if not content then
                showDialog(T("common.failed"), T("main.update_download_failed_msg", tostring(err)), {T("common.ok")})
                return
            end

            -- Save as a new file next to the current script
            local script_dir  = SCRIPT_PATH:match("^(.*[/\\])") or ""
            local new_path    = script_dir .. "void_v" .. remote_ver .. ".lua"

            local f = io.open(new_path, "w")
            if not f then
                showDialog(T("common.failed"), T("main.update_write_failed_msg", new_path), {T("common.ok")})
                return
            end
            f:write(content)
            f:close()
            
            showDialog(
                T("main.update_done_title", remote_ver),
                T("main.update_done_msg", remote_ver),
                {T("common.got_it")}
            )
            
            showToast(T("main.launching_version", remote_ver))
            local ok, load_err = pcall(function() dofile(new_path) end)
            if not ok then
                showDialog(T("common.launch_failed"), T("main.launch_failed_msg", tostring(load_err)), {T("common.ok")})
                return
            end

            exitScript()
        end}, {T("common.later")})
    end
end

local function detectVirtualSpace()
    if not Config.vSpaceReal then
        LOG.info("detectVM", "Real root detected.")
        return 0, "/data/data/" .. PKG
    end
    
    local info = gg.getTargetInfo()
    local dataDir = info.dataDir
    local game_pkg = info.packageName
    local first_pkg = dataDir:match("^/data/data/([^/]+)") or dataDir:match("^/data/user/%d+/([^/]+)")
    local vm_pkg
    
    if Config.E and Config.E ~= "" and Config.E ~= gg.PACKAGE then
        vm_pkg = Config.E
    end
    
    if first_pkg and first_pkg ~= game_pkg then
        vm_pkg = first_pkg
    else
        vm_pkg = nil
    end
    
    if vm_pkg == nil then
        return 2, nil
    end
    
    local result = Shell.sh("find /data/data/" .. vm_pkg .. " -maxdepth 8 -name '" .. PKG .. "' -type d 2>/dev/null")

    if result and result:find("Permission denied by user") then
        LOG.warn("detectVM", "User denied shell permission.")
        return 3, nil
    end

    if not result or result == "" then
        LOG.warn("detectVM", "HCR2 not found in VM: " .. vm_pkg)
        return 2, nil
    end
    
    -- Collect all matches first
    local by_uid = {}
    for path in result:gmatch("([^\n]+)") do
        if path:find(PKG, 1, true)
        and path:find("/user/", 1, true)
        and not path:find("/user_de/", 1, true) then
            local uid = path:match("/user/(%d+)/") or "?"
            -- Keep shortest path per uid (= the root, not nested subdirs)
            if not by_uid[uid] or #path < #by_uid[uid] then
                by_uid[uid] = path
            end
        end
    end
    
    -- Build sorted paths table
    local paths = {}
    for uid, path in pairs(by_uid) do
        table.insert(paths, path)
    end
    
    table.sort(paths, function(a, b)
        local ua = tonumber(a:match("/user/(%d+)/") or "0") or 0
        local ub = tonumber(b:match("/user/(%d+)/") or "0") or 0
        return ua < ub
    end)

    if #paths == 0 then
        LOG.warn("detectVM", "No valid /user/ paths found in VM: " .. vm_pkg)
        return 2, nil
    end

    -- Single path — no need to ask
    if #paths == 1 then
        LOG.info("detectVM", "Single HCR2 path: " .. paths[1])
        return 1, paths[1]
    end

    -- Multiple spaces with HCR2 — ask user, loop until selection made
    LOG.info("detectVM", "Multiple HCR2 paths found: " .. tostring(#paths))

    local items = {}
    for _, path in ipairs(paths) do
        local uid = path:match("/user/(%d+)/") or "?"
        local short = path:match("(user/.-/" .. PKG .. ")") or path
        table.insert(items, T("main.user_space_item", uid, short))
    end
    
    local selected = nil
    while not selected or selected == 0 do
        selected = showList(
            T("main.multiple_spaces_title"),
            T("main.multiple_spaces_desc", tostring(#paths)),
            items
        )
        if not selected or selected == 0 then
            showToast(T("main.select_space_toast"))
        end
    end

    local chosen = paths[selected]
    LOG.info("detectVM", "User selected: " .. chosen)
    return 1, chosen
end

if not exit then
    local vm_status
    vm_status, game_path = detectVirtualSpace()
    
    if vm_status == 3 then
        showDialog(T("main.permission_error_title"),
            T("main.permission_error_msg"),
            {T("common.ok")})
        os.exit()
    end
    
    if vm_status == 2 or game_path == nil then
        local action = showDialog(
            T("main.hcr2_not_found_title"),
            T("main.hcr2_not_found_msg"),
            {T("common.proceed_anyway")}, {T("common.manual_mode")}, {T("common.retry")}
        )
    
        if action == 1 then
            -- Proceed without path — affected modules will handle nil game_path gracefully
            LOG.warn("Main", "Proceeding without game_path.")
    
        elseif action == 2 then
            -- Manual mode — replace gg.prompt with showPrompt
            local response = showPrompt(T("main.manual_data_path_title"), {
                {T("main.manual_data_path_hint"), "text", "/"}
            })
            if response and response[1] and response[1] ~= "" then
                vm_status = 1
                game_path = response[1]
                LOG.info("Main", "Manual path set: " .. game_path)
            else
                showToast(T("main.manual_path_cancelled"))
                LOG.warn("Main", "Manual path cancelled.")
            end
    
        elseif action == 3 then
            -- Retry detection
            vm_status, game_path = detectVirtualSpace()
            LOG.info("Main", "Retry result: vm_status=" .. tostring(vm_status) .. " path=" .. tostring(game_path))
        end
    end
    
    local function awaitLib(lib)
        local tick_count = 0
        while #gg.getRangesList(lib) == 0 do
            tick_count = tick_count + 1
            if tick_count % 7 == 0 then showToast(T("main.waiting_for_lib", lib)) end
            gg.sleep(500)
            if tick_count > 120 then return false end
        end
        return true
    end
    
    if not awaitLib("libcocos2dcpp.so") then os.exit() end
    
    function readString(addr, max_len)
        max_len = max_len or 64
        local reads = {}
        for i = 0, max_len - 1 do
            table.insert(reads, { address = addr + i, flags = 1 })
        end
        local result = gg.getValues(reads)
        local bytes  = {}
        for _, v in ipairs(result) do
            if v.value == 0 then break end
            local b = v.value < 0 and v.value + 256 or v.value
            table.insert(bytes, string.char(b))
        end
        return table.concat(bytes)
    end
    
    -- ── GameStatus resolution ─────────────────────────────────────────────────────
    
    local SEARCH_REGIONS = { gg.REGION_C_ALLOC, gg.REGION_OTHER }
    local saved_status   = memory:load("gamestatus")
    
    shellStates   = memory:load("shell_states")   or { root = false }
    toggleStates  = memory:load("toggle_states")  or {}
    inputStates   = memory:load("input_states")   or {}
    spinnerStates = memory:load("spinner_states") or {}
    sliderStates  = memory:load("slider_states")  or {}
    
    if saved_status then
        BaseRegion, BaseGameStatus, BaseGameStatusRaw = saved_status[1], saved_status[2], saved_status[3]
        LOG.info("INIT", string.format(
            "GameStatus restored from cache | BaseRegion=0x%X  BaseGameStatus=0x%X  BaseGameStatusRaw=0x%X",
            BaseRegion, BaseGameStatus, BaseGameStatusRaw))
    else
        LOG.info("INIT", string.format(
            "GameStatus not cached — scanning %d region(s): %s",
            #SEARCH_REGIONS,
            (function()
                local names = {}
                for _, r in ipairs(SEARCH_REGIONS) do
                    names[#names+1] = (r == gg.REGION_C_ALLOC and "C_ALLOC" or
                                       r == gg.REGION_OTHER    and "OTHER"   or tostring(r))
                end
                return table.concat(names, ", ")
            end)()))

        for _, region in ipairs(SEARCH_REGIONS) do
            local regionName = (region == gg.REGION_C_ALLOC and "C_ALLOC" or
                                region == gg.REGION_OTHER    and "OTHER"   or tostring(region))
            LOG.info("INIT", "Scanning region: " .. regionName)

            gg.clearResults(); gg.setRanges(region)
            gg.searchNumber("h 73 74 61 72 74 75 70 5F 63 6F 75 6E 74", gg.TYPE_BYTE)
            gg.refineNumber("h 73", gg.TYPE_BYTE)
            local scan_results = gg.getResults(gg.getResultsCount())
            gg.clearResults()

            LOG.info("INIT", string.format("  AOB scan hits: %d", #scan_results))

            local status_hits     = {}
            local status_raw_hits = {}
            local ptr_zero        = 0
            local ver_mismatch    = 0

            for _, d in ipairs(scan_results) do
                local ptr = gg.getValues({ { address = d.address + 0x1F, flags = gg.TYPE_QWORD } })[1]
                if ptr and ptr.value ~= 0 then
                    -- Sanity-check: a real pointer should be in a plausible
                    -- memory range (above 0x10000). Values that look like ASCII
                    -- text are false-positive AOB matches inside string literals.
                    local pv = ptr.value
                    if pv < 0x10000 or pv > 0x7FFFFFFFFFFF then
                        ptr_zero = ptr_zero + 1
                        LOG.dbg("INIT", string.format(
                            "  implausible ptr at 0x%X → 0x%X (likely AOB false-positive in string literal)",
                            d.address, pv))
                    else
                        local ver = gg.getValues({ { address = pv + 0x10, flags = gg.TYPE_DWORD } })[1]
                        local v   = ver and tonumber(ver.value)
                        if v == 65792 or v == 65793 or v == 16843008 or v == 16843009 then
                            table.insert(status_raw_hits, ver.address)
                            local tp = gg.getValues({ { address = pv + 0x80, flags = gg.TYPE_QWORD } })[1]
                            if tp and tp.value ~= 0 then
                                local td = gg.getValues({ { address = tp.value, flags = gg.TYPE_DWORD } })[1]
                                if td then table.insert(status_hits, td.address) end
                            end
                        else
                            ver_mismatch = ver_mismatch + 1
                            LOG.dbg("INIT", string.format(
                                "  ver mismatch at 0x%X → ptr=0x%X  ver=0x%X (%s)",
                                d.address, pv, v or 0, tostring(v)))
                        end
                    end
                else
                    ptr_zero = ptr_zero + 1
                end
            end

            LOG.info("INIT", string.format(
                "  Region %s — ptr_zero=%d  ver_mismatch=%d  status_hits=%d",
                regionName, ptr_zero, ver_mismatch, #status_hits))

            if #status_hits > 0 then
                BaseRegion, BaseGameStatus, BaseGameStatusRaw = region, status_hits[1], status_raw_hits[1]
                memory:save("gamestatus", { region, status_hits[1], status_raw_hits[1] })
                LOG.info("INIT", string.format(
                    "  ✓ Found in %s | BaseGameStatus=0x%X  BaseGameStatusRaw=0x%X",
                    regionName, BaseGameStatus, BaseGameStatusRaw))
                break
            else
                LOG.warn("INIT", "  ✗ Not found in " .. regionName)
            end
        end

        if BaseGameStatus == nil then
            LOG.fatal("INIT", "GameStatus not found in any region — is the game running and past the loading screen?")
        end
    end
    
    showToast(T("main.initialized"), true)
    LOG.info("INIT", "Initialized | BaseGameStatus=" .. tostring(BaseGameStatus) .. " BaseRegion=" .. tostring(BaseRegion))
    
    if BaseGameStatus == nil or BaseRegion == nil then
        LOG.fatal("INIT", "BaseGameStatus or BaseRegion is NIL — floating menu will NOT appear!")
        LOG.flush()
        local tip = (DEVICE_ARCH == DEFAULT_ARCH)
            and T("main.gamestatus_not_found_tip_arm64")
            or  T("main.gamestatus_not_found_tip_x86")
        showDialog(T("main.gamestatus_not_found"), tip, T("common.ok"))
        exit = true
    else
        LOG.info("INIT", "BaseGameStatus OK=" .. tostring(BaseGameStatus) .. " | scheduling initUI() via MainHandler")
        
        MainHandler.post(function()
            LOG.info("INIT", "MainHandler: calling initUI()")
            local ok, err = _safePcall(function() initUI() end)
            if not ok then
                LOG.fatal("INIT", "initUI() CRASHED: " .. tostring(err))
                LOG.flush()
            else
                LOG.info("INIT", "initUI() completed | menuView=" .. tostring(menuView) .. " iconView=" .. tostring(iconView) .. " activeView=" .. tostring(activeView))
            end
        end)
    end
    
    LOG.info("INIT", "activeView check before switchToIcon: activeView=" .. tostring(activeView))
    if activeView == nil then
        LOG.warn("INIT", "activeView is nil — calling switchToIcon() as fallback")
        switchToIcon()
    end
    
    
    -- ── Main loop ─────────────────────────────────────────────────────────────────
    LOG.info("MAIN", "Entering main loop | exit=" .. tostring(exit) .. " activeView=" .. tostring(activeView))
    LOG.flush()
    
    while not exit do
        local ok, err = pcall(function()
            if gg.isVisible(true) then gg.setVisible(false); gg.toast(T("main.dont_interrupt")) end
            if FORCE_EXIT then exitScript() end
            gg.sleep(100)
        end)
        if not ok then
            LOG.fatal("MAIN", "Main loop crashed: " .. tostring(err))
            LOG.flush()
            exitScript()
            break
        end
    end
end