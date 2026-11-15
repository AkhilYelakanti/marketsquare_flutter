# MarketSquare · Clean Retail (merged) — design spec

Merged direction: original Clean Retail structure (red header with rounded bottom,
bottom navigation, tile shortcuts) + Light variation (photo-first product cards,
floating order bar, item bottom sheet, delivery timeline). Frame size 360 × 760.

## Files
| File | Purpose |
|---|---|
| `00-overview.svg` / `.png` | All 10 screens on one sheet (drag the SVG into Figma as one import) |
| `01`…`10-*.svg` | One screen per file, named layers (Header, Bottom navigation, Product card/…, etc.) |
| `generate_svgs.py` | Source that generated the SVGs. Run `python3 generate_svgs.py <out_dir>` to regenerate |

## Importing into Figma
1. Drag `00-overview.svg` (or the individual files) onto a Figma page. Shapes and text stay editable.
2. Install font **Plus Jakarta Sans** (Google Fonts) so text renders as designed.
3. Convert repeated groups to components: Button, Status pill, Product card, List row, Chip, Field, Bottom navigation, Floating order bar, Header.
4. Create Figma variables from the tokens below and bind fills to them.
5. Apply auto-layout to the components (the SVG import has absolute positions only).

## Screens
| # | Screen | Flutter route (existing) |
|---|---|---|
| 01 | Sign in | `/login` |
| 02 | Home | `/dashboard` |
| 03 | Order type (with Repeat last + standing orders) | `/select_order_type`, `/standing_orders` |
| 04 | Order filling (product grid + floating bar) | `/order_filling` |
| 05 | Item bottom sheet | `/order_item_detail` |
| 06 | Catalog | `/item_catalog` |
| 07 | Review & send (timeline) | `/send_orders`, `/submit_order` |
| 08 | Orders list | `/review_orders` |
| 09 | Approval detail | `/approval_order_detail` |
| 10 | Inbox | `/messages` |

## Color tokens
| Token | Hex | Use |
|---|---|---|
| `brand/red` | `#C4202E` | Header, primary buttons, active nav, quantity badge |
| `brand/red-tint` | `#FDECEE` | Draft card, icon chips, suggestions |
| `ink` | `#1D1B1A` | Primary text, floating bar, selected chip |
| `muted` | `#9A928D` | Secondary text |
| `surface/bg` | `#FAF8F7` | Screen background |
| `surface/card` | `#FFFFFF` | Cards, fields |
| `line` | `#ECE7E4` | Card borders, dividers |
| `field-border` | `#E3DEDB` | Input borders, outlined buttons |
| `image-bg` | `#F6EFE9` | Product image placeholder |
| `success` / `success-bg` | `#1E7A3A` / `#DFF3E4` | Approved, paid, positive margin |
| `warning` / `warning-bg` | `#8A5A00` / `#FDF0D4` | Pending, ad, below minimum |
| `error` / `error-bg` | `#A3111F` / `#FBE0E2` | Overdue, important alert |

Note: the app builds its theme from the brand colour returned by the server, so in Flutter `brand/red` and its tint should be derived from `colorScheme.primary`, not hard-coded.

## Typography (Plus Jakarta Sans)
| Style | Size / weight | Use |
|---|---|---|
| Display | 26 / 800 | Sign-in headline |
| Title | 19–22 / 800 | Screen title, store name |
| Heading | 16 / 800 | Card headings, prices |
| Body strong | 12–13 / 700 | Row titles, buttons (13) |
| Body | 11–12 / 500–600 | Descriptions |
| Caption | 10–10.5 / 500–700 | Metadata, pills, nav labels |
| Overline | 9.5–10 / 800, +0.6–0.8 letter spacing | Field labels, section tags |

## Spacing, radius, elevation
- Screen gutter 16; card gap 8–12; list row height 58; card padding 12–16.
- Radius: header bottom 24, cards 16, product card 18, bottom sheet 28, inputs 12, pills and buttons full (height / 2), chips 15.
- Touch targets: buttons 40–52 high, bottom navigation 70 high. Raise stepper buttons to 40 minimum in Flutter (design shows 26 for density).
- No shadows except the floating order bar and bottom sheet scrim (black 45%).

## Components to build (Flutter widget names suggested)
| Component | Variants / states |
|---|---|
| `AppHeader` | with back, with action icon, with search bar (catalog, home) |
| `BottomNav` | 4 items, active / inactive |
| `PrimaryButton` / `OutlineButton` | 52, 44, 40 high; disabled; loading |
| `StatusPill` | success, warning, error, brand |
| `FilterChip` | selected / unselected |
| `ProductCard` | qty 0 / qty > 0 (badge), deal tag |
| `QtyStepper` | compact (card), large (item sheet) |
| `FloatingOrderBar` | totals + Review |
| `ListRow` | icon chip + title + subtitle + trailing |
| `InfoField` | label + value, placeholder |
| `Timeline` | done / upcoming steps |
| `ItemSheet` | metrics, suggestion, stepper, add CTA |

## Data and config notes
- Order types, form fields, totals (cases, cube, estimate), alerts and order minimums come from the server config (LOV1). The designs show typical values; the layout must render whatever the config returns.
- The 9×9 configurable tile grid is replaced by `ProductCard` for the default view. Add a compact list toggle for stores whose tile config needs many fields.
- Needs backend work (not in the current app): margin, "suggested quantity", "Repeat last order", delivery timeline status, approval notes, price-change warnings.
