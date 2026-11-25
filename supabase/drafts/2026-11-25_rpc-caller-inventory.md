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
