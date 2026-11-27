# Exact-decimal rollout: ledger and concurrency release gates

> Status: review/runbook only. This document does not authorize a Production migration, function replacement, grant change, Cron change, deployment, or merge.

## 1. Historical ledger reconciliation plan

The current Production snapshot observed on 2026-11-27 has no rows in `orders`, `trades`, `asset_balances`, `order_reservations`, `conditional_orders`, or `transactions`, and one `wallets` row. The six current cross-table integrity checks returned no issues. This is a point-in-time observation only; it is not evidence that past wallet changes can be reconstructed. With empty transaction/trade history, historical reconciliation cannot be inferred from current balances.

Before any rollout is considered:

1. **Freeze the evidence set (read-only):** record UTC snapshot time, database version, exact function-definition fingerprints, relevant column types, constraints, indexes, triggers, RLS policies, table grants, function owners/SECURITY DEFINER/search_path/EXECUTE ACLs, and Cron job definitions. Hash/export query results and retain the SQL plus result counts.
2. **Establish an auditable baseline:** for each user and asset, capture wallet balances, asset balances, all active orders, conditional/Stop-Limit parents and children, reservations (reserved/consumed/released), trades, and transactions. Do not mutate or normalize source rows during this phase.
3. **Reconcile order lifecycle:** every pending/partially-filled Limit order must have exactly one valid active reservation with matching user and asset and sufficient unconsumed amount for the remaining order. Terminal orders must not retain active reservations. Every pending conditional order must have a matching parent and exactly matching reservation; triggered Stop-Limit parents must point to the expected child order and symbol/side/amount/price relationship.
4. **Reconcile fills and cash/inventory:** group trades by order and user; verify fill quantities do not exceed order amount, filled + remaining = amount within the declared precision, each fill has its corresponding transaction rows, fee calculation and quote/base deltas use the same per-fill quantization, and reservation consumption equals the settled amount. Recompute wallet and inventory deltas from a trusted opening balance plus the complete transaction ledger; compare with stored balances.
5. **Classify exceptions without auto-repair:** missing ledger history, unexplained wallet deltas, duplicate/missing reservations, orphan trades, mismatched parent/child orders, negative or over-consumed reservations, and precision loss are blockers. Produce a row-level exception report and require owner-approved remediation separately. Never fabricate historical transactions or infer an opening balance.
6. **Repeat after rehearsal:** run the same read-only checks against a populated disposable PostgreSQL fixture before and after the candidate migration. Compare schema/catalog fingerprints and all financial invariants. Preserve rollback evidence and verify no partial DDL/data changes after deliberate failure.
7. **Production gate:** only after the owner reviews the baseline, exception report, rehearsal evidence, and rollback plan may a separate explicit approval authorize any Production change. A successful CI run alone is not approval.

### Minimum reconciliation equations

- `filled_amount + remaining_amount = amount` for every live order.
- `consumed_amount + released_amount <= reserved_amount`; reservation status must agree with its remaining active amount.
- Buy settlement: quote debit = quantized gross + quantized fee; base credit = quantized fill quantity.
- Sell settlement: base debit = quantized fill quantity; quote credit = quantized gross - quantized fee.
- Wallet/inventory closing balance = trusted opening balance + sum of signed ledger movements.
- For each order, the aggregate trade fill quantity and corresponding transaction totals must reconcile to order state and reservation consumption at the same precision policy.

The precision policy must be explicitly agreed for every currency/asset field before release; do not mix raw high-precision arithmetic with separately rounded wallet, transaction, and reservation values.

## 2. Caller and worker compatibility matrix

| Routine / path | Production contract observed | Candidate / test expectation | Required release evidence |
|---|---|---|---|
| `execute_demo_trade` | User-facing market execution; authenticated/service-role boundary; SECURITY DEFINER with empty search_path | Exact-decimal arithmetic and shared settlement semantics | Caller inventory, rounding/fee parity, ACL/owner/search_path parity |
| `place_limit_order` | Wallet row lock first; sell path then asset-balance lock; creates order + reservation | Candidate accepts bounded decimal scale and rejects zero-rounded USDT notional | Existing clients/RPC arguments, scale boundary, concurrent Buy/Sell placement |
| `place_stop_limit_order` | Wallet then sell inventory lock; creates parent, reservation, conditional row | Candidate must preserve parent/child relationships and reservation invariants | Trigger/child lifecycle, cancel/worker races, symbol/side/price parity |
| `place_conditional_exit_order` | Wallet then base-asset lock; creates conditional parent and reservation | Candidate must preserve TP/SL amount and reservation equality | TP/SL execution/cancel race, caller compatibility, exact amount/trigger validation |
| `process_limit_orders` | service_role-only worker; current settlement lacks explicit 8-place gross/fee quantization | Candidate worker quantizes each fill consistently | Fee half-quantum boundaries, idempotency, retry inertness, wallet/asset/reservation/trade/transaction reconciliation |
| `process_conditional_orders` | Separate live worker; locks conditional + parent + reservation before settlement; releases reservation inside a rollback-safe subtransaction; then invokes market execution | Not replaced by the current Limit candidate | Pinned source/ACL compatibility, conditional-worker vs placement, TP/SL cancel race |
| `process_stop_limit_orders` | Separate one-minute worker; synchronizes triggered parent with child Limit order | Not replaced by the current Limit candidate | Parent/child state, partial-fill synchronization, cancel vs child-worker race |
| `cancel_limit_order` | Locks order then updates reservation; does not currently enforce active-account guard | Cancellation for inactive accounts may be intentionally retained | Preserve policy unless owner explicitly decides otherwise; cancellation atomicity and duplicate-cancel race |
| `cancel_stop_limit_order` | Locks conditional, parent, then child; triggered path calls Limit cancellation | Different lock prefix from placement and workers | Parent/child concurrent cancellation and worker interleavings; no state/ledger drift |
| `cancel_conditional_exit_order` | Locks conditional then reservation then parent; checks active account | Candidate/test must preserve fail-closed account semantics | Conditional worker vs cancellation, concurrent duplicate cancellation, rollback invariants |

All inspected routines were observed as owned by `postgres`, SECURITY DEFINER, and configured with empty search_path; grants differ by caller role and must be compared exactly rather than generalized. User-facing placement/trade RPCs retain their current authenticated/service-role access. Background workers remain service_role-only. Do not broaden or narrow ACLs as part of an arithmetic-only change without a separately reviewed authorization decision.

## 3. Two-session lock/interleaving matrix

The existing disposable PostgreSQL suite already covers:

| Interleaving | Existing evidence | Status |
|---|---|---|
| Limit worker vs same-user Buy placement | Real two-session race in exact-decimal workflow | Passed on HEAD `53ad1b69e5b5161c143008213fa3b2b2e57e9862` |
| Limit worker vs same-user same-asset Sell placement | Real two-session race in exact-decimal workflow | Passed on HEAD `53ad1b69e5b5161c143008213fa3b2b2e57e9862` |
| Stop-Limit cancel vs child Limit worker | `exact_decimal_stop_limit_cancel_race.sh` | Existing coverage; re-run with full suite |
| TP/SL cancel vs conditional worker | `exact_decimal_conditional_cancel_race.sh` | Existing coverage; re-run with full suite |
| Conditional worker vs same-user placement | Dedicated two-session race; CI run 45995474050 on HEAD e7e53468 | **Passed** |
| Concurrent cancellation through Stop-Limit parent and child Limit RPC | Dedicated two-session parent-vs-child cancellation race; CI run 45995474050 on HEAD e7e53468 | **Passed** |

For each open case, use separate PostgreSQL sessions with distinct `application_name`, deterministic barriers (test-only trigger/advisory barrier), bounded `lock_timeout`/test timeout, and capture `pg_stat_activity`, `pg_locks`, wait events, and PostgreSQL deadlock diagnostics. After both sessions finish, assert:

- exactly one terminal transition or a documented idempotent response;
- no duplicate child order, trade, transaction, or reservation;
- parent/child/conditional statuses and fill totals agree;
- wallet, asset inventory, and reservation totals reconcile;
- failed/deadlocked transaction leaves no partial ledger or reservation mutation.

Do not interpret the current passing worker/cancel lifecycle suites as proof that the full cross-entrypoint wait-for graph is deadlock-free.

## 4. Explicit non-goals and safety boundaries

- This plan is not a migration and must not be executed against Production as a write script.
- No Production function, row, schema, grant, Auth setting, Cron job, Edge Function, or deployment is changed by this document.
- The 18-decimal base-quantity proposal remains blocked until dependent column widths, every caller, every worker, and every ledger field share a compatible precision contract.
- The live Limit worker's missing explicit 8-decimal settlement quantization remains a release-blocking accounting defect until corrected and rehearsed.
- Production history cannot be declared reconciled while source ledger history is absent.


## Fresh evidence addendum — 2026-11-27 12:07 UTC

### Two previously open interleavings are now covered
- [x] Conditional worker vs same-user Sell placement: the dedicated two-session disposable-PostgreSQL test passed in GitHub Actions run [45995295489](https://github.com/shahram-adim/DigiArz/actions/runs/45995295489) on intermediate HEAD `7c77a4aaa0a78e4232c8cb2af7dd0fe436c92b0d`.
- [x] Stop-Limit parent cancellation vs direct child `cancel_limit_order(child)`: the dedicated two-session disposable-PostgreSQL test passed in GitHub Actions run [45995474050](https://github.com/shahram-adim/DigiArz/actions/runs/45995474050) on final HEAD `e7e53468beb71385ebeaf0b2d45a3ebfa11454b9`.
- [x] The final exact-decimal workflow run [45995474050](https://github.com/shahram-adim/DigiArz/actions/runs/45995474050) completed with `success` on exact HEAD `e7e53468beb71385ebeaf0b2d45a3ebfa11454b9`; both new tests and the existing two-session lifecycle/race tests passed. The earlier run on the intermediate HEAD is not used as evidence for the final HEAD; run 45995474050 is the final-HEAD evidence.
- [!] These tests establish the specific interleavings they exercise; they do not prove every possible cross-entrypoint lock graph or replace a production-faithful schema/ACL harness.

### Fresh Production read-only snapshot
- [x] Supabase project `gfoaubfilhttnwjykaox` is `ACTIVE_HEALTHY`, PostgreSQL `17.11.0.018`.
- [x] Current financial row counts: `orders=0`, `trades=0`, `asset_balances=0`, `order_reservations=0`, `conditional_orders=0`, `transactions=0`, `wallets=1`. This is a point-in-time snapshot, not historical ledger reconciliation.
- [x] Current Production function fingerprints remain unchanged from the earlier audit: `process_limit_orders=00ab429596fb99392666632967cde9c0`, `process_stop_limit_orders=66357ab4a2247019f22a8b6ab6eac6fe`, `process_conditional_orders=5cfbf0e2e73474ae64e42643b3feb28a`, `execute_demo_trade=4289e358b0c7293fc33f86c2511486d7`, `place_limit_order=3eab167c47bf8ff2e1705b9f243380ec`, `place_stop_limit_order=d6f4ff7478b83fbabbab519c7c711bcd`, `place_conditional_exit_order=e4de4667d89e6663f04d92d47ac4d5cf`, `cancel_limit_order=69360684173b6aabebc5ff4e4de2eed9`, `cancel_stop_limit_order=82cedc2c442b0c826a8684044aed5f8d`, `cancel_conditional_exit_order=efa4c8a200d299f76b0d2cbe2d0b49e9`.
- [x] Relevant live column types still include `orders.amount/price numeric(24,8)`, `trades.amount/price numeric(24,8)`, `asset_balances.balance numeric(28,8)`, `wallets.balance_usdt numeric(24,8)`, and `transactions.amount numeric(24,8)`; reservation and conditional amount/price fields remain unconstrained `numeric`. Therefore the proposed 18-place base-quantity contract is not deployable as-is.
- [x] Production Cron jobs 8, 9, and 12 (`digiarz-limit-orders`, `digiarz-conditional-orders`, `digiarz-stop-limit-orders`) remain active at `* * * * *`. No Cron change was made.
- [!] Current Advisor snapshot (observed 2026-11-27 12:07:10 UTC): 2 anon-executable SECURITY DEFINER RPCs, 23 authenticated-executable SECURITY DEFINER RPCs, 15 RLS-enabled/no-policy findings, 9 unindexed foreign keys, 11 RLS init-plan findings, 12 unused-index findings, and leaked-password protection disabled. These are review findings; no ACL, RLS, index, or Auth setting was changed.
- [!] The accounting quantization defect in the live Limit worker remains a release blocker. The current candidate entrypoint SQL does not itself replace `process_limit_orders()`; the separate worker candidate must be included and validated together with the entrypoints and coordinated column widths.
- [!] Empty financial tables mean there is no historical trade/transaction ledger from which to reconstruct prior wallet movements. Do not call the current snapshot a completed historical reconciliation.

### Current release decision
- The two previously open lock interleavings are **Passed** in disposable PostgreSQL CI.
- The financial rollout remains **Blocked** by live-vs-candidate worker arithmetic parity, coordinated numeric typmods/precision, complete candidate caller/worker/ACL compatibility, and the absence of historical ledger evidence.
- This addendum is evidence/documentation only. No Production SQL writes, Migration, function replacement, ACL/RLS change, Cron change, Edge Function deployment, merge, or release was performed.
