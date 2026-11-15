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
