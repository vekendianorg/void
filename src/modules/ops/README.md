# `modules/ops/` — feature logic layer

Each game feature is split across two files with the **same base name**:

| Layer | Location | Responsibility |
|---|---|---|
| **UI** | `modules/tabs/<name>.lua` | Builds the cards, gathers user input (prompts, dialogs, pickers), shows toasts, calls `done()`. |
| **Ops** | `modules/ops/<name>.lua` | The memory / file work. No UI calls. |

> Not to be confused with `src/core/` — that's the **framework** (engines, utils,
> shared libs). `modules/ops/` is the per-feature logic that those engines run.

A tab loads its ops module non-fatally so one broken feature can't take down the
menu:

```lua
local ops = CrashHandler.loadFeature("modules/ops/<name>.lua")
```

## The ops/UI contract

Each op has the shape:

```lua
function M.opName(params, cb)
    scheduler:add(function(finishTask)
        ... memory work, decide a `status` string ...
        finishTask()
        cb(status, data)        -- data optional (count, value, ...)
    end)
end
```

Rules:

- Ops **never** call `showToast` / `showDialog` / `showPrompt` / `showList` / `t()`.
  They return a `status` code; the tab maps it to the localized message.
- Ops own `scheduler:add` (these must serialize on the GG engine).
- User input (prompts, confirm dialogs, pickers) is gathered in the **tab**
  *before* calling ops, and passed in via `params`.
- Quick synchronous reads used only to gate UI (e.g. "are we on the Cups tab?")
  are exposed as plain functions that return immediately.
- Mid-pipeline UI that's unavoidable (e.g. the event picker) is handled by
  passing a small `ui` callback table into the op — see `ops/event.lua`.

The fully worked reference is [`ops/account.lua`](account.lua).

## Shared helpers

Logic shared by more than one feature lives in `src/modules/lib/` (e.g.
`raceinfo.lua`, the race-info pointer resolver used by both `cups` and
`adventure`), not duplicated across ops files.
