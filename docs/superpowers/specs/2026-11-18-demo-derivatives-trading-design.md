# DigiArz Demo Derivatives Trading — Design Specification

Date: 2026-11-18
Repository: `shahram-adim/DigiArz`
Target branch: `feat/demo-derivatives-trading`
Base: `main` at `1514668bc76dc697fa26b22edb2ebfd80b2199b8`

## Product decision

DigiArz will support four virtual-only trading modes:
1. Spot (existing engine; preserve existing behavior).
2. USDT-settled perpetual futures (long and short).
3. Margin spot (long borrowing and short borrowing, with isolated and cross collateral modes).
4. Leverage controls shared by futures and margin.

Live market prices may be used for display and risk valuation. All collateral, borrowed balances, fills, fees, funding, realized/unrealized PnL, liquidation and settlement are simulated ledger entries. No real deposits, withdrawals, credit, or asset transfers are introduced.

## Repository and production baseline

- Existing app is a Persian RTL single-page app in `index.html`, with Supabase client initialization in the main IIFE and `switchTab()` routing.
- Existing Spot path uses `execute_demo_trade`, `orders`, `trades`, `wallets`, `asset_balances`, `order_reservations`, `market_prices`, and enabled `demo_trading_pairs`.
- Existing advanced spot orders include Limit, conditional TP/SL, and Stop-Limit. These must remain unchanged.
- Current Supabase project is ACTIVE_HEALTHY on PostgreSQL 17.11. Public schema includes the spot tables above and has RLS enabled on exposed application tables.
- Production migration history and repository migration files are not yet reconciled. No Production migration, DDL, cron, function, order, wallet, balance, or other data is to be changed as part of this design checkpoint.
- PR #11 (catalog matcher design) is open and Draft; do not merge or repurpose it for derivatives.

## Navigation and experience

Add a distinct `معاملات` area with tabs:
- اسپات
- فیوچرز
- مارجین
- پوزیشن‌های باز
- سفارش‌های مشتقه
- تاریخچه مشتقه

Keep existing Spot forms and RPC calls intact. Derivatives must not be inserted into the existing `orders` table or masquerade as spot fills.

### Futures terminal

- Pair selector restricted to enabled and fresh USDT markets.
- Long / Short entry, Market / Limit order types, quantity, leverage selector, and isolated/cross margin mode.
- Order preview shows notional, initial margin, estimated fee, maintenance margin, and a clearly labelled indicative liquidation price.
- Open positions list: side, size, average entry, mark price, leverage, margin mode, collateral, unrealized PnL, ROI, liquidation price.
- Position actions: reduce-only partial close, close all, add/release isolated margin, change leverage only when risk checks pass.
- Funding history and next funding countdown; funding is simulated and transparently disclosed.

### Margin terminal

- Spot-style buy/long and sell/short with explicit borrow preview.
- Isolated and cross modes.
- Borrow, repay, accrued simulated interest, collateral ratio, debt, net equity, and liquidation warning.
- Shorting requires a simulated borrow of the base asset; closing buys back and repays debt.
- Borrow limits are virtual risk limits, not real credit.

### Portfolio and risk

- Separate spot wallet from derivatives equity and margin liabilities.
- Cross collateral must use only explicitly supported collateral assets and conservative haircuts.
- Isolated collateral is ring-fenced per position.
- Show maintenance margin, margin ratio, liquidation distance, estimated close fee, and stale-price state.
- Never silently auto-top-up or transfer spot funds into derivatives. Any transfer between virtual subaccounts requires an explicit, atomic user action and ledger entries.

## Backend architecture

Use separate derivatives domain tables; do not overload Spot `orders` / `trades`:
- `demo_derivative_accounts`: per-user futures equity and risk preferences.
- `demo_derivative_orders`: futures/margin order intent and lifecycle.
- `demo_derivative_positions`: open/closed position snapshots with versioning.
- `demo_derivative_fills`: immutable execution records.
- `demo_derivative_ledger`: immutable double-entry virtual journal for collateral, fee, funding, borrow, interest, PnL, transfer and liquidation movements.
- `demo_margin_loans`: simulated borrow principal, outstanding amount, accrued interest, asset and collateral mode.
- `demo_derivative_funding_events`: immutable funding settlement records.
- `demo_derivative_risk_events`: margin warnings, liquidation decisions, stale price blocks and audit metadata.

Exact final names and constraints must be checked against recovered Production schema and migration history before implementation.

### Atomic server-side operations

All state-changing actions must be Postgres RPC transactions (or an equally safe server-side transaction boundary):
- place/cancel derivative order
- fill/settle order
- open/increase/reduce/close position
- add/release isolated collateral
- transfer virtual funds between spot and derivatives accounts
- borrow/repay margin
- accrue/settle funding and simulated interest
- evaluate and execute liquidation

The browser may submit intent and display previews; it must never authoritatively set price, balance, PnL, leverage, debt, margin, fee, liquidation state, or fill status.

### Safety and correctness invariants

- Derivatives ledger is append-only; corrections use compensating entries.
- All balances use PostgreSQL `numeric` and exact-decimal parsing; no JavaScript floating-point arithmetic for money or quantity.
- Lock account, order, loan and position rows in deterministic order; use idempotency keys and optimistic version checks to prevent duplicate execution.
- Enforce positive quantity/notional, enabled pair, fresh market/mark price, max leverage, max order size, available collateral, maintenance margin, reduce-only constraints and account active state.
- Mark price must be sourced server-side from fresh trusted price rows. A stale/missing/outlier price blocks new risk and automated liquidation; do not liquidate based on stale data.
- Liquidation uses a deterministic, documented maintenance-margin formula, conservative fee reserve, partial liquidation where feasible, and an immutable audit trail.
- Cross margin risk calculation must aggregate all eligible positions and liabilities under one account lock.
- Funding/interest calculations are deterministic, capped, timestamped and idempotent.
- Users can read only their own account, positions, orders, fills and ledger under RLS. Client roles receive no direct write privileges to ledger or risk tables.
- SECURITY DEFINER functions must use a fixed safe search_path, validate `auth.uid()`, and have explicit EXECUTE grants. No service-role key in browser.
- All UI labels state that the system is demo-only and that liquidation/funding are simulations.

## Rollout gates

1. Recover and compare the full Production schema, relevant function definitions, grants, RLS policies, cron jobs and migration history against repository files. Resolve existing drift before any DDL.
2. Build an isolated disposable PostgreSQL fixture first; test formulas and lifecycle without Production.
3. Implement backend schema/RPC migrations in GitHub branch only, then run unit, integration, concurrency, failure-recovery and security tests.
4. Implement UI as a separately testable module and integrate without changing Spot behavior.
5. Verify all CI on the feature branch; perform static checks and mobile layout review.
6. Only after user review and explicit release approval, prepare a reconciled deployment migration. Never use `supabase db push` blindly.

## Acceptance criteria

- Spot buy/sell, Limit, TP/SL, Stop-Limit, wallet reservations, market display and admin flows pass their existing tests unchanged.
- Futures supports long/short, market/limit, isolated/cross, leverage, reduce-only, partial/full close, funding history and correct PnL.
- Margin supports long/short borrowing, repayment, isolated/cross collateral, interest and liquidation simulation.
- Every operation has a consistent immutable ledger trail and is idempotent under retries/concurrency.
- No user can read or modify another user's account or records.
- Stale market prices cannot create new positions or trigger liquidation.
- All calculations use exact numeric arithmetic and tests cover rounding boundaries.
- Persian RTL UI works at 360px width and desktop widths, with accessible controls and dark/light themes.
- The interface consistently discloses demo-only funds and simulated liquidation/funding.
- Android/PWA build and existing app navigation remain functional.


## 16. Futures fee, funding and borrowing-cost contract (design only)

This section records calculation boundaries and candidate semantics. It does not approve any rate, funding interval, fee tier, interest rate, recipient, or Production activation.

### Trading fees

- Maker/Taker classification is determined per actual fill by liquidity role: an execution that adds resting liquidity is Maker; an execution that immediately consumes resting liquidity is Taker. Order type alone is not authoritative; a marketable Limit order can execute as Taker.
- Calculate the fee from the actual executed fill notional, never from the original order quantity after a partial fill. Each fill stores the fee schedule ID/version and the Maker/Taker classification used.
- A partially filled order may contain both Maker and Taker fills only if the matching engine actually produced both roles; each fill is charged using its own recorded role and pinned schedule.
- Opening and closing fees are separate executions. A close fee is not silently included in unrealized PnL or charged twice when the fill is settled.
- For opening-order margin reservation, use a conservative fee estimate (candidate: Taker rate) until actual fills determine the final fee. Reservation is not a ledger debit; actual fee is posted exactly once with the fill.
- The current schedule draft is per-symbol and versioned, with one active schedule per symbol. The policy must still decide whether an order pins the schedule at acceptance or each fill resolves the active schedule at execution. The chosen rule must be deterministic across retries and schedule activation races.
- Settlement precision, per-fill versus aggregated rounding, fee cap, rebates, and any VIP/volume-tier calculation remain policy decisions. Do not infer them from SQL test fixtures.

### Futures funding

- Funding is a periodic simulated transfer between eligible Long and Short positions, not an exchange trading fee and not Margin Spot loan interest.
- Each funding event pins symbol, interval/window, rate source/version, rate sign convention, mark/reference price snapshot, position quantity, notional, and exact settlement timestamp.
- Define one signed convention and test both positive and negative rates. The payer/receiver direction must be explicit; a sign change must reverse the transfer without changing the formula silently.
- Funding is settled idempotently per position and funding window. A retry cannot post twice, and a closed/reduced position is charged only for the eligible quantity and timestamp window defined by the approved rule.
- Rate source, interval, caps/floors, eligibility timestamp, treatment of partial intervals, and rounding remain NOT DECIDED. Live exchange funding rates must not be copied into user balances without a separately approved simulation rule.

### Margin Spot borrowing interest

- Borrow principal and accrued interest are separate liabilities, denominated in the borrowed asset; they must not be mixed into the USDT Futures cash ledger.
- Interest accrues from a pinned principal/time/rate basis using exact-decimal arithmetic and a deterministic accrual window. Repayment allocation between accrued interest and principal must be explicitly specified and journaled.
- Borrow APR/rate, accrual frequency, day-count basis, compounding, grace period, repayment priority, and liquidation treatment remain NOT DECIDED. No interest worker or loan accrual RPC is authorized by this design section.

### Required disclosures

Before order confirmation and in position/history views, disclose the estimated opening fee, actual Maker/Taker fee after fill, possible closing fee, simulated funding exposure, and (for Margin Spot only) borrowing-interest basis. Distinguish estimates from booked ledger amounts. Never label funding or borrowing interest as a trading fee.

No operational values are approved by this section. Any rates or quantities in tests remain fixtures only.


### Funding convention and settlement boundary (proposed; values unapproved)

- Adopt an explicit signed-rate convention for all formulas: a positive funding rate means Long positions pay and Short positions receive; a negative rate reverses payer and receiver. This is a proposed convention for the simulator and must be visible in UI/history.
- Candidate per-position amount: absolute eligible position notional at the approved funding reference snapshot multiplied by the signed rate, with side determining debit/credit. The final notional basis (mark vs another pinned reference), rate scaling, and rounding stage require approval and exact-decimal tests.
- Eligibility must be defined at one deterministic settlement instant. Snapshot eligible position quantity and account/position version under stable locks; concurrent open/reduce/close operations must serialize against that boundary so a position is neither charged twice nor omitted inconsistently.
- Use a unique idempotency key for (account, position, symbol, funding window, policy version). A retry returns the prior settlement result and cannot create a second ledger posting.
- The funding event and balanced ledger postings must commit atomically. If the simulation uses a platform clearing account to balance net payer/receiver flows, its treatment and any residual imbalance policy must be approved; never create value silently or allow a negative user balance.
- Candidate schedule-pinning rule for trading fees: resolve and persist the active schedule version inside the transaction that creates each actual fill. This makes the fee reflect the rate active at execution and allows partial fills spanning a policy change to retain an auditable per-fill rate. Order acceptance may store an estimate only; it must not freeze the final fee rate. This is a recommendation, not yet an approved policy.
- Funding interval, source, rate caps/floors, settlement instant/timezone, notional reference, partial-period eligibility, rounding, clearing-account treatment and policy activation remain NOT DECIDED.


### Funding verification matrix (test design only; not executed)

The disposable-PostgreSQL test suite must cover these invariants before any funding settlement code is considered:

1. **Sign symmetry:** for identical eligible notional and absolute rate, positive and negative rates produce equal-magnitude opposite payer/receiver directions; test both Long and Short independently.
2. **Exact decimal:** use values whose products have repeating or boundary decimal representations; assert the unrounded exact numeric intermediate, then assert the explicitly approved rounding boundary. Do not choose a production scale from fixtures.
3. **Snapshot pinning:** mutate mark/reference price and position quantity after the funding snapshot is captured; settlement must use only the pinned snapshot values and policy version.
4. **Eligibility boundary:** open, reduce, and close immediately before, exactly at, and immediately after the approved settlement instant; assert the eventual policy's precise inclusion rule.
5. **Concurrent position mutation:** race settlement against reduce/close and assert serializable, single-boundary treatment with no double charge or missed eligible quantity.
6. **Idempotent retry:** submit the same account/position/window/policy key sequentially and concurrently; exactly one funding event and one balanced pair/set of ledger postings may exist.
7. **Atomic rollback:** inject a failure between payer debit and receiver/clearing credit; all event and ledger writes must roll back together.
8. **Balance and solvency:** aggregate debits and credits must reconcile exactly under the approved clearing model; insufficient payer balance must follow an explicitly approved policy and never create a negative user balance.
9. **Version isolation:** changing the funding policy after snapshot creation must not alter an in-flight event; retries must resolve the original policy version.
10. **Audit trail:** each result must retain source/version, signed rate, reference snapshot, eligible quantity/notional, window, settlement timestamp, policy version, and idempotency key.

The tests must be isolated from Supabase Production. Until the sign convention, eligibility instant, notional basis, rounding, clearing model and insufficient-balance policy are approved, tests may use named synthetic fixtures only and must not be represented as policy approval.
