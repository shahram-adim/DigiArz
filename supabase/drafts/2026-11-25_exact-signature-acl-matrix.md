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
| `public.admin_exchange_asset_sync_report()` | authenticated, service_role | Browser `.rpc()` inventory; integration test exercises function-body guard | Anon and ordinary-user denial must be tested at function-body level; catalog grant is currently present |
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


## 7. Read-only body authorization review — 23 browser/session signatures

A fresh Production catalog query used only `pg_get_functiondef` / `pg_proc.prosrc` and metadata inspection. No function was invoked. All 23 signatures have `search_path=""` in the inspected catalog snapshot.

### A. Administrative RPCs (8)

| Function | Observed server-side guard | Operation / data exposure | Review result |
|---|---|---|---|
| `admin_add_market_listing(text)` | Requires non-null `auth.uid()` and `private.is_super_admin()` | Inserts curated market listing | Guard present; validates active asset, fresh price/metadata, symbol format and symbol collision |
| `admin_disable_market_pair(text,text)` | Requires non-null `auth.uid()` and `private.is_super_admin()` | Cancels open orders, releases reservations, disables pair, writes audit | Guard present; uses row lock; high-impact admin action remains admin-only |
| `admin_enable_market_pair(text)` | Requires non-null `auth.uid()` and `private.is_super_admin()` | Enables pair after market-data/liquidity checks; writes audit | Guard present; advisory lock and eligibility validation observed |
| `admin_exchange_asset_sync_report()` | Requires `private.is_current_user_super_admin()` | Read-only aggregate and issue report | Guard delegates to verified current-user helper |
| `admin_remove_market_listing(text)` | Requires non-null `auth.uid()` and `private.is_super_admin()` | Deletes curated listing | Guard present |
| `admin_request_exchange_asset_sync()` | Requires `private.is_current_user_super_admin()` | Calls two request functions | Guard delegates to verified current-user helper; nested calls run through postgres-owned SECURITY DEFINER context |
| `admin_review_market_listings()` | Filters result set with `auth.uid() IS NOT NULL AND private.is_super_admin()` | Read-only review/eligibility rows | Unauthorized callers receive no rows; guard is a row filter rather than an exception |
| `admin_search_market_assets(text,integer)` | Requires non-null `auth.uid()` and `private.is_super_admin()` | Read-only catalog search | Guard present; minimum search length enforced |

### B. Verified admin identity helper chain

The following helper definitions were read from Production:
- `private.is_current_user_super_admin()`: SECURITY DEFINER, `search_path=""`; returns true only when `auth.uid()` is non-null and `private.is_super_admin()` is true.
- `private.is_super_admin()`: SECURITY DEFINER, `search_path=""`; checks `private.admin_users.user_id = auth.uid()` and `role = 'super_admin'`.
- Neither helper reads `user_metadata` or accepts a caller-supplied user ID. This is consistent with the requirement not to trust user-editable JWT metadata for authorization.
- `public.is_current_user_super_admin()` is a SECURITY INVOKER SQL wrapper around the private helper; the reviewed admin RPCs call the private helper directly.

### C. User-owned account and trading RPCs (11)

| Function | Observed identity / ownership control | Operation / review result |
|---|---|---|
| `cancel_conditional_exit_order(uuid)` | Requires `auth.uid()`; selects conditional order by both `order_id` and `user_id=v_uid`; checks active account | Owner-scoped cancellation and reservation release; row locks and row-count assertions observed |
| `cancel_limit_order(uuid)` | Requires `auth.uid()`; selects order by `id` and `user_id=v_uid` | Owner-scoped cancellation; validates order type/status and reservation invariants |
| `cancel_stop_limit_order(uuid)` | Requires `auth.uid()`; parent and conditional rows are filtered by `user_id=v_uid` | Owner-scoped stop-limit cancellation; state and row-count checks observed |
| `current_account_is_active()` | Reads profile where `profiles.id=auth.uid()`; missing profile resolves false | User-scoped status helper |
| `deactivate_my_account()` | Requires `auth.uid()`; updates only `profiles.id=v_uid`; subsequent order/reservation cleanup is filtered to `v_uid` | User-scoped deactivation and cleanup; no caller-supplied user ID |
| `execute_demo_trade(text,text,numeric,numeric)` | Requires `auth.uid()`, active account; writes orders/trades/transactions with `user_id=v_uid` | User-scoped demo trade; validates symbol, side, amount, balance/reservations and current account state |
| `get_my_order_reservations(uuid[])` | Requires non-null `auth.uid()`; filters `r.user_id=auth.uid()`; limits array size to 1..100 | Owner-scoped read; caller cannot read another user's reservations by supplying order IDs |
| `place_conditional_exit_order(text,text,numeric,numeric)` | Requires `auth.uid()` and active account; wallet/assets/reservations and inserted rows use `v_uid` | User-scoped order placement with balance/reservation checks and row locks |
| `place_limit_order(text,text,numeric,numeric)` | Requires `auth.uid()` and active account; wallet/assets/reservations and inserted rows use `v_uid` | User-scoped order placement with balance/reservation checks and row locks |
| `place_stop_limit_order(text,text,numeric,numeric,numeric)` | Requires `auth.uid()` and active account; wallet/assets/reservations and inserted rows use `v_uid` | User-scoped order placement with stop/limit relationship checks and row locks |
| `reactivate_my_account()` | Requires `auth.uid()`; updates only `profiles.id=v_uid`; requires JWT `auth_time` within 300 seconds | User-scoped reactivation with recent-authentication check |

### D. Public read/configuration RPCs (3)

| Function | Current exposure | Observed returned data / review result |
|---|---|---|
| `get_admin_market_listings()` | anon + authenticated + service_role | Active curated market assets, market price/volume/rank and listing date; no user/account data observed. This is a public market catalogue endpoint despite the historical `admin_` prefix. |
| `get_exchange_discovered_market_assets()` | anon + authenticated + service_role | Aggregated active unmatched/ambiguous exchange observations and recent market prices; no user/account data observed. Treat as intentional public market metadata only if product policy accepts exposing source observations and labels. |
| `get_demo_trading_fee_rate(text,text)` | authenticated + service_role | Reads enabled maker/taker fee configuration for a quote asset; no user/account data observed. Validate that fee configuration itself is not considered sensitive. |

### E. Rate-limit and behavioral note

`request_market_price_refresh()` requires an authenticated active profile, locks the singleton `private.market_price_refresh_control` row, enforces a 30-second interval, updates that shared timestamp, and calls `public.refresh_market_prices()`. This is a global shared cooldown, not a per-user limit: any authenticated active user may occupy the 30-second slot for all users. It is not an authorization bypass, but it is a potential availability/fairness concern worth a separate product decision. Do not change it during ACL hardening; the live price-refresh Cron must remain untouched.

### F. Security review disposition and remaining tests

- No obvious missing caller identity guard was found in the eight administrative RPCs; the two admin identity helpers resolve authorization from `auth.uid()` and the private admin table, not user-editable metadata.
- User order, reservation, account, and demo-trade paths reviewed are scoped to the authenticated user's ID in their reads/writes.
- Three public/read-only endpoints have no user identity guard by design. Their output should remain restricted to market metadata; keep a regression test to prevent accidental addition of user/private data.
- Static source review is not a substitute for negative runtime tests. The current integration job remains skipped; do not enable it until the policy discrepancy and disposable parity environment blockers are resolved.
- The current integration SQL only tests a limited admin guard with temporary grants; it does not exercise all 23 exact signatures, cross-user IDOR attempts, anon public-read data boundaries, or real catalog ACL behavior.
- No grant/revoke recommendation is finalized by this body review. Preserve all current grants until exact policy approval and disposable-clone testing.

This review was performed using SELECT-only catalog/function-definition reads. No RPC function was invoked and no data, ACL, function, trigger, Cron job, migration, CI secret, or deployment was changed.


## 8. Public read RPCs — fresh definition-level review

The three public/read/configuration definitions were re-read directly from Production catalogs using SELECT-only queries. All are `STABLE SECURITY DEFINER` with `search_path=""`. No RPC was invoked and no output rows were queried.

### 8.1 `public.get_admin_market_listings()`

- Exact result contract: 11 columns — CoinGecko ID, symbol, name, image URL, market-cap rank, current USD price, Toman price, 24h percentage, USD volume, market-price timestamp, and listing timestamp.
- Reads curated listings joined to active `crypto_assets`, with a left join to `market_prices`.
- USD price is returned only when the price row is from CoinGecko, positive, and updated within two minutes; otherwise the USD price is NULL.
- No user, wallet, order, reservation, email, or account identifiers are referenced in the function body.
- Public exposure is consistent with a public market catalogue, notwithstanding the legacy `admin_` name.
- Review caveat: Toman price, 24h percentage, volume and rank are selected directly from `crypto_assets`; their own freshness is not checked in this function. Consumers should not treat the `last_updated` value (which comes from the USD market-price join) as a freshness guarantee for those other fields.

### 8.2 `public.get_exchange_discovered_market_assets()`

- Exact result contract: 8 columns — symbol, observed name, recent USD price, price timestamp, exchange-source names, distinct source count, observation timestamp, and match status.
- Only active observations seen within 48 hours, with normalized-looking base symbols and statuses `pending`, `ambiguous`, or `unmatched`, are considered.
- It excludes likely tokenized-stock labels and symbols already represented in curated listings or enabled demo pairs.
- Output is grouped by symbol; source names are aggregated, and the most recently observed non-empty name is selected.
- USD price is included only if positive and updated within two minutes.
- No user, wallet, order, reservation, email, or account identifiers are referenced.
- Public exposure reveals exchange names, asset symbols/names, match-state labels and observation recency. This is market-operations metadata, not personal data, but the product owner should explicitly accept that public disclosure.
- Semantics note: a group with only `pending` rows is emitted as `unmatched` because the CASE expression only distinguishes whether any row is `ambiguous`; otherwise it returns `unmatched`.
- Review caveat: the function has no explicit row limit. The 48-hour and eligibility predicates bound the input window, but output cardinality can still grow with distinct symbols.

### 8.3 `public.get_demo_trading_fee_rate(text,text)`

- Exact signature: `(p_quote_asset text, p_liquidity_type text)`; returns a single numeric rate.
- Current EXECUTE roles: authenticated and service_role; anon is not granted execution.
- Reads enabled maker/taker fee values by normalized quote asset. It returns no user or account data.
- The body validates `p_liquidity_type NOT IN ('maker','taker')`, but SQL three-valued logic means a NULL liquidity type does not satisfy that IF condition. In the current CASE expression, every value other than the exact string `maker` selects the taker rate, so NULL is implicitly treated as taker.
- This is not an observed privilege escalation or data disclosure, but it is an input-validation/contract defect candidate. Recommended future correction: explicitly reject NULL and any non-maker/non-taker value, with regression tests for NULL, invalid strings, both valid liquidity types, and unknown/disabled quote assets. Do not change Production as part of this audit.

### 8.4 Public endpoint regression-test requirements

Before treating these public endpoints as stable contracts, a disposable Production-parity database should test:
1. Anon can execute only the two explicitly public market-metadata functions; anon cannot execute the fee function or any other SECURITY DEFINER endpoint.
2. Authenticated can read the same public market metadata and fee configuration, but neither endpoint returns user-specific or wallet/order/reservation data.
3. The market-listing USD price becomes NULL when stale, non-positive, or from a non-CoinGecko source; fresh valid values are returned.
4. Exchange observations older than 48 hours, inactive rows, unsupported statuses, tokenized-stock labels, and already-listed/enabled symbols are excluded.
5. Ambiguous groups remain marked ambiguous; pending-only groups currently map to unmatched (assert current behavior or change only after product decision).
6. Fee function accepts maker/taker, rejects NULL and invalid values after an approved correction, and rejects missing/disabled quote-asset configurations.
7. Public result schemas remain exactly 11, 8, and 1 columns respectively; prevent future additions of personal or account-level fields.

No such runtime tests were run because the existing Recovery-Test project is not a valid Production ACL/Cron/Auth-trigger parity environment.

## 9. Consolidated remaining decisions

- Owner policy decision: whether default function EXECUTE should be removed for `service_role` as well as PUBLIC/anon/authenticated, given no reviewed Edge Function currently uses service-role RPC.
- Resolve the conflict between `tests/default-function-acl-hardening.sql` and the proposed default-ACL SQL draft.
- Determine external/manual caller intent for `claim_admin_asset_refresh(text,uuid)`; do not revoke while unresolved.
- Decide whether public disclosure of exchange source names and observation states is acceptable.
- Decide whether the global 30-second market-price refresh cooldown should remain global or become per-user/per-client; no change before explicit approval.
- Correct NULL liquidity-type validation only after a separately reviewed draft and owner approval.
- Build a disposable environment with matching grants, schema USAGE, Auth trigger, Cron identities, and fixtures before enabling the skipped RPC integration CI job.


## 10. Fee RPC NULL-validation fix — isolated draft and regression test

Created two review-only artifacts on the feature branch:

- `supabase/drafts/2026-11-25_fix_demo_trading_fee_rate_null_validation.sql`
  - Preserves the exact function signature, numeric return type, STABLE volatility, SECURITY DEFINER, and empty search_path.
  - Adds explicit `p_liquidity_type IS NULL` rejection before the maker/taker branch.
  - Does not alter grants, ownership, ACL defaults, or caller authorization.
  - This is deliberately stored under `drafts/`, not as a migration.

- `tests/demo-trading-fee-rate-validation.sql`
  - On a disposable test database with at least one enabled fee row, checks that maker/taker values match the configured table values.
  - Checks that NULL and unsupported liquidity types raise exactly `Invalid liquidity type`.
  - Checks that an unknown quote asset raises the existing configuration error.
  - Performs no persistent table writes or schema/ACL changes.
  - Not executed against Production or the non-parity Recovery-Test project.

The test is a manual isolated-database regression script; it has not yet been wired into CI. It must not be enabled against Production. The proposed SQL has not been applied anywhere.

Remaining verification: run this script against a disposable database with the exact function/table contract, then decide whether to convert the approved SQL into a timestamped migration. Owner approval is required before any Production migration or database change.


## 11. Exact-signature catalog regression contract — refreshed Production snapshot

The test `tests/rpc-security-catalog.sql` was revised to compare the complete tuple:

`(schema_name, function_name, pg_get_function_identity_arguments, anon_execute, authenticated_execute, service_role_execute)`

- The expected inventory contains all 46 SECURITY DEFINER signatures observed in the fresh read-only Production catalog query: 9 in `private` and 37 in `public`.
- The tuple comparison uses bidirectional `EXCEPT`, so it detects missing signatures, unexpected signatures, new overloads, and effective role-EXECUTE drift. Function-name-only matching is no longer used for the inventory or role contract.
- The test separately retains constrained `search_path`, effective PUBLIC EXECUTE prohibition, and schema USAGE assertions.
- The exact current snapshot confirms 36 of the 46 signatures are executable by `service_role`; `public.refresh_market_prices()` is intentionally recorded as not executable by anon, authenticated, or service_role.
- Current anon EXECUTE is present only on `public.get_admin_market_listings()` and `public.get_exchange_discovered_market_assets()`. A prior row in Section 2 incorrectly listed `public.admin_exchange_asset_sync_report()` as anon-executable; the fresh catalog query shows anon=false, and this matrix row has been corrected.
- This is a regression test for the observed CURRENT state, not a proposed target ACL policy. It does not resolve or alter the separate default-function-ACL policy conflict.

The catalog query was SELECT-only. The revised SQL test has been committed to the PR branch but has NOT been executed against Production or the non-parity Recovery-Test project. CI integration remains intentionally skipped until a valid disposable parity environment exists.

No GRANT/REVOKE, function change, default ACL change, migration, db push, Cron/trigger change, Edge Function deployment, or Production write was performed.
