# Captured Production admin-disable source parity — 2026-11-28

## Scope

This is a disposable PostgreSQL regression that executes the exact captured
Production function body from
`supabase/tests/canonical_identity_live_admin_disable_market_pair_snapshot.sql`
(captured 2026-11-27; function-definition MD5
`07ff2862b133f6dbeb3c0cf5d33c5878`).

It does not call or modify Supabase Production. The snapshot is test input only,
not a migration or deployable artifact.

## Finding reproduced

The captured `public.admin_disable_market_pair(text,text)` resolves the target
pair by `base_coingecko_id` and locks that row, but its cleanup predicates use
`orders.symbol = v_pair.pair_symbol`. The final pair update also uses
`pair_symbol`. Therefore, if two canonical pairs share a display symbol in a
future duplicate-ticker-capable schema, the captured function body can cancel
both pairs' open orders, release both pairs' reservations, cancel both
conditional children, and disable both pairs.

The fixture intentionally permits duplicate `pair_symbol` values while keeping
`pair_id` and `base_coingecko_id` distinct. This models the identity contract
required by the all-catalog objective; it is not a claim that the current
Production table presently permits duplicate pair symbols.

## What the CI script does

1. Creates a minimal disposable PostgreSQL schema and auth/admin stubs.
2. Includes the exact captured Production function body with psql `\\ir`.
3. Seeds two pairs with the same display symbol but distinct immutable IDs,
   each with a Limit order, conditional order, and reservation.
4. Calls the captured function for only the first CoinGecko asset and asserts
   the captured ticker-scoped behavior touches both pairs. This is a baseline
   characterization, not a passing safety assertion for that function.
5. Resets only disposable fixture rows and executes a pair_id-scoped candidate
   with the same super-admin guard, target-row lock, reservation accounting,
   conditional cleanup, audit record, and idempotent repeat behavior.
6. Asserts the candidate cancels/releases only the selected pair and leaves
   the same-symbol sibling pair, orders, conditional state, and reservations
   unchanged.

## Limits

- The pair_id-scoped function in this test is a candidate model only. It is not
  wired into the application, not a replacement migration, and not evidence
  that any deployed function has changed.
- The disposable schema intentionally contains only columns required by the
  captured function and candidate. It does not prove full table, trigger, RLS,
  grants, worker lock-order, or transaction parity.
- The fixture does not yet exercise the race against every deployed Limit,
  TP/SL, Stop-Limit, and cancellation worker. Those require a complete
  source-faithful schema and pair_id propagation through each caller.
- The captured function snapshot is dated 2026-11-27. A fresh Production
  fingerprint is still required before any future rollout proposal.
- PostgreSQL execution is delegated to GitHub Actions. Until a run on the exact
  resulting HEAD is observed and its job steps are inspected, runtime status is
  unknown; no pass is claimed.

## Safety

No Production query or write, migration, DDL, backfill, RPC, Worker, Cron,
Edge Function, RLS/ACL, Auth, financial data, merge, rebase, db push, deploy,
APK/Pages publication, or paid service action was performed.
