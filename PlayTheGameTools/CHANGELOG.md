# Play The Game Tools changelog

## Unreleased

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
