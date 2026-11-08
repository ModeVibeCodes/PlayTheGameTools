# Rogue poison tools

November 8, 2026. Revision 2, available for local Forever testing on
`codex/rogue-poisons`. User confirms the first version's module/elements appear,
but application buttons produce no action. After revision 2, the owner reports
**"It is working upon quick testing!"** and authorizes merging to main on
November 8, 2026. This confirms the reported quick-test scope; broader event-order,
combat, rank/hand history, customization and persistence coverage remains bounded
by the native packet below. No public release, SavedVariables reset, Retail
change or installation-link change is part of this merge.

## Button correction

The first version only searched learned application spells. Poison consumables
in bags were never scanned or bound, leaving no usable action when the player had
items but no known application spell. The first mock assumed learned spells and
therefore did not cover that failure. Inventory-backed regression tests now start
with **zero learned application spells** and real `item:<ID>` action identifiers.

Carried poison items now use Blizzard's `InsecureActionButtonTemplate` with
`type1=item`, `item1=item:<ID>` and `target-slot1=16/17`. Genuinely learned native
application entries remain `type1=spell`. Blizzard owns OnClick and action/target
dispatch; addon PreClick records intent or explains an unavailable action. Explicit
`useOnKeyDown=false` dispatches on release independently of action-bar preferences.
No addon direct Cast/Use/RunMacro calls, replacement OnClick, automatic applications
or combat actions. Both press/release events are registered for native dispatch.

Unavailable actions now explain the reason on hover/click: missing selection,
out of stock/locked stacks, missing weapon, restricted snapshot, native template
unavailable, or positioning/preview. A rejected attempt is not saved as success.

## Controls

`/ptg` -> **Class Tools** -> **Rogue**. Enable **Poison Watcher -> Enable Rogue
Tools**, or the existing page-header switch. Default module disabled, Rogue only.

| Section | Controls |
| --- | --- |
| Poison Watcher | Enable Rogue Tools; Enable Poison Watcher; Show Watcher In Combat (on); Reminder Threshold (minutes), 5–20; Poison Status |
| Poison Quick Apply | **Poison Refresh Quick Apply:**; Inventory and Learned Poisons row -> **Refresh Poisons** |
| Poison Flyout | Enable Poison Flyout (off); **Always Show Poison Flyout** (off); Flyout Direction (Up/Down/Left/Right); Visible Flyout Rows (1–10, default 6) |
| Watcher Appearance | Icon Size, Scale, Opacity, Padding, Crop Icons, Show Tooltips, Icon Tint, Show Icons, Show Hand Labels, Show Poison Names, Show Inventory Counts, Cell Width, Icon Spacing, Label Gap, Text Size, Text Outline, Text Font, Text Color, Vertical Watcher Layout, Show Remaining Time, Timer Text Size, Timer Text Color, Timer Position, Background Color/Opacity, Border Color/Opacity/Size |
| Watcher Position | **Lock Poison Watcher**; Watcher Horizontal/Vertical Offset; Watcher Preview row -> **Toggle Poison Preview**; Watcher Screen Position row -> **Reset Watcher Position** |
| Flyout Icon Appearance | Independent Icon Size, Scale, Opacity, Padding, Crop Icons, Show Tooltips, Icon Tint, Background Color/Opacity, Border Color/Opacity/Size |
| Flyout Menu Appearance | Independent icon/text/font/color/background/border/layout controls, including Poison Columns (1–3), Show Hand Labels, Show Poison Names and Show Inventory Counts |
| Flyout Position | **Lock Poison Flyout**; Flyout Horizontal/Vertical Offset; Flyout Screen Position row -> **Reset Flyout Position** |

Color rows use **Pick** for the color wheel or the existing hex field/**Apply**.
Text Font includes game/chat and available shared-media fonts. Timer Position
offers On Icon / Above Icon / Below Labels. Appearance groups are independent;
changing the watcher does not resize/recolor the menu or launcher.

## Visibility and quick application

Watcher cells show missing poisons or durations **at or below** the threshold.
Healthy hands hide; absent/non-melee weapons have no reminder. Restricted/unknown
snapshots display inert Unknown rather than claiming missing poison. Readable
combat timers can show, with mouse/actions disabled; Show Watcher In Combat can
turn that display off. Temporary oils/stones do not count as poison Imbue entries.

The flyout launcher is the native **Poisons profession icon** (spell 2842 metadata,
native icon-path fallback), with a separate purple border by default. It appears
OOC when either hand needs attention, including missing/unknown poison, regardless
of the watcher toggle. **Always Show Poison Flyout** keeps it visible OOC while
both hands are healthy. Clicking opens the menu; it closes when no longer needed
or on combat entry and does not reopen automatically. Long menus scroll with the
mouse wheel; columns, direction and visible rows are configurable. Each poison
has Main Hand/Off Hand icons and carried counts; learned casts are labeled.

**Poison Refresh Quick Apply:** defaults to **Last Used Poison (per hand)**. Its
list includes exact carried poison types/ranks and counts, plus learned native
castable poisons. Choosing a specific entry overrides the default for both hands.
Last-use history is saved per character and hand, with the character's latest
poison as fallback for a hand with no observation. Successful public player casts
are correlated with a changed/refreshed weapon enchant before remembering the
exact item/spell. Manual bag use can also be observed. A last dose disappearing
from inventory does not overwrite history with a different rank. Restock or choose
another entry if the remembered one is unavailable; there is no silent stock swap.

For a poison already active before observation, native icons identify its family,
not necessarily its rank. Initial family seeding uses the highest carried rank
matching that icon until an unambiguous successful application is observed. Prior
manual actions cannot be reconstructed when the family is unknown. Multiple
ambiguous event/hand matches do not establish an exact last-used action. If neither
history nor an active-family match is available, explicitly choose Quick Apply or
apply through the flyout; the addon does not guess Instant Poison.

Unlock watcher/flyout independently to drag backgrounds or icons. Positioning,
Preview and shared Edit Mode signals are inert. Preview reveals the enabled
elements/menu using actual available poisons. These elements are not registered
in the shared Edit Mode picker; use the Rogue controls. Relock and stop preview
before application. Native reagent, cast-time, level and target requirements still
apply; an attempted click alone is not successful use.

## API evidence and limits

Primary Blizzard Forever sources reviewed November 8, 2026:

- [Container API](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/ContainerDocumentation.lua):
  carried bag sizes and item info; scans are OOC on enable, bag/metadata/spell
  changes or explicit Refresh Poisons. Counts aggregate unlocked carried stacks.
  Locked stacks remain listed with zero available count; bank contents are excluded.
- [Item API](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemDocumentation.lua):
  native item name/icon/effect identify carried poisons. Five localized application
  family names and a bounded classic-item family fallback are used, never crafting
  recipes. `C_Item.GetWeaponEnchantInfo` provides hasEnchant/enchantType/timeLeft/
  enchantIconID/enchantID; missing/secret/malformed observations fail visibly inert.
- [Native action template](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.xml)
  guards combat, while its [dispatcher](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.lua)
  supports item identifiers and target-slot dispatch. Attributes only change OOC.
  Unprotected frames support presentation updates in combat. Native action acceptance
  and the client's item-target cursor/cast behavior need owner validation.
- [Unit event contract](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua):
  UNIT_SPELLCAST_SUCCEEDED supplies unit/castGUID/spellID. Only OOC public player
  spellID is used; castGUID/restricted spell data are never inspected. Exact manual
  event ordering and rank/hand correlation still need native testing.
- [SpellBook](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/SpellBookDocumentation.lua)
  and [Flyout](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/FlyoutDocumentation.lua)
  provide learned/override entries. Item availability is independent of them.
- [Item constants](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemConstantsDocumentation.lua)
  distinguish weapon enums from inventory slots and Imbue from Temporary. Poison
  classification as Imbue and timeLeft milliseconds remain native validation items.

No reference-addon code/assets copied or original addon modified. Five Rogue Lua
files separate settings, lifecycle/history, inventory/readers, display and config.
One enabled-Rogue 1s ticker reads two weapon snapshots, never scans bags; it reads
nothing when both subfeatures are off and is cancelled on disable. Settings remain
under modules.foreverRogue. Legacy appearance/position values and unknown keys are
preserved; new nested styles fill missing fields. The old source/ZIP candidate is
retained under `.cache/checkpoints/rogue-v1-before-item-fix-2026-11-08` and local
build retention. No new junction/sync or live settings write is performed.

## Validation and exact native test packet

`tests/rogue_poisons.py`: zero-learned-spell inventory actions, exact native item
identifiers/weapon slots, release dispatch under both CVar preferences, native
success vs rejected attempt, manual observations, last dose, per-character history,
bag changes/cache/locks, healthy/threshold/Always Show launcher, independent styles,
combat crossing, preview, migration and persistence. The mock rejects combat
attribute mutations, OnClick replacement and OnClick hooks. `tests/smoke.py` compiles
106 chunks and checks startup, pages, profiles, wrong-client guard and deterministic
package content. Static tests/builds do not establish native acceptance.

1. **Navigation:** chat -> `/reload`, then `/ptg` -> **Class Tools** -> **Rogue** ->
   **Poison Quick Apply** -> **Poison Refresh Quick Apply:**. **Action:** inspect
   exact carried poison entries/counts; choose one. If new files fail to load, fully
   restart WoW. **Required state:** Rogue OOC, Enable Rogue Tools on, carried poison.
   **Confirmation:** items appear even without learned poison application spells;
   Refresh Poisons updates counts and no Lua error occurs.
2. **Navigation:** Rogue -> **Watcher Position** -> **Lock Poison Watcher**;
   on-screen watcher -> **Main Hand** / **Off Hand**. **Action:** relock, turn off
   Toggle Poison Preview if active, click each reminder separately and finish each
   cast. **Required state:** OOC, valid equipped weapons, chosen carried poison.
   **Confirmation:** correct one-hand native application, inventory decreases,
   refreshed reminder hides; an unavailable click explains its reason.
3. **Navigation:** Rogue -> **Poison Quick Apply** -> **Poison Refresh Quick
   Apply:** -> **Last Used Poison (per hand)**; native bags and watcher.
   **Action:** apply different poisons to each hand through the flyout or native
   bags, allow success; later click each threshold reminder. **Required state:**
   OOC applications, no Preview, both elements locked. **Confirmation:** correct
   last-used poison and hand; rejected/interrupted attempts do not replace history.
   Repeat after `/reload`; depleted poison requests restock/explicit selection.
4. **Navigation:** Rogue -> **Poison Flyout** -> **Enable Poison Flyout** / **Always
   Show Poison Flyout**; on-screen profession icon. **Action:** leave Always Show
   off with healthy poisons, observe a real threshold/missing hand, then enable
   Always Show while healthy. **Required state:** OOC, preview off, flyout locked.
   **Confirmation:** default icon hides while healthy and appears when needed;
   Always Show keeps it visible; clicking toggles the menu and hand buttons apply.
5. **Navigation:** Rogue -> **Watcher Appearance**, **Flyout Icon Appearance**,
   **Flyout Menu Appearance**, **Watcher Position**, **Flyout Position**.
   **Action:** use Toggle Poison Preview, change size/font/color/border/layout,
   unlock and drag, then relock/stop preview and `/reload`. **Required state:** OOC.
   **Confirmation:** three independent styles and two positions persist; no poison
   is consumed in preview/unlocked mode; menu direction/columns/scrolling work.
6. **Navigation:** Rogue -> **Poison Watcher** -> **Show Watcher In Combat** /
   **Reminder Threshold (minutes)**; watcher and flyout icon. **Action:** observe
   a real timer cross its threshold in combat and attempt a click; leave combat.
   **Required state:** real equipped poison near threshold; no synthetic preview.
   **Confirmation:** readable combat timer shows statically (or inert Unknown if
   restricted), no application/drag in combat, flyout hides and stays closed;
   application works OOC. Repeat with watcher combat display disabled.
