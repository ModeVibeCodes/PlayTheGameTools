# Global Settings

Forever only. The sidebar's **Global Settings** page controls **Global Font**,
**Global Texture**, and **Global Border** for the suite. Defaults are Game font,
Flat texture, and Play The Game Tools Thin border. Changes use the existing
header **Reload** request and apply together after `/reload`.

Font choices include game/chat fonts and every registered LibSharedMedia font.
Textures include every registered status-bar texture and background; borders
include None, Thin, and all registered LibSharedMedia borders. SharedMedia and
other installed media packs extend those lists through the optional library.
No provider code/assets are copied or redistributed. The library's
[official API](https://www.wowace.com/projects/libsharedmedia-3-0/pages/api-documentation)
provides List/HashTable/Fetch and registration callbacks. This feature uses the
existing optional library integration; it does not install a media pack.

Global settings live in the active profile's `globalMedia` table. Defaults fill
missing keys, retain unknown keys and preserve saved selections when a media
provider is unavailable. Missing fonts/textures/borders fall back safely.
Profile validation checks media-key types and lengths before publication.

Each **[module title] Overrides** section has **Font**, **Texture**, and
**Border** dropdowns, initially **Use Global Setting**. A module override changes
only that module. Existing custom local font/media and XP texture selections
remain more specific. Old game/flat defaults inherit; selecting Game/Chat in an
existing font selector now explicitly pins that choice. **Use Global Setting**
in that selector resumes inheritance. The XP **Bar Texture** selector also has
**Use Global Setting** and **Flat (override)**.

Owned module panel/icon borders and configuration outlines resolve the shared
border instead of retaining a second fixed/native edge. Existing color, opacity,
zero-size/hidden-border choices and action-template behavior remain intact.
Spell/item icons, map symbols, hover/selection highlights, cooldown art, dividers,
and explicit Blizzard XP textures keep their functional meaning. Texture
inheritance covers panel backgrounds, contribution rows and status-bar fills.
The Blizzard configuration theme keeps its button/check art, but the window and
popup edges use Global Border.

No polling, global frame hooks, Blizzard FontObject writes, external addon
settings, SavedVariables resets, or `LibSharedMedia:SetGlobal` calls are added.
Runtime implementation uses existing loaded files; the feature adds no TOC entries.
Retail/shared development source is outside this standalone change.

## Validation and local testing

Run `python tests/global_settings.py`, the existing regression suites, and
`python tools/build_release.py`. Static/mock checks do not establish native
rendering, native action dispatch or combat acceptance. In-game confirmation is
pending.

Local validation: all 29 standalone regression scripts passed. Focused global
media, contribution appearance and Rogue icon checks passed again after the
selector/thickness refinements; smoke checks cover both configuration themes.
The deterministic package contains 109 Lua chunks and 185 files. No WoW session
or native acceptance is claimed.

1. **Navigation:** Play The Game Tools → Global Settings → Global Appearance →
   Global Font / Global Texture / Global Border. **Action:** open `/ptg`, choose
   a different registered item in each dropdown, then use header **Reload**.
   **Required state:** OOC, feature branch loaded. **Confirmation:** settings
   persist, configuration text/backgrounds/edges use the selection; enabled
   module displays inherit. None removes the owned border.
2. **Navigation:** Play The Game Tools → Global Settings → Combat Timer Overrides
   → Font / Texture / Border. **Action:** choose module media, reload, then change
   a global choice and reload again. **Required state:** OOC, Combat Timer enabled
   with its existing visible preview or in combat. **Confirmation:** timer keeps
   its override; other uncustomized modules inherit the new global choice.
   Return each dropdown to **Use Global Setting** and reload to resume inheritance.
3. **Navigation:** Play The Game Tools → Timers → Combat Timer → Display → Font.
   **Action:** select Game font, reload, change Global Font and reload again;
   then select **Use Global Setting** in the timer font dropdown.
   **Required state:** OOC for configuration/reload. **Confirmation:** explicit
   Game font remains pinned; Use Global Setting restores inheritance.
4. **Navigation:** Play The Game Tools → Global Settings → Global Appearance.
   **Action:** enter combat with the page open and try a media dropdown; leave
   combat and repeat. **Required state:** existing enabled modules running.
   **Confirmation:** media cannot change in combat, settings work OOC, no errors;
   existing module actions, drag/lock, previews, timers and XP forecasts still work.

The desktop's pre-existing Forever junction must remain untouched. For requested
local testing, switch the clean live-linked standalone checkout to the validated
feature branch; do not run the old ModeTools copy-sync wrapper against this addon.
Use `/reload` to load the existing runtime files. No release/merge is implied.
