# Feature registry

Mode module layouts: Campfire's flow is owner-accepted and now applied across
module settings in Mode only. Every setting and callback is retained, with
feature-specific catalogs/browsers intact. Modern/Blizzard retain their layouts;
the owner accepted the final layout and authorized PR #26's merge, retaining
Mode-only scope. Gameplay validation is unchanged. [Coverage and checks](MODE_MODULE_LAYOUTS.md).

Mode explanatory blocks use full-width page footers. Category subheadings,
short summaries and minor labels retain their approved positions. Live status
and active rejection warnings remain inline. All settings remain, with natural
scrolling/search and existing-theme layout isolation.

Settings (v2, formerly Global Settings): one scroll of Appearance (Theme, Class colors) / Game (Fast loot, Hide red error text, Camera distance) / Profile (Active profile, Manage) / About. No Global Font, Global Texture or Global Border pickers: displays use the built-in defaults and are styled in Layout. Earlier pages were user-reviewed; the v2 page is static/mock validated, native review pending. See [Settings](GLOBAL_SETTINGS.md).

| Feature | Configuration | Scope | Native status |
| --- | --- | --- | --- |
| mode interface theme | Settings → Appearance → Theme → mode | Opt-in graphite/cyan materials, rounded controls with contained fills, Lato, fading selection, cyan PTG branding, one-line navigation, borderless pages, title-aligned search, centered numeric values and fitted Profile beside rightmost Close; existing themes/module behavior retained | PR #24 baseline owner-accepted and merged; November 10 darker-page/Figma-detail prototype awaits native review; gameplay validation unchanged; [checklist](MODE_INTERFACE_THEME.md) |
| Settings | Sidebar → Settings → Appearance / Game / Profile / About | Theme cards, nine-class color grid, Fast loot, red-error and camera distance controls, account-wide profiles; no global font/texture/border pickers (displays use built-in defaults, styled in Layout) | Earlier page owner-reviewed; expanded native behavior pending; [checklist](GLOBAL_SETTINGS.md) |
| Guild (Roster tab) | Sidebar Guild -> Open Guild -> Roster (module `foreverRecruitment`, merged with Recruitment) | Opt-in, read-only: every guild member listed by class from native `C_Club` data; search by name/class/race/zone/rank/notes/level with Class and Status filters and member tooltips; Class Summary, Online Now and level/rank/race/last-online/zone breakdowns; session-only, no saved roster or search | Static fixtures only; native validation pending |
| Rogue Poisons | Sidebar Rogue Tools -> Poison Reminder / Quick Poisons / Settings (styling in Layout) | Poison Reminder: independent time/5–25 charge thresholds, minimal defaults, right-click dismissal, Recent/family grid, true Main Hand/Off Hand Icon Gap and custom borders; customizable Quick Access Poisons with session-only right-click dismissal/restore; shared Edit Mode/coordinates and class branding | Prior application version quick-tested by owner; current layout/dismissal/Edit Mode native review pending; [details](FOREVER_ROGUE_POISONS.md) |
| Experience Bar | Questing & Leveling -> Experience Bar | Opt-in XP/rested/full-log XP, priority tints, texture choices, independent text, shared Edit Mode and native/Ellesmere provider choice | Owner accepted current feature and authorized PR #13 merge; broader native coverage remains bounded; [details](ENHANCED_EXPERIENCE_BAR.md) |
| Campfire Monitor | Questing & Leveling -> Gameplay Enhancements -> Campfire Monitor | Independent opt-in under parent master; native proximity, colored joined/detached Camp Buffs with native tooltip duration only, centered status icon, guide and shared Edit Mode | Prior UI owner-accepted; PR #26 Campfire flow owner-accepted; Mode-only module rollout awaits broader native review; all settings retained; [details](CAMPFIRE_MONITOR.md) |
| Camp Contributions | Questing & Leveling -> Gameplay Enhancements -> Campfire Monitor -> Camp Contributions | Ready carried profession kits at a native fire; movable popup with full independent appearance controls, inert preview/shared Edit Mode, quick jumps and detected kits, user-click native OOC placement, dismiss/reopen | Detection/window generation confirmed; latest UI accepted; native item dispatch/placement remains pending; [details](CAMP_CONTRIBUTIONS.md) |
| Loot Sparkles | Questing & Leveling -> Gameplay Enhancements -> Loot Sparkles | Default-off native quest effect plus one-target herb/ore/quest/corpse glints and names; appearance controls; owned CVar restoration | Static fixtures only; native validation and screenshots pending; [details](LOOT_SPARKLES.md) |
| Dungeon Loot | Questing & Leveling → Dungeon Loot | All recorded Forever dungeon/wing cards, boss/quest details, customizable Quick Icon/shared Edit Mode/direct keybinding editor, automatic faction/class filtering and quest-log/completion card status, deduplicated chain tasks and bracket jumps, native map/copy controls; bundled GPLv3 catalog; no DungeonJournal dependency | SFK, PR #8 player-progress/completion/layout and PR #14 Quick Icon/keybinding revisions accepted in-game by owner; screenshots pending |
| Map Labels | Quality of Life -> Map Labels | Opt-in world map icons/names: class and profession trainers each Mine (auto-detected class/professions)/All/Off, banks, auction houses, inns, flight masters, guild/transmog, optional stable masters, mailboxes and vendors; faction filter, sizes; Efficient Games data (CC BY 4.0) plus CMaNGOS classic-db positions (GPL-3.0) for gaps | Mock-tested; native confirmation pending; [details](CITY_LABELS.md) |

Cooldown Profits: Sidebar Cooldown Profits → Open Cooldown Profits (module `cooldownProfits`). Opt-in ranking of transmutes, Mooncloth and the Salt Shaker by gold per day from Auctionator's API (optional), with learned plan, Worth learning, ready times and an optional ready chat line; per-character timers outside profiles. Mock-tested; native confirmation pending; [details](COOLDOWN_PROFITS.md).

See [Dungeon Loot](DUNGEON_LOOT.md) for source provenance, dependencies, API
assumptions, limitations and exact manual checks. Existing modules are documented
in the README and their owning source/config files; this registry begins with the
Dungeon Loot pilot and does not replace their documentation.
