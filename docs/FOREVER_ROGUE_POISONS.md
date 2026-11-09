# Rogue class tools

November 8, 2026, layout revision on `codex/rogue-tools-layout`. The owner confirmed
the previous inventory-backed application version working in quick testing; that
confirmation does not cover this revision's layout, dismissal or shared Edit Mode
changes. New native acceptance is pending. A new PR is requested; no main merge
or release publication is authorized by this task.

## Current configuration

`/ptg` -> **Class Tools** -> **Rogue**. The category tab includes the native Rogue
class icon. The page header uses the icon in place of the Rogue title and keeps
the standard Enabled/Disabled module switch. Its two-sentence description explains
Poison Reminder and Quick Access Poisons. Other module headers retain their titles.

The page has exactly three sections in this order:

| Section | Controls |
| --- | --- |
| **Display** | **Poison Reminder**, **Quick Access Poisons**, **Reminder Visibility**, **Quick Access Visibility**, **Reminder Threshold (min)**, **Right-click to Dismiss**, **Customize Reminder**, **Customize Quick Access** |
| **Settings** | Six poison tiles: **Recent**, **Instant**, **Deadly**, **Crippling**, **Mind-numbing**, **Wound** (localized native first words); **Refresh Poisons**, **Restore Dismissed**; current status |
| **Position** | Separate enabled-element groups for Poison Reminder and Quick Access Poisons, each with **Enter Edit Mode**, **Reset Position**, **Lock Position**, and paired **X** / **Y** sliders |

Reminder Visibility offers **When Needed**, **When Needed (OOC)**, **Always Outside
Combat**, and **Always, Including Combat**. Quick Access Visibility offers **When
Needed** or **Always Outside Combat**; its menu/actions remain OOC only. The existing
module master must be enabled for either display to run. Disabling an element hides
its Position group and removes its shared Edit Mode highlight/selection eligibility.

Primary icon controls are directly visible in Display under **Poison Reminder
Icons** and **Quick Access Poisons Icon** whenever that element is enabled. Both
provide **Icon Size**, **Icon Padding**, **Icon Border Size**, and **Icon Border
Color**. Reminder icons also expose **Icon Spacing**; Quick Access exposes **Icon
Opacity**. Text and window editors stay behind the Customize buttons. Quick Access's **Customize** selector offers **Icon and
Label** or **Expanded Menu**. Numeric sliders pair where width permits, cap at
260 UI units per cell, and wrap on smaller canvases. Control values remain precise
through the standard numeric fields. There are no extra top-level appearance tabs.

### Appearance

Poison Reminder now defaults to **icons and hand labels only**, with background
opacity 0, border size 0, timers/counts/names off. The unchanged original v2 preset
migrates to that minimal presentation; customized styles and unknown keys remain.
The **Minimal** button inside Customize Reminder explicitly restores only that
presentation without resetting size, font, color, positioning or poison history.

Each icon now has its own image padding, border size/color/opacity, image opacity
and optional background color/opacity. Image padding is inset inside its button
and clamps before the texture can collapse. Reminder Icon Spacing adjusts the
separation of its hand columns; each column also reserves Cell Width for labels.
Window background/border controls are explicitly named **Window** in Customize;
individual icon borders work while the reminder window remains transparent.
The reminder retains icon size/tint/crop/visibility, scale, opacity, padding,
spacing/cell width, vertical layout, font/size/outline/color, optional hand labels,
names, inventory counts, countdown size/color/placement, background and border
color/opacity/size. Quick Access has independent icon/scale/opacity/padding, tint,
border/background, optional editable label text/font/size/color/outline/placement
and inventory total. Its expanded menu retains independent appearance, columns,
direction and scrollable visible rows. Color rows use **Pick** or hex/**Apply**.

### Poison selection and application

The grid is a **single quick-apply selection**, not an application action. Recent
follows the last successfully observed poison per character/hand. A poison-family
tile chooses that type and resolves to the best currently available carried rank,
or a genuinely known native application. The tile count aggregates carried stock
for its family. Unknown/unstocked types remain visible, desaturated and disabled;
they cannot create a pretend usable action. Each icon has the same contrasting
first-word text strip. Recent uses the native Poisons icon and text **Recent**.
The actual Quick Access menu continues to offer available exact items/known casts.

Old exact item/spell quick-apply preferences remain supported and highlight their
family in the grid. Selecting a family opts into rank availability resolution;
Recent retains exact last-use history and does not silently swap a depleted item.
Carried poison items use the native InsecureActionButtonTemplate item identifier
and inventory target slot 16/17. Blizzard owns OnClick. Left release dispatches;
no automatic applications, direct Cast/Use/RunMacro, synthetic clicks or OnClick
replacement/hooks are added. Reagent/cast/target requirements still belong to WoW.

### Dismissal

With Right-click to Dismiss on, right-click either reminder icon to hide that hand
only. This is session-only presentation state; it survives timer ticks, bag scans,
combat transitions and poison expiration into Missing. It rearms after a poison
refresh/replacement, equipped weapon change, restored data-state change, explicit
Restore Dismissed or reload. The other hand and Quick Access visibility are not
suppressed. Preview/Edit Mode reveals enabled elements and ignores dismissal.

Right-click dismissal also works on the unprotected combat display. PreClick
handles the ordinary presentation change; the native template retains its combat
guard, no right-button action/weapon-target attributes are bound, and attribute
mutation/reanchoring remain OOC. Left clicks and dragging cannot apply/move in
combat. Tooltip text explains right-click dismissal. Native confirmation is pending.

### Position ownership

`roguePoisonReminder` and `rogueQuickPoisons` register with the actual shared
Position Manager. Edit Mode shows **Rogue: Poison Reminder** and **Rogue: Quick
Access Poisons** handles/highlights and the same element picker, coordinates,
dragging, Exit and combat cleanup used by the rest of the addon. The Position
hot button opens Edit Mode and selects its corresponding element. Applications
and Quick Access menu opening stay inert during editing.

Positions live in `positions.<elementID>`, seeded once from existing Rogue x/y
preferences. Position Manager updates mirror to the legacy x/y keys for backwards
compatibility, and numeric sliders/reset feed that same shared record. Profile
changes re-register stale position references. Frames establish geometry before
registration. Explicit unlocked dragging outside Edit Mode remains supported and
stores through the shared position record; highlighted Edit Mode handles work
independently of the normal position lock. Existing live installation link and
SavedVariables are preserved; no new Lua file or TOC entry is needed for this change.

## API and validation limits

The existing [Blizzard native template](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.xml)
and [dispatcher](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.lua)
remain the application boundary. Only public inventory, player cast observations
and weapon-enchant fields are used, with missing/restricted data inert. The
[Item API](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemDocumentation.lua)
and [Container API](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/ContainerDocumentation.lua)
support carried metadata. Poison Imbue classification and timeLeft milliseconds
retain their existing native acceptance boundary. Initial active icons identify
families, not guaranteed exact ranks; ambiguous manual events do not prove an exact
last-used item/hand. No reference-addon source/assets or Retail files are changed.

`tests/rogue_icons.py` checks directly visible controls, actual numeric inputs,
spacing changes, per-icon padding/border/color/opacity/background, extreme padding
bounds, independent styles, the Minimal preset, Edit Mode and persistence.
`tests/rogue_layout.py` adds dismissal/rearm/expiration/combat cases, minimal/default
migration and custom retention, class-header restoration, six-tile availability/
selection, independent labels, responsive widths and real Position Manager
selection/decoration/drag/coordinate/reset/persistence checks. Existing
`tests/rogue_poisons.py` keeps inventory/native action/combat/history coverage and
updates its UI assertion for the new selector. Smoke constructs all pages/profiles;
Edit Mode and Quick Actions suites check the shared integration. Mocks do not
establish native rendering, target acceptance, input routing or event-order safety.

## Exact native test packet

1. **Navigation:** `/reload` -> `/ptg` -> **Class Tools** -> **Rogue**.
   **Action:** inspect the tab icon, icon-only header and description, then Display,
   Settings and Position. **Required state:** Rogue, OOC, module enabled.
   **Confirmation:** three sections in order; default reminder has icons and hand
   text without background/border/countdown/counts; customized old styles persist.
2. **Navigation:** Rogue -> **Display** -> **Poison Reminder**, **Reminder
   Visibility**, **Right-click to Dismiss**; on-screen **Main Hand** / **Off Hand**.
   **Action:** right-click one due reminder, wait/tick or change bags, then refresh
   that poison or click Settings -> **Restore Dismissed**. **Required state:** real
   equipped poison or missing poison, no Preview/Edit Mode. **Confirmation:** one
   hand hides without consuming poison; other hand remains; refresh/restore rearms.
   Repeat during combat: right-click can dismiss, left click cannot apply.
3. **Navigation:** Rogue -> **Settings** -> **Recent** / a poison-family icon.
   **Action:** select an available type; inspect the grey unstocked types; click a
   reminder separately, then return to Recent. **Required state:** OOC, actual
   carried poisons, positions locked, no Preview/Edit Mode. **Confirmation:** grid
   selection consumes nothing; reminder applies chosen available family to the
   correct hand; Recent restores last-use behavior; counts/availability refresh.
4. **Navigation:** Rogue -> **Display** -> **Customize Reminder** / **Customize
   Quick Access** -> **Customize** -> **Icon and Label** / **Expanded Menu**.
   **Action:** adjust paired size/opacity fields, font/color/border, label text ->
   **Apply**, label placement and optional counts; select **Minimal** for reminder.
   **Required state:** OOC. **Confirmation:** elements style independently, controls
   wrap at narrower sizes, Minimal removes reminder chrome/extras; reload persists.
5. **Navigation:** Rogue -> **Position** -> **Poison Reminder** or **Quick Access
   Poisons** -> **Enter Edit Mode**. **Action:** inspect both highlights, select and
   drag each handle, change X/Y, then use shared **Exit**. Back in Position, test
   **Lock Position**, X/Y and **Reset Position** independently. **Required state:**
   OOC, corresponding displays enabled. **Confirmation:** selected Rogue handle,
   shared coordinates and saved position agree; editing consumes no poison;
   normal locks do not block Edit Mode; disabled elements lose Position controls
   and Edit Mode eligibility. Reload retains positions; combat ends editing.

6. **Navigation:** Rogue -> **Display** -> **Poison Reminder Icons** -> **Icon
   Spacing**, **Icon Padding**, **Icon Size**, **Icon Border Size** / **Icon Border
   Color**. **Action:** change each numeric field; choose a border color using
   **Pick**. **Required state:** OOC, Poison Reminder enabled; use Enter Edit Mode
   from Position if reminders are currently healthy/hidden. **Confirmation:** hand
   columns separate, images inset inside their buttons, both reminder icons resize
   and gain individually colored borders; the outer window stays at its saved style.
7. **Navigation:** Rogue -> **Display** -> **Quick Access Poisons Icon** -> **Icon
   Size**, **Icon Padding**, **Icon Border Size**, **Icon Opacity**. **Action:** change
   values and border color, then /reload. **Required state:** OOC, Quick Access
   enabled; choose Quick Access Visibility -> Always Outside Combat to view it.
   **Confirmation:** only that icon changes, its size/padding/border/opacity persist,
   and its saved Edit Mode position and poison applications still work.
