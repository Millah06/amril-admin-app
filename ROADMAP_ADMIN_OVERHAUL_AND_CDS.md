# Amril — Admin Panel Overhaul, CDS, & Loose Ends

**Type:** Implementation roadmap. Hand this to a fresh chat: "read this MD and implement it."
**Scope:** Three repos.
- Admin: `C:\Users\HP\PersonalProjects\admin_panel` (Flutter) — the bulk of this doc.
- App: `C:\Users\HP\PersonalProjects\amril-app` (Flutter) — CDS screen, withdrawal-fee UI, web QR scan, KDS status.
- API: `C:\Users\HP\PersonalProjects\amril-api` (Node/Express/Prisma) — only if an endpoint is missing; most is done.

**Status of prior work:** Phases 1–4 of `amril-app/ROADMAP_HARDWARE_WEB_LANDING.md` are code-complete (hardware program, KDS mode, printing, fee/settlement, landing, responsive polish). This doc is the follow-up: the admin panel is functional but its UI is weak, plus a few app-side items the owner flagged.

---

## 0. Ground rules (read first)

1. **Amril app UI >> admin panel UI.** When building admin UI, COPY patterns/widgets/snippets from `amril-app` rather than inventing. Named reuse targets are listed per-task below. The single most important one: **image upload** — `amril-app/lib/shared/widgets/image_editor.dart` (`AppImagePicker`) already does multi-image pick + crop/edit + returns `List<XFile>`, and `amril-app/lib/shared/utils/upload_helpers.dart` does web-safe multipart. Port these; do NOT write a new picker.
2. **No dialogs for create/edit.** The owner explicitly hates the current dialog-based hardware CRUD. Every create/edit/add flow must be a **dedicated full screen** with proper fields, preloaded data on edit, a Save button, and validation. Dialogs are only acceptable for a destructive confirm ("Delete this?").
3. **Paginate everything that lists.** Any list that can grow (vendors, orders, hardware orders, transactions, users) must be cursor- or page-paginated, not a single unbounded fetch. The API already uses cursor pagination on many endpoints (`amril-api` `utils/pagination.ts`, `buildPage`/`decodeCursor`); reuse it.
4. **Don't touch these two files carelessly:** `admin_panel/lib/features/marketPlace/screens/appeal_detail_screen.dart` and `vendor_detail_screen.dart`. A previous AI corrupted them (UTF-16 + cross-swapped contents); they were just restored from git and are clean UTF-8 now. If you edit them, keep UTF-8, and NEVER use PowerShell `>` redirects to write Dart (that produces UTF-16-LE with null bytes that Dart can't compile — use the Write/Edit tools).
5. **Verify after each area:** `cd admin_panel && flutter analyze` must stay at **0 errors**. The project currently builds (debug APK confirmed) on `font_awesome_flutter ^11.0.0` + `google_fonts ^6.3.3`. FontAwesome 11 needs `FaIcon(FontAwesomeIcons.x)`, never `Icon(FontAwesomeIcons.x)` (the icons are `FaIconData`, not `IconData`).

---

## 1. Admin panel — architecture as-is (so you know what you're changing)

```
admin_panel/lib/
  core/network/dio_client.dart      → DioClient.get/post/patch/delete (static). Base URL
                                       https://everywhere-data-app.onrender.com. Firebase token auth.
  core/constants/api_constants.dart → all endpoint paths (hardware paths already added)
  core/theme/app_theme.dart         → AppTheme.{background,surface,surfaceVariant,primary(cyan),
                                       accent(green),success,warning,danger,textPrimary,textSecondary,divider}
  features/
    dashboard/      (model/provider/service/screen) — top-level app dashboard
    analytics/, reconciliation/, transactions (in admin controllers)
    marketPlace/
      shell.dart    → bottom-nav shell: Overview | Vendors | Appeals | Hardware | Config
      models/       config_model, vendor_model, appeal_model, hardware_model
      providers/    config_provider, vendor_provider, appeal_provider, dashboard_provider, hardware_provider
      service/      *_service.dart (thin DioClient wrappers)
      tabs/         dashboard_tab, vendors_tab, appeal_tab, hardware_tab, config_tab
      screens/      vendor_detail_screen, appeal_detail_screen, order_chat_view, vendor_filter_sheet
  screens/login.dart  → the sign-in/passcode screen (weak, see §7)
```

The provider/service/model/tab pattern is clean and worth keeping. The problems are all in the **tab UIs** (dialogs, no pagination, missing detail navigation) and **config** (editable inline instead of read → edit-page).

---

## 2. TASK — Hardware admin, rebuilt (highest priority; owner most unhappy here)

Current state (`tabs/hardware_tab.dart` + `providers/hardware_provider.dart` + `service/hardware_service.dart`, all built in Phase 2 A4): a `SegmentedButton` toggles Products/Batches/Orders; create/edit are **dialogs**; bullet points are one textfield; no image upload; orders show only vendor NAME with no way to see the vendor; changing batch state doesn't reflect on orders. Rebuild it:

### 2.1 Hardware Products
- **List screen:** paginated list of product cards (image thumb, name, tier chip, price, active toggle). Reuse the card styling from `amril-app` `hardware_catalog_page.dart` `_productCard` as a visual reference.
- **Dedicated create/edit screen** (`hardware_product_edit_screen.dart`), NOT a dialog:
  - Fields: name, SKU, tier (segmented budget/premium — see §4, tiers may expand), description (multiline), price (₦), branding upcharge (₦, optional), **bullet points as a proper repeatable list** (each bullet its own row with add/remove, NOT one textarea), active toggle, sort order.
  - **Image upload:** port `AppImagePicker` from `amril-app/lib/shared/widgets/image_editor.dart` (multi-image, crop/edit) + `upload_helpers.dart`. Products have `images String[]`. Needs an admin image-upload endpoint — **CHECK**: `amril-api` has `uploadImage.service.ts` (Cloudflare R2) and vendor upload controllers; add an admin endpoint `POST /admin/hardware/product/:id/images` (multer `.array("images")`, `requireAdmin`) that appends to `HardwareProduct.images`. Mirror `uploadMenuItemImages` in `amril-api/src/modules/marketPlace/upload/uploadController.ts`.
  - On edit, preload all fields from the product. Save = POST (create) or PATCH (update) via existing `hardwareController` admin endpoints.
- Keep the destructive **delete** as a confirm dialog (that's fine).

### 2.2 Hardware Batches
- **List** of batches (tier, state, reserved/target progress bar, ETA note).
- **Dedicated edit screen** (`hardware_batch_edit_screen.dart`): MOQ target, state dropdown (collecting→producing→shipping→fulfilling→closed), ETA note. Preload on edit.
- **BUG the owner hit — batch state does NOT propagate to member orders. OWNER DECISION (LOCKED): auto-advance member orders.** When an admin moves a batch `collecting → producing` (and later states), bulk-update all member `HardwareOrder{batchId}` to the corresponding order status. Implement in the backend: in `amril-api` `hardware.controller.ts` admin `updateBatch`, when `state` changes, update every `HardwareOrder` with that `batchId` whose status is BEHIND the new batch state, mapping:
  - batch `producing`  → orders `inProduction`
  - batch `shipping`   → orders `shipping`
  - batch `fulfilling` → orders `atHub`
  - batch `closed`     → leave orders (admin finishes delivered/installed manually per-order)
  - Only advance orders that are behind (don't rewind a `delivered` order because the batch is `producing`; don't touch `cancelled`). Respect the order status order defined by `HardwareOrderStatus` enum. Do it in one transaction. After the batch update returns, the app's My-Hardware timeline + the admin fulfillment board both reflect it. Keep manual per-order status advance too (for delivered/installed and exceptions).

### 2.3 Hardware Orders (fulfillment board)
- Paginated list. Each row: product ×qty, **vendor name that is TAPPABLE → opens the vendor detail screen** (`VendorDetailScreen` — it already exists and shows vendor address/branches/etc.). This is the owner's explicit ask: "on tab should take us to vendor detail page, so we know his detail, address." The admin `listOrders` endpoint already `include`s vendor `{id,name,phone}`; extend it to include enough for the detail screen OR just navigate with the vendorId and let `VendorDetailScreen` fetch (check how `vendors_tab.dart` opens it today and reuse that exact navigation).
- Keep the per-order **status dropdown** to manually advance reserved→…→installed (that part is fine), but make the row richer (branding flag, amount, batch, created date).

### 2.4 General hardware UI
- Replace the `SegmentedButton`-in-one-screen with either a cleaner tabbed layout or three list screens reachable from a hardware hub — your call, but no dialogs for edits, and everything paginated.

---

## 3. TASK — Config, read-only + edit page (owner: "config should be read-only, then edit config opens edit page with preloaded data, click save")

Current `tabs/config_tab.dart` is one big editable form (built in Phase 2). Rework into two screens:
- **`config_view_screen.dart` (read-only):** shows every config value in a clean, grouped, labelled read-only layout (Financials, Timings, Utility Bonuses, Vendor Fees & Settlement, Hardware Program). An "Edit" button top-right.
- **`config_edit_screen.dart`:** the current form, but as a dedicated page, **preloaded** with current values, Save → PATCH `/admin/config` → pop back to the view. Keep all fields already wired (transactionFeePercent, commissionPercent, fundingFees, autoReleaseHours, appealWindowHours, chatCloseHours, bonuses, withdrawalFeePercent, withdrawalFlatFeeNaira, netGatewayFromVendor, hardwareReservationMode, brandingAvailable). Model/provider/service already support all of these.
- **Make it feel premium, not cheap** (owner's words). Use `app_theme.dart` colors, section headers with icons, subtle cards per group. Reference the polish of `amril-app` settings/profile screens.
- **Reminder for the owner (surface in the view UI as a hint):** `commissionPercent` default is still 5 — the roadmap's locked rate is **3**. The view screen should just show whatever's set; the owner sets 3 in edit.

---

## 4. TASK — CDS (Customer Display System) — NEW, in `amril-app`

**Decision (owner-confirmed):** ONE app (not separate). A locked kiosk route inside `amril-app`. Works on both a wall tablet AND an Android TV box from the same APK. Premium branding (Amril + the restaurant's own logo/name — both).

### 4.1 The screen
- New route/page, e.g. `amril-app/lib/features/marketPlace/pages/cds_screen.dart`.
- **Read-only, zero interaction.** Landscape-forced. No app chrome (no BottomBar, no back nav, no wallet/feed). Keep screen awake (`WakelockPlus`, already a dependency).
- **Two columns:** `PREPARING` and `READY`. Big, glanceable order numbers (`orderNumber` for dine-in; short id otherwise). Reuse the realtime path KDS uses: listen to Firestore `orderPings/{ownerId}` and refetch `GET /order/vendor/list` (see `amril-app/lib/features/marketPlace/pages/kds_screen.dart` for the exact listener + fetch — copy it). Map: preparing column = orders with status `preparing`; ready column = `outForDelivery` (which the app relabels "Ready" for dine-in — see `order_model.dart` `statusLabel`). Confirm the status→column mapping against how KDS advances orders.
- **Branding (make it premium):**
  - The restaurant's logo + name at the top (from `myVendor.logo` / `myVendor.name`).
  - A subtle "Powered by Amril" mark (use brand cyan `#21D3ED`, the Amril lockup). Both brands present — restaurant is the hero, Amril is the trust mark.
  - Between updates / when idle, it can show the restaurant name large + a tasteful brand backdrop so a mounted screen never looks empty. Reference the landing page's dark premium aesthetic (`amril-web/landing.css` tokens) for the vibe.
- **First-boot setup:** the vendor "sets it once" — a small config gate that saves `vendorId`/`ownerId`/`branchId` to `SharedPreferences` (enter a code or scan a QR — reuse the QR scanner, see §6 so it works on web too). After that the device stays locked on the board. Document that Android **screen pinning** / kiosk mode is what physically locks the device (not app code).
- **Android TV discoverability:** add a `LEANBACK_LAUNCHER` intent-filter in `amril-app/android/app/src/main/AndroidManifest.xml` alongside the normal launcher intent, so the APK appears on the Android TV home. (Manifest only, no new code. CDS has no D-pad interaction so TV input isn't a concern.)

### 4.2 Hardware catalog / tiers — CDS + à-la-carte
Owner decision: move from rigid budget/premium bundles toward **bundles PLUS standalone add-ons**. CDS goes into Premium AND is buyable standalone; the **printer** should also be a standalone add-on (owner: "some items should also be like separate add on such as printer").

**OWNER DECISION (LOCKED): separate `category` field, NOT a third tier.** Keep `HardwareTier = budget | premium` UNCHANGED, and add a NEW independent field `HardwareCategory = bundle | addon`. Every product carries BOTH a tier AND a category — the two ideas stay separate (tier = which bundle level; category = is this a bundle or a standalone add-on). Examples:
```
PRODUCT              tier      category
All-in-One POS       premium   bundle
KDS + Printer combo  budget    bundle
Thermal Printer      budget    addon
Customer Display     premium   addon
```
Implementation:
- Prisma (`amril-api/prisma/schema.prisma`): add `enum HardwareCategory { bundle addon }` and `category HardwareCategory @default(bundle)` on `HardwareProduct`. Leave `HardwareTier` as-is. Add an index if you filter by category.
- **Prisma migration** — hand-write an idempotent additive migration under `amril-api/prisma/migrations/` (see `20260706000000_hardware_and_fee_model/migration.sql` for the `DO $$ ... EXCEPTION WHEN duplicate_object` guard style) because `migrate dev` is unsafe against the live `.env` DATABASE_URL. Then `prisma generate`.
- Seed (`amril-api/prisma/seed_hardware.ts`): add CDS (category `addon`, placeholder price), standalone Thermal Printer (`addon`), and optionally a standalone KDS-screen (`addon`), alongside the existing bundle products. Idempotent upsert on `sku` like the current seed.
- Vendor catalog UI (`amril-app/hardware_catalog_page.dart`): render bundles and add-ons in separate sections ("Bundles" vs "Add-ons"). The catalog endpoint (`amril-api` `hardwareController.getCatalog`) should return `category` per product (it returns the full product row, so once the column exists it flows through — just confirm the app model `hardware_model.dart` parses `category`).
- Admin product edit screen (§2.1): add a category selector (bundle/addon) next to the tier selector.
- Batch counter note: batches are tier-based today (`HardwareBatch.tier`). Add-ons may not need MOQ batches the same way (an add-on like a printer might ship on-demand rather than group-buy). Decide with the owner whether add-ons join a batch/MOQ counter or are order-on-demand; simplest is add-ons skip the MOQ counter and are fulfilled per-order. Note this in the catalog UI (don't show a batch progress bar for add-ons if they have no batch).

### 4.3 Premium package with a BUILT-IN printer (owner's question)
The A6 setup guide + A5 printing (`amril-app` `thermal_printer_service.dart`, `printer_setup_page.dart`, `hardware_setup_guide_page.dart`) assumed a **separate Bluetooth/LAN printer**. The Premium all-in-one POS has the **printer built into the same Android device**. Handle this:
- A built-in printer is typically driven by a **vendor SDK / a different connection** (often a local service or USB/serial, not LAN/BT). Options to note for the owner:
  - Many all-in-one Android POS units (Sunmi, Telpo, etc.) expose their built-in printer via a manufacturer SDK or a standard "inner printer" service. The current LAN(socket)/BT transports won't drive it.
  - **Recommendation:** add a third `PrinterTransport.builtin` to `thermal_printer_service.dart` that targets the specific OEM's printer SDK once the factory is chosen (§Appendix of the hardware roadmap lists candidates — Telpo/Sunmi). Until the OEM is locked, leave `builtin` as a stub that shows "configured at the factory." Update the A6 guide to branch: separate-printer path (pair BT/LAN) vs all-in-one path (printer pre-configured, just log in).
- Don't over-build this before the OEM is chosen — just make the guide + service NOT assume everyone pairs an external printer.

---

## 5. TASK — Withdrawal-fee UI (finish Workstream E, app-side)

Backend is done: `GET /banks/withdrawal-fee?amount=` returns `{amount, fee, net, percent, flat}`, and `createExternalWithdrawal` already deducts the fee (sends `amount − fee` to Paystack). **The app never shows the fee.**
- File: `amril-app/lib/features/wallet/pages/withdraw_bank_screen.dart` (+ `providers/withdrawal_provider.dart`, `services/external_withdrawal_services.dart`).
- On the confirm step (before the user commits), call the preview endpoint with the entered amount and show a breakdown: **You withdraw ₦X · Fee ₦Y · Lands in your bank ₦Z**. Mirror the expandable breakdown style from `amril-app/lib/features/marketPlace/pages/merchant_balance_page.dart` (`_HoldTile` breakdown rows) for visual consistency.
- Handle the "amount too small after fee" rejection gracefully (the backend 400s it).

---

## 6. TASK — QR scanning must work on WEB (owner: big issue)

Owner: a customer on a phone browser can't scan. `amril-app` uses `mobile_scanner ^7.1.4` in `lib/features/marketPlace/pages/qr_scanner_screen.dart`.
- **Verify** whether `mobile_scanner` v7 actually initializes the camera on Flutter web (it has partial web support via `getUserMedia`, but needs HTTPS + camera-permission prompt + sometimes a JS shim). Test on the deployed web build.
- If it doesn't work on web: options to implement/note —
  - Gate the scanner behind `kIsWeb` and provide a **manual code-entry fallback** (type the table/vendor code) on web, since many desktop browsers/older phones block camera in-page anyway.
  - OR integrate a web-capable path (e.g. a `<video>` + BarcodeDetector API behind a web-only implementation file, like the `_net_image_web.dart` conditional-import pattern already used in `amril-app`).
- **Recommendation:** camera scan where supported + manual-entry fallback always. A dine-in QR usually deep-links a URL anyway (`amril.app/...`), so also make sure the QR encodes a URL that opens the right screen without needing the in-app scanner at all — that sidesteps the whole problem for the common case.

---

## 7. TASK — Admin panel: dashboard dedup, pagination, cleanup, signup

- **Overview vs Dashboard duplication:** the marketplace shell's "Overview" tab (`tabs/dashboard_tab.dart`) overlaps the app-level `features/dashboard/` screen. Decide which is canonical, merge, and delete the redundant one. Don't show the owner two dashboards.
- **Pagination sweep:** audit every list in the admin app (vendors, appeals, hardware orders, transactions, users). Anything doing a single unbounded fetch → convert to cursor/page pagination with infinite scroll or a "load more". The API endpoints mostly already paginate (reuse `buildPage`); the admin providers/services may be ignoring the cursor. Match the pattern in `amril-app`'s `OrderListProvider` / `CursorPage` for the client side.
- **Delete cruft:** remove unused/placeholder components. `lib/components/` has many generic pieces (`electric_plan_frame.dart`, `service_fraame.dart`, `wallet.dart`, `zig-za.dart`, etc.) that may be dead in an admin context. Grep for usages; delete what's unreferenced. Also the big commented-out `DioClient` block in `dio_client.dart` can go.
- **Sign-up / login screen** (`lib/screens/login.dart`): the owner says it's not good. Rebuild it to the quality of `amril-app`'s auth screens (`amril-app/lib/features/auth/login_screen.dart` / `signup_screen.dart` are the reference for layout, spacing, brand). Admin auth is Firebase + a passcode; keep the auth logic, upgrade the UI.
- **General UI uplift:** the owner wants the whole admin app to feel as polished as `amril-app`. Port spacing, typography (GoogleFonts.inter/poppins as used in app), card styles, empty/error/loading states (`amril-app` has nice `VEmptyState`/`VErrorState`/skeletons — mirror them). Don't limit yourself to the listed items; improve UI proactively where it's weak.

---

## 8. TASK — KDS status flow (owner question: "KDS has just two steps, intentional?")

In `amril-app/lib/features/marketPlace/pages/kds_screen.dart` the kitchen flow was intentionally limited to `pending → confirmed → preparing` (labels Accept → Start Preparing → Mark Ready), and orders leave the board once "Ready" (`outForDelivery`). Rationale: a kitchen screen shouldn't manage delivery/serving.
- **Confirm with the owner what they actually want.** If they want the full lifecycle visible on KDS (including out-for-delivery / served / completed), extend `_kitchenStatuses` and `_nextStatus`/`_nextLabel` maps. If the two-ish steps are fine, document it and move on.
- Related: the CDS (§4) READY column depends on this mapping — keep them consistent.

---

## 9. Screenshots (already done this session — just FYI)

`amril-app/amril-web/amril_store_screenshots.py` now generates **tablet** store assets (7" 1920×1200 + 10" 2560×1600, landscape, no Dynamic Island — webcam dot instead) in addition to phone/iOS. It reads landscape captures named `tab_kds.png`, `tab_dashboard.png`, `tab_orders.png` from `landing_page_raw_screenshots/` and skips gracefully if missing. Chrome capture instructions (custom **1280×800 @ DPR 2 landscape** → 2560×1600) are in `amril-web/AMRIL_SCREENSHOT_HANDOFF.md`. The owner will generate the tablet captures separately. Nothing to do here unless asked.

---

## 10. Suggested sequencing

1. **Admin hardware rebuild** (§2) + **config view/edit** (§3) — the owner's biggest pain, self-contained in admin_panel.
2. **Withdrawal-fee UI** (§5) + **KDS status confirm** (§8) — small app-side finishers.
3. **CDS** (§4) — new feature; do the screen first (reuse KDS listener), then branding, then the catalog/tier changes + migration, then the built-in-printer guide branch.
4. **Web QR scan** (§6).
5. **Admin cleanup/pagination/dashboard-dedup/signup/UI uplift** (§7) — the broad polish pass.

Each is independently shippable. Verify `flutter analyze` = 0 after each area, in whichever repo you touched.

---

## 11. Open questions

**RESOLVED (owner decided 2026-07-07) — build to these, do NOT re-ask:**
- **§2.2 batch-state → order-status propagation:** ✅ LOCKED = **auto-advance member orders** (producing→inProduction, shipping→shipping, fulfilling→atHub; only advance orders that are behind; closed leaves orders for manual delivered/installed). Full spec in §2.2.
- **§4.2 hardware add-on modelling:** ✅ LOCKED = **separate `HardwareCategory = bundle | addon` field**, tier stays `budget | premium`. Full spec in §4.2.

**Still open — confirm with owner while building (don't block on these; pick the noted default and flag it):**
- **§4.2 (sub)** do add-ons join a batch/MOQ counter, or ship on-demand per-order? Default: add-ons skip MOQ, fulfilled per-order (no batch progress bar).
- **§4.3** which OEM for the all-in-one (drives the built-in printer SDK) — pending factory choice; stub `PrinterTransport.builtin` until then.
- **§8** KDS: keep the current short kitchen flow (pending→confirmed→preparing) or show the full order lifecycle? Default: keep short, document it.
- **§6** does the dine-in QR already encode a deep-link URL? If yes, in-app web scanning is largely unnecessary for the main flow (the URL just opens the right screen). Verify in code before building a web scanner.
