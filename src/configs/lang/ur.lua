--[[
  configs/lang/ur.lua — اردو (Urdu)

  Flat table of dotted keys -> strings, loaded by core/utils/lang.lua.
  Looked up at runtime via the global T(key, ...) function, e.g.:
      T("common.ok")                          -> "ٹھیک ہے"
      T("settings.window_width_desc", 400, 650) -> "فلوٹنگ مینو کی چوڑائی (400 - 650 dp)"

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

  This file handles the Urdu localization for the VOID script.
]]

return {

-- ── Common / shared (buttons, generic dialog text) ───────────────────────────
["common.ok"] = "ٹھیک ہے",
["common.cancel"] = "منسوخ",
["common.yes"] = "ہاں",
["common.no"] = "نہیں",
["common.failed"] = "ناکام",
["common.success"] = "کامیاب",
["common.later"] = "بعد میں",
["common.got_it"] = "سمجھ گیا",
["common.retry"] = "دوبارہ کوشش کریں",
["common.wait_safe"] = "انتظار کریں (محفوظ)",
["common.waiting"] = "انتظار ہو رہا ہے...",
["common.force_exit"] = "زبردستی باہر جائیں",
["common.proceed_anyway"] = "پھر بھی آگے بڑھیں",
["common.manual_mode"] = "دستی موڈ",
["common.update_button"] = "اپ ڈیٹ",
["common.launch_failed"] = "چلانے میں ناکامی",
["common.confirm_exit_title"] = "باہر جانے کی تصدیق",
["common.confirm_exit_msg"] = "اسکرپٹ سے باہر جائیں؟",
["common.not_available"] = "دستیاب نہیں",
["common.warning"] = "انتباہ",

-- ── main.lua (boot, updater, virtual-space detection, main loop) ─────────────
["main.exit_active_ops_title"] = "انتباہ: فعال کارروائیاں",
["main.exit_active_ops_msg"] = "%d پس منظر کے کام چل رہے ہیں۔\nزبردستی باہر جانے سے گیم کی حالت خراب ہو سکتی ہے۔",
["main.initializing"] = "شروع ہو رہا ہے...",
["main.no_app_found"] = "کوئی ایپ نہیں ملی",
["main.arch_64bit_required_title"] = "64-bit درکار ہے",
["main.arch_64bit_required_msg"] = "ARMv8a لازمی ہے۔ x86_64 جزوی طور پر سپورٹ شدہ ہے۔",

["main.update_available_title"] = "اپ ڈیٹ دستیاب ہے",
["main.update_available_msg"] = "v%s دستیاب ہے (موجودہ: v%s)\n\n%s\n\nابھی اپ ڈیٹ کریں؟",
["main.no_changelog"] = "کوئی تبدیلی کا ریکارڈ نہیں۔",
["main.downloading_version"] = "v%s ڈاؤن لوڈ ہو رہا ہے...",
["main.update_download_failed_msg"] = "اپ ڈیٹ ڈاؤن لوڈ نہیں ہو سکا:\n%s",
["main.update_write_failed_msg"] = "اس میں لکھا نہیں جا سکا:\n%s",
["main.update_done_title"] = "VOID کو v%s میں اپ ڈیٹ کر دیا گیا",
["main.update_done_msg"] = "VOID کامیابی سے اپ ڈیٹ ہو گیا۔\n\nنیا اسکرپٹ اس نام سے محفوظ ہو گیا ہے:\nvoid_v%s.lua\n\nاپ ڈیٹ لاگو کرنے کے لیے اسے GameGuardian سے چلائیں۔",
["main.launching_version"] = "v%s چل رہا ہے...",
["main.launch_failed_msg"] = "ڈاؤن لوڈ ہو گیا لیکن چل نہیں سکا:\n%s",

["main.multiple_spaces_title"] = "متعدد اسپیسز مل گئیں",
["main.multiple_spaces_desc"] = "HCR2 %d ورچوئل اسپیسز میں پایا گیا۔\nوہ اسپیس منتخب کریں جس میں آپ فی الحال کھیل رہے ہیں۔",
["main.select_space_toast"] = "جاری رکھنے کے لیے ایک اسپیس منتخب کریں۔",
["main.user_space_item"] = "صارف %s  —  %s",
["main.permission_error_title"] = "اجازت کی خرابی",
["main.permission_error_msg"] = "شیل تک رسائی سے انکار کر دیا گیا۔\n\nVoid کو آپ کی ورچوئل اسپیس میں HCR2 تلاش کرنے کے لیے اس کی ضرورت ہے۔ اگر آپ تصدیق کرنا چاہتے ہیں کہ کون سا کمانڈ چل رہا ہے تو Void سورس کوڈ چیک کریں۔",
["main.hcr2_not_found_title"] = "HCR2 ڈیٹا نہیں ملا",
["main.hcr2_not_found_msg"] = "Void آپ کی ورچوئل اسپیس میں HCR2 ڈیٹا تلاش نہیں کر سکا۔ یہ ہو سکتا ہے اگر HCR2 ابھی تک شروع نہیں کیا گیا، یا آپ کی ورچوئل اسپیس ایپ غیر معمولی پاتھ ڈھانچہ استعمال کرتی ہے۔\n\nگیم فائلوں پر منحصر خصوصیات (ایونٹ ریوارڈز، وغیرہ) درست پاتھ کے بغیر کام نہیں کریں گی۔",
["main.manual_data_path_title"] = "دستی ڈیٹا پاتھ",
["main.manual_data_path_hint"] = "HCR2 ڈیٹا پاتھ درج کریں",
["main.manual_path_cancelled"] = "منسوخ کر دیا گیا — پاتھ کے بغیر جاری رکھا جا رہا ہے۔",
["main.waiting_for_lib"] = "%s کا انتظار ہے...",
["main.initialized"] = "شروع ہو گیا",
["main.gamestatus_not_found"] = "GameStatus نہیں ملا",
["main.dont_interrupt"] = "اس اسکرپٹ میں خلل نہ ڈالیں",

-- ── ui/ui.lua (framework chrome: menu, cards, dialogs) ────────────────────────
["ui.size_saved_restart"] = "سائز محفوظ ہو گیا! اسکرپٹ دوبارہ شروع کریں",
["ui.category_error"] = "خرابی: %s",
["ui.category_not_found"] = "کیٹیگری نہیں ملی",
["ui.na"] = "غ/م",
["ui.spinner_select"] = "منتخب کریں",
["ui.slider_default_title"] = "قدر",

-- ── core/engines/patches.lua (addArchModule patch engine) ────────────────────
["patches.requires_arch"] = "%s ڈیوائس درکار ہے (آپ کی ڈیوائس: %s)",
["patches.suffix_enabled"] = " فعال",
["patches.suffix_disabled"] = " غیر فعال",
["patches.pattern_not_found"] = "ناکام: %d پیٹرن نہیں ملے",

-- ── core/engines/arch.lua (architecture detection warnings) ──────────────────
["arch.warning_title"] = "آرکیٹیکچر انتباہ",
["arch.unknown_arch_msg"] = "آپ کا آرکیٹیکچر نامعلوم ہے۔ کیا لائبریری لوڈ ہوئی؟ آپ کون سا سسٹم استعمال کر رہے ہیں؟",
["arch.non_primary_arch_msg"] = "پایا گیا: %s\nکچھ یا تمام لائبریری پیچ کام نہیں کر سکتے۔",
["arch.unknown_version_msg"] = "گیم کا ورژن نامعلوم ہے۔ گیم لوڈ ہونے کے بعد دوبارہ کوشش کریں۔",
["arch.no_base_data_msg"] = "اندرونی خرابی: اس آرکیٹیکچر کے لیے کوئی بنیادی ڈیٹا دستیاب نہیں۔",

-- ── core/engines/scheduler.lua ────────────────────────────────────────────────
["scheduler.task_crashed"] = "شیڈیولر انتباہ: کام کریش ہو گیا -> %s",

-- ── core/utils/paste.lua + catbox.lua (network error strings) ────────────────
["errors.http_error_code"] = "HTTP ایرر کوڈ: %s",
["errors.crashed"] = "کریش ہو گیا: %s",
["errors.url_missing"] = "URL پیرامیٹر غائب یا خالی ہے",
["errors.file_path_missing"] = "فائل کا پاتھ غائب ہے",
["errors.download_url_missing"] = "URL غائب ہے",
["errors.dest_path_missing"] = "منزل کا پاتھ غائب ہے",

-- ── modules/registry.lua (sidebar tab labels + module-load error cards) ──────
["tabs.sep_game"] = "گیم مینو",
["tabs.account"] = "اکاؤنٹ مینو",
["tabs.vehicle"] = "گاڑی مینو",
["tabs.player"] = "کھلاڑی مینو",
["tabs.adventure"] = "ایڈونچر مینو",
["tabs.cups"] = "کپ مینو",
["tabs.team"] = "ٹیم مینو",
["tabs.event"] = "ایونٹ مینو",
["tabs.creative"] = "تخلیقی مینو",
["tabs.shop"] = "شاپ مینو",
["tabs.other"] = "دیگر مینو",
["tabs.sep_script"] = "اسکرپٹ مینو",
["tabs.settings"] = "ترتیبات",
["tabs.about"] = "تعارف",

["registry.module_load_failed"] = "ماڈیول لوڈ کرنے میں ناکامی۔ تفصیلات کے لیے لاگ چیک کریں۔",
["registry.module_runtime_error"] = "رن ٹائم خرابی: %s",
["registry.error"] = "خرابی",

-- ── modules/tabs/settings.lua ─────────────────────────────────────────────────
["settings.section_updates"] = "اپ ڈیٹس",
["settings.auto_update.title"] = "خودکار اپ ڈیٹ",
["settings.auto_update.desc"] = "شروع ہونے پر VOID خودکار اپ ڈیٹ کریں",
["settings.dev_mode_title"] = "ڈیو موڈ",
["settings.auto_update.dev_mode_msg"] = "main.lua کے لیے خودکار اپ ڈیٹ غیر فعال ہے (ڈیو بلڈ)。",
["settings.check_updates.title"] = "اپ ڈیٹ چیک کریں",
["settings.check_updates.desc"] = "GitHub پر تازہ ترین VOID ریلیز چیک کریں",
["settings.check_updates.dev_mode_msg"] = "main.lua کے لیے اپ ڈیٹ چیک غیر فعال ہے (ڈیو بلڈ)。\n\nدستی طور پر ریپو سے پل کریں۔",
["settings.check_updates.checking"] = "اپ ڈیٹس چیک ہو رہے ہیں...",
["settings.check_updates.failed_title"] = "اپ ڈیٹ چیک ناکام",
["settings.check_updates.failed_msg"] = "GitHub تک نہیں پہنچ سکا:\n%s",
["settings.check_updates.up_to_date_title"] = "تازہ ترین",
["settings.check_updates.up_to_date_msg"] = "آپ پہلے ہی تازہ ترین ورژن پر ہیں (v%s)。",
["settings.check_updates.no_changelog"] = "کوئی تبدیلی کا ریکارڈ دستیاب نہیں۔",
["settings.check_updates.available_msg"] = "v%s  (موجودہ: v%s)\n\n%s\n\nاس اسکرپٹ کو ڈاؤن لوڈ اور تبدیل کریں؟",
["settings.check_updates.no_asset_msg"] = "ریلیز میں کوئی .lua اثاثہ نہیں ملا۔",
["settings.check_updates.download_failed_title"] = "ڈاؤن لوڈ ناکام",
["settings.check_updates.write_failed_title"] = "لکھنا ناکام",
["settings.check_updates.done_title"] = "مکمل",
["settings.check_updates.done_msg"] = "v%s میں اپ ڈیٹ ہو گیا۔ لاگو کرنے کے لیے اسکرپٹ دوبارہ شروع کریں۔",
["settings.check_updates.restart_button"] = "دوبارہ شروع کریں",

["settings.section_language"] = "زبان",
["settings.language.title"] = "زبان",
["settings.language.desc"] = "مینو کے لیے اپنی پسندیدہ زبان منتخب کریں",
["settings.language.changed"] = "زبان %s میں سیٹ کر دی گئی",
["settings.language.failed"] = "وہ زبان لوڈ کرنے میں ناکامی",
["settings.language.restart_msg"] = "زبان مکمل طور پر لاگو کرنے کے لیے اسکرپٹ دوبارہ شروع کریں",

["settings.region.other"] = "د: دیگر",
["settings.region.cpp_alloc"] = "Ca: C++ مختص",
["settings.region.unknown"] = "غ: نامعلوم",
["settings.section_memory"] = "میموری",
["settings.memory_range.title"] = "میموری رینج",
["settings.memory_range.desc"] = "موجودہ منتخب کردہ میموری رینج\n(اسکرپٹ کے ذریعے خودکار انتخاب)",
["settings.gamestatus.title"] = "GameStatus",
["settings.gamestatus.desc"] = "موجودہ gamestatus پتہ\n(اسکرپٹ کے ذریعے خودکار انتخاب)",
["settings.gamestatus_raw.title"] = "GameStatus (خام)",
["settings.gamestatus_raw.desc"] = "موجودہ gamestatus (خام) پتہ\n(اسکرپٹ کے ذریعے خودکار انتخاب)",
["settings.clear_memory.title"] = "محفوظ میموری صاف کریں",
["settings.clear_memory.desc"] = "پوری گیم دوبارہ شروع کیے بغیر VOID کی تمام محفوظ میموری صاف کریں۔",

["settings.section_ui_customizations"] = "UI حسب ضرورت",
["settings.theme_store.title"] = "تھیم اسٹور",
["settings.theme_store.desc"] = "کمیونٹی Void تھیمز براؤز اور انسٹال کریں",
["settings.theme_store.unreachable_msg"] = "تھیم اسٹور تک نہیں پہنچ سکا:\n%s",
["settings.theme_store.parse_failed_msg"] = "تھیم اسٹور ڈیٹا پارس نہیں ہو سکا۔",
["settings.theme_store.list_title"] = "Void تھیم اسٹور",
["settings.theme_store.search_results_desc"] = "تلاش کے نتائج: %s ملے",
["settings.theme_store.available_desc"] = "%s تھیمز دستیاب ہیں",
["settings.theme_store.by_author"] = "%s کے ذریعے",
["settings.theme_store.search_item"] = "🔍 تلاش کریں...",
["settings.theme_store.clear_search_item"] = "✕ تلاش صاف کریں",
["settings.theme_store.search_title"] = "تھیمز تلاش کریں",
["settings.theme_store.search_hint"] = "تھیم کا نام، مصنف یا وضاحت",
["settings.theme_store.no_results"] = "%s کے لیے کوئی تھیم نہیں ملا",
["settings.theme_store.detail_msg"] = "%s کے ذریعے\n\n%s\n\nID: %s",
["settings.theme_store.install_button"] = "تھیم انسٹال کریں",
["settings.theme_downloading_bg"] = "پس منظر کی تصویر ڈاؤن لوڈ ہو رہی ہے...",
["settings.theme_imported"] = "تھیم درآمد ہو گیا!",
["settings.theme_invalid_bundle"] = "غلط بنڈل فارمیٹ۔",
["settings.theme_cloud_error"] = "کلاؤڈ خرابی: %s",
["settings.reset_theme.title"] = "تھیم ری سیٹ کریں",
["settings.reset_theme.desc"] = "کسٹم تھیم اور پس منظر کی تصویر کو ڈیفالٹ پر ری سیٹ کریں",
["settings.import_theme.title"] = "تھیم درآمد کریں",
["settings.import_theme.desc"] = "کلاؤڈ سے کسٹم تھیم درآمد کریں",
["settings.import_theme.hint"] = "شیئر ID درج کریں",
["settings.export_theme.title"] = "تھیم برآمد کریں",
["settings.export_theme.desc"] = "کسٹم تھیم اور پس منظر کی تصویر کو کلاؤڈ میں برآمد کریں",
["settings.export_theme.share_id_msg"] = "شیئر ID: %s\n\nکلپ بورڈ پر کاپی ہو گیا۔",
["settings.export_theme.upload_failed_msg"] = "اپ لوڈ ناکام: %s",
["settings.export_theme.size_warning_title"] = "اپ لوڈ سائز انتباہ",
["settings.export_theme.size_warning_msg"] = "کسٹم پس منظر کی تصویر شامل کریں؟ اس سے آپ کی تصویر کے سائز کے لحاظ سے اپ لوڈ سائز بڑھ جائے گا۔",
["settings.export_theme.uploading_bg"] = "Catbox پر پس منظر کی تصویر اپ لوڈ ہو رہی ہے...",
["settings.export_theme.image_upload_failed_title"] = "خرابی",
["settings.export_theme.image_upload_failed_msg"] = "تصویر اپ لوڈ ناکام: %s",
["settings.tabs_icon.title"] = "ٹیب آئیکن",
["settings.tabs_icon.desc"] = "ٹیب آئیکن تبدیل کریں",
["settings.tabs_icon.hint"] = "آئیکن درج کریں",
["settings.tabs_icon.empty_error"] = "خالی نہیں ہو سکتا",

["settings.bg_opacity.title"] = "پس منظر کی دھندلاپن",
["settings.bg_opacity.desc"] = "پینلز، کارڈز اور ہیڈر کی شفافیت",
["settings.slider.alpha"] = "الفا",
["settings.bg_image_opacity.title"] = "پس منظر کی تصویر کی دھندلاپن",
["settings.bg_image_opacity.desc"] = "خالص انٹیجر چینلز کا استعمال کرتے ہوئے مرئیت الفا ترتیبات کو براہ راست ایڈجسٹ کریں۔",
["settings.bg_image_picker.title"] = "پس منظر کی تصویر",
["settings.bg_image_picker.desc"] = "اپنی کسٹم ترتیب کی پس منظر کی تصویر کے لیے مطلق فائل پاتھ تبدیل کرنے کے لیے تھپتھپائیں",
["settings.bg_image_picker.path_label"] = "مطلق تصویر فائل پاتھ (.jpg یا .png):",
["settings.bg_image_picker.remove_label"] = "پس منظر کی تصویر ہٹائیں",
["settings.bg_image_picker.success_title"] = "کامیاب",
["settings.bg_image_picker.removed_msg"] = "پس منظر کی تصویر ہٹا دی گئی",
["settings.bg_image_picker.added_msg"] = "پس منظر کی تصویر شامل کر دی گئی",
["settings.bg_image_picker.not_found_msg"] = "فائل نہیں ملی یا پڑھنے کی کارروائی مسترد کر دی گئی:\n%s",

["settings.bg_rgb.title"] = "پس منظر RGB",
["settings.bg_rgb.desc"] = "پینل کے پس منظر کے لیے رنگ (ہیڈر اور کارڈ خودکار پیمانہ)",
["settings.slider.r"] = "R",
["settings.slider.g"] = "G",
["settings.slider.b"] = "B",
["settings.accent_rgb.title"] = "تاکیدی RGB",
["settings.accent_rgb.desc"] = "بٹنز، ٹوگلز اور فعال کارڈز کے لیے رنگ (دھیما رنگ خودکار اخذ)",
["settings.logo_rgb.title"] = "ہائی لائٹ RGB",
["settings.logo_rgb.desc"] = "لیبلز، آئیکونز اور انٹرایکٹو ٹیکسٹ کے لیے رنگ (ہمیشہ مکمل طور پر مبہم)",
["settings.sub_rgb.title"] = "ذیلی متن RGB",
["settings.sub_rgb.desc"] = "وضاحتوں اور غیر فعال ٹیب لیبلز کے لیے رنگ",
["settings.text_rgb.title"] = "متن RGB",
["settings.text_rgb.desc"] = "مرکزی مینو متن کے لیے رنگ",

["settings.win_width.title"] = "مینو کی چوڑائی",
["settings.win_width.desc"] = "فلوٹنگ مینو کی چوڑائی (%d – %d dp)",
["settings.slider.width"] = "چوڑائی",
["settings.win_height.title"] = "مینو کی اونچائی",
["settings.win_height.desc"] = "اسکرول ایبل مواد کے علاقے کی اونچائی (%d – %d dp)",
["settings.slider.height"] = "اونچائی",

-- ── modules/tabs/about.lua ────────────────────────────────────────────────────
["about.about_script.title"] = "اسکرپٹ کے بارے میں",
["about.about_script.desc"] = "Hill Climb Racing 2 کے لیے کسٹم Pivot ماحول پر بنایا گیا ایک طاقتور اور انتہائی بہتر میموری ہیرا پھیری اسکرپٹ۔\n\nPivot ڈاؤن لوڈ کریں:\nhttps://github.com/vekendianorg/pivot/releases/",
["about.script_owner.title"] = "اسکرپٹ کا مالک",
["about.script_owner.desc"] = "- Vekendian Organization (github: vekendianorg)",
["about.script_dev.title"] = "اسکرپٹ ڈویلپر",
["about.script_dev.desc"] = [[
- Lazor (github: lazor-git)
- AMR (github: amr-gt)
- Erik (github: eomthix)
]],
["about.script_translator.title"] = "اسکرپٹ مترجم",
["about.script_translator.desc"] = [[
- English: Lazor (github: lazor-git)
- Bahasa Indonesia: Lazor (github: lazor-git)
- Español: Jayy2k (github: Jayy2k)
- Deutsch: Erik (github: eomthix)
- Русский: Winter Lotus(github: Ohranik1Pitorochki; discord:nikolaypg67), profinoobru (github: profinoobru)
- Thai: NaiArt777 (github: artphakkapol-hub)
- বাংলা: AMR (github: amr-gt)
- العربية: AMR (github: amr-gt)
- اردو: AMR (github: amr-gt)
- Français: AMR (github: amr-gt)
- Українська: AMR (github: amr-gt)
- Türkçe: AMR (github: amr-gt)
- Português (Brasil): AMR (github: amr-gt)
]],
["about.credits.title"] = "اعترافات",
["about.credits.desc"] = [[
- Lazor (github: lazor-git)
- Lan9118 (discord: lan9118)
- AMR (github: amr-gt)
- Erik (github: eomthix)
- Sr Romero
- Profinoobru
]],
["about.special_thanks.title"] = "خصوصی شکریہ",
["about.special_thanks.desc"] = [[
- Aryan/KokushiboModz
]],

-- ── modules/tabs/other.lua ────────────────────────────────────────────────────
["other.debug_mode.title"] = "ڈیبگ موڈ",
["other.debug_mode.desc"] = "ان-گیم ڈیبگ موڈ ٹوگل کریں",
["other.debug_mode.enabled"] = "ڈیبگ موڈ فعال",
["other.debug_mode.disabled"] = "ڈیبگ موڈ غیر فعال",
["other.hint.width"] = "چوڑائی",
["other.hint.height"] = "اونچائی",
["other.resolution.title"] = "ریزولوشن ایڈجسٹ کریں",
["other.resolution.desc"] = "گیم کی چوڑائی اور اونچائی ایڈجسٹ کریں (ڈیفالٹ 1280x720)",
["other.resolution.applied"] = "ریزولوشن %dx%d پر سیٹ کر دی گئی",
["other.resolution_offset.title"] = "ریزولوشن آفسیٹ ایڈجسٹ کریں",
["other.resolution_offset.desc"] = "گیم کی چوڑائی آفسیٹ اور اونچائی آفسیٹ ایڈجسٹ کریں (ڈیفالٹ 0x0)، بڑی اسکرین پر چھوٹی ریزولوشن کے لیے بہترین۔",
["other.resolution_offset.applied"] = "ریزولوشن آفسیٹ %dx%d پر سیٹ کر دی گئی",
["other.glsurface_not_found"] = "GLSurfaceView نہیں ملا",

-- ── modules/tabs/shop.lua ─────────────────────────────────────────────────────
["shop.free_chest.title"] = "مفت چیسٹ",
["shop.free_chest.desc"] = "شاپ ٹیب میں چیسٹس کو مفت کریں",
["shop.free_chest.enabled"] = "مفت چیسٹ فعال",
["shop.free_chest.disabled"] = "مفت چیسٹ غیر فعال",
["shop.free_purchases.title"] = "مفت خریداریاں",
["shop.free_purchases.desc"] = "شاپ ٹیب میں کچھ روزانہ ڈیلز کو مفت کریں (پاپ اپ/بیجز کے طور پر خصوصی پیشکشوں کے لیے بھی کام کرتا ہے)",
["shop.free_purchases.progress"] = "%d/%d",
["shop.free_purchases.success"] = "مفت خریداری کامیاب",
["shop.change_chest.title"] = "چیسٹ تبدیل کریں",
["shop.change_chest.desc"] = "لیجنڈری چیسٹ کو منتخب کردہ چیسٹ میں تبدیل کریں",
["shop.change_chest.changed"] = "چیسٹ %s میں تبدیل ہو گئی",
["shop.change_chest.options"] = {
    "عام چیسٹ", "غیر معمولی چیسٹ", "نایاب چیسٹ", "مہاکاوی چیسٹ",
    "چیمپئن چیسٹ", "خصوصی چیسٹ 1", "کرسمس چیسٹ", "لیجنڈری چیسٹ",
    "نیلی چیسٹ", "VIP چیسٹ 1", "VIP چیسٹ 2", "ویڈیو چیسٹ",
    "اسٹارٹر چیسٹ", "خصوصی چیسٹ 2", "Fingersoft چیسٹ", "میگا چیسٹ",
    "ٹیم اسپرٹ چیسٹ", "اسٹائل چیسٹ", "میتھک چیسٹ"
},

-- ── modules/tabs/player.lua ───────────────────────────────────────────────────
["player.auto_detach.title"] = "خودکار علیحدگی",
["player.auto_detach.desc"] = "ریلی کار کی چھت جیسے حصوں کو خودکار طور پر الگ کریں",
["player.auto_die.title"] = "خودکار موت",
["player.auto_die.desc"] = "خودکار طور پر موت واقع کریں (ایندھن ختم)",
["player.no_clip.title"] = "نو-کلپ",
["player.no_clip.desc"] = "اپنے کھلاڑی کو بغیر مرے اشیاء کے ذریعے گزاریں (آپ کپ میں ختم لائنوں کے اوپر جا سکتے ہیں)",
["player.no_clip.enabled"] = "نو-کلپ فعال",
["player.no_clip.disabled"] = "نو-کلپ غیر فعال",
["player.hide_name.title"] = "نام چھپائیں",
["player.hide_name.desc"] = "ریس میں اپنا کھلاڑی نام چھپائیں",
["player.hide_name.enabled"] = "نام چھپانا فعال",
["player.hide_name.disabled"] = "نام چھپانا غیر فعال",
["player.hide_flag.title"] = "جھنڈا چھپائیں",
["player.hide_flag.desc"] = "ریس میں اپنا جھنڈا چھپائیں",
["player.hide_flag.enabled"] = "جھنڈا چھپانا فعال",
["player.hide_flag.disabled"] = "جھنڈا چھپانا غیر فعال",
["player.fuel.title"] = "ایندھن",
["player.fuel.desc"] = "ریس کے دوران ایندھن کو ایک مستقل قدر پر بند کریں (0.0 – 100.0)",
["player.fuel.prompt_amount"] = "ایندھن کی مقدار (0 – 100)",
["player.fuel.prompt_reset"] = "ری سیٹ",
["player.fuel.invalid"] = "غلط قدر، 0 – 100 ہونی چاہیے",
["player.fuel.applied"] = "ایندھن %s پر بند کر دیا گیا",
["player.fuel.reset"] = "ایندھن بحال ہو گیا",
["player.fuel.not_applied"] = "ایندھن فعال نہیں",
["player.zoom.title"] = "زوم ایڈجسٹ کریں",
["player.zoom.desc"] = "اپنا کیمرہ کتنا قریب یا دور ہے ایڈجسٹ کریں",
["player.slider.min"] = "کم از کم",
["player.slider.max"] = "زیادہ سے زیادہ",
["player.gravity.title"] = "کشش ثقل ایڈجسٹ کریں",
["player.gravity.desc"] = "کشش ثقل کتنی مضبوط ہے ایڈجسٹ کریں",
["player.slider.x"] = "X",
["player.slider.y"] = "Y",

-- ── modules/tabs/adventure.lua ────────────────────────────────────────────────
["adventure.auto_adventure_chests.title"] = "خودکار ایڈونچر چیسٹس (غیر مستحکم)",
["adventure.auto_adventure_chests.desc"] = "خودکار طور پر اپنی ایڈونچر چیسٹس کا لیول بڑھائیں",
["adventure.auto_adventure_chests.none_found"] = "کوئی ایڈونچر چیسٹ نہیں ملی",
["adventure.auto_adventure_chests.done"] = "مکمل",

["adventure.set_distance.title"] = "فاصلہ سیٹ کریں",
["adventure.set_distance.desc"] = "اپنے ایڈونچر ریس کا فاصلہ ایک کسٹم قدر پر سیٹ کریں۔ ایک فعال ریس میں ہونا ضروری ہے۔ زیادہ فاصلہ زیادہ ستارے حاصل کر سکتا ہے۔ زیادہ سے زیادہ ستارے 5000m پر۔ (ٹیلی پورٹ فنکشن نہیں)",
["adventure.set_distance.loop_active_title"] = "فاصلہ سیٹ کریں — لوپ فعال",
["adventure.set_distance.loop_active_msg"] = "فاصلہ لوپ فی الحال چل رہا ہے۔\nآپ کیا کرنا چاہتے ہیں؟",
["adventure.set_distance.stop_loop"] = "لوپ روکیں",
["adventure.set_distance.keep_running"] = "چلتے رہیں",
["adventure.set_distance.loop_will_stop"] = "موجودہ ٹک کے بعد لوپ رک جائے گا۔",
["adventure.set_distance.prompt_target"] = "ہدف فاصلہ (میٹر)",
["adventure.set_distance.prompt_loop"] = "لوپ (خودکار دوبارہ لاگو)",
["adventure.set_distance.prompt_interval"] = "لوپ وقفہ (ملی سیکنڈ، کم از کم 250)",
["adventure.set_distance.over_max_title"] = "فاصلہ انتباہ",
["adventure.set_distance.over_max_msg"] = "5000m سے زیادہ فاصلہ آپ کو کوئی ستارے نہیں دے گا۔\n\nریس فاصلہ رجسٹر کرے گی، لیکن کوئی ستارہ انعام نہیں دیا جائے گا۔ جاری رکھیں؟",
["adventure.set_distance.continue_button"] = "جاری رکھیں",
["adventure.set_distance.not_in_adventure"] = "پہلے ایڈونچر ٹیب پر جائیں اور ریس شروع کریں",
["adventure.set_distance.start_race_first"] = "پہلے ریس شروع کریں",
["adventure.set_distance.applied"] = "فاصلہ سیٹ کر دیا گیا: %sm",
["adventure.set_distance.loop_stopped"] = "فاصلہ سیٹ کریں لوپ روک دیا گیا۔",
["adventure.set_distance.loop_running"] = "فاصلہ لوپ چل رہا ہے — روکنے کے لیے Set Distance کو تھپتھپائیں",
["adventure.set_distance.loop_warn_title"] = "فاصلہ لوپ انتباہ",
["adventure.set_distance.loop_warn_msg"] = "لوپ موڈ ہر %s ملی سیکنڈ بعد میموری میں لکھتا ہے۔\n\nمختصر وقفہ استعمال کرنے سے عدم استحکام، بصری خرابیاں، یا گیم کریش ہو سکتی ہے۔\n\nپھر بھی جاری رکھیں؟",

-- ── modules/tabs/cups.lua ─────────────────────────────────────────────────────
["cups.adjust_countdown.title"] = "کاؤنٹ ڈاؤن ایڈجسٹ کریں",
["cups.adjust_countdown.desc"] = "ریس شروع ہونے سے پہلے کاؤنٹ ڈاؤن ایڈجسٹ کریں",
["cups.slider.seconds"] = "سیکنڈ",
["cups.adjust_countdown.applied"] = "کاؤنٹ ڈاؤن %ss پر ایڈجسٹ کر دیا گیا",
["cups.auto_win.title"] = "خودکار جیت",
["cups.auto_win.desc"] = "آپ کے ریس کے نتائج کچھ بھی ہوں خودکار طور پر جیتیں",
["cups.force_boss.title"] = "باس مجبور کریں",
["cups.force_boss.desc"] = "باس ہمیشہ ظاہر ہو",
["cups.force_cup.title"] = "کپ مجبور کریں",
["cups.force_cup.desc"] = "ایک کپ مجبور کرتا ہے",
["cups.force_cup.not_found"] = "Force Cup نہیں ملا۔ بعد میں دوبارہ کوشش کریں۔",
["cups.force_cup.enabled"] = "Force Cup فعال",
["cups.force_cup.disabled"] = "Force Cup غیر فعال",
["cups.set_time.title"] = "وقت سیٹ کریں",
["cups.set_time.desc"] = "اپنا ریس کا وقت سیٹ کریں (حفاظت کے لیے وقت منجمد نہیں ہوگا)۔ ایک فعال کپ ریس میں ہونا ضروری ہے۔ (مثال: 1:09.069، 7.284)",
["cups.set_time.hint"] = "وقت (1:09.069 یا 7.284)",
["cups.set_time.invalid_format"] = "غلط فارمیٹ۔ 1:09.069 یا 7.284 استعمال کریں",
["cups.set_time.no_negative"] = "منفی قدریں نہیں",
["cups.set_time.not_in_cup"] = "پہلے کپ ٹیب پر جائیں اور ریس شروع کریں",
["cups.set_time.start_race_first"] = "پہلے ریس شروع کریں",
["cups.set_time.applied"] = "وقت %s پر سیٹ کر دیا گیا",
["cups.unlimited_tasks.title"] = "لامحدود کام",
["cups.unlimited_tasks.desc"] = "تمام کاموں کو مکمل شدہ اور ہمیشہ قابل دعوی کے طور پر منجمد کریں۔ بار بار انعامات کا دعوی کریں۔",
["cups.unlimited_tasks.resolve_failed"] = "کاموں کی فہرست حل کرنے میں ناکامی",
["cups.unlimited_tasks.none_found"] = "کوئی کام نہیں ملا",
["cups.unlimited_tasks.enabled"] = "لامحدود کام فعال",
["cups.unlimited_tasks.disabled"] = "لامحدود کام غیر فعال",
["cups.unlimited_tasks.none_to_freeze"] = "منجمد کرنے کے لیے کوئی کام نہیں",
["cups.rank_points_bonus.title"] = "+498 رینک پوائنٹس",
["cups.rank_points_bonus.desc"] = "تمام لیگ کاموں کو 200 پوائنٹس کے بجائے 498 پوائنٹس دیں، دیگر انعامات ہٹا دیں۔",
["cups.rank_points_bonus.none_found"] = "کوئی لیگ کام نہیں ملا",
["cups.rank_points_bonus.boosted"] = "رینک پوائنٹس بڑھا دیے گئے: %s",
["cups.rank_points_bonus.no_match"] = "کوئی مماثل لیگ کام نہیں ملا",
["cups.rank_points_bonus.nothing_to_restore"] = "بحال کرنے کے لیے کچھ نہیں",
["cups.rank_points_bonus.restored"] = "بحال کر دیا گیا: %s",

-- ── modules/tabs/event.lua ────────────────────────────────────────────────────
["event.patch_rewards.title"] = "ایونٹ ریوارڈز پیچ",
["event.patch_rewards.desc"] = "موجودہ پبلک ایونٹ ریوارڈز کو VOID کی فراہم کردہ کسٹم ریوارڈز میں پیچ کریں (گیم دوبارہ شروع کرنے کی ضرورت ہے)",
["event.restore_events.title"] = "ایونٹ ریوارڈز بحال کریں",
["event.restore_events.desc"] = "ترمیم شدہ ایونٹ JSON کو حذف کریں تاکہ گیم سرور بحالی پر مجبور ہو (گیم دوبارہ شروع کرنے کی ضرورت ہے)",

["event.checking_permissions"] = "ماحول کی اجازتوں کی جانچ ہو رہی ہے...",
["event.scanning_files"] = "فعال فائلیں اسکین ہو رہی ہیں...",
["event.decode_rewards_failed"] = "ریوارڈز JSON ڈی کوڈ کرنے میں ناکامی",
["event.workspace_creation_failed"] = "مہلک: ورک اسپیس تخلیق ناکام: %s",
["event.workspace_creation_failed_dialog"] = "مہلک: ورک اسپیس ڈائرکٹری نہیں بن سکی۔\n%s",
["event.file_inaccessible"] = "فائل اس پاتھ پر ناقابل رسائی: %s",
["event.predecrypt_not_found"] = "پری ڈیکرپٹ: ماخذ نہیں ملا: %s",
["event.predecrypt_empty"] = "پری ڈیکرپٹ: ماخذ خالی ہے (0 بائٹس): %s",
["event.decode_active_failed"] = "اس پاتھ پر active_events.json ڈی کوڈ کرنے میں ناکامی: %s",
["event.no_active_events"] = "اس پاتھ پر کوئی فعال ایونٹ نہیں ملا: %s",
["event.cannot_open_active"] = "اس پاتھ پر active_events.json نہیں کھل سکا: %s",
["event.decrypt_active_failed"] = "اس پاتھ پر active_events.json ڈیکرپٹ کرنے میں ناکامی: %s",
["event.root_copy_failed"] = "روٹ کاپی ناکام: %s",

["event.select_events_patch"] = "پیچ کرنے کے لیے ایونٹس منتخب کریں:\nپاتھ: %s",
["event.user_cancelled"] = "صارف نے اس پاتھ کے لیے انتخاب منسوخ کر دیا: %s",
["event.rewards_unavailable"] = "ایمبیڈڈ ریوارڈز دستیاب نہیں، اس پاتھ کے لیے پیچ چھوڑ رہے ہیں: %s",
["event.skipped_unreadable"] = "ناقابل پڑھ ایونٹ چھوڑ دیا: %s",
["event.predecrypt_event_not_found"] = "پری ڈیکرپٹ: ایونٹ نہیں ملا: %s",
["event.predecrypt_event_empty"] = "پری ڈیکرپٹ: ایونٹ خالی ہے (0 بائٹس): %s",
["event.processing_failed"] = "%s پر کارروائی ناکام: %s",
["event.cannot_open_decrypted"] = "ڈیکرپٹڈ فائل نہیں کھل سکی: %s",
["event.decrypt_event_failed"] = "ایونٹ ڈیکرپٹ کرنے میں ناکامی: %s",
["event.loop_crash"] = "اہم فائل پروسیسنگ لوپ کریش: %s",

["event.success_header"] = "کامیابی سے:",
["event.success_removed_header"] = "کامیابی سے ہٹا دیا گیا (دوبارہ شروع کرنے پر بحال ہوگا):",
["event.success_item"] = "- %s",
["event.success_item_json"] = "- %s.json",
["event.failed_header"] = "ناکام:",
["event.failed_item"] = "- %s",

["event.patch_results_title"] = "پیچ کے نتائج",
["event.restore_results_title"] = "بحالی کے نتائج",
["event.restart_required_title"] = "دوبارہ شروع کرنے کی ضرورت ہے",
["event.patch_restart_msg"] = "گیم بند کر دی گئی ہے اور یہ اسکرپٹ باہر جائے گا، اسے دوبارہ شروع کریں اور پیچ کے اثرات دیکھیں",
["event.restore_restart_msg"] = "سرور فائل کی مطابقت پذیری کی اجازت کے لیے گیم اب بند ہو جائے گی۔",
["event.finishing_tasks_patch"] = "زیر التواء پس منظر کے کام ختم کیے جا رہے ہیں... براہ کرم انتظار کریں۔",
["event.finishing_tasks_restore"] = "زیر التواء پس منظر کے کام ختم کیے جا رہے ہیں...",
["event.patch_failed_msg"] = "پیچ کرنے میں ناکامی، دوبارہ کوشش کریں۔",

["event.select_events_restore"] = "بحال کرنے (حذف کرنے) کے لیے فائلیں منتخب کریں:\nپاتھ: %s",
["event.delete_failed"] = "%s حذف کرنے میں ناکامی: %s",

-- ── modules/tabs/account.lua ──────────────────────────────────────────────────
["account.change_name.title"] = "نام تبدیل کریں",
["account.change_name.desc"] = "اپنا کھلاڑی نام تبدیل کریں",
["account.change_name.hint"] = "نام درج کریں",
["account.change_name.empty"] = "پہلے نام درج کریں",
["account.change_name.too_long_title"] = "نام بہت طویل ہے",
["account.change_name.too_long_msg"] = "آپ کا نام بہت طویل ہے، براہ کرم اسے چھوٹا کریں",
["account.change_name.resolve_failed"] = "نام پوائنٹر حل کرنے میں ناکامی",
["account.change_name.applied"] = "نام %s میں تبدیل کر دیا گیا",

["account.change_gp.title"] = "گیراج پاور تبدیل کریں",
["account.change_gp.desc"] = "پروفائل گیراج پاور تبدیل کرتا ہے (اگر زیادہ ہو تو برقرار رہتی ہے)۔ اگر زیادہ سے زیادہ سے تجاوز کرے تو ری سیٹ کرنے کے لیے 8 سیٹ کریں، لیکن صرف اس صورت میں جب آپ کی اصل GP پہلے سے ہی حد کے نیچے طے شدہ ہو۔",
["account.change_gp.hint"] = "گیراج پاور درج کریں",
["account.change_gp.max_int_title"] = "زیادہ سے زیادہ 32-bit int تک پہنچ گیا",
["account.change_gp.lower_value"] = "براہ کرم اپنی قدر کم کریں",
["account.change_gp.too_low_title"] = "بہت کم",
["account.change_gp.higher_value"] = "براہ کرم اپنی قدر بڑھائیں",
["account.change_gp.applied"] = "گیراج پاور %s میں تبدیل کر دی گئی",

["account.fake_unlock.title"] = "جعلی انلاک",
["account.fake_unlock.desc"] = "تمام حسب ضرورت کو عارضی طور پر انلاک کریں",
["account.fake_vip.title"] = "جعلی VIP",
["account.fake_vip.desc"] = "VIP سبسکرپشن کی حالت کو مقامی طور پر ٹوگل کریں",

["account.fake_rank.title"] = "جعلی رینک",
["account.fake_rank.desc"] = "اپنی رینک کو خودکار طور پر جعلی لیجنڈری پر سیٹ کریں",
["account.fake_rank.race_warn_title"] = "ریس درکار ہے",
["account.fake_rank.race_warn_msg"] = "جعلی رینک صرف اس وقت لاگو کی جانی چاہیے جب کپ ریس فعال طور پر چل رہی ہو۔\n\nاسے ریس کے باہر لاگو کرنے سے شیڈو بین ہو سکتا ہے۔\n\nجاری رکھنے سے پہلے یقینی بنائیں کہ آپ پہلے ہی کپ ریس کے اندر ہیں۔\n\nپھر بھی جاری رکھیں؟",
["account.fake_rank.continue_button"] = "جاری رکھیں",

-- ── modules/tabs/vehicle.lua ──────────────────────────────────────────────────
["vehicle.parts_slot.title"] = "پرزے سلاٹ ایڈجسٹ کریں",
["vehicle.parts_slot.desc"] = "تمام گاڑیوں کے لیے پرزے سلاٹ ایڈجسٹ کریں",
["vehicle.parts_slot.slider_title"] = "سلاٹس",
["vehicle.parts_slot.no_vehicles"] = "کوئی گاڑی نہیں ملی",
["vehicle.parts_slot.applied"] = "پرزے سلاٹ ایڈجسٹ کر دیا گیا: %d گاڑیاں",

["vehicle.parts_modifier.title"] = "پرزے موڈیفائر",
["vehicle.parts_modifier.desc"] = "فعال ریس میں ٹیوننگ پارٹ لیول کی قدروں میں ترمیم کریں",
["vehicle.parts_modifier.select"] = "ایک پرزہ منتخب کریں",
["vehicle.parts_modifier.prompt_level"] = "لیول: ",
["vehicle.parts_modifier.prompt_digit0"] = "ہندسہ: ",
["vehicle.parts_modifier.prompt_digit1"] = "دم: ",
["vehicle.parts_modifier.prompt_reset"] = "ری سیٹ",
["vehicle.parts_modifier.invalid"] = "غلط لیول قدر",
["vehicle.parts_modifier.not_found"] = "میموری میں پرزہ نہیں ملا",
["vehicle.parts_modifier.applied"] = "%s لیول %s پر سیٹ کر دیا گیا",
["vehicle.parts_modifier.reset"] = "%s ری سیٹ کر دیا گیا",

["vehicle.unlock_vehicles.title"] = "گاڑیاں انلاک کریں",
["vehicle.unlock_vehicles.desc"] = "تمام گاڑیوں کو سکوں کے ساتھ خریدنے کے لیے دستیاب کریں",
["vehicle.unlock_vehicles.no_vehicles"] = "کوئی گاڑی نہیں ملی",
["vehicle.unlock_vehicles.unlocked"] = "گاڑیاں انلاک کر دی گئیں: %d",
["vehicle.unlock_vehicles.none_to_unlock"] = "انلاک کرنے کے لیے کوئی گاڑی نہیں",

["vehicle.max_vehicles.title"] = "زیادہ سے زیادہ گاڑیاں",
["vehicle.max_vehicles.desc"] = "تمام انلاک شدہ گاڑیوں کی اپ گریڈ لیول کو فوری طور پر زیادہ سے زیادہ کریں",
["vehicle.max_vehicles.no_vehicles"] = "گاڑیوں کی فہرست حل کرنے میں ناکامی",
["vehicle.max_vehicles.all_maxed"] = "تمام گاڑیاں زیادہ سے زیادہ کر دی گئیں",
["vehicle.max_vehicles.failed"] = "گاڑیاں زیادہ سے زیادہ کرنے میں ناکامی",

["vehicle.max_mastery.title"] = "زیادہ سے زیادہ مہارت",
["vehicle.max_mastery.desc"] = "تمام انلاک شدہ اور زیادہ سے زیادہ گاڑیوں کی مہارتوں کو فوری طور پر زیادہ سے زیادہ کریں۔",
["vehicle.max_mastery.all_maxed"] = "تمام مہارتیں زیادہ سے زیادہ کر دی گئیں",
["vehicle.max_mastery.failed"] = "مہارتوں کو زیادہ سے زیادہ کرنے میں ناکامی",

["vehicle.max_parts.title"] = "زیادہ سے زیادہ پرزے",
["vehicle.max_parts.desc"] = "تمام گاڑیوں کے لیے تمام انلاک شدہ پرزوں کی لیول کو فوری طور پر زیادہ سے زیادہ کریں۔",
["vehicle.max_parts.no_vehicles"] = "گاڑیوں کی فہرست حل کرنے میں ناکامی",
["vehicle.max_parts.all_maxed"] = "تمام پرزے زیادہ سے زیادہ کر دیے گئے",
["vehicle.max_parts.failed"] = "پرزے زیادہ سے زیادہ کرنے میں ناکامی",

["vehicle.common.no_vehicles"] = "کوئی گاڑی نہیں ملی",
["vehicle.common.progress"] = "%d/%d",
["vehicle.common.resolve_list_failed"] = "گاڑیوں کی فہرست حل کرنے میں ناکامی",
["vehicle.common.no_zero_region"] = "کوئی زیرو ریجن نہیں ملا",

}
