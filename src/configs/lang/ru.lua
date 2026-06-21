--[[
  configs/lang/ru.lua — Russian 

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

    This file handles the Russian localization for the VOID script.
]]

return {

-- ── Common / shared (buttons, generic dialog text) ───────────────────────────
["common.ok"] = "OK",
["common.cancel"] = "Отмена",
["common.yes"] = "Да",
["common.no"] = "Нет",
["common.failed"] = "Ошибка",
["common.success"] = "Обработано",
["common.later"] = "Позже",
["common.got_it"] = "Получить это",
["common.retry"] = "Повторить",
["common.wait_safe"] = "Подождать (Безопаснее)",
["common.waiting"] = "Подождите...",
["common.force_exit"] = "Принудительный выход",
["common.proceed_anyway"] = "Всё равно начать",
["common.manual_mode"] = "Ручной режим",
["common.update_button"] = "Обновление",
["common.launch_failed"] = "Launch Failed",
["common.confirm_exit_title"] = "Confirm Exit",
["common.confirm_exit_msg"] = "Закрыть скрипт?",
["common.not_available"] = "Недоступен",
["common.warning"] = "ПРЕДУПРЕЖДЕНИЕ",

-- ── main.lua (boot, updater, virtual-space detection, main loop) ─────────────
["main.exit_active_ops_title"] = "Warning: Active Operations",
["main.exit_active_ops_msg"] = "There are %d background task(s) running.\nForce exit may corrupt game state.",
["main.initializing"] = "Инициализация...",
["main.no_app_found"] = "Приложение не обнаружено",
["main.arch_64bit_required_title"] = "64-bit необходимо",
["main.arch_64bit_required_msg"] = "ARMv8a is mandatory. x86_64 is partially supported.",

["main.update_available_title"] = "Доступно обновление!",
["main.update_available_msg"] = "v%s is available (current: v%s)\n\n%s\n\nОбновить сейчас?",
["main.no_changelog"] = "No changelog.",
["main.downloading_version"] = "Загружаем v%s...",
["main.update_download_failed_msg"] = "Could not download the update:\n%s",
["main.update_write_failed_msg"] = "Could not write to:\n%s",
["main.update_done_title"] = "VOID обновлён до v%s",
["main.update_done_msg"] = "VOID has been updated successfully.\n\nThe new script has been saved as:\nvoid_v%s.lua\n\nRun it from GameGuardian to apply the update.",
["main.launching_version"] = "Launching v%s...",
["main.launch_failed_msg"] = "Downloaded but could not run:\n%s",

["main.multiple_spaces_title"] = "Multiple Spaces Detected",
["main.multiple_spaces_desc"] = "HCR2 was found in %d virtual spaces.\nSelect the space you are currently playing in.",
["main.select_space_toast"] = "Please select a space to continue.",
["main.user_space_item"] = "User %s  —  %s",
["main.permission_error_title"] = "Permission Error",
["main.permission_error_msg"] = "Shell access was denied.\n\nVoid needs this to locate HCR2 in your virtual space. Check Void source code if you want to verify what command is being run.",
["main.hcr2_not_found_title"] = "HCR2 Data Not Found",
["main.hcr2_not_found_msg"] = "Void couldn't locate HCR2 data in your virtual space. This may happen if HCR2 hasn't been launched yet, or your virtual space app uses an unusual path structure.\n\nFeatures that rely on game files (Event Rewards, etc.) will not work without a valid path.",
["main.manual_data_path_title"] = "Manual Data Path",
["main.manual_data_path_hint"] = "Enter the HCR2 data path",
["main.manual_path_cancelled"] = "Cancelled — proceeding without path.",
["main.waiting_for_lib"] = "Waiting for %s...",
["main.initialized"] = "Initialized",
["main.gamestatus_not_found"] = "GameStatus Not Found",
["main.dont_interrupt"] = "Don't interrupt this script",

-- ── ui/ui.lua (framework chrome: menu, cards, dialogs) ────────────────────────
["ui.size_saved_restart"] = "Size saved! Restart the script",
["ui.category_error"] = "Error: %s",
["ui.category_not_found"] = "Category Not Found",
["ui.na"] = "N/A",
["ui.spinner_select"] = "Select",
["ui.slider_default_title"] = "Value",

-- ── core/engines/patches.lua (addArchModule patch engine) ────────────────────
["patches.requires_arch"] = "Requires %s device (your device: %s)",
["patches.suffix_enabled"] = " Enabled",
["patches.suffix_disabled"] = " Disabled",
["patches.pattern_not_found"] = "Failed: %d pattern(s) not found",

-- ── core/engines/arch.lua (architecture detection warnings) ──────────────────
["arch.warning_title"] = "Architecture Warning",
["arch.unknown_arch_msg"] = "Your architecture is unknown. Is the lib loaded? What system are you using?",
["arch.non_primary_arch_msg"] = "Detected: %s\nSome or all lib-patches may not work.",
["arch.unknown_version_msg"] = "Game version unknown. Try again after the game loads.",
["arch.no_base_data_msg"] = "Internal error: no base data available for this architecture.",

-- ── core/engines/scheduler.lua ────────────────────────────────────────────────
["scheduler.task_crashed"] = "Scheduler Warning: Task crashed -> %s",

-- ── core/utils/paste.lua + catbox.lua (network error strings) ────────────────
["errors.http_error_code"] = "HTTP Error Code: %s",
["errors.crashed"] = "Crashed: %s",
["errors.url_missing"] = "URL parameter is missing or empty",
["errors.file_path_missing"] = "File path is missing",
["errors.download_url_missing"] = "URL is missing",
["errors.dest_path_missing"] = "Destination path is missing",

-- ── modules/registry.lua (sidebar tab labels + module-load error cards) ──────
["tabs.sep_game"] = "GAME MENU",
["tabs.account"] = "ACCOUNT MENU",
["tabs.vehicle"] = "VEHICLE MENU",
["tabs.player"] = "PLAYER MENU",
["tabs.adventure"] = "ADVENTURE MENU",
["tabs.cups"] = "CUPS MENU",
["tabs.team"] = "TEAM MENU",
["tabs.event"] = "EVENT MENU",
["tabs.creative"] = "CREATIVE MENU",
["tabs.shop"] = "SHOP MENU",
["tabs.other"] = "OTHER MENU",
["tabs.sep_script"] = "SCRIPT MENU",
["tabs.settings"] = "SETTINGS",
["tabs.about"] = "ABOUT",

["registry.module_load_failed"] = "Module failed to load. Check logs for details.",
["registry.module_runtime_error"] = "Runtime error: %s",
["registry.error"] = "Error",

-- ── modules/tabs/settings.lua ─────────────────────────────────────────────────
["settings.section_updates"] = "Updates",
["settings.auto_update.title"] = "Auto Update",
["settings.auto_update.desc"] = "Auto update VOID on startup",
["settings.dev_mode_title"] = "Dev Mode",
["settings.auto_update.dev_mode_msg"] = "Auto update is disabled for main.lua (dev build).",
["settings.check_updates.title"] = "Check for Update",
["settings.check_updates.desc"] = "Check for the latest VOID release on GitHub",
["settings.check_updates.dev_mode_msg"] = "Update check is disabled for main.lua (dev build).\n\nPull from the repo manually.",
["settings.check_updates.checking"] = "Checking for updates...",
["settings.check_updates.failed_title"] = "Update Check Failed",
["settings.check_updates.failed_msg"] = "Could not reach GitHub:\n%s",
["settings.check_updates.up_to_date_title"] = "Up to date",
["settings.check_updates.up_to_date_msg"] = "You are already on the latest version (v%s).",
["settings.check_updates.no_changelog"] = "No changelog available.",
["settings.check_updates.available_msg"] = "v%s  (current: v%s)\n\n%s\n\nDownload and replace this script?",
["settings.check_updates.no_asset_msg"] = "No .lua asset found in the release.",
["settings.check_updates.download_failed_title"] = "Download Failed",
["settings.check_updates.write_failed_title"] = "Write Failed",
["settings.check_updates.done_title"] = "Done",
["settings.check_updates.done_msg"] = "Updated to v%s. Restart the script to apply.",
["settings.check_updates.restart_button"] = "Restart",

["settings.section_language"] = "Language",
["settings.language.title"] = "Language",
["settings.language.desc"] = "Choose your preferred language for the menu",
["settings.language.changed"] = "Language set to %s",
["settings.language.failed"] = "Failed to load that language",
["settings.language.restart_msg"] = "Restart the script to fully apply the language",

["settings.region.other"] = "O: Other",
["settings.region.cpp_alloc"] = "Ca: C++ alloc",
["settings.region.unknown"] = "U: Unknown",
["settings.section_memory"] = "Memory",
["settings.memory_range.title"] = "Memory Range",
["settings.memory_range.desc"] = "Current selected memory range\n(automatically chosen by script)",
["settings.gamestatus.title"] = "GameStatus",
["settings.gamestatus.desc"] = "Current gamestatus address\n(automatically chosen by script)",
["settings.gamestatus_raw.title"] = "GameStatus (Raw)",
["settings.gamestatus_raw.desc"] = "Current gamestatus (raw) address\n(automatically chosen by script)",
["settings.clear_memory.title"] = "Clear Saved Memory",
["settings.clear_memory.desc"] = "Clear all VOID saved memory without needed to restart the whole game.",

["settings.section_ui_customizations"] = "UI Customizations",
["settings.theme_store.title"] = "Theme Store",
["settings.theme_store.desc"] = "Browse and install community Void themes",
["settings.theme_store.unreachable_msg"] = "Could not reach theme store:\n%s",
["settings.theme_store.parse_failed_msg"] = "Could not parse theme store data.",
["settings.theme_store.list_title"] = "Void Theme Store",
["settings.theme_store.search_results_desc"] = "Search results: %s found",
["settings.theme_store.available_desc"] = "%s themes available",
["settings.theme_store.by_author"] = "by %s",
["settings.theme_store.search_item"] = "🔍 Search...",
["settings.theme_store.clear_search_item"] = "✕ Clear search",
["settings.theme_store.search_title"] = "Search Themes",
["settings.theme_store.search_hint"] = "Theme name, author or description",
["settings.theme_store.no_results"] = "No themes found for: %s",
["settings.theme_store.detail_msg"] = "By %s\n\n%s\n\nID: %s",
["settings.theme_store.install_button"] = "Install Theme",
["settings.theme_downloading_bg"] = "Downloading background image...",
["settings.theme_imported"] = "Theme imported!",
["settings.theme_invalid_bundle"] = "Invalid bundle format.",
["settings.theme_cloud_error"] = "Cloud error: %s",
["settings.reset_theme.title"] = "Reset Theme",
["settings.reset_theme.desc"] = "Reset custom theme and background image to the default",
["settings.import_theme.title"] = "Import Theme",
["settings.import_theme.desc"] = "Import custom theme from cloud",
["settings.import_theme.hint"] = "Enter Share ID",
["settings.export_theme.title"] = "Export Theme",
["settings.export_theme.desc"] = "Export custom theme and background image to cloud",
["settings.export_theme.share_id_msg"] = "Share ID: %s\n\nCopied to clipboard.",
["settings.export_theme.upload_failed_msg"] = "Upload failed: %s",
["settings.export_theme.size_warning_title"] = "Upload Size Warning",
["settings.export_theme.size_warning_msg"] = "Include custom background image? It will increase the Upload Size depending what size is your image is.",
["settings.export_theme.uploading_bg"] = "Uploading background image to Catbox...",
["settings.export_theme.image_upload_failed_title"] = "Error",
["settings.export_theme.image_upload_failed_msg"] = "Image upload failed: %s",
["settings.tabs_icon.title"] = "Tabs Icon",
["settings.tabs_icon.desc"] = "Change tabs icon",
["settings.tabs_icon.hint"] = "Enter Icon",
["settings.tabs_icon.empty_error"] = "Cannot be empty",

["settings.bg_opacity.title"] = "Background Opacity",
["settings.bg_opacity.desc"] = "Transparency of panels, cards, and header",
["settings.slider.alpha"] = "Alpha",
["settings.bg_image_opacity.title"] = "Background Image Opacity",
["settings.bg_image_opacity.desc"] = "Adjust visibility alpha settings directly using pure integer channels.",
["settings.bg_image_picker.title"] = "Background Image",
["settings.bg_image_picker.desc"] = "Tap to modify the absolute file path destination for your custom layout background image",
["settings.bg_image_picker.path_label"] = "Absolute Image File Path (.jpg or .png):",
["settings.bg_image_picker.remove_label"] = "Remove BG Image",
["settings.bg_image_picker.success_title"] = "Successfully",
["settings.bg_image_picker.removed_msg"] = "Background Image Removed",
["settings.bg_image_picker.added_msg"] = "Background image added",
["settings.bg_image_picker.not_found_msg"] = "File not found or read operation refused:\n%s",

["settings.bg_rgb.title"] = "Background RGB",
["settings.bg_rgb.desc"] = "Hue for panel backgrounds (Header and Card scale automatically)",
["settings.slider.r"] = "R",
["settings.slider.g"] = "G",
["settings.slider.b"] = "B",
["settings.accent_rgb.title"] = "Accent RGB",
["settings.accent_rgb.desc"] = "Tint for buttons, toggles, and active cards (muted color auto-derived)",
["settings.logo_rgb.title"] = "Highlight RGB",
["settings.logo_rgb.desc"] = "Color for labels, icons, and interactive text (always fully opaque)",
["settings.sub_rgb.title"] = "Sub-text RGB",
["settings.sub_rgb.desc"] = "Color for descriptions and inactive tab labels",
["settings.text_rgb.title"] = "Text RGB",
["settings.text_rgb.desc"] = "Color for main menu text",

["settings.win_width.title"] = "Menu Width",
["settings.win_width.desc"] = "Width of the floating menu (%d – %d dp)",
["settings.slider.width"] = "Width",
["settings.win_height.title"] = "Menu Height",
["settings.win_height.desc"] = "Height of the scrollable content area (%d – %d dp)",
["settings.slider.height"] = "Height",

-- ── modules/tabs/about.lua ────────────────────────────────────────────────────
["about.about_script.title"] = "About Script",
["about.about_script.desc"] = "A powerful and highly optimized memory manipulation script built for Hill Climb Racing 2 on the custom Pivot environment.\n\nDownload Pivot:\nhttps://github.com/vekendianorg/pivot/releases/",
["about.script_owner.title"] = "Script Owner",
["about.script_owner.desc"] = "- Vekendian Organization (github: vekendianorg)",
["about.script_dev.title"] = "Script Developer",
["about.script_dev.desc"] = [[
- Lazor (github: lazor-git)
- AMR (github: amr-gt)
- Erik (github: eomthix)
]],
["about.script_translator.title"] = "Script Translator",
["about.script_translator.desc"] = [[
- English: Lazor (github: lazor-git)
- Bahasa Indonesia: Lazor (github: lazor-git)
- Español: Jayy2k (github: Jayy2k)
- Deutsch: Erik (github: eomthix)
- Thai: NaiArt777 (github: artphakkapol-hub)
]],
["about.credits.title"] = "Credits",
["about.credits.desc"] = [[
- Lazor (github: lazor-git)
- Lan9118 (discord: lan9118)
- AMR (github: amr-gt)
- Erik (github: eomthix)
- Sr Romero
]],
["about.special_thanks.title"] = "Special Thanks",
["about.special_thanks.desc"] = [[
- Aryan/KokushiboModz
]],

-- ── modules/tabs/other.lua ────────────────────────────────────────────────────
["other.debug_mode.title"] = "Debug Mode",
["other.debug_mode.desc"] = "Toggle the in-game debug mode",
["other.debug_mode.enabled"] = "Debug Mode Enabled",
["other.debug_mode.disabled"] = "Debug Mode Disabled",
["other.hint.width"] = "Width",
["other.hint.height"] = "Height",
["other.resolution.title"] = "Adjust Resolution",
["other.resolution.desc"] = "Adjust the game width and height (default is 1280x720)",
["other.resolution.applied"] = "Resolution set to %dx%d",
["other.resolution_offset.title"] = "Adjust Resolution Offset",
["other.resolution_offset.desc"] = "Adjust the game width offset and height offset (default is 0x0), best for small resolution in a large screen.",
["other.resolution_offset.applied"] = "Resolution offset set to %dx%d",
["other.glsurface_not_found"] = "GLSurfaceView not found",

-- ── modules/tabs/shop.lua ─────────────────────────────────────────────────────
["shop.free_chest.title"] = "Free Chest",
["shop.free_chest.desc"] = "Make the chests free in Shop Tab",
["shop.free_chest.enabled"] = "Free Chest Enabled",
["shop.free_chest.disabled"] = "Free Chest Disabled",
["shop.free_purchases.title"] = "Free Purchases",
["shop.free_purchases.desc"] = "Make some daily deals purchases free in the shop tab (also works for special offers as popup/badges)",
["shop.free_purchases.progress"] = "%d/%d",
["shop.free_purchases.success"] = "Free Purchase Successful",
["shop.change_chest.title"] = "Change Chest",
["shop.change_chest.desc"] = "Change legendary chest to selected chest",
["shop.change_chest.changed"] = "Chest changed to %s",
["shop.change_chest.options"] = {
    "Common Chest", "Uncommon Chest", "Rare Chest", "Epic Chest",
    "Champion Chest", "Special Chest 1", "Xmas Chest", "Legendary Chest",
    "Blue Chest", "VIP Chest 1", "VIP Chest 2", "Video Chest",
    "Starter Chest", "Special Chest 2", "Fingersoft Chest", "Mega Chest",
    "Team Spirit Chest", "Style Chest", "Mythic Chest"
},

-- ── modules/tabs/player.lua ───────────────────────────────────────────────────
["player.auto_detach.title"] = "Auto Detach",
["player.auto_detach.desc"] = "Automatically detach parts like the Rally Car roof",
["player.no_clip.title"] = "No-Clip",
["player.no_clip.desc"] = "Make your player go through objects without dying (You can go over the finish lines in cups)",
["player.no_clip.enabled"] = "No-Clip Enabled",
["player.no_clip.disabled"] = "No-Clip Disabled",
["player.hide_name.title"] = "Hide Name",
["player.hide_name.desc"] = "Hide your player name at race",
["player.hide_name.enabled"] = "Hide Name Enabled",
["player.hide_name.disabled"] = "Hide Name Disabled",
["player.hide_flag.title"] = "Hide Flag",
["player.hide_flag.desc"] = "Hide your player flag at race",
["player.hide_flag.enabled"] = "Hide Flag Enabled",
["player.hide_flag.disabled"] = "Hide Flag Disabled",
["player.zoom.title"] = "Adjust Zoom",
["player.zoom.desc"] = "Adjust how close or far your camera",
["player.slider.min"] = "Min",
["player.slider.max"] = "Max",
["player.gravity.title"] = "Adjust Gravity",
["player.gravity.desc"] = "Adjust how strong is the gravity",
["player.slider.x"] = "X",
["player.slider.y"] = "Y",

-- ── modules/tabs/adventure.lua ────────────────────────────────────────────────
["adventure.auto_adventure_chests.title"] = "Auto Adventure Chests (unstable)",
["adventure.auto_adventure_chests.desc"] = "Automatically level up your adventure chests",
["adventure.auto_adventure_chests.none_found"] = "No adventure chests found",
["adventure.auto_adventure_chests.done"] = "Done",

["adventure.set_distance.title"] = "Set Distance",
["adventure.set_distance.desc"] = "Sets your Adventure race distance to a custom value. Must be in an active race. Higher distance can gain more stars. Max stars at 5000m. (Not a teleport function)",
["adventure.set_distance.loop_active_title"] = "Set Distance — Loop Active",
["adventure.set_distance.loop_active_msg"] = "The distance loop is currently running.\nWhat do you want to do?",
["adventure.set_distance.stop_loop"] = "Stop Loop",
["adventure.set_distance.keep_running"] = "Keep Running",
["adventure.set_distance.loop_will_stop"] = "Loop will stop after current tick.",
["adventure.set_distance.prompt_target"] = "Target distance (meters)",
["adventure.set_distance.prompt_loop"] = "Loop (auto re-apply)",
["adventure.set_distance.prompt_interval"] = "Loop interval (ms, min 250)",
["adventure.set_distance.over_max_title"] = "Distance Warning",
["adventure.set_distance.over_max_msg"] = "Distance over 5000m won't give you any stars.\n\nThe race will still register the distance, but no star rewards will be given. Continue?",
["adventure.set_distance.continue_button"
