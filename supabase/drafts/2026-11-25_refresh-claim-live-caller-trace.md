# DigiArz — Live caller trace for admin asset refresh claim

**Evidence date:** 2026-11-25  
**Production project:** `gfoaubfilhttnwjykaox`  
**Related PR:** #62  
**Branch:** `feature/persian-asset-name-candidates-2026`  
**Base evidence commit:** `9697a6790c945ace2a21008ff97044c4c9366f8d`

## Scope and safety

This is a read-only trace of the current GitHub frontend callsite, the deployed Supabase Edge Function source/metadata, the live PostgreSQL function definition/ACL, and aggregate log paths. No function was invoked. No SQL write, migration, GRANT/REVOKE, deployment, secret read, Cron/trigger change, or CI change was performed.

## Caller chain confirmed

1. The admin UI in `index.html` calls `supabaseClient.functions.invoke('admin-refresh-crypto-asset', { body: { coingecko_id: id } })` from `addAdminMarketListing()`. The UI handler first requires `isSuperAdmin`.
2. Production Edge Function `admin-refresh-crypto-asset` is ACTIVE, version 2, with `verify_jwt=true`.
3. The deployed handler:
   - validates the Bearer token and calls `userClient.auth.getUser(token)`;
   - calls `admin_search_market_assets` using that user JWT and fails closed on an RPC error;
   - obtains the user ID from the verified Auth response, not from the request body;
   - creates a server-side service-role client and calls `claim_admin_asset_refresh(p_coingecko_id, p_admin_user_id)`;
   - only after a successful claim, fetches the CoinGecko asset and updates the matching active `crypto_assets` row.
4. The live database definition of `public.claim_admin_asset_refresh(text, uuid)` is SECURITY DEFINER with an empty search_path. Its explicit ACL is `{postgres=X/postgres,service_role=X/postgres}`; it checks the supplied user ID against `private.admin_users` for `super_admin`, then takes a per-asset advisory transaction lock and enforces a 30-second per-asset cooldown before returning true.

## Security disposition

- The earlier caller uncertainty is resolved for the currently deployed admin refresh path: the function is directly called by the active `admin-refresh-crypto-asset` Edge Function using the server-side service-role client.
- **Do not revoke service_role EXECUTE from this function.** Doing so would break the observed active caller unless that runtime is deliberately redesigned and separately reviewed.
- The Edge Function obtains the user ID from `auth.getUser(token)`; it does not accept `p_admin_user_id` from the browser payload. Its preceding admin RPC check also uses the user JWT.
- This finding does not settle the separate default-function-ACL policy conflict, nor justify retaining service_role EXECUTE on unrelated functions. Keep the function-specific caller evidence separate from the default-privilege policy decision.

## Log evidence and limitation

- In the available default 24-hour log window, `function_edge_logs` contained no request path for `/functions/v1/admin-refresh-crypto-asset`.
- In the same window, `postgrest_logs` contained no path matching `claim_admin_asset_refresh` or `admin_search_market_assets`.
- Therefore the deployed source and frontend call path are confirmed, but an actual invocation during that 24-hour window is **not** evidenced. Absence from this window does not prove the feature is unused or that no older/external caller exists.

## Remaining work

1. Preserve the confirmed function-specific `service_role` grant in any future policy proposal unless the caller is intentionally replaced.
2. Continue auditing the other 23 browser/session-facing RPC signatures and their exact frontend callsites; do not infer safety from ACL alone.
3. Resolve the separate default `service_role` EXECUTE policy conflict through an explicit owner decision.
4. Build or obtain an approved disposable PostgreSQL 17 parity environment before negative/positive runtime role tests. The existing Recovery-Test project is not parity; do not enable the skipped RPC-security CI job against it.
5. Do not create a Supabase project/branch or incur cost without explicit approval.

## Production impact

No Production database object, ACL, function, table row, Auth setting, Cron job, trigger, Edge Function deployment, or financial record was changed.
