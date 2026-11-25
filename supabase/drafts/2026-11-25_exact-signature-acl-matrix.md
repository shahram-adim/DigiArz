# DigiArz — Exact-Signature SECURITY DEFINER ACL Matrix

**Status:** REVIEW DRAFT — NO SQL / NO PRIVILEGE CHANGE  
**Evidence date:** 2026-11-25  
**Source:** `2026-11-25_rpc-caller-inventory.md` and read-only Production catalog audit  
**Related PR:** #62

## 1. Scope and interpretation

This matrix records the 36 exact function signatures for which the Production audit found effective `service_role` EXECUTE. It is a current-state evidence matrix, not a target-state migration and not authorization to revoke any privilege.

Shared verified properties for all 36 rows:
- schema: `public`;
- owner: `postgres`;
- `SECURITY DEFINER`: yes;
- `search_path`: explicitly constrained to either empty string (`search_path=""`) or `pg_catalog`; the source snapshot does not map which of these two values belongs to each individual signature, so no per-row value is guessed;
- no function was invoked during the catalog audit.

Effective API role summary:
- 23 signatures: `authenticated` + `service_role`;
- among those 23, two market-metadata read endpoints are also executable by `anon`;
- 13 signatures: `service_role` only among API roles;
- `postgres` is the observed owner/execution identity for Cron and Auth-trigger paths; it is not an API-role grant.

## 2. Current Production signature matrix

| Exact identity signature | Current API EXECUTE roles | Observed caller / evidence | Caller-path conclusion |
|---|---|---|---|
| `public.admin_add_market_listing(text)` | authenticated, service_role | Browser `.rpc()` inventory | User-session RPC; inspect body authorization before any ACL change |
| `public.admin_disable_market_pair(text,text)` | authenticated, service_role | Browser `.rpc()` inventory | User-session RPC; inspect body authorization before any ACL change |
| `public.admin_enable_market_pair(text)` | authenticated, service_role | Browser `.rpc()` inventory | User-session RPC; inspect body authorization before any ACL change |
| `public.admin_exchange_asset_sync_report()` | anon, authenticated, service_role | Browser `.rpc()` inventory; integration test exercises function-body guard | Anon and ordinary-user denial must be tested at function-body level; catalog grant is currently present |
| `public.admin_remove_market_listing(text)` | authenticated, service_role | Browser `.rpc()` inventory | User-session RPC; inspect body authorization before any ACL change |
| `public.admin_request_exchange_asset_sync()` | authenticated, service_role | Browser `.rpc()` inventory; body calls two request functions as postgres-owned SECURITY DEFINER | User-session RPC; nested child calls do not establish a service_role client caller |
| `public.admin_review_market_listings()` | authenticated, service_role | Browser `.rpc()` inventory | User-session RPC; inspect body authorization before any ACL change |
| `public.admin_search_market_assets(text,integer)` | authenticated, service_role | Browser `.rpc()` inventory | User-session RPC; inspect body authorization before any ACL change |
| `public.cancel_conditional_exit_order(uuid)` | authenticated, service_role | Browser `.rpc()` inventory | User-session order lifecycle RPC |
| `public.cancel_limit_order(uuid)` | authenticated, service_role | Browser `.rpc()` inventory | User-session order lifecycle RPC |
| `public.cancel_stop_limit_order(uuid)` | authenticated, service_role | Browser `.rpc()` inventory | User-session order lifecycle RPC |
| `public.current_account_is_active()` | authenticated, service_role | Browser `.rpc()` inventory | User-session account RPC |
| `public.deactivate_my_account()` | authenticated, service_role | Browser `.rpc()` inventory | User-session account lifecycle RPC |
| `public.execute_demo_trade(text,text,numeric,numeric)` | authenticated, service_role | Browser `.rpc()` inventory | User-session demo-trading RPC |
| `public.get_admin_market_listings()` | anon, authenticated, service_role | Browser `.rpc()` inventory | Public metadata/read endpoint plus authenticated client path |
| `public.get_demo_trading_fee_rate(text,text)` | authenticated, service_role | Browser `.rpc()` inventory | User-session read RPC |
| `public.get_exchange_discovered_market_assets()` | anon, authenticated, service_role | Browser `.rpc()` inventory | Public market metadata endpoint plus authenticated client path |
| `public.get_my_order_reservations(uuid[])` | authenticated, service_role | Browser `.rpc()` inventory | User-session order read RPC |
| `public.place_conditional_exit_order(text,text,numeric,numeric)` | authenticated, service_role | Browser `.rpc()` inventory | User-session order lifecycle RPC |
| `public.place_limit_order(text,text,numeric,numeric)` | authenticated, service_role | Browser `.rpc()` inventory | User-session order lifecycle RPC |
| `public.place_stop_limit_order(text,text,numeric,numeric,numeric)` | authenticated, service_role | Browser `.rpc()` inventory | User-session order lifecycle RPC |
| `public.reactivate_my_account()` | authenticated, service_role | Browser `.rpc()` inventory | User-session account lifecycle RPC |
| `public.request_market_price_refresh()` | authenticated, service_role | Browser `.rpc()` inventory | User-session market refresh request RPC |
| `public.claim_admin_asset_refresh(text,uuid)` | service_role | No caller found in browser, reviewed Edge Functions, DB function bodies, Cron jobs, or application triggers | **UNRESOLVED**; explicit grant is unexplained. Do not revoke until external/manual callers and intended rate-limit design are checked |
| `public.new_user_setup()` | service_role | Enabled `auth.users.on_auth_user_created` trigger | Trigger executes in postgres-owned context; observed path does not require service_role EXECUTE |
| `public.process_bit24_exchange_sync()` | service_role | Active Cron job, `username='postgres'`, schedule 16,46 | Observed Cron path does not require service_role EXECUTE |
| `public.process_conditional_orders()` | service_role | Active Cron job, `username='postgres'`, every minute | Observed Cron path does not require service_role EXECUTE; preserve worker behavior |
| `public.process_iran_exchange_asset_sync()` | service_role | Active Cron job, `username='postgres'`, schedule 1,31 | Observed Cron path does not require service_role EXECUTE |
| `public.process_limit_orders()` | service_role | Active Cron job, `username='postgres'`, every minute | Observed Cron path does not require service_role EXECUTE; preserve worker behavior |
| `public.process_stop_limit_orders()` | service_role | Active Cron job, `username='postgres'`, every minute | Observed Cron path does not require service_role EXECUTE; preserve worker behavior |
| `public.recover_stale_crypto_assets_sync()` | service_role | Active Cron job, `username='postgres'`, every 5 minutes | Observed Cron path does not require service_role EXECUTE |
| `public.refresh_crypto_assets()` | service_role | Active Cron job, `username='postgres'`, minutes 6,16,26,36,46,56 | Observed Cron path does not require service_role EXECUTE |
| `public.refresh_crypto_assets_toman()` | service_role | Active Cron job, `username='postgres'`, minutes 7,17,27,37,47,57 | Observed Cron path does not require service_role EXECUTE |
| `public.refresh_market_fx_rate()` | service_role | Active Cron job, `username='postgres'`, every minute | Observed Cron path does not require service_role EXECUTE |
| `public.request_bit24_exchange_sync()` | service_role | Active Cron job, `username='postgres'`; also nested from postgres-owned `admin_request_exchange_asset_sync()` | Observed Cron/nested paths do not require service_role EXECUTE |
| `public.request_iran_exchange_asset_sync()` | service_role | Active Cron job, `username='postgres'`; also nested from postgres-owned `admin_request_exchange_asset_sync()` | Observed Cron/nested paths do not require service_role EXECUTE |

## 3. Important exclusions and corrections

- `public.refresh_market_prices()` is **not** one of the 36 service_role-executable functions. Its exact ACL currently grants EXECUTE only to `postgres`; `has_function_privilege('service_role', ...)` is false. It runs from the active market-price Cron as postgres. Do not accidentally add it to a service_role allowlist.
- Private-schema SECURITY DEFINER functions are outside this 36-signature public API matrix. Their schema USAGE and effective reachability are separately constrained and must be reviewed independently.
- The 26-name authenticated allowlist includes private functions in addition to the 23 public signatures above. Do not infer that every authenticated function belongs in this public 36-signature matrix.

## 4. Proposed disposition — conservative, not an executable target

| Group | Count | Current evidence | Review disposition |
|---|---:|---|---|
| Browser/session-facing signatures | 23 | Browser RPC callsites found | Preserve authenticated access pending per-function body/authorization review. The two anon metadata endpoints remain explicit public exceptions pending product/API review. |
| Cron/Auth-trigger signatures | 12 | Cron or Auth trigger runs as postgres | No observed caller needs service_role EXECUTE. Candidate for removal only after external caller search and disposable parity tests; do not change now. |
| Refresh claim signature | 1 | No caller found in inspected runtime/repository surfaces | Hold unresolved. Determine whether rate limiting should route through this function and search out-of-repository/manual deployments before deciding. |

This is deliberately not a final grant matrix. In particular, service_role is a privileged backend role and bypasses RLS for table access; that fact neither grants nor implies a need for function EXECUTE. Table privileges, RLS bypass, schema USAGE, and function EXECUTE must be tested as separate dimensions.

## 5. Evidence gaps / next read-only work

1. Obtain per-signature `proconfig` values (empty search_path versus `pg_catalog`) and retain exact owner, language, volatility, and ACL snapshots.
2. Review function bodies for all 23 browser-callable signatures, with emphasis on admin authorization and ownership checks; the current matrix records callsites, not proof that bodies are safe.
3. Search accessible deployment manifests, non-secret environment-variable names, server-side worker source, and authorized function logs for external callers of `claim_admin_asset_refresh(text,uuid)`. Do not expose secret values.
4. Determine whether refresh rate limiting was intended to use `claim_admin_asset_refresh`; current reviewed Edge Function path uses direct table operations.
5. Resolve the conflict between `tests/default-function-acl-hardening.sql` (retains service_role default EXECUTE) and the proposed SQL draft (revokes service_role default EXECUTE).
6. Only after owner policy selection, update the catalog test to compare exact identity-argument signatures and write separate current-state and proposed-target matrices.

## 6. Safety status

- No Production SQL or function invocation was performed to create this matrix.
- No GRANT, REVOKE, ALTER DEFAULT PRIVILEGES, migration, db push, Cron/trigger change, Edge Function deployment, secret change, or test fixture was performed.
- No CI gate was enabled.
- PR #62 remains Draft and unmerged.
