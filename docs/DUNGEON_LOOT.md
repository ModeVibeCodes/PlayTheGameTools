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
Headers use an amber-to-rose-to-violet text gradient with a faint static glow. Notes, descriptions and warnings appear
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

An owned, manually curated SFK planning catalog now supplies pickup and turn-in
pins for all seven visible quests **without Questie or QuestieDB**. It also covers
selected direct objectives and two associated chain steps. Points are rounded,
marked **[approx.]** on buttons and **Approximate location** on markers, and return
fresh copies. Locations inside SFK intentionally use the outdoor entrance on the
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

Native map canvas data-provider callbacks manage an independent overlay: high-contrast
40px bordered quest/objective icons with labels, plus recorded patrol segments. Only
the clicked target is shown. Right-clicking its marker dismisses the owned icons
and route without closing the map; closing later still returns to settings. Multiple spawn points are never joined as a patrol;
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

1. **Navigation:** `/mode` → Questing & Leveling → Dungeon Loot → Dungeons →
   Shadowfang Keep → Quests → Deathstalkers in Shadowfang.
   **Action:** `/reload`, inspect title, notes, section spacing, search and faction
   chooser. **Required state:** Forever, out of combat, DungeonJournal enabled.
   **Confirmation:** text/icons do not clip; headers have a gradient; notes are
   visible near the top; search and the smaller faction selector do not overlap.
2. **Navigation:** same quest → Map pickup — High Executor Hadrec [approx.].
   **Action:** click the pickup button, then close the map. **Required state:**
   out of combat. **Confirmation:** Silverpine opens with a yellow quest marker;
   settings do not obscure it and return on close. Missing capability/rejection
   produces an actionable status instead of a claimed successful pin.
3. **Navigation:** same quest → Map turn-in — Deathstalker Vincent (inside SFK)
   [approx.]. **Action:** click, zoom/change maps, then close. **Required state:**
   out of combat; Questie is not required. **Confirmation:** the owned Silverpine
   entrance marker appears with an explanation to enter for the courtyard. It
   does not imply exact interior coordinates; map changes/close clear it.
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

- **Navigation:** AddOns → Questie / QuestieDB; then `/mode` → Questing & Leveling
  → Dungeon Loot → Shadowfang Keep → Quests → Deathstalkers in Shadowfang →
  Map pickup — High Executor Hadrec [approx.]. **Action:** disable Questie and
  QuestieDB, `/reload`, then click the map button. **Required state:** Forever,
  out of combat; DungeonJournal and Dungeon Loot enabled. **Confirmation:** a
  high-contrast labeled quest icon appears near the Sepulcher, clearly marked
  approximate. The owned estimate works without either Questie addon.
- **Navigation:** the resulting world-map marker. **Action:** right-click it, then
  close the map. **Required state:** map open. **Confirmation:** only this addon's
  markers/route disappear; the map stays open, and closing it returns to settings.
- **Navigation:** Quests → Deathstalkers in Shadowfang → Map turn-in — Deathstalker
  Vincent (inside SFK) [approx.]. **Action:** click with Questie still disabled.
  **Required state:** out of combat. **Confirmation:** the marker is at the outdoor
  SFK entrance; its tooltip explicitly explains the interior courtyard destination.
  It does not claim to pinpoint Vincent on a dungeon floor.
- **Navigation:** Dungeon Loot → Shadowfang Keep → Quests → any quest detail.
  **Action:** inspect section headings. **Required state:** out of combat.
  **Confirmation:** amber/rose/violet colors and a restrained static glow, with
  readable normal text and unchanged native item-quality colors.

Focused tests now verify all seven owned pickup/return pairs with optional
providers absent, copy isolation, interior-proxy labeling, unknown-objective
handling, warm gradient/glow, marker elevation/labeling and right-click dismissal.
Native marker visibility, exact planning-point placement and glow remain pending.