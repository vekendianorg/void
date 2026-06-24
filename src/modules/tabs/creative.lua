--[[
  Creative Tab - Creative mode / Custom track features
  Status: auto_verify_all unfinished (task 5)

  UI wiring only. Memory ops live in modules/ops/creative.lua.

  @module callback Receives container View to populate with modules
]]

local ops = CrashHandler.loadFeature("modules/ops/creative.lua")

return function(container)
    local function t(key, ...) return T("creative." .. key, ...) end

    addArchModule(container, "auto_verify_all", t("auto_verify_all.title"), t("auto_verify_all.desc"), "button", nil,
    function(done)
        showDialog("still in progress", "unfinished", "ok")
        ops.autoVerifyAll(function() end)
        done()
    end)
end
