# Standalone Forever development

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

Dungeon Loot adds a seventh registered module, twelve Lua files and a virtual
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
