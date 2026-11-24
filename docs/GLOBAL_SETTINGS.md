# Settings page

Forever only. `/ptg` → **Settings** (pinned at the bottom of the sidebar; the
page title also reads Settings) is one short scrolling page with no section
tabs: **Appearance**, **Game**, **Profile** and **About**, in that order. This is
the approved v2 layout (design mockup "PTG Tools v2 design"). Mocks do not
establish rendering, security or gameplay acceptance; native confirmation is
pending.

## Appearance

**Theme** shows three preview cards side by side, **Modern**, **Blizzard** and
**mode**, built from `addon.InterfaceThemes`. Each card draws a tiny settings
window in that theme's own palette, edges and font: a header strip, a sidebar
strip with a selected row, and two rows with an on switch in the theme accent.
Modern has a square one-unit edge, Blizzard a three-line metal frame, and mode
its rounded Figma material. Below the drawing are the name and a one-line
caption. The theme on screen is marked **Current**; the chosen one is outlined.
Picking a card uses the existing `SetInterfaceTheme` save and reload request, so
a theme still applies after a reload, and picking the current theme again
withdraws the request. Narrow pages stack the cards.

**Global Font, Global Texture and Global Border were removed.** Themes are
predefined only: the theme decides the font, surfaces and edges of the addon's
own windows and displays. Modern and Blizzard use the stock game font and mode
uses the bundled Lato. Module displays without a font choice of their own use the
game font, the flat built-in surface and the thin built-in edge, which were the
defaults. `Media:GlobalStyle` now returns those built-ins for every caller, so no
code reads a saved global choice any more. Saved `globalMedia` values (including
the inert `overrides` table) stay in SavedVariables and profile strings untouched;
nothing was reset. PR #40 had already limited Global Font to the addon's own
frames; this change removes the remaining paths that applied a saved font,
texture or border to settings text, Edit Mode or module displays.

Per-display choices on module pages (a display's own font, the XP bar texture,
icon borders) are gone since the v2 styling reset (see DEVELOPMENT.md): each
display uses the built-in defaults above, scaled by its Layout Style card. Saved
per-display styling was reset once per profile, with a one-time notice.

**Class colors** is one row of nine class swatches. Clicking a swatch opens the
native color picker (blocked in combat); cancelling restores the previous color.
One **Reset** button returns all nine to native colors and is available only
while a custom color exists. Recruitment, Guild Roster, Threat Meter and
class-colored Dungeon Loot labels use the shared accessor after a reload. Native
class-color tables and other addons' settings are not rewritten.

## Shared media registry

LibSharedMedia, LibStub and CallbackHandler remain bundled for the per-display
media lists, so another addon is not required. Bundled examples include **PTG
JetBrains Mono**, **PTG Satin**, **PTG Matte** and **PTG Clean**.

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

Media dropdown labels contain names only; stored media keys and fallback
behavior are unchanged.

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

Original procedural media is generated by `tools/build_global_media.py`.
The PTG Clean atlas follows the eight cells and cropped UVs in the pinned
[native backdrop renderer](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_SharedXML/Backdrop.lua).
Library/font licenses and provenance are in THIRD_PARTY_NOTICES.md and LICENSES.

## Profile

The **Active profile** row has one dropdown plus a **Manage** button. Choosing a
profile in the dropdown uses the existing `ProfileManager:Select`: the switch
waits for a reload and the status line says so; choosing the profile in use again
withdraws it. **Manage** (blocked in combat) opens a menu with **New profile…**,
**Duplicate…**, **Rename…**, **Import…**, **Export…** and **Delete profile…**.
Each opens one small dialog over the page that calls the existing
`Create`/`Duplicate`/`Rename`/`PrepareImport`/`Import`/`Export` functions.
Duplicate, Rename, Export and Delete choose their profile inside the dialog.
New starts as a copy of the profile in use, as Create New Profile did.

**Delete** is new: `ProfileManager:Delete` removes one stored profile. It never
removes the profile in use or one waiting to apply after a reload, and refuses a
profile still assigned elsewhere where specialization profiles exist. Deleting the
fallback profile moves the fallback to the profile in use. Nothing else changes.

The profile library and selected/pending profile are shared across characters
through `accountSelection`. Profiles retain module enable states, module settings,
Edit Mode positions, saved media keys, class colors and game options. Import
creates a new named profile without overwriting an existing name, and validates a
detached candidate. Account assignments, identity, runtime history and backups
remain excluded from exports. Forever specialization controls are not shown.

## Game

- **Auto loot was removed.** The addon no longer writes the game's
  `autoLootDefault` CVar at startup, on profile switches or anywhere else, and
  leaves whatever the player set in the game's own options alone. Saved
  `autoLoot`/`adoptAutoLoot` keys stay in profiles, unread.
- **Fast loot** uses native `LOOT_READY(autoloot)` and schedules bounded 50ms
  slot requests for an actual auto-loot session outside combat. Generation tokens
  invalidate requests on closure, a replacement session or disable. Manual/modifier
  sessions are untouched. Native confirmations and the loot window remain; no
  confirmation acceptance, window hiding or combat-action fallback is added.
  Native API rejection stops this helper for the session, and the page then
  shows the **Fast loot** notice "Stopped after the client rejected it; loot
  manually."
- **Camera distance** always applies the selected `cameraDistanceMaxZoomFactor`
  at initialization/world entry and when changed. The slider offers 1–4 in 0.1
  steps. The pinned native Forever options expose only 1–2; Lua's CVar metadata
  does not declare engine bounds. The wider range is a candidate, not proof of a
  client ceiling: accepted-value readback displays clamping and retains the
  accepted value. The game enforces its own limit. The mouse wheel still controls
  the current view; this changes its maximum distance, without forcing movement.
- **Global UI Scale** was removed at the owner's request. The addon no longer
  sets `useUiScale`/`uiScale` or resizes UIParent, so Blizzard's own UI Scale
  option stays in control. Older saved `autoScale`/`uiScale` values are retained
  but inert.
- CVar writes verify public writable/nonsecure metadata and read back the
  accepted value; a refusal is shown instead of claiming success.
- **Hide red error text** unregisters only UIErrorsFrame's red-error event. It restores
  that event only if this helper originally found it registered. Yellow/system
  messages and error sounds retain their normal behavior. No event payload,
  resource value or secret combat value is inspected.

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

## About

**Version** (from the TOC), **Created by** Mode and Prox, **Bug reports**
Discord NoJumperMike, and **Data sources**: the full Map Labels
license notice, copied exactly from that module's page (which is unchanged).
Its search keywords are license, attribution, Efficient Games and CMaNGOS; the
module's old names (Points of Interest Labels, City Labels) find Map Labels.

## Validation and native checklist

Static/mock checks: `tests/global_settings.py`, `tests/shared_media.py`,
`tests/media_discovery.py`, `tests/mode_theme.py`, `tests/smoke.py`, the full
`tests/` suite and `tools/build_release.py`. No new files: 123 Lua chunks. None of
this is native confirmation.

1. **Navigation:** `/ptg` → Settings → Appearance → Theme. **Action:**
   click the **mode** card, then the **Modern** card, then **mode** again and
   click **Reload now** on the "Applies after a reload" banner above the page.
   **Required state:** out of combat. **Confirmation:** each card draws its own
   colors and edges, the clicked card is outlined, **Current** stays on the theme
   on screen until the reload, and after it the mode theme is applied and marked
   Current.
2. **Navigation:** `/ptg` → Settings → Appearance. **Action:** look for
   Global Font, Global Texture and Global Border, then look at module displays.
   **Required state:** a profile saved with a custom Global Font/Texture/Border
   before this change, after one reload. **Confirmation:** no such pickers exist;
   settings text uses the theme font; displays use the game font, flat surface and
   thin edge; a module's own font choice still applies.
3. **Navigation:** `/ptg` → Settings → Appearance → Class colors.
   **Action:** click the Mage swatch and pick a color; click it again and cancel;
   reload and look at a class-colored roster or recruiter name; then click
   **Reset** and reload. **Required state:** out of combat (in combat the swatch
   does nothing). **Confirmation:** the swatch shows the color, cancel keeps it,
   the color appears after reload, and Reset returns all nine to native colors.
4. **Navigation:** `/ptg` → Settings → Game → Fast loot. **Action:** turn it
   on, loot a corpse with auto loot, repeat with the auto-loot modifier, turn it
   off. **Required state:** out of combat, no other fast-loot addon.
   **Confirmation:** normal auto loot is faster; modifier sessions stay manual;
   the game's own Auto Loot option is never changed by the addon.
5. **Navigation:** Escape → Options, the game's own Auto Loot checkbox (find it with the Options search if needed), then `/ptg` →
   Settings → Game. **Action:** set the game's Auto Loot either way, reload,
   switch profiles and reload again. **Required state:** out of combat.
   **Confirmation:** the game's Auto Loot stays as you set it; there is no Auto
   loot control on the page.
6. **Navigation:** `/ptg` → Settings → Game → Camera distance / Hide red
   error text. **Action:** move the slider; turn Hide red error text on, trigger a
   red error, turn it off and repeat. **Required state:** out of combat.
   **Confirmation:** the camera value matches what the game accepted; red text is
   hidden then shown again; yellow messages and sounds are unchanged.
7. **Navigation:** `/ptg` → Settings → Profile → Manage → New profile….
   **Action:** enter a name and click **Create**; choose it in the **Active
   profile** dropdown; reload; log into another character. **Required state:** out
   of combat. **Confirmation:** the status line says the switch waits for a
   reload; after it the new profile, settings and positions are active on both
   characters.
8. **Navigation:** `/ptg` → Settings → Profile → Manage → Export…, then
   Manage → Import…. **Action:** copy the string with Ctrl+A, Ctrl+C, click
   **Close**, open Import…, paste, enter a name and click **Import**. **Required
   state:** out of combat. **Confirmation:** the imported profile appears in the
   dropdown; an existing name or an invalid string is refused without overwriting.
9. **Navigation:** `/ptg` → Settings → Profile → Manage → Duplicate… /
   Rename… / Delete profile…. **Action:** duplicate a profile, rename the copy,
   then delete it; also try deleting the profile in use. **Required state:** out
   of combat. **Confirmation:** each dialog acts on the profile chosen in it; the
   profile in use (or one waiting for a reload) is refused with a message.
10. **Navigation:** `/ptg` → Settings → About. **Action:** read the rows.
    **Required state:** none. **Confirmation:** Version matches the installed
    version; Created by Mode and Prox; Bug reports Discord NoJumperMike; Data
    sources names Map Labels and matches the Map Labels page notice word for word.

Media-pack checks still apply to per-display font, texture and border choices on
module pages: with SharedMedia or a cataloged disabled provider installed, those
lists show the pack's entries without enabling unrelated addons.
