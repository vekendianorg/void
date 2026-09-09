--==================================================
-- configs/app/risk.lua — per-card risk levels
--==================================================
-- Rendered as a colored pill on each card by ui.lua (buildRiskPill).
-- Levels: very_low | low | medium | high | very_high (colors in colors.lua).
-- Cards not listed here render without a badge. A card can also pass
-- opts.risk to addModule() to override this registry.

return {
    -- Account tab
    change_name = "low", change_gp = "medium", fake_rank = "medium",
    ad_free = "low", change_ws = "medium",

    -- Adventure tab
    free_adventure_shop = "low", auto_adventure_chests = "medium",

    -- Cups tab
    adjust_countdown = "low", force_cup = "low", force_frenzy_mode = "low",
    unlimited_tasks = "medium", rank_points_bonus = "very_high",

    -- Player tab
    no_clip = "low", hide_name = "low", hide_flag = "low",
    speed_hack = "medium", zoom = "very_low", gravity = "medium",

    -- Shop tab
    free_chest = "low", free_purchases = "medium", change_chest = "low",

    -- Team tab
    team_size_bypass = "low",
    
    -- Event tab
    patch_rewards = "low", restore_events = "very_low",

    -- Vehicle tab
    parts_slot = "medium", max_mastery = "medium", max_parts = "medium",
    max_vehicles = "medium", unlock_vehicles = "low",

    -- Creative / Other tabs
    any_theme_objects = "low", show_hidden_objects = "low",
    debug_mode = "low", aspect_ratio = "very_low",
    resolution = "very_low", resolution_offset = "very_low", mods_packs = "medium",

    -- AOB-patch cards (addArchModule)
    fake_vip = "low", fake_unlock = "low",
    auto_detach = "medium", auto_die = "low", fuel = "medium",
    set_distance = "medium", copy_any = "low", track_editor = "low",
    parts_modifier = "medium", set_time = "high",
    auto_win = "medium", force_boss = "medium",
}