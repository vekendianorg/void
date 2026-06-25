-- data/x86_64/1.73.3.lua — x86_64 baseline for v1.73.3

-- AOB patterns and offsets differ from arm64-v8a in every version.
-- If these AOBs change in a future update (e.g. v1.73.5 or later):
-- Create a new file in src/data/x86_64/
-- Name it after the version (e.g. 1.73.5.lua, 1.74.0.lua)

-- All AOBs are for x86_64 except fuel, which is currently a placeholder copied from arm64-v8a.
-- Only raceInfo is x86_64-specific; the remaining offsets are temporary placeholders copied from arm64-v8a.
-- We'll update the remaining ones as soon as we get them.


return {
    aobs = {
        fakeVip = {
            {scan = "h 12 C0 00 55 48 89 E5 41 56 53", offset = 3, patch = "h B0 01 C3", unpatch = "h 55 48 89"},
        },

        fakeUnlock = {
            {scan = "h 92 C0 00 55 48 89 E5 41 57 41 56 41 55 41 54", offset = 3, patch = "h B8 01 00 00 00 C3", unpatch = "h 55 48 89 E5 41 57"},
        },

        autoDetach = {
            {scan = "h C0 41 0F 2E 46 30 76 0B 48 89 DF", offset = 4, patch = "h 46 30 90 90", unpatch = "h 46 30 76 0B"},
        },

        autoWin = {                                                                                                                                                        -- setFirstPos, instantDie
            {scan = "h 60 F3 0F 10 40 4C F3 0F 11 44 24 0C 48", offset = 1, patch = "h C7 44 24 0C 00 00 A0 C0 90 90 90", unpatch = "h F3 0F 10 40 4C F3 0F 11 44 24 0C"}, -- setFirstPos
            {scan = "h 8B 40 60 89 44 24 04", offset = 0, patch = "h 6A 02 8F 44 24 04 90", unpatch = "h 8B 40 60 89 44 24 04"},                                           -- instantDie
        },

        autoDie = {                                                                                               -- freeze, noFuel
            {scan = "h 49 89 47 50 48 8B 43 30", offset = 0, patch = "h 90 90 90 90", unpatch = "h 49 89 47 50"}, -- freeze
            {scan = "h C9 0F 2E C8 76 0A C7 83", offset = 4, patch = "h 90 90", unpatch = "h 76 0A"},             -- noFuel
        },

        forceBoss = {                                                                                                -- Trophy, Legendary
            {scan = "h F8 F3 0F 10 80 28 04 00 00", offset = 5, patch = "h FC FF FF FF", unpatch = "h 28 04 00 00"}, -- Trophy
            {scan = "h F8 F3 0F 10 80 CC 01 00 00", offset = 5, patch = "h FC FF FF FF", unpatch = "h CC 01 00 00"}, -- Legendary
        },

        fuel = {
            {scan = "h 61 56 48 BD 00 C0 22 1E 21 C0 22 1E 00 84 48 1F 00 40 62 1E 60 56 08 BD", offset = 4}, -- arm64-v8a
        },
    },
    offsets = {
        raceInfo = 0x2066508,     -- x86_64
        vnpStats = 0x2060CA0,     -- arm64-v8a
        customTracks = 0x1FE27F0, -- arm64-v8a
    },
}
