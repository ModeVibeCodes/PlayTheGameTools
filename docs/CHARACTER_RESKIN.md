# Reskins: character-panel pilot

November 10, 2026. Character Panel is the only implemented reskin. Damage Meters
and Chat Window are explicitly planned pages with no runtime enable switch.
The pilot is opt-in, works under every configuration theme and preserves settings.

## Screenshot refinement

The owner confirmed a native start and supplied screenshots showing overlapping
settings tabs, clipped quick stats and leftover Blizzard artwork. This refinement
awaits native confirmation; the first screenshot is not acceptance of the changes.

- Reserve the strip height plus 12 units before the settings scroll viewport and
  scrollbar. The fix belongs only to this page; other module layouts stay intact.
- Use the Mode navigation material (ModeSurface tinted #232323), without the
  page-detail overlay, for the character panel and stats background. Remove the
  stats pane's race art, stock frame and the right-pane bronze divider.
- Place quick stats in a noninteractive frame above the model scene, with 18
  separate text rows. Its top-left is anchored six units right of the helm slot's
  top-right. Gap, Y offset and width remain adjustable. Old screen/model-relative
  placement fields are retained in saved profiles but no longer drive the list.
- Retain native buttons and their scripts, tooltips, checked state, availability
  and hit rectangles. Replace only their faces: graphite, thin gray edges, cyan
  hover/selection, compact text glyphs for zoom/rotate/reset/close. Sidebar icons
  retain their native meaning. Native model-control visibility is unchanged.
- Add two-unit, full-color rarity edges around actual equipment icons. The size
  is adjustable. Common/empty/unreadable quality uses neutral gray. Refit ammo to
  its icon bounds, fading only stock bevel and arrow; preserve count/cooldown.
- Shrink the native portrait to 28 units with a thin Mode border. Center the name
  inside equal title margins at 15 units. Portrait/title/close geometry and native
  fonts/decoration restore on disable or leaving the paper doll, outside combat.
- Hide unreadable enhancement labels, including unknown weapon imbues. Remove
  Unknown Enhancement Color. Recognized permanent bonuses remain green; known
  poisons remain lavender; readable proc names retain a short name.

No reference-addon code or assets were copied. EllesmereUI's published API was
reviewed for cosmetic ownership only. The implementation uses inspected Forever
UI definitions; see API_COMPATIBILITY.md. Existing Mode artwork is reused, so no
new texture files or client restart are expected.

## Relevant settings

Options: Show Quick Stats, Show Enhancements, Status.
Text: Text Font (SharedMedia), Font Size, Text Outline, Text Shadow, Text Color,
Enchant Color, Weapon Enhancement Color, Character Name Size.
Appearance: Panel Color, Panel Opacity, Class Icon Size, Item Rarity Border Size,
Control Accent Color.
Borders: Panel Border Size, Panel Border Opacity, Panel Border Color.
Position: Quick Stats Gap, Quick Stats Y Offset, Quick Stats Width,
Enhancement X Offset, Enhancement Y Offset, Enhancement Width.

Generic surface-media, foreground-opacity, border-media/padding/shift and quick
stats anchor/alignment controls are removed from this pilot. Their earlier stored
values are preserved for profile compatibility. The panel always uses the Mode
navigation texture; only the relevant panel tint/opacity and edges are exposed.

Stats: Strength, Agility, Stamina, Intellect, Spirit, Armor, Attack Power,
Holy Spell Power, Healing, Melee/Spell Crit, Melee Hit, Melee/Spell Haste,
Expertise, Dodge, Parry and Block. Values refresh OOC while open; unavailable
stats use a dash. No DPS/stat weights are computed. Only typed permanent-enchant
lines are summarized; base gear stats are excluded. Unknowns stay hidden.

## Native validation

1. **Navigation:** `/ptg` → Reskins → Character Panel → Options.
   **Action:** OOC `/reload`, then inspect Options and each pill tab.
   **Required state:** OOC, pilot enabled through its header toggle.
   **Confirmation:** no checkbox/field appears behind or above the pill strip;
   switching tabs and scrolling still reaches every displayed setting.
2. **Navigation:** WoW Character Info → Character → helm slot/model window.
   **Action:** open the sheet; inspect the entire quick-stat list.
   **Required state:** OOC, Show Quick Stats enabled.
   **Confirmation:** all rows render, left-aligned immediately beside the helm,
   without covering its icon. Compare values to the native stats pane.
3. **Navigation:** Play The Game Tools → Reskins → Character Panel → Position →
   Quick Stats Gap / Quick Stats Y Offset / Quick Stats Width.
   **Action:** adjust each. **Required state:** OOC, character sheet open.
   **Confirmation:** only the text list moves/resizes; its left edge stays
   outside the helm. Native equipment buttons retain their anchors/tooltips.
4. **Navigation:** WoW Character Info → Character → model controls / sidebar
   icon buttons / collapse arrow / close button.
   **Action:** hover and click; rotate/zoom/reset, change sidebars, collapse/
   expand, and close/reopen. **Required state:** OOC; model controls retain their
   native hover visibility. **Confirmation:** Mode faces, visible hover/selection
   and the original native actions. Inspect the smaller bordered class portrait
   and vertically/horizontally centered, larger character name.
5. **Navigation:** WoW Character Info → Character → equipment / ammo slots /
   stats sidebar. **Action:** inspect items of different quality, hover ammo,
   scroll stats and switch sidebar tabs. **Required state:** OOC.
   **Confirmation:** strong rarity edges fit icons; ammo has a compact matching
   border with its count/cooldown intact; stats use the dark navigation material
   without the stock bronze/race background. Native interactions still work.
6. **Navigation:** Play The Game Tools → Reskins → Character Panel → Text /
   Appearance / Borders. **Action:** change font, name size, panel color/opacity,
   portrait size, rarity border size and panel border controls; cancel a picker.
   **Required state:** OOC. **Confirmation:** only relevant panel elements change;
   cancel restores its prior color; no Unknown Enhancement Color control exists.
7. **Navigation:** WoW Character Info → Character → enchanted equipment slot.
   **Action:** compare visible labels to native tooltips, replace gear and
   apply/remove a poison normally. **Required state:** OOC.
   **Confirmation:** known effects update; unreadable effects produce no label,
   and base item stats are not mistaken for enchants.
8. **Navigation:** Play The Game Tools → Reskins → Character Panel → header toggle.
   **Action:** disable, switch Character Info tabs, return, re-enable and reload.
   **Required state:** restoration waits for OOC if disabled in combat.
   **Confirmation:** original art/fonts/portrait/name/button geometry restore;
   custom text disappears, and enable/reload preserves preferences.

## Validation limits

All 37 local regression scripts pass. The release builder passes with the
current candidate, and the focused checks were rerun after the final cleanup.

Regression fixtures cover tab separation, individual helm-relative rows, rarity
edge geometry/colors, ammo decoration, native click-handler preservation,
portrait/title restoration, restricted/missing enhancement suppression, combat
restoration and profiles. The package has 122 Lua chunks / 224 files. Static and
mocked checks do not establish native appearance, secure interaction, overlap,
localization or performance; inspect this candidate before another reskin phase.
