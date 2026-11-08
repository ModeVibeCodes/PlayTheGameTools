# Forever API compatibility notes

## Enhanced Experience Bar

Uses public player XP/rest state, quest log metadata and reward XP APIs behind
function/type/restriction checks. No combat target data, stock XP hooks or
protected frames. Full-log scans temporarily expand collapsed headers OOC and
restore header state/selection before returning. See
[the research and native validation contract](ENHANCED_EXPERIENCE_BAR.md#api-research-and-licensing).

Initial display is owner-reported working/no errors. Full-log totals, header
restoration and revised overlays/textures/text need native confirmation. Missing/
restricted rewards or combat-deferred hidden quests produce a visibly
incomplete estimate; unavailable XP hides the display. Shared Position Manager
owns movement. Static mocks do not establish native Blizzard support.

XP-provider visibility uses only inspected unprotected native XP containers and
the Ellesmere 9.7.8 XP holder. Native reputation/other data bars retain their
owner. No provider methods, events, settings or source files are replaced;
OnShow hooks are inert when released. Restore delegates to each owner's normal
update OOC (queued to regen if disabling in combat). Unsupported/protected frames
are skipped. Native coexistence and future Ellesmere versions require testing.
