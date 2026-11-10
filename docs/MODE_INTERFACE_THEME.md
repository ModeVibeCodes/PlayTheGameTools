# mode interface theme

Forever only, experimental and opt-in. Open `/ptg` → **Global Settings** →
**Appearance** → **Interface Theme** → **mode**, then use header **Reload** OOC.
Modern remains the default. Modern and Blizzard retain their palettes and layouts.
The selected theme uses the existing profile setting and reload flow; no settings
are reset or migrated. Theme changes affect configuration surfaces only.

The revised mode palette uses neutral graphite **#2B2B2B**, labels **#B3B3B3**,
headings/body text **#D4D4D4**, and cyan **#00F0FF** for selected/hovered text and
selection lines. Related surfaces use neutral gray steps with equal RGB channels;
there is no blue tint in body material. Original Figma satin gradients and soft
10px corner silhouettes replace flat default surfaces. Cyan etched lines denote
selection. Only text lights on hover; whole-row/button glow washes are removed.
Disabled controls remain inactive and unlit.
Small native switches/checkboxes retain their square state geometry rather than
becoming circles; the softer corners apply to panels, fields and larger controls.

Lato Regular/Bold, selected from Figma's font catalog, is the mode configuration
default when Global Font is **Game font**; **PTG Lato** is also available explicitly.
Other explicit Global Font choices still win. This does not set the global font,
change gameplay fonts or overwrite a saved choice. Custom Global Texture/Border
choices remain supported and can override the default material/corner treatment.
To review the authored materials use Global Texture **Flat**, Global Border
**Thin**. Gameplay displays, module functions, class colors and state meanings
are unchanged.

The sidebar lists every populated category expanded by default each UI session.
Bold gray category headings are plain text click targets: clicking collapses/expands
their children without selecting a different page or toggling a module. Children
use an indented `·` prefix and body-size type. Child inset is reduced from 24 to
16 UI units, with wrapping for long names. Class icons remain available.
Disclosure state survives unrelated page navigation and closing/reopening the
window within the session. Direct module/search navigation expands its category.
The sidebar scrolls when needed. The redundant category tab strip above module
pages is hidden only in mode, recovering space; internal module section tabs,
enable switches, search, previews, Edit Mode and settings controls are retained.
The existing search field moves into the mode header beside the existing header
controls. **Profile: <active name>** opens **Global Settings → Profiles** through
the existing page/tab engine; it does not select, create or mutate a profile.

## Design reference

[Editable Figma preview](https://www.figma.com/design/8ZPSZPK4eJ4ocvy7CA2HpO?node-id=2-21)
uses the runtime palette, editable local components and **Lato Regular/Bold**.
The screenshots supplied by the owner informed hierarchy,
spacing and neutral surfaces; no reference-addon code or assets were copied.
The preview is a design reference, not an in-game screenshot. Client text
measurement, font selection, clipping and native rendering still need review.

Original surface, border and selection exports are retained under `design/mode/`.
`python tools/build_mode_textures.py` (Pillow) converts their RGBA pixels unchanged
to uncompressed 32-bit TGAs. Source nodes, export details and licenses are in
[asset provenance](../design/mode/README.md). No screenshot is used as runtime art.

## Validation and local testing

Run `python tests/mode_assets.py`, `python tests/mode_theme.py`, `python tests/smoke.py`,
`python tests/global_settings.py`, `python tests/edit_mode.py` and
`python tools/build_release.py`. The theme suite checks all module page routes,
disclosure, header search/profile routing, font overrides, missing-art fallback,
preference preservation, selected/hover/disabled lighting, reload combat guards
and restoration of both existing themes. Asset checks cover neutral pixels,
transparent corners, border transparency, selection hue and packaged font license.
Static/mock checks
do not establish native visual or gameplay acceptance.

This revision edits existing Lua files and adds three TGAs plus two licensed TTFs;
there are no new Lua files or TOC entries. Try `/reload` OOC first. If the running
client cannot discover a new asset/font (missing-texture warning, missing art or
fallback font), one full client restart may be needed; do not close it routinely
for ordinary Lua/layout changes. In the existing desktop Forever test setup,
the owner-approved AddOns junction points to the standalone public checkout.
Use the feature branch there for local `/reload` testing, preserving the junction
and SavedVariables. The isolated PR checkout alone is not the live source.
No release publication or automatic theme activation is included.

1. **Navigation:** Play The Game Tools → Global Settings → Appearance → Interface Theme → mode;
   **Action:** open `/ptg`, select **mode**, then click header **Reload**;
   **Required state:** OOC, feature branch available through the existing test installation;
   **Confirmation:** reopening `/ptg` shows neutral graphite backgrounds, gray headings,
   readable gray text and all populated sidebar categories expanded.
2. **Navigation:** Play The Game Tools → Timers → · Combat Timer;
   **Action:** select **· Combat Timer**, then click **Timers** twice;
   **Required state:** OOC; **Confirmation:** first click hides only that category's
   children, second restores them; Combat Timer's current page, settings and enable
   state remain unchanged. Internal section tabs still work; the duplicate
   category strip above the page is absent.
3. **Navigation:** Play The Game Tools → header → Search settings...;
   **Action:** collapse **Timers**, search **Combat Timer**, then click its result;
   **Required state:** OOC; **Confirmation:** Timers expands and Combat Timer opens;
   the selected child retains a cyan selection line after mouse leave; only text
   lights during hover, without a row-wide glow. Hover other clickable controls,
   visit populated categories and scroll the sidebar; labels remain readable and
   disabled controls stay inactive. Check your usual module controls/Preview/Edit
   Mode for unchanged behavior and report errors, clipped labels or missing controls.
4. **Navigation:** Play The Game Tools → Global Settings → Appearance → Interface Theme → Modern / Blizzard;
   **Action:** select either existing theme and click header **Reload**;
   **Required state:** OOC; **Confirmation:** its original palette, selected-category
   sidebar expansion and top category tabs return; settings and positions persist.
5. **Navigation:** Play The Game Tools → header → Profile: <active name>;
   **Action:** click the button; **Required state:** OOC;
   **Confirmation:** Global Settings opens with **Profiles** selected and the same
   active profile; no profile change occurs from opening it.
6. **Navigation:** Play The Game Tools → Global Settings → Appearance → Global Font / Global Texture / Global Border;
   **Action:** choose **PTG Lato**, **Flat**, **Thin**, respectively, then header
   **Reload**; **Required state:** OOC, optional when existing custom media differs;
   **Confirmation:** the recommended Lato type and authored graphite satin/soft
   corners appear. Your previous choices can be restored through the same controls.

Native validation remains pending owner feedback. Record Forever build,
resolution, UI scale, font/media selections and screenshots when reporting fit.

November 9 static verification: all 33 standalone regression scripts pass. The
Figma PNG → TGA conversions preserve RGBA pixels exactly, and the deterministic
release build passes with 116 Lua chunks / 205 package files. No native rendering
or gameplay acceptance is inferred from these results.
