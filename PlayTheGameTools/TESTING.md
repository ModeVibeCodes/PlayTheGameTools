# Play The Game Tools 0.2.0-beta.1 candidate testing

Paths read "sidebar → Module → section": the module's row in the A–Z sidebar
list, then a titled group on its page. Every page is one vertical scroll (page
header, then each section top to bottom) with no category headings, pills or
tabs; "Settings" is the row pinned at the bottom of the sidebar. Display styling
(fonts, sizes, colors) is edited in **Layout**, not on module pages.

Record PASS / FAIL / NOT TESTED for each item, with version, client build, class
and level. These instructions do not claim native acceptance. Do one chunk at a
time; start with A. Stop and report startup/errors/settings loss before continuing.

## v2: Campfire Monitor and Loot Sparkles

Gameplay Enhancements is now two sidebar entries, **Campfire Monitor** and
**Loot Sparkles**, each with its own page header switch; Map Labels' services
and Loot Sparkles' targets are chips. Use checks S1–S9 in the repository's
TESTING.md ("Campfire Monitor and Loot Sparkles (v2 split)"). Do S1 first on
your existing settings. A new file was added: restart the client once.

## v2: styling reset

This update resets each display's old font, color and size settings once per
profile (approved by the user) and shows a one-time notice. **Close WoW and
copy `WTF\Account\<account>\SavedVariables\PlayTheGameTools.lua` first.**
Use checks R1–R8 in the repository's TESTING.md ("v2 styling reset"); do R1
on your existing settings first, and R3 for a fresh profile. One file was
added and one removed: restart the client once.

## A. Package and first startup

Use the attached `PlayTheGameTools-0.2.0-beta.1-forever.zip`, not GitHub's source archive.
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
   0.2.0-beta.1; configuration opens without a Lua error or wrong-edition message.
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
   Upcoming Abilities / Available & Known tabs (their own window since v2).
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
   click Jump to Settings; move the Quick Actions button near screen edges in Layout.
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
