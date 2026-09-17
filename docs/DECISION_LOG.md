# Decision Log

Every time we intentionally choose something, we write it down here — so
that six months from now we don't have to reconstruct why.

## 2026-09-16

**Decision:** Ignore trinkets in MVP.
**Reason:** Item level alone is insufficient to determine progression value.

**Decision:** No auto-selling.
**Reason:** Greenlit evaluates. Other addons can perform vendor actions.

**Decision:** No stat weights.
**Reason:** Outside project scope.

## 2026-09-17

**Decision:** Confidence is a binary go/no-go signal, not a scored scale
(capped at at most 2 levels).
**Reason:** A sliding confidence score invites threshold-tuning, which
contradicts the Conservative and Focused principles. Only surface a badge
when the recommendation is certain; otherwise say nothing.

**Decision:** Warband / account-wide gear evaluation is deferred to a
fast-follow, not part of V1.
**Reason:** Get single-character correctness bulletproof first before
expanding the evaluated pool.

**Decision:** Shields are excluded from evaluation for now, treated like
offhands.
**Reason:** Ambiguous how the API classifies them; needs confirmation before
committing logic either way.

**Decision:** Compare items via track + rank *position*, using explicit
equivalence checkpoints between tracks, rather than raw item-level integers.
**Reason:** Raw ilvl values change every season and sometimes mid-season.
Track order (Adventurer < Veteran < Champion < Hero < Myth) is stable;
only the checkpoint table needs updating when Blizzard shifts numbers.

**Decision:** Per-item ceilings are always read live from the game API,
never computed from a static ilvl table we maintain ourselves. Only track
ordering and cross-track equivalence checkpoints are our own config data.
**Reason:** Matches the Transparent principle (no hidden heuristics, no
stale hardcoded numbers) and means unusual items (e.g. Great Vault / bonus
roll items that start above normal crest-progression ceilings) are handled
correctly without any special-casing.

**Decision:** Product framing is "cleanup / safety-net addon that prevents
accidentally vendoring away a free upgrade," not a progression-value
analyzer or a mini Raidbots.
**Reason:** Keeps the tool's job narrow and matches how the core rules
actually behave — they catch mistakes, they don't score gear.

**Decision:** The Evaluation result stays object-shaped, with a 0/1
(boolean-like) Candidate signal at its core, without being tightly coupled
to a single bare boolean field.
**Reason:** Leaves room to restructure later without breaking every
consumer of the result.

**Decision:** Ceiling ties — including duplicate items on the same track —
are always left unbadged, never marked as a vendor candidate.
**Reason:** A tie means Greenlit cannot know which item is actually better
without secondary-stat comparison, which is explicitly out of scope
(Non-Goals). Silence, not a guess.

**Decision:** Rule pipeline order is **Rule B (pending free upgrade) → Rule
C (duplicate suppression) → Rule A (strict ceiling comparison) → otherwise,
silence.**
**Reason:** Matches the actual manual process a player follows: check
whether an item is holding an uncaptured free upgrade before ever asking
whether it's simply obsolete.

**Decision:** Duplicate suppression (Rule C) keeps exactly one item per
(slot, track) group that's being held solely to trigger a free upgrade;
every other duplicate in that group is a vendor candidate. No "closest to
max rank" tiebreaker is needed.
**Reason:** The crest cost to finish upgrading any duplicate of a given
track to max rank is fixed, regardless of the rank it dropped at — so no
duplicate is meaningfully "closer" to triggering the free upgrade than
another. Only one copy is ever needed.

**Decision:** V1 baseline for comparison is equipped + bags + personal bank,
on a single character. This is a V1 requirement, not a fast-follow.
**Reason:** Get the most holistic view of what's actually available to the
character, within the constraint of only using what the player has exposed
to the addon (single character, not warband).

**Decision:** V1 evaluates against currently-equipped-right-now only;
off-spec Equipment Manager sets are not consulted, so items belonging to an
unequipped spec's set may be misjudged. Confirmed feasible via
`C_EquipmentSet` API for a fast-follow.
**Reason:** Handling multiple saved equipment sets correctly would require
Rule A's "currently equipped" concept to become "best relevant item across
all saved sets for this slot," which meaningfully complicates every rule
designed so far. Documented explicitly as a known V1 limitation rather than
a silent gap.

**Decision:** Evaluation triggers on any inventory- or equipment-changing
event, but is slot-scoped first via a cheap `equipLoc` check (via
`C_Item.GetItemInfoInstant`) before running the more expensive upgrade-info
reads.
**Reason:** Cheap filtering first, expensive API calls only on items that
could plausibly matter.

**Decision:** Cache invalidation is event-driven: `BAG_UPDATE_DELAYED` and
`PLAYER_EQUIPMENT_CHANGED` trigger re-evaluation; item data not yet cached
is queued and retried via `GET_ITEM_INFO_RECEIVED`; an equipment change
invalidates the *entire* cached evaluation set for that slot, not just the
one item that changed.
**Reason:** Changing the equipped item in a slot moves the comparison
target for every bag item in that slot — a single-item re-check would leave
stale evaluations behind.

**Decision:** Distribution is CurseForge and/or Wago. Track/checkpoint
config updates are shipped manually after reading patch notes each patch,
not fetched remotely.
**Reason:** Standard, low-overhead model for a two-person side project.

**Decision:** Greenlit targets Retail only. No Classic support.
**Reason:** The crest/upgrade-track system the addon is built around
doesn't exist in Classic.

**Decision:** `Config.lua`'s track order and checkpoint table are left
unseeded, as an explicit first research task rather than carried over from
planning-conversation research.
**Reason:** These values drift patch to patch; freshly verifying against
live patch notes at implementation time is safer than inheriting
potentially-stale numbers from an earlier discussion.

**Decision:** Git workflow is feature branches + PR review, no direct
commits to `main`, effective as soon as code starts landing.
**Reason:** Two people writing real Lua from day one — cheaper to start
clean than to retrofit review discipline after history is already messy.
