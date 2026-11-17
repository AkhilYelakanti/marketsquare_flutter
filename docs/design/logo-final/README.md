# MarketSquare logo (final set)

Straight M with a black square badge holding an S set in Archivo Black. Wordmark: Inter ExtraBold "Market" + Inter Medium "Square". All text is converted to outlines.

## Colours
| Name | Hex | Use |
|---|---|---|
| Brand red | `#DB2031` | M, "Square", app icon background |
| Ink | `#1D1B1A` | "Market", badge on light backgrounds |
| Pink | `#FFC9CE` | Badge in the on-red lockups |
| Light red | `#FF8A93` | "Square" and badge on dark backgrounds |
| Dark | `#17120F` | Dark backgrounds, S on reversed badge |

## Files
- `svg/` editable vector masters (import into Figma).
  - `lockup`: horizontal, for white or light backgrounds
  - `lockup-reversed`: for dark backgrounds
  - `lockup-on-red`: for brand-red backgrounds
  - `lockup-mono-black` / `-mono-white`: single colour (S is knocked out, so the background shows through)
  - `stacked*`: same five versions with the mark above the name
  - `mark*`: M and badge only
  - `app-icon`, `-square`, `-round`: red icon with a white M and a black badge with a white S, in rounded, square and circular corners
  - `android-adaptive-foreground` / `-background`: 108 dp adaptive icon layers
- `png/lockup`, `png/mark`: transparent PNGs (lockups 1600 px wide, stacked 1200 px, marks 1024 px).
- `png/app-icon`: 1024, 512 and square-corner 1024.
- `png/android`: `mipmap-*/ic_launcher.png`, `ic_launcher_round.png`, and 432 px adaptive layers.
- `png/ios`: `AppIcon-{1024,180,167,152,120,87,80,76,60,58,40,29,20}.png` (square, opaque).
- `png/web`: favicons 16/32/48, `apple-touch-icon` 180, `icon-192`, `icon-512`.
- `png/header-tile`: option A for the red app bar, the white rounded tile with the colour mark (32 to 1024 px), plus `flutter/1.0x, 2.0x, 3.0x` for a 36 logical-pixel logo. `svg/marketsquare-header-tile.svg` is the master.
- `header-preview.png`: how the tile looks on the app header.
- `brand-sheet.png`: every version on its intended background.

## Usage rules
- Clear space around the lockup: at least the height of the badge.
- Minimum size: lockup 120 px wide, mark 24 px, app icon 29 px. The S inside the badge is not legible below about 40 px, where only the M reads. That is expected.
- Use the reversed or on-red version on dark or red backgrounds. Do not place the primary lockup on red.
- Do not stretch, rotate, recolour or add effects.

## Regenerate
`generate_final.py` and `defs.py` produce the SVGs and a manifest for PNG export. Requires `fonttools` and the Inter font files; `fonts/ArchivoBlack-Regular.ttf` (SIL Open Font License) is included for the S.
