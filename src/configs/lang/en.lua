--[[
  configs/lang/en.lua — English (default/fallback language)

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

  This file is the always-present fallback: every other language file only
  needs to cover the keys it has translations for. Missing keys silently
  fall back to English.
]]

return {

-- ── Common / shared (buttons, generic dialog text) ───────────────────────────
["common.ok"] = "OK",
["common.cancel"] = "Cancel",
["common.yes"] = "Yes",
["common.no"] = "No",
["common.failed"] = "Failed",
["common.success"] = "Success",
["common.later"] = "Later",
["common.got_it"] = "Got it",
["common.retry"] = "Retry",
["common.wait_safe"] = "Wait (Safe)",
["common.waiting"] = "Waiting...",
["common.force_exit"] = "Force Exit",
["common.proceed_anyway"] = "Proceed Anyway",
["common.manual_mode"] = "Manual Mode",
["common.update_button"] = "UPDATE",
["common.launch_failed"] = "Launch Failed",
["common.confirm_exit_title"] = "Confirm Exit",
["common.confirm_exit_msg"] = "Exit The Script?",
["common.not_available"] = "Not Available",
["common.warning"] = "Warning",

-- ── main.lua (boot, updater, virtual-space detection, main loop) ─────────────
["main.exit_active_ops_title"] = "Warning: Active Operations",
["main.exit_active_ops_msg"] = "There are %d background task(s) running.\nForce exit may corrupt game state.",
["main.initializing"] = "Initializing...",
["main.no_app_found"] = "No app found",
["main.arch_64bit_required_title"] = "64-bit Required",
["main.arch_64bit_required_msg"] = "ARMv8a is mandatory. x86_64 is partially supported.",

["main.update_available_title"] = "Update Available",
["main.update_available_msg"] = "v%s is available (current: v%s)\n\n%s\n\nUpdate now?",
["main.no_changelog"] = "No changelog.",
["main.downloading_version"] = "Downloading v%s...",
["main.update_download_failed_msg"] = "Could not download the update:\n%s",
["main.update_write_failed_msg"] = "Could not write to:\n%s",
["main.update_done_title"] = "VOID Updated to v%s",
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
- Русский: Winter Lotus(github: Ohranik1Pitorochki; discord:nikolaypg67)
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
["player.fuel.title"] = "Set Fuel Amount",
["player.fuel.desc"] = "Set a constant fuel value during race (0.0 – 100.0)",
["player.fuel.hint"] = "Fuel (0 – 100)",
["player.fuel.invalid"] = "Invalid value, must be 0 – 100",
["player.fuel.applied"] = "Fuel locked to %s",
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
["adventure.set_distance.continue_button"] = "Continue",
["adventure.set_distance.not_in_adventure"] = "Go to Adventure tab and start a race first",
["adventure.set_distance.start_race_first"] = "Start a race first",
["adventure.set_distance.applied"] = "Distance set: %sm",
["adventure.set_distance.loop_stopped"] = "Set Distance loop stopped.",
["adventure.set_distance.loop_running"] = "Distance loop running — tap Set Distance to stop",

-- ── modules/tabs/cups.lua ─────────────────────────────────────────────────────
["cups.adjust_countdown.title"] = "Adjust Countdown",
["cups.adjust_countdown.desc"] = "Adjust the countdown before starting race",
["cups.slider.seconds"] = "Seconds",
["cups.adjust_countdown.applied"] = "Countdown adjusted to %ss",
["cups.auto_win.title"] = "Auto Win",
["cups.auto_win.desc"] = "Automatically win no matter what your race results is",
["cups.force_boss.title"] = "Force Boss",
["cups.force_boss.desc"] = "Force boss always appears",
["cups.force_cup.title"] = "Force Cup",
["cups.force_cup.desc"] = "Forces a single cup",
["cups.force_cup.not_found"] = "Force Cup not found. Try again later.",
["cups.force_cup.enabled"] = "Force Cup Enabled",
["cups.force_cup.disabled"] = "Force Cup Disabled",
["cups.unlimited_tasks.title"] = "Unlimited Tasks",
["cups.unlimited_tasks.desc"] = "Freeze all tasks as completed and always claimable. Claim rewards repeatedly.",
["cups.unlimited_tasks.resolve_failed"] = "Failed to resolve task list",
["cups.unlimited_tasks.none_found"] = "No tasks found",
["cups.unlimited_tasks.enabled"] = "Unlimited Tasks Enabled",
["cups.unlimited_tasks.disabled"] = "Unlimited Tasks Disabled",
["cups.unlimited_tasks.none_to_freeze"] = "No tasks to freeze",
["cups.rank_points_bonus.title"] = "+498 Rank Points",
["cups.rank_points_bonus.desc"] = "Make all league tasks gives you 498 points instead of 200 points, also remove other rewards.",
["cups.rank_points_bonus.none_found"] = "No league tasks found",
["cups.rank_points_bonus.boosted"] = "Rank points boosted: %s",
["cups.rank_points_bonus.no_match"] = "No matching league tasks found",
["cups.rank_points_bonus.nothing_to_restore"] = "Nothing to restore",
["cups.rank_points_bonus.restored"] = "Restored: %s",

-- ── modules/tabs/event.lua ────────────────────────────────────────────────────
["event.patch_rewards.title"] = "Event Rewards Patch",
["event.patch_rewards.desc"] = "Patch the current public event rewards to custom one provided by VOID (require game restart)",
["event.restore_events.title"] = "Event Rewards Restore",
["event.restore_events.desc"] = "Delete modified event JSONs to force game server recovery (requires game restart)",

["event.checking_permissions"] = "Checking environment permissions...",
["event.scanning_files"] = "Scanning active files...",
["event.decode_rewards_failed"] = "Failed to decode rewards JSON",
["event.workspace_creation_failed"] = "FATAL: Workspace creation failed: %s",
["event.workspace_creation_failed_dialog"] = "FATAL: Could not create workspace directory.\n%s",
["event.file_inaccessible"] = "File inaccessible at path: %s",
["event.predecrypt_not_found"] = "Pre-decrypt: source not found: %s",
["event.predecrypt_empty"] = "Pre-decrypt: source is empty (0 bytes): %s",
["event.decode_active_failed"] = "Failed to decode active_events.json at path: %s",
["event.no_active_events"] = "No active events found at path: %s",
["event.cannot_open_active"] = "Cannot open active_events.json at path: %s",
["event.decrypt_active_failed"] = "Failed to decrypt active_events.json at path: %s",
["event.root_copy_failed"] = "Root copy failed: %s",

["event.select_events_patch"] = "Select events to patch:\nPath: %s",
["event.user_cancelled"] = "User cancelled selection for path: %s",
["event.rewards_unavailable"] = "Embedded rewards not available, skipping patches for path: %s",
["event.skipped_unreadable"] = "Skipped unreadable event: %s",
["event.predecrypt_event_not_found"] = "Pre-decrypt: event not found: %s",
["event.predecrypt_event_empty"] = "Pre-decrypt: event is empty (0 bytes): %s",
["event.processing_failed"] = "Failed processing %s: %s",
["event.cannot_open_decrypted"] = "Cannot open decrypted file: %s",
["event.decrypt_event_failed"] = "Failed to decrypt event: %s",
["event.loop_crash"] = "Critical file processing loop crash: %s",

["event.success_header"] = "Successfully:",
["event.success_removed_header"] = "Successfully Removed (Will Restore on Restart):",
["event.success_item"] = "- %s",
["event.success_item_json"] = "- %s.json",
["event.failed_header"] = "Failed:",
["event.failed_item"] = "- %s",

["event.patch_results_title"] = "Patch Results",
["event.restore_results_title"] = "Restore Results",
["event.restart_required_title"] = "Restart Required",
["event.patch_restart_msg"] = "Game is killed and this script gonna exit, start it again and see the patch effects",
["event.restore_restart_msg"] = "Game will now close to allow server file synchronization.",
["event.finishing_tasks_patch"] = "Finishing pending background tasks... Please wait.",
["event.finishing_tasks_restore"] = "Finishing pending background tasks...",
["event.patch_failed_msg"] = "Failed to patch, try again.",

["event.select_events_restore"] = "Select files to restore (delete):\nPath: %s",
["event.delete_failed"] = "Failed to delete %s: %s",

-- ── modules/tabs/account.lua ──────────────────────────────────────────────────
["account.change_name.title"] = "Change Name",
["account.change_name.desc"] = "Change your player name",
["account.change_name.hint"] = "Enter Name",
["account.change_name.empty"] = "Enter a name first",
["account.change_name.too_long_title"] = "Name Too Long",
["account.change_name.too_long_msg"] = "Your name is too long, please shorten it",
["account.change_name.resolve_failed"] = "Failed to resolve name pointer",
["account.change_name.applied"] = "Name changed to %s",

["account.change_gp.title"] = "Change Garage Power",
["account.change_gp.desc"] = "Changes profile garage power (persists if higher). Set to 8 to reset if over max, but only if your actual GP is already fixed under the limit.",
["account.change_gp.hint"] = "Enter Garage Power",
["account.change_gp.max_int_title"] = "Max 32bit int Reached",
["account.change_gp.lower_value"] = "Please lower your value",
["account.change_gp.too_low_title"] = "Too Low",
["account.change_gp.higher_value"] = "Please higher your value",
["account.change_gp.applied"] = "Garage Power has been changed to %s",

["account.fake_unlock.title"] = "Fake Unlock",
["account.fake_unlock.desc"] = "Unlock all customizations temporarily",
["account.fake_vip.title"] = "Fake VIP",
["account.fake_vip.desc"] = "Toggle vip subscription state locally",
["account.fake_rank.title"] = "Fake Rank",
["account.fake_rank.desc"] = "Set your rank to fake legendary automatically",
["account.fake_rank.applied"] = "Fake Rank has been injected.",


-- ── modules/tabs/vehicle.lua ──────────────────────────────────────────────────
["vehicle.parts_slot.title"] = "Adjust Parts Slot",
["vehicle.parts_slot.desc"] = "Adjust the parts slot for all vehicles",
["vehicle.parts_slot.slider_title"] = "Slots",
["vehicle.parts_slot.no_vehicles"] = "No vehicles found",
["vehicle.parts_slot.applied"] = "Parts slot adjusted: %d vehicles",

["vehicle.unlock_vehicles.title"] = "Unlock Vehicles",
["vehicle.unlock_vehicles.desc"] = "Unlock all vehicles to be available to purchase with coins",
["vehicle.unlock_vehicles.no_vehicles"] = "No vehicles found",
["vehicle.unlock_vehicles.unlocked"] = "Vehicles unlocked: %d",
["vehicle.unlock_vehicles.none_to_unlock"] = "No vehicles to unlock",

["vehicle.max_vehicles.title"] = "Max Vehicles",
["vehicle.max_vehicles.desc"] = "Max all unlocked vehicles upgrade levels instantly",
["vehicle.max_vehicles.no_vehicles"] = "Failed to resolve vehicle list",
["vehicle.max_vehicles.all_maxed"] = "All vehicles maxed",
["vehicle.max_vehicles.failed"] = "Failed to max vehicles",

["vehicle.max_mastery.title"] = "Max Mastery",
["vehicle.max_mastery.desc"] = "Max all unlocked and maxed vehicles masteries instantly.",
["vehicle.max_mastery.all_maxed"] = "All masteries maxed",
["vehicle.max_mastery.failed"] = "Failed to max masteries",

["vehicle.max_parts.title"] = "Max Parts",
["vehicle.max_parts.desc"] = "Max all unlocked parts levels for all vehicles instantly.",
["vehicle.max_parts.no_vehicles"] = "Failed to resolve vehicle list",
["vehicle.max_parts.all_maxed"] = "All parts maxed",
["vehicle.max_parts.failed"] = "Failed to max parts",

["vehicle.common.no_vehicles"] = "No vehicles found",
["vehicle.common.progress"] = "%d/%d",
["vehicle.common.resolve_list_failed"] = "Failed to resolve vehicle list",
["vehicle.common.no_zero_region"] = "No zero region found",

}
