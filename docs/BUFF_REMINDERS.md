# Buff Reminders

Module `buffReminders`, title **Buff Reminders** (Quality of Life), off by
default. It warns when your class buffs, poisons, imbues, totems, group buffs
or food are missing or about to run out, and can reapply them with a click.
Every class sees only its own buffs plus the general ones (food, elixirs,
weapon oils and stones).

Status: mock-tested (`tests/buff_reminders.py` plus the full suite). Native
behaviour, secure casting and the Forever-only IDs below need in-game checks.
New TOC files: restart the client once after updating, then `/reload` out of
combat works for later changes.

## What it reminds about

| Class | Reminders (default on unless marked opt-in) | Detected by |
| --- | --- | --- |
| All | Food buff (any Well Fed or Forever food aura); Elixirs and flasks (opt-in); Weapon oils and stones (opt-in) | Aura; weapon enchant (Temporary) |
| Warrior | Battle Shout | Aura |
| Paladin | Blessing (yours, on you); Paladin aura; Righteous Fury (opt-in) | Aura, "one active" check |
| Hunter | Aspect; Trueshot Aura; Pet | "One active" check, aura, pet unit |
| Rogue | Main-hand poison; Off-hand poison | Weapon enchant (Imbue) |
| Priest | Power Word: Fortitude; Inner Fire (warns at 5 charges); Divine Spirit, Shadow Protection, Shadowform (opt-in) | Aura |
| Shaman | Main-hand and Off-hand imbue; Elemental shield (warns at 1 charge); one totem per element you pick (Air defaults to Windfury Totem) | Weapon enchant (Imbue), aura, totem slot |
| Mage | Arcane Intellect; Armor; Dampen or Amplify Magic (opt-in) | Aura |
| Warlock | Demon Armor (or Skin); Demon; Soulstone (in a group only); Firestone or Spellstone (opt-in) | Aura, pet unit, group aura, weapon enchant |
| Druid | Mark of the Wild; Thorns (opt-in, on whoever you cast it) | Aura, group aura |

A reminder appears only once its spell is learned (the highest known rank is
cast). Group versions count: Prayer of Fortitude satisfies Fortitude, Arcane
Brilliance satisfies Arcane Intellect, Gift of the Wild satisfies Mark, Greater
Blessings satisfy blessings.

**Group watcher** (Paladin blessings, Fortitude, Divine Spirit, Arcane
Intellect, Mark of the Wild): one small icon per group member with the
player's name in class colour, your buff's timer, red when missing, crossed out
when dead. Paladins see which blessing each player has from them (Might for
Warriors, Rogues and Hunters, Kings for Paladins, Wisdom for others, until a
read shows what you actually gave). In raids the icons shrink and group by
class so 20 players fit in one strip; layouts for groups over five players are
due for refinement.

## How timing works

Forever marks aura data `SecretWhenUnitAuraRestricted` (combat, encounters,
PvP; `Blizzard_APIDocumentationGenerated/UnitAuraDocumentation.lua` in the
`forever` branch of Gethe/wow-ui-source, build 1.60.1.71139). So:

1. **Out of combat**, a complete read of your auras and your group's records
   each buff's end time, charges and caster. Only a complete read proves a buff
   is gone (`M:ReadAuras`).
2. **In combat**, timers count down from those end times and show a `~`
   (estimates). Still read live: deaths (`UnitIsDeadOrGhost`, clears that
   player's buffs; a Soulstone outlives death), your own casts
   (`UNIT_SPELLCAST_SUCCEEDED`, plus the target from `UNIT_SPELLCAST_SENT` for
   group buffs), totem slots (`PLAYER_TOTEM_UPDATE` / `GetTotemInfo` unless the
   slot is secret), weapon enchants (`C_Item.GetWeaponEnchantInfo`) and
   resources.
3. **After combat**, a full read replaces every estimate. Things the estimate
   cannot see (an enemy dispel, another player overwriting your buff) show up
   here.

Warning time: 25% of the buff's duration, at most 5 minutes (Battle Shout warns
at 45 s), or the fixed time chosen in **Warn before expiry**. Poisons use the
adopted Poison Reminder time and charge warnings.

## Resources

When you can't apply a reminder it is dimmed (default) or hidden (**Can't apply
it**). Out of mana or rage always dims, never hides, since it passes. Spells use
`C_Spell.IsSpellUsable` (`insufficientPower`); items use `C_Item.GetItemCount`
(poisons, oils, stones, food, Soulstones, Soul Shards). Soulstone shows
**Create Soulstone** with only a shard, and dims or hides with neither.

## Click to reapply

`Modules/BuffRemindersSecure.lua`: a separate layer of
`SecureActionButtonTemplate` buttons on UIParent, laid over the visual icons out
of combat. The displays stay plain frames (Position Manager refuses protected
frames). Left-click casts: self buffs on you; poisons, oils and stones on the
right weapon slot (`target-slot`); totem icons cast the chosen totem;
**Totems Missing** runs a `/castsequence` of the missing ones; Soulstone and
Thorns use `[@target,help,nodead][@player]` (your friendly target, else you);
watcher icons cast on that player's unit. Right-click only dismisses (until the
next loading screen). In combat nothing in this layer is shown, hidden, moved
or rebound: icons keep their combat-start places (a buff reapplied mid-fight
stays as a faded icon; one right-clicked mid-fight hides and leaves its place
empty, though its button there still reapplies on left-click until combat
ends), and a reminder that first appears mid-fight is visual
only until combat ends. Displays hold their size in combat, and "Most urgent only"
does not re-sort, so icons stay under their buttons. With **When Needed (OOC)** or
**Always Outside Combat** a secure state driver hides the whole click layer in
combat. Watcher buttons target unit tokens (party1, raid5): if the roster is
reordered mid-fight a button may point at a different player until combat
ends. Elixirs have no click.

## Choice menus and last used

`Modules/BuffRemindersMenu.lua`. Every reminder with a choice (poison per hand,
food, Shaman imbue per hand, weapon oil, Firestone/Spellstone, blessing,
Paladin aura, aspect, Mage armor, demon, totem per element):

- **Click** applies what you used last for that icon: the poison family last put
  on that hand (best rank carried), the food you last ate, the last oil.
- **Corner tab**: a small gold fold at the icon's bottom-right (a plain button
  above the click layer). It opens a menu of everything you could apply, with
  counts, the last used marked. Picking a row casts or uses it through a secure
  button and makes it the new default.
- **Nothing used yet, or none left**: the click opens the menu instead, with a
  note saying why.
- **Placement**: the menu starts from the display's outer edge (never the icon)
  in the direction set by **Menus open**, flipping when there's no room, so it
  never covers a reminder.
- **Memory**: item picks (poisons, food, oils, stones, imbues per hand) are saved
  per character in `lastUsed[characterGUID]`, so they survive `/reload`, loading
  screens and logouts. Spell picks are the saved choices. Eating food or
  applying a poison yourself also updates it (best effort: a food whose count
  dropped right after you started eating, or a poison whose count dropped as a
  hand gained a new poison).
- **Food groups**: Well Fed foods first, from the item tooltip ("Well Fed" or
  "experience"); when the tooltip can't be read, all food is one list.
- **Combat**: the menu is a `SecureHandlerStateTemplate` frame that a
  `[combat]` state driver hides the moment combat starts; tabs hide too, and no
  menu opens until combat ends. Escape closes it out of combat.
- Not in text mode (no tabs there; a click with nothing to apply still opens
  the menu).

## Settings and Layout

Settings page (one scroll): **Reminder** (Show reminder, Time reminder, Charge
reminder, Show charges, Left-click reapplies, Right-click dismisses, When, Warn
before expiry, Display, Can't apply it), **[Class] Buffs** (chips and what to
cast: blessing, aura, aspect, imbue, shield, armor, demon, poisons, stone;
Rogue poison time and charge warnings; Shaman totem per element and **Several
totems missing**), **Group** (watch my buffs, icons or list), **General**,
**Where to Show** (Open World, Dungeons, Raids, Battlegrounds, While resting,
hide while mounted or flying, hide while dead) and **Look** (Customize Display,
Customize Group Watcher, Restore Dismissed).

Layout: two displays, **Buff Reminders** and **Buff Reminders: Group**. Both
start with no background (`element.backgroundDefault=false`; other displays keep
theirs). Besides the shared Scale, Opacity, Text size and Background, each Style
card has its own groups (an approved exception to the v2 rule, kept off settings
pages); only the first group starts open:

- **Display**: Grow, Spacing, Menus open (Up, Down, Left, Right), Glow, Sound.
- **Icons**: Width, Height, Border size (default 1 px, drawn inside the icon),
  Missing, Expiring and Fine colour swatches (game colour picker), Fine border.
- **Timer text**: Font (game, chat and every SharedMedia font), Size, Outline
  (None, Outline, Thick), Position (below, above, inside bottom, centre or top,
  hidden), Colour (by state or white). Text mode uses the same font.
- **Hand labels** (poisons, imbues, oils, stones): Show, Text (MH / OH or Main
  Hand / Off Hand, also used in text mode), Size, Position (above the icon,
  inside at the top, below the timer).
- **Group watcher** (its own card): the same **Icons** group (Width, Height,
  Spacing, Border size, colours, Fine border) and **Timer text** group (Font,
  Size, Outline, Position, Colour) as the main card, saved separately in
  `watchLook`, plus its own **Names** group: Show, Position (inside bottom,
  inside top, below the icon), Colour (class or white), Size, Letters. Names
  and list rows use the watcher's font and outline. A name inside at the top
  or bottom moves an inside timer to the other edge; a name below sits under
  a timer below. Raids keep their smaller tiles and no timers. Older test
  settings (one square **Icon size**, **Timers** off) carry over.

Every icon reserves the same label and timer rows, so icons stay on one line
whether or not each shows a label or has a menu. **Reset** restores the look too.
The card extension is generic: `element.styleGroups` (rows: slider, select with a
list or a function, toggle, colour) and `element.onLayoutReset`
(Config/EditMode.lua, Core/PositionManager.lua).

## Rogue Tools (retired)

Rogue Tools (`foreverRogue`) is retired: Buff Reminders covers its Poison
Reminder (per hand, time and charge thresholds, When, right-click dismissal)
and its Quick Poisons (the poison corner-tab menu; click applies the last
poison used on that hand). Its module files, page, two Layout displays and
tests are removed; `addon.retiredModules.foreverRogue="buffReminders"` lets
old exported profiles import. Its saved table is never written or removed.

A profile whose Buff Reminders settings were never set up adopts, once
(`D.AdoptRogue`, marker `rogueAdopted`): Rogue Tools' switch (on turns Buff
Reminders on), time and charge thresholds, Use Time/Charge Threshold, When
and right-click dismissal. It runs in `OnInitialize` before the saved switch
is applied, and in profile validation, so imports adopt too. Turning Buff
Reminders off later sticks.

## Data and open questions

Spell ranks come from the Forever trainer catalogs
(`Modules/ForeverClassTrainingCatalog*.lua`). Needs in-game confirmation:

- Forever food auras 1248406, 1249517, 1249519–1249521, 1225778/80/82, 1294007
  (Wowhead Forever data) and whether all read as food buffs; matching also uses
  their aura names.
- Elixir and flask aura IDs are Classic values.
- Poisons, Shaman imbues and Firestone/Spellstone are assumed to be the Imbue
  enchant type and oils/stones the Temporary type; Forever lets several stack.
- Firestone/Spellstone: in Classic these are off-hand items, and a secure "item"
  click would equip them instead of applying them. Forever reportedly made them
  weapon imbues; the reminder is opt-in until this is confirmed.
- Firestone/Spellstone duration; Water Shield (408510) availability; top ranks
  missing from the catalog (25289, 25290, 25291, 25359, 25361).
- Whether `UNIT_SPELLCAST_SENT` gives your target's name in combat.
- Whether casting a Shaman off-hand imbue needs a second cast (the click casts
  the spell; the client picks the weapon).

## Validation

`python tests/buff_reminders.py` (Mage timing/combat/resources/modes/Layout/
page/validation, Shaman totems and imbues, Paladin watcher and deaths, Warlock
Soulstone, group watcher look, retired Rogue Tools adoption and import),
`python tests/smoke.py`, the full suite
and `python tools/build_release.py`.

## In-game checks

| Check | Navigation | Action | Required state | Confirmation |
| --- | --- | --- | --- | --- |
| B1 Turn on | `/ptg` → sidebar **Buff Reminders** | Click the page header switch on | Out of combat; client restarted once after updating | Missing buffs for your class appear as icons below the middle of the screen; nothing from other classes |
| B2 Your class only | `/ptg` → sidebar **Buff Reminders** → **[Class] Buffs** group | Read the chips | Out of combat | Only your class's buffs are listed, e.g. Mage: Arcane Intellect, Armor, Dampen or Amplify Magic |
| B3 Expiring | **Reminder** group → **Warn before expiry** → **15 min before** | Cast a 30–60 minute self buff, e.g. Arcane Intellect | Out of combat | The icon shows a gold frame and a timer such as `14m`; it disappears once more than 15 minutes are left |
| B4 Combat estimate | (display on screen) | With an expiring reminder shown, pull a mob | Enter combat | The timer keeps counting with a `~` in front; after combat it shows the exact time again |
| B5 Click to reapply | (display on screen) | Left-click a missing reminder icon | Out of combat, enough mana, **Left-click reapplies** on | Your highest rank is cast on you and the icon disappears |
| B6 Click in combat | (display on screen) | As a Warrior, let Battle Shout run low before a pull; click its icon during combat | In combat | Battle Shout is cast; the icon stays in place, faded, until combat ends |
| B7 Dismiss | (display on screen) | Right-click a reminder; then `/reload` | Out of combat | The icon hides; it returns after the reload or a loading screen |
| B8 Resources | **Reminder** group → **Can't apply it** | As a Rogue with no poisons, try **Dim the reminder** then **Hide the reminder** | Out of combat | Dim: the poison icons are grey; Hide: they disappear. Running out of mana only ever dims |
| B9 Text | **Reminder** group → **Display** → **Text** | Remove both poisons (Rogue) | Out of combat | One line reads `Poison Missing (MH/OH)` |
| B10 Totems | **Shaman Buffs** group → **Water totem** → **Mana Spring Totem**; **Several totems missing** → **One Totems Missing icon** | Stand without totems; click the icon twice | Shaman, out of combat | One **Totems Missing** icon; each click drops the next missing totem; placed totems clear |
| B11 Group watcher | Layout display **Buff Reminders: Group** | Join a party as a Paladin (or Priest, Mage, Druid); click a member's icon | Out of combat | One icon per member with their name in class colour; the click blesses/buffs that player and the icon clears |
| B12 Soulstone | (display on screen) | As a Warlock in a party, target a healer and click **Soulstone**; then clear your target and click again (with a new stone) | Out of combat, Soulstone in bags | The stone goes on your target; with no target, on you. The icon shows who has it |
| B13 Layout card | Window header **Layout** → click **Buff Reminders** | Open **Display**, set **Grow** to **Down** and **Icon size** to 52; click **Reset** | Out of combat | Icons stack downward at the larger size; Reset returns them to the default row |
| B14 Rogue Tools retired | `/ptg` → sidebar | Look for **Rogue Tools**; open **Buff Reminders** → **Rogue Buffs** | Rogue, out of combat | No Rogue Tools page or Layout displays remain; Buff Reminders is on with your poison reminders and the same time and charge warnings Rogue Tools had |
| B16 Poison menu | (display on screen) | As a Rogue with two poison families in your bags, click the gold corner tab on the **MH** icon; pick a different poison | Out of combat | A menu opens above the whole display (not over any icon) listing each poison with counts and **last used**; the pick is applied and the next plain click on **MH** applies the same poison |
| B17 Remembered | (display on screen) | After B16, type `/reload`; log out and back in; check another character | Out of combat | The **MH** click still applies your pick after each; another character keeps its own |
| B18 Food menu | (display on screen) | With no food eaten yet, click the food icon; pick a food; later click the icon again | Out of combat, food in bags | First click opens the food menu with a note; the pick is eaten; the next click eats the same food |
| B19 Learn food | (display on screen) | Eat a different food straight from your bags, then let the food buff run out | Out of combat | The food icon now shows and eats that food |
| B20 Icon and text options | Window header **Layout** → click **Buff Reminders** | Open **Icons**: set Width 52, Height 30, Border size 2, change **Missing**; open **Timer text**: pick a font, **Thick** outline, **Inside, centre**; open **Hand labels**: **Main Hand / Off Hand** | Out of combat | Icons resize (art stays square), borders thicken and recolour, timers change font and position, labels read Main Hand / Off Hand; icons stay on one line; **Reset** restores everything |
| B21 Menus in combat | (display on screen) | Open a menu, then pull a mob | Enter combat | The menu and the corner tabs disappear at once; tabs return when combat ends |
| B22 Group watcher look | Window header **Layout** → click **Buff Reminders: Group** | In a party as a Paladin (or Priest, Mage, Druid): open **Icons**, set Width 40, Height 26, change **Missing**; open **Timer text**, set **Below icon** and **Thick**; open **Names**, set **Below icon** | Out of combat | Tiles resize (art stays square) and recolour; timers sit under each tile with the name under the timer; the main display is unchanged; **Reset** restores the group look |
| B23 Dismiss in combat | (display on screen, two or more reminders up) | Enter combat, then right-click the first reminder | In combat, **When Needed** (not OOC) | The icon hides at once; the others stay where they were; after combat it stays hidden until the next loading screen |
| B15 Food aura | (display on screen) | Eat a Forever food; if the Food buff reminder stays, run `/run for i=1,40 do local a=C_UnitAuras.GetAuraDataByIndex("player",i,"HELPFUL") if not a then break end print(a.name,a.spellId) end` | Out of combat | The reminder clears once fed; otherwise report the printed food aura name and ID |
