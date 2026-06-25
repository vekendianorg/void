--[[
  core/engines/crash_handler.lua — Structured error capture layer

  Keeps two in-memory ring buffers that feed the Console tab:
    • crashes — explicit captures with a traceback (scheduler task failures,
                feature-module load failures, guarded calls). Cap: 50.
    • logs    — every LOG line (all levels: INFO/DEBUG/WARN/ERROR/FATAL),
                mirrored here via a sink installed into main.lua's logger. Cap: 250.

  Also provides loadFeature(), a NON-FATAL loader for feature/core modules: a
  crash while loading one feature is captured and a safe stub is returned, so
  the rest of the UI keeps working instead of the whole script exiting.

  Sets global: CrashHandler  (assigned by main.lua from this file's return)
  Installs:    __log_sink     (read by the logger in main.lua)

  Globals used: loadModule, LOG, os.
]]

local MAX_CRASHES = 50
local MAX_LOGS    = 250  -- all levels are captured now, so allow a deeper tail

local crashes = {}   -- ring buffer (oldest first)
local logs    = {}   -- ring buffer (oldest first)

local function push(ring, max, entry)
    ring[#ring + 1] = entry
    if #ring > max then table.remove(ring, 1) end
end

-- Trim an existing ring buffer to a new (smaller) cap immediately.
local function trimTo(ring, max)
    while #ring > max do table.remove(ring, 1) end
end

-- Wall-clock stamp. os.date is available in this environment.
local function stamp()
    local ok, s = pcall(os.date, "%H:%M:%S")
    return ok and s or "??:??:??"
end

local function trim(s) return (tostring(s):gsub("%s+$", "")) end

local CrashHandler = {}

-- Record a crash. `traceback` is optional but strongly preferred.
function CrashHandler.capture(tag, message, traceback)
    local entry = {
        kind      = "crash",
        ts        = stamp(),
        tag       = tostring(tag or "?"),
        message   = trim(message),
        traceback = traceback and tostring(traceback) or nil,
    }
    push(crashes, MAX_CRASHES, entry)
    -- Mirror to the debug log for file persistence. The "[CRASH]" sentinel
    -- lets onLog skip it so it isn't double-listed in the logs ring.
    if LOG then pcall(LOG.error, entry.tag, "[CRASH] " .. entry.message) end
    return entry
end

-- LOG sink installed into main.lua's _write. Keeps every level; the Console
-- colors them by severity. Crash mirrors (tagged "[CRASH]") are skipped so they
-- aren't double-listed alongside the crashes ring.
function CrashHandler.onLog(level, tag, message)
    local lv = trim(level)
    if type(message) == "string" and message:find("[CRASH]", 1, true) then return end
    push(logs, MAX_LOGS, {
        kind    = "log",
        ts      = stamp(),
        level   = lv,
        tag     = tostring(tag or ""),
        message = tostring(message or ""),
    })
end

-- Run fn(...) guarded; capture (with traceback) on error.
-- Returns ok, result (result is nil on failure).
function CrashHandler.guard(tag, fn, ...)
    local args, n = { ... }, select("#", ...)
    local ok, res = xpcall(
        function() return fn(table.unpack(args, 1, n)) end,
        function(e) return (debug and debug.traceback) and debug.traceback(tostring(e), 2) or tostring(e) end
    )
    if not ok then
        CrashHandler.capture(tag, (tostring(res):match("^[^\n]*")) or res, res)
        return false, nil
    end
    return true, res
end

-- Non-fatal feature/core module loader. On failure, captures the crash and
-- returns a stub table: indexing any key yields a no-op function that still
-- invokes a trailing callback argument (cb/done), so the UI never hard-locks.
local STUB = setmetatable({}, {
    __index = function()
        return function(...)
            local a = { ... }
            local last = a[#a]
            if type(last) == "function" then pcall(last, "unavailable") end
        end
    end,
})

function CrashHandler.loadFeature(name)
    local mod, err = loadModule(name, true)  -- soft = non-fatal
    if mod == nil then
        CrashHandler.capture("loadFeature", "Failed to load " .. tostring(name) .. ": " .. tostring(err), err)
        return STUB
    end
    return mod
end

-- ── Accessors for the Console tab ─────────────────────────────────────────────

function CrashHandler.getCrashes() return crashes end
function CrashHandler.getLogs()    return logs end
function CrashHandler.counts()     return #crashes, #logs end
function CrashHandler.isEmpty()    return #crashes == 0 and #logs == 0 end

function CrashHandler.getCaps()
    return MAX_CRASHES, MAX_LOGS
end

-- Update caps at runtime (called from Settings). Immediately trims existing
-- buffers so they don't exceed the new cap.
function CrashHandler.setCaps(crashCap, logCap)
    crashCap = math.max(5, math.min(500,  tonumber(crashCap) or MAX_CRASHES))
    logCap   = math.max(5, math.min(2000, tonumber(logCap)   or MAX_LOGS))
    MAX_CRASHES = crashCap
    MAX_LOGS    = logCap
    trimTo(crashes, MAX_CRASHES)
    trimTo(logs,    MAX_LOGS)
    LOG.info("CrashHandler", string.format("Caps updated: crashes=%d  logs=%d", MAX_CRASHES, MAX_LOGS))
end

function CrashHandler.clear()
    for i = #crashes, 1, -1 do crashes[i] = nil end
    for i = #logs, 1, -1 do logs[i] = nil end
end

-- Flat text dump for the Console "Copy all" button.
function CrashHandler.formatAll()
    local out = {}
    out[#out + 1] = "===== VOID Console ====="
    out[#out + 1] = "crashes=" .. #crashes .. "  logs=" .. #logs
    out[#out + 1] = ""
    out[#out + 1] = "----- CRASHES & ERRORS -----"
    if #crashes == 0 then out[#out + 1] = "(none)" end
    for _, e in ipairs(crashes) do
        out[#out + 1] = string.format("[%s] [%s] %s", e.ts, e.tag, e.message)
        if e.traceback then out[#out + 1] = e.traceback end
        out[#out + 1] = ""
    end
    out[#out + 1] = "----- LOGS -----"
    if #logs == 0 then out[#out + 1] = "(none)" end
    for _, e in ipairs(logs) do
        out[#out + 1] = string.format("[%s] [%s] [%s] %s", e.ts, e.level, e.tag, e.message)
    end
    return table.concat(out, "\n")
end

-- Install the logger sink so WARN+ lines start flowing in immediately.
__log_sink = CrashHandler.onLog

return CrashHandler
