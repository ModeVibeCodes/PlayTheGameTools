# Dungeon Loot — Shadowfang Keep pilot

Dungeon Loot is under **Questing & Leveling**, alongside Class Training. It is off
by default. Enable it with the Dungeon Loot page's header switch. The visible
addon is Play The Game Tools; compatibility IDs and ModeToolsDB are unchanged.

## Current experience

Only Shadowfang Keep appears. **Dungeons** shows a large Blizzard loading-screen
card under **Suggested levels 20–30**, with its title across the top, Silverpine
Forest location, Horde territory emblem, boss count and total quest count.
The range follows the installed DungeonJournal 1.7.0 SFK record; it is a suggested
bracket, not the entry requirement. External community ranges differ. No other
dungeons or example ranges are populated pending acceptance of the SFK experience.

The card opens **Boss Loot**, a responsive grid of native boss portraits. Clicking
a portrait opens the loot list, with client item icons, quality colors and native
hover tooltips. Rare encounters are labeled. **Other loot** contains the stable
mobs, Arugal's Voidwalker and Trash Drops rather than counting them as bosses.
The inspected source supplies **8 bosses + 1 rare**, 3 extra source groups and
**7 quests**. These counts describe the installed source, not official completeness.

**Quests** shows clickable cards with faction emblems, class/level requirements
and pickup location previews. The All factions / Alliance / Horde filter includes
Both-faction quests appropriately. Details have clear sections: **Start here**,
**Before you go**, **In the dungeon**, **Turn in** and **Rewards**. Prerequisite
steps include their acquisition details when recorded. Coordinates are text with
location labels. No quest acceptance, turn-in, tracking or map-pin action exists.

**General** owns the small **Refresh** button, data attribution, and explanations
of suggested levels and faction emblems. Source/version and implementation
commentary no longer appear throughout the browser. Missing-data and loading
messages remain where they help the player. Dungeon emblems indicate surrounding
territory, not faction entry restrictions. Quest emblems indicate quest faction;
the icon helper supports both emblems for neutral/combined entries.

## Data, art and API provenance

This pilot requires **ForeverDungeonJournal** to be installed and enabled.
The optional TOC dependency establishes load order without blocking Play The Game
Tools if absent. The provider reads its exposed namespace into an ephemeral
normalized SFK snapshot. It never changes the source tables or SavedVariables.
No reference-addon records, prose, code or artwork are shipped, downloaded,
scraped, persisted or exported. DungeonJournal by Exehn/ExehnTV is All Rights
Reserved: https://www.curseforge.com/wow/addons/dungeonjournal
The installed source mixes Forever observations with Classic fallbacks. Missing
records remain unknown; no drop rates or guaranteed quest availability are claimed.
The internal namespace remains a compatibility risk. Expanding coverage or
removing this dependency needs verified data and suitable redistribution terms.

The loading-screen texture is the client-owned
`Interface/Glues/LoadingScreens/LoadScreenShadowFangKeep`, already referenced by
the installed addon's SFK art metadata. No reference addon image is used. The
territory/quest emblems are Blizzard's `Interface/TargetingFrame/UI-PVP-Alliance`
and `UI-PVP-Horde` textures. Boss display IDs are read from the installed source's
`STATIC_DISPLAY_IDS`/boss metadata at runtime, then rendered by native
`SetPortraitTextureFromCreatureDisplayID(texture, displayID)`. No upstream baked
portraits or model-resolver code is used. Missing IDs/API fall back to Blizzard's
`Interface/EncounterJournal/UI-EJ-BOSS-Default`. Native availability and appearance
still require in-game review.

Blizzard's generated documentation on the `forever` branch was reviewed
2026-11-07 for the portrait signature and item APIs:
- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua
- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemDocumentation.lua

## Architecture and checks

- Modules/DungeonLootProvider.lua: read-only SFK adapter, counts and metadata.
- Modules/DungeonLoot.lua: lifecycle, session navigation and item metadata.
- Config/DungeonLootWidgets.lua: pooled cards, faction emblems and portrait grids.
- Config/DungeonLoot.lua: tabs, browser and grouped quest acquisition pages.
- Only the enable preference is saved in the profile. No settings migration.
- Item metadata uses C_Item.GetItemInfo (legacy fallback),
  C_Item.RequestLoadItemDataByID and GET_ITEM_INFO_RECEIVED. Requests are bounded
  per item until Refresh. No polling. The listener is removed when disabled or
  the page is hidden. No secure actions, journal-selection changes or global hooks.

With Python 3.12+ and lupa.lua51 available:

```
python tests/smoke.py
python tests/dungeon_loot.py
python tests/dungeon_loot.py --reference-directory "<installed ForeverDungeonJournal directory>"
python tools/build_release.py
```

Focused checks cover the SFK-only card and counts, General-only refresh, native
portrait handoff and fallback, two-emblem rendering, grid/list callbacks, source
immutability, schema guards, metadata events, tooltips, filtering, row pooling,
module lifecycle and enable-state profile roundtrip. Optional reference testing
executes data files only in the isolated Lua 5.1 mock; it is not native acceptance.

## Native review — redesign pending

The owner reviewed the initial pilot positively; this visual revision needs fresh
native review and before/after screenshots. The existing Forever AddOns junction
points to this checkout's ModeTools folder. No copy-sync, junction changes or
SavedVariables edits. These are Lua/TOC changes using client-owned assets:
`/reload` should load them. Report any client restart needed for new Lua/art.

1. **Navigation:** `/mode` → Questing & Leveling → Dungeon Loot → Dungeons.
   **Action:** keep DungeonJournal and Dungeon Loot enabled, `/reload`, then open
   the page. **Required state:** Forever, out of combat. **Confirmation:** only
   Shadowfang Keep appears under Suggested levels 20–30, as a large loading-screen
   card with title, 8 bosses + 1 rare, 7 quests and a Horde territory emblem.
2. **Navigation:** Play The Game Tools → Questing & Leveling → Dungeon Loot →
   Dungeons → Shadowfang Keep → Boss Loot → Rethilgore.
   **Action:** click the boss portrait and hover an item; use < All bosses.
   **Required state:** out of combat; allow item metadata to arrive.
   **Confirmation:** boss portraits render, loot tooltips appear, and the return
   control restores the grid. Other loot remains separate. Check narrow and wide
   window sizes for portrait, title and loot-row fit.
3. **Navigation:** Play The Game Tools → Questing & Leveling → Dungeon Loot →
   Shadowfang Keep → Quests → Deathstalkers in Shadowfang.
   **Action:** inspect the five named detail sections; return with < All quests
   and try Quest faction / Search names. **Required state:** out of combat;
   All factions or Horde selected. **Confirmation:** Hadrec pickup and Vincent
   turn-in text appear, faction icons and requirements are clear, and filters work.
   Also inspect a class quest's long prerequisite chain for wrapping and scrolling.
4. **Navigation:** Play The Game Tools → Questing & Leveling → Dungeon Loot →
   General → Dungeon data → Refresh. **Action:** refresh, then return to Dungeons.
   **Required state:** out of combat. **Confirmation:** Refresh is compact and
   appears only in General; source attribution stays there. The dungeon card
   still shows the same totals and artwork.
5. **Navigation:** Play The Game Tools → Questing & Leveling → Dungeon Loot →
   header module switch. **Action:** disable, enable and `/reload`.
   **Required state:** out of combat. **Confirmation:** browsing turns off/on and
   enable preference persists; other module settings stay intact.

Screenshots: pending. Keep the PR draft until native behavior and real Forever
before/after captures are supplied. Crop chat and other players' names.
