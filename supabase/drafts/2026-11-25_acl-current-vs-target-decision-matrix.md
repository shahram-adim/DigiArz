# DigiArz — Current Production ACL vs Candidate Target Policy

**Status:** REVIEW DRAFT — TARGET POLICY UNDECIDED / OWNER DECISION REQUIRED  
**Evidence date:** 2026-11-25  
**Branch:** `feature/persian-asset-name-candidates-2026`  
**Related PR:** #62  
**Companion evidence:** `2026-11-25_exact-signature-acl-matrix.md`, `2026-11-25_rpc-caller-inventory.md`

## 1. Purpose and safety boundary

This document separates (A) the effective permissions observed in Production from (B) candidate future policy. It is not a migration plan and does not authorize a GRANT, REVOKE, ALTER DEFAULT PRIVILEGES, function invocation, CI gate change, or database write.

**Target policy status: UNDECIDED.** No target role matrix is inferred from current grants or from the absence of a caller in the inspected repository. Any target change remains blocked until the owner explicitly selects the policy and the missing caller/parity evidence is resolved.

Production evidence was gathered through read-only catalog inspection. No SQL function was invoked.

## 2. Current Production effective API-role state

### 2.1 SECURITY DEFINER signature inventory

The current exact-signature snapshot contains 46 SECURITY DEFINER functions across `public` and `private`:

- 36 signatures have effective `service_role EXECUTE`.
- 23 public signatures are executable by both `authenticated` and `service_role`.
- Two of those 23 are additionally executable by `anon`: `public.get_admin_market_listings()` and `public.get_exchange_discovered_market_assets()`.
- 13 signatures are `service_role`-only among API roles.
- `public.refresh_market_prices()` is an important exclusion: it is not executable by anon, authenticated, or service_role; its observed EXECUTE privilege is for `postgres`.

The companion exact-signature matrix is authoritative for the complete identity-argument tuples and current role booleans. Do not replace signature matching with function-name-only matching.

### 2.2 Current role summary

| Permission dimension | Observed Production state | Interpretation |
|---|---|---|
| SECURITY DEFINER inventory | 46 exact signatures | 9 private + 37 public |
| service_role EXECUTE | 36 signatures | Effective function privilege, not table access/RLS bypass |
| authenticated EXECUTE | 26 signatures | Includes private functions; 23 public signatures are also service_role-executable |
| anon EXECUTE | Exactly 2 signatures | Public market-metadata read endpoints |
| PUBLIC EXECUTE | No effective PUBLIC EXECUTE on the audited 46 signatures | This is current-object state, not future-function default behavior |
| public schema USAGE | anon, authenticated, service_role = true | Schema access is a separate ACL dimension |
| private schema USAGE | authenticated = true; anon and service_role = false | Schema access is a separate ACL dimension |

### 2.3 Current default-function ACL state and discrepancy

The read-only Production audit found default ACL entries for function creation by `postgres` and `supabase_admin` in the public schema, as well as PostgreSQL's global function EXECUTE default behavior. Supabase-managed `supabase_admin` defaults are not treated as user-editable.

Two repository artifacts currently encode different future expectations for functions created by `postgres`:

| Source artifact | Candidate expectation | Status |
|---|---|---|
| `tests/default-function-acl-hardening.sql` | Remove global PUBLIC EXECUTE; remove public-schema defaults for PUBLIC/anon/authenticated; **retain public-schema default EXECUTE for service_role** | Test contract only; not run against a parity DB |
| `supabase/drafts/2026-11-25_proposed_restrict_default_public_function_exec.sql` | Remove global PUBLIC EXECUTE and public-schema defaults for PUBLIC/anon/authenticated/**service_role**; use exact per-function grants if needed | Comments-only proposal; not executable/applied |

**These expectations conflict. Neither is approved as the target.** Do not silently edit either artifact to make them agree. The current object ACL snapshot does not settle the future default policy.

## 3. Caller evidence for the 13 current service_role-only signatures

| Exact signature | Current observed grant | Inspected caller evidence | Candidate disposition (not target approval) |
|---|---|---|---|
| `public.claim_admin_asset_refresh(text,uuid)` | service_role | Active Production Edge Function `admin-refresh-crypto-asset` v2 verifies the user JWT and super-admin status, then invokes this RPC through a server-side service-role client | **CONFIRMED FUNCTION-SPECIFIC CALLER** — preserve the explicit grant; this does not decide default EXECUTE policy for other/future functions |
| `public.new_user_setup()` | service_role | `auth.users.on_auth_user_created` trigger; trigger path runs as postgres-owned SECURITY DEFINER | Observed path does not need service_role EXECUTE; external callers not fully ruled out |
| `public.process_bit24_exchange_sync()` | service_role | Active Cron, username postgres, scheduled minutes 16 and 46 | Observed path does not need service_role EXECUTE; preserve worker |
| `public.process_conditional_orders()` | service_role | Active Cron, username postgres, every minute | Observed path does not need service_role EXECUTE; preserve worker |
| `public.process_iran_exchange_asset_sync()` | service_role | Active Cron, username postgres, scheduled minutes 1 and 31 | Observed path does not need service_role EXECUTE; preserve worker |
| `public.process_limit_orders()` | service_role | Active Cron, username postgres, every minute | Observed path does not need service_role EXECUTE; preserve order engine |
| `public.process_stop_limit_orders()` | service_role | Active Cron, username postgres, every minute | Observed path does not need service_role EXECUTE; preserve order engine |
| `public.recover_stale_crypto_assets_sync()` | service_role | Active Cron, username postgres, every 5 minutes | Observed path does not need service_role EXECUTE; preserve worker |
| `public.refresh_crypto_assets()` | service_role | Active Cron, username postgres, minutes 6,16,26,36,46,56 | Observed path does not need service_role EXECUTE; preserve worker |
| `public.refresh_crypto_assets_toman()` | service_role | Active Cron, username postgres, minutes 7,17,27,37,47,57 | Observed path does not need service_role EXECUTE; preserve worker |
| `public.refresh_market_fx_rate()` | service_role | Active Cron, username postgres, every minute | Observed path does not need service_role EXECUTE; preserve worker |
| `public.request_bit24_exchange_sync()` | service_role | Active Cron, username postgres; also nested from postgres-owned `admin_request_exchange_asset_sync()` | Observed paths do not need service_role EXECUTE |
| `public.request_iran_exchange_asset_sync()` | service_role | Active Cron, username postgres; also nested from postgres-owned `admin_request_exchange_asset_sync()` | Observed paths do not need service_role EXECUTE |

The nested request functions are called inside a postgres-owned SECURITY DEFINER parent; this does not establish a service_role client caller. All 14 observed Cron jobs (including the market-price worker) remain active and must not be disabled or slowed.

## 4. Current state vs candidate target policy — decision register

| Permission area | Current Production state | Candidate future direction | Target decision |
|---|---|---|---|
| Existing 23 authenticated public signatures | authenticated + service_role; two also anon | Preserve authenticated access only after exact body/ownership tests; any service_role change needs caller evidence | **UNDECIDED** |
| Two anon market metadata RPCs | anon + authenticated + service_role | Keep public only if owner accepts disclosure of source names, observation states, and catalogue metadata | **OWNER DECISION REQUIRED** |
| `get_demo_trading_fee_rate(text,text)` | authenticated + service_role; anon denied | Maintain authenticated read if fee configuration is approved for clients; NULL validation defect is a separate code fix | **UNDECIDED** |
| 12 Cron/Auth-trigger service_role-only signatures | service_role EXECUTE currently present; observed execution paths run as postgres | Possible removal of blanket API-role grant only after external caller audit and Production-parity negative/positive tests; worker execution itself must remain unchanged | **BLOCKED — PARITY + OWNER APPROVAL** |
| `claim_admin_asset_refresh(text,uuid)` | service_role EXECUTE currently present | No safe target can be proposed until intended caller/rate-limit design and out-of-repo callers are established | **UNRESOLVED — DO NOT REVOKE** |
| `public.refresh_market_prices()` | postgres-only effective EXECUTE; no service_role EXECUTE | Preserve observed postgres Cron path; do not add to service_role allowlist | **NO CHANGE PROPOSED** |
| Future functions created by postgres — global default | Current defaults include PostgreSQL global behavior; production default ACL inventory is documented separately | Candidate: revoke global PUBLIC EXECUTE so new functions do not become public implicitly | **OWNER DECISION REQUIRED** |
| Future public functions created by postgres — schema defaults | Current public default ACL grants are present for API roles | Candidate A: retain service_role default; Candidate B: remove service_role default and grant exact signatures only | **CONFLICT — OWNER DECISION REQUIRED** |
| Future functions created by supabase_admin | Supabase-managed default ACL exists and is not user-editable by the owner under current platform behavior | Do not attempt to alter managed defaults; inventory/exposure remains a separate exception | **NO OWNER-SIDE ALTER PROPOSED** |
| public/private schema USAGE | public: anon/authenticated/service_role; private: authenticated only | Keep separate from function EXECUTE decisions; any change requires its own call-path analysis | **NO CHANGE PROPOSED** |

No row in the candidate column is an approved target grant. “No change proposed” means only that this review has no supported change proposal; it is not a statement that a future policy decision is unnecessary.

## 5. Owner decisions required before target matrix can be finalized

1. **Default service_role policy:** Should newly created public functions default to service_role EXECUTE, or should service_role receive only exact per-signature grants when a reviewed caller needs them?
2. **Public metadata disclosure:** Is anonymous access to the two market metadata RPCs acceptable, including exchange source names, observed asset names, match states, and observation recency?
3. **Unresolved refresh claim caller:** Is `claim_admin_asset_refresh(text,uuid)` used by any external/manual deployment, or is a new caller/rate-limit path intended? Do not revoke before answering and searching accessible deployment evidence.
4. **Global default PUBLIC behavior:** Approve or reject removing PostgreSQL's global PUBLIC EXECUTE default for postgres-created future functions.
5. **Authenticated/public endpoint contract:** Confirm the intended public/read exposure for fee configuration and the two market metadata endpoints.

A response to these policy questions does not itself authorize Production execution. Any later Production change still requires a separately reviewed exact-signature migration and explicit execution approval.

## 6. Evidence and test blockers

- The Recovery-Test project is healthy but is **not** a Production-parity environment: its 13 service_role-only candidate functions have NULL `proacl` and are effectively callable by anon/authenticated/service_role; it lacks the Production default-function ACL state, Cron relation/jobs, and Auth trigger wiring.
- Do not use that project to claim parity or to validate the exact Production ACL contract.
- The current `tests/rpc-security.integration.sql` exercises only a limited admin guard using temporary grants/rollback; it does not test the complete 46-signature catalog, cross-user IDOR attempts, anon data boundaries, or real ACL inheritance.
- The RPC integration CI job remains intentionally skipped. Do not enable it until a valid disposable parity environment and approved target policy exist.
- The exact-signature catalog test is a CURRENT-state snapshot, not a target-state test. It has not been run against Production or the non-parity Recovery-Test project.
- No new Supabase project/branch has been provisioned; provisioning/cost requires separate approval.

## 7. Explicit non-actions

No Production SQL, function invocation, GRANT, REVOKE, ALTER DEFAULT PRIVILEGES, DDL, migration, db push, data change, Cron/trigger change, Edge Function deployment, secret change, CI gate enablement, Supabase provisioning, paid upgrade, or PR merge was performed in preparing this document.


## Superseding evidence — claim RPC caller and isolated behavior test

The caller for `public.claim_admin_asset_refresh(text,uuid)` is no longer unresolved. The active deployed Edge Function `admin-refresh-crypto-asset` v2 is the confirmed caller and requires this exact explicit service_role EXECUTE grant. Its source validates the Bearer token, verifies super-admin status through the user-scoped RPC, and derives the UUID from the verified Auth response before calling the claim RPC.

A source-faithful PostgreSQL 17 fixture now tests the real Migration body, exact boolean return type, non-admin denial, invalid input, and 30-second cooldown. CI run `45600501368` passed. This per-function finding does not settle the owner decision about future/default service_role EXECUTE privileges.
