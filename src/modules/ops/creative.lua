--[[
  modules/ops/creative.lua — Creative mode / custom-track memory ops
  Contract: see modules/ops/README.md.

  Features:
    getCustomTracks()  — resolve the full list of custom tracks in memory
    verifyTrack(idx)   — mark a single track as verified (isVerified = 1)
    setTrackLength(idx, len) — override the track's length (no 30–1000 cap)
    renameTrack(idx, name)   — rename a track (edits the in-memory string)
    copyAny()          — let the player copy any downloaded track (not just their own)

  String layout (as noted in the instructions):
    offset 0x30 → pointer to the string object
    The string object at that pointer:
      byte 0        = total byte length × 2  (e.g. "abc" = 3 chars → byte = 6)
      bytes 1..N    = raw UTF-8 characters
    Additionally the first byte of the object acts as the length sentinel;
    a second copy of the pointer follows at the end of the fixed header,
    matching the vehicle-name pattern used in vehicle.lua.

  Globals used: scheduler, gg, memory, BaseLib, BaseGameStatus, offsets, LOG.
]]

local M = {}

-- ── Internal helpers ──────────────────────────────────────────────────────────

-- The anchor address (where listPtr and count live) is derived from a static
-- BaseLib offset and never moves within a session — safe to cache.
-- The count and element pointers at that anchor ARE dynamic (tracks created/
-- deleted by the game update them), so they are always read live.
local cachedAnchor = nil

---Resolve (or return the cached) anchor address for the custom-track list.
---The anchor holds: +0x30 = listPtr, +0x38 = live element count.
---Returns the anchor address, or nil if the AOB search fails.
local function resolveAnchor(TAG)
    if cachedAnchor then
        -- Verify the anchor still looks valid (listPtr should be non-zero).
        local check = gg.getValues({{ address = cachedAnchor + 0x30, flags = 32 }})
        if check and check[1] and check[1].value ~= 0 then
            LOG.dbg(TAG, string.format("Anchor cache hit: 0x%X", cachedAnchor))
            return cachedAnchor
        end
        LOG.warn(TAG, "Cached anchor stale — re-scanning")
        cachedAnchor = nil
    end

    local searchTarget = BaseLib + offsets.customTracks
    LOG.info(TAG, string.format(
        "Searching for customTracks anchor | BaseLib=0x%X  offset=0x%X  target=0x%X  range=8",
        BaseLib, offsets.customTracks, searchTarget))

    gg.clearResults()
    gg.setRanges(BaseRegion)
    gg.searchNumber(searchTarget, 32)
    local refs = gg.getResults(gg.getResultsCount())
    gg.clearResults()

    LOG.info(TAG, string.format("Search returned %d result(s)  range=BaseRegion(0x%X)",
        #refs, BaseRegion))

    if #refs == 0 then
        LOG.warn(TAG, string.format(
            "customTracks anchor not found | target=0x%X  BaseRegion=0x%X",
            searchTarget, BaseRegion))
        return nil
    end

    for i, ref in ipairs(refs) do
        LOG.dbg(TAG, string.format("  hit[%d] = 0x%X", i, ref.address))
    end

    cachedAnchor = refs[1].address
    LOG.info(TAG, string.format("Anchor resolved and cached: 0x%X", cachedAnchor))
    return cachedAnchor
end

---Read the live track list from the anchor.
---count is re-read every call so additions/deletions are always reflected.
---Each descriptor: { index, elemPtr, namePtr, nameStr, length, isVerified }
local function resolveTrackList(TAG)
    local anchor = resolveAnchor(TAG)
    if not anchor then return nil end

    -- Read listPtr and the LIVE count together in one call.
    local meta = gg.getValues({
        { address = anchor + 0x30, flags = 32 },   -- listPtr
        { address = anchor + 0x38, flags = 4  },   -- live element count
    })

    local listPtr   = meta[1] and meta[1].value or 0
    local listCount = meta[2] and meta[2].value or 0

    LOG.info(TAG, string.format(
        "Anchor read | listPtr=0x%X  listCount=%d",
        listPtr, listCount))

    if listPtr == 0 or listCount == 0 then
        -- Log the raw bytes at the anchor so we can spot misaligned offsets
        local raw = gg.getValues({
            { address = anchor + 0x28, flags = 32 },
            { address = anchor + 0x30, flags = 32 },
            { address = anchor + 0x38, flags = 4  },
            { address = anchor + 0x3C, flags = 4  },
        })
        LOG.warn(TAG, string.format(
            "List empty or nil — anchor neighbourhood dump:" ..
            "  [+0x28]=0x%X  [+0x30]=0x%X  [+0x38]=%d  [+0x3C]=%d",
            raw[1] and raw[1].value or 0,
            raw[2] and raw[2].value or 0,
            raw[3] and raw[3].value or 0,
            raw[4] and raw[4].value or 0))
        return {}
    end

    LOG.info(TAG, string.format("Reading %d tracks (live count) from listPtr=0x%X", listCount, listPtr))

    local tracks = {}
    for i = 0, listCount - 1 do
        local elemPtrResult = gg.getValues({{ address = listPtr + i * 8, flags = 32 }})
        local elemPtr = elemPtrResult and elemPtrResult[1] and elemPtrResult[1].value or 0
        if elemPtr ~= 0 then
            local fields = gg.getValues({
                { address = elemPtr + 0x30, flags = 32 },  -- namePtr
                { address = elemPtr + 0x50, flags = 4  },  -- length (DWORD)
                { address = elemPtr + 0x64, flags = 4  },  -- isVerified
            })

            local namePtr    = fields[1] and fields[1].value or 0
            local trackLen   = fields[2] and fields[2].value or 0
            local isVerified = fields[3] and fields[3].value or 0

            local nameStr = "?"
            if namePtr ~= 0 then
                local lenByte = gg.getValues({{ address = namePtr, flags = 1 }})
                local byteLen = lenByte and lenByte[1] and math.floor(lenByte[1].value / 2) or 0
                if byteLen > 0 then
                    local charReads = {}
                    for b = 1, byteLen do
                        charReads[b] = { address = namePtr + b, flags = 1 }
                    end
                    local chars = gg.getValues(charReads)
                    local bytes = {}
                    for _, c in ipairs(chars or {}) do
                        bytes[#bytes + 1] = string.char(math.max(0, math.min(255, tonumber(c.value) or 0)))
                    end
                    nameStr = table.concat(bytes)
                end
            end

            tracks[#tracks + 1] = {
                index      = i,
                elemPtr    = elemPtr,
                namePtr    = namePtr,
                nameStr    = nameStr,
                length     = trackLen,
                isVerified = isVerified,
            }
        end
    end

    return tracks
end

-- ── Public API ────────────────────────────────────────────────────────────────

---Resolve the full track list. Results passed to cb as (ok, tracks|errKey).
function M.getCustomTracks(cb)
    scheduler:add(function(finishTask)
        local tracks = resolveTrackList("GetCustomTracks")
        finishTask()
        if not tracks then
            cb(false, "creative.tracks_not_found")
        else
            cb(true, tracks)
        end
    end)
end

---Mark a single track as verified.
---@param elemPtr number  Base address of the track element (from getCustomTracks)
---@param cb fun(ok, errKey|nil)
function M.verifyTrack(elemPtr, cb)
    scheduler:add(function(finishTask)
        if not elemPtr or elemPtr == 0 then
            finishTask(); cb(false, "creative.invalid_track"); return
        end
        gg.setValues({{ address = elemPtr + 0x64, flags = 4, value = 1 }})
        LOG.info("VerifyTrack", string.format("Verified track at 0x%X", elemPtr))
        finishTask(); cb(true)
    end)
end

---Override the track length (bypasses the game's 30–1000 cap).
---@param elemPtr number
---@param length  number  Desired length (any positive integer)
---@param cb fun(ok, errKey|nil)
function M.setTrackLength(elemPtr, length, cb)
    scheduler:add(function(finishTask)
        if not elemPtr or elemPtr == 0 then
            finishTask(); cb(false, "creative.invalid_track"); return
        end
        length = math.max(1, math.floor(tonumber(length) or 100))
        gg.setValues({{ address = elemPtr + 0x50, flags = 4,  value = length }})
        LOG.info("SetTrackLength", string.format("0x%X → %d", elemPtr, length))
        finishTask(); cb(true, nil, length)
    end)
end

---Rename a track by rewriting its in-memory string object.
---The string object header:  byte 0 = strlen × 2,  bytes 1..N = UTF-8.
---@param elemPtr number
---@param newName string
---@param cb fun(ok, errKey|nil)
function M.renameTrack(elemPtr, newName, cb)
    scheduler:add(function(finishTask)
        if not elemPtr or elemPtr == 0 then
            finishTask(); cb(false, "creative.invalid_track"); return
        end
        if not newName or newName == "" then
            finishTask(); cb(false, "creative.rename_empty"); return
        end

        -- Resolve the name pointer from the element base.
        local namePtrResult = gg.getValues({{ address = elemPtr + 0x30, flags = 32 }})
        local namePtr = namePtrResult and namePtrResult[1] and namePtrResult[1].value or 0
        if namePtr == 0 then
            LOG.error("RenameTrack", "namePtr is 0")
            finishTask(); cb(false, "creative.rename_resolve_failed"); return
        end

        -- Build the byte sequence.
        local nameBytes = {}
        for p, code in utf8.codes(newName) do
            local ch    = utf8.char(code)
            local bytes = { ch:byte(1, -1) }
            for _, b in ipairs(bytes) do nameBytes[#nameBytes + 1] = b end
        end

        local byteLen = #nameBytes
        -- Write length sentinel (byteLen × 2) then the character bytes.
        local writes = {{ address = namePtr, flags = 1, value = byteLen * 2 }}
        for i, b in ipairs(nameBytes) do
            writes[#writes + 1] = { address = namePtr + i, flags = 1, value = b }
        end
        -- Zero-terminate any remaining bytes from a longer previous name.
        writes[#writes + 1] = { address = namePtr + byteLen + 1, flags = 1, value = 0 }

        gg.setValues(writes)
        LOG.info("RenameTrack", string.format("0x%X → %q  (%d bytes)", elemPtr, newName, byteLen))
        finishTask(); cb(true, nil, newName)
    end)
end

---Allow copying any downloaded track (not just tracks owned by the player).
---Overwrites the creator-ID pointer of every downloaded track with the
---current player's ID pointer, making them all appear as "yours".
---@param cb fun(ok, errKey|nil, count|nil)
function M.copyAny(cb)
    scheduler:add(function(finishTask)
        local TAG = "CopyAny"
        gg.clearResults()
        gg.setRanges(BaseRegion)
        gg.searchNumber(BaseLib + offsets.downloadedCustomTracks, 32)
        local refs = gg.getResults(gg.getResultsCount())
        gg.clearResults()

        if #refs == 0 then
            LOG.warn(TAG, "downloadedCustomTracks anchor not found")
            finishTask(); cb(false, "creative.copy_any_not_found"); return
        end

        local idPtrResult = gg.getValues({{ address = BaseGameStatus + 0x30, flags = 32 }})
        local idPtr = idPtrResult and idPtrResult[1] and idPtrResult[1].value or 0
        if idPtr == 0 then
            LOG.error(TAG, "player ID pointer is 0")
            finishTask(); cb(false, "creative.copy_any_no_id"); return
        end

        local edits = {}
        for _, v in ipairs(refs) do
            edits[#edits + 1] = { address = v.address + 0x18, flags = 32, value = idPtr }
        end
        gg.setValues(edits)

        LOG.info(TAG, string.format("Patched %d entries with idPtr=0x%X", #edits, idPtr))
        finishTask(); cb(true, nil, #edits)
    end)
end

return M
