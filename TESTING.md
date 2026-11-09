# Play The Game Tools 0.2.0-beta.1 candidate testing

Disabled-provider media: run tests/media_discovery.py and use the
[known-path/cache native check](docs/GLOBAL_SETTINGS.md#validation-and-native-checklist).
Test providers already disabled; PTG must not change their enabled state.

Global Settings: use the exact [four-tab native checklist](docs/GLOBAL_SETTINGS.md). Run tests/global_settings.py for bundled LSM/media, standard game font inheritance and local overrides, account-wide profile selection/import/export/positions, class picker, native loot-session cancellation, camera/scale readback and combat guards.

Enhanced Experience Bar: follow [the focused checklist](docs/ENHANCED_EXPERIENCE_BAR.md#validation-and-exact-native-checks)
on its local feature branch. Enable under Questing & Leveling; native acceptance
is pending.

Record PASS / FAIL / NOT TESTED for each item, with version, client build, class
and level. These instructions do not claim native acceptance. Do one chunk at a
time; start with A. Stop and report startup/errors/settings loss before continuing.

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
   **Confirmation:** AddOns metadata reports Play The Game Tools, author Mode and version
   0.2.0-beta.1; configuration opens without a Lua error or wrong-edition message.
2. **Navigation:** Play The Game Tools → Quality of Life → Class Training → Show Shortcut.
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

1. **Navigation:** Play The Game Tools → Quality of Life → Class Training → Spellbook row
   → Refresh button; tabs To Learn / Upcoming / Learned / Directory.
   **Action:** Refresh and inspect known/unknown ranks against your spellbook and
   an ordinary class trainer. Record mismatched ability/rank/level/cost examples.
   **Required state:** OOC, enabled module, supported current class.
   **Confirmation:** Only your class appears; learned/superseded ranks are handled
   sensibly, estimates remain estimates, uncertain entries are not guaranteed offers.
2. **Navigation:** Play The Game Tools → Quality of Life → Class Training → Show Shortcut;
   Quick Actions button → green Class Training icon → Minimize / Jump to Settings.
   **Action:** Turn Show Shortcut on, click the book, scroll, minimize, reopen,
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

1. **Navigation:** Play The Game Tools → Timers → Combat Timer → module header switch
   (unlabeled, beside Enabled/Disabled).
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
4. **Navigation:** Play The Game Tools → Quality of Life → Automation → Dialogue → Auto Gossip.
   **Action:** Inspect the disabled control and Auto Gossip Availability note.
   **Required state:** OOC.
   **Confirmation:** Explicitly unavailable/deferred; dialogue stays manual.

## E. Guild Recruitment

1. **Navigation:** Play The Game Tools â†’ Guild Tools â†’ Recruitment.
   **Action:** Turn the page switch on, set Minimum Level / Maximum Level, pick one
   class, click Open Recruiter, then click Scan in the Recruiter window.
   **Required state:** OOC, in a guild with invite permission.
   **Confirmation:** One Who search runs; the Who window closes again if it was not
   already open; unguilded players in range appear in the list with class colors.
2. **Navigation:** Recruiter window (Open Recruiter or `/ptgr`).
   **Action:** With candidates listed, click Scan again after the countdown.
   **Required state:** Candidates present, Scan button not counting down.
   **Confirmation:** The list empties before the next search's results appear.
3. **Navigation:** Recruiter window.
   **Action:** Click Invite on a row, press Ctrl+C, open Guild â†’ Add Member,
   paste and confirm.
   **Required state:** OOC, invite permission, a willing test player.
   **Confirmation:** The copy box shows the name; the game invites without a
   blocked-action message; Statistics show Invited +1 (and Joined/Declined after
   the reply); no whisper is sent.
4. **Navigation:** Recruiter window.
   **Action:** Type a message longer than 255 characters in the Whisper message
   box, then click Whisper on a row without pressing Enter.
   **Required state:** OOC, candidates listed, a willing test player.
   **Confirmation:** The box scrolls as you type; the player receives the whole
   message as consecutive whispers with no blocked-action message; the row leaves
   the list; Statistics do not change.
5. **Navigation:** Recruiter window, then Guild Tools â†’ Recruitment â†’ History.
   **Action:** Click X on a row, scan again, then click Clear Never-Invite List.
   **Required state:** OOC.
   **Confirmation:** The X'd player no longer appears until the list is cleared;
   invited players stay hidden for the saved re-invite window (7 days by default).

## Guild Roster

Run `python tests/guild_roster.py`. Mocks do not establish native member data, so
these checks need the game client. New Lua files need one full client restart.

| Check | Navigation | Action | Required state | Confirmation |
| --- | --- | --- | --- | --- |
| R1 Turn on | `/ptg` → Guild Tools → Roster | Click the switch at the top right of the page | Logged in on a character in a guild | Switch reads **Enabled**; **Class Summary** shows **Total Members** and all nine classes with a count, including 0 |
| R2 Members by class | `/ptg` → Guild Tools → Roster | Scroll to the bottom of **Members by Class**, then compare with the native guild window | R1 done | Each class with members has a colored heading such as **Mage (12)** and its names alphabetically; **Total Members** matches the native member count; offline members are included |
| R3 Totals agree | `/ptg` → Guild Tools → Roster | Compare each **Class Summary** count with the number in that class's heading | R1 done | Every count matches its heading |
| R4 No guild | `/ptg` → Guild Tools → Roster | Open the page | Roster enabled on a character not in a guild | Page reads **You are not in a guild.** and **Total Members: 0**, with no Lua error |
| R5 Turn off | `/ptg` → Guild Tools → Roster | Click the switch at the top right of the page | Roster enabled | Switch reads **Disabled**; names are cleared and the page asks you to turn on the switch |

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
| T1 Choose Blizzard | `/ptg` → Dashboard → Appearance → Interface Theme | Click **Blizzard**, then **Reload** in the window header | Out of combat | Header **Reload** shows pending before the click; after reload `/ptg` shows the gold dialog border, opaque dark stone, red header buttons, stock checkboxes and gold headings |
| T2 Text fit | Blizzard active; open each sidebar entry | Read sidebar items, Dashboard module rows, dropdowns and search results | Out of combat | No clipped or overlapping labels in the game font |
| T3 Selectors and inputs | Blizzard active; Dashboard → Appearance, a module's Positioning section, the search box | Click options; type in the search box | Out of combat | Selected option has a gold outline; input borders show no square corners |
| T4 Return to Modern | `/ptg` → Dashboard → Appearance → Interface Theme | Click **Modern**, then **Reload** | Out of combat | Window shows the Modern graphite look: dark sidebar column, slightly lighter canvas, outlined header buttons |
| T5 Fresh-launch labels | Quit WoW fully, relaunch | Type `/ptg` as soon as you are in the world | Out of combat | Sidebar labels and the window title are visible, at worst after about a second |
| T6 Threat Meter | Quality of Life → Threat Meter enabled | Target an enemy; unlock the meter | Any | Header strip, class-coloured bars, accent edge on your row; "Drag to move" while unlocked |
| T7 Modern edges and hover | Modern active; `/ptg` → Dashboard | Look at **Reload**, **Preview**, **Edit Mode**, **X**, the **Search settings...** box and Appearance → Interface Theme without hovering, then hover each | Out of combat | Every control shows a visible outline at rest; hovering lifts its fill; **Modern** has a solid mint outline and **Blizzard** a grey one |
| T8 Modern navigation and sections | Modern active; click a sidebar entry, then a module with several sections | Compare the selected sidebar entry with the others; scroll the page | Out of combat | Selected entry has a mint bar on its left edge; sections are separated by clearly more space than rows; dividers are visible but quiet |
| T9 Modern checkboxes and sliders | Modern active; sidebar **Quality of Life** → **Automation**, then **Timers** → **Combat Timer** → **Display** | On Automation tick and untick any box; on Combat Timer drag the **Font Size** slider | Out of combat | Ticked box shows a mint square on a faint mint wash with a mint edge; slider track is a thick grey bar filled mint up to the thumb |
| T10 Solid Dungeon Loot text | `/ptg` → Questing & Leveling → Dungeon Loot (enabled) | On **Dungeons** read the card titles and Suggested Starting Levels headings; open a dungeon and view **Boss Loot** and **Quests** | Out of combat | Every heading, card title, list entry and NPC name is one solid colour; the selected tab underline is one solid accent; bracket headings sit over a plain hairline |
| T11 Recruitment page | `/ptg` → Guild Tools → Recruitment | Scroll the page, then click **Open Recruiter** | Out of combat | Page shows only Recruiter (**Open Recruiter**) and History (**Clear Invite History**, **Clear Never-Invite List**, **Reset Statistics**); the Recruiter window still has Level range, Levels per search, Classes and the whisper box, and saved values are as before |

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
