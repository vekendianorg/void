return function(container)
    local function t(key, ...) return T("about." .. key, ...) end

    addModule(container, "about_script", t("about_script.title"), t("about_script.desc"), "ro", " ", nil)
    addModule(container, "script_owner", t("script_owner.title"), t("script_owner.desc"), "ro", " ", nil)
    addModule(container, "script_dev", t("script_dev.title"), t("script_dev.desc"), "ro", " ", nil)
    addModule(container, "script_translator", t("script_translator.title"), t("script_translator.desc"), "ro", " ", nil)
    addModule(container, "credits", t("credits.title"), t("credits.desc"), "ro", " ", nil)
    addModule(container, "special_thanks", t("special_thanks.title"), t("special_thanks.desc"), "ro", " ", nil)
    
end
