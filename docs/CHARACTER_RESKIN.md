# Reskins: character-panel pilot

November 10, 2026. Phase one only; native visual/interaction acceptance pending.
Validation: 37 regression scripts pass across the full run and focused reruns
(the initial new-page layout declaration failure was corrected). Final targeted
checks cover lifecycle ownership, combat deferral, restricted/missing values,
poison identification independent of Rogue enable state and profile validation.
Release build verifies 121 Lua chunks / 223 package files. These are local static
and mocked results, not in-game acceptance.
Reskins contains Character Panel plus explicit planned Damage Meters and Chat
Window pages. Planned pages have no enable switch or runtime skin. Character
Panel defaults off and works independently of the chosen configuration theme.
Existing profiles and all previous module behavior remain owned by their modules.

## Design and implementation

The default graphite surfaces (#2A2A2A/#353535), cyan (#00F0FF), muted white
(#D4D4D4), restrained hairlines and existing ModeSurface/ModePageDetail assets
come from the accepted Mode design. This is original implementation code;
EllesmereUI is neither required nor copied. Its published skinning API was
reviewed as a reference for cosmetic ownership and preserving native controls.
No license was found at its root LICENSE URL, so no code/assets were taken.

CharacterReskin.lua owns settings, cosmetic snapshots and lifecycle;
CharacterReskinData.lua owns guarded player-stat and enhancement presentation;
Config/Reskins.lua exposes Options, Text, Appearance, Borders and Position tabs.
The skin changes native decoration alpha/fonts, adds noninteractive surfaces
behind native slot icons, and creates text only. Native slots, item tooltips,
drag/equip actions, model controls, tab switching, frame geometry and stats
calculations stay Blizzard-owned. Snapshots restore when disabled or leaving
the paper doll. Combat changes/restoration wait for PLAYER_REGEN_ENABLED.
No OnUpdate, timers, equip actions, SavedVariables replacement or Retail edits.

Fonts, font size, outline/shadow, text and effect colors are configurable.
Quick stats have top anchors, alignment, width and integer X/Y sliders;
enhancements have side-aware alignment, width and X/Y sliders. Surface media,
foreground/background opacity and colors are separate. Border media, size,
opacity, padding, color and X/Y offsets are configurable; the default inner
border edge begins at the target's outside edge. Media menus expose registered
SharedMedia assets; unregistered client files are not enumerable. Missing media
falls back safely without replacing the saved selection.

Stats: Strength, Agility, Stamina, Intellect, Spirit, Armor, Attack Power,
Holy Spell Power, Healing, Melee/Spell Crit, Melee Hit, Melee/Spell Haste,
Expertise, Dodge, Parry and Block. Holy is labeled explicitly; school-specific
spell power is not claimed to be an aggregate. Values refresh only outside
combat while open; unavailable values show an em dash.

Only typed permanent-enchantment tooltip lines produce permanent labels.
Base item stats are excluded. English effects summarize recognized stats
(for example Str / Agi); localized/unrecognized effects retain two words rather
than inventing a stat. A nonzero item-link enchant without readable tooltip
shows amber Unknown. Weapon imbues use Forever's C_Item.GetWeaponEnchantInfo;
known poison names come from native spell icons, with Imbue as a safe fallback.
Green denotes permanent enchants and lavender denotes imbues. Colors are editable.
No DPS weights or gear recommendations are calculated.

## Native validation

Use `/reload` outside combat after the local candidate is installed. Keep other
character skinning disabled for the pilot. No full client restart is expected:
the addon is already loaded and no new media files were introduced.

1. **Navigation:** `/ptg` → Reskins → Character Panel → header toggle (beside
   Disabled). **Action:** enable, then open WoW's Character Info → Character.
   **Required state:** OOC. **Confirmation:** Mode graphite/cyan surfaces,
   visible equipped icons, readable stats, enchant text beside applicable items.
2. **Navigation:** Play The Game Tools → Reskins → Character Panel → Text →
   Text Font / Font Size / Text Outline / Text Shadow / Text Color → Pick.
   **Action:** change each and cancel a color change once. **Required state:**
   OOC, character sheet open. **Confirmation:** fonts/color update; cancel
   restores the preceding color; other addon displays retain their appearance.
3. **Navigation:** Play The Game Tools → Reskins → Character Panel → Position →
   Quick Stats Anchor / Quick Stats Alignment / Quick Stats X Offset /
   Quick Stats Y Offset / Enhancement X Offset / Enhancement Y Offset.
   **Action:** adjust placement. **Required state:** OOC. **Confirmation:**
   list and effect labels move; no equipment button moves or loses its tooltip.
4. **Navigation:** Play The Game Tools → Reskins → Character Panel → Appearance
   → Surface Texture / Background Opacity / Foreground Opacity; Borders →
   Border Media / Border Padding / Border X Offset / Border Y Offset.
   **Action:** try a registered texture/border and offsets. **Required state:**
   OOC. **Confirmation:** changes render without hiding icons or interactions.
5. **Navigation:** WoW Character Info → Character → an enchanted equipment slot.
   **Action:** compare label to its tooltip; replace gear or apply/remove a
   poison through your usual controls. **Required state:** OOC. **Confirmation:**
   labels reflect the native effect, multiple stats remain listed, base item
   stats are not mislabeled. Unknown/Imbue remain explicit where data is missing.
6. **Navigation:** WoW Character Info → Character → stats sidebar / model /
   equipment slots / other Character Info tabs. **Action:** scroll stats,
   rotate model, inspect/equip an item, switch tabs and return. **Required
   state:** OOC. **Confirmation:** native actions still work; other tabs restore
   native shell art; returning reapplies the skin. Compare list values to
   native stats; melee and spell percentages are intentionally separate.
7. **Navigation:** Play The Game Tools → Reskins → Character Panel → header
   toggle. **Action:** disable, then `/reload`; repeat with a disable during
   combat if practical. **Required state:** restoration waits for OOC.
   **Confirmation:** original decoration/fonts return, custom labels disappear,
   preferences survive reload, no Lua errors. Unchanged modules still work.
8. **Navigation:** Play The Game Tools → Reskins → Damage Meters / Chat Window.
   **Action:** open each. **Required state:** OOC. **Confirmation:** clearly
   planned, no enable control or changes to those windows.

Static regression/mocked lifecycle checks cannot establish Blizzard security
behavior, native overlap, localized effect parsing, scrolling or appearance.
Review the first in-game screenshots before expanding this pilot.
