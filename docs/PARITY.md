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
- ☑ Full inventory step `ITEMS_INVENTORY-ITEM2` (merge onto item table by ITEM_ID/DEPT_NAME) — needs backend verification
- ☑ Delta inventory refresh `ITEMS_INVENTORY-DELTA` (`runDeltaInventoryRefresh`), runs on order-entry enter — needs backend verification
- ☐ **P1** Promo item file `PROMO_ITEM_FILE` → Refresh Data "AD PROMO ITEM FILE" block
- ☐ **P2** Welcome messages `WELCOME_MESSAGES-WELCOME`
- ☐ **P2** Image download service → Refresh Data "IMAGES IN STORE" count + Search Images
- ◐ Refresh Data screen (layout done; AD PROMO + image count show "—")

## Order entry
- ◐ **P1** Rich item tiles from `tileConfigMap` — parser + a true positioned 9×9 grid renderer (name/value cells, CSS, CALCULATED/IMAGE, qty box). Remaining: real item images (needs image service), deal highlight, pixel-tune vs native. Verify against real items on backend login.
- ◐ **P1** Order-filling screen rebuild: PARTITION/QTY/CHARGE sort bar, inline "tap to key item" entry (number/UPC → fetch+add), item-not-found (2× alert + "NOT ON FILE", still orderable), bottom totals (per-type LOV), expandable 2-row toolbar (BACK/SEARCH/SEND default + LOV buttons). Remaining: QTY/CHARGE sort logic, exact tone/beep (needs ToneGenerator channel), tap→item-detail with ITEM_DETAILS_1 HTML.
- ☑ `orderTotals` parsed as dict-by-type (totalItem/totalEst/totalCube/totalCases); per-type totals row
- ☑ `defaultTileConfig` wired (fallback / item catalog)
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
- ☑ Menu screen — native labels (SEARCH ALL, BY DEPARTMENT, BY C&S CATEGORY, BY NEILSON CATEGORY, SEARCH DEALS, SEARCH IMAGES), centered circle-icon cards
- ☐ **P1** Catalog item list uses rich tiles (default tileConfiguration)
- ☐ **P2** Search Deals form (DEPARTMENT / CATEGORY / AD PLAN / "deals effective next billing date" toggle / SUBMIT)
- ☐ **P2** Search Images screen

## Review orders
- ☑ Conditional option visibility by LOV flags — `orderApprovalView` / `enableViewInvoice` / `displayInvoicePDF`; View Device Orders + View All Previous Store Orders always
- ◐ **P2** Order Approval list parity — checkboxes, Dept/Date/Conf#/Items/Cases/Est$ columns, DELETE SELECTED + confirm dialog, "retrieving details" overlay, approve confirm dialog (verify vs native)
- ◐ Invoices list / detail / PDF (exist; verify + gate)

## Help
- ☑ Help layout: version, EMAIL / CALL cards, OPERATIONAL GUIDE, SCAN DEBUGGING, DEBUG
- ◐ **P2** Operational Guide (PDF viewer) — tile wired; verify renderer
- ☐ **P3** Make EMAIL / CALL cards launch mailto: / tel: (needs url_launcher)

## Polish
- ◐ Connectivity indicator live wiring (green/red by real connectivity)
- ☑ Connectivity indicator visual (green broadcast circle)
- ☑ ANDROID_ID device id, CSWG branding, dashboard/refresh styling, Change Store, dynamic action bar
