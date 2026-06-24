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
- Lazor (discord: vekendian)
- AMR (discord: amrgg)
- Erik (discord: eomthix)
]],

-- ── Translators ───────────────────────────────────────────────────────────
-- One entry per language. Names and handles are not translated.
["about.script_translator.desc"] = [[
- English: Lazor (discord: vekendian)
- Bahasa Indonesia: Lazor (discord: vekendian)
- Español: Jayy2k (github: Jayy2k)
- Deutsch: Erik (discord: eomthix)
- Русский: Winter Lotus (discord:nikolaypg67)
           profinoobru (discord: profinoobru)
- Thai: NaiArt777 (discord: 4r77y_888)
- বাংলা: AMR (discord: amrgg)
- العربية: AMR (discord: amrgg)
- اردو: AMR (discord: amrgg)
- Français: AMR (discord: amrgg)
- Українська: AMR (discord: amrgg)
- Türkçe: AMR (discord: amrgg)
- Português (Brasil): AMR (discord: amrgg)
- हिन्दी: AMR (discord: amrgg)
- Italiano: AMR (discord: amrgg)
]],

-- ── Credits ───────────────────────────────────────────────────────────────
["about.credits.desc"] = [[
- Lazor (discord: vekendian)
- Lan9118 (discord: lan9118)
- AMR (discord: amrgg)
- Erik (discord: eomthix)
- Sr Romero
- Profinoobru
]],

-- ── Special thanks ────────────────────────────────────────────────────────
["about.special_thanks.desc"] = [[
- Aryan/KokushiboModz
]],

}
