--[[
  configs/lang/tr.lua — Türkçe (Turkish)

  Flat table of dotted keys -> strings, loaded by core/utils/lang.lua.
  Looked up at runtime via the global T(key, ...) function, e.g.:
      T("common.ok")                           -> "Tamam"
      T("settings.window_width_desc", 400, 650) -> "Menü genişliği (400 - 650 dp)"

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

  This file handles the Turkish localization for the VOID script.
]]

return {

-- ── Common / shared (buttons, generic dialog text) ───────────────────────────
["common.ok"] = "Tamam",
["common.cancel"] = "İptal",
["common.yes"] = "Evet",
["common.no"] = "Hayır",
["common.failed"] = "Başarısız",
["common.success"] = "Başarılı",
["common.later"] = "Sonra",
["common.got_it"] = "Anladım",
["common.retry"] = "Yeniden Dene",
["common.wait_safe"] = "Bekle (Güvenli)",
["common.waiting"] = "Bekleniyor...",
["common.force_exit"] = "Zorla Çık",
["common.proceed_anyway"] = "Yine de Devam Et",
["common.manual_mode"] = "Manuel Mod",
["common.update_button"] = "GÜNCELLE",
["common.launch_failed"] = "Başlatılamadı",
["common.confirm_exit_title"] = "Çıkışı Onayla",
["common.confirm_exit_msg"] = "Betikten Çıkılsın mı?",
["common.not_available"] = "Mevcut Değil",
["common.warning"] = "Uyarı",

-- ── main.lua (boot, updater, virtual-space detection, main loop) ─────────────
["main.exit_active_ops_title"] = "Uyarı: Aktif İşlemler",
["main.exit_active_ops_msg"] = "%d arka plan görevi çalışıyor.\nZorla çıkış oyun durumunu bozabilir.",
["main.initializing"] = "Başlatılıyor...",
["main.no_app_found"] = "Uygulama bulunamadı",
["main.arch_64bit_required_title"] = "64-bit Gerekli",
["main.arch_64bit_required_msg"] = "ARMv8a zorunludur. x86_64 kısmen desteklenir.",

["main.update_available_title"] = "Güncelleme Mevcut",
["main.update_available_msg"] = "v%s mevcut (mevcut: v%s)\n\n%s\n\nŞimdi güncellensin mi?",
["main.no_changelog"] = "Değişiklik günlüğü yok.",
["main.downloading_version"] = "v%s indiriliyor...",
["main.update_download_failed_msg"] = "Güncelleme indirilemedi:\n%s",
["main.update_write_failed_msg"] = "Yazılamadı:\n%s",
["main.update_done_title"] = "VOID v%s sürümüne güncellendi",
["main.update_done_msg"] = "VOID başarıyla güncellendi.\n\nYeni betik şuraya kaydedildi:\nvoid_v%s.lua\n\nGüncellemeyi uygulamak için GameGuardian'dan çalıştırın.",
["main.launching_version"] = "v%s başlatılıyor...",
["main.launch_failed_msg"] = "İndirildi ancak çalıştırılamadı:\n%s",

["main.multiple_spaces_title"] = "Birden Fazla Alan Algılandı",
["main.multiple_spaces_desc"] = "HCR2 %d sanal alanda bulundu.\nŞu anda oynadığınız alanı seçin.",
["main.select_space_toast"] = "Devam etmek için bir alan seçin.",
["main.user_space_item"] = "Kullanıcı %s  —  %s",
["main.permission_error_title"] = "İzin Hatası",
["main.permission_error_msg"] = "Shell erişimi reddedildi.\n\nVoid, HCR2'yi sanal alanınızda bulmak için buna ihtiyaç duyar. Hangi komutun çalıştırıldığını doğrulamak istiyorsanız Void kaynak kodunu kontrol edin.",
["main.hcr2_not_found_title"] = "HCR2 Verileri Bulunamadı",
["main.hcr2_not_found_msg"] = "Void, HCR2 verilerinizi sanal alanınızda bulamadı. Bu, HCR2 henüz başlatılmadıysa veya sanal alan uygulamanız alışılmadık bir yol yapısı kullanıyorsa olabilir.\n\nOyun dosyalarına bağlı özellikler (Etkinlik Ödülleri vb.) geçerli bir yol olmadan çalışmaz.",
["main.manual_data_path_title"] = "Manuel Veri Yolu",
["main.manual_data_path_hint"] = "HCR2 veri yolunu girin",
["main.manual_path_cancelled"] = "İptal edildi — yolsuz devam ediliyor.",
["main.waiting_for_lib"] = "%s bekleniyor...",
["main.initialized"] = "Başlatıldı",
["main.gamestatus_not_found"] = "GameStatus Bulunamadı",
["main.dont_interrupt"] = "Bu betiği kesmeyin",

-- ── ui/ui.lua (framework chrome: menu, cards, dialogs) ────────────────────────
["ui.size_saved_restart"] = "Boyut kaydedildi! Betiği yeniden başlatın",
["ui.category_error"] = "Hata: %s",
["ui.category_not_found"] = "Kategori Bulunamadı",
["ui.na"] = "Yok",
["ui.spinner_select"] = "Seç",
["ui.slider_default_title"] = "Değer",
["ui.loading"] = "Yükleniyor",

-- ── core/engines/patches.lua (addArchModule patch engine) ────────────────────
["patches.requires_arch"] = "%s cihaz gerektirir (cihazınız: %s)",
["patches.suffix_enabled"] = " Etkin",
["patches.suffix_disabled"] = " Devre Dışı",
["patches.pattern_not_found"] = "Başarısız: %d kalıp bulunamadı",

-- ── core/engines/arch.lua (architecture detection warnings) ──────────────────
["arch.warning_title"] = "Mimari Uyarısı",
["arch.unknown_arch_msg"] = "Mimariniz bilinmiyor. Kütüphane yüklendi mi? Hangi sistemi kullanıyorsunuz?",
["arch.non_primary_arch_msg"] = "Algılandı: %s\nBazı veya tüm kütüphane yamaları çalışmayabilir.",
["arch.unknown_version_msg"] = "Oyun sürümü bilinmiyor. Oyun yüklendikten sonra tekrar deneyin.",
["arch.no_base_data_msg"] = "Dahili hata: bu mimari için temel veri mevcut değil.",

-- ── core/engines/scheduler.lua ────────────────────────────────────────────────
["scheduler.task_crashed"] = "Zamanlayıcı Uyarısı: Görev çöktü -> %s",

-- ── core/utils/paste.lua + catbox.lua (network error strings) ────────────────
["errors.http_error_code"] = "HTTP Hata Kodu: %s",
["errors.crashed"] = "Çöktü: %s",
["errors.url_missing"] = "URL parametresi eksik veya boş",
["errors.file_path_missing"] = "Dosya yolu eksik",
["errors.download_url_missing"] = "URL eksik",
["errors.dest_path_missing"] = "Hedef yol eksik",

-- ── modules/registry.lua (sidebar tab labels + module-load error cards) ──────
["tabs.sep_game"] = "OYUN MENÜSÜ",
["tabs.account"] = "HESAP MENÜSÜ",
["tabs.vehicle"] = "ARAÇ MENÜSÜ",
["tabs.player"] = "OYUNCU MENÜSÜ",
["tabs.adventure"] = "MACERA MENÜSÜ",
["tabs.cups"] = "KUPALAR MENÜSÜ",
["tabs.team"] = "TAKIM MENÜSÜ",
["tabs.event"] = "ETKİNLİK MENÜSÜ",
["tabs.creative"] = "YARATICI MENÜ",
["tabs.shop"] = "MAĞAZA MENÜSÜ",
["tabs.other"] = "DİĞER MENÜ",
["tabs.sep_script"] = "BETİK MENÜSÜ",
["tabs.settings"] = "AYARLAR",
["tabs.about"] = "HAKKINDA",

["registry.module_load_failed"] = "Modül yüklenemedi. Ayrıntılar için günlükleri kontrol edin.",
["registry.module_runtime_error"] = "Çalışma zamanı hatası: %s",
["registry.error"] = "Hata",

-- ── modules/tabs/settings.lua ─────────────────────────────────────────────────
["settings.section_updates"] = "Güncellemeler",
["settings.auto_update.title"] = "Otomatik Güncelleme",
["settings.auto_update.desc"] = "Başlangıçta VOID'i otomatik güncelle",
["settings.dev_mode_title"] = "Geliştirici Modu",
["settings.auto_update.dev_mode_msg"] = "main.lua için otomatik güncelleme devre dışı (geliştirici yapısı).",
["settings.check_updates.title"] = "Güncellemeleri Kontrol Et",
["settings.check_updates.desc"] = "GitHub'daki en son VOID sürümünü kontrol et",
["settings.check_updates.dev_mode_msg"] = "main.lua için güncelleme kontrolü devre dışı (geliştirici yapısı).\n\nManuel olarak depodan çekin.",
["settings.check_updates.checking"] = "Güncellemeler kontrol ediliyor...",
["settings.check_updates.failed_title"] = "Güncelleme Kontrolü Başarısız",
["settings.check_updates.failed_msg"] = "GitHub'a ulaşılamadı:\n%s",
["settings.check_updates.up_to_date_title"] = "Güncel",
["settings.check_updates.up_to_date_msg"] = "Zaten en son sürümdesiniz (v%s).",
["settings.check_updates.no_changelog"] = "Değişiklik günlüğü mevcut değil.",
["settings.check_updates.available_msg"] = "v%s  (mevcut: v%s)\n\n%s\n\nBu betik indirilip değiştirilsin mi?",
["settings.check_updates.no_asset_msg"] = "Sürümde .lua varlığı bulunamadı.",
["settings.check_updates.download_failed_title"] = "İndirme Başarısız",
["settings.check_updates.write_failed_title"] = "Yazma Başarısız",
["settings.check_updates.done_title"] = "Tamamlandı",
["settings.check_updates.done_msg"] = "v%s sürümüne güncellendi. Uygulamak için betiği yeniden başlatın.",
["settings.check_updates.restart_button"] = "Yeniden Başlat",

["settings.section_language"] = "Dil",
["settings.language.title"] = "Dil",
["settings.language.desc"] = "Menü için tercih ettiğiniz dili seçin",
["settings.language.changed"] = "Dil %s olarak ayarlandı",
["settings.language.failed"] = "Bu dil yüklenemedi",
["settings.language.restart_msg"] = "Dili tamamen uygulamak için betiği yeniden başlatın",

["settings.region.other"] = "D: Diğer",
["settings.region.cpp_alloc"] = "Ca: C++ tahsisi",
["settings.region.unknown"] = "B: Bilinmiyor",
["settings.section_memory"] = "Bellek",
["settings.memory_range.title"] = "Bellek Aralığı",
["settings.memory_range.desc"] = "Geçerli seçili bellek aralığı\n(betik tarafından otomatik seçilir)",
["settings.gamestatus.title"] = "GameStatus",
["settings.gamestatus.desc"] = "Geçerli gamestatus adresi\n(betik tarafından otomatik seçilir)",
["settings.gamestatus_raw.title"] = "GameStatus (Ham)",
["settings.gamestatus_raw.desc"] = "Geçerli gamestatus (ham) adresi\n(betik tarafından otomatik seçilir)",
["settings.clear_memory.title"] = "Kaydedilmiş Belleği Temizle",
["settings.clear_memory.desc"] = "Oyunu yeniden başlatmaya gerek kalmadan VOID'in kaydedilmiş tüm belleğini temizleyin.",

["settings.section_ui_customizations"] = "Arayüz Özelleştirmeleri",
["settings.theme_store.title"] = "Tema Mağazası",
["settings.theme_store.desc"] = "Topluluk Void temalarına göz atın ve yükleyin",
["settings.theme_store.unreachable_msg"] = "Tema mağazasına ulaşılamadı:\n%s",
["settings.theme_store.parse_failed_msg"] = "Tema mağazası verileri ayrıştırılamadı.",
["settings.theme_store.list_title"] = "Void Tema Mağazası",
["settings.theme_store.search_results_desc"] = "Arama sonuçları: %s bulundu",
["settings.theme_store.available_desc"] = "%s tema mevcut",
["settings.theme_store.by_author"] = "%s tarafından",
["settings.theme_store.search_item"] = "🔍 Ara...",
["settings.theme_store.clear_search_item"] = "✕ Aramayı temizle",
["settings.theme_store.search_title"] = "Tema Ara",
["settings.theme_store.search_hint"] = "Tema adı, yazar veya açıklama",
["settings.theme_store.no_results"] = "%s için tema bulunamadı",
["settings.theme_store.detail_msg"] = "%s tarafından\n\n%s\n\nKimlik: %s",
["settings.theme_store.install_button"] = "Temayı Yükle",
["settings.theme_downloading_bg"] = "Arka plan görseli indiriliyor...",
["settings.theme_imported"] = "Tema içe aktarıldı!",
["settings.theme_invalid_bundle"] = "Geçersiz paket biçimi.",
["settings.theme_cloud_error"] = "Bulut hatası: %s",
["settings.reset_theme.title"] = "Temayı Sıfırla",
["settings.reset_theme.desc"] = "Özel temayı ve arka plan görselini varsayılana sıfırla",
["settings.import_theme.title"] = "Tema İçe Aktar",
["settings.import_theme.desc"] = "Buluttan özel tema içe aktar",
["settings.import_theme.hint"] = "Paylaşım Kimliğini Girin",
["settings.export_theme.title"] = "Tema Dışa Aktar",
["settings.export_theme.desc"] = "Özel temayı ve arka plan görselini buluta dışa aktar",
["settings.export_theme.share_id_msg"] = "Paylaşım Kimliği: %s\n\nPanoya kopyalandı.",
["settings.export_theme.upload_failed_msg"] = "Yükleme başarısız: %s",
["settings.export_theme.size_warning_title"] = "Yükleme Boyutu Uyarısı",
["settings.export_theme.size_warning_msg"] = "Özel arka plan görseli dahil edilsin mi? Bu, görselinizin boyutuna bağlı olarak Yükleme Boyutunu artıracaktır.",
["settings.export_theme.uploading_bg"] = "Catbox'a arka plan görseli yükleniyor...",
["settings.export_theme.image_upload_failed_title"] = "Hata",
["settings.export_theme.image_upload_failed_msg"] = "Görsel yüklemesi başarısız: %s",
["settings.tabs_icon.title"] = "Sekme Simgesi",
["settings.tabs_icon.desc"] = "Sekme simgesini değiştir",
["settings.tabs_icon.hint"] = "Simge Girin",
["settings.tabs_icon.empty_error"] = "Boş olamaz",

["settings.bg_opacity.title"] = "Arka Plan Opaklığı",
["settings.bg_opacity.desc"] = "Panellerin, kartların ve başlığın saydamlığı",
["settings.slider.alpha"] = "Alfa",
["settings.bg_image_opacity.title"] = "Arka Plan Görseli Opaklığı",
["settings.bg_image_opacity.desc"] = "Görünürlük alfa ayarlarını doğrudan saf tamsayı kanallarını kullanarak ayarlayın.",
["settings.bg_image_picker.title"] = "Arka Plan Görseli",
["settings.bg_image_picker.desc"] = "Özel düzen arka plan görseliniz için mutlak dosya yolunu değiştirmek için dokunun",
["settings.bg_image_picker.path_label"] = "Mutlak Görsel Dosya Yolu (.jpg veya .png):",
["settings.bg_image_picker.remove_label"] = "Arka Plan Görselini Kaldır",
["settings.bg_image_picker.success_title"] = "Başarılı",
["settings.bg_image_picker.removed_msg"] = "Arka Plan Görseli Kaldırıldı",
["settings.bg_image_picker.added_msg"] = "Arka plan görseli eklendi",
["settings.bg_image_picker.not_found_msg"] = "Dosya bulunamadı veya okuma işlemi reddedildi:\n%s",

["settings.bg_rgb.title"] = "Arka Plan RGB",
["settings.bg_rgb.desc"] = "Panel arka planları için renk tonu (Başlık ve Kart otomatik ölçeklenir)",
["settings.slider.r"] = "R",
["settings.slider.g"] = "G",
["settings.slider.b"] = "B",
["settings.accent_rgb.title"] = "Vurgu RGB",
["settings.accent_rgb.desc"] = "Düğmeler, anahtarlar ve aktif kartlar için renk tonu (loş renk otomatik türetilir)",
["settings.logo_rgb.title"] = "Vurgulama RGB",
["settings.logo_rgb.desc"] = "Etiketler, simgeler ve etkileşimli metin için renk (her zaman tamamen opak)",
["settings.sub_rgb.title"] = "Alt metin RGB",
["settings.sub_rgb.desc"] = "Açıklamalar ve etkin olmayan sekme etiketleri için renk",
["settings.text_rgb.title"] = "Metin RGB",
["settings.text_rgb.desc"] = "Ana menü metni için renk",

["settings.win_width.title"] = "Menü Genişliği",
["settings.win_width.desc"] = "Yüzen menü genişliği (%d – %d dp)",
["settings.slider.width"] = "Genişlik",
["settings.win_height.title"] = "Menü Yüksekliği",
["settings.win_height.desc"] = "Kaydırılabilir içerik alanının yüksekliği (%d – %d dp)",
["settings.slider.height"] = "Yükseklik",

-- ── modules/tabs/about.lua ────────────────────────────────────────────────────
["about.about_script.title"] = "Betik Hakkında",
["about.about_script.desc"] = "Hill Climb Racing 2 için özel Pivot ortamında oluşturulmuş güçlü ve son derece optimize edilmiş bir bellek manipülasyon betiği.\n\nPivot'u İndir:\nhttps://github.com/vekendianorg/pivot/releases/",
["about.script_owner.title"] = "Betik Sahibi",
["about.script_owner.desc"] = "- Vekendian Organization (github: vekendianorg)",
["about.script_dev.title"] = "Betik Geliştiricisi",
["about.script_dev.desc"] = [[
- Lazor (github: lazor-git)
- AMR (github: amr-gt)
- Erik (github: eomthix)
]],
["about.script_translator.title"] = "Betik Çevirmeni",
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
]],
["about.credits.title"] = "Katkıda Bulunanlar",
["about.credits.desc"] = [[
- Lazor (github: lazor-git)
- Lan9118 (discord: lan9118)
- AMR (github: amr-gt)
- Erik (github: eomthix)
- Sr Romero
- Profinoobru
]],
["about.special_thanks.title"] = "Özel Teşekkürler",
["about.special_thanks.desc"] = [[
- Aryan/KokushiboModz
]],

-- ── modules/tabs/other.lua ────────────────────────────────────────────────────
["other.debug_mode.title"] = "Hata Ayıklama Modu",
["other.debug_mode.desc"] = "Oyundaki hata ayıklama modunu aç/kapat",
["other.debug_mode.enabled"] = "Hata Ayıklama Modu Etkin",
["other.debug_mode.disabled"] = "Hata Ayıklama Modu Devre Dışı",
["other.hint.width"] = "Genişlik",
["other.hint.height"] = "Yükseklik",
["other.resolution.title"] = "Çözünürlüğü Ayarla",
["other.resolution.desc"] = "Oyun genişliğini ve yüksekliğini ayarlayın (varsayılan 1280x720)",
["other.resolution.applied"] = "Çözünürlük %dx%d olarak ayarlandı",
["other.resolution_offset.title"] = "Çözünürlük Ofsetini Ayarla",
["other.resolution_offset.desc"] = "Oyun genişlik ofsetini ve yükseklik ofsetini ayarlayın (varsayılan 0x0), büyük ekranda küçük çözünürlük için en iyisidir.",
["other.resolution_offset.applied"] = "Çözünürlük ofseti %dx%d olarak ayarlandı",
["other.glsurface_not_found"] = "GLSurfaceView bulunamadı",

-- ── modules/tabs/shop.lua ─────────────────────────────────────────────────────
["shop.free_chest.title"] = "Ücretsiz Sandık",
["shop.free_chest.desc"] = "Mağaza Sekmesindeki sandıkları ücretsiz yap",
["shop.free_chest.enabled"] = "Ücretsiz Sandık Etkin",
["shop.free_chest.disabled"] = "Ücretsiz Sandık Devre Dışı",
["shop.free_purchases.title"] = "Ücretsiz Satın Alımlar",
["shop.free_purchases.desc"] = "Mağaza sekmesindeki bazı günlük fırsatları ücretsiz yap (açılır pencereler/rozetler olarak özel teklifler için de çalışır)",
["shop.free_purchases.progress"] = "%d/%d",
["shop.free_purchases.success"] = "Ücretsiz Satın Alma Başarılı",
["shop.change_chest.title"] = "Sandığı Değiştir",
["shop.change_chest.desc"] = "Efsanevi sandığı seçilen sandıkla değiştir",
["shop.change_chest.changed"] = "Sandık %s olarak değiştirildi",
["shop.change_chest.options"] = {
    "Ortak Sandık", "Sıradışı Sandık", "Nadir Sandık", "Destansı Sandık",
    "Şampiyon Sandığı", "Özel Sandık 1", "Noel Sandığı", "Efsanevi Sandık",
    "Mavi Sandık", "VIP Sandık 1", "VIP Sandık 2", "Video Sandığı",
    "Başlangıç Sandığı", "Özel Sandık 2", "Fingersoft Sandığı", "Mega Sandık",
    "Takım Ruhu Sandığı", "Stil Sandığı", "Mitik Sandık"
},

-- ── modules/tabs/player.lua ───────────────────────────────────────────────────
["player.auto_detach.title"] = "Otomatik Ayırma",
["player.auto_detach.desc"] = "Ralli Arabasının tavanı gibi parçaları otomatik olarak ayır",
["player.auto_die.title"] = "Otomatik Ölüm",
["player.auto_die.desc"] = "Otomatik olarak ölüme neden ol (yakıt bitti)",
["player.no_clip.title"] = "No-Clip",
["player.no_clip.desc"] = "Oyuncunuzun nesnelerin arasından ölmeden geçmesini sağlayın (Kupalarda bitiş çizgilerinin üzerinden gidebilirsiniz)",
["player.no_clip.enabled"] = "No-Clip Etkin",
["player.no_clip.disabled"] = "No-Clip Devre Dışı",
["player.hide_name.title"] = "Adı Gizle",
["player.hide_name.desc"] = "Yarışta oyuncu adınızı gizleyin",
["player.hide_name.enabled"] = "Adı Gizle Etkin",
["player.hide_name.disabled"] = "Adı Gizle Devre Dışı",
["player.hide_flag.title"] = "Bayrağı Gizle",
["player.hide_flag.desc"] = "Yarışta oyuncu bayrağınızı gizleyin",
["player.hide_flag.enabled"] = "Bayrağı Gizle Etkin",
["player.hide_flag.disabled"] = "Bayrağı Gizle Devre Dışı",
["player.fuel.title"] = "Yakıt",
["player.fuel.desc"] = "Yarış sırasında yakıtı sabit bir değerde kilitle (0.0 – 100.0)",
["player.fuel.prompt_amount"] = "Yakıt miktarı (0 – 100)",
["player.fuel.prompt_reset"] = "Sıfırla",
["player.fuel.invalid"] = "Geçersiz değer, 0 – 100 arası olmalı",
["player.fuel.applied"] = "Yakıt %s olarak kilitlendi",
["player.fuel.reset"] = "Yakıt geri yüklendi",
["player.fuel.not_applied"] = "Yakıt aktif değil",
["player.zoom.title"] = "Yakınlaştırmayı Ayarla",
["player.zoom.desc"] = "Kameranızın ne kadar yakın veya uzak olduğunu ayarlayın",
["player.slider.min"] = "Min",
["player.slider.max"] = "Max",
["player.gravity.title"] = "Yerçekimini Ayarla",
["player.gravity.desc"] = "Yerçekiminin ne kadar güçlü olduğunu ayarlayın",
["player.slider.x"] = "X",
["player.slider.y"] = "Y",

-- ── modules/tabs/adventure.lua ────────────────────────────────────────────────
["adventure.auto_adventure_chests.title"] = "Otomatik Macera Sandıkları (kararsız)",
["adventure.auto_adventure_chests.desc"] = "Macera sandıklarınızı otomatik olarak seviye atlatın",
["adventure.auto_adventure_chests.none_found"] = "Macera sandığı bulunamadı",
["adventure.auto_adventure_chests.done"] = "Tamamlandı",

["adventure.set_distance.title"] = "Mesafeyi Ayarla",
["adventure.set_distance.desc"] = "Macera yarışı mesafenizi özel bir değere ayarlar. Aktif bir yarışta olmalısınız. Daha yüksek mesafe daha fazla yıldız kazanabilir. Maksimum yıldız 5000m'de. (Işınlanma işlevi değil)",
["adventure.set_distance.loop_active_title"] = "Mesafeyi Ayarla — Döngü Aktif",
["adventure.set_distance.loop_active_msg"] = "Mesafe döngüsü şu anda çalışıyor.\nNe yapmak istiyorsunuz?",
["adventure.set_distance.stop_loop"] = "Döngüyü Durdur",
["adventure.set_distance.keep_running"] = "Çalışmaya Devam Et",
["adventure.set_distance.loop_will_stop"] = "Döngü geçerli tikten sonra duracak.",
["adventure.set_distance.prompt_target"] = "Hedef mesafe (metre)",
["adventure.set_distance.prompt_loop"] = "Döngü (otomatik yeniden uygula)",
["adventure.set_distance.prompt_interval"] = "Döngü aralığı (ms, min 250)",
["adventure.set_distance.over_max_title"] = "Mesafe Uyarısı",
["adventure.set_distance.over_max_msg"] = "5000m üzerindeki mesafe size yıldız vermez.\n\nYarış mesafeyi kaydedecek, ancak yıldız ödülü verilmeyecektir. Devam edilsin mi?",
["adventure.set_distance.continue_button"] = "Devam Et",
["adventure.set_distance.not_in_adventure"] = "Önce Macera sekmesine gidin ve bir yarış başlatın",
["adventure.set_distance.start_race_first"] = "Önce bir yarış başlatın",
["adventure.set_distance.applied"] = "Mesafe ayarlandı: %sm",
["adventure.set_distance.loop_stopped"] = "Mesafe Ayarla döngüsü durduruldu.",
["adventure.set_distance.loop_running"] = "Mesafe döngüsü çalışıyor — durdurmak için Mesafe Ayarla'ya dokunun",
["adventure.set_distance.loop_warn_title"] = "Mesafe Döngüsü Uyarısı",
["adventure.set_distance.loop_warn_msg"] = "Döngü modu her %s ms'de bir belleğe yazar.\n\nKısa aralık kullanmak kararsızlığı, görsel aksaklıkları veya oyun çökmelerini artırabilir.\n\nYine de devam edilsin mi?",

-- ── modules/tabs/cups.lua ─────────────────────────────────────────────────────
["cups.adjust_countdown.title"] = "Geri Sayımı Ayarla",
["cups.adjust_countdown.desc"] = "Yarış başlamadan önceki geri sayımı ayarlayın",
["cups.slider.seconds"] = "Saniye",
["cups.adjust_countdown.applied"] = "Geri sayım %ss olarak ayarlandı",
["cups.auto_win.title"] = "Otomatik Kazan",
["cups.auto_win.desc"] = "Yarış sonucunuz ne olursa olsun otomatik kazanın",
["cups.force_boss.title"] = "Patronu Zorla",
["cups.force_boss.desc"] = "Patron her zaman görünsün",
["cups.force_cup.title"] = "Kupayı Zorla",
["cups.force_cup.desc"] = "Tek bir kupayı zorlar",
["cups.force_cup.not_found"] = "Kupa Zorlama bulunamadı. Daha sonra tekrar deneyin.",
["cups.force_cup.enabled"] = "Kupa Zorlama Etkin",
["cups.force_cup.disabled"] = "Kupa Zorlama Devre Dışı",
["cups.set_time.title"] = "Süreyi Ayarla",
["cups.set_time.desc"] = "Yarış sürenizi ayarlayın (güvenlik nedeniyle süre donmayacaktır). Aktif bir kupa yarışında olmalısınız. (örn. 1:09.069, 7.284)",
["cups.set_time.hint"] = "Süre (1:09.069 veya 7.284)",
["cups.set_time.invalid_format"] = "Geçersiz biçim. 1:09.069 veya 7.284 kullanın",
["cups.set_time.no_negative"] = "Negatif değer yok",
["cups.set_time.not_in_cup"] = "Önce Kupalar sekmesine gidin ve bir yarış başlatın",
["cups.set_time.start_race_first"] = "Önce bir yarış başlatın",
["cups.set_time.applied"] = "Süre %s olarak ayarlandı",
["cups.unlimited_tasks.title"] = "Sınırsız Görevler",
["cups.unlimited_tasks.desc"] = "Tüm görevleri tamamlanmış ve her zaman talep edilebilir olarak dondurun. Ödülleri tekrar tekrar talep edin.",
["cups.unlimited_tasks.resolve_failed"] = "Görev listesi çözülemedi",
["cups.unlimited_tasks.none_found"] = "Görev bulunamadı",
["cups.unlimited_tasks.enabled"] = "Sınırsız Görevler Etkin",
["cups.unlimited_tasks.disabled"] = "Sınırsız Görevler Devre Dışı",
["cups.unlimited_tasks.none_to_freeze"] = "Donduracak görev yok",
["cups.rank_points_bonus.title"] = "+498 Sıralama Puanı",
["cups.rank_points_bonus.desc"] = "Tüm lig görevlerinin size 200 puan yerine 498 puan vermesini sağlayın, ayrıca diğer ödülleri kaldırın.",
["cups.rank_points_bonus.none_found"] = "Lig görevi bulunamadı",
["cups.rank_points_bonus.boosted"] = "Sıralama puanları yükseltildi: %s",
["cups.rank_points_bonus.no_match"] = "Eşleşen lig görevi bulunamadı",
["cups.rank_points_bonus.nothing_to_restore"] = "Geri yüklenecek bir şey yok",
["cups.rank_points_bonus.restored"] = "Geri yüklendi: %s",

-- ── modules/tabs/event.lua ────────────────────────────────────────────────────
["event.patch_rewards.title"] = "Etkinlik Ödülleri Yaması",
["event.patch_rewards.desc"] = "Mevcut genel etkinlik ödüllerini VOID tarafından sağlanan özel ödüllerle yamalayın (oyun yeniden başlatma gerekir)",
["event.restore_events.title"] = "Etkinlik Ödüllerini Geri Yükle",
["event.restore_events.desc"] = "Oyun sunucusu kurtarmasını zorlamak için değiştirilmiş etkinlik JSON dosyalarını silin (oyun yeniden başlatma gerekir)",

["event.checking_permissions"] = "Ortam izinleri kontrol ediliyor...",
["event.scanning_files"] = "Aktif dosyalar taranıyor...",
["event.decode_rewards_failed"] = "Ödüller JSON'ı çözülemedi",
["event.workspace_creation_failed"] = "ÖLÜMCÜL: Çalışma alanı oluşturulamadı: %s",
["event.workspace_creation_failed_dialog"] = "ÖLÜMCÜL: Çalışma alanı dizini oluşturulamadı.\n%s",
["event.file_inaccessible"] = "Dosyaya erişilemiyor yolu: %s",
["event.predecrypt_not_found"] = "Ön deşifre: kaynak bulunamadı: %s",
["event.predecrypt_empty"] = "Ön deşifre: kaynak boş (0 bayt): %s",
["event.decode_active_failed"] = "active_events.json çözülemedi yolu: %s",
["event.no_active_events"] = "Etkin etkinlik bulunamadı yolu: %s",
["event.cannot_open_active"] = "active_events.json açılamadı yolu: %s",
["event.decrypt_active_failed"] = "active_events.json deşifre edilemedi yolu: %s",
["event.root_copy_failed"] = "Kök kopyalama başarısız: %s",

["event.select_events_patch"] = "Yamalanacak etkinlikleri seçin:\nYol: %s",
["event.user_cancelled"] = "Kullanıcı seçimi iptal etti yolu: %s",
["event.rewards_unavailable"] = "Gömülü ödüller mevcut değil, yamalar atlanıyor yolu: %s",
["event.skipped_unreadable"] = "Okunamayan etkinlik atlandı: %s",
["event.predecrypt_event_not_found"] = "Ön deşifre: etkinlik bulunamadı: %s",
["event.predecrypt_event_empty"] = "Ön deşifre: etkinlik boş (0 bayt): %s",
["event.processing_failed"] = "%s işlenemedi: %s",
["event.cannot_open_decrypted"] = "Deşifre dosyası açılamadı: %s",
["event.decrypt_event_failed"] = "Etkinlik deşifre edilemedi: %s",
["event.loop_crash"] = "Kritik dosya işleme döngüsü çöktü: %s",

["event.success_header"] = "Başarıyla:",
["event.success_removed_header"] = "Başarıyla Kaldırıldı (Yeniden Başlatıldığında Geri Yüklenecek):",
["event.success_item"] = "- %s",
["event.success_item_json"] = "- %s.json",
["event.failed_header"] = "Başarısız:",
["event.failed_item"] = "- %s",

["event.patch_results_title"] = "Yama Sonuçları",
["event.restore_results_title"] = "Geri Yükleme Sonuçları",
["event.restart_required_title"] = "Yeniden Başlatma Gerekli",
["event.patch_restart_msg"] = "Oyun kapatıldı ve bu betik çıkacak, yama etkilerini görmek için tekrar başlatın",
["event.restore_restart_msg"] = "Sunucu dosyası senkronizasyonuna izin vermek için oyun şimdi kapanacak.",
["event.finishing_tasks_patch"] = "Bekleyen arka plan görevleri tamamlanıyor... Lütfen bekleyin.",
["event.finishing_tasks_restore"] = "Bekleyen arka plan görevleri tamamlanıyor...",
["event.patch_failed_msg"] = "Yama başarısız, tekrar deneyin.",

["event.select_events_restore"] = "Geri yüklenecek (silinecek) dosyaları seçin:\nYol: %s",
["event.delete_failed"] = "%s silinemedi: %s",

-- ── modules/tabs/account.lua ──────────────────────────────────────────────────
["account.change_name.title"] = "Adı Değiştir",
["account.change_name.desc"] = "Oyuncu adınızı değiştirin",
["account.change_name.hint"] = "Ad Girin",
["account.change_name.empty"] = "Önce bir ad girin",
["account.change_name.too_long_title"] = "Ad Çok Uzun",
["account.change_name.too_long_msg"] = "Adınız çok uzun, lütfen kısaltın",
["account.change_name.resolve_failed"] = "Ad işaretçisi çözülemedi",
["account.change_name.applied"] = "Ad %s olarak değiştirildi",

["account.change_gp.title"] = "Garaj Gücünü Değiştir",
["account.change_gp.desc"] = "Profil garaj gücünü değiştirir (daha yüksekse kalıcıdır). Maksimumu aşarsa sıfırlamak için 8'e ayarlayın, ancak yalnızca gerçek GP'niz zaten limitin altında sabitlenmişse.",
["account.change_gp.hint"] = "Garaj Gücü Girin",
["account.change_gp.max_int_title"] = "Maksimum 32bit int'e ulaşıldı",
["account.change_gp.lower_value"] = "Lütfen değerinizi düşürün",
["account.change_gp.too_low_title"] = "Çok Düşük",
["account.change_gp.higher_value"] = "Lütfen değerinizi yükseltin",
["account.change_gp.applied"] = "Garaj Gücü %s olarak değiştirildi",

["account.fake_unlock.title"] = "Sahte Açma",
["account.fake_unlock.desc"] = "Tüm özelleştirmeleri geçici olarak aç",
["account.fake_vip.title"] = "Sahte VIP",
["account.fake_vip.desc"] = "VIP abonelik durumunu yerel olarak değiştir",
["account.fake_rank.title"] = "Sahte Sıralama",
["account.fake_rank.desc"] = "Sıralamanızı otomatik olarak sahte efsanevi olarak ayarlayın",
["account.fake_rank.applied"] = "Sahte sıralama enjekte edildi.",
["account.fake_rank.race_warn_title"] = "Yarış Gerekli",
["account.fake_rank.race_warn_msg"] = "Sahte Sıralama yalnızca bir Kupa yarışı aktif olarak çalışırken uygulanmalıdır.\n\nYarış dışında uygulanması gizli yasaklamaya neden olabilir.\n\nDevam etmeden önce zaten bir Kupa yarışının içinde olduğunuzdan emin olun.\n\nYine de devam edilsin mi?",
["account.fake_rank.continue_button"] = "Devam Et",

-- ── modules/tabs/vehicle.lua ──────────────────────────────────────────────────
["vehicle.parts_slot.title"] = "Parça Yuvalarını Ayarla",
["vehicle.parts_slot.desc"] = "Tüm araçlar için parça yuvalarını ayarlayın",
["vehicle.parts_slot.slider_title"] = "Yuvalar",
["vehicle.parts_slot.no_vehicles"] = "Araç bulunamadı",
["vehicle.parts_slot.applied"] = "Parça yuvaları ayarlandı: %d araç",

["vehicle.parts_modifier.title"] = "Parça Düzenleyici",
["vehicle.parts_modifier.desc"] = "Aktif yarışta ayar parçası seviye değerlerini değiştir",
["vehicle.parts_modifier.select"] = "Bir parça seçin",
["vehicle.parts_modifier.prompt_level"] = "Seviye: ",
["vehicle.parts_modifier.prompt_digit0"] = "Rakam: ",
["vehicle.parts_modifier.prompt_digit1"] = "Kuyruk: ",
["vehicle.parts_modifier.prompt_reset"] = "Sıfırla",
["vehicle.parts_modifier.invalid"] = "Geçersiz seviye değeri",
["vehicle.parts_modifier.not_found"] = "Parça bellekte bulunamadı",
["vehicle.parts_modifier.applied"] = "%s seviye %s olarak ayarlandı",
["vehicle.parts_modifier.reset"] = "%s sıfırlandı",

["vehicle.unlock_vehicles.title"] = "Araçları Aç",
["vehicle.unlock_vehicles.desc"] = "Tüm araçları jetonlarla satın alınabilir hale getir",
["vehicle.unlock_vehicles.no_vehicles"] = "Araç bulunamadı",
["vehicle.unlock_vehicles.unlocked"] = "Araçlar açıldı: %d",
["vehicle.unlock_vehicles.none_to_unlock"] = "Açılacak araç yok",

["vehicle.max_vehicles.title"] = "Maksimum Araçlar",
["vehicle.max_vehicles.desc"] = "Tüm açılmış araçların yükseltme seviyelerini anında maksimuma çıkar",
["vehicle.max_vehicles.no_vehicles"] = "Araç listesi çözülemedi",
["vehicle.max_vehicles.all_maxed"] = "Tüm araçlar maksimuma çıkarıldı",
["vehicle.max_vehicles.failed"] = "Araçlar maksimuma çıkarılamadı",

["vehicle.max_mastery.title"] = "Maksimum Ustalık",
["vehicle.max_mastery.desc"] = "Tüm açılmış ve maksimuma çıkarılmış araçların ustalıklarını anında maksimuma çıkar.",
["vehicle.max_mastery.all_maxed"] = "Tüm ustalıklar maksimuma çıkarıldı",
["vehicle.max_mastery.failed"] = "Ustalıklar maksimuma çıkarılamadı",

["vehicle.max_parts.title"] = "Maksimum Parçalar",
["vehicle.max_parts.desc"] = "Tüm araçlar için tüm açılmış parça seviyelerini anında maksimuma çıkar.",
["vehicle.max_parts.no_vehicles"] = "Araç listesi çözülemedi",
["vehicle.max_parts.all_maxed"] = "Tüm parçalar maksimuma çıkarıldı",
["vehicle.max_parts.failed"] = "Parçalar maksimuma çıkarılamadı",

["vehicle.common.no_vehicles"] = "Araç bulunamadı",
["vehicle.common.progress"] = "%d/%d",
["vehicle.common.resolve_list_failed"] = "Araç listesi çözülemedi",
["vehicle.common.no_zero_region"] = "Sıfır bölgesi bulunamadı",

}
