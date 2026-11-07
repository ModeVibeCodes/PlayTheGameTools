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
576 quest associations**, including repeated quests across wings. These counts
are source assignments, not completeness or current-server claims. Drowned City
has partial boss records but no recorded loot/quests; its card says **Quests not
recorded**. Classic fallback quests and incomplete loot are explicitly labeled.

DungeonJournal, Lootified, AtlasLoot, Questie and QuestieDB are not required.
The catalog ships as editable Lua data derived from the pinned Lootified 1.2.0
release, with independently authored SFK additions. The snapshot predates some
newest Forever content. See ../CATALOG_SOURCES.md for provenance, licensing and
uncertainty. Raids are excluded. No settings or compatibility IDs change.

## Browser and appearance

Cards retain the accepted 180px scene, title, territory emblem, boss/rare totals,
quest count and light text bands. Each card shows its actual recommended range.
Groups use **Suggested starting levels 10–19 / 20–29 / 30–39 / 40–49 / 50–60**,
based on the lower end of that range, rather than treating it as an entry rule.
Unknown levels remain Unknown. Ordering is starting level, ending level, then
name. Search filters names; empty results are explicit.

Card scenes use native Blizzard loading-screen, encounter-journal or LFG
textures. No external-addon artwork paths are used. Missing native scenes fall
back to a small native icon. The accepted SFK loading-screen crop remains
0.04–0.96 / 0.28–0.78. Text bands are 34px/44px at 55%.

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
python tools/build_release.py
```

The catalog test traverses all 31 bundled browsable dungeons and 576 quest associations,
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

1. **Navigation:** `/mode` -> Questing & Leveling -> Dungeon Loot -> Dungeons.
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
4. **Navigation:** `/mode` -> Questing & Leveling -> Dungeon Loot -> Dungeons ->
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
