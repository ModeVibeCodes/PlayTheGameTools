# Standalone Forever development

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
