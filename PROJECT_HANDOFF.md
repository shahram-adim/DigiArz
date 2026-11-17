# DigiArz — Project Handoff

> Operational rule: **Do not repeat completed work. Verify before acting.**
> This file is the durable handoff for work across ChatGPT sessions. GitHub/Supabase live state outranks this document; update this file after every material change.

## Project identity
- Product: DigiArz, Persian-language Android demo crypto exchange.
- Market prices/data may be real; balances and trades are virtual/demo only.
- GitHub: https://github.com/shahram-adim/DigiArz
- Default branch: `main`
- Supabase project ref (known): `gfoaubfilhttnwjykaox`

## Mandatory workflow — anti-duplication
1. At the start of every work session, read this file from the default branch and inspect live GitHub PRs, branch heads, recent commits, and relevant CI. For Supabase work, read the current live schema/state before proposing or applying changes.
2. Identify the exact task, branch, file paths, commit SHA, and acceptance criteria already completed. Do not recreate, re-run, or re-implement completed work unless a fresh check proves it is missing or broken.
3. Before editing a file, fetch its current contents and blob SHA. Never overwrite a newer change. Inspect diffs and related tests first.
4. Make the smallest safe change. Do not modify unrelated PRs/branches. Do not merge drafts or deploy to Production without explicit readiness and safety checks.
5. After each material step, record: date/time, branch, commit SHA, files changed, tests and exact run IDs/results, what remains, and the single next action.
6. If evidence conflicts or status is uncertain, stop and verify; do not guess or ask the user to repeat information already available in the repo.
7. Never claim an action succeeded until GitHub/Supabase confirms it.
8. Keep known Production risks visible. A passing synthetic fixture or CI is not proof of Production schema compatibility or deployment readiness.

## Live GitHub snapshot
Verified on 2026-11-18 around 01:02 (+03:30), using GitHub API:
- Open Draft PR #11: `perf/iran-exchange-matcher-design`, head `dd7b9395275344e68d390da4a2fa66fd63e94dd3`, base `main`.
- Open Draft PR #10: `diagnostics/auth-cron-connection-pressure`, head `e9d5e5f49726ad85dc6b947c2c1c651a49b7ff9e`.
- Open Draft PR #9: `fix/android-offline-asset-cache`, head `9130d3a27fd45632a08671272751e9c752d522ba`.
- Open Draft PR #8: `fix/iran-exchange-sync-response-race`, head `82bf2cc70643a5c747f4ff097c8d4a7444995032`.
- PRs #1–#7 are closed and merged (confirmed via GitHub API).
- No other PRs were returned by the all-PRs query (1–11).

### PR #11 — matcher design / synthetic fixtures
- URL: https://github.com/shahram-adim/DigiArz/pull/11
- Branch: `perf/iran-exchange-matcher-design`
- Current head at snapshot: `dd7b9395275344e68d390da4a2fa66fd63e94dd3`
- Draft; do not mark ready or merge solely because CI passes.
- Previously observed successful workflow runs: matcher fixture `44179246487`; exact-decimal `44179247699`. Recheck these/current checks before relying on them.
- Scope is synthetic fixture/docs, not Production changes.
- Fixture work already documented includes matcher equivalence, heartbeat-only no-dirty behavior, changed-input dirtying, two-session SKIP LOCKED row-claim primitive, catalog insert/rename/deactivation, multi-page cursor, alias insert/delete stale-match clearing, and response queue retry/dead-letter fixture extension (per latest PR description).
- Known remaining validation gaps from the last code review: catalog-job worker concurrency; committed-page restart/recovery; interleaved catalog event while another cursor is partway through; no-starvation/loop bounds; Production schema compatibility, leases/recovery, query plans, ACLs/triggers/grants, and migration-history reconciliation. **Reinspect current branch files/tests before implementing any of these; some may since have been completed.**
- PR #11 must remain isolated from PR #8.

### PR #10 — Auth/cron/connection diagnostics
- URL: https://github.com/shahram-adim/DigiArz/pull/10
- Branch head at snapshot: `e9d5e5f49726ad85dc6b947c2c1c651a49b7ff9e`.
- Diagnostics/docs only. Prior CI was reported successful, but recheck live runs.
- Shared/Nano compute or API health does not by itself prove database latency/connection health. Keep Draft pending authoritative metrics/support evidence.

### PR #9 — Android offline cache
- URL: https://github.com/shahram-adim/DigiArz/pull/9
- Branch head at snapshot: `9130d3a27fd45632a08671272751e9c752d522ba`.
- Real install/offline test on Android device has not been confirmed in the saved project record. Verify current state before repeating or requesting a test.

### PR #8 — Iran exchange sync response race
- URL: https://github.com/shahram-adim/DigiArz/pull/8
- Branch head at snapshot: `82bf2cc70643a5c747f4ff097c8d4a7444995032`.
- Historical note: branch was reported diverged (31 ahead / 17 behind) and non-mergeable. This must be rechecked live.
- Do not rebase, merge, force-push, or change this branch until a controlled reconciliation plan and CI validation are complete.
- Historical draft SQL: `supabase/drafts/2026-11-17_process_iran_exchange_asset_sync_race_fix.sql`. Re-fetch before relying on any prior details.

## Production / Supabase safety notes
These are historical observations, not proof of current state. Revalidate before acting:
- Production previously showed repeated PostgreSQL/cron startup timeouts and statement timeouts in the Iran exchange sync path.
- Potential connection/resource pressure and upstream DNS/network timeouts were observed; CPU/memory saturation was not proven.
- `public.exchange_asset_observations` Production creation migration was not found in the repo at the last review; do not assume repository migrations reconstruct Production.
- No Production rollout until authoritative schema/index/trigger/grant state, migration history, worker claiming/recovery semantics, concurrency, and query plans are reconciled.
- Do not run `supabase db push` while migration history/schema drift remains unresolved.
- Avoid repeated heavy SQL during known DB instability.
- Do not add indexes, alter triggers, change cron, or modify balances/orders without evidence and explicit safety review.
- For any SQL request to the user, include the direct SQL editor URL: https://supabase.com/dashboard/project/_/sql/new

## Build / device validation
- An Android debug APK was previously built by Actions run `44085696047`, artifact `DigiArz-Android-debug-APK`.
- Actual installation and offline/functional testing on the user's phone were not confirmed in the prior record. Recheck Actions/artifact and ask only for the specific device result still missing.

## Current next action
**Re-establish the live project baseline before choosing the next implementation task.** Re-fetch PR #8–#11 details, their current heads and checks, recent `main` commits, and relevant branch file contents. Then select the highest-priority unfinished item based on the user's approved project scope. Do not assume PR #11 is the whole project or that historical TODOs are still outstanding.

## Change log
- 2026-11-18 01:02 (+03:30): Created this handoff from the live all-PRs GitHub API snapshot plus previously recorded project notes. PR states/heads are live-verified; Production and device notes are explicitly historical and require revalidation.


## Live audit and priority decision — 2026-11-18
Verified directly against GitHub and Supabase after the previous handoff snapshot:

### Current live state
- GitHub main latest commit at audit start: b8e79735100d8d26cb594147b5fc78d8b7c63c2b (handoff file itself is the latest commit).
- Open Draft PRs remain #8–#11; no new PR appeared. PR #8 head 82bf2cc70643a5c747f4ff097c8d4a7444995032; #9 9130d3a27fd45632a08671272751e9c752d522ba; #10 e9d5e5f49726ad85dc6b947c2c1c651a49b7ff9e; #11 dd7b9395275344e68d390da4a2fa66fd63e94dd3.
- PR #11 latest head checks: matcher-fixture and exact-decimal both completed successfully (2026-11-17 21:23–21:24 UTC). This does not close its Production readiness gates.
- PR #9 APK build check on its head succeeded (2026-11-17 12:44 UTC); actual device install/offline QA remains unconfirmed.
- Supabase project gfoaubfilhttnwjykaox is ACTIVE_HEALTHY, PostgreSQL 17.11.0.018. Health advisor returned no lints. These signals do not establish acceptable query latency or connection reliability.

### Fresh Production evidence (read-only)
- Live Supabase migration history currently returns **52 applied entries**; GitHub main contains **40 SQL migration files**.
- Reconciliation report supabase/MIGRATION_RECONCILIATION.md still matches the live inventory: 14 applied versions have no local SQL source, 20 local files have timestamp-prefix mismatches, 2 local-only files are unrecorded, and only 4 local files match applied versions exactly.
- The two local-only files 20261116203000_add_kucoin_to_scheduled_market_price_refresh.sql and 20261116203100_add_gateio_to_scheduled_market_price_refresh.sql replace public.refresh_market_prices() with older definitions missing the later 515-ID CoinGecko cap. The report records that Production already has the cap and CoinGecko/KuCoin/Gate.io branches. **supabase db push remains prohibited.**
- Unified logs (default last-24-hour window) returned 480 PostgreSQL ERROR events, 276 WARNING events, and 2 FATAL events across all PostgreSQL sources; these aggregate counts are not all attributable to DigiArz application code.
- A targeted log query found **236 SQLSTATE 57014 cancellation events** whose context references public.process_iran_exchange_asset_sync() between 2026-11-17 08:31 and 20:49 UTC, plus 46 context events with SQLSTATE 00000. Recent samples show cancellations during the bulk observation upsert (function line 4) and matching/update query (line 44). This is direct evidence the sync worker remains a current operational bottleneck; it does not by itself prove whether CPU, I/O, locks, query plan, or shared connection pressure is the root cause.
- No Production schema, migration history, cron, function, order, wallet, balance, or market data was modified during this audit.

### Priority decision — next work must address safe Production diagnosis, not add another feature
1. **First priority:** obtain a bounded, read-only diagnosis of the live process_iran_exchange_asset_sync() hot path and cron overlap using authoritative current function/schema/index definitions and relevant execution evidence. Avoid repeating heavy catalog queries; stop if connection/timeouts recur.
2. **Release blocker:** reconcile the 52-entry Production migration inventory against the 40 local files, recovering the 14 missing SQL sources and verifying the 20 timestamp mismatches by full SQL content. Keep the two older local-only market-price replacements out of any replay path until superseded safely.
3. Keep PR #8 isolated and do not rebase/merge it until the live comparison is recalculated and the branch is safely reconciled. Keep PR #11 Draft until its documented fixture gaps and Production compatibility gates are actually closed.
4. Device QA for PR #9 is still a user-device acceptance step; do not claim it passed without the user's actual test result.

**Single next action:** continue with one targeted read-only review of the current live sync function and its existing cron job configuration, then decide whether a test-only/query-plan investigation can safely proceed. No DDL, cron edits, function replacement, migration push, or Production data changes are authorized by this audit.
