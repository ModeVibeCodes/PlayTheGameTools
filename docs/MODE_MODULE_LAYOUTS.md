# Mode module settings rollout — November 10, 2026

The owner accepted Campfire Monitor's flow and authorized applying the pattern
to the other module settings pages in PR #26. This rollout is **Mode only**.
Modern and Blizzard keep their existing page layouts. Broad native acceptance
is pending; the owner will review all modules before considering other themes.

The shared presentation layer reuses existing controls, getter/setter callbacks,
visibility predicates, search entries and saved settings. It adds no gameplay
behavior, settings defaults or SavedVariables migration. No settings were deleted.
The existing Rogue Customize selector is replaced by the Quick Icon / Expanded
Menu navigation; the General shortcut buttons still open their customization.

## Layout map

Open **PTG Tools**, then follow the sidebar category and page below. Main pills
fit one centered row; the smaller rectangular tabs tuck below a clipped separator
when inactive and rise when selected. Only panels with existing settings appear.
Each feature remembers its last panel until reload. Content headings are 20 units
with thin, symmetric fading underlines. Wide forms place the heading and muted
description beside their fields; mixed slider/toggle pages put the description
inline after a dot, with checkboxes under the left heading.

| Sidebar category → page | Main pills / retained views | Common settings panels |
| --- | --- | --- |
| Timers → Combat Timer | One display; existing preview controls stay above settings | Options, Text, Appearance, Position |
| Quality of Life → Automation | Quests, Merchant, Dialogue | Each is one compact Options page |
| Quality of Life → Quick Access Bars | Professions, Food Bar | Options, Text, Appearance, Position |
| Quality of Life → Threat Meter | One display | Options, Position; no invented text/appearance settings |
| Questing & Leveling → Class Training | General, Level Up Window, Shortcut Icon & Menu, Upcoming Abilities, Available & Known | Options, Text, Appearance where available; the last two views remain live catalogs |
| Questing & Leveling → Dungeon Loot | Dungeons, Boss Loot, Quests, General | General: Options, Appearance, Position, Data; browser/search/quest/map/binding behavior retained |
| Questing & Leveling → Gameplay Enhancements | Loot Sparkles, Campfire Monitor | Loot Sparkles: Options, Text, Appearance; approved Campfire layout unchanged |
| Questing & Leveling → Enhanced Experience Bar | XP Bar, Session Text | XP Bar: Options, Text, Appearance, Position; Session Text: Options, Text |
| Guild Tools → Recruitment | Recruiter, History | Original actions in compact Options pages; Recruiter gameplay window unchanged |
| Guild Tools → Roster | Class Summary, Members by Class | Existing class/member data layouts under the new pills and heading |
| Class Tools → Rogue | General, Poison Reminder, Quick Icon, Expanded Menu, Quick Apply | Options, Text, Appearance, Position where available; feature enablement remains in General |
| Developer Mode | Existing diagnostic groups and expansion gates | Heading styling only; no diagnostic controls moved |

Mode color rows show **Pick**, with their original wheel, live swatch and cancel
callbacks. Redundant in-page hex/Apply controls are hidden. Common size/color
and opacity/color pairs share rows. On wide pages with both sliders and toggles,
checkboxes move below the left heading; sliders stay in the form. Narrow pages
restore checkbox rows. Search follows the visible host and respects disabled
feature gates. A hidden result no longer attempts to scroll to a missing offset.

## Exact in-game checks

Use `/reload` OOC in the existing Forever test installation. No new artwork was
added in this rollout, so a client restart is not expected. Preserve settings;
restore every value changed during the checks. Record PASS / FAIL / NOT TESTED,
client build, resolution/UI scale, and the page/panel for any screenshot or error.

1. **Navigation:** PTG Tools → Global Settings → Appearance → Interface Theme →
   **mode**, then header **Reload**. **Action:** select Mode if necessary and
   reload. **Required state:** OOC. **Confirmation:** the existing charcoal/cyan
   theme and custom page texture remain; Global Texture still affects display
   elements rather than the settings interface.
2. **Navigation:** PTG Tools → each category/page in the layout map → every
   displayed main pill and secondary tab. **Action:** inspect each view, narrow
   and widen the settings window, then revisit a previous pill. **Required
   state:** OOC; enable the module with its header switch only if needed to
   inspect its active controls. **Confirmation:** all settings/data remain
   reachable; tabs stay inside one row, active tabs rise from the separator,
   inactive lower pixels are clipped, headings/underlines are consistent, and
   forms do not overlap the checkbox column or window edges.
3. **Navigation:** PTG Tools → Timers → Combat Timer → **Text** → **Font Size** /
   **Text Color** → **Pick**. **Action:** temporarily change font size, open the
   color wheel, change a color and cancel; restore the size. **Required state:**
   OOC; use the existing **Static** preview. **Confirmation:** original callbacks
   update the preview; cancellation restores the color; the picker shares the
   size row without in-page hex/Apply fields. **Text outline** moves to the left
   checkbox column at wide sizes and back into the form at narrower sizes.
4. **Navigation:** PTG Tools → header **Search settings...**. **Action:** search
   **Food Font Size**, then **Popout Text Size**, then **Icon Border Color** and
   open the relevant result. **Required state:** OOC; Quick Access Bars/Class
   Training/Rogue features enabled as needed. **Confirmation:** each result
   opens its correct Text or Appearance panel and highlights the visible
   control. Disabled Class Training windows keep their original tab gating and
   do not raise a Lua error.
5. **Navigation:** PTG Tools → Quality of Life → Quick Access Bars → **Food Bar**
   → **Options** → **Carried Items** row → **Refresh Bags**. **Action:** refresh
   carried items; visit Text, Appearance and Position, then return to Options.
   **Required state:** OOC; Food Bar enabled for a populated list.
   **Confirmation:** carried-item rows still refresh, show the original
   selections and remain selectable; no food or profession choices are reset.
6. **Navigation:** PTG Tools → Questing & Leveling → Class Training → **Level Up
   Window** / **Shortcut Icon & Menu**, then **Upcoming Abilities** / **Available
   & Known**. **Action:** review each settings panel and both catalogs; use
   General → **Spellbook** row → **Refresh**. **Required state:** OOC; header
   switch enabled and the two features enabled in General. **Confirmation:**
   catalogs refresh normally, costs and ability rows remain visible, and
   disabling a feature in General prevents access to its settings as before.
7. **Navigation:** PTG Tools → Questing & Leveling → Dungeon Loot → **General**
   → **Options / Appearance / Position / Data**. **Action:** inspect settings,
   briefly adjust Icon Size and restore it, then return to **Dungeons** and open
   a dungeon's **Boss Loot** and **Quests**. **Required state:** OOC; module
   enabled. **Confirmation:** the General panels contain the original shortcut,
   keybinding, position and data actions; catalog search, details and maps still
   work and General tabs stay hidden in the browser. No keybinding changes are
   necessary for this layout check.
8. **Navigation:** PTG Tools → Class Tools → Rogue → **General**, then **Poison
   Reminder / Quick Icon / Expanded Menu** → **Text / Appearance / Position**
   where shown. **Action:** review each feature, temporarily adjust Text Size
   and restore it; return to **Quick Apply**. **Required state:** OOC, Rogue
   character, Poison Reminder and Quick Access Poisons enabled in General.
   **Confirmation:** independent styles remain independent, controls operate
   on the selected feature, and the poison selection grid/actions still work.
   These checks do not require applying poison or changing a keybinding.
9. **Navigation:** PTG Tools → Guild Tools → **Recruitment / Roster**.
   **Action:** visit **Recruiter / History** and **Class Summary / Members by
   Class**. **Required state:** OOC; guild membership for populated roster data.
   **Confirmation:** original actions/data remain accessible and live refresh
   does not lose rows. Do not clear history or send invitations for this check.
10. **Navigation:** PTG Tools → Questing & Leveling → Gameplay Enhancements →
    **Campfire Monitor** → **Campfire Icon / Camp Buffs / Contributions**.
    **Action:** inspect the accepted panels, then alternate with **Loot
    Sparkles** → **Options / Text / Appearance**. **Required state:** OOC.
    **Confirmation:** Campfire keeps its accepted flow, preview cleanup and
    independent state; neither page leaves stray tabs, gutters or scroll gaps.
11. **Navigation:** PTG Tools → Global Settings → Appearance → Interface Theme
    → **Modern / Blizzard**, then header **Reload**. **Action:** inspect a
    previously checked module, then restore Mode and reload. **Required state:**
    OOC. **Confirmation:** both original themes retain their original layouts
    and color editors; edited module values and profile data persist.

Static validation: `tests/mode_module_layouts.py` checks complete original
settings-label inventories, panel/search reachability, native callback ownership,
wide/narrow checkbox restoration, paired controls, Class Training gating/catalog
rebuild, Dungeon Loot row recycling, Campfire coexistence and theme isolation.
The full regression suite and deterministic builder remain required. Mock checks
do not establish native visual quality or Blizzard support.
