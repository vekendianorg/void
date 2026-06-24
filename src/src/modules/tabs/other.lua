--[[
  Other Tab - Misc features
  Features: Debug mode, Change aspect ratio, Set resolution, Set resolution offset

  UI wiring only. Memory ops live in modules/ops/other.lua.
  done() is called right after dispatch (not inside the result callback) so a
  crash in the scheduled work can't leave a card stuck.

  @module callback Receives container View to populate with modules
]]

local ops = CrashHandler.loadFeature("modules/ops/other.lua")

-- Aspect-ratio presets (index matches other.aspect_ratio.options), applied as a
-- matching resolution at 1080p height via the shared resolution op.
local RATIOS = {
    { w = 1920, h = 1080 }, -- 16:9
    { w = 2160, h = 1080 }, -- 18:9
    { w = 2340, h = 1080 }, -- 19.5:9
    { w = 2400, h = 1080 }, -- 20:9
    { w = 2520, h = 1080 }, -- 21:9
    { w = 1440, h = 1080 }, -- 4:3
}

return function(container)
    local function t(key, ...) return T("other." .. key, ...) end

    addModule(container, "debug_mode", t("debug_mode.title"), t("debug_mode.desc"), "switch", nil, function(done, state)
        ops.debugMode(state, function(status)
            showToast(t("debug_mode." .. status), true)
        end)
        done()
    end)

    addModule(container, "aspect_ratio", t("aspect_ratio.title"), t("aspect_ratio.desc"), "spinner", {
        options = t("aspect_ratio.options"),
        default = 4
    }, function(done, item, index)
        local r = RATIOS[index] or RATIOS[1]
        ops.setResolution({ width = r.w, height = r.h }, function(status)
            if status == "glsurface_not_found" then
                gg.toast(t("glsurface_not_found"))
            elseif status == "applied" then
                gg.toast(t("aspect_ratio.applied", item))
            end
        end)
        done()
    end)

    addModule(container, "resolution", t("resolution.title"), t("resolution.desc"), "input", {
        {hint = t("hint.width"), type = "number"},
        {hint = t("hint.height"), type = "number"}
    }, function(done, vals)
        ops.setResolution({ width = vals[1], height = vals[2] }, function(status, data)
            if status == "glsurface_not_found" then
                gg.toast(t("glsurface_not_found"))
            elseif status == "applied" then
                gg.toast(t("resolution.applied", data.width, data.height))
            end
        end)
        done()
    end)

    addModule(container, "resolution_offset", t("resolution_offset.title"), t("resolution_offset.desc"), "input", {
        {hint = t("hint.width"), type = "number"},
        {hint = t("hint.height"), type = "number"}
    }, function(done, vals)
        ops.setResolutionOffset({ width = vals[1], height = vals[2] }, function(status, data)
            if status == "glsurface_not_found" then
                gg.toast(t("glsurface_not_found"))
            elseif status == "applied" then
                gg.toast(t("resolution_offset.applied", data.width, data.height))
            end
        end)
        done()
    end)

    --[[
    -- mods_packs: disabled pending pack-swapping implementation. UI only.
    addModule(container, "mods_packs", "Mods Packs", "...", "spinner", {
        options = {"Default", "KAR's Pack"}, default = 1
    }, function(done, item, index)
        -- TODO: implement pack swapping logic per path
        done()
    end)
    ]]--
end
