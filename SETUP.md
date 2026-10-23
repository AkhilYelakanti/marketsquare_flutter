# MarketSquare — Flutter port

Cross-platform (Android + iOS) rewrite of the native Kotlin/Compose app
`com.ms.marketsquare`. The original Android project is untouched; this is a
separate Flutter project in a sibling directory.

## What's in this first drop

**Full app architecture + one working vertical slice.** The slice proves the
pattern end-to-end; the remaining ~50 screens are ported area-by-area on top of
it.

Ported & working:
- **Splash** → session check → route (login or dashboard / rep store select)
- **Login / User Setup** — real device-setup API + OAuth token, branding + session persisted
- **TOS** and **Data Sync** — simplified gates (backend recording/download are follow-ups)
- **Dashboard** — 2-column grid, order-entry wide tile, rep vs. non-rep tile swap, date footer
- **Order Entry entry screen** — active store + working barcode scanner demo
- Every other native route is a **navigable placeholder** so the whole app shell browses

Infrastructure (reusable by all future screens):
- **State**: Riverpod (`*Controller` Notifiers ≈ native ViewModels)
- **Navigation**: go_router, route constants 1:1 with native `NavGraph` (`lib/router/`)
- **Networking**: Dio client replacing Ktor (`lib/core/network/`, `lib/data/repository/`)
- **Session**: SharedPreferences-backed `SessionManager` (`lib/data/session/`)
- **Theme**: brand-color theming, MsRed default, parsed from login (`lib/core/theme/`)
- **Push**: Firebase Messaging + local notifications + deep-link router (`lib/data/push/`)
- **Scanner**: `mobile_scanner` replacing CameraX + MLKit (`lib/widgets/scanner_sheet.dart`)

## Architecture map (native → Flutter)

| Native (Kotlin) | Flutter |
|---|---|
| Jetpack Compose | Flutter widgets |
| ViewModel + StateFlow | Riverpod `Notifier` + immutable state |
| Navigation-Compose `NavGraph` | `go_router` (`lib/router/app_router.dart`) |
| Ktor `HttpClient` | Dio (`lib/core/network/api_client.dart`) |
| `SessionManager` (SharedPreferences) | `SessionManager` (shared_preferences) |
| Room | *(to port)* drift/sqflite |
| Firebase Messaging + `FcmTokenProvider` | firebase_messaging + `FcmService` |
| CameraX + MLKit | mobile_scanner |
| Coil | cached_network_image |

## Run it (Android)

```bash
cd marketsquare_flutter
flutter pub get
flutter run
```

Login hits `https://<hostId>.cswg.com/devicesetup/1.0` exactly as the native app.

## Firebase / push setup (required for notifications)

Push is **off until configured** — the app runs fine without it (login never
blocks on push, matching native behaviour).

### Android
1. In the Firebase console, add an Android app with package `com.ms.marketsquare`.
2. Download `google-services.json` → place in `android/app/google-services.json`.
3. The Google Services Gradle plugin auto-applies when that file is present (see `android/app/build.gradle.kts`). Rebuild.

### iOS (must be built on a Mac with Xcode — you're on Windows)
1. Firebase console → add an iOS app with bundle id `com.ms.marketsquare`.
2. Download `GoogleService-Info.plist` → add to `ios/Runner/` (via Xcode so it's in the target).
3. Apple Developer: create an **APNs auth key (.p8)** and upload it to Firebase console → Cloud Messaging.
4. In Xcode: Runner target → Signing & Capabilities → add **Push Notifications** and **Background Modes** (Remote notifications). `Info.plist` already declares the background mode.
5. On the Mac: `cd ios && pod install`, then `flutter build ios` / run from Xcode.

### Backend push contract (already implemented, native parity)
FCM `data` payload `screen` routes deep links: `HOME`, `ORDER_APPROVALS`
(+`confirmId`/`mode`), `REFRESH_DATA`, `REVIEW_ORDERS`, `INVOICES`
(+`invoiceNumber`). Deep links wait until the user is past splash/login/sync.

## Order Entry flow (ported)

`lib/features/orderentry/` — shared Riverpod `OrderEntryController` (port of
`OrderEntryViewModel`) drives the whole flow:
- **Select Customer** → **Select Order Type** → **Order Header** (dynamic form
  from the order type's field config: partition picker, text/date/dropdown
  overlays, validation) → **NEW** → **Order Filling** (order lines with qty
  +/-/remove, totals bar, SEARCH / SCAN / SEND controls) → **SEND** persists the
  order to local SQLite as UNSENT and continues to Send Orders.
- **Order Item Search** (debounced ≥3-char search) and **Multiple Items
  Returned** (mults) are wired to the item repository.
- Faithful API payload builder (`OrderRepository.buildPayloadJson`): ITEM_ORDER /
  AD_ORDER / TAG_ORDER / TOBACCO, PRICE_CHANGE / TPR, and CREDIT_REQUEST shapes
  with per-partition grouping + transmission summaries, `Authorization: Bearer`
  + `CSOR-Token` headers — byte-compatible with the native builder.
- Local DB: `pending_orders` + `items` tables via sqflite (replaces Room).

**Depends on, and simplified until, these follow-ups:**
- **Item catalog DB population** — the `items` table is filled by the Data Sync
  download (not yet ported), so item **search returns empty** until then.
  Scan/keyed codes still add order lines (minimal line when not in catalog), so
  the flow is exercisable today.
- **LOV1 config parsing** — `OrderConfig` reads the obvious LOV1 keys
  (customers, request types, partitions, cr/data1 lists, flags) with the native
  ViewModel's defaults; the full bespoke LOV1 parsing (control buttons, totals,
  tile configs, mandatory/optional attribute maps, service-URL mapping) is part
  of the SessionManager-config port. The flow runs on defaults meanwhile.
- **Item-status / qty alert pipeline** and catalog **tile cards** (native
  `OrderAlertHost` / `ItemTileCard`) ride on the item-catalog module.
- Per-store LOV1 re-fetch + image-download prompt on customer tap; standing
  orders; edit-saved-order; scan telemetry — not yet ported.

## Send Orders flow (ported)

`lib/features/sendorders/` — port of the Send Orders module:
- **Send Orders** lists UNSENT orders from the local DB (select, delete),
  SEND SELECTED runs the pre-submit pipeline.
- **Pre-submit pipeline** (`SendOrdersController`, port of `SendOrdersViewModel`):
  Recommended Items check → Order Minimum check → submit, all **fail-open**
  (any network/parse failure proceeds to submit, matching native).
- **Recommended Items** screen: edit qty, PROCEED appends items to the order and
  continues; **Order Minimum** screen: shows the shortfall message with ADD TO
  ORDER / SEND WITHOUT ADDING; **Submit Order** screen: submits, parses the
  confirmation/receipt, marks the order SENT, shows success/failure.
- `OrderRepository.preOmCheck` / `preRecommendedItemsCheck` / `submitSavedOrder`
  reuse the same faithful payload builder.

**Simplified until follow-ups:**
- The two gate toggles (`isOrderMinimumCheckEnabled` / `isRecommendedItemsCheckEnabled`)
  and approval-submit mode default **off** (LOV1 flags) — so SEND goes straight to
  submit until full LOV1 parsing lands. The pipeline code is in place; flipping the
  flags on activates the gates.
- Server HTML (order-minimum message, submit response) is rendered as **plain text**
  (`core/html_text.dart`) — native uses a WebView; add `webview_flutter` later for
  exact rendering.
- ADD TO ORDER returns to the in-memory order; reloading a saved order for edit
  (native `loadSavedOrderForEditing`) is a follow-up.

## Item Catalog + Data Sync (ported)

The item table is now real and **item search returns results**.

- **Dynamic ingest** (`data/db/item_file_db.dart`, port of `ItemDatabaseHelper`):
  the item-file download (ZIP or delimited text) is parsed with auto-detected
  delimiter (`|`, tab, `,`); a dynamically-schema'd `item_file_data` table is
  dropped + recreated from the header row; item/dept columns auto-detected; the
  schema is recorded in `refresh_metadata`.
- **`ItemRepository`** queries `item_file_data` by the resolved column names and
  returns each row with its raw CSV columns **plus canonical alias keys**
  (`itemNumber`, `description`, `pack`, `upc`, `department`, `adEffective`,
  `allowance`, `cube`, `itemCodeMults`) — so the order-entry flow reads items by
  a fixed key set no matter what the server names its columns.
- **Data Sync** runs `ItemRefreshService.runFullRefresh` on login (authenticate →
  download `ITEMS_REFRESH-ITEM1` → ingest), fail-soft when the endpoint isn't
  configured. **Refresh Data** screen re-runs it and shows last-refresh info.
- **Order item search + order filling now pull real catalog rows** (pricing,
  dept, cube) once the table is populated.

**Using it without a backend:** Dashboard → Refresh Data → **LOAD SAMPLE CATALOG
(DEV)** ingests a bundled `assets/sample_items.psv` (15 items) so item search and
order lines work immediately. This dev seed is not part of the native app.

**Simplified / follow-ups:**
- Inventory merge (`ITEMS_INVENTORY` into item file), promo/welcome/image
  downloads, delta inventory, and the catalog sub-screens (department list,
  category lists, filtered list, deals, images, saved items) are not yet ported
  (placeholders remain).
- Catalog tile-card rendering + the item-status/qty alert pipeline still ride on
  their own follow-up.

## Review Orders + Order Approvals (ported)

`lib/features/revieworders/`:
- **Review Orders** landing → View Device Orders / View All Previous Store Orders
  (placeholder) / Order Approval / View Invoices (placeholder).
- **View Device Orders**: all orders on the device (UNSENT + SENT) from the local
  DB, with a line-item detail dialog.
- **Order Approval** chooser → **Approvals List** (WAITING / APPROVED via `?mode`):
  single-select rows; WAITING supports **delete selected** and **open order**
  (fetches the order, saves it locally as UNSENT, opens it in Send Orders);
  APPROVED opens a read-only **Approval Order Detail** (items grouped by dept).
- `OrderRepository` gains `fetchApprovals` (waiting/approved), `fetchApprovalOrder`,
  `deleteWaitingApprovals`, posting to the approval service URLs with the faithful
  request shapes; `ApprovalsController` (Riverpod) is the port of
  `ApprovalsListViewModel`.
- Push deep links already route here (`ORDER_APPROVALS` → approvals list/detail,
  `REVIEW_ORDERS` → review orders).

**Simplified / follow-ups:**
- Store-order history (SelectStore / StoreOrdersList / StoreOrderDetail /
  StoreOrderResponse — RECENT_ORDERS / RETRIEVE_ORDER endpoints) remain placeholders.
- Opening a waiting order loads it into Send Orders, not back into the live order
  editor (edit-load follow-up).
- Approval list/detail need the live approval endpoints configured (LOV1); with no
  backend the list shows an empty/error state.

## Invoices (ported)

`lib/features/invoices/`:
- **Invoice List**: date-range + invoice# filters → list of invoices (tap → detail).
- **Invoice Detail**: header (number/date/dept/total) + line items.
- **Invoice PDF**: fetch a PDF by number; bytes are saved to a local file.
- `OrderRepository.fetchInvoiceList` / `fetchInvoiceDetails` / `fetchInvoicePdf`
  (bytes) post to the invoice service URLs; `InvoicesController` (Riverpod) ports
  `InvoicesViewModel` + `InvoicePdfViewModel`. Push `INVOICES` deep links route here.

**Simplified / follow-ups:**
- The PDF is saved to disk but **not rendered in-app** — add a PDF-viewer plugin
  (e.g. `pdfx`/`printing`) to display pages (native uses `PdfRenderer`).
- Needs the live invoice endpoints configured (LOV1); with no backend the list
  shows an empty/error state.

## Backroom Inventory (ported)

`lib/features/backroom/` — fully local (no network), port of `BackroomViewModel`:
- **Backroom Inventory** landing → Update / Pull List / Reset.
- **Update Inventory**: pick department (dropdown from LOV1 partitions, or manual),
  enter/**scan** an item code + qty → ADD (adds to an existing (dept,itemCode)
  record or creates one); shows the department's items.
- **View Pull List**: all items grouped by department; **PULL** removes one unit
  (deletes the row at 0).
- **Reset Inventory**: clear one department or everything (confirm dialog).
- Local `backroom_inventory` table (sqflite, DB v3) + `BackroomDao`; reached via a
  minimal **Other Options** landing.

## Messages + Help (ported)

**Messages** (`lib/features/messages/`):
- Local `messages` table (sqflite, DB v4) + `MessageDao`; `MessagesRepository`
  (Dio) pulls from `PULL_MESSAGES-PULLMSG` / `REFRESH_MESSAGES-REFRESHMSG` into the
  table and sends read receipts (`MESSAGE_READ_RECEIPT`), grouped by `deptQueue`.
- **Messages screen** (dashboard tile): group list → group messages → detail,
  with read marking. Dashboard Messages tile shows an **unread badge**.
- Polling replaced by pull-on-open; the mandatory IMPORTANT alert is a follow-up.

**Help** (`lib/features/help/`):
- **Help** menu + support email/phone (LOV1) + version → **Operational Guide**
  (cached manual text), **Scan Debug** (scanner test), **Debug** (session/app info
  + debug-logging toggle). FileLogger output is a follow-up.

**Simplified / follow-ups:** message pull needs the live endpoints (empty without
a backend); IMPORTANT alert dialog + inbound push-message insert; file logging.

## Standing Orders + Store-Order History (ported)

**Standing Orders** (`lib/features/orderentry/standing_orders_screen.dart`): list
saved favourite-order templates, **START** one (fetches + loads its lines into the
order editor → Order Filling), **delete**, or **save the current order as a
template**. `OrderRepository` gains the favourite endpoints
(`FETCH_FAVOURITE_ORDER_NAMES` / `FETCH_FAVOURITE_ORDERS` / `SAVE_FAVOURITE_ORDER` /
`DELETE_FAVOURITE_ORDER`); `StandingOrdersController` + `OrderEntryController.loadTemplateLines`.

**Store-Order History** (`lib/features/revieworders/`): Review Orders → View All
Previous Store Orders → **Select Store** → **Store Orders** list (`RECENT_ORDERS`)
→ **Store Order Detail** (`RETRIEVE_ORDER`, header + dept-grouped lines).
`StoreOrdersController` ports `ViewAllOrdersViewModel`.

**Simplified / follow-ups:** both need the live endpoints (empty without a
backend); the separate template-select screen and the order-response screen
remain placeholders.

## Item Catalog sub-screens (ported)

`lib/features/itemcatalog/`:
- **Departments / CS Categories / Neilson Categories** (`CatalogListScreen`):
  distinct values from the item table → tap → filtered item list.
- **Filtered item list** (`ItemFilteredListScreen`): items for a department,
  category, or deals-only (via query params); tap → item detail.
- **Search Deals**: filtered list with the deal-flag filter.
- **Saved Items** (`SavedItemsScreen`): the user's saved item codes (prefs),
  resolved against the catalog, with remove.
- **Item Images** (`ItemImagesScreen`): reached from item detail; shows the
  no-images state (image-package download is a follow-up).
- `ItemRepository.queryItems` adds department/category/deals filtering and column
  resolution (CS/Neilson/deal-flag); catalog landing now links all sub-screens.

With this the item-catalog module is complete; all return real rows once a
catalog is loaded (Refresh Data → Load Sample Catalog, or a live sync).

## LOV1 config parsing (ported)

`OrderConfig.fromLov1Json` now fully parses the stored LOV1 config (faithful to
the SessionManager getters), so order behaviour is server-driven:
- **Customers, request types, partitions, dept list, store categories, store
  invoices** (list keys, string-or-object forms).
- **Form fields** (`formFieldsInOrdering`/`formFeildsInOrdering`, string → config
  via the ported `stringToFormFieldConfig`, or object form) + **mandatory/optional
  attribute maps** per request type.
- **Control buttons** (`orderControlButtons` map or array, incl. the Y/N
  sub-format with icon hints), **totals** (`orderTotals`), **data1/cr dropdowns**.
- **Gates now activate from config**: `isOrderMinimumCheckEnabled` /
  `isRecommendedItemsCheckEnabled` (with `addRecommendedItemsToOrder` + sequence)
  / `isApprovalSubmit` (`orderApprovalView` + `enableOrderApproveRoleButton`),
  `restrictDepartment`, `displayAddTagToItem`, `displayDepartmentBreakup`.
- Session-level: `getOrderServiceUrl` now resolves the LOV1 `urlsMap` first (then
  the stored service map); support email/phone from `email`/`phoneNumber`;
  message subjects from `messagesSubject`; store invoices from `storeInvoices`.
- Backroom departments prefer the configured dept list; Messages groups use the
  configured subjects.

Covered by unit tests (`test/widget_test.dart`). Still a follow-up: the catalog
**tile configs** (`tileConfigMap`/`tileByRequestType`) drive tile-card rendering,
which rides on the tile-card/alert-pipeline follow-up.

## Tile cards + alert pipeline (ported)

- **Tile config** (`tile_config.dart`): parses `tileConfigMap` / `tileByRequestType`
  into `OrderTileConfig` (grid positions, CSS color/size/bold, calculated
  formulas) + a recursive-descent **formula evaluator** (`AD_EFFECTIVE*QTY_ENTRY`).
- **`ItemTileCard`** (`tile_widgets.dart`): config-driven rendering of catalog
  items (elements laid out by grid row/col with styling, calculated values,
  IMAGE placeholder, and a qty-entry stepper); falls back to a default layout
  when no tile config. Applies the alert **watermark + background**.
- **Alert pipeline** (`alert_pipeline.dart`): status-code alerts
  (`itemStatusAlertMessagesConfig`) on first add + qty **max/min** bounds
  (`allowedMaxQuantity` / per-item `ITEM_QTY_LIMITS` + `alertMessagesConfig`),
  producing an evaluation that is either a **popup** (`itemAlertNeeded = Y`) or a
  **silent** watermark/tint. `OrderEntryController.commitItem` runs it; Accept on
  a discontinued (`DS`) item substitutes the `ALTERNATE_ITEM_ID`.
- **`OrderAlertHost`** dialog + `OrderItemTile` wired into Order Item Search,
  Order Filling (scan + qty), and Mults — every add now funnels through the
  pipeline with config-driven popup text + buttons.
- `OrderConfig` now also parses `itemStatusAlertMessagesConfig`,
  `alertMessagesConfig`, `allowedMaxQuantity`, and the tile configs.
- Covered by unit tests (status/qty/formula).

**Follow-up:** the exact pixel grid (row/col spans, overlapping label+value
positions) is approximated as an ordered row/column layout; inventory-first
OOS/LTMO/SI routing + beep are simplified to status-code + qty.

## Inbound push → Messages + IMPORTANT alert (ported)

- `FcmService.onMessageData` fires for every received FCM message (foreground,
  opened-app tap, cold launch) with its `data` map.
- `MessagesController.ingestPushMessage` builds a `MessageRow` from the payload
  (`msgId`, `deptQueue`/`notificationType`, `msgText`/`body`, `msgOwner`,
  `storeId`, `lastComm`) and inserts it into the local `messages` table, then
  refreshes the unread counts (dashboard badge) and re-checks the IMPORTANT alert.
- **Mandatory IMPORTANT alert**: when an unread `IMPORTANT` message exists and
  LOV1 configures `MESSAGE_IMPORTANT` (`alertNeeded = Y`), the dashboard pops a
  config-driven dialog (header/text/buttons); "READ" opens Messages, the other
  dismisses. Wired via `checkImportant()` on dashboard show + `ref.listen`.
- Dev demo seeds an unread IMPORTANT message + the `MESSAGE_IMPORTANT` config so
  the alert + unread badge are visible without a backend.

**Follow-up:** background-isolate messages are inserted when the app next opens
or the notification is tapped (the background handler can't touch app state);
real-time background insert would need a background DB write in the handler.

## Datalogic hardware scanner (ported)

The device trigger feeds item scans via the Datalogic **Intent Wedge** (no SDK
AAR needed — the native app used a compile-only AAR that isn't in the repo):
- **Native** (`android/.../MainActivity.kt`): a dynamic `BroadcastReceiver` for
  `com.datalogic.decodewedge.decode_action` reads the barcode extra
  (`...intentwedge.barcode_string`) and streams it to Dart over an `EventChannel`
  (`com.ms.marketsquare/datalogic`), registered while Flutter is listening.
- **Dart**: `DatalogicScanner` exposes the barcode `Stream`; `HardwareScanListener`
  subscribes while mounted. Wired into **Order Filling** (scan → add via the alert
  pipeline / mults) and **Order Item Search**. Non-Android or trigger-not-firing →
  stream stays empty; the on-screen camera scanner still works.

**Device setup (one-time):** on the MEMOR 10, Settings → Scanner Settings →
**Wedge → Intent Wedge = ON**, delivery mode **Broadcast**, action
`com.datalogic.decodewedge.decode_action` (DL default). Then the hardware trigger
adds items in the order screens. The DL SDK's programmatic `BarcodeManager` path
is an alternative if the AAR is added to `android/app/libs/`.

## Porting roadmap (remaining native modules)

Each becomes a feature folder under `lib/features/` + a Riverpod controller,
replacing its placeholder route:

1. Item Catalog (search, departments, categories, detail, images, deals, saved items)
2. Order Entry flow (customer/order-type/partition select, order filling, item search, mults)
3. Send Orders (minimum check, recommended items, submit)
4. Review Orders / Store Orders / Device Orders
5. Order Approval (list, detail) + Invoices (list, detail, PDF)
6. Backroom Inventory (update, reset, pull list)
7. Other Options, Messages, Refresh Data, Help / Operational Guide / Debug
8. Local DB layer (Room → drift) for pending orders, messages, backroom items, refresh metadata
9. Full `SessionManager` LOV1 config parsing (drives order/dashboard behaviour — raw JSON is already stored)
10. Connectivity/network-status indicator, app-resume auth check

## Known simplifications in this drop
- TOS acceptance recording and Data Sync catalog download are stubbed gates.
- Dashboard order-entry pre-check overlay (native `OrderEntryCheckState`) not yet ported.
- Local DB not yet created; screens needing it use placeholders.
