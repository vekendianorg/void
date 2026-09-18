# Changelog
## v1.1.0

Updated:
- RaceInfo resolver (Set Distance / Set Time) rewritten to the GameStatus-holder method: finds the native race controller by locating GameStatus* holders (holder - 0x88 -> manager -> controller, shape-validated). No longer anchored at the per-version BaseLib offsets.raceInfo data offset, so lib changes need no offset upkeep here
- Nebula SDK vendored build updated to v1.0.1 (RaceInfo fix: full nested metadata snapshots — levelDefinition, worldDefinition, currentCup, vehicleSpecificRecords array, Proto2 subtrees with indirect strings)
- Nebula SDK vendored build updated to v1.0.0 (encapsulated, auto-resolving metadata for 1.73/1.74)
- Ad-free migrated to Nebula.PlayerInfo ("gameStatus.adFree" dotted path) — GameStatus module no longer exists
- Team size bypass and ad-free now read-back verify their writes

Removed:
- bundle.py minify mode (-m) — pre-packed lib builds (e.g. the Nebula SDK) embed module sources in long strings that comment-stripping would corrupt

## v1.0.23

Added:
- Parts Modifier
- Set Fuel
- Speed Hack
- Set Time
- Any Theme Objects
- Show Hidden Objects
- Copy Any Track
- Track Editor
- Change Aspect Ratio
- Console
- Runtime Translation Completeness Calculation

Optimized:
- Fake vip (1 byte edit)
- Ui loading
- Codebase

Maybe there's more.
