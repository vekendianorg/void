--[[
  configs/lang/hi.lua — हिन्दी (Hindi)

  Flat table of dotted keys -> strings, loaded by core/utils/lang.lua.
  Looked up at runtime via the global T(key, ...) function, e.g.:
      T("common.ok")                          -> "ठीक है"
      T("settings.window_width_desc", 400, 650) -> "फ्लोटिंग मेनू की चौड़ाई (400 - 650 dp)"

  Conventions:
    - Keys are namespaced by file: "settings.*", "account.*", "cups.*", etc.
    - %s / %d / %X etc. are string.format placeholders — keep them in the
      same order when translating, but they don't need to keep the same
      letter (e.g. %s can become %d if the translated grammar needs it).
    - Entries that are Lua arrays (e.g. spinner option lists) are returned
      as-is, untouched by string.format.
    - LOG.*() calls, debug tags, and internal cache/state keys are NOT
      translated — only user-visible text (dialogs, toasts, buttons,
      module titles/descriptions) lives here.

  This file handles the Hindi localization for the VOID script.
]]

return {

-- ── Common / shared (buttons, generic dialog text) ───────────────────────────
["common.ok"] = "ठीक है",
["common.cancel"] = "रद्द करें",
["common.yes"] = "हाँ",
["common.no"] = "नहीं",
["common.failed"] = "विफल",
["common.success"] = "सफल",
["common.later"] = "बाद में",
["common.got_it"] = "समझ गया",
["common.retry"] = "पुनः प्रयास करें",
["common.wait_safe"] = "प्रतीक्षा करें (सुरक्षित)",
["common.waiting"] = "प्रतीक्षा...",
["common.force_exit"] = "जबरदस्ती बाहर निकलें",
["common.proceed_anyway"] = "फिर भी आगे बढ़ें",
["common.manual_mode"] = "मैन्युअल मोड",
["common.update_button"] = "अपडेट करें",
["common.launch_failed"] = "लॉन्च विफल",
["common.confirm_exit_title"] = "बाहर निकलने की पुष्टि करें",
["common.confirm_exit_msg"] = "स्क्रिप्ट से बाहर निकलें?",
["common.not_available"] = "उपलब्ध नहीं",
["common.warning"] = "चेतावनी",

-- ── main.lua (boot, updater, virtual-space detection, main loop) ─────────────
["main.exit_active_ops_title"] = "चेतावनी: सक्रिय ऑपरेशन",
["main.exit_active_ops_msg"] = "%d बैकग्राउंड कार्य चल रहे हैं।\nजबरदस्ती बाहर निकलने से गेम की स्थिति खराब हो सकती है।",
["main.initializing"] = "आरंभ हो रहा है...",
["main.no_app_found"] = "कोई ऐप नहीं मिला",
["main.arch_64bit_required_title"] = "64-बिट आवश्यक",
["main.arch_64bit_required_msg"] = "ARMv8a अनिवार्य है। x86_64 आंशिक रूप से समर्थित है।",

["main.update_available_title"] = "अपडेट उपलब्ध",
["main.update_available_msg"] = "v%s उपलब्ध है (वर्तमान: v%s)\n\n%s\n\nअभी अपडेट करें?",
["main.no_changelog"] = "कोई परिवर्तन लॉग नहीं।",
["main.downloading_version"] = "v%s डाउनलोड हो रहा है...",
["main.update_download_failed_msg"] = "अपडेट डाउनलोड नहीं हो सका:\n%s",
["main.update_write_failed_msg"] = "इसमें लिखा नहीं जा सका:\n%s",
["main.update_done_title"] = "VOID v%s में अपडेट हुआ",
["main.update_done_msg"] = "VOID सफलतापूर्वक अपडेट हो गया।\n\nनई स्क्रिप्ट इस रूप में सहेजी गई है:\nvoid_v%s.lua\n\nअपडेट लागू करने के लिए इसे GameGuardian से चलाएं।",
["main.launching_version"] = "v%s लॉन्च हो रहा है...",
["main.launch_failed_msg"] = "डाउनलोड हो गया लेकिन चल नहीं सका:\n%s",

["main.multiple_spaces_title"] = "एकाधिक स्पेस मिले",
["main.multiple_spaces_desc"] = "HCR2 %d वर्चुअल स्पेस में मिला।\nउस स्पेस का चयन करें जिसमें आप अभी खेल रहे हैं।",
["main.select_space_toast"] = "जारी रखने के लिए एक स्पेस चुनें।",
["main.user_space_item"] = "उपयोगकर्ता %s  —  %s",
["main.permission_error_title"] = "अनुमति त्रुटि",
["main.permission_error_msg"] = "शेल एक्सेस अस्वीकार कर दिया गया।\n\nVoid को आपके वर्चुअल स्पेस में HCR2 ढूंढने के लिए इसकी आवश्यकता है। यदि आप यह सत्यापित करना चाहते हैं कि कौन सा कमांड चल रहा है तो Void सोर्स कोड देखें।",
["main.hcr2_not_found_title"] = "HCR2 डेटा नहीं मिला",
["main.hcr2_not_found_msg"] = "Void आपके वर्चुअल स्पेस में HCR2 डेटा ढूंढ नहीं सका। यह तब हो सकता है यदि HCR2 अभी तक लॉन्च नहीं हुआ है, या आपका वर्चुअल स्पेस ऐप असामान्य पथ संरचना का उपयोग करता है।\n\nगेम फ़ाइलों पर निर्भर सुविधाएँ (इवेंट रिवॉर्ड्स, आदि) मान्य पथ के बिना काम नहीं करेंगी।",
["main.manual_data_path_title"] = "मैन्युअल डेटा पथ",
["main.manual_data_path_hint"] = "HCR2 डेटा पथ दर्ज करें",
["main.manual_path_cancelled"] = "रद्द किया गया — पथ के बिना आगे बढ़ रहा है।",
["main.waiting_for_lib"] = "%s की प्रतीक्षा...",
["main.initialized"] = "आरंभ हुआ",
["main.gamestatus_not_found"] = "GameStatus नहीं मिला",
["main.dont_interrupt"] = "इस स्क्रिप्ट को बाधित न करें",

-- ── ui/ui.lua (framework chrome: menu, cards, dialogs) ────────────────────────
["ui.size_saved_restart"] = "आकार सहेजा गया! स्क्रिप्ट पुनः आरंभ करें",
["ui.category_error"] = "त्रुटि: %s",
["ui.category_not_found"] = "श्रेणी नहीं मिली",
["ui.na"] = "लागू नहीं",
["ui.spinner_select"] = "चुनें",
["ui.slider_default_title"] = "मान",
["ui.loading"] = "लोड हो रहा है",

-- ── core/engines/patches.lua (addArchModule patch engine) ────────────────────
["patches.requires_arch"] = "%s डिवाइस की आवश्यकता है (आपका डिवाइस: %s)",
["patches.suffix_enabled"] = " सक्षम",
["patches.suffix_disabled"] = " अक्षम",
["patches.pattern_not_found"] = "विफल: %d पैटर्न नहीं मिले",

-- ── core/engines/arch.lua (architecture detection warnings) ──────────────────
["arch.warning_title"] = "आर्किटेक्चर चेतावनी",
["arch.unknown_arch_msg"] = "आपका आर्किटेक्चर अज्ञात है। क्या लाइब्रेरी लोड हुई? आप कौन सा सिस्टम उपयोग कर रहे हैं?",
["arch.non_primary_arch_msg"] = "पाया गया: %s\nकुछ या सभी लिब-पैच काम नहीं कर सकते।",
["arch.unknown_version_msg"] = "गेम का संस्करण अज्ञात है। गेम लोड होने के बाद पुनः प्रयास करें।",
["arch.no_base_data_msg"] = "आंतरिक त्रुटि: इस आर्किटेक्चर के लिए कोई आधार डेटा उपलब्ध नहीं है।",

-- ── core/engines/scheduler.lua ────────────────────────────────────────────────
["scheduler.task_crashed"] = "शेड्यूलर चेतावनी: कार्य क्रैश हुआ -> %s",

-- ── core/utils/paste.lua + catbox.lua (network error strings) ────────────────
["errors.http_error_code"] = "HTTP त्रुटि कोड: %s",
["errors.crashed"] = "क्रैश हुआ: %s",
["errors.url_missing"] = "URL पैरामीटर अनुपस्थित या खाली है",
["errors.file_path_missing"] = "फ़ाइल पथ अनुपस्थित है",
["errors.download_url_missing"] = "URL अनुपस्थित है",
["errors.dest_path_missing"] = "गंतव्य पथ अनुपस्थित है",

-- ── modules/registry.lua (sidebar tab labels + module-load error cards) ──────
["tabs.sep_game"] = "गेम मेनू",
["tabs.account"] = "खाता मेनू",
["tabs.vehicle"] = "वाहन मेनू",
["tabs.player"] = "खिलाड़ी मेनू",
["tabs.adventure"] = "साहसिक मेनू",
["tabs.cups"] = "कप मेनू",
["tabs.team"] = "टीम मेनू",
["tabs.event"] = "इवेंट मेनू",
["tabs.creative"] = "क्रिएटिव मेनू",
["tabs.shop"] = "दुकान मेनू",
["tabs.other"] = "अन्य मेनू",
["tabs.sep_script"] = "स्क्रिप्ट मेनू",
["tabs.settings"] = "सेटिंग्स",
["tabs.about"] = "परिचय",

["registry.module_load_failed"] = "मॉड्यूल लोड नहीं हुआ। विवरण के लिए लॉग देखें।",
["registry.module_runtime_error"] = "रनटाइम त्रुटि: %s",
["registry.error"] = "त्रुटि",

-- ── modules/tabs/settings.lua ─────────────────────────────────────────────────
["settings.section_updates"] = "अपडेट",
["settings.auto_update.title"] = "स्वचालित अपडेट",
["settings.auto_update.desc"] = "स्टार्टअप पर VOID स्वचालित रूप से अपडेट करें",
["settings.dev_mode_title"] = "डेव मोड",
["settings.auto_update.dev_mode_msg"] = "main.lua के लिए स्वचालित अपडेट अक्षम है (डेव बिल्ड)।",
["settings.check_updates.title"] = "अपडेट जाँचें",
["settings.check_updates.desc"] = "GitHub पर नवीनतम VOID रिलीज़ देखें",
["settings.check_updates.dev_mode_msg"] = "main.lua के लिए अपडेट जाँच अक्षम है (डेव बिल्ड)।\n\nमैन्युअल रूप से रिपो से पुल करें।",
["settings.check_updates.checking"] = "अपडेट की जाँच हो रही है...",
["settings.check_updates.failed_title"] = "अपडेट जाँच विफल",
["settings.check_updates.failed_msg"] = "GitHub तक पहुँच नहीं सका:\n%s",
["settings.check_updates.up_to_date_title"] = "अद्यतित",
["settings.check_updates.up_to_date_msg"] = "आप पहले से ही नवीनतम संस्करण पर हैं (v%s)।",
["settings.check_updates.no_changelog"] = "कोई परिवर्तन लॉग उपलब्ध नहीं।",
["settings.check_updates.available_msg"] = "v%s  (वर्तमान: v%s)\n\n%s\n\nइस स्क्रिप्ट को डाउनलोड और बदलें?",
["settings.check_updates.no_asset_msg"] = "रिलीज़ में कोई .lua एसेट नहीं मिला।",
["settings.check_updates.download_failed_title"] = "डाउनलोड विफल",
["settings.check_updates.write_failed_title"] = "लेखन विफल",
["settings.check_updates.done_title"] = "संपन्न",
["settings.check_updates.done_msg"] = "v%s में अपडेट हुआ। लागू करने के लिए स्क्रिप्ट पुनः आरंभ करें।",
["settings.check_updates.restart_button"] = "पुनः आरंभ करें",

["settings.section_language"] = "भाषा",
["settings.language.title"] = "भाषा",
["settings.language.desc"] = "मेनू के लिए अपनी पसंदीदा भाषा चुनें",
["settings.language.changed"] = "भाषा %s पर सेट की गई",
["settings.language.failed"] = "वह भाषा लोड नहीं हुई",
["settings.language.restart_msg"] = "भाषा पूरी तरह से लागू करने के लिए स्क्रिप्ट पुनः आरंभ करें",

["settings.region.other"] = "अ: अन्य",
["settings.region.cpp_alloc"] = "Ca: C++ आवंटन",
["settings.region.unknown"] = "अज: अज्ञात",
["settings.section_memory"] = "मेमोरी",
["settings.memory_range.title"] = "मेमोरी रेंज",
["settings.memory_range.desc"] = "वर्तमान चयनित मेमोरी रेंज\n(स्क्रिप्ट द्वारा स्वचालित रूप से चुनी गई)",
["settings.gamestatus.title"] = "GameStatus",
["settings.gamestatus.desc"] = "वर्तमान gamestatus पता\n(स्क्रिप्ट द्वारा स्वचालित रूप से चुना गया)",
["settings.gamestatus_raw.title"] = "GameStatus (कच्चा)",
["settings.gamestatus_raw.desc"] = "वर्तमान gamestatus (कच्चा) पता\n(स्क्रिप्ट द्वारा स्वचालित रूप से चुना गया)",
["settings.clear_memory.title"] = "सहेजी गई मेमोरी साफ़ करें",
["settings.clear_memory.desc"] = "पूरा गेम पुनः आरंभ किए बिना VOID की सभी सहेजी गई मेमोरी साफ़ करें।",

["settings.section_ui_customizations"] = "UI अनुकूलन",
["settings.theme_store.title"] = "थीम स्टोर",
["settings.theme_store.desc"] = "समुदाय Void थीम ब्राउज़ और इंस्टॉल करें",
["settings.theme_store.unreachable_msg"] = "थीम स्टोर तक नहीं पहुँच सका:\n%s",
["settings.theme_store.parse_failed_msg"] = "थीम स्टोर डेटा पार्स नहीं हो सका।",
["settings.theme_store.list_title"] = "Void थीम स्टोर",
["settings.theme_store.search_results_desc"] = "खोज परिणाम: %s मिले",
["settings.theme_store.available_desc"] = "%s थीम उपलब्ध",
["settings.theme_store.by_author"] = "%s द्वारा",
["settings.theme_store.search_item"] = "🔍 खोजें...",
["settings.theme_store.clear_search_item"] = "✕ खोज साफ़ करें",
["settings.theme_store.search_title"] = "थीम खोजें",
["settings.theme_store.search_hint"] = "थीम का नाम, लेखक या विवरण",
["settings.theme_store.no_results"] = "%s के लिए कोई थीम नहीं मिली",
["settings.theme_store.detail_msg"] = "%s द्वारा\n\n%s\n\nID: %s",
["settings.theme_store.install_button"] = "थीम इंस्टॉल करें",
["settings.theme_downloading_bg"] = "पृष्ठभूमि छवि डाउनलोड हो रही है...",
["settings.theme_imported"] = "थीम आयात हुई!",
["settings.theme_invalid_bundle"] = "अमान्य बंडल प्रारूप।",
["settings.theme_cloud_error"] = "क्लाउड त्रुटि: %s",
["settings.reset_theme.title"] = "थीम रीसेट करें",
["settings.reset_theme.desc"] = "कस्टम थीम और पृष्ठभूमि छवि को डिफ़ॉल्ट पर रीसेट करें",
["settings.import_theme.title"] = "थीम आयात करें",
["settings.import_theme.desc"] = "क्लाउड से कस्टम थीम आयात करें",
["settings.import_theme.hint"] = "शेयर ID दर्ज करें",
["settings.export_theme.title"] = "थीम निर्यात करें",
["settings.export_theme.desc"] = "कस्टम थीम और पृष्ठभूमि छवि को क्लाउड पर निर्यात करें",
["settings.export_theme.share_id_msg"] = "शेयर ID: %s\n\nक्लिपबोर्ड पर कॉपी हुआ।",
["settings.export_theme.upload_failed_msg"] = "अपलोड विफल: %s",
["settings.export_theme.size_warning_title"] = "अपलोड आकार चेतावनी",
["settings.export_theme.size_warning_msg"] = "कस्टम पृष्ठभूमि छवि शामिल करें? यह आपकी छवि के आकार के अनुसार अपलोड आकार बढ़ाएगा।",
["settings.export_theme.uploading_bg"] = "Catbox पर पृष्ठभूमि छवि अपलोड हो रही है...",
["settings.export_theme.image_upload_failed_title"] = "त्रुटि",
["settings.export_theme.image_upload_failed_msg"] = "छवि अपलोड विफल: %s",
["settings.tabs_icon.title"] = "टैब आइकन",
["settings.tabs_icon.desc"] = "टैब आइकन बदलें",
["settings.tabs_icon.hint"] = "आइकन दर्ज करें",
["settings.tabs_icon.empty_error"] = "खाली नहीं हो सकता",

["settings.bg_opacity.title"] = "पृष्ठभूमि अपारदर्शिता",
["settings.bg_opacity.desc"] = "पैनल, कार्ड और हेडर की पारदर्शिता",
["settings.slider.alpha"] = "अल्फा",
["settings.bg_image_opacity.title"] = "पृष्ठभूमि छवि अपारदर्शिता",
["settings.bg_image_opacity.desc"] = "शुद्ध पूर्णांक चैनलों का उपयोग करके दृश्यता अल्फा सेटिंग्स सीधे समायोजित करें।",
["settings.bg_image_picker.title"] = "पृष्ठभूमि छवि",
["settings.bg_image_picker.desc"] = "अपनी कस्टम लेआउट पृष्ठभूमि छवि के लिए पूर्ण फ़ाइल पथ संशोधित करने के लिए टैप करें",
["settings.bg_image_picker.path_label"] = "पूर्ण छवि फ़ाइल पथ (.jpg या .png):",
["settings.bg_image_picker.remove_label"] = "पृष्ठभूमि छवि हटाएँ",
["settings.bg_image_picker.success_title"] = "सफल",
["settings.bg_image_picker.removed_msg"] = "पृष्ठभूमि छवि हटा दी गई",
["settings.bg_image_picker.added_msg"] = "पृष्ठभूमि छवि जोड़ी गई",
["settings.bg_image_picker.not_found_msg"] = "फ़ाइल नहीं मिली या पढ़ने का कार्य अस्वीकृत:\n%s",

["settings.bg_rgb.title"] = "पृष्ठभूमि RGB",
["settings.bg_rgb.desc"] = "पैनल पृष्ठभूमि के लिए रंग (हेडर और कार्ड स्वचालित रूप से स्केल होते हैं)",
["settings.slider.r"] = "R",
["settings.slider.g"] = "G",
["settings.slider.b"] = "B",
["settings.accent_rgb.title"] = "एक्सेंट RGB",
["settings.accent_rgb.desc"] = "बटन, टॉगल और सक्रिय कार्ड के लिए रंग (म्यूट रंग स्वचालित रूप से व्युत्पन्न)",
["settings.logo_rgb.title"] = "हाइलाइट RGB",
["settings.logo_rgb.desc"] = "लेबल, आइकन और इंटरैक्टिव टेक्स्ट के लिए रंग (हमेशा पूरी तरह से अपारदर्शी)",
["settings.sub_rgb.title"] = "उप-पाठ RGB",
["settings.sub_rgb.desc"] = "विवरण और निष्क्रिय टैब लेबल के लिए रंग",
["settings.text_rgb.title"] = "पाठ RGB",
["settings.text_rgb.desc"] = "मुख्य मेनू पाठ के लिए रंग",

["settings.win_width.title"] = "मेनू चौड़ाई",
["settings.win_width.desc"] = "फ्लोटिंग मेनू की चौड़ाई (%d – %d dp)",
["settings.slider.width"] = "चौड़ाई",
["settings.win_height.title"] = "मेनू ऊँचाई",
["settings.win_height.desc"] = "स्क्रॉल करने योग्य सामग्री क्षेत्र की ऊँचाई (%d – %d dp)",
["settings.slider.height"] = "ऊँचाई",

-- ── modules/tabs/about.lua ────────────────────────────────────────────────────
["about.about_script.title"] = "स्क्रिप्ट के बारे में",
["about.about_script.desc"] = "Hill Climb Racing 2 के लिए कस्टम Pivot वातावरण पर निर्मित एक शक्तिशाली और अत्यधिक अनुकूलित मेमोरी हेरफेर स्क्रिप्ट।\n\nPivot डाउनलोड करें:\nhttps://github.com/vekendianorg/pivot/releases/",
["about.script_owner.title"] = "स्क्रिप्ट स्वामी",
["about.script_owner.desc"] = "- Vekendian Organization (github: vekendianorg)",
["about.script_dev.title"] = "स्क्रिप्ट डेवलपर",
["about.script_dev.desc"] = [[
- Lazor (github: lazor-git)
- AMR (github: amr-gt)
- Erik (github: eomthix)
]],
["about.script_translator.title"] = "स्क्रिप्ट अनुवादक",
["about.script_translator.desc"] = [[
- English: Lazor (github: lazor-git)
- Bahasa Indonesia: Lazor (github: lazor-git)
- Español: Jayy2k (github: Jayy2k)
- Deutsch: Erik (github: eomthix)
- Русский: Winter Lotus(github: Ohranik1Pitorochki; discord:nikolaypg67)
- Thai: NaiArt777 (github: artphakkapol-hub)
- বাংলা: AMR (github: amr-gt)
- العربية: AMR (github: amr-gt)
- اردو: AMR (github: amr-gt)
- Français: AMR (github: amr-gt)
- Українська: AMR (github: amr-gt)
- Türkçe: AMR (github: amr-gt)
- Português (Brasil): AMR (github: amr-gt)
- हिन्दी: AMR (github: amr-gt)
- Italiano: AMR (github: amr-gt)
]],
["about.credits.title"] = "क्रेडिट",
["about.credits.desc"] = [[
- Lazor (github: lazor-git)
- Lan9118 (discord: lan9118)
- AMR (github: amr-gt)
- Erik (github: eomthix)
- Sr Romero
- Profinoobru
]],
["about.special_thanks.title"] = "विशेष धन्यवाद",
["about.special_thanks.desc"] = [[
- Aryan/KokushiboModz
]],

-- ── modules/tabs/other.lua ────────────────────────────────────────────────────
["other.debug_mode.title"] = "डीबग मोड",
["other.debug_mode.desc"] = "इन-गेम डीबग मोड टॉगल करें",
["other.debug_mode.enabled"] = "डीबग मोड सक्षम",
["other.debug_mode.disabled"] = "डीबग मोड अक्षम",
["other.hint.width"] = "चौड़ाई",
["other.hint.height"] = "ऊँचाई",
["other.resolution.title"] = "रेज़ोल्यूशन समायोजित करें",
["other.resolution.desc"] = "गेम की चौड़ाई और ऊँचाई समायोजित करें (डिफ़ॉल्ट 1280x720 है)",
["other.resolution.applied"] = "रेज़ोल्यूशन %dx%d पर सेट हुआ",
["other.resolution_offset.title"] = "रेज़ोल्यूशन ऑफ़सेट समायोजित करें",
["other.resolution_offset.desc"] = "गेम की चौड़ाई ऑफ़सेट और ऊँचाई ऑफ़सेट समायोजित करें (डिफ़ॉल्ट 0x0 है), बड़ी स्क्रीन पर छोटे रेज़ोल्यूशन के लिए सर्वोत्तम।",
["other.resolution_offset.applied"] = "रेज़ोल्यूशन ऑफ़सेट %dx%d पर सेट हुआ",
["other.glsurface_not_found"] = "GLSurfaceView नहीं मिला",

-- ── modules/tabs/shop.lua ─────────────────────────────────────────────────────
["shop.free_chest.title"] = "मुफ्त चेस्ट",
["shop.free_chest.desc"] = "दुकान टैब में चेस्ट मुफ्त करें",
["shop.free_chest.enabled"] = "मुफ्त चेस्ट सक्षम",
["shop.free_chest.disabled"] = "मुफ्त चेस्ट अक्षम",
["shop.free_purchases.title"] = "मुफ्त खरीदारी",
["shop.free_purchases.desc"] = "दुकान टैब में कुछ दैनिक ऑफ़र मुफ्त करें (पॉपअप/बैज के रूप में विशेष ऑफ़र के लिए भी काम करता है)",
["shop.free_purchases.progress"] = "%d/%d",
["shop.free_purchases.success"] = "मुफ्त खरीदारी सफल",
["shop.change_chest.title"] = "चेस्ट बदलें",
["shop.change_chest.desc"] = "लीजेंडरी चेस्ट को चयनित चेस्ट में बदलें",
["shop.change_chest.changed"] = "चेस्ट %s में बदला गया",
["shop.change_chest.options"] = {
    "सामान्य चेस्ट", "असामान्य चेस्ट", "दुर्लभ चेस्ट", "महाकाव्य चेस्ट",
    "चैंपियन चेस्ट", "विशेष चेस्ट 1", "क्रिसमस चेस्ट", "लीजेंडरी चेस्ट",
    "नीला चेस्ट", "VIP चेस्ट 1", "VIP चेस्ट 2", "वीडियो चेस्ट",
    "स्टार्टर चेस्ट", "विशेष चेस्ट 2", "Fingersoft चेस्ट", "मेगा चेस्ट",
    "टीम स्पिरिट चेस्ट", "स्टाइल चेस्ट", "पौराणिक चेस्ट"
},

-- ── modules/tabs/player.lua ───────────────────────────────────────────────────
["player.auto_detach.title"] = "स्वचालित अलगाव",
["player.auto_detach.desc"] = "रैली कार की छत जैसे भागों को स्वचालित रूप से अलग करें",
["player.auto_die.title"] = "स्वचालित मृत्यु",
["player.auto_die.desc"] = "स्वचालित रूप से मृत्यु का कारण बनें (ईंधन समाप्त)",
["player.no_clip.title"] = "नो-क्लिप",
["player.no_clip.desc"] = "अपने खिलाड़ी को बिना मरे वस्तुओं के माध्यम से जाने दें (आप कप में फिनिश लाइनों के ऊपर जा सकते हैं)",
["player.no_clip.enabled"] = "नो-क्लिप सक्षम",
["player.no_clip.disabled"] = "नो-क्लिप अक्षम",
["player.hide_name.title"] = "नाम छुपाएं",
["player.hide_name.desc"] = "दौड़ में अपना खिलाड़ी नाम छुपाएं",
["player.hide_name.enabled"] = "नाम छुपाना सक्षम",
["player.hide_name.disabled"] = "नाम छुपाना अक्षम",
["player.hide_flag.title"] = "ध्वज छुपाएं",
["player.hide_flag.desc"] = "दौड़ में अपना खिलाड़ी ध्वज छुपाएं",
["player.hide_flag.enabled"] = "ध्वज छुपाना सक्षम",
["player.hide_flag.disabled"] = "ध्वज छुपाना अक्षम",
["vehicle.fuel.title"] = "ईंधन",
["vehicle.fuel.desc"] = "दौड़ के दौरान ईंधन को एक स्थिर मान पर लॉक करें (0.0 – 100.0)",
["vehicle.fuel.prompt_amount"] = "ईंधन की मात्रा (0 – 100)",
["vehicle.fuel.prompt_reset"] = "रीसेट",
["vehicle.fuel.invalid"] = "अमान्य मान, 0 – 100 होना चाहिए",
["vehicle.fuel.applied"] = "ईंधन %s पर लॉक हुआ",
["vehicle.fuel.reset"] = "ईंधन बहाल हुआ",
["vehicle.fuel.not_applied"] = "ईंधन सक्रिय नहीं",
["player.zoom.title"] = "ज़ूम समायोजित करें",
["player.zoom.desc"] = "आपका कैमरा कितना निकट या दूर है समायोजित करें",
["player.slider.min"] = "न्यूनतम",
["player.slider.max"] = "अधिकतम",
["player.gravity.title"] = "गुरुत्वाकर्षण समायोजित करें",
["player.gravity.desc"] = "गुरुत्वाकर्षण कितना मजबूत है समायोजित करें",
["player.slider.x"] = "X",
["player.slider.y"] = "Y",

-- ── modules/tabs/adventure.lua ────────────────────────────────────────────────
["adventure.auto_adventure_chests.title"] = "स्वचालित साहसिक चेस्ट (अस्थिर)",
["adventure.auto_adventure_chests.desc"] = "अपने साहसिक चेस्ट को स्वचालित रूप से स्तर ऊपर करें",
["adventure.auto_adventure_chests.none_found"] = "कोई साहसिक चेस्ट नहीं मिला",
["adventure.auto_adventure_chests.done"] = "संपन्न",

["adventure.set_distance.title"] = "दूरी सेट करें",
["adventure.set_distance.desc"] = "आपकी साहसिक दौड़ की दूरी को एक कस्टम मान पर सेट करता है। सक्रिय दौड़ में होना चाहिए। अधिक दूरी अधिक सितारे प्राप्त कर सकती है। 5000m पर अधिकतम सितारे। (टेलीपोर्ट फ़ंक्शन नहीं)",
["adventure.set_distance.loop_active_title"] = "दूरी सेट करें — लूप सक्रिय",
["adventure.set_distance.loop_active_msg"] = "दूरी लूप वर्तमान में चल रहा है।\nआप क्या करना चाहते हैं?",
["adventure.set_distance.stop_loop"] = "लूप रोकें",
["adventure.set_distance.keep_running"] = "चलते रहें",
["adventure.set_distance.loop_will_stop"] = "वर्तमान टिक के बाद लूप बंद हो जाएगा।",
["adventure.set_distance.prompt_target"] = "लक्ष्य दूरी (मीटर)",
["adventure.set_distance.prompt_loop"] = "लूप (स्वचालित पुनः लागू)",
["adventure.set_distance.prompt_interval"] = "लूप अंतराल (ms, न्यूनतम 250)",
["adventure.set_distance.over_max_title"] = "दूरी चेतावनी",
["adventure.set_distance.over_max_msg"] = "5000m से अधिक दूरी आपको कोई सितारे नहीं देगी।\n\nदौड़ दूरी को पंजीकृत करेगी, लेकिन कोई सितारा पुरस्कार नहीं दिया जाएगा। जारी रखें?",
["adventure.set_distance.continue_button"] = "जारी रखें",
["adventure.set_distance.not_in_adventure"] = "पहले साहसिक टैब पर जाएं और एक दौड़ शुरू करें",
["adventure.set_distance.start_race_first"] = "पहले एक दौड़ शुरू करें",
["adventure.set_distance.applied"] = "दूरी सेट: %sm",
["adventure.set_distance.loop_stopped"] = "दूरी सेट करें लूप बंद हुआ।",
["adventure.set_distance.loop_running"] = "दूरी लूप चल रहा है — रोकने के लिए दूरी सेट करें टैप करें",
["adventure.set_distance.loop_warn_title"] = "दूरी लूप चेतावनी",
["adventure.set_distance.loop_warn_msg"] = "लूप मोड हर %s ms पर मेमोरी में लिखता है।\n\nकम अंतराल का उपयोग करने से अस्थिरता, दृश्य गड़बड़ी या गेम क्रैश हो सकता है।\n\nफिर भी जारी रखें?",

-- ── modules/tabs/cups.lua ─────────────────────────────────────────────────────
["cups.adjust_countdown.title"] = "काउंटडाउन समायोजित करें",
["cups.adjust_countdown.desc"] = "दौड़ शुरू करने से पहले काउंटडाउन समायोजित करें",
["cups.slider.seconds"] = "सेकंड",
["cups.adjust_countdown.applied"] = "काउंटडाउन %ss पर समायोजित हुआ",
["cups.auto_win.title"] = "स्वचालित जीत",
["cups.auto_win.desc"] = "आपकी दौड़ का परिणाम चाहे जो भी हो स्वचालित रूप से जीतें",
["cups.force_boss.title"] = "बॉस को बाध्य करें",
["cups.force_boss.desc"] = "बॉस हमेशा दिखाई दे",
["cups.force_cup.title"] = "कप को बाध्य करें",
["cups.force_cup.desc"] = "एक एकल कप को बाध्य करता है",
["cups.force_cup.not_found"] = "कप बाध्य नहीं मिला। बाद में पुनः प्रयास करें।",
["cups.force_cup.enabled"] = "कप बाध्य सक्षम",
["cups.force_cup.disabled"] = "कप बाध्य अक्षम",
["cups.set_time.title"] = "समय सेट करें",
["cups.set_time.desc"] = "अपना दौड़ का समय सेट करें (सुरक्षा कारणों से समय फ्रीज नहीं होगा)। सक्रिय कप दौड़ में होना चाहिए। (उदा: 1:09.069, 7.284)",
["cups.set_time.hint"] = "समय (1:09.069 या 7.284)",
["cups.set_time.invalid_format"] = "अमान्य प्रारूप। 1:09.069 या 7.284 का उपयोग करें",
["cups.set_time.no_negative"] = "कोई नकारात्मक मान नहीं",
["cups.set_time.not_in_cup"] = "पहले कप टैब पर जाएं और एक दौड़ शुरू करें",
["cups.set_time.start_race_first"] = "पहले एक दौड़ शुरू करें",
["cups.set_time.applied"] = "समय %s पर सेट हुआ",
["cups.unlimited_tasks.title"] = "असीमित कार्य",
["cups.unlimited_tasks.desc"] = "सभी कार्यों को पूर्ण और हमेशा दावा करने योग्य के रूप में फ्रीज करें। बार-बार पुरस्कार दावा करें।",
["cups.unlimited_tasks.resolve_failed"] = "कार्य सूची हल करने में विफल",
["cups.unlimited_tasks.none_found"] = "कोई कार्य नहीं मिला",
["cups.unlimited_tasks.enabled"] = "असीमित कार्य सक्षम",
["cups.unlimited_tasks.disabled"] = "असीमित कार्य अक्षम",
["cups.unlimited_tasks.none_to_freeze"] = "फ्रीज करने के लिए कोई कार्य नहीं",
["cups.rank_points_bonus.title"] = "+498 रैंक अंक",
["cups.rank_points_bonus.desc"] = "सभी लीग कार्यों को 200 अंकों के बजाय 498 अंक दें, अन्य पुरस्कार हटाएँ।",
["cups.rank_points_bonus.none_found"] = "कोई लीग कार्य नहीं मिला",
["cups.rank_points_bonus.boosted"] = "रैंक अंक बढ़ाए गए: %s",
["cups.rank_points_bonus.no_match"] = "कोई मिलान लीग कार्य नहीं मिला",
["cups.rank_points_bonus.nothing_to_restore"] = "बहाल करने के लिए कुछ नहीं",
["cups.rank_points_bonus.restored"] = "बहाल: %s",

-- ── modules/tabs/event.lua ────────────────────────────────────────────────────
["event.patch_rewards.title"] = "इवेंट रिवॉर्ड्स पैच",
["event.patch_rewards.desc"] = "वर्तमान सार्वजनिक इवेंट रिवॉर्ड्स को VOID द्वारा प्रदान किए गए कस्टम रिवॉर्ड्स पर पैच करें (गेम पुनः आरंभ आवश्यक)",
["event.restore_events.title"] = "इवेंट रिवॉर्ड्स बहाल करें",
["event.restore_events.desc"] = "गेम सर्वर पुनर्प्राप्ति के लिए संशोधित इवेंट JSON हटाएँ (गेम पुनः आरंभ आवश्यक)",

["event.checking_permissions"] = "पर्यावरण अनुमतियों की जाँच हो रही है...",
["event.scanning_files"] = "सक्रिय फ़ाइलें स्कैन हो रही हैं...",
["event.decode_rewards_failed"] = "रिवॉर्ड्स JSON डिकोड नहीं हुआ",
["event.workspace_creation_failed"] = "गंभीर: कार्यक्षेत्र निर्माण विफल: %s",
["event.workspace_creation_failed_dialog"] = "गंभीर: कार्यक्षेत्र निर्देशिका नहीं बन सकी।\n%s",
["event.file_inaccessible"] = "फ़ाइल इस पथ पर पहुँच योग्य नहीं: %s",
["event.predecrypt_not_found"] = "पूर्व-डिक्रिप्ट: स्रोत नहीं मिला: %s",
["event.predecrypt_empty"] = "पूर्व-डिक्रिप्ट: स्रोत खाली है (0 बाइट्स): %s",
["event.decode_active_failed"] = "इस पथ पर active_events.json डिकोड नहीं हुआ: %s",
["event.no_active_events"] = "इस पथ पर कोई सक्रिय इवेंट नहीं मिला: %s",
["event.cannot_open_active"] = "इस पथ पर active_events.json नहीं खुल सका: %s",
["event.decrypt_active_failed"] = "इस पथ पर active_events.json डिक्रिप्ट नहीं हुआ: %s",
["event.root_copy_failed"] = "रूट कॉपी विफल: %s",

["event.select_events_patch"] = "पैच करने के लिए इवेंट चुनें:\nपथ: %s",
["event.user_cancelled"] = "उपयोगकर्ता ने इस पथ के लिए चयन रद्द किया: %s",
["event.rewards_unavailable"] = "एम्बेडेड रिवॉर्ड्स उपलब्ध नहीं, इस पथ के लिए पैच छोड़ रहा है: %s",
["event.skipped_unreadable"] = "अपठनीय इवेंट छोड़ा गया: %s",
["event.predecrypt_event_not_found"] = "पूर्व-डिक्रिप्ट: इवेंट नहीं मिला: %s",
["event.predecrypt_event_empty"] = "पूर्व-डिक्रिप्ट: इवेंट खाली है (0 बाइट्स): %s",
["event.processing_failed"] = "%s संसाधित नहीं हुआ: %s",
["event.cannot_open_decrypted"] = "डिक्रिप्टेड फ़ाइल नहीं खुल सकी: %s",
["event.decrypt_event_failed"] = "इवेंट डिक्रिप्ट नहीं हुआ: %s",
["event.loop_crash"] = "महत्वपूर्ण फ़ाइल प्रसंस्करण लूप क्रैश: %s",

["event.success_header"] = "सफलतापूर्वक:",
["event.success_removed_header"] = "सफलतापूर्वक हटाया गया (पुनः आरंभ पर बहाल होगा):",
["event.success_item"] = "- %s",
["event.success_item_json"] = "- %s.json",
["event.failed_header"] = "विफल:",
["event.failed_item"] = "- %s",

["event.patch_results_title"] = "पैच परिणाम",
["event.restore_results_title"] = "बहाली परिणाम",
["event.restart_required_title"] = "पुनः आरंभ आवश्यक",
["event.patch_restart_msg"] = "गेम बंद कर दिया गया है और यह स्क्रिप्ट बाहर निकलेगी, पैच प्रभाव देखने के लिए इसे फिर से शुरू करें",
["event.restore_restart_msg"] = "सर्वर फ़ाइल सिंक्रोनाइज़ेशन की अनुमति देने के लिए गेम अब बंद हो जाएगा।",
["event.finishing_tasks_patch"] = "लंबित बैकग्राउंड कार्य समाप्त हो रहे हैं... कृपया प्रतीक्षा करें।",
["event.finishing_tasks_restore"] = "लंबित बैकग्राउंड कार्य समाप्त हो रहे हैं...",
["event.patch_failed_msg"] = "पैच करने में विफल, पुनः प्रयास करें।",

["event.select_events_restore"] = "बहाल करने (हटाने) के लिए फ़ाइलें चुनें:\nपथ: %s",
["event.delete_failed"] = "%s हटाने में विफल: %s",

-- ── modules/tabs/account.lua ──────────────────────────────────────────────────
["account.change_name.title"] = "नाम बदलें",
["account.change_name.desc"] = "अपना खिलाड़ी नाम बदलें",
["account.change_name.hint"] = "नाम दर्ज करें",
["account.change_name.empty"] = "पहले एक नाम दर्ज करें",
["account.change_name.too_long_title"] = "नाम बहुत लंबा",
["account.change_name.too_long_msg"] = "आपका नाम बहुत लंबा है, कृपया इसे छोटा करें",
["account.change_name.resolve_failed"] = "नाम पॉइंटर हल करने में विफल",
["account.change_name.applied"] = "नाम %s में बदला गया",

["account.change_gp.title"] = "गैरेज पावर बदलें",
["account.change_gp.desc"] = "प्रोफ़ाइल गैरेज पावर बदलता है (यदि अधिक हो तो बनी रहती है)। यदि अधिकतम से अधिक हो तो रीसेट करने के लिए 8 सेट करें, लेकिन केवल तभी जब आपकी वास्तविक GP पहले से ही सीमा के नीचे तय हो।",
["account.change_gp.hint"] = "गैरेज पावर दर्ज करें",
["account.change_gp.max_int_title"] = "अधिकतम 32-बिट int तक पहुँच गया",
["account.change_gp.lower_value"] = "कृपया अपना मान कम करें",
["account.change_gp.too_low_title"] = "बहुत कम",
["account.change_gp.higher_value"] = "कृपया अपना मान बढ़ाएँ",
["account.change_gp.applied"] = "गैरेज पावर %s में बदली गई",

["account.fake_unlock.title"] = "नकली अनलॉक",
["account.fake_unlock.desc"] = "सभी अनुकूलन अस्थायी रूप से अनलॉक करें",
["account.fake_vip.title"] = "नकली VIP",
["account.fake_vip.desc"] = "VIP सदस्यता स्थिति को स्थानीय रूप से टॉगल करें",

["account.fake_rank.title"] = "नकली रैंक",
["account.fake_rank.desc"] = "अपनी रैंक को तुरंत नकली लीजेंडरी पर सेट करें",
["account.fake_rank.race_warn_title"] = "दौड़ आवश्यक",
["account.fake_rank.race_warn_msg"] = "नकली रैंक केवल तभी लागू की जानी चाहिए जब कोई कप दौड़ सक्रिय रूप से चल रही हो।\n\nइसे दौड़ के बाहर लागू करने पर शैडो बैन हो सकता है।\n\nजारी रखने से पहले सुनिश्चित करें कि आप पहले से ही कप दौड़ के अंदर हैं।\n\nफिर भी जारी रखें?",
["account.fake_rank.continue_button"] = "जारी रखें",
["account.fake_rank.applied"] = "नकली रैंक इंजेक्ट की गई",
["account.fake_rank.not_in_cups"] = "पहले एक दौड़ शुरू करें",

-- ── modules/tabs/vehicle.lua ──────────────────────────────────────────────────
["vehicle.parts_slot.title"] = "पार्ट्स स्लॉट समायोजित करें",
["vehicle.parts_slot.desc"] = "सभी वाहनों के लिए पार्ट्स स्लॉट समायोजित करें",
["vehicle.parts_slot.slider_title"] = "स्लॉट",
["vehicle.parts_slot.no_vehicles"] = "कोई वाहन नहीं मिला",
["vehicle.parts_slot.applied"] = "पार्ट्स स्लॉट समायोजित: %d वाहन",

["vehicle.parts_modifier.title"] = "पार्ट्स संशोधक",
["vehicle.parts_modifier.desc"] = "सक्रिय दौड़ में ट्यूनिंग पार्ट स्तर मान संशोधित करें",
["vehicle.parts_modifier.select"] = "एक पार्ट चुनें",
["vehicle.parts_modifier.prompt_level"] = "स्तर: ",
["vehicle.parts_modifier.prompt_digit0"] = "अंक: ",
["vehicle.parts_modifier.prompt_digit1"] = "पूंछ: ",
["vehicle.parts_modifier.prompt_reset"] = "रीसेट",
["vehicle.parts_modifier.invalid"] = "अमान्य स्तर मान",
["vehicle.parts_modifier.not_found"] = "पार्ट मेमोरी में नहीं मिला",
["vehicle.parts_modifier.applied"] = "%s स्तर %s पर सेट हुआ",
["vehicle.parts_modifier.reset"] = "%s रीसेट हुआ",

["vehicle.unlock_vehicles.title"] = "वाहन अनलॉक करें",
["vehicle.unlock_vehicles.desc"] = "सभी वाहनों को सिक्कों के साथ खरीदने के लिए उपलब्ध कराएँ",
["vehicle.unlock_vehicles.no_vehicles"] = "कोई वाहन नहीं मिला",
["vehicle.unlock_vehicles.unlocked"] = "वाहन अनलॉक: %d",
["vehicle.unlock_vehicles.none_to_unlock"] = "अनलॉक करने के लिए कोई वाहन नहीं",

["vehicle.max_vehicles.title"] = "अधिकतम वाहन",
["vehicle.max_vehicles.desc"] = "सभी अनलॉक वाहनों के अपग्रेड स्तरों को तुरंत अधिकतम करें",
["vehicle.max_vehicles.no_vehicles"] = "वाहन सूची हल करने में विफल",
["vehicle.max_vehicles.all_maxed"] = "सभी वाहन अधिकतम हुए",
["vehicle.max_vehicles.failed"] = "वाहन अधिकतम करने में विफल",

["vehicle.max_mastery.title"] = "अधिकतम महारत",
["vehicle.max_mastery.desc"] = "सभी अनलॉक और अधिकतम वाहनों की महारत को तुरंत अधिकतम करें।",
["vehicle.max_mastery.all_maxed"] = "सभी महारत अधिकतम हुईं",
["vehicle.max_mastery.failed"] = "महारत अधिकतम करने में विफल",

["vehicle.max_parts.title"] = "अधिकतम पार्ट्स",
["vehicle.max_parts.desc"] = "सभी वाहनों के लिए सभी अनलॉक पार्ट स्तरों को तुरंत अधिकतम करें।",
["vehicle.max_parts.no_vehicles"] = "वाहन सूची हल करने में विफल",
["vehicle.max_parts.all_maxed"] = "सभी पार्ट्स अधिकतम हुए",
["vehicle.max_parts.failed"] = "पार्ट्स अधिकतम करने में विफल",

["vehicle.common.no_vehicles"] = "कोई वाहन नहीं मिला",
["vehicle.common.progress"] = "%d/%d",
["vehicle.common.resolve_list_failed"] = "वाहन सूची हल करने में विफल",
["vehicle.common.no_zero_region"] = "कोई शून्य क्षेत्र नहीं मिला",

}
