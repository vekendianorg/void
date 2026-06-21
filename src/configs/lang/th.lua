--[[
  configs/lang/ru.lua — Thailand 

  Flat table of dotted keys -> strings, loaded by core/utils/lang.lua.
  Looked up at runtime via the global T(key, ...) function, e.g.:
      T("common.ok")                          -> "OK"
      T("settings.window_width_desc", 400, 650) -> "Width of the floating menu (400 - 650 dp)"

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

    This file handles the Thailand localization for the VOID script.
]]

return {

-- ── Common / shared (buttons, generic dialog text) ───────────────────────────
["common.ok"] = "ตกลง",
["common.cancel"] = "ยกเลิก",
["common.yes"] = "ใช่",
["common.no"] = "ไม่",
["common.failed"] = "ไม่สําเร็จ",
["common.success"] = "สําเร็จ",
["common.later"] = "รอไปก่อน",
["common.got_it"] = "ได้มาแล้ว",
["common.retry"] = "ใส่อีกรอบ",
["common.wait_safe"] = "รอก่อน... (ปลอดภัย)",
["common.waiting"] = "รอก่อน...",
["common.force_exit"] = "บังคับออก",
["common.proceed_anyway"] = "เอาเลย",
["common.manual_mode"] = "ทําเอง",
["common.update_button"] = "อัพเดท",
["common.launch_failed"] = "สคริปไม่ขึ้น",
["common.confirm_exit_title"] = "กดปิดสคริป",
["common.confirm_exit_msg"] = "จะปิดสคริปแล้วหรอ?",
["common.not_available"] = "ไม่มีอยู่ในนี้",
["common.warning"] = "ระวัง",

-- ── main.lua (boot, updater, virtual-space detection, main loop) ─────────────
["main.exit_active_ops_title"] = "ระวัง: ระบบยังทำงานอยู่",
["main.exit_active_ops_msg"] = "ยังมีอีก %d งานรันอยู่ข้างหลัง\nถ้าฝืนปิดตอนนี้ เกมอาจพังได้",
["main.initializing"] = "กำลังโหลดสคริป...",
["main.no_app_found"] = "ตัวเกมหาไม่เจอ",
["main.arch_64bit_required_title"] = "ใช้แค่ 64-bit เท่านั้น",
["main.arch_64bit_required_msg"] = "บังคับใช้ ARMv8a ส่วนพวก x86_64 รองรับแค่บางส่วน",
["main.update_available_title"] = "อัปเดตใหม่มาแล้ว!",
["main.update_available_msg"] = "เวอร์ชัน v%s มาแล้ว (ตอนนี้ใช้: v%s)\n\n%s\n\nจะอัปเดตเลยไหม?",
["main.no_changelog"] = "ไม่มีรายละเอียดการอัปเดต",
["main.downloading_version"] = "กำลังโหลด v%s...",
["main.update_download_failed_msg"] = "อัปเดตไม่ผ่าน:\n%s",
["main.update_write_failed_msg"] = "เขียนไฟล์ลงที่นี่ไม่ได้:\n%s",
["main.update_done_title"] = "VOID อัปเดตเป็น v%s สําเร็จ",
["main.update_done_msg"] = "อัปเดต VOID สำเร็จแล้ว\n\nไฟล์ใหม่ถูกเซฟไว้ที่:\nvoid_v%s.lua\n\nไปรันต่อใน GameGuardian ได้เลย",
["main.launching_version"] = "กำลังเปิด v%s...",
["main.launch_failed_msg"] = "รันไม่ได้:\n%s",

["main.multiple_spaces_title"] = "เจอแอปโคลนมากกว่า 1",
["main.multiple_spaces_desc"] = "เจอเกม HCR2 ในแอปจำลอง %d ตัว\nเลือกพื้นที่จำลองที่กำลังเล่นอยู่ตอนนี้เลย",
["main.select_space_toast"] = "เลือกพื้นที่จำลองก่อน",
["main.user_space_item"] = "ผู้ใช้ %s  —  %s",
["main.permission_error_title"] = "ระบบปฏิเสธการเข้าถึง",
["main.permission_error_msg"] = "โดนปฏิเสธการเข้าถึง Shell\n\nVOID จำเป็นต้องใช้ส่วนนี้เพื่อหาตำแหน่งเกม HCR2 ในแอปจำลอง เช็คโค้ดของ VOID ได้เลยถ้าอยากรู้ว่าสั่งรันคำสั่งอะไรไปบ้าง",
["main.hcr2_not_found_title"] = "หาข้อมูล HCR2 ไม่เจอ",
["main.hcr2_not_found_msg"] = "VOID หาตำแหน่งไฟล์ข้อมูลเกม HCR2 ในแอปจำลองไม่เจอ อาจเป็นเพราะยังไม่ได้เปิดเกมเลย หรือแอปจำลองใช้โครงสร้างพาธที่ไม่เหมือนชาวบ้าน\n\nพวกฟังก์ชันที่ต้องดึงข้อมูลไฟล์เกม (เช่น รับของรางวัลกิจกรรม) จะใช้งานไม่ได้ถ้าพาธไม่ถูกต้อง",
["main.manual_data_path_title"] = "ใส่ตำแหน่งไฟล์เอง",
["main.manual_data_path_hint"] = "ใส่พาธข้อมูลเกม HCR2",
["main.manual_path_cancelled"] = "ยกเลิกแล้ว — ลุยต่อแบบไม่มีพาธ",
["main.waiting_for_lib"] = "กำลังรอ %s...",
["main.initialized"] = "โหลดระบบเสร็จแล้ว",
["main.gamestatus_not_found"] = "หา GameStatus ไม่เจอ",
["main.dont_interrupt"] = "ห้ามขัดจังหวะการทำงานของสคริปต์นี้",

-- ── ui/ui.lua (framework chrome: menu, cards, dialogs) ────────────────────────
["ui.size_saved_restart"] = "เซฟขนาดเรียบร้อย! รันสคริปต์ใหม่อีกรอบ",
["ui.category_error"] = "เกิดข้อผิดพลาด: %s",
["ui.category_not_found"] = "หาหมวดหมู่ไม่เจอ",
["ui.na"] = "ไม่มีข้อมูล",
["ui.spinner_select"] = "เลือก",
["ui.slider_default_title"] = "ค่าพลัง",

-- ── core/engines/patches.lua (addArchModule patch engine) ────────────────────
["patches.requires_arch"] = "ต้องใช้กับเครื่อง %s (เครื่องของนาย: %s)",
["patches.suffix_enabled"] = " เปิดใช้งานแล้ว",
["patches.suffix_disabled"] = " ปิดใช้งานแล้ว",
["patches.pattern_not_found"] = "ไม่สำเร็จ: หาแพทเทิร์นไม่เจอ %d จุด",

-- ── core/engines/arch.lua (architecture detection warnings) ──────────────────
["arch.warning_title"] = "เตือนเรื่องสถาปัตยกรรมระบบ",
["arch.unknown_arch_msg"] = "ไม่รู้จักสถาปัตยกรรมเครื่อง โหลดไฟล์ lib หรือยัง? หรือใช้ระบบอะไรอยู่?",
["arch.non_primary_arch_msg"] = "ตรวจพบ: %s\nโค้ดแพทช์ lib บางตัวหรือทั้งหมดอาจใช้งานไม่ได้",
["arch.unknown_version_msg"] = "ไม่รู้เวอร์ชันเกม ลองใหม่อีกรอบหลังจากเกมโหลดเสร็จ",
-- แปลงคำยากๆ ให้เป็นแนว Dev คุยกันเข้าใจง่ายขึ้น
["arch.no_base_data_msg"] = "ระบบภายในเอ๋อ: ไม่มีข้อมูลฐานสำหรับสถาปัตยกรรมเครื่องนี้",

-- ── core/engines/scheduler.lua ────────────────────────────────────────────────
["scheduler.task_crashed"] = "ตัวจัดคิวงานเตือน: งานค้างจนระบบพัง -> %s",

-- ── core/utils/paste.lua + catbox.lua (network error strings) ────────────────
["errors.http_error_code"] = "รหัสข้อผิดพลาด HTTP: %s",
["errors.crashed"] = "ระบบพัง: %s",
["errors.url_missing"] = "ลิงก์ URL หายไปหรือเป็นค่าว่าง",
["errors.file_path_missing"] = "ตำแหน่งพาธไฟล์หายไป",
["errors.download_url_missing"] = "ลิงก์ดาวน์โหลดหายไป",
["errors.dest_path_missing"] = "ตำแหน่งพาธปลายทางหายไป",

-- ── modules/registry.lua (sidebar tab labels + module-load error cards) ──────
["tabs.sep_game"] = "เมนูเกม",
["tabs.account"] = "เมนูรหัสี",
["tabs.vehicle"] = "เมนูรถ",
["tabs.player"] = "เมนูรหัสคนเล่น",
["tabs.adventure"] = "เมนูแรงค์ผจญภัย",
["tabs.cups"] = "เมนูแรงค์แข่ง",
["tabs.team"] = "เมนูทีม",
["tabs.event"] = "เมนูอีเว้นต์",
["tabs.creative"] = "เมนูสร้างแมพ",
["tabs.shop"] = "เมน ร้านค้า",
["tabs.other"] = "เมนูอื่นๆ",
["tabs.sep_script"] = "เมนูสคริปต์",
["tabs.settings"] = "ตั้งค่า",
["tabs.about"] = "เกี่ยวกับสคริปต์",

["registry.module_load_failed"] = "โหลดมอดูลไม่ผ่าน เช็ครายละเอียดในล็อกได้เลย",
["registry.module_runtime_error"] = "ระบบรันเอ๋อ: %s",
["registry.error"] = "เกิดข้อผิดพลาด",

-- ── modules/tabs/settings.lua ─────────────────────────────────────────────────
["settings.section_updates"] = "อัปเดต",
["settings.auto_update.title"] = "อัปเดตอัตโนมัติ",
["settings.auto_update.desc"] = "อัปเดต VOID อัตโนมัติเวลาเปิดสคริปต์",
["settings.dev_mode_title"] = "โหมดนักพัฒนา",
["settings.auto_update.dev_mode_msg"] = "ปิดการอัปเดตอัตโนมัติสำหรับไฟล์ main.lua (เวอร์ชันทดสอบ)",
["settings.check_updates.title"] = "เช็คอัปเดต",
["settings.check_updates.desc"] = "เช็คเวอร์ชันใหม่ล่าสุดของ VOID บน GitHub",
["settings.check_updates.dev_mode_msg"] = "ปิดการเช็คอัปเดตสำหรับไฟล์ main.lua (เวอร์ชันทดสอบ)\n\nให้ไปดึงไฟล์จากคลังเก็บเอาเอง",
["settings.check_updates.checking"] = "กำลังเช็คอัปเดต...",
["settings.check_updates.failed_title"] = "เช็คอัปเดตไม่ผ่าน",
["settings.check_updates.failed_msg"] = "เชื่อมต่อกับ GitHub ไม่ได้:\n%s",
["settings.check_updates.up_to_date_title"] = "เวอร์ชันล่าสุดแล้ว",
["settings.check_updates.up_to_date_msg"] = "นายกำลังใช้เวอร์ชันล่าสุดอยู่แล้ว (v%s)",
["settings.check_updates.no_changelog"] = "ไม่มีประวัติการอัปเดตโชว์",
["settings.check_updates.available_msg"] = "v%s  (ตอนนี้ใช้: v%s)\n\n%s\n\nจะโหลดมาทับสคริปต์ตัวเดิมเลยไหม?",
["settings.check_updates.no_asset_msg"] = "หาไฟล์ .lua ไม่เจอในเวอร์ชันที่ปล่อยอัปเดต",
["settings.check_updates.download_failed_title"] = "ดาวน์โหลดไม่ผ่าน",
["settings.check_updates.write_failed_title"] = "เขียนข้อมูลลงไฟล์ไม่ผ่าน",
["settings.check_updates.done_title"] = "เสร็จเรียบร้อย",
["settings.check_updates.done_msg"] = "อัปเดตเป็น v%s แล้ว รันสคริปต์ใหม่อีกรอบเพื่อเริ่มใช้งาน",
["settings.check_updates.restart_button"] = "รันใหม่",

["settings.section_language"] = "ภาษา",
["settings.language.title"] = "ภาษา",
["settings.language.desc"] = "เลือกภาษาที่อยากใช้ในเมนู",
["settings.language.changed"] = "เปลี่ยนภาษาเป็น %s แล้ว",
["settings.language.failed"] = "โหลดภาษานั้นไม่ผ่าน",
["settings.language.restart_msg"] = "รันสคริปต์ใหม่อีกรอบเพื่อเปลี่ยนภาษาให้สมบูรณ์",

["settings.region.other"] = "O: อื่นๆ (แต่ช้า)",
["settings.region.cpp_alloc"] = "Ca: C++ alloc",
["settings.region.unknown"] = "U: ไม่รู้จัก",
["settings.section_memory"] = "หน่วยความจำ (Memory)",
["settings.memory_range.title"] = "ช่วงความจำที่เลือก",
["settings.memory_range.desc"] = "ช่วงความจำที่ใช้อยู่ตอนนี้\n(สคริปต์จะเลือกให้เองอัตโนมัติ)",
["settings.gamestatus.title"] = "ที่อยู่ GameStatus",
["settings.gamestatus.desc"] = "แอดเดรสตำแหน่ง GameStatus ตอนนี้\n(สคริปต์จะเลือกให้เองอัตโนมัติ)",
["settings.gamestatus_raw.title"] = "ตำแหน่ง GameStatus (ดิบ)",
["settings.gamestatus_raw.desc"] = "แอดเดรสตำแหน่ง GameStatus ดิบตอนนี้\n(สคริปต์จะเลือกให้เองอัตโนมัติ)",
["settings.clear_memory.title"] = "ล้างความจำที่เซฟไว้",
["settings.clear_memory.desc"] = "ล้างข้อมูลความจำทั้งหมดที่ VOID เซฟไว้ โดยไม่ต้องกดรีสตาร์ทเกมใหม่ทั้งเกม",

["settings.section_ui_customizations"] = "ปรับแต่งหน้าตาเมนู (UI)",
["settings.theme_store.title"] = "ร้านค้าธีม",
["settings.theme_store.desc"] = "เปิดดูและติดตั้งธีมที่คนในชุมชน VOID ทำแจกไว้",
["settings.theme_store.unreachable_msg"] = "เข้าร้านค้าธีมไม่ได้:\n%s",
["settings.theme_store.parse_failed_msg"] = "อ่านข้อมูลโครงสร้างร้านค้าธีมไม่ผ่าน",
["settings.theme_store.list_title"] = "คลังธีมของ Void",
["settings.theme_store.search_results_desc"] = "ผลการค้นหา: เจอ %s ธีม",
["settings.theme_store.available_desc"] = "มีธีมให้เลือก %s ตัว",
["settings.theme_store.by_author"] = "สร้างโดย %s",
["settings.theme_store.search_item"] = "🔍 ค้นหา...",
["settings.theme_store.clear_search_item"] = "✕ ล้างคำค้นหา",
["settings.theme_store.search_title"] = "ค้นหาธีม",
["settings.theme_store.search_hint"] = "ใส่ชื่อธีม คนสร้าง หรือรายละเอียด",
["settings.theme_store.no_results"] = "ไม่เจอธีมที่ค้นหา: %s",
["settings.theme_store.detail_msg"] = "โดย %s\n\n%s\n\nรหัสธีม: %s",
["settings.theme_store.install_button"] = "ติดตั้งธีมนี้",
["settings.theme_downloading_bg"] = "กำลังโหลดภาพพื้นหลัง...",
["settings.theme_imported"] = "นำเข้าธีมสำเร็จ!",
["settings.theme_invalid_bundle"] = "รูปแบบไฟล์มัดรวมไม่ถูกต้อง",
["settings.theme_cloud_error"] = "เกิดข้อผิดพลาดบนคลาวด์: %s",
["settings.reset_theme.title"] = "รีเซ็ตธีมกลับเป็นค่าเริ่มต้น",
["settings.reset_theme.desc"] = "ล้างค่าธีมและรูปพื้นหลังที่แต่งไว้ กลับไปใช้แบบเดิมๆ โรงงาน",
["settings.import_theme.title"] = "นำเข้าธีมจากคลาวด์",
["settings.import_theme.desc"] = "ดึงข้อมูลธีมจากคลาวด์มาใช้งาน",
["settings.import_theme.hint"] = "ใส่รหัสแชร์ Share ID",
["settings.export_theme.title"] = "ส่งออกธีมไปคลาวด์",
["settings.export_theme.desc"] = "เอาธีมและรูปพื้นหลังที่แต่งไปฝากไว้บนคลาวด์เพื่อแชร์",
["settings.export_theme.share_id_msg"] = "รหัสแชร์ Share ID: %s\n\nก๊อปปี้ลงคลิปบอร์ดให้แล้ว",
["settings.export_theme.upload_failed_msg"] = "อัปโหลดไม่ผ่าน: %s",
["settings.export_theme.size_warning_title"] = "เตือนเรื่องขนาดไฟล์อัปโหลด",
["settings.export_theme.size_warning_msg"] = "จะมัดรวมรูปพื้นหลังไปด้วยไหม? ขนาดไฟล์จะใหญ่ขึ้นตามความละเอียดของรูปภาพนะ จะต่อไหม?",
["settings.export_theme.uploading_bg"] = "กำลังอัปโหลดรูปพื้นหลังไปฝากไว้ที่ Catbox...",
["settings.export_theme.image_upload_failed_title"] = "เกิดข้อผิดพลาด",
["settings.export_theme.image_upload_failed_msg"] = "อัปโหลดรูปภาพไม่ผ่าน: %s",
["settings.tabs_icon.title"] = "ไอคอนแท็บเมนู",
["settings.tabs_icon.desc"] = "เปลี่ยนรูปไอคอนของแท็บหน้าต่างๆ",
["settings.tabs_icon.hint"] = "ใส่โค้ดไอคอน",
["settings.tabs_icon.empty_error"] = "ปล่อยทิ้งเป็นค่าว่างไม่ได้",

["settings.bg_opacity.title"] = "ความโปร่งใสของพื้นหลัง",
["settings.bg_opacity.desc"] = "ปรับความจางของแผงเมนู การ์ดฟังก์ชัน และหัวเมนู",
["settings.slider.alpha"] = "ค่าโปร่งใส",
["settings.bg_image_opacity.title"] = "ความชัดของรูปพื้นหลัง",
["settings.bg_image_opacity.desc"] = "ปรับระดับความชัดเจนของภาพพื้นหลังด้วยการคุมแชนเนลตัวเลขตรงๆ",
["settings.bg_image_picker.title"] = "รูปภาพพื้นหลัง",
["settings.bg_image_picker.desc"] = "กดเพื่อแก้ตำแหน่งพาธไฟล์รูปภาพที่จะเอามาทำเป็นพื้นหลังเมนู",
["settings.bg_image_picker.path_label"] = "พาธไฟล์รูปเต็มๆ (.jpg หรือ .png):",
["settings.bg_image_picker.remove_label"] = "ลบรูปพื้นหลังออก",
["settings.bg_image_picker.success_title"] = "สำเร็จเรียบร้อย",
["settings.bg_image_picker.removed_msg"] = "ลบรูปพื้นหลังออกแล้ว",
["settings.bg_image_picker.added_msg"] = "เพิ่มรูปพื้นหลังแล้ว",
["settings.bg_image_picker.not_found_msg"] = "หาไฟล์ไม่เจอหรือระบบปฏิเสธการอ่านไฟล์:\n%s",

["settings.bg_rgb.title"] = "สีพื้นหลัง (RGB)",
["settings.bg_rgb.desc"] = "ปรับโทนสีหลักของแผงเมนู (ส่วนหัวและการ์ดจะปรับสเกลตามอัตโนมัติ)",
["settings.slider.r"] = "R",
["settings.slider.g"] = "G",
["settings.slider.b"] = "B",
["settings.accent_rgb.title"] = "สีปุ่มและท็อกเกิล (RGB)",
["settings.accent_rgb.desc"] = "ปรับโทนสีของปุ่ม สวิตช์เปิดปิด และการ์ดที่กำลังทำงานอยู่",
["settings.logo_rgb.title"] = "สีไฮไลต์ข้อความ (RGB)",
["settings.logo_rgb.desc"] = "ปรับสีของป้ายกำกับ ไอคอน และข้อความที่กดได้ (สีจะทึบเต็มร้อยตลอด)",
["settings.sub_rgb.title"] = "สีตัวหนังสือรอง (RGB)",
["settings.sub_rgb.desc"] = "ปรับสีคำอธิบาย และชื่อแท็บเมนูที่ไม่ได้เลือก",
["settings.text_rgb.title"] = "สีตัวหนังสือหลัก (RGB)",
["settings.text_rgb.desc"] = "ปรับสีตัวอักษรข้อความหลักในเมนู",

["settings.win_width.title"] = "ความกว้างเมนู",
["settings.win_width.desc"] = "ปรับความกว้างของหน้าต่างเมนูขยับได้ (%d – %d dp)",
["settings.slider.width"] = "ความกว้าง",
["settings.win_height.title"] = "ความสูงเมนู",
["settings.win_height.desc"] = "ปรับความสูงของพื้นที่เลื่อนดูฟังก์ชัน (%d – %d dp)",
["settings.slider.height"] = "ความสูง",

-- ── modules/tabs/about.lua ────────────────────────────────────────────────────
["about.about_script.title"] = "เกี่ยวกับสคริปต์",
["about.about_script.desc"] = "สคริปต์ปรับแต่งและจัดการหน่วยความจำที่ทรงพลังและลื่นไหลสุดๆ ทำมาเพื่อเกม Hill Climb Racing 2 บนแอปจำลอง Pivot โดยเฉพาะ\n\nดาวน์โหลด Pivot ได้ที่นี่เลย:\nhttps://github.com/vekendianorg/pivot/releases/",
["about.script_owner.title"] = "เจ้าของสคริปต์",
["about.script_owner.desc"] = "- Vekendian Organization (github: vekendianorg)",
["about.script_dev.title"] = "ทีมพัฒนาร่วม",
["about.script_dev.desc"] = [[
- Lazor (github: lazor-git)
- AMR (github: amr-gt)
- Erik (github: eomthix)
]],
["about.script_translator.title"] = "คนแปลภาษา",
["about.script_translator.desc"] = [[
- English: Lazor (github: lazor-git)
- Bahasa Indonesia: Lazor (github: lazor-git)
- Español: Jayy2k (github: Jayy2k)
- Deutsch: Erik (github: eomthix)
- Thai: NaiArt777 (github: artphakkapol-hub)
]],
["about.credits.title"] = "เครดิตผู้มีส่วนร่วม",
["about.credits.desc"] = [[
- Lazor (github: lazor-git)
- Lan9118 (discord: lan9118)
- AMR (github: amr-gt)
- Erik (github: eomthix)
- Sr Romero
]],
["about.special_thanks.title"] = "ขอบคุณเป็นพิเศษ",
["about.special_thanks.desc"] = [[
- Aryan/KokushiboModz
]],

-- ── modules/tabs/other.lua ────────────────────────────────────────────────────
["other.debug_mode.title"] = "โหมดดีบักในเกม",
["other.debug_mode.desc"] = "เปิด/ปิดระบบโหมดดีบักภายในตัวเกม",
["other.debug_mode.enabled"] = "เปิดใช้งานโหมดดีบักแล้ว",
["other.debug_mode.disabled"] = "ปิดใช้งานโหมดดีบักแล้ว",
["other.hint.width"] = "ความกว้าง",
["other.hint.height"] = "ความสูง",
["other.resolution.title"] = "ปรับความละเอียดจอ",
["other.resolution.desc"] = "ปรับขนาดความกว้างและความสูงของจอเกม (ค่าเริ่มต้นคือ 1280x720)",
["other.resolution.applied"] = "ปรับความละเอียดจอเป็น %dx%d แล้ว",
["other.resolution_offset.title"] = "ปรับตำแหน่งชดเชยจอ",
["other.resolution_offset.desc"] = "ปรับค่าชดเชยความกว้างและส่วนสูงของจอเกม (ค่าเริ่มต้นคือ 0x0) เหมาะมากสำหรับพวกที่เล่นจอใหญ่แต่ตั้งค่าความละเอียดไว้ต่ำ",
["other.resolution_offset.applied"] = "ปรับค่าชดเชยจอเป็น %dx%d แล้ว",
["other.glsurface_not_found"] = "หา GLSurfaceView ไม่เจอ",

-- ── modules/tabs/shop.lua ─────────────────────────────────────────────────────
["shop.free_chest.title"] = "กล่องสุ่มฟรี",
["shop.free_chest.desc"] = "ทำให้กล่องสุ่มในแท็บร้านค้ากดเปิดได้ฟรีๆ",
["shop.free_chest.enabled"] = "เปิดใช้งานกล่องสุ่มฟรีแล้ว",
["shop.free_chest.disabled"] = "ปิดใช้งานกล่องสุ่มฟรีแล้ว",
["shop.free_purchases.title"] = "ซื้อของฟรี",
["shop.free_purchases.desc"] = "ทำให้พวกดีลข้อเสนอประจำวันบางตัวในร้านค้ากดซื้อได้ฟรี (ใช้กับพวกข้อเสนอพิเศษที่เด้งขึ้นมา หรือพวกป้ายตราสัญลักษณ์ได้ด้วย)",
["shop.free_purchases.progress"] = "%d/%d",
["shop.free_purchases.success"] = "กดซื้อของฟรีสำเร็จแล้ว",
["shop.change_chest.title"] = "เปลี่ยนชนิดกล่องสุ่ม",
["shop.change_chest.desc"] = "เปลี่ยนกล่องระดับตำนาน (Legendary) ให้กลายเป็นกล่องที่นายเลือกแทน",
["shop.change_chest.changed"] = "เปลี่ยนกล่องสุ่มเป็น %s แล้ว",
["shop.change_chest.options"] = {
    "กล่องธรรมดา", "กล่องทั่วไป", "กล่องหายาก", "กล่องมหากาพย์",
    "กล่องแชมป์เปี้ยน", "กล่องพิเศษ 1", "กล่องคริสต์มาส", "กล่องตํานาน",
    "กล่องสีน้ำเงิน", "กล่อง VIP 1", "กล่อง VIP 2", "กล่องโฆษณา",
    "กล่องเริ่มต้น", "กล่องพิเศษ 2", "กล่องฟิงเกอร์ซอฟต์", "กล่องเมก้า",
    "กล่องทีม", "กล่องสไตล", "กล่องลึกลับ"
},

-- ── modules/tabs/player.lua ───────────────────────────────────────────────────
["player.auto_detach.title"] = "ถอดชิ้นส่วนรถอัตโนมัติ",
["player.auto_detach.desc"] = "เอาชิ้นส่วนรถออกอัตโนมัติ เช่น แรลลี้ี่",
["player.no_clip.title"] = "ทะลุของ",
["player.no_clip.desc"] = "ทำให้ตัวละครขับทะลุสิ่งกีดขวางได้โดยไม่ตาย (ขับทะลุเข้าเส้นชัยในโหมดcupsได้เลย)",
["player.no_clip.enabled"] = "เปิดใช้งานทะลุวัตถุแล้ว",
["player.no_clip.disabled"] = "ปิดใช้งานทะลุวัตถุแล้ว",
["player.hide_name.title"] = "ซ่อนชื่อผู้เล่น",
["player.hide_name.desc"] = "ซ่อนชื่อของตัวเองตอนกำลังแข่งอยู่",
["player.hide_name.enabled"] = "เปิดใช้งานซ่อนชื่อแล้ว",
["player.hide_name.disabled"] = "ปิดใช้งานซ่อนชื่อแล้ว",
["player.hide_flag.title"] = "ซ่อนธงประเทศ",
["player.hide_flag.desc"] = "ซ่อนรูปธงชาติของตัวเองตอนอยู่ใน cupsู่",
["player.hide_flag.enabled"] = "เปิดใช้งานซ่อนธงแล้ว",
["player.hide_flag.disabled"] = "ปิดใช้งานซ่อนธงแล้ว",
["player.zoom.title"] = "ปรับระดับกล้อง",
["player.zoom.desc"] = "ปรับระยะความใกล้-ไกลของมุมกล้องในเกม",
["player.slider.min"] = "ใกล้สุด",
["player.slider.max"] = "ไกลสุด",
["player.gravity.title"] = "ปรับแรงโน้มถ่วง",
["player.gravity.desc"] = "ปรับระดับความแรงของแรงโน้มถ่วงในเกม",
["player.slider.x"] = "X",
["player.slider.y"] = "Y",

-- ── modules/tabs/adventure.lua ────────────────────────────────────────────────
["adventure.auto_adventure_chests.title"] = "อัปเวลกล่องผจญภัยออโต้ (ไม่เสถียร)",
["adventure.auto_adventure_chests.desc"] = "เร่งระดับเลเวลกล่องอัตโนมัติ",
["adventure.auto_adventure_chests.none_found"] = "ไม่เจอกล่อง",
["adventure.auto_adventure_chests.done"] = "ทำสําเร็จ",

["adventure.set_distance.title"] = "ตั้งค่าระยะทาง",
["adventure.set_distance.desc"] = "ตั้งค่าระยะทางด่านผจญภัยเป็นค่าที่ต้องการ ต้องกดเปิดตอนที่กำลังแข่งอยู่เท่านั้น ยิ่งระยะทางไกลยิ่งได้ดาวเยอะ ได้ดาวสูงสุดที่ระยะ 5000 เมตร (ไม่ใช่โปรวาร์ป/เทเลพอร์ต)",
["adventure.set_distance.loop_active_title"] = "ตั้งค่าระยะทาง — กำลังวนลูปอยู่",
["adventure.set_distance.loop_active_msg"] = "ระบบกำลังรันวนลูปทับระยะทางอยู่ตอนนี้\nเอายังไงต่อ",
["adventure.set_distance.stop_loop"] = "สั่งหยุดวนลูป",
["adventure.set_distance.keep_running"] = "ปล่อยให้รันต่อไป",
["adventure.set_distance.loop_will_stop"] = "ระบบจะหยุดวนลูปหลังจากจบรอบดีเลย์นี้",
["adventure.set_distance.prompt_target"] = "ระยะทางที่ต้องการตั้ง (หน่วยเป็นเมตร)",
["adventure.set_distance.prompt_loop"] = "ตั้งวนลูป (การหมุนลูป)",
["adventure.set_distance.prompt_interval"] = "ดีเลย์ของการวนลูป (หน่วยมิลลิวิต่ำสุด 250)",
["adventure.set_distance.over_max_title"] = "ระยะทางเกิน",
["adventure.set_distance.over_max_msg"] = "ระยะทางที่ตั้งเกิน 5000 เมตร จะไม่ได้แต้มดาวเพิ่ม\n\nตัวเกมจะบันทึกระยะทางปกติ แต่เต้มดาวจะไม่เพิ่มให้ จะไปต่อไหม?",

}
