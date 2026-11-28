# Canonical duplicate-ticker financial integration test plan — 2026-11-28

**Status:** disposable-test design only. This is not a migration, implementation, or authorization for Production changes.

## 1. What the existing tests prove

The current authoritative Market/Limit harness applies the checked-in migration
`20261113161641_enforce_active_accounts_in_demo_trade_and_limit_engine.sql`
to PostgreSQL 17 disposable database and invokes its actual
`execute_demo_trade`, `place_limit_order`, and `process_limit_orders`
functions. It retains the reduced fixture's wallet, base-asset balance,
reservation, trade, transaction, fee helper, and active-account behavior.

The separate canonical prototype proves that two assets with the same display
ticker can be isolated inside its own simplified schema. It is not financial
source parity and must not be described as exercising the authoritative
Market/Limit ledger or worker.

## 2. Structural reason the two harnesses cannot simply be combined

The authoritative fixture deliberately models the current ticker-keyed schema:

- `demo_trading_pairs.pair_symbol` is the primary key;
- `market_prices.symbol` is the primary key;
- `orders.symbol` is the execution lookup key;
- `asset_balances` and `order_reservations` identify base assets by text;
- the authoritative migration's RPCs and worker resolve pair/base asset through
  the ticker-derived symbol.

Therefore two different canonical assets cannot both be represented as
independent rows under one display pair symbol in this fixture. Adding
`pair_id` columns without changing the authoritative function bodies would
not make execution canonical: the old functions would continue to select by
ticker text.

The canonical prototype has the opposite limitation: it keys pairs/prices and
asset balances by canonical IDs, but uses a generic
`balances(user_id,asset_id)` table, a hard-coded fee, a simplified
reservation model, and a simplified worker. It must not be reused as the
financial baseline.

## 3. Required architecture for the next disposable integration harness

Create a *separate* canonical extension fixture that starts from the exact
authoritative Market/Limit fixture and migration, then introduces candidate
canonical columns and candidate canonical RPC/worker definitions in the
disposable database only. Do not alter the authoritative migration or claim
the candidate functions are Production source.

The candidate must preserve:

1. `wallets.balance_usdt` for quote-currency funds;
2. `asset_balances` for base-asset balances, with a deterministic,
   unique canonical-asset-to-legacy-ledger mapping;
3. the configured `get_demo_trading_fee_rate` helper (taker for Market,
   maker for Limit);
4. `order_reservations` cumulative
   `reserved_amount/consumed_amount/released_amount/status` lifecycle;
5. `orders`, `trades`, and `transactions` journal writes;
6. active-account checks, wallet-first row-lock discipline, and the
   `739201126` Limit worker advisory lock;
7. one-minute price freshness and the authoritative 25%-of-original
   per-cycle Limit fill cap;
8. the existing distinction in precision behavior: explicit 8-decimal
   Market rounding, but no silently introduced Market-style rounding in the
   authoritative Limit worker.

The canonical lookup chain must be:
`pair_id -> (base_asset_id, quote_asset_id) -> exact pair price`.
Display ticker and display pair are labels only. Every order, trade,
reservation, and worker selection must retain the exact pair/asset identity.

## 4. Minimum duplicate-ticker proof

Seed two different canonical base assets A and B with the same display ticker
and two distinct pair IDs, both quoted in the supported quote asset. Seed
different prices and distinct base-ledger mappings for A and B.

For the same user, exercise:

- Market buy A and Market buy B; assert only the matching base balance changes;
- Market sell A and Market sell B; assert quote wallet and correct base balance;
- Limit buy/sell A and B; assert each reservation refers to the exact canonical
  asset and cannot consume the other asset's available funds;
- run four authoritative-semantics 25% partial-fill cycles per order and assert
  each trade/transaction and cumulative reservation belongs to the same pair;
- cancel one pair's pending order and prove the other same-label pair remains
  pending with its reservation intact;
- disable one pair and prove cancellation/release cannot cross into the other;
- reject stale, missing, non-positive, and future-invalid pair prices;
- reject inactive accounts, disabled pairs, insufficient available funds,
  invalid/mismatched asset IDs, and unsupported quote assets;
- verify repeated requests/idempotency and two-session placement-versus-cancel
  and worker-versus-cancel races without double-spend or double-fill.

## 5. Hard gates before a candidate can be considered

- The test must execute the candidate canonical RPC/worker bodies, not only
  assert source text or exercise the independent prototype.
- No generic parallel balance table may replace or shadow the existing
  wallet/base-ledger model.
- The exact authoritative migration and setup remain immutable test inputs.
- The candidate must be isolated in a disposable PostgreSQL database and
  clearly labeled candidate-only.
- Node static guards and the full PostgreSQL workflow must pass on the exact
  current commit SHA before describing the harness as executed.
- Full Production schema, FK/index/trigger/RLS/grant parity is still a separate
  requirement; the reduced authoritative fixture does not prove it.
- The 17 unrecovered applied migration sources and 20 filename/ledger timestamp
  mismatches remain independent reconciliation gates. No migration replay or
  db push is permitted while unresolved.

## 6. Release boundary

This plan changes no Production schema, function, worker, cron, financial data,
RLS, grants, or Supabase setting. It does not authorize merge, rebase,
deployment, APK/Pages publication, infrastructure spend, or any Production
SQL. Those remain blocked pending explicit owner approval and completion of
the documented review gates.
