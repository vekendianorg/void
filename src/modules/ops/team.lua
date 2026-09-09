--[[[
  modules/ops/team.lua — Team feature memory ops (no UI)
  Contract: see modules/ops/README.md.

  Uses the vendored Nebula SDK (Nebula.TeamEvent) for base resolution
  and typed field access. All ops serialize on the scheduler.

  Globals used: scheduler, storage, Nebula, LOG.
]]

local M = {}

-- Team Size Bypass toggle.
-- status: "enabled" | "disabled" | "resolve_failed" | "nebula_unavailable"
function M.teamSizeBypass(state, cb)
    scheduler:add(function(finishTask)
        local TAG = "TeamSizeBypass"

        if not (Nebula and Nebula.TeamEvent) then
            LOG.warn(TAG, "Nebula SDK unavailable")
            finishTask(); cb("nebula_unavailable"); return
        end

        if state then
            -- Enable: read the current server value first so we can
            -- restore it exactly on disable.
            local current, getErr = Nebula.TeamEvent.get("minTeamSizeToJoin")
            if current == nil then
                LOG.warn(TAG, "resolve failed: " .. tostring(getErr))
                finishTask(); cb("resolve_failed"); return
            end
            storage:save_session("team_size_bypass_orig", current)

            local op = Nebula.TeamEvent.set("minTeamSizeToJoin", 1)
            if not op._ok then
                LOG.error(TAG, "set failed: " .. tostring(op._err))
                finishTask(); cb("resolve_failed"); return
            end

            LOG.info(TAG, string.format("bypass ON  | original min=%s", tostring(current)))
            finishTask(); cb("enabled")
        else
            -- Disable: restore the original value (fallback to default).
            local orig = storage:load_session("team_size_bypass_orig") or 5

            local op = Nebula.TeamEvent.set("minTeamSizeToJoin", orig)
            if not op._ok then
                LOG.error(TAG, "set failed: " .. tostring(op._err))
                finishTask(); cb("resolve_failed"); return
            end

            LOG.info(TAG, string.format("bypass OFF | restored min=%s", tostring(orig)))
            finishTask(); cb("disabled")
        end
    end)
end

return M