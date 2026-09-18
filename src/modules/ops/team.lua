--[[[
  modules/ops/team.lua — Team feature memory ops (no UI)
  Contract: see modules/ops/README.md.

  Uses the vendored Nebula SDK (Nebula.TeamEvent, 1.0.0 API: get/set
  returning chainable ops with :verify()) for base resolution and typed
  field access. All ops serialize on the scheduler.

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
            if op:verify()._verified == false then
                LOG.warn(TAG, "bypass ON read-back mismatch: expected=1 actual="
                    .. tostring(op._actual))
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
            if op:verify()._verified == false then
                LOG.warn(TAG, "bypass OFF read-back mismatch: expected="
                    .. tostring(orig) .. " actual=" .. tostring(op._actual))
            end

            LOG.info(TAG, string.format("bypass OFF | restored min=%s", tostring(orig)))
            finishTask(); cb("disabled")
        end
    end)
end



-- ── EventDefinition patches (switches; shared core: modules/lib/eventpatch.lua) ──
local eventpatch = loadModule("modules/lib/eventpatch.lua")

local KIND = "TeamEvent"

-- Unlimited Vehicle Usage (switch). -1 experiment: gameMode.defaultRunCountLimit
-- plus a same-length -1 array over gameMode.perVehicleRunCountLimits.
-- status: "applied" | "reverted" | "resolve_failed" | "nebula_unavailable" | "failed"
function M.unlimitedVehicleUsage(state, cb)
    scheduler:add(function(finishTask)
        local TAG = "UnlimitedVehicleUsage"
        local status, err = eventpatch.toggle(KIND, state,
            "ep_unlimited_usage_" .. KIND,
            { "gameMode.defaultRunCountLimit", "gameMode.perVehicleRunCountLimits" },
            function()
                local limits = eventpatch.get(KIND, "gameMode.perVehicleRunCountLimits")
                local writes = { { path = "gameMode.defaultRunCountLimit", value = -1 } }
                if type(limits) == "table" and #limits > 0 then
                    local neg = {}
                    for i = 1, #limits do neg[i] = -1 end
                    writes[#writes + 1] = { path = "gameMode.perVehicleRunCountLimits", value = neg }
                end
                return eventpatch.apply(KIND, writes)
            end)
        if status ~= "applied" and status ~= "reverted" then
            LOG.warn(TAG, "toggle failed: " .. tostring(err))
        end
        finishTask(); cb(status)
    end)
end

-- Allow All Vehicles (switch). Clear gameMode.bannedVehicles + fill
-- gameMode.allowedVehicles with every GameData vehicle id (vehicle_*.json -> *).
-- status: "applied" | "reverted" | "no_vehicles" | "resolve_failed" |
--         "nebula_unavailable" | "failed"
function M.allowAllVehicles(state, cb)
    scheduler:add(function(finishTask)
        local TAG = "AllowAllVehicles"
        local status, err = eventpatch.toggle(KIND, state,
            "ep_allow_all_vehicles_" .. KIND,
            { "gameMode.bannedVehicles", "gameMode.allowedVehicles" },
            function()
                local ids, ierr = eventpatch.vehicleIds()
                if not ids then
                    return (ierr == "nebula_unavailable") and "nebula_unavailable" or "no_vehicles", ierr
                end
                return eventpatch.apply(KIND, {
                    { path = "gameMode.bannedVehicles", value = {} },
                    { path = "gameMode.allowedVehicles", value = ids },
                })
            end)
        if status ~= "applied" and status ~= "reverted" then
            LOG.warn(TAG, "toggle failed: " .. tostring(err))
        end
        finishTask(); cb(status)
    end)
end

-- Free Entry Fee (switch). sessionEntry.entryFeeTickets = 0.
-- status: "applied" | "reverted" | "resolve_failed" | "nebula_unavailable" | "failed"
function M.freeEntryFee(state, cb)
    scheduler:add(function(finishTask)
        local status, err = eventpatch.toggle(KIND, state,
            "ep_free_entry_fee_" .. KIND,
            { "sessionEntry.entryFeeTickets" },
            function()
                return eventpatch.apply(KIND,
                    { { path = "sessionEntry.entryFeeTickets", value = 0 } })
            end)
        if status ~= "applied" and status ~= "reverted" then
            LOG.warn("FreeEntryFee", "toggle failed: " .. tostring(err))
        end
        finishTask(); cb(status)
    end)
end

-- Bonuses for All Vehicles (switch). bonusVehiclePool = every GameData vehicle id.
-- status: "applied" | "reverted" | "no_vehicles" | "resolve_failed" |
--         "nebula_unavailable" | "failed"
function M.vehicleBonuses(state, cb)
    scheduler:add(function(finishTask)
        local TAG = "VehicleBonuses"
        local status, err = eventpatch.toggle(KIND, state,
            "ep_vehicle_bonuses_" .. KIND,
            { "bonusVehiclePool" },
            function()
                local ids, ierr = eventpatch.vehicleIds()
                if not ids then
                    return (ierr == "nebula_unavailable") and "nebula_unavailable" or "no_vehicles", ierr
                end
                return eventpatch.apply(KIND,
                    { { path = "bonusVehiclePool", value = ids } })
            end)
        if status ~= "applied" and status ~= "reverted" then
            LOG.warn(TAG, "toggle failed: " .. tostring(err))
        end
        finishTask(); cb(status)
    end)
end

-- Custom Participants: gameMode.maxSessionParticipants = n (1..2147483647).
-- status: "applied" | "invalid" | "resolve_failed" | "nebula_unavailable" | "failed"
function M.customParticipants(n, cb)
    scheduler:add(function(finishTask)
        n = math.floor(tonumber(n) or 0)
        if n < 1 then finishTask(); cb("invalid"); return end
        if n > 2147483647 then n = 2147483647 end
        local status, err = eventpatch.apply(KIND,
            { { path = "gameMode.maxSessionParticipants", value = n } })
        if status ~= "applied" then LOG.warn("CustomParticipants", "apply failed: " .. tostring(err)) end
        finishTask(); cb(status)
    end)
end

-- Custom Session Duration: gameMode.duration = n seconds (1..2147483647).
-- status: "applied" | "invalid" | "resolve_failed" | "nebula_unavailable" | "failed"
function M.customDuration(n, cb)
    scheduler:add(function(finishTask)
        n = math.floor(tonumber(n) or 0)
        if n < 1 then finishTask(); cb("invalid"); return end
        if n > 2147483647 then n = 2147483647 end
        local status, err = eventpatch.apply(KIND,
            { { path = "gameMode.duration", value = n } })
        if status ~= "applied" then LOG.warn("CustomDuration", "apply failed: " .. tostring(err)) end
        finishTask(); cb(status)
    end)
end

-- Instant Ticket Refill (switch). sessionEntry refill time + cost = 0.
-- status: "applied" | "reverted" | "resolve_failed" | "nebula_unavailable" | "failed"
function M.instantTicketRefill(state, cb)
    scheduler:add(function(finishTask)
        local status, err = eventpatch.toggle(KIND, state,
            "ep_instant_refill_" .. KIND,
            { "sessionEntry.eventTicketRefillTime", "sessionEntry.eventTicketRefillCost" },
            function()
                return eventpatch.apply(KIND, {
                    { path = "sessionEntry.eventTicketRefillTime", value = 0 },
                    { path = "sessionEntry.eventTicketRefillCost", value = 0 },
                })
            end)
        if status ~= "applied" and status ~= "reverted" then
            LOG.warn("InstantTicketRefill", "toggle failed: " .. tostring(err))
        end
        finishTask(); cb(status)
    end)
end

return M
