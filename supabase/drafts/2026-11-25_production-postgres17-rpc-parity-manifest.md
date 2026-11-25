# DigiArz — Production ↔ PostgreSQL 17 RPC parity manifest

**Status:** INCOMPLETE EVIDENCE REGISTER — REVIEW ONLY  
**Branch:** `feature/persian-asset-name-candidates-2026`  
**Snapshot baseline:** Production read-only catalog evidence dated 2026-11-25, encoded by `tests/rpc-security-catalog.sql`.  
**Purpose:** Track exact 46 SECURITY DEFINER function signatures and distinguish verified Production facts from fixture-only approximations.  
**Safety:** No SQL execution, grants, revokes, migration replay, deployment, data mutation, or default-ACL policy decision is authorized by this document.

## Interpretation rules

1. The 46 signatures and the three API-role EXECUTE booleans below are copied from the reviewed current-state catalog contract. They are not proposed target permissions.
2. The 42 functions represented by NO-OP stubs in `rpc-security-postgres17-catalog-stubs.sql` are metadata-only. Their fixture `RETURNS void` declarations MUST NOT be treated as Production return types or function definitions.
3. Four functions have real bodies in the current disposable fixture: `private.is_super_admin()`, `private.is_current_user_super_admin()`, `public.admin_exchange_asset_sync_report()`, and `public.claim_admin_asset_refresh(text,uuid)`. Their source provenance differs; see below.
4. For the 36 signatures with effective `service_role` EXECUTE, the prior read-only Production audit reports owner `postgres` and constrained `search_path` (either empty or `pg_catalog`). The exact per-function search_path values are not in the current manifest evidence and are not guessed. For the other 10, owner and per-function path need direct evidence.
5. Table dependencies, column dependencies, referenced functions, RLS policies, and table privileges are not inferred from names or stub code. They remain open until exact Production definitions and catalog dependency evidence are captured.
6. No fixture is considered full Supabase parity: this is PostgreSQL 17 with synthetic roles and minimal tables; Auth/JWT, pg_net, pg_cron, extension behavior, RLS policies and grants are not comprehensively reproduced.

## 1. Exact-signature register (46)

| Exact identity signature | Current API EXECUTE snapshot | Owner evidence | search_path evidence | Fixture body | Return type evidence | Dependencies | RLS/table grants | Fixture note |
|---|---|---|---|---|---|---|---|---|
| `private.admin_adjust_wallet(p_user_id uuid, p_currency text, p_direction text, p_amount numeric, p_reason text)` | anon=false, authenticated=true, service_role=false | not individually recorded | constrained (exact value per signature not yet captured) | stub only | not inspected from valid source | not mapped | not reviewed | NO-OP stub; RETURNS void is fixture-only and not Production evidence |
| `private.admin_list_users()` | anon=false, authenticated=true, service_role=false | not individually recorded | constrained (exact value per signature not yet captured) | stub only | not inspected from valid source | not mapped | not reviewed | NO-OP stub; RETURNS void is fixture-only and not Production evidence |
| `private.auto_activate_verified_exchange_pairs()` | anon=false, authenticated=false, service_role=false | not individually recorded | constrained (exact value per signature not yet captured) | stub only | not inspected from valid source | not mapped | not reviewed | NO-OP stub; RETURNS void is fixture-only and not Production evidence |
| `private.auto_list_verified_exchange_asset()` | anon=false, authenticated=false, service_role=false | not individually recorded | constrained (exact value per signature not yet captured) | stub only | not inspected from valid source | not mapped | not reviewed | NO-OP stub; RETURNS void is fixture-only and not Production evidence |
| `private.enforce_unique_admin_market_listing_symbol()` | anon=false, authenticated=false, service_role=false | not individually recorded | constrained (exact value per signature not yet captured) | stub only | not inspected from valid source | not mapped | not reviewed | NO-OP stub; RETURNS void is fixture-only and not Production evidence |
| `private.guard_active_account_writes()` | anon=false, authenticated=false, service_role=false | not individually recorded | constrained (exact value per signature not yet captured) | stub only | not inspected from valid source | not mapped | not reviewed | NO-OP stub; RETURNS void is fixture-only and not Production evidence |
| `private.is_current_user_super_admin()` | anon=false, authenticated=true, service_role=false | not individually recorded | constrained (exact value per signature not yet captured) | real body | partial/source-specific | synthetic fixture dependencies only | not yet parity-tested | real reviewed body in PG17 fixture |
| `private.is_super_admin()` | anon=false, authenticated=false, service_role=false | not individually recorded | constrained (exact value per signature not yet captured) | real body | partial/source-specific | synthetic fixture dependencies only | not yet parity-tested | real reviewed body in PG17 fixture |
| `private.request_market_price_overflow()` | anon=false, authenticated=false, service_role=false | not individually recorded | constrained (exact value per signature not yet captured) | stub only | not inspected from valid source | not mapped | not reviewed | NO-OP stub; RETURNS void is fixture-only and not Production evidence |
| `public.admin_add_market_listing(p_coingecko_id text)` | anon=false, authenticated=true, service_role=true | postgres (verified for service_role subset) | constrained (exact value per signature not yet captured) | stub only | not inspected from valid source | not mapped | not reviewed | NO-OP stub; RETURNS void is fixture-only and not Production evidence |
| `public.admin_disable_market_pair(p_coingecko_id text, p_reason text)` | anon=false, authenticated=true, service_role=true | postgres (verified for service_role subset) | constrained (exact value per signature not yet captured) | stub only | not inspected from valid source | not mapped | not reviewed | NO-OP stub; RETURNS void is fixture-only and not Production evidence |
| `public.admin_enable_market_pair(p_coingecko_id text)` | anon=false, authenticated=true, service_role=true | postgres (verified for service_role subset) | constrained (exact value per signature not yet captured) | stub only | not inspected from valid source | not mapped | not reviewed | NO-OP stub; RETURNS void is fixture-only and not Production evidence |
| `public.admin_exchange_asset_sync_report()` | anon=false, authenticated=true, service_role=true | postgres (verified for service_role subset) | constrained (exact value per signature not yet captured) | real body | partial/source-specific | synthetic fixture dependencies only | not yet parity-tested | real reviewed body in PG17 fixture |
| `public.admin_remove_market_listing(p_coingecko_id text)` | anon=false, authenticated=true, service_role=true | postgres (verified for service_role subset) | constrained (exact value per signature not yet captured) | stub only | not inspected from valid source | not mapped | not reviewed | NO-OP stub; RETURNS void is fixture-only and not Production evidence |
| `public.admin_request_exchange_asset_sync()` | anon=false, authenticated=true, service_role=true | postgres (verified for service_role subset) | constrained (exact value per signature not yet captured) | stub only | not inspected from valid source | not mapped | not reviewed | NO-OP stub; RETURNS void is fixture-only and not Production evidence |
| `public.admin_review_market_listings()` | anon=false, authenticated=true, service_role=true | postgres (verified for service_role subset) | constrained (exact value per signature not yet captured) | stub only | not inspected from valid source | not mapped | not reviewed | NO-OP stub; RETURNS void is fixture-only and not Production evidence |
| `public.admin_search_market_assets(p_search text, p_limit integer)` | anon=false, authenticated=true, service_role=true | postgres (verified for service_role subset) | constrained (exact value per signature not yet captured) | stub only | not inspected from valid source | not mapped | not reviewed | NO-OP stub; RETURNS void is fixture-only and not Production evidence |
| `public.cancel_conditional_exit_order(p_order_id uuid)` | anon=false, authenticated=true, service_role=true | postgres (verified for service_role subset) | constrained (exact value per signature not yet captured) | stub only | not inspected from valid source | not mapped | not reviewed | NO-OP stub; RETURNS void is fixture-only and not Production evidence |
| `public.cancel_limit_order(p_order_id uuid)` | anon=false, authenticated=true, service_role=true | postgres (verified for service_role subset) | constrained (exact value per signature not yet captured) | stub only | not inspected from valid source | not mapped | not reviewed | NO-OP stub; RETURNS void is fixture-only and not Production evidence |
| `public.cancel_stop_limit_order(p_order_id uuid)` | anon=false, authenticated=true, service_role=true | postgres (verified for service_role subset) | constrained (exact value per signature not yet captured) | stub only | not inspected from valid source | not mapped | not reviewed | NO-OP stub; RETURNS void is fixture-only and not Production evidence |
| `public.claim_admin_asset_refresh(p_coingecko_id text, p_admin_user_id uuid)` | anon=false, authenticated=false, service_role=true | postgres (verified for service_role subset) | constrained (exact value per signature not yet captured) | real body | partial/source-specific | synthetic fixture dependencies only | not yet parity-tested | real Migration body in PG17 fixture |
| `public.current_account_is_active()` | anon=false, authenticated=true, service_role=true | postgres (verified for service_role subset) | constrained (exact value per signature not yet captured) | stub only | not inspected from valid source | not mapped | not reviewed | NO-OP stub; RETURNS void is fixture-only and not Production evidence |
| `public.deactivate_my_account()` | anon=false, authenticated=true, service_role=true | postgres (verified for service_role subset) | constrained (exact value per signature not yet captured) | stub only | not inspected from valid source | not mapped | not reviewed | NO-OP stub; RETURNS void is fixture-only and not Production evidence |
| `public.execute_demo_trade(p_symbol text, p_side text, p_amount numeric, p_price numeric)` | anon=false, authenticated=true, service_role=true | postgres (verified for service_role subset) | constrained (exact value per signature not yet captured) | stub only | not inspected from valid source | not mapped | not reviewed | NO-OP stub; RETURNS void is fixture-only and not Production evidence |
| `public.get_admin_market_listings()` | anon=true, authenticated=true, service_role=true | postgres (Production security review) | empty (`search_path=''`, Production review) | real Migration body | TABLE with 11 named columns (see §2) | `admin_market_listings`, `crypto_assets`, `market_prices` | `admin_market_listings` public-read RLS policy from migration; exact RLS/grants for other two dependencies not fully verified | source-backed read-only body; tested with synthetic market rows |
| `public.get_demo_trading_fee_rate(p_quote_asset text, p_liquidity_type text)` | anon=false, authenticated=true, service_role=true | postgres (verified for service_role subset) | constrained (exact value per signature not yet captured) | stub only | not inspected from valid source | not mapped | not reviewed | NO-OP stub; RETURNS void is fixture-only and not Production evidence |
| `public.get_exchange_discovered_market_assets()` | anon=true, authenticated=true, service_role=true | postgres (verified for service_role subset) | constrained (exact value per signature not yet captured) | stub only | not inspected from valid source | not mapped | not reviewed | NO-OP stub; RETURNS void is fixture-only and not Production evidence |
| `public.get_my_order_reservations(p_order_ids uuid[])` | anon=false, authenticated=true, service_role=true | postgres (verified for service_role subset) | constrained (exact value per signature not yet captured) | stub only | not inspected from valid source | not mapped | not reviewed | NO-OP stub; RETURNS void is fixture-only and not Production evidence |
| `public.new_user_setup()` | anon=false, authenticated=false, service_role=true | postgres (verified for service_role subset) | constrained (exact value per signature not yet captured) | stub only | not inspected from valid source | not mapped | not reviewed | NO-OP stub; RETURNS void is fixture-only and not Production evidence |
| `public.place_conditional_exit_order(p_symbol text, p_order_kind text, p_amount numeric, p_trigger_price numeric)` | anon=false, authenticated=true, service_role=true | postgres (verified for service_role subset) | constrained (exact value per signature not yet captured) | stub only | not inspected from valid source | not mapped | not reviewed | NO-OP stub; RETURNS void is fixture-only and not Production evidence |
| `public.place_limit_order(p_symbol text, p_side text, p_amount numeric, p_limit_price numeric)` | anon=false, authenticated=true, service_role=true | postgres (verified for service_role subset) | constrained (exact value per signature not yet captured) | stub only | not inspected from valid source | not mapped | not reviewed | NO-OP stub; RETURNS void is fixture-only and not Production evidence |
| `public.place_stop_limit_order(p_symbol text, p_side text, p_amount numeric, p_stop_price numeric, p_limit_price numeric)` | anon=false, authenticated=true, service_role=true | postgres (verified for service_role subset) | constrained (exact value per signature not yet captured) | stub only | not inspected from valid source | not mapped | not reviewed | NO-OP stub; RETURNS void is fixture-only and not Production evidence |
| `public.process_bit24_exchange_sync()` | anon=false, authenticated=false, service_role=true | postgres (verified for service_role subset) | constrained (exact value per signature not yet captured) | stub only | not inspected from valid source | not mapped | not reviewed | NO-OP stub; RETURNS void is fixture-only and not Production evidence |
| `public.process_conditional_orders()` | anon=false, authenticated=false, service_role=true | postgres (verified for service_role subset) | constrained (exact value per signature not yet captured) | stub only | not inspected from valid source | not mapped | not reviewed | NO-OP stub; RETURNS void is fixture-only and not Production evidence |
| `public.process_iran_exchange_asset_sync()` | anon=false, authenticated=false, service_role=true | postgres (verified for service_role subset) | constrained (exact value per signature not yet captured) | stub only | not inspected from valid source | not mapped | not reviewed | NO-OP stub; RETURNS void is fixture-only and not Production evidence |
| `public.process_limit_orders()` | anon=false, authenticated=false, service_role=true | postgres (verified for service_role subset) | constrained (exact value per signature not yet captured) | stub only | not inspected from valid source | not mapped | not reviewed | NO-OP stub; RETURNS void is fixture-only and not Production evidence |
| `public.process_stop_limit_orders()` | anon=false, authenticated=false, service_role=true | postgres (verified for service_role subset) | constrained (exact value per signature not yet captured) | stub only | not inspected from valid source | not mapped | not reviewed | NO-OP stub; RETURNS void is fixture-only and not Production evidence |
| `public.reactivate_my_account()` | anon=false, authenticated=true, service_role=true | postgres (verified for service_role subset) | constrained (exact value per signature not yet captured) | stub only | not inspected from valid source | not mapped | not reviewed | NO-OP stub; RETURNS void is fixture-only and not Production evidence |
| `public.recover_stale_crypto_assets_sync()` | anon=false, authenticated=false, service_role=true | postgres (verified for service_role subset) | constrained (exact value per signature not yet captured) | stub only | not inspected from valid source | not mapped | not reviewed | NO-OP stub; RETURNS void is fixture-only and not Production evidence |
| `public.refresh_crypto_assets()` | anon=false, authenticated=false, service_role=true | postgres (verified for service_role subset) | constrained (exact value per signature not yet captured) | stub only | not inspected from valid source | not mapped | not reviewed | NO-OP stub; RETURNS void is fixture-only and not Production evidence |
| `public.refresh_crypto_assets_toman()` | anon=false, authenticated=false, service_role=true | postgres (verified for service_role subset) | constrained (exact value per signature not yet captured) | stub only | not inspected from valid source | not mapped | not reviewed | NO-OP stub; RETURNS void is fixture-only and not Production evidence |
| `public.refresh_market_fx_rate()` | anon=false, authenticated=false, service_role=true | postgres (verified for service_role subset) | constrained (exact value per signature not yet captured) | stub only | not inspected from valid source | not mapped | not reviewed | NO-OP stub; RETURNS void is fixture-only and not Production evidence |
| `public.refresh_market_prices()` | anon=false, authenticated=false, service_role=false | not individually recorded | constrained (exact value per signature not yet captured) | stub only | not inspected from valid source | not mapped | not reviewed | NO-OP stub; RETURNS void is fixture-only and not Production evidence |
| `public.request_bit24_exchange_sync()` | anon=false, authenticated=false, service_role=true | postgres (verified for service_role subset) | constrained (exact value per signature not yet captured) | stub only | not inspected from valid source | not mapped | not reviewed | NO-OP stub; RETURNS void is fixture-only and not Production evidence |
| `public.request_iran_exchange_asset_sync()` | anon=false, authenticated=false, service_role=true | postgres (verified for service_role subset) | constrained (exact value per signature not yet captured) | stub only | not inspected from valid source | not mapped | not reviewed | NO-OP stub; RETURNS void is fixture-only and not Production evidence |
| `public.request_market_price_refresh()` | anon=false, authenticated=true, service_role=true | postgres (verified for service_role subset) | constrained (exact value per signature not yet captured) | stub only | not inspected from valid source | not mapped | not reviewed | NO-OP stub; RETURNS void is fixture-only and not Production evidence |

## 2. Real-body provenance and limits

| Function | Source provenance | Fixture dependency model | Current test scope | Remaining gap |
|---|---|---|---|---|
| `private.is_super_admin()` | Reviewed body copied into bootstrap; uses `auth.uid()` and `private.admin_users` | Synthetic Auth shim + synthetic admin table | Helper path used by admin report/claim guard | Confirm exact current Production definition, owner, ACL, path and all dependent policies |
| `private.is_current_user_super_admin()` | Reviewed body copied into bootstrap; calls `auth.uid()` and `private.is_super_admin()` | Same synthetic Auth/admin objects | Used by admin report guard | Confirm exact Production definition and direct/indirect dependency graph |
| `public.admin_exchange_asset_sync_report()` | Production definition captured via `pg_get_functiondef` on 2026-11-25 | Empty synthetic reporting tables: observations, listings, sync request tables | anon and ordinary authenticated denied; synthetic super-admin can read JSON report | Full source dependency, table ACL/RLS, schema/function dependency parity not yet demonstrated |
| `public.claim_admin_asset_refresh(text,uuid)` | Migration `20261113190000_admin_on_demand_crypto_asset_refresh.sql` | Synthetic `private.admin_asset_refresh_limits` + synthetic admin identity | positive service_role call, non-admin 42501, invalid input 22023, cooldown 55000; rollback checked | Edge Function not executed in harness; validate migration/source hash and exact live definition before claiming full parity |

## 3. Known caller classifications

- Browser/session call sites are recorded in `2026-11-25_rpc-caller-inventory.md`; this is source scanning, not proof of successful invocation.
- The deployed Edge Function `admin-refresh-crypto-asset` v2 is the confirmed source-level caller for `claim_admin_asset_refresh(text,uuid)`; it validates the bearer token and super-admin status before invoking through a service-role client.
- Cron jobs observed under `username='postgres'` are not evidence that `service_role` needs EXECUTE. Preserve worker schedules and behavior; do not disable/slow them.
- Auth trigger `new_user_setup()` is observed via the Auth users trigger; verify trigger definition and function source before modeling in the fixture.

## 4. Dependency/RLS completion checklist

For each of the 46 exact signatures, collect and attach:
- [ ] `pg_get_functiondef(oid)` (stored securely in the review artifact; redact secrets if any).
- [ ] `pg_get_function_identity_arguments(oid)`, `pg_get_function_result(oid)`, `proowner` resolved to role name, `prolang`, `provolatile`, `prosecdef`, `proconfig`.
- [ ] `proacl` plus effective privileges for PUBLIC, anon, authenticated, service_role and owner; do not alter them.
- [ ] `pg_depend` edges and parsed relation/function references from the body (catalog dependency tracking alone does not capture all dynamic SQL).
- [ ] For every referenced table/view: owner, grants, RLS enabled/forced flags, policies, sequence grants, and relevant constraints/indexes.
- [ ] Trigger bindings and pg_cron job identity/schedule for invoked functions, without altering jobs.
- [ ] Positive and negative behavior tests with synthetic identities and synthetic-only rows, with explicit rollback/cleanup assertions.

## 5. Stub replacement gate

A stub may be replaced only when all are true:
1. A source of truth is available (current `pg_get_functiondef` snapshot or an exact, verified migration source).
2. Exact identity arguments, return type, owner, language, volatility, SECURITY DEFINER and search_path are reconciled.
3. Every table/function/extension/sequence dependency is identified and represented safely in the disposable fixture.
4. RLS and table privileges are modeled; any missing Supabase-specific behavior is explicitly marked and not claimed as tested.
5. The function can be tested without live external HTTP, real users, wallets, balances, orders, trades, or persistent financial rows. If not, do not invoke it; use a static contract test only.
6. Tests cover caller role, function-level authorization, error paths, side effects and rollback.
7. CI passes on PostgreSQL 17, and the manifest is updated with evidence links/commit hashes.

**Current disposition:** no additional stub was replaced in this step. The next candidate must be selected by source availability and safety, not by function name or apparent simplicity.

## 6. Migration source recovery — unresolved

The repository evidence has two dated inventory snapshots that must not be conflated:

- The 2026-11-17 reconciliation snapshot listed 14 missing sources and 20 timestamp mismatches.
- The 2026-11-22/25 checkpoint in `IMPLEMENTATION_STATUS.md` adds three applied Production entries dated 2026-11-21, taking the tracked missing-source count to 17 (14 earlier + 3 later). The three added versions are:
  - `20261121045434` — `digiarz_backpressure_and_exchange_sync_bloat_guards`
  - `20261121045531` — `snapshot_pg_net_unlogged_queue_before_recovery`
  - `20261121050216` — `temporarily_throttle_exchange_asset_processors_20261121`

The 14 earlier missing versions recorded in the 2026-11-17 inventory are:
- `20261113153808` — `approved_wallet_defaults_fees_and_coin_reviews`
- `20261113154323` — `assign_confirmed_super_admin`
- `20261113154736` — `secure_admin_wallet_management`
- `20261113154750` — `add_admin_role_probe`
- `20261113154844` — `use_toman_units_in_admin_credit_ui`
- `20261113154926` — `move_admin_privilege_logic_to_private_schema`
- `20261115101709` — `create_exchange_asset_observations`
- `20261115102729` — `schedule_iran_exchange_asset_sync`
- `20261115102927` — `fix_exchange_sync_response_json_cast`
- `20261115103227` — `auto_list_verified_exchange_assets`
- `20261115103507` — `schedule_bit24_exchange_asset_sync`
- `20261115105721` — `admin_exchange_asset_sync_monitoring`
- `20261115105956` — `restrict_exchange_sync_worker_execution`
- `20261116201639` — `auto_activate_verified_exchange_pairs`

The 2026-11-17 inventory itself reports 20 timestamp-prefix mismatches, two local-only files, and four exact matches at that snapshot. The current ledger/file inventory must be refreshed before treating those counts as current. The full SQL source of the three later entries is partially preserved in `2026-11-25_recovered-production-migration-sources.md`, but it is not a complete canonical migration set. Recover exact sources from authoritative deployment/backup evidence, compare full content and checksums, and do not replay any recovered SQL.

## 7. Default ACL policy

Owner decision remains OPEN. Do not run `GRANT`, `REVOKE`, `ALTER DEFAULT PRIVILEGES`, migration, or db push to change default `service_role` EXECUTE. Existing function-specific grants and active worker paths remain unchanged.

## 8. Latest checkpoint

- Baseline CI for the 46-signature metadata contract passed previously; four real bodies now exist in the disposable fixture, with 42 metadata-only stubs.
- CI #277 passed after the claim rollback post-check: https://github.com/shahram-adim/DigiArz/actions/runs/45600722397
- This manifest is an evidence tracker, not proof that all fields are complete or that Production parity is achieved.


### Exact return types established for the four real fixture bodies

| Function | Return type in reviewed source |
|---|---|
| `private.is_super_admin()` | `boolean` |
| `private.is_current_user_super_admin()` | `boolean` |
| `public.admin_exchange_asset_sync_report()` | `jsonb` |
| `public.claim_admin_asset_refresh(text,uuid)` | `boolean` |

These four types are source-backed for the reviewed fixture bodies only. The remaining 42 Production return types are still unknown in this artifact; their fixture `void` type is deliberately excluded as evidence.


## 2A. Additional source-backed body: `public.get_admin_market_listings()`

- Authoritative source: `supabase/migrations/20261113181000_show_live_prices_for_curated_assets.sql`; the prior Production security review independently records the live owner as `postgres`, `STABLE SECURITY DEFINER`, empty search_path, anon/authenticated execution, and the same three read-only table dependencies.
- Return shape: 11 columns — CoinGecko ID, symbol, name, image URL, market-cap rank, current USD price, toman price, 24-hour percentage, USD volume, price timestamp, listing timestamp.
- The USD price is returned only when the market-price row is positive, sourced from CoinGecko, and updated within the last two minutes; otherwise the function returns NULL for that price.
- The disposable fixture now defines only the required synthetic columns for `crypto_assets` and `market_prices`, enables RLS on its three synthetic dependencies, and grants no direct base-table SELECT to anon. The curated listing table has the source migration's public-read policy. This is a narrow fixture, not proof of exact RLS parity for all three Production tables.
- Tests exercise anon, authenticated and service_role reads; inactive listings are omitted; fresh CoinGecko USD price is visible; stale price is redacted; direct anon table SELECT remains unavailable. All inserted rows are synthetic non-financial market metadata and the transaction rolls back.
- The current effective service_role EXECUTE bit is reproduced explicitly in this disposable fixture to match the read-only catalog snapshot. No default privileges are altered.
