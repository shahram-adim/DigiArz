# DigiArz exact-decimal database rollout plan

Status as of 2026-11-16: **candidate assembled and rehearsed in disposable PostgreSQL; not applied to Production**.

## Candidate bundle

- SQL: `supabase/drafts/2026-11-16_exact_decimal_rollout_candidate.sql`
- Scope:
  - widen base-asset/order/trade/reservation/conditional numeric columns to 18 decimal places;
  - keep `wallets.balance_usdt` and `transactions.amount` at 8 decimal places;
  - update Market/Limit/Stop-Limit/TP-SL placement RPC precision checks and settlement rounding;
  - update Limit worker gross/fee rounding and the small reserve cushion for repeated partial fills;
  - update Stop-Limit worker parent synchronization to lock the child row;
  - explicitly preserve the verified RPC/worker execution model through grants.
- Atomic behavior: `BEGIN`, `lock_timeout='5s'`, `statement_timeout='30s'`, data preflight, type changes, function replacements, grants, postflight checks, `COMMIT`.
- A lock conflict or failed preflight/postflight aborts the whole transaction.

## Verification already performed

- PostgreSQL 17 schema widening rehearsal, invalid-data rejection, lock-timeout atomicity, and mid-migration rollback.
- Entry-point tests for exact 18-place values and 8-place USDT settlement.
- Limit worker tests for four partial fills, exact trade quantities/prices, wallet and asset balances, and ledger reconciliation.
- Two-session Limit worker/cancellation races in both lock orders.
- Two-session Stop-Limit child execution/cancellation races in both lock orders.
- Stop-Limit child-fill versus parent-sync race.
- Two-session TP/SL execution/cancellation races in both lock orders.
- Combined rollout candidate rehearsal against disposable PostgreSQL.
- Per-fill USDT rounding regression at a boundary value that previously left a final fill short by (10^{-8}) USDT.
- No Production schema, function, reservation, order, or balance has been changed.

## Production transfer sequence

- Read-only SQL checklist: `supabase/drafts/2026-11-16_exact_decimal_live_preflight.sql` (SELECT-only; execute immediately before the migration).

1. Re-read Supabase migration history and confirm the chosen new migration name is unused.
2. Take/confirm a recoverable database backup or point-in-time recovery window before applying financial schema/function changes.
3. Re-run live preflight immediately before the migration:
   - counts and numeric range/scale for all widened tables;
   - reservation accounting and order amount accounting constraints;
   - dependent views/materialized views;
   - current column types and function signatures.
4. Apply only this one reviewed SQL bundle with the Supabase migration action (a single explicitly named migration). **Do not use `supabase db push` until the separate migration-history reconciliation is complete.**
5. Verify all 14 widened columns, unchanged 8-place USDT settlement columns, function definitions, SECURITY DEFINER/search_path, and exact EXECUTE grants.
6. Run read-only accounting checks and a controlled test account trade/limit/conditional lifecycle before normal use.

## Rollback

- If the SQL fails before commit, PostgreSQL transaction rollback leaves the database unchanged.
- After a successful commit, the safe rollback is restore from the confirmed backup/PITR point.
- A reverse precision migration is only safe if a fresh preflight proves every widened value has at most 8 fractional digits and all values fit the original numeric limits. It must refuse to run otherwise.
- Do not blindly downgrade numeric columns after 18-place orders or trades have been written.

## Migration-history caveat

`supabase/MIGRATION_RECONCILIATION.md` records 46 remote applied migrations, 33 local files, 13 missing source files, and 19 local filename prefixes that differ from the applied versions. This blocks a normal full `db push`, but does not require reapplying old migrations when the next release is executed as one explicit `apply_migration` operation. Do not edit remote history rows to hide the drift.


## Final handoff checkpoint — 2026-11-16 05:52 UTC

- Latest full exact-decimal CI run `43811668020`: **success** on commit `9e74074507a5075d6c5c875bdf620596b0a85872`.
- Latest Pages deployment run `43811667755`: **success** on the same commit.
- Supabase project status: `ACTIVE_HEALTHY`; PostgreSQL `17.11.0.018`, region `us-west-2`.
- Fresh read-only production preflight: all five target tables have 0 rows; all five invalid-row counters are 0; all six target function signatures exist; migration name `atomic_exact_decimal_rollout` is unused; no transaction older than 30 seconds was found.
- Fresh function privilege check: Market/Limit/Stop-Limit/conditional entry points are SECURITY DEFINER with empty search_path, executable by `authenticated` and `service_role`, not `anon`; both workers are executable only by `service_role`. The candidate explicitly preserves this matrix.
- Migration inventory remains 46 remote applied entries; the local-history drift report remains in force. Do not use `supabase db push`.
- Advisors snapshot: 1 existing anon-callable SECURITY DEFINER function (`get_admin_market_listings()`, public market-list use must be confirmed); 22 authenticated-callable SECURITY DEFINER functions; leaked-password protection warning; 9 unindexed foreign keys and 11 RLS init-plan performance findings. These are existing project-level findings outside this precision migration's scope; no blanket permission changes are included.
- **Backup/PITR availability is not exposed by the connected project-inspection tool**, so it has not been verified. Immediately before transfer, confirm a recent restorable backup/PITR point in Supabase Dashboard; if unavailable, export a backup first. This is the sole operational release gate not yet independently verified here.
- Production remains unchanged.


## Final candidate hardening — 2026-11-16

- The migration now takes `ACCESS EXCLUSIVE` locks on all five target tables before its internal preflight, preventing a concurrent writer from inserting out-of-contract rows between validation and the type changes. It fails closed after a 5-second lock timeout.
- Internal preflight also enforces `orders.filled_amount + remaining_amount = amount` and `order_reservations.consumed_amount + released_amount <= reserved_amount`, plus positive reservation amounts and numeric range/scale limits.
- Postflight verifies all 14 widened columns individually and explicitly confirms the two USDT settlement columns remain `numeric(24,8)`.
- Final hardened candidate commit: `36c16b588fbce373e4d281da54c53841bab9973d`.
- Final full CI: [run 43813355851](https://github.com/shahram-adim/DigiArz/actions/runs/43813355851) — **success**.
- Final Pages deployment: [run 43813355394](https://github.com/shahram-adim/DigiArz/actions/runs/43813355394) — **success**.
- No Production database changes have been made. Backup/PITR verification remains a required operational gate immediately before execution.
