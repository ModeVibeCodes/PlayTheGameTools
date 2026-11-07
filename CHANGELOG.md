# Play The Game Tools changelog

## Unreleased

- Fixed campfire movement with Move Windows and draggable previews; aura/font refreshes no longer reset dragged anchors. Added compact earned-buff lines and optional independently positioned buff text that remains while its earned buffs last.

- Gameplay Enhancements now has separate Loot Sparkles and Campfire Monitor tabs with per-feature switches. Added an opt-in native campfire proximity icon/text monitor, earned bonus details, appearance/position controls, preview and a clearly labeled profession guide. Campfire native validation/screenshots pending.

- Added default-off Loot Sparkles under Questing & Leveling -> Gameplay Enhancements, with quest/node/corpse switches, animated glints, optional object names/range text, appearance controls and owned client-setting restoration. Native validation and screenshots pending; see docs/LOOT_SPARKLES.md.
- Added interface themes: Dashboard > Appearance > Interface Theme chooses
  Modern (default, unchanged) or Blizzard (stock dialog border and stone, red
  push buttons, stock checkboxes, input borders and slider knob, the game font
  with drop shadows, and softened gold/parchment text). The choice is saved per
  profile and applies after reloading the interface.
- Restyled the Threat Meter panel: graphite panel with a hairline border and
  header strip, flat class-coloured bars, the interface font and plain empty
  states. Your own row carries an accent edge that turns amber near pulling.
- Settings labels left blank on the first open after a fresh game launch (the
  sidebar and window title) now fill themselves in shortly after the window opens.

- Added clear In your log / Completed labels to Dungeon Loot quest lists/details.
  Dungeon tiles now recognize character completion history, show All quests
  completed when every eligible task is finished, and put larger pickup counts
  at bottom right. Grouped repeated titles only when mandatory prerequisite
  links prove the same chain; all stages remain available through compact stage
  buttons. Removed 15 duplicated catalog listings (Ruins: six Horde tasks).
  Centered dungeon titles with adjacent faction emblems, reversed/underlined
  Suggested Starting Levels headings and added a compact level-bracket jump strip.

- Dungeon Loot now automatically hides quests and prerequisites for the opposite
  faction or another class. Dungeon cards show the character's quest-log count
  out of faction/class-eligible catalog quests, plus pickup progress for their
  class-specific quests. Counts update while the browser is visible; the faction
  control is now an automatic identity badge. SFK collection stages count toward
  their listed reward-step quest without double-counting the chain.

- Finished renaming from ModeTools: the addon folder, TOC, settings variable
  (`PTGToolsDB`) and frame names now use Play The Game Tools names. Open
  configuration with `/ptg`; `/modetools` and `/mode` were removed. Settings are
  adopted automatically once SavedVariables/ModeTools.lua is renamed to
  PlayTheGameTools.lua.
- Added a Threat Meter module (Quality of Life, off by default): a plain list of
  threat on your current hostile target for you and your party or raid, tanking
  first, then highest percentage. Optional Show Pets (off by default), Hide Out
  of Combat while locked, Lock Threat Meter and Reset Position.

- Made Dungeon Loot standalone: bundled the GPLv3 Lootified 1.2.0 data catalog
  with its full license, source attribution and editable Lua. Removed the
  DungeonJournal dependency and external artwork paths. Native world-coordinate
  conversion supports recorded pickup/return locations without Questie. Retained
  SFK class quests and the accepted UI; incomplete/newer records remain labeled.

- Expanded the accepted SFK browser to every recorded Forever dungeon/wing:
  31 playable entries and four non-clickable previews in the current source.
  Added sorted suggested-starting-level groups, per-dungeon scenes/counts/region
  emblems, a fixed dungeon context header and independent selection routing.
  Selected-dungeon normalization keeps item/location work bounded. Recorded
  giver-name joins and explicit entrance proxies improve map/copy coverage;
  missing or ambiguous locations remain unavailable. No upstream media copied; data bundling is described above.

- Replaced invisible loose map markers with managed native map pins using an
  addon-owned XML template, normalized positioning, zoom compensation and the
  native topmost frame level. Added pool lifecycle/load-order validation and
  actionable marker errors, including failures inside map refresh callbacks.

- Tightened SFK quest spacing, added glowing gray NPC subheaders and retained
  useful location hints. Objective map actions are removed. Pickup/turn-in actions
  now pair View on Map with Copy Coordinates (preselected field, Ctrl+C).
  Added blue-gradient tab underlines and cleaner centered map symbols with blue
  borders and a short hide tooltip. Lightened/shrank dungeon card text bands.

- Updated Dungeon Loot map opening/layout handling with the native zone-opening
  API, bounded redraws and canvas rebinding. Custom markers remain independent
  of quest ownership. Added compact View on Map buttons, removed approximation
  suffixes, numbered quest steps, and applied the requested blue/red/gold gradients.

- Dungeon Loot headers now use amber/rose/violet with a subtle static glow. Map
  targets use larger contrasting labeled icons, dismissible by right-click.
  Added an owned, attributed SFK pickup/turn-in planning catalog for all seven
  quests, usable without Questie. Points remain planning estimates; interior destinations
  use explicit entrance proxies. Optional sources may still enrich patrols.

- Refined Dungeon Loot quest alignment, gradient headings, always-visible notes,
  class colors and Chain indicators. Fixed the search/faction anchor overlap.
  Added experimental OOC quest-map buttons with native !/? markers and ordered
  patrol lines from optional installed QuestieDB/Questie data. Missing coordinates
  stay unknown; source tables and other addons are not modified.

- Top-aligned Dungeon Loot item icons/text with enough row height. Bosses with up
  to five items now show client tooltip text inline; six or more stay compact.
  Native tooltip-data updates refresh visible details without polling. Shortened
  and tightened the SFK loading-screen crop to exclude its logo/loading bar.

- Dungeon Loot now keeps a persistent boss/quest list beside its selected detail
  pane. The first entry opens automatically; switching entries updates loot or
  quest details in place and preserves list scroll. Quest details are condensed
  to objective, pickup, turn-in and rewards, with expandable notes/prerequisites.
  Removed boss/quest back navigation and redundant reward prose.

- Refined Dungeon Loot into an SFK-only loading-screen card grouped by suggested
  levels, with boss/rare/quest totals and a Horde territory emblem. Added native
  boss portrait grids, quest faction emblems and grouped acquisition/reward
  sections. Moved the compact Refresh control and attribution to General.
  Other dungeon entries and repeated implementation descriptions were removed.

- Added the off-by-default Dungeon Loot SFK pilot under Questing & Leveling:
  dungeon index, boss/source loot with native item tooltips, and dungeon quests
  with pickup/turn-in locations, prerequisites and rewards. Reads the separately
  installed, enabled DungeonJournal at runtime; no third-party tables are bundled.
  Includes name search and quest faction filtering. Native review is pending.
  See docs/DUNGEON_LOOT.md.

- The guild ding message now includes the time it took to level on the first
  level-up of a session. With Time to Level on, Class Training requests /played
  once per login or reload (the client prints its usual two /played lines) and
  adds the server's time played at that level. The level-up window's Time to
  level line uses the same value. If /played is unavailable it falls back to
  the in-session clock as before.
- Replaced the Recruitment module with the guild's standalone recruiter flow:
  class x level-range Who searches that split capped ranges, a Recruiter window
  (`/ptgr`), a Ctrl+C copy-name box for Guild > Add Member in place of the blocked
  direct invite and chat drafts, optional whisper after a confirmed invite,
  invite/join/decline statistics, a re-invite window (default 7 days) and a
  never-invite list. Each manual Scan clears the candidate list. Existing level
  range and message are kept; Mark Contacted entries now expire after the
  re-invite window and Skip entries become never-invite entries. The zone filter
  was removed.
- Redesigned the settings window: flat graphite surfaces, 1px hairlines and square
  corners in place of the textured panels. One mint accent marks on, selected
  and focused states only. Headings and body text use neutral colors.
- New page header with the page title, a one-line description and the module
  switch. The window title no longer repeats the page name.
- Dashboard module rows show each module's description. Sidebar, section tabs and
  category tabs use a left accent bar or underline for the selected item.
- Settings, behavior, frame names, commands and SavedVariables are unchanged.

## 0.2.0-beta.1 — Forever beta candidate

- Renamed Forever to Play The Game Tools for the Play The Game guild. Presentation
  text and release naming only; settings, behavior, styling and commands retained.

Initial public-release candidate prepared for review; not yet published.

- Unified modular configuration, saved settings and supported preview/position tools.
- Combat Timer with configurable appearance and placement.
- Optional Auto Loot, quest and merchant automation with conservative checks.
- Current-class training catalogs for all nine Forever classes; spellbook refresh,
  training tabs, reference costs, shortcut popout and level-up window/options.
- Existing explicit preferences retained; new Class Training preference defaults on.

Known limits: training catalog/prerequisite/cost accuracy needs native evidence;
recent UI changes require native acceptance. Auto Gossip, development prototypes
and Retail gameplay modules are not included. See README and TESTING for details.
