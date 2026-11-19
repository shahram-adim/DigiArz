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


### Follow-up live matcher investigation — 2026-11-18 (read-only)
- Re-read the current Production definition of public.process_iran_exchange_asset_sync(): SECURITY DEFINER, owner postgres, empty search_path, source length 9,982 characters. No function change was made.
- Confirmed active cron jobs: job 13 requests Iranian exchange sync every 10 minutes; job 14 runs process_iran_exchange_asset_sync() every minute; job 17 requests market-price overflow at minutes 5,15,25,35,45,55. No cron change was made.
- Current relevant indexes: crypto_assets has lower(name), lower(symbol), primary key(coingecko_id), market-cap and rank indexes; exchange_asset_observations has upper(base_symbol), primary key(id), unique(exchange,market_symbol), and (match_status,last_seen_at DESC). No upper(symbol) expression index exists on crypto_assets.
- Current cumulative statistics (not reset/windowed): crypto_assets has 18,874 live rows, 573,487 sequential scans and 10,816,317,434 sequential tuples read; its lower(symbol) index has only 26 scans. exchange_asset_observations has 4,960 live rows and 3,307 sequential scans; its upper(base_symbol) index has 787 scans. These counters are cumulative and do not identify which query caused each scan.
- A read-only EXPLAIN (no ANALYZE) of the simplified production matcher join upper(ca.symbol)=upper(o.base_symbol) produced a Hash Join with a Sequential Scan over all 18,874 crypto_assets rows; the observation side used exchange_asset_observations_symbol_idx. This confirms the simplified join does not use the existing lower(symbol) index, but it does **not** prove that an upper(symbol) index should be created or that this plan alone caused the function timeouts. No index or DDL change was made.
- The current integration fixture already covers catalog insert/rematch, symbol rename/stale-match clearing, deactivation, multi-page cursor progress with a convergence guard, and Kifpool alias insertion/removal. Do not reimplement these tests. Still-open catalog-queue coverage is concurrent catalog workers, committed-page restart/recovery, interleaving a new catalog event while an earlier cursor is part-way through, and explicit no-starvation guarantees. Recheck the latest fixture before adding any tests.
- Current Production bottleneck remains the one-minute sync function: targeted logs showed 236 SQLSTATE 57014 cancellation events during 2026-11-17 08:31–20:49 UTC. The function's line 4 bulk observation upsert and line 44 matching/update statement both appear in recent cancellation contexts. The exact root cause is not yet established.

**Refined next action:** do not create a Production index or rewrite the worker from the simplified EXPLAIN alone. First add a test-only PostgreSQL 17 plan/scale experiment that compares the existing lower(symbol) index with a candidate upper(symbol) expression index under representative catalog/observation cardinalities, then record whether the candidate changes the plan and actual fixture timings. Keep all changes isolated to PR #11 or a dedicated test branch; no Production DDL, cron, function, or data change.


### Work started from the 2026-11-18 priority decision
- Rechecked PR #11 fixture before editing. Catalog insert/rematch, symbol rename/stale-match clearing, deactivation, multi-page cursor convergence, and Kifpool alias add/remove tests were already present. These were not recreated.
- Read-only Production plan evidence and current table/index stats are recorded in the PR #11 design document.
- Added a separate disposable PostgreSQL 17 scale/plan experiment at supabase/tests/iran_exchange_matcher_plan_fixture.sql. It compares a lower(symbol)-only baseline with a candidate upper(symbol) expression index for both a 100-row dirty batch and a full 4,960-observation join, using 18,874 synthetic catalog rows. It records EXPLAIN ANALYZE timings, buffers, and plan shape. The candidate index exists only on temporary fixture tables.
- Wired the experiment into .github/workflows/iran-exchange-matcher-tests.yml and documented its limits in docs/IRAN_EXCHANGE_MATCHER_INCREMENTAL_DESIGN_2026-11-17.md.
- PR #11 latest head: 79a172dcec406e43be4c900dfd348cef8251f330 (still Draft).
- CI runs on latest head are queued/in progress at last check: matcher fixture 44182523044; exact-decimal 44182523061. Earlier workflow runs on the preceding head 9d722131c9d74d928742f822aab539d94779bb61 were also in progress. Do not claim the new experiment passed until the latest-head matcher run completes successfully and its output is inspected.
- No Production index, DDL, function, cron, migration history, orders, balances, or data were changed.

**Next action:** inspect the latest-head matcher workflow result and its plan output. If the experiment fails, fix only the test fixture and rerun; if it passes, record the observed plan/timing comparison and decide whether further synthetic testing is warranted. Do not create any Production index from this experiment alone.


### Matcher plan experiment — initial result and repeated-run refinement — 2026-11-18
- First single-pass disposable PostgreSQL 17 experiment passed on PR #11 head 79a172dcec406e43be4c900dfd348cef8251f330 (run 44182523044).
- One warm-ish fixture pass measured dirty batch (100 observations): 4.534 ms with only lower(symbol), versus 0.137 ms with candidate upper(symbol); full 4,960-observation join: 7.644 ms versus 5.384 ms. The candidate changed the dirty-batch plan from full catalog Seq Scan/Hash Join to catalog upper(symbol) Index Scan/Merge Join. Full-scan behavior used a different plan and did not show the same magnitude of benefit.
- These are single-run synthetic fixture observations only; they are not robust benchmarks and are not proof that a Production index is appropriate. No Production change was made.
- To avoid over-relying on one run, the fixture was refined in commit b19273edc94a98c603b3e10529f86c88499c680d to warm each scenario and collect five warm-cache runs, reporting median/min/max plus representative plan. This is a test-only change on PR #11 branch.
- New-head CI runs 44182855849 (matcher fixture) and 44182856169 (exact-decimal) were in progress at the last check. Do not report the repeated-run experiment as passing until run 44182855849 completes successfully and its output is inspected.
- PR #11 remains Draft. Production DDL/index/function/cron/data are unchanged.


### Repeated matcher plan experiment — completed — 2026-11-18
- PR #11 plan fixture was upgraded from one timing per case to one warm-up plus five measured warm-cache runs per case; commit b19273edc94a98c603b3e10529f86c88499c680d.
- Latest matcher CI on that commit passed: run 44182855849 (PostgreSQL 17.12).
- Five-run medians (synthetic fixture): dirty batch 100 rows, lower(symbol)-only 6.188 ms vs candidate upper(symbol) 0.170 ms; full 4,960-row join 10.549 ms vs 7.422 ms. Dirty-batch plan changes from catalog Seq Scan/Hash Join to catalog upper(symbol) Index Scan/Merge Join. Full scan improves less.
- The repeated measurements are warm-cache and use unique synthetic symbols, simplified SQL, and only the current 18,874/4,960 row cardinalities. No duplicates/ambiguous symbols, alias resolution, source priority, concurrent writes, index maintenance, or Production hardware behavior is represented. Evidence supports further test-only exploration of incremental batches; it is **not** sufficient to recommend or deploy a Production index.
- Results and limitations are recorded in docs/IRAN_EXCHANGE_MATCHER_INCREMENTAL_DESIGN_2026-11-17.md on PR #11 branch.
- Exact-decimal workflow on the same PR head b19273edc94a98c603b3e10529f86c88499c680d, run 44182856169, was still in progress at last check. Do not treat the full PR checks as green until it completes.
- PR #11 remains Draft; Production remains unchanged.


### Catalog queue recovery/interleaving/concurrency — implementation and matcher CI success — 2026-11-18
- User authorized proceeding from the prior checkpoint without repeating completed tests.
- Added focused test-only file supabase/tests/iran_exchange_matcher_catalog_queue_concurrency.sql; wired into matcher workflow after existing matcher/plan/response-queue fixtures. Existing matcher semantics, multipage convergence, alias insert/remove, response queue lease/retry, and response-worker concurrency tests were not recreated.
- Coverage added:
  1. Simulated worker crash before commit: both cursor advancement and dirty-row enqueue roll back atomically; a restarted worker resumes from durable cursor across committed pages and completes the job.
  2. Interleaved catalog event: event A is partway through its cursor when event B arrives; A's cursor remains intact, B receives an independent cursor, and both eventually match.
  3. Two independent dblink PostgreSQL sessions: worker A holds the oldest catalog job lock; worker B skips the locked job and advances the next job. After A commits, the oldest job resumes; bounded convergence asserts neither job starves.
- Initial CI run found a wrong assertion in the new test (expected first rather than second ID after a two-row page). Corrected the assertion only; no Production logic changed.
- Latest matcher fixture run 44184100854 on commit d121c4cc303774ab0012acde93f7efc7ec710c73 passed. Logs explicitly say “Catalog queue recovery, interleaving, and concurrent-worker tests passed”.
- Exact-decimal workflow for the same commit, run 44184100898, was still in progress at last check. Prior exact-decimal run 44182856169 on commit b19273edc94a98c603b3e10529f86c88499c680d completed successfully; do not claim latest-head exact-decimal run passed until verified.
- PR #11 remains Draft. No Production DDL/index/function/cron/migration/data/order/wallet/balance changes. No merge and no supabase db push.
- Design/results details recorded in docs/IRAN_EXCHANGE_MATCHER_INCREMENTAL_DESIGN_2026-11-17.md on PR #11 branch.
- Immediate next step: verify exact-decimal run 44184100898 (and current PR head/checks), then inspect remaining uncovered queue invariants only if they are not already represented in fixtures. Keep PR #11 Draft pending broader production-schema/concurrency/query-plan/migration reconciliation gates.

## Market logos and 24h ranking consistency — 2026-11-19
- Work branch: `fix/market-logo-and-ranking-consistency`, created from verified `main` HEAD `ad8d52bf49027b20756242259b1de867c04d5ab9`.
- Root cause confirmed from live Supabase Edge Function source: active `app-assets` v1 used only the SpotHQ cryptocurrency icon set; missing symbol files returned HTTP 404.
- Branch changes: `index.html` now resolves curated HTTPS `image_url` metadata when available, then tries the existing `app-assets` route and a CoinCap fallback before the text fallback. The repository now contains `supabase/functions/app-assets/index.ts` with a two-provider logo fetcher; this source has **not** been deployed to Supabase.
- Branch changes: one freshness-aware `getMarketChange24h` helper and deterministic `sortMarketRowsByChange` comparator now drive the market list, top gainers, top losers and volatility summary. Gainers sort descending; losers ascending; stale stored percentages are excluded; tie order is deterministic by symbol; summary gain/loss selects positive/negative values only.
- Added regression tests to `tests/index-syntax.test.js` for helper ordering, stale data, shared view ranking and logo fallbacks.
- Manual V8 check passed: all three inline scripts parsed; test sample returned descending `BTC, DOGE, ADA, SOL, ETH`, ascending `ETH, SOL, ADA, DOGE, BTC`; stale fallback was rejected and fresh fallback accepted.
- No Supabase Production deployment, schema/migration/cron/RPC changes, or financial data changes were made.
- Pending: open Draft PR, verify GitHub Actions `node --test tests/*.test.js` and the rest of the exact-decimal workflow, fix failures, then separately decide whether to deploy the Edge Function. Android visual QA and a live smoke test for previously missing symbols remain outstanding.

## PR #13 opened — market logos and 24h ranking — 2026-11-19
- Draft PR: https://github.com/shahram-adim/DigiArz/pull/13
- Base: `main` at `ad8d52bf49027b20756242259b1de867c04d5ab9`; head branch: `fix/market-logo-and-ranking-consistency`.
- Latest code/test head at this checkpoint: `693a598a0d51076e6c1981728725413074e57a6a`.
- Follow-up audit found the dashboard market preview had a second independent percentage parser and comparator. It has now been aligned to `getMarketChange24h` / `compareMarketChange`, and regression assertions cover dashboard gainers/losers too.
- GitHub Actions run `44475074226` on the latest code head: Node test step `node --test tests/*.test.js` completed successfully. PostgreSQL integration steps are still running; do not claim the whole workflow passed yet.
- PR remains Draft, not merged. Production Supabase `app-assets` remains at its previously inspected v1; new two-provider Edge Function source exists only in the GitHub branch and has not been deployed.
- Next action: verify the remaining exact-decimal workflow steps and PR checks, then decide separately whether the Edge Function is ready for deployment. No user financial data, DB schema, migrations, cron, RPC, wallets, balances, orders or trades were changed.


### نتیجهٔ نهایی CI برای PR #13 — ۱۹ نوامبر ۲۰۲۶
- GitHub Actions run `44475236966` روی head `209634cb797fcea379a728bf5bd4d23ad9f8e1e0` با نتیجهٔ نهایی `success` تکمیل شد.
- همهٔ مراحل job از ۱ تا ۴۳ موفق شدند؛ تست‌های Node/browser و تمام مراحل PostgreSQL ایزوله برای arithmetic، widening/preflight/rollback، Market/Limit، رزرو و rounding، Stop-Limit، TP/SL، lifecycle و raceهای دو نشست مستقل موفق شدند.
- PR #13 هنوز open و Draft است، merge نشده و base همچنان `main` با SHA `ad8d52bf49027b20756242259b1de867c04d5ab9` است.
- CI سبز به معنی deploy یا تأیید Production نیست. Edge Function `app-assets` جدید هنوز deploy نشده؛ هیچ schema، migration، cron، RPC یا دادهٔ مالی Production تغییر نکرده است.
- Android visual QA و live logo smoke test هنوز انجام نشده‌اند.

**Next:** بازبینی نهایی PR و تکمیل تست بصری Android؛ merge و deploy را جداگانه و فقط پس از تأیید صریح انجام بده.


### تأیید اجرای دوم CI — ۱۹ نوامبر ۲۰۲۶
- Run `44475656448` روی commit `33eb1e5b94d5fb2a2019294e3be12a5afcc4cc58` با نتیجهٔ `success` تمام شد؛ تمام ۴۳ مرحله موفق شدند.
- مراحل Node/browser و PostgreSQL ایزوله، از جمله widening، lock timeout، rollback، Market/Limit، Stop-Limit، TP/SL، rounding و رقابت دو نشست موفق شدند.
- PR #13 باز و Draft است؛ merge نشده؛ main همچنان `ad8d52bf49027b20756242259b1de867c04d5ab9` است.
- هیچ deploy یا تغییر دیتابیس Production انجام نشده؛ Edge Function لوگو هنوز deploy نشده و Android visual QA/live smoke test باقی است.

**Next:** تست بصری در Android و تصمیم جداگانهٔ تأییدشده برای merge/deploy.
