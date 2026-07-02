--[[
  modules/ops/account.lua — Account feature memory ops (no UI)
  Contract: see modules/ops/README.md. Order mirrors the Account tab.

  Globals used: scheduler, memory, gg, BaseGameStatus, BaseGameStatusRaw, LOG.
]]

local M = {}

-- Change the player name (max 12 bytes).
-- status: "empty" | "too_long" | "resolve_failed" | "applied"
function M.changeName(val, cb)
    scheduler:add(function(finishTask)
        local TAG = "ChangeName"

        if val == nil or val == "" then
            LOG.warn(TAG, "Empty input — aborted")
            finishTask(); cb("empty"); return
        end

        local nameBytes = {}
        local byteCount = 0

        for _, code in utf8.codes(val) do
            local encoded = utf8.char(code)
            local bytes   = { encoded:byte(1, -1) }
            if byteCount + #bytes > 12 then
                LOG.warn(TAG, "Name exceeds 12 bytes — aborted")
                finishTask(); cb("too_long"); return
            end
            for _, b in ipairs(bytes) do
                table.insert(nameBytes, b)
                byteCount = byteCount + 1
            end
        end

        while #nameBytes < 12 do table.insert(nameBytes, 0) end

        local namePtr = gg.getValues({{ address = BaseGameStatus + 0x38, flags = 32 }})[1].value
        if not namePtr or namePtr == 0 then
            LOG.fatal(TAG, "namePtr is nil or 0")
            finishTask(); cb("resolve_failed"); return
        end

        local writes = {{ address = namePtr, flags = 1, value = byteCount * 2 }}
        for i = 1, #nameBytes do
            writes[#writes + 1] = { address = namePtr + i, flags = 1, value = nameBytes[i] }
        end

        gg.setValues(writes)
        LOG.info(TAG, string.format("Done. byteCount=%d namePtr=0x%X", byteCount, namePtr))
        finishTask()
        cb("applied")
    end)
end

-- Set Gameplay (GP) currency. Valid range: 8 .. 2147483647.
-- status: "max_int" | "too_low" | "applied"
function M.changeGp(val, cb)
    scheduler:add(function(finishTask)
        local n = tonumber(val)
        if n and n > 2147483647 then
            finishTask(); cb("max_int"); return
        elseif not n or n < 8 then
            finishTask(); cb("too_low"); return
        end

        gg.setValues({
            { address = BaseGameStatus + 0x4F4, flags = 4, value = val }
        })

        finishTask()
        cb("applied")
    end)
end

-- ── Fake rank ─────────────────────────────────────────────────────────────────

-- Quick synchronous read used by the tab to gate the fake-rank action:
-- is the game currently on the Cups tab? (activeTab == 1)
function M.isCupsTab()
    local activeTab = gg.getValues({{ address = BaseGameStatusRaw - 0xD4, flags = 4 }})
    return type(activeTab) == "table" and activeTab[1] ~= nil and activeTab[1].value == 1
end

-- Apply fake rank (writes the given value). The tab confirms M.isCupsTab() and
-- shows the race-warning dialog BEFORE calling this.
-- value: number to write, defaults to 50.0 if nil/invalid
-- status: "applied"
function M.applyFakeRank(value, cb)
    local rank = tonumber(value) or 50.0
    scheduler:add(function(finishTask)
        gg.setValues({
            { address = BaseGameStatus + 0x200, flags = 16, value = rank }
        })
        LOG.info("FakeRank", string.format("Fake rank applied: %.1f", rank))
        finishTask()
        cb("applied")
    end)
end


-- ── Change Win Streak ────────────────────────────────────────────────────────

-- Write current and best win streak values.
-- status: "resolve_failed" | "applied"
function M.changeWinStreak(current, best, cb)
    scheduler:add(function(finishTask)
        local TAG = "ChangeWinStreak"

        local reads = gg.getValues({
            { address = BaseGameStatus + 0x6AC, flags = 4  },  -- static key
            { address = BaseGameStatus + 0x768, flags = 32 },  -- current WS ptr
            { address = BaseGameStatus + 0x770, flags = 32 },  -- best WS ptr
        })

        local staticKey  = reads[1] and reads[1].value or 0
        local currentPtr = reads[2] and reads[2].value or 0
        local bestPtr    = reads[3] and reads[3].value or 0

        LOG.info(TAG, string.format(
            "staticKey=0x%X  currentPtr=0x%X  bestPtr=0x%X",
            staticKey, currentPtr, bestPtr))

        if currentPtr == 0 or bestPtr == 0 then
            LOG.error(TAG, "one or more ptrs are 0 — resolve failed")
            finishTask(); cb("resolve_failed"); return
        end

        gg.setValues({
            { address = currentPtr + 0x18, flags = 4, value = staticKey },
            { address = currentPtr + 0x1C, flags = 4, value = current   },
            { address = currentPtr + 0x20, flags = 4, value = 0         },
            { address = currentPtr + 0x24, flags = 4, value = 0         },
            { address = bestPtr    + 0x18, flags = 4, value = staticKey },
            { address = bestPtr    + 0x1C, flags = 4, value = best      },
            { address = bestPtr    + 0x20, flags = 4, value = 0         },
            { address = bestPtr    + 0x24, flags = 4, value = 0         },
        })

        LOG.info(TAG, string.format("Applied — current=%d  best=%d", current, best))
        finishTask(); cb("applied")
    end)
end

-- ── Unlock achievements ─────────────────────────────────────────────────────────────────
-- unfinished, don't touch

local _achievementsData = {}
local function achievementsData()
    if _achievementsData ~= nil then return _achievementsData or nil end
    local ok, data = pcall(function() return json.decode(loadModule("configs/achievements.json")) end)
    if not ok or type(data) ~= "table" then
        LOG.warn("Vehicle", "achievements.json failed to decode")
        _achievementsData = false
        return nil
    end
    _achievementsData = data
    return data
end

-- TODO: in progress
function M.unlockAchievements()
    LOG.warn(TAG, "unlockAchievements: not yet implemented")
end

return M
