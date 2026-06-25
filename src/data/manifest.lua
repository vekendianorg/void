-- data/manifest.lua — Version × Architecture data tree
--
-- ── Chain structure ────────────────────────────────────────────────────────────
--
--   [arch] = {
--       chain = {
--           -- Each entry is applied in order, oldest → newest.
--           -- The engine walks up to (and including) the user's game version.
--
--           { version = "1.73.3", file = "data/<arch>/1.73.3.lua", full = true },
--           --   └─ full = true  → complete baseline; resets accumulated state
--           --                     before merging. Use for the first entry in a
--           --                     chain, and whenever a game update rewrites so
--           --                     many AOBs that a diff would be larger than a
--           --                     fresh file.
--
--           { version = "1.73.5", file = "data/<arch>/1.73.5.lua" },
--           --   └─ full absent  → diff only. Only the aobs/offsets keys present
--           --                     in this file overwrite the accumulated state;
--           --                     everything else is kept as-is from earlier
--           --                     entries.
--
--           { version = "1.74.0", file = "data/<arch>/1.74.0.lua", full = true },
--           --   └─ New era, full reset. Users on 1.73.x never reach this entry.
--       },
--   }
--
-- ── Resolution rules ──────────────────────────────────────────────────────────
--
--   Walk the chain from index 1 forward.  Stop the moment an entry's version
--   exceeds the device's game version.  Accumulate changes from every entry
--   visited:
--
--     • full = true  → clear accumulated aobs/offsets, then merge this file.
--     • diff         → merge this file on top of what we already have.
--
--   Result: users on any version in the chain get the exact data built up to
--   their version.  Users on an OLDER version than the first entry get only
--   that first entry's data (the baseline).  Users on a NEWER version than the
--   last entry get the most recent known data + a "newer version" warning —
--   much better than silently running on stale 1.73.3 offsets forever.
--
-- ── When to add what ──────────────────────────────────────────────────────────
--
--   • Game update changes NOTHING for you → add no entry; existing users are
--     unaffected, newer-version users get the last known data + warning.
--
--   • A patch bump shifts ONE offset → append a tiny diff entry containing
--     only that changed key, e.g.:
--       { version = "1.73.5", file = "data/arm64-v8a/1.73.5.lua" }
--     where 1.73.5.lua returns { offsets = { raceInfo = 0x200DEAD } }
--
--   • A minor/major bump rewrites most AOBs → append a full baseline entry:
--       { version = "1.74.0", file = "data/arm64-v8a/1.74.0.lua", full = true }
--     Users still on 1.73.x never walk past their version, so the old data
--     stays alive for them automatically — no deletion needed.
--
-- ── Adding a new arch ─────────────────────────────────────────────────────────
--   1. Create data/<arch>/base.lua (full aobs + offsets).
--   2. Add manifest[<arch>] = { chain = { { version = "...", file = "...", full = true } } }.
--   3. Append diff entries as versions release.  No changes to core/ required.

return {

    ["arm64-v8a"] = {
        chain = {
            { version = "1.73.3", file = "data/arm64-v8a/1.73.3.lua", full = true },
            { version = "1.73.5", file = "data/arm64-v8a/1.73.3.lua", full = true }, -- useless update lol, same lib.
            -- Example future entries (add when a new game update releases):
            -- { version = "1.73.5", file = "data/arm64-v8a/1.73.5.lua" },           -- diff
            -- { version = "1.74.0", file = "data/arm64-v8a/1.74.0.lua", full = true }, -- new era
        },
    },

    ["x86_64"] = {
        chain = {
            { version = "1.73.3", file = "data/x86_64/1.73.3.lua", full = true },
            -- Example future entries:
            -- { version = "1.73.5", file = "data/x86_64/1.73.5.lua" },
        },
    },

}
