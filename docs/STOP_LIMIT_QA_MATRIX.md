# DigiArz — Stop-Limit QA Matrix

Date: 2026-11-13  
Scope: Demo trading only. This document defines safe verification; it does not authorize live order placement.

## Safety boundary

- Never create a test order in the production project while the owner is absent.
- Never alter an existing user's wallet, asset balance, reservation, order, trade, or financial history for testing.
- Do not invoke `place_stop_limit_order`, `cancel_stop_limit_order`, or a worker against a real user's account as a test.
- Full lifecycle tests must run in an isolated Supabase test project with disposable test users and virtual balances, or inside a transaction that is proven to roll back every write.
- A successful cron invocation is only a worker-execution check; it is not proof that trigger, child Limit creation, fill synchronization, or cancellation works end to end.

## Current production observations

- Migration `20261113181827_add_stop_limit_order_engine` is applied.
- Cron jobs `digiarz-limit-orders` (job 8) and `digiarz-stop-limit-orders` (job 12) are active at one-minute intervals.
- The Stop-Limit cron history showed 78 successful invocations at the time of review.
- Current Stop-Limit parent orders, conditional orders, and active reservations were all zero at review.
- RPC grants: authenticated users can place/cancel; anon cannot; only service_role can execute the worker.
- No financial or order records were changed during this review.

## Test matrix

| Case | Setup | Expected result | Safe execution boundary |
|---|---|---|---|
| Buy trigger below Stop | Buy Stop-Limit, market below trigger | Remains pending; no child Limit | Isolated test DB |
| Buy trigger at/above Stop | Buy Stop-Limit, market reaches trigger | Exactly one child Limit at configured Limit price | Isolated test DB |
| Sell trigger above Stop | Sell Stop-Limit, market above trigger | Remains pending; no child Limit | Isolated test DB |
| Sell trigger at/below Stop | Sell Stop-Limit, market reaches trigger | Exactly one child Limit at configured Limit price | Isolated test DB |
| Invalid price relationship | Buy Limit below Stop or sell Limit above Stop | RPC rejects; no order/reservation | Negative validation only; no writes expected |
| Insufficient balance | Available balance below required reserve | RPC rejects atomically | Isolated disposable user |
| Stale/missing market price | No valid price updated within one minute | Worker skips; no trigger | Isolated test DB |
| Trigger reservation | Valid pending Stop-Limit reaches trigger | Parent reservation released and child Limit reservation created atomically | Isolated test DB |
| Child creation failure | Force child Limit RPC failure | Parent remains pending; original reservation restored; attempt recorded | Isolated test DB |
| Retry exhaustion (child creation failure) | Ten failed child Limit creation attempts with a valid reservation | Parent/conditional rejected; only a reservation whose ownership and arithmetic validate may be released atomically | Isolated test DB |
| Invalid reservation retry exhaustion | Ten missing/released/inconsistent/wrong-asset reservation validations | Parent/conditional rejected; invalid reservation is not automatically modified and requires manual reconciliation | Isolated test DB |
| Duplicate worker invocation | Two workers overlap | Advisory lock prevents overlapping processing | Isolated test DB |
| Partial child fill | Child Limit partially fills | Parent filled/remaining amounts mirror child | Isolated test DB |
| Full child fill | Child Limit fills | Parent and conditional become filled | Isolated test DB |
| Cancel before trigger | Pending Stop-Limit | Parent/conditional cancelled; reservation released once | Isolated test DB |
| Cancel after trigger | Child Limit still open/partial | Child cancelled through existing Limit RPC; parent synced; remaining reserve released | Isolated test DB |
| Account deactivation | Active pending/triggered Stop-Limit | Pending conditional and child Limit are cancelled safely | Isolated test DB |
| Unauthorized execution | anon/authenticated calls worker | Permission denied | Read-only grant inspection / isolated negative test |

## Acceptance criteria

1. At most one child Limit order exists per parent Stop-Limit order.
2. Parent and child filled/remaining amounts remain consistent after every worker cycle.
3. Every failure path is atomic: no lost reservation, double reservation, or orphan child.
4. Every cancellation releases only the unconsumed remainder, exactly once.
5. Worker ignores stale/missing prices and inactive accounts.
6. No user-facing status claims a fill before the child Limit actually fills.
7. Production test evidence contains no test orders or test reservations belonging to real users.

## Next steps

1. Prepare a separate Supabase test project and disposable authenticated users.
2. Reproduce the relevant schema, migrations, cron setup, and market-price fixtures there.
3. Run the matrix above, capturing database state before/after each case.
4. Only after all cases pass, consider a supervised production smoke test with explicit owner approval.


## Review update — 2026-11-14

### Read-only verification performed
- [x] Re-read the current `main` tree and the latest commit before this review: `152d87efd75860e4c0abe4a9ce216c7427db87ee` (defer external libraries and start after DOMContentLoaded).
- [x] Supabase project discovery returned only the production project `DigiArz` (`gfoaubfilhttnwjykaox`); no isolated test project is currently available to this connection.
- [x] Production cron job `digiarz-stop-limit-orders` (job 12) is active with schedule `* * * * *`. The five most recent recorded invocations were `succeeded`; this proves the scheduled function was invoked, not that any order lifecycle passed.
- [x] Aggregate production state at review time: no Stop-Limit conditional rows, no conditional parent orders, and zero active Stop-Limit reservations.
- [x] Live function grants/settings were inspected: place/cancel are executable by `authenticated` and not `anon`; worker is executable by `service_role` only. All three are SECURITY DEFINER with an empty search_path.
- [x] Front-end static checks: all three inline scripts parse; 190 HTML IDs are unique; the Stop-Limit form, place/cancel RPC calls, and open-order loader are wired.
- [x] No production order, trade, wallet, balance, reservation, or financial-history row was inserted or modified.

### UI safety correction
- [x] The pending Stop-Limit card previously stated that assets were reserved without reading the reservation row.
- [x] `index.html` now reads the user's own reservation for pending Stop-Limit orders and validates its status and arithmetic.
- [x] The UI now shows the remaining reserved amount and asset only when a valid active reservation is found; query failure, missing reservation, released status, or inconsistent amounts are shown as an unverified/invalid reservation instead of claiming funds are reserved.
- [x] Change committed as `6445729024dd2437cbc96b136c630fcdedc1fa69`.

### Newly identified backend QA gap
- [ ] In `process_stop_limit_orders()`, the reservation-validation failure branch increments `attempt_count` and records `last_error`, then skips the order. Unlike the child-creation exception branch, it does not apply the ten-attempt terminal transition. A pending order with a missing, released, or inconsistent reservation can therefore remain pending and be retried indefinitely.
- [ ] Define a fail-closed recovery policy for this branch. Do not automatically release an invalid reservation unless its ownership and arithmetic are independently validated; expose the reason for operator review and ensure the parent/conditional state cannot imply that execution is progressing normally.
- [ ] Add a concurrency test for cancellation racing with the trigger worker; verify exactly one child order and one reservation transition.
- [ ] Add a deactivation-after-trigger test with a pending or partially filled child Limit; verify child cancellation, remaining reservation release, and parent/conditional synchronization.

### Added/clarified QA cases
| Case | Setup | Expected result | Safe execution boundary |
|---|---|---|---|
| Missing/released reservation | Pending Stop-Limit with no valid active reservation | Worker creates no child; UI does not claim assets are reserved; operator-visible reason | Isolated test DB |
| Inconsistent reservation arithmetic | Pending Stop-Limit with negative or over-consumed/released amounts | Fail closed; no child or duplicate release; recovery policy is explicit | Isolated test DB |
| Reservation validation retry exhaustion | Repeat the invalid-reservation condition | A bounded, observable terminal/recovery path; never an invisible infinite pending loop | Isolated test DB |
| Cancel/trigger race | User cancellation overlaps worker trigger | Exactly one valid outcome; no orphan child or double release | Isolated test DB |
| Deactivate after trigger | Child Limit is pending or partially filled when account is deactivated | Child Limit is cancelled, its remaining reservation released once, and parent/conditional state mirrors child | Isolated test DB |

### Remaining blocker
Full lifecycle testing remains blocked until an isolated Supabase test project with disposable users and balances is provisioned. The production project was used only for SELECT/read-only inspection in this review. Cron success is not being reported as Stop-Limit end-to-end QA success.


### Reservation read path — production verification update (2026-11-15)

- [x] Direct table SELECT remains intentionally unavailable to `authenticated` and `anon`; do not grant broad table access merely to support the UI.
- [x] The repository migration `supabase/migrations/20261114143035_get_my_order_reservations_rpc.sql` is present and the matching migration is recorded as applied in the production project.
- [x] Read-only inspection of the live function confirmed `public.get_my_order_reservations(uuid[])` is `STABLE SECURITY DEFINER`, has an empty `search_path`, filters every row by `r.user_id = auth.uid()`, returns only order/reservation display fields, and rejects null/empty or more than 100 order IDs.
- [x] Live privilege inspection confirmed EXECUTE is granted to `authenticated`, not to `anon`; no direct SELECT grant was added to the reservation table.
- [x] The Limit, Stop-Limit, and conditional-order UI paths call the owner-scoped RPC rather than reading the reservation table directly.
- [x] A further client-side boundary mismatch was found in `loadQuickTradeReservations()`: it can collect up to 500 order IDs plus 500 conditional order IDs, while the RPC accepts at most 100 IDs per call.
- [x] Added `getMyOrderReservations()` to split unique IDs into sequential batches of at most 100 and aggregate the read-only results. Code commit: `2efce841a5abb12b86d202104363be16e606a6ed`.
- [x] Static verification after the change: all 3 inline scripts parse, all 208 HTML IDs are unique, and a mocked 250-ID test produced RPC batch sizes `100, 100, 50` and 250 aggregated rows. The mock did not call production Supabase.
- [ ] The full reservation lifecycle and worker interaction still require the isolated test project described above. The RPC's owner filter and grants were inspected read-only in production; no production order, reservation, wallet, balance, or financial-history row was created or changed.


## Backend retry-safety correction — 2026-11-15

- [x] Reproduced the previously identified gap by inspecting the live `process_stop_limit_orders()` definition: invalid/missing/released/inconsistent reservation validation incremented `attempt_count` but did not terminate the parent order after repeated failures.
- [x] Applied migration `20261115153000_bound_stop_limit_invalid_reservation_retries` to production and committed the matching SQL file.
- [x] After ten reservation-validation failures, the worker now marks the parent order and conditional row `rejected`, records `Reservation validation failed; manual review required`, and stops retrying.
- [x] Fail-closed policy: the worker deliberately does **not** release or modify an invalid reservation. Any potentially stuck reservation requires manual reconciliation of ownership and arithmetic before recovery.
- [x] Re-read the live function after migration and confirmed the bounded retry branch is present.
- [x] Read-only aggregate check confirmed there are currently zero Stop-Limit conditional rows, zero conditional parent orders, and zero active conditional reservations. No order, reservation, wallet, balance, trade, or financial-history row was created or changed.
- [ ] Full lifecycle, cancellation/trigger race, and deactivation-after-trigger tests remain blocked until an isolated test project with disposable users is available. This correction does not constitute end-to-end QA.


## Cancellation and permission review — 2026-11-15

### Read-only inspection
- [x] `cancel_stop_limit_order(uuid)` derives the caller from `auth.uid()` and filters the conditional and parent order by that user ID.
- [x] The cancellation RPC locks the conditional row and parent order before deciding whether the order is pending or triggered.
- [x] Pending cancellation validates the active reservation arithmetic, releases only `reserved_amount - consumed_amount`, then changes parent and conditional states in the same transaction.
- [x] Triggered cancellation verifies the child belongs to the same user and is a Limit order, delegates open/partially-filled child cancellation to `cancel_limit_order`, then synchronizes parent/conditional status and fill quantities.
- [x] Live privilege inspection: `place_stop_limit_order` and `cancel_stop_limit_order` are executable by `authenticated`, not `anon`; `process_stop_limit_orders` is executable by `service_role` only.
- [x] Front-end Stop-Limit placement calls the authenticated RPC; the active-order list is user-scoped and offers cancellation for pending and triggered orders.
- [ ] Cancellation-versus-trigger concurrency and partial-fill cancellation still require isolated end-to-end tests. Static function review is not proof of race-free behavior.


## Limit engine integration review — 2026-11-15

### Read-only checks
- [x] `place_limit_order` derives the user from `auth.uid()`, rejects inactive accounts, validates the enabled USDT pair, locks the wallet, accounts for existing active reservations, and inserts the order and reservation in one transaction.
- [x] `process_limit_orders` uses a transaction-scoped advisory lock and `FOR UPDATE SKIP LOCKED` to prevent overlapping workers from processing the same order.
- [x] The processor requires a fresh positive market price (at most 60 seconds old), enforces the side-specific limit-price condition, and validates reservation owner/status/arithmetic and expected reserve asset before applying a fill.
- [x] Partial fills are capped at 25% of the original order amount per processing pass; wallet/asset balances, order fill totals, reservation consumption/release, trade and transaction records are updated transactionally.
- [x] `cancel_limit_order` locks the user-owned order, permits only pending/partially-filled Limit orders, requires exactly one valid active reservation, and updates order cancellation and reservation release atomically.
- [x] Unique indexes enforce one reservation per order and one conditional order per parent order.
- [x] Stop-Limit child creation calls the same `place_limit_order` engine inside the trigger transaction after releasing the parent reservation; the child order therefore follows the ordinary Limit execution path.
- [ ] Production transaction tests remain intentionally unrun. Fill, partial-fill, cancel-vs-worker concurrency, and child/parent state reconciliation require an isolated test database and test-only balances.

### Scope note
This review is static/read-only. It does not certify matching-engine economics, race behavior under load, or full transaction correctness; those remain explicit QA items.


## Wallet, asset-balance and reservation consistency snapshot — 2026-11-15

### Read-only production snapshot
- [x] Checked for negative USDT/IRR wallet balances and negative asset balances: zero findings.
- [x] Checked reservation arithmetic for negative values or consumed + released exceeding reserved: zero findings.
- [x] Checked active orders for missing/duplicate reservations, invalid active reservation state, and amount = filled + remaining mismatches: zero findings.
- [x] Checked terminal orders retaining an active reservation: zero findings.
- [x] Checked trades with missing orders or user ownership mismatch: zero findings.
- [x] Checked conditional parent/child links for missing rows or user ownership mismatch: zero findings.
- [x] Production row counts at inspection: 3 orders (all `market:filled`), 0 order reservations, 3 trades, 3 transactions, 1 wallet, 1 asset-balance row, 0 conditional orders.
- [ ] Important limitation: there are currently no Limit or Stop-Limit orders and no reservation rows in production. Therefore the reservation and Limit lifecycle checks are structurally clean but do not exercise those paths; they are not evidence of successful Limit/Stop-Limit fills, partial fills, or cancellation.
- [x] No production row was inserted, updated, or deleted during this review.

### Next QA requirement
Run the complete reserve/fill/partial-fill/cancel and Stop-Limit parent-child lifecycle against an isolated test database with disposable users and balances. Do not create test orders or alter balances in production.


## Market execution engine review — 2026-11-15

### Read-only findings
- [x] `execute_demo_trade` requires `auth.uid()`, an active account, a syntactically valid symbol, positive bounded amount, and an enabled USDT pair.
- [x] The function reads the authoritative server-side market price and rejects missing, non-positive, or older-than-60-second prices. The client-supplied `p_price` is not trusted for settlement.
- [x] The function locks the user's wallet before balance mutations; it includes outstanding reservations in available-balance calculations for both USDT buys and base-asset sells.
- [x] Buy/sell settlement, fee calculation, order, trade, and transaction history writes occur in the same database transaction.
- [x] Function privilege check: `anon` cannot execute; `authenticated` can execute. The function itself still requires a real authenticated UID and active account.
- [x] Current enabled-pair snapshot: 12 pairs; every current price rounds to a positive value at the current 8-decimal trade/order price precision.
- [x] Existing production Market rows (3) were checked: each order amount and price exactly matches its linked trade; each has a corresponding USDT transaction of the expected side. No discrepancy was found.
- [x] No production data was changed.

### Precision issue to resolve before widening asset coverage
- [!] `execute_demo_trade` accepts arbitrary numeric `p_amount`, calculates gross/fees from that original value, but persists order/trade/asset balance amounts in columns with scale 8. An amount with more than 8 decimal places can therefore be rounded when stored after settlement was calculated from the unrounded input. The same class of mismatch needs to be checked across Limit and conditional placement functions.
- [!] `market_prices.price` supports 18 decimal places, while `orders.price` and `trades.price` are scale 8. This is harmless for the current 12 enabled pairs (all 12 round to positive values at 8 decimals), but future micro-price pairs could be recorded at a rounded or zero trade price even while settlement uses the higher-precision market price.
- [ ] Before enabling additional pairs or accepting higher-precision quantity inputs, align order/trade price and amount precision with market and asset requirements, or explicitly validate/reject unsupported precision at the server boundary. Do not silently round user inputs.
- [ ] Isolated end-to-end tests are still required for insufficient balance under concurrent requests, fee accounting, buy/sell round trips, and order/history atomicity.

### Scope
Static inspection and read-only aggregate checks only. No test trade, balance change, or order was performed on production.


## Cross-engine numeric precision review — 2026-11-15

### Confirmed storage precision
- `market_prices.price`: numeric(38,18).
- `orders.amount`, `orders.price`: numeric(24,8).
- `trades.amount`, `trades.price`: numeric(24,8).
- `asset_balances.balance`: numeric(28,8).
- `wallets.balance_usdt` and `transactions.amount`: numeric(24,8).
- `orders.filled_amount`, `orders.remaining_amount`, `conditional_orders` numeric fields and reservation amount fields are unconstrained numeric.

### Additional confirmed issues
- `process_limit_orders()` fills at most 25% of the original amount per cycle. Example: amount 0.12345678 produces an exact first fill of 0.0308641950, but a numeric(24,8) trade amount stores 0.03086420 (delta +0.0000000050). The engine increments the order's unconstrained filled_amount using the exact quantity, while trade and asset balance columns round to 8 places. This can create a ledger/history mismatch and a small balance drift.
- `process_limit_orders()` computes quote gross, fee and net without explicit 8-place rounding, then writes wallet and transaction amounts to numeric(24,8) while reservation consumed_amount remains unconstrained numeric. Explicit settlement rounding is needed so wallet debit/credit, transaction ledger and reservation consumption use the same USDT amount.
- `execute_demo_trade()` rounds gross and fee to 8 places, but the amount is accepted at arbitrary numeric precision while order/trade/asset balance columns are scale 8. Validate or support greater base-asset precision consistently.
- `place_limit_order()`, `place_stop_limit_order()`, and `place_conditional_exit_order()` accept numeric amount/price values without enforcing a storage precision policy. The first two store order values in scale-8 columns; conditional metadata uses unconstrained numeric fields.
- Market prices can carry 18 decimal places but the order/trade price columns retain only 8. Current enabled pairs happen to round to positive 8-place prices; this is not a safe general rule for future micro-price pairs.

### Scope checked
- Reviewed definitions of Market execution, Limit placement/processing/cancellation, Stop-Limit placement/processing/cancellation, and conditional exit placement.
- Production currently has 0 active Limit orders and 0 active conditional orders. No live partial-fill sample exists to validate the lifecycle.
- No production data was changed and no simulated trade was executed.

### Recommended coordinated fix (not yet applied)
1. Widen base-asset quantity storage to 18 places in `orders.amount`, `orders.filled_amount`, `orders.remaining_amount`, `trades.amount`, and `asset_balances.balance`; widen `orders.price` and `trades.price` to 18 places to preserve the 18-place market price.
2. Keep USDT wallet and transaction settlement at 8 places for now, but explicitly round Limit gross/fee/net/consumed quote amounts to 8 places before mutating wallet, transaction, or reservation ledger. Keep Market's existing 8-place quote settlement semantics consistent.
3. Add consistent server-side input range/precision validation for Market, Limit, Stop-Limit, and conditional-exit RPCs after the storage policy is agreed.
4. Add isolated test coverage for repeated 25% partial fills, very small asset quantities/prices, buy/sell settlement, and reservation reconciliation before applying schema changes to production.
5. Review all dependent functions, UI formatters, exports and constraints before generating/applying the migration. This recommendation is not an authorization to change production schema.


## Frontend precision dependency review — 2026-11-15

### Confirmed UI dependencies
- The four order-entry flows (Market, Limit, Stop-Limit, conditional exit) currently convert numeric input strings with JavaScript `Number(...)` before sending Supabase RPC arguments. This conversion is not safe for arbitrary 18-decimal quantities/prices and may lose decimal precision before PostgreSQL receives the value.
- `formatNum()` converts all values through JavaScript `Number`; increasing database scale alone would not preserve/display 18-place values exactly.
- Quick-trade estimate and available-balance precheck also use JavaScript Number arithmetic. These are client-side convenience checks only; server validation remains authoritative, but the UI can show a rounded estimate.
- Order book display currently formats prices at 8 decimals; recent public-market trades use 10 decimals. These are not aligned with the 18-place market-price storage.
- Open-order, conditional-order, Stop-Limit and order-history panels request and display values with up to 10 fractional digits, so they will need a consistent exact-decimal display policy if the schema is widened to 18.

### Required coordinated frontend changes before enabling 18-place input
1. Preserve raw input strings for amount and price RPC arguments; validate decimal syntax, maximum integer digits, and maximum fractional digits without converting the submitted value to Number.
2. Use an exact-decimal strategy for client-side estimates and formatting (or explicitly label estimates as approximate); do not use binary floating-point for authoritative settlement.
3. Update order-book and order-history formatters to display meaningful precision without truncating micro-prices or quantities.
4. Keep the server-side PostgreSQL functions authoritative for balance, reservation, fee and settlement arithmetic.
5. Test representative micro-price symbols and 18-decimal amounts in an isolated environment, including Android browser input behavior.

### Dependency conclusion
The database widening migration must not be applied alone. The UI's Number conversions and formatters are direct dependencies. Production schema remains unchanged; this is a dependency assessment only.


## Production schema dependency inventory — 2026-11-15

Read-only inventory of Production PostgreSQL dependencies for `orders`, `trades`, `asset_balances`, and `order_reservations`:

### Indexes and constraints
- No index on these four tables currently keys or includes the numeric amount/price/balance columns. Existing indexes cover primary/unique identifiers, user/asset, reservation status, order creation time, and trade order/time access paths.
- `orders` has accounting invariants `filled_amount + remaining_amount = amount`, filled/remaining range checks, positive amount, and positive-or-null price. These checks must remain valid at the higher scale; the equality check is especially relevant to partial-fill rounding.
- `asset_balances.balance` has a nonnegative check; `trades.amount` and `trades.price` have positive checks.
- Reservation accounting checks enforce nonnegative consumed/released amounts and `consumed_amount + released_amount <= reserved_amount`.

### Foreign keys, triggers, policies
- Tables referencing `orders` by foreign key are `conditional_orders` (parent and execution order IDs), `order_reservations` (order/user pair), and `trades` (order ID). These foreign keys reference identifiers, not the numeric precision columns.
- Existing non-internal triggers on the target tables are account-guard triggers on `orders` and `trades`; none were found on `asset_balances` or `order_reservations`.
- Existing RLS policies on the four tables are user/account-scoped and do not reference the numeric columns.
- The catalog dependency query found no view rewrite dependency on these four target relations. No generated numeric columns were identified in the inspected column inventory.

### Migration implications
- Widening numeric typmods does not require dropping the listed identifier foreign keys or current indexes based on the inspected definitions; however, PostgreSQL may still take strong table locks and rewrite/rebuild storage/index structures for type changes. Migration timing, lock duration, table size, and rollback cost must be assessed before any Production DDL.
- Do not weaken or remove accounting constraints. The migration and engine changes must preserve exact order accounting and reservation reconciliation.
- This inventory is not a complete substitute for isolated migration rehearsal. Function bodies, RPC return JSON contracts, edge functions, export/report consumers, and all UI call sites still require a final cross-reference review.

Production schema was not changed. No orders, balances, reservations, or transactions were created or modified.


## Limit engine exact-decimal execution path — 2026-11-15

The current Production `process_limit_orders()` definition was read directly (read-only). It confirms the precision mismatch occurs in the settlement path, not only at column storage:
- `v_qty := LEAST(v_remaining, v_order.amount * 0.25)` retains an exact numeric quarter-fill. There is no explicit quantization at the engine boundary.
- The same `v_qty` updates `orders.filled_amount`, `orders.remaining_amount`, the asset balance, reservation consumption (for sells), and `trades.amount`. The latter two destination table columns currently have 8 decimal places for asset quantity, so they can round while the order accounting retains the higher-precision quantity.
- Buy-side quote `v_total = gross + fee` and sell-side `v_net = gross - fee` currently have no explicit 8-decimal rounding before wallet/transaction writes. Reservation `consumed_amount` is updated from the same unrounded `v_total`; this can diverge from the amount actually stored in the 8-decimal wallet/transaction columns.
- The remaining buy reservation target is recalculated as `v_new_remaining * v_order.price * (1 + fee_rate)` without an explicit quote-currency 8-decimal rounding policy.

### Required engine behavior after the precision migration
1. Base-asset quantity and execution price must remain at the agreed 18-decimal scale across order, trade, and asset-balance records.
2. Quote-currency settlement must be quantized once, explicitly, to 8 decimals; the exact same quantized quote amount must feed wallet delta, transaction amount, reservation consumption, and remaining-reserve arithmetic.
3. Partial fills must preserve `filled_amount + remaining_amount = amount` exactly at the storage scale, including the final residual fill. Do not round each quarter-fill independently in a way that accumulates or creates dust.
4. Apply the same policy consistently to Market, Limit, Stop-Limit child Limit orders, and conditional exits; validate the raw decimal string at the RPC boundary before any lossy conversion.
5. Before deployment, test repeated partial fills, final dust/residual fills, buy/sell fee settlement, reservation release, cancellation, and trigger-to-child-order handoff using isolated fixtures only.

No Production function or data was changed by this review.


## Exact-decimal frontend follow-up — 2026-11-15

- [x] The browser now has a shared BigInt decimal-string utility at \`src/decimal.js\`.
- [x] Market, Limit, Stop-Limit, and conditional-exit RPC arguments are sent as canonical decimal strings. The four order-entry functions no longer convert submitted amount/price values through JavaScript Number, parseFloat, or toFixed.
- [x] Reservation remaining amounts and Limit/Stop/conditional trigger comparisons in the order panels use exact decimal arithmetic.
- [x] The utility supports 18 fractional digits; unit tests pass locally.
- [x] The utility is part of the PWA shell cache (v47).
- [!] The live browser input cap remains 8 fractional digits because Production order/trade/balance columns are still scale 8. Do not remove this guard until schema and RPC migrations have passed isolated tests and are approved for rollout.
- [ ] Backend exact-decimal migrations, shared 8-place USDT quantization, repeated partial-fill/final-residual tests, and concurrency tests remain blocked by the absence of an isolated database.
- [ ] Inline-script syntax/flow tests are committed in GitHub Actions, but no completed workflow result was confirmed at this checkpoint.

See \`docs/superpowers/reports/2026-11-15-exact-decimal-implementation-checkpoint.md\` for the full implementation status and release gate.


## Review update — 2026-11-17 (main CI and PWA cache boundary)

### Main-branch isolated QA
- [x] Re-read the current main branch HEAD: `bfc6d9b30bc9e109daf7df2a35b0d0efc33cec5c`.
- [x] Exact-decimal workflow run `44068551988` completed with `success` on this main commit. The disposable PostgreSQL 17 job passed the Market/Limit entrypoints, Stop-Limit and TP/SL placement, Limit cancellation, two-session Limit/Stop-Limit/TP-SL cancellation races, and parent-child lifecycle integration.
- [x] The same workflow's Node/browser test step passed, including seven new Service Worker/PWA tests.
- [x] GitHub Pages run `44068551980` completed with `success`.
- [x] Android APK workflow run `44068495018` completed with `success` on code commit `348ebd4a222401023549a3cb484806b1e772db65`; artifact `DigiArz-Android-debug-APK` (ID `14320943624`) was produced. This build contains the Service Worker v54 change; the subsequent main commit only added tests.
- [!] These are disposable PostgreSQL CI tests, not a dedicated Supabase development branch. Supabase branch discovery returned no development branches. Production compatibility and a physical Android install/offline check remain separate gates.

### PWA offline-cache hardening
- [x] Review found Service Worker v53 cached every successful same-origin GET response at runtime, beyond the declared app shell. Although current Supabase calls use a different origin and bypassed the worker, this broad rule could cache future same-origin user-specific/API responses.
- [x] Service Worker v54 now pre-caches only the declared app shell, including both manifest icons (`icon-192.svg`, `icon-512.svg`); successful root/index navigation refreshes only the canonical `index.html` cache entry.
- [x] Unlisted same-origin GET requests are fetched but are not written to Cache Storage. External Supabase/API and non-GET requests remain outside the cache path.
- [x] Added `tests/service-worker.test.js` with seven tests for Persian RTL standalone manifest metadata, app-shell installation, icon precaching, external/non-GET bypass, no caching of unlisted same-origin responses, navigation refresh, offline fallback, and old-cache cleanup.
- [x] Local Node 22 test run: 7/7 passed. Main GitHub Actions run `44068551988` also passed the complete `node --test tests/*.test.js` step.
- [!] Physical Android Chrome install, offline launch, and icon rendering have not yet been manually verified.

### Supabase read-only status
- [x] Project `gfoaubfilhttnwjykaox` reports `ACTIVE_HEALTHY` on PostgreSQL 17.11.
- [x] Supabase development branch listing returned an empty list; no isolated Supabase branch is currently available to this connection.
- [!] Follow-up read-only SQL/table-list calls timed out. No current row-count or live function-body claim is made from those failed calls.
- [x] No Production SQL, migration, function, grant, cron, order, trade, reservation, wallet, balance, or financial-history row was changed in this review.

## PWA Android install affordance — 2026-11-17

- [x] Added a browser-native install affordance to the Persian RTL UI. The banner remains hidden unless the browser dispatches beforeinstallprompt; it does not claim the app is installable on browsers that do not expose that event.
- [x] The install action consumes the deferred prompt once, disables the button while the prompt is active, hides the banner after the user choice, and also hides it after appinstalled.
- [x] The controller is loaded as a deferred first-party script and added to the explicit offline app shell. Service Worker cache advanced from v54 to v55 so existing clients replace the previous shell.
- [x] Added five isolated Node tests for prompt availability, one-shot prompt use, app-installed handling, and dismissed/failed prompt handling.
- [x] Updated Service Worker tests to assert that src/pwa-install.js is precached and both older shell caches are removed.
- [x] Local Node 22 verification: node --test tests/*.test.js passed 12/12 tests (5 install-controller tests + 7 Service Worker tests).
- [!] GitHub Actions result for the new commits was not available through the connected workflow-run reader during this execution; do not mark CI as passed until a run for the new HEAD is independently confirmed.
- [!] Physical Android Chrome install prompt and APK installation have not been exercised on a device. The native prompt is browser-dependent; if beforeinstallprompt is not emitted, the banner intentionally remains hidden.
- [x] No Supabase schema, functions, permissions, migrations, financial records, or user balances were changed.

### Files and commits
- src/pwa-install.js — 23359ab6cbe54fdcdd5dfc22766cf54c54ea677c
- index.html — 68e9c6d86a2a7c7f57e70fd9655e34560b16d29a
- sw.js — 05197c1ae2f955e3aa1d53d570513022e80c338a
- tests/service-worker.test.js — 3f9358fbb07fb57621c1774a0187581d933bc6d1
- tests/pwa-install.test.js — b7ad171c2f1a038d21040bfe63043deb140533b2

- [x] Added a separate failure-path test proving a rejected native prompt is caught, the one-shot event is not reused, and the banner closes.

### Next QA
1. Confirm a new main-branch GitHub Actions run for the install-controller commits and verify the APK build includes the new controller.
2. Install the APK or PWA on Android Chrome and verify banner visibility, native prompt, standalone launch, and offline shell behavior.
3. Keep Supabase Production untouched; retry read-only catalog and function inspection only after the database connection is stable.

## وضعیت تازهٔ QA و مرز Production — ۲۰ نوامبر ۲۰۲۶

### آخرین آزمون‌های ایزوله ثبت‌شده
- [x] آخرین نتیجهٔ کامل Stop-Limit/TP-SL در تاریخ ۱۹ نوامبر از CI بازیابی شد: workflow run `44594127811` (Run #914) روی commit کد `577da09fb157307440c85a08b1f55308bb262e84` با نتیجهٔ `success`.
- [x] طبق گزارش اجرایی همان run، آزمون‌های browser integration و exact-decimal، PostgreSQL arithmetic، preflight نامعتبر و atomicity، lock timeout و rollback، ورود Market/Limit، ثبت Stop-Limit و TP/SL، لغو سفارش و رقابت دو نشست مستقل برای Limit/Stop-Limit/TP-SL موفق بودند.
- [x] اصلاح matcherهای آزمون صفحه ورود نیز در همان CI سبز شد؛ این بخش به منطق مالی تغییری نداد.
- [!] این اجرا روی PostgreSQL 17 دورریختنی در CI انجام شده است؛ معادل Development Branch مستقل Supabase نیست و به‌تنهایی رفتار Production را اثبات نمی‌کند.

### Snapshot تازهٔ Supabase در ۲۰ نوامبر
- [x] پروژه `gfoaubfilhttnwjykaox` در وضعیت `ACTIVE_HEALTHY` و PostgreSQL `17.11.0.018` است.
- [x] شمارش خواندنی جداول مالی: `orders=0`, `trades=0`, `transactions=0`, `asset_balances=0`, `order_reservations=0`, `conditional_orders=0`.
- [x] فهرست Development Branchها خالی است؛ بنابراین محیط ایزولهٔ Supabase برای آزمون انتهابه‌انتها در دسترس نیست.
- [!] صفر بودن ردیف‌ها به معنی عبور چرخه مالی از آزمون واقعی نیست. هیچ سفارش یا موجودی ساختگی در Production ایجاد نشد و هیچ Worker/RPC مالی برای تست روی کاربران واقعی اجرا نشد.

### دروازه‌های باز
1. تهیه/فعال‌سازی Development Branch یا پروژه Supabase جداگانه با کاربران و موجودی دورریختنی؛ هزینه و ایجاد محیط باید طبق تأیید/فرایند Supabase انجام شود.
2. اجرای چرخه کامل parent Stop-Limit → child Limit شامل trigger، رزرو، اجرای جزئی/کامل، لغو، آزادسازی رزرو، idempotency و race لغو/پردازش.
3. تطبیق نتیجهٔ هر مرحله با دفترکل USDT و مقدار دقیق دارایی پایه؛ quantization تسویه USDT باید ۸ رقم و مقدار/قیمت پایه مطابق قرارداد precision باشد.
4. نگه‌داشتن Production بدون تغییر تا تکمیل آزمون ایزوله و بازبینی نهایی grants/RLS و برنامهٔ rollback.

این به‌روزرسانی فقط مستندسازی نتیجهٔ CI و وضعیت خواندنی Production است؛ هیچ آزمون مالی روی Supabase Production اجرا نشده است.

## Main CI verification — 2026-11-21

- [x] Exact-decimal workflow Run #1454 (44895814215) completed with success on main HEAD 31ebb934b55d7c3610950081df0ed4483de2e672.
- [x] Node/browser regression step passed, including the new final auth palette test (Binance-inspired black/yellow), preservation of email/password-only signup, login/recovery controls, and existing responsive layout.
- [x] PostgreSQL 17 disposable CI passed arithmetic, schema-widening preflight, lock-timeout and atomic rollback checks.
- [x] Market/Limit entrypoints, combined exact-decimal candidate, per-fill USDT reservation rounding, Stop-Limit/TP-SL placement, Limit worker, Limit cancellation, two-session Limit/TP-SL/Stop-Limit cancellation races, and parent-child/conditional lifecycle tests all passed.
- [!] This is an isolated GitHub Actions PostgreSQL service, not the production Supabase database or a dedicated Supabase Development Branch. Workflow tests use the repository's draft candidate SQL; they do not prove full Production migration/ACL parity.
- [x] Production Supabase was not used for any test. No orders, trades, reservations, wallets, balances, migrations, grants, policies, cron jobs, or financial RPCs were changed.
- [ ] Still required: a fresh schema-only PostgreSQL 17 harness with exact Production DDL/ACL parity, then source-faithful Stop-Limit tests. Supabase project currently has no Development Branch; the separate Recovery-Test project contains backup data and is not a disposable financial test database.