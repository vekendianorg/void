--[[
  modules/ops/other.lua — Misc feature memory ops (no UI)
  Contract: see modules/ops/README.md.

  Globals used: scheduler, memory, gg, BaseRegion, BaseGameStatusRaw, LOG.
]]

local M = {}

-- Debug mode toggle. status: "enabled" | "disabled"
function M.debugMode(state, cb)
    scheduler:add(function(finishTask)
        gg.setValues({{
            address = BaseGameStatusRaw + 0x3,
            flags = 1,
            value = state and 1 or 0
        }})
        finishTask()
        cb(state and "enabled" or "disabled")
    end)
end

-- Set render resolution. params = { width, height } (raw strings/numbers).
-- status: "glsurface_not_found" | "none" | "applied"
-- On "applied", data = { width, height } (resolved numbers).
function M.setResolution(params, cb)
    scheduler:add(function(finishTask)
        local TAG = "Resolution"
        local width  = tonumber(params.width)  or 1280
        local height = tonumber(params.height) or 720
        LOG.info(TAG, string.format("Applying resolution: %dx%d", width, height))

        local results = memory:load("resolution")

        if not results then
            LOG.dbg(TAG, "No cache — searching for GLSurfaceView")
            gg.clearResults()
            gg.setRanges(BaseRegion)

            gg.searchNumber(":Cocos2dxGLSurfaceView", 1)
            gg.refineNumber(":C", 1)
            local cocos = gg.getResults(gg.getResultsCount())
            gg.clearResults()

            if #cocos == 0 then
                LOG.warn(TAG, "GLSurfaceView not found in memory")
                finishTask(); cb("glsurface_not_found"); return
            end

            local addresses = {}

            for i, v in ipairs(cocos) do
                gg.searchNumber(v.address, 32)
                local ptrs = gg.getResults(gg.getResultsCount())
                gg.clearResults()

                for _, p in ipairs(ptrs) do
                    table.insert(addresses, p.address + 0x38)
                    table.insert(addresses, p.address + 0x3C)
                    table.insert(addresses, p.address + 0x40)
                    table.insert(addresses, p.address + 0x44)
                end
            end

            if #addresses > 0 then
                results = addresses
                memory:save("resolution", results)
            else
                finishTask(); cb("none"); return
            end
        end

        if results and #results > 0 then
            local values = {}

            for i = 1, #results, 4 do
                if results[i] then
                    table.insert(values, {address = results[i], flags = 4, value = width})
                    table.insert(values, {address = results[i+1], flags = 4, value = height})
                    table.insert(values, {address = results[i+2], flags = 4, value = width})
                    table.insert(values, {address = results[i+3], flags = 4, value = height})
                end
            end

            if #values > 0 then
                gg.setValues(values)
                finishTask(); cb("applied", { width = width, height = height }); return
            end
        end

        finishTask()
        cb("none")
    end)
end

-- Set resolution offset. params = { width, height } (raw strings/numbers).
-- status: "glsurface_not_found" | "none" | "applied"
-- On "applied", data = { width, height } (resolved numbers).
function M.setResolutionOffset(params, cb)
    scheduler:add(function(finishTask)
        local width  = tonumber(params.width)  or 0
        local height = tonumber(params.height) or 0

        local results = memory:load("resolution_offset")

        if not results then
            gg.clearResults()
            gg.setRanges(BaseRegion)

            gg.searchNumber(":Cocos2dxGLSurfaceView", 1)
            gg.refineNumber(":C", 1)
            local cocos = gg.getResults(gg.getResultsCount())
            gg.clearResults()

            if #cocos == 0 then
                finishTask(); cb("glsurface_not_found"); return
            end

            local addresses = {}

            for i, v in ipairs(cocos) do
                gg.searchNumber(v.address, 32)
                local ptrs = gg.getResults(gg.getResultsCount())
                gg.clearResults()

                for _, p in ipairs(ptrs) do
                    table.insert(addresses, p.address + 0x30)
                    table.insert(addresses, p.address + 0x34)
                end
            end

            if #addresses > 0 then
                results = addresses
                memory:save("resolution_offset", results)
            else
                finishTask(); cb("none"); return
            end
        end

        if results and #results > 0 then
            local values = {}

            for i = 1, #results, 2 do
                if results[i] then
                    table.insert(values, {address = results[i], flags = 4, value = width})
                    table.insert(values, {address = results[i+1], flags = 4, value = height})
                end
            end

            if #values > 0 then
                gg.setValues(values)
                finishTask(); cb("applied", { width = width, height = height }); return
            end
        end

        finishTask()
        cb("none")
    end)
end

return M
