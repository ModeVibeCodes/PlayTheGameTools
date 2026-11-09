# Forever API compatibility notes

Global Settings now includes standard Blizzard FontObject face changes (OOC), bundled LSM, account-wide profile selection, native CVar writes with accepted-value readback, UIParent scaling, UIErrorsFrame event ownership and generation-cancelled OOC loot-slot requests. Current Forever UI source, Naowh behavior/licensing, client range uncertainties and native gates are recorded in [Global Settings](GLOBAL_SETTINGS.md). Earlier addon-only/optional-library/no-game-font statements were superseded by the requested expansion.

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

## Rogue per-icon appearance — November 8, 2026

Per-icon padding, borders, background and opacity use only owned Texture regions,
public local style preferences and existing OOC layout. Four border edges avoid
corner alpha overlap; image padding is clamped to preserve positive drawable area.
No native action template, spell/item bindings, combat dispatch or data reader
changes. Defaults add missing preferences and retain bare reminders/current window
styles. Numeric-control, geometry, independence, Edit Mode and persistence mocks
pass; native visual fit/input acceptance remains for the owner to confirm.

## Rogue navigation spacing — November 8, 2026

The class icon appears only in the left subcategory and top module tab, with no
second header icon. Class-tab width uses measured local label/status text and
anchors status 8 UI units after the label; description-only class headers retain
the ordinary module switch. Other module tab/header layouts keep their existing
behavior. Owned UI texture/anchor changes only; no gameplay, protected actions or
SavedVariables changes. Smoke/layout checks pass; native screenshot fit is pending.

## Rogue poison charges — November 8, 2026

Blizzard's Forever [Item API](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemDocumentation.lua)
documents C_Item.GetWeaponEnchantInfo(weaponSlot) -> WeaponEnchantInfo[], including
charges alongside timeLeft, hasEnchant, enchantType, enchantID and enchantIconID.
Positive public integer counts establish charge capability for that weapon/enchant;
a subsequent public zero on the same identity can represent exhaustion. No native
hasCharges flag/zero sentinel is documented, so cold zero is not treated as low
charges; missing/secret/malformed counts leave the public timer path intact. No
secret count is inferred from history. Session-only capability records reset on
reload and do not populate SavedVariables. Any recognized poison Imbue can use
the same field; actual charged families, zero semantics and combat readability
remain native validation items. Inclusive 5–25 threshold, toggle independence,
counter/tooltip, zero/restricted cases, charge-only rearm and combat mocks pass.
Application templates/guards are unchanged. [Exact controls and native packet](FOREVER_ROGUE_POISONS.md).

## Rogue gap/default-border correction — November 8, 2026

Horizontal Reminder button-center spacing is iconSize + iconGap, independent of
legacy cell width/image inset. Owned hand-label GetStringHeight measurements OOC
reserve wrapping space; vertical rows include their labels before the gap. No
new runtime API, combat layout or action dispatch path is added. Default Quick
Access/menu borders are removed; one-time stock-only migration retains custom
sizes/colors and all border controls. Legacy inset keys remain stored but unused.
True-gap numeric fields, bounds, migration/custom retention, Edit Mode, poison
actions and charge tests pass; native visual layout still needs owner review.
