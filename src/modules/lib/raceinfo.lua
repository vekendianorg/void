--[[
  modules/lib/raceinfo.lua — Shared race-controller base-pointer resolver (v2)

  Resolves the native C++ race controller — the object holding the live
  distance counter (int @+0x0) and the race timer pair (float @+0x10/+0x14)
  written by the Cups "Set Time" and Adventure "Set Distance" features.

  v2 method (lib-offset-free, on-device verified Sept 2026):

      holder slot   = C_ALLOC address whose QWORD == BaseGameStatus
                      (the GameStatus object pointer, resolved once at init
                      from the content-based "startup_count" AOB)
      manager  p1   = QWORD at (holder - 0x88)
      controller p2 = QWORD at p1
      p2 + 0x0 / +0x10 / +0x14  = distance / timer pair

  The old v1 walk anchored at BaseLib + offsets.raceInfo — a native .data
  offset that changes on every libcocos2dcpp rebuild and needed per-version
  data-file upkeep. v2 anchors on the GameStatus pointer instead, so a lib
  change (or a new offset sweep) never touches this file: the init AOB finds
  the base, and everything below is a stable heap relationship.

  A built-in shape check (distance int in range, timer floats in
  [0, 2^31-1]) is ALWAYS applied, on both cached and fresh paths, so a
  garbage pointer from a false holder can never be returned. The optional
  caller validator adds stricter rules on top (e.g. "is a race live right
  now" for Set Distance). v1 only validated cached hits; v2 applies the
  validator on fresh searches too, to pick the right candidate when
  multiple holders pass the shape check.

  Cache: the holder slot address is stored under the caller's cacheKey
  (PID-scoped). The chain holder -> p1 -> p2 is re-dereferenced on every
  call, so per-race controller reallocations are picked up automatically.
  The cache is cleared when the chain breaks or the holder stops holding
  the GameStatus pointer; a validator failure KEEPS the cache and returns
  nil, so the next attempt can reuse it once the player is back in a race.
  v1-format caches self-heal: their slot value will not equal BaseGameStatus,
  so the first resolve after this update re-searches once and re-caches.

  Globals used: storage, gg, BaseGameStatus, LOG.
]]

local TAG = "RaceInfo"

local HOLDER_DELTA    = 0x88             -- holder slot -> manager pointer field
local CTRL_DIST       = 0x0             -- controller: live distance (int, meters)
local CTRL_TIMER_1    = 0x10            -- controller: race timer float 1
local CTRL_TIMER_2    = 0x14            -- controller: race timer float 2
local PTR_MIN         = 0x10000
local PTR_MAX         = 0x7FFFFFFFFFFF
local SHAPE_INT_MAX   = 2147483647      -- also bounds the timers we write (2e9)

local raceinfo = {}

local function plausiblePtr(v)
    return type(v) == "number" and v >= PTR_MIN and v <= PTR_MAX
end

-- Read the distance/timer triple at a candidate controller address.
-- Returns the 3-entry getValues result, or nil on a failed read.
local function readShape(base)
    local r = gg.getValues({
        { address = base + CTRL_DIST,     flags = 4  },
        { address = base + CTRL_TIMER_1, flags = 16 },
        { address = base + CTRL_TIMER_2, flags = 16 },
    })
    if not r or type(r) ~= "table" or #r ~= 3 then return nil end
    return r
end

-- Built-in minimum shape check: sane distance int and timer floats.
local function shapeOk(r)
    local dist, f1, f2 = r[1].value, r[2].value, r[3].value
    if type(dist) ~= "number" or dist < 0 or dist > SHAPE_INT_MAX then return false end
    if type(f1) ~= "number" or f1 < 0 or f1 > SHAPE_INT_MAX then return false end
    if type(f2) ~= "number" or f2 < 0 or f2 > SHAPE_INT_MAX then return false end
    return true
end

-- Walk one holder slot: holder -> p1 -> p2 (+ shape check).
-- Returns controller base and the manager pointer, or nil.
local function walkHolder(holderAddr)
    local m = gg.getValues({ { address = holderAddr - HOLDER_DELTA, flags = 32 } })
    if not m or not m[1] or not plausiblePtr(m[1].value) then return nil end
    local p1 = m[1].value

    local c = gg.getValues({ { address = p1, flags = 32 } })
    if not c or not c[1] or not plausiblePtr(c[1].value) then return nil end
    local p2 = c[1].value

    local r = readShape(p2)
    if not r or not shapeOk(r) then return nil end
    return p2, p1
end

-- Resolve the race-controller base pointer.
--   cacheKey  : persistent memory key for the holder slot address.
--   validate  : optional function(controllerBase) -> bool, applied on top
--               of the built-in shape check (cached AND fresh paths).
-- Returns the controller base address, or nil if it can't be resolved.
function raceinfo.resolve(cacheKey, validate)
    -- ── Cached holder slot ─────────────────────────────────────────────────
    local cachedHolder = storage:load_session(cacheKey)
    if cachedHolder and cachedHolder ~= 0 then
        local still = gg.getValues({ { address = cachedHolder, flags = 32 } })
        if still and still[1] and still[1].value == BaseGameStatus then
            local p2, p1 = walkHolder(cachedHolder)
            if p2 then
                if validate and not validate(p2) then
                    LOG.warn(TAG, "Cached holder: controller failed validation — cache kept.")
                    return nil
                end
                LOG.dbg(TAG, string.format(
                    "Cache hit: holder=0x%X → p1=0x%X → ctrl=0x%X",
                    cachedHolder, p1 or 0, p2))
                return p2
            end
            LOG.warn(TAG, "Cached holder: chain broken — clearing cache (" .. tostring(cacheKey) .. ")")
            storage:delete_session(cacheKey)
        else
            LOG.warn(TAG, "Holder no longer holds GameStatus* — clearing cache (" .. tostring(cacheKey) .. ")")
            storage:delete_session(cacheKey)
        end
    end

    -- ── Fresh search ────────────────────────────────────────────────────────
    if not BaseGameStatus or BaseGameStatus == 0 then
        LOG.warn(TAG, "BaseGameStatus not resolved — cannot search.")
        return nil
    end

    gg.clearResults()
    gg.setRanges(gg.REGION_C_ALLOC)
    gg.searchNumber(BaseGameStatus, 32)
    local holders = gg.getResults(gg.getResultsCount())
    gg.clearResults()

    if not holders or #holders == 0 then
        LOG.warn(TAG, "Level 1: no GameStatus* holders found")
        return nil
    end

    LOG.dbg(TAG, string.format("Holder search: %d candidate(s)", #holders))

    -- Batched: manager pointers for every holder slot.
    local p1Reads, holderAddrs = {}, {}
    for i, h in ipairs(holders) do
        p1Reads[#p1Reads + 1] = { address = h.address - HOLDER_DELTA, flags = 32 }
        holderAddrs[#holderAddrs + 1] = h.address
    end
    local p1Vals = gg.getValues(p1Reads)
    if not p1Vals then
        LOG.warn(TAG, "Level 2: manager pointer read failed")
        return nil
    end

    -- Batched: controller pointers for plausible managers.
    local p2Reads, holderOfP1 = {}, {}
    for i, v in ipairs(p1Vals) do
        if plausiblePtr(v.value) then
            p2Reads[#p2Reads + 1] = { address = v.value, flags = 32 }
            holderOfP1[#holderOfP1 + 1] = holderAddrs[i]
        end
    end
    if #p2Reads == 0 then
        LOG.warn(TAG, "Level 2: no plausible manager pointers")
        return nil
    end
    local p2Vals = gg.getValues(p2Reads)
    if not p2Vals then
        LOG.warn(TAG, "Level 3: controller pointer read failed")
        return nil
    end

    -- Batched: shape triple for every plausible controller.
    local shapeReads, holderOfP2, ctrlOf = {}, {}, {}
    for i, v in ipairs(p2Vals) do
        if plausiblePtr(v.value) then
            shapeReads[#shapeReads + 1] = { address = v.value + CTRL_DIST,     flags = 4  }
            shapeReads[#shapeReads + 1] = { address = v.value + CTRL_TIMER_1, flags = 16 }
            shapeReads[#shapeReads + 1] = { address = v.value + CTRL_TIMER_2, flags = 16 }
            holderOfP2[#holderOfP2 + 1] = holderOfP1[i]
            ctrlOf[#ctrlOf + 1] = v.value
        end
    end
    if #shapeReads == 0 then
        LOG.warn(TAG, "Level 3: no plausible controller pointers")
        return nil
    end
    local shapes = gg.getValues(shapeReads)
    if not shapes then
        LOG.warn(TAG, "Level 3: shape read failed")
        return nil
    end

    -- First shape-valid candidate that also passes the caller validator wins.
    local validCount = 0
    local chosenCtrl, chosenHolder
    for i = 1, #ctrlOf do
        local triple = { shapes[3 * i - 2], shapes[3 * i - 1], shapes[3 * i] }
        if shapeOk(triple) then
            validCount = validCount + 1
            if not chosenCtrl then
                if not validate or validate(ctrlOf[i]) then
                    chosenCtrl, chosenHolder = ctrlOf[i], holderOfP2[i]
                end
            end
        end
    end

    if validCount == 0 then
        LOG.warn(TAG, "Level 3: no holder passed the shape check")
        return nil
    end
    if not chosenCtrl then
        LOG.warn(TAG, string.format(
            "%d shape-valid holder(s) but none passed validation", validCount))
        return nil
    end

    storage:save_session(cacheKey, chosenHolder)
    if validCount > 1 then
        LOG.dbg(TAG, string.format(
            "%d shape-valid holder(s), chose holder=0x%X → ctrl=0x%X",
            validCount, chosenHolder, chosenCtrl))
    else
        LOG.info(TAG, string.format(
            "Resolved + cached: holder=0x%X → ctrl=0x%X", chosenHolder, chosenCtrl))
    end
    return chosenCtrl
end

return raceinfo
