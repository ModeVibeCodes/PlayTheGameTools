# Dungeon Loot — Shadowfang Keep pilot

Dungeon Loot is under **Questing & Leveling**, alongside Class Training. It is off
by default. Enable it with the header switch. Compatibility IDs, slash commands,
ModeToolsDB and other modules remain unchanged. Continue on codex/dungeon-loot and
update draft PR #6; do not merge or push directly to main.

## Browser

Only Shadowfang Keep appears. Dungeons shows a 180px Blizzard loading-screen card
under **Suggested levels 20–30**, with title, territory emblem and source totals:
8 bosses + 1 rare, 3 extra loot sources and 7 quests. The range follows the installed
DungeonJournal 1.7.0 record and is not an entry requirement. The UV crop is
0.04–0.96 horizontally / 0.28–0.78 vertically to exclude logo/loading-bar regions.

Boss Loot and Quests use persistent, independently scrolling left lists and right
details. The first match is selected immediately. Selecting an entry preserves
list scroll and resets detail scroll. Filters replace excluded selections with a
matching entry or an explicit empty state. Boss/quest selections persist across
tab changes. Extra sources stay under Other loot and do not inflate boss counts.

Bosses with up to five items show public client tooltip text/colors inline. Six or
more stay compact; quest rewards are compact. Hover tooltips remain available.
Missing/restricted text is not inferred. Only visible short lists query tooltip
data; matching TOOLTIP_DATA_UPDATE IDs refresh them without polling. The first
item tooltip line is treated as its title and omitted from the body. Specialized
native graphics/comparisons stay in the hover UI.

Quest titles/subtitles have corrected height/padding and explicit top alignment.
Headers use #9fccfa to #0974f1; boss names use #f83d5c to #fd4b2f;
quest titles/section headings use #FADA5E to #FAF2DF, with faint static heading glow. Notes, descriptions and warnings appear
near the title without a notes toggle. Class names use localized Blizzard names
and RAID_CLASS_COLORS. List rows show Chain when prerequisite steps are recorded.
Numbered Starts at, Objective and Turn in steps precede rewards; Prerequisites (N)
expands chain acquisition details. The faction chooser is 128 × 28, with inherited
anchors cleared; search ends 10px before it. General owns compact Refresh and
source attribution. Dungeon emblems denote territory, not entry restrictions;
quest emblems denote quest faction.

## Locations and map pilot

**View on Map** buttons (128 x 28, matching the faction chooser) appear beside
destination captions in pickup, objective and turn-in sections, only for recorded
coordinates. Expanded prerequisites can also have buttons. A Patrol caption means
an ordered path is recorded. Missing buttons mean no
usable coordinates, not confirmed absence of the entity. Direct NPC and object
objectives are supported; item-drop and kill-credit associations are not inferred.

An owned, manually curated SFK planning catalog now supplies pickup and turn-in
pins for all seven visible quests **without Questie or QuestieDB**. It also covers
selected direct objectives and two associated chain steps. Points remain rounded planning estimates and return fresh copies. Buttons and
marker captions omit approximation suffixes at the owner's request. Locations inside SFK intentionally use the outdoor entrance on the
Silverpine map, with an **Entrance marker only** explanation of where to go inside.
No exact floor/NPC position is implied. The final Old Fire-Eye kill remains unknown
in this catalog; no objective point is invented. Forging/payment phases map to
Jordan/Dead Drop rather than incorrectly marking the earlier dungeon collection.

The optional installed QuestieDB/Questie APIs remain enrichment for gaps and
recorded patrols. Owned pins take priority; an optional ordered patrol attaches
only for the same named entity on the same map. No route is manufactured from
estimates or spawn clusters. Public entity getters and ZoneDB conversion follow
the inspected installed APIs. DungeonJournal's structured pickup maps remain an
additional fallback for uncataloged chain steps. Loot and quest list data still
come from the separately enabled DungeonJournal; this location work does not
remove that separate pilot dependency.

The native C_Map.OpenWorldMap entry point opens the zone (ShowUIPanel fallback).
Data-provider size/scale/map callbacks and three bounded post-open redraws handle
canvas layout settling; the overlay rebinds if the canvas changes. Closing,
dismissing or choosing another target invalidates queued redraws. Quest-log
ownership and completion are never queried to decide whether to show an icon.
Native map canvas data-provider callbacks manage an independent overlay: high-contrast
40px bordered quest/objective icons with labels, plus recorded patrol segments. Only
the clicked target is shown. Right-clicking its marker dismisses the owned icons
and route without closing the map; closing later still returns to settings. Multiple spawn points are never joined as a patrol;
separate paths remain separate; an invalid point invalidates its path. No Questie
artwork or route-rendering code is copied. Changing maps hides the overlay; closing
the map clears it. Settings hide while the map is open and return on close outside
combat. Disabling Dungeon Loot clears pins/lines. No polling or user-waypoint API.

Map opening requires out-of-combat state. Missing APIs or rejected opens produce
a status message on the quest page, without retrying rejected protected actions.
Native map support, dungeon-floor art, zoom/layering and actual SFK patrol-data
availability remain experimental and unconfirmed. Do not expand dungeon/map
coverage until the owner confirms the pilot in game. No quest acceptance, turn-in,
sharing, tracking, automated messages or journal-selection changes are implemented.

## Data, ownership and API assumptions

ForeverDungeonJournal must be separately installed/enabled for the pilot's loot
and quest data. Optional TOC dependencies establish load order without preventing
Play The Game Tools startup when providers are absent. Its exposed internal
namespace remains a compatibility risk. Community loot/quest assignments mix
Forever observations with Classic fallbacks; source counts are not official
completeness, current-drop or guaranteed quest-availability claims. No drop rates.

No reference-addon records, prose, code or artwork are bundled, downloaded,
scraped, persisted or exported. Source tables/SavedVariables are never changed.
DungeonJournal by Exehn/ExehnTV is All Rights Reserved:
https://www.curseforge.com/wow/addons/dungeonjournal
QuestieDB's LICENSE.md and Questie's licensing were inspected. The location adapter
is runtime API interoperability, not redistribution. Removing dependencies needs
verified data and appropriate redistribution terms.

Client-owned art: Interface/Glues/LoadingScreens/LoadScreenShadowFangKeep,
TargetingFrame/UI-PVP-Alliance / UI-PVP-Horde, GossipFrame quest icons and WorldMap
Skull_64. Boss display IDs come from installed metadata and are passed to native
SetPortraitTextureFromCreatureDisplayID; missing metadata/API uses Blizzard's
default boss icon. No baked reference portraits or Blizzard image files are shipped.

Primary Blizzard source reviewed 2026-11-07 on the forever branch:
- Blizzard_APIDocumentationGenerated/UnitDocumentation.lua, ItemDocumentation.lua
  and TooltipInfoDocumentation.lua: portrait/item signatures and tooltip updates.
- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/MapDocumentation.lua (C_Map.OpenWorldMap)
- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_MapCanvas/MapCanvas_DataProviderBase.lua
- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_MapCanvas/Blizzard_MapCanvas.lua
- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleLineAPIDocumentation.lua

## Architecture and checks

Modules/DungeonLootProvider.lua normalizes SFK data; DungeonLootLocationData.lua owns approximate points; DungeonLootLocations.lua reads
optional location APIs; DungeonLootMap.lua owns map overlays; DungeonLoot.lua owns
lifecycle and item metadata. Config/DungeonLootWidgets.lua pools themed rows;
Config/DungeonLoot.lua owns lists/details. Only module enable is saved in profiles.
Item listeners stop when hidden/disabled; snapshots/navigation/expansion are session
only. No settings migration or source-art copying.

With Python 3.12+ and lupa.lua51:

```
python tests/smoke.py
python tests/dungeon_loot.py --reference-directory "<installed ForeverDungeonJournal directory>"
python tests/dungeon_loot_map.py
python tools/build_release.py
```

Tests cover startup, all pages, profiles, source isolation, actual list/map button
callbacks, auto-selection, independent scroll preservation, filters/empty states,
pooled rows, tooltip threshold/colors/events/fallback, route geometry, no guessed
patrols, cleanup, combat guards, notes/class/chain styling and toolbar anchors.
Installed DungeonJournal data files run only in an isolated Lua 5.1 mock. Actual
Questie runtime data availability and native behavior are not established by mocks.
Preserve prior same-version artifacts before rebuilding; never overwrite evidence.

## Next native review — pending

Existing Forever AddOns junction targets this checkout's ModeTools folder. No
copy-sync, junction changes or SavedVariables edits. `/reload` should load changes;
if new optional providers are not recognized, report whether a restart was needed.
The owner liked earlier revisions; current quest styling/map behavior needs fresh
review. Supplied DungeonJournal screenshots are interaction references, not native
evidence of Play The Game Tools.

Use the current native review steps after the provenance table below. Screenshots: pending.

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

### Current native review additions

1. **Navigation:** `/mode` -> Questing & Leveling -> Dungeon Loot -> Dungeons ->
   Shadowfang Keep -> Quests -> Deathstalkers in Shadowfang -> 1. Starts at ->
   View on Map (High Executor Hadrec caption). **Action:** click with the quest in
   your log, then repeat on a character without it. **Required state:** Forever,
   out of combat, DungeonJournal and Dungeon Loot enabled; `/reload` after changes.
   **Confirmation:** a labeled quest marker appears near the Sepulcher in both
   cases; no approximation suffix. Test with Questie/QuestieDB disabled as well.
2. **Navigation:** resulting world-map marker. **Action:** zoom, right-click the
   marker, then close the map. **Required state:** map open. **Confirmation:** the
   marker stays attached to its location while zooming; right-click dismisses our
   icons/routes without closing the map; closing returns to settings.
3. **Navigation:** same quest -> 3. Turn in -> View on Map (Deathstalker Vincent
   (inside SFK) caption). **Action:** click. **Required state:** out of combat.
   **Confirmation:** the Silverpine entrance marker explains the courtyard
   destination; it does not claim an exact dungeon-floor position.
4. **Navigation:** Dungeon Loot -> Shadowfang Keep -> Quests, then Boss Loot.
   **Action:** inspect titles, steps and map controls. **Required state:** out of
   combat. **Confirmation:** numbered pickup/objective/turn-in steps, compact
   View on Map buttons, gold quest text, red boss names and blue general headers;
   class/item colors remain readable and heading glow remains subtle.

Focused mock tests cover exact gradient endpoints, compact button anchors,
ordered patrol geometry, ownership-independent targets, delayed/replaced canvas
layout and cancellation after dismissal. Native rendering, zoom, placement and
actual patrol availability remain pending. Screenshots: pending.
