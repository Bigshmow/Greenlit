# Architecture

This document covers *how* Greenlit is organized — modules, data flow, and
folder structure. *What* we're building and why lives in `PRD.md`. *Why* we
chose specific tradeoffs lives in `DECISION_LOG.md`.

## Target client

Retail only. No Classic support — the crest/upgrade-track system this
addon is built around doesn't exist there.

## Folder structure

```
Greenlit/
├── Greenlit.toc
├── src/
│   ├── Core.lua                        -- addon lifecycle, slash commands
│   ├── Events.lua                      -- event registration + cheap slot pre-filter
│   ├── Cache.lua                       -- per-slot item state, diffing, invalidation
│   ├── Config.lua                      -- track order + cross-track equivalence checkpoints
│   ├── Rules/
│   │   ├── RuleEngine.lua              -- Evaluate(item) orchestrator
│   │   ├── RuleB_PendingFreeUpgrade.lua
│   │   ├── RuleC_DuplicateSuppression.lua
│   │   └── RuleA_CeilingComparison.lua
│   └── UI/
│       ├── Badge.lua                   -- renders the Vendor Candidate badge
│       └── Tooltip.lua                 -- renders Reasons[] on hover
├── docs/
│   ├── PRD.md
│   ├── PHILOSOPHY.md
│   ├── DECISION_LOG.md
│   └── ARCHITECTURE.md
├── spec/                                -- LuaUnit tests for pure-logic files only
│   ├── helpers/
│   │   └── load_addon_file.lua
│   ├── Config_spec.lua
│   └── rules/
│       ├── RuleA_CeilingComparison_spec.lua
│       ├── RuleB_PendingFreeUpgrade_spec.lua
│       ├── RuleC_DuplicateSuppression_spec.lua
│       └── RuleEngine_spec.lua
├── README.md
├── LICENSE
└── .gitignore
```

`src/` doesn't exist yet — this structure is the target for when Lua work
starts, not a description of what's in the repo today.

## Data flow

```
Events.lua
  ↓ (cheap equipLoc pre-filter via C_Item.GetItemInfoInstant)
Cache.lua
  ↓ (diffs against last-known state, requests + queues uncached item data,
     invalidates a slot's whole evaluation set on equip change)
Rules/RuleEngine.lua — Evaluate(item)
  ↓ Rule B (pending free upgrade) → Rule C (duplicate suppression)
    → Rule A (strict ceiling comparison) → otherwise, silence
Evaluation { candidate, reasons[], rule }
  ↓
UI/Badge.lua, UI/Tooltip.lua (pure consumers, no logic of their own)
```

## Module responsibilities

**Core.lua** — addon lifecycle (`ADDON_LOADED`), any SavedVariables setup
(none anticipated for V1), and a slash command for a manual rescan.

**Events.lua** — registers `PLAYER_ENTERING_WORLD`, `BAG_UPDATE_DELAYED`,
`PLAYER_EQUIPMENT_CHANGED`, `GET_ITEM_INFO_RECEIVED`, `BANKFRAME_OPENED`,
and `PLAYERBANKSLOTS_CHANGED`. Runs the cheap `equipLoc` check first so
non-armor-slot items never reach the more expensive upgrade-info reads.
`PLAYER_ENTERING_WORLD` does the one-time initial sync (all currently
equipped slots + bags) that nothing else would ever trigger — every other
event only reacts to something *changing*, so without this, a player who
logs in and never re-equips anything would never get a single evaluation.

**Cache.lua** — maintains the known-item map across equipped + bags +
personal bank (single character, V1 scope). Diffs on every relevant event.
If an item's data isn't cached yet (`C_Item.IsItemDataCachedByID`), queues it
and retries on `GET_ITEM_INFO_RECEIVED`. On `PLAYER_EQUIPMENT_CHANGED`,
invalidates every cached evaluation for that *entire slot*, not just the
one item that changed — the comparison target moved for everything in bags
too.

**Config.lua** — the track order (Adventurer < Veteran < Champion < Hero <
Myth), the cross-track equivalence checkpoint table (e.g. "Champion max
== Hero rank 2"), and every other piece of Greenlit's own domain data or
decision that doesn't require a running WoW client to evaluate — e.g.
`armorEquipLocs` (which equip-locs Greenlit cares about at all) and
`NormalizeEquipLoc` (merging robe into chest, since they compete for the
same slot). The dividing line with `Cache.lua`/`Events.lua` isn't "reads
data" vs "doesn't" — `Config.lua` also gets read by those files — it's
whether the logic itself needs the live client to run and be tested. Data
that's tied to the runtime (e.g. numeric equipment-slot constants that
only exist as WoW globals) stays in `Events.lua` instead, since it can't
be loaded standalone for a test even if it looks like plain data. Track
order and checkpoints are the one part of this file expected to need a
hand-edit every time Blizzard shifts the numbers mid-patch or mid-season.
Per-item ceilings themselves are never stored here — those are always
read live from the game's own API.

**Rules/RuleEngine.lua** — `Evaluate(item)`, the single entry point. Runs
each rule in order and returns as soon as one produces a decisive result:

1. **Rule B — Pending Free Upgrade.** Would upgrading this item cross a
   watermark checkpoint the equipped item hasn't reached yet? If yes: hold,
   not a candidate, with the reason.
2. **Rule C — Duplicate Suppression.** Among items already flagged by Rule
   B as a checkpoint trigger, only one per (slot, track) group is kept —
   the rest fall through to Rule A, since the crest cost to finish any
   duplicate is fixed regardless of drop rank.
3. **Rule A — Ceiling Comparison.** Compare this item's max-rank ceiling
   (read live) against the best already-owned item's ceiling in the same
   slot, via track+rank position, never raw ilvl integers. Strict
   inequality only — ties (including same-track duplicates) produce no
   result, not a vendor badge.
4. **Otherwise:** no Evaluation at all. Silence is a valid, and the most
   common, outcome — Conservative means "if unsure, do nothing" all the way
   down to "if no rule fires, don't badge it."

Each rule is its own file with a single responsibility, so any one of them
can be read, tested, or corrected without touching the others — this
matches Explainable and Transparent directly: if a badge is wrong, there's
exactly one rule file to check.

**UI/Badge.lua, UI/Tooltip.lua** — consume the `Evaluation` object and
render it. They contain no decision logic themselves; they only know how to
display `candidate` and `reasons[]`.

## The Evaluation object

```lua
Evaluation = {
  candidate = true,        -- boolean core signal (per Decision Log: no
                            -- separate scored Confidence field)
  reasons = { "..." },      -- human-readable strings, always present when
                            -- candidate is true
  rule = "RuleA",           -- which rule produced this result, for
                            -- debugging / explainability
}
```

A `nil` Evaluation (no table returned at all) means no rule fired — this is
the Conservative default and is expected to be the most common return
value in practice.

## Known unknowns going into implementation

These are still research tasks, not architecture decisions — carried over
from the PRD, now with a home to be resolved into as they're answered:

- Exact behavior of the crest-discount/watermark system at the API level
  (confirmed to exist; exact API-level read path not yet verified in code)
- Cache timing edge cases beyond the basic `IsItemDataCachedByID` /
  `GET_ITEM_INFO_RECEIVED` pattern
- Whether `C_Item.GetItemInfoInstant`'s `equipLoc` reliably distinguishes
  shields from other offhands (Decision Log: shields excluded pending
  confirmation)
- The actual current track order and cross-track equivalence checkpoints
  for `Config.lua` — deliberately left unseeded; verify against current
  live patch notes rather than carrying over anything from an earlier
  research pass, since these values drift patch to patch
