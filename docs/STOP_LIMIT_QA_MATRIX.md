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
| Retry exhaustion | Ten failed trigger attempts | Parent/conditional rejected and remaining reservation released | Isolated test DB |
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


### Additional access-control finding — reservation read path
- [x] The RLS policy `Users can view own order reservations` exists for `authenticated` with predicate `auth.uid() = user_id`.
- [x] The table ACL does not grant SELECT to `authenticated` or `anon`; `relacl` contains only `postgres` and `service_role`, and `has_table_privilege('authenticated', 'public.order_reservations', 'SELECT')` is false.
- [x] Therefore the RLS policy alone does not make the browser query readable. The current Limit and Stop-Limit UI must show an unverified-reservation message rather than infer a reservation.
- [ ] Do not solve this by granting broad direct table access without review. Preferred design: an owner-scoped SECURITY DEFINER read RPC that returns only order_id, asset, reserved_amount, consumed_amount, released_amount, and status for `auth.uid()`, with empty search_path and authenticated-only EXECUTE. This requires an isolated test and a separately reviewed migration before production application.
