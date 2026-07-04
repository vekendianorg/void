return function(container)
    local function t(key, ...) return T("about." .. key, ...) end

    -- Plain info cards (mode = nil): no action widget. These are read-only
    -- credits/info text meant to be read, not a value anyone needs to
    -- toggle/copy/configure — the old "ro" copy-chip duplicated the same
    -- text right next to itself and looked broken/goofy, so it's gone.
    addModule(container, "about_script", t("about_script.title"), t("about_script.desc"), nil, nil, nil)
    addModule(container, "script_owner", t("script_owner.title"), t("script_owner.desc"), nil, nil, nil)
    addModule(container, "script_dev", t("script_dev.title"), t("script_dev.desc"), nil, nil, nil)
    addModule(container, "script_translator", t("script_translator.title"), t("script_translator.desc"), nil, nil, nil)
    addModule(container, "credits", t("credits.title"), t("credits.desc"), nil, nil, nil)
    addModule(container, "special_thanks", t("special_thanks.title"), t("special_thanks.desc"), nil, nil, nil)

end
