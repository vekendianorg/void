--[[
  Shop Tab - Shop mode features
  Features: Free chest, Free purchases, Change chest type

  UI wiring only. Memory ops live in modules/ops/shop.lua.

  @module callback Receives container View to populate with modules
]]

local ops = CrashHandler.loadFeature("modules/ops/shop.lua")

return function(container)
    local function t(key, ...) return T("shop." .. key, ...) end

    addModule(container, "free_chest", t("free_chest.title"), t("free_chest.desc"), "switch", nil, function(done, state)
        ops.freeChest(state, function(status)
            showToast(t("free_chest." .. status), true)
        end)
        done()
    end)

    addModule(container, "free_purchases", t("free_purchases.title"), t("free_purchases.desc"), "button", nil, function(done)
        ops.freePurchases(
            function(counter, total) showToast(t("free_purchases.progress", counter, total), true) end,
            function(status)
                if status == "success" then gg.toast(t("free_purchases.success")) end
            end)
        done()
    end)

    addModule(container, "change_chest", t("change_chest.title"), t("change_chest.desc"), "spinner", {
        options = t("change_chest.options"),
        default = 8
    }, function(done, item, index)
        ops.changeChest(index, function()
            showToast(t("change_chest.changed", item))
        end)
        done()
    end)
end
