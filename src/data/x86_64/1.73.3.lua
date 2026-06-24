-- data/x86_64/1.73.3.lua — x86_64 baseline for 1.73.3
--
-- AOB patterns are identical to arm64-v8a for this version; only offsets differ.
-- If AOBs ever diverge between arches, add them here explicitly.

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
    },
    offsets = {
        raceInfo = 0x2066508,     -- race info like distance, cd
    },
}
