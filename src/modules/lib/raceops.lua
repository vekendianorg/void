--[[
  modules/lib/raceops.lua - Guarded live-race helpers over Nebula currentRace

  Every feature in the Race tab goes through this file. It enforces the
  benchmark rules established on-device (Sept 2026):

    * scalar dotted-path reads only (2-20ms live) - never whole-object
      dumps (currentRace full dump is ~300-400ms, gameStatus is a 7s trap)
    * every write is gated on currentRace.raceInfoState being readable,
      so a write can never land into a stale/zeroed RaceInfo after the
      race has ended and the object has been torn down
    * every write chains :verify() - a failed read-back returns "failed"
      with the error string, instead of silently succeeding

  The UX contract handled by callers: when the guard fails with the
  "no_race" status, the tab tells the user to enter a race first, then
  activate the feature again.

  Globals used: Nebula, LOG.
]]

local TAG = "RaceOps"

local raceops = {}

-- Acceptable decoded states for a LIVE write. READY is the single-race
-- state observed live; CUP_READY / PENDING_CUP_UPDATE / WAITING_FOR_PARTICIPANTS
-- are the cup/multiplayer equivalents. UNINITIALIZED/FAILED mean the object
-- exists but a write would land into a half-built or broken race context.
local LIVE_STATES = {
    READY                  = true,
    CUP_READY              = true,
    PENDING_CUP_UPDATE     = true,
    WAITING_FOR_PARTICIPANTS = true,
}

-- Nebula guard: the SDK must be present and PlayerInfo resolvable.
-- Returns true when ops are possible at all, otherwise nil + reason.
function raceops.nebulaOk()
    if not (Nebula and Nebula.PlayerInfo) then
        return nil, "nebula_unavailable"
    end
    return true
end

-- Scalar read. Returns (value, err). Never reads whole objects.
function raceops.read(path)
    local ok, value, err = pcall(Nebula.PlayerInfo.get, path)
    if not ok then
        return nil, tostring(value)
    end
    if value == nil then
        return nil, tostring(err or "read_failed")
    end
    return value
end

-- Scalar write + read-back verify. Returns (true, value) or (nil, err).
function raceops.write(path, value)
    local ok, op = pcall(Nebula.PlayerInfo.set, path, value)
    if not ok or type(op) ~= "table" then
        return nil, tostring(op)
    end
    local vop = op:verify()
    if type(vop) == "table" and vop._verified == false then
        return nil, "verify_mismatch: " .. tostring(vop._actual)
    end
    return true, value
end

-- Read-modify-write add. Returns (new_value, err).
function raceops.add(path, delta)
    local current, err = raceops.read(path)
    if current == nil then
        return nil, err
    end
    if type(current) ~= "number" then
        return nil, "not_numeric: " .. tostring(current)
    end
    local nextv = current + (tonumber(delta) or 0)
    local ok, werr = raceops.write(path, nextv)
    if not ok then
        return nil, werr
    end
    return nextv
end

-- Race guard. Reads currentRace.raceInfoState (one scalar read).
-- Returns (state_name, nil) when a live race context exists, or
-- (nil, status) with status "nebula_unavailable" | "no_race".
function raceops.raceState()
    local ok = raceops.nebulaOk()
    if not ok then
        return nil, "nebula_unavailable"
    end

    local state, err = raceops.read("currentRace.raceInfoState")
    if state == nil then
        -- currentRace is null / unreadable outside a race session.
        LOG.info(TAG, "race guard rejected: " .. tostring(err))
        return nil, "no_race"
    end
    if type(state) ~= "string" then
        -- Enum decodes to a name; a raw id means unknown state - refuse writes.
        state = "STATE_" .. tostring(state)
    end
    return state, nil
end

-- Full guard for a write op: state must be one of LIVE_STATES.
-- Returns (state_name, nil) or (nil, status_for_tab).
function raceops.guardLive()
    local state, err = raceops.raceState()
    if state == nil then
        return nil, err
    end
    if not LIVE_STATES[state] then
        LOG.info(TAG, "guard: state " .. state .. " is not live, refusing write")
        return nil, "no_race"
    end
    return state, nil
end

return raceops
