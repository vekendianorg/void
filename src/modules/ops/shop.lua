--[[
  modules/ops/shop.lua — Shop feature memory ops (no UI)
  Contract: see modules/ops/README.md.

  Globals used: scheduler, memory, gg, BaseRegion, LOG.
]]

local M = {}

-- Free chest toggle. status: "enabled" | "disabled"
function M.freeChest(state, cb)
    scheduler:add(function(finishTask)
        local TAG = "FreeChest"
        local cache = memory:load("free_chest")
        if cache then
            LOG.dbg(TAG, "Using cached results")
            gg.clearResults()
            gg.loadResults(cache)
            gg.getResults(gg.getResultsCount())
        else
            LOG.dbg(TAG, "No cache — scanning memory")
            gg.clearResults()
            gg.setRanges(8)
            gg.searchNumber("h CE CC 4C 3F AF 47 E1 3E FA 7E AA 3E 5B B1 BF 3C CD CC CC 3D", 1)
            gg.refineNumber("h CD CC CC 3D", 1)
            local results = gg.getResults(gg.getResultsCount())
            LOG.info(TAG, "Scan results: " .. tostring(#results))
            memory:save("free_chest", results)
        end

        if state then
            gg.editAll("0", 1)
        else
            gg.editAll("h CD CC CC 3D", 1)
        end

        gg.clearResults()
        finishTask()
        cb(state and "enabled" or "disabled")
    end)
end

-- Free purchases. `onProgress(counter, total)` is an optional UI reporter
-- invoked during the pointer-collection loop.
-- status: "success" | "none"
function M.freePurchases(onProgress, cb)
    scheduler:add(function(finishTask)
        gg.clearResults()
        gg.setRanges(4)
        gg.searchNumber("h 04 65 6E 00", 1)
        gg.refineNumber("h 04", 1)

        local results = gg.getResults(gg.getResultsCount())
        local totalres = #results
        local applied = false
        if totalres > 0 then
            local counter = 0
            local edits = {}
            local tptrs = {}

            for _, r in ipairs(results) do
                gg.clearResults()
                gg.searchNumber(tostring(r.address), 32)
                local ptrs = gg.getResults(gg.getResultsCount())
                for _, sp in ipairs(ptrs) do
                    table.insert(tptrs, {address = sp.address + 0x18, flags = 4})
                end
                counter = counter + 1
                if onProgress then onProgress(counter, totalres) end
            end

            tptrs = gg.getValues(tptrs)
            for _, p in ipairs(tptrs) do
                local val = p.value
                if val > 0 and val < 100 then
                    for off = 0x18, 0x2C, 4 do
                        table.insert(edits, {address = p.address + off, flags = 4, value = 0})
                    end
                end
            end

            if #edits > 0 then
                gg.setValues(edits)
                applied = true
            end
        end

        gg.clearResults()
        finishTask()
        cb(applied and "success" or "none")
    end)
end

-- Change chest type by spinner index (1-based). status: "changed"
function M.changeChest(index, cb)
    scheduler:add(function(finishTask)
        local chestIDs = {
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 18, 19, 20
        }
        local cache = memory:load("change_chest")
        if cache then
            gg.clearResults()
            gg.loadResults(cache)
            gg.getResults(gg.getResultsCount())
        else
            gg.clearResults()
            gg.setRanges(BaseRegion)
            gg.searchNumber("h 2A 48 75 67 65 20 43 68 65 73 74 20 6F 66 20 47 6F 6F 64 69", 1)
            gg.refineNumber("h 2A", 1)
            local results = gg.getResults(gg.getResultsCount())
            if #results > 0 then
                gg.loadResults(gg.getValues({{ address = results[1].address + 0x4C, flags = 1 }}))
                local results2 = gg.getResults(gg.getResultsCount())
                memory:save("change_chest", results2)
            end
        end

        gg.editAll(chestIDs[index], 1)

        gg.clearResults()
        finishTask()
        cb("changed")
    end)
end

return M
