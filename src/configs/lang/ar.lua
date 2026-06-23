--[[
  configs/lang/ar.lua — العربية (Arabic)

  Flat table of dotted keys -> strings, loaded by core/utils/lang.lua.
  Looked up at runtime via the global T(key, ...) function, e.g.:
      T("common.ok")                          -> "موافق"
      T("settings.window_width_desc", 400, 650) -> "عرض القائمة العائمة (400 - 650 dp)"

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

  This file handles the Arabic localization for the VOID script.
]]

return {

-- ── Common / shared (buttons, generic dialog text) ───────────────────────────
["common.ok"] = "موافق",
["common.cancel"] = "إلغاء",
["common.yes"] = "نعم",
["common.no"] = "لا",
["common.failed"] = "فشل",
["common.success"] = "نجح",
["common.later"] = "لاحقًا",
["common.got_it"] = "فهمت",
["common.retry"] = "إعادة المحاولة",
["common.wait_safe"] = "انتظر (آمن)",
["common.waiting"] = "جارٍ الانتظار...",
["common.force_exit"] = "إغلاق إجباري",
["common.proceed_anyway"] = "المتابعة على أي حال",
["common.manual_mode"] = "الوضع اليدوي",
["common.update_button"] = "تحديث",
["common.launch_failed"] = "فشل التشغيل",
["common.confirm_exit_title"] = "تأكيد الخروج",
["common.confirm_exit_msg"] = "الخروج من السكريبت؟",
["common.not_available"] = "غير متاح",
["common.warning"] = "تحذير",

-- ── main.lua (boot, updater, virtual-space detection, main loop) ─────────────
["main.exit_active_ops_title"] = "تحذير: عمليات نشطة",
["main.exit_active_ops_msg"] = "هناك %d مهمة/مهام تعمل في الخلفية.\nقد يؤدي الإغلاق الإجباري إلى تلف حالة اللعبة.",
["main.initializing"] = "جارٍ التهيئة...",
["main.no_app_found"] = "لم يتم العثور على تطبيق",
["main.arch_64bit_required_title"] = "مطلوب 64 بت",
["main.arch_64bit_required_msg"] = "ARMv8a إلزامي. x86_64 مدعوم جزئيًا.",

["main.update_available_title"] = "تحديث متاح",
["main.update_available_msg"] = "الإصدار v%s متاح (الحالي: v%s)\n\n%s\n\nتحديث الآن؟",
["main.no_changelog"] = "لا يوجد سجل تغييرات.",
["main.downloading_version"] = "جارٍ تنزيل الإصدار v%s...",
["main.update_download_failed_msg"] = "تعذّر تنزيل التحديث:\n%s",
["main.update_write_failed_msg"] = "تعذّر الكتابة إلى:\n%s",
["main.update_done_title"] = "تم تحديث VOID إلى v%s",
["main.update_done_msg"] = "تم تحديث VOID بنجاح.\n\nتم حفظ السكريبت الجديد باسم:\nvoid_v%s.lua\n\nشغّله من GameGuardian لتطبيق التحديث.",
["main.launching_version"] = "جارٍ تشغيل الإصدار v%s...",
["main.launch_failed_msg"] = "تم التنزيل لكن لا يمكن التشغيل:\n%s",

["main.multiple_spaces_title"] = "تم اكتشاف مساحات متعددة",
["main.multiple_spaces_desc"] = "تم العثور على HCR2 في %d مساحات افتراضية.\nاختر المساحة التي تلعب فيها حاليًا.",
["main.select_space_toast"] = "الرجاء اختيار مساحة للمتابعة.",
["main.user_space_item"] = "مستخدم %s  —  %s",
["main.permission_error_title"] = "خطأ في الأذونات",
["main.permission_error_msg"] = "تم رفض الوصول إلى Shell.\n\nيحتاج Void إلى هذا لتحديد موقع HCR2 في مساحتك الافتراضية. تحقق من الكود المصدري لـ Void إذا أردت التحقق من الأمر الذي يتم تشغيله.",
["main.hcr2_not_found_title"] = "لم يتم العثور على بيانات HCR2",
["main.hcr2_not_found_msg"] = "تعذّر على Void تحديد موقع بيانات HCR2 في مساحتك الافتراضية. قد يحدث هذا إذا لم يتم تشغيل HCR2 بعد، أو إذا كان تطبيق المساحة الافتراضية يستخدم بنية مسار غير معتادة.\n\nالميزات التي تعتمد على ملفات اللعبة (مكافآت الأحداث، إلخ) لن تعمل بدون مسار صالح.",
["main.manual_data_path_title"] = "مسار البيانات اليدوي",
["main.manual_data_path_hint"] = "أدخل مسار بيانات HCR2",
["main.manual_path_cancelled"] = "تم الإلغاء — المتابعة بدون مسار.",
["main.waiting_for_lib"] = "جارٍ الانتظار لـ %s...",
["main.initialized"] = "تمت التهيئة",
["main.gamestatus_not_found"] = "لم يتم العثور على GameStatus",
["main.dont_interrupt"] = "لا تقاطع هذا السكريبت",

-- ── ui/ui.lua (framework chrome: menu, cards, dialogs) ────────────────────────
["ui.size_saved_restart"] = "تم حفظ الحجم! أعد تشغيل السكريبت",
["ui.category_error"] = "خطأ: %s",
["ui.category_not_found"] = "الفئة غير موجودة",
["ui.na"] = "غ/م",
["ui.spinner_select"] = "اختر",
["ui.slider_default_title"] = "القيمة",
["ui.loading"] = "جارٍ التحميل",

-- ── core/engines/patches.lua (addArchModule patch engine) ────────────────────
["patches.requires_arch"] = "يتطلب جهاز %s (جهازك: %s)",
["patches.suffix_enabled"] = " مفعّل",
["patches.suffix_disabled"] = " معطّل",
["patches.pattern_not_found"] = "فشل: %d نمط/أنماط غير موجودة",

-- ── core/engines/arch.lua (architecture detection warnings) ──────────────────
["arch.warning_title"] = "تحذير المعمارية",
["arch.unknown_arch_msg"] = "المعمارية غير معروفة. هل تم تحميل المكتبة؟ ما النظام الذي تستخدمه؟",
["arch.non_primary_arch_msg"] = "تم الاكتشاف: %s\nبعض أو كل تصحيحات المكتبة قد لا تعمل.",
["arch.unknown_version_msg"] = "إصدار اللعبة غير معروف. حاول مرة أخرى بعد تحميل اللعبة.",
["arch.no_base_data_msg"] = "خطأ داخلي: لا تتوفر بيانات أساسية لهذه المعمارية.",

-- ── core/engines/scheduler.lua ────────────────────────────────────────────────
["scheduler.task_crashed"] = "تحذير المجدول: تعطّلت المهمة -> %s",

-- ── core/utils/paste.lua + catbox.lua (network error strings) ────────────────
["errors.http_error_code"] = "رمز خطأ HTTP: %s",
["errors.crashed"] = "تعطّل: %s",
["errors.url_missing"] = "معامل URL مفقود أو فارغ",
["errors.file_path_missing"] = "مسار الملف مفقود",
["errors.download_url_missing"] = "URL مفقود",
["errors.dest_path_missing"] = "مسار الوجهة مفقود",

-- ── modules/registry.lua (sidebar tab labels + module-load error cards) ──────
["tabs.sep_game"] = "قائمة اللعبة",
["tabs.account"] = "قائمة الحساب",
["tabs.vehicle"] = "قائمة المركبة",
["tabs.player"] = "قائمة اللاعب",
["tabs.adventure"] = "قائمة المغامرة",
["tabs.cups"] = "قائمة الكؤوس",
["tabs.team"] = "قائمة الفريق",
["tabs.event"] = "قائمة الأحداث",
["tabs.creative"] = "القائمة الإبداعية",
["tabs.shop"] = "قائمة المتجر",
["tabs.other"] = "قائمة أخرى",
["tabs.sep_script"] = "قائمة السكريبت",
["tabs.settings"] = "الإعدادات",
["tabs.about"] = "حول",

["registry.module_load_failed"] = "فشل تحميل الوحدة. تحقق من السجلات للتفاصيل.",
["registry.module_runtime_error"] = "خطأ وقت التشغيل: %s",
["registry.error"] = "خطأ",

-- ── modules/tabs/settings.lua ─────────────────────────────────────────────────
["settings.section_updates"] = "التحديثات",
["settings.auto_update.title"] = "التحديث التلقائي",
["settings.auto_update.desc"] = "تحديث VOID تلقائيًا عند بدء التشغيل",
["settings.dev_mode_title"] = "وضع المطور",
["settings.auto_update.dev_mode_msg"] = "التحديث التلقائي معطّل لـ main.lua (بناء تطوير).",
["settings.check_updates.title"] = "التحقق من التحديثات",
["settings.check_updates.desc"] = "التحقق من أحدث إصدار VOID على GitHub",
["settings.check_updates.dev_mode_msg"] = "التحقق من التحديثات معطّل لـ main.lua (بناء تطوير).\n\nاسحب من المستودع يدويًا.",
["settings.check_updates.checking"] = "جارٍ التحقق من التحديثات...",
["settings.check_updates.failed_title"] = "فشل التحقق من التحديثات",
["settings.check_updates.failed_msg"] = "تعذّر الوصول إلى GitHub:\n%s",
["settings.check_updates.up_to_date_title"] = "محدّث",
["settings.check_updates.up_to_date_msg"] = "أنت بالفعل على أحدث إصدار (v%s).",
["settings.check_updates.no_changelog"] = "لا يوجد سجل تغييرات متاح.",
["settings.check_updates.available_msg"] = "v%s  (الحالي: v%s)\n\n%s\n\nتنزيل واستبدال هذا السكريبت؟",
["settings.check_updates.no_asset_msg"] = "لم يتم العثور على ملف .lua في الإصدار.",
["settings.check_updates.download_failed_title"] = "فشل التنزيل",
["settings.check_updates.write_failed_title"] = "فشل الكتابة",
["settings.check_updates.done_title"] = "تم",
["settings.check_updates.done_msg"] = "تم التحديث إلى v%s. أعد تشغيل السكريبت للتطبيق.",
["settings.check_updates.restart_button"] = "إعادة التشغيل",

["settings.section_language"] = "اللغة",
["settings.language.title"] = "اللغة",
["settings.language.desc"] = "اختر لغتك المفضلة للقائمة",
["settings.language.changed"] = "تم تعيين اللغة إلى %s",
["settings.language.failed"] = "فشل تحميل تلك اللغة",
["settings.language.restart_msg"] = "أعد تشغيل السكريبت لتطبيق اللغة بالكامل",

["settings.region.other"] = "أ: أخرى",
["settings.region.cpp_alloc"] = "Ca: تخصيص C++",
["settings.region.unknown"] = "غ: غير معروف",
["settings.section_memory"] = "الذاكرة",
["settings.memory_range.title"] = "نطاق الذاكرة",
["settings.memory_range.desc"] = "نطاق الذاكرة المحدد حاليًا\n(يُختار تلقائيًا بواسطة السكريبت)",
["settings.gamestatus.title"] = "GameStatus",
["settings.gamestatus.desc"] = "عنوان GameStatus الحالي\n(يُختار تلقائيًا بواسطة السكريبت)",
["settings.gamestatus_raw.title"] = "GameStatus (خام)",
["settings.gamestatus_raw.desc"] = "عنوان GameStatus (الخام) الحالي\n(يُختار تلقائيًا بواسطة السكريبت)",
["settings.clear_memory.title"] = "مسح الذاكرة المحفوظة",
["settings.clear_memory.desc"] = "مسح كل ذاكرة VOID المحفوظة دون الحاجة إلى إعادة تشغيل اللعبة بأكملها.",

["settings.section_ui_customizations"] = "تخصيصات الواجهة",
["settings.theme_store.title"] = "متجر الثيمات",
["settings.theme_store.desc"] = "تصفح وتثبيت ثيمات Void المجتمعية",
["settings.theme_store.unreachable_msg"] = "تعذّر الوصول إلى متجر الثيمات:\n%s",
["settings.theme_store.parse_failed_msg"] = "تعذّر تحليل بيانات متجر الثيمات.",
["settings.theme_store.list_title"] = "متجر ثيمات Void",
["settings.theme_store.search_results_desc"] = "نتائج البحث: %s موجودة",
["settings.theme_store.available_desc"] = "%s ثيمات متاحة",
["settings.theme_store.by_author"] = "بواسطة %s",
["settings.theme_store.search_item"] = "🔍 بحث...",
["settings.theme_store.clear_search_item"] = "✕ مسح البحث",
["settings.theme_store.search_title"] = "بحث في الثيمات",
["settings.theme_store.search_hint"] = "اسم الثيم أو المؤلف أو الوصف",
["settings.theme_store.no_results"] = "لم يتم العثور على ثيمات لـ: %s",
["settings.theme_store.detail_msg"] = "بواسطة %s\n\n%s\n\nالمعرّف: %s",
["settings.theme_store.install_button"] = "تثبيت الثيم",
["settings.theme_downloading_bg"] = "جارٍ تنزيل صورة الخلفية...",
["settings.theme_imported"] = "تم استيراد الثيم!",
["settings.theme_invalid_bundle"] = "تنسيق الحزمة غير صالح.",
["settings.theme_cloud_error"] = "خطأ سحابي: %s",
["settings.reset_theme.title"] = "إعادة تعيين الثيم",
["settings.reset_theme.desc"] = "إعادة تعيين الثيم المخصص وصورة الخلفية إلى الافتراضي",
["settings.import_theme.title"] = "استيراد ثيم",
["settings.import_theme.desc"] = "استيراد ثيم مخصص من السحابة",
["settings.import_theme.hint"] = "أدخل معرّف المشاركة",
["settings.export_theme.title"] = "تصدير ثيم",
["settings.export_theme.desc"] = "تصدير الثيم المخصص وصورة الخلفية إلى السحابة",
["settings.export_theme.share_id_msg"] = "معرّف المشاركة: %s\n\nتم النسخ إلى الحافظة.",
["settings.export_theme.upload_failed_msg"] = "فشل الرفع: %s",
["settings.export_theme.size_warning_title"] = "تحذير حجم الرفع",
["settings.export_theme.size_warning_msg"] = "هل تريد تضمين صورة الخلفية المخصصة؟ سيزيد ذلك من حجم الرفع اعتمادًا على حجم الصورة.",
["settings.export_theme.uploading_bg"] = "جارٍ رفع صورة الخلفية إلى Catbox...",
["settings.export_theme.image_upload_failed_title"] = "خطأ",
["settings.export_theme.image_upload_failed_msg"] = "فشل رفع الصورة: %s",
["settings.tabs_icon.title"] = "أيقونة التبويبات",
["settings.tabs_icon.desc"] = "تغيير أيقونة التبويبات",
["settings.tabs_icon.hint"] = "أدخل الأيقونة",
["settings.tabs_icon.empty_error"] = "لا يمكن أن يكون فارغًا",

["settings.bg_opacity.title"] = "شفافية الخلفية",
["settings.bg_opacity.desc"] = "شفافية اللوحات والبطاقات والرأس",
["settings.slider.alpha"] = "ألفا",
["settings.bg_image_opacity.title"] = "شفافية صورة الخلفية",
["settings.bg_image_opacity.desc"] = "ضبط إعدادات ألفا للرؤية مباشرةً باستخدام قنوات صحيحة خالصة.",
["settings.bg_image_picker.title"] = "صورة الخلفية",
["settings.bg_image_picker.desc"] = "اضغط لتعديل مسار الملف المطلق لصورة الخلفية المخصصة",
["settings.bg_image_picker.path_label"] = "مسار ملف الصورة المطلق (.jpg أو .png):",
["settings.bg_image_picker.remove_label"] = "إزالة صورة الخلفية",
["settings.bg_image_picker.success_title"] = "بنجاح",
["settings.bg_image_picker.removed_msg"] = "تمت إزالة صورة الخلفية",
["settings.bg_image_picker.added_msg"] = "تمت إضافة صورة الخلفية",
["settings.bg_image_picker.not_found_msg"] = "الملف غير موجود أو تم رفض عملية القراءة:\n%s",

["settings.bg_rgb.title"] = "خلفية RGB",
["settings.bg_rgb.desc"] = "تدرج لخلفيات اللوحات (الرأس والبطاقة تتكيف تلقائيًا)",
["settings.slider.r"] = "R",
["settings.slider.g"] = "G",
["settings.slider.b"] = "B",
["settings.accent_rgb.title"] = "تمييز RGB",
["settings.accent_rgb.desc"] = "تلوين للأزرار والتبديلات والبطاقات النشطة (اللون المكتوم يُشتق تلقائيًا)",
["settings.logo_rgb.title"] = "إبراز RGB",
["settings.logo_rgb.desc"] = "لون التسميات والأيقونات والنص التفاعلي (دائمًا معتم بالكامل)",
["settings.sub_rgb.title"] = "نص ثانوي RGB",
["settings.sub_rgb.desc"] = "لون الأوصاف وتسميات التبويبات غير النشطة",
["settings.text_rgb.title"] = "نص RGB",
["settings.text_rgb.desc"] = "لون نص القائمة الرئيسية",

["settings.win_width.title"] = "عرض القائمة",
["settings.win_width.desc"] = "عرض القائمة العائمة (%d – %d dp)",
["settings.slider.width"] = "العرض",
["settings.win_height.title"] = "ارتفاع القائمة",
["settings.win_height.desc"] = "ارتفاع منطقة المحتوى القابلة للتمرير (%d – %d dp)",
["settings.slider.height"] = "الارتفاع",

-- ── modules/tabs/about.lua ────────────────────────────────────────────────────
["about.about_script.title"] = "حول السكريبت",
["about.about_script.desc"] = "سكريبت قوي ومحسّن للغاية لمعالجة الذاكرة مبني لـ Hill Climb Racing 2 على بيئة Pivot المخصصة.\n\nتنزيل Pivot:\nhttps://github.com/vekendianorg/pivot/releases/",
["about.script_owner.title"] = "مالك السكريبت",
["about.script_owner.desc"] = "- Vekendian Organization (github: vekendianorg)",
["about.script_dev.title"] = "مطور السكريبت",
["about.script_dev.desc"] = [[
- Lazor (github: lazor-git)
- AMR (github: amr-gt)
- Erik (github: eomthix)
]],
["about.script_translator.title"] = "مترجم السكريبت",
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
["about.credits.title"] = "الشكر والتقدير",
["about.credits.desc"] = [[
- Lazor (github: lazor-git)
- Lan9118 (discord: lan9118)
- AMR (github: amr-gt)
- Erik (github: eomthix)
- Sr Romero
- Profinoobru
]],
["about.special_thanks.title"] = "شكر خاص",
["about.special_thanks.desc"] = [[
- Aryan/KokushiboModz
]],

-- ── modules/tabs/other.lua ────────────────────────────────────────────────────
["other.debug_mode.title"] = "وضع التصحيح",
["other.debug_mode.desc"] = "تبديل وضع التصحيح داخل اللعبة",
["other.debug_mode.enabled"] = "وضع التصحيح مفعّل",
["other.debug_mode.disabled"] = "وضع التصحيح معطّل",
["other.hint.width"] = "العرض",
["other.hint.height"] = "الارتفاع",
["other.resolution.title"] = "ضبط الدقة",
["other.resolution.desc"] = "ضبط عرض وارتفاع اللعبة (الافتراضي 1280x720)",
["other.resolution.applied"] = "تم تعيين الدقة إلى %dx%d",
["other.resolution_offset.title"] = "ضبط إزاحة الدقة",
["other.resolution_offset.desc"] = "ضبط إزاحة عرض وارتفاع اللعبة (الافتراضي 0x0)، الأفضل للدقة الصغيرة على شاشة كبيرة.",
["other.resolution_offset.applied"] = "تم تعيين إزاحة الدقة إلى %dx%d",
["other.glsurface_not_found"] = "لم يتم العثور على GLSurfaceView",

-- ── modules/tabs/shop.lua ─────────────────────────────────────────────────────
["shop.free_chest.title"] = "صندوق مجاني",
["shop.free_chest.desc"] = "اجعل الصناديق مجانية في تبويب المتجر",
["shop.free_chest.enabled"] = "الصندوق المجاني مفعّل",
["shop.free_chest.disabled"] = "الصندوق المجاني معطّل",
["shop.free_purchases.title"] = "مشتريات مجانية",
["shop.free_purchases.desc"] = "اجعل بعض عروض اليوم مجانية في تبويب المتجر (يعمل أيضًا للعروض الخاصة كنوافذ منبثقة/شارات)",
["shop.free_purchases.progress"] = "%d/%d",
["shop.free_purchases.success"] = "نجحت الشراء المجاني",
["shop.change_chest.title"] = "تغيير الصندوق",
["shop.change_chest.desc"] = "تغيير الصندوق الأسطوري إلى الصندوق المحدد",
["shop.change_chest.changed"] = "تم تغيير الصندوق إلى %s",
["shop.change_chest.options"] = {
    "صندوق عادي", "صندوق غير عادي", "صندوق نادر", "صندوق ملحمي",
    "صندوق البطل", "صندوق خاص 1", "صندوق عيد الميلاد", "صندوق أسطوري",
    "صندوق أزرق", "صندوق VIP 1", "صندوق VIP 2", "صندوق فيديو",
    "صندوق المبتدئين", "صندوق خاص 2", "صندوق Fingersoft", "صندوق ضخم",
    "صندوق روح الفريق", "صندوق الأناقة", "صندوق أسطوري"
},

-- ── modules/tabs/player.lua ───────────────────────────────────────────────────
["player.auto_detach.title"] = "فصل تلقائي",
["player.auto_detach.desc"] = "فصل الأجزاء تلقائيًا مثل سقف سيارة الرالي",
["player.auto_die.title"] = "موت تلقائي",
["player.auto_die.desc"] = "تسبب في الموت تلقائيًا (نفاد الوقود)",
["player.no_clip.title"] = "اختراق الجدران",
["player.no_clip.desc"] = "اجعل لاعبك يمر عبر الأجسام دون الموت (يمكنك تجاوز خطوط النهاية في الكؤوس)",
["player.no_clip.enabled"] = "اختراق الجدران مفعّل",
["player.no_clip.disabled"] = "اختراق الجدران معطّل",
["player.hide_name.title"] = "إخفاء الاسم",
["player.hide_name.desc"] = "إخفاء اسم لاعبك في السباق",
["player.hide_name.enabled"] = "إخفاء الاسم مفعّل",
["player.hide_name.disabled"] = "إخفاء الاسم معطّل",
["player.hide_flag.title"] = "إخفاء العلم",
["player.hide_flag.desc"] = "إخفاء علم لاعبك في السباق",
["player.hide_flag.enabled"] = "إخفاء العلم مفعّل",
["player.hide_flag.disabled"] = "إخفاء العلم معطّل",
["player.fuel.title"] = "الوقود",
["player.fuel.desc"] = "تثبيت الوقود على قيمة ثابتة أثناء السباق (0.0 – 100.0)",
["player.fuel.prompt_amount"] = "كمية الوقود (0 – 100)",
["player.fuel.prompt_reset"] = "إعادة تعيين",
["player.fuel.invalid"] = "قيمة غير صالحة، يجب أن تكون 0 – 100",
["player.fuel.applied"] = "تم تثبيت الوقود على %s",
["player.fuel.reset"] = "تم استعادة الوقود",
["player.fuel.not_applied"] = "الوقود غير نشط",
["player.zoom.title"] = "ضبط التكبير",
["player.zoom.desc"] = "ضبط مدى قرب أو بُعد الكاميرا",
["player.slider.min"] = "الحد الأدنى",
["player.slider.max"] = "الحد الأقصى",
["player.gravity.title"] = "ضبط الجاذبية",
["player.gravity.desc"] = "ضبط قوة الجاذبية",
["player.slider.x"] = "X",
["player.slider.y"] = "Y",

-- ── modules/tabs/adventure.lua ────────────────────────────────────────────────
["adventure.auto_adventure_chests.title"] = "صناديق المغامرة التلقائية (غير مستقرة)",
["adventure.auto_adventure_chests.desc"] = "رفع مستوى صناديق المغامرة تلقائيًا",
["adventure.auto_adventure_chests.none_found"] = "لم يتم العثور على صناديق مغامرة",
["adventure.auto_adventure_chests.done"] = "تم",

["adventure.set_distance.title"] = "تعيين المسافة",
["adventure.set_distance.desc"] = "تعيين مسافة سباق المغامرة إلى قيمة مخصصة. يجب أن تكون في سباق نشط. المسافة الأكبر تمنحك نجومًا أكثر. الحد الأقصى للنجوم عند 5000م. (ليست دالة نقل)",
["adventure.set_distance.loop_active_title"] = "تعيين المسافة — الحلقة نشطة",
["adventure.set_distance.loop_active_msg"] = "حلقة المسافة تعمل حاليًا.\nماذا تريد أن تفعل؟",
["adventure.set_distance.stop_loop"] = "إيقاف الحلقة",
["adventure.set_distance.keep_running"] = "الاستمرار في التشغيل",
["adventure.set_distance.loop_will_stop"] = "ستتوقف الحلقة بعد الدورة الحالية.",
["adventure.set_distance.prompt_target"] = "المسافة المستهدفة (بالأمتار)",
["adventure.set_distance.prompt_loop"] = "حلقة (إعادة تطبيق تلقائية)",
["adventure.set_distance.prompt_interval"] = "فترة الحلقة (مللي ثانية، الحد الأدنى 250)",
["adventure.set_distance.over_max_title"] = "تحذير المسافة",
["adventure.set_distance.over_max_msg"] = "المسافة فوق 5000م لن تمنحك أي نجوم.\n\nسيسجّل السباق المسافة، لكن لن تُمنح مكافآت النجوم. المتابعة؟",
["adventure.set_distance.continue_button"] = "متابعة",
["adventure.set_distance.not_in_adventure"] = "اذهب إلى تبويب المغامرة وابدأ سباقًا أولًا",
["adventure.set_distance.start_race_first"] = "ابدأ سباقًا أولًا",
["adventure.set_distance.applied"] = "تم تعيين المسافة: %sm",
["adventure.set_distance.loop_stopped"] = "تم إيقاف حلقة تعيين المسافة.",
["adventure.set_distance.loop_running"] = "حلقة المسافة تعمل — اضغط تعيين المسافة للإيقاف",
["adventure.set_distance.loop_warn_title"] = "تحذير حلقة المسافة",
["adventure.set_distance.loop_warn_msg"] = "وضع الحلقة يكتب في الذاكرة كل %s مللي ثانية.\n\nاستخدام فترة قصيرة قد يزيد من عدم الاستقرار أو التشوهات البصرية أو تعطل اللعبة.\n\nالمتابعة على أي حال؟",

-- ── modules/tabs/cups.lua ─────────────────────────────────────────────────────
["cups.adjust_countdown.title"] = "ضبط العد التنازلي",
["cups.adjust_countdown.desc"] = "ضبط العد التنازلي قبل بدء السباق",
["cups.slider.seconds"] = "ثوانٍ",
["cups.adjust_countdown.applied"] = "تم ضبط العد التنازلي إلى %sث",
["cups.auto_win.title"] = "فوز تلقائي",
["cups.auto_win.desc"] = "الفوز تلقائيًا بغض النظر عن نتيجة سباقك",
["cups.force_boss.title"] = "إجبار الزعيم",
["cups.force_boss.desc"] = "إجبار الزعيم على الظهور دائمًا",
["cups.force_cup.title"] = "إجبار الكأس",
["cups.force_cup.desc"] = "إجبار كأس واحدة",
["cups.force_cup.not_found"] = "لم يتم العثور على كأس. حاول مرة أخرى لاحقًا.",
["cups.force_cup.enabled"] = "الكأس الإجباري مفعّل",
["cups.force_cup.disabled"] = "الكأس الإجباري معطّل",
["cups.set_time.title"] = "تعيين الوقت",
["cups.set_time.desc"] = "تعيين وقت سباقك (لن يتم تجميد الوقت لأسباب أمان). يجب أن تكون في سباق كأس نشط. (مثال: 1:09.069، 7.284)",
["cups.set_time.hint"] = "الوقت (1:09.069 أو 7.284)",
["cups.set_time.invalid_format"] = "تنسيق غير صالح. استخدم 1:09.069 أو 7.284",
["cups.set_time.no_negative"] = "لا توجد قيم سالبة",
["cups.set_time.not_in_cup"] = "اذهب إلى تبويب الكؤوس وابدأ سباقًا أولًا",
["cups.set_time.start_race_first"] = "ابدأ سباقًا أولًا",
["cups.set_time.applied"] = "تم تعيين الوقت إلى %s",
["cups.unlimited_tasks.title"] = "مهام غير محدودة",
["cups.unlimited_tasks.desc"] = "تجميد جميع المهام كمكتملة وقابلة للمطالبة دائمًا. المطالبة بالمكافآت مرارًا.",
["cups.unlimited_tasks.resolve_failed"] = "فشل حل قائمة المهام",
["cups.unlimited_tasks.none_found"] = "لم يتم العثور على مهام",
["cups.unlimited_tasks.enabled"] = "المهام غير المحدودة مفعّلة",
["cups.unlimited_tasks.disabled"] = "المهام غير المحدودة معطّلة",
["cups.unlimited_tasks.none_to_freeze"] = "لا توجد مهام للتجميد",
["cups.rank_points_bonus.title"] = "+498 نقطة رتبة",
["cups.rank_points_bonus.desc"] = "اجعل جميع مهام الدوري تمنحك 498 نقطة بدلًا من 200 نقطة، مع إزالة المكافآت الأخرى.",
["cups.rank_points_bonus.none_found"] = "لم يتم العثور على مهام دوري",
["cups.rank_points_bonus.boosted"] = "نقاط الرتبة معززة: %s",
["cups.rank_points_bonus.no_match"] = "لم يتم العثور على مهام دوري مطابقة",
["cups.rank_points_bonus.nothing_to_restore"] = "لا يوجد شيء للاستعادة",
["cups.rank_points_bonus.restored"] = "تمت الاستعادة: %s",

-- ── modules/tabs/event.lua ────────────────────────────────────────────────────
["event.patch_rewards.title"] = "تصحيح مكافآت الحدث",
["event.patch_rewards.desc"] = "تصحيح مكافآت الحدث العام الحالي إلى مكافأة مخصصة مقدمة من VOID (يتطلب إعادة تشغيل اللعبة)",
["event.restore_events.title"] = "استعادة مكافآت الحدث",
["event.restore_events.desc"] = "حذف ملفات JSON المعدّلة لإجبار خادم اللعبة على الاستعادة (يتطلب إعادة تشغيل اللعبة)",

["event.checking_permissions"] = "جارٍ التحقق من أذونات البيئة...",
["event.scanning_files"] = "جارٍ فحص الملفات النشطة...",
["event.decode_rewards_failed"] = "فشل فك ترميز JSON المكافآت",
["event.workspace_creation_failed"] = "خطأ فادح: فشل إنشاء مساحة العمل: %s",
["event.workspace_creation_failed_dialog"] = "خطأ فادح: تعذّر إنشاء مجلد مساحة العمل.\n%s",
["event.file_inaccessible"] = "الملف غير قابل للوصول في المسار: %s",
["event.predecrypt_not_found"] = "ما قبل فك التشفير: المصدر غير موجود: %s",
["event.predecrypt_empty"] = "ما قبل فك التشفير: المصدر فارغ (0 بايت): %s",
["event.decode_active_failed"] = "فشل فك ترميز active_events.json في المسار: %s",
["event.no_active_events"] = "لم يتم العثور على أحداث نشطة في المسار: %s",
["event.cannot_open_active"] = "تعذّر فتح active_events.json في المسار: %s",
["event.decrypt_active_failed"] = "فشل فك تشفير active_events.json في المسار: %s",
["event.root_copy_failed"] = "فشل النسخ الجذري: %s",

["event.select_events_patch"] = "اختر الأحداث للتصحيح:\nالمسار: %s",
["event.user_cancelled"] = "ألغى المستخدم الاختيار للمسار: %s",
["event.rewards_unavailable"] = "المكافآت المدمجة غير متاحة، تجاوز التصحيحات للمسار: %s",
["event.skipped_unreadable"] = "تم تخطي الحدث غير القابل للقراءة: %s",
["event.predecrypt_event_not_found"] = "ما قبل فك التشفير: الحدث غير موجود: %s",
["event.predecrypt_event_empty"] = "ما قبل فك التشفير: الحدث فارغ (0 بايت): %s",
["event.processing_failed"] = "فشل معالجة %s: %s",
["event.cannot_open_decrypted"] = "تعذّر فتح الملف المفكوك تشفيره: %s",
["event.decrypt_event_failed"] = "فشل فك تشفير الحدث: %s",
["event.loop_crash"] = "تعطّل حلقة معالجة الملفات الحرجة: %s",

["event.success_header"] = "بنجاح:",
["event.success_removed_header"] = "تمت الإزالة بنجاح (ستُستعاد عند إعادة التشغيل):",
["event.success_item"] = "- %s",
["event.success_item_json"] = "- %s.json",
["event.failed_header"] = "فشل:",
["event.failed_item"] = "- %s",

["event.patch_results_title"] = "نتائج التصحيح",
["event.restore_results_title"] = "نتائج الاستعادة",
["event.restart_required_title"] = "إعادة التشغيل مطلوبة",
["event.patch_restart_msg"] = "تم إيقاف اللعبة وسيخرج هذا السكريبت، شغّله مرة أخرى وشاهد تأثيرات التصحيح",
["event.restore_restart_msg"] = "ستُغلق اللعبة الآن للسماح بمزامنة ملفات الخادم.",
["event.finishing_tasks_patch"] = "إنهاء المهام المعلّقة في الخلفية... يرجى الانتظار.",
["event.finishing_tasks_restore"] = "إنهاء المهام المعلّقة في الخلفية...",
["event.patch_failed_msg"] = "فشل التصحيح، حاول مرة أخرى.",

["event.select_events_restore"] = "اختر الملفات للاستعادة (الحذف):\nالمسار: %s",
["event.delete_failed"] = "فشل حذف %s: %s",

-- ── modules/tabs/account.lua ──────────────────────────────────────────────────
["account.change_name.title"] = "تغيير الاسم",
["account.change_name.desc"] = "تغيير اسم لاعبك",
["account.change_name.hint"] = "أدخل الاسم",
["account.change_name.empty"] = "أدخل اسمًا أولًا",
["account.change_name.too_long_title"] = "الاسم طويل جدًا",
["account.change_name.too_long_msg"] = "اسمك طويل جدًا، يرجى تقصيره",
["account.change_name.resolve_failed"] = "فشل حل مؤشر الاسم",
["account.change_name.applied"] = "تم تغيير الاسم إلى %s",

["account.change_gp.title"] = "تغيير قوة الكراج",
["account.change_gp.desc"] = "تغيير قوة كراج الملف الشخصي (تستمر إذا كانت أعلى). اضبط على 8 لإعادة التعيين إذا تجاوز الحد الأقصى، لكن فقط إذا كانت قوة الكراج الفعلية مثبّتة بالفعل تحت الحد.",
["account.change_gp.hint"] = "أدخل قوة الكراج",
["account.change_gp.max_int_title"] = "تم الوصول إلى الحد الأقصى لـ 32 بت",
["account.change_gp.lower_value"] = "يرجى تخفيض القيمة",
["account.change_gp.too_low_title"] = "منخفض جدًا",
["account.change_gp.higher_value"] = "يرجى رفع القيمة",
["account.change_gp.applied"] = "تم تغيير قوة الكراج إلى %s",

["account.fake_unlock.title"] = "فتح وهمي",
["account.fake_unlock.desc"] = "فتح جميع التخصيصات مؤقتًا",
["account.fake_vip.title"] = "VIP وهمي",
["account.fake_vip.desc"] = "تبديل حالة اشتراك VIP محليًا",
  
["account.fake_rank.title"] = "رتبة وهمية",
["account.fake_rank.desc"] = "تعيين رتبتك إلى أسطورية وهمية تلقائيًا",
["account.fake_rank.race_warn_title"] = "السباق مطلوب",
["account.fake_rank.race_warn_msg"] = "يجب تطبيق الرتبة الوهمية فقط أثناء سباق كؤوس نشط.\n\nتطبيقها خارج السباق قد يؤدي إلى حظر ظلي.\n\nتأكد من أنك بالفعل داخل سباق كؤوس قبل المتابعة.\n\nالمتابعة على أي حال؟",
["account.fake_rank.continue_button"] = "متابعة",

-- ── modules/tabs/vehicle.lua ──────────────────────────────────────────────────
["vehicle.parts_slot.title"] = "ضبط خانات الأجزاء",
["vehicle.parts_slot.desc"] = "ضبط خانات الأجزاء لجميع المركبات",
["vehicle.parts_slot.slider_title"] = "الخانات",
["vehicle.parts_slot.no_vehicles"] = "لم يتم العثور على مركبات",
["vehicle.parts_slot.applied"] = "تم ضبط خانات الأجزاء: %d مركبة",

["vehicle.parts_modifier.title"] = "معدل الأجزاء",
["vehicle.parts_modifier.desc"] = "تعديل مستويات أجزاء الضبط في السباق النشط",
["vehicle.parts_modifier.select"] = "اختر جزءًا",
["vehicle.parts_modifier.prompt_level"] = "المستوى: ",
["vehicle.parts_modifier.prompt_digit0"] = "الرقم: ",
["vehicle.parts_modifier.prompt_digit1"] = "الجزء الأخير: ",
["vehicle.parts_modifier.prompt_reset"] = "إعادة تعيين",
["vehicle.parts_modifier.invalid"] = "قيمة مستوى غير صالحة",
["vehicle.parts_modifier.not_found"] = "لم يتم العثور على الجزء في الذاكرة",
["vehicle.parts_modifier.applied"] = "تم تعيين %s إلى المستوى %s",
["vehicle.parts_modifier.reset"] = "تم إعادة تعيين %s",

["vehicle.unlock_vehicles.title"] = "فتح المركبات",
["vehicle.unlock_vehicles.desc"] = "فتح جميع المركبات لتكون متاحة للشراء بالعملات",
["vehicle.unlock_vehicles.no_vehicles"] = "لم يتم العثور على مركبات",
["vehicle.unlock_vehicles.unlocked"] = "تم فتح المركبات: %d",
["vehicle.unlock_vehicles.none_to_unlock"] = "لا توجد مركبات لفتحها",

["vehicle.max_vehicles.title"] = "الحد الأقصى للمركبات",
["vehicle.max_vehicles.desc"] = "رفع مستوى ترقيات جميع المركبات المفتوحة فوريًا",
["vehicle.max_vehicles.no_vehicles"] = "فشل حل قائمة المركبات",
["vehicle.max_vehicles.all_maxed"] = "تم رفع جميع المركبات إلى الحد الأقصى",
["vehicle.max_vehicles.failed"] = "فشل رفع المركبات إلى الحد الأقصى",

["vehicle.max_mastery.title"] = "الحد الأقصى للإتقان",
["vehicle.max_mastery.desc"] = "رفع إتقانات جميع المركبات المفتوحة والمحسّنة إلى الحد الأقصى فوريًا.",
["vehicle.max_mastery.all_maxed"] = "تم رفع جميع الإتقانات إلى الحد الأقصى",
["vehicle.max_mastery.failed"] = "فشل رفع الإتقانات إلى الحد الأقصى",

["vehicle.max_parts.title"] = "الحد الأقصى للأجزاء",
["vehicle.max_parts.desc"] = "رفع مستويات جميع الأجزاء المفتوحة لجميع المركبات فوريًا.",
["vehicle.max_parts.no_vehicles"] = "فشل حل قائمة المركبات",
["vehicle.max_parts.all_maxed"] = "تم رفع جميع الأجزاء إلى الحد الأقصى",
["vehicle.max_parts.failed"] = "فشل رفع الأجزاء إلى الحد الأقصى",

["vehicle.common.no_vehicles"] = "لم يتم العثور على مركبات",
["vehicle.common.progress"] = "%d/%d",
["vehicle.common.resolve_list_failed"] = "فشل حل قائمة المركبات",
["vehicle.common.no_zero_region"] = "لم يتم العثور على منطقة صفرية",

}
