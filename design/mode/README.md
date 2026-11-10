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
| Selection | 6:34 | 8 × 64 | Thin cyan #00F0FF line with quiet fading ends on transparency |

PNGs were exported through the Figma Plugin API `exportAsync({format:'PNG',
contentsOnly:true})` and `figma.base64Encode`. This preserves transparent alpha;
the generic asset preview export includes the page background and is not used.
Runtime TGAs are exact RGBA conversions, not regenerated approximations:
`python tools/build_mode_textures.py` with Pillow. Source PNGs/design files are
outside the addon; only TGAs are included in the runtime package. Texture slicing
uses the existing native texture-slice helper and 12px margins for fixed corners.
Missing surfaces fall back to readable neutral fills; missing borders stay clear.

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
