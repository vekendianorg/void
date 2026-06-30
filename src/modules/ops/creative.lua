--[[
  modules/ops/creative.lua — Creative mode / custom-track memory ops
  Contract: see modules/ops/README.md.

  Features:
    anyThemeObjects(?)
    showHiddenObjects(?)
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

  Globals used: scheduler, gg, memory, BaseLib, BaseGameStatus, offsets, LOG, alloc.
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
        local _r = gg.getValues({{ address = listPtr + i * 8, flags = 32 }}); local elemPtr = _r and _r[1] and _r[1].value or 0
        if elemPtr ~= 0 then
            local fields = gg.getValues({
                { address = elemPtr + 0x30, flags = 32 },  -- namePtr
                { address = elemPtr + 0x50, flags = 4  },  -- length (DWORD)
                { address = elemPtr + 0x64, flags = 4  },  -- isVerified
            })

            local namePtr    = fields[1] and fields[1].value or 0
            local trackLen   = fields[2] and fields[2].value or 0
            local isVerified = fields[3] and fields[3].value or 0

            local nameStr = namePtr ~= 0 and readString(namePtr + 1) or "?"

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
        local _r = gg.getValues({{ address = elemPtr + 0x30, flags = 32 }}); local namePtr = _r and _r[1] and _r[1].value or 0
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

        local _r = gg.getValues({{ address = BaseGameStatus + 0x30, flags = 32 }}); local idPtr = _r and _r[1] and _r[1].value or 0
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

-- ── Editor hacks ──────────────────────────────────────────────────────────────

local PAGE_SIZE = 75   -- max objects per group per anchor slot

-- Alloc handles kept in module-local only — they are runtime Lua objects and
-- cannot be serialized. Slot data (addresses, originals) goes to memory:save.
local _liveAllocHandles = nil

-- requiresTheme zero pattern: 6 DWORDs covering +0x00..+0x14
local THEME_ZERO_OFFSETS = { 0x00, 0x04, 0x08, 0x0C, 0x10, 0x14 }

-- Group slot layout: { ptr1, ptr2, ptr3 }
-- Each group is a cocos2d::Vector with three 64-bit pointers:
--   ptr1 = buffer start  (first element)
--   ptr2 = buffer end    (one-past-last element)
--   ptr3 = capacity end  (one-past-last allocated slot, = ptr2 for exact-fit alloc)
-- When zeroing a group that has no data, zero all three pointers (3 × QWORD = 24 bytes).
local GROUP_SLOTS = {
    dynamic = { ptr1 = 0x48, ptr2 = 0x50, ptr3 = 0x58 },
    static  = { ptr1 = 0x60, ptr2 = 0x68, ptr3 = 0x70 },
    props   = { ptr1 = 0x78, ptr2 = 0x80, ptr3 = 0x88 },
}
local GROUP_ORDER = { "dynamic", "static", "props" }

-- Cached verified anchor list (addresses).
local cachedAnchors = nil

-- ── AOB scan + anchor verification ───────────────────────────────────────────

local function resolveAnchors(TAG)
    if cachedAnchors then
        local chk = gg.getValues({{ address = cachedAnchors[1] - 0x8, flags = 32 }})
        if chk and chk[1] and chk[1].value ~= 0 then
            LOG.dbg(TAG, "anchor cache hit")
            return cachedAnchors
        end
        LOG.warn(TAG, "anchor cache stale — re-scanning")
        cachedAnchors = nil
    end

    gg.clearResults()
    gg.setRanges(BaseRegion)
    gg.searchNumber("h 20 66 6F 72 65 73 74 32 5F 67 66 78 2E 6A 73 6F", 1)
    gg.refineNumber("h 20", 1)
    local results = gg.getResults(gg.getResultsCount())
    gg.clearResults()
    
    local valid = {}
    for i, v in ipairs(results) do
        local verify = gg.getValues({{
            address = v.address + 0x18,
            flags = 4
        }, {
            address = v.address + 0x20,
            flags = 4
        }})
        
        if verify and verify[1] and verify[2] and verify[1].value and verify[2].value then
            table.insert(valid, { address = v.address, flags = 4 })
        end
    end
    
    local hits = gg.getValues(valid)
    gg.clearResults()

    LOG.info(TAG, string.format("AOB returned %d hit(s)", #hits))
    if #hits == 0 then return nil end

    local verified = {}
    for hi, hit in ipairs(hits) do
        local aobAddr = hit.address
        LOG.dbg(TAG, string.format("hit[%d] aobAddr=0x%X", hi, aobAddr))

        gg.clearResults()
        gg.searchNumber(aobAddr, 32)
        local ptrs = gg.getResults(gg.getResultsCount())
        gg.clearResults()

        for _, ptr in ipairs(ptrs) do
            local addr = ptr.address

            local _rA  = gg.getValues({{ address = addr - 0x8, flags = 32 }})
            local ptrA = _rA and _rA[1] and _rA[1].value or 0
            if ptrA == 0 then goto next_ptr end

            local checkA   = gg.getValues({
                { address = ptrA + 0x8,  flags = 4  },
                { address = ptrA + 0x10, flags = 32 },
            })
            local dwordAt8 = checkA and checkA[1] and checkA[1].value or nil
            local ptr2     = checkA and checkA[2] and checkA[2].value or 0
            if dwordAt8 ~= 23 or ptr2 == 0 then goto next_ptr end

            local countryside = readString(ptr2, 32)
            if not countryside:find("countryside_gfx_01.json", 1, true) then goto next_ptr end

            local _rB  = gg.getValues({{ address = addr + 0x8, flags = 32 }})
            local ptrB = _rB and _rB[1] and _rB[1].value or 0
            if ptrB == 0 then goto next_ptr end

            local _bb     = gg.getValues({{ address = ptrB, flags = 1 }})
            local byteAt0 = _bb and _bb[1] and _bb[1].value or nil
            if byteAt0 ~= 26 then goto next_ptr end

            local cityStr = readString(ptrB + 1, 8)
            if not cityStr:find("city_gfx", 1, true) then goto next_ptr end

            LOG.info(TAG, string.format("anchor verified at 0x%X", addr))
            verified[#verified + 1] = addr
            ::next_ptr::
        end
    end

    if #verified == 0 then
        LOG.warn(TAG, "no verified anchors found")
        return nil
    end

    cachedAnchors = verified
    return verified
end

-- ── Read all objectGroup ptr arrays from every anchor ─────────────────────────
-- Walk anchors starting at anchor-0x8, stepping +0x8, stopping at ptr==0 or
-- sentinel "all". For each anchor ptr, read the three group ranges and collect
-- non-zero object pointers into the pool.
-- Returns: pool = { dynamic={ptr,...}, static={ptr,...}, props={ptr,...} }
--          anchorsWalked = list of { anchorSlotAddr, slotPtr, origGroups }
--            origGroups = { dynamic={s,e}, static={s,e}, props={s,e} }

local function readAllPools(TAG, anchors)
    local pool        = { dynamic = {}, static = {}, props = {} }
    local anchorSlots = {}

    for ai, anchor in ipairs(anchors) do
        local cur   = anchor - 0x8
        local step  = 0
        LOG.dbg(TAG, string.format("anchor[%d]=0x%X  walk starts at 0x%X", ai, anchor, cur))

        while true do
            local _r   = gg.getValues({{ address = cur, flags = 32 }})
            local sPtr = _r and _r[1] and _r[1].value or 0
            LOG.dbg(TAG, string.format("  slot[%d] cur=0x%X sPtr=0x%X", step, cur, sPtr))

            if sPtr == 0 then
                LOG.dbg(TAG, "  stop: sPtr==0")
                break
            end

            local _sb      = gg.getValues({{ address = sPtr, flags = 1 }})
            local sentByte = _sb and _sb[1] and _sb[1].value or 0
            local sentStr  = readString(sPtr + 1, 3)
            LOG.dbg(TAG, string.format("  requiresTheme sentinel: byte=%d str=%q", sentByte, sentStr))

            if sentByte == 6 and sentStr:find("all", 1, true) then
                LOG.dbg(TAG, "  stop: sentinel 'all'")
                break
            end

            local gv = gg.getValues({
                { address = sPtr + 0x48, flags = 32 },  -- dynamic ptr1
                { address = sPtr + 0x50, flags = 32 },  -- dynamic ptr2
                { address = sPtr + 0x58, flags = 32 },  -- dynamic ptr3
                { address = sPtr + 0x60, flags = 32 },  -- static  ptr1
                { address = sPtr + 0x68, flags = 32 },  -- static  ptr2
                { address = sPtr + 0x70, flags = 32 },  -- static  ptr3
                { address = sPtr + 0x78, flags = 32 },  -- props   ptr1
                { address = sPtr + 0x80, flags = 32 },  -- props   ptr2
                { address = sPtr + 0x88, flags = 32 },  -- props   ptr3
            })

            -- s=ptr1 (buffer start), e=ptr2 (end of elements), c=ptr3 (capacity end)
            local origGroups = {
                dynamic = { s = gv[1].value, e = gv[2].value, c = gv[3].value },
                static  = { s = gv[4].value, e = gv[5].value, c = gv[6].value },
                props   = { s = gv[7].value, e = gv[8].value, c = gv[9].value },
            }

            LOG.info(TAG, string.format(
                "  sPtr=0x%X  dynamic=[0x%X..0x%X cap=0x%X](%d)  static=[0x%X..0x%X cap=0x%X](%d)  props=[0x%X..0x%X cap=0x%X](%d)",
                sPtr,
                origGroups.dynamic.s, origGroups.dynamic.e, origGroups.dynamic.c, math.max(0, math.floor((origGroups.dynamic.e - origGroups.dynamic.s) / 8)),
                origGroups.static.s,  origGroups.static.e,  origGroups.static.c,  math.max(0, math.floor((origGroups.static.e  - origGroups.static.s)  / 8)),
                origGroups.props.s,   origGroups.props.e,   origGroups.props.c,   math.max(0, math.floor((origGroups.props.e   - origGroups.props.s)   / 8))))

            anchorSlots[#anchorSlots + 1] = { addr = cur, sPtr = sPtr, origGroups = origGroups }

            for _, grp in ipairs(GROUP_ORDER) do
                local gs      = origGroups[grp].s
                local ge      = origGroups[grp].e
                local before  = #pool[grp]
                if gs ~= 0 and ge > gs then
                    local a = gs
                    while a < ge do
                        local _p  = gg.getValues({{ address = a, flags = 32 }})
                        local obj = _p and _p[1] and _p[1].value or 0
                        if obj ~= 0 then
                            pool[grp][#pool[grp] + 1] = obj
                        else
                            LOG.dbg(TAG, string.format("    %s: zero ptr at 0x%X — skipped", grp, a))
                        end
                        a = a + 0x8
                    end
                end
                LOG.dbg(TAG, string.format("    %s: collected %d ptrs from this slot", grp, #pool[grp] - before))
            end

            cur  = cur + 0x8
            step = step + 1
        end
    end

    LOG.info(TAG, string.format(
        "Pool totals: dynamic=%d  static=%d  props=%d  |  slots walked=%d",
        #pool.dynamic, #pool.static, #pool.props, #anchorSlots))

    return pool, anchorSlots
end

-- ── Chunk a flat pool into pages of PAGE_SIZE ─────────────────────────────────

local function chunkPool(pool)
    local pages = { dynamic = {}, static = {}, props = {} }
    for _, grp in ipairs(GROUP_ORDER) do
        local src = pool[grp]
        local i   = 1
        while i <= #src do
            local page = {}
            for j = i, math.min(i + PAGE_SIZE - 1, #src) do
                page[#page + 1] = src[j]
            end
            pages[grp][#pages[grp] + 1] = page
            i = i + PAGE_SIZE
        end
    end
    return pages
end

-- ── Zero requiresTheme on a slot ptr ─────────────────────────────────────────

local function zeroRequiresTheme(sPtr, writes)
    for _, off in ipairs(THEME_ZERO_OFFSETS) do
        writes[#writes + 1] = { address = sPtr + off, flags = 4, value = 0 }
    end
end

-- ── Write "hidden" into requiresTheme on a slot ptr ──────────────────────────
-- Layout: byte 0 = len*2 (6*2=12=0x0C), bytes 1-6 = "hidden"

local function writeHiddenTheme(sPtr, writes)
    writes[#writes + 1] = { address = sPtr + 0x00, flags = 1, value = 0x0C }
    local hid = { 0x68, 0x69, 0x64, 0x64, 0x65, 0x6E }  -- "hidden"
    for i, b in ipairs(hid) do
        writes[#writes + 1] = { address = sPtr + i, flags = 1, value = b }
    end
end

-- ── Zero all three cocos2d::Vector pointers for a group slot ─────────────────

local function zeroGroupSlot(sPtr, gs, writes)
    writes[#writes + 1] = { address = sPtr + gs.ptr1, flags = 32, value = 0 }
    writes[#writes + 1] = { address = sPtr + gs.ptr2, flags = 32, value = 0 }
    writes[#writes + 1] = { address = sPtr + gs.ptr3, flags = 32, value = 0 }
end

-- ── Main: anyThemeObjects ─────────────────────────────────────────────────────

---Merge all objectGroup ptr arrays into PAGE_SIZE chunks, allocate new memory
---for each chunk, and redistribute across anchor slots so the editor can scroll.
---Slots that receive data get requiresTheme zeroed; source-only slots get "hidden".
---@param state boolean  true = apply, false = revert
---@param cb fun(ok, errKey|nil, count|nil)
function M.anyThemeObjects(state, cb)
    scheduler:add(function(finishTask)
        local TAG = "AnyThemeObjects"

        -- ── Revert path ───────────────────────────────────────────────────────
        if not state then
            local cache = memory:load("any_theme_objects")
            if not cache then
                LOG.warn(TAG, "no cache to revert")
                finishTask(); cb(false, "creative.obj_no_cache"); return
            end

            -- 1. Restore original start/end pointers and requiresTheme on all slots
            local restoreWrites = {}
            for _, slot in ipairs(cache.slots) do
                -- Restore all three cocos2d::Vector pointers per group
                local og  = slot.origGroups
                local sp  = slot.sPtr
                -- dynamic
                restoreWrites[#restoreWrites + 1] = { address = sp + 0x48, flags = 32, value = og.dynamic.s }
                restoreWrites[#restoreWrites + 1] = { address = sp + 0x50, flags = 32, value = og.dynamic.e }
                restoreWrites[#restoreWrites + 1] = { address = sp + 0x58, flags = 32, value = og.dynamic.c }
                -- static
                restoreWrites[#restoreWrites + 1] = { address = sp + 0x60, flags = 32, value = og.static.s  }
                restoreWrites[#restoreWrites + 1] = { address = sp + 0x68, flags = 32, value = og.static.e  }
                restoreWrites[#restoreWrites + 1] = { address = sp + 0x70, flags = 32, value = og.static.c  }
                -- props
                restoreWrites[#restoreWrites + 1] = { address = sp + 0x78, flags = 32, value = og.props.s   }
                restoreWrites[#restoreWrites + 1] = { address = sp + 0x80, flags = 32, value = og.props.e   }
                restoreWrites[#restoreWrites + 1] = { address = sp + 0x88, flags = 32, value = og.props.c   }
                -- Restore original requiresTheme bytes
                for _, rb in ipairs(slot.origTheme) do
                    restoreWrites[#restoreWrites + 1] = rb
                end
            end
            gg.setValues(restoreWrites)

            -- 2. Free alloc handles from module-local store.
            -- After a script restart _liveAllocHandles is nil (handles are not
            -- serializable) — the alloc memory leaks for that session but the
            -- game state is correctly restored via the pointer writes above.
            if _liveAllocHandles then
                local freedCount = #_liveAllocHandles
                for _, handle in ipairs(_liveAllocHandles) do
                    handle:free()
                end
                _liveAllocHandles = nil
                LOG.info(TAG, string.format("Freed %d alloc handle(s)", freedCount))
            else
                LOG.warn(TAG, "No live alloc handles (script restarted?) — pointers restored but alloc memory not freed")
            end

            memory:save("any_theme_objects", nil)
            LOG.info(TAG, string.format("Reverted %d slot(s)", #cache.slots))
            finishTask(); cb(true, nil, #cache.slots); return
        end

        -- ── Apply path ────────────────────────────────────────────────────────

        -- Already applied?
        if memory:load("any_theme_objects") then
            LOG.warn(TAG, "already applied — revert first")
            finishTask(); cb(false, "creative.obj_already_applied"); return
        end

        -- Phase 1: resolve anchors
        local anchors = resolveAnchors(TAG)
        if not anchors or #anchors == 0 then
            finishTask(); cb(false, "creative.obj_anchor_not_found"); return
        end

        -- Phase 2: read all pools + walk record
        local pool, anchorSlots = readAllPools(TAG, anchors)
        if #anchorSlots == 0 then
            finishTask(); cb(false, "creative.obj_no_slots"); return
        end

        -- Phase 3: chunk into pages
        local pages    = chunkPool(pool)
        local numPages = math.max(#pages.dynamic, #pages.static, #pages.props)
        LOG.info(TAG, string.format(
            "Pages: dynamic=%d  static=%d  props=%d  → output slots needed=%d  available=%d",
            #pages.dynamic, #pages.static, #pages.props, numPages, #anchorSlots))

        if numPages > #anchorSlots then
            -- More pages than available anchor slots — shouldn't happen in practice
            -- since pool size / PAGE_SIZE ≤ anchorSlots × PAGE_SIZE / PAGE_SIZE
            LOG.warn(TAG, string.format(
                "need %d output slots but only %d anchor slots — capping", numPages, #anchorSlots))
            numPages = #anchorSlots
        end

        -- Phase 4: allocate new memory for each page × group
        local allocHandles = {}   -- flat list for cache/free
        local pageAllocs   = {}   -- [pageIdx][grp] = handle|nil

        local function freeAll()
            for _, h in ipairs(allocHandles) do h:free() end
        end

        for pi = 1, numPages do
            pageAllocs[pi] = {}
            for _, grp in ipairs(GROUP_ORDER) do
                local page = pages[grp][pi]
                if page and #page > 0 then
                    local sz     = #page * 8
                    local handle = alloc.new(sz, { flags = 32, step = 8, align = 8 })
                    if not handle then
                        LOG.error(TAG, string.format(
                            "alloc failed for page %d group %s (%d bytes)", pi, grp, sz))
                        freeAll()
                        finishTask(); cb(false, "creative.obj_alloc_failed"); return
                    end
                    handle:write(page)
                    allocHandles[#allocHandles + 1] = handle
                    pageAllocs[pi][grp] = handle
                    LOG.dbg(TAG, string.format(
                        "page[%d].%s → 0x%X (%d ptrs)", pi, grp, handle.base, #page))
                end
            end
        end

        -- Phase 5 + 6: write back + requiresTheme
        -- Output slots: anchorSlots[1..numPages] receive data (requiresTheme zeroed)
        -- Source slots: anchorSlots[numPages+1..#anchorSlots] get "hidden"

        local allWrites = {}

        -- Save original requiresTheme bytes for revert (read first, write after)
        -- We need 7 bytes per slot: byte at +0x00 (len sentinel) + 6 bytes for the string
        for _, slot in ipairs(anchorSlots) do
            local reads = {}
            for i = 0, 6 do
                reads[i + 1] = { address = slot.sPtr + i, flags = 1 }
            end
            local orig = gg.getValues(reads)
            slot.origTheme = orig or {}
        end

        -- Output slots (receive merged pages)
        LOG.info(TAG, string.format("Writing %d output slot(s)", numPages))
        for pi = 1, numPages do
            local slot = anchorSlots[pi]
            local sPtr = slot.sPtr
            LOG.info(TAG, string.format("  output slot[%d] sPtr=0x%X", pi, sPtr))

            for _, grp in ipairs(GROUP_ORDER) do
                local gs     = GROUP_SLOTS[grp]
                local handle = pageAllocs[pi][grp]
                if handle and pages[grp][pi] and #pages[grp][pi] > 0 then
                    local endAddr = handle.base + #pages[grp][pi] * 8
                    -- Write all three cocos2d::Vector pointers.
                    -- ptr3 == ptr2 since our alloc is exactly sized (no spare capacity).
                    LOG.info(TAG, string.format(
                        "    %s: alloc=0x%X..0x%X (%d ptrs) → +0x%X(ptr1) +0x%X(ptr2) +0x%X(ptr3)",
                        grp, handle.base, endAddr, #pages[grp][pi], gs.ptr1, gs.ptr2, gs.ptr3))
                    allWrites[#allWrites + 1] = { address = sPtr + gs.ptr1, flags = 32, value = handle.base }
                    allWrites[#allWrites + 1] = { address = sPtr + gs.ptr2, flags = 32, value = endAddr     }
                    allWrites[#allWrites + 1] = { address = sPtr + gs.ptr3, flags = 32, value = endAddr     }
                else
                    LOG.dbg(TAG, string.format("    %s: no data — zeroing ptr1/ptr2/ptr3", grp))
                    zeroGroupSlot(sPtr, gs, allWrites)
                end
            end

            zeroRequiresTheme(sPtr, allWrites)
        end

        -- Source-only slots (objects moved away → mark as "hidden")
        LOG.info(TAG, string.format("Hiding %d source-only slot(s)", #anchorSlots - numPages))
        for si = numPages + 1, #anchorSlots do
            LOG.dbg(TAG, string.format("  hidden slot[%d] sPtr=0x%X", si, anchorSlots[si].sPtr))
            writeHiddenTheme(anchorSlots[si].sPtr, allWrites)
        end

        gg.setValues(allWrites)

        -- Save serializable slot data to persistent cache (survives script restart
        -- as long as the game PID is the same). Alloc handles are runtime-only
        -- objects — keep them in a module-local so revert can free them if the
        -- script hasn't been restarted.
        _liveAllocHandles = allocHandles
        memory:save("any_theme_objects", { slots = anchorSlots })

        LOG.info(TAG, string.format(
            "Done: %d output slot(s), %d hidden, %d alloc(s), %d total writes",
            numPages, #anchorSlots - numPages, #allocHandles, #allWrites))
        finishTask(); cb(true, nil, numPages * PAGE_SIZE * 3)
    end)
end

---Show all hidden (testModeOnly) objects in the editor.
---Zeroes the testModeOnly byte (offset +0x101) for every object entry.
---@param state boolean  true = apply, false = revert
---@param cb fun(ok, errKey|nil, count|nil)
function M.showHiddenObjects(state, cb)
    scheduler:add(function(finishTask)
        local TAG = "ShowHiddenObjects"

        local cache = memory:load("show_hidden_objects")

        if state then
            local anchors = resolveAnchors(TAG)
            if not anchors or #anchors == 0 then
                finishTask(); cb(false, "creative.obj_anchor_not_found"); return
            end

            -- Walk all slots and collect ptr3 targets (same hidden walk as before)
            local hiddenTargets = {}
            for _, anchor in ipairs(anchors) do
                local cur = anchor - 0x20
                while true do
                    local _r  = gg.getValues({{ address = cur, flags = 32 }})
                    local ptr = _r and _r[1] and _r[1].value or 0
                    if ptr == 0 then break end

                    local _sb      = gg.getValues({{ address = ptr, flags = 1 }})
                    local sentByte = _sb and _sb[1] and _sb[1].value or 0
                    if sentByte == 6 and readString(ptr + 1, 3):find("all", 1, true) then break end

                    local rangeR    = gg.getValues({
                        { address = ptr + 0x30, flags = 32 },
                        { address = ptr + 0x38, flags = 32 },
                    })
                    local ptr2Start = rangeR and rangeR[1] and rangeR[1].value or 0
                    local ptr2End   = rangeR and rangeR[2] and rangeR[2].value or 0

                    if ptr2Start ~= 0 and ptr2End > ptr2Start then
                        local cur2 = ptr2Start
                        while cur2 < ptr2End do
                            local _r3  = gg.getValues({{ address = cur2, flags = 32 }})
                            local ptr3 = _r3 and _r3[1] and _r3[1].value or 0
                            if ptr3 ~= 0 then
                                hiddenTargets[#hiddenTargets + 1] = { address = ptr3 + 0x101, flags = 1, value = 0 }
                            end
                            cur2 = cur2 + 0x8
                        end
                    end
                    cur = cur + 0x8
                end
            end

            if #hiddenTargets == 0 then
                finishTask(); cb(false, "creative.obj_anchor_not_found"); return
            end

            if not cache then
                local reads = {}
                for _, w in ipairs(hiddenTargets) do
                    reads[#reads + 1] = { address = w.address, flags = w.flags }
                end
                cache = gg.getValues(reads)
                memory:save("show_hidden_objects", cache)
                LOG.dbg(TAG, string.format("Cached %d original byte(s)", #cache))
            end

            gg.setValues(hiddenTargets)
            LOG.info(TAG, string.format("Cleared testModeOnly on %d object(s)", #hiddenTargets))
            finishTask(); cb(true, nil, #hiddenTargets)
        else
            if not cache then
                LOG.warn(TAG, "No cache to revert")
                finishTask(); cb(false, "creative.obj_no_cache"); return
            end
            gg.setValues(cache)
            LOG.info(TAG, string.format("Reverted %d byte(s)", #cache))
            finishTask(); cb(true, nil, #cache)
        end
    end)
end

return M
