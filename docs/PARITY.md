# MarketSquare Flutter — Native Parity Backlog

Tracks remaining gaps vs the native Kotlin/Compose CSWG Ordering app. Grouped by
area, prioritised. **P1** = ordering correctness / core parity, **P2** = screen
parity, **P3** = polish. Status: ☐ todo · ◐ partial · ☑ done.

> Many items are **LOV1-config-driven and conditional**. To implement the exact
> conditions faithfully we need a real LOV1 JSON sample from a logged-in store
> (capture from the Debug screen log or `LOV1_CONFIG_JSON` in prefs). Without it
> conditions are inferred from the native Kotlin.

## Data sync / refresh
- ☑ Fetch + save `ORDER_DEPT_TYPES-LOV1` (customers, tiles, buttons, fields)
- ☐ **P1** Full inventory step `ITEMS_INVENTORY-ITEM2` (merge into item table)
- ☐ **P1** Delta inventory refresh `ITEMS_INVENTORY-DELTA` (`runDeltaInventoryRefresh`) — run on order-entry enter
- ☐ **P1** Promo item file `PROMO_ITEM_FILE` → Refresh Data "AD PROMO ITEM FILE" block
- ☐ **P2** Welcome messages `WELCOME_MESSAGES-WELCOME`
- ☐ **P2** Image download service → Refresh Data "IMAGES IN STORE" count + Search Images
- ◐ Refresh Data screen (layout done; AD PROMO + image count show "—")

## Order entry
- ☐ **P1** Rich item tiles from `tileConfigMap` (per-request-type configs) — image, List/Upcharge/Deal/Delivered cost, In Stock/LOQ, qty stepper, Ucost/SRP/CUBE/GM%, Prv.Orders; DS/SI watermarks; deal highlight. Currently simple line rows + default config.
- ☐ **P1** Per-order-type behaviour & field sets:
  - ITEM_ORDER, AD_ORDER (ad date/id)
  - PRICE_CHANGE (BASE / NEW price fields, item-detail edit)
  - TAG_ORDER, TPR
  - CREDIT_REQUEST (reason codes, credit type, invoice #)
- ☐ **P1** Delta inventory refresh on order-entry enter
- ☐ **P2** Per-store LOV1 re-fetch on order-entry enter (native re-saves LOV1)
- ☐ **P2** Item-entry top bar: PARTITION / QTY / CHARGE / SEARCH + "tap to key item" + grid key icon
- ☐ **P2** Item detail screen (PRICE CHANGE style): DONE / ITEM DETAILS / DELETE
- ◐ Control-button action bar (renders now; APPROVE/LINKED actions need wiring)
- ☑ Customer list, order types, form fields, control buttons populate from LOV1

## Item catalog
- ◐ Menu screen — rename to native (SEARCH ALL, BY DEPARTMENT, BY C&S CATEGORY, BY NEILSON CATEGORY, SEARCH DEALS, SEARCH IMAGES), centered circle-icon cards
- ☐ **P1** Catalog item list uses rich tiles (default tileConfiguration)
- ☐ **P2** Search Deals form (DEPARTMENT / CATEGORY / AD PLAN / "deals effective next billing date" toggle / SUBMIT)
- ☐ **P2** Search Images screen

## Review orders
- ☐ **P1** Conditional option visibility by LOV flags — View Invoices / View Invoices-PDF / Order Approval gated; View Device Orders + View All Previous Store Orders always (currently all 5 always shown)
- ◐ **P2** Order Approval list parity — checkboxes, Dept/Date/Conf#/Items/Cases/Est$ columns, DELETE SELECTED + confirm dialog, "retrieving details" overlay, approve confirm dialog (verify vs native)
- ◐ Invoices list / detail / PDF (exist; verify + gate)

## Help
- ☐ **P2** Help layout: version, EMAIL / CALL cards, OPERATIONAL GUIDE, SCAN DEBUGGING, DEBUG
- ☐ **P2** Operational Guide (PDF viewer)

## Polish
- ◐ Connectivity indicator live wiring (green/red by real connectivity)
- ☑ Connectivity indicator visual (green broadcast circle)
- ☑ ANDROID_ID device id, CSWG branding, dashboard/refresh styling, Change Store, dynamic action bar
