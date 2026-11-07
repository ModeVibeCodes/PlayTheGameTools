# Initial standalone import

Prepared November 6, 2026, at the owner's request for public guild collaboration.

- Name: Play The Game Tools. Edition: WoW Forever only.
- Independent repository: `ModeVibeCodes/PlayTheGameTools`, starting on `main`.
- All 71 production Lua files, release-label Lua, 66 runtime media files and TOC
  were copied from the reviewed current Forever package. Existing uncommitted
  Forever work was included in that snapshot, rather than silently using an old
  source commit. No mixed-edition Git history was imported.
- Existing compatibility folder, settings names, commands, licenses and native
  gameplay behavior remain. Player docs now link the collaboration instructions
  and list Quick Access/Food Bar and Recruitment.
- Developer additions: contributor/agent guidance, PR template, standalone build
  and Lua smoke test. The source repository has no dependency on the old checkout.
- The original source files, Git index, HEAD, remote and live installation were
  preserved. Future edits in this repository do not sync back automatically.
- Initial payload hashes are recorded in INITIAL_RUNTIME_SHA256.json. Mock
  startup and all module pages, settings roundtrip, wrong-client rejection,
  deterministic archive and inventory checks passed. Native validation remains
  bounded by the existing TESTING.md checklist; no new in-game result is claimed.

The standalone ZIP builder reproduced the original import ZIP byte-for-byte
before the public README additions. Those additions affect documentation only.
No packaged addon release or automatic updater publication is implied by making
the source repository public. Build an installable ZIP with the included tool;
the owner controls reviewed releases separately.

Research followed GitHub's official guidance for
[importing local code](https://docs.github.com/en/migrations/importing-source-code/using-the-command-line-to-import-source-code/adding-locally-hosted-code-to-github),
[creating a repository](https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-new-repository),
and [fork/pull-request contributions](https://docs.github.com/en/get-started/exploring-projects-on-github/contributing-to-a-project).
An independent initial commit keeps the mixed-edition project's history separate.
Public contributors can fork and open pull requests without direct push access;
the owner can invite named collaborators separately when desired.
