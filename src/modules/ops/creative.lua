--[[
  modules/ops/creative.lua — Creative / custom-track memory ops (no UI)
  Contract: see modules/ops/README.md.

  NOTE: auto_verify_all is still unfinished (tracked as task 5). The logic
  below is the relocated stub; getCustomTrack() is the started-but-unused
  helper kept here for that future implementation.

  Globals used: scheduler, gg, BaseLib, offsets, LOG.
]]

local M = {}

-- Resolve the custom-track list. Started helper, not yet wired into a feature.
local function getCustomTrack()
    gg.clearResults()
    gg.setRanges(8)
    gg.searchNumber(BaseLib + offsets.customTracks, 32)
    local refs = gg.getResults(gg.getResultsCount())
    if #refs > 0 then
        for _, v in ipairs(refs) do

        end
    end
end

M.getCustomTrack = getCustomTrack

-- Auto-verify all custom tracks. UNFINISHED — runs an empty scheduled task.
-- status: "unfinished"
function M.autoVerifyAll(cb)
    scheduler:add(function(finishTask)
        -- TODO (task 5): implement using getCustomTrack().
        finishTask()
        cb("unfinished")
    end)
end

return M
