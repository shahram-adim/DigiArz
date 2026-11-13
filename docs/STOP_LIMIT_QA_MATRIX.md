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
