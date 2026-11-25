# DigiArz — Production ↔ PostgreSQL 17 RPC parity manifest

**Status:** INCOMPLETE EVIDENCE REGISTER — REVIEW ONLY  
**Branch:** `feature/persian-asset-name-candidates-2026`  
**Snapshot baseline:** Production read-only catalog evidence dated 2026-11-25, encoded by `tests/rpc-security-catalog.sql`.  
**Purpose:** Track exact 46 SECURITY DEFINER function signatures and distinguish verified Production facts from fixture-only approximations.  
**Safety:** No SQL execution, grants, revokes, migration replay, deployment, data mutation, or default-ACL policy decision is authorized by this document.

## Interpretation rules

1. The 46 signatures and the three API-role EXECUTE booleans below are copied from the reviewed current-state catalog contract. They are not proposed target permissions.
2. The 40 functions still represented by NO-OP stubs in `rpc-security-postgres17-catalog-stubs.sql` are metadata-only. Their fixture `RETURNS void` declarations MUST NOT be treated as Production return types or function definitions.
3. Six functions have real/source-backed bodies in the current disposable fixture: `private.is_super_admin()`, `private.is_current_user_super_admin()`, `private.enforce_unique_admin_market_listing_symbol()`, `public.admin_exchange_asset_sync_report()`, `public.claim_admin_asset_refresh(text,uuid)`, and `public.get_exchange_discovered_market_assets()`. Their source provenance differs; see below.
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
| `private.enforce_unique_admin_market_listing_symbol()` | anon=false, authenticated=false, service_role=false | postgres (direct Production catalog) | `search_path=""` (direct Production catalog) | exact Production body; migration `20261113184000` matches | `trigger` (direct Production catalog) | `crypto_assets`, `admin_market_listings`, `demo_trading_pairs` | all three tables RLS=true/FORCE=false; public-read policies on crypto assets/demo pairs/listings as recorded below; trigger owner is postgres | exact `BEFORE INSERT OR UPDATE OF coingecko_id` trigger body; no API-role EXECUTE |
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
| `public.admin_search_market_assets(p_search text, p_limit integer)` | anon=false, authenticated=true, service_role=true (service_role origin unresolved) | Production owner per-signature snapshot not yet attached; source migration does not set owner | empty (`search_path=''` in source) | stub only; source recovered | TABLE with 7 named columns (see §2C) | `crypto_assets`, `auth.uid()`, `private.is_super_admin()` | migration revokes direct anon/authenticated table access to `admin_market_listings`; exact Production RLS/grants still need catalog verification | source-mapped read-only candidate; fixture body not promoted |
| `public.cancel_conditional_exit_order(p_order_id uuid)` | anon=false, authenticated=true, service_role=true | postgres (verified for service_role subset) | constrained (exact value per signature not yet captured) | stub only | not inspected from valid source | not mapped | not reviewed | NO-OP stub; RETURNS void is fixture-only and not Production evidence |
| `public.cancel_limit_order(p_order_id uuid)` | anon=false, authenticated=true, service_role=true | postgres (verified for service_role subset) | constrained (exact value per signature not yet captured) | stub only | not inspected from valid source | not mapped | not reviewed | NO-OP stub; RETURNS void is fixture-only and not Production evidence |
| `public.cancel_stop_limit_order(p_order_id uuid)` | anon=false, authenticated=true, service_role=true | postgres (verified for service_role subset) | constrained (exact value per signature not yet captured) | stub only | not inspected from valid source | not mapped | not reviewed | NO-OP stub; RETURNS void is fixture-only and not Production evidence |
| `public.claim_admin_asset_refresh(p_coingecko_id text, p_admin_user_id uuid)` | anon=false, authenticated=false, service_role=true | postgres (verified for service_role subset) | constrained (exact value per signature not yet captured) | real body | partial/source-specific | synthetic fixture dependencies only | not yet parity-tested | real Migration body in PG17 fixture |
| `public.current_account_is_active()` | anon=false, authenticated=true, service_role=true | postgres (verified for service_role subset) | constrained (exact value per signature not yet captured) | stub only | not inspected from valid source | not mapped | not reviewed | NO-OP stub; RETURNS void is fixture-only and not Production evidence |
| `public.deactivate_my_account()` | anon=false, authenticated=true, service_role=true | postgres (verified for service_role subset) | constrained (exact value per signature not yet captured) | stub only | not inspected from valid source | not mapped | not reviewed | NO-OP stub; RETURNS void is fixture-only and not Production evidence |
| `public.execute_demo_trade(p_symbol text, p_side text, p_amount numeric, p_price numeric)` | anon=false, authenticated=true, service_role=true | postgres (verified for service_role subset) | constrained (exact value per signature not yet captured) | stub only | not inspected from valid source | not mapped | not reviewed | NO-OP stub; RETURNS void is fixture-only and not Production evidence |
| `public.get_admin_market_listings()` | anon=true, authenticated=true, service_role=true | postgres (Production security review) | empty (`search_path=''`, Production review) | real Migration body | TABLE with 11 named columns (see §2) | `admin_market_listings`, `crypto_assets`, `market_prices` | `admin_market_listings` public-read RLS policy from migration; exact RLS/grants for other two dependencies not fully verified | source-backed read-only body; tested with synthetic market rows |
| `public.get_demo_trading_fee_rate(p_quote_asset text, p_liquidity_type text)` | anon=false, authenticated=true, service_role=true | postgres (verified for service_role subset) | constrained (exact value per signature not yet captured) | stub only | not inspected from valid source | not mapped | not reviewed | NO-OP stub; RETURNS void is fixture-only and not Production evidence |
| `public.get_exchange_discovered_market_assets()` | anon=true, authenticated=true, service_role=true (service_role is explicit test-only grant in fixture) | postgres (verified in disposable fixture; per-signature Production owner snapshot still desirable) | empty (`search_path=''` from exact source migration) | exact source Migration body installed | TABLE with 8 named columns (see §2B) | `exchange_asset_observations`, `admin_market_listings`, `crypto_assets`, `demo_trading_pairs`, `market_prices` | fixture RLS enabled on all five; full Production dependency RLS/grants remain unverified | standalone and shared PostgreSQL 17 tests; synthetic metadata only; rollback
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
| `private.enforce_unique_admin_market_listing_symbol()` | Current Production `pg_get_functiondef` captured 2026-11-25 and text-matched to migration `20261113184000_prevent_curated_ticker_collisions.sql` | Synthetic `crypto_assets`, `admin_market_listings`, and `demo_trading_pairs` tables; no external calls | Positive insert/update plus duplicate-symbol, pair-collision, and missing-asset rejection tests | Production trigger binding: `admin_market_listing_unique_ticker`, BEFORE INSERT OR UPDATE OF `coingecko_id`; no API-role EXECUTE |


For `private.enforce_unique_admin_market_listing_symbol()` the read-only dependency audit recorded:
- `crypto_assets`: RLS enabled, FORCE RLS off; `crypto_assets_public_read` policy for anon/authenticated; anon/authenticated SELECT and service_role ALL.
- `admin_market_listings`: RLS enabled, FORCE RLS off; `admin_market_listings_public_read` policy for anon/authenticated; service_role ALL, with no direct anon/authenticated table grant.
- `demo_trading_pairs`: RLS enabled, FORCE RLS off; `demo_trading_pairs_public_read` policy for anon/authenticated; anon/authenticated SELECT and service_role ALL.
- Trigger `admin_market_listing_unique_ticker` is attached BEFORE INSERT OR UPDATE OF `coingecko_id` on `public.admin_market_listings`.
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

**Current disposition (2026-11-25):** one stub was replaced with the exact current Production trigger body after matching `pg_get_functiondef` against its applied migration source. Its dependencies, RLS flags/policies, table ACLs, and trigger binding were inspected read-only. The new PostgreSQL 17 test uses synthetic market rows inside a transaction and rolls back. Forty inert stubs remain; each must pass the same source, signature, dependency, RLS, and side-effect gates before replacement.

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

- Baseline CI for the 46-signature metadata contract passed previously; five real bodies now exist in the disposable fixture, with 41 metadata-only stubs.
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


## Fixture coverage update — source-faithful curated-market read RPC

`public.get_admin_market_listings()` has now been promoted from metadata stub to the fifth real fixture body using the final reviewed migration source. The fixture includes synthetic, non-financial market metadata only; its read dependencies are `admin_market_listings`, `crypto_assets`, and `market_prices`. The function's exact TABLE return shape, STABLE flag, SECURITY DEFINER, empty search_path, and current effective API ACL are asserted. Role tests verify anon/authenticated/service_role access, active-listing filtering, fresh CoinGecko price visibility, stale-price redaction, and absence of direct anon SELECT on the underlying asset/price tables. All synthetic rows are transaction-scoped and rollback-checked.

Current fixture body count: **6 real bodies + 40 metadata-only stubs = 46 signatures**. Exact Production RLS/grants for all dependency tables remain only partially established; the fixture's table policies are explicitly a minimal model, not full RLS parity.


### CI evidence for the fifth body

GitHub Actions run #313 (`45603853118`) completed successfully on the updated PR branch. Both `unit-tests` and `postgres17-rpc-smoke` concluded success; the remote `rpc-security-integration` job remained intentionally skipped. The PostgreSQL 17 job completed the exact 46-signature ACL contract, the previous report/claim tests, the new `get_admin_market_listings()` role and price-freshness tests, and post-rollback checks confirming no synthetic market rows remain.


## 2B. Source mapping candidate: `public.get_exchange_discovered_market_assets()`

- Authoritative source recovered: `supabase/migrations/20261116200009_auto_list_unmatched_iran_exchange_assets.sql` (Git blob `901f6e3004a1fd51995ea159d840ce5b5b39dbeb`).
- Exact identity: `public.get_exchange_discovered_market_assets()`; source declares SQL, STABLE, SECURITY DEFINER, and `search_path=''`.
- Return shape: `TABLE(symbol text, name text, current_price_usd numeric, last_updated timestamptz, exchange_sources text, exchange_count integer, observed_at timestamptz, match_status text)`.
- Static dependency map from the source: `exchange_asset_observations` → recent active observations; exclusion joins to `admin_market_listings` + `crypto_assets`, and `demo_trading_pairs` + `crypto_assets`; optional fresh-price join to `market_prices`.
- Static side-effect review: the function body contains SELECT/CTE aggregation only; no INSERT/UPDATE/DELETE, HTTP, cron, financial ledger, wallet, order, trade, reservation, or balance side effect was found.
- Static filter review: 48-hour observation window; active rows; valid base symbol; pending/ambiguous/unmatched only; stock/equity/tokenized exclusions; exclude already curated or enabled pairs; aggregate distinct exchanges and preserve ambiguous status; only join positive market prices updated within two minutes.
- **Standalone PostgreSQL 17 source test passed.** The new isolated test database loads the exact migration file with `psql \ir` rather than copying/re-serializing the function body. PostgreSQL 17 successfully created the function, and anon/authenticated behavior, multi-exchange aggregation, ambiguous status, stale-price suppression, direct-table denial, PUBLIC ACL absence, and the migration's anon/authenticated grants all passed. The test transaction rolled back all synthetic metadata. The function was then promoted into the shared 46-signature fixture by dropping only its matching metadata stub and executing the exact source migration file; the shared fixture now contains 6 real bodies + 40 metadata-only stubs.
- ACL discrepancy: the reviewed current-state catalog contract records anon=true, authenticated=true, service_role=true. The cited migration explicitly revokes PUBLIC and grants anon/authenticated, but does not itself grant service_role. The origin of the observed service_role EXECUTE bit is unresolved. Do not infer a default-ACL cause or change any ACL/default privilege. Any future fixture reproduction must use an explicit test-only grant and label the source of the live bit unresolved.
- Full Production table owners, grants, RLS policies, and the per-function `proacl/proowner/proconfig` row remain to be attached before claiming complete parity.
- CI evidence: workflow run #372 (`45607071619`) on the source-test commit succeeded. Its PostgreSQL 17 job directly executed the migration in a fresh disposable database; the standalone source test completed `CREATE FUNCTION`, both role behavior blocks, ACL assertions, and `ROLLBACK` without errors. The remote RPC integration job remained skipped.

### Next safe step

Promote this function into the shared disposable 46-signature fixture using the proven source-file execution path, not a copied SQL body:
1. Add only the five minimal synthetic dependency tables/columns to the shared bootstrap, with RLS enabled and no direct anon table SELECT.
2. After loading the catalog stubs, drop only the matching `get_exchange_discovered_market_assets()` stub and execute the exact migration file from the PostgreSQL 17 container.
3. Apply a function-specific test-only EXECUTE grant to `service_role` only after the migration, solely to reproduce the observed current catalog snapshot; keep the source-level ACL test showing that the migration itself does not grant it.
4. Add exact return-shape/SECURITY DEFINER/search_path/owner/ACL contract assertions and role/rollback behavior tests. The shared fixture is now at 6 real bodies + 40 stubs after the new path passed.
5. The cause of the earlier shared-fixture parser failure remains unknown; do not attribute it to source or transfer without evidence.


## 2C. Source mapping candidate: `public.admin_search_market_assets(text, integer)`

- Authoritative source: `supabase/migrations/20261113172000_harden_admin_market_listing_access.sql` (Git blob `31adf046df44f04976d926280c062228db38c30e`). The migration also redefines `get_admin_market_listings()` and revokes direct anon/authenticated access to `admin_market_listings`; that broader migration side effect must be considered before replaying it in the shared fixture.
- Function identity: `public.admin_search_market_assets(p_search text, p_limit integer)`; PL/pgSQL, STABLE, SECURITY DEFINER, `search_path=''`. The source migration does not issue an explicit ALTER OWNER, so exact Production owner remains a catalog-evidence item rather than an assumption.
- Return shape: `TABLE(coingecko_id text, symbol text, name text, image_url text, market_cap_rank integer, current_price_usd numeric, last_updated timestamptz)`.
- Read dependencies: `public.crypto_assets`, `auth.uid()`, and `private.is_super_admin()`. The helper enforces a signed-in super-admin before returning any data. The body contains SELECT/RETURN QUERY only; no DML, HTTP, cron, wallet, order, trade, reservation, balance, or financial-ledger side effect.
- Filter behavior: trimmed search string must contain at least two characters; only active assets with positive current USD price updated within 24 hours; matches symbol/name/CoinGecko ID using ILIKE; requested limit is clamped to 1..50 (default 20); results sorted by market-cap rank.
- Source ACL: revokes PUBLIC and anon, grants authenticated. The reviewed current catalog snapshot additionally records service_role EXECUTE=true. The migration does not grant service_role; source of that effective bit is unresolved. Do not change Production ACL/default privileges.
- **Standalone PostgreSQL 17 source test passed.** CI run #399 (`45608422378`) executed the exact migration file in a fresh database and verified anon EXECUTE denial, authenticated EXECUTE, ordinary-user rejection, synthetic super-admin results, 24-hour freshness/active/positive-price filters, search validation, 1..50 limit clamping, no direct SELECT on `admin_market_listings`, and the source-level absence of a service_role grant. Synthetic asset rows were rolled back. The function is not yet promoted into the shared fixture.
- Promotion caution: this source migration also redefines `get_admin_market_listings()` using the earlier `crypto_assets.current_price_usd/last_updated` columns and revokes direct table SELECT from anon/authenticated. A later migration `20261113181000_show_live_prices_for_curated_assets.sql` replaces that listing body with the current `market_prices`-based projection. Any shared-fixture promotion must apply the two source migrations in chronological order (or otherwise isolate only the exact search-function definition with provenance), add the required synthetic columns, and then re-apply the later listing migration so the existing fifth body remains source-current. It must also model the service_role snapshot bit with a clearly labeled function-specific test-only grant.
