# Play The Game Tools changelog

Global Settings now groups Appearance, account-wide Profiles, Optimizations and Class Colors. Bundled LibSharedMedia plus licensed PTG media populate the dropdowns. Standard game UI fonts inherit; module overrides stay in their own controls. Added account-wide profile selection/import/export, Auto Loot/Fast Loot, camera zoom, detected UI scale and red-error suppression. Prior page-only native feedback is retained; these additions await in-game confirmation. See docs/GLOBAL_SETTINGS.md.

## Unreleased

- Add opt-in **mode** interface theme under Global Settings → Appearance:
  neutral graphite Figma satin/soft-corner textures, licensed Lato typography,
  gray headings, cyan text-only hover and etched selection lines. Expanded,
  collapsible text categories have less-indented dot-prefixed children. Header
  search and active-profile shortcut reuse existing controls/pages. Existing themes,
  module controls and gameplay behavior are preserved. Apply with Reload OOC;
  new asset discovery may need a restart only if reload falls back. Native review
  pending. See docs/MODE_INTERFACE_THEME.md.
  Refinement: PTG logo/short title, 208-unit sidebar, padded module rows, darker
  descriptors, text-aligned right-fading underlines, rounded checkboxes/buttons,
  capsule on/off tracks with circular thumbs, thin scroll indicator and beveled
  separators. Remove header/navigation divider lines; place Profile far right
  and accent only its name. Prior appearance received positive owner feedback;
  these final native refinements still need review.
  Screenshot correction: replace 24px checkbox runtime files with 32px images;
  draw small controls without slices so their rounded silhouettes remain intact.
  Fit subcategories on one line using a wider navigation area and measured text.
  Restore Close far right with Profile next to it; make PTG Tools cyan. Native
  verification of this correction remains pending.
  Follow-up: remove mode window/page perimeter outlines, inset checked fills,
  align search with page titles, and center/size the profile text group. Center
  numeric values and round the existing-size slider thumb. Existing editing,
  navigation, module logic and other themes remain unchanged; native review pending.
  Fill-containment correction: use a solid rounded outer backing for mode toggles
  and checkboxes, with the same inset interior in both states and a distinct gray
  rim when checked. All regions share one frame; no new assets or state changes.
  Native confirmation is pending after reload.
  Owner reports improved containment; reduce mode switch/checkbox rims from two
  units to one and use charcoal #2B2B2B in both states. Native fit review pending.

- Owner accepted Global Settings and authorized PR #23's public main merge on
  2026-11-09; broader native coverage remains documented in GLOBAL_SETTINGS.md.

- Move Interface Theme from Dashboard to Global Settings → Appearance below the
  media options; remove the SharedMedia status text while keeping integration.

- Activate installed SharedMedia/MyMedia on first adoption, respecting later
  manual disables; consume its additional/custom media.
  Media dropdown labels now show names without parenthetical annotations.
- Remember shared font/texture/border registrations across reloads and discover
  cataloged assets from installed disabled providers without loading their code.
  Added a read-only local media indexer; current catalog contains 55 paths.
- Global Settings: removed the Shared Media, Loot and Errors, and Camera Distance
  descriptions; inset the Class Colors grid below its separator; discover optional
  installed Expressway fonts through LibSharedMedia without bundling their files.
- Added Guild Tools -> Roster: an opt-in page that lists every guild member under
  their class and totals each class in a Class Summary. Read-only; nothing about
  the roster is saved. Native validation is pending.

- Added a Recruiter icon to the Quick Actions ring. It appears while Recruitment
  is enabled, opens or closes the Recruiter window, and lights the main button
  while the window is open. Native validation is pending.

- Rogue Icon Gap now sets actual Main Hand/Off Hand separation. Removed individual
  image-padding controls and the Reminder's hidden cell-width spacing. Hand labels
  wrap with measured heights. Quick Access and its expanded menu start borderless;
  stock borders migrate once while custom border controls/settings remain.

- Rogue reminders support independent time and charge triggers. Charge Threshold
  ranges from 5 to 25 (default 10); either enabled threshold reveals the hand icon
  and Quick Access. Optional poison-charge text is distinct from bag counts.
  Unavailable charge data leaves timer reminders intact; native charge validation
  is pending.

- Removed the duplicate Rogue header icon. The left sidebar subcategory and
  compact top tab carry the class icon; tab On/Off sits close to the Rogue label.

- Rogue Display now exposes icon size, padding, reminder spacing and per-icon
  borders directly. Both elements have independent icon border colors/opacity,
  image opacity and optional icon backgrounds; window styling remains separate.
  Minimal keeps the reminder bare. Icon geometry/settings mocks pass; native
  visual review remains pending.

- Merged the Class Training and Dungeon Loot icons into one Quick Actions button.
  Clicking it opens the icons on a gold ring around it, and the button lights up
  while open; clicking an icon closes the ring. Only the button moves, through Edit Mode. It starts where the Class
  Training icon was; older icon positions and the Dungeon Loot lock preference
  stay in saved settings unused. The Lock Shortcut Icon control is removed.

- Refined Class Tools -> Rogue into Display, Settings and Position. Poison
  Reminder defaults to bare icons/hand text and supports per-hand right-click
  dismissal; Quick Access Poisons gains independent labels and shared Edit Mode.
  Added a Recent/poison-family availability grid, compact appearance editors and
  class-icon navigation/header. Existing customized styles/history are retained;
  new layout and dismissal native checks are pending.

- Added Class Tools -> Rogue: per-hand poison reminders and inventory-backed OOC
  item applications; Last Used Poison tracking and Poison Refresh Quick Apply
  selection; threshold-only Poisons profession icon with Always Show option;
  independent watcher/icon/menu appearance, layout, position and preview controls.
  First button candidate was owner-reported inert; revised item dispatch is
  owner-confirmed working in quick testing. Broader native coverage remains
  bounded by docs/FOREVER_ROGUE_POISONS.md.

- Edit Mode's Exit / Save button is now Exit, since positions are written as they
  change. Exit keeps a typed coordinate that was not applied yet and can no longer
  be stranded by a module error. Combat ends Edit Mode without reopening settings.
  Target, placement and Reset Offset no longer wipe offsets or custom attachment
  points, and UI anchors no longer require `issecretvalue` to exist.

- Recruiter candidates have a Whisper button that sends the whisper message
  instead of an invite; the player then stays out of scans for the re-invite
  window. The message box is multi-line and holds 500 letters; text over the
  255-character chat limit goes out as consecutive whispers. Whisper After
  Invite was removed, so confirmed invites no longer whisper.

- Dungeon Loot's Set Keybinding now replaces the selected key's current action,
  with the assigned key or Not bound in a separate read-only field beside the
  button. Failed changes restore both the overwritten action and prior shortcut.

- Reworked the Dungeon Loot launcher after the blue-square/non-moving report:
  native circular loot dice icon, explicit dimensions, Class Training-style ring,
  size/opacity controls and shared Edit Mode drag/coordinate integration. General
  now groups Quick Icon settings and provides direct Set/Clear Keybinding with
  current assignment, conflict checks and native account/character persistence.

- Added a standalone Dungeon Loot chest icon (shown while the module is enabled),
  freely draggable while unlocked, with saved position and General visibility,
  lock and reset controls. Added an unassigned Open Dungeon Loot action to native
  Key Bindings. Both open the dungeon index outside combat; the keybind remains
  available when the icon is hidden and never enables the module implicitly.

- Enhanced Experience Bar offers Use PTG Only / Use Existing Bar and independent
  Blizzard/Ellesmere XP hide toggles. Hides are opt-in, reversible and XP-only;
  provider saved settings remain untouched. Native coexistence testing pending.

- XP bar forecast priority is current XP, rested XP, then quest log XP. Quest
  tint is clipped beneath rested coverage so overlay colors no longer mix.

- Enhanced Experience Bar has independent Rested XP Overlay Color and Quest Log
  XP Overlay Color pickers, available while the main fill uses native XP colors.

- Added opt-in Enhanced Experience Bar under Questing & Leveling: flat/native
  Blizzard/SharedMedia textures, XP/rested/total-quest-log XP, full-height tinted
  overlays with independent opacity, session time/XP per hour, independent bar/
  session text controls with dash/dot separators and shared Edit Mode.
  Initial bar works per owner; revised native validation pending. See
  docs/ENHANCED_EXPERIENCE_BAR.md.

- Recruitment settings page no longer duplicates the Recruiter window: level
  range, levels per search, classes (All/None), Whisper After Invite and the
  whisper text are set only in the Recruiter window (`/ptgr`). Recruitment
  Status, Statistics, How It Works and the Invites section (Re-invite After
  (days)) were removed from the page, which now holds only Open Recruiter and
  the History resets. Saved values are unchanged (the re-invite window keeps
  its saved days, default 7); searching "whisper" or "classes" still finds
  Recruitment.

- Removed the per-letter gradient text from Dungeon Loot: dungeon card titles,
  section and bracket headings, boss/quest names, list entries and NPC
  subheaders now use solid theme colours. Tab underlines are a solid accent and
  bracket heading rules a plain hairline. Map pin rims are unchanged.

- Refreshed the Modern interface theme for contrast and focus: the sidebar is
  recessed below the canvas, popups and controls step up from it, and buttons,
  inputs, choices, checkboxes and slider tracks have edges you can find before
  hovering. Hover is a clear step brighter, selected choices show a full accent
  edge, the selected sidebar entry has a wider accent bar, ticked boxes carry
  an accent wash, sliders are thicker, and sections have more space between
  them. Text is softer off-white with brighter headings. Blizzard is unchanged.


- Added Monitor / Camp Buffs / Contributions quick jumps and an element overview near the top of Campfire Monitor. Expanded independent Contributions styling for window/border/background, row dimensions and spacing, icons, fonts, every text size/color/alignment, optional title gradient, visibility, tooltips and lock/offset controls. Preview and live kits share the same styling path.

- Fixed contribution editing after fractional drags by rounding managed coordinates and repairing affected offsets without resetting positions. Apply geometry after Show, keep the panel below the Edit Mode workspace, and snap numeric appearance edits to supported steps. Removed Crit/Int pickers; typed stats use the fixed existing palette.

- Fixed repeated Camp Contributions invalid-frame assertions: finish and show the panel before registering its position, retry unavailable geometry once on the next frame, then suppress event-driven retries and expose manual recovery if layout stays unavailable. Shared position safety checks and native item actions are unchanged.

- Removed the addon Camp Buffs countdown and timer controls; native tooltip duration remains. Grouped customizations by General, Campfire Icon, Camp Buffs and Camp Contributions. Fixed missing contribution rendering by anchoring before position registration; added contribution scale/opacity/background/reset controls and reduced status refresh to a secondary tool.

- Camp Buffs now drops native intro and parenthesized duration footer text. Added plain text color-wheel controls with optional header/timer gradients, compact toggle grids, concise help, detected kits, an inert Contributions preview and shared Edit Mode placement. Native visual acceptance pending.

- Removed duplicate duration-only footer text beneath Camp Buffs; the countdown stays in its subheading. Added a movable Camp Contributions popup for ready carried profession kits at a nearby fire, native click-to-place actions, per-visit dismissal and reopen/refresh controls. Native item placement/screenshots pending.

- Campfire elements now use shared Edit Mode handles, coordinates and saved positions. Added an orange/red Camp Buffs heading, native countdown with white-to-green/yellow/red urgency gradients, distinct stat colors and spell-ID filtering. Centered the camp icon above its status; no unsupported yards/navigation are fabricated.

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
