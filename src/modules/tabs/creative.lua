--[[
  Creative Tab - Creative mode/Custom track features
  Status: idk
  
  @module callback Receives container View to populate with modules
]]

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

return function(container)
    local function t(key, ...) return T("creative." .. key, ...) end
    
    addArchModule(container, "auto_verify_all", t("auto_verify_all.title"), t("auto_verify_all.desc"), "button", nil,
    function(done)
        local TAG = "AutoVerifyAll"
        
        showDialog("still in progress", "unfinished", "ok")
        schedelur:add(function(finishTask)
            
            finishTask()
            done()
        end)
        
        done()
    end)
    
end
