# CSW5: handoff for the local session

## Goal
Create a **new** Flutter project named `csw5` (version **5.1.01**) from the final working app at
`C:\Users\Akhil\Work Drive\android-workspace\csor_csw`, and re-skin it with the new design.
**Do not modify `csor_csw`.** Copy it, then work only in the copy.

## What this session produced (all in the repo `AkhilYelakanti/marketsquare_flutter`, branch `claude/focused-tesla-ff4j87`, folder `docs/design/`)
| Path | Content |
|---|---|
| `clean-retail-merged/` | 10 merged screens as SVG (sign in, home, order type, order filling, item sheet, catalog, review and send, orders, approval detail, inbox) and `DESIGN_SPEC.md` (tokens, type scale, spacing, components, Flutter route mapping) |
| `logo-ms-box/` | The chosen box logo (white background, red M, black S): marks, lockups, header tile, platform icons, `brand-sheet.png` |
| `launcher-icon/` | Launcher icon set (red tile, white box): Android mipmaps, adaptive layers, monochrome layer, iOS AppIcon sizes, web icons |
| `logo-ms-monogram/` | Alternative MS monogram set, kept for reference |

Design source of truth for screens: `clean-retail-merged/DESIGN_SPEC.md`. The page with the three directions and extra
screens (Light and Bold variations) was published as an artifact: https://claude.ai/artifact/PxT4FriPhTMENSADTykzq6
Figma file with the app icon: https://www.figma.com/design/ryg8yNJY7hIXmqLLZR6mgy

## Decisions already made
- Direction: **Clean Retail** merged with the **Light** variation (photo-first product cards, floating order bar, item bottom sheet, delivery timeline).
- Brand red: **`#DB2031`** (same as `msRedArgb` in `lib/core/constants.dart`). Ink `#1D1B1A`.
- Header logo: white rounded tile with the colour mark (`logo-ms-box/png/header-tile`, Flutter 1x/2x/3x at 36 logical px).
- Font for UI: Plus Jakarta Sans (design), wordmark is outlined artwork.

## Rules for csw5
1. **No behaviour changes.** Keep all business logic: LOV1 config parsing, order flow, sync, push, scanner, SQLite, API calls. Only change presentation (theme, widgets, layout) screen by screen.
2. Keep the existing folder structure (`lib/features/*`, `lib/data/*`, `lib/router/*`) so diffs against `csor_csw` stay reviewable.
3. Config-driven UI (order types, form fields, totals, tile grid from LOV1) must still render whatever the server returns.
4. Features marked "needs backend" in `DESIGN_SPEC.md` (margin, suggested qty, repeat last order, delivery timeline, approval notes, price-change warnings) are **phase 2**; do not call new endpoints.

## Setup steps (local)
1. Copy `csor_csw` to a sibling folder, e.g. `C:\Users\Akhil\Work Drive\android-workspace\csw5` (exclude `build/`, `.dart_tool/`, `.git`). `git init` in the copy.
2. `pubspec.yaml`: `name: csw5`, `version: 5.1.01+<build>`. **Verify** `flutter pub get` accepts the leading zero in `5.1.01`; if it does not, use `5.1.1+<build>` and show "5.1.01" from a constant in the Help screen.
3. Rename identifiers so csw5 can install next to the old app. **Ask the user for the new ids first**: Android `applicationId`, iOS bundle id, app label (suggest "CSW5").
4. **Push notifications:** `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are tied to the package or bundle id. A new id needs a new Firebase app registration, or FCM tokens will fail. APNs key also needs to be linked for the new bundle id.
5. iOS cannot be built on Windows: reuse the Codemagic flow (`codemagic.yaml`) with the new bundle id, new App Store Connect app record and signing.
6. Replace launcher icons with `launcher-icon/png/android/*` and `launcher-icon/png/ios/AppIcon-*.png`, add the adaptive and monochrome layers.

## Implementation phases
1. Theme: `ThemeData` from the tokens (colours, type scale, radii) and shared widgets: `AppHeader`, `BottomNav`, `PrimaryButton`/`OutlineButton`, `StatusPill`, `FilterChip`, `ProductCard`, `QtyStepper`, `FloatingOrderBar`, `ListRow`, `InfoField`, `Timeline`, `ItemSheet`.
2. Login/setup, dashboard (home).
3. Order entry flow (select customer, order type, header form, order filling, item detail).
4. Catalog, review orders, approvals, send orders, invoices.
5. Messages, backroom, refresh data, help.
6. Test each screen against the old app for identical behaviour; run on a handheld (Datalogic scanner) before release.

## Open questions for the user
- New Android `applicationId` and iOS bundle id for csw5?
- New GitHub repo for csw5, or a folder inside an existing one?
- Is the box logo final, and is the original logo file available (SVG/AI/PDF) for exact artwork?
- Do the third-party company's terms allow reusing their existing logo?
