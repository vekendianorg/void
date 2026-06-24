-- data/x86_64/1.73.3.lua — x86_64 baseline for 1.73.3
--
-- AOB patterns are identical to arm64-v8a for this version; only offsets differ.
-- If AOBs ever diverge between arches, add them here explicitly.

return {
    aobs = {
        fakeVip = {
            {scan = "h 93 D6 01 F9 68 B2 40 39 1F 01 00 71", offset = 4, patch = "h 28 00 80 52", unpatch = "h 68 B2 40 39"},
        },

        fakeUnlock = {
            {scan = "h 36 C5 40 F9", pattern = { { offset = 0x164, valid = {"h E0 03 1F 2A"} }, { offset = 0x16C, valid = {"h 20 00 80 52"} } }, offset = 0x164, patch = "h 20 00 80 52", unpatch = "h E0 03 1F 2A"},
        },

        autoDetach = {
            {scan = "h 08 20 20 1E 85 00 00 54 E0 03 13 AA E1 03 14 AA", offset = 4, patch = "h 1F 20 03 D5", unpatch = "h 85 00 00 54"},
        },

        autoWin = {
            {scan = "h E8 5F 5D A9 16 61 40 B9", offset = 4, patch = "h 55 00 80 52", unpatch = "h 16 61 40 B9"},
            {scan = "h E0 5F 40 F9 09 4D 40 BD", offset = 4, patch = "h 0A 90 32 1E", unpatch = "h 09 4D 40 BD"},
        },

        autoDie = {
            {scan = "h 60 56 08 BD 60 56 48 BD 08 20 20 1E", offset = 12, patch = "h 00 00 80 52", unpatch = "h 45 00 00 54"},
            {scan = "h 60 56 08 BD 60 56 48 BD 08 20 20 1E", offset = 16, patch = "h 60 56 08 B9", unpatch = "h 7F 56 08 B9"},
        },

        forceBoss = {
            {scan = "h 00 CD 41 BD FD 7B C1 A8 C0 03 5F D6", offset = 0, patch = "h 00 C1 5F BC", unpatch = "h 00 CD 41 BD"},
            {scan = "h 00 29 44 BD FD 7B C1 A8 C0 03 5F D6", offset = 0, patch = "h 00 C1 5F BC", unpatch = "h 00 29 44 BD"},
        },

        fuel = {
            {scan = "h 61 56 48 BD 00 C0 22 1E 21 C0 22 1E 00 84 48 1F 00 40 62 1E 60 56 08 BD", offset = 4},
        },
    },
    offsets = {
        raceInfo     = 0x2066508, -- x86_64-specific
        vnpStats     = 0x2060CA0,
        customTracks = 0x1FE27F0,
    },
}
