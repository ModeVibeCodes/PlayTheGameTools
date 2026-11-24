# Play The Game Tools 0.3.0 candidate testing

Mode module layout rollout: run `tests/mode_module_layouts.py` and the full
regression suite. The [page-by-page native checklist](docs/MODE_MODULE_LAYOUTS.md#exact-in-game-checks)
covers the owner-approved Campfire pattern across the remaining module settings.
Mode only; use `/reload` OOC. Broad native acceptance is still pending.

SharedMedia pack integration: run tests/shared_media.py. After OOC reload, Global
Settings → Appearance → SharedMedia should report Ready for the installed pack;
its fonts/textures/borders and optional MyMedia choices should have plain names.

Disabled-provider media: run tests/media_discovery.py and use the
[known-path/cache native check](docs/GLOBAL_SETTINGS.md#validation-and-native-checklist).
Test providers already disabled; PTG must not change their enabled state.

Global Settings: use the exact [four-tab native checklist](docs/GLOBAL_SETTINGS.md). Run tests/global_settings.py for bundled LSM/media, standard game font inheritance and local overrides, account-wide profile selection/import/export/positions, class picker, native loot-session cancellation, camera/scale readback and combat guards.

Experience Bar: follow [the focused checklist](docs/ENHANCED_EXPERIENCE_BAR.md#validation-and-exact-native-checks)
on its local feature branch. Enable under Questing & Leveling; native acceptance
is pending.

Sidebar paths: since the v2 window the sidebar has no category headings. A path
such as "Timers → Combat Timer" means the **Combat Timer** row in the A–Z list;
"Global Settings" means the **Settings** row pinned at the bottom. Header
**Reload** is now the **Reload now** button in the banner above the page.

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
2. **Navigation:** Play The Game Tools → Questing & Leveling → Class Training → General → Level Up Window.
   **Action:** Record its current value, change it, reload using `/reload`, then
   reopen the same page. Restore your preferred value afterward.
   **Required state:** OOC, Class Training enabled; retain existing settings.
   **Confirmation:** The explicit value persists; existing module preferences and
   positions remain. Do not delete your settings to make a failed upgrade pass.
3. **Navigation:** Play The Game Tools → Timers → Combat Timer; Play The Game Tools → Quality of Life
   → Automation / Class Training.
   **Action:** Visit each page and close/reopen configuration with `/ptg`.
   **Required state:** OOC; no feature needs enabling merely to inspect pages.
   **Confirmation:** Pages render, text/art/scrolling work; no absent Retail module
   or prototype is advertised as usable. Optional media addons are not required.

For clean-install defaults, use a separate test account/client settings setup;
never erase the developer's working SavedVariables. Confirm Class Training on,
Combat Timer/Automation off, and no automatic training popout on login. This is a
separate result from the existing-settings upgrade check above.

## B. Training and positioning

1. **Navigation:** Play The Game Tools → Questing & Leveling → Class Training →
   Upcoming Abilities / Available & Known tabs.
   **Action:** Learn a rank at a trainer (or level up), return to the page without
   reloading, and inspect known/unknown ranks against your spellbook and
   an ordinary class trainer. Record mismatched ability/rank/level/cost examples.
   **Required state:** OOC, enabled module, supported current class.
   **Confirmation:** Only your class appears; learned/superseded ranks are handled
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
4. **Navigation:** Play The Game Tools → Quality of Life → Class Training → Level-Up Window
   tab → Level-Up Window row → Preview button.
   **Action:** Preview; vary Time to Level, Player Money, Professions, Secondary
   Professions and Window Width / Window Scale / Detail Text Size.
   **Required state:** OOC; no actual level gain required for preview.
   **Confirmation:** Preview is readable, optional summaries follow preferences,
   and settings survive reload. Record actual Level-Up Alerts separately on the
   next naturally occurring level gain; preview does not validate that event.
5. **Navigation:** Play The Game Tools → Questing & Leveling → Class Training →
   Level Up Window section → Guild Ding Message and Time to Level toggles; then the
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

1. **Navigation:** Play The Game Tools → sidebar **Combat Timer** → page header switch
   (unlabeled, top right of the page).
   **Action:** Enable, close configuration, enter and leave ordinary combat.
   **Required state:** OOC to configure; ordinary combat to observe.
   **Confirmation:** Elapsed time advances during combat and follows the configured
   visibility afterward. Disable OOC and confirm its display stops.
2. **Navigation:** Play The Game Tools → Timers → Combat Timer → Display tab → Font Size.
   **Action:** Change font size, observe the sample, reload OOC and revisit.
   **Required state:** OOC; restore preferred size afterward.
   **Confirmation:** Sample and actual timer follow the chosen size and retain it.

## D. Automation (opt-in actions)

Review each switch before enabling the Automation header switch. Test on ordinary
interactions you intend to perform: quest actions, sales and repair spend/change
game state. Leave a feature off if you are not ready to exercise it.

1. **Navigation:** Play The Game Tools → Global Settings → Optimizations → Auto Loot.
   **Action:** Enable Auto Loot OOC, inspect Applied Settings and the native loot
   setting. Disable it afterward if desired; Automation may remain disabled.
   **Required state:** OOC, native setting available.
   **Confirmation:** Native Auto Loot follows the selected on/off value after its
   initial preference adoption; profile changes restore that choice. Unavailability is explicit.
2. **Navigation:** Play The Game Tools → Quality of Life → Automation → Quests → Auto Accept
   Quests / Auto Turn-In Quests / Modifier Bypass.
   **Action:** Select Shift; test an ordinary eligible offer/turn-in, then hold
   Shift while opening the next interaction. Inspect a multiple-choice reward.
   **Required state:** OOC, master enabled, only intended actions opted in.
   **Confirmation:** Eligible actions happen once; bypass and multiple-choice
   rewards remain manual; no unintended reward/payment/confirmation handling.
3. **Navigation:** Play The Game Tools → Quality of Life → Automation → Merchant → Auto Sell
   Junk / Auto Sell Gray Equipment / Auto Repair / Maximum Repair Cost (%).
   **Action:** Keep gray equipment off; test unwanted gray non-equipment at a
   merchant and a repair bill within your chosen percentage, then test opt-out.
   **Required state:** OOC, master enabled, disposable intended junk and personal
   funds; inspect options before opening merchant. No developer item injector exists.
   **Confirmation:** Eligible junk only sells; gray equipment remains; repair uses
   personal funds once within threshold; disabled features leave actions manual.
4. **Navigation:** Play The Game Tools → Quality of Life → Automation.
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
| L1 Turn on | `/ptg` → Quality of Life → Map Labels | Click the switch at the top right of the page, then open the world map (M) on your capital (Stormwind, Orgrimmar, Thunder Bluff or Undercity) | Out of combat | Switch reads **Enabled**; **Class Trainers** and **Profession Trainers** both read **Mine**; icons with names mark **Bank**, **Auction House**, **Flight Master**, **Inn**, your class's trainer and trainers for professions you know only; no Lua error |
| L2 Icons | World map on your capital, zoomed in | Look at each label | L1 done | Each label is a game icon in a thin colored edge: your class icon on your class trainer, your profession's icon on its trainer, a bag on **Bank**, coins on **Auction House**, a hearthstone on **Inn**; a plain colored dot appears only if an icon file is missing |
| L3 Undercity gaps | World map on Undercity (Horde, or **Other Faction** ticked) | Set **Profession Trainers** to **All**, then find **Alchemy**; set **Class Trainers** to **All**, then find **Warlock Trainer** | Out of combat | **Alchemy** labels near 47, 75 and 51, 75; **Warlock Trainer** near 87, 16 in the Rogues' Quarter, whose tooltip reads **Classic position: may differ where Forever moved an NPC.** and **Location: CMaNGOS classic-db (GPL-3.0)** |
| L4 Tooltip | World map on your capital | Hover the **Bank** icon | L1 done | Tooltip lists the bankers and **Guild Vault**, then **Approximate: where players stood to use it.** and **Locations: Efficient Games (CC BY 4.0)** |
| L5 Clicks pass through | World map zoomed into your capital | Left-click an icon, then right-click it | L1 done | The map zooms in and out as if the icon were not there |
| L6 Trainer modes and filters | `/ptg` → Quality of Life → Map Labels | Set **Class Trainers** and **Profession Trainers** to **All**, then **Off**, then back to **Mine**; under **Labels** tick **Mailboxes**; under **Filters** tick **Other Faction**; reopen the map each time | Out of combat | **All** adds every class's and profession's trainers, **Off** removes them, **Mine** restores yours; mailbox icons without names and the other faction's labels appear while ticked |
| L7 Appearance | `/ptg` → Quality of Life → Map Labels → **Appearance** (in the mode theme, the **Appearance** tab) | Drag **Icon Size** to 24 and **Name Size** to 14, reopen the map; then untick **Show Names** under **Filters** | Out of combat | Icons and names are larger; with **Show Names** off only icons remain |
| L8 Turn off and combat start | `/ptg` → Quality of Life → Map Labels; later a fresh login | Click the switch at the top right of the page and open the map; switch it back on, log in again, enter combat before first opening the map, and open it after combat | Combat, then out of combat | Switch reads **Disabled** and no Map Labels icons show; after re-enabling, labels appear once combat has ended; no Lua error |

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
| T3 Selectors and inputs | Blizzard active; Global Settings → Appearance, a module's Positioning section, the search box | Click options; type in the search box | Out of combat | Selected option has a gold outline; input borders show no square corners |
| T4 Return to Modern | `/ptg` → sidebar **Settings** → Appearance → Interface Theme | Click **Modern**, then **Reload now** in the banner | Out of combat | Window shows the Modern graphite look: dark sidebar column, slightly lighter canvas, outlined header buttons |
| T5 Fresh-launch labels | Quit WoW fully, relaunch | Type `/ptg` as soon as you are in the world | Out of combat | Sidebar labels and the window title are visible, at worst after about a second |
| T6 Threat Meter | `/ptg` → Quality of Life → Threat Meter (enabled); in a group with a tank, or with your pet tanking | Attack the tank's target and keep adding threat until your row shows 90% or more without taking aggro; then stop and let it fall back | In combat | Header strip and class-coloured bars; your row has an accent stripe in its own gap left of the bar, not on the bar; at 90% or more that stripe turns red and a thin red frame surrounds your bar; below 90%, or once you hold aggro, both return to the plain accent stripe. Repeat once with the **Blizzard** theme: the red is clearly different from the gold stripe |
| T7 Modern edges and hover | Modern active; `/ptg` | Look at **Layout**, **X**, the **Search** box and Settings → Appearance → Interface Theme without hovering, then hover each | Out of combat | Every control shows a visible outline at rest; hovering lifts its fill; **Modern** has a solid mint outline and **Blizzard** a grey one |
| T8 Modern navigation and sections | Modern active; click a sidebar entry, then a module with several sections | Compare the selected sidebar entry with the others; scroll the page | Out of combat | Selected entry has a mint bar on its left edge; sections are separated by clearly more space than rows; dividers are visible but quiet |
| T9 Modern checkboxes and sliders | Modern active; sidebar **Automation**, then **Combat Timer** → **Display** | On Automation tick and untick any box; on Combat Timer drag the **Font Size** slider | Out of combat | Ticked box shows a mint square on a faint mint wash with a mint edge; slider track is a thick grey bar filled mint up to the thumb |
| T10 Solid Dungeon Loot text | `/ptg` → Questing & Leveling → Dungeon Loot (enabled) | On **Dungeons** read the card titles and Suggested Starting Levels headings; open a dungeon and view **Boss Loot** and **Quests** | Out of combat | Every heading, card title, list entry and NPC name is one solid colour; the selected tab underline is one solid accent; bracket headings sit over a plain hairline |
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
| V7 Reload banner | `/ptg` → **Settings** → Appearance → Interface Theme | Click a theme other than the current one; open another page; click the current theme again; pick the other theme and click **Reload now** | Out of combat | A banner "Applies after a reload" with the theme reason and **Reload now** shows above every page while the change is pending, disappears when you pick the current theme back, and **Reload now** reloads the UI |
| V8 Reload in combat | Banner showing (V7 before reloading) | Enter combat, click **Reload now** | In combat | No reload; the banner says reload is unavailable during combat (also printed in chat) |
| V9 Search | `/ptg` → **Search** box | Type `font`; click a setting result; then type `threat` and press Enter; then type `zzzz` and press Escape | Out of combat | While typing, results (name and page beneath) replace the list; a click opens that page and briefly highlights the setting; Enter opens the first result; `zzzz` says "Nothing matches"; Escape clears it and the list returns |
| V10 Last page | `/ptg` → **Threat Meter** | Close with **X**, type `/ptg` | Out of combat | Reopens on Threat Meter. After `/reload`, the first `/ptg` opens on **Automation** (first A–Z) |
| V11 Developer Mode | Type `/ptg dev` | Read the page | Out of combat | Settings opens on Developer Mode (no switch in its page header); it is not in the sidebar |

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

## Gameplay Enhancements / Campfire Monitor

Use the exact Navigation/Action/Required state/Confirmation checklist in
[Campfire Monitor](docs/CAMPFIRE_MONITOR.md#static-validation-and-native-checklist).
Loot Sparkles has scoped positive owner feedback; the new two-tab layout and
campfire monitor require native review. Campfire benefits are earned player buffs,
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
action using General -> Keybinding -> Set Keybinding; the adjacent field shows
its key or Not bound after Clear Keybinding. Automated coverage includes occupied
key capture, failed-save restoration of the overwritten action and previous
Dungeon Loot keys, and live field updates. The Quick Icon revision has positive
owner confirmation; the owner also confirmed the final binding refinement
working on 2026-11-07 and authorized merging PR #14. The checks above remain
regression guidance; no release publication is authorized.
