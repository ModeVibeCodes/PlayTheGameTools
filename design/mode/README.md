# mode material provenance

Original editable Figma artwork created for Mode's Play The Game Tools theme,
November 9, 2026. Copyright (c) 2026 Mode, MIT (repository LICENSE).
The owner's dashboard reference informed spacing and hierarchy; none of its
pixels, icons, code or assets is copied into the addon.

Source file: https://www.figma.com/design/8ZPSZPK4eJ4ocvy7CA2HpO

| PNG / runtime TGA | Figma source node | Size | Treatment |
| --- | --- | --- | --- |
| Surface | 6:32 | 128 × 128 | Neutral white-to-96.5%-gray satin gradient, 10px transparent corners; tinted by neutral runtime surface palette |
| Border | 6:33 | 128 × 128 | White 1px inside stroke, 10px soft corners, transparent center; tinted by runtime border palette |
| Selection | 6:34 | 128 × 4 | Cyan #00F0FF underline fading from left to right; anchored to measured text |
| ControlSurface / ControlBorder | 22:31 / 22:32 | 64 × 32 | 9px rounded buttons, separately tintable fill/border |
| CheckSurface / CheckBorder → CheckSurfaceRound / CheckBorderRound | 22:33 / 22:34 | 24 × 24 source; 32 × 32 runtime | Rounded checkbox geometry, resampled for power-of-two runtime files; full sprites without slicing |
| ToggleSurface / ToggleBorder → ToggleSurfacePill / ToggleBorderPill | 22:35 / 22:36 | 32 × 16 | Capsule tracks drawn as complete sprites without slicing |
| Thumb | 22:37 | 32 × 32 | Circular switch thumb |
| ScrollThumb | 22:38 | 4 × 64 | Thin antialiased indicator, rendered 2 units wide |
| Divider | 22:39 | 256 × 4 | Even separator with beveled ends, rendered 1 unit high |

PNGs were exported through the Figma Plugin API `exportAsync({format:'PNG',
contentsOnly:true})` and `figma.base64Encode`. This preserves transparent alpha;
the generic asset preview export includes the page background and is not used.
Runtime TGAs preserve RGBA pixels except the documented checkbox/logo resampling:
`python tools/build_mode_textures.py` with Pillow. Source PNGs/design files are
outside the addon; only TGAs are included in the runtime package. Texture slicing
uses the existing native helper with 12px margins on panels and 10px on buttons;
small checkbox/switch sprites do not use slicing.
Missing surfaces fall back to readable neutral fills; missing borders stay clear.
Small checkbox/switch sprites now bypass slicing so the full rounded silhouette
is drawn. Their runtime paths changed after the owner reported square controls;
the original source PNGs remain untouched. All runtime canvases are powers of two.
Large surfaces and control buttons retain their existing slices. Surface
6:32 also includes subtle neutral sheen/detail layers. The Starter tool-call limit
was reached after these assets were exported; the composed screen could not be
updated with the final header/spacing refinement in this pass.

`Logo.png` is the addon owner's supplied **ptg addon.png**, with background removal
performed through ImageGen. The second cutout was selected after inspecting alpha
and its actual 38px presentation against the #2B2B2B canvas; the faint fully/near
transparent export pixels are not an opaque backing. The source PNG is retained;
the builder downsamples it to a 128px RGBA TGA for the mode header. This owner-supplied
brand asset is separate from the original Figma control artwork. Logo, settings,
frame names and metadata in the other themes are unchanged.

The composed preview remains editable text, instances and frames. It uses Lato
Regular/Bold, verified in the Figma font catalog. No flattened UI image is embedded
as a substitute for the editable preview or runtime UI.

## Lato

Unmodified Lato Regular/Bold from the official Google Fonts repository:
https://github.com/google/fonts/tree/15e8fc68b03a0214ace8b52ca0153e1b597345ec/ofl/lato

Copyright (c) 2010–2014 tyPoland Lukasz Dziedzic, reserved font name Lato, SIL OFL 1.1.
Full license is packaged at `LICENSES/Lato-OFL.txt`. Font hashes:

- Lato-Regular.ttf: d636e4683231f931eda222d588e944d082bfd3bdba02f928bee461c0f185b251
- Lato-Bold.ttf: 8a0aace75d33794eece4b28187bfc1df0bbd2888b5d8a56e01788c8d65d16be1

The Figma font catalog supplies the design font; the official licensed files
supply the WoW font. No Figma-only font embedding or external provider is required.
