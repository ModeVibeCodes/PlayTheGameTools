# Gameplay Enhancements — Campfire Monitor

## Scope and interface

November 7, 2026. Questing & Leveling → Gameplay Enhancements now contains two
feature tabs: **Loot Sparkles** and **Campfire Monitor**. The existing header
toggle remains the Gameplay Enhancements master. Each tab has its own enable
switch beneath that master. Existing `modules.lootSparkles.enabled` and sparkle
preferences are preserved; `sparklesEnabled` defaults true to retain their prior
behavior. New `modules.lootSparkles.campfire.enabled` defaults false. This follows
the existing Quick Access/Food Bar subfeature lifecycle without changing shared
navigation, the module registry, compatibility identifiers or SavedVariables.

Campfire Monitor displays the native proximity status with an optional campfire
icon and text. It shows **Camp Buffs**, using compact native-value stat lines by default, with full native text available, and optional **Nearby camp (native)** details.
An optional twelve-profession guide explains possible contributions.

**Limits:** earned Camp Benefits can include previous camps. They do not prove a
fire is currently close. Neither these auras nor the inspected supported APIs
provide a complete inventory of objects at the current campsite. The guide is
not such an inventory; vendors/workstations with no player aura cannot be
discovered by scanning buffs. No coordinates, distance estimates, map pins,
automatic sitting, object scans, buff granting or public messages are included.

## Research and implementation strategy

The owner reported the existing Loot Sparkles feature appears to work with
functioning features. This is scoped positive feedback, not acceptance of every
prior test case. The new tab layout and Campfire Monitor need native validation.

Primary-source research:

- [Blizzard camping overview](https://news.blizzard.com/en-us/article/24301516/gather-around-the-campfire-in-world-of-warcraft-forever)
  describes profession contributions, class-buff exclusions and resting/crafting
  to earn their effects. The guide summarizes effects without fixed amounts;
  actual native amounts belong to the player's tooltip.
- [Classic UnitAura documentation](https://github.com/Gethe/wow-ui-source/blob/classic/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitAuraDocumentation.lua)
  documents `C_UnitAuras.GetAuraDataByIndex(unit, index, filter)`.
- [Blizzard tooltip accessors](https://github.com/Gethe/wow-ui-source/blob/classic/Interface/AddOns/Blizzard_SharedXMLGame/Tooltip/TooltipDataHandler.lua)
  register `GetUnitBuffByAuraInstanceID` and `GetUnitAura` accessors. The installed
  camp reader confirms the former's player/instance usage on Forever.
- [Forever Forge](https://github.com/crumpshot-forever/ForeverForge), MIT,
  `Modules/CampfireAlert.lua`: inspected to verify the proximity aura and the
  distinction between presence and earned benefits. No code/assets copied.
- Installed **NaowhForever_Combat 1.2.15**:
  `AuraBuffs/Data/Campfire.lua` identifies native spells; `AuraBuffs/CampReader.lua`
  demonstrates that Camp Benefits' tooltip contains player bonus details.
  `NaowhForever/LICENSE.md` reserves rights for original code. No source, assets,
  parsing rules, alias catalogs or implementations were copied. Reference sources
  remain untouched. Native spell IDs/API facts informed independent code.

Verified reference identities, still requiring client acceptance here:

| Native aura | Spell ID | Meaning |
| --- | --- | --- |
| Campfire Nearby | 1283391 | Sole proximity signal |
| Camp Benefits | 1229741 | Earned bonuses; never proximity evidence |
| Welcoming Campfire | 1229739 | Native resting state |
| Welcoming Campfire while crafting | 1289723 | Native crafting/resting state |

The reader does not identify buffs by English names. Instance-ID tooltips are
preferred, with documented indexed player/HELPFUL fallback when that accessor is
absent. Compact Buff Text shortens unambiguous English descriptions using actual native
amounts. Localized, unfamiliar or ambiguous descriptions remain native text.
No fixed guide amounts are substituted or assigned to unverified nearby objects. Secret fields, API errors and missing
data are skipped. Complete public scans prove absence; an incomplete scan does
not prove missing benefits. Bounded scans end at 255 auras. Missing APIs show an
availability message rather than a fabricated success.

`Modules/CampfireMonitor.lua` owns pure settings/defaults, aura reading and the
subfeature lifecycle. `Modules/CampfireMonitorDisplay.lua` owns an unprotected,
draggable display. `Config/CampfireMonitor.lua` supplies its section in the common
Gameplay Enhancements page. The three files load before configuration/startup in
the TOC. There is no external addon runtime dependency.

Player-filtered UNIT_AURA plus world/combat events drive updates. There is no
campfire aura polling. A separate one-second presentation driver refreshes only
visible countdown labels while native timing is readable; it stops when hidden,
disabled, paused or using a static sample. Combat display defaults off and performs no aura reads while
paused. Optional Show In Combat uses the same public-value checks; unavailable
data clears proximity rather than retaining a stale nearby claim. The locked
display is click-through. Dragging/settings changes and preview require OOC.
Preview is explicitly synthetic and ends on tab navigation, page close, combat
or master disable. It is never stored as a real aura or saved enabled state.

## Current controls and duration behavior

The owner still saw a duplicate timer and requested removal of the addon timer.
There is now **no custom countdown label, timing loop or timer color/threshold
control**. Native tooltip duration text remains under the stats. The reader still
removes the gained-benefits intro and spell-ID metadata. Stored legacy timer
preferences are left untouched but are inert; no SavedVariables file is edited.

Customization groups are compact and separated by window:

- **General:** enable, combat behavior, status, Tools → Open Edit Mode / Refresh
  Status, Preview & Placement → Preview / Move Windows, shared text/header colors
  and optional Header Gradient. Refresh Status is a small secondary button;
  there is no Native Camp Data field. General header styling serves buffs; Contributions now has independent styling.
- **Campfire Icon:** icon/status/detail/guide visibility, lock, icon and status
  text size, window width/scale/opacity/background, X/Y and Reset Position.
- **Camp Buffs:** earned bonus visibility, compact formatting, detach/lock,
  typed stat colors, fixed Crit/Int colors, buff font size, detached window
  width/scale/opacity/background/X/Y and Reset Buff Position. Buff font size
  applies in joined mode too; joined size/background/position share the icon frame.
- **Camp Contributions:** popup switch, Detected Kits with small Refresh button,
  Open Contributions / Preview Contributions, Edit Contributions / Reset Position,
  and its own scale/opacity/background. See [contributions](CAMP_CONTRIBUTIONS.md).

Toggle grids use two columns, wrapping to one on narrow layouts. Color **Pick**
opens the native wheel; hex entry remains available. Crit red/Int blue and distinct
other stat colors remain defaults. Turning Color Stats by Type off uses shared
Text Color. Optional header gradient defaults off. The icon stays centered above
Campfire Nearby / No Nearby Campfire; no unsupported yards or arrow.

## Exact native checks

1. **Navigation:** /ptg → Questing & Leveling → Gameplay Enhancements → Campfire
   Monitor → General → Enable Campfire Monitor; Camp Buffs → Show Your Camp
   Benefits / Compact Buff Text / Separate Buff Window.
   **Action:** /reload, enable parent/monitor, inspect earned buffs in compact/full
   and joined/separate modes. **Required state:** OOC, actual earned Camp Benefits,
   preview off. **Confirmation:** Camp Buffs followed by stats and native tooltip
   duration only; no extra addon countdown above the list or update loop.
2. **Navigation:** same tab → General → Preview & Placement → Preview; General →
   Header Color → Pick / Header Gradient; Camp Buffs → Color Stats by Type.
   **Action:** preview and change/cancel colors. **Required state:** OOC, enabled
   parent/monitor. **Confirmation:** wheel works for shared/header colors, samples have no timer, and
   chosen colors/gradient apply and survive reload; typed Crit/Int stay red/blue.
3. **Navigation:** same tab → Campfire Icon → Icon Size / Status Text Size / Icon
   Window Scale; Camp Buffs → Buff Text Size / Buff Window Scale / Separate Buff Window.
   **Action:** adjust each window's controls. **Required state:** OOC, preview or
   earned buffs visible. **Confirmation:** icon controls style the monitor; buff
   font works joined or detached, and detached styling is independent.
4. **Navigation:** same tab → General → Tools → Open Edit Mode; Campfire Monitor /
   Camp Buffs / Camp Contributions handles; Edit Mode → X Position / Y Position →
   Exit / Save. **Action:** drag/adjust eligible elements, save and reload.
   **Required state:** OOC, monitor enabled, Separate Buff Window on for buff handle,
   Show Contribution Popup on for contribution handle.
   **Confirmation:** saved positions remain; contribution sample is visible/inert,
   joined buffs have no separate handle, and aura refreshes do not interrupt drag.

## Validation and known limits

tests/campfire_controls.py includes a scoped real-client-like geometry fixture:
unanchored top-level frames have no GetCenter until positioned. It verifies the
contribution preview constructs only after a valid anchor, with icon/title/size,
appearance controls, handles/header drag, detected kits and native picker intent.
tests/campfire_editmode.py verifies the absence of a custom timer/driver, native
duration retained once, joined/detached/full-text behavior, stat styling and saved
positions. Also run campfire_movement.py, loot_sparkles.py, smoke.py and the builder.
Static tests do not establish native rendering or hardware item use. Owner confirms
contribution detection is correct; visual correction and item placement still need
in-game confirmation. Screenshots: pending.

## Contribution edit and fixed-palette follow-up
+
+The owner confirms the contribution panel now generates, but reported all editing
+options ineffective. A fractional drag could leave non-integer managed offsets;
+the callback rounded a copy rather than the actual managed record, and later
+refreshes copied fractions into integer-only settings. Subsequent customization
+validation then failed. The actual managed coordinates are now rounded, and
+legacy finite in-range contribution offsets are normalized to the nearest pixel
+without resetting position. Placement applies only after the panel is shown.
+
+The contribution subject uses MEDIUM strata in Edit Mode so it cannot cover the
+DIALOG edit workspace; it returns to DIALOG for normal/live preview. Actual
+numeric/slider callbacks snap valid inputs to supported steps. Individual Crit
+Color and Int Color controls are removed; typed stats use the existing fixed
+palette (Crit red, Int blue), ignoring old per-stat customization values while
+preserving stored settings. Shared Text Color and header styling remain available.
+
+**Navigation:** /ptg → Questing & Leveling → Gameplay Enhancements → Campfire
+Monitor → Camp Contributions → Contribution Window → Preview Contributions;
+Contribution Scale / Contribution Opacity / Contribution Background; Contribution
+Position → Edit Contributions; Edit Mode → X Position / Y Position → Exit / Save.
+**Action:** /reload, preview, change each appearance slider and numeric field,
+drag at a non-100% scale, change opacity again, edit X/Y, save and reload.
+**Required state:** OOC, parent/monitor/popup enabled.
+**Confirmation:** every change applies; input rounds to its slider step; settings
+still work after dragging; workspace controls are accessible and saved position
+survives. Under Camp Buffs, Crit/Int pickers are absent and typed colors stay fixed.
+
+tests/camp_contributions_editing.py exercises those actual controls, fractional
+drag followed by another edit, legacy-offset normalization, layering, hidden
+reopen/reset and persistence. Native editing acceptance/screenshots remain pending.
+
## Contribution customization suite and quick jumps
+
+**Jump To** is a full-width button strip near the top of Campfire Monitor:
+**Monitor**, **Camp Buffs**, **Contributions**. Each scrolls to its existing group
+and highlights it, using the shared page Reveal behavior. Module Elements briefly
+identifies the nearby-fire monitor, earned bonuses and profession contribution
+popup. These controls do not add extra feature tabs or stop a contribution preview.
+
+Contribution appearance is now independent of the icon/buff windows:
+
+- **Camp Contributions:** existing scale/opacity/background opacity and live,
+  preview, edit, detection and reset-position controls.
+- **Contribution Window Style:** lock, title/hint/footer visibility, width,
+  padding, border size/color/opacity, background color, X/Y offsets.
+- **Contribution Text:** interface-font inheritance or Game/Chat/available media
+  font, outline, independent title gradient/colors, size/color for title, kit
+  name, profession/count, Place, hint, footer and Dismiss; title/row alignment.
+  Selecting a font disables interface inheritance automatically. Native kit
+  identities/content are retained; styling never substitutes item data.
+- **Contribution Icons & Rows:** icon/name/profession/count/Place visibility,
+  native tooltips, icon size/opacity, row height/spacing, visible row count,
+  row and hover colors/opacities. If both icons and names are disabled, the kit
+  name remains for identity. Row height grows to fit the selected icon/fonts.
+
+Preview and live rows call one style/layout implementation; sample rows remain
+inert and visibly marked Preview. Dismiss remains available even if the title
+is hidden. Lock applies to the ordinary live header; preview/Edit Mode can still
+move the window. Scroll distance and viewport height follow actual styled rows.
+Oversized configurations scale to the screen. Changes are OOC; position safety,
+fractional-offset migration, bounded registration retry and native click dispatch
+are unchanged. No shared infrastructure or Retail changes.
+
+1. **Navigation:** /ptg → Questing & Leveling → Gameplay Enhancements → Campfire
+   Monitor → Jump To → Monitor / Camp Buffs / Contributions.
+   **Action:** click each button. **Required state:** config open.
+   **Confirmation:** the corresponding Campfire Icon / Camp Buffs / Camp
+   Contributions heading scrolls into view and highlights.
+2. **Navigation:** same tab → Camp Contributions → Contribution Window → Preview
+   Contributions; Contribution Window Style → Contribution Width / Contribution
+   Padding; Contribution Text → Contribution Font / Title Text Size / Kit Name
+   Color → Pick; Contribution Icons & Rows → Kit Icon Size / Contribution Row Spacing.
+   **Action:** preview, adjust the named fields, choose/cancel a color, select a
+   font and compare with live kits at a real fire. **Required state:** OOC, enabled
+   parent/monitor/popup; live comparison requires a ready learned-profession kit.
+   **Confirmation:** chosen window/text/icon/row styles apply in both modes;
+   Preview has no item action, live Place still uses native click/targeting.
+3. **Navigation:** same tab → Contribution Window Style → Lock Contribution
+   Window / Contribution Horizontal Offset / Contribution Vertical Offset;
+   Contribution Text → Title Alignment / Row Text Alignment.
+   **Action:** change offsets, alignment, lock, then reload and reopen preview.
+   **Required state:** OOC. **Confirmation:** settings/position persist; a live
+   locked header does not drag, while preview/Edit Mode remains movable.
+
+tests/camp_contributions_appearance.py checks actual jumps/width input/color
+picker/font choice plus all styling categories, preview/live parity, scrolling,
+native action retention, profile validation and persistence. Native rendering,
+readability at extreme sizes and screenshots remain pending owner confirmation.
+
## Owner acceptance and merge closeout

Owner accepted the latest UI/customization with "Looks good" and requested the
feature branch be merged to main. This supersedes pending appearance acceptance
for the reviewed layout; it does not assert every native placement/combat case
was tested. Current main reconciliation preserves its Modern contrast and
Recruitment simplification changes; only changelog entries conflicted.
