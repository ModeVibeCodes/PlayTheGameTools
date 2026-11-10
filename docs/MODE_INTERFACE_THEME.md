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
The outer window and module-page perimeter outlines are removed; control outlines
and row separators remain. Button backgrounds are inset one unit, and checkbox/
toggle tracks are inset one unit inside their outer border geometry. Checked
fills and circular thumbs have room inside the outer shape rather than sharing
its edge pixels. Native feedback showed the previous hollow border still looked
clipped when filled. Small controls now draw a solid rounded backing beneath the
same inset interior and thumb, all on one frame. Off/on changes the interior color,
not its dimensions or silhouette. After positive owner feedback on containment,
the rim is reduced from two units to one and uses charcoal **#2B2B2B** in both
states. This thinner/darker refinement awaits native review. No new assets are needed.
Checkboxes now use dedicated rounded silhouettes. On/off switches have capsule
tracks and circular thumbs; their click handlers, hit targets and state remain
unchanged. Buttons, including header controls, Collapse and Refresh, use dedicated
rounded control art rather than scaling the larger panel corners.
Native screenshots exposed square small controls in the preceding revision.
Checkbox runtime art is now 32×32 (the original Figma source is 24×24), and both
checkboxes and switches use complete alpha sprites without texture slicing.
Fresh file paths prevent reusing old cached images. Custom global borders cannot
replace these small silhouettes with rectangular frames; **None** still hides
their outlines. If a new small-control file is unavailable, the already bundled
circular thumb supplies a rounded fallback instead of a solid square. The new
native result remains pending owner confirmation.

Lato Regular/Bold, selected from Figma's font catalog, is the mode configuration
default when Global Font is **Game font**; **PTG Lato** is also available explicitly.
Other explicit Global Font choices still win. This does not set the global font,
change gameplay fonts or overwrite a saved choice. **Global Texture** affects
module/feature displays only. Mode's window, page panels and configuration popups
always use their original theme material and sheen, regardless of that selection.
Modern keeps its flat surfaces and Blizzard keeps its native popup background.
The selected global texture stays saved for module displays; no reset is needed
to restore the interface. Global Border remains independent; use **Thin** to
review authored corner treatment. Gameplay functions and state meanings are unchanged.

The sidebar lists every populated category expanded by default each UI session.
Bold gray category headings are plain text click targets: clicking collapses/expands
their children without selecting a different page or toggling a module. Children
use an indented `·` prefix and single-line type. Child inset is 16 UI units; the
navigation width is restored to 240 and each child measures the selected font,
reducing its size only when needed to fit the available width. Word wrapping is
disabled. Class icons remain available. Selection lines follow
the measured text and alignment, fading toward the right; they no longer center
under the entire clickable row. Internal section tabs share that line instead
of drawing a second underline.
Disclosure state survives unrelated page navigation and closing/reopening the
window within the session. Direct module/search navigation expands its category.
The sidebar scrolls when needed. The redundant category tab strip above module
pages is hidden only in mode, recovering space; internal module section tabs,
enable switches, search, previews, Edit Mode and settings controls are retained.
The navigation column is 240 UI units wide; module page rows have
12-unit inner padding to clear their borders. The visible scroll thumb is 2 units
wide while its existing hit target stays unchanged. Descriptor copy is darker
than body text (#A0A0A0 versus #D4D4D4). Separators remain 1 unit high with beveled
ends. The header separator and the navigation/content vertical separator are hidden.

The existing search field remains in the mode header. **Profile: <active name>**
is immediately left of the rightmost **X** button; only its profile name uses cyan. It opens **Global
Settings → Profiles** through the existing page/tab engine without mutating a
profile. The cyan mode window title is **PTG Tools**, preceded by the owner's supplied
logo with its navy background removed. Addon metadata and other themes keep the
existing Play The Game Tools name.
Search's left edge is anchored to the same content-left coordinate as the module
page title. The clear header drag region and off-screen recovery reserve account
for that position. The profile caption and cyan name are measured and centered
as one group, with a 132–196-unit button width and matching header-control space.
Close remains far right.

Numeric value inputs and plain slider value labels are centered. Slider thumbs
retain their 10×20-unit size and use an existing rounded full sprite; parsing,
limits, callbacks and native slider interaction are unchanged. This correction
changes Lua/layout only and adds no new runtime assets.

## Design reference

[Editable Figma preview](https://www.figma.com/design/8ZPSZPK4eJ4ocvy7CA2HpO?node-id=2-21)
uses the runtime palette, editable local components and **Lato Regular/Bold**.
The screenshots supplied by the owner informed hierarchy,
spacing and neutral surfaces; no reference-addon code or assets were copied.
The preview is a design reference, not an in-game screenshot. Client text
measurement, font selection, clipping and native rendering still need review.
The latest rounded-control/line assets were authored and exported in Figma, but
the Starter plan tool-call limit prevented updating the composed preview for this
last refinement. Its composition therefore reflects the previous revision.

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

This revision edits existing Lua files and adds thirteen TGAs plus two licensed TTFs;
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
6. **Navigation:** PTG Tools → Global Settings → Appearance → Global Font / Global Texture / Global Border;
   **Action:** choose **PTG Lato**, **Flat**, **Thin**, respectively, then header
   **Reload**; **Required state:** OOC, optional when existing custom media differs;
   **Confirmation:** the recommended Lato type and authored graphite satin/soft
   corners appear. Your previous choices can be restored through the same controls.
7. **Navigation:** PTG Tools → Global Settings → Appearance / Profiles;
   **Action:** alternate the two tabs, hover **Modern**, **Blizzard** and **mode**
   without changing the theme, and scroll **Profiles**; **Required state:** OOC;
   **Confirmation:** a single fading line sits directly under selected text,
   buttons have rounded corners, rows stay inside their borders, and the thinner
   scroll indicator works. Logo/title sit at upper left in cyan; **X** is far right
   and **Profile: <active name>** is immediately left with only its name cyan.
   Neither removed separator is visible.
8. **Navigation:** PTG Tools → Global Settings → Optimizations → Auto Loot;
   **Action:** hover the checkbox and inspect its shape without changing the value;
   **Required state:** OOC; **Confirmation:** rounded checkbox corners, unchanged
   saved state and normal text-only hover.
9. **Navigation:** PTG Tools → Timers → · Combat Timer → header's unlabeled module
   enable switch (beside **Enabled** / **Disabled**);
   **Action:** inspect/hover without changing the current state; **Required state:**
   OOC; **Confirmation:** capsule track and circular thumb, unchanged enabled state
   and no clipping. Report any remaining clipped page and UI/font scale.
10. **Navigation:** PTG Tools → Questing & Leveling → · Gameplay Enhancements → Loot Sparkles → Options → Enable Loot Sparkles;
    **Action:** inspect the checkbox without changing its value;
    **Required state:** OOC after `/reload` with this revision;
    **Confirmation:** rounded corners rather than the reported solid square,
    with the same saved checked/unchecked state.
11. **Navigation:** PTG Tools → Questing & Leveling → · Gameplay Enhancements / · Enhanced Experience Bar;
    **Action:** inspect both sidebar entries, then click each;
    **Required state:** OOC; **Confirmation:** each name stays on one line and
    opens the same page. Long names may use a slightly smaller selected font.
12. **Navigation:** PTG Tools → Questing & Leveling → · Class Training → General;
    **Action:** inspect the page title, header switch, **Level Up Window** and
    **Shortcut Icon & Menu** checkboxes without changing their values;
    **Required state:** OOC after `/reload`; **Confirmation:** no page perimeter
    line crosses the title/controls, checked fills stay inside their outlines,
    and the search bar's left edge lines up with **Class Training**.
13. **Navigation:** PTG Tools → header → Profile: <active name>;
    **Action:** inspect the caption/name group, then click it;
    **Required state:** OOC; **Confirmation:** centered, proportionate text with
    only the name cyan, Close far right, and the existing Profiles page opens.
14. **Navigation:** PTG Tools → Global Settings → Optimizations → Camera Max Zoom;
    **Action:** inspect the numeric field and slider thumb;
    **Required state:** OOC; **Confirmation:** centered value text and rounded
    thumb corners with the same thumb size; the current value is unchanged.
15. **Navigation:** PTG Tools → Questing & Leveling → · Class Training → General → Level Up Window;
    **Action:** note the original checkbox state, click twice to compare both
    states and restore it; inspect the page's enabled switch without changing it;
    **Required state:** OOC after `/reload`; **Confirmation:** the cyan interior
    replaces the same unfilled region and stays inside the larger rounded gray
    charcoal rim; the switch thumb remains contained and the original setting is restored.

16. **Navigation:** PTG Tools → Global Settings → Appearance → Global Texture;
    **Action:** inspect after `/reload` with the existing selection, then choose
    **PTG Satin** and use header **Reload**; restore the original selection if desired;
    **Required state:** OOC; **Confirmation:** original graphite window/page material
    and sheen remain in both cases, including dropdown/popup surfaces. Module
    displays continue to use the selected texture where they inherit Global Texture.

Native validation remains pending owner feedback. Record Forever build,
resolution, UI scale, font/media selections and screenshots when reporting fit.

The owner reports the previous revision looks sharp; this is scoped visual
feedback, not module/gameplay acceptance. Current native refinement review remains
pending. Texture conversion retains exact Figma RGBA pixels; the owner logo is
downsampled separately for its 38-unit header presentation.

November 9 verification: all 33 regression scripts pass on the final revision,
including text alignment/resizing, inner padding, rounded control geometry,
profile-only accent text and asset transparency/fade checks. The deterministic
build passes at 116 Lua chunks / 215 package files. The header and body sheen
layers are static, neutral and non-interactive; there is no new polling.
