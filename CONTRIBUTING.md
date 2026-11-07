# Contributing to Play The Game Tools

This standalone repository contains the **Forever edition only**. Make changes
here for guild collaboration. The initial import is an independent snapshot;
changes do not automatically synchronize with another repository or a live game.

1. Fork this public repository, clone your fork, and branch from `main`.
2. Use a focused branch, for example `feature/training-fix`. Keep one feature or
   fix per pull request and preserve working behavior and existing settings.
3. Edit `ModeTools/Core`, `ModeTools/Config`, `ModeTools/Modules`, or
   `ModeTools/Media` directly. Add new Lua files to `ModeTools/ModeTools.toc` in
   dependency order; keep Edition first and Init/ReleaseMetadata last.
4. Install Python 3.12+ and the test dependency: `python -m pip install lupa`.
   Run `python tests/smoke.py` and `python tools/build_release.py`.
5. Test a separate Forever installation with WoW closed while copying the built
   ZIP. Preserve your own SavedVariables. Never install into Retail or link your
   Git checkout into a live AddOns directory.
6. Open a pull request to `ModeVibeCodes/PlayTheGameTools:main`. Describe the
   problem, change, static results, actual native results and remaining unknowns.
   A maintainer reviews and merges it. Do not publish releases automatically.

Forks and pull requests work without write access. Direct push access requires
the owner to invite your GitHub username separately. No collaborator credentials
or settings belong in the repository.

The visible title is Play The Game Tools. Retain the technical `ModeTools` folder,
`ModeToolsDB`, slash commands, frame names, media paths and profile format for
compatibility. Do not migrate or reset users' settings without an explicit plan.

Use supported Forever client APIs, keep combat-sensitive operations guarded,
preserve module independence, and avoid unnecessary polling and protected-action
workarounds. Existing mock tests establish neither Blizzard support nor native
behavior. Use actual implemented UI paths and exact labels for manual tests.

Original code is MIT. Preserve all third-party notices and artwork ownership.
Never copy reference-addon code or assets without reviewing their licenses.
