# Feature registry

Reskins → Character Panel: opt-in Forever pilot using the accepted Mode palette,
native equipment controls, guarded enchant/imbue text and configurable quick
stats. Damage Meters and Chat Window are planned navigation only, with no enable
switch or runtime behavior. [Implementation and exact checks](CHARACTER_RESKIN.md).
Screenshot refinement adds the navigation-gray material, dedicated tab spacing,
helm-relative stat rows, rarity/ammo edges and reversible Mode control/portrait/
name styling. Unreadable effects and irrelevant generic controls are hidden.
Latest refinement: quiet unified framing, circular portrait crop, Mode scrollbar,
independent Quick Stats pill with per-stat choices, and toggleable gold/equipped
durability footer rows. Native refinement validation remains pending.
Reload correction assigns fonts before title/footer text, covers enabled-module
startup with an already-open sheet, fades the native divider early and aligns
the name to the level/class model-pane center. Current saved profiles validate
read-only; the separate Campfire report remains unreplicated.
Owner confirmed no-error rendering of that correction. Final requested polish
adds native rarity halos, split stat colors, fitted/working border thickness,
effective modifier cell width, cyan enchants and helm-aligned portrait defaults;
Positioning groups all placements and hides disabled features' controls.

Mode module layouts: Campfire's flow is owner-accepted and now applied across
module settings in Mode only. Every setting and callback is retained, with
feature-specific catalogs/browsers intact. Modern/Blizzard retain their layouts;
the owner accepted the final layout and authorized PR #26's merge, retaining
Mode-only scope. Gameplay validation is unchanged. [Coverage and checks](MODE_MODULE_LAYOUTS.md).

Mode explanatory blocks use full-width page footers. Category subheadings,
short summaries and minor labels retain their approved positions. Live status
and active rejection warnings remain inline. All settings remain, with natural
scrolling/search and existing-theme layout isolation.

Global Settings: Appearance / Profiles / Optimizations / Class Colors, with bundled LSM media, standard game fonts, account-wide profiles, fast loot, scale/zoom and red-error controls. Previous page was user-reviewed; additions are static/mock validated, native review pending. See [Global Settings](GLOBAL_SETTINGS.md).

| Feature | Configuration | Scope | Native status |
| --- | --- | --- | --- |
| mode interface theme | Global Settings → Appearance → Interface Theme → mode | Opt-in graphite/cyan materials, rounded controls with contained fills, Lato, fading selection, cyan PTG branding, one-line navigation, borderless pages, title-aligned search, centered numeric values and fitted Profile beside rightmost Close; existing themes/module behavior retained | PR #24 baseline owner-accepted and merged; November 10 darker-page/Figma-detail prototype awaits native review; gameplay validation unchanged; [checklist](MODE_INTERFACE_THEME.md) |
| Global Settings | Sidebar → Global Settings → Appearance / Profiles / Optimizations / Class Colors | Bundled LSM/media, standard game fonts, display-only global textures independent of configuration themes, module-local customization, account-wide profiles, Auto Loot/Fast Loot, camera/scale/error controls and nine-class color grid | Earlier page owner-reviewed; expanded native behavior pending; [checklist](GLOBAL_SETTINGS.md) |
| Guild Roster | Guild Tools -> Roster | Opt-in, read-only: every guild member listed by class from native `C_Club` data, Class Summary totals, session-only with no saved roster | Static fixtures only; native validation pending |
| Rogue Poisons | Class Tools -> Rogue -> Display / Settings / Position | Poison Reminder: independent time/5–25 charge thresholds, minimal defaults, right-click dismissal, Recent/family grid, true Main Hand/Off Hand Icon Gap and custom borders; customizable Quick Access Poisons with session-only right-click dismissal/restore; shared Edit Mode/coordinates and class branding | Prior application version quick-tested by owner; current layout/dismissal/Edit Mode native review pending; [details](FOREVER_ROGUE_POISONS.md) |
| Enhanced Experience Bar | Questing & Leveling -> Enhanced Experience Bar | Opt-in XP/rested/full-log XP, priority tints, texture choices, independent text, shared Edit Mode and native/Ellesmere provider choice | Owner accepted current feature and authorized PR #13 merge; broader native coverage remains bounded; [details](ENHANCED_EXPERIENCE_BAR.md) |
| Campfire Monitor | Questing & Leveling -> Gameplay Enhancements -> Campfire Monitor | Independent opt-in under parent master; native proximity, colored joined/detached Camp Buffs with native tooltip duration only, centered status icon, guide and shared Edit Mode | Prior UI owner-accepted; PR #26 Campfire flow owner-accepted; Mode-only module rollout awaits broader native review; all settings retained; [details](CAMPFIRE_MONITOR.md) |
| Camp Contributions | Questing & Leveling -> Gameplay Enhancements -> Campfire Monitor -> Camp Contributions | Ready carried profession kits at a native fire; movable popup with full independent appearance controls, inert preview/shared Edit Mode, quick jumps and detected kits, user-click native OOC placement, dismiss/reopen | Detection/window generation confirmed; latest UI accepted; native item dispatch/placement remains pending; [details](CAMP_CONTRIBUTIONS.md) |
| Loot Sparkles | Questing & Leveling -> Gameplay Enhancements -> Loot Sparkles | Default-off native quest effect plus one-target herb/ore/quest/corpse glints and names; appearance controls; owned CVar restoration | Static fixtures only; native validation and screenshots pending; [details](LOOT_SPARKLES.md) |
| Dungeon Loot | Questing & Leveling → Dungeon Loot | All recorded Forever dungeon/wing cards, boss/quest details, customizable Quick Icon/shared Edit Mode/direct keybinding editor, automatic faction/class filtering and quest-log/completion card status, deduplicated chain tasks and bracket jumps, native map/copy controls; bundled GPLv3 catalog; no DungeonJournal dependency | SFK, PR #8 player-progress/completion/layout and PR #14 Quick Icon/keybinding revisions accepted in-game by owner; screenshots pending |

See [Dungeon Loot](DUNGEON_LOOT.md) for source provenance, dependencies, API
assumptions, limitations and exact manual checks. Existing modules are documented
in the README and their owning source/config files; this registry begins with the
Dungeon Loot pilot and does not replace their documentation.
