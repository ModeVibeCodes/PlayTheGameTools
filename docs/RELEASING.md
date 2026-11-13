# Releasing to CurseForge and GitHub

Releases are built and published by `.github/workflows/release.yml`, which runs
[BigWigsMods/packager](https://github.com/BigWigsMods/packager) with the rules in
`.pkgmeta`. Only the maintainer publishes: pushing a version tag is the release
approval. Merges, branches and pull requests never publish anything.

## One-time setup

1. Create the CurseForge project (World of Warcraft → Addons) and note the
   numeric **Project ID** from its "About Project" box. Wait for CurseForge to
   approve the project before the first tagged release.
2. Create a CurseForge API token at
   <https://authors.curseforge.com/#/settings/api-tokens>.
3. In GitHub: Settings → Secrets and variables → Actions:
   - **Secrets** tab → New repository secret `CF_API_KEY` = the API token.
   - **Variables** tab → New repository variable `CURSEFORGE_PROJECT_ID` = the
     Project ID.

The GitHub release uses the built-in `GITHUB_TOKEN`; no extra secret is needed.
The workflow requests `contents: write` itself. If a run reports "Resource not
accessible by integration", set Settings → Actions → General → Workflow
permissions to "Read and write permissions".

## Publishing a version

1. On `main`, set `## Version:` in `PlayTheGameTools/PlayTheGameTools.toc` to the new
   version (for example `0.2.0-beta.2`) and update `CHANGELOG.md`. Merge it.
2. Tag that commit with the same version prefixed by `v`, then push the tag:

   ```sh
   git tag -a v0.2.0-beta.2 -m "v0.2.0-beta.2"
   git push origin v0.2.0-beta.2
   ```

3. Watch Actions → Release. The workflow:
   - fails early if the secret/variable is missing or the tag does not equal
     `v` + the TOC version;
   - runs `tools/build_release.py` (TOC/inventory guards) and every `tests/*.py`
     under lupa;
   - packages `PlayTheGameTools-v<version>-forever.zip`, uploads it to CurseForge
     for the Forever game version read from `## Interface:`, and creates a GitHub
     release with the zip attached.

Tags containing `beta` publish as Beta and tags containing `alpha` as Alpha
(CurseForge file type and GitHub pre-release); any other tag is a full Release.
CurseForge shows `CHANGELOG.md` as the file's changelog.

To check a package without publishing, run Actions → Release → Run workflow on
any branch. It runs the same checks and packaging with uploads skipped and keeps
the zip as a workflow artifact.

## Package contents

`.pkgmeta` lifts the `PlayTheGameTools/` addon folder to the package root and ships
the root documents and `LICENSES/`, matching the file list `tools/build_release.py`
produces. The older duplicate documents inside `PlayTheGameTools/` are ignored so
the current root copies ship. The packager writes text files with CRLF line
endings; the content is otherwise byte-identical to the builder's ZIP.
`tools/build_release.py` remains the local, offline build and has no publication
step.
