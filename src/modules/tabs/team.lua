--[[
  Team Tab - Team mode features
  Status: TODO - Not yet implemented

  @module callback Receives container View to populate with modules
]]

return function(container)
    local function t(key, ...) return T("team." .. key, ...) end

    -- Feature isn't built yet — show an explicit placeholder instead of a
    -- silent blank content area (which looked like a broken/dead tab).
    addModule(container, "team_coming_soon", t("coming_soon.title"),
        t("coming_soon.desc"), "ro", t("coming_soon.status"), nil)
end
