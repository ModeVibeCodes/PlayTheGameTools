# Global Settings

Forever only. `/ptg` → **Global Settings** has four tabs: **Appearance**,
**Profiles**, **Optimizations**, and **Class Colors**. The owner confirmed the
previous page mostly worked. The expansion described here still needs native
confirmation; mocks do not establish rendering, security or gameplay acceptance.

## Appearance and shared media

**Global Font**, **Global Texture**, and **Global Border** list every available
LibSharedMedia font, status-bar/background texture and border. LibSharedMedia,
LibStub and CallbackHandler are now bundled, so another addon is not required.
Bundled examples include **PTG JetBrains Mono**, **PTG Satin**, **PTG Matte**,
and **PTG Clean**, alongside LSM's native choices and PTG panel textures.
Installed media packs extend the same lists. Missing selections remain stored
with safe fallbacks. Use header **Reload** after appearance changes.

**SharedMedia asset-pack integration:** SharedMedia is the additional-media addon;
LibSharedMedia is the registry it uses. On first adoption, PTG enables/saves and
loads installed **SharedMedia** and **SharedMedia_MyMedia** outside combat, as
explicitly requested by the owner. The service runs without a descriptive/status row on this page. Other providers
remain passive. Later manual disables of these two addons are respected; setup markers
are account/machine state and excluded from profiles. No addon is downloaded,
no MyMedia files are generated/overwritten, and no upstream pack files are copied.
Registered MyMedia additions automatically join the same font/texture/border lists.
Use SharedMedia's own MyMedia instructions for custom files/registration.

Inspected installed SharedMedia 3.1.3-202: SharedMedia.toc, SharedMedia.lua and
INSTRUCTIONS for MyMedia.txt. Its pack declares fonts such as Adventure, status
bars such as Aluminium, backgrounds such as Bricks, and borders such as RothSquare.
The [official pack description](https://www.wowace.com/projects/sharedmedia)
confirms that its assets are registered into LibSharedMedia. SharedMedia remains
an installed external addon, distinct from PTG's bundled registry library.

Media dropdown labels now contain names only. Texture-kind, override and fallback
parenthetical annotations are removed from lists/selected labels; stored media
keys and fallback behavior are unchanged.

The Shared Media, Loot and Errors, and Camera Distance description rows were
removed at the owner's request. The class grid now has body insets and vertical
padding, so its controls clear the separator. Native alignment confirmation is
pending after `/reload`.

**Expressway** is also offered when an installed EllesmereUI or AyijeUI font asset
is verified by the client, or any media pack already registers that LSM name.
Late provider loading is detected without replacing existing registrations. No
provider font file is copied or bundled; without a provider the option is absent
(an existing saved selection retains its fallback). Redistribution permission for
the installed copy was not established; the current
[author licensing guide](https://typodermicfonts.com/license/) distinguishes
desktop use from software embedding. The bundled JetBrains Mono remains available
independently of other addons.

### Media from disabled addons

The owner accepted the description/class-grid cleanup. The subsequent media
discovery work has static/mock validation; disabled-provider rendering still
needs native confirmation.

All live LibSharedMedia fonts, status bars, backgrounds and borders remain listed.
Their addon-file name/path registrations are now remembered in the account-wide
`mediaRegistry` cache, outside profiles and profile exports. On a later reload,
cached entries are registered again when the provider is still installed and its
asset is client-known, regardless of its enabled state. Current live registrations
win name collisions; ordinary disabled providers are never enabled or loaded.
SharedMedia/MyMedia are the explicit owner-requested activation exception above. Missing
providers are ignored while selections/cache data remain available for recovery.
The cache is bounded to 4,096 entries, with validated primitive name/path values.
Media refreshes defer rendering during combat and complete after combat ends.

A bundled path-only catalog also exposes media without requiring a previous run
of its provider. It currently describes 55 installed assets: font files, literal
LSM media declarations and Ellesmere's declared bar textures. Names are qualified
by provider. No font/texture bytes, provider implementation or saved settings are
copied, evaluated or modified. Refresh this metadata from an explicitly selected
Forever AddOns directory with:

```powershell
python tools/index_installed_media.py --addons '<Forever client>/Interface/AddOns'
```

Metadata references inspected include AyijeUI/Media/SharedMedia.lua and
EllesmereUI/EllesmereUI.lua's BAR_TEXTURE_FILES, plus installed font filenames.
These files and their original assets remain untouched.

This is an external, read-only indexing step whose only output is this checkout's
Core/MediaCatalog.lua. WoW cannot perform arbitrary directory enumeration or read
disabled addons' Lua registrations. A never-loaded, uncataloged provider therefore
needs a catalog refresh or a prior ordinary run that registers its media. Arbitrary
icons/masks/custom border renderers are not assumed compatible backdrop media.
The [native asset API](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/UIFileAssetAPIDocumentation.lua)
recognizes supplied paths but explicitly does not verify loose-file openability;
the [addon API](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/AddOnsDocumentation.lua)
can verify installation without checking/enabling/loading the provider. Actual
font and texture rendering still requires native validation. This is not universal
runtime discovery of every file in every disabled addon.

There are no module override sections on this page. Earlier experimental
`globalMedia.overrides` data is retained but inert. Existing module custom fonts
and XP texture settings remain more specific; their **Use Global Setting**
choice resumes inheritance. Choosing Game/Chat locally pins the original native
font path, even when the game UI's standard font objects use the global font.

The requested game-wide font behavior changes standard Blizzard FontObjects'
faces outside combat, retaining their sizes, flags and colors. Standard game,
system, chat, tooltip, quest and number fonts are covered; privately owned
third-party FontObjects are not rewritten. Native text that does not use an
accessible standard FontObject cannot be promised universal coverage. There are
no global SetFont hooks or LSM:SetGlobal overrides. New/later-loaded standard
objects are handled on addon loading; unchanged faces are not rewritten.

Owned module panel/icon borders resolve the global setting while retaining
color/opacity/thickness and existing hidden or zero-size choices. Textures cover
owned surfaces and bar fills. Item/spell art, map symbols and functional
highlights retain their meaning. The Blizzard configuration theme retains its
button/check art; its window/popup edges use Global Border.

Original procedural media is generated by `tools/build_global_media.py`.
The PTG Clean atlas follows the eight cells and cropped UVs in the pinned
[native backdrop renderer](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_SharedXML/Backdrop.lua).
Library/font licenses and provenance are in THIRD_PARTY_NOTICES.md and LICENSES.

## Account-wide profiles

The existing ModeTools-derived profile codec, validation, reload manager and
profile hub were already present in Forever. Their controls are now exposed in
**Profiles**. The TOC's `PTGToolsDB` is account SavedVariables. Both the profile
library and selected/pending profile are shared across characters, through a
new `accountSelection` record. Initial adoption retains the current character's
previous assignment when available; historical character assignments remain
stored for recovery. No SavedVariables files are edited externally or reset.

Create copies the active setup. Profiles automatically retain module enable
states, module settings, shared Edit Mode anchors/positions, global appearance,
class colors and optimizations. Selection applies all modules together after
Reload. Duplicate, rename, cancel selection, import and export reuse the existing
hub. Forever specialization controls remain hidden. Import creates a new named
profile without overwriting an existing name, and validates a detached candidate.
The compatible version-1 envelope now permits globalMedia/globalOptions; older
exports still import. Account assignments, identity, runtime history and backups
remain excluded. Edit Mode's temporary active/dragging state is not serialized.

## Optimizations and API boundaries

- **Auto Loot** moved out of Quality of Life → Automation and operates without
  that module's enable switch. An active old opt-in is adopted when introducing
  global options. Otherwise first adoption captures the existing native setting.
  Once adopted, each profile restores its explicit on/off state; toggle-off sets
  the CVar to zero. The legacy field remains dormant for recovery.
- **Fast Loot** uses native `LOOT_READY(autoloot)` and schedules bounded 50ms
  slot requests for an actual auto-loot session outside combat. Generation tokens
  invalidate requests on closure, a replacement session or disable. Manual/modifier
  sessions are untouched. Native confirmations and the loot window remain; no
  confirmation acceptance, window hiding or combat-action fallback is added.
  Native API rejection stops this helper for the session.
- **Camera Max Zoom** always applies the selected `cameraDistanceMaxZoomFactor`
  at initialization/world entry and when changed. The slider offers 1–4 in 0.1
  steps. The pinned native Forever options expose only 1–2; Lua's CVar metadata
  does not declare engine bounds. The wider range is a candidate, not proof of a
  client ceiling: accepted-value readback displays clamping and retains the
  accepted value. The game enforces its own limit. The mouse wheel still controls
  the current view; this changes its maximum distance, without forcing movement.
- **Global UI Scale (%)** allows 40–115%. **Use Detected Scale** uses physical
  screen height and `768 / height`: approximately .7111 at 1080p and .5333 at
  1440p. Automatic detection is the initial default. A manual slider change exits
  automatic mode. The native graphics slider's .65 lower bound remains respected
  for the CVar; UIParent's supported scaling API applies the requested smaller
  scale. Resolution/UI-scale events reapply it OOC with a reentrancy guard; combat
  changes defer until combat ends. Actual resolution/scale/coexistence needs native
  review. CVar writes verify public writable/nonsecure metadata and read back the
  accepted value; a refusal is shown instead of claiming success.
- **Hide Error Text** unregisters only UIErrorsFrame's red-error event. It restores
  that event only if this helper originally found it registered. Yellow/system
  messages and error sounds retain their normal behavior. No event payload,
  resource value or secret combat value is inspected.

The **Class Colors** tab displays all nine Forever classes in a responsive grid.
Click the class name for the native color picker; **Reset** restores native color.
Picker cancel restores the previous override. Class-colored Dungeon Loot labels,
Recruitment, Guild Roster and Threat Meter use the shared accessor after Reload.
Native class-color tables and other addons' saved settings are not rewritten.

Research: pinned Forever [CVar declarations](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/CVarDocumentation.lua),
[screen declarations](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/ScreenDocumentation.lua),
[camera options](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_SettingsDefinitions_Frame/Camelot/ControlsOverrides.lua),
[graphics options](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_SettingsDefinitions_Shared/Graphics.lua),
and [error frame](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_UIErrorsFrame/Mainline/UIErrorsFrame.lua).
[ElvUI's original scaling implementation](https://github.com/tukui-org/ElvUI/blob/main/ElvUI/Game/Shared/General/PixelPerfect.lua)
supports the physical-height approach. No ElvUI implementation was copied.

Naowh Forever reference: local `NaowhForever_QoL/Loot/LootFeed.lua`, specifically
OnLootReady/ApplyLootWindow, inspected alongside its public source. It schedules
short delayed LootSlot requests from LOOT_READY and cancels by generation. Its
hide-window/feed/glimmer dependencies are unnecessary here. Naowh's original
code is all rights reserved; this helper is independently written using native
events/actions, without copying its code/assets or modifying the reference addon.
The current native loot UI also calls LootSlot, while its
[loot declarations](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/LootDocumentation.lua)
define LOOT_READY's boolean. This does not establish native action acceptance.

Interface Theme now appears below Global Border in Global Settings → Appearance,
with the existing Modern/Blizzard choices and header Reload behavior. Dashboard
no longer exposes its former Appearance section.

## Validation and native checklist

All 31 standalone scripts pass, including the expanded global/discovery/SharedMedia suites. Focused
rechecks cover the final media, scaling and layout changes. Smoke compiles/loads
116 Lua chunks. Deterministic packaging has 199 files, including upstream licenses
and runtime media. No new native acceptance or release is claimed.

1. **Navigation:** Play The Game Tools → Global Settings → Appearance → Global
   Font / Global Texture / Global Border. **Action:** choose PTG JetBrains Mono,
   PTG Satin and PTG Clean, then use header Reload. **Required state:** OOC;
   restart once if the running client has not discovered the new files/font.
   **Confirmation:** choices persist; addon and standard game UI fonts change,
   eligible surfaces/edges inherit, and custom module font choices remain pinned.
2. **Navigation:** Play The Game Tools → Global Settings → Profiles → Create New
   Profile → Create. **Action:** save a named setup after changing module enable
   states and Edit Mode positions; select that name in the profile dropdown
   (initially Default), Reload, and log into another character. **Required state:**
   OOC for selection/reload, same account/client. **Confirmation:** same selected
   profile, settings and positions; earlier profiles remain available.
3. **Navigation:** Play The Game Tools → Global Settings → Profiles → Import /
   Export → Export / Import. **Action:** copy the selected profile string, import
   with a new Profile Name, and select/reload it. **Required state:** OOC.
   **Confirmation:** modules, positions, media/colors/options round-trip; duplicate
   names and invalid strings do not overwrite existing profiles.
4. **Navigation:** Play The Game Tools → Global Settings → Optimizations → Auto
   Loot / Fast Loot. **Action:** enable both, loot a corpse, repeat with the native
   auto-loot modifier, and disable Fast Loot. **Required state:** OOC, no other fast
   loot helper enabled. **Confirmation:** normal auto-loot accelerates; modifier
   sessions stay manual; confirmations/full bags retain native handling, and
   disabling restores stock timing without delayed requests on a later corpse.
5. **Navigation:** Play The Game Tools → Global Settings → Optimizations → Camera
   Max Zoom / Global UI Scale (%) / Use Detected Scale / Applied Settings.
   **Action:** adjust the sliders and restore detected scale. **Required state:**
   OOC; repeat a resolution change separately. **Confirmation:** accepted camera
   value/status matches the game; manual scale persists and detected scale matches
   physical resolution; no reentrant scaling or combat writes/errors.
6. **Navigation:** Play The Game Tools → Global Settings → Optimizations → Hide
   Error Text. **Action:** enable, trigger an insufficient-resource error, disable
   and repeat. **Required state:** configure OOC. **Confirmation:** red text is
   suppressed/restored; information messages and error sounds retain behavior.
7. **Navigation:** Play The Game Tools → Global Settings → Class Colors → Mage /
   Reset. **Action:** pick a color, separately cancel a second edit, Reload and
   inspect class-colored module text; then Reset and Reload. **Required state:**
   OOC, applicable module enabled. **Confirmation:** selected color propagates,
   cancel preserves it, and Reset restores native color.

The existing desktop Forever junction remains unchanged. The requested local
checkout update reads the feature branch on reload; new TOC/library/font discovery
can require one full client restart. No Retail sync, release or merge is implied.

8. **Navigation:** Play The Game Tools → Global Settings → Appearance → Global
   Font / Global Texture / Global Border. **Action:** with AyijeUI already installed
   and disabled, choose AyijeUI: Expressway, AyijeUI: focus, and
   AyijeUI: Ayije_Thin; Reload. **Required state:** OOC; restart once for new catalog
   files if necessary. **Confirmation:** the provider stays disabled, the choices
   render and persist, and no provider functionality starts. For uncataloged media,
   first let its provider register normally, then disable it and reload separately;
   the remembered choices should remain available while its files remain installed.

9. **Navigation:** Play The Game Tools → Global Settings → Appearance → Global Font / Global Texture / Global Border. **Action:** Reload with the
   SharedMedia pack installed and choose Adventure / Aluminium /
   RothSquare; inspect custom MyMedia entries if installed. **Required state:**
   OOC; restart once if SharedMedia was installed while the client was running.
   **Confirmation:** the actual pack is enabled/loaded, its registered choices
   render, menu labels have no parenthetical annotations, and unrelated addon
   enabled states are unchanged. A later deliberate SharedMedia disable must
   remain respected on the next reload.
