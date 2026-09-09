-- Packed by bundle.py  •  2026-09-06 10:13:03

-- Do not edit — regenerate with:  python bundle.py


local __vfs = {}

__vfs['test.lua'] = function(...)
local scriptDir = gg.getFile():match("(.*/)") or ""
local _moduleCache = {}

function nebulaLoadModule(name, soft)
    local path = scriptDir .. name
    if _moduleCache[path] ~= nil then
        return _moduleCache[path]
    end
    local chunk, err = loadfile(path)
    if not chunk then
        if soft then return nil, err end
        gg.alert("Module load failed: " .. name .. "\n" .. tostring(err))
        error("nebula: module load failed: " .. tostring(name))
    end
    if soft then
        local results = table.pack(pcall(chunk))
        if not results[1] then return nil, results[2] end
        _moduleCache[path] = table.unpack(results, 2, results.n)
        return _moduleCache[path]
    end
    _moduleCache[path] = chunk()
    return _moduleCache[path]
end

Nebula = Nebula or {}
Nebula.log = true
Nebula.verbose = false
Nebula.GameStatus = nebulaLoadModule("api/GameStatus.lua")
Nebula.PublicEvent = nebulaLoadModule("api/PublicEvent.lua")
Nebula.TeamEvent  = nebulaLoadModule("api/TeamEvent.lua")
Nebula.CommunityEvent = nebulaLoadModule("api/CommunityEvent.lua")
Nebula.Type   = nebulaLoadModule("core/Type.lua")
Nebula.Memory = nebulaLoadModule("core/Memory.lua")
Nebula.Cache   = nebulaLoadModule("core/Cache.lua")
Nebula.VERSION = "0.1.0"

local function log(msg)
    print(msg)
end

--------------------------------------------------------------------------
-- Timing helper
--------------------------------------------------------------------------
-- os.clock() returns CPU seconds (fractional); os.time() is whole seconds.
-- Prefer os.clock for per-field resolution, fall back if unavailable.
local function now()
    if os.clock then return os.clock() end
    return os.time()
end

local t0 = os.time()

--------------------------------------------------------------------------
-- Value preview
--------------------------------------------------------------------------
-- Render a fetched value compactly for the log: scalars inline,
-- tables as {key=value, ...} with full nesting depth. Arrays are the
-- exception — only the first few elements are shown, with the total
-- count in the tail (event arrays can hold hundreds of structs).
local MAX_DEPTH = 6
local ARRAY_SHOW = 3   -- array elements shown before the "..." tail
local MAP_SHOW = 8     -- max map keys shown per level

local function preview(v, depth)
    depth = depth or 0
    local t = type(v)
    if t == "string" then
        if #v > 48 then return ("%q..."):format(v:sub(1, 45)) end
        return ('"%s"'):format(v)
    end
    if t == "boolean" or t == "number" then return tostring(v) end
    if t ~= "table" then return ("<" .. t .. ">") end

    if depth >= MAX_DEPTH then return "{...}" end

    -- Count entries and detect array-vs-map shape
    local n, maxI = 0, 0
    for _ in pairs(v) do n = n + 1 end
    for i in pairs(v) do
        if type(i) == "number" and i > maxI then maxI = i end
    end

    if n == 0 then return "{}" end

    local isArray = maxI == n

    if isArray then
        local show = math.min(n, ARRAY_SHOW)
        local parts = {}
        for i = 1, show do
            parts[#parts + 1] = preview(v[i], depth + 1)
        end
        if n > show then
            parts[#parts + 1] = ("... n=%d"):format(n)
        end
        return "[" .. table.concat(parts, ", ") .. "]"
    end

    local parts, count = {}, 0
    for k, e in pairs(v) do
        count = count + 1
        if count > MAP_SHOW then
            parts[#parts + 1] = ("...(+%d more)"):format(n - MAP_SHOW)
            break
        end
        local key
        if type(k) == "string" and k:match("^[%a_][%w_]*$") then
            key = k .. "="
        else
            key = ("[%s]="):format(tostring(k))
        end
        parts[#parts + 1] = key .. preview(e, depth + 1)
    end
    return "{" .. table.concat(parts, ", ") .. "}"
end

--------------------------------------------------------------------------
-- Modules under test
--------------------------------------------------------------------------
local MODULES = {
    { name = "GameStatus",    mod = Nebula.GameStatus },
    { name = "PublicEvent",   mod = Nebula.PublicEvent },
    { name = "TeamEvent",     mod = Nebula.TeamEvent },
    { name = "CommunityEvent", mod = Nebula.CommunityEvent },
}

--------------------------------------------------------------------------
-- Per-module benchmark: enumerate every field, time each get()
--
-- Two passes per module:
--   COLD  - first read of each field (includes any pointer chasing,
--           gg memory reads, string decoding)
--   WARM  - second read (base addresses / repeated fields are cached
--           by core/Cache.lua, so this isolates raw read cost)
--------------------------------------------------------------------------
local function benchModule(name, mod)
    log("")
    log(("=== %s ==="):format(name))

    local ids = mod.fields()
    if not ids or #ids == 0 then
        log("  (no fields returned by fields())")
        return nil
    end
    log(("  fields: %d"):format(#ids))

    -- Resolve the base once up front and time it, so the first field
    -- read isn't polluted by resolve cost. If resolution fails (e.g.
    -- no event struct currently active in memory), SKIP this module's
    -- field passes entirely — otherwise every get() would trigger
    -- another full-memory scan.
    local baseMs, baseOk, baseErr
    if mod.resolveBase then
        local t = now()
        local okB, addrOrErr = pcall(mod.resolveBase)
        baseMs = (now() - t) * 1000
        baseOk = okB and addrOrErr ~= nil
        if not baseOk then
            baseErr = okB and "base_not_found" or tostring(addrOrErr)
        end
        log(("  resolveBase: %s (%.3f ms)%s"):format(
            baseOk and "ok" or ("FAILED: " .. tostring(baseErr)), baseMs,
            baseOk and "" or "  -- skipping field passes"))
    end

    if mod.resolveBase and not baseOk then
        return { name = name, n = #ids, skipped = true, err = baseErr }
    end

    local function pass(label)
        local rows = {}
        local total, okCount, failCount = 0, 0, 0
        for i, id in ipairs(ids) do
            local t = now()
            local ok, v = pcall(mod.get, id)
            local ms = (now() - t) * 1000
            total = total + ms
            if ok then okCount = okCount + 1 else failCount = failCount + 1 end
            rows[i] = {
                id = id, ms = ms, ok = ok,
                val = ok and v or nil,
                err = ok and nil or tostring(v),
            }
        end
        return rows, total, okCount, failCount
    end

    local coldRows, coldTotal, coldOk, coldFail = pass("cold")
    local warmRows, warmTotal, warmOk, warmFail = pass("warm")

    -- Per-field detail: id, cold/warm timing, and the fetched value
    -- rendered compactly (scalars inline, tables as {k=v, ...} with
    -- depth/width limits so huge arrays stay readable).
    for i, id in ipairs(ids) do
        local c, w = coldRows[i], warmRows[i]
        if c.ok then
            log(("    %-55s cold %8.3f  warm %8.3f ms  = %s")
                :format(id, c.ms, w.ms, preview(c.val)))
        else
            log(("    %-55s cold %8.3f  warm %8.3f ms  ERR: %s")
                :format(id, c.ms, w.ms, tostring(c.err):sub(1, 60)))
        end
    end

    -- Summary stats
    local coldMin, coldMax, coldMaxId = math.huge, 0, "-"
    for _, r in ipairs(coldRows) do
        if r.ms < coldMin then coldMin = r.ms end
        if r.ms > coldMax then coldMax, coldMaxId = r.ms, r.id end
    end

    log(("  COLD: total %.3f ms  avg %.3f ms  min %.3f ms  max %.3f ms (%s)  ok %d  fail %d")
        :format(coldTotal, coldTotal / #ids, coldMin, coldMax, coldMaxId, coldOk, coldFail))
    log(("  WARM: total %.3f ms  avg %.3f ms  (base + repeated fields cached)")
        :format(warmTotal, warmTotal / #ids))
    if coldTotal > 0 then
        log(("  cache effect: %.1fx faster on warm reads")
            :format(coldTotal / math.max(warmTotal, 1e-9)))
    end

    return {
        name = name, n = #ids, baseMs = baseMs,
        coldTotal = coldTotal, coldAvg = coldTotal / #ids,
        coldMax = coldMax, coldMaxId = coldMaxId,
        warmTotal = warmTotal, warmAvg = warmTotal / #ids,
        coldRows = coldRows,
    }
end

--------------------------------------------------------------------------
-- Run all modules
--------------------------------------------------------------------------
local results = {}
for _, m in ipairs(MODULES) do
    results[#results + 1] = benchModule(m.name, m.mod)
end

--------------------------------------------------------------------------
-- Overall report
--------------------------------------------------------------------------
log("")
log("=== OVERALL ===")
local allCold, allWarm, allFields = 0, 0, 0
for _, r in ipairs(results) do
    if r then
        if r.skipped then
            log(("  %-15s SKIPPED — base not resolved (%s)")
                :format(r.name, tostring(r.err)))
        else
            allCold = allCold + r.coldTotal
            allWarm = allWarm + r.warmTotal
            allFields = allFields + r.n
            log(("  %-15s %3d fields  cold %9.3f ms (avg %.3f)  warm %9.3f ms (avg %.3f)")
                :format(r.name, r.n, r.coldTotal, r.coldAvg, r.warmTotal, r.warmAvg))
        end
    end
end
log(("  TOTAL: %d fields  cold %.3f ms  warm %.3f ms")
    :format(allFields, allCold, allWarm))

-- Slowest fields across all modules (cold pass)
local slow = {}
for _, r in ipairs(results) do
    if r and not r.skipped then
        for _, row in ipairs(r.coldRows) do
            slow[#slow + 1] = { mod = r.name, id = row.id, ms = row.ms, ok = row.ok }
        end
    end
end
table.sort(slow, function(a, b) return a.ms > b.ms end)
log("")
log("=== SLOWEST 15 FIELDS (cold pass) ===")
for i = 1, math.min(15, #slow) do
    local s = slow[i]
    log(("  %-15s %-55s %9.3f ms%s"):format(
        s.mod, s.id, s.ms, s.ok and "" or "  (error)"))
end

log("")
log(("done in %d s wall time"):format(os.time() - t0))

end

__vfs['api/CommunityEvent.lua'] = function(...)
--==================================================
-- api/CommunityEvent.lua
--==================================================
-- Public-facing Nebula.CommunityEvent module.
--
-- CommunityShowcase (社区赛道) is a distinct event type from
-- PublicEvent and TeamEvent — simpler struct, no reward/loot
-- fields, and resolved via string search instead of AOB.
--
-- Base resolution uses a string-search method: search for the ASCII
-- bytes of "community Showcase\0", validate with a vtable marker
-- (0x6D6F631E at hit-0x18), then extract the struct pointer at
-- hit-0x20. See core/Memory.lua's resolveActiveCommunityEventBase()
-- for the full flow.
--
--   Nebula.CommunityEvent.get("startTime")
--   Nebula.CommunityEvent.get("sessionEntry.entryFeeTickets")
--   Nebula.CommunityEvent.get("minRankToJoin")
--
--   local event = Nebula.CommunityEvent.get()
--   event.get("name")
--   event.get("sessionEntry.maxEventTickets")
--
--   Nebula.CommunityEvent.set("startTime", 1700000000)
--   Nebula.CommunityEvent.set("startTime", 1700000000):dry()

local Memory   = nebulaLoadModule("core/Memory.lua")
local Type     = nebulaLoadModule("core/Type.lua")
local Repeated = nebulaLoadModule("core/Repeated.lua")
local Path     = nebulaLoadModule("core/Path.lua")
local Struct   = nebulaLoadModule("core/Struct.lua")
local metadata = nebulaLoadModule("metadata/CommunityEvent.lua")

local M = {}

M.metadata = metadata

-- Cached per script session.
local baseAddress = nil

--==================================================
-- Base address resolution
--==================================================

local function log(...)
    if Nebula ~= nil and Nebula.log then
        print("[Nebula.CommunityEvent]", ...)
    end
end

-- When no event struct is currently active, resolution fails. Cache
-- the failure with a cooldown so repeated get() calls don't re-run
-- the expensive full-memory scan every time; resolveBase(true) forces
-- an immediate rescan.
local FAIL_RETRY_SECONDS = 5
local lastFailErr = nil
local lastFailClock = nil

local function nowSec()
    if os.clock then return os.clock() end
    return os.time()
end

---@param forceRescan boolean|nil
---@return integer|nil address, string|nil error
local function resolveBase(forceRescan)
    if baseAddress ~= nil and not forceRescan then
        return baseAddress
    end

    if lastFailErr ~= nil and not forceRescan
        and (nowSec() - lastFailClock) < FAIL_RETRY_SECONDS then
        return nil, lastFailErr
    end

    local address, err = Memory.resolveActiveCommunityEventBase()
    if not address then
        lastFailErr = err or "base_not_found"
        lastFailClock = nowSec()
        log("resolveBase failed:", lastFailErr)
        return nil, lastFailErr
    end

    baseAddress = address
    lastFailErr, lastFailClock = nil, nil
    return baseAddress
end

M.resolveBase = resolveBase

--==================================================
-- Field lookup helpers
--==================================================

---A field is a leaf (readable) entry iff its own `type` is a
---string. Pure namespace containers (sessionEntry, gameMode) have
---no `type` of their own — only typed children.
---@param node any
---@return boolean
local function isLeafField(node)
    return type(node) == "table" and type(node.type) == "string"
end

local function isOffsetKnown(field)
    return field.offset ~= nil and field.offset ~= 0xBAAD
end

local function shadowStringDirect(field)
    if field.type == "String" and field.indirect == nil then
        return setmetatable({ indirect = false }, { __index = field })
    end
    return field
end

local function shadowStringDirectArray(field)
    if field.stringDirect == nil then
        return setmetatable({ stringDirect = true, container = "vector" }, { __index = field })
    end
    return field
end

---@param id string @ dotted field id, e.g. "sessionEntry.entryFeeTickets"
---@return table|nil field, string|nil error
local function resolvePath(id)
    local segments = Path.parse(id)
    if #segments == 0 then
        return nil, "empty_path"
    end

    local base, baseErr = resolveBase()
    if not base then
        return nil, baseErr
    end

    local currentBase = base
    local currentMeta = metadata
    local finalField = nil

    for i, seg in ipairs(segments) do
        local node = currentMeta[seg.name]
        if node == nil then
            return nil, "unknown_field: " .. tostring(id)
        end

        if seg.index ~= nil then
            if node.type ~= "Array" then
                return nil, "not_an_array: " .. seg.name
            end
            if not isOffsetKnown(node) then
                return nil, "offset_unknown: " .. seg.name
            end
            local arr, arrErr = Repeated.get(currentBase, shadowStringDirectArray(node))
            if not arr then
                return nil, arrErr
            end
            local luaIdx = seg.index
            if luaIdx < 1 or luaIdx > #arr then
                return nil, string.format("index_out_of_bounds: %s[%d] (size=%d)", seg.name, seg.index, #arr)
            end
            if i == #segments then
                local elemStride = node.elementStride or 0x8
                local header, _ = Repeated.readHeaderForSet(currentBase, node)
                local writeAddr = nil
                if header and header.arrayPtr and header.arrayPtr ~= 0 then
                    if elemStride > 0x8 then
                        writeAddr = header.arrayPtr + (seg.index - 1) * elemStride
                    else
                        local slots, _ = Memory.readBatchChunked({
                            { address = header.arrayPtr + (seg.index - 1) * 0x8, flags = Memory.FLAGS.INT64 }
                        })
                        if slots and slots[1] and slots[1].value ~= 0 then
                            writeAddr = slots[1].value
                        end
                    end
                end
                return { value = arr[luaIdx], resolved = true, writeAddr = writeAddr, elementType = node.elementType }
            end
            if node.elements then
                local stride = node.elementStride or 0x8
                if stride > 0x8 then
                    local header, hErr = Repeated.readHeaderForSet(currentBase, node)
                    if not header then return nil, hErr end
                    currentBase = header.arrayPtr + (seg.index - 1) * stride
                else
                    local h, he = Repeated.readHeaderForSet(currentBase, node)
                    if not h then return nil, he end
                    local slots, sErr = Memory.readBatchChunked({
                        { address = h.arrayPtr + (seg.index - 1) * 0x8, flags = Memory.FLAGS.INT64 }
                    })
                    if not slots or not slots[1] or slots[1].value == 0 then
                        return nil, "null_element_ptr"
                    end
                    currentBase = slots[1].value
                end
                currentMeta = node.elements
            else
                return nil, "array_has_no_elements: " .. seg.name
            end
        elseif isLeafField(node) and i == #segments then
            finalField = node
            break
        elseif type(node) == "table" and not isLeafField(node) and i < #segments then
            currentMeta = node
        else
            return nil, "unknown_field: " .. tostring(id)
        end
    end

    if finalField then
        return { field = finalField, base = currentBase }
    end
    return nil, "unknown_field: " .. tostring(id)
end



---Same ABI fact as PublicEvent/TeamEvent — CommunityShowcase's
---strings are inlined into the struct (no pointer indirection).
---Does NOT mutate the shared metadata.
---@param field table
---@return table field

---Shadow an Array-with-elements field to add stringDirect=true.
---@param field table
---@return table field

---Shared by M.get(id) and the accessor object returned by M.get() with no id.
---@param base integer
---@param id string
---@return any|nil value, string|nil error
local function readFieldById(id)
    local result, err = resolvePath(id)
    if not result then
        log("get failed:", err)
        return nil, err
    end

    if result.resolved then
        return result.value
    end

    local field = result.field
    local base = result.base

    if field.type == "Object" then
        return nil, "unsupported_type: Object fields are not yet readable (missing nested metadata)"
    end

    if not isOffsetKnown(field) then
        return nil, "offset_unknown: " .. id
    end

    if field.type == "Array" then
        return Repeated.get(base, shadowStringDirectArray(field))
    end

    if field.repeated then
        return Repeated.get(base, field)
    end

    local impl = Type.resolve(field.type)
    if not impl then
        return nil, "no_type_impl: " .. tostring(field.type)
    end

    local value, valErr = impl.get(base, shadowStringDirect(field))
    if value == nil and valErr then
        log("get('" .. id .. "') failed:", valErr)
    end
    return value, valErr
end

---Shared by M.set(id, value) and SetOperation.
---@param base integer
---@param id string
---@param value any
---@return boolean ok, string|nil error
local function writeFieldById(id, value)
    local result, err = resolvePath(id)
    if not result then
        return false, err
    end

    if result.resolved then
        if not result.writeAddr then
            return false, "cannot_set_array_element_value_directly"
        end
        if op._dry then
            log(string.format("[dry] would set '%s' = %s", op.id, tostring(op.value)))
            return true, nil
        end
        local elemType = result.elementType
        if not elemType then
            return false, "unknown_element_type"
        end
        local impl = Type.resolve(elemType)
        if not impl then
            return false, "no_type_impl: " .. tostring(elemType)
        end
        local f = { offset = 0, type = elemType }
        if elemType == "String" then
            f.indirect = false
        end
        local ok = impl.set(result.writeAddr, f, op.value)
        if not ok then
            log("set('" .. op.id .. "') failed")
            return false, "write_failed"
        end
        log(string.format("set '%s' = %s", op.id, tostring(op.value)))
        return true, nil
    end

    local field = result.field
    local base = result.base

    if field.type == "Object" then
        return false, "unsupported_type: Object fields are not yet writable (missing nested metadata)"
    end

    if not isOffsetKnown(field) then
        return false, "offset_unknown: " .. id
    end

    if field.type == "Array" then
        return Repeated.set(base, shadowStringDirectArray(field), value)
    end

    if field.repeated then
        return Repeated.set(base, field, value)
    end

    local impl = Type.resolve(field.type)
    if not impl then
        return false, "no_type_impl: " .. tostring(field.type)
    end

    local ok = impl.set(base, shadowStringDirect(field), value)
    if not ok then
        return false, "write_failed"
    end
    return true, nil
end

--==================================================
-- get()
--==================================================
-- Called with a dotted id, reads that field immediately. Called
-- with no id, resolves the base immediately and returns an
-- accessor/context object with its own get(id) bound to that exact
-- snapshot — no separate :now() step required.

---@param id string|nil @ omit to get an event accessor bound to the currently-active struct
---@return any|nil value, string|nil error
function M.get(id)
    local base, baseErr = resolveBase()
    if not base then
        log("get failed, no base:", baseErr)
        return nil, baseErr
    end

    if id == nil then
        return {
            base = base,
            get = function(fieldId)
                return readFieldById(fieldId)
            end,
        }
    end

    return readFieldById(id)
end

--==================================================
-- set() — returns a chainable operation object supporting
-- :dry()
--==================================================

local SetOperation = {}
SetOperation.__index = SetOperation

local function performWrite(op)
    if op._dry then
        local result, dryErr = resolvePath(op.id)
        if not result then
            log("set failed:", dryErr)
            return false, dryErr
        end
        log(string.format("[dry] would set '%s' = %s", op.id, tostring(op.value)))
        return true, nil
    end

    local ok, err = writeFieldById(op.id, op.value)
    if not ok and err then
        log("set('" .. op.id .. "') failed:", err)
    end
    return ok, err
end

---Mark this operation as a dry run: validates everything (field
---exists, offset known) but never touches memory.
---Returns (ok, err).
function SetOperation:dry()
    self._dry = true
    return performWrite(self)
end

setmetatable(SetOperation, {
    __call = function(cls, id, value)
        local self = setmetatable({ id = id, value = value, _dry = false }, cls)
        local ok, err = performWrite(self)
        self._ok, self._err = ok, err
        return self
    end
})

---Write a field value to the currently-active CommunityEvent struct.
---@param id string @ dotted field id
---@param value any
---@return table operation @ chainable; already executed
function M.set(id, value)
    return SetOperation(id, value)
end

--==================================================
-- fields() / meta() — read-only introspection
--==================================================

---@param node table
---@param prefix string|nil
---@param results string[]
local function walkFields(node, prefix, results)
    for key, child in pairs(node) do
        if type(child) == "table" then
            local id = prefix and (prefix .. "." .. key) or key
            if isLeafField(child) then
                if isOffsetKnown(child) then
                    results[#results + 1] = id
                end
            else
                walkFields(child, id, results)
            end
        end
    end
end

---List every offset-verified field's dotted id.
---@return string[] ids
function M.fields()
    local results = {}
    walkFields(metadata, nil, results)
    table.sort(results)
    return results
end

---@param id string
---@return table|nil metaView, string|nil error
function M.meta(id)
    local result, err = resolvePath(id)
    local field = result and result.field
    if not field then
        return nil, err
    end

    local known = isOffsetKnown(field)
    return {
        type = field.type,
        offset = field.offset,
        known = known,
        repeated = field.repeated == true,
    }
end

return M

end

__vfs['api/GameStatus.lua'] = function(...)
--==================================================
-- api/GameStatus.lua
--==================================================
-- Public-facing Nebula.GameStatus module.
--
--   Nebula.GameStatus.get("coins")
--   Nebula.GameStatus.set("coins", 999)
--   Nebula.GameStatus.set("cheater", true):force()
--   Nebula.GameStatus.set("coins", 999):dry()
--   Nebula.GameStatus.has("device")
--   Nebula.GameStatus.add("coins", 1000)
--   Nebula.GameStatus.add("coins", 1000):dry()
--   Nebula.GameStatus.sub("coins", 500)
--   Nebula.GameStatus.meta("coins")
--   Nebula.GameStatus.fields()

local Memory   = nebulaLoadModule("core/Memory.lua")
local Type     = nebulaLoadModule("core/Type.lua")
local Repeated = nebulaLoadModule("core/Repeated.lua")
local Path     = nebulaLoadModule("core/Path.lua")
local Struct   = nebulaLoadModule("core/Struct.lua")
local metadata = nebulaLoadModule("metadata/GameStatus.lua")

local M = {}

-- Fields considered dangerous enough to require :force().
local DANGEROUS_FIELDS = {
    playerId = true,
    coins = true,
    gems = true,
    cheater = true,
}

-- Cached per script session — resolveGameStatusBase() is an
-- expensive signature scan, only run it once unless forced.
local baseAddress = nil

-- Cache for enum module loads. nebulaLoadModule() re-reads and
-- re-executes the file from disk every call — with no cache, every
-- BitMask get/set/log line pays that cost again, which adds up
-- fast when scanning many fields in a loop.
local enumCache = {}

---@param enumName string|table
---@return table|nil
local function resolveEnum(enumName)
    if type(enumName) == "table" then
        return enumName
    end
    if enumCache[enumName] ~= nil then
        return enumCache[enumName]
    end
    local enum = nebulaLoadModule("metadata/enums/" .. enumName .. ".lua")
    enumCache[enumName] = enum
    return enum
end

--==================================================
-- Base address resolution
--==================================================

---Resolve and cache the GameStatus struct base address.
-- Cache failures with a cooldown too: if the GameStatus struct isn't
-- present (e.g. wrong process attached), repeated get() calls would
-- otherwise re-run the signature scan every time. resolveBase(true)
-- forces an immediate rescan.
local FAIL_RETRY_SECONDS = 5
local lastFailErr = nil
local lastFailClock = nil

local function nowSec()
    if os.clock then return os.clock() end
    return os.time()
end

---@param forceRescan boolean|nil
---@return integer|nil address, string|nil error
local function resolveBase(forceRescan)
    if baseAddress ~= nil and not forceRescan then
        return baseAddress
    end

    if lastFailErr ~= nil and not forceRescan
        and (nowSec() - lastFailClock) < FAIL_RETRY_SECONDS then
        return nil, lastFailErr
    end

    local addresses, err = Memory.resolveGameStatusBase()
    if not addresses or #addresses == 0 then
        lastFailErr = err or "base_not_found"
        lastFailClock = nowSec()
        return nil, lastFailErr
    end

    baseAddress = addresses[1]
    lastFailErr, lastFailClock = nil, nil
    return baseAddress
end

M.resolveBase = resolveBase

--==================================================
-- Field lookup helpers
--==================================================

local function log(...)
    if Nebula ~= nil and Nebula.log then
        print("[Nebula.GameStatus]", ...)
    end
end

local function isOffsetKnown(field)
    return field.offset ~= nil and field.offset ~= 0xBAAD
end

local function resolvePath(id)
    local segments = Path.parse(id)
    if #segments == 0 then
        log("[resolvePath] empty path")
        return nil, "empty_path"
    end

    local base, baseErr = resolveBase()
    if not base then
        log(string.format("[resolvePath] base resolution failed: %s", tostring(baseErr)))
        return nil, baseErr
    end
    log(string.format("[resolvePath] id='%s' base=0x%X segments=%d", id, base, #segments))

    local currentBase = base
    local currentMeta = metadata
    local finalField = nil

    for i, seg in ipairs(segments) do
        local node = currentMeta[seg.name]
        if node == nil then
            log(string.format("[resolvePath] seg[%d] '%s' not found in metadata", i, seg.name))
            return nil, "unknown_field: " .. tostring(id)
        end

        if seg.index ~= nil then
            log(string.format("[resolvePath] seg[%d] '%s[%d]' type=%s offset=0x%X base=0x%X", i, seg.name, seg.index, tostring(node.type), node.offset or 0, currentBase))
            if node.type ~= "Array" then
                return nil, "not_an_array: " .. seg.name
            end
            if not isOffsetKnown(node) then
                return nil, "offset_unknown: " .. seg.name
            end
            local arr, arrErr = Repeated.get(currentBase, node)
            if not arr then
                log(string.format("[resolvePath] Repeated.get failed for '%s': %s", seg.name, tostring(arrErr)))
                return nil, arrErr
            end
            log(string.format("[resolvePath] '%s' array size=%d", seg.name, #arr))
            local luaIdx = seg.index
            if luaIdx < 1 or luaIdx > #arr then
                return nil, string.format("index_out_of_bounds: %s[%d] (size=%d)", seg.name, seg.index, #arr)
            end
            if i == #segments then
                log(string.format("[resolvePath] returning resolved value for '%s[%d]'", seg.name, seg.index))
                local elemStride = node.elementStride or 0x8
                local header, _ = Repeated.readHeaderForSet(currentBase, node)
                local writeAddr = nil
                if header and header.arrayPtr and header.arrayPtr ~= 0 then
                    if elemStride > 0x8 then
                        writeAddr = header.arrayPtr + (seg.index - 1) * elemStride
                    else
                        local slots, _ = Memory.readBatchChunked({
                            { address = header.arrayPtr + (seg.index - 1) * 0x8, flags = Memory.FLAGS.INT64 }
                        })
                        if slots and slots[1] and slots[1].value ~= 0 then
                            writeAddr = slots[1].value
                        end
                    end
                end
                return { value = arr[luaIdx], resolved = true, writeAddr = writeAddr, elementType = node.elementType }
            end
            if node.elements then
                local stride = node.elementStride or 0x8
                if stride > 0x8 then
                    local header, hErr = Repeated.readHeaderForSet(currentBase, node)
                    if not header then return nil, hErr end
                    currentBase = header.arrayPtr + (seg.index - 1) * stride
                    log(string.format("[resolvePath] inline element base=0x%X (arrayPtr=0x%X + (%d-1)*0x%X)", currentBase, header.arrayPtr, seg.index, stride))
                else
                    local h, he = Repeated.readHeaderForSet(currentBase, node)
                    if not h then return nil, he end
                    local slotAddr = h.arrayPtr + (seg.index - 1) * 0x8
                    local slots, sErr = Memory.readBatchChunked({
                        { address = slotAddr, flags = Memory.FLAGS.INT64 }
                    })
                    if not slots or not slots[1] or slots[1].value == 0 then
                        log(string.format("[resolvePath] null element ptr at slotAddr=0x%X", slotAddr))
                        return nil, "null_element_ptr"
                    end
                    currentBase = slots[1].value
                    log(string.format("[resolvePath] ptr element base=0x%X (slotAddr=0x%X)", currentBase, slotAddr))
                end
                currentMeta = node.elements
            else
                return nil, "array_has_no_elements: " .. seg.name
            end
        elseif node.type == "Object" and i < #segments then
            log(string.format("[resolvePath] seg[%d] '%s' Object offset=0x%X base=0x%X", i, seg.name, node.offset, currentBase))
            if not isOffsetKnown(node) then
                return nil, "offset_unknown: " .. seg.name
            end
            local ptr = Memory.deref(currentBase, node.offset)
            if not ptr or ptr == 0 then
                log(string.format("[resolvePath] null pointer deref at base+0x%X=0x%X", node.offset, currentBase))
                return nil, "null_pointer: " .. seg.name
            end
            log(string.format("[resolvePath] Object deref ptr=0x%X", ptr))
            currentBase = ptr
            currentMeta = node
        elseif node.type == "Array" and i == #segments then
            log(string.format("[resolvePath] seg[%d] '%s' Array (final) offset=0x%X base=0x%X", i, seg.name, node.offset, currentBase))
            finalField = node
            break
        elseif type(node.type) == "string" and i == #segments then
            log(string.format("[resolvePath] seg[%d] '%s' type=%s (final) offset=0x%X base=0x%X", i, seg.name, node.type, node.offset, currentBase))
            finalField = node
            break
        elseif type(node) == "table" and node.type == nil and i < #segments then
            log(string.format("[resolvePath] seg[%d] '%s' namespace container", i, seg.name))
            currentMeta = node
        else
            log(string.format("[resolvePath] seg[%d] '%s' unhandled node type=%s", i, seg.name, tostring(node.type)))
            return nil, "unknown_field: " .. tostring(id)
        end
    end

    if finalField then
        log(string.format("[resolvePath] resolved field='%s' type=%s offset=0x%X base=0x%X", tostring(finalField.name or "?"), tostring(finalField.type), finalField.offset or 0, currentBase))
        return { field = finalField, base = currentBase }
    end
    log(string.format("[resolvePath] no final field found for '%s'", id))
    return nil, "unknown_field: " .. tostring(id)
end

---Produce a compact, human-readable description of a value for
---logging. Boxed types (like BitMask) dump their entire internal
---table via plain tostring(), which is noisy and useless in a log
---line — this gives each type a chance to describe itself sensibly.
---@param field table
---@param value any
---@return string
local function describeValue(field, value)
    if field.type == "Array" and type(value) == "table" then
        return string.format("[ %d element(s) ]", #value)
    end

    if field.type == "BitMask" and type(value) == "table" then
        local ok, hasMethod = pcall(function() return value.has end)
        if ok and hasMethod then
            local enum = resolveEnum(field.enum)
            local active = {}
            if enum then
                for name in pairs(enum) do
                    if value:has(name) then
                        active[#active + 1] = name
                    end
                end
                table.sort(active)
            end
            return string.format("{ %s }", table.concat(active, ", "))
        end
    end

    return tostring(value)
end

--==================================================
-- get()
--==================================================

---@param id string
---@return any|nil value, string|nil error
function M.get(id)
    log(string.format("[get] id='%s'", id))
    local result, err = resolvePath(id)
    if not result then
        log(string.format("[get] resolvePath failed: %s", tostring(err)))
        return nil, err
    end

    if result.resolved then
        log(string.format("[get] returning pre-resolved value for '%s'", id))
        return result.value
    end

    local field = result.field
    local base = result.base
    log(string.format("[get] field type=%s offset=0x%X base=0x%X", tostring(field.type), field.offset or 0, base))

    if field.type == "Object" then
        local hasChildren = false
        for _, v in pairs(field) do
            if type(v) == "table" and type(v.offset) == "number" then
                hasChildren = true
                break
            end
        end
        if hasChildren and isOffsetKnown(field) then
            local ptr = Memory.deref(base, field.offset)
            if not ptr or ptr == 0 then
                return nil
            end
            return Struct.get(ptr, field, false)
        end
        return nil, "unsupported_type: Object fields are not yet readable (missing nested metadata)"
    end

    if not isOffsetKnown(field) then
        return nil, "offset_unknown: " .. id
    end

    if field.type == "Array" then
        local values, arrErr = Repeated.get(base, field)
        if values == nil and arrErr then
            log("get('" .. id .. "') failed:", arrErr)
        end
        return values, arrErr
    end

    local impl = Type.resolve(field.type)
    if not impl then
        return nil, "no_type_impl: " .. tostring(field.type)
    end

    local value, valErr = impl.get(base, field)
    if value == nil and valErr then
        log("get('" .. id .. "') failed:", valErr)
    end
    return value, valErr
end

--==================================================
-- set() — returns a chainable operation object supporting
-- :force() and :dry()
--==================================================

local SetOperation = {}
SetOperation.__index = SetOperation

local function performWrite(op)
    log(string.format("[set] id='%s' value=%s", op.id, tostring(op.value)))
    local result, err = resolvePath(op.id)
    if not result then
        log(string.format("[set] resolvePath failed: %s", tostring(err)))
        return false, err
    end

    if result.resolved then
        if not result.writeAddr then
            log("[set] cannot set array element value directly (no write address)")
            return false, "cannot_set_array_element_value_directly"
        end
        if op._dry then
            log(string.format("[dry] would set '%s' = %s", op.id, tostring(op.value)))
            return true, nil
        end
        local elemType = result.elementType
        if not elemType then
            return false, "unknown_element_type"
        end
        local impl = Type.resolve(elemType)
        if not impl then
            return false, "no_type_impl: " .. tostring(elemType)
        end
        local f = { offset = 0, type = elemType }
        if elemType == "String" then
            f.indirect = false
        end
        local ok = impl.set(result.writeAddr, f, op.value)
        if not ok then
            log("set('" .. op.id .. "') failed")
            return false, "write_failed"
        end
        log(string.format("set '%s' = %s", op.id, tostring(op.value)))
        return true, nil
    end

    local field = result.field
    local base = result.base
    log(string.format("[set] field type=%s offset=0x%X base=0x%X", tostring(field.type), field.offset or 0, base))

    if field.type == "Object" then
        local hasChildren = false
        for _, v in pairs(field) do
            if type(v) == "table" and type(v.offset) == "number" then
                hasChildren = true
                break
            end
        end
        if hasChildren and isOffsetKnown(field) then
            if op._dry then
                log(string.format("[dry] would set '%s' = %s", op.id, describeValue(field, op.value)))
                return true, nil
            end
            local ptr = Memory.deref(base, field.offset)
            if not ptr or ptr == 0 then
                return false, "null_pointer"
            end
            local ok = Struct.set(ptr, field, op.value, false)
            if not ok then
                log("set('" .. op.id .. "') failed")
                return false, "write_failed"
            end
            log(string.format("set '%s' = %s", op.id, describeValue(field, op.value)))
            return true, nil
        end
        return false, "unsupported_type: Object fields are not yet writable (missing nested metadata)"
    end

    if not isOffsetKnown(field) then
        return false, "offset_unknown: " .. op.id
    end

    if DANGEROUS_FIELDS[op.id] and not op._forced then
        return false, "dangerous_field_requires_force: " .. op.id
    end

    if op._dry then
        log(string.format("[dry] would set '%s' = %s", op.id, describeValue(field, op.value)))
        return true, nil
    end

    if field.type == "Array" then
        local ok, setErr = Repeated.set(base, field, op.value)
        if not ok then
            log("set('" .. op.id .. "') failed:", setErr)
            return false, setErr or "write_failed"
        end
        log(string.format("set '%s' = %s", op.id, describeValue(field, op.value)))
        return true, nil
    end

    local impl = Type.resolve(field.type)
    if not impl then
        return false, "no_type_impl: " .. tostring(field.type)
    end

    local ok = impl.set(base, field, op.value)
    if not ok then
        log("set('" .. op.id .. "') failed")
        return false, "write_failed"
    end

    log(string.format("set '%s' = %s", op.id, describeValue(field, op.value)))
    return true, nil
end

---Mark this operation as forced, bypassing the dangerous-field guard,
---then execute it. Returns (ok, err).
function SetOperation:force()
    self._forced = true
    return performWrite(self)
end

---Mark this operation as a dry run: validates everything (field
---exists, offset known, force requirement) but never touches memory.
---Returns (ok, err).
function SetOperation:dry()
    self._dry = true
    return performWrite(self)
end

-- Calling set() executes immediately (no modifier required), while
-- still returning the chainable object so :force()/:dry() remain
-- usable for staged/conditional execution.
setmetatable(SetOperation, {
    __call = function(cls, id, value)
        local self = setmetatable({ id = id, value = value, _forced = false, _dry = false }, cls)
        local ok, err = performWrite(self)
        self._ok, self._err = ok, err
        return self
    end
})

---@param id string
---@param value any
---@return table operation @ chainable; already executed unless dangerous-field guard blocked it
function M.set(id, value)
    return SetOperation(id, value)
end

--==================================================
-- add() / sub() — numeric read-modify-write shortcuts
--==================================================
-- Nebula.GameStatus.add("coins", 1000)  ==  set("coins", get("coins") + 1000)
-- Nebula.GameStatus.sub("coins", 500)   ==  set("coins", get("coins") - 500)
--
-- Only meaningful for numeric field types (Int32, Float,
-- SafeInt32) — String, Bool, BitMask, Array, Object, and repeated
-- fields don't have a sensible "add" operation and are rejected
-- with unsupported_operation rather than silently coercing.
--
-- Both go through the exact same SetOperation as set() (internally
-- they just compute the new value and call M.set()), so :force()
-- and :dry() work identically: Nebula.GameStatus.add("coins", 1000):dry().

local NUMERIC_TYPES = {
    Int32     = true,
    Float     = true,
    SafeInt32 = true,
}

---@param id string
---@param delta number
---@param negate boolean
---@return table operation @ chainable, same shape as set()'s return
local function performArithmetic(id, delta, negate)
    local result, fieldErr = resolvePath(id)
    local field = result and result.field
    if not field then
        log("add/sub failed:", fieldErr)
        local self = setmetatable({ id = id, value = nil, _forced = false, _dry = false }, SetOperation)
        self._ok, self._err = false, fieldErr
        return self
    end

    if not NUMERIC_TYPES[field.type] then
        log("add/sub failed: unsupported_operation for type " .. tostring(field.type))
        local self = setmetatable({ id = id, value = nil, _forced = false, _dry = false }, SetOperation)
        self._ok, self._err = false, "unsupported_operation: add/sub not valid for type " .. tostring(field.type)
        return self
    end

    local current, getErr = M.get(id)
    if current == nil then
        log("add/sub failed, get() failed:", getErr)
        local self = setmetatable({ id = id, value = nil, _forced = false, _dry = false }, SetOperation)
        self._ok, self._err = false, getErr or "read_failed"
        return self
    end

    local newValue = negate and (current - delta) or (current + delta)
    return SetOperation(id, newValue)
end

---@param id string
---@param delta number
---@return table operation
function M.add(id, delta)
    return performArithmetic(id, delta, false)
end

---@param id string
---@param delta number
---@return table operation
function M.sub(id, delta)
    return performArithmetic(id, delta, true)
end

--==================================================
-- has() — cheap existence check, no full decode
--==================================================
-- For pointer-backed fields (String, SafeInt32, message/repeated
-- types), "exists" means the pointer at base+offset is non-null —
-- this is a single Memory.deref(), far cheaper than a full get()
-- when all you need to know is whether something's there.
--
-- Plain inline scalars (Int32, Bool, Float, BitMask) have no null
-- state — they always "exist" once GameStatus itself is resolved —
-- so has() for those just reflects whether the offset is known.
--
-- Note: this is field-level existence, distinct from BitMask's own
-- boxed-value :has(flagName), which checks bit membership on an
-- already-read value. Nebula.GameStatus.has("flags") asks "is the
-- flags field itself present"; flags:has("IsPitCrew") asks "is
-- this specific bit set" — different questions, kept separate.

local POINTER_BACKED_TYPES = {
    String      = true,
    SafeInt32   = true,
}

---@param field table
---@return boolean
local function isPointerBackedType(field)
    if field.type == "Array" then
        return true -- array fields are always pointer-backed containers
    end
    if POINTER_BACKED_TYPES[field.type] then
        return true
    end
    -- Anything not a known inline scalar is assumed to be a
    -- pointer-backed message/custom type.
    local INLINE_SCALARS = { Int32 = true, Bool = true, Float = true, BitMask = true, Enum = true }
    return not INLINE_SCALARS[field.type]
end

---@param id string
---@return boolean|nil exists, string|nil error
function M.has(id)
    local result, fieldErr = resolvePath(id)
    local field = result and result.field
    if not field then
        log("has failed:", fieldErr)
        return nil, fieldErr
    end

    if field.type == "Object" then
        return nil, "unsupported_type: Object fields are not yet checkable (missing nested metadata)"
    end

    if not isOffsetKnown(field) then
        return nil, "offset_unknown: " .. id
    end

    if not isPointerBackedType(field) then
        -- No null state for inline scalars — known offset means it exists.
        return true, nil
    end

    local base, baseErr = resolveBase()
    if not base then
        log("has failed, no base:", baseErr)
        return nil, baseErr
    end

    local ptr = Memory.read(base + field.offset, Memory.FLAGS.POINTER)
    return ptr ~= nil and ptr ~= 0, nil
end

--==================================================
-- fields() — read-only introspection
--==================================================

---List every offset-verified field's id. Fields still at the
---0xBAAD placeholder are excluded.
---@return string[] ids
function M.fields()
    local results = {}
    for key, field in pairs(metadata) do
        if type(field) == "table" and type(field.type) == "string" and isOffsetKnown(field) then
            results[#results + 1] = key
        end
    end
    table.sort(results)
    return results
end

--==================================================
-- meta() — read-only introspection
--==================================================

local MetaView = {}
MetaView.__index = MetaView

---For BitMask fields, read the live value and decode it into a
---plain { FlagName = true/false, ... } table, so introspection
---shows readable flag states instead of a raw bitmask type name.
---Returns nil if the field isn't a readable BitMask right now
---(offset unknown, base unresolved, or read failed).
---@param base integer|nil
---@param field table
---@return table|nil flags
local function decodeBitMaskFlags(base, field)
    if field.type ~= "BitMask" or base == nil or not isOffsetKnown(field) then
        return nil
    end

    local impl = Type.resolve("BitMask")
    if not impl then
        return nil
    end

    local ok, boxed = pcall(impl.get, base, field)
    if not ok or boxed == nil then
        return nil
    end

    local enum = resolveEnum(field.enum)
    if not enum then
        return nil
    end

    local decoded = {}
    for name in pairs(enum) do
        decoded[name] = boxed:has(name)
    end

    return decoded
end

---@param id string
---@return table|nil metaView, string|nil error
function M.meta(id)
    local result, err = resolvePath(id)
    local field = result and result.field
    if not field then
        return nil, err
    end

    local view = setmetatable({
        name       = id,
        type       = field.type,
        offset     = field.offset,
        repeated   = field.type == "Array" or false,
        risk       = DANGEROUS_FIELDS[id] and "high" or "low",
        known      = isOffsetKnown(field),
    }, MetaView)

    if baseAddress ~= nil and isOffsetKnown(field) then
        view.address = baseAddress + field.offset
    else
        view.address = nil
    end

    if field.type == "BitMask" then
        view.flags = decodeBitMaskFlags(baseAddress, field)
    end

    return view
end

return M

end

__vfs['api/PublicEvent.lua'] = function(...)
--==================================================
-- api/PublicEvent.lua
--==================================================
-- Public-facing Nebula.PublicEvent module.
--
-- The field schema and offsets are defined by metadata/PublicEvent.lua
-- (the canonical source — see that file for what TeamEvent mirrors
-- from it, and for the offset conventions this module relies on).
-- Base resolution here picks out whichever PublicEvent struct is
-- currently active. See core/Memory.lua for the
-- byte-signature scan.
--
--   Nebula.PublicEvent.get("startTime")
--   Nebula.PublicEvent.get("gameMode.duration")
--   Nebula.PublicEvent.get("eventRewards")
--
--   local event = Nebula.PublicEvent.get()
--   event.get("minTeamSizeToJoin")
--   event.get("sessionEntry.numberOfParallelSessions")
--
--   Nebula.PublicEvent.set("eventRewards", {
--       [1] = { rewardCondition = { criteria = 0 },
--               maxCollectAmount = -1 }
--   })
--   Nebula.PublicEvent.set("startTime", 1700000000)
--   Nebula.PublicEvent.set("startTime", 1700000000):dry()
--
-- get() with no id resolves the currently-active struct's base
-- address immediately and returns an object bound to that exact
-- snapshot — so a sequence of event.get(...) calls stays consistent
-- even if a different event becomes "current" in between. No
-- separate :now() step is needed.

local Memory   = nebulaLoadModule("core/Memory.lua")
local Type     = nebulaLoadModule("core/Type.lua")
local Repeated = nebulaLoadModule("core/Repeated.lua")
local Path     = nebulaLoadModule("core/Path.lua")
local Struct   = nebulaLoadModule("core/Struct.lua")
local metadata = nebulaLoadModule("metadata/PublicEvent.lua")

local M = {}

M.metadata = metadata

-- Cached per script session.
local baseAddress = nil

--==================================================
-- Base address resolution
--==================================================

local function log(...)
    if Nebula ~= nil and Nebula.log then
        print("[Nebula.PublicEvent]", ...)
    end
end

-- When no event struct is currently active, resolution fails. Cache
-- the failure with a cooldown so repeated get() calls don't re-run
-- the expensive full-memory scan every time; resolveBase(true) forces
-- an immediate rescan.
local FAIL_RETRY_SECONDS = 5
local lastFailErr = nil
local lastFailClock = nil

local function nowSec()
    if os.clock then return os.clock() end
    return os.time()
end

---@param forceRescan boolean|nil
---@return integer|nil address, string|nil error
local function resolveBase(forceRescan)
    if baseAddress ~= nil and not forceRescan then
        return baseAddress
    end

    if lastFailErr ~= nil and not forceRescan
        and (nowSec() - lastFailClock) < FAIL_RETRY_SECONDS then
        return nil, lastFailErr
    end

    local address, err = Memory.resolveActivePublicEventBase()
    if not address then
        lastFailErr = err or "base_not_found"
        lastFailClock = nowSec()
        log("resolveBase failed:", lastFailErr)
        return nil, lastFailErr
    end

    baseAddress = address
    lastFailErr, lastFailClock = nil, nil
    return baseAddress
end

M.resolveBase = resolveBase

--==================================================
-- Field lookup helpers
--==================================================

---A field is a leaf (readable) entry iff its own `type` is a
---string ("Int32", "String", "Array", "Object", ...). Pure
---namespace containers (sessionEntry, gameMode, gameMode.levelPool)
---have no `type` of their own — only typed children — so they fail
---this check and get walked into instead of returned directly.
---@param node any
---@return boolean
local function isLeafField(node)
    return type(node) == "table" and type(node.type) == "string"
end

local function isOffsetKnown(field)
    return field.offset ~= nil and field.offset ~= 0xBAAD
end

local function shadowStringDirect(field)
    if field.type == "String" and field.indirect == nil then
        return setmetatable({ indirect = false }, { __index = field })
    end
    return field
end

local function shadowStringDirectArray(field)
    if field.stringDirect == nil then
        return setmetatable({ stringDirect = true, container = "vector" }, { __index = field })
    end
    return field
end

---@param id string @ dotted field id, e.g. "gameMode.duration"
---@return table|nil field, string|nil error
local function resolvePath(id)
    local segments = Path.parse(id)
    if #segments == 0 then
        return nil, "empty_path"
    end

    local base, baseErr = resolveBase()
    if not base then
        return nil, baseErr
    end

    local currentBase = base
    local currentMeta = metadata
    local finalField = nil

    for i, seg in ipairs(segments) do
        local node = currentMeta[seg.name]
        if node == nil then
            return nil, "unknown_field: " .. tostring(id)
        end

        if seg.index ~= nil then
            if node.type ~= "Array" then
                return nil, "not_an_array: " .. seg.name
            end
            if not isOffsetKnown(node) then
                return nil, "offset_unknown: " .. seg.name
            end
            local arr, arrErr = Repeated.get(currentBase, shadowStringDirectArray(node))
            if not arr then
                return nil, arrErr
            end
            local luaIdx = seg.index
            if luaIdx < 1 or luaIdx > #arr then
                return nil, string.format("index_out_of_bounds: %s[%d] (size=%d)", seg.name, seg.index, #arr)
            end
            if i == #segments then
                local elemStride = node.elementStride or 0x8
                local header, _ = Repeated.readHeaderForSet(currentBase, node)
                local writeAddr = nil
                if header and header.arrayPtr and header.arrayPtr ~= 0 then
                    if elemStride > 0x8 then
                        writeAddr = header.arrayPtr + (seg.index - 1) * elemStride
                    else
                        local slots, _ = Memory.readBatchChunked({
                            { address = header.arrayPtr + (seg.index - 1) * 0x8, flags = Memory.FLAGS.INT64 }
                        })
                        if slots and slots[1] and slots[1].value ~= 0 then
                            writeAddr = slots[1].value
                        end
                    end
                end
                return { value = arr[luaIdx], resolved = true, writeAddr = writeAddr, elementType = node.elementType }
            end
            if node.elements then
                local stride = node.elementStride or 0x8
                if stride > 0x8 then
                    local header, hErr = Repeated.readHeaderForSet(currentBase, node)
                    if not header then return nil, hErr end
                    currentBase = header.arrayPtr + (seg.index - 1) * stride
                else
                    local h, he = Repeated.readHeaderForSet(currentBase, node)
                    if not h then return nil, he end
                    local slots, sErr = Memory.readBatchChunked({
                        { address = h.arrayPtr + (seg.index - 1) * 0x8, flags = Memory.FLAGS.INT64 }
                    })
                    if not slots or not slots[1] or slots[1].value == 0 then
                        return nil, "null_element_ptr"
                    end
                    currentBase = slots[1].value
                end
                currentMeta = node.elements
            else
                return nil, "array_has_no_elements: " .. seg.name
            end
        elseif isLeafField(node) and i == #segments then
            finalField = node
            break
        elseif type(node) == "table" and not isLeafField(node) and i < #segments then
            currentMeta = node
        else
            return nil, "unknown_field: " .. tostring(id)
        end
    end

    if finalField then
        return { field = finalField, base = currentBase }
    end
    return nil, "unknown_field: " .. tostring(id)
end



---Shadow a String field with indirect=false. PublicEvent's strings
---are C++ objects inlined directly into the struct (no pointer to
---follow first) — confirmed against every String field in this
---schema during the raw-dump reverse-engineering. That's an ABI
---fact about this struct as a whole, not a per-field quirk, so
---it's declared once here rather than repeated on every String
---entry in metadata/PublicEvent.lua. See core/types/String.lua's
---field.indirect doc for what this actually changes.
---
---Does NOT mutate the shared metadata — returns a shadow table.
---Explicit field.indirect always wins.
---@param field table
---@return table field

---Shadow an Array-with-elements field to add stringDirect=true
---without mutating the shared metadata. Passed through to
---Struct.get via Repeated.get.
---@param field table
---@return table field

---Shared by M.get(id) and the snapshot object returned by
---M.get() with no id.
---@param base integer
---@param id string
---@return any|nil value, string|nil error
local function readFieldById(id)
    local result, err = resolvePath(id)
    if not result then
        log("get failed:", err)
        return nil, err
    end

    if result.resolved then
        return result.value
    end

    local field = result.field
    local base = result.base

    if field.type == "Object" then
        return nil, "unsupported_type: Object fields are not yet readable (missing nested metadata)"
    end

    if not isOffsetKnown(field) then
        return nil, "offset_unknown: " .. id
    end

    if field.type == "Array" then
        return Repeated.get(base, shadowStringDirectArray(field))
    end

    if field.repeated then
        return Repeated.get(base, field)
    end

    local impl = Type.resolve(field.type)
    if not impl then
        return nil, "no_type_impl: " .. tostring(field.type)
    end

    local value, valErr = impl.get(base, shadowStringDirect(field))
    if value == nil and valErr then
        log("get('" .. id .. "') failed:", valErr)
    end
    return value, valErr
end

---Shared by M.set(id, value) and SetOperation — writes a single
---field or an array of struct elements back to the live struct.
---@param base integer
---@param id string
---@param value any
---@return boolean ok, string|nil error
local function writeFieldById(id, value)
    local result, err = resolvePath(id)
    if not result then
        return false, err
    end

    if result.resolved then
        if not result.writeAddr then
            return false, "cannot_set_array_element_value_directly"
        end
        if op._dry then
            log(string.format("[dry] would set '%s' = %s", op.id, tostring(op.value)))
            return true, nil
        end
        local elemType = result.elementType
        if not elemType then
            return false, "unknown_element_type"
        end
        local impl = Type.resolve(elemType)
        if not impl then
            return false, "no_type_impl: " .. tostring(elemType)
        end
        local f = { offset = 0, type = elemType }
        if elemType == "String" then
            f.indirect = false
        end
        local ok = impl.set(result.writeAddr, f, op.value)
        if not ok then
            log("set('" .. op.id .. "') failed")
            return false, "write_failed"
        end
        log(string.format("set '%s' = %s", op.id, tostring(op.value)))
        return true, nil
    end

    local field = result.field
    local base = result.base

    if field.type == "Object" then
        return false, "unsupported_type: Object fields are not yet writable (missing nested metadata)"
    end

    if not isOffsetKnown(field) then
        return false, "offset_unknown: " .. id
    end

    if field.type == "Array" then
        return Repeated.set(base, shadowStringDirectArray(field), value)
    end

    if field.repeated then
        return Repeated.set(base, field, value)
    end

    local impl = Type.resolve(field.type)
    if not impl then
        return false, "no_type_impl: " .. tostring(field.type)
    end

    local ok = impl.set(base, shadowStringDirect(field), value)
    if not ok then
        return false, "write_failed"
    end
    return true, nil
end

--==================================================
-- get()
--==================================================
-- Called with a dotted id, reads that field immediately (using the
-- module's cached base — resolved on first use). Called with no id,
-- resolves the base immediately and returns an accessor/context
-- object with its own get(id), bound to that exact snapshot — no
-- separate :now() step required.

---@param id string|nil @ omit to get an event accessor bound to the currently-active struct
---@return any|nil value, string|nil error
function M.get(id)
    local base, baseErr = resolveBase()
    if not base then
        log("get failed, no base:", baseErr)
        return nil, baseErr
    end

    if id == nil then
        return {
            base = base,
            get = function(fieldId)
                return readFieldById(fieldId)
            end,
        }
    end

    return readFieldById(id)
end

--==================================================
-- set() — returns a chainable operation object supporting
-- :dry()
--==================================================

local SetOperation = {}
SetOperation.__index = SetOperation

local function performWrite(op)
    if op._dry then
        local result, dryErr = resolvePath(op.id)
        if not result then
            log("set failed:", dryErr)
            return false, dryErr
        end
        log(string.format("[dry] would set '%s' = %s", op.id, tostring(op.value)))
        return true, nil
    end

    local ok, err = writeFieldById(op.id, op.value)
    if not ok and err then
        log("set('" .. op.id .. "') failed:", err)
    end
    return ok, err
end

---Mark this operation as a dry run: validates everything (field
---exists, offset known) but never touches memory.
---Returns (ok, err).
function SetOperation:dry()
    self._dry = true
    return performWrite(self)
end

-- Calling set() executes immediately (no modifier required), while
-- still returning the chainable object so :dry() remains usable for
-- staged/conditional execution.
setmetatable(SetOperation, {
    __call = function(cls, id, value)
        local self = setmetatable({ id = id, value = value, _dry = false }, cls)
        local ok, err = performWrite(self)
        self._ok, self._err = ok, err
        return self
    end
})

---Write a field value to the currently-active PublicEvent struct.
---For array-of-struct fields (eventRewards), pass a Lua array of
---element tables — only keys present in each element are written
---(partial update). Scalar fields accept plain numbers/strings.
---@param id string @ dotted field id
---@param value any
---@return table operation @ chainable; already executed
function M.set(id, value)
    return SetOperation(id, value)
end

--==================================================
-- fields() / meta() — read-only introspection
--==================================================

---@param node table
---@param prefix string|nil
---@param results string[]
local function walkFields(node, prefix, results)
    for key, child in pairs(node) do
        if type(child) == "table" then
            local id = prefix and (prefix .. "." .. key) or key
            if isLeafField(child) then
                if isOffsetKnown(child) then
                    results[#results + 1] = id
                end
            else
                walkFields(child, id, results)
            end
        end
    end
end

---List every offset-verified field's dotted id. Fields still at the
---0xBAAD placeholder, and per-element Array templates, are excluded.
---@return string[] ids
function M.fields()
    local results = {}
    walkFields(metadata, nil, results)
    table.sort(results)
    return results
end

---@param id string
---@return table|nil metaView, string|nil error
function M.meta(id)
    local result, err = resolvePath(id)
    local field = result and result.field
    if not field then
        return nil, err
    end

    local view = {
        name     = id,
        type     = field.type,
        offset   = field.offset,
        repeated = field.repeated,
        known    = isOffsetKnown(field),
    }

    if baseAddress ~= nil and view.known then
        view.address = baseAddress + field.offset
    end

    return view
end

return M

end

__vfs['api/TeamEvent.lua'] = function(...)
--==================================================
-- api/TeamEvent.lua
--==================================================
-- Public-facing Nebula.TeamEvent module.
--
-- TeamEvent mirrors PublicEvent through metadata/TeamEvent.lua (see
-- that file for what's shared vs. patched). Base resolution here is
-- TeamEvent-specific, though: unlike GameStatus's single fixed
-- struct, there can be several TeamEvent structs in memory at once
-- (past/current/upcoming), so resolveBase() picks out whichever one
-- is currently active. See core/Memory.lua for the
-- byte-signature scan.
--
--   Nebula.TeamEvent.get("startTime")
--   Nebula.TeamEvent.get("sessionEntry.entryFeeTickets")
--   Nebula.TeamEvent.get("eventRewards")
--
--   local event = Nebula.TeamEvent.get()
--   event.get("minTeamSizeToJoin")
--   event.get("sessionEntry.numberOfParallelSessions")
--
--   Nebula.TeamEvent.set("eventRewards", {
--       [1] = { rewardCondition = { criteria = 0 },
--               maxCollectAmount = -1 }
--   })
--   Nebula.TeamEvent.set("startTime", 1700000000):dry()

local Memory   = nebulaLoadModule("core/Memory.lua")
local Type     = nebulaLoadModule("core/Type.lua")
local Repeated = nebulaLoadModule("core/Repeated.lua")
local Path     = nebulaLoadModule("core/Path.lua")
local Struct   = nebulaLoadModule("core/Struct.lua")
local metadata = nebulaLoadModule("metadata/TeamEvent.lua")

local M = {}

M.metadata = metadata

-- Cached per script session.
local baseAddress = nil

--==================================================
-- Base address resolution
--==================================================

local function log(...)
    if Nebula ~= nil and Nebula.log then
        print("[Nebula.TeamEvent]", ...)
    end
end

-- When no event struct is currently active, resolution fails. Cache
-- the failure with a cooldown so repeated get() calls don't re-run
-- the expensive full-memory scan every time; resolveBase(true) forces
-- an immediate rescan.
local FAIL_RETRY_SECONDS = 5
local lastFailErr = nil
local lastFailClock = nil

local function nowSec()
    if os.clock then return os.clock() end
    return os.time()
end

---@param forceRescan boolean|nil
---@return integer|nil address, string|nil error
local function resolveBase(forceRescan)
    if baseAddress ~= nil and not forceRescan then
        return baseAddress
    end

    if lastFailErr ~= nil and not forceRescan
        and (nowSec() - lastFailClock) < FAIL_RETRY_SECONDS then
        return nil, lastFailErr
    end

    local address, err = Memory.resolveActiveTeamEventBase()
    if not address then
        lastFailErr = err or "base_not_found"
        lastFailClock = nowSec()
        log("resolveBase failed:", lastFailErr)
        return nil, lastFailErr
    end

    baseAddress = address
    lastFailErr, lastFailClock = nil, nil
    return baseAddress
end

M.resolveBase = resolveBase

--==================================================
-- Field lookup helpers
--==================================================

---@param node any
---@return boolean
local function isLeafField(node)
    return type(node) == "table" and type(node.type) == "string"
end

local function isOffsetKnown(field)
    return field.offset ~= nil and field.offset ~= 0xBAAD
end

local function shadowStringDirect(field)
    if field.type == "String" and field.indirect == nil then
        return setmetatable({ indirect = false }, { __index = field })
    end
    return field
end

local function shadowStringDirectArray(field)
    if field.stringDirect == nil then
        return setmetatable({ stringDirect = true, container = "vector" }, { __index = field })
    end
    return field
end

---@param id string @ dotted field id, e.g. "sessionEntry.entryFeeTickets"
---@return table|nil field, string|nil error
local function resolvePath(id)
    local segments = Path.parse(id)
    if #segments == 0 then
        return nil, "empty_path"
    end

    local base, baseErr = resolveBase()
    if not base then
        return nil, baseErr
    end

    local currentBase = base
    local currentMeta = metadata
    local finalField = nil

    for i, seg in ipairs(segments) do
        local node = currentMeta[seg.name]
        if node == nil then
            return nil, "unknown_field: " .. tostring(id)
        end

        if seg.index ~= nil then
            if node.type ~= "Array" then
                return nil, "not_an_array: " .. seg.name
            end
            if not isOffsetKnown(node) then
                return nil, "offset_unknown: " .. seg.name
            end
            local arr, arrErr = Repeated.get(currentBase, shadowStringDirectArray(node))
            if not arr then
                return nil, arrErr
            end
            local luaIdx = seg.index
            if luaIdx < 1 or luaIdx > #arr then
                return nil, string.format("index_out_of_bounds: %s[%d] (size=%d)", seg.name, seg.index, #arr)
            end
            if i == #segments then
                local elemStride = node.elementStride or 0x8
                local header, _ = Repeated.readHeaderForSet(currentBase, node)
                local writeAddr = nil
                if header and header.arrayPtr and header.arrayPtr ~= 0 then
                    if elemStride > 0x8 then
                        writeAddr = header.arrayPtr + (seg.index - 1) * elemStride
                    else
                        local slots, _ = Memory.readBatchChunked({
                            { address = header.arrayPtr + (seg.index - 1) * 0x8, flags = Memory.FLAGS.INT64 }
                        })
                        if slots and slots[1] and slots[1].value ~= 0 then
                            writeAddr = slots[1].value
                        end
                    end
                end
                return { value = arr[luaIdx], resolved = true, writeAddr = writeAddr, elementType = node.elementType }
            end
            if node.elements then
                local stride = node.elementStride or 0x8
                if stride > 0x8 then
                    local header, hErr = Repeated.readHeaderForSet(currentBase, node)
                    if not header then return nil, hErr end
                    currentBase = header.arrayPtr + (seg.index - 1) * stride
                else
                    local h, he = Repeated.readHeaderForSet(currentBase, node)
                    if not h then return nil, he end
                    local slots, sErr = Memory.readBatchChunked({
                        { address = h.arrayPtr + (seg.index - 1) * 0x8, flags = Memory.FLAGS.INT64 }
                    })
                    if not slots or not slots[1] or slots[1].value == 0 then
                        return nil, "null_element_ptr"
                    end
                    currentBase = slots[1].value
                end
                currentMeta = node.elements
            else
                return nil, "array_has_no_elements: " .. seg.name
            end
        elseif isLeafField(node) and i == #segments then
            finalField = node
            break
        elseif type(node) == "table" and not isLeafField(node) and i < #segments then
            currentMeta = node
        else
            return nil, "unknown_field: " .. tostring(id)
        end
    end

    if finalField then
        return { field = finalField, base = currentBase }
    end
    return nil, "unknown_field: " .. tostring(id)
end



---Same ABI fact as PublicEvent (see api/PublicEvent.lua) —
---TeamEvent's strings are inlined into the struct too, since
---metadata/TeamEvent.lua mirrors PublicEvent's header where every
---String field lives. Does NOT mutate the shared metadata.
---@param field table
---@return table field

---Shadow an Array-with-elements field to add stringDirect=true.
---@param field table
---@return table field

---Shared by M.get(id) and the accessor object returned by M.get() with no id.
---@param base integer
---@param id string
---@return any|nil value, string|nil error
local function readFieldById(id)
    local result, err = resolvePath(id)
    if not result then
        log("get failed:", err)
        return nil, err
    end

    if result.resolved then
        return result.value
    end

    local field = result.field
    local base = result.base

    if field.type == "Object" then
        return nil, "unsupported_type: Object fields are not yet readable (missing nested metadata)"
    end

    if not isOffsetKnown(field) then
        return nil, "offset_unknown: " .. id
    end

    if field.type == "Array" then
        return Repeated.get(base, shadowStringDirectArray(field))
    end

    if field.repeated then
        return Repeated.get(base, field)
    end

    local impl = Type.resolve(field.type)
    if not impl then
        return nil, "no_type_impl: " .. tostring(field.type)
    end

    local value, valErr = impl.get(base, shadowStringDirect(field))
    if value == nil and valErr then
        log("get('" .. id .. "') failed:", valErr)
    end
    return value, valErr
end

---Shared by M.set(id, value) and SetOperation.
---@param base integer
---@param id string
---@param value any
---@return boolean ok, string|nil error
local function writeFieldById(id, value)
    local result, err = resolvePath(id)
    if not result then
        return false, err
    end

    if result.resolved then
        if not result.writeAddr then
            return false, "cannot_set_array_element_value_directly"
        end
        if op._dry then
            log(string.format("[dry] would set '%s' = %s", op.id, tostring(op.value)))
            return true, nil
        end
        local elemType = result.elementType
        if not elemType then
            return false, "unknown_element_type"
        end
        local impl = Type.resolve(elemType)
        if not impl then
            return false, "no_type_impl: " .. tostring(elemType)
        end
        local f = { offset = 0, type = elemType }
        if elemType == "String" then
            f.indirect = false
        end
        local ok = impl.set(result.writeAddr, f, op.value)
        if not ok then
            log("set('" .. op.id .. "') failed")
            return false, "write_failed"
        end
        log(string.format("set '%s' = %s", op.id, tostring(op.value)))
        return true, nil
    end

    local field = result.field
    local base = result.base

    if field.type == "Object" then
        return false, "unsupported_type: Object fields are not yet writable (missing nested metadata)"
    end

    if not isOffsetKnown(field) then
        return false, "offset_unknown: " .. id
    end

    if field.type == "Array" then
        return Repeated.set(base, shadowStringDirectArray(field), value)
    end

    if field.repeated then
        return Repeated.set(base, field, value)
    end

    local impl = Type.resolve(field.type)
    if not impl then
        return false, "no_type_impl: " .. tostring(field.type)
    end

    local ok = impl.set(base, shadowStringDirect(field), value)
    if not ok then
        return false, "write_failed"
    end
    return true, nil
end

--==================================================
-- get()
--==================================================
-- Called with a dotted id, reads that field immediately. Called
-- with no id, resolves the base immediately and returns an
-- accessor/context object with its own get(id) bound to that exact
-- snapshot — no separate :now() step required.

---@param id string|nil @ omit to get an event accessor bound to the currently-active struct
---@return any|nil value, string|nil error
function M.get(id)
    local base, baseErr = resolveBase()
    if not base then
        log("get failed, no base:", baseErr)
        return nil, baseErr
    end

    if id == nil then
        return {
            base = base,
            get = function(fieldId)
                return readFieldById(fieldId)
            end,
        }
    end

    return readFieldById(id)
end

--==================================================
-- set() — returns a chainable operation object supporting
-- :dry()
--==================================================

local SetOperation = {}
SetOperation.__index = SetOperation

local function performWrite(op)
    if op._dry then
        local result, dryErr = resolvePath(op.id)
        if not result then
            log("set failed:", dryErr)
            return false, dryErr
        end
        log(string.format("[dry] would set '%s' = %s", op.id, tostring(op.value)))
        return true, nil
    end

    local ok, err = writeFieldById(op.id, op.value)
    if not ok and err then
        log("set('" .. op.id .. "') failed:", err)
    end
    return ok, err
end

---Mark this operation as a dry run: validates everything (field
---exists, offset known) but never touches memory.
---Returns (ok, err).
function SetOperation:dry()
    self._dry = true
    return performWrite(self)
end

-- Calling set() executes immediately (no modifier required), while
-- still returning the chainable object so :dry() remains usable for
-- staged/conditional execution.
setmetatable(SetOperation, {
    __call = function(cls, id, value)
        local self = setmetatable({ id = id, value = value, _dry = false }, cls)
        local ok, err = performWrite(self)
        self._ok, self._err = ok, err
        return self
    end
})

---Write a field value to the currently-active TeamEvent struct.
---Same interface as PublicEvent.set — see api/PublicEvent.lua.
---@param id string @ dotted field id
---@param value any
---@return table operation @ chainable; already executed
function M.set(id, value)
    return SetOperation(id, value)
end

--==================================================
-- fields() / meta() — read-only introspection
--==================================================

---@param node table
---@param prefix string|nil
---@param results string[]
local function walkFields(node, prefix, results)
    for key, child in pairs(node) do
        if type(child) == "table" then
            local id = prefix and (prefix .. "." .. key) or key
            if isLeafField(child) then
                if isOffsetKnown(child) then
                    results[#results + 1] = id
                end
            else
                walkFields(child, id, results)
            end
        end
    end
end

---List every offset-verified field's dotted id.
---@return string[] ids
function M.fields()
    local results = {}
    walkFields(metadata, nil, results)
    table.sort(results)
    return results
end

---@param id string
---@return table|nil metaView, string|nil error
function M.meta(id)
    local result, err = resolvePath(id)
    local field = result and result.field
    if not field then
        return nil, err
    end

    local view = {
        name     = id,
        type     = field.type,
        offset   = field.offset,
        repeated = field.repeated,
        known    = isOffsetKnown(field),
    }

    if baseAddress ~= nil and view.known then
        view.address = baseAddress + field.offset
    end

    return view
end

return M

end

__vfs['core/Cache.lua'] = function(...)
--==================================================
-- core/Cache.lua
--==================================================
-- Persistent, PID-scoped cache for address discovery results.
--
-- Stores serialized Lua tables to gg.FILES_DIR using plain io.open
-- / loadfile / os.remove — no LuaJava, no directory enumeration.
-- A manifest file tracks which cache IDs exist so we never need to
-- list gg.FILES_DIR.
--
--   Nebula.Cache.load("team_event_addresses")   → { 0x1234, 0x5678 }
--   Nebula.Cache.save("team_event_addresses", { 0x1234 })
--   Nebula.Cache.delete("team_event_addresses")
--   Nebula.Cache.clear_all()
--
-- PID scoping: the manifest stores the PID it was written under.
-- On load, if the current PID differs from the manifest's PID,
-- every old cache file is deleted and the manifest is reset —
-- stale addresses from a previous process never leak through.
--
-- File naming:
--   <packageName>-nebula-cache-index         (manifest)
--   <packageName>-nebula-cache-<id>          (data)
--
-- Data files contain a plain Lua table returned by loadfile():
--   return { 305419896, 2271560481 }

local M = {}

local function log(...)
    if Nebula ~= nil and Nebula.log then
        print("[Nebula.Cache]", ...)
    end
end

--==================================================
-- Serializer
--==================================================
-- Produces loadable Lua source: loadfile() on the result yields
-- the original table. Handles arrays (contiguous integer keys
-- starting at 1) and hash tables (string/integer keys). Numbers,
-- strings, booleans, and nil are handled; nested tables are
-- recursed.

local function serializeValue(v, indent)
    indent = indent or ""
    local t = type(v)
    if t == "number" then
        return tostring(v)
    elseif t == "string" then
        return string.format("%q", v)
    elseif t == "boolean" then
        return tostring(v)
    elseif t == "nil" then
        return "nil"
    elseif t == "table" then
        -- Detect array vs hash
        local maxIdx = 0
        local count = 0
        local isArray = true
        for k, _ in pairs(v) do
            count = count + 1
            if type(k) == "number" and k == math.floor(k) and k >= 1 then
                if k > maxIdx then maxIdx = k end
            else
                isArray = false
            end
        end
        if isArray and maxIdx == count and maxIdx > 0 then
            local parts = {}
            for i = 1, maxIdx do
                parts[#parts + 1] = indent .. "    " .. serializeValue(v[i], indent .. "    ")
            end
            return "{\n" .. table.concat(parts, ",\n") .. "\n" .. indent .. "}"
        else
            local parts = {}
            for k, val in pairs(v) do
                local keyStr
                if type(k) == "string" then
                    keyStr = string.format("[%q]", k)
                else
                    keyStr = string.format("[%s]", tostring(k))
                end
                parts[#parts + 1] = indent .. "    " .. keyStr .. " = " .. serializeValue(val, indent .. "    ")
            end
            return "{\n" .. table.concat(parts, ",\n") .. "\n" .. indent .. "}"
        end
    end
    return "nil"
end

---Serialize a Lua value to loadable Lua source.
---@param data any
---@return string
local function serialize(data)
    return "return " .. serializeValue(data)
end

M.serialize = serialize

--==================================================
-- Target / path helpers
--==================================================

---Get the current target info. Returns nil if unavailable.
---@return table|nil target  { pid, packageName }
local function getTarget()
    local target = gg.getTargetInfo()
    if not target or not target.packageName or not target.pid then
        return nil
    end
    return target
end

---@param packageName string
---@param id string
---@return string path
local function cache_path(packageName, id)
    return gg.FILES_DIR .. "/" .. packageName .. "-nebula-cache-" .. id
end

---@param packageName string
---@return string path
local function index_path(packageName)
    return gg.FILES_DIR .. "/" .. packageName .. "-nebula-cache-index"
end

--==================================================
-- Manifest (index) management
--==================================================
-- The manifest stores { pid = <number>, ids = { ... } }. On load,
-- if the stored PID doesn't match the current PID, all listed
-- cache files are deleted and a fresh empty manifest is returned.

---Load the manifest. If the PID has changed, invalidates all old
---caches and returns an empty manifest.
---@return table manifest  { pid = int, ids = string[] }
local function load_index()
    local target = getTarget()
    if not target then
        return { pid = 0, ids = {} }
    end

    local f = loadfile(index_path(target.packageName))
    if not f then
        return { pid = target.pid, ids = {} }
    end

    local ok, result = pcall(f)
    if not ok or type(result) ~= "table" then
        return { pid = target.pid, ids = {} }
    end

    -- PID check: if the process changed, nuke everything
    if result.pid ~= target.pid then
        if type(result.ids) == "table" then
            for _, id in ipairs(result.ids) do
                os.remove(cache_path(target.packageName, id))
            end
        end
        os.remove(index_path(target.packageName))
        log("PID changed (", result.pid, "→", target.pid, ") — old caches invalidated")
        return { pid = target.pid, ids = {} }
    end

    if type(result.ids) ~= "table" then
        result.ids = {}
    end

    return result
end

---Save the manifest. Writes to a temp file first, then renames
---over the existing file for crash-safety.
---@param manifest table  { pid = int, ids = string[] }
---@return boolean ok
local function save_index(manifest)
    local target = getTarget()
    if not target then
        return false
    end

    local path = index_path(target.packageName)
    local content = serialize(manifest)

    -- Write to temp file first, then rename for atomicity.
    local tmp = path .. ".tmp"
    local f = io.open(tmp, "w")
    if not f then
        return false
    end
    f:write(content)
    f:close()

    -- os.rename overwrites the destination on most platforms.
    -- If it fails, fall back to direct write.
    if not os.rename(tmp, path) then
        f = io.open(path, "w")
        if not f then
            return false
        end
        f:write(content)
        f:close()
        os.remove(tmp)
    end

    return true
end

--==================================================
-- Public API
--==================================================

---Load a cache entry by logical ID. Returns nil for missing,
---corrupt, or PID-mismatched caches.
---@param id string  logical cache ID (e.g. "team_event_addresses")
---@return any|nil data, string|nil error
function M.load(id)
    local target = getTarget()
    if not target then
        return nil, "no_target"
    end

    -- Check PID validity via the manifest
    local manifest = load_index()
    local found = false
    for _, existingId in ipairs(manifest.ids) do
        if existingId == id then
            found = true
            break
        end
    end
    if not found then
        return nil  -- not in manifest = doesn't exist for this PID
    end

    local f = loadfile(cache_path(target.packageName, id))
    if not f then
        return nil  -- missing file (listed in manifest but gone)
    end

    local ok, result = pcall(f)
    if not ok or result == nil then
        log("load('", id, "') — corrupt cache, ignoring")
        return nil
    end

    return result
end

---Save data under a logical ID. Updates the manifest if the ID is
---new. Never stores duplicate IDs in the manifest.
---@param id string   logical cache ID
---@param data any    value to store (must be serializable)
---@return boolean ok, string|nil error
function M.save(id, data)
    local target = getTarget()
    if not target then
        return false, "no_target"
    end

    -- Write the data file
    local path = cache_path(target.packageName, id)
    local content = serialize(data)

    local f = io.open(path, "w")
    if not f then
        log("save('", id, "') — io.open failed for ", path)
        return false, "write_failed"
    end
    f:write(content)
    f:close()

    -- Load manifest, add ID if missing, save
    local manifest = load_index()
    manifest.pid = target.pid

    local alreadyPresent = false
    for _, existingId in ipairs(manifest.ids) do
        if existingId == id then
            alreadyPresent = true
            break
        end
    end
    if not alreadyPresent then
        manifest.ids[#manifest.ids + 1] = id
    end

    save_index(manifest)
    return true
end

---Delete a cache entry and remove its ID from the manifest.
---Safe to call even if the cache doesn't exist.
---@param id string  logical cache ID
---@return boolean ok
function M.delete(id)
    local target = getTarget()
    if not target then
        return false
    end

    -- Remove the data file
    os.remove(cache_path(target.packageName, id))

    -- Update the manifest
    local manifest = load_index()
    local newIds = {}
    for _, existingId in ipairs(manifest.ids) do
        if existingId ~= id then
            newIds[#newIds + 1] = existingId
        end
    end
    manifest.ids = newIds
    save_index(manifest)

    return true
end

---Delete all Nebula cache entries for the current package + PID,
---then delete the manifest. Never enumerates gg.FILES_DIR — uses
---only the manifest's ID list.
function M.clear_all()
    local target = getTarget()
    if not target then
        return
    end

    local manifest = load_index()
    for _, id in ipairs(manifest.ids) do
        os.remove(cache_path(target.packageName, id))
    end
    os.remove(index_path(target.packageName))
end

return M

end

__vfs['core/Field.lua'] = function(...)
--==================================================
-- core/Field.lua
--==================================================
-- Generic field/message accessor factory.
--
-- Creates proxy objects that wrap (baseAddress, metadataNode)
-- and support __index navigation through metadata-defined fields.
-- This is NOT a parallel system — it routes every read/write
-- through the existing Type registry and Repeated module, just
-- with a one-level-at-a-time access pattern instead of the
-- dotted-path walk used by the module-level get(id)/set(id, value).
--
-- Three accessor kinds:
--
--   MessageView   — wraps a base + metadata node. __index resolves
--                   field names from metadata and returns the
--                   appropriate accessor. Methods (get, set, now,
--                   fields, meta) are stored as closures on the
--                   table itself, so dot syntax works without self:
--                     event.get("startTime")      -- backward compat
--                     event.startTime.get()        -- new style
--                     event.startTime.set(1700000000)
--                     event.sessionEntry.entryFeeTickets.get()
--
--   ScalarAccessor — wraps a single typed field. get()/set() go
--                   straight to the Type implementation.
--
--   ArrayAccessor   — wraps an Array/repeated field. get()/set()
--                   go through Repeated.
--
-- ABI configuration (opts):
--   stringDirect = true   — String fields are inlined into the
--                           struct (no pointer indirection). This
--                           is the same fact that the api modules
--                           encode via shadowStringDirect().
--   container = "vector"  — Arrays use C++ std::vector ABI (vs
--                           protobuf RepeatedField default).
--
-- Base resolution:
--   The root MessageView (created by api module's get()) receives
--   a resolveFn closure. Base is resolved lazily on first field
--   access or explicit now() call. Nested MessageViews (created
--   by __index traversal) receive a pre-resolved base — no
--   resolveFn needed.

local Type     = nebulaLoadModule("core/Type.lua")
local Repeated = nebulaLoadModule("core/Repeated.lua")
local Memory   = nebulaLoadModule("core/Memory.lua")

local Field = {}

--==================================================
-- Shared helpers
--==================================================

---A metadata node is a leaf (readable) field iff it has a `type`
---string. Pure namespace containers (sessionEntry, gameMode) have
---no `type` — only typed children.
local function isLeaf(node)
    return type(node) == "table" and type(node.type) == "string"
end

---Offset is known (not the 0xBAAD placeholder).
local function isOffsetKnown(field)
    return field.offset ~= nil and field.offset ~= 0xBAAD
end

---Shadow a String field with indirect=false when opts.stringDirect
---is set. Same logic as every api module's shadowStringDirect().
---Does NOT mutate the shared metadata — returns a shadow table.
local function shadowString(field, opts)
    if field.type == "String" and field.indirect == nil
       and opts and opts.stringDirect then
        return setmetatable({ indirect = false }, { __index = field })
    end
    return field
end

---Shadow an Array field with stringDirect + container when opts
---requires it. Same logic as every api module's
---shadowStringDirectArray().
local function shadowArray(field, opts)
    if field.stringDirect == nil
       and opts and opts.stringDirect then
        return setmetatable({
            stringDirect = true,
            container = opts.container or "vector",
        }, { __index = field })
    end
    return field
end

---Walk a metadata tree looking up a dotted-path field id,
---starting from the given metadata node (not necessarily root).
---@param metadata table
---@param id string  e.g. "sessionEntry.entryFeeTickets"
---@return table|nil field, string|nil error
local function lookupInMetadata(metadata, id)
    local node = metadata
    for part in id:gmatch("[^.]+") do
        if type(node) ~= "table" or node[part] == nil then
            return nil, "unknown_field: " .. tostring(id)
        end
        node = node[part]
    end
    if not isLeaf(node) then
        return nil, "unknown_field: " .. tostring(id)
    end
    return node
end

---Generic read: walk metadata from the given node, read the field
---through the Type/Repeated system. Same logic as each api module's
---readField(), just factored out so nested MessageViews can use it
---without duplicating the module's local readField.
---@param base integer
---@param metadata table
---@param opts table|nil
---@param id string  dotted field id
---@return any|nil value, string|nil error
local function readFieldGeneric(base, metadata, opts, id)
    local field, err = lookupInMetadata(metadata, id)
    if not field then return nil, err end

    if field.type == "Object" then
        return nil, "unsupported_type: Object fields are not yet readable (missing nested metadata)"
    end

    if not isOffsetKnown(field) then
        return nil, "offset_unknown: " .. id
    end

    if field.type == "Array" then
        return Repeated.get(base, shadowArray(field, opts))
    end

    if field.repeated then
        return Repeated.get(base, field)
    end

    local impl = Type.resolve(field.type)
    if not impl then
        return nil, "no_type_impl: " .. tostring(field.type)
    end

    return impl.get(base, shadowString(field, opts))
end

---Generic write: same structure as readFieldGeneric, but writes.
---@param base integer
---@param metadata table
---@param opts table|nil
---@param id string
---@param value any
---@return boolean ok, string|nil error
local function writeFieldGeneric(base, metadata, opts, id, value)
    local field, err = lookupInMetadata(metadata, id)
    if not field then return false, err end

    if field.type == "Object" then
        return false, "unsupported_type: Object fields are not yet writable (missing nested metadata)"
    end

    if not isOffsetKnown(field) then
        return false, "offset_unknown: " .. id
    end

    if field.type == "Array" then
        return Repeated.set(base, shadowArray(field, opts), value)
    end

    if field.repeated then
        return Repeated.set(base, field, value)
    end

    local impl = Type.resolve(field.type)
    if not impl then
        return false, "no_type_impl: " .. tostring(field.type)
    end

    return impl.set(base, shadowString(field, opts), value)
end

---Walk a metadata node collecting leaf field IDs (dotted paths).
---Same logic as each api module's walkFields(), but starts from
---the given node instead of root.
---@param node table
---@param prefix string|nil
---@param results string[]
local function walkFields(node, prefix, results)
    for key, child in pairs(node) do
        if type(key) == "string" and type(child) == "table" then
            local id = prefix and (prefix .. "." .. key) or key
            if isLeaf(child) then
                if isOffsetKnown(child) then
                    results[#results + 1] = id
                end
            else
                walkFields(child, id, results)
            end
        end
    end
end

--==================================================
-- ScalarAccessor
--==================================================
-- Plain table with get/set closures (dot syntax, no self needed).
-- Created when __index resolves a leaf field that's a scalar type
-- (Int32, String, Float, Enum, Bool, BitMask, etc.).

function Field.scalar(base, field, opts)
    local shadowedField = shadowString(field, opts)

    return {
        get = function()
            if not isOffsetKnown(field) then
                return nil, "offset_unknown"
            end
            local impl = Type.resolve(field.type)
            if not impl then
                return nil, "no_type_impl: " .. tostring(field.type)
            end
            return impl.get(base, shadowedField)
        end,

        set = function(value)
            if not isOffsetKnown(field) then
                return false, "offset_unknown"
            end
            local impl = Type.resolve(field.type)
            if not impl then
                return false, "no_type_impl: " .. tostring(field.type)
            end
            return impl.set(base, shadowedField, value)
        end,

        meta = function()
            return {
                type     = field.type,
                offset   = field.offset,
                known    = isOffsetKnown(field),
                repeated = field.repeated == true,
            }
        end,
    }
end

--==================================================
-- ArrayAccessor
--==================================================
-- Plain table with get/set closures. Routes through Repeated,
-- same as the module-level readField/writeField for Array fields.

function Field.array(base, field, opts)
    local shadowedField = shadowArray(field, opts)

    return {
        get = function()
            if not isOffsetKnown(field) then
                return nil, "offset_unknown"
            end
            return Repeated.get(base, shadowedField)
        end,

        set = function(value)
            if not isOffsetKnown(field) then
                return false, "offset_unknown"
            end
            return Repeated.set(base, shadowedField, value)
        end,

        meta = function()
            return {
                type     = field.type,
                offset   = field.offset,
                known    = isOffsetKnown(field),
                repeated = true,
            }
        end,
    }
end

--==================================================
-- MessageView
--==================================================
-- Wraps a base address + metadata node. Supports:
--
--   __index navigation:  event.startTime → ScalarAccessor
--                        event.sessionEntry → MessageView (same base)
--                        event.lootDefinition → MessageView (base+offset)
--                        event.eventRewards → ArrayAccessor
--
--   Method closures (dot syntax, no colon needed):
--     event.get("dotted.path")  — backward compat, returns value
--     event.set("dotted.path", v) — backward compat, writes value
--     event.now()               — resolve base, return (self|nil, err)
--     event.fields()            — list known field IDs
--     event.meta("field")       — field metadata
--
-- Methods are stored as table fields (found by rawget before
-- __index), so they never shadow metadata field names. No known
-- metadata field is named "get", "set", "now", "fields", or "meta".

function Field.message(base, metadata, opts, resolveFn)
    opts = opts or {}
    local self = {}

    -- Private state
    self._base      = base
    self._metadata  = metadata
    self._opts      = opts
    self._resolveFn = resolveFn
    self._resolveErr = nil

    ---Resolve base address if not already resolved.
    ---Returns true if base is available.
    local function ensureBase()
        if self._base == nil and resolveFn then
            self._base, self._resolveErr = resolveFn()
        end
        return self._base ~= nil
    end

    --================================
    -- Method closures (dot syntax)
    --================================

    ---Resolve base and return self (for backward compat with the
    ---get():now() pattern). Returns (nil, error) if resolution fails.
    self.now = function()
        if not ensureBase() then
            return nil, self._resolveErr
        end
        return self
    end

    ---Read a field by dotted path (backward compat). Delegates to
    ---readFieldGeneric which walks metadata from this node.
    self.get = function(id)
        if id == nil then return self end
        if not ensureBase() then
            return nil, self._resolveErr
        end
        return readFieldGeneric(self._base, metadata, opts, id)
    end

    ---Write a field by dotted path (backward compat).
    self.set = function(id, value)
        if not ensureBase() then
            return false, self._resolveErr
        end
        return writeFieldGeneric(self._base, metadata, opts, id, value)
    end

    ---List every offset-verified field's dotted id, starting from
    ---this metadata node.
    self.fields = function()
        local results = {}
        walkFields(metadata, nil, results)
        table.sort(results)
        return results
    end

    ---Return metadata about a field by dotted path.
    self.meta = function(id)
        local field, err = lookupInMetadata(metadata, id)
        if not field then return nil, err end
        return {
            type     = field.type,
            offset   = field.offset,
            known    = isOffsetKnown(field),
            repeated = field.repeated == true,
        }
    end

    --================================
    -- __index field navigation
    --================================

    local mt = {
        __index = function(t, k)
            -- Methods are in the table itself (rawget finds them
            -- before __index is called). So if we're here, k is
            -- not a method — it's a field name to resolve from
            -- metadata.
            local node = metadata[k]
            if node == nil then
                return nil
            end

            if not ensureBase() then
                return nil, self._resolveErr
            end

            if isLeaf(node) then
                if node.type == "Object" then
                    -- Pointer-backed nested sub-struct (e.g.
                    -- lootDefinition) — same convention as
                    -- core/Struct.lua's M.get(): base+offset holds
                    -- a POINTER to the sub-struct, not the
                    -- sub-struct's data itself. Must deref, not
                    -- just add the offset.
                    local ptr, derefErr = Memory.deref(self._base, node.offset or 0)
                    if not ptr or ptr == 0 then
                        return nil, derefErr or "null_pointer"
                    end
                    return Field.message(ptr, node, opts, nil)
                elseif node.type == "Array" then
                    return Field.array(self._base, node, opts)
                elseif node.repeated then
                    -- Plain repeated field (not Array type)
                    return Field.array(self._base, node, opts)
                else
                    return Field.scalar(self._base, node, opts)
                end
            else
                -- Namespace container (e.g. sessionEntry, gameMode):
                -- children have absolute offsets from the struct base.
                -- Base stays the same; only the metadata scope narrows.
                return Field.message(self._base, node, opts, nil)
            end
        end,
    }

    setmetatable(self, mt)
    return self
end

return Field

end

__vfs['core/Memory.lua'] = function(...)
--==================================================
-- core/Memory.lua
--==================================================
-- Thin wrapper around GameGuardian's gg.getValues/gg.setValues.
-- Every Type module and api/*.lua goes through this instead of
-- calling gg.* directly. This is the only file allowed to know
-- about gg.* flag numbers.
--
-- Also owns base-address resolution for the four structs Nebula
-- reads (GameStatus, PublicEvent, TeamEvent, CommunityEvent).
-- Resolution for PublicEvent and TeamEvent integrates a persistent
-- address cache (core/Cache.lua) so that addresses discovered in a
-- previous run survive even after the user modifies signature fields
-- — but the AOB scan ALWAYS runs. See resolveActiveTeamEventBase()
-- and resolveActivePublicEventBase() below for the merge flow.
-- CommunityEvent uses a string-search resolver instead of AOB but
-- shares the same cache integration — see
-- resolveActiveCommunityEventBase().

local M = {}

local function log(...)
    if Nebula and Nebula.verbose then
        print("[core.Memory]", ...)
    end
end



-- GG value-type flags used throughout Nebula.
M.FLAGS = {
    BYTE   = 1,
    WORD   = 2,
    INT32  = 4,
    XOR    = 8,   -- unused/reserved
    FLOAT  = 16,
    INT64  = 32,  -- also used for pointers
    DOUBLE = 64,
}

M.FLAGS.POINTER = M.FLAGS.INT64

---Verbose, timed logging for every gg.* round-trip. Off by default
---— gated by Nebula.verbose (separate from Nebula.log, which is
---for api/GameStatus.lua's higher-level get/set/dry logging). Use
---this to see where time is actually going: number of gg calls,
---batch sizes, and per-call duration.
local function vlog(label, count, startTime)
    if Nebula ~= nil and Nebula.verbose then
        local elapsedMs = (os.clock() - startTime) * 1000
        print(string.format("[Nebula.Memory] %-12s count=%-4d %.2fms", label, count, elapsedMs))
    end
end

---Read a single value at an address with a given flag.
---@param address integer
---@param flags integer
---@return any|nil value, string|nil error
function M.read(address, flags)
    if address == nil or address == 0 then
        return nil, "nil_address"
    end

    local startTime = os.clock()
    local ok, result = pcall(function()
        return gg.getValues({ { address = address, flags = flags } })
    end)
    vlog("read", 1, startTime)

    if not ok or type(result) ~= "table" or result[1] == nil then
        return nil, "read_failed"
    end

    return result[1].value
end

---Read multiple {address, flags} pairs in one batched call.
---@param specs table[] @ array of { address = int, flags = int }
---@return table[]|nil results, string|nil error
function M.readBatch(specs)
    local startTime = os.clock()
    local ok, result = pcall(function()
        return gg.getValues(specs)
    end)
    vlog("readBatch", #specs, startTime)

    if not ok or type(result) ~= "table" then
        return nil, "read_failed"
    end

    return result
end

---Write a single value at an address with a given flag.
---@param address integer
---@param flags integer
---@param value any
---@return boolean ok
function M.write(address, flags, value)
    if address == nil or address == 0 then
        return false
    end

    local startTime = os.clock()
    local ok = pcall(function()
        gg.setValues({ { address = address, flags = flags, value = value } })
    end)
    vlog("write", 1, startTime)

    return ok
end

---Write multiple {address, flags, value} triples in one batched call.
---@param specs table[]
---@return boolean ok
function M.writeBatch(specs)
    local startTime = os.clock()
    local ok, result = pcall(function()
        return gg.setValues(specs)
    end)
    vlog("writeBatch", #specs, startTime)

    -- pcall catches errors; also check gg.setValues return value
    -- (some GG versions return false instead of throwing)
    return ok and result ~= false
end

-- Max specs sent to gg.getValues/setValues in a single call.
-- Even with header size/capacity sanity-checked (see
-- core/Repeated.lua), a legitimately large repeated field could
-- still produce a batch big enough to strain GG's IPC layer in one
-- shot. Chunking keeps every individual gg.* call small and
-- predictable regardless of how many specs the caller has.
M.MAX_BATCH_SIZE = 256

---Read multiple {address, flags} pairs, transparently chunked into
---calls of at most M.MAX_BATCH_SIZE each. Result order matches
---input order.
---@param specs table[]
---@return table[]|nil results, string|nil error
function M.readBatchChunked(specs)
    if #specs <= M.MAX_BATCH_SIZE then
        return M.readBatch(specs)
    end

    local results = {}
    for i = 1, #specs, M.MAX_BATCH_SIZE do
        local chunk = {}
        for j = i, math.min(i + M.MAX_BATCH_SIZE - 1, #specs) do
            chunk[#chunk + 1] = specs[j]
        end

        local chunkResults, err = M.readBatch(chunk)
        if not chunkResults then
            return nil, err
        end

        for _, r in ipairs(chunkResults) do
            results[#results + 1] = r
        end
    end

    return results
end

---Write multiple {address, flags, value} triples, transparently
---chunked into calls of at most M.MAX_BATCH_SIZE each.
---@param specs table[]
---@return boolean ok
function M.writeBatchChunked(specs)
    if #specs <= M.MAX_BATCH_SIZE then
        return M.writeBatch(specs)
    end

    for i = 1, #specs, M.MAX_BATCH_SIZE do
        local chunk = {}
        for j = i, math.min(i + M.MAX_BATCH_SIZE - 1, #specs) do
            chunk[#chunk + 1] = specs[j]
        end

        if not M.writeBatch(chunk) then
            return false
        end
    end

    return true
end

---Copy a contiguous block of memory from src to dst. Uses 8-byte
---(INT64) chunks wherever possible, falling back to single bytes
---only for the final <8 remainder, and batches every read/write
---into as few gg.* calls as MAX_BATCH_SIZE allows. Replaces the
---old pattern of one gg call per byte, which is both 8x more specs
---and — critically — was issuing the writes one at a time instead
---of batched.
---@param src integer
---@param dst integer
---@param length integer
---@return boolean ok
function M.copyRegion(src, dst, length)
    if length <= 0 then
        return true
    end

    local specs = {}
    local offset = 0
    while offset < length do
        if length - offset >= 8 then
            specs[#specs + 1] = { address = src + offset, flags = M.FLAGS.INT64 }
            offset = offset + 8
        else
            specs[#specs + 1] = { address = src + offset, flags = M.FLAGS.BYTE }
            offset = offset + 1
        end
    end

    local readData, err = M.readBatchChunked(specs)
    if not readData then
        return false
    end

    local writes = {}
    offset = 0
    for i, spec in ipairs(specs) do
        local value = readData[i] and readData[i].value or 0
        writes[i] = { address = dst + offset, flags = spec.flags, value = value }
        offset = offset + (spec.flags == M.FLAGS.INT64 and 8 or 1)
    end

    return M.writeBatchChunked(writes)
end

---Follow a pointer field: read the pointer value stored at
---`baseAddress + offset`, returning the address it points to.
---@param baseAddress integer
---@param offset integer
---@return integer|nil pointer, string|nil error
function M.deref(baseAddress, offset)
    local ptr, err = M.read(baseAddress + offset, M.FLAGS.POINTER)
    if ptr == nil or ptr == 0 then
        return nil, err or "null_pointer"
    end
    return ptr
end

--==================================================
-- Base address resolution
--==================================================
-- Finds the live GameStatus struct in memory by locating the
-- "startup_count" string constant, then walking a fixed chain of
-- pointer derefs to reach the real struct base:
--
--   hit            = AOB match address of "startup_count"
--   ptr            = read(hit + 0x1F, INT64)     -- object holding the string
--   ver            = read(ptr + 0x10, INT32)     -- vtable/version marker
--   typePtr        = read(ptr + 0x80, INT64)     -- pointer to the actual struct
--   base           = read(typePtr, INT32).address -- the struct's own address
--
-- The scan must run per-region (gg.REGION_C_ALLOC / gg.REGION_OTHER)
-- — searching all regions at once misses the hit in some game
-- states, which is why this previously failed.
--
-- Result is cached per script session — see api/GameStatus.lua's
-- resolveBase(), which owns the cache. This function always does
-- a fresh scan; callers are responsible for caching.

local SIGNATURE_HEX = "73 74 61 72 74 75 70 5F 63 6F 75 6E 74" -- "startup_count"
local VALID_VTABLE_MARKERS = {
    [65792]    = true,
    [65793]    = true,
    [16843008] = true,
    [16843009] = true,
}

M.SEARCH_REGIONS = { gg.REGION_C_ALLOC, gg.REGION_OTHER }

local function regionName(region)
    if region == gg.REGION_C_ALLOC then return "C_ALLOC" end
    if region == gg.REGION_OTHER then return "OTHER" end
    return tostring(region)
end

---Scan a single region for GameStatus struct base address hits.
---@param region integer
---@return integer[] found
local function scanRegion(region)
    local found = {}

    gg.clearResults()
    gg.setRanges(region)
    gg.searchNumber("h " .. SIGNATURE_HEX, 1)
    gg.refineNumber("h 73", 1)

    local results = gg.getResults(gg.getResultsCount())
    gg.clearResults()

    if not results or #results == 0 then
        return found
    end

    for _, hit in ipairs(results) do
        local ptr = M.read(hit.address + 0x1F, M.FLAGS.INT64)

        if ptr ~= nil and ptr ~= 0 then
            -- Sanity-check: a real pointer should be in a plausible
            -- memory range. Values outside this look like ASCII text
            -- from false-positive AOB matches inside string literals.
            if ptr >= 0x10000 and ptr <= 0x7FFFFFFFFFFF then
                local ver = M.read(ptr + 0x10, M.FLAGS.INT32)
                if ver ~= nil and VALID_VTABLE_MARKERS[ver] then
                    local typePtr = M.read(ptr + 0x80, M.FLAGS.INT64)
                    if typePtr ~= nil and typePtr ~= 0 then
                        -- Reference reads a value AT typePtr just to confirm
                        -- the address is live/readable, then uses typePtr
                        -- itself (not the value read) as the resolved base.
                        local probe = M.read(typePtr, M.FLAGS.INT32)
                        if probe ~= nil then
                            table.insert(found, typePtr)
                        end
                    end
                end
            end
        end
    end

    return found
end

---Scan process memory for the GameStatus struct base address.
---Expensive — call once per session and cache the result.
---@return integer[]|nil addresses, string|nil error
function M.resolveGameStatusBase()
    for _, region in ipairs(M.SEARCH_REGIONS) do
        local ok, found = pcall(scanRegion, region)
        if ok and found and #found > 0 then
            return found
        end
    end

    return nil, "no_valid_matches"
end

--==================================================
-- Event address validation
--==================================================
-- Validates that a given address is a real event struct (not
-- freed/unmapped memory or a false positive). The AOB signature
-- may have been modified by the user (e.g. eventTicketRefillCost
-- changed from 50 to 999), so validation must NOT rely on the
-- signature bytes. Instead it checks structural fields that are
-- invariant under user modification:
--
--   contentVersion (0x0) — small positive number
--   startTime      (0x14C) — Unix timestamp > 1.5 billion
--   endTime        (0x154) — Unix timestamp > 1.5 billion
--   startTime < endTime  — valid event window
--
-- All three reads must succeed (address is in mapped memory).

-- Schema minimum for startTime/endTime — matches the JSON schema's
-- "minimum": 1500000000 constraint.
local MIN_TIMESTAMP = 1500000000

---Validate a single event struct address by reading structural
---fields that should be present regardless of signature
---modification. Returns true if all checks pass.
---@param addr integer  base address of the event struct
---@return boolean valid
local function validateEventAddress(addr)
    if addr == nil or addr == 0 then
        return false
    end

    -- Batch-read contentVersion, startTime, endTime in one call.
    local specs = {
        { address = addr,        flags = M.FLAGS.INT32 },  -- contentVersion @ 0x0
        { address = addr + 0x14C, flags = M.FLAGS.INT32 }, -- startTime
        { address = addr + 0x154, flags = M.FLAGS.INT32 }, -- endTime
    }

    local results, err = M.readBatch(specs)
    if not results or #results < 3 then
        return false
    end

    local contentVersion = results[1].value
    local startTime = results[2].value
    local endTime = results[3].value

    -- contentVersion: small positive number
    if contentVersion == nil or contentVersion < 0 or contentVersion > 10000 then
        return false
    end

    -- startTime / endTime: plausible Unix timestamps
    if startTime == nil or startTime < MIN_TIMESTAMP then
        return false
    end
    if endTime == nil or endTime < MIN_TIMESTAMP then
        return false
    end

    -- Valid event window
    if startTime >= endTime then
        return false
    end

    return true
end

M.validateEventAddress = validateEventAddress

--==================================================
-- Address cache integration helpers
--==================================================
-- Merges cached and AOB-discovered addresses into a single
-- deduplicated list of valid addresses, then persists the result.
-- The AOB scan ALWAYS runs — cache is supplementary, not a
-- replacement.
--
-- Flow:
--   load cache → validate cached → AOB scan → validate AOB →
--   merge + deduplicate → save cache → return combined

---Merge cached and AOB-discovered addresses: validate each,
---deduplicate, save the combined list, and return it.
---@param cacheId string       logical cache ID (e.g. "team_event_addresses")
---@param aobBases integer[]   raw AOB scan results (already signature-matched)
---@return integer[] combined  valid, deduplicated addresses
local function resolveWithCache(cacheId, aobBases, validator)
    validator = validator or validateEventAddress

    local Cache = nebulaLoadModule("core/Cache.lua")

    local cached = Cache.load(cacheId)
    if cached == nil then
        cached = {}
    end

    local validCached = {}
    for _, addr in ipairs(cached) do
        if validator(addr) then
            validCached[#validCached + 1] = addr
        end
    end

    local validAob = {}
    for _, addr in ipairs(aobBases) do
        if validator(addr) then
            validAob[#validAob + 1] = addr
        end
    end

    -- 4. Merge + deduplicate
    local seen = {}
    local combined = {}
    for _, addr in ipairs(validCached) do
        if not seen[addr] then
            seen[addr] = true
            combined[#combined + 1] = addr
        end
    end
    for _, addr in ipairs(validAob) do
        if not seen[addr] then
            seen[addr] = true
            combined[#combined + 1] = addr
        end
    end

    -- 5. Save the combined list back to cache
    if #combined > 0 then
        Cache.save(cacheId, combined)
    end

    return combined
end

--==================================================
-- TeamEvent base resolution
--==================================================
-- Finds every live TeamEvent struct in memory by searching for the
-- raw bytes of three back-to-back sessionEntry fields:
-- eventTicketRefillTime=14400, eventTicketRefillAmount=2,
-- eventTicketRefillCost=50 (offsets 0x168/0x16C/0x170). These are
-- event-design constants, not per-instance data, so the byte
-- pattern is stable across restarts — UNLESS a future update
-- rebalances any of those three numbers, in which case this search
-- will silently return zero hits. That's the signal to re-derive
-- the signature, not a bug in the walk itself.
--
-- The AOB signature bytes can also be modified by an SDK user who
-- changes eventTicketRefillCost etc. via Nebula.TeamEvent.set().
-- To survive that, resolveActiveTeamEventBase() integrates the
-- persistent address cache: cached addresses that still pass
-- structural validation are kept even when the AOB signature no
-- longer matches them. The AOB scan ALWAYS runs regardless.

local TEAM_EVENT_SIGNATURE_HEX = "40 38 00 00 02 00 00 00 32 00 00 00"
local TEAM_EVENT_SIGNATURE_OFFSET = 0x168 -- eventTicketRefillTime, relative to struct base
local TEAM_EVENT_START_TIME_OFFSET = 0x14C
local TEAM_EVENT_END_TIME_OFFSET = 0x154

---Scan process memory for every live TeamEvent struct base address
---(via the sessionEntry byte signature), regardless of which one is
---currently active.
---@return integer[]|nil bases, string|nil error
function M.findTeamEventBases()
    for _, region in ipairs(M.SEARCH_REGIONS) do
        gg.clearResults()
        gg.setRanges(region)
        gg.searchNumber("h " .. TEAM_EVENT_SIGNATURE_HEX, 1)
        gg.refineNumber("64", 1) -- re-check eventTicketRefillTime's low byte (0x40 = 64)

        local results = gg.getResults(gg.getResultsCount())
        gg.clearResults()

        if results and #results > 0 then
            local bases = {}
            for _, hit in ipairs(results) do
                bases[#bases + 1] = hit.address - TEAM_EVENT_SIGNATURE_OFFSET
            end
            return bases
        end
    end

    return nil, "signature_not_found"
end

---Resolve the struct base of whichever TeamEvent is currently
---active (startTime < now < endTime). Integrates the persistent
---address cache so addresses discovered in a previous run survive
---even after the user modifies signature fields.
---@return integer|nil base, string|nil error
function M.resolveActiveTeamEventBase()
    -- AOB scan ALWAYS runs first.
    local aobBases, aobErr = M.findTeamEventBases()
    if not aobBases then
        aobBases = {}
    end

    -- Merge cached + AOB, validate, deduplicate, save.
    local combined = resolveWithCache("team_event_addresses", aobBases)

    if #combined == 0 then
        return nil, "no_active_team_event"
    end

    -- Filter for the currently-active event
    local currentTime = os.time()
    local readList = {}
    for _, base in ipairs(combined) do
        readList[#readList + 1] = { address = base + TEAM_EVENT_START_TIME_OFFSET, flags = M.FLAGS.INT32 }
        readList[#readList + 1] = { address = base + TEAM_EVENT_END_TIME_OFFSET, flags = M.FLAGS.INT32 }
    end

    local readValues, readErr = M.readBatch(readList)
    if not readValues then
        return nil, readErr
    end

    for i = 1, (#readValues / 2) do
        local startTime = readValues[i * 2 - 1].value
        local endTime = readValues[i * 2].value
        if startTime ~= nil and endTime ~= nil and startTime < currentTime and currentTime < endTime then
            return combined[i]
        end
    end

    return nil, "no_active_team_event"
end

--==================================================
-- PublicEvent base resolution
--==================================================
-- Same pattern as the TeamEvent section above. The anchor here is
-- gemsToPointsConversion=6 immediately followed by
-- conversionDuration=86400 (1 day) — offsets 0x3F0/0x3F4, part of
-- the header shared between PublicEvent and TeamEvent (see
-- metadata/PublicEvent.lua). Same fragility caveat: if either of
-- those two constants ever changes, this signature silently stops
-- matching.
--
-- Same cache integration as TeamEvent: the AOB scan always runs,
-- and cached addresses that pass structural validation are kept.

local PUBLIC_EVENT_SIGNATURE_HEX = "06 00 00 00 80 51 01 00"
local PUBLIC_EVENT_SIGNATURE_OFFSET = 0x3F0 -- gemsToPointsConversion, relative to struct base
local PUBLIC_EVENT_START_TIME_OFFSET = 0x14C
local PUBLIC_EVENT_END_TIME_OFFSET = 0x154

---Scan process memory for every live PublicEvent struct base address.
---@return integer[]|nil bases, string|nil error
function M.findPublicEventBases()
    for _, region in ipairs(M.SEARCH_REGIONS) do
        gg.clearResults()
        gg.setRanges(region)
        gg.searchNumber("h " .. PUBLIC_EVENT_SIGNATURE_HEX, 1)
        gg.refineNumber("6", 1) -- re-check gemsToPointsConversion is still 6

        local results = gg.getResults(gg.getResultsCount())
        gg.clearResults()

        if results and #results > 0 then
            local bases = {}
            for _, hit in ipairs(results) do
                bases[#bases + 1] = hit.address - PUBLIC_EVENT_SIGNATURE_OFFSET
            end
            return bases
        end
    end

    return nil, "signature_not_found"
end

---Resolve the struct base of whichever PublicEvent is currently
---active (startTime < now < endTime). Same caching convention as
---resolveActiveTeamEventBase() — cache + AOB always run.
---@return integer|nil base, string|nil error
function M.resolveActivePublicEventBase()
    -- AOB scan ALWAYS runs first.
    local aobBases, aobErr = M.findPublicEventBases()
    if not aobBases then
        aobBases = {}
    end

    -- Merge cached + AOB, validate, deduplicate, save.
    local combined = resolveWithCache("public_event_addresses", aobBases)

    if #combined == 0 then
        return nil, "no_active_public_event"
    end

    -- Filter for the currently-active event
    local currentTime = os.time()
    local readList = {}
    for _, base in ipairs(combined) do
        readList[#readList + 1] = { address = base + PUBLIC_EVENT_START_TIME_OFFSET, flags = M.FLAGS.INT32 }
        readList[#readList + 1] = { address = base + PUBLIC_EVENT_END_TIME_OFFSET, flags = M.FLAGS.INT32 }
    end

    local readValues, readErr = M.readBatch(readList)
    if not readValues then
        return nil, readErr
    end

    for i = 1, (#readValues / 2) do
        local startTime = readValues[i * 2 - 1].value
        local endTime = readValues[i * 2].value
        if startTime ~= nil and endTime ~= nil and startTime < currentTime and currentTime < endTime then
            return combined[i]
        end
    end

    return nil, "no_active_public_event"
end


--==================================================
-- CommunityEvent base resolution
--==================================================
-- Finds the CommunityShowcase struct in memory via a string-search
-- method.
--
-- Unlike PublicEvent/TeamEvent (AOB byte-signature scan), the
-- CommunityShowcase is located by searching for its own name field:
-- the ASCII bytes of "community Showcase\0". This is a more stable
-- search target than a config constant — it's the event's identity,
-- not a tunable value that could change between events.
--
-- Flow:
--   1. Search for "community Showcase\0" as raw bytes (BYTE flag)
--   2. Refine: the first byte of the hit must be 0x24 ('$' — the
--      SSO length byte of the std::string at name offset 0x20)
--   3. For each hit: read hit.address - 0x18 as INT32
--      If it equals 0x6D6F631E (a vtable/type marker), the hit is
--      inside a real CommunityShowcase struct
--   4. Struct base = hit.address - 0x20 (name field is at offset
--      0x20 in the struct, so base = hit - 0x20)
--   5. Validate structurally (startTime/endTime plausible)
--
-- The vtable marker 0x6D6F631E is the low 4 bytes of the string
-- "comm" (0x6D6F631E in little-endian) — used to
-- distinguish real struct hits from false-positive string matches
-- elsewhere in memory. It's read at hit-0x18, which is the
-- beginning of the std::string object's internal SSO buffer (the
-- string data starts at +0x8 in the string object, and the object
-- starts at name_offset - 0x8 = 0x18... actually the exact layout
-- reason is that the marker is a type tag in the struct header
-- area, not the string itself).
--
-- Same cache integration: string scan always runs, cached addresses
-- that pass validation are kept and merged.

local COMMUNITY_EVENT_NAME_HEX = "24 43 6F 6D 6D 75 6E 69 74 79 20 53 68 6F 77 63 61 73 65 00"
local COMMUNITY_EVENT_VTABLE_MARKER = 0x6D6F631E
local COMMUNITY_EVENT_NAME_OFFSET = 0x20 -- name field offset in struct
local COMMUNITY_EVENT_START_TIME_OFFSET = 0x14C
local COMMUNITY_EVENT_END_TIME_OFFSET = 0x154

---Scan process memory for the CommunityShowcase struct base address
---via string search + vtable marker validation.
---@return integer[]|nil bases, string|nil error
function M.findCommunityEventBases()
    for _, region in ipairs(M.SEARCH_REGIONS) do
        gg.clearResults()
        gg.setRanges(region)
        gg.searchNumber("h " .. COMMUNITY_EVENT_NAME_HEX, 1)
        gg.refineNumber("36", 1) -- 0x24 = 36, first byte of the name string

        local results = gg.getResults(gg.getResultsCount())
        gg.clearResults()

        if not results or #results == 0 then
            goto nextRegion
        end

        -- Batch-read vtable markers for all hits at once.
        local markerSpecs = {}
        for _, hit in ipairs(results) do
            markerSpecs[#markerSpecs + 1] = {
                address = hit.address - 0x18,
                flags = M.FLAGS.INT32
            }
        end

        local markerResults = M.readBatchChunked(markerSpecs)
        if not markerResults then
            goto nextRegion
        end

        local bases = {}
        for i, hit in ipairs(results) do
            if markerResults[i] and markerResults[i].value == COMMUNITY_EVENT_VTABLE_MARKER then
                bases[#bases + 1] = hit.address - COMMUNITY_EVENT_NAME_OFFSET
            end
        end

        if #bases > 0 then
            return bases
        end

        ::nextRegion::
    end

    return nil, "signature_not_found"
end

---Resolve the struct base of the currently-active CommunityEvent
---(startTime < now < endTime). Same caching convention as the
---other event modules — string scan always runs, cache merges.
---@return integer|nil base, string|nil error
function M.resolveActiveCommunityEventBase()
    -- String scan ALWAYS runs first.
    local scanBases, scanErr = M.findCommunityEventBases()
    if not scanBases then
        scanBases = {}
    end

    local function validateCommunityEventAddress(addr)
        if addr == nil or addr == 0 then
            return false
        end
        local marker = M.read(addr + COMMUNITY_EVENT_NAME_OFFSET - 0x18, M.FLAGS.INT32)
        return marker == COMMUNITY_EVENT_VTABLE_MARKER
    end

    local combined = resolveWithCache("community_event_addresses", scanBases, validateCommunityEventAddress)

    if #combined == 0 then
        return nil, "no_active_community_event"
    end

    -- Filter for the currently-active event
    local currentTime = os.time()
    local readList = {}
    for _, base in ipairs(combined) do
        readList[#readList + 1] = { address = base + COMMUNITY_EVENT_START_TIME_OFFSET, flags = M.FLAGS.INT32 }
        readList[#readList + 1] = { address = base + COMMUNITY_EVENT_END_TIME_OFFSET, flags = M.FLAGS.INT32 }
    end

    local readValues, readErr = M.readBatch(readList)
    if not readValues then
        return nil, readErr
    end

    for i = 1, (#readValues / 2) do
        local startTime = readValues[i * 2 - 1].value
        local endTime = readValues[i * 2].value
        if startTime ~= nil and endTime ~= nil and startTime < currentTime and currentTime < endTime then
            return combined[i]
        end
    end

    -- No active event found — if there's only one result, return it
    -- anyway (CommunityShowcase may not have startTime/endTime set
    -- the same way as PublicEvent/TeamEvent).
    if #combined == 1 then
        return combined[1]
    end

    return nil, "no_active_community_event"
end

return M

end

__vfs['core/Path.lua'] = function(...)
local M = {}

function M.parse(id)
    local segments = {}
    for part in id:gmatch("[^.]+") do
        local name, idxStr = part:match("^(.+)%[(%d+)%]$")
        if name then
            segments[#segments + 1] = { name = name, index = tonumber(idxStr) }
        else
            segments[#segments + 1] = { name = part }
        end
    end
    return segments
end

return M

end

__vfs['core/Repeated.lua'] = function(...)
local Memory = nebulaLoadModule("core/Memory.lua")
local Type   = nebulaLoadModule("core/Type.lua")
local ZeroPage = nebulaLoadModule("core/ZeroPage.lua")

local M = {}

local function log(...)
    if Nebula and Nebula.verbose then
        print("[core.Repeated]", ...)
    end
end



local DEFAULT_STRIDE = 0x8

local POINTER_ELEMENT_TYPES = {
    SafeInt32 = true,
}

local function isPointerElement(elementType)
    if POINTER_ELEMENT_TYPES[elementType] then
        return true
    end
    local INLINE_SCALARS = { Int32 = true, Bool = true, Float = true, String = true, BitMask = true, Enum = true }
    return not INLINE_SCALARS[elementType]
end

local MAX_TRUSTED_ELEMENT_COUNT = 100000

local function readHeader(baseAddress, field)
    local ptr = baseAddress + field.offset
    local stride = field.elementStride or DEFAULT_STRIDE

    if field.container == "vector" then
        local fields, readErr = Memory.readBatch({
            { address = ptr,        flags = Memory.FLAGS.INT64 },
            { address = ptr + 0x8,  flags = Memory.FLAGS.INT64 },
            { address = ptr + 0x10, flags = Memory.FLAGS.INT64 },
        })

        if not fields then
            return nil, readErr
        end

        local beginPtr  = fields[1] and fields[1].value
        local endPtr    = fields[2] and fields[2].value
        local capEndPtr = fields[3] and fields[3].value

        if beginPtr == nil or endPtr == nil then
            return nil, "header_read_failed"
        end

        if beginPtr == 0 then
            return { containerPtr = ptr, arrayPtr = 0, size = 0, capacity = 0 }
        end

        if endPtr < beginPtr then
            return nil, string.format(
                "vector_end_before_begin (begin=0x%X end=0x%X)",
                beginPtr, endPtr)
        end

        local size = math.floor((endPtr - beginPtr) / stride)
        local capacity = size
        if capEndPtr ~= nil and capEndPtr ~= 0 and capEndPtr >= beginPtr then
            capacity = math.floor((capEndPtr - beginPtr) / stride)
        end

        if size < 0 or capacity < 0 then
            return nil, "header_negative_size_or_capacity"
        end

        if size > MAX_TRUSTED_ELEMENT_COUNT or capacity > MAX_TRUSTED_ELEMENT_COUNT then
            return nil, string.format(
                "header_size_out_of_bounds (size=%d capacity=%d, max=%d)",
                size, capacity, MAX_TRUSTED_ELEMENT_COUNT)
        end

        if size > capacity then
            return nil, string.format("header_size_exceeds_capacity (size=%d capacity=%d)", size, capacity)
        end

        return { containerPtr = ptr, arrayPtr = beginPtr, size = size, capacity = capacity }
    end

    local fields, readErr = Memory.readBatch({
        { address = ptr,        flags = Memory.FLAGS.INT64 },
        { address = ptr + 0x8,  flags = Memory.FLAGS.INT32 },
        { address = ptr + 0xC,  flags = Memory.FLAGS.INT32 },
    })

    if not fields then
        return nil, readErr
    end

    local arrayPtr = fields[1] and fields[1].value
    local size     = fields[2] and fields[2].value
    local capacity = fields[3] and fields[3].value

    if arrayPtr == nil or size == nil or capacity == nil then
        return nil, "header_read_failed"
    end

    if size < 0 or capacity < 0 then
        return nil, "header_negative_size_or_capacity"
    end

    if size > MAX_TRUSTED_ELEMENT_COUNT or capacity > MAX_TRUSTED_ELEMENT_COUNT then
        return nil, string.format(
            "header_size_out_of_bounds (size=%d capacity=%d, max=%d)",
            size, capacity, MAX_TRUSTED_ELEMENT_COUNT)
    end

    if size > capacity then
        return nil, string.format("header_size_exceeds_capacity (size=%d capacity=%d)", size, capacity)
    end

    return { containerPtr = ptr, arrayPtr = arrayPtr, size = size, capacity = capacity }
end

local function readSlotPointers(header, count, stride)
    local slotSpecs = {}
    for i = 1, count do
        slotSpecs[i] = { address = header.arrayPtr + (i - 1) * stride, flags = Memory.FLAGS.INT64 }
    end
    return Memory.readBatchChunked(slotSpecs)
end

local function shadowString(field, stringDirect)
    if stringDirect and field.type == "String" and field.indirect == nil then
        return setmetatable({ indirect = false }, { __index = field })
    end
    return field
end

function M.get(baseAddress, field, preReadHeader)
    log(string.format("[get] base=0x%X type=%s elementType=%s stride=0x%X container=%s", baseAddress, tostring(field.type), tostring(field.elementType), field.elementStride or 0x8, tostring(field.container)))
    local header = preReadHeader
    if not header then
        local err
        header, err = readHeader(baseAddress, field)
        if not header then
            return nil, err
        end
    end

    if header.size <= 0 then
        return {}, nil
    end

    if header.arrayPtr == 0 then
        return nil, "null_array_ptr"
    end

    log(string.format("[get] elements path: size=%d stride=0x%X arrayPtr=0x%X", header.size, field.elementStride or 0x8, header.arrayPtr or 0))
if field.elements then
        local Struct = nebulaLoadModule("core/Struct.lua")
        local stride = field.elementStride or DEFAULT_STRIDE
        local values = {}

        if stride > DEFAULT_STRIDE then
            for i = 1, header.size do
                values[i] = Struct.get(
                    header.arrayPtr + (i - 1) * stride,
                    field.elements,
                    field.stringDirect
                )
            end
        else
            local slots, slotErr = readSlotPointers(header, header.size, stride)
            if not slots then
                return nil, slotErr
            end
            for i = 1, header.size do
                local elementPtr = slots[i] and slots[i].value
                if elementPtr and elementPtr ~= 0 then
                    values[i] = Struct.get(elementPtr, field.elements, field.stringDirect)
                else
                    values[i] = false
                end
            end
        end
        log(string.format("[get] returning %d values", #values))
return values, nil
    end

    log(string.format("[get] elementType path: type=%s size=%d stride=0x%X arrayPtr=0x%X", field.elementType, header.size, field.elementStride or 0x8, header.arrayPtr or 0))
if field.elementType then
        local elementType = field.elementType
        local stride = field.elementStride or DEFAULT_STRIDE
        local impl = Type.resolve(elementType)
        if not impl then
            return nil, "no_type_impl: " .. tostring(elementType)
        end

        local values = {}
        local pointerElements = isPointerElement(elementType)

        if pointerElements and stride == DEFAULT_STRIDE then
            local slots, slotErr = readSlotPointers(header, header.size, stride)
            if not slots then
                return nil, slotErr
            end
            for i = 1, header.size do
                local elementPtr = slots[i] and slots[i].value
                if elementPtr and elementPtr ~= 0 then
                    local f = { offset = 0, type = elementType }
                    if field.enum then f.enum = field.enum end
                    f = shadowString(f, field.stringDirect)
                    log(string.format("[get] ptr element[%d] ptr=0x%X type=%s", i-1, elementPtr, elementType))
values[i] = impl.get(elementPtr, f)
                else
                    values[i] = false
                end
            end
        elseif elementType == "String" and stride == DEFAULT_STRIDE then
            local slots, slotErr = readSlotPointers(header, header.size, DEFAULT_STRIDE)
            if not slots then
                return nil, slotErr
            end
            for i = 1, header.size do
                local elementPtr = slots[i] and slots[i].value
                if elementPtr and elementPtr ~= 0 then
                    local f = { offset = 0, type = "String", indirect = false }
                    log(string.format("[get] str slot[%d] slotAddr=0x%X elementPtr=0x%X", i-1, header.arrayPtr + (i-1)*DEFAULT_STRIDE, elementPtr))
                    values[i] = impl.get(elementPtr, f)
                else
                    values[i] = false
                end
            end
        else
            for i = 1, header.size do
                local f = { offset = (i - 1) * stride, type = elementType }
                if field.enum then f.enum = field.enum end
                -- Inline string elements are always direct (no pointer
                -- indirection) regardless of the parent struct's
                -- stringDirect flag.
                if elementType == "String" then
                    f.indirect = false
                else
                    f = shadowString(f, field.stringDirect)
                end
                log(string.format("[get] inline element[%d] offset=0x%X type=%s", i-1, (i-1)*(field.elementStride or 0x8), elementType))
values[i] = impl.get(header.arrayPtr, f)
            end
        end

        log(string.format("[get] returning %d values", #values))
return values, nil
    end

    local impl = Type.resolve(field.type)
    if not impl then
        return nil, "no_type_impl: " .. tostring(field.type)
    end

    local pointerElements = isPointerElement(field.type)
    local values = {}
    local count = 0

    if pointerElements then
        local slots, slotErr = readSlotPointers(header, header.size, DEFAULT_STRIDE)
        if not slots then
            return nil, slotErr
        end

        if impl.specs and impl.parse then
            local elementPtrs = {}
            local allSpecs = {}
            local specCounts = {}

            for i = 1, header.size do
                local elementPtr = slots[i] and slots[i].value
                elementPtrs[i] = elementPtr
                if elementPtr and elementPtr ~= 0 then
                    local elSpecs = impl.specs(elementPtr)
                    specCounts[i] = #elSpecs
                    for _, spec in ipairs(elSpecs) do
                        allSpecs[#allSpecs + 1] = spec
                    end
                else
                    specCounts[i] = 0
                end
            end

            local allResults, batchErr = Memory.readBatchChunked(allSpecs)
            if not allResults then
                return nil, batchErr
            end

            local cursor = 1
            for i = 1, header.size do
                count = count + 1
                local n = specCounts[i]
                if elementPtrs[i] and elementPtrs[i] ~= 0 and n > 0 then
                    local slice = {}
                    for j = 1, n do
                        slice[j] = allResults[cursor + j - 1]
                    end
                    cursor = cursor + n
                    local value, elErr = impl.parse(slice)
                    values[count] = value == nil and false or value
                else
                    values[count] = false
                end
            end
        else
            for i = 1, header.size do
                local elementPtr = slots[i] and slots[i].value
                count = count + 1
                if elementPtr and elementPtr ~= 0 then
                    local value, elErr = impl.get(elementPtr, { offset = 0, type = field.type, enum = field.enum })
                    values[count] = value == nil and false or value
                else
                    values[count] = false
                end
            end
        end
    else
        for i = 1, header.size do
            local value = impl.get(header.arrayPtr, { offset = i * DEFAULT_STRIDE, type = field.type, enum = field.enum })
            count = count + 1
            values[count] = value == nil and false or value
        end
    end

    log(string.format("[get] returning %d values", #values))
return values, nil
end

function M.set(baseAddress, field, values, preReadHeader)
    if type(values) ~= "table" then
        return false, "value_not_array"
    end

    local header = preReadHeader
    if not header then
        local err
        header, err = readHeader(baseAddress, field)
        if not header then
            return false, err
        end
    end

    local newSize = #values
    local stride = field.elementStride or DEFAULT_STRIDE

    if newSize > header.capacity then
        if field.container == "vector" then
            return false, "capacity_exceeded"
        end
        local allocSize = newSize * stride
        if allocSize < 8 then allocSize = 8 end
        local newArrayPtr = ZeroPage.allocate(allocSize)
        if not newArrayPtr then
            return false, "zero_page_alloc_failed"
        end
        if header.arrayPtr ~= 0 and header.size > 0 then
            local copySize = header.size * stride
            local copyOk = Memory.copyRegion(header.arrayPtr, newArrayPtr, copySize)
            if not copyOk then
                return false, "copy_region_failed"
            end
        end
        local ptrOk = Memory.write(header.containerPtr, Memory.FLAGS.INT64, newArrayPtr)
        if not ptrOk then
            return false, "container_ptr_write_failed"
        end
        header.arrayPtr = newArrayPtr
        header.capacity = newSize
    end

    if header.arrayPtr == 0 and newSize == 0 then
        return true, nil
    end

    if header.arrayPtr == 0 then
        return false, "null_array_ptr"
    end

    log(string.format("[get] elements path: size=%d stride=0x%X arrayPtr=0x%X", header.size, field.elementStride or 0x8, header.arrayPtr or 0))
if field.elements then
        local Struct = nebulaLoadModule("core/Struct.lua")
        local stride = field.elementStride or DEFAULT_STRIDE

        if stride > DEFAULT_STRIDE then
            for i = 1, newSize do
                local ok = Struct.set(
                    header.arrayPtr + (i - 1) * stride,
                    field.elements,
                    values[i],
                    field.stringDirect
                )
                if not ok then
                    return false, string.format("element_write_failed_at_index_%d", i)
                end
            end
        else
            local oldSize = header.size or 0
            local slots
            if oldSize > 0 then
                local readCount = math.min(oldSize, newSize)
                local slotErr
                slots, slotErr = readSlotPointers(header, readCount, stride)
                if not slots then
                    return false, slotErr
                end
            end
            for i = 1, newSize do
                local elementPtr
                if i <= oldSize and slots and slots[i] then
                    elementPtr = slots[i].value
                end
                if elementPtr == nil or elementPtr == 0 then
                    elementPtr = ZeroPage.allocate(0x100)
                    if not elementPtr then
                        return false, "zero_page_alloc_failed"
                    end
                    Memory.write(header.arrayPtr + (i - 1) * stride, Memory.FLAGS.INT64, elementPtr)
                end
                local ok = Struct.set(elementPtr, field.elements, values[i], field.stringDirect)
                if not ok then
                    return false, string.format("element_write_failed_at_index_%d", i)
                end
            end
        end

        if field.container ~= "vector" then
            Memory.writeBatch({
                { address = header.containerPtr + 0x8, flags = Memory.FLAGS.INT32, value = newSize },
                { address = header.containerPtr + 0xC, flags = Memory.FLAGS.INT32, value = newSize },
            })
        end

        return true, nil
    end

    log(string.format("[get] elementType path: type=%s size=%d stride=0x%X arrayPtr=0x%X", field.elementType, header.size, field.elementStride or 0x8, header.arrayPtr or 0))
if field.elementType then
        local elementType = field.elementType
        local stride = field.elementStride or DEFAULT_STRIDE
        local impl = Type.resolve(elementType)
        if not impl then
            return false, "no_type_impl: " .. tostring(elementType)
        end

        local pointerElements = isPointerElement(elementType)

        if pointerElements and stride == DEFAULT_STRIDE then
            local slots, slotErr = readSlotPointers(header, newSize, stride)
            if not slots then
                return false, slotErr
            end
            for i = 1, newSize do
                local elementPtr = slots[i] and slots[i].value
                if elementPtr == nil or elementPtr == 0 then
                    return false, string.format("null_element_ptr_at_index_%d", i)
                end
                local f = shadowString({ offset = 0, type = elementType }, field.stringDirect)
                if impl.collectWrite then
                    local cw = {}
                    if not impl.collectWrite(elementPtr, f, values[i], cw) then
                        return false, string.format("element_write_failed_at_index_%d", i)
                    end
                    if #cw > 0 and not Memory.writeBatch(cw) then
                        return false, string.format("element_write_failed_at_index_%d", i)
                    end
                else
                    if not impl.set(elementPtr, f, values[i]) then
                        return false, string.format("element_write_failed_at_index_%d", i)
                    end
                end
            end
        elseif elementType == "String" and stride == DEFAULT_STRIDE then
            local oldSize = header.size or 0
            local slots
            if oldSize > 0 then
                local readCount = math.min(oldSize, newSize)
                local slotErr
                slots, slotErr = readSlotPointers(header, readCount, DEFAULT_STRIDE)
                if not slots then
                    return false, slotErr
                end
            end
            for i = 1, newSize do
                local elementPtr
                if i <= oldSize and slots and slots[i] then
                    elementPtr = slots[i].value
                end
                if elementPtr == nil or elementPtr == 0 then
                    elementPtr = ZeroPage.allocate(0x18)
                    if not elementPtr then
                        return false, "zero_page_alloc_failed"
                    end
                    Memory.write(header.arrayPtr + (i - 1) * DEFAULT_STRIDE, Memory.FLAGS.INT64, elementPtr)
                end
                local f = { offset = 0, type = "String", indirect = false }
                if impl.collectWrite then
                    local cw = {}
                    if not impl.collectWrite(elementPtr, f, values[i], cw) then
                        return false, string.format("element_write_failed_at_index_%d", i)
                    end
                    if #cw > 0 and not Memory.writeBatch(cw) then
                        return false, string.format("element_write_failed_at_index_%d", i)
                    end
                else
                    if not impl.set(elementPtr, f, values[i]) then
                        return false, string.format("element_write_failed_at_index_%d", i)
                    end
                end
            end
        else
            for i = 1, newSize do
                local f = { offset = (i - 1) * stride, type = elementType }
                if elementType == "String" then
                    -- Inline std::string elements are always direct.
                    f.indirect = false
                else
                    f = shadowString(f, field.stringDirect)
                end
                if impl.collectWrite then
                    local cw = {}
                    if not impl.collectWrite(header.arrayPtr, f, values[i], cw) then
                        return false, string.format("element_write_failed_at_index_%d", i)
                    end
                    if #cw > 0 and not Memory.writeBatch(cw) then
                        return false, string.format("element_write_failed_at_index_%d", i)
                    end
                else
                    if not impl.set(header.arrayPtr, f, values[i]) then
                        return false, string.format("element_write_failed_at_index_%d", i)
                    end
                end
            end
        end

        if field.container ~= "vector" then
            Memory.writeBatch({
                { address = header.containerPtr + 0x8, flags = Memory.FLAGS.INT32, value = newSize },
                { address = header.containerPtr + 0xC, flags = Memory.FLAGS.INT32, value = newSize },
            })
        end

        return true, nil
    end

    local impl = Type.resolve(field.type)
    if not impl then
        return false, "no_type_impl: " .. tostring(field.type)
    end

    local pointerElements = isPointerElement(field.type)

    if pointerElements then
        local slots, slotErr = readSlotPointers(header, newSize, DEFAULT_STRIDE)
        if not slots then
            return false, slotErr
        end
        for i = 1, newSize do
            local elementPtr = slots[i] and slots[i].value
            if elementPtr == nil or elementPtr == 0 then
                return false, string.format("null_element_ptr_at_index_%d", i)
            end
            local ok = impl.set(elementPtr, { offset = 0, type = field.type, enum = field.enum }, values[i])
            if not ok then
                return false, string.format("element_write_failed_at_index_%d", i)
            end
        end
    else
        for i = 1, newSize do
            local ok = impl.set(header.arrayPtr, { offset = (i - 1) * DEFAULT_STRIDE, type = field.type, enum = field.enum }, values[i])
            if not ok then
                return false, string.format("element_write_failed_at_index_%d", i)
            end
        end
    end

    if field.container ~= "vector" then
        Memory.writeBatch({
            { address = header.containerPtr + 0x8, flags = Memory.FLAGS.INT32, value = newSize },
            { address = header.containerPtr + 0xC, flags = Memory.FLAGS.INT32, value = newSize },
        })
    end

    return true, nil
end

function M.readHeaderForSet(baseAddress, field)
    return readHeader(baseAddress, field)
end

function M.setWithHeader(baseAddress, field, values, header, writes)
    if type(values) ~= "table" then
        return false
    end

    local newSize = #values
    local stride = field.elementStride or DEFAULT_STRIDE

    if newSize > header.capacity then
        if field.container == "vector" then
            return false
        end
        local allocSize = newSize * stride
        if allocSize < 8 then allocSize = 8 end
        local newArrayPtr = ZeroPage.allocate(allocSize)
        if not newArrayPtr then
            return false
        end
        if header.arrayPtr ~= 0 and header.size > 0 then
            local copySize = header.size * stride
            local copyOk = Memory.copyRegion(header.arrayPtr, newArrayPtr, copySize)
            if not copyOk then return false end
        end
        writes[#writes + 1] = { address = header.containerPtr, flags = Memory.FLAGS.INT64, value = newArrayPtr }
        header.arrayPtr = newArrayPtr
        header.capacity = newSize
    end

    if header.arrayPtr == 0 and newSize == 0 then
        return true
    end

    if header.arrayPtr == 0 then
        return false
    end

    log(string.format("[get] elements path: size=%d stride=0x%X arrayPtr=0x%X", header.size, field.elementStride or 0x8, header.arrayPtr or 0))
if field.elements then
        local Struct = nebulaLoadModule("core/Struct.lua")
        local stride = field.elementStride or DEFAULT_STRIDE

        if stride > DEFAULT_STRIDE then
            for i = 1, newSize do
                local ok = Struct.set(
                    header.arrayPtr + (i - 1) * stride,
                    field.elements,
                    values[i],
                    field.stringDirect,
                    writes
                )
                if not ok then return false end
            end
        else
            local oldSize = header.size or 0
            local slots
            if oldSize > 0 then
                local readCount = math.min(oldSize, newSize)
                local slotErr
                slots, slotErr = readSlotPointers(header, readCount, stride)
                if not slots then return false end
            end
            for i = 1, newSize do
                local elementPtr
                if i <= oldSize and slots and slots[i] then
                    elementPtr = slots[i].value
                end
                if elementPtr == nil or elementPtr == 0 then
                    elementPtr = ZeroPage.allocate(0x100)
                    if not elementPtr then return false end
                    writes[#writes + 1] = { address = header.arrayPtr + (i - 1) * stride, flags = Memory.FLAGS.INT64, value = elementPtr }
                end
                local ok = Struct.set(elementPtr, field.elements, values[i], field.stringDirect, writes)
                if not ok then return false end
            end
        end

        if field.container ~= "vector" then
            writes[#writes + 1] = { address = header.containerPtr + 0x8, flags = Memory.FLAGS.INT32, value = newSize }
            writes[#writes + 1] = { address = header.containerPtr + 0xC, flags = Memory.FLAGS.INT32, value = newSize }
        end
        return true
    end

    log(string.format("[get] elementType path: type=%s size=%d stride=0x%X arrayPtr=0x%X", field.elementType, header.size, field.elementStride or 0x8, header.arrayPtr or 0))
if field.elementType then
        local elementType = field.elementType
        local stride = field.elementStride or DEFAULT_STRIDE
        local impl = Type.resolve(elementType)
        if not impl then return false end

        local pointerElements = isPointerElement(elementType)

        if pointerElements and stride == DEFAULT_STRIDE then
            local slots, slotErr = readSlotPointers(header, newSize, stride)
            if not slots then return false end
            for i = 1, newSize do
                local elementPtr = slots[i] and slots[i].value
                if elementPtr == nil or elementPtr == 0 then
                    return false
                end
                local f = shadowString({ offset = 0, type = elementType }, field.stringDirect)
                if impl.collectWrite then
                    if not impl.collectWrite(elementPtr, f, values[i], writes) then return false end
                else
                    if not impl.set(elementPtr, f, values[i]) then return false end
                end
            end
        elseif elementType == "String" and stride == DEFAULT_STRIDE then
            local oldSize = header.size or 0
            local slots
            if oldSize > 0 then
                local readCount = math.min(oldSize, newSize)
                local slotErr
                slots, slotErr = readSlotPointers(header, readCount, DEFAULT_STRIDE)
                if not slots then return false end
            end
            for i = 1, newSize do
                local elementPtr
                if i <= oldSize and slots and slots[i] then
                    elementPtr = slots[i].value
                end
                if elementPtr == nil or elementPtr == 0 then
                    elementPtr = ZeroPage.allocate(0x18)
                    if not elementPtr then return false end
                    writes[#writes + 1] = { address = header.arrayPtr + (i - 1) * DEFAULT_STRIDE, flags = Memory.FLAGS.INT64, value = elementPtr }
                end
                local f = { offset = 0, type = "String", indirect = false }
                if impl.collectWrite then
                    if not impl.collectWrite(elementPtr, f, values[i], writes) then return false end
                else
                    if not impl.set(elementPtr, f, values[i]) then return false end
                end
            end
        else
            for i = 1, newSize do
                local f = { offset = (i - 1) * stride, type = elementType }
                if elementType == "String" then
                    -- Inline std::string elements are always direct.
                    f.indirect = false
                else
                    f = shadowString(f, field.stringDirect)
                end
                if impl.collectWrite then
                    if not impl.collectWrite(header.arrayPtr, f, values[i], writes) then return false end
                else
                    if not impl.set(header.arrayPtr, f, values[i]) then return false end
                end
            end
        end

        if field.container ~= "vector" then
            writes[#writes + 1] = { address = header.containerPtr + 0x8, flags = Memory.FLAGS.INT32, value = newSize }
            writes[#writes + 1] = { address = header.containerPtr + 0xC, flags = Memory.FLAGS.INT32, value = newSize }
        end
        return true
    end

    local impl = Type.resolve(field.type)
    if not impl then return false end

    local pointerElements = isPointerElement(field.type)

    if pointerElements then
        local slots, slotErr = readSlotPointers(header, newSize, DEFAULT_STRIDE)
        if not slots then return false end
        for i = 1, newSize do
            local elementPtr = slots[i] and slots[i].value
            if elementPtr == nil or elementPtr == 0 then return false end
            if not impl.set(elementPtr, { offset = 0, type = field.type, enum = field.enum }, values[i]) then return false end
        end
    else
        for i = 1, newSize do
            if not impl.set(header.arrayPtr, { offset = (i - 1) * DEFAULT_STRIDE, type = field.type, enum = field.enum }, values[i]) then return false end
        end
    end

    if field.container ~= "vector" then
        writes[#writes + 1] = { address = header.containerPtr + 0x8, flags = Memory.FLAGS.INT32, value = newSize }
        writes[#writes + 1] = { address = header.containerPtr + 0xC, flags = Memory.FLAGS.INT32, value = newSize }
    end
    return true
end

return M

end

__vfs['core/Struct.lua'] = function(...)
--==================================================
-- core/Struct.lua
--==================================================
-- Reads/writes a struct element using a metadata template
-- (the `elements` sub-table on an Array field). Called by
-- core/Repeated.lua when a repeated field's slots point to struct
-- elements rather than inline scalars.
--
-- Node shapes from the metadata template:
--
-- LEAF FIELD — has `type` (string) and `offset`, no child
-- sub-tables with their own offsets:
--   { offset = 0x20, type = "Int32" }
--
-- ARRAY FIELD — has `type = "Array"`, `offset`, AND either
-- `elements` (struct-element template) or `elementType` +
-- `elementStride` (simple typed elements). Dispatched to
-- Repeated.get/set with a vector container shadow.
--
--   Array fields WITHOUT `elements` or `elementType` are skipped
--   (no reader available).
--
-- POINTER-BACKED CONTAINER — has `type` (string, not "Array"),
-- `offset`, AND child fields. Dereference base+offset, recurse.
--
-- NAMESPACE CONTAINER — no `type`, children at same base. Recurse.
--
-- Performance: Struct.get batch-reads ALL Array vector headers in
-- a single gg.getValues call before dispatching. This avoids
-- ~196 individual reads per eventRewards scan (14 rewards × 14
-- nested arrays = 196 reads at ~180ms each = 35s without batching).
-- With batching: 14 reads (one batch per reward element) = ~2s.
--
-- String indirection: caller passes `stringDirect = true` for C++
-- struct ABI (inline strings). Struct.get shadows String fields
-- with indirect=false.
--
-- Zero-value suppression: scalar fields with value 0/0.0/"" are
-- omitted. Bool values are never suppressed. Empty arrays (size=0)
-- are omitted for cleaner output. Empty containers (no readable
-- fields) are also omitted.

local Memory = nebulaLoadModule("core/Memory.lua")
local Type   = nebulaLoadModule("core/Type.lua")
local ZeroPage = nebulaLoadModule("core/ZeroPage.lua")

local M = {}

local function log(...)
    if Nebula and Nebula.verbose then
        print("[core.Struct]", ...)
    end
end



local typeCache = {}
local function resolveType(name)
    if typeCache[name] == nil then
        typeCache[name] = Type.resolve(name)
    end
    return typeCache[name]
end

local DEFAULT_STRIDE = 0x8

---Check if a node has child field definitions.
local function hasChildren(node)
    for _, v in pairs(node) do
        if type(v) == "table" and type(v.offset) == "number" then
            return true
        end
    end
    return false
end

---Check if a field's offset is known (not 0xBAAD).
local function isOffsetKnown(field)
    return field.offset ~= nil and field.offset ~= 0xBAAD
end

---Check if an Array field has the metadata needed to read elements.
local function isReadableArray(field)
    return field.elements ~= nil or field.elementType ~= nil
end

---Shadow a String field with indirect=false.
local function shadowString(field, stringDirect)
    if stringDirect and field.type == "String" and field.indirect == nil then
        return setmetatable({ indirect = false }, { __index = field })
    end
    return field
end

---Build a shadow for an Array field inside a struct template.
local function shadowArray(field, stringDirect)
    local shadow = { stringDirect = stringDirect }
    return setmetatable(shadow, { __index = field })
end

---Check if a scalar value should be suppressed (0, 0.0, "").
local function isEmptyValue(field, value)
    if value == nil then return true end
    if field.type == "Bool" then return false end
    if field.type == "Enum" then return false end
    if field.type == "Int32" then return false end
    if field.type == "SafeInt32" then return false end
    if type(value) == "number" then return value == 0 end
    if type(value) == "string" then return value == "" end
    return false
end

---Check if a table is empty (no key-value pairs).
local function isEmptyTable(t)
    return t == nil or next(t) == nil
end

---Pre-read batch: collect all Array field vector headers in one
---gg.getValues call. Returns a map of key → {beginPtr, endPtr, capEndPtr}.
local function batchReadArrayHeaders(base, template, stringDirect)
    local specs = {}
    local meta = {}

    for key, field in pairs(template) do
        if type(field) == "table"
           and type(field.type) == "string"
           and field.type == "Array"
           and isOffsetKnown(field)
           and isReadableArray(field) then
            local ptr = base + field.offset
            local idx = #specs
            local isVector = stringDirect or field.container == "vector"
            if isVector then
                specs[idx + 1] = { address = ptr,        flags = Memory.FLAGS.INT64 }
                specs[idx + 2] = { address = ptr + 0x8,  flags = Memory.FLAGS.INT64 }
                specs[idx + 3] = { address = ptr + 0x10, flags = Memory.FLAGS.INT64 }
                meta[#meta + 1] = { key = key, offset = idx + 1, vector = true }
            else
                specs[idx + 1] = { address = ptr,       flags = Memory.FLAGS.INT64 }
                specs[idx + 2] = { address = ptr + 0x8, flags = Memory.FLAGS.INT32 }
                specs[idx + 3] = { address = ptr + 0xC, flags = Memory.FLAGS.INT32 }
                meta[#meta + 1] = { key = key, offset = idx + 1, vector = false }
            end
        end
    end

    local result = {}
    if #specs == 0 then
        return result
    end

    local values, err = Memory.readBatch(specs)
    if not values then
        return result
    end

    for _, m in ipairs(meta) do
        if m.vector then
            result[m.key] = {
                beginPtr  = values[m.offset]     and values[m.offset].value     or 0,
                endPtr    = values[m.offset + 1] and values[m.offset + 1].value or 0,
                capEndPtr = values[m.offset + 2] and values[m.offset + 2].value or 0,
            }
        else
            local arrayPtr = values[m.offset]     and values[m.offset].value     or 0
            local size     = values[m.offset + 1] and values[m.offset + 1].value or 0
            local capacity = values[m.offset + 2] and values[m.offset + 2].value or 0
            result[m.key] = {
                containerPtr = base + template[m.key].offset,
                arrayPtr  = arrayPtr,
                size      = size,
                capacity  = capacity,
            }
        end
    end

    return result
end

---Build a Repeated-compatible header from pre-read pointers.
local function buildPreHeader(field, base, beginPtr, endPtr, capEndPtr)
    local ptr = base + field.offset
    local stride = field.elementStride or DEFAULT_STRIDE

    if beginPtr == 0 or endPtr == 0 or endPtr < beginPtr then
        return { containerPtr = ptr, arrayPtr = 0, size = 0, capacity = 0 }
    end

    local size = math.floor((endPtr - beginPtr) / stride)
    local capacity = size
    if capEndPtr ~= 0 and capEndPtr >= beginPtr then
        capacity = math.floor((capEndPtr - beginPtr) / stride)
    end

    if size < 0 then size = 0 end
    if capacity < size then capacity = size end

    return { containerPtr = ptr, arrayPtr = beginPtr, size = size, capacity = capacity }
end

--==================================================
-- get()
--==================================================

function M.get(base, template, stringDirect)
    log(string.format("[get] base=0x%X stringDirect=%s", base, tostring(stringDirect)))
    local result = {}

    -- Pre-pass: batch-read all readable Array vector headers in
    -- one gg.getValues call.
    local preReadHeaders = batchReadArrayHeaders(base, template, stringDirect)

    for key, field in pairs(template) do
        if type(field) == "table" then
            local container = hasChildren(field)

            if type(field.type) == "string" and field.type == "Array" then
                if isOffsetKnown(field) and isReadableArray(field) then
                    local h = preReadHeaders[key]
                    if h then
                        local preHeader
                        if h.beginPtr ~= nil then
                            if h.beginPtr ~= 0 and h.endPtr > h.beginPtr then
                                preHeader = buildPreHeader(field, base,
                                    h.beginPtr, h.endPtr, h.capEndPtr)
                            end
                        else
                            if h.arrayPtr ~= 0 and h.size > 0 then
                                preHeader = h
                            end
                        end
                        if preHeader and preHeader.size > 0 then
                            local Repeated = nebulaLoadModule("core/Repeated.lua")
                            local shadow = shadowArray(field, stringDirect)
                            local arrResult = Repeated.get(base, shadow, preHeader)
                            if arrResult and not isEmptyTable(arrResult) then
                                result[key] = arrResult
                            end
                        end
                    end
                end

            elseif type(field.type) == "string" and container then
                -- Pointer-backed container (e.g. lootDefinition)
                if isOffsetKnown(field) then
                    local ptr = Memory.deref(base, field.offset)
                    if ptr and ptr ~= 0 then
                        local subResult = M.get(ptr, field, stringDirect)
                        -- Only include non-empty containers
                        if not isEmptyTable(subResult) then
                            result[key] = subResult
                        end
                    end
                end

            elseif type(field.type) == "string" then
                -- Leaf field
                if isOffsetKnown(field) then
                    local impl = resolveType(field.type)
                    if impl then
                        local f = shadowString(field, stringDirect)
                        local value = impl.get(base, f)
                        if not isEmptyValue(field, value) then
                            result[key] = value
                        end
                    end
                end

            elseif container then
                -- Namespace container
                local subResult = M.get(base, field, stringDirect)
                if not isEmptyTable(subResult) then
                    result[key] = subResult
                end
            end
        end
    end
    return result
end

--==================================================
-- set()
--==================================================

local function collectWrites(base, template, values, stringDirect, writes)
    if type(values) ~= "table" then
        return false
    end

    local allOk = true

    for key, value in pairs(values) do
        local field = template[key]
        if type(field) == "table" then
            local container = hasChildren(field)

            if type(field.type) == "string" and field.type == "Array" then
                if isOffsetKnown(field) and isReadableArray(field) then
                    local Repeated = nebulaLoadModule("core/Repeated.lua")
                    local shadow = shadowArray(field, stringDirect)
                    local header, hErr = Repeated.readHeaderForSet(base, shadow)
                    if not header then
                        allOk = false
                    else
                        local ok2 = Repeated.setWithHeader(base, shadow, value, header, writes)
                        if not ok2 then
                            allOk = false
                        end
                    end
                end

            elseif type(field.type) == "string" and container then
                if isOffsetKnown(field) then
                    local ptr = Memory.deref(base, field.offset)
                    local needsAlloc = not ptr or ptr == 0
                    if needsAlloc then
                        ptr = ZeroPage.allocate(0x100)
                        if ptr then
                            writes[#writes + 1] = { address = base + field.offset, flags = Memory.FLAGS.INT64, value = ptr }
                        end
                    end
                    if ptr and ptr ~= 0 then
                        if not collectWrites(ptr, field, value, stringDirect, writes) then
                            allOk = false
                        end
                    else
                        allOk = false
                    end
                end

            elseif type(field.type) == "string" then
                if isOffsetKnown(field) then
                    local impl = resolveType(field.type)
                    if impl then
                        local f = shadowString(field, stringDirect)
                        if impl.collectWrite then
                            if not impl.collectWrite(base, f, value, writes) then
                                allOk = false
                            end
                        else
                            if not impl.set(base, f, value) then
                                allOk = false
                            end
                        end
                    end
                end

            elseif container then
                if not collectWrites(base, field, value, stringDirect, writes) then
                    allOk = false
                end
            end
        end
    end

    return allOk
end

function M.set(base, template, values, stringDirect, outWrites)
    log(string.format("[set] base=0x%X stringDirect=%s outWrites=%s", base, tostring(stringDirect), tostring(outWrites ~= nil)))
    if type(values) ~= "table" then
        return false
    end

    local writes = outWrites or {}
    local ok = collectWrites(base, template, values, stringDirect, writes)

    if not outWrites and #writes > 0 then
        local wbOk = Memory.writeBatch(writes)
        if not wbOk then
            if Nebula and Nebula.log then
                print("[Struct.set] writeBatch FAILED, " .. #writes .. " writes")
                for i, w in ipairs(writes) do
                    print(string.format("  [%d] addr=0x%X flags=%d val=%s", i, w.address, w.flags, tostring(w.value)))
                end
            end
            ok = false
        end
    end

    return ok
end

return M

end

__vfs['core/Type.lua'] = function(...)
--==================================================
-- core/Type.lua
--==================================================
-- Central registry mapping metadata `type` strings to their
-- get/set implementation modules. Adding a new type = add a file
-- to core/types/ and register it here.

local M = {}

local registry = {
    Int32       = nebulaLoadModule("core/types/Int32.lua"),
    SafeInt32   = nebulaLoadModule("core/types/SafeInt32.lua"),
    Bool        = nebulaLoadModule("core/types/Bool.lua"),
    Float       = nebulaLoadModule("core/types/Float.lua"),
    String      = nebulaLoadModule("core/types/String.lua"),
    BitMask     = nebulaLoadModule("core/types/BitMask.lua"),
    Enum        = nebulaLoadModule("core/types/Enum.lua"),
}

---@param typeName string
---@return table|nil implementation
function M.resolve(typeName)
    return registry[typeName]
end

---Register a new type implementation at runtime (for modules that
---want to extend Nebula without editing this file).
---@param typeName string
---@param implementation table @ must expose get(base, field) and set(base, field, value)
function M.register(typeName, implementation)
    registry[typeName] = implementation
end

return M

end

__vfs['core/ZeroPage.lua'] = function(...)
local Memory = nebulaLoadModule("core/Memory.lua")

--==================================================
-- core/ZeroPage.lua
--==================================================
-- Bump-allocator for scratch memory, using alloc.lua's
-- safe region-selection logic.
--
-- Safety rules (from alloc.lua):
--   - Only rw-p (read/write private) regions
--   - Skip .bss, .data, [stack], [heap], thread stacks,
--     signal stacks — all look empty but are live game memory
--   - Verify zeros with gg.getValues, not gg.searchNumber
--   - Track claimed regions to prevent double-allocation
--
-- The bump allocator hands out 8-byte-aligned addresses
-- from a found zero region. When the cursor exceeds the
-- region, it re-probes for a fresh one.

local M = {}

local function log(...)
    if Nebula and Nebula.verbose then
        print("[core.ZeroPage]", ...)
    end
end



local DEFAULT_REGION_BYTES = 2048
local MIN_REGION_BYTES     = 256

local zeroPageBase   = nil
local zeroPageCursor = 0
local zeroPageSize   = 0
local _claimed       = {}

-- Returns true for regions that are unsafe to write into.
-- Only rw-p (read/write private) pages are safe.
local function isDangerousRegion(region)
    local perms = region.type or ""
    if perms ~= "" and perms ~= "rw-p" then
        return true
    end
    local name         = region.name         or ""
    local internalName = region.internalName or ""
    if name:match("%.bss") or internalName:match(":bss") then
        return true
    end
    if name:match("%.data") or internalName:match(":data") then
        return true
    end
    if name:match("%[stack%]")
        or name:match("stack_and_tls")
        or name:match("signal stack")
        or internalName:match("stack_and_tls")
        or internalName:match("signal stack")
        or name:match("%[heap%]") then
        return true
    end
    return false
end

local function isClaimed(base, size)
    for claimedBase, info in pairs(_claimed) do
        local claimedEnd = claimedBase + info.size
        local reqEnd     = base + size
        if base < claimedEnd and reqEnd > claimedBase then
            return true
        end
    end
    return false
end

-- Verify that a range of memory is all zeros using gg.getValues.
-- Reads in chunks to avoid GG batch limits.
local function verifyZeros(base, byteCount)
    local step   = 4   -- DWORD step
    local slots  = {}
    local addr   = base
    while addr < base + byteCount do
        slots[#slots + 1] = { address = addr, flags = 4 }
        addr = addr + step
    end
    if #slots == 0 then return true end
    local results = gg.getValues(slots)
    if not results then return false end
    for _, v in ipairs(results) do
        if v.value ~= 0 then return false end
    end
    return true
end

-- Find a safe zero region using gg.getRangesList.
-- Tries progressively smaller region sizes until one is found.
local function findZeroRegion(desiredBytes)
    desiredBytes = desiredBytes or DEFAULT_REGION_BYTES
    local regions = gg.getRangesList()

    -- Try the desired size first, then shrink by half each round
    local sizes = { desiredBytes }
    local s = desiredBytes
    while s > MIN_REGION_BYTES do
        s = math.floor(s / 2)
        sizes[#sizes + 1] = s
    end

    for _, regionBytes in ipairs(sizes) do
        local dwords = math.floor(regionBytes / 4)
        if dwords >= 8 then  -- need at least 32 bytes
            for _, region in ipairs(regions) do
                local regionSize = region["end"] - region.start

                if (region.state == "O" or region.state == "Ca")
                   and not isDangerousRegion(region)
                   and regionSize >= regionBytes then

                    local base = region.start
                    local rem = base % 8
                    if rem ~= 0 then base = base + (8 - rem) end

                    if base + regionBytes <= region["end"]
                       and not isClaimed(base, regionBytes) then

                        if verifyZeros(base, regionBytes) then
                            _claimed[base] = { size = regionBytes }
                            return base, regionBytes
                        end
                    end
                end
            end
        end
    end

    return nil, 0
end

function M.allocate(size)
    size = (size + 7) & ~7  -- align to 8 bytes

    if zeroPageBase == nil
       or zeroPageCursor + size > zeroPageSize then
        local desired = math.max(size * 4, DEFAULT_REGION_BYTES)
        zeroPageBase, zeroPageSize = findZeroRegion(desired)
        zeroPageCursor = 0
        if zeroPageBase == nil then
            zeroPageBase, zeroPageSize = findZeroRegion(size)
            zeroPageCursor = 0
            if zeroPageBase == nil then
                return nil
            end
        end
    end

    local addr = zeroPageBase + zeroPageCursor
    zeroPageCursor = zeroPageCursor + size
    return addr
end

function M._status()
    return {
        base   = zeroPageBase,
        cursor = zeroPageCursor,
        size   = zeroPageSize,
        claimed = (function()
            local n = 0
            for _ in pairs(_claimed) do n = n + 1 end
            return n
        end)()
    }
end

return M

end

__vfs['core/types/Achievement.lua'] = function(...)
--==================================================
-- core/types/Achievement.lua
--==================================================
-- message Achievement {
--   required int32 id = 1;
--   required bool unlocked = 2;
--   optional int32 steps = 3;
-- }
--
-- Struct layout (fields relative to the element's own base — for
-- repeated fields, that's the element pointer itself, offset 0):
--
--   base + 0x18  id        (int32)
--   base + 0x1C  unlocked  (bool, 1 byte)
--   base + 0x20  steps     (int32)
--
-- Unlike scalar/String/SafeInt32 type modules, this one doesn't
-- use field.offset directly — `field` here is the synthetic
-- { offset = 0, type = "Achievement" } passed in by
-- core/Repeated.lua, since each array slot already points straight
-- at the element struct. get()/set() return/accept a plain Lua
-- table: { id = ..., unlocked = ..., steps = ... }.
--
-- Also implements the optional M.specs(base)/M.parse(results) pair
-- so core/Repeated.lua can batch every element's reads into one
-- cross-element gg.getValues call instead of one call per element.
-- See core/Repeated.lua's batchGetElements() for how this is used.

local Memory = nebulaLoadModule("core/Memory.lua")

local M = {}

local function log(...)
    if Nebula and Nebula.verbose then
        print("[core.types.Achievement]", ...)
    end
end



local FIELD_ID_OFF       = 0x18
local FIELD_UNLOCKED_OFF = 0x1C
local FIELD_STEPS_OFF    = 0x20

---Optional batch-read descriptor: given an element base, describe
---the {address, flags} specs needed to read this element, in a
---fixed order, without doing any actual I/O. core/Repeated.lua
---uses this (when present) to collect every element's field specs
---into one big cross-element readBatch instead of calling get()
---once per element — cutting N round-trips down to 1 for an
---N-element array. Falls back to per-element M.get() when a type
---doesn't implement this.
---@param base integer
---@return table specs @ array of { address, flags }
function M.specs(base)
    return {
        { address = base + FIELD_ID_OFF,       flags = Memory.FLAGS.INT32 },
        { address = base + FIELD_UNLOCKED_OFF, flags = Memory.FLAGS.BYTE },
        { address = base + FIELD_STEPS_OFF,    flags = Memory.FLAGS.INT32 },
    }
end

---Parse a slice of already-fetched readBatch results (in the same
---order M.specs() described them) into this type's value shape.
---Used alongside M.specs() for batch reads; independent of get().
---@param results table @ slice of gg.getValues-style results, same order as specs()
---@return table|nil value, string|nil error
function M.parse(results)
    local id       = results[1] and results[1].value
    local unlocked = results[2] and results[2].value
    local steps    = results[3] and results[3].value

    if id == nil or unlocked == nil then
        return nil, "read_failed"
    end

    return {
        id       = id,
        unlocked = (unlocked & 0xFF) ~= 0,
        steps    = steps,
    }
end

---@param base integer @ pointer to the Achievement struct itself
---@param field table @ unused offset (struct starts at base+0), kept for interface consistency
---@return table|nil value, string|nil error
function M.get(base, field)
    local fields, err = Memory.readBatch(M.specs(base))
    if not fields then
        return nil, err
    end
    return M.parse(fields)
end

---@param base integer @ pointer to the Achievement struct itself
---@param field table @ unused offset, kept for interface consistency
---@param value table @ { id, unlocked, steps }
---@return boolean ok
function M.set(base, field, value)
    if type(value) ~= "table" then
        return false
    end

    local writes = {}

    if value.id ~= nil then
        writes[#writes + 1] = { address = base + FIELD_ID_OFF, flags = Memory.FLAGS.INT32, value = math.floor(value.id) }
    end

    if value.unlocked ~= nil then
        writes[#writes + 1] = { address = base + FIELD_UNLOCKED_OFF, flags = Memory.FLAGS.BYTE, value = value.unlocked and 1 or 0 }
    end

    if value.steps ~= nil then
        writes[#writes + 1] = { address = base + FIELD_STEPS_OFF, flags = Memory.FLAGS.INT32, value = math.floor(value.steps) }
    end

    if #writes == 0 then
        return false
    end

    return Memory.writeBatch(writes)
end

return M

end

__vfs['core/types/Array.lua'] = function(...)


local function log(...)
    if Nebula and Nebula.verbose then
        print("[core.types.Array]", ...)
    end
end


end

__vfs['core/types/BitMask.lua'] = function(...)
local BitMask = {}


local function log(...)
    if Nebula and Nebula.verbose then
        print("[core.types.BitMask]", ...)
    end
end

BitMask.__index = BitMask

local function loadEnum(field)
    if type(field.enum) == "table" then
        return field.enum
    end

    return nebulaLoadModule("metadata/enums/" .. field.enum .. ".lua")
end

function BitMask.new(value, enum)
    return setmetatable({
        _value = value or 0,
        _enum = enum,
    }, BitMask)
end

function BitMask:value()
    return self._value
end

function BitMask:has(name)
    local flag = self._enum[name]
    assert(flag, ("Unknown flag '%s'"):format(name))

    return (self._value & flag) ~= 0
end

function BitMask:enable(name)
    local flag = self._enum[name]
    assert(flag, ("Unknown flag '%s'"):format(name))

    self._value = self._value | flag
    return self
end

function BitMask:disable(name)
    local flag = self._enum[name]
    assert(flag, ("Unknown flag '%s'"):format(name))

    self._value = self._value & (~flag)
    return self
end

function BitMask:toggle(name)
    local flag = self._enum[name]
    assert(flag, ("Unknown flag '%s'"):format(name))

    self._value = self._value ~ flag
    return self
end

function BitMask.get(base, field)
    local Int32 = Nebula.Type.resolve("Int32")
    local value = Int32.get(base, field)
    return BitMask.new(value, loadEnum(field))
end

function BitMask.set(base, field, value)
    if getmetatable(value) == BitMask then
        value = value:value()
    end

    local Int32 = Nebula.Type.resolve("Int32")
    return Int32.set(base, field, value)
end

return BitMask
end

__vfs['core/types/Bool.lua'] = function(...)
--==================================================
-- core/types/Bool.lua
--==================================================
-- Single-byte boolean field (proto2 `bool`). Stored as 0x00/0x01.

local Memory = nebulaLoadModule("core/Memory.lua")

local M = {}

local function log(...)
    if Nebula and Nebula.verbose then
        print("[core.types.Bool]", ...)
    end
end



---@param baseAddress integer
---@param field table
---@return boolean|nil value, string|nil error
function M.get(baseAddress, field)
    local raw, err = Memory.read(baseAddress + field.offset, Memory.FLAGS.BYTE)
    if raw == nil then
        return nil, err
    end
    return raw ~= 0
end

---@param baseAddress integer
---@param field table
---@param value boolean
---@return boolean ok
function M.set(baseAddress, field, value)
    if type(value) ~= "boolean" then
        return false
    end
    function M.collectWrite(baseAddress, field, value, writes)
    if type(value) == "boolean" then
        writes[#writes + 1] = { address = baseAddress + field.offset, flags = Memory.FLAGS.BYTE, value = value and 1 or 0 }
    end
end

return Memory.write(baseAddress + field.offset, Memory.FLAGS.BYTE, value and 1 or 0)
end

function M.collectWrite(baseAddress, field, value, writes)
    if type(value) == "boolean" then
        writes[#writes + 1] = { address = baseAddress + field.offset, flags = Memory.FLAGS.BYTE, value = value and 1 or 0 }
    end
end

return M

end

__vfs['core/types/Enum.lua'] = function(...)
--==================================================
-- core/types/Enum.lua
--==================================================
-- Int32 field backed by a bidirectional enum mapping. Reads an
-- Int32 from memory and converts to the schema string name; writes
-- a string name back as the Int32 enum value.
--
-- The enum table is loaded from metadata/enums/<field.enum>.lua
-- (or used inline if field.enum is a table). It must expose:
--   byId[number]   → string name
--   byName[string] → number id
--
-- Metadata usage:
--   { offset = 0x18, type = "Enum", enum = "ChestType" }
--
-- get returns the string name (e.g. "rare") or the raw number
-- if the ID is not in the enum table.
-- set accepts either the string name or the raw number.

local Memory = nebulaLoadModule("core/Memory.lua")

local M = {}

local function log(...)
    if Nebula and Nebula.verbose then
        print("[core.types.Enum]", ...)
    end
end



local function loadEnum(field)
    if type(field.enum) == "table" then
        return field.enum
    end
    if not field.enum then
        return { byId = {}, byName = {} }
    end
    return nebulaLoadModule("metadata/enums/" .. field.enum .. ".lua")
end

---@param baseAddress integer
---@param field table @ { offset, enum } from metadata
---@return string|integer|nil value, string|nil error
function M.get(baseAddress, field)
    local raw, err = Memory.read(baseAddress + field.offset, Memory.FLAGS.INT32)
    if err then return nil, err end
    if raw == 0 and field.allowZero == false then
        return nil, nil
    end

    local enum = loadEnum(field)
    local name = enum.byId and enum.byId[raw]
    if name ~= nil then
        return name
    end
    -- Unknown ID: return the raw number so caller can see it
    return raw
end

---@param baseAddress integer
---@param field table
---@param value string|integer @ enum name or raw Int32
---@return boolean ok
function M.set(baseAddress, field, value)
    local raw

    if type(value) == "string" then
        local enum = loadEnum(field)
        raw = enum.byName and enum.byName[value]
        if raw == nil then
            error(("Enum: unknown name '%s'"):format(value))
        end
    elseif type(value) == "number" then
        raw = math.floor(value)
    else
        return false
    end

    function M.collectWrite(baseAddress, field, value, writes)
    local raw
    if type(value) == "string" then
        local enum = loadEnum(field)
        raw = enum.byName and enum.byName[value]
        if raw == nil then return end
    elseif type(value) == "number" then
        raw = math.floor(value)
    else
        return
    end
    writes[#writes + 1] = { address = baseAddress + field.offset, flags = Memory.FLAGS.INT32, value = raw }
end

return Memory.write(baseAddress + field.offset, Memory.FLAGS.INT32, raw)
end

function M.collectWrite(baseAddress, field, value, writes)
    local raw
    if type(value) == "string" then
        local enum = loadEnum(field)
        raw = enum.byName and enum.byName[value]
        if raw == nil then return end
    elseif type(value) == "number" then
        raw = math.floor(value)
    else
        return
    end
    writes[#writes + 1] = { address = baseAddress + field.offset, flags = Memory.FLAGS.INT32, value = raw }
end

return M

end

__vfs['core/types/Float.lua'] = function(...)
--==================================================
-- core/types/Float.lua
--==================================================
-- 4-byte IEEE-754 float field.

local Memory = nebulaLoadModule("core/Memory.lua")

local M = {}

local function log(...)
    if Nebula and Nebula.verbose then
        print("[core.types.Float]", ...)
    end
end



---@param baseAddress integer
---@param field table
---@return number|nil value, string|nil error
function M.get(baseAddress, field)
    function M.collectWrite(baseAddress, field, value, writes)
    if type(value) == "number" then
        writes[#writes + 1] = { address = baseAddress + field.offset, flags = Memory.FLAGS.FLOAT, value = value }
    end
end

return Memory.read(baseAddress + field.offset, Memory.FLAGS.FLOAT)
end

---@param baseAddress integer
---@param field table
---@param value number
---@return boolean ok
function M.set(baseAddress, field, value)
    if type(value) ~= "number" then
        return false
    end
    function M.collectWrite(baseAddress, field, value, writes)
    if type(value) == "number" then
        writes[#writes + 1] = { address = baseAddress + field.offset, flags = Memory.FLAGS.FLOAT, value = value }
    end
end

return Memory.write(baseAddress + field.offset, Memory.FLAGS.FLOAT, value)
end

function M.collectWrite(baseAddress, field, value, writes)
    if type(value) == "number" then
        writes[#writes + 1] = { address = baseAddress + field.offset, flags = Memory.FLAGS.FLOAT, value = value }
    end
end

return M

end

__vfs['core/types/Int32.lua'] = function(...)
--==================================================
-- core/types/Int32.lua
--==================================================
-- Plain 4-byte signed integer field. No indirection, no protobuf
-- wrapper — just a direct read/write at baseAddress + offset.

local Memory = nebulaLoadModule("core/Memory.lua")

local M = {}

local function log(...)
    if Nebula and Nebula.verbose then
        print("[core.types.Int32]", ...)
    end
end



---@param baseAddress integer
---@param field table @ { offset, ... } from metadata
---@return integer|nil value, string|nil error
function M.get(baseAddress, field)
    function M.collectWrite(baseAddress, field, value, writes)
    if type(value) == "number" then
        writes[#writes + 1] = { address = baseAddress + field.offset, flags = Memory.FLAGS.INT32, value = math.floor(value) }
    end
end

return Memory.read(baseAddress + field.offset, Memory.FLAGS.INT32)
end

---@param baseAddress integer
---@param field table
---@param value integer
---@return boolean ok
function M.set(baseAddress, field, value)
    if type(value) ~= "number" then
        return false
    end
    function M.collectWrite(baseAddress, field, value, writes)
    if type(value) == "number" then
        writes[#writes + 1] = { address = baseAddress + field.offset, flags = Memory.FLAGS.INT32, value = math.floor(value) }
    end
end

return Memory.write(baseAddress + field.offset, Memory.FLAGS.INT32, math.floor(value))
end

function M.collectWrite(baseAddress, field, value, writes)
    if type(value) == "number" then
        writes[#writes + 1] = { address = baseAddress + field.offset, flags = Memory.FLAGS.INT32, value = math.floor(value) }
    end
end

return M

end

__vfs['core/types/Object.lua'] = function(...)


local function log(...)
    if Nebula and Nebula.verbose then
        print("[core.types.Object]", ...)
    end
end


end

__vfs['core/types/SafeInt32.lua'] = function(...)
local Memory = nebulaLoadModule("core/Memory.lua")
local ZeroPage = nebulaLoadModule("core/ZeroPage.lua")

SafeInt32 = setmetatable({
    safeValue   = 0;
    key         = 0;
    checksum    = 0;
    keyChecksum = 0;
    __index = function(t, k) return SafeInt32[k] end
}, {
    __call = function(cls, ...) return cls:__new() end
})

IntUtils = {}

function IntUtils:toInt32(x)
    if x >= 0x80000000 then
        return x - 0x100000000
    end
    return x
end

function SafeInt32:__hash(value)
    local x = value & 0xFFFFFFFF
    x = x ~ (x >> 16)
    x = (x * 0x045d9f3b) & 0xFFFFFFFF
    x = x ~ (x >> 16)
    x = (x * 0x045d9f3b) & 0xFFFFFFFF
    x = x ~ (x >> 16)
    return IntUtils:toInt32(x)
end

function SafeInt32:__new()
    local instance = setmetatable({}, self)
    return instance
end

function SafeInt32:decode(staticKey)
    return staticKey ~ self.safeValue ~ self.key
end

function SafeInt32:encode(staticKey, value, key)
    return staticKey ~ value ~ key
end

function SafeInt32:set(safeInt)
    self.safeValue   = safeInt.safeValue
    self.key         = safeInt.key
    self.checksum    = safeInt.checksum
    self.keyChecksum = safeInt.keyChecksum
end

function SafeInt32:new(value, staticKey)
    if value ~= nil then
        local safeInt = SafeInt32:__new()
        safeInt.key         = math.random(0, 0x7fffffff)
        safeInt.safeValue   = self:encode(staticKey, value, safeInt.key)
        safeInt.checksum    = self:__hash(value ~ safeInt.key)
        safeInt.keyChecksum = self:__hash(staticKey ~ safeInt.key)
        return safeInt
    end

    local safeInt = SafeInt32:__new()
    value               = math.random(0, 0x7fffffff)
    safeInt.key         = math.random(0, 0x7fffffff)
    safeInt.safeValue   = self:encode(staticKey, value, safeInt.key)
    safeInt.checksum    = self:__hash(value ~ safeInt.key)
    safeInt.keyChecksum = self:__hash(staticKey ~ safeInt.key)
    return safeInt
end

function SafeInt32:update(value, staticKey)
    local safeInt = self:new(value, staticKey)
    self:set(safeInt)
end

function SafeInt32:isValid(staticKey)
    if self.checksum ~= self:__hash(self:decode(staticKey) ~ self.key) then
        return false
    end
    if self.keyChecksum ~= self:__hash(staticKey ~ self.key) then
        return false
    end
    return true
end

function SafeInt32:verifyAndCheckSafeValue(value, staticKey)
    local decoded = self:decode(staticKey)
    if value ~= decoded then
        return false
    end
    if self:isValid(staticKey) then
        if self.checksum ~= self:__hash(value ~ self.key) then
            return false
        end
        return true
    end
    return false
end

function SafeInt32:print(staticKey)
    local safeInt = string.format("[\t\n\x20safeValue=(%d);\n key=(%d);\n checksum=(%d);\n keyChecksum=(%d);\t\n]", IntUtils:toInt32(self.safeValue), IntUtils:toInt32(self.key), IntUtils:toInt32(self.checksum), IntUtils:toInt32(self.keyChecksum))
    local info    = string.format("[\t\n\x20decoded=(%d);\n staticKey=(%d);\n isValid=(%s)\t\n]", IntUtils:toInt32(self:decode(staticKey)), IntUtils:toInt32(staticKey), self:isValid(staticKey))
    print(string.format("[SafeInt32::print] -> SafeInt : %s\n Info : %s\n", safeInt, info))
end

local M = {}

local function log(...)
    if Nebula and Nebula.verbose then
        print("[core.types.SafeInt32]", ...)
    end
end



local STRUCT_SAFEVALUE_OFF   = 0x18
local STRUCT_KEY_OFF         = 0x1C
local STRUCT_CHECKSUM_OFF    = 0x20
local STRUCT_KEYCHECKSUM_OFF = 0x24
local STATIC_KEY_OFFSET = 0x6AC
local STRUCT_SIZE = 0x28

local cachedStaticKey = nil
local cachedGameStatusBase = nil

local function resolveStaticKey(baseAddress)
    if cachedStaticKey ~= nil then
        return cachedStaticKey
    end
    if cachedGameStatusBase == nil then
        if Nebula and Nebula.GameStatus and Nebula.GameStatus.resolveBase then
            cachedGameStatusBase = Nebula.GameStatus.resolveBase()
        end
    end
    local gsBase = cachedGameStatusBase or baseAddress
    cachedStaticKey = Memory.read(gsBase + STATIC_KEY_OFFSET, Memory.FLAGS.INT32) or 0
    return cachedStaticKey
end

local function readStruct(structPtr)
    local specs = {
        { address = structPtr + STRUCT_SAFEVALUE_OFF,   flags = Memory.FLAGS.INT32 },
        { address = structPtr + STRUCT_KEY_OFF,         flags = Memory.FLAGS.INT32 },
        { address = structPtr + STRUCT_CHECKSUM_OFF,    flags = Memory.FLAGS.INT32 },
        { address = structPtr + STRUCT_KEYCHECKSUM_OFF, flags = Memory.FLAGS.INT32 },
    }
    local results = Memory.readBatch(specs)
    local instance = SafeInt32:__new()
    if results then
        instance.safeValue   = results[1] and results[1].value or 0
        instance.key         = results[2] and results[2].value or 0
        instance.checksum    = results[3] and results[3].value or 0
        instance.keyChecksum = results[4] and results[4].value or 0
    end
    return instance
end

function M.get(baseAddress, field)
    local structPtr, err = Memory.deref(baseAddress, field.offset)
    if not structPtr then
        return nil, err
    end

    local instance = readStruct(structPtr)
    local staticKey = resolveStaticKey(baseAddress)

    if not instance:isValid(staticKey) then
        return nil, "checksum_invalid"
    end

    return instance:decode(staticKey)
end

function M.set(baseAddress, field, value)
    if type(value) ~= "number" then
        return false
    end

    local structPtr, err = Memory.deref(baseAddress, field.offset)
    local needsAlloc = not structPtr or structPtr == 0

    if needsAlloc then
        structPtr = ZeroPage.allocate(STRUCT_SIZE)
        if not structPtr then
            return false
        end
    end

    local staticKey = resolveStaticKey(baseAddress)
    local instance = SafeInt32:new(math.floor(value), staticKey)

    local writes = {
        { address = structPtr + STRUCT_SAFEVALUE_OFF,   flags = Memory.FLAGS.INT32, value = instance.safeValue },
        { address = structPtr + STRUCT_KEY_OFF,         flags = Memory.FLAGS.INT32, value = instance.key },
        { address = structPtr + STRUCT_CHECKSUM_OFF,    flags = Memory.FLAGS.INT32, value = instance.checksum },
        { address = structPtr + STRUCT_KEYCHECKSUM_OFF, flags = Memory.FLAGS.INT32, value = instance.keyChecksum },
    }

    if needsAlloc then
        writes[#writes + 1] = { address = baseAddress + field.offset, flags = Memory.FLAGS.INT64, value = structPtr }
    end

    return Memory.writeBatch(writes)
end

function M.collectWrite(baseAddress, field, value, writes)
    if type(value) ~= "number" then return end
    local structPtr, err = Memory.deref(baseAddress, field.offset)
    local needsAlloc = not structPtr or structPtr == 0

    if needsAlloc then
        structPtr = ZeroPage.allocate(STRUCT_SIZE)
        if not structPtr then return end
        writes[#writes + 1] = { address = baseAddress + field.offset, flags = Memory.FLAGS.INT64, value = structPtr }
    end

    local staticKey = resolveStaticKey(baseAddress)
    local instance = SafeInt32:new(math.floor(value), staticKey)
    writes[#writes + 1] = { address = structPtr + STRUCT_SAFEVALUE_OFF, flags = Memory.FLAGS.INT32, value = instance.safeValue }
    writes[#writes + 1] = { address = structPtr + STRUCT_KEY_OFF, flags = Memory.FLAGS.INT32, value = instance.key }
    writes[#writes + 1] = { address = structPtr + STRUCT_CHECKSUM_OFF, flags = Memory.FLAGS.INT32, value = instance.checksum }
    writes[#writes + 1] = { address = structPtr + STRUCT_KEYCHECKSUM_OFF, flags = Memory.FLAGS.INT32, value = instance.keyChecksum }

    if needsAlloc then
        writes[#writes + 1] = { address = baseAddress + field.offset, flags = Memory.FLAGS.INT64, value = structPtr }
    end
end

return M

end

__vfs['core/types/String.lua'] = function(...)
local Memory = nebulaLoadModule("core/Memory.lua")
local ZeroPage = nebulaLoadModule("core/ZeroPage.lua")

local M = {}

local function log(...)
    if Nebula and Nebula.verbose then
        print("[core.types.String]", ...)
    end
end



local INLINE_MAX_BYTES = 6 * 4
local LONG_HEADER_MIN = 9
local LONG_HEADER_MAX = 99

local function toUnsignedByte(signed)
    return signed & 0xFF
end

local function readRawBytes(addr, count)
    if count <= 0 then
        return "", nil
    end

    local specs = {}
    for i = 0, count - 1 do
        specs[i + 1] = { address = addr + i, flags = Memory.FLAGS.BYTE }
    end

    local results, err = Memory.readBatch(specs)
    if not results then
        return nil, err
    end

    local bytes = {}
    for i = 1, count do
        local raw = results[i] and results[i].value or 0
        bytes[i] = toUnsignedByte(raw)
    end

    return string.char(table.unpack(bytes))
end

local function readInline(ptr)
    local lenRaw, lenErr = Memory.read(ptr, Memory.FLAGS.BYTE)
    if lenRaw == nil then
        return nil, lenErr
    end

    local byteCount = math.floor(toUnsignedByte(lenRaw) / 2)
    return readRawBytes(ptr + 1, byteCount)
end

local function readLong(ptr)
    local fields, err = Memory.readBatch({
        { address = ptr,        flags = Memory.FLAGS.INT32 },
        { address = ptr + 0x4,  flags = Memory.FLAGS.INT32 },
        { address = ptr + 0x8,  flags = Memory.FLAGS.INT32 },
        { address = ptr + 0xC,  flags = Memory.FLAGS.INT32 },
        { address = ptr + 0x10, flags = Memory.FLAGS.INT64 },
    })

    if not fields then
        return nil, err
    end

    local header   = fields[1] and fields[1].value
    local reserved1 = fields[2] and fields[2].value
    local length   = fields[3] and fields[3].value
    local reserved2 = fields[4] and fields[4].value
    local dataPtr  = fields[5] and fields[5].value

    if header == nil or header < LONG_HEADER_MIN or header > LONG_HEADER_MAX then
        return nil, "long_header_invalid"
    end
    if reserved1 ~= 0 or reserved2 ~= 0 then
        return nil, "long_reserved_nonzero"
    end
    if dataPtr == nil or dataPtr == 0 then
        return nil, "long_dataptr_null"
    end
    if length == nil or length < 0 then
        return nil, "long_length_invalid"
    end

    return readRawBytes(dataPtr, length)
end

local function resolvePtr(baseAddress, field)
    if field.indirect == false then
        return baseAddress + field.offset
    end
    return Memory.deref(baseAddress, field.offset)
end

function M.get(baseAddress, field)
    log(string.format("[get] base=0x%X offset=0x%X indirect=%s", baseAddress, field.offset, tostring(field.indirect)))
    local ptr, err = resolvePtr(baseAddress, field)
    if not ptr then
        return nil, err
    end
    log(string.format("[get] resolved ptr=0x%X", ptr))

    local longVal, longErr = readLong(ptr)
    log(string.format("[get] readLong result=%s err=%s", tostring(longVal), tostring(longErr)))
    if longVal ~= nil then
        return longVal
    end

    log(string.format("[get] falling back to readInline at ptr=0x%X", ptr))
    return readInline(ptr)
end

local function writeInline(ptr, nameBytes, byteCount)
    local writes = { { address = ptr, flags = Memory.FLAGS.BYTE, value = byteCount * 2 } }
    for i = 1, #nameBytes do
        writes[#writes + 1] = { address = ptr + i, flags = Memory.FLAGS.BYTE, value = nameBytes[i] }
    end
    return Memory.writeBatch(writes)
end

local function isLongForm(ptr)
    local fields, err = Memory.readBatch({
        { address = ptr,       flags = Memory.FLAGS.INT32 },
        { address = ptr + 0x4, flags = Memory.FLAGS.INT32 },
        { address = ptr + 0xC, flags = Memory.FLAGS.INT32 },
        { address = ptr + 0x10, flags = Memory.FLAGS.INT64 },
    })
    if not fields then return false end
    local header = fields[1] and fields[1].value
    local r1 = fields[2] and fields[2].value
    local r2 = fields[3] and fields[3].value
    local dp = fields[4] and fields[4].value
    if header == nil or header < LONG_HEADER_MIN or header > LONG_HEADER_MAX then return false end
    if r1 ~= 0 or r2 ~= 0 then return false end
    if dp == nil or dp == 0 then return false end
    return true
end

local function writeLong(ptr, nameBytes, byteCount)
    local fields, err = Memory.readBatch({
        { address = ptr,       flags = Memory.FLAGS.INT32 },
        { address = ptr + 0x4, flags = Memory.FLAGS.INT32 },
        { address = ptr + 0xC, flags = Memory.FLAGS.INT32 },
        { address = ptr + 0x10, flags = Memory.FLAGS.INT64 },
    })

    local header = fields and fields[1] and fields[1].value
    local r1 = fields and fields[2] and fields[2].value
    local r2 = fields and fields[3] and fields[3].value
    local dataPtr = fields and fields[4] and fields[4].value

    local alreadyLong = header ~= nil and header >= LONG_HEADER_MIN and header <= LONG_HEADER_MAX
        and r1 == 0 and r2 == 0 and dataPtr ~= nil and dataPtr ~= 0

    if not alreadyLong then
        local n = math.ceil(math.sqrt(byteCount))
        header = (n * n) | 1
        dataPtr = ZeroPage.allocate(byteCount + 1)
        if not dataPtr then
            return false
        end
    end

    local writes = {
        { address = ptr,      flags = Memory.FLAGS.INT32, value = header },
        { address = ptr + 0x4, flags = Memory.FLAGS.INT32, value = 0 },
        { address = ptr + 0x8, flags = Memory.FLAGS.INT32, value = byteCount },
        { address = ptr + 0xC, flags = Memory.FLAGS.INT32, value = 0 },
        { address = ptr + 0x10, flags = Memory.FLAGS.INT64, value = dataPtr },
    }
    for i = 1, #nameBytes do
        writes[#writes + 1] = { address = dataPtr + (i - 1), flags = Memory.FLAGS.BYTE, value = nameBytes[i] }
    end
    writes[#writes + 1] = { address = dataPtr + byteCount, flags = Memory.FLAGS.BYTE, value = 0 }

    return Memory.writeBatch(writes)
end

local STRING_OBJECT_SIZE = 0x18

function M.set(baseAddress, field, value)
    log(string.format("[set] base=0x%X offset=0x%X value='%s'", baseAddress, field.offset, tostring(value)))
    if type(value) ~= "string" then
        return false
    end

    local ptr, err = resolvePtr(baseAddress, field)
    local needsAlloc = not ptr or ptr == 0

    if needsAlloc then
        -- indirect == false means baseAddress+offset IS the string
        -- storage (no separate object to allocate) — nothing we can do.
        if field.indirect == false then
            return false
        end
        ptr = ZeroPage.allocate(STRING_OBJECT_SIZE)
        if not ptr then
            return false
        end
    end

    local nameBytes = {}
    local byteCount = #value

    for i = 1, byteCount do
        nameBytes[i] = string.byte(value, i)
    end

    local writeOk
    if byteCount + 1 <= INLINE_MAX_BYTES then
        writeOk = writeInline(ptr, nameBytes, byteCount)
    else
        writeOk = writeLong(ptr, nameBytes, byteCount)
    end

    if not writeOk then
        return false
    end

    if needsAlloc then
        return Memory.write(baseAddress + field.offset, Memory.FLAGS.INT64, ptr)
    end

    return true
end

function M.collectWrite(baseAddress, field, value, writes)
    if type(value) ~= "string" then return false end

    local ptr, err = resolvePtr(baseAddress, field)
    local needsAlloc = not ptr or ptr == 0

    if needsAlloc then
        if field.indirect == false then return false end
        ptr = ZeroPage.allocate(STRING_OBJECT_SIZE)
        if not ptr then return false end
        writes[#writes + 1] = { address = baseAddress + field.offset, flags = Memory.FLAGS.INT64, value = ptr }
    end

    local nameBytes = {}
    local byteCount = #value
    for i = 1, byteCount do
        nameBytes[i] = string.byte(value, i)
    end
    if byteCount + 1 <= INLINE_MAX_BYTES then
        writes[#writes + 1] = { address = ptr, flags = Memory.FLAGS.BYTE, value = byteCount * 2 }
        for i = 1, #nameBytes do
            writes[#writes + 1] = { address = ptr + i, flags = Memory.FLAGS.BYTE, value = nameBytes[i] }
        end
    else
        local alreadyLong = not needsAlloc and isLongForm(ptr)
        local header, dataPtr
        if alreadyLong then
            local fields = Memory.readBatch({
                { address = ptr, flags = Memory.FLAGS.INT32 },
                { address = ptr + 0x10, flags = Memory.FLAGS.INT64 },
            })
            header = fields and fields[1] and fields[1].value
            dataPtr = fields and fields[2] and fields[2].value
        end
        if not alreadyLong or dataPtr == nil or dataPtr == 0 then
            local n = math.ceil(math.sqrt(byteCount))
            header = (n * n) | 1
            dataPtr = ZeroPage.allocate(byteCount + 1)
            if not dataPtr then return false end
        end
        writes[#writes + 1] = { address = ptr, flags = Memory.FLAGS.INT32, value = header }
        writes[#writes + 1] = { address = ptr + 0x4, flags = Memory.FLAGS.INT32, value = 0 }
        writes[#writes + 1] = { address = ptr + 0x8, flags = Memory.FLAGS.INT32, value = byteCount }
        writes[#writes + 1] = { address = ptr + 0xC, flags = Memory.FLAGS.INT32, value = 0 }
        writes[#writes + 1] = { address = ptr + 0x10, flags = Memory.FLAGS.INT64, value = dataPtr }
        for i = 1, #nameBytes do
            writes[#writes + 1] = { address = dataPtr + (i - 1), flags = Memory.FLAGS.BYTE, value = nameBytes[i] }
        end
        writes[#writes + 1] = { address = dataPtr + byteCount, flags = Memory.FLAGS.BYTE, value = 0 }
    end

    return true
end

return M

end

__vfs['metadata/CommunityEvent.lua'] = function(...)
--==================================================
-- metadata/CommunityEvent.lua
--==================================================
-- Field table for the CommunityShowcase event struct.
--
-- Cross-referenced with the shared header offsets from
-- PublicEvent/TeamEvent (id, name, startTime, endTime,
-- sessionEntry fields, duration, joinWindow, etc. are at the
-- same absolute offsets). Verified against the IL2CPP dump:
-- CommunityEvent is also backed by the shared EventDefinition
-- struct (Size 0x5D8, Confidence: exact), so the header offsets
-- id 0x8 / name 0x20 / description 0x38 / eventIcon 0x80 /
-- minRankToJoin 0x140 / startTimeLive 0x14C / startTime 0x150 /
-- endTime 0x154 / sessionEntry 0x160 and the gameMode children
-- all match exactly.
--
-- This is a SIMPLER struct than PublicEvent/TeamEvent:
--   - No contentVersion field (resolution uses string search,
--     not byte-signature scanning, so there's no signature to
--     version-check against)
--   - No eventRewards / lootDefinition / rotatingEventRewards /
--     mainEventRewards / premiumEventRewards
--   - No gemsToPointsConversion / conversionDuration
--   - No fixedVehicles / specialFeatures / eventSpecials
--   - No requiredPackages
--
-- Unique field vs PublicEvent/TeamEvent:
--   - minRankToJoin (0x140) — PublicEvent has
--     unlockCurrentlyActiveSegment there, TeamEvent has
--     minTeamSizeToJoin. CommunityEvent has minRankToJoin.
--
-- Resolution is string-based (see core/Memory.lua's
-- resolveActiveCommunityEventBase), not AOB — the search target
-- is the event's own name field ("community Showcase"), so the
-- "signature" is the event identity itself, not a config constant.
--
-- String fields use the same ABI as PublicEvent/TeamEvent —
-- inlined C++ strings, no pointer indirection. The shadowStringDirect()
-- helper in api/CommunityEvent.lua handles this, same as the other
-- event modules.
--
-- offset = 0xBAAD means the offset is NOT YET KNOWN.

return {
    ["id"] = {
        offset = 0x8,
        type = "String"
    },
    ["name"] = {
        offset = 0x20,
        type = "String"
    },
    ["description"] = {
        offset = 0x38,
        type = "String"
    },
    ["eventIcon"] = {
        offset = 0x80,
        type = "String"
    },
    ["minRankToJoin"] = {
        offset = 0x140,
        type = "Int32"
    },
    ["startTimeLive"] = {
        offset = 0x14C,
        type = "Int32"
    },
    ["startTime"] = {
        offset = 0x150,
        type = "Int32"
    },
    ["endTime"] = {
        offset = 0x154,
        type = "Int32"
    },
    ["sessionEntry"] = {
        ["entryFeeTickets"] = {
            offset = 0x160,
            type = "Int32"
        },
        ["maxEventTickets"] = {
            offset = 0x164,
            type = "Int32"
        },
        ["eventTicketRefillTime"] = {
            offset = 0x168,
            type = "Int32"
        },
        ["eventTicketRefillAmount"] = {
            offset = 0x16C,
            type = "Int32"
        },
        ["eventTicketRefillCost"] = {
            offset = 0x170,
            type = "Int32"
        },
    },
    ["gameMode"] = {
        ["duration"] = {
            offset = 0x21C,
            type = "Int32"
        },
        ["joinWindow"] = {
            offset = 0x220,
            type = "Int32"
        },
        ["maxSessionParticipants"] = {
            offset = 0x2D0,
            type = "Int32"
        },
        ["levelPools"] = {
            offset = 0x2F0,
            type = "Array",
            -- std::vector<std::vector<std::string>>: outer elements
            -- are vector<string> objects (0x18 each), inline
            elementStride = 0x18,
            elements = {
                ["levels"] = {
                    offset = 0x0,
                    type = "Array",
                    elementType = "String",
                    elementStride = 0x18 -- inline std::string elements
                }
            }
        },
        ["pointsSystem"] = {
            offset = 0x3E0,
            type = "Object" -- known offset, no reader yet
        },
    },
}

end

__vfs['metadata/GameStatus.lua'] = function(...)
--==================================================
-- metadata/GameStatus.lua
--==================================================
-- Field table for the top-level GameStatus proto2 message.
-- Sourced from descriptor.proto (field numbers / proto types)
-- cross-referenced with known offsets from the legacy flat
-- GameStatus.lua and account.lua ops.
--
-- Offsets and element layouts cross-validated against an
-- exact-confidence struct dump of libcocos2dcpp.so
-- (temp/libcocos2dcpp.cs, DWARF-recovered field names). Every
-- previously verified offset matches the dump. The remaining
-- 0xBAAD placeholders and placeholder-array element templates that
-- were previously unmapped are filled from it and will need
-- on-device spot checks before being treated as fully trusted.
--
-- offset = 0xBAAD means the offset is NOT YET KNOWN. Do not
-- trust these fields until the placeholder is replaced by a
-- verified static offset.
--
-- type = "Object" marks single nested message fields that
-- carry their own child layouts inline (or reference a shared
-- element template via a local). Fields without a reader yet are
-- left with a comment noting which sub-template is still unmapped.
--
-- type = "Array" marks repeated fields. Use elementType = "X"
-- for simple typed arrays (e.g. repeated string). Use elements =
-- { ... } for struct-element arrays with known field layouts.
-- Placeholder arrays (no elementType/elements) fail gracefully
-- until the element layout is mapped.
--
-- SafeInt32 fields: `offset` points to a POINTER to the
-- struct (not an inline struct). The static XOR key is
-- fixed account-wide at safeIntStaticKey and resolved
-- internally by core/types/SafeInt32.lua — no per-field
-- staticKeyOffset needed.

local stringIntMapElements = {
    ["key"] = { offset = 0x18, type = "String" },
    ["value"] = { offset = 0x20, type = "Int32" },
}

local seasonResultElements = {
    ["seasonId"] = { offset = 0x18, type = "String" },
    ["result"] = { offset = 0x20, type = "Float" },
}

local distanceHighscoreElements = {
    ["levelId"] = { offset = 0x18, type = "String" },
    ["distance"] = { offset = 0x20, type = "Float" },
    -- 0x24/0x28 per the libcocos2dcpp dump (was 0x28/0x2C); the dump
    -- puts previousSeasonBest directly after distance.
    ["previousSeasonBest"] = { offset = 0x24, type = "Float" },
    ["previousSeasons"] = {
        offset = 0x28,
        type = "Array",
        elements = seasonResultElements,
    },
    ["currentSeasonBest"] = { offset = 0x40, type = "Float" },
}

local timeTrialHighscoreElements = {
    ["levelId"] = { offset = 0x18, type = "String" },
    ["time"] = { offset = 0x20, type = "Float" },
    -- 0x24/0x28 per the libcocos2dcpp dump (was 0x28/0x2C)
    ["previousSeasonBest"] = { offset = 0x24, type = "Float" },
    ["previousSeasons"] = {
        offset = 0x28,
        type = "Array",
        elements = seasonResultElements,
    },
    ["currentSeasonBest"] = { offset = 0x40, type = "Float" },
}

--==================================================
-- Element templates filled from the libcocos2dcpp dump.
-- All offsets are element-relative. Singular submessage
-- members are POINTERS (confirmed by struct-size overlap
-- analysis), so Object containers keep the deref convention.
--==================================================

local missionStatusFields = {
    ["missionId"] = { offset = 0x18, type = "String" },
    ["bestValue"] = { offset = 0x20, type = "Float" },
    ["achievedLevel"] = { offset = 0x24, type = "Int32" },
    ["missionDefinitionId"] = { offset = 0x28, type = "String" },
    ["allowedVehicleIds"] = { offset = 0x30, type = "Array", elementType = "String" },
    ["allowedWorldIds"] = { offset = 0x48, type = "Array", elementType = "String" },
    ["allowedLevelIds"] = { offset = 0x60, type = "Array", elementType = "String" },
    ["startingValue"] = { offset = 0x78, type = "Float" },
}

local missionStatusElements = missionStatusFields

local missionStatusMapElements = {
    ["levelId"] = { offset = 0x18, type = "String" },
    ["missionStatus"] = { offset = 0x20, type = "Object" },
}
for k, v in pairs(missionStatusFields) do
    missionStatusMapElements.missionStatus[k] = v
end

local qualifyTimeElements = {
    ["levelId"] = { offset = 0x18, type = "String" },
    ["time"] = { offset = 0x20, type = "Float" },
}

local racePointsElements = {
    ["levelId"] = { offset = 0x18, type = "String" },
    ["points"] = { offset = 0x20, type = "Int32" },
}

local upgradeStatusElements = {
    ["upgradeId"] = { offset = 0x18, type = "String" },
    ["level"] = { offset = 0x20, type = "Int32" },
    ["maxLevel"] = { offset = 0x24, type = "Int32" },
}

local friendlyRaceElements = {
    ["sessionId"] = { offset = 0x18, type = "String" },
    ["levelId"] = { offset = 0x20, type = "String" },
    ["friendlyRaceType"] = { offset = 0x28, type = "Int32" },
    ["expirationTimestamp"] = { offset = 0x2C, type = "Int32" },
    ["retryCount"] = { offset = 0x30, type = "Int32" },
}

local iapPurchaseEventElements = {
    ["iapId"] = { offset = 0x18, type = "String" },
    ["timestamp"] = { offset = 0x20, type = "Int32" },
    ["validated"] = { offset = 0x24, type = "Bool" },
    ["transactionId"] = { offset = 0x28, type = "String" },
    ["offerId"] = { offset = 0x30, type = "String" },
    ["recipientIds"] = { offset = 0x38, type = "Array", elementType = "String" },
    ["validationState"] = { offset = 0x50, type = "Int32" },
}

local pendingChestElements = {
    ["vehicleId"] = { offset = 0x18, type = "String" },
    ["chestIndex"] = { offset = 0x20, type = "Int32" },
    ["level"] = { offset = 0x24, type = "Int32" },
    ["type"] = { offset = 0x28, type = "String" },
}

local rentalStatusElements = {
    ["id"] = { offset = 0x18, type = "String" },
    ["eventId"] = { offset = 0x20, type = "String" },
    ["expiryTimestamp"] = { offset = 0x28, type = "Int32" },
}

local dealItemElements = {
    ["id"] = { offset = 0x18, type = "String" },
    ["type"] = { offset = 0x20, type = "String" },
    ["amount"] = { offset = 0x28, type = "Int32" },
}

local dealStatusElements = {
    ["id"] = { offset = 0x18, type = "String" },
    ["purchasedItems"] = { offset = 0x20, type = "Array", elements = dealItemElements },
    ["items"] = { offset = 0x38, type = "Array", elements = dealItemElements },
    ["endTimestamp"] = { offset = 0x50, type = "Int32" },
}

local seasonStatusElements = {
    ["highestRank"] = { offset = 0x18, type = "Float" },
    ["startRank"] = { offset = 0x1C, type = "Float" },
    ["seasonId"] = { offset = 0x20, type = "String" },
    ["endTimestamp"] = { offset = 0x28, type = "Int32" },
    ["ended"] = { offset = 0x2C, type = "Bool" },
    ["premiumUnlocked"] = { offset = 0x2D, type = "Bool" },
    ["bonusChestClaimed"] = { offset = 0x2E, type = "Bool" },
    ["premiumProgressClaimed"] = { offset = 0x2F, type = "Bool" },
    ["receivedRewards"] = { offset = 0x30, type = "Array", elementType = "String" },
    ["animatedRank"] = { offset = 0x48, type = "Float" },
    ["premiumTierUnlocked"] = { offset = 0x4C, type = "Int32" },
}

local activePopupOfferElements = {
    ["id"] = { offset = 0x18, type = "String" },
    ["endTimestamp"] = { offset = 0x20, type = "Int32" },
    ["useAdOffer"] = { offset = 0x24, type = "Bool" },
    ["activationCount"] = { offset = 0x28, type = "Int32" },
    ["activationTimestamp"] = { offset = 0x2C, type = "Int32" },
    ["originalActivationTimestamp"] = { offset = 0x30, type = "Int32" },
}

local homeCosmeticsOwnershipElements = {
    ["id"] = { offset = 0x18, type = "String" },
    ["ownedCount"] = { offset = 0x20, type = "Int32" },
    ["usedCount"] = { offset = 0x24, type = "Int32" },
    ["newUnlock"] = { offset = 0x28, type = "Bool" },
}

local megaAdChestItemElements = {
    ["type"] = { offset = 0x18, type = "Int32" },
    ["amount"] = { offset = 0x1C, type = "Int32" },
    ["rarity"] = { offset = 0x20, type = "Int32" },
}

local megaAdChestRewardStatusElements = {
    ["watched"] = { offset = 0x18, type = "Int32" },
    ["watchedLastSession"] = { offset = 0x1C, type = "Int32" },
    ["reward"] = { offset = 0x20, type = "Object" },
    ["rewardLastSession"] = { offset = 0x28, type = "Object" },
    ["claimed"] = { offset = 0x30, type = "Bool" },
    ["claimedLastSession"] = { offset = 0x31, type = "Bool" },
}
for k, v in pairs(megaAdChestItemElements) do
    megaAdChestRewardStatusElements.reward[k] = v
    megaAdChestRewardStatusElements.rewardLastSession[k] = v
end

local leagueTaskElements = {
    ["id"] = { offset = 0x18, type = "Int32" },
    ["target"] = { offset = 0x1C, type = "Int32" },
    ["progress"] = { offset = 0x20, type = "Int32" },
    ["claimed"] = { offset = 0x24, type = "Bool" },
    ["createTimestamp"] = { offset = 0x28, type = "Int32" },
}

local megaAdChestProgressDayElements = {
    ["watched"] = { offset = 0x18, type = "Int32" },
    ["claimed"] = { offset = 0x1C, type = "Bool" },
    ["reward"] = { offset = 0x20, type = "Object" },
}
for k, v in pairs(megaAdChestItemElements) do
    megaAdChestProgressDayElements.reward[k] = v
end

local megaAdChestProgressElements = {
    -- rewardHash (0x18) is int64 — no Int64 reader yet
    ["progress"] = { offset = 0x20, type = "Array", elements = megaAdChestProgressDayElements },
}

local adViewsMapElements = {
    ["placementId"] = { offset = 0x18, type = "Int32" },
    ["resetTimestamp"] = { offset = 0x1C, type = "Int32" },
    ["remaining"] = { offset = 0x20, type = "Int32" },
}

local activeTriggerElements = {
    ["timestamp"] = { offset = 0x18, type = "Int32" },
    ["type"] = { offset = 0x1C, type = "Int32" },
    ["vehicleId"] = { offset = 0x20, type = "String" },
    ["level"] = { offset = 0x28, type = "Int32" },
}

local dailyTaskElements = {
    ["type"] = { offset = 0x18, type = "Int32" },
    ["target"] = { offset = 0x1C, type = "Int32" },
    ["vehicle"] = { offset = 0x20, type = "String" },
    ["level"] = { offset = 0x28, type = "String" },
    ["completed"] = { offset = 0x30, type = "Bool" },
    ["progress"] = { offset = 0x34, type = "Int32" },
    ["slot"] = { offset = 0x38, type = "Int32" },
    ["createTimestamp"] = { offset = 0x3C, type = "Int32" },
    ["taskSpecific"] = { offset = 0x40, type = "Array", elementType = "Int32", elementStride = 0x4 },
}

local currentFriendEventElements = {
    ["claimedRewards"] = { offset = 0x18, type = "Array", elementType = "SafeInt32" },
    ["eventHash"] = { offset = 0x30, type = "Int32" },
    ["hasEventPass"] = { offset = 0x34, type = "Bool" },
    ["collectibleResetTimestamp"] = { offset = 0x38, type = "SafeInt32" },
    ["collectibleCollected"] = { offset = 0x40, type = "SafeInt32" },
    ["activeEventTasks"] = { offset = 0x48, type = "Array", elements = dailyTaskElements },
    ["taskRefillsRemaining"] = { offset = 0x60, type = "Array", elementType = "Int32", elementStride = 0x4 },
    ["singleScore"] = { offset = 0x70, type = "SafeInt32" },
    ["tasksResetTimestamp"] = { offset = 0x78, type = "Int32" },
    ["adsResetTimestamp"] = { offset = 0x7C, type = "Int32" },
    ["eventId"] = { offset = 0x80, type = "String" },
    ["teamId"] = { offset = 0x88, type = "String" },
    ["adsRemaining"] = { offset = 0x90, type = "Int32" },
}

local banDataElements = {
    ["bundleId"] = { offset = 0x18, type = "String" },
    ["timestamp"] = { offset = 0x20, type = "Int32" },
    ["oldIntValue"] = { offset = 0x24, type = "Int32" },
    ["key"] = { offset = 0x28, type = "String" },
    ["newIntValue"] = { offset = 0x30, type = "Int32" },
    ["oldFloatValue"] = { offset = 0x34, type = "Float" },
    ["oldStringValue"] = { offset = 0x38, type = "String" },
    ["newStringValue"] = { offset = 0x40, type = "String" },
    ["newFloatValue"] = { offset = 0x48, type = "Float" },
}

local distanceTicketElements = {
    ["ticketId"] = { offset = 0x18, type = "String" },
    ["amount"] = { offset = 0x20, type = "Int32" },
    ["lastRefillTime"] = { offset = 0x24, type = "Int32" },
    ["totalSpentAmount"] = { offset = 0x28, type = "Int32" },
    ["videoSkipsRemaining"] = { offset = 0x2C, type = "Int32" },
    ["nextVideoSkipTimestamp"] = { offset = 0x30, type = "Int32" },
    ["vipSkipsRemaining"] = { offset = 0x34, type = "Int32" },
    ["nextVipSkipTimestamp"] = { offset = 0x38, type = "Int32" },
}

local featuredChallengeElements = {
    ["challengeId"] = { offset = 0x18, type = "String" },
    ["expirationTimestamp"] = { offset = 0x20, type = "Int32" },
    ["unlimitedTries"] = { offset = 0x24, type = "Bool" },
    ["challengeWon"] = { offset = 0x25, type = "Bool" },
    ["rewardClaimed"] = { offset = 0x26, type = "Bool" },
    ["videoRetriesRemaining"] = { offset = 0x28, type = "Int32" },
}

local eventStatusElements = {
    ["instanceId"] = { offset = 0x18, type = "String" },
    ["eventId"] = { offset = 0x20, type = "String" },
    ["expirationTimestamp"] = { offset = 0x28, type = "Int32" },
    ["eventPoints"] = { offset = 0x2C, type = "Int32" },
    ["collectedRewardIndexes"] = { offset = 0x30, type = "Array", elementType = "Int32", elementStride = 0x4 },
    ["activeSessionId"] = { offset = 0x40, type = "String" },
    ["tickets"] = { offset = 0x48, type = "Int32" },
    ["lastTicketsRefillTime"] = { offset = 0x4C, type = "Int32" },
    ["spentTickets"] = { offset = 0x50, type = "Int32" },
    ["totalEventRaces"] = { offset = 0x54, type = "Int32" },
    ["latestSessionRaces"] = { offset = 0x58, type = "Int32" },
    ["eventPointsUnlockProgress"] = { offset = 0x5C, type = "Int32" },
    ["teamId"] = { offset = 0x60, type = "String" },
    -- fixedVehicleStatus (0x68) is RepeatedPtrField<VehicleStatus>;
    -- the vehicleStatus element template lives inline on the
    -- vehicleStatus entry below, so no reader is attached here.
    ["eventName"] = { offset = 0x80, type = "String" },
    ["eventButtonBackground"] = { offset = 0x88, type = "String" },
    ["shownOfferIds"] = { offset = 0x90, type = "Array", elementType = "String" },
    ["spentSpecialTickets"] = { offset = 0xA8, type = "Int32" },
    ["spentEventPoints"] = { offset = 0xAC, type = "Int32" },
    ["collectedMainRewardIndexes"] = { offset = 0xB0, type = "Array", elementType = "Int32", elementStride = 0x4 },
    ["collectedRotatingRewardIndexes"] = { offset = 0xC0, type = "Array", elementType = "Int32", elementStride = 0x4 },
    ["levelId"] = { offset = 0xD0, type = "String" },
    ["videosWatched"] = { offset = 0xD8, type = "Int32" },
    ["hasUnlimitedTicket"] = { offset = 0xDC, type = "Bool" },
    ["hasScoreDoubled"] = { offset = 0xDD, type = "Bool" },
    ["hasEventPass"] = { offset = 0xDE, type = "Bool" },
    ["allBoosters"] = { offset = 0xE0, type = "Array", elementType = "String" },
    ["eventPointsPrev"] = { offset = 0xF8, type = "Int32" },
    ["totalSessionsJoined"] = { offset = 0xFC, type = "Int32" },
    -- activeBoosters (0x100) is RepeatedPtrField<ActiveBooster> — layout not yet mapped
    ["boosterFreeShopItems"] = { offset = 0x118, type = "Array", elementType = "String" },
    ["randomBoosterSelection"] = { offset = 0x130, type = "Array", elementType = "String" },
    ["activeSessionBonusVehicles"] = { offset = 0x148, type = "Array", elementType = "String" },
    ["pendingMultichoiceChestVehicles"] = { offset = 0x160, type = "Array", elementType = "String" },
    ["specialFeatureUpgrades"] = { offset = 0x178, type = "Array", elements = upgradeStatusElements },
    ["collectedSpecialsRewardIndexes"] = { offset = 0x190, type = "Array", elementType = "Int32", elementStride = 0x4 },
    ["boosterClaimedAtSession"] = { offset = 0x1A0, type = "Int32" },
}

local distanceCollectibleStatusElements = {
    ["seasonId"] = { offset = 0x18, type = "String" },
    -- levels (0x20) is RepeatedPtrField<LevelCollectibleStatus> — layout not yet mapped
    ["claimedRewardLevel"] = { offset = 0x38, type = "Int32" },
    ["totalCollectedValue"] = { offset = 0x3C, type = "Int32" },
    ["totalValue"] = { offset = 0x40, type = "Int32" },
    ["endTimestamp"] = { offset = 0x44, type = "Int32" },
}

local leaderboardItemDataElements = {
    ["playerId"] = { offset = 0x18, type = "String" },
    ["playerName"] = { offset = 0x20, type = "String" },
    ["time"] = { offset = 0x28, type = "Float" },
    ["distance"] = { offset = 0x2C, type = "Float" },
    ["levelId"] = { offset = 0x30, type = "String" },
    ["points"] = { offset = 0x38, type = "Int32" },
    ["finishingStatus"] = { offset = 0x3C, type = "Int32" },
    ["sessionId"] = { offset = 0x40, type = "String" },
    ["replayId"] = { offset = 0x48, type = "String" },
    ["flag"] = { offset = 0x50, type = "String" },
    ["vehicleId"] = { offset = 0x58, type = "String" },
    ["retryCount"] = { offset = 0x60, type = "Int32" },
    ["result"] = { offset = 0x64, type = "Float" },
    ["teamId"] = { offset = 0x68, type = "String" },
    ["resultType"] = { offset = 0x70, type = "Int32" },
    ["raceIndex"] = { offset = 0x74, type = "Int32" },
}

local tournamentPlayerStatusElements = {
    ["tournamentId"] = { offset = 0x18, type = "String" },
    ["sessionId"] = { offset = 0x20, type = "String" },
    ["remainingAttempts"] = { offset = 0x28, type = "Array", elementType = "Int32", elementStride = 0x4 },
}

local rewardStatusElements = {
    ["id"] = { offset = 0x18, type = "String" },
    ["state"] = { offset = 0x20, type = "Int32" },
    ["startTimestamp"] = { offset = 0x24, type = "Int32" },
    ["vehicleId"] = { offset = 0x28, type = "String" },
    ["type"] = { offset = 0x30, type = "Int32" },
    ["target"] = { offset = 0x34, type = "Int32" },
    ["duration"] = { offset = 0x38, type = "Int32" },
    ["specialCupRewardTypeIndex"] = { offset = 0x3C, type = "Int32" },
    ["slot"] = { offset = 0x40, type = "Int32" },
    ["level"] = { offset = 0x44, type = "Int32" },
}

local homePropElements = {
    ["typeId"] = { offset = 0x18, type = "String" },
    ["propId"] = { offset = 0x20, type = "String" },
    -- position (0x28) is Vector2Int (two packed int32s) — not mapped yet
}

local roomElements = {
    ["wallId"] = { offset = 0x18, type = "String" },
    ["floorId"] = { offset = 0x20, type = "String" },
    ["rafterId"] = { offset = 0x28, type = "String" },
    ["props"] = { offset = 0x30, type = "Array", elements = homePropElements },
}

return {
    ["playerId"] = {
        offset = 0x30,
        optional = false,
        tracked = true,
        type = "String"
    },
    ["playerName"] = {
        offset = 0x38,
        optional = false,
        tracked = true,
        type = "String"
    },
    ["flag"] = {
        offset = 0x40,
        optional = true,
        tracked = true,
        type = "String"
    },
    ["coins"] = {
        offset = 0x48,
        optional = true,
        tracked = true,
        type = "Int32"
    },
    ["totalCoinsEarned"] = {
        offset = 0x4C,
        optional = true,
        tracked = true,
        type = "Int32"
    },
    ["totalNeckFlips"] = {
        offset = 0x50,
        type = "Int32"
    },
    ["totalBackFlips"] = {
        offset = 0x54,
        type = "Int32"
    },
    ["totalFlips"] = {
        offset = 0x58,
        type = "Int32"
    },
    ["totalFuelCanistersCollected"] = {
        offset = 0x5C,
        type = "Int32"
    },
    ["totalCoinsCollected"] = {
        offset = 0x60,
        type = "Int32"
    },
    ["totalDistance"] = {
        offset = 0x64,
        type = "Float"
    },
    ["totalPlayTime"] = {
        offset = 0x68,
        type = "Float"
    },
    ["lastRaceTimestamp"] = {
        offset = 0x6C,
        type = "Float"
    },
    ["completedMissions"] = {
        offset = 0x70, -- Timerise
        type = "Array",
        elements = missionStatusElements,
    },  -- MissionStatus
    ["activeLevelMissions"] = {
        offset = 0x88, -- was 0x80 (Timerise); dump says 0x88
        type = "Array",
        elements = missionStatusMapElements,
    },  -- MissionStatusMap
    ["qualifyBests"] = {
        offset = 0xA0,
        type = "Array",
        elements = qualifyTimeElements,
    },  -- QualifyTime
    ["vehicleStatus"] = {
        offset = 0xB8,
        type = "Array",
        elements = {
            ["vehicleId"] = { offset = 0x18, type = "String" },
            ["upgrades"] = {
                offset = 0x20,
                type = "Array",
                elements = {
                    ["upgradeId"] = { offset = 0x18, type = "String" },
                    ["level"] = { offset = 0x20, type = "Int32" },
                    ["maxLevel"] = { offset = 0x24, type = "Int32" },
                },
            },
            ["customizations"] = {
                offset = 0x38,
                type = "Array",
                elements = {
                    ["id"] = { offset = 0x18, type = "String" },
                    ["value"] = { offset = 0x20, type = "String" },
                },
            },
            ["vehicleStats"] = {
                offset = 0x50,
                type = "Object",
                ["levelStars"] = {
                    offset = 0x18,
                    type = "Array",
                    elements = stringIntMapElements,
                },
                ["levelDivisionMedals"] = {
                    offset = 0x30,
                    type = "Array",
                    elements = stringIntMapElements,
                },
                ["flips"] = { offset = 0x48, type = "Int32" },
                ["backflips"] = { offset = 0x4C, type = "Int32" },
                ["neckflips"] = { offset = 0x50, type = "Int32" },
                ["airtime"] = { offset = 0x54, type = "Float" },
                ["wheelieTime"] = { offset = 0x58, type = "Float" },
                ["racesFinished"] = { offset = 0x5C, type = "Int32" },
                ["racesWon"] = { offset = 0x60, type = "Int32" },
                ["totalDistance"] = { offset= 0x64, type = "Int32" },
                ["challengesWon"] = { offset = 0x68, type = "Int32" },
                ["featuredChallengesWon"] = { offset = 0x6C, type = "Int32" },
                ["recentUsage"] = {
                    offset = 0x70,
                    type = "Array",
                    elements = {
                        ["daysSinceEpoch"] = { offset = 0x18, type = "Int32" },
                        ["raceStarts"] = { offset = 0x1C, type = "Int32" },
                        ["distanceStarts"] = { offset = 0x20, type = "Int32" },
                        ["eventStarts"] = { offset = 0x24, type = "Int32" },
                        ["totalDistance"] = { offset = 0x28, type = "Int32" },
                    },
                },
            },
            ["tuningParts"] = {
                offset = 0x58,
                type = "Array",
                elements = {
                    ["id"] = { offset = 0x18, type = "String" },
                    ["level"] = { offset = 0x20, type = "Int32" },
                    ["progressSteps"] = { offset = 0x24, type = "Int32" },
                    ["isNewUnlock"] = { offset = 0x30, type = "Bool" },
                    ["maxLevel"] = { offset = 0x34, type = "Int32" },
                },
            },
            ["equippedTuningParts"] = {
                offset = 0x70,
                type = "Array",
                elementType = "String",
            },
            ["distanceHighscores"] = {
                offset = 0x88,
                type = "Array",
                elements = distanceHighscoreElements,
            },
            ["timeTrialHighscores"] = {
                offset = 0xA0,
                type = "Array",
                elements = timeTrialHighscoreElements,
            },
            ["unlockedEquipSlotsCount"] = { offset = 0xE8, type = "Int32" },
            ["newDistanceHighscores"] = {
                offset = 0xB8,
                type = "Array",
                elements = distanceHighscoreElements,
            },
            ["newTimeTrialHighscores"] = {
                offset = 0xD0,
                type = "Array",
                elements = timeTrialHighscoreElements,
            },
            ["distanceTarget"] = {
                offset = 0xF0,
                type = "Array",
                elements = stringIntMapElements,
            },
            ["tuningPartPresets"] = {
                offset = 0x108,
                type = "Array",
                elements = {
                    ["equippedParts"] = {
                        offset = 0x18,
                        type = "Array",
                        elementType = "String"
                    },
                },
            },
            ["selectedPresetIndex"] = {
                offset = 0xEC,
                type = "Int32",
            },
            ["vehiclePower"] = {
                offset = 0x140,
                type = "Int32",
            },
            ["masteryStatus"] = {
                offset = 0x120,
                type = "Array",
                elements =  {
                    ["unlocked"] = { offset = 0x18, type = "Bool" },
                    ["purchased"] = { offset = 0x19, type = "Bool" },
                    ["enabled"] = { offset = 0x1A, type = "Bool" },
                    ["progressStartTimestamp"] = { offset = 0x1C, type = "Int32" },
                },
            },
            ["masteryXp"] = {
                offset = 0x138,
                type = "SafeInt32",
            },
            ["currentVehicleWinStreak"] = {
                offset = 0x144,
                type = "Int32",
            },
            ["bestVehicleWinStreak"] = {
                offset = 0x190,
                type = "Int32",
            },
        },
    },  -- VehicleStatus
    ["totalChampionshipPoints"] = {
        offset = 0xD0,
        type = "Int32"
    },
    ["currentDailyBestPoints"] = {
        offset = 0xD4,
        type = "Int32"
    },
    ["dailyBestPoints"] = {
        offset = 0xD8,
        type = "Array",
        elements = racePointsElements,
    },  -- RacePoints
    ["tournamentRaceBests"] = {
        offset = 0xF0,
        type = "Array",
        elements = leaderboardItemDataElements,
    },  -- LeaderboardItemData
    ["activeTournaments"] = {
        offset = 0x108,
        type = "Array",
        elements = tournamentPlayerStatusElements,
    },  -- TournamentPlayerStatus
    ["diamonds"] = {
        offset = 0x120,
        type = "Int32"
    },
    ["ladderPoints"] = {
        offset = 0x124,
        type = "Int32"
    },
    ["playerXp"] = {
        offset = 0x128,
        type = "Int32"
    },
    ["dailyMissionsFilledTimeStamp"] = {
        offset = 0x12C,
        type = "Int32"
    },
    ["dailyMissionChangesFilledTimeStamp"] = {
        offset = 0x130,
        type = "Int32"
    },
    ["availableDailyMissionChanges"] = {
        offset = 0x134,
        type = "Int32"
    },
    ["completedDailyMissions"] = {
        offset = 0x138,
        type = "Array",
        elements = missionStatusElements,
    },  -- MissionStatus
    ["activeDailyMissions"] = {
        offset = 0x150,
        type = "Array",
        elements = missionStatusElements,
    },  -- MissionStatus
    ["driver"] = {
        offset = 0x168,
        type = "Object",
        ["head"] = { offset = 0x18, type = "String" },
        ["body"] = { offset = 0x20, type = "String" },
        ["legs"] = { offset = 0x28, type = "String" },
        ["hat"] = { offset = 0x30, type = "String" },
        ["bodyAttachment"] = { offset = 0x38, type = "String" },
        ["profileAnimation"] = { offset = 0x40, type = "String" },
        ["podiumWinAnimation"] = { offset = 0x48, type = "String" },
        ["podiumLoseAnimation"] = { offset = 0x50, type = "String" },
    },
    ["levelStars"] = {
        offset = 0x170,
        type = "Array",
        elements = stringIntMapElements,
    },
    ["unlocks"] = {
        offset = 0x188,
        type = "Array",
        elements = {
            ["type"] = { offset = 0x20, type = "Enum", enum = "UnlockType" },
            ["id"] = { offset = 0x18, type = "String" },
            ["unlockState"] = { offset = 0x24, type = "Int32" },
            ["unlockType"] = { offset = 0x30, type = "Int32" },
            ["vehicleId"] = { offset = 0x28, type = "String" },
        },
    },
    ["chips"] = {
        offset = 0x1A0,
        type = "Int32"
    },
    ["totalAirtime"] = {
        offset = 0x1A4,
        type = "Int32"
    },
    ["totalWheelieTime"] = {
        offset = 0x1A8,
        type = "Int32"
    },
    ["totalRacesFinished"] = {
        offset = 0x1AC,
        type = "Int32"
    },
    ["myDivisions"] = {
        offset = 0x1B0,
        type = "Array", 
        elements = stringIntMapElements,
    },
    ["selectedLevel"] = {
        offset = 0x1C8,
        type = "Int32"
    },
    ["WCRank"] = {
        offset = 0x1CC,
        optional = true,
        type = "Float"
    },
    ["ownedWorlds"] = {
        offset = 0x1D0,
        type = "Array",
        elementType = "String",
    },
    ["AllowedLevelTier"] = {
        offset = 0x1E8,
        type = "Int32"
    },
    ["totalDistanceStarts"] = {
        offset = 0x1EC,
        type = "Int32"
    },
    ["totalRaceStarts"] = {
        offset = 0x1F0,
        type = "Int32"
    },
    ["totalRaceVictories"] = {
        offset = 0x1F4,
        type = "Int32"
    },
    ["rewardManagerStatus"] = {
        offset = 0x1F8,
        type = "Object",
        ["rewards"] = { offset = 0x18, type = "Array", elements = rewardStatusElements },
        ["nextRewardTimestamp"] = { offset = 0x30, type = "Int32" },
        ["nextVideoAdTimestamp"] = { offset = 0x34, type = "Int32" },
        ["dailyToolbox"] = {
            offset = 0x38,
            type = "Object",
            ["state"] = { offset = 0x18, type = "Int32" },
            ["startTimestamp"] = { offset = 0x1C, type = "Int32" },
            ["progress"] = { offset = 0x20, type = "Int32" },
        },
        ["nextFreeChestTimestamp"] = { offset = 0x40, type = "Int32" },
        ["videoSkipSpecialCupsRemaining"] = { offset = 0x44, type = "Int32" },
        ["nextVideoSkipsTimestamp"] = { offset = 0x48, type = "Int32" },
        ["currentSpecialCupRewardIndex"] = { offset = 0x4C, type = "Int32" },
        ["distanceRewards"] = { offset = 0x50, type = "Array", elements = rewardStatusElements },
        ["videoSkipScrapperRemaining"] = { offset = 0x68, type = "Int32" },
        ["nextVideoSkipScrapperTimestamp"] = { offset = 0x6C, type = "Int32" },
        ["videoSkipTeamEventTicketsRemaining"] = { offset = 0x70, type = "Int32" },
        ["nextVideoSkipTeamEventTicketTimestamp"] = { offset = 0x74, type = "Int32" },
        ["videoSkipEventTicketsRemaining"] = { offset = 0x78, type = "Int32" },
        ["nextVideoSkipEventTicketTimestamp"] = { offset = 0x7C, type = "Int32" },
        ["nextVideoChestTimestamp"] = { offset = 0x80, type = "Int32" },
        ["distanceVideoRewardsRemaining"] = { offset = 0x84, type = "Int32" },
        ["videoMultipliedCoinsCollected"] = { offset = 0x88, type = "Int32" },
        ["nextVideoCoinMultiplierTimestamp"] = { offset = 0x8C, type = "Int32" },
        ["activeDistanceReward"] = {
            offset = 0x90,
            type = "Object",
            ["id"] = { offset = 0x18, type = "String" },
            ["state"] = { offset = 0x20, type = "Int32" },
            ["startTimestamp"] = { offset = 0x24, type = "Int32" },
            ["vehicleId"] = { offset = 0x28, type = "String" },
            ["type"] = { offset = 0x30, type = "Int32" },
            ["target"] = { offset = 0x34, type = "Int32" },
            ["duration"] = { offset = 0x38, type = "Int32" },
            ["specialCupRewardTypeIndex"] = { offset = 0x3C, type = "Int32" },
            ["slot"] = { offset = 0x40, type = "Int32" },
            ["level"] = { offset = 0x44, type = "Int32" },
        },
        ["distanceRewardsRemaining"] = { offset = 0x98, type = "Int32" },
        ["nextDistanceRewardsTimestamp"] = { offset = 0x9C, type = "Int32" },
        ["videoDoubleEventPointsRemaining"] = { offset = 0xA0, type = "Int32" },
        ["nextVideoDoubleEventPointsTimestamp"] = { offset = 0xA4, type = "Int32" },
        ["previousConsumedXPromo"] = { offset = 0xA8, type = "String" },
        ["chestRandomCounter"] = { offset = 0xB0, type = "Array", elementType = "Int32", elementStride = 0x4 },
        ["videoChestsRemaining"] = { offset = 0xC0, type = "Int32" },
    },  -- RewardManagerStatus
    ["maxWCRank"] = {
        offset = 0x200,
        type = "Float"
    },
    ["nextFreeUpgradeTimestamp"] = {
        offset = 0x204,
        type = "Int32"
    },
    ["unlockedRaces"] = {
        offset = 0x208,
        type = "Array",
        elementType = "String",
    },
    ["totalTime"] = {
        offset = 0x238,
        type = "Int32"
    },
    ["unlockedVehicles"] = {
        offset = 0x220,
        type = "Array",
        elementType = "String",
    },
    ["totalGemsEarned"] = {
        offset = 0x23C,
        type = "Int32"
    },
    ["recentChallenges"] = {
        offset = 0x240,
        type = "Array",
        elementType = "String",
    },
    ["achievements"] = {
        offset = 0x258,
        type = "Array",
        elements = {
            ["id"] = { offset = 0x18, type = "Int32" },
            ["unlocked"] = { offset = 0x1C, type = "Bool" },
            ["steps"] = { offset = 0x20, type = "Int32" },
        },
    },
    ["totalCupVictories"] = {
        offset = 0x270,
        type = "Int32"
    },
    ["cloudSaveVersion"] = {
        offset = 0x274,
        type = "Int32"
    },
    ["ratingsAsked"] = {
        offset = 0x278,
        type = "Int32"
    },
    ["ratingEventCounter"] = {
        offset = 0x27C,
        type = "Int32"
    },
    ["tutorialState"] = {
        offset = 0x280,
        type = "Int32"
    },
    ["totalCupsFinished"] = {
        offset = 0x284,
        type = "Int32"
    },
    ["adFree"] = {
        offset = 0x3DC,
        type = "Bool"
    },
    ["purchasedSpecialOffers"] = {
        offset = 0x288,
        type = "Array",
        elementType = "String",
    },
    ["teamId"] = {
        offset = 0x2A0,
        type = "String"
    },
    ["activeFriendlyRaces"] = {
        offset = 0x2A8,
        type = "Array",
        elements = friendlyRaceElements,
    },  -- FriendlyRace
    ["cheater"] = {
        offset = 0x3DD,
        type = "Bool"
    },
    ["currentCupId"] = {
        offset = 0x2C0,
        type = "String"
    },
    ["deviceSignature"] = {
        offset = 0x2C8,
        type = "String"
    },
    ["deviceHash"] = {
        offset = 0x2D0, -- was 0x2C8; dump: devicesignature_ 0x2c8, devicehash_ 0x2d0
        type = "String"
    },
    ["currentSpecialEventId"] = {
        offset = 0x2D8,
        type = "String"
    },
    ["contentVersion"] = {
        offset = 0x300,
        type = "Int32"
    },
    ["seasonStatus"] = {
        offset = 0x2E0,
        type = "Object",
        ["highestRank"] = { offset = 0x18, type = "Float" },
        ["startRank"] = { offset = 0x1C, type = "Float" },
        ["seasonId"] = { offset = 0x20, type = "String" },
        ["endTimestamp"] = { offset = 0x28, type = "Int32" },
        ["ended"] = { offset = 0x2C, type = "Bool" },
        ["premiumUnlocked"] = { offset = 0x2D, type = "Bool" },
        ["bonusChestClaimed"] = { offset = 0x2E, type = "Bool" },
        ["premiumProgressClaimed"] = { offset = 0x2F, type = "Bool" },
        ["receivedRewards"] = { offset = 0x30, type = "Array", elementType = "String" },
        ["animatedRank"] = { offset = 0x48, type = "Float" },
        ["premiumTierUnlocked"] = { offset = 0x4C, type = "Int32" },
    },  -- SeasonStatus
    ["purchasedIaps"] = {
        offset = 0x2E8,
        type = "Array",
        elements = iapPurchaseEventElements,
    },  -- IapPurchaseEvent
    ["acsPlayerGuid"] = {
        offset = 0x308,
        type = "String"
    },
    ["challengesWon"] = {
        offset = 0x304,
        type = "Int32"
    },
    ["featuredChallengesWon"] = {
        offset = 0x310,
        type = "Int32"
    },
    ["totalRank"] = {
        offset = 0x314,
        type = "Float"
    },
    ["nameChanges"] = {
        offset = 0x318,
        type = "Int32"
    },
    ["nextFreeTuningPartUpgradeTimestamp"] = {
        offset = 0x31C,
        type = "Int32"
    },
    ["activeEventStatus"] = {
        offset = 0x320,
        type = "Object",
        ["instanceId"] = { offset = 0x18, type = "String" },
        ["eventId"] = { offset = 0x20, type = "String" },
        ["expirationTimestamp"] = { offset = 0x28, type = "Int32" },
        ["eventPoints"] = { offset = 0x2C, type = "Int32" },
        ["collectedRewardIndexes"] = { offset = 0x30, type = "Array", elementType = "Int32", elementStride = 0x4 },
        ["activeSessionId"] = { offset = 0x40, type = "String" },
        ["tickets"] = { offset = 0x48, type = "Int32" },
        ["lastTicketsRefillTime"] = { offset = 0x4C, type = "Int32" },
        ["spentTickets"] = { offset = 0x50, type = "Int32" },
        ["totalEventRaces"] = { offset = 0x54, type = "Int32" },
        ["latestSessionRaces"] = { offset = 0x58, type = "Int32" },
        ["eventPointsUnlockProgress"] = { offset = 0x5C, type = "Int32" },
        ["teamId"] = { offset = 0x60, type = "String" },
        -- fixedVehicleStatus (0x68) is RepeatedPtrField<VehicleStatus>;
        -- the vehicleStatus element template lives inline on the
        -- vehicleStatus entry above, so no reader is attached here.
        ["eventName"] = { offset = 0x80, type = "String" },
        ["eventButtonBackground"] = { offset = 0x88, type = "String" },
        ["shownOfferIds"] = { offset = 0x90, type = "Array", elementType = "String" },
        ["spentSpecialTickets"] = { offset = 0xA8, type = "Int32" },
        ["spentEventPoints"] = { offset = 0xAC, type = "Int32" },
        ["collectedMainRewardIndexes"] = { offset = 0xB0, type = "Array", elementType = "Int32", elementStride = 0x4 },
        ["collectedRotatingRewardIndexes"] = { offset = 0xC0, type = "Array", elementType = "Int32", elementStride = 0x4 },
        ["levelId"] = { offset = 0xD0, type = "String" },
        ["videosWatched"] = { offset = 0xD8, type = "Int32" },
        ["hasUnlimitedTicket"] = { offset = 0xDC, type = "Bool" },
        ["hasScoreDoubled"] = { offset = 0xDD, type = "Bool" },
        ["hasEventPass"] = { offset = 0xDE, type = "Bool" },
        ["allBoosters"] = { offset = 0xE0, type = "Array", elementType = "String" },
        ["eventPointsPrev"] = { offset = 0xF8, type = "Int32" },
        ["totalSessionsJoined"] = { offset = 0xFC, type = "Int32" },
        -- activeBoosters (0x100) is RepeatedPtrField<ActiveBooster> — layout not yet mapped
        ["boosterFreeShopItems"] = { offset = 0x118, type = "Array", elementType = "String" },
        ["randomBoosterSelection"] = { offset = 0x130, type = "Array", elementType = "String" },
        ["activeSessionBonusVehicles"] = { offset = 0x148, type = "Array", elementType = "String" },
        ["pendingMultichoiceChestVehicles"] = { offset = 0x160, type = "Array", elementType = "String" },
        ["specialFeatureUpgrades"] = { offset = 0x178, type = "Array", elements = upgradeStatusElements },
        ["collectedSpecialsRewardIndexes"] = { offset = 0x190, type = "Array", elementType = "Int32", elementStride = 0x4 },
        ["boosterClaimedAtSession"] = { offset = 0x1A0, type = "Int32" },
    },  -- EventStatus
    ["flags"] = {
        offset = 0x328,
        type = "BitMask",
        enum = "GameStatusFlag"
    },
    ["ownedVehicles"] = {
        offset = 0x330,
        type = "Array",
        elementType = "String",
    },
    ["nextVehicleChestTimestamp"] = {
        offset = 0x348,
        type = "Int32"
    },
    ["vehicleChestsPurchased"] = {
        offset = 0x34C,
        type = "Int32"
    },
    ["gachaNewVehicleCounter"] = {
        offset = 0x368,
        type = "Int32"
    },
    ["purchasedPopupOffers"] = {
        offset = 0x350,
        type = "Array",
        elementType = "String",
    },
    ["activePopupOffer"] = {
        offset = 0x370,
        type = "String"
    },
    ["activePopupOfferEndTimestamp"] = {
        offset = 0x36C,
        type = "Int32"
    },
    ["expiredPopupOffers"] = {
        offset = 0x378,
        type = "Array",
        elementType = "String",
    },
    ["pendingChests"] = {
        offset = 0x390,
        type = "Array",
        elements = pendingChestElements,
    },  -- PendingChest
    ["libHash"] = {
        offset = 0x3B0,
        type = "Int32"
    },
    ["vipStatus"] = {
        offset = 0x3A8,
        type = "Object",
        ["isVip"] = { offset = 0x2C, type = "Bool" },
        ["vipSkipCupsRemaining"] = { offset = 0x1C, type = "Int32" },
        ["nextVipSkipTimestamp"] = { offset = 0x20, type = "Int32" },
        ["autoRenew"] = { offset = 0x2D, type = "Bool" },
        ["vipTier"] = { offset = 0x30, type = "String" },
        ["vipSkipScrapperRemaining"] = { offset = 0x38, type = "Int32" },
        ["nextVipSkipScrapperTimestamp"] = { offset = 0x3C, type = "Int32" },
        ["vipSkipTeamEventTicketsRemaining"] = { offset = 0x40, type = "Int32" },
        ["nextVipSkipTeamEventTicketTimeStamp"] = { offset = 0x44, type = "Int32" },
        ["vipSkipEventTicketsRemaining"] = { offset = 0x48, type = "Int32" },
        ["nextVipSkipEventTicketTimeStamp"] = { offset = 0x4C, type = "Int32" },
        ["hasBeenVipBefore"] = { offset = 0x2E, type = "Bool" },
        ["manuallyEnabled"] = { offset = 0x50, type = "Bool" } -- was 0x2E; dump: hasbeenvipbefore_ 0x2e, manuallyenabled_ 0x50
    },
    ["totalEventsJoined"] = {
        offset = 0x3B4,
        type = "Int32"
    },
    ["totalEventPoints"] = {
        offset = 0x3B8,
        type = "Int32"
    },
    ["totalEventRaces"] = {
        offset = 0x3BC,
        type = "Int32"
    },
    ["totalEarnedTickets"] = {
        offset = 0x3C0,
        type = "Int32"
    },
    ["totalSpentTickets"] = {
        offset = 0x3C4,
        type = "Int32"
    },
    ["device"] = {
        offset = 0x3C8,
        type = "String"
    },
    ["os"] = {
        offset = 0x3D0,
        type = "String"
    },
    ["totalEventRacesWon"] = {
        offset = 0x3D8,
        type = "Int32"
    },
    ["rentedVehicles"] = {
        offset = 0x3E0,
        type = "Array",
        elements = rentalStatusElements,
    },  -- RentalStatus
    ["unlockedWorlds"] = {
        offset = 0x3F8,
        type = "Array",
        elementType = "String",
    },
    ["segmentId"] = {
        offset = 0x410,
        type = "String"
    },
    ["playerSegments"] = {
        offset = 0x418,
        type = "String"
    },
    ["checkinReward"] = {
        offset = 0x420,
        type = "Object",
        ["id"] = { offset = 0x18, type = "String" },
        ["rewardIndex"] = { offset = 0x20, type = "Int32" },
        ["lastCollectedTimestamp"] = { offset = 0x24, type = "Int32" },
        ["startTimestamp"] = { offset = 0x28, type = "Int32" },
        ["endTimestamp"] = { offset = 0x2C, type = "Int32" },
        ["claimedRewards"] = { offset = 0x30, type = "Array", elementType = "Int32", elementStride = 0x4 },
        ["allowDaySkip"] = { offset = 0x40, type = "Bool" },
        ["updateRewardIndexAfterSkip"] = { offset = 0x41, type = "Bool" },
        ["minCollectInterval"] = { offset = 0x44, type = "Int32" },
        ["maxCollectInterval"] = { offset = 0x48, type = "Int32" },
        ["shuffleKey"] = { offset = 0x4C, type = "Int32" },
    },  -- CheckinReward
    ["seasonRank"] = {
        offset = 0x428,
        type = "Float"
    },
    ["totalSeasonRank"] = {
        offset = 0x42C,
        type = "Float"
    },
    ["bestSeasonRank"] = {
        offset = 0x438,
        type = "Float"
    },
    ["currentSeasonId"] = {
        offset = 0x430,
        type = "String"
    },
    ["totalEventRaceStarts"] = {
        offset = 0x43C,
        type = "Int32"
    },
    ["createTimestamp"] = {
        offset = 0x458,
        type = "Int32"
    },
    ["deals"] = {
        offset = 0x440,
        type = "Array",
        elements = dealStatusElements,
    },  -- DealStatus
    ["scrap"] = {
        offset = 0x45C,
        type = "Int32"
    },
    ["scrapperStatus"] = {
        offset = 0x460,
        type = "Object",
        ["readyTimestamp"] = { offset = 0x18, type = "Int32" },
        ["partsIn"] = { offset = 0x1C, type = "Int32" },
        ["scrapOut"] = { offset = 0x20, type = "Int32" },
        ["isUnlocked"] = { offset = 0x24, type = "Bool" },
        ["isExcessTutorialShown"] = { offset = 0x25, type = "Bool" },
    },  -- ScrapperStatus
    ["totalScrapEarned"] = {
        offset = 0x480,
        type = "Int32"
    },
    ["oldSeasons"] = {
        offset = 0x468,
        type = "Array",
        elements = seasonStatusElements,
    },  -- SeasonStatus
    ["targetedAdsConsent"] = {
        offset = 0x484,
        type = "Int32"
    },
    ["acceptedEulaVersion"] = {
        offset = 0x4A8,
        type = "Int32"
    },
    ["activePopupOffers"] = {
        offset = 0x488,
        type = "Array",
        elements = activePopupOfferElements,
    },  -- ActivePopupOffer
    ["activeTeamEventStatus"] = {
        offset = 0x4A0,
        type = "Object",
        ["instanceId"] = { offset = 0x18, type = "String" },
        ["eventId"] = { offset = 0x20, type = "String" },
        ["expirationTimestamp"] = { offset = 0x28, type = "Int32" },
        ["eventPoints"] = { offset = 0x2C, type = "Int32" },
        ["collectedRewardIndexes"] = { offset = 0x30, type = "Array", elementType = "Int32", elementStride = 0x4 },
        ["activeSessionId"] = { offset = 0x40, type = "String" },
        ["tickets"] = { offset = 0x48, type = "Int32" },
        ["lastTicketsRefillTime"] = { offset = 0x4C, type = "Int32" },
        ["spentTickets"] = { offset = 0x50, type = "Int32" },
        ["totalEventRaces"] = { offset = 0x54, type = "Int32" },
        ["latestSessionRaces"] = { offset = 0x58, type = "Int32" },
        ["eventPointsUnlockProgress"] = { offset = 0x5C, type = "Int32" },
        ["teamId"] = { offset = 0x60, type = "String" },
        -- fixedVehicleStatus (0x68) is RepeatedPtrField<VehicleStatus>;
        -- the vehicleStatus element template lives inline on the
        -- vehicleStatus entry above, so no reader is attached here.
        ["eventName"] = { offset = 0x80, type = "String" },
        ["eventButtonBackground"] = { offset = 0x88, type = "String" },
        ["shownOfferIds"] = { offset = 0x90, type = "Array", elementType = "String" },
        ["spentSpecialTickets"] = { offset = 0xA8, type = "Int32" },
        ["spentEventPoints"] = { offset = 0xAC, type = "Int32" },
        ["collectedMainRewardIndexes"] = { offset = 0xB0, type = "Array", elementType = "Int32", elementStride = 0x4 },
        ["collectedRotatingRewardIndexes"] = { offset = 0xC0, type = "Array", elementType = "Int32", elementStride = 0x4 },
        ["levelId"] = { offset = 0xD0, type = "String" },
        ["videosWatched"] = { offset = 0xD8, type = "Int32" },
        ["hasUnlimitedTicket"] = { offset = 0xDC, type = "Bool" },
        ["hasScoreDoubled"] = { offset = 0xDD, type = "Bool" },
        ["hasEventPass"] = { offset = 0xDE, type = "Bool" },
        ["allBoosters"] = { offset = 0xE0, type = "Array", elementType = "String" },
        ["eventPointsPrev"] = { offset = 0xF8, type = "Int32" },
        ["totalSessionsJoined"] = { offset = 0xFC, type = "Int32" },
        -- activeBoosters (0x100) is RepeatedPtrField<ActiveBooster> — layout not yet mapped
        ["boosterFreeShopItems"] = { offset = 0x118, type = "Array", elementType = "String" },
        ["randomBoosterSelection"] = { offset = 0x130, type = "Array", elementType = "String" },
        ["activeSessionBonusVehicles"] = { offset = 0x148, type = "Array", elementType = "String" },
        ["pendingMultichoiceChestVehicles"] = { offset = 0x160, type = "Array", elementType = "String" },
        ["specialFeatureUpgrades"] = { offset = 0x178, type = "Array", elements = upgradeStatusElements },
        ["collectedSpecialsRewardIndexes"] = { offset = 0x190, type = "Array", elementType = "Int32", elementStride = 0x4 },
        ["boosterClaimedAtSession"] = { offset = 0x1A0, type = "Int32" },
    },  -- EventStatus
    ["teamStatus"] = {
        offset = 0x4B0,
        type = "Object",
        ["collectedTeamChests"] = { offset = 0x18, type = "Array", elementType = "Int32", elementStride = 0x4 },
        ["joinedToTeamTimestamp"] = { offset = 0x28, type = "Int32" },
        ["pendingTeamChestContribution"] = { offset = 0x2C, type = "Float" },
        ["numberOfTeamJoins"] = { offset = 0x30, type = "Int32" },
        ["numberOfKickedOut"] = { offset = 0x34, type = "Int32" },
        ["reportedMessages"] = { offset = 0x38, type = "Array", elementType = "String" },
        ["currentTeamDonations"] = { offset = 0x50, type = "SafeInt32" },
        ["collectedTeamBossChests"] = { offset = 0x58, type = "Array", elementType = "Int32", elementStride = 0x4 },
        ["waitingJoinLeaveResponse"] = { offset = 0x68, type = "Bool" },
        ["waitingCreateResponse"] = { offset = 0x69, type = "Bool" },
    },  -- TeamStatus
    ["specialTickets"] = {
        offset = 0x4AC,
        type = "Int32"
    },
    ["totalEarnedSpecialTickets"] = {
        offset = 0x4B8,
        type = "Int32"
    },
    ["totalSpentSpecialTickets"] = {
        offset = 0x4BC,
        type = "Int32"
    },
    ["kickedTeamStatus"] = {
        offset = 0x4C0,
        type = "Object",
        ["teamEventId"] = { offset = 0x18, type = "String" },
        ["teamId"] = { offset = 0x20, type = "String" },
        ["sessionId"] = { offset = 0x28, type = "String" },
        ["teamTicketsRefillTime"] = { offset = 0x30, type = "Int32" },
    },  -- KickedTeamStatus
    ["teamEventOfferShown"] = {
        offset = 0x4C8,
        type = "String"
    },
    ["weeklyEventOfferShown"] = {
        offset = 0x4D0,
        type = "String"
    },
    ["playerNameApprovalState"] = {
        offset = 0x4F0,
        type = "Int32",
        enum = "PlayerNameApprovalState"
    },
    ["distanceTickets"] = {
        offset = 0x4D8,
        type = "Array",
        elements = distanceTicketElements,
    },  -- DistanceTicket
    ["previousEventStatuses"] = {
        offset = 0x4F8,
        type = "Array",
        elements = eventStatusElements,
    },  -- EventStatus
    ["garagePower"] = {
        offset = 0x4F4,
        type = "Int32"
    },
    ["premiumWCUnlocked"] = {
        offset = 0x3DE,
        type = "Bool"
    },
    ["receivedWCRewards"] = {
        offset = 0x510,
        type = "Array",
        elementType = "String",
    },
    ["animatedWCRank"] = {
        offset = 0x528,
        type = "Float"
    },
    ["adventurerRank"] = {
        offset = 0x52C,
        type = "Float"
    },
    ["receivedAdventurerRewards"] = {
        offset = 0x530,
        type = "Array",
        elementType = "Int32",
        elementStride = 0x4, -- RepeatedField<int> packs elements at 4 bytes
    },
    ["secret"] = {
        offset = 0x540,
        type = "String"
    },
    ["animatedAdventurerRank"] = {
        offset = 0x568,
        type = "Float"
    },
    ["banData"] = {
        offset = 0x548,
        type = "Array",
        elements = banDataElements,
    },  -- BanData
    ["banReviewed"] = {
        offset = 0x3DF,
        type = "Bool"
    },
    ["teamSeasonStatus"] = {
        offset = 0x560,
        type = "Object",
        ["seasonId"] = { offset = 0x18, type = "String" },
        ["division"] = { offset = 0x20, type = "Int32" },
        ["rank"] = { offset = 0x24, type = "Float" },
        ["previousOpponents"] = { offset = 0x28, type = "Array", elementType = "String" },
        ["startTimestamp"] = { offset = 0x40, type = "Int32" },
        ["endTimestamp"] = { offset = 0x44, type = "Int32" },
        ["finalPlacement"] = { offset = 0x48, type = "Int32" },
        ["subdivision"] = { offset = 0x4C, type = "Int32" },
        ["teamSupportLevel"] = { offset = 0x50, type = "Int32" },
    },  -- TeamSeasonStatus
    ["nonRewardedTeamSeasons"] = {
        offset = 0x570,
        type = "Array",
        elementType = "String",
    },
    ["activeDailyBonusTasks"] = {
        offset = 0x588,
        type = "Array",
        elements = dailyTaskElements,
    },  -- DailyTask
    ["activeDailyTasks"] = {
        offset = 0x5A0,
        type = "Array",
        elements = dailyTaskElements,
    },  -- DailyTask
    ["nextDailyTaskTimeStamp"] = {
        offset = 0x56C,
        type = "Int32"
    },
    ["nextDailyTaskRerollTimeStamp"] = {
        offset = 0x5B8,
        type = "Int32"
    },
    ["dailyTaskRerollsRemaining"] = {
        offset = 0x5BC,
        type = "Int32"
    },
    ["shownGDPRVersion"] = {
        offset = 0x5C0,
        type = "Int32"
    },
    ["dailyTaskRerollsWithVideoRemaining"] = {
        offset = 0x5C4,
        type = "Int32"
    },
    ["pendingofferid"] = {
        offset = 0x5C8,
        type = "String"
    },
    ["pendingOfferIds"] = {
        offset = 0x5D0,
        type = "Array",
        elements = iapPurchaseEventElements,
    },  -- IapPurchaseEvent
    ["dailyTaskRefillsRemaining"] = {
        offset = 0x5E8,
        type = "Array",
        elementType = "Int32",
        elementStride = 0x4, -- RepeatedField<int> packs elements at 4 bytes
    },
    ["currencies"] = {
        offset = 0x5F8,
        type = "Array",
        elements = {
            ["id"] = { offset = 0x18, type = "String" },
            ["amount"] = { offset = 0x20, type = "Int32" },
            ["totalEarned"] = { offset = 0x24, type = "Int32" },
            ["totalSpent"] = { offset = 0x30, type = "Int32" },
            ["safeAmount"] = { offset = 0x28, type = "SafeInt32" },
            ["timesEarned"] = { offset = 0x34, type = "Int32" },
            ["maxEarn"] = { offset = 0x48, type = "Int32" },
            ["iapCount"] = { offset = 0x38, type = "SafeInt32" },
            ["iapAmount"] = { offset = 0x40, type = "SafeInt32" },
        },
    },  -- Currency
    ["publishedLevels"] = {
        offset = 0x610,
        type = "Array",
        elementType = "String",
    },
    ["featuredChallenges"] = {
        offset = 0x628,
        type = "Array",
        elements = featuredChallengeElements,
    },  -- FeaturedChallenge
    ["featuredChallengeIndex"] = {
        offset = 0x640,
        type = "Int32"
    },
    ["nextFreeFeaturedChallengeTimestamp"] = {
        offset = 0x644,
        type = "Int32"
    },
    ["lastPlayerNameChangedTimestamp"] = {
        offset = 0x6A8,
        type = "Int32"
    },
    ["firstPlayerNameChange"] = {
        offset = 0x754,
        type = "Bool"
    },
    ["distanceCollectibles"] = {
        offset = 0x648,
        type = "Array",
        elements = distanceCollectibleStatusElements,
    },  -- DistanceCollectibleStatus
    ["activeCommunityEventStatus"] = {
        offset = 0x660,
        type = "Object",
        ["instanceId"] = { offset = 0x18, type = "String" },
        ["eventId"] = { offset = 0x20, type = "String" },
        ["expirationTimestamp"] = { offset = 0x28, type = "Int32" },
        ["eventPoints"] = { offset = 0x2C, type = "Int32" },
        ["collectedRewardIndexes"] = { offset = 0x30, type = "Array", elementType = "Int32", elementStride = 0x4 },
        ["activeSessionId"] = { offset = 0x40, type = "String" },
        ["tickets"] = { offset = 0x48, type = "Int32" },
        ["lastTicketsRefillTime"] = { offset = 0x4C, type = "Int32" },
        ["spentTickets"] = { offset = 0x50, type = "Int32" },
        ["totalEventRaces"] = { offset = 0x54, type = "Int32" },
        ["latestSessionRaces"] = { offset = 0x58, type = "Int32" },
        ["eventPointsUnlockProgress"] = { offset = 0x5C, type = "Int32" },
        ["teamId"] = { offset = 0x60, type = "String" },
        -- fixedVehicleStatus (0x68) is RepeatedPtrField<VehicleStatus>;
        -- the vehicleStatus element template lives inline on the
        -- vehicleStatus entry above, so no reader is attached here.
        ["eventName"] = { offset = 0x80, type = "String" },
        ["eventButtonBackground"] = { offset = 0x88, type = "String" },
        ["shownOfferIds"] = { offset = 0x90, type = "Array", elementType = "String" },
        ["spentSpecialTickets"] = { offset = 0xA8, type = "Int32" },
        ["spentEventPoints"] = { offset = 0xAC, type = "Int32" },
        ["collectedMainRewardIndexes"] = { offset = 0xB0, type = "Array", elementType = "Int32", elementStride = 0x4 },
        ["collectedRotatingRewardIndexes"] = { offset = 0xC0, type = "Array", elementType = "Int32", elementStride = 0x4 },
        ["levelId"] = { offset = 0xD0, type = "String" },
        ["videosWatched"] = { offset = 0xD8, type = "Int32" },
        ["hasUnlimitedTicket"] = { offset = 0xDC, type = "Bool" },
        ["hasScoreDoubled"] = { offset = 0xDD, type = "Bool" },
        ["hasEventPass"] = { offset = 0xDE, type = "Bool" },
        ["allBoosters"] = { offset = 0xE0, type = "Array", elementType = "String" },
        ["eventPointsPrev"] = { offset = 0xF8, type = "Int32" },
        ["totalSessionsJoined"] = { offset = 0xFC, type = "Int32" },
        -- activeBoosters (0x100) is RepeatedPtrField<ActiveBooster> — layout not yet mapped
        ["boosterFreeShopItems"] = { offset = 0x118, type = "Array", elementType = "String" },
        ["randomBoosterSelection"] = { offset = 0x130, type = "Array", elementType = "String" },
        ["activeSessionBonusVehicles"] = { offset = 0x148, type = "Array", elementType = "String" },
        ["pendingMultichoiceChestVehicles"] = { offset = 0x160, type = "Array", elementType = "String" },
        ["specialFeatureUpgrades"] = { offset = 0x178, type = "Array", elements = upgradeStatusElements },
        ["collectedSpecialsRewardIndexes"] = { offset = 0x190, type = "Array", elementType = "Int32", elementStride = 0x4 },
        ["boosterClaimedAtSession"] = { offset = 0x1A0, type = "Int32" },
    },  -- EventStatus
    ["currentPublicLevels"] = {
        offset = 0x668,
        type = "Array",
        elementType = "String",
    },
    ["unlockedEditorThemes"] = {
        offset = 0x680,
        type = "Array",
        elementType = "String",
    },
    ["FSHomeProfileID"] = {
        offset = 0x698,
        type = "String"
    },
    ["home"] = {
        offset = 0x6A0,
        type = "Object",
        ["rooms"] = { offset = 0x18, type = "Array", elements = roomElements },
    },  -- Home
    ["ownedHomeProps"] = {
        offset = 0x6B0,
        type = "Array",
        elements = homeCosmeticsOwnershipElements,
    },  -- HomeCosmeticsOwnership
    ["ownedHomeBackgrounds"] = {
        offset = 0x6C8,
        type = "Array",
        elements = homeCosmeticsOwnershipElements,
    },  -- HomeCosmeticsOwnership
    ["megaAdChestRewards"] = {
        offset = 0x6E0,
        type = "Array",
        elements = megaAdChestRewardStatusElements,
    },  -- MegaAdChestRewardStatus
    ["activeLeagueTasks"] = {
        offset = 0x6F8,
        type = "Array",
        elements = leagueTaskElements,
    },  -- LeagueTask
    ["communityEvent"] = {
        offset = 0x710,
        type = "Object",
        ["seasonId"] = { offset = 0x18, type = "String" },
        ["results"] = { offset = 0x20, type = "Array", elementType = "Int32", elementStride = 0x4 },
        ["oldSeasons"] = { offset = 0x30, type = "Array", elements = stringIntMapElements },
        ["levelIds"] = { offset = 0x48, type = "Array", elementType = "String" },
        ["levelTimestamps"] = { offset = 0x60, type = "Array", elements = stringIntMapElements },
        ["eventPoints"] = { offset = 0x78, type = "Int32" },
    },
    ["masteryBonusXp"] = {
        offset = 0x718,
        type = "SafeInt32"
    },
    ["safeIntStaticKey"] = {
        offset = 0x6AC,
        type = "Int32"
    },
    ["adFreeEndTimestamp"] = {
        offset = 0x720,
        type = "SafeInt32"
    },
    ["safeCoins"] = {
        offset = 0x728,
        type = "SafeInt32"
    },
    ["safeDiamonds"] = {
        offset = 0x730,
        type = "SafeInt32"
    },
    ["safeScrap"] = {
        offset = 0x738,
        type = "SafeInt32"
    },
    ["megaAdChestMultiplier"] = {
        offset = 0x750,
        type = "Int32"
    },
    ["safeUnlocks"] = {
        offset = 0x740,
        type = "SafeInt32"
    },
    ["safeUnlockedVehicles"] = {
        offset = 0x748,
        type = "SafeInt32"
    },
    ["safeOwnedVehicles"] = {
        offset = 0x758,
        type = "SafeInt32"
    },
    ["safeOwnedWorlds"] = {
        offset = 0x760,
        type = "SafeInt32"
    },
    ["currentWinStreak"] = {
        offset = 0x768,
        type = "SafeInt32"
    },
    ["bestWinStreak"] = {
        offset = 0x770,
        type = "SafeInt32"
    },
    ["pendingWinStreakRestore"] = {
        offset = 0x755,
        type = "Bool"
    },
    ["rankedCupOngoing"] = {
        offset = 0x756,
        type = "Bool"
    },
    ["rankedCupVehicle"] = {
        offset = 0x778,
        type = "String"
    },
    ["supportHmac"] = {
        offset = 0x780,
        type = "String"
    },
    ["megaAdChestProgress"] = {
        offset = 0x788,
        type = "Array",
        elements = megaAdChestProgressElements,
    },  -- MegaAdChestProgress
    ["signatureChallengeId"] = {
        offset = 0x7A0,
        type = "String"
    },
    ["activeTutorialVersion"] = {
        offset = 0x7C0,
        type = "Int32"
    },
    ["adviews"] = {
        offset = 0x7A8,
        type = "Array",
        elements = adViewsMapElements,
    },  -- AdViewsMap
    ["premiumTierWCUnlocked"] = {
        offset = 0x7C4,
        type = "Int32"
    },
    ["premiumProgressWCClaimed"] = {
        offset = 0x757,
        type = "Bool"
    },
    ["currentGachaProgress"] = {
        offset = 0x7C8,
        type = "Object",
        ["pendingReward"] = { offset = 0x18, type = "SafeInt32" },
        ["eventHash"] = { offset = 0x20, type = "Int32" },
        ["totalSpins"] = { offset = 0x24, type = "Int32" },
        ["claimedRewards"] = { offset = 0x28, type = "Array", elementType = "SafeInt32" },
        ["claimedBonusRewards"] = { offset = 0x40, type = "SafeInt32" },
        ["adSpinDay"] = { offset = 0x48, type = "SafeInt32" },
        ["dailyAdSpins"] = { offset = 0x50, type = "SafeInt32" },
        ["safeTotalSpins"] = { offset = 0x58, type = "SafeInt32" },
    },  -- CurrentGachaProgress
    ["claimedResearchRewardAmount"] = {
        offset = 0x7D0,
        type = "Array",
        elementType = "SafeInt32",
    },
    ["claimedResearchDonationAmount"] = {
        offset = 0x7E8,
        type = "SafeInt32"
    },
    ["currentFriendEvent"] = {
        offset = 0x7F0,
        type = "Object",
        ["claimedRewards"] = { offset = 0x18, type = "Array", elementType = "SafeInt32" },
        ["eventHash"] = { offset = 0x30, type = "Int32" },
        ["hasEventPass"] = { offset = 0x34, type = "Bool" },
        ["collectibleResetTimestamp"] = { offset = 0x38, type = "SafeInt32" },
        ["collectibleCollected"] = { offset = 0x40, type = "SafeInt32" },
        ["activeEventTasks"] = { offset = 0x48, type = "Array", elements = dailyTaskElements },
        ["taskRefillsRemaining"] = { offset = 0x60, type = "Array", elementType = "Int32", elementStride = 0x4 },
        ["singleScore"] = { offset = 0x70, type = "SafeInt32" },
        ["tasksResetTimestamp"] = { offset = 0x78, type = "Int32" },
        ["adsResetTimestamp"] = { offset = 0x7C, type = "Int32" },
        ["eventId"] = { offset = 0x80, type = "String" },
        ["teamId"] = { offset = 0x88, type = "String" },
        ["adsRemaining"] = { offset = 0x90, type = "Int32" },
    },  -- CurrentFriendEvent
    ["teamDonationTrack"] = {
        offset = 0x808,
        type = "Int32"
    },
    ["displayedInfoPopups"] = {
        offset = 0x7F8,
        type = "Array",
        elementType = "Int32",
        elementStride = 0x4, -- RepeatedField<int> packs elements at 4 bytes
    },
    ["teamSupportChestTransactions"] = {
        offset = 0x810,
        type = "Array",
        elementType = "String",
    },
    ["showOnlineStatus"] = {
        id = "showOnlineStatus",
        offset = 0x80C,
        optional = true,
        tracked = true,
        type = "Bool"
    },
    ["eventPointUnlockVehicle"] = {
        id = "eventPointUnlockVehicle",
        offset = 0x828,
        optional = true,
        tracked = true,
        type = "String"
    },
    ["eventPointUnlockProgress"] = {
        id = "eventPointUnlockProgress",
        offset = 0x860,
        optional = true,
        tracked = true,
        type = "Int32"
    },
    ["purchasedIapGifts"] = {
        id = "purchasedIapGifts",
        offset = 0x830,
        optional = false,
        tracked = false,
        type = "Array",
        elementType = "String",
    },
    ["claimedInboxMessages"] = {
        id = "claimedInboxMessages",
        offset = 0x848,
        optional = false,
        tracked = false,
        type = "Array",
        elementType = "String",
    },
    ["currentWinStreakAdRestores"] = {
        id = "currentWinStreakAdRestores",
        offset = 0x868,
        optional = true,
        tracked = true,
        type = "SafeInt32"
    },
    ["winStreakSpecialShield"] = {
        id = "winStreakSpecialShield",
        offset = 0x864,
        optional = true,
        tracked = true,
        type = "Int32"
    },
    ["winStreakEvent"] = {
        id = "winStreakEvent",
        offset = 0x870,
        optional = true,
        tracked = true,
        type = "Object",
        ["cupCounter"] = { offset = 0x18, type = "SafeInt32" },
        ["endTime"] = { offset = 0x20, type = "SafeInt32" },
        ["startStreak"] = { offset = 0x28, type = "SafeInt32" },
        ["claimedRewards"] = { offset = 0x30, type = "Array", elementType = "SafeInt32" },
        ["vehicleId"] = { offset = 0x48, type = "String" },
        ["rewards"] = { offset = 0x50, type = "Array", elementType = "SafeInt32" },
        ["cooldownTime"] = { offset = 0x68, type = "SafeInt32" },
        ["active"] = { offset = 0x70, type = "Bool" },
        ["pendingEnd"] = { offset = 0x71, type = "Bool" },
    }, --WinStreakEvent
    ["activeTriggers"] = {
        id = "activeTriggers",
        offset = 0x878,
        optional = false,
        tracked = true,
        type = "Array",
        elements = activeTriggerElements,
    }, -- ActiveTrigger
    ["previousPlayerIds"] = {
        id = "previousPlayerIds",
        offset = 0x890,
        optional = true,
        tracked = true,
        type = "Array",
        elementType = "String",
    }, -- String (was Object; dump: RepeatedPtrField<string>)
    ["currentFriendEvents"] = {
        id = "currentFriendEvents",
        offset = 0x8A8,
        optional = false,
        tracked = true,
        type = "Array",
        elements = currentFriendEventElements,
    }, -- CurrentFriendEvent
    ["nextBonusLevelRank"] = {
        id = "nextBonusLevelRank",
        offset = 0x8C0,
        optional = true,
        tracked = true,
        type = "Float" -- was Object; dump: float nextbonuslevelrank_
    },
}

end

__vfs['metadata/Mirror.lua'] = function(...)
--==================================================
-- metadata/Mirror.lua
--==================================================
-- Utility for metadata schemas that intentionally mirror an existing
-- metadata file. The source remains canonical; the mirror gets its
-- own module entry without duplicating the field table.

local M = {}

function M.of(name)
    assert(type(name) == "string" and name ~= "", "metadata mirror requires a source name")

    local metadata, err = nebulaLoadModule("metadata/" .. name .. ".lua", true)
    if not metadata then
        print("metadata mirror source failed: " .. tostring(err))
    end

    return metadata
end

return M

end

__vfs['metadata/PublicEvent.lua'] = function(...)
--==================================================
-- metadata/PublicEvent.lua
--==================================================
-- Field table for the PublicEvent
-- Sourced from each PublicEvent JSON(s)
-- cross-referenced with known offsets from the legacy flat
--
-- offset = 0xBAAD means the offset is NOT YET KNOWN. Do not
-- trust these fields until the placeholder is replaced by a
-- verified static offset.
--
-- contentVersion..pointsSystem is the header shared with
-- TeamEvent (see metadata/TeamEvent.lua). Fields past
-- fixedVehicles (0x4A0) are PublicEvent-only and must NOT be mirrored
-- onto TeamEvent as-is — TeamEvent has its own divergent tail.
--
-- Every leaf field's offset is absolute (from the struct base) — no
-- offset accumulates through parent containers. Pure namespace
-- containers like sessionEntry/gameMode carry no offset of their
-- own, just absolute-offset children. A container CAN have both an
-- offset of its own (e.g. pointsSystem) and typed children (e.g.
-- pointsSystem.function) — those children's offsets are still
-- absolute, already computed from struct base, not from the
-- parent's offset.
--
-- Array fields use one of:
--   elements = { ... }        → per-element struct template
--   elementType = "String"    → simple typed inline elements
--   elementStride = N            (stride N, no pointer dereference)
--   (neither)                 → vector header only, not readable
--
-- Empty arrays are suppressed from output (not shown as {}).

--==================================================
-- Reward element template — shared by eventRewards,
-- mainEventRewards, premiumEventRewards, rotatingEventRewards.
-- All four use the same element layout.
--==================================================
local rewardElements = {
    ["rewardCondition"] = {
        offset = 0x4,
        type = "Float"
    },
    ["lootDefinition"] = {
        offset = 0x20,
        type = "Object",
        ["id"] = {
            offset = 0x0,
            type = "String"
        },
        ["rankAmount"] = {
            offset = 0x1C,
            type = "Float"
        },
        ["coinAmount"] = {
            offset = 0x20,
            type = "Int32"
        },
        ["gemAmount"] = {
            offset = 0x24,
            type = "Int32"
        },
        ["bonusXpAmount"] = {
            offset = 0x28,
            type = "Int32"
        },
        ["unlockVehicleLevel"] = {
            offset = 0x2C,
            type = "Int32"
        },
        ["unlockVehicles"] = {
            offset = 0x48,
            type = "Array",
            elementType = "String",
            elementStride = 0x18
        },
        ["unlockDriverAssets"] = {
            offset = 0x60,
            type = "Array",
            elementType = "String",
            elementStride = 0x18
        },
        ["unlockDriverAnimations"] = {
            offset = 0x78,
            type = "Array",
            elementType = "String",
            elementStride = 0x18
        },
        ["unlockAdventureMaps"] = {
            offset = 0xC0,
            type = "Array",
            elementType = "String",
            elementStride = 0x18
        },
        ["unlockEditorThemes"] = {
            offset = 0xD8,
            type = "Array",
            elementType = "String",
            elementStride = 0x18
        },
        ["chests"] = {
            offset = 0xF0,
            type = "Array",
            elementType = "Enum",
            elementStride = 4,
            enum = "ChestType"
        },
        ["unlockHomeBackgrounds"] = {
            offset = 0x198,
            type = "Array",
            elementType = "String",
            elementStride = 0x18
        },
        ["currencies"] = {
            offset = 0x120,
            type = "Array",
            elementStride = 0x20,
            elements = {
                ["currency"] = {
                    offset = 0x0,
                    type = "String"
                },
                ["amount"] = {
                    offset = 0x18,
                    type = "Int32"
                }
            }
        },
        ["tuningParts"] = {
            offset = 0x150,
            type = "Array",
            elementStride = 0x38,
            elements = {
                ["id"] = {
                    offset = 0x0,
                    type = "String"
                },
                ["vehicleId"] = {
                    offset = 0x18,
                    type = "String"
                },
                ["amount"] = {
                    offset = 0x30,
                    type = "Int32"
                },
                ["rarity"] = {
                    offset = 0x34,
                    type = "Enum",
                    enum = "TuningRarity"
                }
            }
        },
        ["unlockVehiclePaints"] = {
            offset = 0x90,
            type = "Array",
            elementStride = 0x30,
            elements = {
                ["paintId"] = {
                    offset = 0x0,
                    type = "String"
                },
                ["vehicleId"] = {
                    offset = 0x18,
                    type = "String"
                }
            }
        },
        ["unlockVehicleSpriteVariants"] = {
            offset = 0xA8,
            type = "Array",
            elementStride = 0x48,
            elements = {
                ["partId"] = {
                    offset = 0x0,
                    type = "String"
                },
                ["variantId"] = {
                    offset = 0x18,
                    type = "String"
                },
                ["vehicleId"] = {
                    offset = 0x30,
                    type = "String"
                }
            }
        },
        ["vehicleChests"] = {
            offset = 0x108,
            type = "Array",
            elementStride = 0x38,
            elements = {
                ["vehicleId"] = {
                    offset = 0x0,
                    type = "String"
                },
                ["chestId"] = {
                    offset = 0x18,
                    type = "Enum",
                    enum = "ChestType"
                },
                ["targetIndex"] = {
                    offset = 0x1C,
                    type = "Int32"
                }
            }
        },
        ["unlockHomeProps"] = {
            offset = 0x180,
            type = "Array",
            elementStride = 0x20,
            elements = {
                ["id"] = {
                    offset = 0x0,
                    type = "String"
                },
                ["amount"] = {
                    offset = 0x18,
                    type = "Int32"
                }
            }
        },
        ["customChests"] = {
            offset = 0x1B0,
            type = "Array",
            elementStride = 0x50,
            elements = {
                ["name"] = {
                    offset = 0x0,
                    type = "String"
                },
                ["chestImageOpen"] = {
                    offset = 0x18,
                    type = "String"
                },
                ["chestImageClosed"] = {
                    offset = 0x30,
                    type = "String"
                },
                ["gems"] = {
                    offset = 0x48,
                    type = "Int32"
                }
            }
        }
    },
    ["maxCollectAmount"] = {
        offset = 0x28,
        type = "Int32"
    }
}

return {
    ["contentVersion"] = {
        offset = 0x0,
        type = "Int32"
    },
    ["id"] = {
        offset = 0x8,
        type = "String"
    },
    ["name"] = {
        offset = 0x20,
        type = "String"
    },
    ["description"] = {
        offset = 0x38,
        type = "String"
    },
    ["requiredPackages"] = {
        offset = 0x50,
        type = "Array",
        elementType = "String",
        elementStride = 0x18 -- std::vector<std::string>, inline elements
    },
    ["eventIcon"] = {
        offset = 0x80,
        type = "String"
    },
    ["eventBackground"] = {
        offset = 0xB0,
        type = "String"
    },
    ["eventButtonBackground"] = {
        offset = 0xC8,
        type = "String"
    },
    ["unlockCurrentlyActiveSegment"] = {
        offset = 0x140,
        type = "Int32"
    },
    ["minTeamSizeToJoin"] = {
        offset = 0x144,
        type = "Int32"
    },
    ["startTimeLive"] = {
        offset = 0x14C,
        type = "Int32"
    },
    ["startTime"] = {
        offset = 0x150,
        type = "Int32"
    },
    ["endTime"] = {
        offset = 0x154,
        type = "Int32"
    },
    ["sessionEntry"] = {
        ["entryFeeTickets"] = {
            offset = 0x160,
            type = "Int32"
        },
        ["maxEventTickets"] = {
            offset = 0x164,
            type = "Int32"
        },
        ["eventTicketRefillTime"] = {
            offset = 0x168,
            type = "Int32"
        },
        ["eventTicketRefillAmount"] = {
            offset = 0x16C,
            type = "Int32"
        },
        ["eventTicketRefillCost"] = {
            offset = 0x170,
            type = "Int32"
        },
        ["numberOfParallelSessions"] = {
            offset = 0x174,
            type = "Int32"
        },
        ["maxSpecialTicketsPerMatch"] = {
            offset = 0x178,
            type = "Int32"
        }
    },
    ["gameMode"] = {
        ["duration"] = {
            offset = 0x21C,
            type = "Int32"
        },
        ["joinWindow"] = {
            offset = 0x220,
            type = "Int32"
        },
        ["gameMode"] = {
            offset = 0x198,
            type = "Int32" -- GameMode enum
        },
        ["maxSessionParticipants"] = {
            offset = 0x2D0,
            type = "Int32"
        },
        ["maxBotCount"] = {
            -- NOT FOUND in GameModeDefinition dump. Field does not exist
            -- between maxSessionParticipants (0x138) and initialFuelTank (0x13c).
            -- May have been removed or renamed. Do not trust.
            offset = 0xBAAD,
            type = "Int32"
        },
        ["initialFuelTank"] = {
            offset = 0x2D4,
            type = "Float"
        },
        ["perVehicleRunCountLimits"] = {
            offset = 0x458,
            type = "Array",
            elementType = "Int32",
            elementStride = 4
        },
        ["allowedVehicles"] = {
            offset = 0x470,
            type = "Array",
            elementType = "String",
            elementStride = 0x18 -- std::vector<std::string>, inline elements
        },
        ["levelPool"] = {
            ["poolOrder"] = {
                offset = 0x2E8,
                type = "Int32" -- LevelPoolType enum
            },
            ["levelOrder"] = {
                offset = 0x2EC,
                type = "Int32" -- LevelPoolType enum
            },
            ["levelPools"] = {
                offset = 0x2F0,
                type = "Array",
                -- std::vector<std::vector<std::string>>: outer elements
                -- are vector<string> objects (0x18 each), inline
                elementStride = 0x18,
                elements = {
                    ["levels"] = {
                        offset = 0x0,
                        type = "Array",
                        elementType = "String",
                        elementStride = 0x18 -- inline std::string elements
                    }
                }
            }
        },
        ["pointsSystem"] = {
            offset = 0x3E0,
            ["function"] = {
                offset = 0x400,
                type = "Object" -- ValueSequence<float>, no reader yet
            },
            ["type"] = {
                offset = 0x3C0,
                type = "Int32" -- PointsSystemType enum
            },
            ["gemsToPointsConversion"] = {
                offset = 0x3F0,
                type = "Int32"
            },
            ["conversionDuration"] = {
                offset = 0x3F4,
                type = "Int32"
            }
        }
    },

    ["eventSpecials"] = {
        offset = 0x540,
        type = "Array"
    },
    ["fixedVehicles"] = {
        offset = 0x4A0,
        type = "Array",
        -- std::vector<FixedVehicleDefinition> (Size 0x118), inline
        elementStride = 0x118,
        elements = {
            ["id"] = {
                offset = 0x0,
                type = "String"
            },
            ["levelUpsPerPurchase"] = {
                offset = 0xE0,
                type = "Int32"
            },
            ["tuningPartSlots"] = {
                offset = 0xE4,
                type = "Int32"
            },
            ["eventPointsToUnlock"] = {
                offset = 0x110,
                type = "Int32"
            },
            ["allowCustomization"] = {
                offset = 0x114,
                type = "Bool"
            }
        }
    },
    ["specialFeatures"] = {
        offset = 0x4D0,
        type = "Array",
        elements = {
            ["id"] = {
                offset = 0x0,
                type = "String"
            },
            ["name"] = {
                offset = 0x48,
                type = "String"
            },
            ["description"] = {
                offset = 0x60,
                type = "String"
            },
            ["icon"] = {
                offset = 0x30,
                type = "String"
            },
            ["startingLevel"] = {
                offset = 0x78,
                type = "Int32"
            },
            ["maxLevels"] = {
                offset = 0x7C,
                type = "Int32"
            },
            ["mode"] = {
                offset = 0x80,
                type = "Int32"
            },
            ["amount"] = {
                offset = 0x88,
                type = "Float"
            },
            ["amountX"] = {
                offset = 0x90,
                type = "Float"
            },
            ["return"] = {
                offset = 0x98,
                type = "Int32"
            }
        }
    },
    ["eventRewards"] = {
        offset = 0x528,
        type = "Array",
        elements = rewardElements
    },
    ["rotatingEventRewards"] = {
        offset = 0x558,
        type = "Array",
        elements = rewardElements
    },
    ["rotatingEventRewardsInterval"] = {
        offset = 0x570,
        type = "Int32"
    },
    ["mainEventRewards"] = {
        offset = 0x578,
        type = "Array",
        elements = rewardElements
    },
    ["premiumEventRewards"] = {
        offset = 0x590,
        type = "Array",
        elements = rewardElements
    }
}

end

__vfs['metadata/TeamEvent.lua'] = function(...)
--==================================================
-- metadata/TeamEvent.lua
--==================================================
-- Field table for the TeamEvent
--
-- TeamEvent shares its header with PublicEvent - contentVersion
-- through pointsSystem are identical offsets. The header is mirrored from PublicEvent
-- (the canonical source for that portion) rather than duplicated.
--
-- Past 0x4A0 the two structs diverge: PublicEvent has
-- fixedVehicles/specialFeatures/eventSpecials/premiumEventRewards,
-- none of which appear in the TeamEvent source. TeamEvent instead
-- has multiRaceGameModes and winningTeamReward, which PublicEvent
-- doesn't have. A bare Mirror.of("PublicEvent") would misattribute
-- both directions, so the mirrored header is patched with
-- TeamEvent's own tail instead of returned as-is.
--
-- nebulaLoadModule() (see main.lua) does a fresh loadfile()+call every
-- time, not require()-style caching, so mutating the table below is
-- safe - it won't affect PublicEvent's own separately-loaded copy.
--
-- offset = 0xBAAD means the offset is NOT YET KNOWN. Do not
-- trust these fields until the placeholder is replaced by a
-- verified static offset.

local Mirror = nebulaLoadModule("metadata/Mirror.lua")

local metadata = Mirror.of("PublicEvent")

-- Fields that only exist on PublicEvent - not present in the
-- TeamEvent source, so they don't belong here.
metadata.eventSpecials = nil
metadata.fixedVehicles = nil
metadata.specialFeatures = nil
metadata.premiumEventRewards = nil
metadata.unlockCurrentlyActiveSegment = nil -- not present in TeamEvent source either

-- Fields unique to TeamEvent.
metadata.multiRaceGameModes = {
    offset = 0x500,
    type = "Array"
}
metadata.winningTeamReward = {
    offset = 0x520,
    type = "Object" -- known offset, no reader yet
}

-- eventRewards (0x528) is confirmed identical in both sources and
-- stays as mirrored from PublicEvent - no patch needed.
--
-- rotatingEventRewards (0x558) / rotatingEventRewardsInterval (0x570)
-- / mainEventRewards (0x578) were previously UNVERIFIED for TeamEvent
-- (the TeamEvent source jumped from eventRewards straight to
-- multiRaceGameModes). The IL2CPP dump now confirms they are correct:
-- the game stores team event definitions in
-- Dictionary<string, Pointer<EventDefinition>>, i.e. the SAME
-- EventDefinition struct backs PublicEvent, TeamEvent and
-- CommunityEvent (Size 0x5D8, Confidence: exact). All mirrored
-- offsets in the 0x528..0x590 range are therefore verified.

return metadata
end

__vfs['metadata/enums/ChestType.lua'] = function(...)
---@class ChestType
-- Bidirectional mapping between C++ Int32 chest IDs and schema
-- string names. Used by the Enum type module for vehicleChests.chestId
-- and chests array elements.
--
-- Source: $EventSchema chestId enum (19 values, IDs 0-18) +
-- economy.json specialCupRewards (21 entries, IDs 0-20) +
-- economy.json key indexes (freeChestIndex, vipChestIndexes, etc.)
--
-- IDs 19-20 ("style", "mythic") are NOT in the $EventSchema enum —
-- they were added to the game after the schema was written. Names
-- derived from economy.json chest image assets (toolbox_style,
-- toolbox_7) and iapChests display names ("Mythic Chest of
-- Goodies" → rewardChestTypeIndex=20).
--
--  ID | Schema Name        | Display Name          | Economy Evidence
-- ----|-------------------|-----------------------|------------------
--   0 | common            | Common Chest          | toolbox_1
--   1 | uncommon          | Uncommon Chest        | toolbox_2, vehicleChestIndex
--   2 | rare              | Rare Chest            | toolbox_3, vehicleChestIndex
--   3 | epic              | Epic Chest            | toolbox_4, epic particles
--   4 | champion          | Champion Chest         | toolbox_5
--   5 | tutorial          | Special Chest 1       | toolbox_1 (reused)
--   6 | xmas              | Xmas Chest             | toolbox_x
--   7 | legendary         | Legendary Chest       | toolbox_6, legendary particles
--   8 | free              | Blue Chest            | toolbox_free, freeChestIndex=8
--   9 | vip               | VIP Chest 1           | toolbox_vip, subscriptionChest=9
--  10 | vip2              | VIP Chest 2           | toolbox_vip, subscriptionChest=10
--  11 | video             | Video Chest           | toolbox_free, videoChestIndex=11
--  12 | tutorial_looks    | Starter Chest         | toolbox_1 (reused)
--  13 | tutorial_tuningparts | Special Chest 2    | toolbox_1 (reused)
--  14 | xpromo            | Fingersoft Chest      | toolbox_crosspromo, xpromoChestIndex=14
--  15 | mega              | Mega Chest            | mega_ad_chest
--  16 | legendary_team    | Team Legendary Chest  | toolbox_6, legendary particles
--  17 | vip_diamond       | VIP Diamond Chest     | toolbox_vip, vipChestIndexes=[10,17]
--  18 | team_support      | Team Spirit Chest     | toolbox_teamsupport, epic particles
--  19 | style             | Style Chest           | toolbox_style, legendary particles (not in schema)
--  20 | mythic            | Mythic Chest          | toolbox_7, legendary particles (not in schema)
return {
    byId = {
        [0]  = "common",
        [1]  = "uncommon",
        [2]  = "rare",
        [3]  = "epic",
        [4]  = "champion",
        [5]  = "tutorial",
        [6]  = "xmas",
        [7]  = "legendary",
        [8]  = "free",
        [9]  = "vip",
        [10] = "vip2",
        [11] = "video",
        [12] = "tutorial_looks",
        [13] = "tutorial_tuningparts",
        [14] = "xpromo",
        [15] = "mega",
        [16] = "legendary_team",
        [17] = "vip_diamond",
        [18] = "team_support",
        [19] = "style",
        [20] = "mythic",
    },
    byName = {
        common                  = 0,
        uncommon                = 1,
        rare                    = 2,
        epic                    = 3,
        champion                = 4,
        tutorial                = 5,
        xmas                    = 6,
        legendary               = 7,
        free                    = 8,
        vip                     = 9,
        vip2                    = 10,
        video                   = 11,
        tutorial_looks          = 12,
        tutorial_tuningparts    = 13,
        xpromo                  = 14,
        mega                    = 15,
        legendary_team          = 16,
        vip_diamond             = 17,
        team_support            = 18,
        style                   = 19,
        mythic                  = 20,
    },
}

end

__vfs['metadata/enums/GameStatusFlag.lua'] = function(...)
---@class GameStatusFlag
return {
    EventModeUnlocked          = 0x000001,
    TooMuchCoins               = 0x000002,
    TooMuchGems                = 0x000004,
    InvalidLibHash             = 0x000008,
    IsPitCrew                  = 0x000010,
    IapHacker                  = 0x000020,
    RootedAndroid              = 0x000040,
    MemoryHacker               = 0x000080,
    ManuallyBanned             = 0x000100,
    TeamModeUnlocked           = 0x000200,
    AutoClicker                = 0x000400,
    EmulatorDetected           = 0x000800,
    DebuggerDetected           = 0x001000,
    HookingDetected            = 0x002000,
    InstrumentationDetected    = 0x004000,
    ChecksumFailed             = 0x008000,
    SignatureCheckFailed       = 0x010000,
    VirtualizationDetected     = 0x020000,
    AdventureModeUnlocked      = 0x040000,
    CreativeModeUnlocked       = 0x080000,
    CommunityEventUnlocked     = 0x100000,
    HomeCustomizationUnlocked  = 0x200000,
    SafeIntHacker              = 0x400000,
    CurrencyTrackerHacker      = 0x800000,
}
end

__vfs['metadata/enums/TuningRarity.lua'] = function(...)
---@class TuningRarity
-- Bidirectional mapping between C++ Int32 tuning part rarity IDs
-- and schema string names. Used by the Enum type module for
-- tuningParts.rarity.
--
-- Source: $EventSchema tuningParts.items.properties.rarity enum +
-- economy.json tuningPartsRarityWeights arrays.
--
-- Note: ID 0 is "none" (no rarity set) — not in the schema enum,
-- not a valid rarity. The schema's 4 values start at ID 1. ID 5
-- (mythic) was added after the schema was written, same as chest
-- types style/mythic.
--
--  ID | Schema Name | Economy Array Index
-- ----|------------|--------------------
--   0 | none       | 0 (always 0 weight/amount)
--   1 | common     | 1
--   2 | rare       | 2
--   3 | epic       | 3
--   4 | legendary  | 4
--   5 | mythic     | 5
return {
    byId = {
        [0] = "none",
        [1] = "common",
        [2] = "rare",
        [3] = "epic",
        [4] = "legendary",
        [5] = "mythic",
    },
    byName = {
        none      = 0,
        common    = 1,
        rare      = 2,
        epic      = 3,
        legendary = 4,
        mythic    = 5,
    },
}

end

__vfs['metadata/enums/UnlockType.lua'] = function(...)
return {
    byId = {
        [0] = "DRIVER_HEAD",
        [1] = "DRIVER_BODY",
        [2] = "DRIVER_LEGS",
        [3] = "CAR_ATTACHMENT",
        [4] = "DRIVER_HAT",
        [5] = "CAR_SPRITE",
        [6] = "DRIVER_BACK_ATTACHMENT",
        [7] = "DRIVER_ANIMATION",
    },
    byName = {
        DRIVER_HEAD = 0,
        DRIVER_BODY = 1,
        DRIVER_LEGS = 2,
        CAR_ATTACHMENT = 3,
        DRIVER_HAT = 4,
        CAR_SPRITE = 5,
        DRIVER_BACK_ATTACHMENT = 6,
        DRIVER_ANIMATION = 7,
    },
}

end

local scriptDir = gg.getFile():match("(.*/)" ) or ""
nebula_script_dir = scriptDir  -- scoped to Nebula (must NOT clobber Void's script_dir global)

function nebulaLoadModule(name, soft)
    local key = name:gsub("^%./", "")
    if not key:match("%.lua$") then key = key .. ".lua" end
    local vchunk = __vfs[key]
    if vchunk then
        -- Soft mode: run the module body guarded so a feature crash returns
        -- nil, err instead of propagating (mirrors main.lua's nebulaLoadModule).
        if soft then
            local results = table.pack(pcall(vchunk))
            if not results[1] then return nil, results[2] end
            return table.unpack(results, 2, results.n)
        end
        return vchunk()
    end
    local path = scriptDir .. name
    local chunk, err = loadfile(path)
    if not chunk then
        if soft then return nil, err end
        gg.alert("VFS miss: " .. name .. "\n" .. tostring(err))
        error("nebula: module load failed: " .. tostring(name))
    end
    if soft then
        local results = table.pack(pcall(chunk))
        if not results[1] then return nil, results[2] end
        return table.unpack(results, 2, results.n)
    end
    return chunk()
end


-- ── MAIN ENTRYPOINT ──────────────────────────────────────────────────────


--==================================================
-- main.lua
--==================================================
-- Nebula SDK entry point.
--
-- Unpacked (dev) use: run this file directly with GG's script
-- loader; nebulaLoadModule() below resolves modules from disk relative
-- to this file.
--
-- Packed (release) use: run `python bundle.py` from the project
-- root. It strips the block below and replaces it with a
-- VFS-aware nebulaLoadModule() backed by an embedded __vfs table, so
-- the exact same require-style calls in every module keep working
-- with zero edits.

local scriptDir = gg.getFile():match("(.*/)") or ""
local _moduleCache = {}

--==================================================
-- Nebula wiring
--==================================================

Nebula = Nebula or {}

-- Global logging switch. No per-operation :log() — see api/GameStatus.lua.
Nebula.log = false

-- Verbose, timed logging for every gg.getValues/setValues round-trip
-- — see core/Memory.lua's vlog(). Flip to true to see exactly where
-- time is going: number of calls, batch sizes, per-call duration.
Nebula.verbose = false

Nebula.GameStatus = nebulaLoadModule("api/GameStatus.lua")

-- PublicEvent owns the canonical event metadata. TeamEvent mirrors that
-- metadata through metadata/TeamEvent.lua and keeps a separate get().
Nebula.PublicEvent = nebulaLoadModule("api/PublicEvent.lua")
Nebula.TeamEvent  = nebulaLoadModule("api/TeamEvent.lua")

-- CommunityEvent (CommunityShowcase) is a separate event type with
-- its own simpler struct and string-search resolution.
Nebula.CommunityEvent = nebulaLoadModule("api/CommunityEvent.lua")

-- Expose the type registry and Memory layer for advanced/extension
-- use (e.g. a consumer registering a custom type via
-- Nebula.Type.register("MyType", impl)).
Nebula.Type   = nebulaLoadModule("core/Type.lua")
Nebula.Memory = nebulaLoadModule("core/Memory.lua")

-- Persistent address cache for event resolution. Used internally
-- by Memory.lua's resolveActiveTeamEventBase/resolveActivePublicEventBase/
-- resolveActiveCommunityEventBase to preserve discovered addresses
-- across signature modifications.
Nebula.Cache   = nebulaLoadModule("core/Cache.lua")

Nebula.VERSION = "0.1.0"

return Nebula
