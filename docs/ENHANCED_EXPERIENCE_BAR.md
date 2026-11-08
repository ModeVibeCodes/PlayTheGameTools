# Enhanced Experience Bar

Forever only; opt-in tenth module. Open `/ptg`, expand **Questing & Leveling**,
then select **Enhanced Experience Bar**. Uses the addon's shared **Edit Mode**
workspace for its owned frame. Existing modules, settings and stock XP UI stay intact.

## Behavior

- **Colors → Rested XP Overlay Color → Pick** and **Quest Log XP Overlay Color →
  Pick** customize the forecast tints independently. These stay available with
  **Use Native XP Colors** enabled; that toggle only governs the normal/rested
  XP fill. Existing custom rested tint is retained when splitting the setting.

- **Bar Texture** offers Flat, Blizzard XP, Blizzard Status Bar and registered
  SharedMedia textures, with flat fallback if unavailable. Normal purple/rested blue is the default;
  disable **Use Native XP Colors** to customize/tint the XP fill.
- Current XP fills the full height. Independent forecasts start at its edge:
  rested bonus pool and total quest log XP as full-height tints, with priority
  **current XP > rested XP > quest log XP**. Quest tint is clipped out of the
  rested span, so translucent colors do not mix. A quest forecast entirely inside
  rested coverage is hidden, while its text still reports the full total.
  **Rested Overlay Opacity** and **Quest Overlay Opacity** independently reach
  100% opaque; each tint fades against the bar background. Both forecast endpoints
  still measure from current XP (they are not added together). Forecasts clip at the next-level edge;
  labels retain full percentages of the current level requirement, even above
  100%. Rested XP is not added to or multiplied into quest rewards.
- All quests are deduplicated by ID and included regardless of completion.
  **Quest Log XP Format** offers Percent, XP Amount, or Percent and XP Amount.
  Missing/restricted rewards are not invented. Outside combat, collapsed headers
  are temporarily expanded for a bounded scan and restored in reverse order;
  original selected quest is restored if changed. Layout signatures suppress
  scans from our own header notifications. Quest add/remove/turn-in, level changes
  and reward-data events invalidate the cache. Combat defers header expansion;
  a partial total displays `Quest log >=... (incomplete)` until the OOC refresh.
  Server-side bonuses and next-level reward scaling may differ from the estimate.
- XP/log data refresh on relevant events; no quest polling. One one-second ticker
  updates only session text. Disable removes events and cancels the ticker.
- Session time and XP/hr start at enable or `/reload`, include idle time and
  exclude earlier XP. One-level rollover includes the previous level remainder;
  missing/multiple-level gaps mark rate `~`. **Reset Session** starts over.
  Counters are runtime only; character/profile reloads do not share a session.
- **Bar Text** and **Session Text** have independent fonts, sizes, outlines,
  colors, opacity, alignment and dash/dot separators. Session text also has its
  own width/horizontal offset, above/below placement and gap. Changing bar opacity
  does not fade either text element. Existing shared text preferences are copied
  into separate session defaults once, preserving the prior appearance.
- Width/height/scale, opacity, text offset, label visibility, colors and managed anchors/offsets are editable
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
  `C_QuestLog.GetNumQuestLogEntries`, `GetInfo`, `GetSelectedQuest`, `SetSelectedQuest`;
  visible entry count. Native [quest log header handlers](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_UIPanels_Game/Vanilla/QuestLogFrame.lua)
  verify `ExpandQuestHeader(logIndex)` and `CollapseQuestHeader(logIndex)`.
- [Native QuestInfo](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_UIPanels_Game/Vanilla/QuestInfo.lua)
  retains the reward-XP API reference but suppresses its stock display.
  **Uncertainty:** full-log `GetQuestLogRewardXP(questID)` totals need native Forever confirmation;
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

Owner reports the initial bar works with no errors. The screenshot confirms its
initial display, but does not establish reward totals or revised behavior. This
follow-up changes overlays, all-log scanning, texture selection and separate text;
those revisions need the native checks below.

Owner subsequently reports the XP bar looks good. Independent overlay color
pickers are the next scoped revision and still need native confirmation.

2026-11-07: all six listed validation commands passed locally, including smoke
and the deterministic release build (99 Lua / 174 packaged files). These are
Lua 5.1 mock/static results; no in-game acceptance is claimed.

1. **Navigation:** Chat input → `/reload`, then `/ptg` → Play The Game Tools →
   Questing & Leveling → Enhanced Experience Bar → General →
   Enable Enhanced Experience Bar; **Action:** reload and enable on a leveling
   character; **Required state:** OOC with feature branch installed;
   **Confirmation:** bar shows current XP %, rested % and total quest log XP without
   errors. This revision uses existing runtime files; `/reload` loads it.
2. **Navigation:** Native Quest Log → zone headers, then Play The Game Tools →
   Questing & Leveling → Enhanced Experience Bar → General → Forecasts;
   **Action:** accept an unfinished quest, collapse headers, complete it, then
   turn it in; **Required state:** OOC, below max level; **Confirmation:** total
   includes its reward before completion, does not double-count completion,
   and drops on turn-in as XP rises. Header collapse and selected quest remain
   unchanged after scanning. Compare the sum with each quest's native reward.
3. **Navigation:** Play The Game Tools → Questing & Leveling → Enhanced Experience
   Bar → Layout → Rested Overlay Opacity / Quest Overlay Opacity; **Action:** tune each, toggle Show Rested Overlay
   and Show Quest Overlay separately; **Required state:** OOC, rested pool and
   quests available; **Confirmation:** current XP has priority, then rested,
   then quest tint only beyond the rested endpoint. No color blending between
   forecasts, no split lanes, and no change to the total quest XP label.
4. **Navigation:** Play The Game Tools → Questing & Leveling → Enhanced Experience
   Bar → General → Bar Texture, then Bar Text / Session Text / Colors;
   **Action:** choose Flat, Blizzard XP, Blizzard Status Bar and an installed
   SharedMedia texture; independently change Bar Font / Session Font, text colors,
   sizes, outlines, alignment and separators; disable
   Use Native XP Colors to customize XP colors; **Required state:** OOC;
   **Confirmation:** immediate readable updates; enabling native colors restores
   blue/purple. Bar text edits do not alter session text. No pipe separators/errors.
   Bar Text → Quest Log XP Format shows Percent, XP Amount or both as selected.
5. **Navigation:** Play The Game Tools → header → Edit Mode → Enhanced Experience
   Bar handle; **Action:** drag, exit with Escape, `/reload`; **Required state:** OOC,
   feature enabled; **Confirmation:** PREVIEW while editing; saved appearance and
   position persist, normal play locks movement. This is the addon's workspace,
   not Blizzard's Edit Mode menu.
6. **Navigation:** Play The Game Tools → Questing & Leveling → Enhanced Experience
   Bar → Session Text → Session Tracking → Reset Session; **Action:** reset, earn XP,
   wait and cross a level; **Required state:** leveling character, reset OOC;
   **Confirmation:** session clock/XP/hr update with no rollover spike. `/reload`
   resets counters while retaining appearance/position.
7. **Navigation:** Play The Game Tools → Questing & Leveling → Enhanced Experience
   Bar → General → Enable Enhanced Experience Bar; **Action:** disable/re-enable
   after a combat/XP gain check; **Required state:** settings OOC;
   **Confirmation:** combat XP updates without blocked-action errors, disable
   hides the bar, re-enable starts a fresh session and other features still work.

8. **Navigation:** Play The Game Tools → Questing & Leveling → Enhanced Experience
   Bar → Colors → Rested XP Overlay Color / Quest Log XP Overlay Color → Pick;
   **Action:** choose distinct colors, then `/reload`; **Required state:** OOC,
   overlays enabled with rested XP and quest log rewards (or Preview enabled);
   **Confirmation:** only the selected overlay tint changes, both colors persist,
   and Use Native XP Colors can remain enabled for the main fill.
