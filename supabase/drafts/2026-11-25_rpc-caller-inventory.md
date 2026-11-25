# DigiArz — RPC caller inventory (review snapshot)

Date: 2026-11-25
Branch: `feature/persian-asset-name-candidates-2026`
Reviewed commit: `1f0db5efe87f03fad1510be36954195d0e52d6d4` (source snapshot before this inventory)
Scope: source-code call-site inspection only. No database access, SQL execution, migration, grant, revoke, or runtime invocation.

## 1. Verified browser call sites

The browser application entrypoint `index.html` was scanned for direct `supabaseClient.rpc(...)` calls matching the SECURITY DEFINER allowlist. The following functions have direct browser call sites:

- Account and admin: `admin_adjust_wallet`, `admin_list_users`, `is_current_user_super_admin`.
- Market administration: `admin_add_market_listing`, `admin_disable_market_pair`, `admin_enable_market_pair`, `admin_exchange_asset_sync_report`, `admin_remove_market_listing`, `admin_request_exchange_asset_sync`, `admin_review_market_listings`, `admin_search_market_assets`, `get_admin_market_listings`.
- Trading and order lifecycle: `cancel_conditional_exit_order`, `cancel_limit_order`, `cancel_stop_limit_order`, `execute_demo_trade`, `get_my_order_reservations`, `place_conditional_exit_order`, `place_limit_order`, `place_stop_limit_order`, `request_market_price_refresh`.
- Account lifecycle: `deactivate_my_account`, `reactivate_my_account`.
- Public market metadata: `get_exchange_discovered_market_assets`.

This is a call-site inventory, not proof that every call succeeds for every role. The browser uses the Supabase client session; each function body must still be reviewed for authorization checks and expected JWT state.

## 2. Effective role allowlists already present in the catalog test

The current `tests/rpc-security-catalog.sql` encodes:
- `anon`: exactly two SECURITY DEFINER read endpoints — `public.get_admin_market_listings()` and `public.get_exchange_discovered_market_assets()`.
- `authenticated`: 26 SECURITY DEFINER function names (including the admin, account, trading and order RPC surface).
- `service_role`: 36 SECURITY DEFINER function names (including server-side order engines and exchange/market workers).

The test rejects PUBLIC EXECUTE on SECURITY DEFINER functions, unexpected role grants, missing allowlist entries, unsafe search_path settings, and unexpected overloads. The allowlists are based on the reviewed Production catalog snapshot; they are not a substitute for reviewing each function body or exact identity arguments.

## 3. Server-side / internal candidates without direct browser RPC call sites

The following functions in the service-role catalog allowlist did not appear as direct `.rpc(...)` calls in `index.html` during this scan:

- `claim_admin_asset_refresh`
- `new_user_setup`
- `process_bit24_exchange_sync`
- `process_conditional_orders`
- `process_iran_exchange_asset_sync`
- `process_limit_orders`
- `process_stop_limit_orders`
- `recover_stale_crypto_assets_sync`
- `refresh_crypto_assets`
- `refresh_crypto_assets_toman`
- `refresh_market_fx_rate`
- `refresh_market_prices`
- `request_bit24_exchange_sync`
- `request_iran_exchange_asset_sync`

This classification is intentionally cautious: absence from the browser entrypoint does not prove a cron schedule, Auth trigger, Edge Function caller, or worker relationship. Specific repository artifacts reviewed in this pass include:
- `supabase/migrations/20261113181827_add_stop_limit_order_engine.sql` (stop-limit/order processing and cancellation surface).
- `supabase/migrations/20261113190000_admin_on_demand_crypto_asset_refresh.sql` (on-demand asset refresh claim path).
- `supabase/drafts/recovered_20261115102729_schedule_iran_exchange_asset_sync.sql` and `...15103507_schedule_bit24_exchange_asset_sync.sql` (exchange sync scheduling drafts).
- `supabase/drafts/recovered_20261115105956_restrict_exchange_sync_worker_execution.sql` (worker execution restriction draft).

The drafts are evidence of proposed/recovered call paths, not proof that those SQL statements are active in Production.

## 4. Remaining evidence needed before changing default ACLs

1. Obtain exact `pg_get_function_identity_arguments(oid)`, owner, `prosecdef`, `proconfig`, and effective ACL for every function in public/private.
2. Trace every service-role function to its actual caller: pg_cron job, trigger, Edge Function, server process, or administrative action. Verify the caller's credential role; do not infer service_role merely from a function name.
3. Inspect each SECURITY DEFINER body for explicit authorization checks, especially admin functions and functions callable by authenticated users.
4. Verify Auth trigger wiring for `new_user_setup` and worker schedule wiring for all `process_*` and `refresh_*` functions.
5. Convert the role/name allowlists to exact signatures and prepare explicit grants only after this tracing.
6. Test on a disposable, Production-parity clone with real test Auth identities and negative/positive caller tests.

## 5. Safety and CI

- Latest PR #62 CI at commit `1f0db5efe87f03fad1510be36954195d0e52d6d4`: unit tests and Edge Function type-check passed in both Push run #179 and PR run #180.
- RPC integration job was skipped in both runs because the opt-in gate remains disabled. This is intentional; no repository secret or variable was changed.
- No Production or Test database operation was performed for this inventory.
- No Migration, ALTER DEFAULT PRIVILEGES, GRANT, REVOKE, db push, Auth, Cron, Worker, or data change was performed.
- PR #62 remains Draft/open/unmerged. No merge or infrastructure spend occurred.

## 6. Conclusion

The browser-facing call surface is now partially mapped, while backend/worker callers still require exact catalog-to-scheduler tracing. Do not apply the default ACL proposal yet. In particular, preserve the currently working trading/order and exchange-sync workers until each required exact-signature grant and caller path has been independently verified.


## 7. Production catalog and active caller evidence (read-only, 2026-11-25)

A fresh Production catalog audit was performed using SELECT-only queries against `pg_proc`, `pg_namespace`, `pg_roles`, `pg_trigger`, `pg_class`, `pg_depend`, and `cron.job`. No function was invoked. The audit returned exactly 36 SECURITY DEFINER functions in `public/private` for which `service_role` has effective EXECUTE. All 36 are owned by `postgres`; all have an explicit safe `search_path` (`''` or `pg_catalog`). None is extension-owned. Function definitions were not copied into this report; only MD5 fingerprints were computed for comparison metadata.

### Exact service-role grant signatures

The 36 signatures, grouped by their additional effective callers, are:

**Also executable by authenticated (22):**
- `public.admin_add_market_listing(text)`
- `public.admin_disable_market_pair(text,text)`
- `public.admin_enable_market_pair(text)`
- `public.admin_exchange_asset_sync_report()`
- `public.admin_remove_market_listing(text)`
- `public.admin_request_exchange_asset_sync()`
- `public.admin_review_market_listings()`
- `public.admin_search_market_assets(text,integer)`
- `public.cancel_conditional_exit_order(uuid)`
- `public.cancel_limit_order(uuid)`
- `public.cancel_stop_limit_order(uuid)`
- `public.current_account_is_active()`
- `public.deactivate_my_account()`
- `public.execute_demo_trade(text,text,numeric,numeric)`
- `public.get_admin_market_listings()`
- `public.get_demo_trading_fee_rate(text,text)`
- `public.get_exchange_discovered_market_assets()`
- `public.get_my_order_reservations(uuid[])`
- `public.place_conditional_exit_order(text,text,numeric,numeric)`
- `public.place_limit_order(text,text,numeric,numeric)`
- `public.place_stop_limit_order(text,text,numeric,numeric,numeric)`
- `public.reactivate_my_account()`
- `public.request_market_price_refresh()`

**Service-role only among API roles (13):**
- `public.claim_admin_asset_refresh(text,uuid)`
- `public.new_user_setup()`
- `public.process_bit24_exchange_sync()`
- `public.process_conditional_orders()`
- `public.process_iran_exchange_asset_sync()`
- `public.process_limit_orders()`
- `public.process_stop_limit_orders()`
- `public.recover_stale_crypto_assets_sync()`
- `public.refresh_crypto_assets()`
- `public.refresh_crypto_assets_toman()`
- `public.refresh_market_fx_rate()`
- `public.request_bit24_exchange_sync()`
- `public.request_iran_exchange_asset_sync()`

Note: the earlier source inventory's inclusion of `refresh_market_prices()` in the service-role candidate set is not supported by the current Production ACL. Its exact signature is `public.refresh_market_prices()`; its ACL currently contains only postgres EXECUTE, and `has_function_privilege('service_role', ...)` is false. This distinction must be retained in any proposed ACL reconciliation.

### Confirmed Production cron identities and schedules

All 14 relevant Production jobs are active and have `username='postgres'`. This means their SQL is executed as postgres, not as service_role; their existence does not prove that service_role EXECUTE is needed. Current live schedules:

| Job | Exact function | Production schedule |
|---|---|---|
| digiarz-fx-rate-refresh | `public.refresh_market_fx_rate()` | every minute |
| digiarz-market-price-refresh | `public.refresh_market_prices()` | every minute |
| refresh-crypto-assets | `public.refresh_crypto_assets()` | minutes 6,16,26,36,46,56 |
| refresh-crypto-assets-toman | `public.refresh_crypto_assets_toman()` | minutes 7,17,27,37,47,57 |
| digiarz-limit-orders | `public.process_limit_orders()` | every minute |
| digiarz-conditional-orders | `public.process_conditional_orders()` | every minute |
| digiarz-crypto-assets-stale-request-recovery | `public.recover_stale_crypto_assets_sync()` | every 5 minutes at 3,8,...,58 |
| digiarz-stop-limit-orders | `public.process_stop_limit_orders()` | every minute |
| digiarz-iran-exchange-request | `public.request_iran_exchange_asset_sync()` | every 10 minutes |
| digiarz-iran-exchange-process | `public.process_iran_exchange_asset_sync()` | minutes 1 and 31 |
| digiarz-bit24-request | `public.request_bit24_exchange_sync()` | every 30 minutes |
| digiarz-bit24-process | `public.process_bit24_exchange_sync()` | minutes 16 and 46 |
| digiarz-market-price-overflow | `private.request_market_price_overflow()` | minutes 5,15,25,35,45,55 |
| digiarz-auto-activate-verified-exchange-pairs | `private.auto_activate_verified_exchange_pairs()` | minutes 9,19,29,39,49,59 |

No cron job was updated, paused, rescheduled, or invoked by this audit.

### Confirmed Auth trigger

Production has an enabled `auth.users` trigger `on_auth_user_created` calling `public.new_user_setup()`. The trigger function is postgres-owned and SECURITY DEFINER. This is a database-trigger caller, not a service-role client call.

### Recovered migration schedule drift — do not replay drafts

The recovered review-only SQL drafts do not match current Production cron schedules:
- Iran exchange draft records request `*/30` and processor `*/2`; Production currently has request `*/10` and processor `1,31`.
- Bit24 draft records request `*/30` and processor `*/2`; Production currently has request `*/30` and processor `16,46`.

The live `cron.job` catalog is the current schedule evidence. Recovered drafts are historical migration text and must not be replayed or used to overwrite live schedules.

### Remaining unresolved caller

`public.claim_admin_asset_refresh(text,uuid)` has an explicit service_role grant and validates a supplied super-admin user ID, but no direct browser RPC call was found in `index.html`, and the reviewed refresh migration only defines/grants it. Its actual caller (Edge Function, server worker, or currently unused) remains unverified. Do not revoke its grant until every Edge Function and backend source has been searched and the refresh call chain has been traced.

### ACL decision status

The catalog evidence establishes that cron and Auth trigger execution currently run as postgres, not service_role. It does **not** yet establish that all 13 service-role-only grants are unused: the remaining Edge Function/backend caller search is still required, particularly for `claim_admin_asset_refresh`. Do not apply the default-ACL proposal or any per-function revoke until that search and disposable-clone integration tests are complete. The Production catalog audit was read-only; no schema, ACL, data, cron, worker, secret, or configuration changes were made.
