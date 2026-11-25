# DigiArz — Production ACL Metadata and Refresh-Claim Provenance

**Status:** READ-ONLY EVIDENCE / REVIEW DRAFT  
**Evidence date:** 2026-11-25  
**Production project:** `gfoaubfilhttnwjykaox`  
**Related PR:** #62  
**Branch:** `feature/persian-asset-name-candidates-2026`

## 1. Safety and method

This note records a SELECT-only PostgreSQL catalog query against Production and a read-only repository search. It does not propose or authorize any SQL change, function invocation, GRANT/REVOKE, migration, deployment, or CI change.

The catalog query selected SECURITY DEFINER functions in `public` and `private` for which `has_function_privilege('service_role', oid, 'EXECUTE')` is true. It returned 36 exact function signatures. No function body was executed.

## 2. Aggregate metadata for the 36 current service_role-executable functions

| Catalog property | Observed count |
|---|---:|
| Total exact signatures | 36 |
| Owner = postgres | 36 |
| SECURITY DEFINER | 36 |
| Explicit `search_path=""` | 35 |
| Explicit `search_path=pg_catalog` | 1 |
| Missing `proconfig` / unset search_path | 0 |
| Language = plpgsql | 31 |
| Language = sql | 5 |
| Volatility = volatile | 29 |
| Volatility = stable | 7 |
| Volatility = immutable | 0 |
| Effective anon EXECUTE | 2 |
| Effective authenticated EXECUTE | 23 |
| NULL `proacl` | 0 |

The single `search_path=pg_catalog` exception is:

- `public.refresh_market_fx_rate()` — owner `postgres`, SECURITY DEFINER, PL/pgSQL, VOLATILE, effective API roles: `service_role` only.

The other 35 signatures have explicit `search_path=""`. The two anon-executable signatures remain exactly `public.get_admin_market_listings()` and `public.get_exchange_discovered_market_assets()`.

All 36 rows have non-NULL explicit `proacl`; the per-signature current role booleans and identity arguments remain in `2026-11-25_exact-signature-acl-matrix.md`. This metadata snapshot describes current Production state, not an approved target policy.

## 3. Refresh-claim provenance — important refinement

The repository migration `supabase/migrations/20261113190000_admin_on_demand_crypto_asset_refresh.sql` defines:

- `private.admin_asset_refresh_limits`, with RLS enabled and table privileges revoked from PUBLIC/anon/authenticated;
- `public.claim_admin_asset_refresh(text, uuid)`, SECURITY DEFINER with `search_path=""`;
- a super-admin lookup against `private.admin_users`;
- a per-asset advisory transaction lock and a 30-second per-asset cooldown;
- an explicit function ACL that revokes PUBLIC/anon/authenticated and grants EXECUTE to `service_role`.

This proves the function was intentionally designed as a service-role-accessible rate-limit claim operation. It does **not** prove which deployed runtime currently calls it.

A GitHub repository code search for `claim_admin_asset_refresh` and `admin_asset_refresh_limits` returned only this migration; search for the camelCase spelling `claimAdminAssetRefresh` returned no results. The reviewed active browser and Edge Function call paths still show no direct caller. Repository code search is not proof that no caller exists in external deployments, manually operated workers, older artifacts, or code outside the indexed repository.

**Disposition remains UNRESOLVED — DO NOT REVOKE.** Before any target decision, trace the full on-demand refresh workflow from the admin UI through any deployed server/Edge Function, inspect non-secret deployment manifests and authorized invocation logs, and establish whether the rate-limit claim is currently enforced. Do not expose secret values.

## 4. Policy status

- Current Production ACL state is recorded separately from any future policy.
- The conflict between `tests/default-function-acl-hardening.sql` (retains postgres public-schema default EXECUTE for `service_role`) and `2026-11-25_proposed_restrict_default_public_function_exec.sql` (removes that default) remains unresolved.
- No target ACL policy is inferred or approved.
- The Recovery-Test project remains non-parity and is not used to claim a security test pass.
- No database object, privilege, trigger, Cron job, CI gate, secret, or deployment was changed.

## 5. Next evidence required

1. Preserve the confirmed caller/grant pair. If runtime-usage evidence is needed, inspect a later authorized log window; do not infer non-use from the prior empty 24-hour window.
2. Complete exact caller mapping for the 23 browser/session-facing signatures and preserve function-body review separately from ACL state.
3. Obtain the owner's explicit decisions on default `service_role` EXECUTE, anonymous market-metadata disclosure, and the intended refresh-claim design.
4. Only after an approved disposable parity environment and target policy exist, prepare role-positive/negative runtime tests. Do not enable the skipped CI integration job before those gates pass.
