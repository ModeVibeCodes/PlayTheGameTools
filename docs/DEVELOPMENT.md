# Standalone Forever development

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
conflict-aware SetBinding/SaveBindings and Clear, scoped to the existing action.
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
