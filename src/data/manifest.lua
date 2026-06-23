-- data/manifest.lua — Version × Architecture data tree
--
-- ── Structure ─────────────────────────────────────────────────────────────
--
--   [arch] = {
--       default_base = "data/<arch>/base.lua",  -- REQUIRED. Also marks this
--                                                 -- arch as supported (its
--                                                 -- presence = arch_t exists).
--
--       [major] = {
--           [minor] = {
--               base = "data/<arch>/base_X.Y.lua",  -- OPTIONAL. New full
--                                                     -- baseline for this
--                                                     -- X.Y era. Omit to
--                                                     -- inherit default_base.
--
--               [patch] = "data/<arch>/vX.Y.Z.lua",  -- OPTIONAL. Diff-only
--                                                      -- override, merged on
--                                                      -- top of `base` above.
--           },
--       },
--   }
--
--   major/minor/patch are STRING keys ("1", "73", "3"), taken verbatim from
--   the game's versionName "1.73.3".
--
-- ── Resolution (see core/engines/arch.lua) ───────────────────────────────────
--
--   1. arch_t = manifest[DEVICE_ARCH], or manifest[DEFAULT_ARCH] if the
--      current arch has no entry (with a warning — lib patches likely
--      won't match on the wrong arch's base).
--
--   2. minor_t = arch_t[major][minor], or {} if that major/minor combo
--      isn't mapped yet (brand new version — falls through to step 3/4
--      with no override, using default_base as-is).
--
--   3. base_path = minor_t.base or arch_t.default_base
--      → loaded as the full baseline.
--
--   4. override_path = minor_t[patch] (may be nil)
--      → if present, shallow-merged on top of base per `aobs` group key
--        and per `offsets` key.
--
-- ── When to add what ─────────────────────────────────────────────────────────
--
--   • Most patch bumps change NOTHING → no entry needed at all. They fall
--     through to default_base (or the era's `base`) untouched.
--
--   • A patch bump shifts ONE offset → add a tiny diff file under
--     [major][minor][patch], e.g. v1.73.3.lua containing just that key.
--
--   • A minor/major bump rewrites everything (new lib, new AOB bytes
--     everywhere) → write a fresh full base_X.Y.lua ONCE, point
--     [major][minor].base at it. Subsequent patches in that era go back
--     to being tiny diffs against THIS new base.
--
-- ── Adding a new arch ───────────────────────────────────────────────────────
--   1. Create data/<arch>/base.lua (full aobs + offsets).
--   2. Add manifest[<arch>] = { default_base = "data/<arch>/base.lua" }.
--   3. Add version entries as needed — no changes to core/ required.

return {

    ["arm64-v8a"] = {
        default_base = "data/arm64-v8a/1.73.3.lua",

        ["1"] = {
            ["73"] = {
                ["3"] = "data/arm64-v8a/1.73.3.lua",
            },
            
        },
    },
    
    ["x86_64"] = {
        default_base = "data/x86_64/1.73.3.lua",

        ["1"] = {
            ["73"] = {
                ["3"] = "data/x86_64/1.73.3.lua",
            },
            
        },
    },
}
