# MS box logo set

Vector trace of the supplied box logo, recoloured: white background, red box outline and red M, black S. Colours: red `#DB2031`, ink `#1D1B1A`. Wordmark: Inter ExtraBold + Medium, converted to outlines.

The source image was about 447 x 422 px, so edges are traced approximations. For print or signage, have it redrawn from `svg/ms-mark.svg`.

## Files
- `svg/ms-mark*.svg` colour, reversed (dark), on-red, mono black, mono white.
- `svg/ms-lockup*.svg` and `ms-stacked*.svg` mark + "MarketSquare", same five versions.
- `svg/ms-app-icon*.svg` white tile (primary) and red tile; rounded, square and round corners.
- `svg/ms-header-tile.svg` white tile for the red app bar; `png/header-tile/flutter/{1.0x,2.0x,3.0x}` = 36 / 72 / 108 px.
- `png/android`, `png/ios`, `png/web` platform icon sizes. `brand-sheet.png` shows every version.

## Regenerate
`python3 generate_ms.py <out_dir>` rebuilds SVGs from `ms_trace.json`; `trace_logo.py` re-traces a source image. Needs `fonttools`, `potracer`, `numpy`, `pillow`.
