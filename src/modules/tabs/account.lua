--[[
  Account Tab - Player profile modifications
  Features: Change player name, Fake VIP, Fake Rank
  
  @module callback Receives container View to populate with modules
]]

return function(container)
    local function t(key, ...) return T("account." .. key, ...) end

    addModule(container, "change_name", t("change_name.title"), t("change_name.desc"), "input", {
        { hint = t("change_name.hint"), value = "", type = "text" }
    }, function(done, val)
        scheduler:add(function(finishTask)
            local TAG = "ChangeName"

            if val == nil or val == "" then
                showToast(t("change_name.empty"))
                LOG.warn(TAG, "Empty input — aborted")
                finishTask(); done(); return
            end

            LOG.info(TAG, "Attempting name change to: " .. val)

            local nameBytes = {}
            local byteCount = 0

            for _, code in utf8.codes(val) do
                local encoded = utf8.char(code)
                local bytes   = { encoded:byte(1, -1) }
                if byteCount + #bytes > 12 then
                    showDialog(t("change_name.too_long_title"), t("change_name.too_long_msg"), T("common.ok"))
                    LOG.warn(TAG, "Name exceeds 12 bytes — aborted")
                    finishTask(); done(); return
                end
                for _, b in ipairs(bytes) do
                    table.insert(nameBytes, b)
                    byteCount = byteCount + 1
                end
            end

            while #nameBytes < 12 do table.insert(nameBytes, 0) end

            local namePtr = gg.getValues({{ address = BaseGameStatus + 0x38, flags = 32 }})[1].value
            if not namePtr or namePtr == 0 then
                showToast(t("change_name.resolve_failed"))
                LOG.fatal(TAG, "namePtr is nil or 0")
                finishTask(); done(); return
            end

            local writes  = {{ address = namePtr, flags = 1, value = byteCount * 2 }}
            for i = 1, #nameBytes do
                writes[#writes + 1] = { address = namePtr + i, flags = 1, value = nameBytes[i] }
            end

            gg.setValues(writes)
            showToast(t("change_name.applied", val))
            LOG.info(TAG, string.format("Done. byteCount=%d namePtr=0x%X", byteCount, namePtr))
            finishTask()
            done()
        end)
    end)
    
    addModule(container, "change_gp", t("change_gp.title"), t("change_gp.desc"), "input", {
        { hint = t("change_gp.hint"), value = "8", type = "number" }
    }, function(done, val)
        scheduler:add(function(finishTask)
            if tonumber(val) > 2147483647 then
                showDialog(t("change_gp.max_int_title"), t("change_gp.lower_value"), {T("common.ok")})
                finishTask()
                done()
                return
            elseif tonumber(val) < 8 then
                showDialog(t("change_gp.too_low_title"), t("change_gp.higher_value"), {T("common.ok")})
                finishTask()
                done()
                return
            end
            
            gg.setValues({
                { address = BaseGameStatus + 0x4F4, flags = 4, value = val }
            })
            
            showToast(t("change_gp.applied", tostring(val)))
            finishTask()
            done()
        end)
    end)
    
    addArchModule(container, "fake_unlock", t("fake_unlock.title"), t("fake_unlock.desc"), "switch", nil, aobs.fakeUnlock)
    
    addArchModule(container, "fake_vip", t("fake_vip.title"), t("fake_vip.desc"), "switch", nil, aobs.fakeVip)
        
    addModule(container, "fake_rank", t("fake_rank.title"), t("fake_rank.desc"), "button", nil, function(done)
        local TAG = "FakeRank"
    
        local activeTab = gg.getValues({
            { address = BaseGameStatusRaw - 0xD4, flags = 4 }
        })
    
        local isCupsTab = (type(activeTab) == "table" and activeTab[1] and activeTab[1].value == 1 )   
        if not isCupsTab then
            LOG.warn(TAG, "Not in Cups tab.")
            showToast(t("fake_rank.not_in_cups"))
            done()
            return
        end
    
        local confirm = showDialog(
            t("fake_rank.race_warn_title"),
            t("fake_rank.race_warn_msg"),
            {t("fake_rank.continue_button")},
            {T("common.cancel")}
        )
    
        if confirm ~= 1 then
            done()
            return
        end
    
        scheduler:add(function(finishTask)
            gg.setValues({
                { address = BaseGameStatus + 0x200, flags = 16, value = 50.0 }
            })
    
            LOG.info(TAG, "Fake rank applied.")
            showToast(t("fake_rank.applied"))
    
            finishTask()
            done()
        end)
    end)
end
