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
