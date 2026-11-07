# Play The Game Tools — Forever only

- This repository is exclusively WoW Forever. Edit the addon in `ModeTools/`.
- Preserve functionality, appearance, settings and existing compatibility IDs
  unless the user requests a specific change. Never reset SavedVariables.
- Read relevant source before editing; implement one focused feature at a time.
- Research uncertain APIs in current Blizzard source/docs; never invent APIs,
  bypass restrictions, or assume Retail behavior applies to Forever.
- Keep modules independent and combat-safe operations separated from protected UI.
- Keep `ModeTools.toc` load order correct. No placeholder functionality.
- Read CONTRIBUTING.md and docs/DEVELOPMENT.md for the standalone workflow.
- Run `python tests/smoke.py` and `python tools/build_release.py` as appropriate.
  Do not claim native testing without the user's in-game confirmation.
- Manual checks must state Navigation, Action, Required state and Confirmation,
  using actual implemented control labels. Do not invent UI paths.
- Live sync, releases, pushes and collaborator invitations require user scope
  authorization. Source edits alone do not authorize deployment or publication.
- Preserve licenses/notices and unknown user work. Never force-push or reset.
