# DigiArz — Frontend RPC inventory reconciliation

**Evidence date:** 2026-11-25  
**Repository:** `shahram-adim/DigiArz`  
**Branch:** `feature/persian-asset-name-candidates-2026`  
**Evidence base:** `6a349de1e3983a6090a0f2d22b4ad8787c7325d6`  
**Supabase project:** `gfoaubfilhttnwjykaox`

## Scope

Read-only comparison of the current branch `index.html` RPC callsites against live PostgreSQL function definitions and effective ACL metadata. No RPC was invoked. No SQL write, migration, GRANT/REVOKE, deployment, Auth change, or CI change was performed.

## Direct frontend RPC inventory

A source scan of `index.html` found 24 distinct direct `supabaseClient.rpc(...)` names (28 call occurrences):

`admin_add_market_listing`, `admin_adjust_wallet`, `admin_disable_market_pair`, `admin_enable_market_pair`, `admin_exchange_asset_sync_report`, `admin_list_users`, `admin_remove_market_listing`, `admin_request_exchange_asset_sync`, `admin_review_market_listings`, `admin_search_market_assets`, `cancel_conditional_exit_order`, `cancel_limit_order`, `cancel_stop_limit_order`, `deactivate_my_account`, `execute_demo_trade`, `get_admin_market_listings`, `get_exchange_discovered_market_assets`, `get_my_order_reservations`, `is_current_user_super_admin`, `place_conditional_exit_order`, `place_limit_order`, `place_stop_limit_order`, `reactivate_my_account`, `request_market_price_refresh`.

The three Edge Function invocations found in the same frontend file are `admin-refresh-crypto-asset`, `market-data`, and `refresh-toman-market-prices`.

## Wrapper-to-definer chains verified from Production

The browser client is initialized with the Supabase default schema (no custom `db.schema` option). Three directly called public RPCs are SECURITY INVOKER wrappers, not members of the 46-function SECURITY DEFINER inventory:

| Browser RPC | Public wrapper | Private callee | Effective ACL observed |
|---|---|---|---|
| `admin_list_users()` | SQL, SECURITY INVOKER, empty search_path | `private.admin_list_users()` — STABLE SECURITY DEFINER | authenticated + service_role on public wrapper; authenticated only on private callee |
| `admin_adjust_wallet(uuid,text,text,numeric,text)` | SQL, SECURITY INVOKER, empty search_path | `private.admin_adjust_wallet(...)` — SECURITY DEFINER | authenticated + service_role on public wrapper; authenticated only on private callee |
| `is_current_user_super_admin()` | SQL, SECURITY INVOKER, empty search_path | `private.is_current_user_super_admin()` — STABLE SECURITY DEFINER | authenticated + service_role on public wrapper; authenticated only on private callee |

The three private callees each use an empty search_path. The admin data/mutation callees enforce `auth.uid() IS NOT NULL` and `private.is_super_admin()`; the identity helper requires a non-null `auth.uid()` and delegates to the private super-admin check.

### Sensitive admin paths

- `admin_list_users()` returns user IDs, email addresses, active status, creation timestamps, and wallet balances. Its private SECURITY DEFINER callee performs the super-admin check before returning rows.
- `admin_adjust_wallet(...)` can update a target wallet and insert a transaction/audit row. Its private SECURITY DEFINER callee checks the caller with `auth.uid()` and `private.is_super_admin()`, validates target/currency/direction/amount/reason, and protects reserved USDT from debit.
- The browser code additionally gates the admin UI on `isSuperAdmin`, but that client-side condition is not the security boundary; the private function-body checks are.

## Reconciliation against the earlier 23-signature browser/session list

The prior audit list must not be treated as a complete direct-callsite inventory without this wrapper reconciliation:

- The source contains direct callsites for the three public invoker wrappers above, whose private SECURITY DEFINER callees must be included in the authorization/call-path map.
- The same source scan found no direct callsite for `current_account_is_active()` or `get_demo_trading_fee_rate(text,text)`; both remain in the broader function inventory but are not evidenced as direct browser RPCs in this `index.html`.
- The 24-name source inventory is not a replacement for the 46-signature catalog contract. It is a separate frontend reachability inventory; wrapper functions, private callees, Edge Function calls, Cron paths, and Auth-trigger paths must remain distinct categories.

## Remaining work

1. Reconcile all 24 direct frontend RPC names against exact public signatures and private callees, including any overloads.
2. Finish function-body and caller review for every direct browser RPC, with cross-user IDOR/unauthorized-role tests deferred until an approved disposable PostgreSQL 17 parity environment exists.
3. Keep the live `claim_admin_asset_refresh` service_role caller grant; its separate trace is documented in `2026-11-25_refresh-claim-live-caller-trace.md`.
4. Do not infer that service_role EXECUTE is needed for unrelated RPCs; resolve default-function ACL policy separately with the owner.
5. Do not create a project/branch, incur cost, run Production tests, change ACLs, or enable skipped security CI without explicit approval.

## Production impact

No Production function, ACL, table, row, Auth setting, Cron job, trigger, Edge Function, or financial record was changed.
