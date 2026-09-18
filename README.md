<p align="center">
  <img src="./assets/void.png" alt="Void Logo" width="420"/>
</p>

# 🌌 Void

A modular memory manipulation menu for **Hill Climb Racing 2**, built for the
custom **Pivot** environment (GameGuardian-compatible `gg` API, Lua 5.3).

Download Pivot: https://github.com/vekendianorg/pivot/releases/

---

## ⚠️ Caution

Void provides powerful modification capabilities that may affect account integrity, progression, or game behavior.
By using Void, you acknowledge all associated risks. The developers are not responsible for account bans, suspensions, data loss, or other consequences resulting from its use.

Use at your own risk.

---

## How Void works

Void is not one giant script. It is ~70 Lua modules packed into a single
`void_packed.lua` at build time. At runtime the flow is:

1. **Boot** (`src/main.lua`): logging, constants, core engines, then the
   overlay UI. The loader detects the device architecture and game version,
   and loads the matching offset data from `src/data/` into the global
   `aobs` / `offsets` tables.
2. **Overlay UI** (`src/ui/ui.lua`): a floating window with one tab per menu
   section (Account, Player, Vehicle, Cups, Adventure, Team, Event, Shop,
   Creative, Other, Settings). Every feature is a **card**.
3. **Cards call ops, ops touch memory.** The tab gathers user input, the ops
   module does the memory work on the scheduler, and the tab turns the
   returned status code into a localized toast.

### The two write paths

- **Raw memory**: pointer walks and AOB scans through the `gg` API, for live
  game objects (race state, shop screens, fuel tanks). Fast, but offsets
  move with every game update, so raw ops resolve their addresses through
  the per-version data in `src/data/<arch>/<gamever>.lua`. Cards whose patch
  data is missing for the running version render as "not available for this
  version" instead of crashing.
- **Nebula** (`src/modules/lib/nebula.lua`, vendored): typed access to the
  protobuf-backed save structure. Reads and writes go through dotted paths
  such as `gameStatus.adFree`, with read-back verification. The host seeds
  it with `{ embed = true }` so a failed load is catchable instead of fatal.

---

## Repository layout

```
src/
  main.lua                 entry point and boot order
  ui/ui.lua                overlay framework: tabs, cards, dialogs, toasts
  core/
    env.lua                global environment setup
    engines/               scheduler, storage, resolver, patches,
                           crash handler, loader, alloc
    utils/                 cast, json, lang, webhook, paste, catbox
  modules/
    tabs/<name>.lua        one file per menu tab: builds cards, handles input
    ops/<name>.lua         one file per tab: the memory work behind the cards
    lib/                   shared feature helpers (nebula.lua, raceinfo.lua)
  configs/
    app/lang/en.lua        every user-visible string, one key each
    app/risk.lua           per-card risk level, rendered as a colored pill
    app/credits.lua        language-independent credits content
    app/colors.lua         theme colors
    content/               game content tables (tuning parts, rewards, ...)
  data/
    <arch>/<gamever>.lua   AOB patterns and offsets per game version
    manifest.lua           version resolution and merge rules
```

---

## Cards

A card is created with `addModule(parent, id, title, desc, mode, extra, callback)`:

| Mode     | Widget | Typical use |
|----------|--------|-------------|
| `switch` | on/off toggle | stateful patches, saved across sessions |
| `button` | single action button | one-shot ops (editors, appliers) |
| `input`  | text field(s) on the card, optional number type | value entry, last value saved |
| `slider` | single or multi slider | bounded numeric settings |
| `spinner`| dropdown selector | enum choices, saved |
| `ro`     | read-only text, tap to copy | status displays |
| `nil`    | none | plain info cards |

Input is gathered **on the card** where possible (input, slider, spinner
modes). Dialog prompts (`showPrompt`, `showList`, `showDialog`) are for
mid-flow choices only: multi-step wizards, pickers, and confirmations.

`addArchModule` is a variant for AOB-patch cards: it checks that the patch
data exists for the running game version before rendering the card.

---

## The ops contract

Each tab has exactly one ops module with the same base name
(`tabs/vehicle.lua` + `ops/vehicle.lua`). Ops names match the cards they
implement. The full contract lives in
[`src/modules/ops/README.md`](src/modules/ops/README.md). The short version:

- Ops never call UI functions (`showToast`, `showPrompt`, `t()`, ...).
  They return a **status string**; the tab maps it to a localized message.
- Ops own `scheduler:add`, so memory work serializes on the GG engine.
- User input is gathered by the tab first and passed in via `params`.
- Logic shared by more than one feature goes into `modules/lib/`, never
  duplicated across ops files.

---

## Adding a feature

1. **Strings**: add keys under your tab's section in
   `src/configs/app/lang/en.lua` (`"<tab>.<card>.<key>"`).
2. **Op**: implement `M.featureName(params, cb)` in
   `src/modules/ops/<tab>.lua` following the shape in the ops README.
3. **Card**: wire `addModule(...)` in `src/modules/tabs/<tab>.lua`, map every
   status the op can return to a toast.
4. **Risk**: register the card in `src/configs/app/risk.lua` if it deserves
   a risk pill.
5. **Test**: mock-test the op against fake memory before touching the device
   (see below), then verify on device with a single small change first.
6. **Build**: `python bundle.py -v <version>` and ship the release zip.

---

## Building and testing

```
python bundle.py -v 1.1.0
```

produces `void_packed.lua` with every module embedded. There is no minify
mode on purpose: Nebula's embedded module sources must survive the packer
untouched. Releases are zipped as source + packed file.

Ops are developed against **mock harnesses** (Python + `lupa` running the
same Lua 5.3): fake `gg` memory, a mock scheduler, and planted Nebula
structures. Each harness asserts that writes land in the right fields and
that every documented status path is reachable. On-device testing is still
the final gate for anything that touches live game state: probe a single
field first, then batch.

---

## Localization

All user-visible text is a key in `src/configs/app/lang/en.lua`, loaded
through `T(key, ...)` with `string.format` placeholders (`%s`, `%d`).
Tabs wrap it as `t(key, ...)` with their section prefix. Never hardcode
UI strings in tabs or ops.

---

## Credits

See the About tab in the menu, or `src/configs/app/credits.lua` (the single
source of truth for names, handles and links).
