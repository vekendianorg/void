--[[
  Player Tab - Vehicle and character modifications
  Features: Auto-detach, Auto-die, No-clip, Hide name/flag, Zoom, Gravity

  UI wiring only. Memory ops live in modules/ops/player.lua.

  @module callback Receives container View to populate with modules
]]

local ops = CrashHandler.loadFeature("modules/ops/player.lua")

return function(container)
    local function t(key, ...) return T("player." .. key, ...) end

    addArchModule(container, "auto_detach", t("auto_detach.title"), t("auto_detach.desc"), "switch", nil, aobs.autoDetach)

    addArchModule(container, "auto_die", t("auto_die.title"), t("auto_die.desc"), "switch", nil, aobs.autoDie)

    addModule(container, "no_clip", t("no_clip.title"), t("no_clip.desc"), "switch", nil,
    function(done, state)
        ops.noClip(state, function(status)
            showToast(t("no_clip." .. status), true)
        end)
        done()
    end)

    addModule(container, "hide_name", t("hide_name.title"), t("hide_name.desc"), "switch", nil,
    function(done, state)
        ops.hideName(state, function(status)
            showToast(t("hide_name." .. status), true)
        end)
        done()
    end)

    addModule(container, "hide_flag", t("hide_flag.title"), t("hide_flag.desc"), "switch", nil,
    function(done, state)
        ops.hideFlag(state, function(status)
            showToast(t("hide_flag." .. status), true)
        end)
        done()
    end)

    addModule(container, "zoom", t("zoom.title"), t("zoom.desc"), "slider", {
        {title=t("slider.min"), min=10, max=100, current=20},
        {title=t("slider.max"), min=10, max=100, current=50}
    }, function(done, vals)
        ops.setZoom(vals, function() end)
        done()
    end)

    addModule(container, "gravity", t("gravity.title"), t("gravity.desc"), "slider", {
        {title=t("slider.x"), min=-100, max=100, current=0},
        {title=t("slider.y"), min=-100, max=100, current=-10}
    }, function(done, vals)
        ops.setGravity(vals, function() end)
        done()
    end)
end
