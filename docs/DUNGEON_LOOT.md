# Dungeon Loot — Shadowfang Keep pilot

Dungeon Loot is an independent module under **Questing & Leveling**, alongside
Class Training. It is off by default. Enable it with the Dungeon Loot page's
header switch. The visible addon is Play The Game Tools; technical identifiers,
slash commands and ModeToolsDB are unchanged.

## Current scope

The dungeon index lists the dungeons supplied by the installed data addon.
Shadowfang Keep is the only pilot with details. Other entries say **Not in this
pilot** and open an explicit scope message. This is not a complete official
Forever dungeon inventory.

SFK has Boss Loot and Quests views. Boss/source groups open their item lists;
items show client icons and quality colors when available and native hover
tooltips. Search names filters the current list. Quests show faction/class,
required level, objectives, pickup and turn-in text, coordinates when recorded,
notes, prerequisite steps with recorded acquisition details, and reward items.
Quest faction offers All factions, Alliance and Horde; Both-faction quests remain
visible in either faction filter. All classes are listed with their restrictions
shown rather than silently omitted. There is no promise that a quest is currently
offered to this character. No quest acceptance, turn-in, tracking or map-pin action
is implemented. Coordinates are textual, accompanied by the source's location.

## Data and ownership

This first pilot requires **ForeverDungeonJournal** to be installed and enabled.
The optional TOC dependency establishes load order without preventing Play The
Game Tools from loading when it is absent. The independent provider reads
`ForeverDungeonJournal_NS.DB`, quest prerequisite details and quest start maps
into a session-only normalized snapshot. It never calls the reference UI or
writes its tables or SavedVariables. It does not ship, download, scrape, persist
or export that addon's records, prose, artwork or code. The installed addon's
version is visible on the page. Use Refresh Data to take a fresh snapshot and
retry item metadata requests. Opening the page also refreshes the snapshot.

DungeonJournal by Exehn/ExehnTV is All Rights Reserved:
https://www.curseforge.com/wow/addons/dungeonjournal
The inspected installed version was 1.7.0. Its source history mixes Forever
observations with Classic fallbacks. A listed item is a claim by that source,
not independent confirmation of a current drop. Missing tables, an empty loot
list and no filter matches have separate messages. No drop probabilities are
provided. The provider's use of an exposed internal namespace is a compatibility
risk; the focused test accepts a local reference directory to check its schema
without bundling its records. Expanding coverage or removing the dependency needs
separately verified data and appropriate redistribution terms. Wowhead links or
public visibility alone do not establish permission to redistribute a database.

## Architecture and API assumptions

- Modules/DungeonLootProvider.lua: read-only source adapter and normalization.
- Modules/DungeonLoot.lua: module lifecycle, session navigation and item metadata.
- Config/DungeonLoot.lua: pooled rows, current theme/widgets, browser and tooltips.
- Only the enable preference is saved in the existing profile. Source tables,
  navigation, search and item caches are not persisted. No settings migration.
- C_Item.GetItemInfo (legacy GetItemInfo fallback),
  C_Item.RequestLoadItemDataByID and GET_ITEM_INFO_RECEIVED handle visible item
  metadata, with at most one request per item until Refresh Data. No polling.
- The item event listener is removed when disabled or the page is hidden.
- GameTooltip:SetHyperlink provides native item inspection. No secure actions,
  encounter-journal selection changes, global tooltip hooks or automated messages.
- Blizzard generated ItemDocumentation on the wow-ui-source forever branch was
  reviewed on 2026-11-07. Documented functions and mocks do not establish native
  behavior, cache timing, quality accuracy, rendering or combat safety.
  https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemDocumentation.lua

## Validation

Use Python 3.12+ with lupa.lua51 available:

```
python tests/smoke.py
python tests/dungeon_loot.py
python tests/dungeon_loot.py --reference-directory "<installed ForeverDungeonJournal directory>"
python tools/build_release.py
```

The focused test uses synthetic records for callbacks, schema guards, upstream
immutability, pending metadata, native-tooltip handoff, search/faction filters,
row pooling, event lifecycle and enable-state profile roundtrip. The optional
reference run executes only the reference's data Lua in the isolated Lua 5.1
mock; no UI, SavedVariables or game interaction. The inspected 1.7.0 data supplied
35 dungeon entries, 12 SFK boss/source groups and 7 quests. These are source
counts, not native acceptance or a completeness claim.

## Native review — pending

The current machine's live ModeTools junction points to this checkout's ModeTools
folder. No directory-copy sync was run. The pilot has Lua/TOC changes and uses
existing Blizzard item icons; `/reload` should load it without a full restart.
If the newly added optional dependency is not recognized, restart the client and
report that result. Do not recreate the junction or change SavedVariables.

1. **Navigation:** AddOns list → DungeonJournal; then `/mode` → Questing & Leveling
   → Dungeon Loot → header module switch. **Action:** keep DungeonJournal enabled,
   `/reload`, open the page and turn Dungeon Loot on. **Required state:** Forever,
   out of combat. **Confirmation:** the source version and dungeon index appear;
   Class Training remains available beside Dungeon Loot.
2. **Navigation:** Play The Game Tools → Questing & Leveling → Dungeon Loot →
   All Dungeons → Shadowfang Keep — Pilot → Boss Loot → Rethilgore.
   **Action:** open the boss and hover an item. **Required state:** out of combat;
   allow the client to fetch uncached items. **Confirmation:** item rows and icons
   appear; a native item tooltip opens. Pending metadata updates without polling.
3. **Navigation:** Play The Game Tools → Questing & Leveling → Dungeon Loot →
   Shadowfang Keep → Quests → Deathstalkers in Shadowfang.
   **Action:** inspect its pickup/turn-in details and rewards; use < All quests,
   Quest faction and Search names. **Required state:** out of combat; All factions
   or Horde selected to see this quest. **Confirmation:** High Executor Hadrec is
   listed for pickup, Deathstalker Vincent for turn-in, and only matching quests
   remain. Check the class quests' notes and recorded prerequisites separately.
4. **Navigation:** Play The Game Tools → Questing & Leveling → Dungeon Loot →
   header module switch. **Action:** turn the module off, on, and `/reload`.
   **Required state:** out of combat. **Confirmation:** off replaces browser content
   with the enable message; on restores browsing; the enable preference persists.
   Existing module settings remain intact.
5. **Navigation:** Play The Game Tools → Questing & Leveling → Dungeon Loot →
   All Dungeons → any entry marked Not in this pilot. **Action:** open it, then
   return with All Dungeons. **Required state:** out of combat. **Confirmation:**
   an explicit pilot-scope message appears rather than invented or empty loot.

Screenshots: pending. Keep the PR draft until the user confirms native behavior
and supplies real Forever screenshots. Crop chat and other players' names. Review
text fit, scrolling, tooltips and long class-quest chains before adding dungeons.
