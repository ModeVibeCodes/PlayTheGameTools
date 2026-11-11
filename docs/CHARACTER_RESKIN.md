# Reskins: character-panel pilot

November 10, 2026. Character Panel is the only implemented reskin. Damage Meters
and Chat Window are explicitly planned pages with no runtime enable switch.
The pilot is opt-in, works under every configuration theme and preserves settings.

## Unified framing and independent displays

### Reload investigation and correction

The owner reported FontString:SetText(): Font not set at the owned title's
first creation, called through native UpdatePortrait before title text existed.
The new title wrote text before assigning its font. Gold and durability also
had that latent ordering error. These were regressions in this pilot. A strict
fixture reproduces the original title error, then passes after assigning each
font before SetText (including empty text). An enabled-profile/open-character-
panel startup fixture now completes with an empty native title and both footer
rows enabled, then mirrors the subsequently populated title.

The native divider cleanup now runs earlier than title/chrome construction,
fading only common-framedivider inside RightPaneHost. The owned name uses equal
48-unit model-pane margins, sharing the level/class heading's horizontal center
in both expanded and collapsed layouts. Native originals remain recoverable.

The separate Campfire contributionX range error was investigated against
history and both current on-disk profiles. Campfire/profile-loader source is
unchanged from pre-reskin main, and the older fractional-coordinate migration
is already present. Both profiles validate using detached copies; coordinates
are valid integers, and file hashes remain unchanged. That report is not
reproduced with current source/settings. No profile reset or validator weakening
is included. A fresh repeat remains an unresolved data/state observation.

The next owner screenshot showed doubled bright lines around nested panes and
an awkward square portrait/name header. The current framing uses one subdued
outer edge (#424242 at 70% by default). Nested canvases and stat heading plates
have no full rectangular outlines; model/name crossbars are removed. Buttons
use consistent one-unit edges with cyan reserved for hover/selection. Rarity
edges remain separate, because they communicate item quality.

The portrait is an addon-owned copy of the native spec/class texture and its
texture coordinates, masked one pixel inside a circular ModeThumb rim. Its
native texture and geometry remain intact underneath. The name also uses an
owned, centered text region with equal model-pane margins and a shared vertical
center with portrait/close controls. The hidden originals restore on disable;
secure post-hooks mirror native title/portrait updates outside combat.

The native stats scrollbar retains its track/thumb size, anchors, hit targets,
wheel/drag/step behavior and atlas state. Only native artwork is faded. Owned
art uses the same two-unit ModeScrollThumb sprite and normal/hover tint as the
addon interface, with a quiet one-unit track and small step glyphs.

Quick Stats has its own pill. Show Quick Stats, per-stat choices, font, size,
outline, shadow, color and placement are independent of panel text. Existing
profiles inherit their prior shared text style once when the new style is
missing; later edits stay separate. Hidden stats compact the list, and choosing
none hides it. The panel's master enable state still controls this module.

Options includes Show Gold and Show Durability, both default on. Gold displays
carried copper as g/s/c at the bottom-left of the model pane. Durability sits
above it (or uses the bottom row when gold is off). It is the rounded, weighted
percentage: sum of current durability / sum of maximum durability over equipped
slots 1–18 that have durability. Non-durable slots do not contribute. Missing or
restricted values display a dash; partial durability is never presented as a
complete total. Updates use native money/durability/inventory events and refresh
OOC while open, with no polling. Both rows disappear on module disable.

## Earlier screenshot refinement

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
- Default the circular portrait copy to 28 units and the centered name to 15.
  Native originals, fonts and close-button geometry restore outside combat.
- Hide unreadable enhancement labels, including unknown weapon imbues. Remove
  Unknown Enhancement Color. Recognized permanent bonuses remain green; known
  poisons remain lavender; readable proc names retain a short name.

No reference-addon code or assets were copied. EllesmereUI's published API was
reviewed for cosmetic ownership only. The implementation uses inspected Forever
UI definitions; see API_COMPATIBILITY.md. Existing Mode artwork is reused, so no
new texture files or client restart are expected.

## Relevant settings

Options: Show Enhancements, Show Gold, Show Durability, Status.
Quick Stats: Show Quick Stats, Quick Stats Font, Quick Stats Font Size,
Quick Stats Outline, Quick Stats Shadow, Quick Stats Color, Quick Stats Gap,
Quick Stats Y Offset, Quick Stats Width, Displayed Stats (18 individual toggles).
Text: Text Font (SharedMedia), Font Size, Text Outline, Text Shadow, Text Color,
Enchant Color, Weapon Enhancement Color, Character Name Size.
Appearance: Panel Color, Panel Opacity, Class Icon Size, Item Rarity Border Size,
Control Accent Color.
Borders: Panel Border Size, Panel Border Opacity, Panel Border Color.
Position: Enhancement X Offset, Enhancement Y Offset, Enhancement Width.

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
   **Required state:** OOC, Quick Stats → Show Quick Stats enabled.
   **Confirmation:** all rows render, left-aligned immediately beside the helm,
   without covering its icon. Compare values to the native stats pane.
3. **Navigation:** Play The Game Tools → Reskins → Character Panel → Quick Stats →
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

9. **Navigation:** Play The Game Tools → Reskins → Character Panel → Quick Stats
   → Displayed Stats → Strength / Agility (checkboxes).
   **Action:** hide individual stats, change Quick Stats Font Size / Quick Stats
   Color, then change Text → Font Size. **Required state:** OOC.
   **Confirmation:** the list compacts; quick-stat styling stays independent of
   panel text. Turning all stats off hides the list; toggles survive reload.
10. **Navigation:** Play The Game Tools → Reskins → Character Panel → Options →
    Show Gold / Show Durability. **Action:** toggle each separately, then earn/
    spend money or repair normally with the sheet open. **Required state:** OOC.
    **Confirmation:** gold appears at bottom left, durability above; each row
    hides independently. Amounts/condition refresh. Compare durability with the
    weighted total of worn gear, not the worst individual item.
11. **Navigation:** WoW Character Info → Character → stats scrollbar/header.
    **Action:** drag/wheel/step through stats and hover the thumb; inspect header.
    **Required state:** OOC. **Confirmation:** slim Mode scrollbar still works,
    portrait has a circular crop/rim, name is centered, and no bright crossbar
    cuts through the portrait or the model. Disable the module to check full
    native artwork/scrollbar restoration.

12. **Navigation:** `/ptg` → Reskins → Character Panel → header toggle; WoW
    Character Info → Character. **Action:** enable the pilot, leave the sheet
    open, `/reload`, reopen Character Info and `/ptg` if needed.
    **Required state:** OOC. **Confirmation:** no new Font not set/profile
    initialization errors, full chrome/footer styling, no hard native divider,
    and the name centered above level/class. Existing module pages still open.

## Validation limits

All 37 local regression scripts pass; focused checks and the deterministic
package build pass after the final cleanup. These remain mocked/static results.

Regression fixtures cover native ownership/restoration, tab separation, circular
portrait copy/mask and source coordinates, equal title margins, no nested frame
outlines, slim scrollbar artwork, independent stat filtering/styling/persistence,
gold denomination formatting, durability aggregation/updates and restricted
footer values. Static and mocked results cannot establish native appearance,
secure interaction, text overlap, cropping or scrolling. The package remains
122 Lua chunks / 224 files; no new media or client restart is expected.
