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

## Rogue poison tools — November 8, 2026

The owner confirms visible module/elements but inert first-version buttons. That
candidate only discovered learned casts; it omitted carried poison items. Revision
2 scans public OOC carried inventory, gets native item names/icons/effect IDs and
binds item:<ID> with native target-slot 16/17 through InsecureActionButtonTemplate.
Blizzard retains OnClick/combat guarding; addon PreClick records intent only, with
explicit release-edge dispatch. No direct Cast/Use/RunMacro or synthetic clicks.
Public OOC player UNIT_SPELLCAST_SUCCEEDED plus changed/refreshed weapon snapshots
identify confirmed last-used poison per character/hand. Attempts alone do not.
Unobserved earlier rank and ambiguous manual hand/event matches remain uncertain.
Secret/missing data stays inert; no cast GUID/restricted value is inspected.
Poison Imbue classification, timeLeft milliseconds, actual item target/cast behavior,
native event order and visual fit need broader owner testing. The owner confirms
revision 2 working in quick testing on November 8, 2026. Inventory-backed mocks
correct the prior learned-spell-only fixture; static passing is not acceptance.
See [primary Blizzard sources, exact boundaries and native checks](FOREVER_ROGUE_POISONS.md).

## Rogue layout and dismissal — November 8, 2026

The previous application version is owner-confirmed in quick testing; the new
Display/Settings/Position UI, dismissal and shared Edit Mode changes are pending
native review. Right-click PreClick updates session-only unprotected reminder
visibility, including in combat. Blizzard retains OnClick and its combat guard;
no right-button action/target attributes or direct Cast/Use/RunMacro paths exist.
Both Rogue elements now register with Position Manager after geometry is ready;
legacy x/y values seed central positions and stay mirrored. Shared highlights,
selection, drag, coordinate limits and combat cleanup are reused. Customized
appearance/history/unknown keys are retained; only the untouched original preset
migrates to icons/hand text. Class icon metadata opts just this module into icon
navigation/header presentation; other headers restore their normal title.
See [current contract, primary sources and exact native tests](FOREVER_ROGUE_POISONS.md).
