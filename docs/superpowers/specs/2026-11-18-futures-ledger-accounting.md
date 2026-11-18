# Futures Ledger Accounting and Available Margin Contract

Date: 2026-11-18
Repository: `shahram-adim/DigiArz`
Branch: `feat/demo-derivatives-trading`
Status: design checkpoint only; no Production changes.

## 1. Single source of truth

The immutable, double-entry derivatives ledger is the sole authoritative source for settled virtual cash. The account row is an identity, configuration, and transaction-lock row; it must not be an independently editable balance authority.

The draft schema has now removed both `futures_cash_usdt` and `margin_cash_usdt` from `demo_derivative_accounts`. Settled Futures cash is exposed through the read-only `demo_derivative_futures_cash_balances` view, derived from immutable ledger entries. No separate cash cache is used in this first implementation. Any later performance cache requires a rebuild/reconciliation routine and invariant tests.

## 2. Ledger balance convention

For a given user, asset and account bucket, the normal debit balance is:

`balance = SUM(debit_amount - credit_amount)`

The Futures cash projection is exactly the USDT balance in bucket `futures_cash`, scoped to the authenticated user's derivatives account and its ledger transactions.

- Credit/debit entries must balance per asset inside each ledger transaction.
- A cash deposit/transfer into virtual Futures cash increases the `futures_cash` debit-normal balance.
- A transfer out, fee, or other settled cash charge decreases it.
- Realized PnL and funding affect Futures cash only when actually booked through ledger entries.
- Unrealized PnL is not a ledger cash entry; it is added to equity from open position snapshots.
- No balance may be accepted from browser input.
- A zero balance is represented by no matching entries and projects to numeric zero.

The existing ledger header is keyed by user and idempotency key. The account is currently one-per-user; if multi-account support is ever introduced, account_id must be added to ledger headers and enforced through composite foreign keys before that change.

## 3. Keep booked and unbooked liabilities separate

Never subtract an item twice.

- Fees already posted to `futures_cash` are already reflected in projected cash; do not subtract them again.
- Funding already settled and posted to the ledger is already reflected in cash.
- Funding accrued but not yet settled may be included once as an explicit unposted liability/reserve.
- Futures does not borrow USDT merely because leverage is used. Margin Spot loans and accrued interest belong to the Margin domain, not the Futures cash projection.
- Margin Spot debt must be projected by loan asset and outstanding principal plus accrued interest; it must not be mixed into the USDT Futures cash bucket.
- The current generic cross-risk helper's liability arguments are provisional inputs for unposted obligations only. They must never be populated with liabilities already included in the ledger cash projection.

## 4. Futures account equity and risk

For a USDT-settled cross-margin Futures account:

- `wallet_cash` = ledger-derived USDT `futures_cash` balance.
- `unrealized_pnl` = sum of exact-decimal unrealized PnL across all eligible open cross Futures positions.
- `unposted_liabilities` = only accrued obligations not already posted to cash.
- `close_fee_reserve` = conservative estimated fee to close all open positions at current trusted mark prices.

`equity = wallet_cash + unrealized_pnl - unposted_liabilities - close_fee_reserve`

`maintenance_margin = SUM(position_notional * applicable_maintenance_rate)`

The production-grade rate must be selected from a documented notional/leverage risk tier table, not an arbitrary client-supplied per-position value. The current math helper's rate inputs are test inputs only.

`margin_ratio = equity / maintenance_margin` when maintenance margin is positive.

A stale, missing, future-dated, outlier, or otherwise invalid mark for any open position makes the account risk snapshot unavailable and blocks risk-increasing operations. No liquidation decision may be based on a stale or incomplete snapshot.

## 5. Available margin and reservations

Equity, used initial margin, and available margin are different values.

`position_initial_margin = SUM(position_notional / position_leverage)`

`open_order_initial_margin = SUM(remaining_limit_order_notional / order_leverage)`

`open_order_fee_reserve = SUM(remaining_limit_order_notional * conservative_open_fee_rate)`

`available_margin = equity - position_initial_margin - open_order_initial_margin - open_order_fee_reserve`

Rules:
- Only live, non-reduce-only limit orders reserve opening margin. Remaining quantity, not original order quantity, is used after partial fills.
- Market orders are executed atomically or rejected; they must not remain as open market orders.
- A reduce-only order does not reserve new opening margin, but its remaining quantity must reserve reducible position quantity so concurrent reduce-only orders cannot close more than the position.
- An order reservation is a derived commitment, not a cash debit and not a ledger movement. Placing/cancelling an order must not change wallet cash solely because a reservation was created/released.
- On fill, order reservation decreases and position initial margin increases in the same database transaction; fee and realized cash movements are ledgered atomically.
- For a limit order, use its limit price for reservation. Any order type without a bounded execution price needs an explicit conservative price/slippage rule or must be synchronous and rejected if it cannot be safely reserved.
- Available margin below zero blocks new risk-increasing orders. Displaying zero as a UI floor must not hide the signed server-side deficit or maintenance breach.

## 6. Transaction and locking contract

Every state-changing Futures RPC must:
1. Derive user identity from `auth.uid()`; never accept user_id as trusted input.
2. Lock the user's derivatives account row with `FOR UPDATE` first. This row is the serialization mutex for all Futures cash, orders, positions and risk transitions.
3. Check/return the idempotency result before applying new effects.
4. Lock affected orders, positions and related records in deterministic primary-key order.
5. Recompute cash from ledger and reservations from current open orders while holding the account lock.
6. Validate mark-price freshness, leverage, quantity, margin and reduce-only constraints server-side.
7. Insert ledger header and all balanced entries in the same transaction as fills/position/order updates.
8. Commit all state changes together; on any failure, roll back all effects.

Every writer, including scheduled funding and liquidation workers, must obey the same account-first lock order. No direct client writes to account, order, position, loan, risk, or ledger tables are allowed.

## 7. Required tests before RPC implementation

- Empty ledger projects to exact zero; deposits, fees, realized PnL and funding project to expected signed cash.
- Two ledger transactions for different assets do not contaminate the USDT projection.
- Posted funding/fees are not subtracted a second time as unposted liabilities.
- Open positions add unrealized PnL and reserve initial/maintenance margin correctly.
- Pending and partially filled limit orders reserve only remaining quantity.
- Reduce-only orders reserve reducible quantity but no opening margin.
- Cancellation releases derived reservation without changing cash.
- Fill atomically converts reservation to position margin and ledger fee/cash effects.
- Concurrent place/cancel/fill requests serialize through the account lock and never over-allocate margin.
- Repeated idempotency keys return the original result without duplicate ledger entries.
- Stale/missing marks fail closed for risk-increasing operations and liquidation.
- RLS and function grants prevent cross-user reads/writes.

## 8. Scope boundaries

This contract is for USDT-settled Futures only. It does not define multi-asset collateral, collateral haircuts, Margin Spot cross collateral, borrowing asset conversion, or Margin Spot liquidation. Those require separate asset-by-asset accounting rules and must not be inferred from Futures math.

No Supabase Production DDL, migration, RPC, cron, balance, or data changes are authorized by this design checkpoint.


## 9. Order direction and reduce-only semantics

An order stores execution direction separately from the position it affects. `position_side` identifies the Long or Short position; `side` identifies the actual buy/sell execution. The allowed combinations are:

- Long increase/open: `side='buy'`, `reduce_only=false`.
- Long reduce/close: `side='sell'`, `reduce_only=true`.
- Short increase/open: `side='sell'`, `reduce_only=false`.
- Short reduce/close: `side='buy'`, `reduce_only=true`.

The draft schema enforces these combinations with a CHECK constraint. Fill rows persist `side` and a composite foreign key ties it to the originating order, preventing an execution record from silently reversing direction. Non-reduce orders may not implicitly close or flip an opposing position; explicit reduce-only orders are required. A future one-way/netting mode or position flip requires a separately specified state transition and must not be inferred from order direction.


## 10. Deterministic Reduce-only allocation and lifecycle

The account row is the serialization mutex. Every operation below takes the account `FOR UPDATE` lock before reading or writing the position or its orders. For a given `(account_id, product_type, symbol, position_side)`, the engine maintains one open position; the server enforces this with a partial unique index on open positions.

- **Place Limit Reduce-only:** lock account, then the matching open position; sum `remaining_quantity` for active (`pending`/`partially_filled`) Reduce-only orders for the same key. Accept only when `new_quantity <= position.quantity - active_reserved_quantity`. The new order joins the active reservation sum in the same transaction. It reserves no opening margin.
- **Place Market Reduce-only:** Market is atomic fill-or-reject. Under the same locks, require requested quantity to be no greater than unreserved reducible quantity, execute immediately, and never persist an active Market order.
- **Cancel/expire/reject:** change the order to a terminal status in the transaction. Terminal orders no longer count toward reserved reduce quantity; retain original and remaining quantities for audit, and do not create a cash-ledger entry solely for reservation release.
- **Partial/full fill of a Reduce-only Limit:** in one transaction reduce both position quantity and order remaining quantity by the exact fill quantity. Because both decrease by the same amount, the aggregate reserved quantity of all active Reduce-only orders remains bounded by the remaining position quantity.
- **Other position reductions (manual close, liquidation, admin risk action):** before commit, recompute active reservations. If the new position quantity is below aggregate reservations, cancel active Reduce-only orders newest-first (`created_at DESC, id DESC`) until the remaining reservations fit. This is intentionally deterministic and conservative; it never silently enlarges an order or changes its price/quantity.
- **Concurrency:** account lock serializes two simultaneous Reduce-only placements, fills, cancels and liquidation. Lock affected order/position rows in stable primary-key order after the account lock. Idempotency is checked before effects; a retry returns the prior result.

A reduce-only order may never increase or reverse a position. Any future netting/flip behavior requires a separate explicit product contract. All rules are server-side; the browser preview is advisory only.


## 11. Open position identity and atomic Market lifecycle

In hedge mode, at most one open position exists for each `(account_id, product_type, symbol, position_side)`. A partial unique index enforces this invariant and provides a single deterministic position row for Reduce-only reservation accounting. Long and Short remain distinct positions.

Market orders are strictly atomic: the only valid terminal states are fully filled (`filled_quantity=quantity`, `remaining_quantity=0`) or rejected without any fill (`filled_quantity=0`, `remaining_quantity=quantity`). A Market order may never persist as pending or partially filled. Limit orders retain the pending/partial-fill lifecycle.
