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

Scaffolding complete: `Greenlit.toc` and empty stub files for every module
under `src/` exist per `ARCHITECTURE.md`'s folder structure. No real rule
logic has been written yet.

## Immediate next step

Start filling in real logic, beginning with `Config.lua` (track order +
cross-track equivalence checkpoints, verified against current live patch
notes — deliberately left unseeded, see `DECISION_LOG.md`) since the rule
files depend on it. The `Greenlit.toc` Interface number is also still a
placeholder and needs verifying against the current live Retail patch.

## Working agreements

- When you make a non-trivial design or tradeoff decision, add an entry to
  `docs/DECISION_LOG.md` in the same Decision/Reason format as the
  existing entries, dated. Don't wait to be asked.
- Rule A, Rule B, and Rule C are pure logic and should be written to be
  testable without a running WoW client. Keep them free of direct API
  calls — `Cache.lua` owns all direct game API access, rules just receive
  plain data.
- Per-item ceilings are always read live from the game API, never
  hardcoded. Only track order and cross-track equivalence checkpoints
  belong in `Config.lua` as our own maintained data.
- Ceiling ties (including same-track duplicates) always resolve to no
  badge — never guess between stat-equivalent items.
