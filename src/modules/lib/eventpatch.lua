--[[
  modules/lib/eventpatch.lua — Shared EventDefinition patch core (Team + Event tabs)

  Same role as raceinfo.lua: logic used by more than one ops module, so it
  lives in lib/ instead of being duplicated in ops/team.lua and ops/event.lua.

  TeamEvent and PublicEvent are both backed by the same EventDefinition
  struct through the vendored Nebula 1.0.1: each API auto-resolves and
  caches the currently-active event's base on first use. All writes go
  through :verify() read-back; a failed read-back is a failed patch.

  Status strings (ops contract: no UI calls here):
    "applied"            every write verified (switch ON)
    "reverted"           snapshot written back (switch OFF)
    "resolve_failed"     no active event / base resolution failed
    "failed"             a write or read-back failed
    "nebula_unavailable" Nebula missing
    "no_vehicles"        GameData vehicle list unavailable or empty

  Globals used: Nebula, LOG, storage.
]]

local EP = {}

-- "TeamEvent" | "PublicEvent"
local function api(kind)
    if not (Nebula and Nebula[kind] and Nebula.VERSION) then return nil end
    return Nebula[kind]
end

---Read one field off the active event. Returns value, err.
function EP.get(kind, path)
    local A = api(kind)
    if not A then return nil, "nebula_unavailable" end
    local ok, v, err = pcall(A.get, path)
    if not ok then return nil, "get_threw: " .. tostring(v) end
    return v, err
end

---Write one field with :verify() read-back. Returns true, nil | false, err.
function EP.set(kind, path, value)
    local A = api(kind)
    if not A then return false, "nebula_unavailable" end
    local ok, op = pcall(A.set, path, value)
    if not ok then return false, "set_threw: " .. tostring(op) end
    if type(op) ~= "table" or not op._ok then
        return false, (type(op) == "table" and op._err) or "set_failed"
    end
    local vok, vop = pcall(function() return op:verify() end)
    if vok and type(vop) == "table" and vop._verified == false then
        return false, "verify_mismatch: expected=" .. tostring(value)
            .. " actual=" .. tostring(vop._actual)
    end
    return true, nil
end

local function classify(err)
    local e = tostring(err)
    if e:find("nebula_unavailable", 1, true) then return "nebula_unavailable" end
    if e:find("no_active", 1, true) then return "resolve_failed" end
    return "failed"
end

---Apply a list of writes { { path = ..., value = ... }, ... } to the active
---event. Stops at the first failure. Returns status, err.
function EP.apply(kind, writes)
    for _, w in ipairs(writes) do
        local ok, err = EP.set(kind, w.path, w.value)
        if not ok then
            return classify(err), tostring(err)
        end
    end
    return "applied", nil
end

---Read the current values of `paths` off the active event, in list form
---({ { path = ..., value = ... }, ... }). Empty vectors read back as {}.
---Returns list, nil | nil, err.
function EP.snapshot(kind, paths)
    local out = {}
    for _, p in ipairs(paths) do
        local v, err = EP.get(kind, p)
        if err then return nil, err end
        out[#out + 1] = { path = p, value = v }
    end
    return out, nil
end

---Shared switch body for the EventDefinition patches. state=true captures the
---originals on first enable (session storage) then applies patchFn();
---state=false writes the snapshot back and clears it. Re-enabling with a
---stored snapshot skips the capture and just re-applies.
---Returns status, err: "applied" | "reverted" | EP.apply statuses.
function EP.toggle(kind, state, skey, paths, patchFn)
    if not state then
        local snap = storage:load_session(skey)
        if type(snap) ~= "table" then
            return "reverted", nil -- nothing captured this session: already stock
        end
        local status, err = EP.apply(kind, snap)
        if status == "applied" then
            storage:delete_session(skey)
            return "reverted", nil
        end
        return status, err
    end
    local snap = storage:load_session(skey)
    if type(snap) ~= "table" then
        local orig, oerr = EP.snapshot(kind, paths)
        if not orig then
            return classify(oerr), tostring(oerr)
        end
        storage:save_session(skey, orig)
    end
    return patchFn()
end

---Game vehicle ids from GameData.vehicles. GameData stores the vehicle
---json filenames (vehicle_hillclimber.json), so strip the prefix + suffix:
---vehicle_*.json -> *. Returns ids, nil | nil, err.
function EP.vehicleIds()
    if not (Nebula and Nebula.GameData and Nebula.VERSION) then
        return nil, "nebula_unavailable"
    end
    local ok, v, err = pcall(Nebula.GameData.get, "vehicles")
    if not ok then return nil, "get_threw: " .. tostring(v) end
    if type(v) ~= "table" then return nil, err or "read_failed" end
    local ids = {}
    for _, name in ipairs(v) do
        local id = tostring(name):match("^vehicle_(.-)%.json$")
        if id and id ~= "" then ids[#ids + 1] = id end
    end
    if #ids == 0 then return nil, "no_vehicles" end
    return ids, nil
end

return EP
