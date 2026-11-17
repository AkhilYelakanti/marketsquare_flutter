# Launcher icon (MS box, red tile)

Red tile with the white box, white M and black S, bolder than the logo trace so it stays clear at launcher sizes (lines thickened, mark fills about 86% of the tile). Red `#DB2031`.

- `launcher-icon-1024.png`, `svg/launcher-icon.svg` rounded master. `-square` is full-bleed for iOS and Play Store; `-round` has a smaller mark so the circle does not clip it.
- `png/android/mipmap-*/ic_launcher.png` and `ic_launcher_round.png` (48 to 192 px).
- Adaptive icon (432 px): `ic_launcher_foreground` (mark in the safe zone), `ic_launcher_background` (red), `ic_launcher_monochrome` (single colour, for Android 13 themed icons). Play Store icon: `play-store-icon-512.png`.
- `png/ios/AppIcon-*.png` 20 to 1024 px, square, no transparency.
- `png/web` favicons and touch icons. `preview.png` shows the icon at real sizes.

Regenerate: `python3 generate_launcher.py <out_dir>` (uses `ms_trace.json`), then export PNGs from the SVGs.
