# Trading Ledger Schema Recovery Evidence — 2026-11-27

## Purpose and scope

This note records the source-recovery result before designing any canonical asset/pair financial schema. It is repository-only documentation. It does not authorize or perform a Production query, schema change, migration, data reconciliation, or release.

## Evidence confirmed on the current PR branch

### 1. CI fixtures are not authoritative base DDL

The following checked-in files construct disposable financial tables:

- `supabase/tests/exact_decimal_type_widening_setup.sql`
- `supabase/tests/exact_decimal_stop_limit_setup.sql`
- `supabase/tests/exact_decimal_conditional_exit_setup.sql`
- `supabase/tests/exact_decimal_limit_worker_setup.sql`

They are useful test scaffolds, but they are not migration sources for the current Production base schema. In particular, the widening fixture explicitly describes itself as a disposable fixture that mirrors relevant catalog details. Its table definitions cannot be promoted to authoritative DDL without a live, reconciled catalog comparison.

The widening fixture currently models:
- `asset_balances` with `UNIQUE(user_id, asset)` where `asset` is text;
- `order_reservations` with text `asset`, an order/user composite FK, accounting checks, and a unique order index;
- `orders`, `trades`, `conditional_orders`, `wallets`, and `transactions` with only the subset required by that test.

It also contains a test-only active-account helper/trigger scaffold and a limited set of RLS policies/grants. It is not a full catalog export.

### 2. Current checked-in Market/Limit migration confirms ticker-keyed financial writes

Migration `supabase/migrations/20261113161641_enforce_active_accounts_in_demo_trade_and_limit_engine.sql` defines the Market entrypoint, Limit placement, and Limit worker. These function bodies:
- resolve the base asset by parsing the pair ticker string;
- use `demo_trading_pairs.pair_symbol` and `market_prices.symbol` as execution lookup keys;
- read/write `asset_balances(user_id, asset text)`;
- reserve funds through `order_reservations.asset text`;
- use a local `market_prices.updated_at` one-minute freshness check;
- rely on the fee and active-account helpers.

The migration alters functions, not the complete base-table schema. It cannot alone reconstruct all table constraints, triggers, RLS policies, or ACLs.

### 3. Exact helper snapshots are useful but incomplete

The current PR contains read-only captured function-body snapshots for:
- `public.get_demo_trading_fee_rate(text,text)`, digest `546d80d7105228ed97da26c5ed0c7b7f`;
- `public.current_account_is_active()`, digest `d932cd1d0da21bb96bdc0a381f7dcbc3`.

Their comments record owner `postgres`, SECURITY DEFINER, empty search_path, and EXECUTE metadata as captured on 2026-11-27. The fee helper reads enabled maker/taker rates from `demo_trading_fees`; the active-account helper reads `profiles.is_active`.

These snapshots do not supply the authoritative `demo_trading_fees` table DDL/data constraints, `profiles` DDL, account-guard trigger function body/trigger inventory, or the complete current grants and policies for the financial tables. They improve the test harness but do not close schema parity.

### 4. Historical Recovery-Test snapshot is not a Production authority

The repository's earlier recovery record in `docs/FINANCIAL_RACE_BOOTSTRAP_PLAN_2026-11-21.md` reports a metadata-only catalog read from the isolated Recovery-Test project on 2026-11-21:
- 32 tables, 239 columns, 116 constraints, 63 indexes;
- 5 non-system triggers and 21 policies across public/private;
- the principal account-guard triggers were on INSERT for `orders`, `trades`, and `transactions`.

That record explicitly says the snapshot was not compared successfully with Production: read-only Production SQL/list-table attempts timed out. It also records that the Recovery-Test restore used `pg_restore --no-owner --no-acl`, so its ACLs and `has_function_privilege` results cannot establish Production grants. The restored project contains backup data and is not approved as a financial test harness.

The historical helper fingerprints in that note are recovery-snapshot fingerprints, not proof of current Production equivalence. The two 2026-11-27 helper snapshots now in this PR are separate, newer function captures; their existence still does not establish full schema parity.

### 5. Migration-source search did not recover authoritative base table DDL

A repository code search for `CREATE TABLE public.asset_balances`, `order_reservations`, `wallets`, and `transactions` returned disposable test setup files and dependent function migrations, but no authoritative base-table creation migration in the searched source. This is a bounded search result, not proof that no such DDL exists in Git history, backups, or the live database.

## Canonical identity implications

The financial key boundary remains unresolved:
- a text ticker in `asset_balances` cannot distinguish two canonical assets sharing the same ticker;
- text `asset` in reservations has the same ambiguity;
- orders, trades, conditional parents/children, pair activation/disable, market prices, cancellation, account deactivation, reservation readers, ingestion, and UI reads must migrate as one identity graph;
- legacy balances/reservations with ambiguous ticker mappings must be quarantined or explicitly reconciled, never silently assigned to an arbitrary asset.

A canonical Market/Limit candidate must preserve the authoritative behavior (wallet-first lock ordering, fee rounding/configuration, 25%-of-original partial fills, reservation consumption/release, advisory lock/SKIP LOCKED scheduling, active-account guards, transaction ledger semantics, and the one-minute local receive-time gate) while using immutable asset and pair IDs. The current simplified duplicate-ticker fixture is not sufficient.

## Required next evidence gate

1. Obtain a fresh, authorized, metadata-only Production fingerprint for the target financial tables, columns/types/defaults, PK/unique/FK/check constraints, indexes, triggers, RLS flags/policies, table grants, relevant function definitions/owners/config/ACLs, and relevant cron metadata. Do not query business or user rows.
2. Compare that fingerprint with the 2026-11-21 Recovery-Test metadata record and the checked-in source. Treat every mismatch and every unavailable field as a blocker; do not infer missing DDL from fixtures.
3. Reconcile the migration ledger separately. A schema fingerprint alone does not prove which migrations were applied.
4. Only then construct a fully source-faithful disposable PostgreSQL 17 schema and run the canonical candidate through the real lifecycle. Keep all Production writes and rollout actions behind separate explicit owner approval.

## Safety boundary

No Production SQL was run for this note. No business/user rows were read. No migration, function, table, index, trigger, RLS, grant, cron, worker, account, wallet, order, reservation, trade, or balance was changed. No db push, merge, deployment, APK/Pages publication, or cost was incurred.


## Additional historical Production metadata recovered from repository audit records

A second bounded repository search found older read-only Production inspection records on `main`, especially `docs/STOP_LIMIT_QA_MATRIX.md` and `docs/superpowers/reports/2026-11-15-exact-decimal-backend-rpc-review.md`. These records add useful historical schema evidence that was not included in the 2026-11-21 Recovery-Test summary:

- Historical typmods at the 2026-11-15 inspection: `market_prices.price numeric(38,18)`; `orders.amount/price numeric(24,8)`; `trades.amount/price numeric(24,8)`; `asset_balances.balance numeric(28,8)`; `wallets.balance_usdt` and `transactions.amount numeric(24,8)`; order fill/residual, reservation amounts and conditional-order numeric fields were unconstrained numeric.
- Historical constraints: order accounting equality `filled_amount + remaining_amount = amount`, order positive/range checks, nonnegative asset balance, positive trade amount/price, and reservation nonnegative/accounting checks `consumed_amount + released_amount <= reserved_amount`.
- Historical FK dependencies: `conditional_orders` references parent and execution orders; `order_reservations` references order/user; `trades` references orders. These were identifier relationships, not numeric-column dependencies.
- Historical trigger inventory on the four reviewed core tables: account guard triggers on `orders` and `trades`; none recorded on `asset_balances` or `order_reservations`.
- Historical index summary: indexes covered primary/unique identifiers, user/asset, reservation status, order creation time and trade order/time paths; no index keyed/included the numeric amount/price/balance fields.
- Historical RLS summary: user/account-scoped policies on the four reviewed tables; policies did not reference numeric columns. The wider Recovery-Test snapshot later counted 21 policies overall.

**Evidence limits:** these are dated, human-authored audit summaries, not raw catalog export or base-table CREATE DDL. They do not prove the schema stayed unchanged after 2026-11-15, do not provide exact constraint/index/policy names or expressions, and do not close the Production-vs-Recovery-Test comparison. The exact original CREATE TABLE statements, all column defaults/nullability, complete index definitions, policy expressions, table ACLs and current migration ledger remain outstanding. Use these records to guide the metadata fingerprint comparison, never as a substitute for it.
