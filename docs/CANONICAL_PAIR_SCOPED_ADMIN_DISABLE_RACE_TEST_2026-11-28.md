# Disposable pair-scoped admin-disable and worker-race regression — 2026-11-28

**Status:** isolated candidate fixture and CI wiring only. Not Production code and not evidence of current Production behavior.

## What was added

- `supabase/tests/canonical_pair_scoped_admin_disable_race.sql`
  - Creates an isolated `canonical_pair_disable` schema.
  - Models immutable `pair_id` separately from non-unique `display_pair`.
  - Uses pair-scoped admin cancellation and reservation release.
  - Uses a shared pair-row-first lock order for the worker and admin operation.
  - Seeds two different pair IDs with the same display symbol.
  - Asserts disabling one pair cancels only its pending/partial orders, releases only its reservations, and leaves the sibling pair, orders, conditional state, and reservations unchanged.
- `supabase/tests/canonical_pair_scoped_admin_disable_race.sh`
  - Runs real two-session PostgreSQL interleavings.
  - Worker-first: an in-flight fill completes before admin disable; the completed fill and consumed reservation remain intact.
  - Admin-first: the worker waits for the pair lock, then observes the disabled pair and does not execute the cancelled order.
  - In both cases, the same-symbol sibling pair remains enabled with its order and reservation unchanged.
- `.github/workflows/exact-decimal-tests.yml`
  - Adds a disposable PostgreSQL 17 workflow step to create a fresh test database, load the fixture, and run the two-session race script.

## Locking contract exercised

Both admin disable and execution worker lock the exact pair row before locking or mutating its orders. This provides a single serialization point for pair disable versus execution. A future production design must review all workers, placement paths, cancellation paths, and admin paths for a consistent lock order; this fixture does not prove that every deployed production worker currently follows it.

## Expected regression matrix

| Scenario | Target pair | Same-symbol sibling |
|---|---|---|
| Admin disable, no race | pair disabled; open orders cancelled; remaining reservation released | enabled; orders/reservations unchanged |
| Worker obtains pair lock first | fill completes; reservation becomes consumed; later disable does not rewrite completed order | enabled; unchanged |
| Admin obtains pair lock first | pair disabled; open order cancelled; reservation released; waiting worker refuses execution | enabled; unchanged |

Reservation release preserves cumulative accounting: for the seeded partially consumed reservation, released amount is reserved minus consumed, not the full reserved amount.

## Evidence and limits

- The existing historical Production snapshot of `admin_disable_market_pair` was the source of the ticker-scoped cleanup finding; it selects a pair by provider identity but cancels/releases through `orders.symbol = pair_symbol`.
- The new SQL is an intentionally small behavioral model. It does not import or patch the historical Production function and does not claim to prove the full application schema, RLS, grants, trigger behavior, wallet settlement, all cancellation RPCs, or deployed Cron/Edge Function behavior.
- No local PostgreSQL server/client or Docker runtime was available in this work session, so the SQL and two-session race have **not** been executed here. CI must run on the exact resulting commit before the fixture can be marked passing.
- Even a passing fixture proves only this candidate model. A separate full disposable fixture must reproduce the authoritative Production schema and function call chain before any production implementation proposal.

## Safety

No Production SQL/query, DDL, migration, backfill, RPC/Worker/Cron/Edge Function change, user/financial row change, RLS/ACL change, merge, rebase, db push, deployment, APK/Pages publication, or paid service action was performed.


## Follow-up schema hardening — Shahram 214

The fixture was tightened after static review:

- `orders` now has a unique composite key on `(order_id, pair_id)`.
- `conditional_orders` and `reservations` use composite foreign keys to the same order/pair tuple, preventing a row from accidentally attaching a valid order ID to a different pair ID.
- Reservation checks enforce nonnegative consumption/release and prevent consumed plus released amounts from exceeding the reserved amount.
- These constraints make the test data model itself reject cross-pair attribution, rather than relying only on procedural WHERE clauses.

The updated SQL was inspected from the committed branch. It has still not been executed locally or in CI; no pass is claimed.
