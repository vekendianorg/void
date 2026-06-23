--[[
  configs/lang/id.lua — Bahasa Indonesia

  Flat table of dotted keys -> strings, loaded by core/utils/lang.lua.
  Looked up at runtime via the global T(key, ...) function, e.g.:
      T("common.ok")                          -> "OK"
      T("settings.window_width_desc", 400, 650) -> "Lebar menu melayang (400 - 650 dp)"

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

  This file handles the Indonesian localization for the VOID script.
]]

return {

-- ── Common / shared (buttons, generic dialog text) ───────────────────────────
["common.ok"] = "OK",
["common.cancel"] = "Batal",
["common.yes"] = "Ya",
["common.no"] = "Tidak",
["common.failed"] = "Gagal",
["common.success"] = "Berhasil",
["common.later"] = "Nanti",
["common.got_it"] = "Paham",
["common.retry"] = "Coba Lagi",
["common.wait_safe"] = "Tunggu (Aman)",
["common.waiting"] = "Menunggu...",
["common.force_exit"] = "Keluar Paksa",
["common.proceed_anyway"] = "Tetap Lanjutkan",
["common.manual_mode"] = "Mode Manual",
["common.update_button"] = "PERBARUI",
["common.launch_failed"] = "Gagal Menjalankan",
["common.confirm_exit_title"] = "Konfirmasi Keluar",
["common.confirm_exit_msg"] = "Keluar dari Skrip?",
["common.not_available"] = "Tidak Tersedia",
["common.warning"] = "Peringatan",

-- ── main.lua (boot, updater, virtual-space detection, main loop) ─────────────
["main.exit_active_ops_title"] = "Peringatan: Operasi Aktif",
["main.exit_active_ops_msg"] = "Ada %d tugas latar belakang yang sedang berjalan.\nKeluar paksa dapat merusak status game.",
["main.initializing"] = "Menginisialisasi...",
["main.no_app_found"] = "Aplikasi tidak ditemukan",
["main.arch_64bit_required_title"] = "Diperlukan 64-bit",
["main.arch_64bit_required_msg"] = "ARMv8a wajib digunakan. x86_64 didukung sebagian.",

["main.update_available_title"] = "Pembaruan Tersedia",
["main.update_available_msg"] = "v%s telah tersedia (saat ini: v%s)\n\n%s\n\nPerbarui sekarang?",
["main.no_changelog"] = "Tidak ada catatan perubahan.",
["main.downloading_version"] = "Mengunduh v%s...",
["main.update_download_failed_msg"] = "Tidak dapat mengunduh pembaruan:\n%s",
["main.update_write_failed_msg"] = "Tidak dapat menulis ke:\n%s",
["main.update_done_title"] = "VOID Diperbarui ke v%s",
["main.update_done_msg"] = "VOID telah berhasil diperbarui.\n\nSkrip baru telah disimpan sebagai:\nvoid_v%s.lua\n\nJalankan dari GameGuardian untuk menerapkan pembaruan.",
["main.launching_version"] = "Menjalankan v%s...",
["main.launch_failed_msg"] = "Berhasil diunduh tetapi tidak dapat dijalankan:\n%s",

["main.multiple_spaces_title"] = "Terdeteksi Beberapa Ruang Virtual",
["main.multiple_spaces_desc"] = "HCR2 ditemukan di %d ruang virtual.\nPilih ruang virtual yang sedang Anda mainkan.",
["main.select_space_toast"] = "Silakan pilih ruang virtual untuk melanjutkan.",
["main.user_space_item"] = "Pengguna %s  —  %s",
["main.permission_error_title"] = "Kesalahan Izin",
["main.permission_error_msg"] = "Akses shell ditolak.\n\nVoid memerlukan ini untuk menemukan HCR2 di ruang virtual Anda. Periksa kode sumber Void jika Anda ingin memverifikasi perintah apa yang dijalankan.",
["main.hcr2_not_found_title"] = "Data HCR2 Tidak Ditemukan",
["main.hcr2_not_found_msg"] = "Void tidak dapat menemukan data HCR2 di ruang virtual Anda. Ini bisa terjadi jika HCR2 belum dijalankan, atau aplikasi ruang virtual Anda menggunakan struktur jalur yang tidak biasa.\n\nFitur yang bergantung pada file game (Hadiah Acara, dll.) tidak akan berfungsi tanpa jalur yang valid.",
["main.manual_data_path_title"] = "Jalur Data Manual",
["main.manual_data_path_hint"] = "Masukkan jalur data HCR2",
["main.manual_path_cancelled"] = "Dibatalkan — melanjutkan tanpa jalur.",
["main.waiting_for_lib"] = "Menunggu %s...",
["main.initialized"] = "Terinisialisasi",
["main.gamestatus_not_found"] = "GameStatus Tidak Ditemukan",
["main.dont_interrupt"] = "Jangan menginterupsi skrip ini",

-- ── ui/ui.lua (framework chrome: menu, cards, dialogs) ────────────────────────
["ui.size_saved_restart"] = "Ukuran disimpan! Mulai ulang skrip",
["ui.category_error"] = "Kesalahan: %s",
["ui.category_not_found"] = "Kategori Tidak Ditemukan",
["ui.na"] = "N/A",
["ui.spinner_select"] = "Pilih",
["ui.slider_default_title"] = "Nilai",

-- ── core/engines/patches.lua (addArchModule patch engine) ────────────────────
["patches.requires_arch"] = "Memerlukan perangkat %s (perangkat Anda: %s)",
["patches.suffix_enabled"] = " Diaktifkan",
["patches.suffix_disabled"] = " Dinonaktifkan",
["patches.pattern_not_found"] = "Gagal: %d pola tidak ditemukan",

-- ── core/engines/arch.lua (architecture detection warnings) ──────────────────
["arch.warning_title"] = "Peringatan Arsitektur",
["arch.unknown_arch_msg"] = "Arsitektur Anda tidak dikenal. Apakah lib sudah dimuat? Sistem apa yang Anda gunakan?",
["arch.non_primary_arch_msg"] = "Terdeteksi: %s\nBeberapa atau semua patch-lib mungkin tidak berfungsi.",
["arch.unknown_version_msg"] = "Versi game tidak diketahui. Coba lagi setelah game dimuat.",
["arch.no_base_data_msg"] = "Kesalahan internal: tidak ada data dasar yang tersedia untuk arsitektur ini.",

-- ── core/engines/scheduler.lua ────────────────────────────────────────────────
["scheduler.task_crashed"] = "Peringatan Penjadwal: Tugas crash -> %s",

-- ── core/utils/paste.lua + catbox.lua (network error strings) ────────────────
["errors.http_error_code"] = "Kode Kesalahan HTTP: %s",
["errors.crashed"] = "Crash: %s",
["errors.url_missing"] = "Parameter URL hilang atau kosong",
["errors.file_path_missing"] = "Jalur file hilang",
["errors.download_url_missing"] = "URL hilang",
["errors.dest_path_missing"] = "Jalur tujuan hilang",

-- ── modules/registry.lua (sidebar tab labels + module-load error cards) ──────
["tabs.sep_game"] = "MENU GAME",
["tabs.account"] = "MENU AKUN",
["tabs.vehicle"] = "MENU KENDARAAN",
["tabs.player"] = "MENU PEMAIN",
["tabs.adventure"] = "MENU PETUALANGAN",
["tabs.cups"] = "MENU PIALA",
["tabs.team"] = "MENU TIM",
["tabs.event"] = "MENU ACARA",
["tabs.creative"] = "MENU KREATIF",
["tabs.shop"] = "MENU TOKO",
["tabs.other"] = "MENU LAINNYA",
["tabs.sep_script"] = "MENU SKRIP",
["tabs.settings"] = "PENGATURAN",
["tabs.about"] = "TENTANG",

["registry.module_load_failed"] = "Modul gagal dimuat. Periksa log untuk detailnya.",
["registry.module_runtime_error"] = "Kesalahan runtime: %s",
["registry.error"] = "Kesalahan",

-- ── modules/tabs/settings.lua ─────────────────────────────────────────────────
["settings.section_updates"] = "Pembaruan",
["settings.auto_update.title"] = "Pembaruan Otomatis",
["settings.auto_update.desc"] = "Perbarui VOID secara otomatis saat startup",
["settings.dev_mode_title"] = "Mode Pengembang",
["settings.auto_update.dev_mode_msg"] = "Pembaruan otomatis dinonaktifkan untuk main.lua (dev build).",
["settings.check_updates.title"] = "Periksa Pembaruan",
["settings.check_updates.desc"] = "Periksa rilis VOID terbaru di GitHub",
["settings.check_updates.dev_mode_msg"] = "Pemeriksaan pembaruan dinonaktifkan untuk main.lua (dev build).\n\nSilakan tarik (pull) dari repositori secara manual.",
["settings.check_updates.checking"] = "Memeriksa pembaruan...",
["settings.check_updates.failed_title"] = "Pemeriksaan Pembaruan Gagal",
["settings.check_updates.failed_msg"] = "Tidak dapat menjangkau GitHub:\n%s",
["settings.check_updates.up_to_date_title"] = "Sudah yang Terbaru",
["settings.check_updates.up_to_date_msg"] = "Anda sudah menggunakan versi terbaru (v%s).",
["settings.check_updates.no_changelog"] = "Tidak ada catatan perubahan yang tersedia.",
["settings.check_updates.available_msg"] = "v%s  (saat ini: v%s)\n\n%s\n\nUnduh dan ganti skrip ini?",
["settings.check_updates.no_asset_msg"] = "Aset .lua tidak ditemukan dalam rilis.",
["settings.check_updates.download_failed_title"] = "Unduhan Gagal",
["settings.check_updates.write_failed_title"] = "Penulisan Gagal",
["settings.check_updates.done_title"] = "Selesai",
["settings.check_updates.done_msg"] = "Diperbarui ke v%s. Mulai ulang skrip untuk menerapkan.",
["settings.check_updates.restart_button"] = "Mulai Ulang",

["settings.section_language"] = "Bahasa",
["settings.language.title"] = "Bahasa",
["settings.language.desc"] = "Pilih bahasa pilihan Anda untuk menu",
["settings.language.changed"] = "Bahasa diatur ke %s",
["settings.language.failed"] = "Gagal memuat bahasa tersebut",
["settings.language.restart_msg"] = "Mulai ulang skrip untuk menerapkan bahasa sepenuhnya",

["settings.region.other"] = "O: Lainnya",
["settings.region.cpp_alloc"] = "Ca: Alokasi C++",
["settings.region.unknown"] = "U: Tidak Diketahui",
["settings.section_memory"] = "Memori",
["settings.memory_range.title"] = "Rentang Memori",
["settings.memory_range.desc"] = "Rentang memori yang dipilih saat ini\n(dipilih secara otomatis oleh skrip)",
["settings.gamestatus.title"] = "GameStatus",
["settings.gamestatus.desc"] = "Alamat gamestatus saat ini\n(dipilih secara otomatis oleh skrip)",
["settings.gamestatus_raw.title"] = "GameStatus (Mentah)",
["settings.gamestatus_raw.desc"] = "Alamat gamestatus (mentah) saat ini\n(dipilih secara otomatis oleh skrip)",
["settings.clear_memory.title"] = "Hapus Memori Tersimpan",
["settings.clear_memory.desc"] = "Hapus semua memori VOID yang tersimpan tanpa perlu memulai ulang seluruh game.",

["settings.section_ui_customizations"] = "Kustomisasi UI",
["settings.theme_store.title"] = "Toko Tema",
["settings.theme_store.desc"] = "Jelajahi dan pasang tema Void dari komunitas",
["settings.theme_store.unreachable_msg"] = "Tidak dapat menjangkau toko tema:\n%s",
["settings.theme_store.parse_failed_msg"] = "Tidak dapat mengurai data toko tema.",
["settings.theme_store.list_title"] = "Toko Tema Void",
["settings.theme_store.search_results_desc"] = "Hasil pencarian: %s ditemukan",
["settings.theme_store.available_desc"] = "%s tema tersedia",
["settings.theme_store.by_author"] = "oleh %s",
["settings.theme_store.search_item"] = "🔍 Cari...",
["settings.theme_store.clear_search_item"] = "✕ Bersihkan pencarian",
["settings.theme_store.search_title"] = "Cari Tema",
["settings.theme_store.search_hint"] = "Nama tema, pembuat, atau deskripsi",
["settings.theme_store.no_results"] = "Tema tidak ditemukan untuk: %s",
["settings.theme_store.detail_msg"] = "Oleh %s\n\n%s\n\nID: %s",
["settings.theme_store.install_button"] = "Pasang Tema",
["settings.theme_downloading_bg"] = "Mengunduh gambar latar belakang...",
["settings.theme_imported"] = "Tema berhasil diimpor!",
["settings.theme_invalid_bundle"] = "Format bundel tidak valid.",
["settings.theme_cloud_error"] = "Kesalahan cloud: %s",
["settings.reset_theme.title"] = "Atur Ulang Tema",
["settings.reset_theme.desc"] = "Kembalikan tema kustom dan gambar latar belakang ke bawaan",
["settings.import_theme.title"] = "Impor Tema",
["settings.import_theme.desc"] = "Impor tema kustom dari cloud",
["settings.import_theme.hint"] = "Masukkan ID Berbagi",
["settings.export_theme.title"] = "Ekspor Tema",
["settings.export_theme.desc"] = "Ekspor tema kustom dan gambar latar belakang ke cloud",
["settings.export_theme.share_id_msg"] = "ID Berbagi: %s\n\nDisalin ke papan klip.",
["settings.export_theme.upload_failed_msg"] = "Unggahan gagal: %s",
["settings.export_theme.size_warning_title"] = "Peringatan Ukuran Unggahan",
["settings.export_theme.size_warning_msg"] = "Sertakan gambar latar belakang kustom? Ini akan meningkatkan Ukuran Unggahan tergantung seberapa besar resolusi gambar Anda.",
["settings.export_theme.uploading_bg"] = "Mengunduh gambar latar belakang ke Catbox...",
["settings.export_theme.image_upload_failed_title"] = "Kesalahan",
["settings.export_theme.image_upload_failed_msg"] = "Unggahan gambar gagal: %s",
["settings.tabs_icon.title"] = "Ikon Tab",
["settings.tabs_icon.desc"] = "Ubah ikon tab",
["settings.tabs_icon.hint"] = "Masukkan Ikon",
["settings.tabs_icon.empty_error"] = "Tidak boleh kosong",

["settings.bg_opacity.title"] = "Opasitas Latar Belakang",
["settings.bg_opacity.desc"] = "Transparansi untuk panel, kartu, dan header",
["settings.slider.alpha"] = "Alfa",
["settings.bg_image_opacity.title"] = "Opasitas Gambar Latar Belakang",
["settings.bg_image_opacity.desc"] = "Sesuaikan visibilitas pengaturan alfa secara langsung menggunakan saluran integer murni.",
["settings.bg_image_picker.title"] = "Gambar Latar Belakang",
["settings.bg_image_picker.desc"] = "Ketuk untuk mengubah jalur file absolut tujuan untuk gambar latar belakang tata letak kustom Anda",
["settings.bg_image_picker.path_label"] = "Jalur File Gambar Absolut (.jpg atau .png):",
["settings.bg_image_picker.remove_label"] = "Hapus Gambar BG",
["settings.bg_image_picker.success_title"] = "Berhasil",
["settings.bg_image_picker.removed_msg"] = "Gambar Latar Belakang Dihapus",
["settings.bg_image_picker.added_msg"] = "Gambar latar belakang ditambahkan",
["settings.bg_image_picker.not_found_msg"] = "File tidak ditemukan atau operasi membaca ditolak:\n%s",

["settings.bg_rgb.title"] = "RGB Latar Belakang",
["settings.bg_rgb.desc"] = "Rona warna latar belakang panel (Header dan Kartu menyesuaikan otomatis)",
["settings.slider.r"] = "R",
["settings.slider.g"] = "G",
["settings.slider.b"] = "B",
["settings.accent_rgb.title"] = "RGB Aksen",
["settings.accent_rgb.desc"] = "Semburat warna untuk tombol, pengalih, dan kartu aktif (warna redup diturunkan otomatis)",
["settings.logo_rgb.title"] = "RGB Sorotan",
["settings.logo_rgb.desc"] = "Warna untuk label, ikon, dan teks interaktif (selalu sepenuhnya buram)",
["settings.sub_rgb.title"] = "RGB Sub-teks",
["settings.sub_rgb.desc"] = "Warna untuk deskripsi dan label tab yang tidak aktif",
["settings.text_rgb.title"] = "RGB Teks",
["settings.text_rgb.desc"] = "Warna untuk teks menu utama",

["settings.win_width.title"] = "Lebar Menu",
["settings.win_width.desc"] = "Lebar menu melayang (%d – %d dp)",
["settings.slider.width"] = "Lebar",
["settings.win_height.title"] = "Tinggi Menu",
["settings.win_height.desc"] = "Tinggi area konten yang dapat digulir (%d – %d dp)",
["settings.slider.height"] = "Tinggi",

-- ── modules/tabs/about.lua ────────────────────────────────────────────────────
["about.about_script.title"] = "Tentang Skrip",
["about.about_script.desc"] = "Skrip manipulasi memori yang kuat dan sangat dioptimalkan yang dibuat untuk Hill Climb Racing 2 di lingkungan kustom Pivot.\n\nUnduh Pivot:\nhttps://github.com/vekendianorg/pivot/releases/",
["about.script_owner.title"] = "Pemilik Skrip",
["about.script_owner.desc"] = "- Organisasi Vekendian (github: vekendianorg)",
["about.script_dev.title"] = "Pengembang Skrip",
["about.script_dev.desc"] = [[
- Lazor (github: lazor-git)
- AMR (github: amr-gt)
- Erik (github: eomthix)
]],
["about.script_translator.title"] = "Penerjemah Skrip",
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
["about.credits.title"] = "Kredit",
["about.credits.desc"] = [[
- Lazor (github: lazor-git)
- Lan9118 (discord: lan9118)
- AMR (github: amr-gt)
- Erik (github: eomthix)
- Sr Romero
]],
["about.special_thanks.title"] = "Terima Kasih Khusus",
["about.special_thanks.desc"] = [[
- Aryan/KokushiboModz
]],

-- ── modules/tabs/other.lua ────────────────────────────────────────────────────
["other.debug_mode.title"] = "Mode Debug",
["other.debug_mode.desc"] = "Aktifkan/nonaktifkan mode debug dalam game",
["other.debug_mode.enabled"] = "Mode Debug Diaktifkan",
["other.debug_mode.disabled"] = "Mode Debug Dinonaktifkan",
["other.hint.width"] = "Lebar",
["other.hint.height"] = "Tinggi",
["other.resolution.title"] = "Sesuaikan Resolusi",
["other.resolution.desc"] = "Sesuaikan lebar dan tinggi game (bawaan adalah 1280x720)",
["other.resolution.applied"] = "Resolusi diatur ke %dx%d",
["other.resolution_offset.title"] = "Sesuaikan Offset Resolusi",
["other.resolution_offset.desc"] = "Sesuaikan offset lebar game dan offset tinggi game (bawaan adalah 0x0), terbaik untuk resolusi kecil di layar besar.",
["other.resolution_offset.applied"] = "Offset resolusi diatur ke %dx%d",
["other.glsurface_not_found"] = "GLSurfaceView tidak ditemukan",

-- ── modules/tabs/shop.lua ─────────────────────────────────────────────────────
["shop.free_chest.title"] = "Peti Gratis",
["shop.free_chest.desc"] = "Gratiskan peti di Tab Toko",
["shop.free_chest.enabled"] = "Peti Gratis Diaktifkan",
["shop.free_chest.disabled"] = "Peti Gratis Dinonaktifkan",
["shop.free_purchases.title"] = "Pembelian Gratis",
["shop.free_purchases.desc"] = "Gratiskan beberapa pembelian penawaran harian di tab toko (juga berlaku untuk penawaran khusus berupa popup/lencana)",
["shop.free_purchases.progress"] = "%d/%d",
["shop.free_purchases.success"] = "Pembelian Gratis Berhasil",
["shop.change_chest.title"] = "Ubah Peti",
["shop.change_chest.desc"] = "Ubah peti legendaris menjadi peti yang dipilih",
["shop.change_chest.changed"] = "Peti diubah menjadi %s",
["shop.change_chest.options"] = {
    "Peti Biasa", "Peti Tidak Biasa", "Peti Langka", "Peti Epik",
    "Peti Juara", "Peti Khusus 1", "Peti Natal", "Peti Legendaris",
    "Peti Biru", "Peti VIP 1", "Peti VIP 2", "Peti Video",
    "Peti Pemula", "Peti Khusus 2", "Peti Fingersoft", "Peti Mega",
    "Peti Semangat Tim", "Peti Gaya", "Peti Mitos"
},

-- ── modules/tabs/player.lua ───────────────────────────────────────────────────
["player.auto_detach.title"] = "Lepas Otomatis",
["player.auto_detach.desc"] = "Lepaskan bagian kendaraan secara otomatis seperti atap Rally Car",
["player.no_clip.title"] = "No-Clip",
["player.no_clip.desc"] = "Membuat pemain Anda menembus objek tanpa mati (Anda bisa melewati garis finis di piala)",
["player.no_clip.enabled"] = "No-Clip Diaktifkan",
["player.no_clip.disabled"] = "No-Clip Dinonaktifkan",
["player.hide_name.title"] = "Sembunyikan Nama",
["player.hide_name.desc"] = "Sembunyikan nama pemain Anda saat balapan",
["player.hide_name.enabled"] = "Sembunyikan Nama Diaktifkan",
["player.hide_name.disabled"] = "Sembunyikan Nama Dinonaktifkan",
["player.hide_flag.title"] = "Sembunyikan Bendera",
["player.hide_flag.desc"] = "Sembunyikan bendera pemain Anda saat balapan",
["player.hide_flag.enabled"] = "Sembunyikan Bendera Diaktifkan",
["player.hide_flag.disabled"] = "Sembunyikan Bendera Dinonaktifkan",
["player.zoom.title"] = "Sesuaikan Zoom",
["player.zoom.desc"] = "Sesuaikan seberapa dekat atau jauh kamera Anda",
["player.slider.min"] = "Min",
["player.slider.max"] = "Maks",
["player.gravity.title"] = "Sesuaikan Gravitasi",
["player.gravity.desc"] = "Sesuaikan seberapa kuat gravitasi",
["player.slider.x"] = "X",
["player.slider.y"] = "Y",

-- ── modules/tabs/adventure.lua ────────────────────────────────────────────────
["adventure.auto_adventure_chests.title"] = "Peti Petualangan Otomatis (tidak stabil)",
["adventure.auto_adventure_chests.desc"] = "Tingkatkan level peti petualangan Anda secara otomatis",
["adventure.auto_adventure_chests.none_found"] = "Peti petualangan tidak ditemukan",
["adventure.auto_adventure_chests.done"] = "Selesai",

["adventure.set_distance.title"] = "Atur Jarak",
["adventure.set_distance.desc"] = "Mengatur jarak balapan Petualangan Anda ke nilai kustom. Harus dalam balapan yang aktif. Jarak lebih tinggi bisa mendapatkan lebih banyak bintang. Bintang maks di 5000m. (Bukan fungsi teleportasi)",
["adventure.set_distance.loop_active_title"] = "Atur Jarak — Loop Aktif",
["adventure.set_distance.loop_active_msg"] = "Loop jarak saat ini sedang berjalan.\nApa yang ingin Anda lakukan?",
["adventure.set_distance.stop_loop"] = "Hentikan Loop",
["adventure.set_distance.keep_running"] = "Tetap Berjalan",
["adventure.set_distance.loop_will_stop"] = "Loop akan berhenti setelah centang (tick) saat ini.",
["adventure.set_distance.prompt_target"] = "Jarak target (meter)",
["adventure.set_distance.prompt_loop"] = "Loop (terapkan ulang otomatis)",
["adventure.set_distance.prompt_interval"] = "Interval loop (ms, min 250)",
["adventure.set_distance.over_max_title"] = "Peringatan Jarak",
["adventure.set_distance.over_max_msg"] = "Jarak di atas 5000m tidak akan memberi Anda bintang.\n\nBalapan akan tetap mencatat jarak tersebut, tetapi tidak ada hadiah bintang yang diberikan. Lanjutkan?",
["adventure.set_distance.continue_button"] = "Lanjutkan",
["adventure.set_distance.not_in_adventure"] = "Buka tab Petualangan dan mulai balapan terlebih dahulu",
["adventure.set_distance.start_race_first"] = "Mulai balapan terlebih dahulu",
["adventure.set_distance.applied"] = "Jarak diatur: %sm",
["adventure.set_distance.loop_stopped"] = "Loop Atur Jarak dihentikan.",
["adventure.set_distance.loop_running"] = "Loop jarak berjalan — ketuk Atur Jarak untuk menghentikan",

-- ── modules/tabs/cups.lua ─────────────────────────────────────────────────────
["cups.adjust_countdown.title"] = "Sesuaikan Hitung Mundur",
["cups.adjust_countdown.desc"] = "Sesuaikan hitung mundur sebelum memulai balapan",
["cups.slider.seconds"] = "Detik",
["cups.adjust_countdown.applied"] = "Hitung mundur disesuaikan ke %ss",
["cups.auto_win.title"] = "Menang Otomatis",
["cups.auto_win.desc"] = "Menang secara otomatis tidak peduli apa pun hasil balapan Anda",
["cups.force_boss.title"] = "Paksa Bos",
["cups.force_boss.desc"] = "Paksa bos agar selalu muncul",
["cups.force_cup.title"] = "Paksa Piala",
["cups.force_cup.desc"] = "Memaksa satu piala khusus",
["cups.force_cup.not_found"] = "Paksa Piala tidak ditemukan. Coba lagi nanti.",
["cups.force_cup.enabled"] = "Paksa Piala Diaktifkan",
["cups.force_cup.disabled"] = "Paksa Piala Dinonaktifkan",
["cups.unlimited_tasks.title"] = "Tugas Tanpa Batas",
["cups.unlimited_tasks.desc"] = "Bekukan semua tugas sebagai selesai dan selalu dapat diklaim. Klaim hadiah berulang kali.",
["cups.unlimited_tasks.resolve_failed"] = "Gagal menyelesaikan daftar tugas",
["cups.unlimited_tasks.none_found"] = "Tugas tidak ditemukan",
["cups.unlimited_tasks.enabled"] = "Tugas Tanpa Batas Diaktifkan",
["cups.unlimited_tasks.disabled"] = "Tugas Tanpa Batas Dinonaktifkan",
["cups.unlimited_tasks.none_to_freeze"] = "Tidak ada tugas untuk dibekukan",
["cups.rank_points_bonus.title"] = "+498 Poin Peringkat",
["cups.rank_points_bonus.desc"] = "Membuat semua tugas liga memberi Anda 498 poin alih-alih 200 poin, serta menghapus hadiah lainnya.",
["cups.rank_points_bonus.none_found"] = "Tugas liga tidak ditemukan",
["cups.rank_points_bonus.boosted"] = "Poin peringkat didorong: %s",
["cups.rank_points_bonus.no_match"] = "Tugas liga yang cocok tidak ditemukan",
["cups.rank_points_bonus.nothing_to_restore"] = "Tidak ada yang bisa dipulihkan",
["cups.rank_points_bonus.restored"] = "Dipulihkan: %s",

-- ── modules/tabs/event.lua ────────────────────────────────────────────────────
["event.patch_rewards.title"] = "Patch Hadiah Acara",
["event.patch_rewards.desc"] = "Patch hadiah acara publik saat ini ke kustom yang disediakan oleh VOID (memerlukan mulai ulang game)",
["event.restore_events.title"] = "Pulihkan Hadiah Acara",
["event.restore_events.desc"] = "Hapus JSON acara yang dimodifikasi untuk memaksa sinkronisasi ulang server game (memerlukan mulai ulang game)",

["event.checking_permissions"] = "Memeriksa izin lingkungan...",
["event.scanning_files"] = "Memindai file aktif...",
["event.decode_rewards_failed"] = "Gagal mendekode JSON hadiah",
["event.workspace_creation_failed"] = "FATAL: Pembuatan ruang kerja gagal: %s",
["event.workspace_creation_failed_dialog"] = "FATAL: Tidak dapat membuat direktori ruang kerja.\n%s",
["event.file_inaccessible"] = "File tidak dapat diakses di jalur: %s",
["event.predecrypt_not_found"] = "Pra-dekripsi: sumber tidak ditemukan: %s",
["event.predecrypt_empty"] = "Pra-dekripsi: sumber kosong (0 byte): %s",
["event.decode_active_failed"] = "Gagal mendekode active_events.json di jalur: %s",
["event.no_active_events"] = "Acara aktif tidak ditemukan di jalur: %s",
["event.cannot_open_active"] = "Tidak dapat membuka active_events.json di jalur: %s",
["event.decrypt_active_failed"] = "Gagal mendekripsi active_events.json di jalur: %s",
["event.root_copy_failed"] = "Penyalinan root gagal: %s",

["event.select_events_patch"] = "Pilih acara untuk di-patch:\nJalur: %s",
["event.user_cancelled"] = "Pengguna membatalkan pilihan untuk jalur: %s",
["event.rewards_unavailable"] = "Hadiah tersemat tidak tersedia, melewati patch untuk jalur: %s",
["event.skipped_unreadable"] = "Melewati acara yang tidak terbaca: %s",
["event.predecrypt_event_not_found"] = "Pra-dekripsi: acara tidak ditemukan: %s",
["event.predecrypt_event_empty"] = "Pra-dekripsi: acara kosong (0 byte): %s",
["event.processing_failed"] = "Gagal memproses %s: %s",
["event.cannot_open_decrypted"] = "Tidak dapat membuka file terdekripsi: %s",
["event.decrypt_event_failed"] = "Gagal mendekripsi acara: %s",
["event.loop_crash"] = "Crash loop pemrosesan file kritis: %s",

["event.success_header"] = "Berhasil:",
["event.success_removed_header"] = "Berhasil Dihapus (Akan Dipulihkan saat Mulai Ulang):",
["event.success_item"] = "- %s",
["event.success_item_json"] = "- %s.json",
["event.failed_header"] = "Gagal:",
["event.failed_item"] = "- %s",

["event.patch_results_title"] = "Hasil Patch",
["event.restore_results_title"] = "Hasil Pemulihan",
["event.restart_required_title"] = "Diperlukan Mulai Ulang",
["event.patch_restart_msg"] = "Game dihentikan paksa dan skrip ini akan keluar, jalankan lagi untuk melihat efek patch",
["event.restore_restart_msg"] = "Game sekarang akan ditutup untuk memungkinkan sinkronisasi file server.",
["event.finishing_tasks_patch"] = "Menyelesaikan tugas latar belakang yang tertunda... Harap tunggu.",
["event.finishing_tasks_restore"] = "Menyelesaikan tugas latar belakang yang tertunda...",
["event.patch_failed_msg"] = "Gagal melakukan patch, coba lagi.",

["event.select_events_restore"] = "Pilih file untuk dipulihkan (dihapus):\nJalur: %s",
["event.delete_failed"] = "Gagal menghapus %s: %s",

-- ── modules/tabs/account.lua ──────────────────────────────────────────────────
["account.change_name.title"] = "Ubah Nama",
["account.change_name.desc"] = "Ubah nama pemain Anda",
["account.change_name.hint"] = "Masukkan Nama",
["account.change_name.empty"] = "Masukkan nama terlebih dahulu",
["account.change_name.too_long_title"] = "Nama Terlalu Panjang",
["account.change_name.too_long_msg"] = "Nama Anda terlalu panjang, silakan perpendek",
["account.change_name.resolve_failed"] = "Gagal menyelesaikan pointer nama",
["account.change_name.applied"] = "Nama diubah menjadi %s",

["account.change_gp.title"] = "Ubah Garage Power",
["account.change_gp.desc"] = "Mengubah garage power profil (menetap jika lebih tinggi). Atur ke 8 untuk mereset jika melebihi batas maks, tetapi hanya jika GP asli Anda sudah diperbaiki di bawah batas.",
["account.change_gp.hint"] = "Masukkan Garage Power",
["account.change_gp.max_int_title"] = "Batas Maks Int 32-bit Tercapai",
["account.change_gp.lower_value"] = "Silakan turunkan nilai Anda",
["account.change_gp.too_low_title"] = "Terlalu Rendah",
["account.change_gp.higher_value"] = "Silakan naikkan nilai Anda",
["account.change_gp.applied"] = "Garage Power telah diubah menjadi %s",

["account.fake_unlock.title"] = "Unlock Palsu",
["account.fake_unlock.desc"] = "Buka semua kustomisasi secara sementara",
["account.fake_vip.title"] = "VIP Palsu",
["account.fake_vip.desc"] = "Aktifkan status langganan VIP secara lokal",
["account.fake_rank.title"] = "Peringkat Palsu",
["account.fake_rank.desc"] = "Atur peringkat Anda ke legendaris palsu secara otomatis",
["account.fake_rank.applied"] = "Peringkat Palsu telah disuntikkan.",

-- ── modules/tabs/vehicle.lua ──────────────────────────────────────────────────
["vehicle.parts_slot.title"] = "Sesuaikan Slot Bagian",
["vehicle.parts_slot.desc"] = "Sesuaikan slot bagian (parts) untuk semua kendaraan",
["vehicle.parts_slot.slider_title"] = "Slot",
["vehicle.parts_slot.no_vehicles"] = "Kendaraan tidak ditemukan",
["vehicle.parts_slot.applied"] = "Slot bagian disesuaikan: %d kendaraan",

["vehicle.unlock_vehicles.title"] = "Buka Kendaraan",
["vehicle.unlock_vehicles.desc"] = "Buka semua kendaraan agar tersedia untuk dibeli dengan koin",
["vehicle.unlock_vehicles.no_vehicles"] = "Kendaraan tidak ditemukan",
["vehicle.unlock_vehicles.unlocked"] = "Kendaraan dibuka: %d",
["vehicle.unlock_vehicles.none_to_unlock"] = "Tidak ada kendaraan untuk dibuka",

["vehicle.max_vehicles.title"] = "Maksimalkan Kendaraan",
["vehicle.max_vehicles.desc"] = "Maksimalkan level peningkatan semua kendaraan yang terbuka secara instan",
["vehicle.max_vehicles.no_vehicles"] = "Gagal menyelesaikan daftar kendaraan",
["vehicle.max_vehicles.all_maxed"] = "Semua kendaraan dimaksimalkan",
["vehicle.max_vehicles.failed"] = "Gagal memaksimalkan kendaraan",

["vehicle.max_mastery.title"] = "Maksimalkan Kemahiran",
["vehicle.max_mastery.desc"] = "Maksimalkan semua kemahiran (mastery) kendaraan yang terbuka dan maksimal secara instan.",
["vehicle.max_mastery.all_maxed"] = "Semua kemahiran dimaksimalkan",
["vehicle.max_mastery.failed"] = "Gagal memaksimalkan kemahiran",

["vehicle.max_parts.title"] = "Maksimalkan Bagian",
["vehicle.max_parts.desc"] = "Maksimalkan semua level bagian (parts) yang terbuka untuk semua kendaraan secara instan.",
["vehicle.max_parts.no_vehicles"] = "Gagal menyelesaikan daftar kendaraan",
["vehicle.max_parts.all_maxed"] = "Semua bagian dimaksimalkan",
["vehicle.max_parts.failed"] = "Gagal memaksimalkan bagian",

["vehicle.common.no_vehicles"] = "Kendaraan tidak ditemukan",
["vehicle.common.progress"] = "%d/%d",
["vehicle.common.resolve_list_failed"] = "Gagal menyelesaikan daftar kendaraan",
["vehicle.common.no_zero_region"] = "Wilayah nol tidak ditemukan",

}
