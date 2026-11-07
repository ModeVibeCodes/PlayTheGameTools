# Dungeon Loot — Forever dungeon browser

Dungeon Loot is under **Questing & Leveling** and off by default. The owner
accepted the SFK layout and native-pin fix on 2026-11-07, then authorized expansion
to the other dungeons. The same appearance and interaction apply across the
catalog. The owner authorized merging PR #6 on 2026-11-07. Standalone native review
and real screenshots remain pending; no release publication is authorized.

## Coverage and dependencies

The bundled GPLv3 catalog contains **35 dungeon/wing entries**: **31 browsable**
and **four preview-only**. Preview cards are non-clickable and say **Data not
available yet**. Automated traversal covers **286 boss/loot-source entries and
576 source quest associations**, including repeated quests across wings. The
browser groups 15 same-chain duplicate listings into **561 dungeon task entries**.
These counts
are source assignments, not completeness or current-server claims. Drowned City
has partial boss records but no recorded loot/quests; its card says **Quests not
recorded**. Classic fallback quests and incomplete loot are explicitly labeled.

DungeonJournal, Lootified, AtlasLoot, Questie and QuestieDB are not required.
The catalog ships as editable Lua data derived from the pinned Lootified 1.2.0
release, with independently authored SFK additions. The snapshot predates some
newest Forever content. See ../CATALOG_SOURCES.md for provenance, licensing and
uncertainty. Raids are excluded. No settings or compatibility IDs change.

## Player eligibility and quest-log progress

On 2026-11-07 the owner confirmed the PR #8 completion, chain grouping,
quest status, tile alignment and quick-jump revision works as intended in-game,
and authorized merging it into main. Real screenshots remain pending. The
checks below are retained for regression testing; this confirmation is not an
exhaustive audit of every catalog fact or a release publication approval.


Quest lists and expanded prerequisites automatically hide entries restricted to
another faction or class. Both-faction quests stay visible. Class lists support
more than one allowed class and use native class colors. The former faction
selector is a compact automatic Alliance/Horde badge; manual filtering cannot
expose the opposite faction.

Every browsable card with known quest records shows **You have X/Y possible
quests**, where Y is the number of distinct recorded quests matching the current
faction/class and X is the number in the player's quest log. Blue means none,
gold means some, green means all. A second line such as **Rogue quests: 1/2 in
log** appears only when that character has recorded class-specific quests.
Pickup progress is larger (14px), right aligned at the bottom of the tile. On
wide cards it shares the footer with metadata; narrow cards stack the footer
sections and can grow to avoid overlap. Titles and adjacent faction icons form
one centered group within the title band. Their existing gradient/glow remains.
Preview and missing-data cards retain their explicit unavailable states.

The SFK pilot lists Test of Righteousness and Horn of Xelthos by their final
reward step. Their known dungeon collection steps (1654 / 78261) also count as
picked up for those entries (1806 / 78307), once per entry. Unrelated prerequisite
quests do not count as dungeon pickups. Counts do not depend on the search box.
Y remains a faction/class catalog total: it does not promise that the player
currently meets level, race, reputation or prerequisite conditions, and does not
remove already completed quests. Existing source completeness warnings apply.

The provider reads `UnitFactionGroup("player")`, the class filename from
`UnitClass("player")`, and `C_QuestLog.IsOnQuest(questID)` through protected calls
plus `C_QuestLog.IsQuestFlaggedCompleted(questID)` for character history, with
public-value validation. Account-wide completion is not used. Unique queries are cached within each
update across all cards. `QUEST_LOG_UPDATE` is registered only while enabled and
the browser page is shown; changed totals, quest statuses or active chain stages redraw the UI. Showing the page
refreshes identity and counts. No polling or quest-log writes are added. Missing,
failing or restricted APIs show an unavailable state instead of a false zero;
quests needing an unknown identity are withheld until it can be read. Card
restriction headers stay cheap; maps/rewards are still normalized on selection.

API signatures/events checked against Forever's generated
[UnitDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua)
and [QuestLogDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLogDocumentation.lua)
on 2026-11-07. These read APIs do not change the independent native map renderer.

Native regression checks (owner confirmed the revision on 2026-11-07):

1. **Navigation:** `/ptg` -> Questing & Leveling -> Dungeon Loot -> Dungeons.
   **Action:** `/reload`, inspect Shadowfang Keep and another recorded dungeon
   while comparing with the quest log. **Required state:** Forever, OOC, Dungeon
   Loot enabled; DungeonJournal/Questie disabled. **Confirmation:** X/Y matches
   the character's recorded faction/class quests, class-only pickup status uses
   the character's class color, and text fits over the existing dungeon image.
2. **Navigation:** `/ptg` -> Questing & Leveling -> Dungeon Loot -> Dungeons ->
   Shadowfang Keep -> Quests. **Action:** inspect the list and expand a visible
   quest's Prerequisites button if present. **Required state:** OOC; repeat on an
   opposite-faction or different-class character if available. **Confirmation:**
   other-faction/class quests are absent, neutral quests remain, and the compact
   faction badge matches the character without overlapping search.
3. **Navigation:** `/ptg` -> Questing & Leveling -> Dungeon Loot -> Dungeons.
   **Action:** pick up/abandon a recorded eligible dungeon quest, then return to
   the cards; repeat with the page already visible if the NPC interaction allows.
   **Required state:** OOC. **Confirmation:** the numerator changes without using
   General -> Refresh; denominator remains stable, and blue/gold/green status
   follows none/some/all. A completed quest awaiting turn-in remains in the log.

## Completion and duplicate-chain handling

Quest list subtitles and the detail pane clearly show **In your log** (gold),
**Completed** (green), or **Not in your log**. A quest awaiting turn-in remains
in the log. The card shows **All quests completed** only when the native
character completion flags confirm every eligible task's terminal listed stage.
A partial history shows X/Y completed beneath pickup progress. Unknown/restricted
history never produces an all-completed claim; zero eligible tasks do not either.
No SavedVariables completion guesses or dungeon-run history are recorded.

Same-title quests collapse only when mandatory `pre` relationships connect them
and their faction/class restrictions match. Intermediate prerequisite stages are
retained, as are each stage's objective, acquisition, turn-in and reward details.
The active or first unfinished stage opens automatically; compact **Stage 1**,
**Stage 2**, etc. buttons permit inspection in place. Completion uses the final
listed stage, not an earlier pickup/collection step. Unrelated identical titles,
faction/class variants, preAny alternatives and cyclic records are not merged.
The raw licensed tables remain unchanged. Computed grouping is cached per dungeon.

The catalog audit found 15 repeated chain-stage listings across RFC, Ruins of
Lordaeron, BFD, Gnomeregan, RFD, Uldaman, BRD, LBRS, Stratholme and UBRS. Horde
Ruins of Lordaeron now has six tasks: Unending Torment is one entry with stages
97288 -> 97289 -> 97290, rather than two counted listings.

Native follow-up regression checks (owner confirmed intended behavior on 2026-11-07):

1. **Navigation:** `/ptg` -> Questing & Leveling -> Dungeon Loot -> Dungeons ->
   Ruins of Lordaeron -> Quests. **Action:** inspect Unending Torment and its
   Stage 1 / Stage 2 / Stage 3 buttons. **Required state:** Forever, OOC, Horde,
   Dungeon Loot enabled. **Confirmation:** one list entry, six eligible tasks on
   the card, active stage selected, and clearly visible In your log or Completed
   labels matching the character. No source stage's details disappear.
2. **Navigation:** `/ptg` -> Questing & Leveling -> Dungeon Loot -> Dungeons.
   **Action:** inspect a dungeon whose eligible quests this character has turned
   in. **Required state:** OOC, completion history available from the client.
   **Confirmation:** All quests completed appears only when every eligible task
   is flagged complete; partly finished dungeons show a partial completion count.
3. **Navigation:** `/ptg` -> Questing & Leveling -> Dungeon Loot -> Dungeons ->
   the **20–29** bracket button below search. **Action:** click it, try another
   range, search for a dungeon, then resize the window. **Required state:** OOC.
   **Confirmation:** the list scrolls to Suggested Starting Levels 20–29;
   unavailable search-result ranges are hidden, headers have a subtle underline
   and reversed blue gradient, and the strip disappears inside a dungeon.
4. **Navigation:** `/ptg` -> Questing & Leveling -> Dungeon Loot -> Dungeons.
   **Action:** inspect a neutral dungeon and a faction dungeon at wide/narrow
   widths. **Required state:** OOC. **Confirmation:** title and emblem(s) center
   together, progress sits at bottom right in larger type, footer columns/stack
   do not overlap, and the title's subtle glow aligns with the text.

## Browser and appearance

Cards retain the 180px minimum scene, title, territory emblem, boss/rare totals,
quest count and light text bands. Each card shows its actual recommended range.
Groups use **Suggested Starting Levels 10–19 / 20–29 / 30–39 / 40–49 / 50–60**,
based on the lower end of that range, rather than treating it as an entry rule.
Unknown levels remain Unknown. Ordering is starting level, ending level, then
name. Search filters names; empty results are explicit.

Card scenes use native Blizzard loading-screen, encounter-journal or LFG
textures. No external-addon artwork paths are used. Missing native scenes fall
back to a small native icon. The accepted SFK loading-screen crop remains
0.04–0.96 / 0.28–0.78. The title band is 34px; the footer starts at 44px and grows for wrapped text,
both at 55% opacity.

Territory emblems are regional guidance, not quest or entry restrictions. Known
Alliance/Horde home-zone map IDs are classified explicitly; other recorded
entrances use both emblems for neutral/contested territory. Preview entries with
no entrance metadata leave territory unknown. Quest emblems retain quest faction.

A fixed selected-dungeon name/range appears above the persistent boss/quest panes.
First matching entries select automatically. Entry selection preserves list
scroll and resets detail scroll. Dungeon changes clear stale entry selections,
copy panels and map status/pins. Filters choose a valid match or an empty state.
Dungeons / Boss Loot / Quests / General have the same 2px blue selection underline.
General retains the compact **Refresh** control and attribution.

Bosses with <=5 items use public client tooltip text inline; larger lists remain
compact. Hover tooltips, missing/restricted-data fallbacks, native item-quality
colors and event-driven item updates are unchanged. Portraits use source display
IDs and Blizzard's portrait renderer; absent metadata uses the native default.
Extra sources remain under **Other loot** and do not inflate boss totals.

Quest steps remain **1. Starts at / 2. Objective / 3. Turn in**, then rewards and
optional prerequisites. Notes remain near the top; useful interior/entrance hints
are retained and missing hints are not invented. Known NPC/target names appear
below their heading in a subtle glowing white/gray gradient. Class names retain
native class colors and recorded chains show **Chain**. Moderate line leading
and reduced row gaps preserve the accepted compact layout.

Gradients: general #9fccfa to #0974f1, boss #f83d5c to #fd4b2f, quest #FADA5E to
#FAF2DF, NPC #F5F7FA to #A0A8B4. Heading glow is static and restrained.

## Locations and map controls

Only pickups and turn-ins expose **View on Map** / **Copy Coordinates** (128 x 28,
stacking on narrow panes). Objectives retain their text/hints without map/copy
buttons, including expanded prerequisite objectives.

The owned SFK planning catalog remains first priority. Other quests use recorded
source pickup/return maps, optional installed QuestieDB/Questie, or exact normalized
giver-name joins against recorded source maps. Conflicting named locations remain
unresolved; names are never substring-matched. Repeated samples within 0.5
percentage points are treated as the same approximate location. A source text
explicitly locating an NPC inside the selected dungeon may use that dungeon's
recorded outdoor entrance, labeled **Entrance marker only** in quest details.
No interior floor position or patrol is invented.

World-space source positions are converted through native C_Map APIs into
zone coordinates, with validated finite/public values and successful conversions
cached. Missing APIs, invalid points and continent-only results omit map controls.
This conversion needs native Forever review; mocks do not establish coverage.
Multiple spawn points are never joined into an invented patrol. Optional recorded
patrols remain separate. Removing Questie does not suppress bundled/owned pins.

The accepted map renderer uses AcquirePin/RemovePin with an addon-owned virtual
XML template and MapCanvasPinMixin: normalized positioning, inverse canvas zoom
and PIN_FRAME_LEVEL_TOPMOST. The 36px blue-bordered icon has a centered 24px
symbol and hover text **Approximate location - Right Click to Hide Icon**. Pins
are reused on refresh and released on mismatch, close, dismissal or disable.
Right-click hides only this addon's pins/routes; closing returns to settings.
Only recorded patrol geometry uses a separate canvas overlay.

Opening is OOC-only. Quest ownership/completion never gates custom pins. Bounded
post-open redraws handle late canvas sizing without polling. Provider rendering
failures are surfaced, including failures during SetMapID; a missing XML template
reports a restart requirement. Rejected protected actions are not retried.

Copy Coordinates opens a focused/preselected native edit field containing the
zone and selected destination's percentage coordinates (first planning point,
not player position). Press **Ctrl+C** to copy. Escape/Enter/Close dismisses it;
navigation/hide/disable releases focus. CopyToClipboard is restricted in Forever's
generated Os documentation; it is not called and no secure workaround is used.
No automated quest acceptance, turn-in, sharing, tracking or messages.

## Implementation, ownership and validation

Only the selected dungeon's quests/items are normalized. Card counts are cheap
metadata; opening the index does not load every dungeon's item tooltips or query
all quests through optional location APIs. Snapshots/navigation/expansion/copy
state remain session-only. Item listeners stop when hidden/disabled. Source
records are read-only and all exposed coordinates/crops/items are fresh copies.

DungeonLootProvider.lua owns discovery/normalization; DungeonLootLocations.lua
owns recorded-name/optional API adapters; DungeonLootLocationData.lua owns the
small independently curated SFK catalog. DungeonLootMap.lua and
DungeonLootMapPins.xml own the native pin lifecycle/template. DungeonLoot.lua
owns module state/item metadata; Config/DungeonLoot*.lua own the shared UI.

The catalog's GPLv3 license, attribution and editable data are included in the
release package. Original MIT grants remain intact. No DungeonJournal data or
assets are redistributed. See ../CATALOG_SOURCES.md and ../THIRD_PARTY_NOTICES.md.

Primary Forever source/API references:
- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_MapCanvas/Blizzard_MapCanvas.lua
- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_MapCanvas/MapCanvas_DataProviderBase.lua
- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_MapCanvas/MapCanvas_PinFrameLevelsManager.lua
- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/MapDocumentation.lua
- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/OsDocumentation.lua
- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleTextureBaseAPIDocumentation.lua
- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleFontStringAPIDocumentation.lua
- ItemDocumentation.lua / TooltipInfoDocumentation.lua / UnitDocumentation.lua:
  item data, tooltip updates and native creature portraits.

Python 3.12+ / lupa.lua51 checks:

```
python tests/smoke.py
python tests/dungeon_loot.py
python tests/dungeon_loot_map.py
python tests/dungeon_loot_catalog.py
python tests/dungeon_loot_standalone.py
python tests/dungeon_loot_player.py
python tests/dungeon_loot_completion.py
python tools/build_release.py
```

The catalog test traverses all 31 bundled browsable dungeons and 561 grouped task entries,
checks source isolation, bounded pooled UI growth, lazy selected-dungeon reads,
preview non-interactivity, search/selection changes, art metadata and conservative
location matching. Map tests cover native pool/zoom/frame-level contracts and
failure paths. The builder validates the virtual XML template and its TOC order.
Mocks do not establish native layout, actual drops or current quest availability.
Retain prior same-version packages with hash verification before rebuilding.

## Native review — expansion pending

The owner confirmed the SFK appearance/native pin result before authorizing this
expansion. Existing Forever junction remains unchanged; no copy-sync or
SavedVariables edits. Restart the client for the added TOC files. Disable DungeonJournal, Questie
and QuestieDB for baseline review. Screenshots: pending;
the owner authorized merging with this native-review limitation recorded.

1. **Navigation:** `/ptg` -> Questing & Leveling -> Dungeon Loot -> Dungeons.
   **Action:** `/reload`, browse the groups and search for Ragefire Chasm, The
   Deadmines, Hall of Thanes, Scarlet Monastery, then clear search.
   **Required state:** Forever, OOC, Dungeon Loot enabled; external data addons disabled.
   **Confirmation:** correct names/scenes/counts/ranges and region emblems, with
   the four preview cards clearly unavailable and no stale SFK title.
2. **Navigation:** Dungeons -> Ragefire Chasm -> Boss Loot, then Dungeons ->
   The Deadmines -> Boss Loot. **Action:** select different boss rows in each.
   **Required state:** OOC; allow item metadata to load. **Confirmation:** header
   names the correct dungeon, list stays visible, loot updates in place and entry
   selections do not leak between dungeons; <=5 items detailed, larger lists compact.
3. **Navigation:** Dungeons -> Shadowfang Keep -> Quests -> Deathstalkers in
   Shadowfang -> 1. Starts at -> View on Map. **Action:** click and right-click
   the pin; close the map. **Required state:** OOC. **Confirmation:** accepted
   blue-bordered pin and short tooltip remain functional; closing restores settings.
4. **Navigation:** `/ptg` -> Questing & Leveling -> Dungeon Loot -> Dungeons ->
   Shadowfang Keep -> Quests -> The Book of Ur -> 1. Starts at -> Copy Coordinates.
   **Action:** copy with Ctrl+C and paste into a text editor; then inspect
   3. Turn in -> View on Map. **Required state:** Forever, OOC, external data
   addons disabled. **Confirmation:** selected Undercity coordinates, visible pin,
   and clean focus release. Objectives retain text without map/copy controls.
5. **Navigation:** Dungeon Loot -> General -> Refresh. **Action:** click, then
   return to Dungeons and open different dungeon/quest tabs. **Required state:**
   OOC. **Confirmation:** refreshed catalog, correct active underlines, faction
   filters, class colors/chain notes and accepted spacing remain consistent.

## Owned location catalog provenance (checked 2026-11-07)

These are a small set of independently curated, rounded planning facts, not a
copy of an addon database or page prose. They are not native sightings. Maps are
Blizzard UI map IDs; coordinates below are approximate percentages.

| Location | UI map | Planning point | Use |
| --- | --- | --- | --- |
| High Executor Hadrec | Silverpine 1421 | 43, 41 | Deathstalkers pickup |
| Doan Karhan | Barrens 1413 | 49, 57 | Orb pickup/return |
| Keeper Bel'dugur | Undercity 1458 | 54, 55 | Book pickup/return |
| Dalar Dawnweaver | Silverpine 1421 | 44, 40 | Arugal pickup/return |
| Jordan Stilwell | Dun Morogh 1426 | 52, 37 | Paladin chain pickup/return/forging |
| Lumina Windsinger | Silverpine 1421 | 43, 41 | Horde paladin pickup/return; crypt after escort |
| Dead Drop | Silverpine 1421 | 47, 71 | Rogue pickup/return/payment |
| SFK entrance | Silverpine 1421 | 45, 68 | Entrance-only proxy for interior quest portions |

Public reference observations, cross-checked where available; no illustrations or
narrative wording reused:
- https://eternadex.com/en/dungeons/shadowfang-keep/quests/ — Hadrec, Doan, Jordan and recipients.
- https://muchamielwow.github.io/en/mazmorras/castillo-de-colmillo-oscuro/ — entrance, pickups and interior room descriptions.
- https://eternadex.com/en/npc/keeper-beldugur/ — Undercity location and Book start/end association.
- https://warcraft.wiki.gg/wiki/Lumina_Windsinger — Sepulcher crypt location after the Fenris escort.
- https://eternadex.com/en/npc/dead-drop/ — Pyrewood pickup/return area.
- https://www.wowhead.com/forever/quest=1013/the-book-of-ur — interior book location cross-check.
- https://www.wowhead.com/forever/quest=78307/the-horn-of-xelthos — payment-step distinction.
