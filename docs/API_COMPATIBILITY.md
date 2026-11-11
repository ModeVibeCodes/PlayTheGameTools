# Forever API compatibility notes

## Character-panel reskin pilot — November 10, 2026

Reviewed the [Forever CharacterFrame XML](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_UIPanels_Game/Camelot/CharacterFrame.xml),
[PaperDoll XML](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_UIPanels_Game/Camelot/PaperDollFrame.xml),
[stats implementation](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_UIPanels_Game/Camelot/PaperDollFrameStats.lua),
[typed tooltip lines](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/TooltipInfoSharedDocumentation.lua)
and [weapon enchant API](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemDocumentation.lua).
CharacterFrame.LeftPaneHost/RightPaneHost, PaperDollFrame.TopBackgroundStripHost
and CharacterModelScene are Forever-specific, not Retail assumptions. Pooled
stats refresh uses the inspected ScrollBoxOnUpdate method when available.
Only ItemEnchantmentPermanent lines are read as permanent enchants;
C_Item.GetWeaponEnchantInfo uses WeaponSlot and ItemEnchantType.Imbue.
No assumed temporary-tooltip line enum or copied Retail enchant database.
Missing or restricted stats show —; unreadable enhancements are hidden. All reads
and cosmetic writes pause in combat. Alpha/font snapshots restore OOC; native
equipment scripts/anchors remain untouched. Local mocks are not evidence of
native support, secure interaction, localization or visual parity. See
[pilot details and exact checks](CHARACTER_RESKIN.md).

Screenshot refinement also inspects Forever's
[model control template](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_SharedXML/ModelSceneControlFrame.xml)
and [portrait/title mixins](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_SharedXML/PortraitFrame.lua).
Chrome styles the existing model buttons, PaperDollSidebarTab1–4,
RightPaneToggleButton and CloseButton without replacing native scripts or
checked state. Portrait/title geometry is snapshotted/restored OOC. Rarity uses
the same GetInventoryItemQuality read as PaperDollItemSlotButton_Update;
GetItemQualityColor supplies the color, with a neutral fallback. Ammo's count,
icon and cooldown are preserved while only its bevel/arrow decoration is faded.
Quick stats now use separate rows in an addon-owned frame outside the model
scene, anchored TOPLEFT to CharacterHeadSlot TOPRIGHT. This corrects the native
single-line/clipping result that was not represented by the original mock.

## mode small-control rendering

Owner screenshots showed square checkbox/toggle windows despite rounded source
art. The previous checkbox runtime canvas was 24×24. It is now resampled to
32×32, with power-of-two dimensions enforced for every mode runtime asset.
Checkboxes and fixed-size switches use full RGBA sprites and deliberately do not
call SetTextureSliceMargins. Panel/button slicing remains unchanged. Fresh small
control paths avoid retaining the prior client texture cache. Custom global
borders do not replace these small silhouettes with rectangular frames.

Blizzard's [texture slice schema](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_SharedXML/UI.xsd)
and [native texture-slice usage](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_AuraContainer/Blizzard_AuraContainerUtil.lua)
were inspected; no new or guessed texture API was introduced. These changes
address concrete asset/geometry issues but do not prove which native condition
caused each screenshot. Mock geometry/alpha checks are not native acceptance.

Disabled-provider media discovery uses C_AddOns.DoesAddOnExist plus supplied
C_UIFileAsset.IsKnownFile paths; it never loads/enables providers. The latter API
does not guarantee loose-file openability. WoW exposes no arbitrary addon-file
listing here: known-path metadata plus an account LSM registration cache provide
bounded discovery, with native rendering still pending. See [Global Settings](GLOBAL_SETTINGS.md).

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

## Rogue Quick Access dismissal (2026-11-10)

The existing ordinary launcher Button now registers LeftButtonUp/RightButtonUp.
Right release changes only runtime visibility/menu state outside combat. It is independent of the Reminder dismissal toggle,
and the explicit Dismiss Quick Access settings button invokes the same method. Preview/Edit Mode ignores dismissal for layout.
Native item buttons, action attributes and combat guards are unchanged; no new
gameplay API or saved fields. Mock checks establish behavior in the harness only;
owner validation of native clicks/rendering remains pending.
