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


The active Reduce-only order scan is supported by a partial index on `(account_id, product_type, symbol, position_side, created_at DESC, id DESC)` restricted to `reduce_only` rows in `pending` or `partially_filled` status. This supports both the reservation sum and deterministic newest-first cancellation without including terminal orders.


## 12. First account-locked Reduce-only RPC slice

The draft now contains a deliberately narrow first server-side slice:
- Place a Reduce-only Limit order only against an existing open position; derive execution side from the position side (Long→Sell, Short→Buy).
- Lock the user's derivative account row first, then the target position row, before summing active reservations and inserting the order.
- Enforce the active reservation ceiling with exact database numeric arithmetic.
- Make placement idempotent by `(user_id, client_request_id)`; replay with identical parameters returns the original order, while key reuse with changed parameters is rejected.
- Cancel an active Reduce-only order under the same account-first lock; its terminal status releases reservation and creates no cash-ledger entry.
- Public PostgREST wrappers are SECURITY INVOKER. The write helpers live in the non-exposed `private` schema, are SECURITY DEFINER with empty search_path, and require `auth.uid()`. The private schema is not intended for Data API exposure.

This slice intentionally does not implement fills, realized PnL, fees, margin release, liquidation reconciliation, Market Reduce-only, or cross-session race tests. Those must be designed with the complete atomic fill/ledger contract before enabling execution.


## 13. Atomic Reduce-only Limit partial fills

A trusted execution worker may submit an actual fill only through a server-only RPC granted to `service_role`; neither `anon` nor `authenticated` may execute it, and the service key must never enter the Android client. The RPC accepts the trusted execution's fill ID, quantity, price and fee, validates 18-decimal precision and Limit price protection, and is idempotent by immutable fill ID plus exact payload.

The transaction locks account first, then order, then the unique open position. It inserts one immutable fill, reduces position quantity, updates realized PnL, releases isolated margin pro rata (rounding release down to 18 decimals except full close, which releases the exact remainder), updates order filled/remaining quantity and weighted average fill price, and writes one balanced USDT ledger group for realized PnL, fee and isolated-margin transfer. A zero-value component creates no empty entries. All state and ledger writes commit or roll back together.

This first fill slice is limited to Futures Reduce-only Limit orders. Market execution, opening/increasing positions, cross-session stress tests, liquidation reconciliation and external reductions that may invalidate other Reduce-only reservations remain out of scope. The caller is a trusted matching/execution service; fee and execution price are not user inputs.


Before a Reduce-only fill is accepted, the worker recomputes the sum of all active Reduce-only remaining quantities for that account/product/symbol/position side under the account mutex and fails closed if the total already exceeds the open position quantity. The fill then reduces both the position quantity and the filled order's remaining reservation by the same amount, preserving the aggregate reservation inequality.

## 14. Atomic trusted external Futures position reduction

The first external-reduction path is intentionally narrower than liquidation. It supports a trusted worker applying a manual/risk-driven reduction to an existing USDT Futures position using a server-authoritative execution price and fee. It does not calculate liquidation eligibility or choose a liquidation price.

Required transaction sequence:
1. Discover the position's account/user without locking a child row.
2. Lock the derivative account row first; this is the mandatory serialization mutex.
3. Check the external event UUID in `demo_derivative_risk_events` before checking current position state. Replaying the same UUID and identical payload returns the original result; changed payload is rejected.
4. Lock the open position. Only `product_type='futures'` is accepted; Margin Spot is excluded.
5. Validate positive quantity/price, non-negative fee, 18-decimal precision, and reduction quantity not greater than current position quantity.
6. Compute realized PnL using the same exact Long/Short formula as the Reduce-only fill path. Release isolated margin pro rata with truncation to 18 decimals, except a full close releases the exact residual.
7. Update position quantity, realized PnL, isolated collateral, status, closed timestamp and version.
8. Post one balanced USDT ledger transaction keyed by the event UUID when PnL, fee or isolated-margin release is non-zero. The event type is `position_reduction`; settled cash changes only through ledger entries.
9. Invoke the existing newest-first Reduce-only reconciliation helper after the position mutation, while still holding the same account lock. Any cancellations, position update, ledger posting and risk event are in the same transaction.
10. Insert `demo_derivative_risk_events` with `id=event_id`, `event_type='external_reduction'`, and request/result snapshots. This durable row also provides idempotency when no ledger entries are required.

The public wrapper is SECURITY INVOKER and executable only by `service_role`; its private SECURITY DEFINER helper uses an empty search_path. The service-role credential must remain server-side. No browser or Android client may invoke this operation.

The disposable test reuses the concurrent ETHUSDT fixture: a trusted reduction from 0.6 to 0.3 ETH at 110 USDT against a 100 USDT Long entry realizes 3 USDT before a 0.01 USDT fee. It must cancel the newest two 0.2 ETH reservations, preserve the oldest partially-filled 0.2 ETH order, produce ledger-derived cash of 2.99 USDT, reject changed event-id payloads and reject over-reduction. The test replaces the earlier direct fixture UPDATE; it is not a production action.

## 15. Liquidation remains separately gated

The live `public.market_prices` table is not a derivatives mark-price oracle. It stores one last-price row per symbol, with the source overwritten by whichever CoinGecko, KuCoin or Gate.io response is processed last. It does not retain per-source observations, an index price, a mark price, a futures premium/basis, or a documented outlier/confidence calculation. A recent timestamp alone does not make this price safe for liquidation.

The current Futures draft also lacks a production risk-tier table and an approved liquidation-fee/insurance-fund accounting model. The math helper's maintenance-rate inputs are test inputs, not a production risk schedule. Therefore:
- Do not implement or activate automatic liquidation from `market_prices`.
- Before liquidation RPC design, specify and test a server-owned multi-source index/mark-price feed with source observations, timestamp/freshness bounds, source-count/quorum, outlier rejection and fail-closed behavior.
- Define maintenance tiers, partial-liquidation sizing, execution slippage, liquidation fee treatment, insurance/deficit handling and event idempotency.
- Then test long/short, isolated/cross, partial/full liquidation, stale/outlier feed, fee boundaries and concurrency with placement/fill/cancel.
- Until these gates pass, only the trusted external reduction path is in scope; it is not a substitute for a liquidation engine.
