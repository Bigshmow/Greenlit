# Greenlit

A World of Warcraft (Retail) addon that flags gear with no remaining progression value, so it's safe to vendor — without ever guessing, and without accidentally throwing away a free upgrade.

Greenlit doesn't recommend best-in-slot gear, compare secondary stats, or auto-vendor anything. It only ever answers one question: can this item still contribute to progression? If it can't say for certain, it says nothing.

## Status

Early alpha. Core rule logic, the cache/event pipeline, and a first pass at the UI (bag/bank badges + tooltip reasons) are all implemented and unit tested, but this has not yet been verified end-to-end in a live client. See `docs/DECISION_LOG.md` for the full history of what's been built and why, and `CLAUDE.md` for current status and the immediate next step.

## How it works

Every armor-slot item you own (equipped, bags, personal bank) is compared against what's currently equipped in that slot, using three rules in order:

1. **Pending free upgrade** — would upgrading this cross a threshold the equipped item hasn't reached, for free or nearly free?
2. **Duplicate suppression** — if multiple items would trigger the same free upgrade, only one is worth holding onto.
3. **Ceiling comparison** — even fully upgraded, does this item have any chance of beating what's already equipped?

If none of the rules fire, Greenlit says nothing — silence is the default, not a bug. Full reasoning for every design decision lives in `docs/DECISION_LOG.md`.

## Development

Read `docs/PRD.md`, `docs/ARCHITECTURE.md`, `docs/DECISION_LOG.md`, and `docs/PHILOSOPHY.md` before making changes — `CLAUDE.md` has the short version and the current working agreements.

**Tests:**
```
.\run-tests.ps1
```
Runs the LuaUnit suite for every pure-logic file (`Config.lua`, all of `src/Rules/`) via a local Lua 5.1 + LuaRocks install. See the Testing section in `CLAUDE.md` for setup details.

**In-game testing:** a directory junction from `AddOns\GreenlitDev` to this repo is the intended workflow — edit, `/reload`, done. See "Local in-game testing" in `CLAUDE.md`.

## License

See `LICENSE`.
