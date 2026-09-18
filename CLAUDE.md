# CLAUDE.md

Read `docs/PRD.md`, `docs/ARCHITECTURE.md`, `docs/DECISION_LOG.md`, and
`docs/PHILOSOPHY.md` before making or proposing any change. They're short
by design — read all four every session, not just once ever.

## What Greenlit is

A WoW addon that flags gear with no remaining progression value, so it's
safe to vendor — without ever guessing, and without accidentally throwing
away a free upgrade. See `PRD.md` for full scope, and just as importantly,
its Non-Goals for what this deliberately does not do (no BiS
recommendations, no stat comparison, no auto-vendoring).

## Principles (canonical five in PHILOSOPHY.md)

**Conservative** — if unsure, do nothing. **Explainable** — every
recommendation needs a human-readable reason. **Transparent** — no hidden
heuristics. **Focused** — if a feature doesn't answer "can this item still
contribute to progression," it doesn't belong.

## Current status

Every file under `src/` is real, working code, end to end: `Core.lua`
through `Events.lua` populate `Cache.lua` (including an initial full sync
on `PLAYER_ENTERING_WORLD`, not just reacting to changes), `RuleEngine.
EvaluateAll()` runs after every scan trigger, and `UI/Badge.lua`/
`UI/Tooltip.lua` render the results on bag/bank item buttons and
tooltips. `Config.lua`, all three `Rules/` files, and `RuleEngine.lua`
itself have full LuaUnit spec coverage (34 tests, see Testing below);
`Cache.lua`/`Events.lua`/UI files are untested by design (WoW API glue,
not pure logic) — and a pre-commit review specifically checked that they
actually only contain glue, moving two domain decisions (`armorEquipLocs`,
`NormalizeEquipLoc`) that had drifted into `Events.lua` back into
`Config.lua` where they can be tested. That same 2026-09-18 review found
and fixed six real bugs in this session's own code (the missing initial
sync, three nil-input crash risks, one non-deterministic Rule C tiebreak,
and a missing cache invalidation on unequip) — see `DECISION_LOG.md`'s
"pre-commit review" entry for the full list. The `Greenlit.toc` Interface
number is still a placeholder needing verification against the current
live patch.

## Immediate next step

Nothing has been tested in an actual live client yet — all of the above
is logically reviewed and unit-tested where testable, but unverified
against real gameplay. Load it in-game and confirm badges/tooltips
actually appear correctly before anything else. After that, the biggest
known gap is off-spec Equipment Manager awareness (see `PRD.md` Future
Ideas and the RuleEngine entry in `DECISION_LOG.md`).

## Testing

`Config.lua`, the `Rules/*.lua` files, and `RuleEngine.lua` are unit
tested with LuaUnit (pure Lua, no native deps), run via a local Lua 5.1 +
LuaRocks install — not the WoW client. `Cache.lua`/`Events.lua` are pure
WoW API glue and aren't unit tested; that boundary is deliberate (see
Working agreements).

Run all specs from the repo root:
```
.\run-tests.ps1
```
That script sets `PATH`/`LUA_PATH`/`LUA_CPATH` itself (Claude Code's spawned
shells don't reliably see the persisted user/machine env var changes made
when this toolchain was installed), so it works regardless of terminal.

## Working agreements

- When you make a non-trivial design or tradeoff decision, add an entry to
  `docs/DECISION_LOG.md` in the same Decision/Reason format as the
  existing entries, dated. Don't wait to be asked.
- Rule A, Rule B, Rule C, and RuleEngine are pure logic and should be
  written to be testable without a running WoW client. Keep them free of
  direct API calls — `Cache.lua` owns all direct game API access, rules
  just receive plain data.
- Per-item ceilings are always read live from the game API, never
  hardcoded. `Config.lua` holds our own maintained domain data/decisions
  that don't require a running client to evaluate (track order,
  checkpoints, armor-slot classification, equip-loc normalization).
  Runtime-only data (e.g. WoW globals used as table keys) has to stay in
  `Events.lua` even if it looks like plain data, since it can't load
  outside the client to be tested.
- Ceiling ties (including same-track duplicates) always resolve to no
  badge — never guess between stat-equivalent items.
- If the same literal, decision, or check needs to happen in two places,
  it belongs in one shared location, not copy-pasted. Extract when you
  find actual duplication (like `armorEquipLocs`/`NormalizeEquipLoc`
  drifting into `Events.lua`, or badge/tooltip colors diverging across
  two files) — not preemptively, before a second real use case exists.
