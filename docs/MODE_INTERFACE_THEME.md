# mode interface theme

Forever only, experimental and opt-in. Open `/ptg` → **Global Settings** →
**Appearance** → **Interface Theme** → **mode**, then use header **Reload** OOC.
Modern remains the default. Modern and Blizzard retain their palettes and layouts.
The selected theme uses the existing profile setting and reload flow; no settings
are reset or migrated. Theme changes affect configuration surfaces only.

The mode palette uses dark slate backgrounds, lighter blue headings and accents,
and muted off-white/gray text. Existing controls gain a restrained static blue wash
and text light on selection/hover. Disabled controls remain inactive and unlit.
Global Font/Texture/Border customization still applies, so custom media can change
the result. Gameplay displays, module functions, class colors and state meanings
are unchanged.

The sidebar lists every populated category expanded by default each UI session.
Blue category headings are plain text click targets: clicking collapses/expands
their children without selecting a different page or toggling a module. Children
use an indented `·` prefix and body-size type. Class icons remain available.
Disclosure state survives unrelated page navigation and closing/reopening the
window within the session. Direct module/search navigation expands its category.
The sidebar scrolls when needed. The redundant category tab strip above module
pages is hidden only in mode, recovering space; internal module section tabs,
enable switches, search, previews, Edit Mode and settings controls are retained.

## Design reference

[Editable Figma preview](https://www.figma.com/design/8ZPSZPK4eJ4ocvy7CA2HpO?node-id=2-21)
uses the runtime palette, editable local components and the bundled **PTG JetBrains
Mono** font option. The screenshots supplied by the owner informed hierarchy,
spacing and neutral surfaces; no reference-addon code or assets were copied.
The preview is a design reference, not an in-game screenshot. Client text
measurement, font selection, clipping and native rendering still need review.

## Validation and local testing

Run `python tests/mode_theme.py`, `python tests/smoke.py`,
`python tests/global_settings.py`, `python tests/edit_mode.py` and
`python tools/build_release.py`. The theme suite checks all module page routes,
disclosure, search, preference preservation, selected/hover/disabled lighting,
reload combat guards and restoration of both existing themes. Static/mock checks
do not establish native visual or gameplay acceptance.

This change edits existing Lua files only: no new runtime files, TOC entries,
media or client restart requirement. In the existing desktop Forever test setup,
the owner-approved AddOns junction points to the standalone public checkout.
Use the feature branch there for local `/reload` testing, preserving the junction
and SavedVariables. The isolated PR checkout alone is not the live source.
No release publication or automatic theme activation is included.

1. **Navigation:** Play The Game Tools → Global Settings → Appearance → Interface Theme → mode;
   **Action:** open `/ptg`, select **mode**, then click header **Reload**;
   **Required state:** OOC, feature branch available through the existing test installation;
   **Confirmation:** reopening `/ptg` shows slate backgrounds, blue headings,
   readable gray text and all populated sidebar categories expanded.
2. **Navigation:** Play The Game Tools → Timers → · Combat Timer;
   **Action:** select **· Combat Timer**, then click **Timers** twice;
   **Required state:** OOC; **Confirmation:** first click hides only that category's
   children, second restores them; Combat Timer's current page, settings and enable
   state remain unchanged. Internal section tabs still work; the duplicate
   category strip above the page is absent.
3. **Navigation:** Play The Game Tools → sidebar search field;
   **Action:** collapse **Timers**, search **Combat Timer**, then click its result;
   **Required state:** OOC; **Confirmation:** Timers expands and Combat Timer opens;
   the selected child stays lit after mouse leave. Hover other clickable controls,
   visit populated categories and scroll the sidebar; labels remain readable and
   disabled controls stay inactive. Check your usual module controls/Preview/Edit
   Mode for unchanged behavior and report errors, clipped labels or missing controls.
4. **Navigation:** Play The Game Tools → Global Settings → Appearance → Interface Theme → Modern / Blizzard;
   **Action:** select either existing theme and click header **Reload**;
   **Required state:** OOC; **Confirmation:** its original palette, selected-category
   sidebar expansion and top category tabs return; settings and positions persist.

Native validation remains pending owner feedback. Record Forever build,
resolution, UI scale, font/media selections and screenshots when reporting fit.
