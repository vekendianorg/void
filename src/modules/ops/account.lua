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

-- Apply fake rank (writes 50.0). The tab confirms M.isCupsTab() and shows the
-- race-warning dialog BEFORE calling this.
-- status: "applied"
function M.applyFakeRank(cb)
    scheduler:add(function(finishTask)
        gg.setValues({
            { address = BaseGameStatus + 0x200, flags = 16, value = 50.0 }
        })
        LOG.info("FakeRank", "Fake rank applied.")
        finishTask()
        cb("applied")
    end)
end

return M
