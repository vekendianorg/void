--[[
  Status Tab - Live diagnostics (Script section, under Settings)

  Read-only snapshots of Nebula (version, metadata map, save/GameData
  channels), the game process (package, version, arch), and the memory
  section moved over from Settings. The Nebula probes do cheap single-field
  reads; the GameData probe resolves the GameData base on first open.

  @module callback Receives container View to populate with modules
]]

return function(container)
    local function t(key, ...) return T("status." .. key, ...) end

    -- ── Nebula ────────────────────────────────────────────────────────────────
    addModuleSep(container, t("section_nebula"))

    local nebVersion = (Nebula and Nebula.VERSION) or "not loaded"
    addModule(container, "nebula_version", t("nebula_version.title"),
        t("nebula_version.desc"), "ro", tostring(nebVersion), nil)

    local metaVersion = "unresolved"
    if Nebula and Nebula.PlayerInfo and Nebula.PlayerInfo.metadataVersion then
        local ok, v = pcall(Nebula.PlayerInfo.metadataVersion)
        if ok and v then metaVersion = tostring(v) end
    end
    addModule(container, "nebula_metadata", t("nebula_metadata.title"),
        t("nebula_metadata.desc"), "ro", metaVersion, nil)

    -- Save channel probe: one cheap Bool read proves PlayerInfo works.
    local saveProbe = "not loaded"
    if Nebula and Nebula.PlayerInfo then
        local ok, v = pcall(Nebula.PlayerInfo.get, "showHiddenVehicles")
        if not ok then
            saveProbe = "read failed"
        elseif v == nil then
            saveProbe = "unresolved"
        else
            saveProbe = "ok (Bool read: " .. tostring(v) .. ")"
        end
    end
    addModule(container, "nebula_save_probe", t("nebula_save_probe.title"),
        t("nebula_save_probe.desc"), "ro", saveProbe, nil)

    -- GameData channel probe: one Float read resolves the GameData base.
    local gdProbe = "not loaded"
    if Nebula and Nebula.GameData then
        local ok, v, err = pcall(Nebula.GameData.get, "startCountdown")
        if not ok or err then
            gdProbe = "read failed (" .. tostring(err or v) .. ")"
        elseif v == nil then
            gdProbe = "unresolved"
        else
            gdProbe = "ok (startCountdown: " .. tostring(v) .. "s)"
        end
    end
    addModule(container, "nebula_gamedata_probe", t("nebula_gamedata_probe.title"),
        t("nebula_gamedata_probe.desc"), "ro", gdProbe, nil)

    -- ── Game Process ──────────────────────────────────────────────────────────
    addModuleSep(container, t("section_process"))

    local info = gg.getTargetInfo() or {}

    addModule(container, "process_package", t("process_package.title"),
        t("process_package.desc"), "ro", tostring(info.packageName or "unknown"), nil)
    addModule(container, "process_version", t("process_version.title"),
        t("process_version.desc"), "ro", tostring(info.versionName or "unknown"), nil)
    addModule(container, "process_version_code", t("process_version_code.title"),
        t("process_version_code.desc"), "ro", tostring(info.versionCode or "unknown"), nil)
    addModule(container, "process_name", t("process_name.title"),
        t("process_name.desc"), "ro", tostring(info.processName or "unknown"), nil)
    addModule(container, "process_arch", t("process_arch.title"),
        t("process_arch.desc"), "ro",
        info.x64 and "64-bit" or "32-bit", nil)

    -- ── Memory ────────────────────────────────────────────────────────────────
    addModuleSep(container, t("section_memory"))

    local function regionName()
        if BaseRegion == -2080896 then return T("settings.region.other")
        elseif BaseRegion == 4 then return T("settings.region.cpp_alloc")
        else return T("settings.region.unknown") end
    end

    addModule(container, "memory_range", T("settings.memory_range.title"),
        T("settings.memory_range.desc"), "ro", regionName(), nil)
    addModule(container, "gamestatus_address", T("settings.gamestatus.title"),
        T("settings.gamestatus.desc"), "ro", string.format("0x%X", BaseGameStatus or 0), nil)

    addModule(container, "clear_memory", T("settings.clear_memory.title"),
        T("settings.clear_memory.desc"), "button", nil, function(done)
        LOG.info("Status", "User triggered clear_all()")
        storage:clear_all_session()
        showToast(t("clear_memory.done"), true)
        done()
    end)
end
