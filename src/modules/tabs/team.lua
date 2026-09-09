--[[
  Team Tab - Team mode features
  Features: Team Size Bypass

  UI wiring only. Memory ops live in modules/ops/team.lua.
  done() is called right after dispatch (not inside the result callback) so a
  crash in the scheduled work can't leave a card stuck.

  @module callback Receives container View to populate with modules
]]

local ops = CrashHandler.loadFeature("modules/ops/team.lua")

return function(container)
    local function t(key, ...) return T("team." .. key, ...) end

    addModule(container, "team_size_bypass", t("team_size_bypass.title"),
        t("team_size_bypass.desc"), "switch", nil, function(done, state)
        ops.teamSizeBypass(state, function(status)
            showToast(t("team_size_bypass." .. status), true)
        end)
        done()
    end)
end
