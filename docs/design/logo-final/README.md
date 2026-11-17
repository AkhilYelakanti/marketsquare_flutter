# MarketSquare logo (final set)

Straight M with a square-S badge. Wordmark: Inter ExtraBold "Market" + Inter Medium "Square", converted to outlines.

## Colours
| Name | Hex | Use |
|---|---|---|
| Brand red | `#C4202E` | M, "Square", app icon background |
| Ink | `#1D1B1A` | "Market", badge on light backgrounds |
| Pink | `#FFC9CE` | Badge on red backgrounds |
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
  - `app-icon`, `-square`, `-round`: red icon with rounded, square and circular corners
  - `android-adaptive-foreground` / `-background`: 108 dp adaptive icon layers
- `png/lockup`, `png/mark`: transparent PNGs (lockups 1600 px wide, stacked 1200 px, marks 1024 px).
- `png/app-icon`: 1024, 512 and square-corner 1024.
- `png/android`: `mipmap-*/ic_launcher.png`, `ic_launcher_round.png`, and 432 px adaptive layers.
- `png/ios`: `AppIcon-{1024,180,167,152,120,87,80,76,60,58,40,29,20}.png` (square, opaque).
- `png/web`: favicons 16/32/48, `apple-touch-icon` 180, `icon-192`, `icon-512`.
- `brand-sheet.png`: every version on its intended background.

## Usage rules
- Clear space around the lockup: at least the height of the badge.
- Minimum size: lockup 120 px wide, mark 24 px, app icon 29 px. The S inside the badge is not legible below about 40 px, where only the M reads. That is expected.
- Use the reversed or on-red version on dark or red backgrounds. Do not place the primary lockup on red.
- Do not stretch, rotate, recolour or add effects.

## Regenerate
`generate_final.py` and `defs.py` produce the SVGs. Requires `fonttools` and the Inter font files.
