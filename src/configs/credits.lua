-- configs/credits.lua — Single source of truth for all arch-universal about/credits content.
--
-- These keys are language-independent (names, handles, URLs) and are shared
-- across every lang file. They are injected into T() as a base layer BEFORE
-- the English fallback, so lang files never need to define them.
--
-- To update a credit: edit here only. All languages update automatically.

return {

-- ── Script owner ──────────────────────────────────────────────────────────
["about.script_owner.desc"] = "- Vekendian Organization (github: vekendianorg)",

-- ── Script developers ─────────────────────────────────────────────────────
["about.script_dev.desc"] = [[
- Lazor (github: lazor-git)
- AMR (github: amr-gt)
- Erik (github: eomthix)
]],

-- ── Translators ───────────────────────────────────────────────────────────
-- One entry per language. Names and handles are not translated.
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

-- ── Credits ───────────────────────────────────────────────────────────────
["about.credits.desc"] = [[
- Lazor (github: lazor-git)
- Lan9118 (discord: lan9118)
- AMR (github: amr-gt)
- Erik (github: eomthix)
- Sr Romero
- Profinoobru
]],

-- ── Special thanks ────────────────────────────────────────────────────────
["about.special_thanks.desc"] = [[
- Aryan/KokushiboModz
]],

}
