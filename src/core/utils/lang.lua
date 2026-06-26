--[[
  core/utils/lang.lua — Multi-language engine

  Loads configs/lang/<code>.lua (a flat table of dotted keys -> strings)
  and exposes a global T(key, ...) lookup used by every user-facing string
  in the project. English (configs/lang/en.lua) is always loaded as the
  fallback table so a partially-translated language file never produces
  blank UI text — missing keys silently fall back to English, then to the
  raw key itself if even English is missing it (should never happen).

  Sets globals:
    T(key, ...)        -- string lookup + optional string.format args
    setLanguage(code)   -- switch active language at runtime, persists choice
    LANG_CODE           -- currently active language code, e.g. "en"
    LANG_AVAILABLE       -- ordered list of { code, name } for the spinner UI

  To add a new language:
    1. Copy configs/lang/en.lua to configs/lang/<code>.lua and translate
       every value (keep the %s/%d placeholders intact).
    2. Add { code = "<code>", name = "<Native Name>" } to AVAILABLE below.
  That's it — settings.lua's Language spinner picks it up automatically.
]]

-- ── Available languages ──────────────────────────────────────────────────────
-- "name" is shown in the Settings → Language picker, in that language's own
-- script (e.g. "Español", not "Spanish") so users can find their language
-- without needing to read English first.

local AVAILABLE = {
    { code = "en", name = "English" },
    { code = "id", name = "Bahasa Indonesia" },
    { code = "es", name = "Español" },
    { code = "de", name = "Deutsch" },
    { code = "ru", name = "Русский" },
    { code = "th", name = "Thai" },
    { code = "bn", name = "বাংলা" },
    { code = "ar", name = "العربية" },
    { code = "ur", name = "اردو" },
    { code = "fr", name = "Français" },
    { code = "uk", name = "Українська" },
    { code = "tr", name = "Türkçe" },
    { code = "pt-BR", name = "Português (Brasil)" },
    { code = "hi", name = "हिन्दी" },
    { code = "it", name = "Italiano" },
    { code = "zh-CN", name = "简体中文" },
}

-- ── Safe, non-fatal module loader ────────────────────────────────────────────
-- main.lua's global loadModule() is fatal-on-failure (gg.alert + os.exit),
-- which is correct for core framework files but wrong here: a missing or
-- broken language file should silently fall back to English, never crash
-- the script. This loader returns nil instead of exiting.
local function tryLoadLangFile(code)
    local ok, result = pcall(loadModule, "configs/lang/" .. code .. ".lua")
    if not ok or type(result) ~= "table" then return nil end
    return result
end

-- ── Credits base layer ───────────────────────────────────────────────────────
-- Loaded before EN so that arch-universal content (names, handles, URLs) lives
-- in one place. T() checks CREDITS last, after ACTIVE and EN, so a lang file
-- can still override any key here if truly needed (shouldn't be necessary).
local ok_credits, CREDITS = pcall(loadModule, "configs/credits.lua")
if not ok_credits or type(CREDITS) ~= "table" then
    LOG.warn("Lang", "configs/credits.lua failed to load — credits will fall through to EN")
    CREDITS = {}
end

local EN = tryLoadLangFile("en")
if not EN then
    -- English itself is the framework's hard dependency; if it's missing
    -- something is badly wrong with the install, but we still shouldn't
    -- crash the whole script over missing translations.
    LOG.error("Lang", "configs/lang/en.lua failed to load — falling back to raw keys")
    EN = {}
end

local ACTIVE      = EN
local ACTIVE_CODE = "en"

local saved_code = memory:load_global("language")
if saved_code and saved_code ~= "en" then
    local loaded = tryLoadLangFile(saved_code)
    if loaded then
        ACTIVE      = loaded
        ACTIVE_CODE = saved_code
    else
        LOG.warn("Lang", "Saved language '" .. tostring(saved_code) .. "' failed to load — using English")
    end
end

LANG_CODE      = ACTIVE_CODE
LANG_AVAILABLE = AVAILABLE

---Looks up a translated string by dotted key, with optional string.format args.
---Falls back to English on a missing key in the active language, then to the
---bare key string if even English doesn't have it (so missing translations
---are visibly obvious in testing rather than silently blank).
---@param key string Dotted key, e.g. "settings.auto_update.title"
---@param ... any Optional string.format arguments
---@return any string (or table, for list-valued entries like spinner options)
function T(key, ...)
    local entry = ACTIVE[key]
    if entry == nil then entry = EN[key] end
    if entry == nil then entry = CREDITS[key] end
    if entry == nil then
        LOG.warn("Lang", "Missing translation key: " .. tostring(key))
        return key
    end

    local n = select("#", ...)
    if n > 0 and type(entry) == "string" then
        local ok, formatted = pcall(string.format, entry, ...)
        if ok then return formatted end
        LOG.warn("Lang", "Format failed for key: " .. tostring(key))
    end

    return entry
end

---Switches the active language at runtime and persists the choice.
---Returns true on success, false if the language file failed to load
---(active language is left unchanged on failure).
---@param code string Language code, e.g. "en"
---@return boolean
function setLanguage(code)
    if code == ACTIVE_CODE then return true end

    if code == "en" then
        ACTIVE, ACTIVE_CODE = EN, "en"
        LANG_CODE = "en"
        memory:save_global("language", "en")
        return true
    end

    local loaded = tryLoadLangFile(code)
    if not loaded then
        LOG.warn("Lang", "setLanguage failed — could not load: " .. tostring(code))
        return false
    end

    ACTIVE, ACTIVE_CODE = loaded, code
    LANG_CODE = code
    memory:save_global("language", code)
    return true
end

return true
