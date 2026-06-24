-- core/env.lua — Java/Android environment gate
-- Loaded before any imports. Calls os.exit() on failure; no return value.

local function fail(msg)
    if gg.alert("Environment check failed!\n\n" .. msg .. "\n\nUse GG: ME by Vekendian.", "Get GG: ME", "OK") == 1 then
        gg.copyText("https://github.com/vekendianorg/me/releases")
    end
    os.exit()
end

if type(luajava)  ~= "table"    then fail("LuaJava not detected.") end
if type(import)   ~= "function" then fail("import() unavailable.") end
if not pcall(function() import("java.lang.String") end)  then fail("Core Java classes unavailable.") end
if not pcall(function() import("android.os.Build") end)  then fail("Android API unavailable.") end

do
    local V = import("android.os.Build$VERSION")
    if V.SDK_INT < 21 then
        fail(("Android 5.0+ (API 21) required. Detected API %d."):format(V.SDK_INT))
    end
end

local required = {
    "android.ext.Tools", "android.ext.rx", "android.ext.Script",
    "android.ext.Config", "android.ext.MainService",
    "org.vekendian.Crypto", "org.vekendian.Ui", "org.vekendian.Zip",
}
local missing = {}
for _, cls in ipairs(required) do
    if not pcall(function() luajava.bindClass(cls) end) then
        missing[#missing + 1] = cls
    end
end
if #missing > 0 then fail("Missing classes:\n" .. table.concat(missing, "\n")) end
