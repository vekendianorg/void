--[[
  Player Tab - Vehicle and character modifications
  Features: Auto-detach parts, No-clip mode, Hide name/flag, Adjust Zoom, Adjust Gravity
  
  @module callback Receives container View to populate with modules
]]

-- Dependencies: addModule, addArchModule, showToast, memory, BaseGameStatus, BaseRegion, scheduler

return function(container)
    local function t(key, ...) return T("player." .. key, ...) end
    
    addArchModule(container, "auto_detach", t("auto_detach.title"), t("auto_detach.desc"), "switch", nil, aobs.autoDetach)

    addModule(container, "no_clip", t("no_clip.title"), t("no_clip.desc"), "switch", nil,
    function(done, state)
        scheduler:add(function(finishTask)
            local TAG = "NoClip"
            local cache = memory:load("no_clip")
            if cache then
                LOG.dbg(TAG, "Using cached results")
                gg.clearResults()
                gg.loadResults(cache)
                gg.getResults(gg.getResultsCount())
            else
                LOG.dbg(TAG, "No cache — scanning memory")
                gg.clearResults()
                gg.setRanges(8)
                gg.searchNumber("h 0A D7 23 3C 00 00 00 00 00 00 20 C1", 1)
                gg.refineNumber("h 0A D7 23 3C", 1)
                local results = gg.getResults(gg.getResultsCount())
                LOG.info(TAG, "Scan results: " .. tostring(#results))
                memory:save("no_clip", results)
            end
            if state then
                gg.editAll("h CD CC 08 C1", 1)
                showToast(t("no_clip.enabled"), true)
                LOG.info(TAG, "Enabled")
            else
                gg.editAll("h 0A D7 23 3C", 1)
                showToast(t("no_clip.disabled"), true)
                LOG.info(TAG, "Disabled")
            end
            gg.clearResults()
            
            finishTask()
            done()
        end)
    end)

    addModule(container, "hide_name", t("hide_name.title"), t("hide_name.desc"), "switch", nil,
    function(done, state)
        scheduler:add(function(finishTask)
            local TAG = "HideName"
            local cache = memory:load("hide_name")
            if cache then
                LOG.dbg(TAG, "Using cached results")
                gg.clearResults()
                gg.loadResults(cache)
                gg.getResults(gg.getResultsCount())
            else
                LOG.dbg(TAG, "No cache — scanning memory")
                gg.clearResults()
                gg.setRanges(BaseRegion)
                gg.searchNumber("h BF 7D AD C1 64 CC 73 41 71 3D 0A 3F 71 3D 0A 3F", 1)
                gg.refineNumber("h 71 3D 0A 3F 71 3D 0A 3F", 1)
                local results = gg.getResults(gg.getResultsCount())
                LOG.info(TAG, "Scan results: " .. tostring(#results))
                memory:save("hide_name", results)
            end
            if state then
                gg.editAll("h 00 00 00 00 00 00 00 00", 1)
                showToast(t("hide_name.enabled"), true)
                LOG.info(TAG, "Enabled")
            else
                gg.editAll("h 71 3D 0A 3F 71 3D 0A 3F", 1)
                showToast(t("hide_name.disabled"), true)
                LOG.info(TAG, "Disabled")
            end
            gg.clearResults()
            
            finishTask()
            done()
        end)
    end)

    addModule(container, "hide_flag", t("hide_flag.title"), t("hide_flag.desc"), "switch", nil,
    function(done, state)
        scheduler:add(function(finishTask)
            local TAG = "HideFlag"

            local cache = memory:load("hide_flag")
            if cache then
                LOG.dbg(TAG, "Using cached results (part 1)")
                gg.clearResults()
                gg.loadResults(cache)
                gg.getResults(gg.getResultsCount())
            else
                LOG.dbg(TAG, "No cache — scanning memory (part 1)")
                gg.clearResults()
                gg.setRanges(BaseRegion)
                gg.searchNumber("h 2E FF D7 C1 36 CD 73 41 00 00 80 3F 00 00 80 3F 00 00 00 3F 00 00 00 3F FF FF FF FF 00 00 08 42 00 00 C0 41", 1)
                gg.refineNumber("h 00 00 08 42 00 00 C0 41", 1)
                local results = gg.getResults(gg.getResultsCount())
                LOG.info(TAG, "Scan results (part 1): " .. tostring(#results))
                memory:save("hide_flag", results)
            end
            if state then
                gg.editAll("h 00 00 00 00 00 00 00 00", 1)
            else
                gg.editAll("h 00 00 08 42 00 00 C0 41", 1)
            end
            gg.clearResults()

            local cache2 = memory:load("hide_flag2")
            if cache2 then
                LOG.dbg(TAG, "Using cached results (part 2)")
                gg.clearResults()
                gg.loadResults(cache2)
                gg.getResults(gg.getResultsCount())
            else
                LOG.dbg(TAG, "No cache — scanning memory (part 2)")
                gg.clearResults()
                gg.setRanges(BaseRegion)
                gg.searchNumber("h 61 32 DB C1 02 9A 70 41 C8 07 5D 3F 63 EE 5A 3F 00 00 00 3F 00 00 00 3F FF FF FF FF 00 00 44 42 00 00 20 42", 1)
                gg.refineNumber("h FF FF FF FF", 1)
                local results = gg.getResults(gg.getResultsCount())
                LOG.info(TAG, "Scan results (part 2): " .. tostring(#results))
                memory:save("hide_flag2", results)
            end
            if state then
                gg.editAll("h 00 00 00 00", 1)
                showToast(t("hide_flag.enabled"), true)
                LOG.info(TAG, "Enabled")
            else
                gg.editAll("h FF FF FF FF", 1)
                showToast(t("hide_flag.disabled"), true)
                LOG.info(TAG, "Disabled")
            end
            gg.clearResults()
            
            finishTask()
            done()
        end)
    end)
    
    addArchModule(container, "fuel", t("fuel.title"), t("fuel.desc"), "input", {
        {hint = t("fuel.hint"), type = "number"}
    }, function(done, vals)  -- no aobs.fuel here!
        scheduler:add(function(finishTask)
            local TAG = "Fuel"
            local val = tonumber(vals)
    
            if not val or val < 0 or val > 100 then
                showToast(t("fuel.invalid"), true)
                finishTask()
                done()
                return
            end
    
            local b = string.pack("<f", val)
            local lo = string.unpack("<H", b:sub(1,2))
            local hi = string.unpack("<H", b:sub(3,4))
            
            local NOP = 0xD503201F  
            local movz = 0x52800000 | (lo << 5) | 8
            local movk = 0x72A00000 | (hi << 5) | 8
            local fmov = 0x1E270100
        
            local cache = memory:load("fuel")
            if cache then
                LOG.dbg(TAG, "Using cached results")
                gg.clearResults()
                gg.loadResults(cache)
                gg.getResults(gg.getResultsCount())
            else
                LOG.dbg(TAG, "No cache — scanning")
                gg.clearResults()
                gg.setRanges(8)
                gg.searchNumber(aobs.fuel[1].scan, 1)
                gg.refineNumber("h 61", 1)
                local results = gg.getResults(gg.getResultsCount())
                LOG.info(TAG, "Scan results: " .. tostring(#results))
                memory:save("fuel", results)
            end
    
            local base = gg.getResults(1)[1].address
            gg.setValues({
                {address = base + 4,  flags = 4, value = cast.arm64(movz)},
                {address = base + 8,  flags = 4, value = cast.arm64(movk)},
                {address = base + 12, flags = 4, value = cast.arm64(fmov)},
                {address = base + 16, flags = 4, value = cast.arm64(NOP)},
            })
    
            showToast(t("fuel.applied", val), true)
            LOG.info(TAG, "Fuel set to " .. tostring(val))
            gg.clearResults()
            finishTask()
            done()
        end)
    end)

    addModule(container, "zoom", t("zoom.title"), t("zoom.desc"), "slider", {
        {title=t("slider.min"), min=10, max=100, current=20},
        {title=t("slider.max"), min=10, max=100, current=50}
    }, function(done, vals)
        scheduler:add(function(finishTask)
            local TAG = "Zoom"
            local results = memory:load("zoom")
            if not results then
                LOG.dbg(TAG, "No cache — scanning memory")
                gg.clearResults()
                gg.setRanges(16)
                gg.searchNumber("20;50::5", 16)
                results = gg.getResults(gg.getResultsCount())
                gg.clearResults()
                LOG.info(TAG, "Scan results: " .. tostring(#results))
                if #results > 0 then memory:save("zoom", results) end
            else
                LOG.dbg(TAG, "Using cached results")
            end
            if results then
                for i, v in ipairs(results) do
                    v.value = (i % 2 == 1) and vals[1] or vals[2]
                    v.flags = 16
                end
                gg.setValues(results)
                LOG.info(TAG, string.format("Zoom set — min: %s max: %s", tostring(vals[1]), tostring(vals[2])))
            else
                LOG.warn(TAG, "No results to apply zoom to")
            end
            
            finishTask()
            done()
        end)
    end)

    addModule(container, "gravity", t("gravity.title"), t("gravity.desc"), "slider", {
        {title=t("slider.x"), min=-100, max=100, current=0},
        {title=t("slider.y"), min=-100, max=100, current=-10}
    }, function(done, vals)
        scheduler:add(function(finishTask)
            local TAG = "Gravity"
            local allGravity = memory:load("gravity")

            if not allGravity then
                LOG.dbg(TAG, "No cache — running pointer walk scan")
                allGravity = { x = {}, y = {} }
                gg.clearResults()
                gg.setRanges(BaseRegion)
                gg.searchNumber("00000021h;00000000h;0000001Ah;00000000h;00000031h;00000000h;00000028h;00000000h;00000000h;00000017h;00000000h;756F4316h;7972746Eh;65646973h::81", 4)
                gg.refineNumber("00000021h", 4)

                local results = gg.getResults(gg.getResultsCount())
                gg.clearResults()
                LOG.dbg(TAG, "Initial scan hits: " .. tostring(#results))

                if #results > 0 then
                    local toProcess = {}
                    for _, v in ipairs(results) do
                        gg.searchNumber(v.address, 32)
                        local ptrResults = gg.getResults(gg.getResultsCount())
                        gg.clearResults()
                        for __, ptr in ipairs(ptrResults) do
                            local getPtr  = gg.getValues({{ address = ptr.address + 0x8, flags = 32 }})[1].value
                            local checkVal = gg.getValues({{ address = getPtr, flags = 4 }})[1].value
                            if checkVal == 0x74616E2A then
                                table.insert(toProcess, ptr.address)
                            end
                        end
                    end
                    LOG.dbg(TAG, "Validated base addresses: " .. tostring(#toProcess))

                    for _, baseAddr in ipairs(toProcess) do
                        local currentAddr = baseAddr
                        while true do
                            local gravityPtr = gg.getValues({{ address = currentAddr, flags = 32 }})[1].value
                            if gravityPtr == 0 then break end
                            local region = gg.getValuesRange({{ address = gravityPtr, flags = 32 }})[1]
                            if region == "Ca" or region == "O" then
                                local check = gg.getValues({{ address = gravityPtr + 0x48, flags = 4 }})[1].value
                                if check ~= 0 then
                                    table.insert(allGravity.x, {address = gravityPtr + 0x120, flags = 16})
                                    table.insert(allGravity.y, {address = gravityPtr + 0x124, flags = 16})
                                else
                                    break
                                end
                            else
                                break
                            end
                            currentAddr = currentAddr + 0x8
                        end
                    end

                    LOG.info(TAG, string.format("Gravity addresses found: %d", #allGravity.x))
                    memory:save("gravity", allGravity)
                else
                    LOG.warn(TAG, "Initial scan returned 0 results — gravity addresses not found")
                end
            else
                LOG.dbg(TAG, "Using cached gravity addresses: " .. tostring(#allGravity.x))
            end

            if #allGravity.x > 0 then
                for i = 1, #allGravity.x do
                    allGravity.x[i].value = vals[1]
                    allGravity.y[i].value = vals[2]
                end
                gg.setValues(allGravity.x)
                gg.setValues(allGravity.y)
                LOG.info(TAG, string.format("Gravity applied — X: %s Y: %s", tostring(vals[1]), tostring(vals[2])))
            else
                LOG.warn(TAG, "No gravity addresses to write to")
            end
            
            finishTask()
            done()
        end)
    end)
end
