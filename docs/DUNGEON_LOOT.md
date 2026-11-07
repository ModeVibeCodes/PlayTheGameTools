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
Headers use a mint-to-blue text gradient. Notes, descriptions and warnings appear
near the title without a notes toggle. Class names use localized Blizzard names
and RAID_CLASS_COLORS. List rows show Chain when prerequisite steps are recorded.
Objective, Starts at, Turn in and reward sections stay concise; Prerequisites (N)
expands chain acquisition details. The faction chooser is 128 × 28, with inherited
anchors cleared; search ends 10px before it. General owns compact Refresh and
source attribution. Dungeon emblems denote territory, not entry restrictions;
quest emblems denote quest faction.

## Locations and map pilot

Map pickup — [name], Map turn-in — [name] and Map objective — [name] buttons appear
only for recorded coordinates. Expanded prerequisites can also have buttons.
The (patrol) suffix means an ordered path is recorded. Missing buttons mean no
usable coordinates, not confirmed absence of the entity. Direct NPC and object
objectives are supported; item-drop and kill-credit associations are not inferred.

The optional, separately enabled QuestieDB (inspected 1.0.11) and Questie supply
locations through their installed public APIs: LibQuestieDB.Quest's startedBy,
finishedBy and objectives; Npc/Object name, spawns and waypoints; and
QuestieLoader:ImportModule("ZoneDB"):GetUiMapIdByAreaId. The installed Types and
src/api.lua establish getter and coordinate shapes. Percent coordinates and
ordered paths are normalized into new session-only data. DungeonJournal's
structured pickup maps are a fallback. No location is guessed from prose.

Native map canvas data-provider callbacks manage an independent overlay: yellow
native ! / ? markers, objective skulls and yellow recorded patrol segments. Only
the clicked target is shown. Multiple spawn points are never joined as a patrol;
separate paths remain separate; an invalid point invalidates its path. No Questie
artwork or route-rendering code is copied. Changing maps hides the overlay; closing
the map clears it. Settings hide while the map is open and return on close outside
combat. Disabling Dungeon Loot clears pins/lines. No polling or user-waypoint API.

Map opening requires out-of-combat state. Missing APIs or rejected opens produce
a status message on the quest page, with no automatic retry or workaround.
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
- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_MapCanvas/MapCanvas_DataProviderBase.lua
- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_MapCanvas/Blizzard_MapCanvas.lua
- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleLineAPIDocumentation.lua

## Architecture and checks

Modules/DungeonLootProvider.lua normalizes SFK data; DungeonLootLocations.lua reads
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

1. **Navigation:** `/mode` → Questing & Leveling → Dungeon Loot → Dungeons →
   Shadowfang Keep → Quests → Deathstalkers in Shadowfang.
   **Action:** `/reload`, inspect title, notes, section spacing, search and faction
   chooser. **Required state:** Forever, out of combat, DungeonJournal enabled.
   **Confirmation:** text/icons do not clip; headers have a gradient; notes are
   visible near the top; search and the smaller faction selector do not overlap.
2. **Navigation:** same quest → Map pickup — High Executor Hadrec.
   **Action:** click the pickup button, then close the map. **Required state:**
   out of combat. **Confirmation:** Silverpine opens with a yellow quest marker;
   settings do not obscure it and return on close. Missing capability/rejection
   produces an actionable status instead of a claimed successful pin.
3. **Navigation:** same quest → Map turn-in — Deathstalker Vincent.
   **Action:** click, zoom/change maps, then close. **Required state:** out of
   combat; optional QuestieDB/Questie enabled and a recorded finisher.
   **Confirmation:** the source's dungeon map and ? marker appear; markers never
   linger on another map or after close. If no finisher coordinate is supplied,
   no button appears; report the gap rather than using pickup coordinates.
4. **Navigation:** Quests → a recorded Map pickup / Map turn-in / Map objective
   button ending (patrol). **Action:** click it. **Required state:** out of combat,
   optional location sources enabled and a recorded ordered path for that entity.
   **Confirmation:** only that recorded patrol accompanies its marker. No SFK
   route availability is claimed yet; if no patrol button exists, this native
   route check cannot be performed until verified route data is available.
5. **Navigation:** Quests → The Horn of Xelthos → Prerequisites (1).
   **Action:** inspect class/Chain/notes, expand the prerequisite, then select a
   different quest. **Required state:** out of combat; All factions.
   **Confirmation:** Rogue is class colored, Chain is shown, notes are already
   visible, and prerequisite details expand without hiding the quest list.
6. **Navigation:** Boss Loot → Rethilgore, then Other loot → Fel Steed / Shadow
   Charger; then Dungeons. **Action:** compare loot and return to the card.
   **Required state:** out of combat; allow item metadata to arrive.
   **Confirmation:** short lists remain detailed, long lists compact, alignment
   stays correct and the smaller scenery-only card retains its source totals.

Screenshots: pending. Keep PR #6 draft until user-confirmed native checks and real
Forever before/after captures of the changed addon. Crop other players' names/chat.
