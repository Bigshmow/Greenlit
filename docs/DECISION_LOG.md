# Decision Log

Every time we intentionally choose something, we write it down here — so that six months from now we don't have to reconstruct why.

## 2026-09-16

**Decision:** Ignore trinkets in MVP.
**Reason:** Item level alone is insufficient to determine progression value.

**Decision:** No auto-selling.
**Reason:** Greenlit evaluates. Other addons can perform vendor actions.

**Decision:** No stat weights.
**Reason:** Outside project scope.

## 2026-09-17

**Decision:** Confidence is a binary go/no-go signal, not a scored scale (capped at at most 2 levels).
**Reason:** A sliding confidence score invites threshold-tuning, which contradicts the Conservative and Focused principles. Only surface a badge when the recommendation is certain; otherwise say nothing.

**Decision:** Warband / account-wide gear evaluation is deferred to a fast-follow, not part of V1.
**Reason:** Get single-character correctness bulletproof first before expanding the evaluated pool.

**Decision:** Shields are excluded from evaluation for now, treated like offhands.
**Reason:** Ambiguous how the API classifies them; needs confirmation before committing logic either way.

**Decision:** Compare items via track + rank *position*, using explicit equivalence checkpoints between tracks, rather than raw item-level integers.
**Reason:** Raw ilvl values change every season and sometimes mid-season. Track order (Adventurer < Veteran < Champion < Hero < Myth) is stable; only the checkpoint table needs updating when Blizzard shifts numbers.

**Decision:** Per-item ceilings are always read live from the game API, never computed from a static ilvl table we maintain ourselves. Only track ordering and cross-track equivalence checkpoints are our own config data.
**Reason:** Matches the Transparent principle (no hidden heuristics, no stale hardcoded numbers) and means unusual items (e.g. Great Vault / bonus roll items that start above normal crest-progression ceilings) are handled correctly without any special-casing.

**Decision:** Product framing is "cleanup / safety-net addon that prevents accidentally vendoring away a free upgrade," not a progression-value analyzer or a mini Raidbots.
**Reason:** Keeps the tool's job narrow and matches how the core rules actually behave — they catch mistakes, they don't score gear.

**Decision:** The Evaluation result stays object-shaped, with a 0/1 (boolean-like) Candidate signal at its core, without being tightly coupled to a single bare boolean field.
**Reason:** Leaves room to restructure later without breaking every consumer of the result.

**Decision:** Ceiling ties — including duplicate items on the same track — are always left unbadged, never marked as a vendor candidate.
**Reason:** A tie means Greenlit cannot know which item is actually better without secondary-stat comparison, which is explicitly out of scope (Non-Goals). Silence, not a guess.

**Decision:** Rule pipeline order is **Rule B (pending free upgrade) → Rule C (duplicate suppression) → Rule A (strict ceiling comparison) → otherwise, silence.**
**Reason:** Matches the actual manual process a player follows: check whether an item is holding an uncaptured free upgrade before ever asking whether it's simply obsolete.

**Decision:** Duplicate suppression (Rule C) keeps exactly one item per (slot, track) group that's being held solely to trigger a free upgrade; every other duplicate in that group is a vendor candidate. No "closest to max rank" tiebreaker is needed.
**Reason:** The crest cost to finish upgrading any duplicate of a given track to max rank is fixed, regardless of the rank it dropped at — so no duplicate is meaningfully "closer" to triggering the free upgrade than another. Only one copy is ever needed.

**Decision:** V1 baseline for comparison is equipped + bags + personal bank, on a single character. This is a V1 requirement, not a fast-follow.
**Reason:** Get the most holistic view of what's actually available to the character, within the constraint of only using what the player has exposed to the addon (single character, not warband).

**Decision:** V1 evaluates against currently-equipped-right-now only; off-spec Equipment Manager sets are not consulted, so items belonging to an unequipped spec's set may be misjudged. Confirmed feasible via `C_EquipmentSet` API for a fast-follow.
**Reason:** Handling multiple saved equipment sets correctly would require Rule A's "currently equipped" concept to become "best relevant item across all saved sets for this slot," which meaningfully complicates every rule designed so far. Documented explicitly as a known V1 limitation rather than a silent gap.

**Decision:** Evaluation triggers on any inventory- or equipment-changing event, but is slot-scoped first via a cheap `equipLoc` check (via `C_Item.GetItemInfoInstant`) before running the more expensive upgrade-info reads.
**Reason:** Cheap filtering first, expensive API calls only on items that could plausibly matter.

**Decision:** Cache invalidation is event-driven: `BAG_UPDATE_DELAYED` and `PLAYER_EQUIPMENT_CHANGED` trigger re-evaluation; item data not yet cached is queued and retried via `GET_ITEM_INFO_RECEIVED`; an equipment change invalidates the *entire* cached evaluation set for that slot, not just the one item that changed.
**Reason:** Changing the equipped item in a slot moves the comparison target for every bag item in that slot — a single-item re-check would leave stale evaluations behind.

**Decision:** Distribution is CurseForge and/or Wago. Track/checkpoint config updates are shipped manually after reading patch notes each patch, not fetched remotely.
**Reason:** Standard, low-overhead model for a two-person side project.

**Decision:** Greenlit targets Retail only. No Classic support.
**Reason:** The crest/upgrade-track system the addon is built around doesn't exist in Classic.

**Decision:** `Config.lua`'s track order and checkpoint table are left unseeded, as an explicit first research task rather than carried over from planning-conversation research.
**Reason:** These values drift patch to patch; freshly verifying against live patch notes at implementation time is safer than inheriting potentially-stale numbers from an earlier discussion.

**Decision:** Git workflow is feature branches + PR review, no direct commits to `main`, effective as soon as code starts landing.
**Reason:** Two people writing real Lua from day one — cheaper to start clean than to retrofit review discipline after history is already messy.

## 2026-09-17 (implementation)

**Decision:** `Config.lua`'s cross-track checkpoints are stored as a rank *position* (which rank of the next track ties the current track's ceiling rank), never as a raw item level.
**Reason:** From patch to patch, item levels attached to each rank drift or get rebalanced, but track naming and the rank relationship between tracks stays stable. Confirmed empirically: three different research sources gave three different ilvl numbers for the same live season, but all agreed Champion's ceiling ties Hero rank 2, and Hero's ceiling ties Myth rank 2. Keying off ilvl would require re-verifying and re-editing this file every time Blizzard touches item level math, even when nothing about the actual track relationship changed.

**Decision:** Only the Champion→Hero and Hero→Myth checkpoints are seeded in `Config.lua` for now. Adventurer→Veteran and Veteran→Champion are left out rather than assumed to share the same rank-2 offset.
**Reason:** No confirmed data exists yet for those two transitions. Per the Conservative principle, an unconfirmed guess is worse than no entry at all — a missing checkpoint means Rule A/B simply can't compare across that specific boundary yet, which is a safe, explicit gap rather than a silent wrong assumption.

## 2026-09-17 (implementation, revised)

**Decision:** Supersedes the entry above — `Config.lua`'s `checkpoints` table is now fully seeded for every track that has a next track (Adventurer, Veteran, Champion, Hero all = rank 2; Myth has no entry since no track follows it, and none is needed before Adventurer since no track precedes it). Adventurer→Veteran and Veteran→Champion use the same rank-2 offset as the two empirically-confirmed transitions, by explicit user direction, rather than being independently verified per-transition first.
**Reason:** Owner call to extend the confirmed Champion→Hero/Hero→Myth pattern to the remaining transitions now rather than leave partial data, accepting the (currently unverified) assumption that Blizzard applies the same rank-2 offset uniformly across all track boundaries this season. Revisit if in-game verification later shows Adventurer or Veteran don't follow the same offset.

## 2026-09-17 (implementation, Events.lua/Cache.lua)

**Decision:** `INVTYPE_ROBE` is normalized to `INVTYPE_CHEST` everywhere Greenlit reads or keys off an item's equip location (armor pre-filter, cache keys, equipment-change invalidation).
**Reason:** Cloth robes and plate/mail chestpieces occupy the same physical equipment slot and directly compete for it, but report different `itemEquipLoc` strings from the API. Treating them as one group is correct for "what's the best item in this slot" comparisons, and as a side effect makes equipment-change invalidation correct without needing to know the old item's type — old and new items always normalize to the same key regardless of which of the two they individually were.

**Decision:** `Cache.lua`'s pending queue stores the actual `itemLocation` object per waiting request, not just a plain key string.
**Reason:** Revises the assumption from the original `Cache.lua` pass (that Cache shouldn't hold onto location references since bag contents shift). In practice the pending window is the short async gap between requesting uncached item data and `GET_ITEM_INFO_RECEIVED` firing, not an arbitrary delay — holding the object for that window is standard practice and far simpler than re-deriving bag/slot by parsing the cache key string back apart.

**Decision:** This pass of `Events.lua` scans equipped slots (reactively, via `PLAYER_EQUIPMENT_CHANGED`) and bags (`BAG_UPDATE_DELAYED`) only. Personal bank scanning, already committed to as a V1 requirement, is not yet implemented.
**Reason:** The current bank system's container/tab API wasn't verified before writing this pass, and it's meaningfully different from simple bag scanning (multiple tabs, possibly requiring the bank frame to be open). Rather than guess at unverified API shape, this is left as an explicit, tracked gap instead of a silently incomplete "done."
[Superseded by the entry below — bank scanning is now implemented.]

## 2026-09-17 (implementation, bank scanning)

**Decision:** Personal bank scanning is implemented in `Events.lua` via `ScanBank()`, reusing the same `ScanContainer` helper as bags, fed by `C_Bank.FetchPurchasedBankTabIDs(Enum.BankType.Character)`. Triggered on `BANKFRAME_OPENED` and `PLAYERBANKSLOTS_CHANGED`.
**Reason:** Confirmed via Blizzard's own generated API docs (`BankDocumentation.lua`) that purchased bank tabs are exposed as ordinary `BagIndex` container IDs, meaning they work through the exact same `C_Container.GetContainerNumSlots`/`GetContainerItemID` calls already used for bags — no separate scanning mechanism needed. `PLAYERBANKSLOTS_CHANGED` and `BANKFRAME_OPENED` are both confirmed real events in the same doc file, and `PLAYER_ACCOUNT_BANK_TAB_SLOTS_CHANGED` being a distinctly different event confirms character bank and Warband/account bank are separate systems, matching the V1 scope of single-character-only.

**Resolved (2026-09-17):** `Enum.BankType.Character` confirmed in-game via `/dump Enum.BankType` → `{ Character = 0, Guild = 1, Account = 2 }`. The guess was correct; no code change needed.

## 2026-09-17 (implementation, RuleB)

**Decision:** `RuleB_PendingFreeUpgrade.lua` compares raw item level (`candidate.highWatermark` vs `owned.itemLevel`), both read live via `C_ItemUpgrade.GetHighWatermarkForItem` and `C_Item.GetDetailedItemLevelInfo` respectively (now cached alongside track/rank in `Cache.lua`).
**Reason:** This does not conflict with the earlier "never raw ilvl, always track+rank position" decision for `Config.lua`/Rule A. That decision was about not hand-maintaining our own ilvl-to-rank table, since ours would drift every patch. The high-watermark system is a live, game-computed number with no track/rank equivalent exposed by the API at all — there is nothing to convert it to. Reading it fresh every evaluation (never hardcoded, never cached across sessions) is the same principle already applied to `ceilingRank`, just for a mechanic the API only expresses in ilvl terms.

**Decision:** `Evaluation.candidate` can be explicitly `false` (Rule B's "hold, not a candidate, with the reason" outcome), not just `true`. A `nil` Evaluation (rule returns nothing at all) remains the separate "silence, no opinion" case used when no rule fires.
**Reason:** `ARCHITECTURE.md`'s Rule B description calls for a decisive negative result with a surfaced reason, which is different from "no rule had anything to say." Needed a way to distinguish the two rather than overload `nil` for both.

**Decision:** Confirmed as intentional (not a gap): items with no upgrade track at all (`GetItemUpgradeInfo` returns nil) are invisible to Greenlit entirely — never cached, never evaluated, no Evaluation of any kind, not even a "no opinion" one. Added to `PRD.md` Non-Goals: leveling gear / non-max-level characters are explicitly out of scope.
**Reason:** Greenlit's problem statement is endgame gearing via the upgrade-track/crest system. Leveling gear has no track to reason about and is simple enough (higher ilvl is strictly better) that it doesn't need Greenlit's judgment at all.

## 2026-09-17 (implementation, RuleEngine)

**Decision:** `owned` (the comparison baseline for both Rule A and Rule B) is specifically the currently *equipped* item in that slot — not the best of equipped-plus-bag-plus-bank duplicates, and not aware of off-spec Equipment Manager sets.
**Reason:** This is an implementation of the scope already decided before any code existed (see the pre-implementation entry above: "V1 evaluates against currently-equipped-right-now only; off-spec Equipment Manager sets are not consulted... deferred fast-follow"), not a new limitation.

An earlier version of this entry claimed this choice was "provably safe" in general — that overstated it. It's only actually safe within a single spec: same-track duplicates always share the same `ceilingRank`, so which specific duplicate happens to be equipped never changes a same-track ceiling comparison. It is NOT safe across specs — a main spec sitting on Hero track will cause Rule A to wrongly flag a Champion-track item as vendor-safe even when that item would be a real upgrade for a neglected alt spec's saved set still sitting on Veteran gear. That's a real, plausibly-common false positive, not a rare edge case, and it's exactly what the pre-existing off-spec-awareness fast-follow is meant to fix later via `C_EquipmentSet`.

**Decision:** `RuleEngine.EvaluateAll()` is the one place that calls `RuleC.Reset()`, exactly once per full pass, before iterating every cached key except `:equipped` ones. `RuleEngine.Evaluate(key)` itself never resets Rule C state.
**Reason:** Rule C's "first duplicate in a group wins" logic only makes sense scoped to a single, complete pass over all currently-known items. Resetting anywhere else (e.g. per-item) would make every duplicate look like the "first" one; never resetting would let stale claims from a previous pass leak into a new one after items move or get vendored.

**Decision:** The equipped item in a slot is never itself passed through `Evaluate` as a candidate (guarded both by `EvaluateAll` skipping `:equipped` keys and by `Evaluate` itself refusing if the candidate and owned keys are the same).
**Reason:** Greenlit's whole premise is bag/bank hygiene — evaluating whether to vendor something you're currently wearing isn't a scenario that makes sense to support.

## 2026-09-17 (tooling, testing)

**Decision:** Tests use LuaUnit, not Busted, despite Busted being the more common choice in the WoW addon community.
**Reason:** Busted's dependency chain includes `luasystem`, a C extension that needs a native compiler to build. The local machine had no compiler at all (MSVC not installed, no gcc), and after installing MinGW-w64 to get gcc, LuaRocks' bundled Windows build still defaulted to invoking MSVC (`cl`) for that specific rockspec rather than gcc, with no quick way to retarget it in this LuaRocks version. LuaUnit is pure Lua with zero native dependencies, sidesteps the problem entirely, and is fully sufficient for testing plain-table-in, plain-table-out functions like `RuleA`/`RuleB`/`RuleC`/`Config`. Revisit Busted later only if a feature it has that LuaUnit lacks (e.g. spies/stubs) actually becomes necessary.

## 2026-09-17 (implementation, cache key scheme)

**Decision:** `Cache.lua` keys changed from `"<equipLoc>:<location>"` (e.g. `"INVTYPE_CHEST:bag0:3"`) to purely positional keys — `"container<bagID>:<slot>"` for any bag or bank item, `"equipped:<equipmentSlot>"` for gear. `equipLoc` moved from being embedded in the key string to a field on the cached item state itself. `InvalidateSlot`/group-key construction in `RuleEngine` now read `item.equipLoc` from the value instead of parsing it back out of the key.
**Reason:** Found while researching the real UI hook point (`ContainerFrameMixin:UpdateItems()` in Blizzard's own source) that the UI only ever has `itemButton:GetBagID()`/`GetID()` (bag+slot) to work with — it has no cheap way to know an item's equip-loc before looking it up, which the old key scheme required. Positional keys are also simpler: bags and bank tabs turned out to be the exact same underlying container API (see the bank-scanning entry above), so there was never a real reason to distinguish "bag" vs "bank" in the key at all — one `ContainerKeyFor` replaces what used to need two prefixes.

**Decision:** Bag and bank items now share one key prefix (`container`), not separate `bag`/`bank` ones.
**Reason:** Direct consequence of the above — since both are `BagIndex` values read through identical `C_Container` calls, keying them differently would only exist to describe something Greenlit never actually needs to distinguish.

## 2026-09-17 (implementation, UI)

**Decision:** `UI/Badge.lua` hooks `hooksecurefunc(ContainerFrameMixin, "UpdateItems", ...)` and `UI/Tooltip.lua` hooks `hooksecurefunc(GameTooltip, "SetBagItem", ...)`. Both cover bags and bank tabs with the same single hook, no bag/bank branching needed.
**Reason:** Confirmed directly in Blizzard's own source (`Blizzard_UIPanels_Game/Mainline/ContainerFrame.lua`) rather than assumed from older addon conventions, since this UI layer changes a lot across expansions. `UpdateItems()` is where Blizzard itself sets per-button state (junk, new-item, quest); `SetBagItem(bag, slot)` is a native tooltip method taking the same `(bag, slot)` shape `Cache.lua` already keys by, so no extra lookup/translation is needed in either hook.

**Decision:** Badge/tooltip colors live once in `Config.lua` (`Greenlit.colors.vendor` / `.hold`), not duplicated in both UI files.
**Reason:** Straightforward DRY — both files render the same two verdicts and should never visually disagree with each other.

**Known gap:** Badges/tooltips only refresh when Blizzard's own UI naturally redraws (bag opens, item moves, etc. all trigger `UpdateItems` anyway) — `Events.lua` calling `RuleEngine.EvaluateAll()` doesn't itself force container frames to redraw. In practice this means results are very rarely stale by more than a moment, but there's no proactive push from evaluation to display yet. Not addressed now; revisit if it proves noticeable in play.

## 2026-09-18 (pre-commit review)

**Decision (bug fix):** `Events.lua` now registers `PLAYER_ENTERING_WORLD` and calls a new `ScanEquipped()` plus `ScanBags()` on it.
**Reason:** Found doing a full read-through before committing: every `Cache` entry for an equipped item was only ever created by `OnEquipmentChanged`, which only fires when gear *changes*. On a normal login or `/reload`, nothing changes, so `Cache.GetEquipped()` would return `nil` for every slot forever, and `RuleEngine.Evaluate` would silently bail out (`owned` not found) for every single item, all the time. This wasn't a rare edge case — it was the default state for anyone who doesn't manually re-equip something after logging in. `ARCHITECTURE.md`'s Events.lua responsibilities updated to reflect this.

**Decision (bug fix):** `RuleA`'s `TrackOffset`/`AbsolutePosition` now return `nil` (rather than erroring) for a track name that's `nil` or not in `trackOrder`; `RuleA` returns `nil` (silence) if either side's position comes back `nil`.
**Reason:** `ItemUpgradeInfo.trackString` is documented nilable even when an item genuinely has upgrade info (some upgrade paths don't report a track name at all) — a nil or unrecognized track name would previously crash with a Lua arithmetic-on-nil error instead of failing conservatively into silence, which is exactly backwards for an addon whose core principle is "if unsure, do nothing."

**Decision (bug fix):** `RuleB` now also guards `owned.itemLevel` being nil, not just `candidate.highWatermark`.
**Reason:** `C_Item.GetDetailedItemLevelInfo` is documented `MayReturnNothing` — same crash-into-silence fix as above, just the other input.

**Decision (bug fix):** `RuleEngine.Evaluate` returns Rule B's result directly (skipping Rule C grouping) when `candidate.track` is nil, instead of crashing on `candidate.equipLoc .. ":" .. candidate.track`.
**Reason:** Same nilable-trackString issue as the RuleA fix above, hit again at the group-key construction site. Chose to let a track-less item always show its Rule B hold rather than try to group/suppress it — we don't know its track identity, so we can't know it's a true duplicate of anything else, and showing more "hold" notices than strictly necessary is the safe direction to err in.

**Decision (bug fix):** `RuleEngine.EvaluateAll` now sorts cache keys before iterating, instead of relying on `pairs()` order.
**Reason:** Lua doesn't guarantee `pairs()` iteration order is stable across separate traversals of the same table. Since `RuleC.ShouldKeep` is "first one seen in this pass wins," an unsorted iteration meant *which* physical duplicate keeps the "hold" badge could flip unpredictably between items on every single re-evaluation (which happens after nearly every game event) — never a wrong recommendation, but a visibly flickering one that undermines Explainable. Sorting by key makes the winner deterministic and stable as long as the underlying items haven't actually moved.

**Decision (bug fix):** `Events.lua` now has a static `EQUIP_SLOT_TO_EQUIP_LOC` table (numeric equipment slot → normalized equip-loc) and `OnEquipmentChanged` always calls `Cache.InvalidateSlot` using that table, before checking `hasCurrent` — not only when a new item was equipped.
**Reason:** The previous version only invalidated the slot when `hasCurrent` was true, because it derived the equip-loc by reading the *newly equipped item itself* — which doesn't exist when you unequip something outright (`hasCurrent = false`, slot now empty). That left the stale, no-longer-worn item permanently in `Cache`, so every bag item in that slot would keep being compared against gear you'd already taken off. The fix also incidentally removed the last remaining `C_Item.GetItemInfoInstant` call on the "what slot is this" question for equipped items — that identity was always static per numeric slot, not something that needed reading off the item to begin with (chest/robe ambiguity aside, which the table already resolves by mapping straight to the normalized value).

**Note:** These are all fixes to code written earlier in this same session, not to anything previously reviewed/approved — surfaced by a deliberate read-through before the first commit, not by anything going wrong in play (nothing has run in a live client yet).

**Decision:** `ARMOR_EQUIP_LOCS` and `NormalizeEquipLoc` moved out of `Events.lua` into `Config.lua` (as `Greenlit.armorEquipLocs` and `Greenlit.NormalizeEquipLoc`), with spec coverage added. The one thing that stayed in `Events.lua` is `EQUIP_SLOT_TO_EQUIP_LOC`, which uses `INVSLOT_HEAD`-style WoW globals as table keys and would crash immediately if loaded outside the client (a table constructor with a nil key errors).
**Reason:** Owner framing: `Cache.lua`/`Events.lua` should stay "pure and dumb" — API glue with no real decisions embedded in it — for the untested boundary to be an acceptable risk at all. Checking that against the actual code found two real domain decisions sitting there anyway: which equip-locs count as armor at all (matches PRD scope), and the chest/robe merge. Neither needed the WoW client to evaluate, so neither had a good reason to be excluded from testing — they were just sitting in the wrong file. `Config.lua` is exactly where "our own maintained domain data/logic that isn't a live API read" already lives.
