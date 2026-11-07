# Dungeon Loot — Shadowfang Keep pilot

Dungeon Loot is under **Questing & Leveling**, alongside Class Training. It is off
by default. Enable it with the Dungeon Loot page's header switch. The visible
addon is Play The Game Tools; compatibility IDs and ModeToolsDB are unchanged.

## Current experience

Only Shadowfang Keep appears. **Dungeons** shows a large Blizzard loading-screen
shorter, tightly cropped card under **Suggested levels 20–30**, with its title across the top, Silverpine
Forest location, Horde territory emblem, boss count and total quest count.
The range follows the installed DungeonJournal 1.7.0 SFK record; it is a suggested
bracket, not the entry requirement. External community ranges differ. No other
dungeons or example ranges are populated pending acceptance of the SFK experience.

The card opens **Boss Loot** with a persistent portrait list on the left and the
selected boss's loot on the right. The first matching boss is selected immediately.
Clicking another boss changes the right pane in place, highlights that boss, resets
only the detail scroll, and preserves the left list's position. No boss back button
or intermediate grid is required. Each pane scrolls independently. **Other loot**
keeps the stable mobs, Arugal's Voidwalker and Trash Drops separate from the boss
count. The inspected source supplies **8 bosses + 1 rare**, 3 extra source groups
and **7 quests**; these are source counts, not an official completeness claim.

Bosses with **up to five items** show public client tooltip lines immediately
beneath each item name, including native text colors. **Six or more items** use
compact name/slot rows. Quest reward rows remain compact. Names and icons share
10px top padding, text is explicitly top-justified and item rows have at least
54px of height so icons cannot overrun the bottom. Hover tooltips remain available.
Inline data comes from `C_TooltipInfo.GetItemByID`; missing/restricted data is not
inferred and falls back to a hover-details hint. Only the selected small loot list
is queried; its `TOOLTIP_DATA_UPDATE` instance IDs refresh details without polling.
The first tooltip line is treated as the item title and omitted from the body to
avoid repetition. This is textual tooltip presentation, not a full embedded native
tooltip widget; specialized graphics and comparison widgets stay in the hover UI.
The generated Forever TooltipInfo documentation was reviewed on 2026-11-07:
https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/TooltipInfoDocumentation.lua

The dungeon card height is now 180px (previously 230px), with source texture UVs
0.04–0.96 horizontally and 0.28–0.78 vertically. This excludes the logo and loading
bar regions; exact native framing still requires visual review.

**Quests** uses the same two-pane layout: compact faction/class/level rows on the
left; **Objective**, **Starts at**, **Turn in** and reward item cards on the right.
The source's choice flag controls the **Choose one reward** heading. Item names
are not repeated in the prose reward summary. **Prerequisites (N)** and **Quest
notes** expand longer acquisition/chain details on demand; important warnings stay
visible. Picking a new quest collapses those extras and resets its detail scroll.
Both-faction quests remain visible in the Alliance/Horde filter. Changing search
or faction selects the first remaining match when needed, or shows an explicit
empty state. Returning between Boss Loot and Quests preserves their selections.
Coordinates remain textual; no map, sharing, tracking or quest actions were added.
The supplied DungeonJournal screenshots guide the interaction, not this addon's
styling, implementation or feature scope. Its images are not bundled or presented
as screenshots of the changed Play The Game Tools UI.

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
- Config/DungeonLootWidgets.lua: pooled cards, compact portrait rows and emblems.
- Config/DungeonLoot.lua: fixed tabs, independently scrolling lists/details and quest disclosure.
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
portrait handoff and fallback, two-emblem rendering, list/detail callbacks, source
immutability, schema guards, metadata events, tooltips, filtering, row pooling,
module lifecycle and enable-state profile roundtrip. Optional reference testing
executes data files only in the isolated Lua 5.1 mock; it is not native acceptance.

## Native review — two-pane revision pending

The owner reviewed the prior pilot positively and supplied DungeonJournal
interaction examples. These are reference screenshots, not native evidence of
this revision. The existing Forever AddOns junction targets this checkout's
ModeTools folder. No copy-sync, junction changes or SavedVariables edits.
Lua-only changes should load with `/reload`; no full client restart is expected.

1. **Navigation:** `/mode` → Questing & Leveling → Dungeon Loot → Dungeons →
   Shadowfang Keep. **Action:** `/reload`, open the dungeon, then select Rethilgore
   and Razorclaw the Butcher from the left list. **Required state:** Forever,
   out of combat, DungeonJournal and Dungeon Loot enabled. **Confirmation:** the
   first boss is selected immediately; either click replaces the right-hand loot
   without hiding the list or requiring a back button. Portraits and hover item
   tooltips remain available. Scroll down the boss list and confirm switching
   bosses preserves that list position while resetting only the loot pane.
2. **Navigation:** Play The Game Tools → Questing & Leveling → Dungeon Loot →
   Shadowfang Keep → Quests → Deathstalkers in Shadowfang. **Action:** switch to
   The Book of Ur directly from the left list. **Required state:** out of combat;
   All factions or Horde selected. **Confirmation:** compact Objective, Starts at,
   Turn in and reward cards change in place; the quest list remains visible.
3. **Navigation:** Play The Game Tools → Questing & Leveling → Dungeon Loot →
   Shadowfang Keep → Quests → The Horn of Xelthos → Prerequisites (1) / Quest notes.
   **Action:** open the displayed prerequisite-count button and Quest notes, then
   select a different quest. **Required state:** out of combat; All factions.
   **Confirmation:** long details expand only when requested and collapse for the
   next quest. The inspected source lists one prerequisite here. No prerequisite
   button is shown when the source records no prerequisites.
4. **Navigation:** Play The Game Tools → Questing & Leveling → Dungeon Loot →
   Shadowfang Keep → Quests → All factions dropdown / Search names field.
   **Action:** choose Alliance, then search for a nonexistent quest. Clear search
   and return to All factions. **Required state:** out of combat. **Confirmation:**
   list and detail stay consistent, excluded selections are replaced by a matching
   quest, and no-match messages replace stale details. Both panes wrap and scroll
   independently at the current settings-window width.
5. **Navigation:** Play The Game Tools → Questing & Leveling → Dungeon Loot →
   General → Refresh, then Dungeons. **Action:** refresh and return to the card.
   **Required state:** out of combat. **Confirmation:** Refresh stays compact;
   the full-width artwork card is restored with unchanged source totals.

6. **Navigation:** Play The Game Tools → Questing & Leveling → Dungeon Loot →
   Shadowfang Keep → Boss Loot → Rethilgore, then Other loot → Fel Steed / Shadow
   Charger. **Action:** compare the item lists, then return to Dungeons.
   **Required state:** Forever, out of combat; allow client item data to arrive.
   **Confirmation:** Rethilgore's short list shows item details inline and hover
   tooltips; the stable source's longer list remains compact. Icons and text align
   at the top without bottom clipping. The smaller SFK card shows dungeon scenery
   without the WoW logo or loading bar. Source changes can alter item counts; the
   fixed display threshold is up to five detailed cards, six or more compact rows.

Screenshots: pending. Keep the PR draft for native review and real Forever
before/after captures of the changed addon. Crop chat and other players' names.