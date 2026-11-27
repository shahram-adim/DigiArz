# OCO Linked-Order Design — 2026-11-27

## Status and scope

**Design only. Not implemented. Not a migration. Not approved for Production.**

The authoritative checked-in migrations currently provide TP/SL conditional exits and Stop-Limit parent/child orders, but no OCO group, sibling link, or OCO lifecycle. OCO must be designed as a separate linked-order state machine; it must not be approximated by submitting two independent conditional orders.

This design is subordinate to the canonical asset identity design. Every OCO group and child order must carry immutable `pair_id`, `base_asset_id`, and `quote_asset_id`. Ticker strings are display-only and must never select the asset, reservation, price, or cancellation target.

## Product semantics

Initial supported scope: a sell-side OCO pair for one existing demo position:
- one take-profit exit leg;
- one stop-loss exit leg;
- both legs refer to the same user, canonical pair, base asset, quote asset, and position quantity;
- whichever leg wins execution atomically disables the sibling;
- all values are virtual/demo-only.

Do not silently extend this initial scope to buy-side OCO, entry brackets, cross-pair legs, or multiple quote assets. Those require separate product and accounting design.

## Suggested data model

A dedicated `oco_groups` parent record should own the linked lifecycle, with fields conceptually equivalent to:
- immutable group UUID and user_id;
- pair_id, base_asset_id, quote_asset_id;
- original quantity and currently unclosed quantity;
- take-profit and stop-loss child conditional-order IDs;
- state: pending, claimed, partially_filled, completed, cancelled, failed_review;
- winning leg ID (nullable until claimed);
- timestamps and a monotonic version for compare-and-swap / idempotency.

Both child legs should reference the same group and carry a distinct leg kind. Enforce exactly one TP and one SL child per group with unique constraints. Enforce same user and same canonical pair/assets through composite foreign keys or equivalent database constraints. A display ticker is not a key.

The group is the sole authority for the shared reserved base quantity. Do not create two independently spendable full-quantity reservations. Either:
1. one group-level reservation is referenced by both legs, or
2. one canonical reservation row is owned by the group and child orders refer to it.

The final choice must preserve existing reservation invariants and be reconciled with order_reservations ownership/foreign keys before any SQL is written. Never double-reserve the same base quantity.

## Atomic trigger / winner protocol

The worker must perform the following in one database transaction:
1. Select an eligible group using `FOR UPDATE SKIP LOCKED`; lock the group before either child.
2. Revalidate group state, active account, enabled pair_id, canonical asset mapping, supported quote, provider-observed price freshness, and the winning leg's trigger condition.
3. Lock both child legs in a deterministic ID order. Confirm both are still pending and belong to this group/user/pair.
4. Atomically claim exactly one leg by changing the group from pending to claimed and setting winner_leg_id under a conditional update (`WHERE state='pending'`). A zero-row update means another worker/cancellation won; do nothing.
5. Mark the sibling cancelled in the same transaction and release only its unconsumed reservation amount. If reservation is group-owned, the sibling cancellation must not release the winner's shared reserve.
6. Execute the winning exit using the canonical pair_id/asset_id and the same validated reservation. Do not re-resolve by ticker.
7. Commit the group, winner, sibling, order, trade, balance, and reservation changes atomically. Any execution exception rolls back the claim and sibling cancellation, leaving the group retryable; a separate bounded failure policy may move repeatedly failing groups to failed_review without releasing funds.

The group row lock plus conditional state transition is the single-winner serialization point. A worker must never execute a child after observing that its group is completed, cancelled, claimed by the sibling, or otherwise terminal.

## Cancellation protocol

- User cancellation locks the group first, then both children in deterministic order.
- Cancellation succeeds only while the group is pending and no leg has been claimed.
- It marks the group and both pending legs cancelled and releases the shared unconsumed reservation exactly once.
- If a worker has already claimed a leg, cancellation returns a conflict/terminal result; it must not cancel the winner or release funds concurrently.
- Repeated cancellation is idempotent and must not release more than the remaining reserved amount.

## Partial fill and residual exposure

The first implementation must explicitly define whether the winning exit is all-or-nothing. If the underlying Market execution can partially fill, the group cannot simply cancel the sibling and call the position closed.

Safe policy options:
- **Preferred initial restriction:** require the OCO winning exit to settle the full remaining quantity atomically; reject/rollback if the engine cannot do so.
- **Later extension:** after a partial fill, atomically reduce the sibling trigger quantity and group-level reservation to the exact remaining position quantity, then return the group to a guarded active state. This requires proof that the old sibling cannot race with the quantity update.

Do not implement partial OCO behavior by copying the original amount into both legs or by trusting client-supplied remaining quantity.

## Required invariants

1. Exactly one group per linked pair of child legs; exactly one TP and one SL.
2. Same user, pair_id, base_asset_id, quote_asset_id, and position across group and both children.
3. One shared reserve; no double reservation and no negative/over-released reserve.
4. At most one winner; winner claim is atomic and idempotent.
5. Sibling cannot execute after winner claim.
6. Cancellation and worker execution serialize on the group row.
7. Group completion, trade settlement, balance mutation, and reservation consumption are atomic.
8. Stale/missing provider-observed price, disabled/missing pair, unresolved asset mapping, inactive account, or malformed reservation fails closed.
9. Duplicate ticker assets remain isolated by immutable IDs; no query or mutation is keyed only by symbol.
10. User RPCs enforce auth.uid() ownership and active-account checks; workers remain service_role-only; no blanket ACL changes.
11. Every state transition is auditable and retry-safe; repeated worker delivery cannot duplicate trades or releases.
12. UI/history show one OCO group with two legs and one shared position/reservation, not two unrelated sell orders.

## Disposable test matrix required before implementation can be called complete

- Create valid TP+SL group and assert one shared reservation.
- Reject cross-user, cross-pair, cross-base, cross-quote, duplicate-leg, missing-leg, and duplicate-child construction.
- Two real PostgreSQL sessions trigger opposite legs simultaneously: exactly one winner, at most one trade, sibling cancelled.
- Race user cancellation against both workers: exactly one terminal outcome and exactly one reservation release.
- Crash/exception after winner claim but before settlement: transaction rollback restores pending group and both legs.
- Duplicate worker delivery and retry: no duplicate trade, balance mutation, or reservation release.
- Stale provider-observed timestamp, missing timestamp, future timestamp, disabled pair, and ambiguous asset mapping: no execution and reserve preserved.
- Partial fill: either prove the initial all-or-nothing restriction or test exact residual quantity and sibling re-arming.
- Duplicate ticker assets with distinct pair_id values: OCO for one asset cannot read price, consume balance, cancel, or execute the other.
- Account deactivation and OCO worker race.
- RLS, SECURITY DEFINER search_path, auth.uid() ownership, service_role-only worker ACL, and direct table-write denial.
- Execute the authoritative migrations and OCO candidate in disposable PostgreSQL; document every unavoidable Supabase dependency adapter. A miniature lookalike fixture is not source-parity evidence.

## Explicit non-actions

No OCO schema, function, UI, worker, cron, grant, RLS policy, Edge Function, or Production data was changed by this design. No migration/db push, merge, deploy, APK/Pages publication, or infrastructure spend is authorized.