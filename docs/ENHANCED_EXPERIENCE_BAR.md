# Enhanced Experience Bar

Forever only; opt-in tenth module. Open `/ptg`, expand **Questing & Leveling**,
then select **Enhanced Experience Bar**. Uses the addon's shared **Edit Mode**
workspace for its owned frame. Existing modules, settings and stock XP UI stay intact.

## Behavior

- Flat fill by default; **Blizzard Style Texture** uses native Forever XP/rested
  fill atlases with flat fallback. Normal purple/rested blue is the default;
  disable **Use Native XP Colors** to customize/tint the XP fill.
- Current XP fills the full height. Independent forecasts start at its edge:
  rested bonus pool on the upper half, completed quest XP on the lower half.
  **Forecast Opacity** reaches 100% opaque. Forecasts clip at the next-level edge;
  labels retain full percentages of the current level requirement, even above
  100%. Rested XP is not added to or multiplied into quest rewards.
- Completed quests are deduplicated by ID. Incomplete/failed quests are excluded.
  Missing/restricted rewards are not invented. Collapsed headers may hide quests:
  expand them in the native quest log for a complete scan. Partial totals show
  `Quests >=... (incomplete)`. Quest selection/header state is never changed.
  Server-side bonuses and next-level reward scaling may differ from the estimate.
- XP/log data refresh on relevant events; no quest polling. One one-second ticker
  updates only session text. Disable removes events and cancels the ticker.
- Session time and XP/hr start at enable or `/reload`, include idle time and
  exclude earlier XP. One-level rollover includes the previous level remainder;
  missing/multiple-level gaps mark rate `~`. **Reset Session** starts over.
  Counters are runtime only; character/profile reloads do not share a session.
- Width/height/scale, opacity, font/sizes/outline, alignment, text offset, session
  placement/gap, label visibility, colors and managed anchors/offsets are editable
  OOC. Normal play is position-locked; Edit Mode permits movement. Max-level hiding
  defaults on, with explicitly marked sample data in Preview/Edit Mode.

## API research and licensing

Inspected current `forever` Blizzard UI source on 2026-11-07. Independent code;
no reference addon code/assets or Blizzard implementation bodies copied.
Existing project licenses/notices remain applicable.

- [Native XP bar](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_StatusTrackingBar/Shared/ExpBar.lua):
  `UnitXP`, `UnitXPMax`, `UnitLevel`, `GetXPExhaustion`, `GetRestState`,
  `IsXPUserDisabled`, effective-max-level check and XP/resting events.
- [Native texture overrides](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_StatusTrackingBar/Mainline/ExpBarOverrides.lua):
  `UI-HUD-ExperienceBar-Fill-Experience` / `UI-HUD-ExperienceBar-Fill-Rested`.
- [Quest log API](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLogDocumentation.lua):
  `C_QuestLog.GetNumQuestLogEntries`, `GetInfo`, `IsComplete`; visible entry count.
- [Native QuestInfo](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_UIPanels_Game/Vanilla/QuestInfo.lua)
  retains the reward-XP API reference but suppresses its stock display.
  **Uncertainty:** `GetQuestLogRewardXP(questID)` needs native Forever confirmation;
  unavailable results visibly mark the total incomplete. Static checks do not
  prove availability, reward accuracy, level-up ordering or native rendering.

The local test setup uses the existing owner-authorized Forever addon junction.
Preserve it and SavedVariables. New TOC files may require a full client restart
if `/reload` does not discover them. This does not publish a release.

## Validation and exact native checks

Run `python tests/enhanced_experience_bar.py` (also smoke),
`python tests/campfire_editmode.py`, `python tests/camp_contributions_startup.py`,
`python tests/dungeon_loot_standalone.py`, `python tests/loot_sparkles.py` and
`python tools/build_release.py`. Native acceptance and screenshots remain pending.

2026-11-07: all six listed validation commands passed locally, including smoke
and the deterministic release build (99 Lua / 174 packaged files). These are
Lua 5.1 mock/static results; no in-game acceptance is claimed.

1. **Navigation:** Chat input → `/reload`, then `/ptg` → Play The Game Tools →
   Questing & Leveling → Enhanced Experience Bar → General →
   Enable Enhanced Experience Bar; **Action:** reload and enable on a leveling
   character; **Required state:** OOC with feature branch installed;
   **Confirmation:** bar shows current XP %, rested % and completed quest % without
   errors. Restart the client if the new page/files are not discovered.
2. **Navigation:** Native Quest Log → zone headers, then Play The Game Tools →
   Questing & Leveling → Enhanced Experience Bar → General → Forecasts;
   **Action:** expand all headers, complete a quest without turning it in, then
   turn it in; **Required state:** OOC, below max level; **Confirmation:** lower
   forecast/quest percent grows on completion and drops on turn-in as XP rises.
   Compare with native reward XP. Collapsing a header marks the estimate incomplete.
3. **Navigation:** Play The Game Tools → Questing & Leveling → Enhanced Experience
   Bar → Layout → Forecast Opacity; **Action:** set 100%, toggle Show Rested Overlay
   and Show Quest Overlay separately; **Required state:** OOC, rested pool and
   completed XP quest available; **Confirmation:** independent upper blue/lower
   quest lanes clip at the edge without multiplying quest rewards.
4. **Navigation:** Play The Game Tools → Questing & Leveling → Enhanced Experience
   Bar → General → Blizzard Style Texture, then Layout/Text/Colors;
   **Action:** toggle texture, resize, change Font/Text Alignment/colors; disable
   Use Native XP Colors to customize XP colors; **Required state:** OOC;
   **Confirmation:** immediate readable updates; enabling native colors restores
   blue/purple. No Lua errors.
5. **Navigation:** Play The Game Tools → header → Edit Mode → Enhanced Experience
   Bar handle; **Action:** drag, exit with Escape, `/reload`; **Required state:** OOC,
   feature enabled; **Confirmation:** PREVIEW while editing; saved appearance and
   position persist, normal play locks movement. This is the addon's workspace,
   not Blizzard's Edit Mode menu.
6. **Navigation:** Play The Game Tools → Questing & Leveling → Enhanced Experience
   Bar → Session → Session Tracking → Reset Session; **Action:** reset, earn XP,
   wait and cross a level; **Required state:** leveling character, reset OOC;
   **Confirmation:** session clock/XP/hr update with no rollover spike. `/reload`
   resets counters while retaining appearance/position.
7. **Navigation:** Play The Game Tools → Questing & Leveling → Enhanced Experience
   Bar → General → Enable Enhanced Experience Bar; **Action:** disable/re-enable
   after a combat/XP gain check; **Required state:** settings OOC;
   **Confirmation:** combat XP updates without blocked-action errors, disable
   hides the bar, re-enable starts a fresh session and other features still work.
