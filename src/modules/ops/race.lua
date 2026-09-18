--[[
  modules/ops/race.lua - Live race feature ops (no UI)
  Contract: see modules/ops/README.md. Order mirrors the Race tab.

  Every op is race-gated via lib/raceops.lua: outside a live race the op
  returns the "no_race" status and the tab tells the user to enter a
  race first, then activate the feature again.

  All paths are scalar dotted reads/writes on PlayerInfo (Nebula 1.0.1),
  benchmark-verified live at 2-20ms per op.

  status codes: "applied" | "no_race" | "nebula_unavailable" | "failed"

  Globals used: scheduler, Nebula, LOG.
]]

local raceops = loadModule("modules/lib/raceops.lua")

local M = {}

-- Shared runner: adds the op to the scheduler, runs the guarded body,
-- maps errors to status codes, always calls back.
local function run(cb, body)
    scheduler:add(function(finishTask)
        local ok, status, data = pcall(body)
        if not ok then
            LOG.error("RaceOps", "op crashed: " .. tostring(status))
            status, data = "failed", nil
        end
        finishTask()
        cb(status, data)
    end)
end

-- Numeric input sanitizer: nil/empty -> default, clamped to >= 0,
-- integer unless allowFloat.
local function amountOf(raw, default, allowFloat)
    local n = tonumber(raw)
    if n == nil then n = default end
    if n < 0 then n = 0 end
    if not allowFloat then n = n // 1 end
    return n
end

-- Currencies ---------------------------------------------------------------

-- Inject coins into the live race counter (added to race rewards at finish).
-- data: { value = new collectedCoins }
function M.injectCoins(raw, cb)
    run(cb, function()
        local amount = amountOf(raw, 100000)
        local state, err = raceops.guardLive()
        if not state then return err end
        local value, werr = raceops.add("currentRace.collectedCoins", amount)
        if value == nil then return "failed", werr end
        return "applied", { value = value }
    end)
end

-- Inject gems into the live race counter.
function M.injectGems(raw, cb)
    run(cb, function()
        local amount = amountOf(raw, 100)
        local state, err = raceops.guardLive()
        if not state then return err end
        local value, werr = raceops.add("currentRace.collectedGems", amount)
        if value == nil then return "failed", werr end
        return "applied", { value = value }
    end)
end

-- Inject bonus coins into all four trick bonus counters at once.
function M.injectBonusCoins(raw, cb)
    run(cb, function()
        local amount = amountOf(raw, 10000)
        local state, err = raceops.guardLive()
        if not state then return err end
        local fields = {
            "trickBonusCoins",
            "flipBonusCoins",
            "wheelieBonusCoins",
            "airtimeBonusCoins",
        }
        local applied = 0
        for _, name in ipairs(fields) do
            local value, werr = raceops.add("currentRace." .. name, amount)
            if value ~= nil then applied = applied + 1 end
        end
        if applied == 0 then return "failed" end
        return "applied", { count = applied, amount = amount }
    end)
end

-- Set the live coin collectible multiplier (applies to coins collected
-- from now on in this race).
function M.setCoinMultiplier(raw, cb)
    run(cb, function()
        local amount = amountOf(raw, 10)
        local state, err = raceops.guardLive()
        if not state then return err end
        local ok, werr = raceops.write("currentRace.coinCollectibleMultiplier", amount)
        if not ok then return "failed", werr end
        return "applied", { value = amount }
    end)
end

-- XP and Mastery -------------------------------------------------------------

-- Inject XP into the live race counter.
function M.injectXp(raw, cb)
    run(cb, function()
        local amount = amountOf(raw, 100000)
        local state, err = raceops.guardLive()
        if not state then return err end
        local value, werr = raceops.add("currentRace.collectedXp", amount)
        if value == nil then return "failed", werr end
        return "applied", { value = value }
    end)
end

-- Inject mastery XP into the live race counter (the +100K instant
-- mastery boost: finishes the race with the injected XP banked).
function M.injectMasteryXp(raw, cb)
    run(cb, function()
        local amount = amountOf(raw, 100000)
        local state, err = raceops.guardLive()
        if not state then return err end
        local value, werr = raceops.add("currentRace.gainedMasteryXp", amount)
        if value == nil then return "failed", werr end
        return "applied", { value = value }
    end)
end

-- Points and records ----------------------------------------------------------

-- Inject ranked race points mid-race (cups / ranked events).
function M.injectRacePoints(raw, cb)
    run(cb, function()
        local amount = amountOf(raw, 1000)
        local state, err = raceops.guardLive()
        if not state then return err end
        local value, werr = raceops.add("currentRace.racePoints", amount)
        if value == nil then return "failed", werr end
        return "applied", { value = value }
    end)
end

-- Inject distance bonus (Float field).
function M.injectDistanceBonus(raw, cb)
    run(cb, function()
        local amount = amountOf(raw, 1000, true)
        local state, err = raceops.guardLive()
        if not state then return err end
        local value, werr = raceops.add("currentRace.distanceBonus", amount)
        if value == nil then return "failed", werr end
        return "applied", { value = value }
    end)
end

-- Inject destroy bonus (Float field) and bump the destroyed counter.
function M.injectDestroyBonus(raw, cb)
    run(cb, function()
        local amount = amountOf(raw, 1000, true)
        local state, err = raceops.guardLive()
        if not state then return err end
        local value, werr = raceops.add("currentRace.destroyBonus", amount)
        if value == nil then return "failed", werr end
        raceops.add("currentRace.breakableObjectsDestroyed", amount // 1)
        return "applied", { value = value }
    end)
end

-- Inject finish bonus: coins + finish-time bonus points at once.
function M.injectFinishBonus(raw, cb)
    run(cb, function()
        local amount = amountOf(raw, 1000)
        local state, err = raceops.guardLive()
        if not state then return err end
        local coins, werr = raceops.add("currentRace.finishBonusCoins", amount)
        if coins == nil then return "failed", werr end
        raceops.add("currentRace.finishTimeBonusPoints", amount)
        return "applied", { value = coins }
    end)
end

-- Edit the "old" values the race result screen compares against.
-- vals: { record = s|nil, stars = s|nil, rankDiv = s|nil, wcRank = s|nil }
-- data: { count = fields_written }
function M.editRecords(vals, cb)
    run(cb, function()
        local state, err = raceops.guardLive()
        if not state then return err end

        local targets = {
            { src = vals and vals.record,  path = "currentRace.oldRecord",         float = true  },
            { src = vals and vals.stars,   path = "currentRace.oldStars",          float = false },
            { src = vals and vals.rankDiv, path = "currentRace.oldRankingInDiv",    float = false },
            { src = vals and vals.wcRank,   path = "currentRace.oldWcRank",         float = true  },
        }

        local count = 0
        for _, t in ipairs(targets) do
            local n = t.src ~= nil and t.src ~= "" and tonumber(t.src) or nil
            if n ~= nil then
                local ok, werr = raceops.write(t.path, n)
                if ok then count = count + 1 end
            end
        end
        if count == 0 then return "failed", "no_fields" end
        return "applied", { count = count }
    end)
end

-- Refill consumed rank doublers for the live race.
function M.refillRankDoublers(cb)
    run(cb, function()
        local state, err = raceops.guardLive()
        if not state then return err end
        local ok, werr = raceops.write("currentRace.consumedRankDoublers", 0)
        if not ok then return "failed", werr end
        return "applied"
    end)
end

-- Utilities --------------------------------------------------------------------

-- Reset all respawn counters (free respawns for the rest of the race).
function M.freeRespawns(cb)
    run(cb, function()
        local state, err = raceops.guardLive()
        if not state then return err end
        local count = 0
        if raceops.write("currentRace.respawnCount", 0) then count = count + 1 end
        if raceops.write("currentRace.respawnAdsWatched", 0) then count = count + 1 end
        if raceops.write("currentRace.respawnGracePeriodUsed", false) then count = count + 1 end
        if count == 0 then return "failed" end
        return "applied", { count = count }
    end)
end

-- Edit the skipped fuel canister counter (add n, or subtract via input).
function M.editSkippedCanisters(raw, cb)
    run(cb, function()
        local delta = tonumber(raw) or 0
        local state, err = raceops.guardLive()
        if not state then return err end
        local value, werr = raceops.add("currentRace.skippedFuelCanisters", delta)
        if value == nil then return "failed", werr end
        return "applied", { value = value }
    end)
end

-- Activate the double adventure token reward on the live race.
function M.doubleAdventureToken(cb)
    run(cb, function()
        local state, err = raceops.guardLive()
        if not state then return err end
        local ok, werr = raceops.write("currentRace.hasDoubleAdventureTokenReward", true)
        if not ok then return "failed", werr end
        return "applied"
    end)
end

-- Read-only live status (one scalar read per line, never a dump).
-- data: { state, coins, gems, xp, mastery, points, distance }
function M.readStatus(cb)
    run(cb, function()
        local state, err = raceops.raceState()
        if state == nil then return err end

        local function scalar(path)
            local v = raceops.read(path)
            return type(v) == "number" and tostring(v) or "n/a"
        end

        return "applied", {
            state    = state,
            coins    = scalar("currentRace.collectedCoins"),
            gems     = scalar("currentRace.collectedGems"),
            xp       = scalar("currentRace.collectedXp"),
            mastery  = scalar("currentRace.gainedMasteryXp"),
            points   = scalar("currentRace.racePoints"),
            distance = scalar("currentRace.distanceBonus"),
        }
    end)
end

return M
