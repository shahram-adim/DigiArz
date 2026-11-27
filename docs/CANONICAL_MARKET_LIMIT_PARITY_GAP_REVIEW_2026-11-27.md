# Canonical Market/Limit Parity Gap Review — 2026-11-27

**Status:** read-only code review of checked-in candidate fixture versus authoritative Market/Limit source. No executable migration or Production change.

## Evidence reviewed

- Authoritative source: `supabase/migrations/20261113161641_enforce_active_accounts_in_demo_trade_and_limit_engine.sql` (SHA `de09b1cd391790fcd9d94708a916cb41cd9ccc9f`).
- Canonical prototype: `supabase/tests/canonical_asset_identity_candidate.sql` (SHA `42b56965140e6c7f7f20bf26126d06eebd472e24`).
- Authoritative source-parity CI: run `46048133466`, step 28 applied the exact Market/Limit migration in disposable PG17 and completed successfully.

## Conclusion

The existing canonical fixture is useful evidence that immutable pair/asset IDs can isolate duplicate display tickers in a deliberately simplified model. It is **not** a faithful canonical replacement for the authoritative Market/Limit financial functions. Do not copy its current functions into a migration or call its worker tests source parity.

The newly passing source-parity baseline is ticker-based and preserves the actual current financial behavior. The next candidate must join both bodies of evidence: exact financial semantics from the authoritative source plus canonical identity isolation from the prototype.

## Critical semantic differences

| Concern | Authoritative Market/Limit source | Current canonical prototype | Required before parity claim |
|---|---|---|---|
| Market quote currency ledger | USDT is `wallets.balance_usdt`; base assets are `asset_balances(user_id,asset)` | Both quote and base balances are in one generic `balances(user_id,asset_id)` table | Preserve the production wallet/base-ledger model or explicitly prove a separate canonical ledger migration and reconciliation |
| Market buy/sell | Market buy debits USDT wallet and credits base; sell debits base and credits USDT wallet | Generic balance mutations; no wallet integration | Keep wallet-first / base-row lock ordering and exact accounting |
| Fees and rounding | Gross and fee are rounded to 8 decimals; fee helper is called with USDT/taker or maker | Hardcoded 0.1%; no equivalent round(…,8) behavior | Use the authoritative fee helper and exact rounding rules, then test cumulative decimal edge cases |
| Freshness | Production functions use `market_prices.updated_at >= now()-1 minute` | Prototype allows provider-observed age up to 2 minutes and 30 seconds into future | Canonical pair-price policy must use an explicitly approved provider-observed freshness contract; do not silently relax the one-minute production rule |
| Market identity | Pair and price selected by mutable `pair_symbol/symbol` | Pair and price selected by UUID | Rewrite all entrypoints and workers to use pair_id; retain display ticker only for output |
| Limit partial fills | Worker fills `LEAST(remaining_amount, original_amount*0.25)` per cycle; up to four cycles for full amount | Worker settles the full remaining amount in one pass | Preserve the 25%-of-original per-cycle behavior and exact repeated-fill ledger arithmetic |
| Limit reservation accounting | Reservation tracks `reserved_amount`, `consumed_amount`, `released_amount`, `status`; per-fill consumption and remaining reserve are updated | Prototype reservation has only amount; worker deletes reservation at full fill | Preserve exact reservation ledger fields and consumed/released invariants; do not delete financial reservation history |
| Limit buy reserve | Reserve amount is `amount*limit_price*(1+maker_fee_rate)`; each fill consumes gross+fee and recalculates remaining target reserve | Candidate pre-reserves quote amount but does not model consumed/released ledger | Reimplement authoritative formulas using quote_asset_id and exact canonical pair |
| Limit sell reserve | Reserve exact base quantity; each fill consumes base amount | Candidate removes balance into a reservation but does not maintain consumed/released ledger | Preserve base-asset reservation accounting and release rules |
| Worker serialization | Global transaction advisory lock `739201126`, order `FOR UPDATE SKIP LOCKED`, wallet-first lock, reservation lock | Candidate has no equivalent global advisory lock and uses a different lock pattern | Preserve/justify lock order and prove two-session races using canonical pair IDs |
| Active accounts | RPCs check `auth.uid()` and `current_account_is_active()`; worker filters active profiles | Prototype takes caller-supplied user_id and has no auth or active-account guard | Canonical RPCs must derive auth.uid(), preserve active-account check; worker must keep active-profile filter |
| Financial ledgers | Authoritative writes orders, trades, transactions and wallets/base balances | Prototype omits transactions and production wallet ledger | Preserve all ledger rows and exact user/pair identity |
| Constraints / precision | Production constraints and exact-decimal migration enforce bounds and order fill accounting | Candidate has simplified checks and different status/shape | Reuse current constraints, ownership FKs, fee precision, and accounting invariants in canonical schema |
| Duplicate ticker isolation | Not supported by ticker-keyed production functions | Prototype passes duplicate display-symbol tests | Add pair_id/base_asset_id/quote_asset_id to orders/trades/reservations/prices and assert the authoritative formulas cannot cross-contaminate |

## Required canonical Market/Limit design, in order

1. **Identity schema:** immutable asset UUID; unique provider/provider-asset mapping; pair UUID with base/quote asset IDs; duplicate display symbols allowed; composite pair identity constraints.
2. **Ledger extension:** add nullable canonical identity columns to orders/trades/reservations and pair-keyed prices, with composite constraints; do not backfill an ambiguous ticker by guess. The current migration-ledger mismatch prevents proposing a deployable migration until reconciled.
3. **Market RPC:** add a pair_id-authoritative RPC; derive user from auth.uid(); validate active account, enabled pair, active assets, supported USDT quote, fresh pair price; preserve fee helper, 8-decimal rounding, wallet/base ledger semantics, orders/trades/transactions writes and lock discipline.
4. **Limit placement:** accept pair_id; derive reserve asset from pair quote/base IDs; preserve maker fee reserve formula, available balance calculation, wallet/base row locks, exact reservation ledger fields, order fill invariant.
5. **Limit worker:** select pending orders by pair_id; price lookup by pair_id; preserve active profile filter, global advisory lock, SKIP LOCKED, wallet-first locking, 25%-of-original partial fill, exact cumulative consumed/released formulas, trade and transaction ledger rows.
6. **Limit cancellation:** inspect the actual authoritative cancellation function/migration separately; preserve auth.uid(), order ownership, row lock, and exact one-time release semantics. It is not defined in the reviewed Market/Limit migration file and must not be inferred from this file.
7. **Parity harness:** load exact authoritative migration first, then apply canonical candidate DDL/functions in a separate disposable database. Test Market and Limit same-ticker pair A/B at once, all fee/rounding/reservation paths, four partial fills, stale/missing/future provider timestamps, disabled pair, inactive account, unauthenticated caller, malformed reservation, retries, cancellation and two-session races.
8. **Downstream:** only after Market/Limit canonical parity passes, replace the adapters used by the existing authoritative TP/SL and Stop-Limit harnesses with these exact canonical Market/Limit entrypoints; then implement OCO as its own linked state machine.

## Explicit non-actions

No schema or function was changed by this review. No executable canonical migration was authored or run. No Production data/function/ACL/RLS/Cron/worker/Auth change, migration-history repair, db push, merge, deploy, APK/Pages publication, or infrastructure spend occurred.
