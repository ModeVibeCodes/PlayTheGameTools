# Loot Sparkles — Gameplay Enhancements

## Scope and design

Research completed November 7, 2026 against the installed **Forever Loot Sparkles
v1.3.1**, Interface 16001. The new independent module lives at **Questing &
Leveling → Gameplay Enhancements → Loot Sparkles**. Its module-header toggle
starts **Disabled**. It neither changes Class Training/Dungeon Loot navigation
nor adds Retail code. No live deployment, release or native acceptance is implied.

The installed reference's `ForeverLootSparkles.lua` keeps the native quest-loot
sparkle enabled after graphics changes. `SoftTarget.lua` classifies Blizzard's
single `softinteract` target using cursor textures, quest-related APIs and loot
access, then animates glints on its nameplate. Text/nameplates come from the
native target UI; the reference does not provide a configurable object-name
FontString of its own. Its README and changelog document approximately 15 yards
of effective range, combat/nameplate issues, CVar taint history and restart-only
removal of the native quest effect. Requesting 60 yards is not a promise of
60-yard detection.

The installed TOC declares **GPL-3.0-or-later** and includes LICENSE. No source,
icon, flare texture or other asset from it was copied. This implementation uses
an independently written deterministic five-glint animation with the client's
`Interface/Cooldown/star4` texture. Original project grants and existing bundled
GPL catalog notices remain unchanged. Reference sources:

- [Forever Loot Sparkles source and license](https://github.com/svengabr/ForeverLootSparkles)
- [Reference behavior and limitations](https://github.com/svengabr/ForeverLootSparkles/blob/main/README.md)
- [Blizzard Unit API source, classic branch](https://github.com/Gethe/wow-ui-source/blob/classic/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua)
- [Blizzard Interact Key settings source](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_SettingsDefinitions_Frame/Controls.lua)

## Architecture and API assumptions

`Modules/LootSparkles.lua` owns registration, pure defaults/validation, lifecycle,
CVar ownership and events. `LootSparklesTarget.lua` resolves/classifies one native
target. `LootSparklesDisplay.lua` owns only the click-through glints and optional
name/range label. `Config/LootSparkles.lua` uses the existing configuration widgets.

- Optional category switches: **Quest Item Sparkles**, **Ore Veins**, **Herbs**,
  **Quest Objects**, **Corpses With Loot**, **Show Object Names**. All start on
  beneath the default-off master. Appearance controls: **Sparkle Size**,
  **Sparkle Opacity**, **Name Font Size**, **Vertical Offset**.
- `UnitIsGameObject`, `SetUnitCursorTexture`, `GetFileIDFromPath`, `UnitName`,
  `C_QuestLog.UnitIsRelatedToActiveQuest`, `UnitIsInInteractRange`, `UnitIsDead`,
  `UnitGUID`, `CanLootUnit`, `C_NamePlate.GetNamePlateForUnit` and `UnitIsUnit`
  are capability checked and called through protected reads. UnitIsGameObject is
  present in the current classic API source; Forever cursor/range/CVar behavior
  is evidenced by the local working reference, **not** proven by Retail docs or
  mocks. Missing/restricted/error results do not grant loot access or interaction.
- Cursor paths, atlas names and resolved numeric cursor file IDs identify herbs,
  ore and quest objects. Public active-quest association can identify other quest
  objects. There is no objective-name substring heuristic or hidden tooltip scan;
  objects without readable native classification may remain unmarked. Corpse
  overlays require both `CanLootUnit` results explicitly true. Unknown range is
  labeled **Range unknown**, never **In reach**.
- Direct `softinteract` nameplates are preferred. Fallback plate tokens must pass
  `UnitIsUnit(token, "softinteract")`; arbitrary nearby objects are never selected.
  Nameplate recycling/target changes detach the old overlay. Forbidden or
  inaccessible plates are skipped. No world scan, automatic loot/gather action,
  protected interaction, secret comparison or restriction workaround exists.
- One 0.15-second target refresh runs only while node categories are enabled and
  outside combat. Animation runs only while the owned overlay is visible. Combat
  hides the overlay and stops polling; no CVar setter runs in combat. Enable/
  disable cleanup requested in combat waits for `PLAYER_REGEN_ENABLED`.
- Native interaction nameplates may remain in combat because their CVar cannot
  safely be changed after lockdown begins. Possible native corpse health/name
  clutter and taint around native settings handlers require client validation.
  This implementation does not promise to suppress that native UI in combat.
- Native quest sparkle changes use a one-second debounced CVAR_UPDATE callback
  after graphics quality changes, with combat deferral. No Blizzard Settings
  initializer/predicate is injected. Only changed CVar values are written;
  native setter rejection stops further apply attempts for that setting during
  the session. No alternative setter is tried.

### Client settings and restoration

The module changes only `outlineModeShowLootEffectWhenDisabled` (1) and, when at
least one node category is selected, `SoftTargetInteract` (3),
`SoftTargetIconGameObject` (1), `SoftTargetInteractRange` (60),
`SoftTargetInteractArc` (2), `SoftTargetInteractOnlyInRange` (0), plus a category
gate on `SoftTargetNameplateInteract` (0/1). It leaves `outlineMode`, NPC icon
settings and unrelated client preferences alone.

Original and last-written values persist under account-root
`PTGToolsDB.lootSparkleCVars`, outside all profiles and profile exports. Restore
only occurs if the current value still equals the last successful module write;
subsequent manual changes are preserved. Manual disabling of Interact Key/object
icons remains respected across world entry and reload until a category is
explicitly switched on again. Turning all node categories off releases their
settings while leaving the independent native quest effect available. Failed
restoration records remain available for the next cleanup event/reload.

**Turn this module off in its UI before disabling/removing the addon in AddOns.**
Unloaded code cannot restore CVars. The game persists these separately. Removing
native quest sparkles can require fully exiting/restarting WoW; `/reload` does
not suffice according to the reference's client observations. The UI/chat say so.
Loaded `ForeverLootSparkles` or `Lueur` pauses this module and reports the conflict;
there is no import/write of those addons' settings or code.

## Validation and exact native checklist

Static commands: `python tests/smoke.py`, `python tests/loot_sparkles.py`,
`python tools/build_release.py`. Also run the existing Dungeon Loot fixtures for
navigation/profile regressions. Fixtures cover categories, public/secret/unknown
range/loot, atlas/path/fileID classification, plate identity, animation lifetime,
combat cleanup, conflicts, settings preservation, reload restoration, profile
isolation and rejected setters. These do **not** establish native safety,
rendering, interaction range, font fit, or Blizzard support.

Native validation and **Screenshots: pending**. Use real Forever captures, with
before/after views of the changed page and an actual highlighted node, excluding
other players' names and chat. No mock screenshot substitutes.

1. **Navigation:** Play The Game Tools → Questing & Leveling → Gameplay
   Enhancements → module-header unlabeled toggle. **Action:** open `/ptg`, record
   current Interact Key/object-icon/graphics settings, disable Forever Loot
   Sparkles and Lueur in AddOns and reload, then enable the module. **Required
   state:** OOC, separately installed feature branch, existing settings retained.
   **Confirmation:** Enabled, readable Loot Sparkles/Appearance/Availability
   headings, no Lua errors; Class Training and Dungeon Loot remain available.
2. **Navigation:** Play The Game Tools → Questing & Leveling → Gameplay
   Enhancements → Loot Sparkles → Ore Veins / Herbs / Quest Objects.
   **Action:** approach a known ore vein, herb and eligible active-quest object;
   toggle each independently. **Required state:** OOC, applicable categories on,
   native Interact Key/object icons on. **Confirmation:** only the current native
   interaction target gains animated glints and its name/range label. Near/far
   states read In reach / Out of reach; unavailable cursors grey the effect.
   Unknown range must say Range unknown. Unreadable objects may remain unmarked.
3. **Navigation:** Play The Game Tools → Questing & Leveling → Gameplay
   Enhancements → Loot Sparkles → Corpses With Loot / Show Object Names;
   Appearance → Sparkle Size / Sparkle Opacity / Name Font Size / Vertical Offset.
   **Action:** approach an unlooted eligible corpse after combat, loot it manually,
   adjust appearance and toggle names. **Required state:** OOC, master enabled,
   own loot available. **Confirmation:** label follows the correct target,
   disappears after looting/target loss; controls update the owned effect and do
   not block clicks. Living NPCs, chairs and unrelated objects gain no custom glints.
4. **Navigation:** Play The Game Tools → Questing & Leveling → Gameplay
   Enhancements → Loot Sparkles → Quest Item Sparkles. **Action:** toggle on,
   change a native graphics preset, then toggle off. **Required state:** OOC;
   restore the original graphics preference after the check. **Confirmation:**
   native quest effect returns after about one second; self outline remains as
   configured. Off prints the full-restart reminder when previously enabled.
5. **Navigation:** Play The Game Tools → Questing & Leveling → Gameplay
   Enhancements → module-header unlabeled toggle. **Action:** enter safe ordinary
   combat while near a node, exit combat, then disable the module OOC.
   **Required state:** safely available encounter; no forced protected failures.
   **Confirmation:** custom overlay vanishes in combat and resumes OOC, with no
   blocked-action/taint errors. Record any native nameplate clutter. Disabling
   restores still-owned settings, preserves manual overrides and stops glints.
6. **Navigation:** Play The Game Tools → Questing & Leveling → Gameplay
   Enhancements → Loot Sparkles / Appearance; header → Reload. **Action:** save
   distinct category/appearance choices, Reload OOC, reopen `/ptg`, then disable
   the module; perform a normal logout/login check too. **Required state:** OOC,
   preserve existing SavedVariables. **Confirmation:** choices survive, manual
   Interact Key/icon overrides remain respected, and original still-owned client
   settings restore after reload. Fully restart only to confirm native quest
   sparkle removal; no profile import/switch control is exposed on Forever.
## Static checkpoint — November 7, 2026

Passed: smoke/startup/profile/wrong-client checks (90 Lua chunks), focused Loot
Sparkles fixtures, all six Dungeon Loot suites, and the deterministic package
builder (165 files). The local ZIP is a review artifact with the existing beta
version, not a published release. Native behavior and screenshots remain pending.
The original shared checkout and standalone main checkout were left untouched;
implementation is isolated in `codex/forever-loot-sparkles` for PR review.

## Owner feedback and feature tabs — November 7, 2026

The owner reports that Loot Sparkles appears to work and has functioning features.
The requested next iteration puts all its controls inside the Loot Sparkles tab
under Gameplay Enhancements, alongside Campfire Monitor. Existing master/settings
are retained; Enable Loot Sparkles is an independent feature switch defaulting on
beneath that master. Current campfire/tab research and test steps are in
[CAMPFIRE_MONITOR.md](CAMPFIRE_MONITOR.md). Earlier pending/live-isolation records
above are historical; source now lives in the verified live-linked checkout.
