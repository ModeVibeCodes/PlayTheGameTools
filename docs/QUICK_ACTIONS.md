# Quick Actions

One on-screen button replaces the separate Class Training and Dungeon Loot icons.
Clicking it opens every available icon in a circle around it. Only that button
moves, through the shared Edit Mode, where it is listed as **Quick Actions**.

## Behavior

- While open, a solid gold ring runs through the icon centers on a dark translucent
  dial, fading in over 0.12 seconds. The main button shows its state: closed is a
  dimmed gear with a neutral edge; open is a gold gear with a gold edge and halo.
- The ring closes when an icon inside it is clicked, when the main button is
  clicked again, when combat starts and when Edit Mode is entered. Clicking
  elsewhere on the screen does not close it.
- Icons keep their own behavior, size and opacity. Dungeon Loot opens its index and
  Class Training opens its popout. The popout stays open after the ring closes,
  anchors to the main button and lights the main button while open. Recruiter
  opens or closes the Recruiter window, which keeps its own placement and lights
  the main button while open.
- Icons are spaced evenly clockwise from the top. Larger icons or longer lists
  widen the ring, and the main button's screen clamp grows so no icon opens
  off-screen.
- A disabled module or hidden icon leaves the ring. With no icons left, the main
  button and its Edit Mode entry hide. Dungeon Loot's keybinding is independent.
- Nothing opens during combat. Frames are created and laid out outside combat only.

## Saved settings

The position is `positions.quickActionsLauncher`. Its first value comes from the
Class Training icon's saved position when present; Reset Shortcut Position returns
to the factory spot. `positions.dungeonLootShortcut`, both modules'
`shortcutPosition` and Dungeon Loot's `shortcutLocked` stay in saved settings, are
still validated and are no longer read for placement.

## Adding an icon

From the owning module, outside combat:

```lua
local button=addon.QuickActions:AddAction("myAction",{order=30,texture=path,
    color={r,g,b},title="Title",hint="Click to open.",onClick=function() end})
addon.QuickActions:SetAvailable("myAction",true)
```

Use `addon.QuickActions.SizeIcon(button,size)` then `addon.QuickActions:Layout()`
to resize, and `SetActive(id,bool)` to light the main button.

The launcher has no module page, so it registers with Position Manager through the
`owner` option, and Edit Mode's Open Module Settings button is disabled while it is
selected. If registration fails, the button stays usable at its starting spot,
Dungeon Loot's General tab shows the reason, and registration is retried after
combat without building new frames.

## Native checks (pending owner confirmation)

Adding `Modules/QuickActions.lua` requires one full client restart.

1. **Navigation:** on-screen Quick Actions button. **Action:** hover it, click it,
   click it again. **Required state:** Forever, out of combat, Class Training on
   with Shortcut Icon & Menu on, and Dungeon Loot on with Show Shortcut Icon: On.
   **Confirmation:** a round dimmed gear icon with a neutral edge and a "Quick
   Actions" tooltip; the old separate icons are gone. Open shows the book and loot
   dice on a solid gold ring over a dark dial, the gear turns gold with a halo and
   stays undimmed, and the tooltip says "Click to close". Closing reverses all of it.
2. **Navigation:** Quick Actions button -> loot dice icon. **Action:** click the
   icon. **Required state:** out of combat, ring open. **Confirmation:** the ring
   closes and Dungeons opens.
3. **Navigation:** Quick Actions button -> green book icon; then the popout's
   Minimize. **Action:** click the book, confirm the popout, click Minimize.
   **Required state:** out of combat. **Confirmation:** the ring closes, the popout
   stays open beside the main button with a green glow on it, and Minimize closes
   both the popout and the glow.
4. **Navigation:** `/ptg` -> Edit Mode (header button); select the Quick Actions
   handle; panel Exit. **Action:** drag it toward each screen edge, change X/Y,
   Exit, open the ring, `/reload`. **Required state:** out of combat.
   **Confirmation:** the ring closes on entry, the button moves, every icon stays
   on-screen at the edges, Open Module Settings is disabled for this element, and
   the position survives the reload.
5. **Navigation:** `/ptg` -> Questing & Leveling -> Dungeon Loot -> General -> Quick
   Icon; `/ptg` -> Questing & Leveling -> Class Training -> Shortcut Icon & Menu ->
   Shortcut Icon Size. **Action:** change both sizes to 72, Icon Opacity to 50%, and
   set Show Shortcut Icon: Off; open the ring after each. **Required state:** out of
   combat. **Confirmation:** the ring widens without overlap, only the loot icon
   fades, and hiding it leaves one icon at the top.
6. **Navigation:** Quick Actions button -> ordinary combat. **Action:** open the
   ring, enter combat, click the button, leave combat, click it. **Required state:**
   safe ordinary combat. **Confirmation:** the ring closes on combat entry, stays
   closed in combat with no blocked-action errors, and opens afterward.
7. **Navigation:** Quick Actions button -> shouting-warrior icon (tooltip
   "Recruiter"). **Action:** click the icon, then open the ring and click it again.
   **Required state:** out of combat, Guild Tools -> Recruitment switched on.
   **Confirmation:** the ring closes each time; the first click opens the Recruiter
   window and puts a green glow on the main button; the second closes the window and
   the glow.
8. **Navigation:** `/ptgr` -> Recruiter window's on/off switch beside Settings.
   **Action:** click the switch off, open the ring, click the switch on, open the
   ring. **Required state:** out of combat, Recruitment on. **Confirmation:** the
   window stays open throughout; the Recruiter icon and glow leave while off and
   return when on.
