-- configs/credits.lua — Single source of truth for all arch-universal about/credits content.
--
-- These keys are language-independent (names, handles, URLs) and are shared
-- across every lang file. They are injected into T() as a base layer BEFORE
-- the English fallback, so lang files never need to define them.
--
-- To update a credit: edit here only. All languages update automatically.
-- Use contactable handles/links (Discord, Telegram, etc.) rather than GitHub profiles.

return {

-- ── Script owner ──────────────────────────────────────────────────────────
["about.script_owner.desc"] = "- Vekendian Organization (Github: vekendianorg)",

-- ── Script developers ─────────────────────────────────────────────────────
["about.script_dev.desc"] = [[
- Lazor (Discord: vekendian)
- AMR (Discord: amrgg)
- Erik (Discord: eomthix)
]],

-- ── Translators ───────────────────────────────────────────────────────────
-- One entry per language. Names and handles are not translated.
["about.script_translator.desc"] = [[
- English: Lazor (Discord: vekendian)
- Bahasa Indonesia: Lazor (Discord: vekendian)
- Español: Jayy2k (Discord: j4yc5b)
- Deutsch: Erik (Discord: eomthix)
- Русский: Winter Lotus (Discord: nikolaypg67)
           profinoobru (Discord: profinoobru)
- Thai: NaiArt777 (Discord: 4r77y_888)
- বাংলা: AMR (Discord: amrgg)
- العربية: AMR (Discord: amrgg)
- اردو: AMR (Discord: amrgg)
- Français: AMR (Discord: amrgg)
- Українська: AMR (Discord: amrgg)
- Türkçe: AMR (Discord: amrgg)
- Português (Brasil): AMR (Discord: amrgg)
]],

-- ── Credits ───────────────────────────────────────────────────────────────
["about.credits.desc"] = [[
- Lazor (Discord: vekendian)
- Lan9118 (Discord: lan9118)
- AMR (Discord: amrgg)
- Erik (Discord: eomthix)
- Sr Romero
- Profinoobru
]],

-- ── Special thanks ────────────────────────────────────────────────────────
["about.special_thanks.desc"] = [[
- Aryan/KokushiboModz: (Discord: kokushibomodz)
]],

}
