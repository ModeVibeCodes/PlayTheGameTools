# Standalone Forever development

The editable addon is `ModeTools/`, displayed in WoW as Play The Game Tools.
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

Keep the addon folder named `ModeTools` and preserve `ModeToolsDB` and the existing
`/modetools` and `/mode` commands. Extract only the built ZIP into the Forever
AddOns directory with WoW closed. Do not install the repository root, tests,
developer tools, or GitHub's source ZIP as the addon.

Use focused pull requests. Issues should include Forever build, addon version,
class/level, exact reproduction and error text. Remove account data and personal
paths before attaching logs. Maintainer approval is needed for native acceptance
and releases; passing static checks alone is not a release acceptance claim.
