# Play The Game Tools 0.3.0 candidate testing

Mode module layout rollout: run `tests/mode_module_layouts.py` and the full
regression suite. The [page-by-page native checklist](docs/MODE_MODULE_LAYOUTS.md#exact-in-game-checks)
covers the owner-approved Campfire pattern across the remaining module settings.
Mode only; use `/reload` OOC. Broad native acceptance is still pending.

SharedMedia pack integration: run tests/shared_media.py. Settings has no media
pickers since v2; the pack's fonts/textures/borders keep plain names wherever the
addon lists them.

Disabled-provider media: run tests/media_discovery.py and use the
[known-path/cache native check](docs/GLOBAL_SETTINGS.md#validation-and-native-checklist).
Test providers already disabled; PTG must not change their enabled state.

Settings: use the [native checklist](docs/GLOBAL_SETTINGS.md); the page is one scroll (Appearance, Game, Profile, About). Run tests/global_settings.py for bundled LSM/media, standard game font inheritance and local overrides, account-wide profile selection/import/export/positions, class picker, native loot-session cancellation, camera/scale readback and combat guards.

Experience Bar: follow [the focused checklist](docs/ENHANCED_EXPERIENCE_BAR.md#validation-and-exact-native-checks)
on its local feature branch. Enable from sidebar **Experience Bar**; native acceptance
is pending.

Paths read "sidebar → Module → section": the module's row in the A–Z sidebar
list, then a titled group on its page. Since v2 every page is one vertical scroll
(page header, then each section top to bottom): there are no category headings,
pills or tabs, so scroll to the named section. "Settings" is the row pinned at the
bottom of the sidebar. Header **Reload** is now the **Reload now** button in the
banner above the page. Display styling (fonts, sizes, colors) is edited in
**Layout**, not on module pages. Run `python tests/mode_module_layouts.py` for the
one-scroll pages (mock only).

Browser windows (v2 wave 2): Dungeon Loot's dungeon index, Boss Loot and Quests,
and Class Training's Upcoming Abilities and Available & Known, now open in their
own movable windows. Run `tests/browser_windows.py` with the full suite. New TOC
file `Config/BrowserWindow.lua`: restart the client once, then `/reload` OOC.
Mock tests only; native confirmation pending.

1. **Navigation:** `/ptg` → **Class Training** row in the sidebar.
   **Action:** Read the page header, then click **Open Class Training**.
   **Required state:** OOC, Class Training on.
   **Confirmation:** The page shows General, Level Up Window and Shortcut Icon &
   Menu only, no ability lists. The button opens a **Class Training** window with
   **Upcoming Abilities** and **Available & Known** tabs, the training total at
   the top and level headings; the settings window closes.
2. **Navigation:** **Class Training** window.
   **Action:** Switch between **Upcoming Abilities** and **Available & Known**;
   learn a rank at a trainer with the window open.
   **Required state:** OOC, at a class trainer.
   **Confirmation:** Each tab shows its list; the learned rank moves to Known
   without a reload or a Refresh button.
3. **Navigation:** `/ptg` → **Dungeon Loot** row.
   **Action:** Read the page, then click **Open Dungeon Loot**.
   **Required state:** OOC, Dungeon Loot on.
   **Confirmation:** The page shows Quick Icon (Icon Size, Icon Opacity),
   Keybinding (**Set Keybinding**, **Clear Keybinding**) and Dungeon Data
   (source, license, **Refresh**). The button opens a **Dungeon Loot** window with
   **Dungeons**, **Boss Loot** and **Quests** tabs and no General tab.
4. **Navigation:** Quick Actions ring → Dungeon Loot icon; then your Dungeon Loot
   keybinding.
   **Action:** Click the icon; close the window; press the key.
   **Required state:** Dungeon Loot on, a key bound with **Set Keybinding**.
   **Confirmation:** Both open the Dungeon Loot window on the dungeon index.
5. **Navigation:** Either window.
   **Action:** Drag it by its body to a new place, close it with **Close**, reopen
   it; then press Escape.
   **Required state:** OOC, same session.
   **Confirmation:** It reopens where you left it (after a `/reload` it starts
   centered again); Escape closes it before the game menu would open.
6. **Navigation:** Dungeon Loot window → a dungeon → **Quests** → a quest →
   **View on Map**.
   **Action:** Close the world map.
   **Required state:** OOC.
   **Confirmation:** The window hides while the map is open and returns when the
   map closes.
7. **Navigation:** Your Dungeon Loot keybinding (set with **Set Keybinding**).
   **Action:** Enter combat with a training dummy, press the Dungeon Loot key,
   browse, then press Escape.
   **Required state:** In combat, Dungeon Loot on.
   **Confirmation:** The window opens, scrolls and closes with no Lua error or
   blocked-action message.
8. **Navigation:** Either window → **Settings** button.
   **Action:** Click it.
   **Required state:** OOC.
   **Confirmation:** The settings window opens on that module's page and the tool
   window closes.
9. **Navigation:** `/ptg` → **Settings** row → Interface Theme.
   **Action:** Switch between mode, Modern and Blizzard (reload when asked) and
   open both windows each time.
   **Required state:** OOC.
   **Confirmation:** Each window takes the theme's window surface, like the
   Recruiter: Blizzard draws the stock dialog border with content clear of it.
10. **Navigation:** `/ptg` → **Dungeon Loot** row.
    **Action:** Turn the module off with the header switch.
    **Required state:** OOC, Dungeon Loot window open beforehand.
    **Confirmation:** **Open Dungeon Loot** greys out and the window closes; your
    keybinding then opens the settings page instead and does not turn it on.

Record PASS / FAIL / NOT TESTED for each item, with version, client build, class
and level. These instructions do not claim native acceptance. Do one chunk at a
time; start with A. Stop and report startup/errors/settings loss before continuing.

## A. Package and first startup

Use the attached `PlayTheGameTools-0.3.0-forever.zip`, not GitHub's source archive.
Installation is a filesystem step, not a Play The Game Tools UI control. Close WoW, back up
your existing Play The Game Tools addon folder and your own settings separately, and extract
the ZIP into an isolated Forever test installation if available. Keep one
`PlayTheGameTools` folder; never merge this into Retail. For an existing installation,
move its old addon folder to a backup location outside AddOns first, rather than
merging stale files into the new folder. Preserve WTF/SavedVariables; when upgrading from the old `ModeTools` folder, rename SavedVariables/ModeTools.lua to PlayTheGameTools.lua. If using the
maintainer's existing managed live installation, request the maintainer's verified
installation procedure instead of changing it manually.

1. **Navigation:** Forever character selection → AddOns → Play The Game Tools.
   **Action:** Enable the candidate and log in; open `/ptg`.
   **Required state:** Candidate installed with game closed, fresh client start.
   **Confirmation:** AddOns metadata reports Play The Game Tools, author Mode and Prox, and version
   0.3.0; configuration opens without a Lua error or wrong-edition message.
2. **Navigation:** `/ptg` → sidebar **Class Training** → **General** section → **Level Up Window** checkbox.
   **Action:** Record its current value, change it, reload using `/reload`, then
   reopen the same page. Restore your preferred value afterward.
   **Required state:** OOC, Class Training enabled; retain existing settings.
   **Confirmation:** The explicit value persists; existing module preferences and
   positions remain. Do not delete your settings to make a failed upgrade pass.
3. **Navigation:** `/ptg` → sidebar **Combat Timer**, then **Automation**, then **Class Training**.
   **Action:** Visit each page, scroll it top to bottom, and close/reopen configuration with `/ptg`.
   **Required state:** OOC; no feature needs enabling merely to inspect pages.
   **Confirmation:** Pages render as one scroll with section headings and no pills
   or tabs; text/art/scrolling work; no absent Retail module or prototype is
   advertised as usable. Optional media addons are not required.

For clean-install defaults, use a separate test account/client settings setup;
never erase the developer's working SavedVariables. Confirm Class Training on,
Combat Timer/Automation off, and no automatic training popout on login. This is a
separate result from the existing-settings upgrade check above.

## B. Training and positioning

1. **Navigation:** `/ptg` → sidebar **Class Training** → **Open Class Training** (page header) →
   **Upcoming Abilities** / **Available & Known** tabs of the Class Training window.
   **Action:** Learn a rank at a trainer (or level up), return to the window without
   reloading, and inspect known/unknown ranks against your spellbook and
   an ordinary class trainer. Record mismatched ability/rank/level/cost examples.
   **Required state:** OOC, enabled module, supported current class.
   **Confirmation:** Only your class appears; abilities above your level list on
   the **Upcoming Abilities** tab and the rest on **Available & Known**, each under
   its **Level N** heading; learned/superseded ranks are handled
   sensibly, estimates remain estimates, uncertain entries are not guaranteed offers.
2. **Navigation:** Quick Actions button → green Class Training icon → Minimize / Jump to Settings.
   **Action:** With Class Training on (its icon is always in the ring then), click the book, scroll, minimize, reopen,
   click Jump to Settings; move the Quick Actions button near screen edges in Edit Mode.
   **Required state:** OOC, enabled module; preserve preferred final position.
   **Confirmation:** Bounded translucent list scrolls, glow follows open state,
   Minimize closes it and Jump to Settings opens the Class Training page.
3. **Navigation:** Quick Actions button → green Class Training icon → open popout → ordinary combat.
   **Action:** Enter and leave safe ordinary combat, then reopen it from the ring OOC.
   **Required state:** Normal safe gameplay, enabled module and shortcut.
   **Confirmation:** Popout closes on combat entry, stays closed afterward, and
   reopens on the next OOC click without blocked/forbidden action errors.
4. **Navigation:** `/ptg` → sidebar **Class Training** → **Level Up Window** section →
   **Level Up Window** row → **Preview** button.
   **Action:** Preview; vary Time to Level, Player Money, Professions, Secondary
   Professions and Window Width / Window Scale / Detail Text Size.
   **Required state:** OOC; **Level Up Window** ticked in the **General** section
   (the section hides while it is off); no actual level gain required for preview.
   **Confirmation:** Preview is readable, optional summaries follow preferences,
   and settings survive reload. Record actual Level-Up Alerts separately on the
   next naturally occurring level gain; preview does not validate that event.
5. **Navigation:** `/ptg` → sidebar **Class Training** → **Level Up Window** section →
   **Guild Ding Message** and **Time to Level** checkboxes; then the
   level-up window's Guild Message button.
   **Action:** With both toggles on, log in or `/reload` and note the native
   "Time played this level" chat line. Gain a level OOC, click Guild Message.
   **Required state:** In a guild with guild chat permission; OOC; empty chat box.
   **Confirmation:** Exactly one /played print per login or reload. The prepared
   `/g` draft reads "Ding <level>, that took me <time>", where time is close to
   the previous "Time played this level" plus the time since. The level-up
   window's Time to level line shows the same duration. With Time to Level off,
   the draft reads "Ding <level>" only.

Repeat the class comparison on other available classes without claiming untested
classes passed. Priest race/Mage faction filters, pet/tome/quest acquisition and
special prerequisites require specific evidence; report uncertainty honestly.

## C. Combat Timer

1. **Navigation:** `/ptg` → sidebar **Combat Timer** → page header switch
   (unlabeled, top right of the page).
   **Action:** Enable, close configuration, enter and leave ordinary combat.
   **Required state:** OOC to configure; ordinary combat to observe.
   **Confirmation:** Elapsed time advances during combat and follows the configured
   visibility afterward. Disable OOC and confirm its display stops.
2. **Navigation:** `/ptg` → sidebar **Combat Timer** → **Behavior** section → **Combat visibility**.
   **Action:** Scroll the page; click **Only in Combat**, then **Always Visible**; reload OOC and revisit.
   **Required state:** OOC; restore your preferred choice afterward.
   **Confirmation:** Below the preview the page shows only the **Behavior** section;
   the **Display** section (font, size, colors) does not appear because the timer
   is styled in **Layout**. The chosen visibility is kept after reload.

## D. Automation (opt-in actions)

Review each switch before enabling the Automation header switch. Test on ordinary
interactions you intend to perform: quest actions, sales and repair spend/change
game state. Leave a feature off if you are not ready to exercise it.

1. **Navigation:** `/ptg` → sidebar **Settings** → **Game** section.
   **Action:** Read the section.
   **Required state:** OOC.
   **Confirmation:** There is no Auto Loot control (v2 removed it; the game's own
   Auto Loot option is unchanged by the addon).
2. **Navigation:** `/ptg` → sidebar **Automation** → **Quests** group → **Auto Accept
   Quests** / **Auto Turn-In Quests** / **Modifier Bypass**.
   **Action:** Select Shift; test an ordinary eligible offer/turn-in, then hold
   Shift while opening the next interaction. Inspect a multiple-choice reward.
   **Required state:** OOC, master enabled, only intended actions opted in.
   **Confirmation:** Eligible actions happen once; bypass and multiple-choice
   rewards remain manual; no unintended reward/payment/confirmation handling.
3. **Navigation:** `/ptg` → sidebar **Automation** → **Merchant** group → **Auto Sell
   Junk** / **Auto Sell Gray Equipment** / **Auto Repair** / **Maximum Repair Cost (%)**.
   **Action:** Keep gray equipment off; test unwanted gray non-equipment at a
   merchant and a repair bill within your chosen percentage, then test opt-out.
   **Required state:** OOC, master enabled, disposable intended junk and personal
   funds; inspect options before opening merchant. No developer item injector exists.
   **Confirmation:** Eligible junk only sells; gray equipment remains; repair uses
   personal funds once within threshold; disabled features leave actions manual.
4. **Navigation:** `/ptg` → sidebar **Automation**.
   **Action:** Scroll the whole page.
   **Required state:** OOC.
   **Confirmation:** Only Quests and Merchant groups appear; there is no Dialogue
   group, Auto Gossip switch or Auto Gossip Availability note. Dialogue stays manual.

## E. Guild

Guild Roster and Guild Recruitment are one module, **Guild**: one sidebar entry,
one switch, and one Guild window with **Roster** and **Recruit** tabs. Run
`python tests/guild.py` and `python tests/guild_roster.py` with smoke/build. Mocks
establish neither native member data nor Who, whisper or invite behavior. One new
file (`Config/ForeverGuild.lua`) is in the TOC: restart the client once.

| Check | Navigation | Action | Required state | Confirmation |
| --- | --- | --- | --- | --- |
| G1 Switch carried over | `/ptg` → sidebar **Guild** | Look at the page header switch | Before updating, Roster **or** Recruitment was on; first login after the update | The switch is on. With both previously off it is off. The sidebar has one **Guild** entry and no Roster or Recruitment entries |
| G2 Turned off stays off | `/ptg` → sidebar **Guild** | Click the header switch off, `/reload`, reopen the page | G1 with the switch on | The switch is still off after the reload |
| G3 Saved recruit data kept | `/ptg` → sidebar **Guild** → **Open Guild** → **Recruit** | Read Level range, Levels per search, the class boxes, the whisper box and the line at the bottom | Guild on; you used the Recruiter before updating | Values match what you had; the bottom line shows your old **Invited / Joined / Declined** numbers; players you invited or marked X earlier still do not come back in a Scan |
| G4 Page | `/ptg` → sidebar **Guild** | Read the page; click **Open Guild** with the switch off, then on | Out of combat | The page shows only a note about the Roster and Recruit tabs. **Open Guild** sits left of the header switch, is dimmed and does nothing while off; while on it opens the Guild window on **Roster** and closes Settings |
| G5 Old names | `/ptg` search box | Type `roster`, then `recruitment`, then `guild recruitment` | Out of combat | Each time the first result is **Guild** (or **Guild > Open Guild**); choosing it opens the Guild page |
| G6 Quick Actions | Quick Actions launcher | Click the launcher, hover the Guild icon, click it; click it again | Guild on, out of combat | One icon with the tooltip **Guild** / **Click to open or close the Guild window.**; it opens the Guild window and the second click closes it. With Guild off there is no icon |
| G7 Tabs and `/ptgr` | Guild window | Click **Recruit**, **Roster**, close with **Close**; type `/ptgr` twice | Guild on | Each tab shows only its own controls; the window reopens on the last tab used; `/ptgr` opens it on **Recruit** and the second `/ptgr` closes it |
| E1 Scan | Guild window → **Recruit** | Set Level range, pick one class, click **Scan** | Out of combat, in a guild with invite permission | One Who search runs; the Who window closes again if it was not already open; unguilded players in range appear in the list with class colors |
| E2 New scan clears | Guild window → **Recruit** | With candidates listed, click **Scan** again after the countdown | Candidates present, **Scan** not counting down | The list empties before the next search's results appear |
| E3 Invite | Guild window → **Recruit** | Click **Invite** on a row, press Ctrl+C, open the game's Guild → Add Member, paste and confirm | Out of combat, invite permission, a willing test player | The copy box shows the name; the game invites without a blocked-action message; the bottom line shows Invited +1 (Joined/Declined after the reply); no whisper is sent |
| E4 Whisper | Guild window → **Recruit** | Type a message longer than 255 characters in the whisper box, then click **Whisper** on a row without pressing Enter | Out of combat, candidates listed, a willing test player | The box scrolls as you type; the player receives the whole message as consecutive whispers with no blocked-action message; the row leaves the list; the bottom line does not change |
| E5 History menu | Guild window → **Recruit** → **History** (bottom right) | Click **X** on a row and scan again; then choose **Clear Never-Invite List**; then open **History** again and choose **Reset Statistics** | Out of combat | The menu lists **Clear Invite History**, **Clear Never-Invite List** and **Reset Statistics** and closes after a choice. The X'd player stays out of scans until the list is cleared; the bottom line reads **Invited: 0   Joined: 0   Declined: 0** after the reset; invited players stay hidden for the saved re-invite window (7 days by default) until **Clear Invite History** |
| E6 Combat | Guild window → **Recruit** | Enter combat, click **Scan**, **Invite** and **Whisper** | In combat, candidates listed | Nothing is sent; the status line reads **Unavailable in combat.** |
| R1 Turn on | Guild window → **Roster** | Click the switch in the window header | Logged in on a character in a guild; Guild off | **Class Summary** shows **Total Members**, **Online Now** and all nine classes with a count, including 0 |
| R2 Members by class | Guild window → **Roster** | Scroll to **Members by Class** and to the bottom of the list, then compare with the native guild window | R1 done | Each class with members has a colored heading such as **Mage (12)** and its names alphabetically, each with its level on the right; the line above the list reads **N members, M online** and both numbers match the native window; offline members are included |
| R3 Totals agree | Guild window → **Roster** | Compare each **Class Summary** count with the number in that class's heading | R1 done; search box empty, **All Classes** and **All Members** selected | Every count matches its heading |
| R4 No guild | Guild window → **Roster** | Open the tab | Guild on, on a character not in a guild | The top reads **You are not in a guild.**; **Total Members: 0** and no breakdowns, with no Lua error |
| R5 Turn off | Guild window → **Roster** | Click the switch in the window header | Guild on | Names are cleared and the tab reads **Turn Guild on with the switch above to view your guild.**; the Quick Actions icon leaves the ring |
| R6 Online marker and tooltip | Guild window → **Roster** | Hover one online and one offline name | R1 done | Online names have a small accent square before them. The tooltip shows the name, then **Level N Race Class**, **Rank: …**, then **Online in Zone** for an online member or **Last online … ago** for an offline one, plus **Note:** / **Officer Note:** when the native window shows them. Moving away, switching to **Recruit** or closing the window closes it |
| R7 Search | Guild window → **Roster** | Type part of a name in the box reading **Search name, zone, rank, note or level**, then a zone, a rank name, `60`, and `40-59`; then clear the box | R1 done | Each search lists only matching members and reads **Showing X of N members** (or **No members match your search.**); numbers match levels only; clearing restores the full list |
| R8 Filters | Guild window → **Roster** | Choose a class in **All Classes**, then **Online** and **Offline** in **All Members**; return both to **All Classes** and **All Members** | R1 done | Only that class is listed; **Online** shows only marked names and matches the native online count for that class; **Offline** shows the rest |
| R9 Breakdowns | Guild window → **Roster** | Scroll below the members through **Level**, **Rank**, **Race**, **Last Online** and **Online by Zone** | R1 done | Each line shows a bar and **count (share%)**; the longest bar is the largest count; **Rank** follows the guild's rank order; **Last Online** starts with **Online Now** equal to **Online Now** above; **Online by Zone** counts only online members, or reads **Nobody is online right now.** |
| R10 Nothing saved | Guild window → **Roster** | Type a search and choose a class filter, then `/reload` and reopen the tab | R1 done | The search box is empty and the filters read **All Classes** and **All Members** |

## Map Labels

Run `python tests/city_labels.py`. Mocks model the inspected Forever map canvas
but do not establish native rendering, icon files or profession reading. City
Labels adds new TOC files: restart the client once. Data, coverage and limits:
[docs/CITY_LABELS.md](docs/CITY_LABELS.md).

| Check | Navigation | Action | Required state | Confirmation |
| --- | --- | --- | --- | --- |
| L1 Turn on | `/ptg` → sidebar **Map Labels** | Click the switch at the top right of the page, then open the world map (M) on your capital (Stormwind, Orgrimmar, Thunder Bluff or Undercity) | Out of combat | Switch reads **Enabled**; **Class Trainers** and **Profession Trainers** both read **Mine**; icons with names mark **Bank**, **Auction House**, **Flight Master**, **Inn**, your class's trainer and trainers for professions you know only; no Lua error |
| L2 Icons | World map on your capital, zoomed in | Look at each label | L1 done | Each label is a game icon in a thin colored edge: your class icon on your class trainer, your profession's icon on its trainer, a bag on **Bank**, coins on **Auction House**, a hearthstone on **Inn**; a plain colored dot appears only if an icon file is missing |
| L3 Undercity gaps | World map on Undercity (Horde, or **Other Faction** ticked) | Set **Profession Trainers** to **All**, then find **Alchemy**; set **Class Trainers** to **All**, then find **Warlock Trainer** | Out of combat | **Alchemy** labels near 47, 75 and 51, 75; **Warlock Trainer** near 87, 16 in the Rogues' Quarter, whose tooltip reads **Classic position: may differ where Forever moved an NPC.** and **Location: CMaNGOS classic-db (GPL-3.0)** |
| L4 Tooltip | World map on your capital | Hover the **Bank** icon | L1 done | Tooltip lists the bankers and **Guild Vault**, then **Approximate: where players stood to use it.** and **Locations: Efficient Games (CC BY 4.0)** |
| L5 Clicks pass through | World map zoomed into your capital | Left-click an icon, then right-click it | L1 done | The map zooms in and out as if the icon were not there |
| L6 Trainer modes and filters | `/ptg` → sidebar **Map Labels** | Set **Class Trainers** and **Profession Trainers** to **All**, then **Off**, then back to **Mine**; under **Services** click the **Mailboxes** and **Other Faction** chips; reopen the map each time | Out of combat | **All** adds every class's and profession's trainers, **Off** removes them, **Mine** restores yours; mailbox icons without names and the other faction's labels appear while selected |
| L7 Appearance | `/ptg` → sidebar **Map Labels** → **Appearance** group | Drag **Icon Size** to 24 and **Name Size** to 14, reopen the map; then untick **Show Names** under **Appearance** | Out of combat | Icons and names are larger; with **Show Names** off only icons remain |
| L8 Turn off and combat start | `/ptg` → sidebar **Map Labels**; later a fresh login | Click the switch at the top right of the page and open the map; switch it back on, log in again, enter combat before first opening the map, and open it after combat | Combat, then out of combat | Switch reads **Disabled** and no Map Labels icons show; after re-enabling, labels appear once combat has ended; no Lua error |

## F. Reporting and release gate

Return the results by chunk, e.g. `A1 PASS, A2 FAIL: preference reset after reload`.
Include actual version/build/class and error text. No automated native test button
exists for this checklist. Maintainers also retain the more detailed module
checklists in the development repository.

The maintainer must confirm the installed package matches the reviewed artifact.
Initial WowUp install/update delivery remains untested until an explicitly approved
public release exists. Test it with one guildmate before broader announcement.
Public repository/release creation is a separate approval; no auto-publish workflow
is supplied. A beta label does not restrict access to guildmates.

## Interface themes

Run `python tests/smoke.py`; it covers the saved choice, the reload request, every
settings page built under Blizzard, refused stock artwork falling back to the flat
drawing, and an unknown saved theme rendering Modern without being rewritten.
Stock artwork, fonts, text fit and contrast require these in-game checks.

| Check | Navigation | Action | Required state | Confirmation |
| --- | --- | --- | --- | --- |
| T1 Choose Blizzard | `/ptg` → sidebar **Settings** → Appearance → Interface Theme | Click **Blizzard**, then **Reload now** in the banner above the page | Out of combat | The banner appears with the theme change before the click; after reload `/ptg` shows the gold dialog border, opaque dark stone, red header buttons, stock checkboxes and gold headings |
| T2 Text fit | Blizzard active; open each sidebar entry | Read sidebar rows, page headers, dropdowns and search results | Out of combat | No clipped or overlapping labels in the game font |
| T3 Selectors and inputs | Blizzard active; sidebar **Settings** → **Appearance** section, sidebar **Combat Timer** → **Behavior** section, the search box | Click options; type in the search box | Out of combat | Selected option has a gold outline; input borders show no square corners |
| T4 Return to Modern | `/ptg` → sidebar **Settings** → Appearance → Interface Theme | Click **Modern**, then **Reload now** in the banner | Out of combat | Window shows the Modern graphite look: dark sidebar column, slightly lighter canvas, outlined header buttons |
| T5 Fresh-launch labels | Quit WoW fully, relaunch | Type `/ptg` as soon as you are in the world | Out of combat | Sidebar labels and the window title are visible, at worst after about a second |
| T6 Threat Meter | `/ptg` → sidebar **Threat Meter** (enabled); in a group with a tank, or with your pet tanking | Attack the tank's target and keep adding threat until your row shows 90% or more without taking aggro; then stop and let it fall back | In combat | Header strip and class-coloured bars; your row has an accent stripe in its own gap left of the bar, not on the bar; at 90% or more that stripe turns red and a thin red frame surrounds your bar; below 90%, or once you hold aggro, both return to the plain accent stripe. Repeat once with the **Blizzard** theme: the red is clearly different from the gold stripe |
| T7 Modern edges and hover | Modern active; `/ptg` | Look at **Layout**, **X**, the **Search** box and Settings → Appearance → Interface Theme without hovering, then hover each | Out of combat | Every control shows a visible outline at rest; hovering lifts its fill; **Modern** has a solid mint outline and **Blizzard** a grey one |
| T8 Modern navigation and sections | Modern active; click a sidebar entry, then **Class Training** | Compare the selected sidebar entry with the others; scroll the page top to bottom | Out of combat | Selected entry has a mint bar on its left edge; the page is one scroll with no pills or tabs: **General**, **Level Up Window** and **Shortcut Icon & Menu** follow one another as plain headings (the ability lists are in the window that **Open Class Training** opens) with no Collapse button, separated by clearly more space than rows; dividers are visible but quiet |
| T9 Modern checkboxes and sliders | Modern active; sidebar **Automation**, then sidebar **Map Labels** → **Appearance** group | On Automation tick and untick any box; on Map Labels drag the **Icon Size** slider | Out of combat | Ticked box shows a mint square on a faint mint wash with a mint edge; slider track is a thick grey bar filled mint up to the thumb |
| T10 Solid Dungeon Loot text | `/ptg` → sidebar **Dungeon Loot** (enabled) | On **Dungeons** read the card titles and Suggested Starting Levels headings; open a dungeon and view **Boss Loot** and **Quests** | Out of combat | Every heading, card title, list entry and NPC name is one solid colour; the selected tab underline is one solid accent; bracket headings sit over a plain hairline |
| T11 Guild page | `/ptg` → sidebar **Guild** | Read the page, then click **Open Guild** | Guild on, out of combat | Superseded by section E, checks G3 and G4: the page holds only a note; Level range, Levels per search, Classes, the whisper box and the **History** menu are on the Guild window's **Recruit** tab with saved values as before |

## v2 settings window

Run `python tests/window_shell.py`, `python tests/smoke.py` and
`python tests/mode_theme.py`. These are mock checks; the window's real fit,
fonts and behavior need these in-game checks. Use `/reload` OOC first.

| Check | Navigation | Action | Required state | Confirmation |
| --- | --- | --- | --- | --- |
| V1 Size and fit | Type `/ptg` | Look at the whole window; drag it by the header strip left of **Layout**, then type `/ptg resetwindow` | Out of combat | The window is smaller than before (960×640 at full scale) and fully on screen; it moves while dragged and returns to the centre after `/ptg resetwindow` |
| V2 Header | `/ptg` | Read the header | Out of combat | Logo and "Play The Game Tools" on the left; only **Layout** and **X** on the right. No Preview, Reload, Edit Mode or Profile button |
| V3 Layout | `/ptg` → sidebar **Combat Timer** (switch on) | Click **Layout**, then **Exit** in the Layout window | Out of combat | Settings steps aside and Edit Mode opens with the Combat Timer display selected; **Exit** brings settings back on Combat Timer |
| V4 Sidebar | `/ptg` | Read the sidebar top to bottom; click two rows; turn one module's page switch off and on | Out of combat | **Search** box first, then one A–Z list of module names with a small dot each (filled accent = on, dim = off), no category headings, no Dashboard, no Developer Mode; **Settings** sits at the bottom below a line; clicking a row opens its page; the dot follows the switch |
| V5 Class-only row | Log in on a Rogue, then on any other class; `/ptg` each time | Read the sidebar | Out of combat | **Rogue** (with its class icon) is listed on the Rogue only |
| V6 Page header | `/ptg` → any module row, then **Settings** | Read the page header | Out of combat | Title, one-line description and one switch at the right; no "Enabled"/"Disabled" text. **Settings** reads "Settings" / "Look, game options and profiles for the whole addon." with no switch |
| V7 Reload banner | `/ptg` → **Settings** → Appearance → Theme | Click a theme other than the current one; open another page; click the current theme again; pick the other theme and click **Reload now** | Out of combat | A banner "Applies after a reload" with the theme reason and **Reload now** shows above every page while the change is pending, disappears when you pick the current theme back, and **Reload now** reloads the UI |
| V8 Reload in combat | Banner showing (V7 before reloading) | Enter combat, click **Reload now** | In combat | No reload; the banner says reload is unavailable during combat (also printed in chat) |
| V9 Search | `/ptg` → **Search** box | Type `repair`; click the **Maximum Repair Cost (%)** result; then type `analytics` and click the **Analytics** result; then type `threat` and press Enter; then type `zzzz` and press Escape | Out of combat | While typing, results (name and page beneath) replace the list; a click opens that page, scrolls it to the setting or section and briefly highlights it; Enter opens the first result; `zzzz` says "Nothing matches"; Escape clears it and the list returns |
| V10 Last page | `/ptg` → **Threat Meter** | Close with **X**, type `/ptg` | Out of combat | Reopens on Threat Meter. After `/reload`, the first `/ptg` opens on **Automation** (first A–Z) |
| V11 Developer Mode | Type `/ptg dev` | Read the page | Out of combat | Settings opens on Developer Mode (no switch in its page header); it is not in the sidebar |

## v2 styling reset

Run `python tests/style_reset.py`, `python tests/layout_style.py`,
`python tests/mode_module_layouts.py`, `python tests/guild.py` and
`python tests/smoke.py`. These are mock checks. One file was added
(`Core/StyleReset.lua`) and one removed (`Config/FontDropdown.lua`): restart
the client once. **Before updating, close WoW and copy
`WTF\Account\<account>\SavedVariables\PlayTheGameTools.lua`**: this update
resets each display's old font, color and size settings once (the user
approved this one reset). Do R1 on your existing settings first.

| Check | Navigation | Action | Required state | Confirmation |
| --- | --- | --- | --- | --- |
| R1 Notice on an old profile | Chat after login, then `/ptg` | Read chat; read the area above the page | First login after updating, on a profile where you had changed display styling before (for example Combat Timer **Font Size** or an Experience Bar color); out of combat | One chat line: "Play The Game Tools: v2 resets each display's old font, color and size settings. Use Layout to restyle displays." A banner above the page shows the same two sentences and **Dismiss**. The Combat Timer and other styled displays show their default font, size and colors; their positions, Layout Style card values, module switches and show/hide options are unchanged |
| R2 Dismiss is stored | Banner from R1 | Click **Dismiss**; `/reload`; `/ptg` | Out of combat | The banner closes at once and the page moves up; after `/reload` there is no banner and no chat line. Your later Layout changes stay |
| R3 Fresh profile is silent | Chat after login, then `/ptg` | Read chat and the area above the page; then quit and put your copied `PlayTheGameTools.lua` back | WoW closed first; move `PlayTheGameTools.lua` out of SavedVariables so the addon starts with no settings; then log in, out of combat | No chat line about styling and no banner: a new profile has nothing to reset |
| R4 Default look, styled in Layout | `/ptg` → sidebar **Combat Timer**; then header **Layout** → click the Combat Timer display | Read the page; on the Style card set **Text size** to 150%, then click **Done** | Combat Timer on, out of combat | Below the preview, the page shows only **Behavior** (**Combat visibility**): no Font, Font Size, Text outline, Text Color, Background Color or Frame scale rows. The timer text grows from its default size |
| R5 No styling rows left | `/ptg` → sidebar **Profession & Food Bars**, **Experience Bar**, **Campfire Monitor**, **Rogue Tools** (Rogue only) | Scroll each page | Out of combat | No font, size, color, texture, border or icon-size rows. Show/hide switches, **Show Tooltips**, **Food Tooltips**, **Session Tracking** (**Reset Session**) and the Campfire **Show** switches remain |
| R6 Rogue Customize | `/ptg` → sidebar **Rogue Tools** → **Display** | Click **Customize Reminder**; click **Done**; click **Customize Quick Access** | Rogue, module on with **Poison Reminder** and **Quick Access Poisons** on, out of combat | Each opens Layout with that display selected and its Style card open |
| R7 Search "rogue" | `/ptg` → **Search** box | Type `rogue` | Rogue, out of combat | Every result names a real setting or page (for example "Rogue Tools > Display > Customize Reminder"); none ends in an empty "Rogue Tools > Display >" |
| R8 Search "Open Guild" | `/ptg` → **Search** box | Type `open guild`; click the **Open Guild** result | Out of combat | The Guild page opens at the top and the page header's **Open Guild** button is briefly outlined |

## Dungeon Loot

Run the smoke test/build and these focused checks:

```
python tests/dungeon_loot.py
python tests/dungeon_loot_map.py
python tests/dungeon_loot_catalog.py
python tests/dungeon_loot_standalone.py
python tests/dungeon_loot_player.py
python tests/dungeon_loot_completion.py
python tests/dungeon_loot_shortcut.py
python tests/dungeon_loot_quick_icon.py
python tests/browser_windows.py
```

The catalog suite traverses all bundled browsable dungeons, every boss/source and
quest pane, preview non-interactivity, read-only provider state, independent
selections/search, artwork metadata, conservative location joins and lazy reads.
Map checks cover native pin pooling, zoom/levels, cleanup, missing templates and
provider failures. Mock tests establish neither native rendering nor actual drops
or quest availability. See [exact native review paths](docs/DUNGEON_LOOT.md#native-review--expansion-pending).
The owner accepted SFK; standalone catalog review and screenshots remain pending.
Disable DungeonJournal, Questie and QuestieDB for the native baseline checks.
Restart the client to load the new TOC files; preserve SavedVariables.

Player-quest revision: tests cover both factions, multiple classes and allowed
class lists, prerequisite filtering, colored card totals, live pickup/abandon
updates, unavailable API/identity states, event cleanup and SFK collection-stage
aliases. The owner confirmed the PR #8 revision works as intended in-game on
2026-11-07 and authorized merging. Retain the exact regression checks in
[Player eligibility and quest-log progress](docs/DUNGEON_LOOT.md#player-eligibility-and-quest-log-progress).
Completion/layout revision: the new suite verifies native completion flags,
Ruins' six-task total, preserved chain stages and controls, unrelated title/variant
isolation, cycle guards, full source-ID coverage, status labels, title/footer
anchors and bracket jumps. The owner confirmed the revised behavior in-game;
exact regression paths remain in docs/DUNGEON_LOOT.md. This does not establish
every catalog fact or server availability.
Screenshots: pending.

## Campfire Monitor and Loot Sparkles (v2 split)

Run `python tests/gameplay_split.py`, `python tests/campfire_monitor.py`,
`python tests/loot_sparkles.py`, `python tests/city_labels.py` and
`python tests/global_settings.py`. These are mock checks. A new TOC file
(`Config/Chips.lua`) was added: restart the client once, then use `/reload` OOC.
Do S1 first on your existing settings, before changing any switch.

| Check | Navigation | Action | Required state | Confirmation |
| --- | --- | --- | --- | --- |
| S1 Switches carried over | `/ptg` → sidebar **Campfire Monitor**, then **Loot Sparkles** | Read each page header switch and sidebar dot | First login after updating; note beforehand whether Gameplay Enhancements, Enable Loot Sparkles and Enable Campfire Monitor were on | Two separate rows, no **Gameplay Enhancements** row. Loot Sparkles is on only if Gameplay Enhancements and Enable Loot Sparkles both were; Campfire Monitor is on only if Gameplay Enhancements and Enable Campfire Monitor both were. Campfire show/hide switches and contribution switches are as before (its sizes, fonts and colors are reset once by the v2 styling reset: see R1) |
| S2 No inner switches | `/ptg` → sidebar **Campfire Monitor** → **General** group; `/ptg` → sidebar **Loot Sparkles** | Read the options | Out of combat | Campfire General shows **Show In Combat**, **Preview** and **Refresh Status** but no **Enable Campfire Monitor**; Loot Sparkles has no **Enable Loot Sparkles** |
| S3 Independent switches | `/ptg` → sidebar **Campfire Monitor**, then sidebar **Loot Sparkles** | Turn Campfire Monitor on and Loot Sparkles off with each page header switch; stand near a campfire | Out of combat, near a campfire | The Campfire display shows; no sparkles appear over ore, herbs or corpses |
| S4 Loot Sparkles restores game settings | `/ptg` → sidebar **Loot Sparkles** | Turn the page header switch on, then off; type `/console SoftTargetInteract` before and after | Out of combat | While on, sparkles mark nearby targets; after off, the value is what it was before you turned Loot Sparkles on |
| S5 Sparkle On chips | `/ptg` → sidebar **Loot Sparkles** → **Sparkle On** group | Click **Ore Veins** off, look at an ore vein, click it on again | Loot Sparkles on, out of combat, near ore | The chips wrap on one or more lines; **Ore Veins** shows unselected and no sparkle appears on ore; selected again, the sparkle returns |
| S6 Positions and styles kept | **Layout** button in the window header | Look at **Campfire Monitor**, **Camp Buffs** (if separate) and **Camp Contributions**; click one and read its Style card | Campfire Monitor on, out of combat | Each display sits where it was before the update with the same Scale, Opacity, Text size and Background; **Settings** on the card opens the Campfire Monitor page |
| S7 Old search terms | `/ptg` → **Search** box | Type `gameplay enhancements`, then `campfire`, then `camp contributions` | Out of combat | The first lists both Campfire Monitor and Loot Sparkles; the other two open Campfire Monitor first |
| S8 Map Labels chips | `/ptg` → sidebar **Map Labels** → **Services** group | Click **Mailboxes** and **Other Faction**, open the world map; click them again | Map Labels on, out of combat | Both chips show selected; mailbox icons and the other faction's labels appear, then disappear when unselected |
| S9 Map Labels source line | `/ptg` → sidebar **Map Labels**, scrolled to the end of the page | Read the source line; click **Full notice in About** | Out of combat | One line reads "Locations: Efficient Games (CC BY 4.0), with CMaNGOS classic-db (GPL-3.0) where none is recorded yet."; the button opens **Settings**, scrolls to About and briefly highlights **Data sources**, which shows the full notice |

For the detailed Campfire checklist see
[Campfire Monitor](docs/CAMPFIRE_MONITOR.md#static-validation-and-native-checklist);
since the v2 split its page is sidebar **Campfire Monitor**, one scroll with the
**General**, **Campfire Icon**, **Camp Buffs** and **Camp Contributions** groups
(not a second section of Gameplay Enhancements), and its switch is the page
header switch.
Loot Sparkles has scoped positive owner feedback; Campfire Monitor requires
native review. Campfire benefits are earned player buffs,
not a detected inventory of objects at a nearby camp. Screenshots: pending.

Dungeon Loot shortcut revision: run dungeon_loot_shortcut.py for binding payload
validation/execution, direct routing, drag/click separation, position persistence,
lock/show/reset controls, combat guards, deferred creation and invalid profile
preferences. Initial installation requires a client restart for the new
TOC/root binding files; subsequent Lua-only Quick Icon fixes use /reload.
Native appearance and binding registration remain pending. Exact paths are recorded in
docs/DUNGEON_LOOT.md under Standalone shortcut and keybinding.

Quick Icon revision: dungeon_loot_quick_icon.py covers native texture dimensions,
circular ring, size/opacity, shared Edit Mode selection/drag/coordinates and mouse
restoration, inline binding field/capture/override/save/rollback/clear and input cleanup.
The failed blue-square prototype is not native acceptance for this replacement.
Use the exact revised checklist in docs/DUNGEON_LOOT.md; `/reload` applies these
Lua-only edits once the initial PR's files are loaded. Native review pending.

Binding-field refinement: verify an already-bound key can replace its previous
action using the Dungeon Loot page -> Keybinding -> Set Keybinding (General before v2 wave 2); the adjacent field shows
its key or Not bound after Clear Keybinding. Automated coverage includes occupied
key capture, failed-save restoration of the overwritten action and previous
Dungeon Loot keys, and live field updates. The Quick Icon revision has positive
owner confirmation; the owner also confirmed the final binding refinement
working on 2026-11-07 and authorized merging PR #14. The checks above remain
regression guidance; no release publication is authorized.
