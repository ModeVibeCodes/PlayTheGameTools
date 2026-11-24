# Play The Game Tools changelog

## Unreleased

- v2 styles displays only in **Layout**. Each display's old font, color and
  size settings (Combat Timer, Profession & Food Bars, Experience Bar, Rogue
  Tools reminder and Quick Access, Campfire icon, Camp Buffs and Camp
  Contributions) are reset to their defaults once per profile, and those
  hidden settings are gone from the pages. Positions, Layout Style card values,
  module switches and show/hide options are kept. If anything was reset, one
  chat line and a banner in the settings window say so; **Dismiss** hides the
  banner for that profile. New or unchanged profiles show nothing.
- Switches that only turned information on or off came back as plain rows:
  Experience Bar **Show XP percent**, **Show XP amounts**, **Show rested XP**,
  **Show quest log XP**, **Rested overlay**, **Quest log overlay**, **Show
  session progress** and **Show XP per hour**; **Show Profession Names** and
  **Show Food Names**; and Rogue Tools' new **Poison Reminder** and **Quick
  Poisons** groups with **Show reminder**, **When**, **Show quick poisons**,
  **Menu opens** and the icon, label, name, time, count and tooltip switches.
- Searching "rogue" no longer lists empty "Rogue Tools > Display >" results,
  and the Guild page's **Open Guild** result now outlines the page header's
  **Open Guild** button.
- Gameplay Enhancements is now two modules with their own switches: Campfire
  Monitor and Loot Sparkles. Each starts on only if Gameplay Enhancements and
  its own Enable switch were both on. The Enable Loot Sparkles and Enable
  Campfire Monitor switches are gone; the page switch is the switch. Campfire
  settings, positions and styles carry over, and searching "gameplay
  enhancements", "campfire" or "camp contributions" finds the right page.
- Map Labels' services and Loot Sparkles' "Sparkle On" targets are now a row of
  chips you click on and off. The Map Labels page shows one source line with a
  **Full notice in About** button; the full notice is unchanged in Settings →
  About.
- Guild Roster and Guild Recruitment are now one module, **Guild**: one
  sidebar entry and one switch. **Open Guild** in the page header (or the Guild
  icon in Quick Actions) opens one Guild window with **Roster** and **Recruit**
  tabs. Roster holds Class Summary, Members by Class with its search and
  filters, and the breakdowns in one scrolling column. Recruit keeps Level
  range, Levels per search, the class picks and the whisper box beside the
  results they change; the three clear/reset buttons are now one **History**
  menu there. `/ptgr` opens the window on Recruit. Guild is on after the
  update if either old module was on, and your recruit history, statistics,
  whisper text and level/class picks are kept. Searching "roster" or
  "recruitment" finds Guild.
- Dungeon Loot and Class Training browsers have their own windows. The page
  header's **Open Dungeon Loot** and **Open Class Training** buttons (usable while
  the module is on) open them; the Quick Actions Dungeon Loot icon and its
  keybinding open the Dungeon Loot window too, and the level-up popup's
  Training button opens Class Training on Available & Known. Each window moves
  freely, remembers its place for the session, closes with Escape, follows the
  Interface Theme and can be opened in combat; **Settings** returns to the
  module's page. The settings pages keep only settings: Dungeon Loot's former
  General tab (Quick Icon, Keybinding, Dungeon Data) is its page, and Class
  Training's ability lists left its page. No saved settings change.

- Layout replaces Preview and Edit Mode. Every enabled display shows its sample
  data with its name, and can be dragged. The bar along the top reads Layout,
  "Click a display to style it", Drag to move, a Grid switch and Done. Grid
  (off by default, this session only) draws guide lines and snaps a display
  dropped on the screen to them. Clicking a display opens its Style card:
  Scale, Opacity, Text size and Background, the same for every display, a
  folded Position section (Anchor To, Attach, X/Y Offset), Reset (this
  display's style and default position) and Settings (its module page).
  Styles are saved with each display's position. Older per-display font, color
  and border settings are kept, but are no longer shown in Layout.
- Renamed four modules to the names people use: Points of Interest Labels is
  now Map Labels, Enhanced Experience Bar is now Experience Bar, Quick Access
  Bars is now Profession & Food Bars (so it isn't confused with the Quick
  Actions ring) and Rogue is now Rogue Tools. Only the names changed: your
  saved settings, keybindings and positions carry over. Searching settings for
  an old name still finds the module.
- Quick Actions ring: the "show in Quick Actions" switches are gone (Class
  Training's Shortcut Icon & Menu checkbox and Dungeon Loot's Show Shortcut Icon
  row). While a module is on, its icon is in the ring; turning the module off
  takes it out. Icon size, opacity and the popout options stay. Old saved
  switch values are left in your profile but no longer read.
- Combat Timer: the Timer format choice is gone. The timer always reads plain
  MM:SS (for example 00:42); a saved [MM:SS] or (MM:SS) choice is ignored.
- Experience Bar: the bar always hides at maximum level, so the Hide at
  Maximum Level switch is gone. Hide Ellesmere XP Bar appears only while
  EllesmereUIActionBars is loaded, and the Detected XP Bars status row is gone.
- Automation: the Dialogue group is gone. Its Auto Gossip switch could never be
  turned on, and its explanation is removed with it. Gossip dialogue stays
  manual, as before.
- Status text no longer repeats a switch. Loot Sparkles Status, Rogue Tools'
  status line, Campfire Status and the Food Bar status now show only when they
  have something to say (a conflict, a rejected setting, a poison message,
  nearby-campfire state, your carried food), and Class Training's summary no
  longer reads "Disabled". Food Bar's Enable Food Bar and Show Food Bar are now
  one Show Food Bar switch; the bar's own Hide button turns it off. Enable Loot
  Sparkles stays: the page switch also covers Campfire Monitor.
- Removed three manual refresh buttons whose data already updates on its own:
  Class Training's Spellbook Refresh (it re-reads when your spellbook changes,
  you train, level up or open the page), Profession & Food Bars' Update Learned
  List (professions re-read when your skills change) and Refresh Bags (food
  re-reads when your bags change). Each waits until combat ends, as before.
- Removed Global UI Scale from Global Settings → Optimizations. The addon no
  longer changes or resets the game's UI scale; Blizzard's own UI Scale option
  in the game's Graphics settings is in charge again.
- Global Font now changes only Play The Game Tools' own windows and displays.
  It no longer changes the font of the game's unit frames, chat, tooltips,
  quest text or other addons. A `/reload` restores the game's original fonts.
- Threat Meter: your row's marker now sits in its own gap left of your bar, so
  it no longer blends into your class color. When you are close to pulling
  aggro the marker turns red (it was amber, which matched the Blizzard theme's
  gold marker) and a thin red frame surrounds your bar.
- Windows and pop-ups no longer stack: opening Settings, Edit Mode, the
  Recruiter or the Class Training flyout closes whichever of those is open.
  Companions stay with their window (Settings' pop-out preview and popup
  preview, the Recruiter's copy box). Escape now closes the addon's newest open
  window, dialog or dropdown first, one per press, before the game menu opens.
  The level-up popup and the reload prompt still appear on their own without
  closing anything.
- Added Points of Interest Labels (Quality of Life, off by default): icons with optional names
  on the world map for class and profession trainers, weapon masters, banks,
  auction houses, inns, flight masters, guild masters and transmogrifiers, plus
  opt-in stable masters, mailboxes, repair and other vendors. Class Trainers and
  Profession Trainers each choose Mine (your class / your learned professions,
  detected automatically), All or Off; Mine is the default. Other Faction, Show
  Names, Icon Size and Name Size options. Hover an icon for the NPCs there.
  Locations are Data from Efficient Games (https://efficient.games), CC BY 4.0,
  with Classic spawn positions from CMaNGOS classic-db (GPL-3.0) where Efficient
  Games has none yet (marked in the tooltip); see THIRD_PARTY_NOTICES.md.
- Credits now read Mode and Prox.
- Display styling moved into Edit Mode. Selecting a display (click it, or pick
  it under Element) now shows its Text and Appearance settings in a styling
  column on the right of the Edit Mode panel: Combat Timer, Profession Bar, Food
  Bar, XP Bar (XP Bar / Session Text tabs), Rogue Poison Reminder and Quick
  Poisons (Quick Icon / Expanded Menu tabs), and the Campfire Icon, Camp Buffs
  and Contributions windows. These are the same controls and saved settings as
  before; settings pages now show only Options for these displays, and settings
  search no longer lists them. Rogue's Customize buttons open the display in
  Edit Mode. Loot Sparkles, Class Training and Dungeon Loot have no Edit Mode
  display, so their appearance settings stay on their pages. Hide at Maximum
  Level (XP Bar) is behavior and stays in settings.
- Declutter and unify the interface. Edit Mode is now the only place to move
  displays: one standard panel (Element, Anchor To, Attach, X/Y Offset, Reset
  Position, Settings, Exit) works for every display. Quick Access, Food Bar and
  Threat Meter now use the same Position Manager as the rest (their saved x/y
  seed the managed position once and keep mirroring screen offsets). Settings
  pages no longer have Position/Lock/offset rows, Campfire's separate Move
  Windows mode is gone, and saved Lock flags are kept but no longer read:
  displays move only in Edit Mode. The header Edit Mode button starts on the
  current page's display.
- One layout for every theme: Modern, Blizzard and mode share the sidebar,
  header (search, Profile, Edit Mode), pill/sub-tab pages and selection
  underline; themes differ only in colors, borders and textures.
- Removed redundant text and settings: long footer notes (How It Works,
  Visibility Help, Food Selection, Forecasts, Session Scope, Other Addon Suites,
  Campfire TLDRs, Rogue notes), generic panel sentences, Global Settings status
  rows, duplicate Enabled/Disabled text on the Dashboard, the XP Bar's in-page
  enable switch and Use PTG/Existing buttons (a saved "existing" choice becomes a
  disabled module, which looks the same). Automation warnings show only while an
  action is actually blocked.
- Performance: settings changes refresh only the visible page; Threat Meter
  polls only while it shows a target, from a separate driver frame; the XP
  session clock ticks only while session text is shown.
- Native in-game confirmation is pending; test with `/reload` out of combat.

- Guild Tools -> Roster now has Members and Analytics tabs. Members adds a search
  box (name, class, race, zone, rank, notes, or a level such as 60 or 40-59),
  Class and Status filters, levels beside names, an online marker and a hover
  tooltip with rank, zone or last online, and notes. Analytics keeps the Class
  Summary and adds Online Now plus bar breakdowns by level, rank, race, last
  online and zone. Still read-only and session-only; native validation is pending.

- Added Guild Tools -> Roster: an opt-in page that lists every guild member under
  their class and totals each class in a Class Summary. Read-only; nothing about
  the roster is saved. Native validation is pending.

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

- Finished renaming from ModeTools: the addon folder, TOC, settings variable
  (`PTGToolsDB`) and frame names now use Play The Game Tools names. Open
  configuration with `/ptg`; `/modetools` and `/mode` were removed. Settings are
  adopted automatically once SavedVariables/ModeTools.lua is renamed to
  PlayTheGameTools.lua.
- Added a Threat Meter module (Quality of Life, off by default): a plain list of
  threat on your current hostile target for you and your party or raid, tanking
  first, then highest percentage. Optional Show Pets (off by default), Hide Out
  of Combat while locked, Lock Threat Meter and Reset Position.
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
