# CI database-target guard review (2026-11-25)

Status: REVIEW ONLY. No workflow, secret, database, ACL, migration, or production setting was changed by this review.

## Finding

The `rpc-security-integration` job currently checks whether the raw `DIGIARZ_TEST_DB_URL` string contains the test project ref `zrriqwyolcjhbappocuw`.

That is not a destination-authentication check. A URL can contain the expected ref in a password, query parameter, path, or other non-host component while resolving to an unrelated database host. The current check can therefore accept an unintended destination.

The integration job remains opt-in through `vars.DIGIARZ_ENABLE_RPC_SECURITY_TESTS == 'true'`; its latest observed run was skipped. Do not enable it until the destination check and environment-parity prerequisites are resolved.

## Safe validation design

1. Parse the value as a URL with a standard URL parser; reject malformed URLs, unexpected schemes, missing hostname, embedded whitespace, and unsupported URL forms.
2. Never echo the URL, username, password, query string, or secret to logs. Diagnostics should report only a reason code such as `invalid_url`, `unexpected_host`, or `missing_project_identity`.
3. Prefer an exact allowlist for the dedicated test project's direct database hostname, if the repository secret is confirmed to use the direct connection form.
4. If the secret uses Supabase's shared pooler, implement a separate explicit pooler validation rule based on the documented hostname suffix AND the expected project identity in the exact documented username format. Do not accept the project ref merely because it occurs somewhere in the raw URL.
5. Reject redirects or alternate hosts; do not infer safety from a password/query/path substring.
6. Keep the secret unavailable to untrusted fork pull-request workflows.

## Required negative and positive tests

- malformed URL and empty secret => reject;
- expected project ref only in password => reject;
- expected project ref only in query string or path => reject;
- wrong hostname with expected project ref elsewhere => reject;
- unexpected scheme, port, or host suffix => reject;
- exact dedicated direct-host form => accept only if direct connection mode is explicitly confirmed;
- pooler hostname with wrong/missing project identity => reject;
- documented pooler host + exact expected project identity format => accept only if pooler mode is explicitly confirmed;
- logs contain no credential, URL, username, password, or query value.

## Blocking decisions and environment caveats

- Connection mode is not yet confirmed: direct database hostname or Supabase pooler. Do not change the workflow until the owner confirms which form the CI secret uses. The secret value itself must not be retrieved or printed for this review.
- The test project previously inspected is not an exact Production-parity environment: it lacks matching function default ACLs, has 13 service-role-only Production functions exposed more broadly in the test project, lacks `cron.job`, and lacks the `auth.users -> new_user_setup()` trigger. It must not be treated as a Production ACL/Cron/Auth parity oracle.
- The default function EXECUTE policy remains unresolved: the current hardening assertion and proposed SQL disagree about whether future public-schema functions should default to service_role EXECUTE. Keep the integration job skipped until the owner chooses a policy and the assertions are made consistent.
- The `claim_admin_asset_refresh(text,uuid)` caller provenance remains unresolved. Do not revoke or alter its grants based only on the absence of an in-repository browser/Edge/Cron caller.

## Explicitly unchanged

No secret was read or changed. No workflow was edited or enabled. No CI integration job was triggered. No database was contacted by this report. No ACL/GRANT/REVOKE, DDL, migration, Cron, trigger, Production data, Supabase project, or billing setting was changed. PR #62 remains Draft and unmerged.
