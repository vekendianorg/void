--[[
  modules/lib/raceinfo.lua — Shared race-info base-pointer resolver

  The Cups "Set Time" and Adventure "Set Distance" features both resolve the
  same in-race object by walking:

      anchor = BaseLib + offsets.raceInfo
        → refs to the anchor (level 1)
          → refs to those refs, minus 0xAC (level 2)
            → that address inside C_ALLOC (level 3) → resolved pointer

  This walk used to be copy-pasted in both core modules. It lives here once;
  callers differ only in their persistent cache key and an optional validator
  applied to a cached base (e.g. "is a race actually running right now?").

  Globals used: memory, gg, BaseRegion, BaseLib, offsets, LOG.
]]

local TAG = "RaceInfo"

local raceinfo = {}

-- Resolve the race-info base pointer.
--   cacheKey  : persistent memory key for the resolved pointer address.
--   validate  : optional function(base) -> bool. When a cached pointer still
--               resolves, the base is returned only if validate(base) passes;
--               otherwise nil is returned and the cache is KEPT (so the next
--               attempt can reuse it once the player is back in a race).
-- Returns the base address, or nil if it can't be resolved.
function raceinfo.resolve(cacheKey, validate)
    local cachedPtr = memory:load(cacheKey)
    if cachedPtr and cachedPtr ~= 0 then
        local verify = gg.getValues({{ address = cachedPtr, flags = 32 }})
        if verify and verify[1] and verify[1].value ~= 0 then
            local base = verify[1].value
            if validate and not validate(base) then
                LOG.warn(TAG, "Cached base failed validation — cache kept.")
                return nil
            end
            LOG.dbg(TAG, string.format("Cache hit: ptr=0x%X → base=0x%X", cachedPtr, base))
            return base
        else
            LOG.warn(TAG, "ptr invalid — clearing cache (" .. tostring(cacheKey) .. ")")
            memory:delete(cacheKey)
        end
    end

    local anchorTarget = BaseLib + offsets.raceInfo
    LOG.dbg(TAG, string.format("Resolving from scratch | anchor=0x%X", anchorTarget))

    gg.clearResults()
    gg.setRanges(BaseRegion)
    gg.searchNumber(anchorTarget, 32)
    local level1Results = gg.getResults(gg.getResultsCount())
    gg.clearResults()

    if #level1Results == 0 then
        LOG.warn(TAG, "Level 1: no refs found")
        return nil
    end

    local resolvedBase = nil

    for _, ref1 in ipairs(level1Results) do
        gg.clearResults()
        gg.setRanges(BaseRegion)
        gg.searchNumber(ref1.address, 32)
        local level2Results = gg.getResults(gg.getResultsCount())
        gg.clearResults()

        for _, ref2 in ipairs(level2Results) do
            local offsetAddr = ref2.address - 0xAC

            gg.clearResults()
            gg.setRanges(gg.REGION_C_ALLOC)
            gg.searchNumber(offsetAddr, 32)
            local level3Results = gg.getResults(gg.getResultsCount())
            gg.clearResults()

            if #level3Results > 0 then
                local pointerReads = {}
                for _, ref3 in ipairs(level3Results) do
                    table.insert(pointerReads, { address = ref3.address, flags = 32 })
                end
                local resolvedPointers = gg.getValues(pointerReads)
                if resolvedPointers then
                    for _, ptr in ipairs(resolvedPointers) do
                        if ptr and ptr.value and ptr.value ~= 0 then
                            memory:save(cacheKey, ptr.address)
                            resolvedBase = ptr.value
                            LOG.info(TAG, string.format("Resolved + cached: ptr=0x%X → base=0x%X", ptr.address, resolvedBase))
                            break
                        end
                    end
                end
            end

            if resolvedBase then break end
        end

        if resolvedBase then break end
    end

    return resolvedBase
end

return raceinfo
