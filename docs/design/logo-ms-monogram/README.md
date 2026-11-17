# MS monogram logo set

Vector trace of the supplied logo (red M, black S, red square with an arrow tip). Colours: red `#DB2031`, ink `#1D1B1A`. Wordmark: Inter ExtraBold + Medium, converted to outlines.

The source image was small (260 x 202 px), so edges are traced approximations. For print or large signage, have the monogram redrawn by hand from `svg/ms-mark.svg`.

## Files
- `svg/ms-mark*.svg` monogram only: colour, reversed (dark backgrounds), on-red, mono black, mono white.
- `svg/ms-lockup*.svg` monogram + "MarketSquare", same five versions. `ms-stacked*.svg` puts the name under the monogram.
- `svg/ms-app-icon*.svg` white tile (primary, the red M needs a light background), red tile, square and round corners.
- `svg/ms-header-tile.svg` white rounded tile for the red app bar. `png/header-tile/flutter/{1.0x,2.0x,3.0x}` are 36 / 72 / 108 px.
- `svg/android-adaptive-*.svg` and `png/android` launcher icons, `png/ios` AppIcon sizes, `png/web` favicons.
- `brand-sheet.png` shows every version on its background.

## Regenerate
`python3 generate_ms.py <out_dir>` rebuilds the SVGs from `ms_trace.json`; `trace_logo.py` re-traces a new source image. Needs `fonttools`, `potracer`, `numpy`, `pillow`.
