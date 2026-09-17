# Greenlit PRD

## 1. Problem Statement

After running dungeons, raids, or Delves, players accumulate equipment that
may or may not still have progression value. Determining whether an item can
be safely vendored requires understanding item level, upgrade tracks, crest
discount rules, and currently owned equipment. This creates unnecessary
cognitive load and slows routine inventory cleanup.

## 2. Goal

Help players confidently identify equipment that no longer has progression
value.

Not:
- Sell gear.
- Recommend upgrades.
- Optimize DPS.

Just this.

## 3. Non-Goals

Greenlit does not:
- Recommend best-in-slot gear.
- Compare secondary stats.
- Recommend upgrades.
- Auto vendor equipment.
- Replace Pawn, Raidbots, or SimulationCraft.
- Manage inventory.
- Manage equipment sets.
- Make decisions based on class/spec tuning.

## 4. Core Principles

**Conservative** — If Greenlit is unsure, it does nothing.

**Explainable** — Every recommendation must have a human-readable
explanation.

**Transparent** — No hidden heuristics.

**Focused** — Every feature must answer: "Can this item still contribute to
progression?" If not, it probably doesn't belong.

## 5. MVP

**Supports**
- Armor slots only
- Item level
- Upgrade tracks
- Upgrade ranks

**Excludes**
- Rings
- Trinkets
- Weapons
- Offhands
- Stat evaluation

**Badge**: `Vendor Candidate`

**Tooltip**:
```
Reason: Higher Hero-track item already owned.
No remaining progression value.
```

## 6. Rule Engine

We don't define the rules yet. Instead:

```
Rule Interface

Evaluate(item)
  ↓
Evaluation
  Candidate
  Confidence
  Reasons[]
```

That way we don't lock ourselves into implementation. (See
`ARCHITECTURE.md` once it exists for the actual rule pipeline as it's
designed.)

## 7. Technical Assumptions

**Known APIs**
- `C_Item.GetItemUpgradeInfo`
- `ItemLocation`
- Equipment slot APIs

**Unknowns**
- High-watermark API behavior
- Cache timing
- Async item loading

These become research tasks.

## 8. Future Ideas

Nothing in this section blocks v1.

- BetterBags integration
- Baganator integration
- Previous expansion reagent rules
- Custom vendor rules
- Dejunk integration
- Plugin API
- Settings
- Badge customization
- Warband / account-wide gear evaluation (deferred fast-follow after MVP)
- Off-spec Equipment Manager set awareness (confirmed feasible via
  `C_EquipmentSet`, deferred fast-follow)
- Crest-cost / upgrade-efficiency guidance (separate from whether an item
  has progression value at all)

## A note on document structure

This PRD is intentionally scoped to "what are we building and why." How it's
organized (modules, data flow, folder structure) lives in
`ARCHITECTURE.md`. Why we made specific tradeoffs lives in
`DECISION_LOG.md`. Five bullets of principle with nothing technical in them
live in `PHILOSOPHY.md`.
