# Canonical prototype financial gap audit — 2026-11-28

**Status:** read-only source review. The canonical prototype is not eligible for promotion or for claims of financial parity.

Reviewed inputs:
- `supabase/tests/canonical_asset_identity_candidate.sql` (existing disposable prototype)
- `supabase/migrations/20261113161641_enforce_active_accounts_in_demo_trade_and_limit_engine.sql` (authoritative Market/Limit baseline)
- `docs/CANONICAL_MARKET_LIMIT_FINANCIAL_CONTRACT_2026-11-28.md`

## Confirmed gaps in the current prototype

| Contract area | Authoritative Market/Limit behavior | Prototype behavior | Required correction |
|---|---|---|---|
| Authentication/account | `auth.uid()`, active-account validation | caller supplies `p_user_id`; no auth/active profile gate | derive actor from auth context and enforce active account |
| Ledger | `wallets.balance_usdt` + `asset_balances` | generic `balances(user_id,asset_id)` | explicit canonical-ID-to-existing-ledger mapping; no parallel balance ledger |
| Market available funds | subtract outstanding reservations before spend | reads gross balance only | compute available balance including durable reservations |
| Fee | configured taker/maker fee helper | hard-coded 0.001 | use authoritative fee helper by quote and side |
| Market precision | gross and fee explicitly rounded to 8 decimals | unrounded numeric arithmetic | reproduce Market rounding and deployed column semantics |
| Price freshness | positive `market_prices.updated_at` within 1 minute | observed time within 2 minutes, permits 30 seconds future | exact one-minute boundary and reject future observations |
| Limit reserve lifecycle | durable reserved/consumed/released/status | simplified amount field; reservation deleted after fill | preserve cumulative reservation lifecycle and partial consumption |
| Limit fill cap | max 25% of original order amount per worker cycle | fills the entire order amount | enforce `LEAST(remaining_amount, original_amount * 0.25)` |
| Worker concurrency | advisory xact lock 739201126 + ordered `SKIP LOCKED` | `SKIP LOCKED` only; no advisory lock | reproduce global worker lock and authoritative ordering |
| Settlement/journal | existing wallet-first locks; trades and transactions per fill | generic balance changes and trade only | preserve wallet/base lock discipline and transaction journal |
| Conditional/cancel lifecycle | authoritative parent/child and reservation accounting | prototype-specific simplified tables | candidate canonical identity must integrate with authoritative lifecycle, not replace it |

## Important consequence

The prototype currently proves *identity isolation in its own simplified model* only. It does not prove that canonical IDs can be carried through the authoritative financial ledger without changing financial semantics. In particular, its successful four-cycle test cannot be treated as evidence of the authoritative 25%-per-cycle rule because its worker fills the full remaining amount in one pass.

## Safe implementation order

1. Keep the current prototype as a clearly labeled identity proof; do not adapt its generic balance table into a production design.
2. Extend the disposable authoritative fixture with canonical mapping tables and pair-keyed candidate functions only after designing a unique mapping from canonical asset IDs to existing legacy `asset_balances.asset` keys. Ambiguous mappings must fail closed.
3. Candidate Market and Limit entrypoints must operate on `wallets`, `asset_balances`, `order_reservations`, `orders`, `trades`, and `transactions` from the authoritative fixture.
4. Add assertions for reserved-fund exclusion, configured maker/taker fees, one-minute freshness, explicit Market precision, four-cycle Limit fills, cumulative reservation consumption/release, global advisory lock, and transaction journaling.
5. Only after those tests pass should duplicate-ticker isolation tests be ported onto the same canonical financial candidate. The exact current commit must then receive a successful PostgreSQL CI run.

## Release boundary

This audit made no SQL changes and executed no database. It authorizes no migration, Production write, db push, merge, rebase, worker/cron change, deployment, APK/Pages publication, or spend.
