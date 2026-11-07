# Gameplay Enhancements — Campfire Monitor

## Scope and interface

November 7, 2026. Questing & Leveling → Gameplay Enhancements now contains two
feature tabs: **Loot Sparkles** and **Campfire Monitor**. The existing header
toggle remains the Gameplay Enhancements master. Each tab has its own enable
switch beneath that master. Existing `modules.lootSparkles.enabled` and sparkle
preferences are preserved; `sparklesEnabled` defaults true to retain their prior
behavior. New `modules.lootSparkles.campfire.enabled` defaults false. This follows
the existing Quick Access/Food Bar subfeature lifecycle without changing shared
navigation, the module registry, compatibility identifiers or SavedVariables.

Campfire Monitor displays the native proximity status with an optional campfire
icon and text. It can show **Your Camp Benefits**, using compact native-value stat lines by default, with full native text available, and optional **Nearby camp (native)** details.
An optional twelve-profession guide explains possible contributions.

**Limits:** earned Camp Benefits can include previous camps. They do not prove a
fire is currently close. Neither these auras nor the inspected supported APIs
provide a complete inventory of objects at the current campsite. The guide is
not such an inventory; vendors/workstations with no player aura cannot be
discovered by scanning buffs. No coordinates, distance estimates, map pins,
automatic sitting, object scans, buff granting or public messages are included.

## Research and implementation strategy

The owner reported the existing Loot Sparkles feature appears to work with
functioning features. This is scoped positive feedback, not acceptance of every
prior test case. The new tab layout and Campfire Monitor need native validation.

Primary-source research:

- [Blizzard camping overview](https://news.blizzard.com/en-us/article/24301516/gather-around-the-campfire-in-world-of-warcraft-forever)
  describes profession contributions, class-buff exclusions and resting/crafting
  to earn their effects. The guide summarizes effects without fixed amounts;
  actual native amounts belong to the player's tooltip.
- [Classic UnitAura documentation](https://github.com/Gethe/wow-ui-source/blob/classic/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitAuraDocumentation.lua)
  documents `C_UnitAuras.GetAuraDataByIndex(unit, index, filter)`.
- [Blizzard tooltip accessors](https://github.com/Gethe/wow-ui-source/blob/classic/Interface/AddOns/Blizzard_SharedXMLGame/Tooltip/TooltipDataHandler.lua)
  register `GetUnitBuffByAuraInstanceID` and `GetUnitAura` accessors. The installed
  camp reader confirms the former's player/instance usage on Forever.
- [Forever Forge](https://github.com/crumpshot-forever/ForeverForge), MIT,
  `Modules/CampfireAlert.lua`: inspected to verify the proximity aura and the
  distinction between presence and earned benefits. No code/assets copied.
- Installed **NaowhForever_Combat 1.2.15**:
  `AuraBuffs/Data/Campfire.lua` identifies native spells; `AuraBuffs/CampReader.lua`
  demonstrates that Camp Benefits' tooltip contains player bonus details.
  `NaowhForever/LICENSE.md` reserves rights for original code. No source, assets,
  parsing rules, alias catalogs or implementations were copied. Reference sources
  remain untouched. Native spell IDs/API facts informed independent code.

Verified reference identities, still requiring client acceptance here:

| Native aura | Spell ID | Meaning |
| --- | --- | --- |
| Campfire Nearby | 1283391 | Sole proximity signal |
| Camp Benefits | 1229741 | Earned bonuses; never proximity evidence |
| Welcoming Campfire | 1229739 | Native resting state |
| Welcoming Campfire while crafting | 1289723 | Native crafting/resting state |

The reader does not identify buffs by English names. Instance-ID tooltips are
preferred, with documented indexed player/HELPFUL fallback when that accessor is
absent. Compact Buff Text shortens unambiguous English descriptions using actual native
amounts. Localized, unfamiliar or ambiguous descriptions remain native text.
No fixed guide amounts are substituted or assigned to unverified nearby objects. Secret fields, API errors and missing
data are skipped. Complete public scans prove absence; an incomplete scan does
not prove missing benefits. Bounded scans end at 255 auras. Missing APIs show an
availability message rather than a fabricated success.

`Modules/CampfireMonitor.lua` owns pure settings/defaults, aura reading and the
subfeature lifecycle. `Modules/CampfireMonitorDisplay.lua` owns an unprotected,
draggable display. `Config/CampfireMonitor.lua` supplies its section in the common
Gameplay Enhancements page. The three files load before configuration/startup in
the TOC. There is no external addon runtime dependency.

Player-filtered UNIT_AURA plus world/combat events drive updates. There is no
campfire polling. Combat display defaults off and performs no aura reads while
paused. Optional Show In Combat uses the same public-value checks; unavailable
data clears proximity rather than retaining a stale nearby claim. The locked
display is click-through. Dragging/settings changes and preview require OOC.
Preview is explicitly synthetic and ends on tab navigation, page close, combat
or master disable. It is never stored as a real aura or saved enabled state.

## Controls

Within **Campfire Monitor**:

- **Enable Campfire Monitor** — independent opt-in beneath the parent master.
- **Display Preview → Preview / Stop Preview** — synthetic labeled sample.
- **Show Campfire Icon**, **Show Status Text**, **Show Your Camp Benefits**,
  **Show Nearby Native Details**, **Show Profession Guide**.
- **Always Show Monitor** — permits absent/unknown status and earned buffs to
  remain visible away from a camp. Otherwise it requires proximity or joined earned buffs to display.
- **Show In Combat** — optional public-only updates; off by default.
- **Font Size**, **Icon Size**, **Monitor Width**, **Monitor Scale**,
  **Monitor Opacity**, **Background Opacity**, **Text Color**.
- **Lock Campfire Monitor**, **Horizontal Offset**, **Vertical Offset**,
  **Monitor Position → Reset Position**. Unlock also keeps the display visible
  for placement. Lock restores click-through behavior.

If both icon and status text are switched off, status text remains visible to
avoid an enabled indicator with no visible content. The profession guide is
English reference text; native bonus descriptions retain the client's language.

## Static validation and native checklist

Run `python tests/campfire_monitor.py`, `python tests/loot_sparkles.py`,
`python tests/smoke.py` and `python tools/build_release.py`. Campfire fixtures
exercise tab switching, independent opt-ins, native aura/tooltip extraction,
restricted/unknown/absent data, combat, preview cleanup, position, saved settings
and profile validation. Mocks cannot establish native rendering or support.

**Native campfire validation and screenshots: pending.** Real before/after tab
captures plus an actual nearby-fire/benefits display are required for the PR;
exclude other players' names and chat.

1. **Navigation:** Play The Game Tools → Questing & Leveling → Gameplay
   Enhancements → Loot Sparkles / Campfire Monitor.
   **Action:** `/reload`, open `/ptg`, click each tab, confirm existing sparkle
   preferences; leave Enable Loot Sparkles as desired. **Required state:** OOC,
   live-linked feature source; fully restart once if new TOC files are not seen.
   **Confirmation:** exactly the two feature tabs, existing loot functionality,
   no missing-file errors, and a Campfire Monitor tab with the controls above.
2. **Navigation:** Play The Game Tools → Questing & Leveling → Gameplay
   Enhancements → header unlabeled toggle; Campfire Monitor → Enable Campfire
   Monitor / Display Preview → Preview. **Action:** enable the parent master and
   monitor, click Preview then Stop Preview. **Required state:** OOC.
   **Confirmation:** readable labeled synthetic icon/text/benefit sample; Stop
   Preview returns to live status. The sample is not claimed as detected benefits.
3. **Navigation:** Play The Game Tools → Questing & Leveling → Gameplay
   Enhancements → Campfire Monitor → Show Your Camp Benefits / Show Nearby Native
   Details. **Action:** approach a camp until Blizzard shows Campfire Nearby;
   sit/craft normally, compare the monitor against native Camp Benefits once
   earned, then walk away. **Required state:** OOC, master/monitor on, preview off,
   Always Show Monitor off and monitor locked. **Confirmation:** icon/text appears
   only for confirmed proximity; earned details match readable native tooltip
   lines; walking out of proximity clears the nearby claim. Joined earned buffs remain
   visible; separate mode keeps the earned-buff list visible independently.
4. **Navigation:** Play The Game Tools → Questing & Leveling → Gameplay
   Enhancements → Campfire Monitor → Always Show Monitor / Show Profession Guide.
   **Action:** enable both and inspect away from a camp. **Required state:** OOC,
   monitor enabled, preview off. **Confirmation:** No nearby campfire is separate
   from Your Camp Benefits; the twelve-profession list is titled Profession guide
   (possible features), never presented as this campsite's detected inventory.
5. **Navigation:** Play The Game Tools → Questing & Leveling → Gameplay
   Enhancements → Campfire Monitor → Appearance / Position → Lock Campfire
   Monitor / Monitor Position → Reset Position. **Action:** adjust size, color,
   opacity and width, unlock/drag/relock, then use Reset Position if desired.
   **Required state:** OOC. **Confirmation:** readable non-overlapping display,
   correct drag/save/reset behavior and click-through when locked. Review long
   tooltip/guide wrapping on your actual resolution and both interface themes.
6. **Navigation:** Play The Game Tools → Questing & Leveling → Gameplay
   Enhancements → Campfire Monitor → Show In Combat; Loot Sparkles → Enable Loot
   Sparkles; Campfire Monitor → Enable Campfire Monitor. **Action:** first leave
   combat display off and enter/exit safe ordinary combat; later, if desired,
   enable Show In Combat OOC and repeat. Toggle each feature independently and
   finally the parent master. **Required state:** safe encounter; configure OOC.
   **Confirmation:** default monitor pauses in combat and resumes OOC; optional
   unreadable data is not reported as nearby; no taint/blocked-action errors.
   Each feature switch affects itself; master off stops both. Unavailable native
   restriction scenarios remain pending rather than manufactured.
7. **Navigation:** Play The Game Tools → Questing & Leveling → Gameplay
   Enhancements → Campfire Monitor; header → Reload. **Action:** save distinct
   options/position, reload OOC, then log out/in normally. **Required state:** OOC,
   preserve existing settings. **Confirmation:** preferences/position persist;
   camp status is freshly read and no synthetic preview survives. Changing tabs
   or closing the settings also ends Preview.

Static checkpoint: 93 Lua chunks compile/load; smoke, campfire, existing Loot
Sparkles and Dungeon Loot UI regression suites pass. The deterministic builder
produces 168 package files. These are source/package checks, not native campfire
acceptance. Local live-file paths are verified through the preserved junction.


## Movable compact buff windows — November 7, 2026

The owner reported the window was not movable and requested short earned-buff
lines, optionally joined or detached. Saved locks prevented normal dragging;
aura/font redraws could also reapply anchors mid-drag. Move Windows and directly
draggable Preview temporarily override mouse locks. Rendering now leaves dragged
frames alone until drag stop saves their coordinates. Existing settings are
retained; placement mode is session-only and is canceled by combat/master disable.

**Compact Buff Text** defaults on. Native amounts produce lines such as 2% Crit,
8% Stats, 12 Stamina and 4 Int. Unrecognized or ambiguous descriptions stay in
their original form; no guessed amounts or guide values appear as earned buffs.
Turning Compact Buff Text off restores full readable native descriptions.

**Separate Buff Window** defaults off. Joined mode keeps earned buffs inside the
monitor after leaving the fire, with the proximity status updated independently.
Detached mode keeps a simple buff-only list while its earned aura persists, even
when the proximity monitor hides. The list defaults to a transparent background
and saves its own position independently of the monitor.

New controls in Campfire Monitor:

- Display → Compact Buff Text / Separate Buff Window.
- Position → Window Placement → Move Windows / Finish Moving. Right-click either
  window to finish. Preview windows are directly draggable even when locked.
- Buff Window → Lock Buff Window / Buff Text Size / Buff Window Width / Buff
  Window Scale / Buff Window Opacity / Buff Background Opacity / Buff Horizontal
  Offset / Buff Vertical Offset / Buff Window Position → Reset Buff Position.

Existing runtime files only: `/reload` loads this revision. No SavedVariables
files or junctions were edited. Run `python tests/campfire_movement.py` (includes
smoke and existing campfire fixtures), `python tests/loot_sparkles.py` and the
release builder. Native movement/compact-text screenshots remain pending.

1. **Navigation:** Play The Game Tools → Questing & Leveling → Gameplay
   Enhancements → Campfire Monitor → Position → Window Placement → Move Windows.
   **Action:** `/reload`, click Move Windows, drag the monitor by its body/handle,
   then right-click it or click Finish Moving. Preview is directly draggable too.
   **Required state:** OOC; live feature enabled or explicit placement/preview.
   **Confirmation:** smooth movement despite aura updates, saved position after
   reload, and click-through when placement ends and the saved lock is on.
2. **Navigation:** Play The Game Tools → Questing & Leveling → Gameplay
   Enhancements → Campfire Monitor → Display → Show Your Camp Benefits / Compact
   Buff Text / Separate Buff Window. **Action:** enable all three after earning
   camp buffs. **Required state:** OOC, Camp Benefits present, Preview off.
   **Confirmation:** actual native amounts appear as short lines, such as 2% Crit
   and 8% Stats when those are the earned bonuses. The detached list has no nearby
   icon and remains after leaving the camp. Unreadable data never reuses stale
   amounts; unfamiliar text remains readable.
3. **Navigation:** Play The Game Tools → Questing & Leveling → Gameplay
   Enhancements → Campfire Monitor → Position → Window Placement → Move Windows;
   Buff Window → Buff Window Position → Reset Buff Position. **Action:** move
   both windows independently, finish, join/detach again, and reload OOC.
   **Required state:** OOC, separate mode on while placing the buff window.
   **Confirmation:** each position persists independently; joined mode shows one
   window; Reset Buff Position affects only the detached list. Combat ends
   placement and stops both windows' dragging without protected actions.
