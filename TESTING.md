# Play The Game Tools 0.2.0-beta.1 candidate testing

Record PASS / FAIL / NOT TESTED for each item, with version, client build, class
and level. These instructions do not claim native acceptance. Do one chunk at a
time; start with A. Stop and report startup/errors/settings loss before continuing.

## A. Package and first startup

Use the attached `PlayTheGameTools-0.2.0-beta.1-forever.zip`, not GitHub's source archive.
Installation is a filesystem step, not a Play The Game Tools UI control. Close WoW, back up
your existing Play The Game Tools addon folder and your own settings separately, and extract
the ZIP into an isolated Forever test installation if available. Keep one
`ModeTools` folder; never merge this into Retail. For an existing installation,
move its old addon folder to a backup location outside AddOns first, rather than
merging stale files into the new folder. Preserve WTF/SavedVariables. If using the
maintainer's existing managed live installation, request the maintainer's verified
installation procedure instead of changing it manually.

1. **Navigation:** Forever character selection → AddOns → Play The Game Tools.
   **Action:** Enable the candidate and log in; open `/modetools`.
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
   **Action:** Visit each page and close/reopen configuration with `/modetools`.
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
   green on-screen Class Training shortcut → Minimize / Full Configuration.
   **Action:** Turn Show Shortcut on, click the book, scroll, minimize, reopen,
   click Full Configuration; Shift-left-drag the shortcut near screen edges OOC.
   **Required state:** OOC, enabled module; preserve preferred final position.
   **Confirmation:** Bounded translucent list scrolls, glow follows open state,
   Minimize closes it and Full Configuration opens the Class Training page.
3. **Navigation:** Green Class Training shortcut → open popout → ordinary combat.
   **Action:** Enter and leave safe ordinary combat, then click the shortcut OOC.
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

1. **Navigation:** Play The Game Tools → Quality of Life → Automation → Convenience → Auto Loot.
   **Action:** Enable Automation and Auto Loot OOC, inspect Availability and the
   native loot setting. Disable the option afterward if desired.
   **Required state:** OOC, native setting available.
   **Confirmation:** Native Auto Loot becomes enabled; disabling this option does
   not claim to restore the previous Blizzard setting. Unavailability is explicit.
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
   paste and confirm. Repeat with Whisper After Invite on.
   **Required state:** OOC, invite permission, a willing test player.
   **Confirmation:** The copy box shows the name; the game invites without a
   blocked-action message; Statistics show Invited +1 (and Joined/Declined after
   the reply); the whisper is sent only when Whisper After Invite is on.
4. **Navigation:** Recruiter window, then Guild Tools â†’ Recruitment â†’ History.
   **Action:** Click X on a row, scan again, then click Clear Never-Invite List.
   **Required state:** OOC.
   **Confirmation:** The X'd player no longer appears until the list is cleared;
   invited players stay hidden for the Re-invite After (days) window.

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

## Dungeon Loot

Run the smoke test/build and these focused checks:

```
python tests/dungeon_loot.py
python tests/dungeon_loot_map.py
python tests/dungeon_loot_catalog.py
python tests/dungeon_loot_standalone.py
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
