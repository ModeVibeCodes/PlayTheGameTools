# Standalone Forever development

v2 window shell (branch `t3/v2-window-shell`): `Config/Window.lua` is now
960×640 (was 1120×760) with the same fit-to-screen scaling and off-screen
recovery; the sidebar is 212 wide and the header 48 tall. The header holds the
brand and only **Layout** (calls `addon:SetEditMode`, starting on the current
module's first display, exactly as the old Edit Mode button did) and **X**;
`window.editButton` names the same control. The Preview, Reload, Edit Mode and
Profile header buttons are gone; profiles stay on the Settings page. A pending
`ReloadManager` request shows as a banner above the page (`window.reloadBanner`,
**Reload now** = `ReloadManager:Reload()`); `ReloadManager:Refresh` drives it.
The sidebar is the search box, one flat A–Z list of module pages
(`addon:ListedConfigPages()`, each row with an on/off dot) and **Settings**
pinned at the bottom (the `globalSettings` page, titled "Settings"). No
Dashboard, no category headings: categories stay registered as module data
(`Core/Categories.lua`) but nothing shows them. A module with a stock
`classIcon` (`ClassIcon_<Class>`) is listed and searchable only for that class
(`addon:IsConfigPageListed`). Developer Mode is not listed; `/ptg dev` opens it
(`addon:OpenDeveloperPage`). The window opens on the last page used this
session (not saved), or the first module. The page header is the title,
description (wraps to two lines; header 76 tall) and the one switch, with no
Enabled/Disabled text. Search
(`Config/Search.lua`) sits at the top of the sidebar; its results replace the
list while it holds text and include the Settings page; choosing one opens the
page and flashes the row. No new TOC files, SavedVariables or frame names.
`tests/window_shell.py` guards the shell. Native confirmation is pending;
`/reload` OOC.

One scroll per module (branch `t3/v2w2-pages`, v2 wave 2): every module page
is one vertical scroll: the page header, then each section as a titled group, top
to bottom. Gone: ModeLayout's feature pills, Options/Text/Appearance panel tabs,
panel headers and the left checkbox gutter; `W.SectionTabs` and the section strip;
the Campfire element pills/panels/summary column (`campfirePilot`,
`SelectCampfirePanel`); module-page Collapse buttons (only `Section(..., true)`
folds, used by Developer Mode); the `underline` button style. `page:Layout`
(Config/Pages.lua) hides a section or `Group` heading while nothing under it
shows, so a section holding only Layout styling (Combat Timer's Display) has no
heading. `page:ShowSection(section|index|title)` replaces `SelectSectionTab`: it
scrolls to the heading (section 1 = top) and sets `selectedSection`; the window
calls `ShowSection(1)` on open. `page:Reveal(entry)` (search) scrolls to the row
and flashes it; search skips a section hit whose rows are all Layout styling.
`W.ApplyModeModuleLayout` keeps only the routes that tag `row.editAppearance`
(still hidden; headings are never tagged), compact rows and color pairing.
Class Training listed upcoming abilities under Upcoming Abilities and the rest
under Available & Known (since the browsers merge those lists are in the Class
Training window); Level Up Window rows show while that window is on and
Shortcut Icon & Menu while the module is on (the old tab gating). Guild Roster
and Loot Sparkles drop their tab strips; Campfire preview now stops when the
page hides, not on a section change (since the split, when leaving the Campfire
Monitor page). Kept: the Dungeon Loot browser's own pills (`W.LayoutModePills`
in Config/SectionTabs.lua); since the browsers merge its Options/Appearance/Data
sub-tabs and `W.SetupModeBrowser` are gone (General became its settings page). No TOC, SavedVariables or frame-name changes;
`tests/mode_module_layouts.py` and `tests/campfire_mode_layout.py` guard it.
Native confirmation is pending; `/reload` OOC.

Guild (branch `t3/v2w2-guild`, v2 wave 2, 2026-11-24): Guild Roster and
Guild Recruitment merged into one module. **ID choice:** the Guild module keeps
`foreverRecruitment` (title "Guild"), because that saved table holds everything
worth keeping: `history` (invite times and never-invite list), `records`
(statistics), `message`, `minLevel`/`maxLevel`/`chunkSize`, `classes` and
`reinviteDays`. The roster stored only `enabled`, so `foreverGuildRoster` is
retired as a module (`Modules/ForeverGuildRoster.lua` is now
`addon.ForeverGuildRoster`, driven by Guild's `OnInitialize`/`SetActive`). Its
table is never written or removed. Adoption is one-time and non-destructive:
`M:AdoptRoster` runs in `OnInitialize` (before the saved switch is applied) and,
unless `db.rosterAdopted` is set, turns Guild on when the old Roster table had
`enabled=true`, then sets `rosterAdopted=true` in the Guild table; so Guild is
on if either old module was on, and turning it off later sticks. Profiles
adopt when they are next loaded. `addon.retiredModules.foreverGuildRoster`
lets `ProfileManager:PrepareImport` accept old exported profiles that carry the
retired ID (one-line change; unknown IDs are still refused); exports carry only
registered modules. `addon.ForeverGuild` aliases `addon.ForeverRecruitment`.
Window: `Config/ForeverGuild.lua` (one new TOC entry, 124 Lua chunks) builds
the Guild window (old frame name `PlayTheGameToolsRecruitmentFrame`, Dialogs
group `recruiter`, 536×712) with the module switch, **Roster**/**Recruit** tabs
(`M:SelectTab`, session-only `M.tab`, default Roster; `/ptgr` opens Recruit) and
the settings page: a note; **Open Guild** is the shared page-header button
(`openLabel="Open Guild"` on the module, `header.openButton` in
`Config/Window.lua`, the same path as Open Dungeon Loot and Open Class
Training): left of the switch, disabled (dimmed) while off, calling
`M:OpenWindow()`. The page carries an "Open Guild" search entry whose keywords are the old
names so they rank Guild first. `Config/ForeverRecruitment.lua` builds the
Recruit tab (`M:BuildRecruitTab`) with one **History** menu (`W.Popup`) for
`M.HISTORY_ACTIONS`; `Config/ForeverGuildRoster.lua` builds the Roster tab
(`Roster:BuildView`) as one stacked, scrolling column instead of a settings page
with pills. The roster reads members and registers events only while the
Roster tab is visible (`Roster:SetViewShown`, from the window's OnShow/OnHide
and tab changes). Quick Actions keeps the `recruitment` action key, titled
"Guild", shown whenever the module is on. Mode: `foreverRecruitment` has an
empty plan (no route: the page is only compacted; it has no sections); the Roster plan is gone. Recruit guards are unchanged: `Ready()`
(switch and `InCombatLockdown`), Who only from clicks with the 5 s cooldown, the
copy box instead of an invite API, `CanGuildInvite`, `ADDON_ACTION_BLOCKED`
reporting. No new game APIs. `tests/guild.py` and `tests/guild_roster.py` cover
it. Native confirmation is pending; new TOC file: restart the client once.

Layout (branch `t3/v2-layout-mode`, v2 redesign): one on-screen mode replaces
Preview and Edit Mode. `addon:SetEditMode(true/false)` is still the way in and
out and `addon.editMode` its only flag; `addon:SetPreviewMode`/`previewMode` are
gone (modules' own `SetPreviewMode(bool)` is now driven by Layout, so displays
show sample data). `Config/EditMode.lua` builds the bar
(`PlayTheGameToolsEditWindow`: Layout, cue, Drag to move, Grid, Done) and the
Style card; nothing is selected on entry, and a selection is the open card.
`addon:EditElementAppearance(id)` opens Layout with one card open. Styles live
in each display's position record as `style = {scale, opacity, text,
background}` (whole percents 50-200 / 10-100 / 50-200, boolean); defaults leave
no record, so profiles, export and import carry styles with positions.
Display API (Core/PositionManager.lua): Scale/Opacity are generic (the manager
multiplies the frame's own SetScale/SetAlpha; GetScale/GetAlpha return the
display's own value; restored on unregister). Displays implement Text size and
Background with `onStyleChanged(element, style)` (re-render) and read values via
`PM:StyleView(id, settings, {text=, background=, scale=, opacity=})`,
`PM:StyleFontSize(id, size)` or `PM:StyleBackground(id)`; `styleText=false`
marks a display without text. Styles never apply in combat (deferred to
PLAYER_REGEN_ENABLED). Grid is session-only (`EditMode.grid`), off by default,
snaps screen-centred drops to 32 units. No TOC or new files besides
`tests/layout_style.py`; `tests/edit_mode.py` covers the mode. Native
confirmation is pending; `/reload` OOC.
v2 Gameplay Enhancements split (branch `t3/v2w2-split`, 2026-11-24, wave 2):
the old `lootSparkles` module ("Gameplay Enhancements") is now two modules and
two sidebar entries, each with its own switch. Decision, for compatibility:
- **Loot Sparkles** keeps the ID `lootSparkles`, its saved table and its CVar
  ownership record (`lootSparkleCVars`); turning it off still restores the
  client settings it changed (unchanged `Configure`/`Restore` path).
- **Campfire Monitor** is the new module `campfireMonitor`
  (`Modules/CampfireMonitor.lua`, `addon.CampfireMonitor.module`). Its own saved
  table holds only `enabled` and `adoptedSplit`. Every Campfire and Camp
  Contributions setting is read in place from `modules.lootSparkles.campfire`;
  nothing is moved or erased, and `LootSparkles.Initialize` still validates it.
- First switch states: `LootSparkles.AdoptSplit` (run by profile validation, so
  also on imports and inactive profiles) records the old master once as
  `lootSparkles.splitMasterEnabled` and sets `lootSparkles.enabled` = old master
  AND `sparklesEnabled`. `campfireMonitor:OnInitialize` sets its switch once to
  `splitMasterEnabled` AND `campfire.enabled`, then marks `adoptedSplit`. Later
  choices are never re-adopted. Missing old inner flags count as their old
  defaults (sparkles on, campfire off).
- The inner "Enable Loot Sparkles" (`sparklesEnabled`) and "Enable Campfire
  Monitor" (`campfire.enabled`) switches are gone; both values stay saved, unread
  and out of the defaults.
- Display element IDs `campfireMonitor`, `campfireBuffs`, `campfireContributions`
  are unchanged, so saved positions and Style card styles apply; they now name
  `campfireMonitor` as their module. Their media scope stays `lootSparkles`.
- Search aliases: both modules answer "gameplay enhancements"; Campfire Monitor
  also "campfire", "camp contributions", "camp buffs".
- Campfire Monitor's page is one scroll (merged with the one-scroll pages
  branch in `t3/v2-wave2`): no pills or panel tabs, and no section either; its
  General / Campfire Icon / Camp Buffs / Camp Contributions groups are the
  headings, routed by its own `C:ApplyModeConfigLayout`. Loot Sparkles is one
  scroll of Sparkle On / Options / Appearance / Availability groups.
  `Config/ModePlans.lua` routes Loot Sparkles as one feature (`sparkles`) and
  points the Campfire `EditAppearance` entries at page `campfireMonitor`.
Chips (`Config/Chips.lua`, new TOC entry after `Config/Widgets.lua`, 124 Lua
chunks): `W.Chips(page, items)` is one wrapping row of toggle chips, one per
saved boolean key, each its own search entry. Used for Loot Sparkles "Sparkle
On" (questSparkles, ore, herbs, questObjects, corpses) and Map Labels
"Services" (the ten service keys plus otherFaction); Map Labels' Show Names
moved to its Appearance group. The Map Labels page shows one source line
(`CityLabels.SOURCE_LINE`) and **Full notice in About**, which opens Settings
and flashes the About "Data sources" row (`CityLabels:ShowDataSources`). The
full notice stays word for word in Settings → About and in the notice files.
`tests/gameplay_split.py` covers adoption; the campfire, Map Labels and
Settings suites cover the pages. Native confirmation pending; new TOC file:
restart the client once.

Browser windows (branch `t3/v2w2-browsers`, v2 wave 2): `Config/BrowserWindow.lua`
(new TOC entry after `Config\EditMode.lua`, 124 Lua chunks) provides
`W.BrowserWindow(spec)`: an unprotected, movable, clamped DIALOG frame drawn
with `W.Texture(f,"Window")` (theme surface, as the Recruiter), Close and
Settings buttons, a `body`, session-only centre positions
(`addon.BrowserWindowPositions`, never saved) and its own Dialogs group (the
module id), so Escape closes it and opening it closes Settings. The page header
(`Config/Window.lua` `PageHeader`) shows `module.openLabel` as a button that
calls `module:OpenWindow()` while the module is on (`header.openButton`).
Dungeon Loot: `M:CreateBrowser(parent)` is the old in-page browser minus its
General tab, parented to `PlayTheGameToolsDungeonLootWindow`; `M.page` still
names it and `M:BrowserShown()` gates item/quest events. `M:CreateConfigPage`
is now a plain `W.Page` (Quick Icon, Keybinding, Dungeon Data; `M.settingsPage`)
and owns binding capture. `OpenDungeonLoot` (ring, binding, header) opens the
window, in combat too; with the module off it still opens the settings page OOC.
The map hand-off hides/restores the window. `W.SetupModeBrowser` was removed from
`Config/ModeLayout.lua` (its only caller is gone). Class Training:
`M:CreateTrainingBrowser` holds the moved row pool and summary under two local
tabs in `PlayTheGameToolsClassTrainingWindow`; `M:OpenTrainingWindow(tab)`;
the settings page refresher is `page:RenderSettings()`. Merged into
`t3/v2-wave2` with the one-scroll pages: the Class Training settings page has
no tab strip; Level Up Window rows show while that window is on and Shortcut
Icon & Menu rows while the module is on, and `OpenTraining(section)` scrolls to
sections 1–3 with `page:ShowSection`. The browser window keeps its own two
pills, as the Dungeon Loot window keeps its own. Guild's Open Guild uses the
same `openLabel` hook. `tests/browser_windows.py` guards it. Native
confirmation is pending; restart the client once for the new TOC file.
v2 module cuts (branch `t3/v2-module-cuts`, 2026-11-23): part of the approved
v2 settings redesign. Display titles only: Map Labels (`cityLabels`), Experience
Bar (`enhancedExperienceBar`), Profession & Food Bars (`foreverQuickAccess`) and
Rogue Tools (`foreverRogue`). Module IDs, SavedVariables keys, frame names and
doc file names are unchanged; old names stay as `searchAliases`. Dated notes
below keep the names that were current when they were written.
Quick Actions: no per-module ring switch. Class Training and Dungeon Loot show
their ring icon whenever the module is on (Recruitment already did). Their old
`showShortcut` values stay in SavedVariables, unread and unvalidated.
Combat Timer: `CombatTimerDisplay.Format(seconds)` is always MM:SS; the Timer
format row and `SetAppearance("format")` are gone. `appearance.format` stays in
SavedVariables and profile validation, unread by the display.
Experience Bar: `hideAtMax` left the defaults (old values stay, unread); the
display hides whenever the player is capped outside Layout. The
Ellesmere row and its search entry use `M:EllesmereLoaded()`
(`C_AddOns.IsAddOnLoaded("EllesmereUIActionBars")`); `OtherBarsStatus` and the
Detected XP Bars row are gone. Search skips entries whose `available()` is false.
Automation: the Dialogue group, `GossipCapability` and the `autoGossip` option and
default are removed; an old saved `autoGossip` stays, unread. The Quest/Merchant
Automation rows stay: they appear only while the client rejected an action.
Echoes: `LootSparkles:StatusNotice()` drops the two on/off status strings; the
Rogue, Campfire and Food Bar status rows hide while they would only restate a
switch. Food Bar: `F:IsOn()` = `enabled and shown`, `F:SetShown(v)` sets both, and
`SyncEnabled` follows `IsOn()`. Enable Loot Sparkles and Enable Campfire Monitor
stayed here; the v2 split above removed them.
Refresh buttons: Spellbook Refresh, Update Learned List and Refresh Bags are gone.
Their modules already re-read on SPELLS_CHANGED / LEARNED_SPELL_IN_SKILL_LINE
(SpellBookDocumentation), SKILL_LINES_CHANGED (SkillInfoDocumentation) and
BAG_UPDATE_DELAYED (ContainerDocumentation) / ITEM_DATA_LOAD_RESULT
(ItemDocumentation), all in Blizzard's published Forever API docs
(Gethe/wow-ui-source, `forever` branch), and on PLAYER_REGEN_ENABLED after combat.
Not in scope and kept: Dungeon Loot's Dungeon Data Refresh, Campfire's Refresh
Status and Rogue Tools' Refresh Poisons. Native confirmation is pending; `/reload` OOC.

Dialogs (`Core/Dialogs.lua`, one new TOC entry, 122 Lua chunks): every addon
window, dialog and dropdown registers with `addon.Dialogs:Register(frame,
{kind, group, close})`. A `window` closes open windows/notices of other groups
when shown; `notice` (reload prompt, level-up popup) never closes anything;
`layer` (`W.Popup` menus) is Escape-only. Settings, its preview pop-out, the
popup preview and Dungeon Loot's in-page dialogs share group `settings`; the
Recruiter and its copy box share `recruiter`. Escape uses one stand-in frame,
`PlayTheGameToolsEscapeHandler`, in `UISpecialFrames`; it is shown only while
something is open and closes the newest entry per press. Register after any
`SetScript("OnShow")` (hooks are used). Unprotected frames only; secure bars,
menus and Camp Contributions are not registered. `tests/dialogs.py` guards it.
Native confirmation is pending; `/reload` OOC (new TOC file: restart client).

Points of Interest Labels (Quality of Life, thirteenth module): Modules/CityLabelsData.lua and
CityLabelsClassicData.lua (generated), CityLabels.lua, CityLabelsMap.lua +
CityLabelsMapPins.xml and Config/CityLabels.lua (123 Lua chunks). One native map data provider on
WorldMapFrame, attached after the map addon loads and outside combat; never
force-loaded. The builder now validates both map pin templates. Regenerate data
with tools/build_city_labels.py from a pinned EG Link dataset commit (CC BY 4.0)
and classic-db dump (GPL-3.0); see [Points of Interest Labels](CITY_LABELS.md). Run tests/city_labels.py with smoke/build.
New TOC files need one client restart. Native confirmation is pending.

Edit Mode styling (branch `t3/5b8d8061`): Text/Appearance panels of every
placeable display moved from settings pages into a styling column of the Edit
Mode window (`Config/EditMode.lua`). `W.EditAppearance` in `Config/ModePlans.lua`
maps each Position Manager element to its settings page and features; rows on
those features' Text/Appearance panels are tagged `editAppearance` (by
`ModeLayout` and the Campfire pilot) and hidden from settings and search. The
column borrows those same row frames while the element is selected
(`row.editBorrowed`, skipped by `page:Layout`) and returns them on selection
change, exit or combat, so controls, callbacks and saved keys are unchanged.
Non-display styling (Loot Sparkles, Class Training, Dungeon Loot) stays put. No
new files in the TOC; no SavedVariables changes. `tests/edit_mode_appearance.py`
guarded the contract. Superseded by Layout (below): the column and that test are gone. Native confirmation is pending; `/reload` OOC.

Declutter / unified Edit Mode (branch `t3/declutter-ui-unify-edit-mode`):
placement lives only in Edit Mode (`Config/EditMode.lua`), and every display
is a Position Manager element. Quick Access, Food Bar and Threat Meter join
through `PM:RegisterModuleDisplay` (seeds legacy module x/y once, mirrors plain
screen offsets, one next-frame retry); the others keep their existing
`RegisterElement` calls. Settings pages carry no
position/lock rows; the layout panels are Options / Text / Appearance only.
`Config/Window.lua` uses one layout for all themes (`art` only gates mode
textures); `Config/Categories.lua` was removed and `Config/PositionControls.lua`
became `Config/Select.lua` (117 Lua chunks). Lock flags stay in SavedVariables
but are unused. `tests/edit_mode_standard.py` guards the standard. Run
`tests/smoke.py`, the full `tests/` suite and
`tools/build_release.py`. Native confirmation is pending; `/reload` OOC.

Rogue Quick Access dismissal follow-up (2026-11-10): right-click the launcher to
hide it and close its menu for the session. Quick Access right-click is always available;
Settings -> Dismiss Quick Access also hides it. The Reminder toggle is separately
labeled Right-click to Dismiss Reminders. Restore Dismissed restores both. Preview/Edit Mode
reveals the icon without clearing dismissal. No new API, TOC or saved fields.
Run `tests/rogue_quick_dismiss.py`, `tests/rogue_layout.py` and smoke/build.
Owner confirmed the corrected dismissal works as expected on 2026-11-10 and
authorized PR #28 to merge into main. Focused dismissal/layout regressions and
smoke/build passed; no release publication or settings reset.

November 10 closeout: the owner accepted the final layout/descriptor placement
and authorized merging PR #26 into main, explicitly retaining Mode-only scope.
Mode guards and other-theme regression coverage were reviewed. Current main's
independent PR #27 Blizzard backdrop repair is preserved; its only conflict was
the changelog, resolved by retaining both entries. Layout acceptance does not
establish new gameplay/API validation. No universal-theme rollout is authorized.

Owner clarification supersedes the broad descriptor pass below: category
subheadings, short panel summaries, separators and minor text stay in their
approved locations. Only explicitly tagged explanatory blocks move to the
bottom, including Quest Automation / Merchant Automation, Visibility Help,
Food Selection, Other Addon Suites and Rogue's reference paragraphs. Source
statuses and brief control instructions stay inline. Rejection warnings in the
two automation blocks temporarily restore their original parent/anchors/height
and return to footer placement when cleared. The injected Loot Sparkles status
sentence is removed; original status text is preserved. Mode only; `/reload` OOC.

Mode descriptor refinement: optional panel summaries and selected background
notes now use full-width bottom rows. Pages lays out controls first, then footer
notes after the form/toggle gutter or against the viewport bottom on short pages.
Wrapped text determines height; long notes scroll naturally and search still
reveals their original row. Source rows and Class Training's dynamic pools are
not reordered. Live status, modifier/repair/blocked-action guidance, food choices,
click-through/dragging instructions and contribution placement guidance remain
inline. Loot Sparkles retains a brief compatibility instruction by its live
status while How It Works moves below controls. Other themes retain their
original positions. No assets/defaults/gameplay changes; `/reload` OOC.

Mode capsule refinement: all primary rows now share a centered 128×32 preferred
size with eight-unit gaps. The existing 4:1 capsule is scaled proportionally on
narrow rows, preserving round ends. Mode section strips have 40 units of height
and a 38-unit scroll child, clearing the 32-unit pills; their redundant baseline
is hidden. Standalone Options forms also omit the duplicate rule. Dungeon Loot,
shared module rows and Campfire use the same geometry helper. No asset/default
changes; focused geometry, alpha containment and callback checks plus build.

Mode rollout correction: native screenshots exposed primary section pills
collapsing before their anchored viewport resolved. Mode SectionTabs now anchor
early, preserve existing widths while unresolved, and listen to viewport sizing
and showing. Custom/Campfire bars also relayout on their own size events; custom
bar anchors are cached to prevent resize feedback. The regression explicitly
models zero-width initialization (the default mock previously returned 1024).
No new files/assets or setting changes; test with `/reload` OOC.

November 10 Mode rollout: the owner accepted Campfire Monitor's design and
authorized adapting the remaining module settings. Shared Config/ModePlans.lua
and Config/ModeLayout.lua route existing controls without gameplay or saved-data
changes. Dynamic catalogs, guild data, diagnostics and browser navigation keep
their original ownership. Modern/Blizzard and Global Settings stay unchanged.
Two TOC entries add 2 Lua files (118 Lua / 220 package files). All-module native
acceptance remains pending; [layout map and exact checks](MODE_MODULE_LAYOUTS.md).
The older instruction below to wait before scaling is satisfied by this approval.

November 10 Campfire layout pilot (PR #26): Mode-only element tabs with consistent
Options / Text / Appearance / Position panels. Text/color and opacity/color pairs
share responsive rows. Refinement combines General's Options/Text into one form,
adds thin gray borders to main pills, and uses compact separator-attached sub-tabs
for other windows (30-unit active / 22-unit tucked inactive). Descriptions are
plain muted-gray text and left headings are now 20 units with subtle underlines.
Mode color rows use Pick without redundant in-page hex/Apply fields. All settings,
picker callbacks, search routing and preview cleanup are retained; no gameplay/module source or manifest changes. Other
themes keep the original layout. All 34 regression scripts pass, including the
new `campfire_mode_layout.py`; final focused checks cover native resize reentrancy
and Blizzard parity. Package has 116 Lua / 217 files. Start with `/reload`
OOC. The supplied reference informs pill tabs and wide-page section descriptions
beside aligned forms; narrow pages fold that description above the fields.
Native visual review is pending.
Latest refinement: General's Text heading aligns left; headings are 20 units
with subtle underlines. Pick-only color rows free space for sliders. Wide mixed
panels place checkbox rows under the left heading, with an inline muted description
after a dot separator; search follows moved/restored rows. A dedicated SVG-derived
256×64 capsule replaces low-resolution pill art, with a matching 1.5-unit rim.
Package now has 116 Lua / 217 files. Try `/reload` first; an undiscovered capsule
uses existing rounded art as a fallback. No gameplay/default changes.
Latest alignment pass: uniform one-unit, text-centered header rules fade at both
ends; a 14-unit separator uses tighter eight-unit spacing. Sub-tabs now live in a
clipping ScrollFrame above the separator, with inactive lower pixels hidden.
Main pills expand/shrink evenly in one centered row inside the actual bar width.
Package now has 116 Lua / 218 files, including a small symmetric header-rule TGA.
Do not scale to another page/theme before the owner confirms this candidate.

November 10: new Mode-only page-material experiment on
`codex/mode-page-material-refinement`, based on public main after PR #22's Class
Training popout fix. Dedicated #2A2A2A page tint, existing Figma base/sheens and a
new Figma-generated abstract overlay at 18% opacity. Sidebar/control palettes,
module logic, profiles and other themes are unchanged. One runtime TGA; missing
art stays transparent. Start with `/reload` OOC. Native validation is pending;
see [page-material experiment](MODE_INTERFACE_THEME.md#november-10-page-material-experiment).
Validation: all 33 regression scripts pass; deterministic package build passes
with 116 Lua chunks / 216 files, including one additional page-detail TGA.

November 9 closeout: the owner accepted the current mode interface and global
texture isolation, and authorized PR #24's merge into main. This is scoped visual
acceptance; it does not establish new gameplay/module validation. Future design
experiments should use a new branch and PR. Final runtime checks passed all 33
regression scripts and the deterministic 116-Lua / 215-file package build.

Global Texture is now limited to module/feature displays. Configuration fills use
their own theme materials, and Blizzard popup backdrops preserve their native
background. This restores mode graphite/sheen with a custom global texture still
saved. No SavedVariables changes or new assets; `/reload` OOC. Regression coverage
checks all three themes, detached configuration popups and module inheritance.
Native appearance confirmation remains pending.

Latest small-control correction replaces the separate hollow mode border with a
solid outer silhouette behind the one-unit-inset fill on the same frame. Owner
feedback accepted the improved containment; the latest thinner rim uses charcoal
#2B2B2B in both states. Off/on recolors the identical interior. Tests
sample actual sprite alpha containment as well as repeated state geometry.
Lua-only, existing assets; `/reload` OOC. Native confirmation remains pending.

Latest mode layout correction removes page/window perimeter outlines, contains
checked fills inside their borders, centers and sizes the profile caption/name,
left-aligns search with page titles, and centers numeric values. The slider thumb
keeps its 10×20 size with rounded corners. Lua-only; `/reload` OOC, no new media.
Static checks include these geometry and callback contracts; native review pending.

Experimental **mode** interface theme: opt-in under Global Settings → Appearance,
using existing Lua files and the existing theme reload/profile flow. Revised Figma
graphite/soft-corner/selection/control textures, the owner logo and licensed Lato
fonts add fifteen media files; 116 Lua chunks remain. Latest native screenshot
correction uses power-of-two, unsliced checkbox/switch sprites, one-line fitted
navigation at 240 units, cyan PTG Tools branding, and Profile immediately left of
the rightmost Close. Padded rows and text-aligned fading selection remain. No module logic, TOC or
default theme changes. Test with `/reload` OOC from the feature
branch in the existing live-linked public checkout; preserve its junction and
settings. Native fit remains pending. Run tests/mode_theme.py with smoke/global/
Edit Mode, tests/mode_assets.py and the builder. Restart only if new assets are
not discovered by the running client. [Design and exact checks](MODE_INTERFACE_THEME.md).

Owner accepted Global Settings and authorized public PR #23's merge to main on
2026-11-09. Final UI refinement removes the SharedMedia status row and relocates
Interface Theme to Global Settings → Appearance below the media controls. Focused
smoke/global/SharedMedia regressions and deterministic 116-Lua / 199-file builds
pass. Broader native checks remain in GLOBAL_SETTINGS.md. Preserve the existing
Forever test junction and SavedVariables; no release publication is authorized.

Media discovery adds a path-only 55-entry installed-provider catalog plus an
account LSM registration cache. Ordinary disabled providers are never loaded/enabled;
the owner's subsequent explicit SharedMedia/MyMedia activation is the exception.
Run tests/media_discovery.py with the regression scripts; current packaging is
116 Lua / 199 files. The external read-only indexer and runtime discovery limits
are documented in [Global Settings](GLOBAL_SETTINGS.md).

Global Settings expands to four tabs and reuses the existing profile engine with an account-wide selection. Bundled LSM/dependencies and two new runtime files bring the addon to 114 Lua chunks. Run tests/global_settings.py and all standalone regressions, then the release builder. New source/media may require one full client restart for discovery; subsequent edits use /reload. See [contract and native checks](GLOBAL_SETTINGS.md).

Roster Search and Analytics extend the existing Roster files (no new chunks; /reload
applies it). Member details use only `ClubMemberInfo` fields in the published
Forever source: level, race (via `C_CreatureInfo.GetRaceInfo`), zone, guildRank/
guildRankOrder, memberNote/officerNote, presence and lastOnline*. Online means
Online/Away/Busy, as the native member count does. A restricted detail reads as
unknown; a restricted name or class still rejects the read. Search and filters are
session-only. Run `python tests/guild_roster.py`; native validation is pending.

Guild Roster adds Guild Tools -> Roster (twelfth module, two Lua files, 109 chunks).
Members come from `C_Club`, the documented path Blizzard's Forever member list uses;
`GetGuildRosterInfo` does not appear in the published Forever source and is not
used. Restricted/secret data keeps the last list, and nothing is saved. Run
`python tests/guild_roster.py` with smoke/build. New TOC files need a client
restart. Native validation is pending; no release or SavedVariables change.

Enhanced Experience Bar adds the tenth module and four Lua files (100 chunks).
Run `python tests/enhanced_experience_bar.py` for forecasts/session/Edit Mode and
profile coverage, plus regression/build checks. The contract and exact `/reload`
test paths are in [ENHANCED_EXPERIENCE_BAR.md](ENHANCED_EXPERIENCE_BAR.md).
Owner reports initial bar working/no errors. Revised full-height overlays,
all-log/hidden-header scans, texture options and separate text customization
remain pending native validation; no release publication is implied.

XP provider choice uses an independent runtime visibility adapter; run
`python tests/enhanced_experience_visibility.py` with the focused bar/smoke tests
and builder. New helper is in the TOC; if /reload misses it, restart the client.
Default hide toggles are off. Native and Ellesmere coexistence needs owner review.

Owner accepted the completed local feature and authorized PR #13's main merge on
2026-11-07. Runtime checkpoint 7054cc0 passes the focused bar/visibility suites,
smoke, Campfire Edit Mode, Dungeon Loot and deterministic build (100 Lua / 175
package files); prior scoped regressions also passed. Main had no intervening
changes or conflicts. Merge closeout updates only owning docs; the clean existing
live-linked checkout returns to merged main, preserving its junction and settings.
Broad native/API/provider-version coverage remains bounded by the owning checklist.

Owner confirmed the Rogue layout/icon-gap corrections look good and function
as intended, and authorized PR #19 to merge into main on 2026-11-08. Focused
layout, icon and charge regressions and the Forever package build passed at
77adc86. This closes the current development pass; the detailed checklist still
bounds broader poison-family/combat coverage. No release or settings reset.

Rogue gap correction: Icon Gap (0–120, seeded from old spacing) is the real
horizontal button-edge gap. Individual image inset controls/rendering and Reminder
Cell Width are removed; wrapped hand text uses measured height. Stock Quick Access
launcher/menu borders migrate to none with custom settings/controls retained.
Run `tests/rogue_icons.py`, layout/charge suites and build; native fit is pending.

Rogue charge follow-up adds Use Time Threshold / Use Charge Threshold,
inclusive 5–25 charge setting (default 10), same-condition Quick Access visibility,
and optional charge text without changing bare defaults. Only public native charge
fields are used; zero semantics and combat behavior need owner validation. Run
`tests/rogue_charges.py`, `tests/rogue_layout.py` and build/smoke.

Rogue navigation correction: class icons belong beside the left sidebar Rogue
subcategory and in its compact top tab. Removed the duplicate below the tab and
anchored On/Off 8 UI units after its label. Description/header module switch remain.
The exact screenshot correction awaits native visual confirmation after /reload.

Rogue icon follow-up: primary controls are now directly visible in Display,
with reminder spacing/image padding and independent per-icon borders, color,
opacity and background. The owner reports the prior layout looks good so far;
new icon rendering awaits native review. Run `tests/rogue_icons.py` alongside
`tests/rogue_layout.py` and smoke/build before updating PR #19.

Current Rogue layout revision: `codex/rogue-tools-layout`, based on main after
Quick Actions PR #18. Uses existing runtime files (107 Lua chunks); /reload applies
the candidate. Display/Settings/Position, minimal reminder, per-hand right-click
dismissal, family selection grid and real shared Position Manager elements.
Run `tests/rogue_layout.py` (includes poison/smoke regressions), `tests/edit_mode.py`,
`tests/quick_actions.py`, and the builder. New native review is pending; the owner's
earlier quick-test confirmation applies to the prior application version only.

Rogue poison tools add Class Tools -> Rogue (eleventh module/fifth category),
five Lua files, 106 chunks. The first buttons were owner-reported inert; revision 2
adds inventory-backed item actions, confirmed last-use and independent styling.
Owner reports revision 2 working in quick testing and authorizes main merge on
November 8, 2026. Run `python tests/rogue_poisons.py` plus smoke/build; broader
native coverage remains bounded by the owning test packet.
[API assumptions and exact local test packet](FOREVER_ROGUE_POISONS.md). Local
source is available through the existing installation link for /reload. The
authorized PR merge does not publish a release or reset SavedVariables.

The editable addon is `PlayTheGameTools/`, displayed in WoW as Play The Game Tools.
It contains all current Forever production Lua and runtime media. The repository
starts with fresh history; no Retail modules, development-machine settings or
mixed-edition Git history are imported. Development prototypes are separate addons
and are not part of this production addon.

The initial import contains 72 Lua files (71 production files plus presentation
metadata), 66 media files and one TOC. Six registered modules cover Foundation
diagnostics, Combat Timer, Automation, Class Training, Quick Access (including
Food Bar) and Recruitment. Existing game behavior and settings are preserved.

## Build and test

```sh
python -m pip install lupa
python tests/smoke.py
python tests/edit_mode.py
python tools/build_release.py
```

The standalone builder reads the actual TOC and runtime media, verifies Forever
identity and dependency paths, excludes developer files/settings, and creates a
deterministic installable ZIP and SHA-256 checksum under ignored `dist/`.
It has no network, live installation or publication step. When the same version's
output differs, retain the previous artifact elsewhere or bump the TOC version.
Publishing to CurseForge and GitHub Releases is a separate, tag-triggered GitHub
Actions workflow; see [RELEASING.md](RELEASING.md).

The smoke test compiles and executes the actual Lua under the Lua 5.1 WoW mock,
constructs all module pages, exercises profile serialization/restoration and the
wrong-client block, and checks ZIP bytes/inventory. These checks are bounded;
native combat safety, secure button behavior, API availability, text fit and
rendering require in-game verification. Use TESTING.md and focused feature checks.

Edit source directly here. This is a standalone copy, with no dependency on the
original package generator or another checkout. A future upstream copy needs
explicit review and is never automatic. The initial import's historical hashes
are recorded in INITIAL_RUNTIME_SHA256.json; they are not a moving expected
baseline for subsequent feature changes.

## Installation and collaboration

Keep the addon folder named `PlayTheGameTools` and preserve `PTGToolsDB` and the
`/ptg` and `/ptgr` commands. Extract only the built ZIP into the Forever
AddOns directory with WoW closed. Do not install the repository root, tests,
developer tools, or GitHub's source ZIP as the addon.

Use focused pull requests. Issues should include Forever build, addon version,
class/level, exact reproduction and error text. Remove account data and personal
paths before attaching logs. Maintainer approval is needed for native acceptance
and releases; passing static checks alone is not a release acceptance claim.

## Dungeon Loot feature work

PR #14's Quick Icon revision replaces the failed square prototype with explicit
native loot art and the Class Training circle construction. It registers
positions.dungeonLootShortcut with the shared manager and exposes size/opacity,
normal drag/lock and Edit Mode controls. General now owns key capture, native
SetBinding/SaveBindings and Clear for Dungeon Loot. The owner confirmed the
revised icon/editor working, then requested overriding the chosen key regardless
of its old action and a separate assignment field. Failure rollback restores the
overwritten action and prior Dungeon Loot keys. The owner confirmed the final
Quick Icon/binding revision working on 2026-11-07 and authorized merging PR #14.
Screenshots remain pending; no release publication is included.
Capture cleanup and managed mouse-state regression checks are in
dungeon_loot_quick_icon.py (under tests/). No new runtime files for this revision;
/reload applies it after initial installation. Native confirmation pending.

The new standalone shortcut/keybinding revision is on codex/dungeon-loot-shortcut
for a separate PR. Startup/profile checks and focused shortcut tests cover
routing, drag persistence, disabled/hidden behavior and combat lifecycle. The
root Bindings.xml is auto-loaded by WoW, explicitly validated/packaged by the
builder, and not listed in the TOC. Restart the client for native review. No
release or live copy-sync is authorized. Native paths: docs/DUNGEON_LOOT.md.

Dungeon Loot adds a seventh registered module, thirteen Lua files and a virtual
map-pin XML template. The builder validates and packages the template immediately
after its Lua mixin. Its owning
document is [DUNGEON_LOOT.md](DUNGEON_LOOT.md), with source/provider limitations,
focused checks and native review steps. The owner accepted SFK and authorized
all-dungeon expansion on 2026-11-07. The owner authorized merging PR #6 on 2026-11-07. Standalone native review
and screenshots remain pending; this authorization does not publish a release.

For this machine the owner verified an existing Forever AddOns junction to this
checkout's PlayTheGameTools directory. Source edits and branch switches affect the next
client load. Preserve that junction; do not apply the older copy-sync workflow.
This owner-directed arrangement supersedes the general separate-install advice
above for this machine only. Never change SavedVariables.

## Loot Sparkles feature branch

The ninth module is Gameplay Enhancements (Loot Sparkles); four new Lua files
bring the runtime to 90 Lua chunks. See [research, architecture and native checks](LOOT_SPARKLES.md).
Run `python tests/loot_sparkles.py` alongside the smoke suite and builder.
Native validation/screenshots are pending. No live branch switch, sync or release
is part of creating this PR. Existing main-checkout junctions remain untouched.

### Local reload workflow

The desktop Forever AddOns/PlayTheGameTools junction loads the standalone
checkout at A:/WoW-Development/PlayTheGameTools/PlayTheGameTools. A PR created
in another worktree does not update that live source. For explicitly requested
local testing, validate the feature, preserve dirty work, and switch the clean
live-linked checkout to the feature branch. Keep the existing junction and
SavedVariables intact. Subsequent runtime edits in that checkout are read on
/reload; adding newly discovered files may require one full client restart if
the running client does not discover the updated TOC/file inventory.

Loot Sparkles local testing uses codex/forever-loot-sparkles, including the
accepted main changes through b8a411b. Disable ForeverLootSparkles/Lueur in the
game AddOns UI and reload before enabling Gameplay Enhancements. Native
validation and screenshots remain pending until the owner reports results.

## Gameplay Enhancements feature tabs and Campfire Monitor

The owner reports Loot Sparkles appears to work with functioning features. This
scoped feedback permits the next requested feature, not blanket native acceptance.
Gameplay Enhancements remains the ninth registered module; it now hosts independent
Loot Sparkles and Campfire Monitor switches beneath its master. Three new Lua files
bring the runtime to 93 chunks. See CAMPFIRE_MONITOR.md for research, native API
limits and exact testing paths. Run tests/campfire_monitor.py and the existing
smoke/sparkle checks plus the release builder. Changes are in the live-linked
standalone checkout for local /reload testing; SavedVariables and junctions stay
untouched. Campfire/tab-layout native acceptance and screenshots are pending.

## Campfire movement and compact buffs

Owner reported movement failure and requested simple earned-buff text with joined
or separate placement. Move Windows and draggable previews now override saved
mouse locks transiently, and aura/font refreshes leave dragged anchors alone.
Compact native-value text defaults on; the optional transparent buff window has
its own position/style. Earned buffs persist after leaving proximity. Existing
runtime files only; local /reload applies it. Run tests/campfire_movement.py,
loot_sparkles.py and the builder. Exact new native paths are in CAMPFIRE_MONITOR.md.
Native validation/screenshots pending; no SavedVariables edits or junction changes.

## Campfire Edit Mode and timer presentation

Campfire Monitor/Camp Buffs now register in the shared Position Manager under
the existing Gameplay Enhancements module. The existing Edit Mode workspace
handles both, with hidden membership for disabled/joined elements and preserved
positions. No shared Edit Mode/core changes. Camp Buffs has gradient header and
native public countdown, 10/2-minute warning/critical defaults, per-stat colors
and ID filtering. Centered icon uses status only; no supported camp coordinates
were verified, so yards/arrows are omitted. Run tests/campfire_editmode.py,
campfire_movement.py, loot_sparkles.py and the builder. Existing runtime files
only; /reload loads local source. Native rendering/movement/screenshots pending.

## Camp contribution popup and duplicate duration footer

Added three Forever-only child-helper files after CampfireMonitorDisplay in the
TOC (96 runtime chunks). The opt-in monitor offers Show Contribution Popup,
Open Contributions and Refresh Contributions. Native OOC action-template clicks
use carried ready profession kits; no crafting/auto-use/targeting bypass. Events
and cached scans replace polling. Separate popup header dragging persists its
position. Camp Buffs filters native duration-only footer rows while retaining
its countdown subheading and periodic stats. See CAMP_CONTRIBUTIONS.md for
research/licensing and exact native checks. Run camp_contributions.py,
campfire_editmode.py, campfire_movement.py, loot_sparkles.py, smoke.py and the
release builder. Native item dispatch, rendering and screenshots remain pending.
The existing owner-authorized live junction is preserved; no SavedVariables edits.

## Campfire settings and safe contribution samples

Owner correction removes native gained-benefits boilerplate and parenthesized
time-only footers. Campfire and sparkle toggles now batch into two-column grids.
Text Colors uses the native picker with plain defaults and optional gradients;
dynamic urgency and typed stat colors can be disabled/customized. Contributions
has Detected Kits, concise TLDR help, a separate Preview Contributions control
and shared Edit Contributions handles/coordinates using an inert non-action row.
The live action path remains native user-click-only; samples do not scan/use
items. Explicit Refresh Contributions reads inventory OOC even away from camp.
Run campfire_controls.py (imports contributions/monitor/smoke), campfire_editmode.py,
campfire_movement.py, loot_sparkles.py and the builder. Native acceptance pending;
owning docs contain exact paths. No shared core/Retail/SavedVariables changes.

## Native-only camp duration and contribution visibility correction

Supersedes the earlier countdown notes: all custom timer labels/drivers/settings
are removed, leaving native tooltip duration. Legacy stored timer preferences are
inert and preserved. Config is grouped General / Campfire Icon / Camp Buffs /
Camp Contributions; status refresh is a secondary Tools button. Contribution
construction now anchors before Position Manager registration; native unanchored
GetCenter can be nil, unlike the original broad fixture. The scoped geometry
regression now models that behavior. Preview has explicit sample icon/row/panel;
contributions have independent scale/opacity/background and Reset Position.
Run campfire_controls.py, campfire_editmode.py, campfire_movement.py,
loot_sparkles.py, smoke.py and builder. Owner confirms detection, but native
visual rendering/item dispatch and screenshots remain pending. See owning docs
for exact paths. No shared core/Retail/SavedVariables/junction changes.

## Contribution registration error follow-up

Owner supplied 174 invalid-frame assertions after the earlier anchor fix. That
fix was insufficient; the broad geometry rejection does not identify the native
field/restriction. Construction is now complete and shown before registration;
one next-frame retry handles delayed layout. Repeated failure latches a short
Detected Kits status, clears OOC action attributes and stops event-driven retries.
Manual Open/Preview/Refresh/Reset Position recovers; combat/hide/disable cancels
the temporary driver. Shared manager checks remain unchanged. Run the new
camp_contributions_registration.py plus campfire_controls.py and the builder.
Native rendering/recovery and screenshots remain pending.

## Contribution editing and fixed stat colors

Owner confirms window generation, reports editing failure. Fractional managed
offsets could leak back into integer-only settings and reject all subsequent
edits. Round the actual managed record; normalize only legacy finite in-range
contribution offsets without resetting position. Apply after Show; use MEDIUM
for the contribution subject during Edit Mode below the DIALOG workspace.
Numeric appearance fields snap to supported steps. Crit/Int custom pickers and
setters are removed; fixed existing stat palette ignores old overrides while
preserving saved fields. Run camp_contributions_editing.py, camp_contributions_registration.py,
campfire_controls.py and builder.
Native editing/screenshots pending; exact paths in CAMPFIRE_MONITOR.md.

## Fractional contribution startup regression

Owner reported initialization rejecting contributionX. A read-only targeted check
confirmed fractional legacy offsets; no SavedVariables were changed. Historical
007819a reproduces the startup failure, while live a427bc2 already repairs the
same profile. Added camp_contributions_startup.py to exercise the full startup
path, unrelated preference/recovery retention and a second reload. No additional
runtime change or profile reset is required. Native reload confirmation pending.

## Contribution appearance and section navigation

Added independent contribution styles/default validation for window dimensions,
border/background, rows/viewport, font/outline, every text color/size, alignment,
icons, visibility, lock/tooltips and direct managed offsets. Live/preview use one
layout/style path; hardware item action ownership is unchanged. Full-width Jump
To buttons use existing page Reveal for Monitor/Buffs/Contributions groups; no
shared page changes or extra tabs. Selecting an explicit font exits interface
font inheritance. Run camp_contributions_appearance.py,
registration/editing/startup suites and builder. Existing runtime files only,
96 chunks; local /reload applies source. Native visual acceptance pending.

## Gameplay Enhancements merge closeout

Owner accepted the latest contribution/customization UI and authorized merging
PR #10 to main. Reconciled current main in an isolated worktree, retaining its
Modern contrast and Recruitment cleanup. Both conflicting changelog additions
are retained. Verify the combined feature/startup/profile/Recruitment/dungeon
suites and release builder before publication, then fast-forward the existing
live-linked checkout to merged main. Native item placement/broad combat coverage
remain unconfirmed; no SavedVariables edits or release publication.

## Quick Actions launcher

Modules/QuickActions.lua owns one Edit Mode button and the ring of module icons
around it; see [QUICK_ACTIONS.md](QUICK_ACTIONS.md). It is not a registered module,
so it adds no page, switch or module count. New TOC file: restart the client once. Run tests/quick_actions.py with the Dungeon Loot icon
suites, edit_mode.py, smoke.py and the builder. Native confirmation pending.
