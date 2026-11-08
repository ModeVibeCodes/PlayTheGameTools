---
name: pr-and-update-local
description: >
  Use when the user runs /pr-and-update-local, or asks to open a Play The Game
  Tools pull request and load that branch in the running WoW Forever client
  with /reload without closing the game.
user-invocable: true
disable-model-invocation: true
argument-hint: "[optional pull request title]"
---

# PR and update local

Publish the current addon change as a pull request, then make the running WoW Forever client load that branch on `/reload`.

Running this command is the authorization to commit, push, and open the PR, and to point the live Forever addon at that branch. It does not authorize a merge, a release, a force-push, or any change under `WTF/` or `SavedVariables/`.

Use the shell, `git`, and `gh`. Grok Build and Claude both load this skill from `.claude/skills/`. Do not depend on a vendor-specific tool name. If the session has a host tool whose only job is to link a pull request, call it once with the PR URL after `gh` creates or updates it. Skip that step when no such tool exists.

## Publish

1. Work in the checkout that contains the change. Do not create a worktree for this command, and do not switch that checkout to `main` afterward.
2. If `HEAD` is `main` and there is something to publish, create `feature/<short-name>` first. Never commit on `main` and never push `main`.
3. From the repo root, run `python tests/smoke.py` and the focused tests for the area you changed. Run `python tools/build_release.py` only when the TOC version changed, or when `dist/` has no artifact for the current version. If a test fails, stop. Do not push, open a PR, or run the live-addon script.
4. Commit the addon change when it is still uncommitted. Match the existing subject style: one imperative sentence, no trailer. Leave out `dist/`, caches, `WTF/`, `SavedVariables/`, secrets, and files that are not part of the change. Do not change git config. Do not force-push or reset.
5. Push with `git push -u origin HEAD`. If `origin` rejects the push for permissions, push to the `fork` remote, or to the remote whose URL is not `ModeVibeCodes/PlayTheGameTools`.
6. Open a PR to `ModeVibeCodes/PlayTheGameTools` base `main` when that branch does not already have one. Use the user's title when they supplied one. Body, in this shape:

```markdown
## Summary

<what changed and why>

## Testing

- python tests/smoke.py — <result>
- <every other command you actually ran, with its result>
- In game: not claimed. `/reload` loads this branch after the live update below.

## Screenshots

Screenshots: pending
```

Replace the Screenshots section only with real Forever captures the user supplied in this session. A branch with nothing ahead of `main` and a clean tree gets no PR. If a PR already exists, push any new commits and use that PR.

## Point the running client at this branch

Run this from the PR checkout after the push. Do not copy the addon, delete the live folder, check out `main`, or replace the junction yourself. The script refuses Retail and the other WoW flavors, and it does not read or write SavedVariables.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<repo>\.claude\skills\pr-and-update-local\scripts\stage-live-addon.ps1" -SourceAddon "<repo>\PlayTheGameTools"
```

`<repo>` is `git rev-parse --show-toplevel` of the checkout that is on the pushed branch. A non-zero exit stops the command. Show the script output and do not invent another install step.

The script leaves the existing Forever junction on this checkout when it already points here. When it points at a different clean checkout, the script switches that checkout onto this branch and leaves the junction path alone. When a switch would overwrite local work, or this branch is already open in a worktree, the script points the junction at this checkout instead and prints `PREVIOUS`. That previous folder is still on disk. Do not delete it, and do not move either checkout back to `main`.

Finish with the PR URL, the script `STATUS` line, and `PREVIOUS` when it is present. Tell the user the game stays open and to type `/reload` to load this branch. Name any uncommitted files still in the addon directory, because `/reload` will load those too. SavedVariables were not modified.
