# Demo Futures liquidation and insurance accounting — design gate

Date: 2026-11-18  
Status: design draft; no execution RPC or Production change authorized  
Scope: USDT-settled demo Futures only. Margin Spot liquidation is explicitly out of scope.

## 1. Preconditions already present on the feature branch

The following building blocks are present and covered by disposable PostgreSQL CI:

- Multi-source Futures oracle observations, provider provenance, quorum/deviation checks, immutable snapshots, and fail-closed stale-snapshot selection.
- Versioned private maintenance-tier schedules and a trusted resolver.
- Transaction-pinned account maintenance snapshots with schedule IDs/versions and oracle provenance.
- Versioned private Maker/Taker fee schedules.
- Account-level Cross risk aggregation, including ledger-derived cash, unrealized PnL, unposted funding, close-fee reserve, equity, maintenance margin and margin ratio.
- Account-first Reduce-only placement, trusted fills, external position reductions and newest-first reservation reconciliation.

These components remain SQL drafts tested in disposable PostgreSQL. They are not deployed to Supabase Production and do not authorize trading or liquidation.

## 2. Non-negotiable safety rules

1. A liquidation decision must use the newest trusted Oracle snapshot and pinned maintenance/fee schedule versions from one transaction. A newer stale, expired, outlier or insufficient-quorum snapshot blocks the decision; never fall back to an older healthy price.
2. `public.market_prices` is not a Futures liquidation oracle and must never trigger liquidation.
3. Mark/index price determines risk eligibility; it is not automatically an executable fill price. A trusted execution component must supply the actual simulated fill price and bounded slippage evidence.
4. All monetary calculations use PostgreSQL `numeric` or the exact-decimal BigInt helper. No floating-point money or client-authored PnL, fee, price, quantity, margin or insurance amount.
5. Every mutation takes the derivatives account `FOR UPDATE` lock first, then locks affected orders and positions in stable primary-key order. This is shared with fill, cancel, Reduce-only and external-reduction writers.
6. One idempotency key maps to one immutable liquidation payload and one atomic result. A retry with identical payload returns the original result; a changed payload is rejected.
7. The user-facing balance must never be silently driven negative to hide a deficit. Insurance and any residual deficit require explicit system accounting.
8. No automatic liquidation, liquidation UI or client RPC is enabled by this design document.

## 3. Liquidation scope

### Isolated

Eligibility is position-scoped. The risk calculation includes isolated collateral, unrealized PnL, unposted funding receivables/payables, the trusted close-fee reserve, the pinned maintenance tier and any separately approved liquidation-fee reserve.

Only the affected isolated position may be reduced. Released collateral and realized PnL move through the ledger; the remaining position retains only its proportional isolated margin, with the final close releasing the exact remainder.

### Cross

Eligibility is account-scoped. All eligible Cross Futures positions, unrealized PnL, unposted funding and close/liquidation fee reserves are aggregated under one account lock and one pinned set of schedule versions.

There is no single meaningful Cross liquidation price. A Cross liquidation plan must evaluate the account after each proposed reduction and stop only when the post-action account meets the approved safety target or all eligible positions have been closed.

The deterministic position-priority rule is still an explicit policy decision; it must not be inferred from row order or browser input.

## 4. Partial versus full reduction

A partial reduction is acceptable only when an exact post-action simulation demonstrates that it restores the account/position to the approved maintenance buffer after execution fees, liquidation fees, slippage and remaining unposted liabilities.

- For Isolated, reducing quantity proportionally does not necessarily improve the margin ratio. A partial reduction is useful only when the pinned tier schedule and remaining exposure produce a demonstrably safer post-action state. Otherwise the plan must choose full close or return a non-executable result.
- For Cross, calculate the post-action account equity and maintenance requirement across every remaining position after each candidate reduction. Do not assume that reducing one position automatically cures the account.
- Quantity is rounded conservatively to the supported 18-decimal scale. The worker must never round a reduction upward beyond the open, unreserved position quantity.
- Existing Reduce-only reservations must be reconciled in the same transaction. Cancel newest active reservations first until remaining reservations fit the post-liquidation position quantity; never rewrite an order's original quantity or price.

The exact target buffer, partial-sizing search method, and cross-position priority remain unapproved parameters. Any initial numeric values in tests are fixtures only.

## 5. Execution price and slippage

The Oracle mark is a trigger/risk reference, not an execution guarantee. A future trusted liquidation executor must provide:

- the pinned mark/index snapshot ID and timestamp;
- the execution source and quote/depth evidence;
- simulated execution price and quantity;
- measured adverse slippage versus the pinned mark;
- the applicable maximum-slippage policy version.

If execution evidence is missing, stale or beyond the approved slippage bound, the worker fails closed and records a blocked attempt. A fallback-to-mark-price execution path is not permitted without a separately approved, explicit simulation rule.

## 6. Fees

- The ordinary close fee is resolved from the active server-owned Maker/Taker fee schedule pinned by ID and version. A liquidation close uses the approved taker path.
- A liquidation surcharge is a separate server-owned, versioned policy value. It must not be supplied by the browser or inferred from the Maker/Taker rate.
- Both fees are calculated from actual simulated execution notional and rounded upward to the supported USDT precision.
- The liquidation fee's cap, destination and treatment when collateral is insufficient are open policy decisions. No production fee rate is approved here.

## 7. Insurance and deficit accounting

Insurance must be a platform-level virtual account, not a user wallet and not an untracked adjustment to `system_clearing`.

Before implementation, specify a separate immutable system-ledger model with:
- a versioned insurance-fund identity and USDT balance derived only from append-only entries;
- atomic contributions/replenishments and liquidation payouts;
- a unique link from each insurance movement to its liquidation event;
- a deficit record for any loss not covered by the user's eligible collateral and available insurance;
- immutable audit data for opening deficit, insurance draw, remaining deficit and any later recovery.

The user ledger and system insurance ledger must reconcile in one database transaction. A partial insurance draw must not be mistaken for full deficit coverage. ADL/socialized-loss handling remains disabled until a separate policy defines ranking, caps, rounding, consent/disclosure and audit semantics. Do not invent an implicit negative user balance or silently spread losses across other demo users.

## 8. Atomic event and audit contract

A successful liquidation event should preserve at least:

- unique event/idempotency key and immutable payload hash;
- account, position and affected order IDs;
- Isolated or Cross scope and the exact pre-action risk snapshot;
- Oracle snapshot IDs/timestamps and maintenance/fee/liquidation-policy IDs/versions;
- pre- and post-action quantities, position status, realized PnL and remaining margin;
- execution price, quantity, source evidence and slippage;
- close fee, liquidation fee, settled/unposted funding treatment;
- insurance draw, residual deficit and resulting account cash/equity;
- reservation cancellations and their deterministic order;
- worker attempt/result timestamps and terminal outcome.

The position/order changes, user-ledger transaction and entries, system-insurance entries, deficit record and risk event must commit or roll back together. Ledger rows remain immutable; corrections use compensating entries.

## 9. Required disposable PostgreSQL tests

- Long and Short, Isolated and Cross.
- Healthy, exact-threshold, one-atomic-unit-below and stale/newest-invalid Oracle states.
- Partial reduction that restores the approved buffer; partial reduction that does not restore it; full close fallback.
- Tier-boundary crossing and schedule-version replacement races.
- Execution slippage at, below and above the approved bound.
- Close-fee and liquidation-fee precision/rounding boundaries.
- Full insurance coverage, partial insurance coverage, empty fund and residual deficit.
- Funding already posted versus still unposted; no double charge.
- Reduce-only reservation reconciliation and newest-first cancellation.
- Retry with identical payload, changed-payload rejection and crash-before/after-commit recovery.
- Two-session liquidation races against order placement, fill, cancel, external reduction and another liquidation.
- RLS/grants: clients cannot invoke trusted liquidation or write ledger, insurance or deficit records.

## 10. Decisions required before execution SQL

The following must be selected and documented before an execution RPC is written:

1. Liquidation surcharge rate, cap, recipient and schedule-version lifecycle.
2. Maximum execution slippage and the trusted simulated execution evidence contract.
3. Target maintenance buffer and whether partial reduction is attempted before full close.
4. Deterministic Cross position priority and whether Cross liquidation is sequential or all-at-once.
5. Insurance seed/replenishment rules and maximum payout policy.
6. Residual-deficit and recovery policy; ADL remains off unless separately approved.

Until these decisions are resolved and the full test matrix passes, the only permitted risk-reduction path is the existing trusted external-reduction draft. It is not a liquidation engine.
