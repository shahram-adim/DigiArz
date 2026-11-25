# DigiArz — Admin Refresh Runtime Caller Trace (Evidence Gap)

**Evidence date:** 2026-11-25  
**PR:** #62  
**Branch:** `feature/persian-asset-name-candidates-2026`  
**Status:** PARTIAL TRACE / OWNER-ACCESS EVIDENCE REQUIRED

## Scope and safety

This is a repository-only, read-only trace. No function was invoked, no deployment or log source was queried, and no database object or privilege was changed.

## Confirmed database-side design

The migration `20261113190000_admin_on_demand_crypto_asset_refresh.sql` defines:

1. `public.admin_search_market_assets(text, integer)` as a SECURITY DEFINER function that requires `auth.uid()` and `private.is_super_admin()`.
2. `public.claim_admin_asset_refresh(text, uuid)` as a SECURITY DEFINER function that checks the supplied user against `private.admin_users`, serializes claims per CoinGecko ID using an advisory transaction lock, and enforces a 30-second cooldown in `private.admin_asset_refresh_limits`.
3. The claim function is explicitly executable by `service_role` only among API roles.

This is evidence of intended architecture, not evidence of a live caller.

## Repository search findings

Searches in the connected GitHub repository for:
- `claim_admin_asset_refresh`
- `admin_asset_refresh_limits`
- `admin_search_market_assets`
- `on-demand crypto asset refresh`

returned only the migration definition for the claim/limits names; the admin-search name also appeared in its defining migration. No browser, Edge Function, or worker callsite was found in the indexed repository search.

The search integration indexes the default branch and does not guarantee exhaustive search of the PR head, generated bundles, external deployments, or unindexed files. A previous audit separately reviewed the active Edge Function and browser RPC callsites and found no direct claim-function caller. These findings narrow the repository evidence but do not prove that no external/manual caller exists.

## Conclusion

**Caller status: UNRESOLVED — no runtime invocation evidence.**

Do not revoke `service_role` EXECUTE and do not remove or bypass the cooldown table/function based on repository search alone. To close this item, an authorized operator must trace the deployed admin refresh flow, inspect deployment manifests without exposing secret values, and inspect permitted invocation/edge logs for the relevant time window. If there is no deployed caller, the owner must decide whether this is intentionally reserved functionality or dead code before any change is proposed.

## Next steps

1. Map the admin UI action and its network request to the deployed Edge Function or server route.
2. Confirm whether that runtime calls `claim_admin_asset_refresh(text, uuid)` and where the service-role client is used.
3. If logs are available, inspect metadata/counts and timestamps only; do not reveal tokens, keys, or personal data.
4. Keep the RPC security integration CI job skipped until the approved policy and a genuine disposable Production-parity environment exist.

## 5. Superseding live runtime confirmation — 2026-11-25

The earlier status **UNRESOLVED** is superseded for the deployed Production path. The active `admin-refresh-crypto-asset` Edge Function, version 2, has `verify_jwt=true` and calls `public.claim_admin_asset_refresh(text,uuid)` using a server-side service-role client. Before the call it validates the Bearer token with `auth.getUser(token)`, checks super-admin authorization with the user-scoped admin RPC, and derives the user UUID from the verified Auth response. The function's live ACL explicitly grants EXECUTE to service_role.

Therefore the caller is confirmed at the deployed-source level; the earlier absence from indexed source search was an incomplete search result. Preserve this exact grant unless the deployed caller is intentionally replaced and separately reviewed. The available 24-hour Edge Function log window showed no request path for this function, so an actual invocation in that window is not evidenced. No Production object or privilege was changed.
