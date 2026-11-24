# CX box logo

A CX version of the MS box logo, drawn from scratch (not traced): isometric box, tape on the lid, C on the left face, X on the right face. Letters are Archivo Black outlines (SIL Open Font License, included). Colours: red `#DB2031`, ink `#1D1B1A`.

- `svg/cx-mark*.svg`: colour (white background, red C, black X), reversed (dark), on red, mono black, mono white.
- `svg/cx-launcher-icon*.svg`: red tile with white box (rounded, square, round). `cx-icon-white.svg`: white tile. `cx-header-tile.svg`: white tile for the red app bar.
- `png/android` (mipmaps, adaptive foreground/background, Play Store 512), `png/ios` (AppIcon sizes), `png/web`, `png/header-tile/flutter/{1.0x,2.0x,3.0x}`.
- `brand-sheet.png`: all versions.

Regenerate: `python3 generate_cx.py <out_dir>`, then export PNGs from the SVGs. To change the letters, edit the two `glyph(...)` calls near the top.
