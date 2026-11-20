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


### وضعیت نهایی انتشار اصلاح بازار و لوگو — ۱۹ نوامبر ۲۰۲۶
- PR #13 با اجازهٔ کاربر merge شد؛ merge commit روی `main`: `d062f4f6d9fed77bae2c1d122fb0cada0801462e`.
- Edge Function `app-assets` در پروژهٔ `gfoaubfilhttnwjykaox` به نسخهٔ ۲ deploy شد و پس از deploy به صورت `ACTIVE` با `verify_jwt=false` تأیید شد.
- SHA-256 نسخهٔ فعال: `1fe0c818ffd91d057fea77406dc6a6df4eb3a2daa20c73b2553a355c037cdb4f`؛ fallback تصویر از SpotHQ و CoinCap در سورس فعال وجود دارد.
- هیچ تغییر دیتابیس/مهاجرت/دادهٔ مالی انجام نشد.
- محدودیت تست: درخواست مستقیم به endpoint از محیط اجرا به علت DNS/شبکه ناموفق بود؛ smoke test واقعی تصویر و بررسی بصری روی Android هنوز باقی است.

**Next:** برنامه DigiArz را refresh کن و چند نماد بدون لوگوی قبلی و ترتیب بخش‌های صعودی/نزولی را بررسی کن؛ اگر موردی باقی مانده، اسکرین‌شات بفرست.

 
## Checkpoint: diagnose and fix market logos / 24h ranking — 2026-11-19
- Live Supabase function logs for the Android client show 1,166 logo HTTP 404s versus 103 HTTP 200s in the last 24 hours. The v2 Edge Function is active, but its symbol-only SpotHQ/CoinCap fallback does not cover most of the market catalogue.
- Read-only Production SQL confirms all 398 enabled `demo_trading_pairs` have an exact `base_coingecko_id` match in `crypto_assets`, and all 398 have a non-empty `image_url`. The UI loader was only reading `market_prices` plus `pair_symbol,is_enabled`; it never loaded the exact CoinGecko metadata. This is the confirmed logo root cause.
- Market ticker logs show 1,155 HTTP 200 and 83 HTTP 502 calls over the last 24 hours. The browser loader used `Promise.all` for ticker batches, so one failed batch rejected the entire batch set, discarding successful responses. Its fallback coverage gate also checked only the first 12 market pairs despite 398 enabled pairs.
- A safe work branch was created from current main: `fix/market-logo-metadata-and-partial-ticker-batches`.
- Code changes on that branch:
  - Load metadata only for enabled pairs, joined by exact `base_coingecko_id`, in chunks of 100; attach `image_url`, name and a separate `change_updated_at` timestamp.
  - Keep stored 24h percentage fallback freshness tied to the crypto metadata timestamp, not the more frequently refreshed `market_prices.updated_at`.
  - Collect fulfilled ticker batches with `Promise.allSettled`, preserving valid batches when one fails.
  - Measure fallback coverage across the full enabled market and exclude null values from valid-change counts.
  - Add regression tests for exact-ID metadata mapping, stale percentage rejection, partial batch retention and full-market coverage threshold.
- CI has not yet been verified for this branch. No Production DB changes, migrations, schema changes, Edge Function deploys, financial data changes, merge or Production release were made.
- Next: open/inspect a Draft PR to trigger CI, fix any test failures, then perform Android visual QA. Merge/deploy require separate user approval.

## PR #14 state — 2026-11-19
- PR #14: https://github.com/shahram-adim/DigiArz/pull/14 — open, ready for review, not merged.
- Branch: `fix/market-logo-metadata-and-partial-ticker-batches`; latest code/test commit at this checkpoint: `be3b9c3841c7acf69bb122f7e103fd8b1c4d7613`.
- GitHub Actions run `44479513790` (run 822) is in progress; do not claim CI success until final status is read.
- No Supabase Production deployment, database changes, or financial data modifications. Merge and deploy still require separate user approval.

## PR #14 CI correction — 2026-11-19
- First CI run `44479513790` failed the inline-script parse test due to one extra closing `]` in the metadata loader. The issue was fixed in code commit `6d9b4be45a4706ef7d292eee60d3440f3bf1cee1`.
- Follow-up run `44479671283`: the exact-decimal and browser integration test step passed. The overall workflow is still running; PostgreSQL integration steps have not yet completed.
- Do not report overall CI success until the run has a final successful conclusion. PR #14 remains open and unmerged; no Production changes were made.

## CI completed successfully — 2026-11-19
- GitHub Actions run `44479671283` (run 824) for commit `6d9b4be45a4706ef7d292eee60d3440f3bf1cee1` completed with conclusion `success`.
- All 43 job steps completed successfully: browser/market tests, PostgreSQL arithmetic and migration rehearsal tests, two-session Limit worker/cancellation races, TP-SL conditional execution/cancellation races, Stop-Limit child execution/cancellation races, and isolated lifecycle integrations.
- The prior syntax regression was fixed before this run. The new CI run is green.
- CI does not prove visual behavior on the Android device or successful live upstream image fetches. PR #14 remains unmerged; no Production deployment or database changes were made.

## Logo recovery follow-up — 2026-11-19
- Live Android function logs after the prior release still showed HTTP 404 for fallback requests for symbols including ZRO, ICNT, ZKC, ASTER and MANTA.
- Read-only Production SQL confirmed the corresponding `crypto_assets.image_url` values exist on CoinGecko image hosts. The browser's direct image attempt was not being retried through the server proxy with that curated URL.
- Work branch: `fix/market-logo-proxy-fallback`, created from current `main`.
- The client now carries the curated image URL in the fallback request; market-list and dashboard-preview renderers pass each row's exact image URL. The `app-assets` source accepts only HTTPS URLs on `coin-images.coingecko.com` or `assets.coingecko.com`, validates the final redirect host and image content type, then falls back to the existing SpotHQ/CoinCap providers.
- Regression assertions were added for URL propagation, market/dashboard rendering and server host allowlisting.
- No merge, Pages publication or Supabase Production Edge Function deployment has been performed. CI and Android visual QA remain required.
- Next: run the project test workflow, inspect the PR, then request separate approval before merge or Production deployment.

## Production deploy: market logo proxy fallback — 2026-11-19
- User explicitly approved deploying only the `app-assets` Edge Function to the DigiArz Production Supabase project.
- Deployed the exact `supabase/functions/app-assets/index.ts` source from GitHub `main` (source blob `5a6d2c8dd1beac78cb51a45f368c02c9ff50be68`).
- Supabase project: `gfoaubfilhttnwjykaox`; function `app-assets`; active version advanced from 2 to 3; status `ACTIVE`; `verify_jwt=false` preserved.
- Post-deploy readback confirmed the active source contains the curated `image_url` proxy and CoinGecko host allowlist. Active SHA-256: `30e3d08801c9bfc651d88cfa867aeee4943a8b8cb359c16c6ae9cf6b3154ad17`.
- No database migrations, schema, RPCs, cron jobs, wallets, balances, orders, trades, or financial data were changed.
- A direct live HTTP image smoke test and Android visual QA have not yet been completed. Do not claim the logos are visually fixed until the user refreshes the app and confirms the previously missing symbols display.
- Next: ask the user to fully refresh DigiArz and check ZRO, ICNT, ZKC, ASTER, and MANTA; capture a screenshot and symbol list if any remain broken.


## Android client diagnosis after app-assets v3 — 2026-11-19
- Supabase logs after v3 deployment show the Android client still making symbol-only logo fallback requests. At 08:00 UTC, 112 requests were recorded: 108 HTTP 404 and 4 HTTP 200; sample URLs contain only `asset=logo&symbol=...`, with no curated `imageUrl` query parameter.
- This establishes that the Edge Function is active but the client observed in those logs had not yet started forwarding the catalog image URL. Do not repeat the Edge Function deployment as the presumed fix.
- GitHub Pages build and deploy for merge commit `1e5d7ee5bcc6571003bfebf6eeca57c7973d2269` succeeded (run `44483387814`).
- A new Android debug APK was built from that exact main commit and uploaded successfully (run `44483387973`, artifact `14509018848`). BUILD-INFO confirms commit `1e5d7ee5bcc6571003bfebf6eeca57c7973d2269`; APK SHA-256 `8d2481a4eb1582f7806aa65173ae8ecb463c466ea5fab57fc417fc550cb7c686`.
- Exact-decimal workflow run `44483387900` completed all 43 steps successfully.
- User has not yet confirmed installing/running the new APK. Next: install this build, then inspect fresh app-assets logs for imageUrl propagation and successful image responses; visual confirmation still required.


## Checkpoint — market row layout/readability — 2026-11-19
- User confirmed the logo issue is now fixed and requested: repair the market asset rows, set logos to 40px, improve low-contrast/dim text, remove the favorite star's ugly border, and restore Persian coin names.
- Current main index.html was inspected. renderMarkets() appends five direct children per .coin row (favorite button, identity, sparkline, change/volume, price), while accumulated CSS overrides had conflicting 2/3/4-column layouts. This is the confirmed structural cause of row misalignment.
- Created work branch fix/market-row-layout-readability from current main.
- Added a final CSS override scoped to #tab-markets .market-board-v34: five aligned desktop columns; compact two-row mobile layout with sparkline hidden; 40x40px coin logos; borderless transparent star; improved contrast for Persian names, symbols, prices, changes and freshness labels.
- Renderer explicitly prefers item.name_fa when present, otherwise uses the existing Persian-name dictionary. No fabricated translations are added.
- Added a regression test in tests/index-syntax.test.js for the five-cell layout, 40px logos, borderless star, visible Persian name, and mobile grid.
- Code is on the work branch only. No main merge, Pages deployment, APK publication, Supabase deployment, database migration, or financial-data change has occurred.
- CI and Android visual QA are pending. Next: open PR to trigger CI, fix any failures, then ask the user to review the installed build. Merge and release require explicit approval.


## 2026-11-19 — Market row fix merged; APK build pending
- User explicitly approved merging PR #16 and building a new APK.
- PR #16 merged successfully into main. Merge commit: 0ee8c9dbeb0c8229b2181acc2e9cb52544e6868b.
- Pre-merge PR exact-decimal CI run 44485982288 succeeded.
- Post-merge exact-decimal workflow run 44486985269 is still in progress.
- Android APK workflow run 44486985383 was automatically triggered by the main push. Capacitor install, web build, Android project generation and sync completed successfully; Gradle assembleDebug is still running. Artifact not yet uploaded/available.
- No Supabase deploy, schema migration, DB or financial-data change was performed.
- Next: monitor both runs; when APK run succeeds, retrieve artifact and verify BUILD-INFO.txt commit matches 0ee8c9dbeb0c8229b2181acc2e9cb52544e6868b, then provide verified APK download.


## 2026-11-20 — Market-price refresh optimization investigation
- User approved continuing the optimization investigation while retaining the one-minute market-price refresh cadence.
- Rechecked live GitHub: main HEAD is 96866f6e023458f857734e30d8aff6a4051cc785. Existing PR #33 optimizes no-op writes in `refresh_crypto_assets()`; it is a separate function and does not implement the `refresh_market_prices()` optimization. PR #33 remains Draft; PostgreSQL 17 fixture and exact-decimal CI checks currently report success, but full-function review and representative performance measurements remain gates.
- Live `refresh_market_prices()` source in the applied 515-ID migration confirms CoinGecko, KuCoin and Gate.io branches, advisory transaction lock, queue cleanup, and one CoinGecko upsert per mapped symbol in PL/pgSQL loops. The 515-ID cap must be preserved.
- Read-only snapshot: 398 enabled demo pairs, 891 curated listings, 3 queued requests and none older than 2 minutes. Recent cron observations recorded ~43.7 s average and ~98.5 s maximum runtime for `refresh_market_prices()`.
- Opened issue #34, https://github.com/shahram-adim/DigiArz/issues/34, to scope a set-based upsert design and PostgreSQL 17 regression fixture. It explicitly requires deterministic duplicate-symbol handling and preservation of provider/source semantics, permissions, precision, locking, queue behavior and one-minute cadence.
- No Production function, index, cron schedule, migration history, market data, order, trade, wallet or balance was changed. Do not run `supabase db push`; migration reconciliation remains unresolved.
- Next: implement the issue #34 work on an isolated branch only after the exact current live function and duplicate-symbol semantics can be captured and tested. Keep Production untouched until CI, equivalence review and representative benchmarks pass.


## 2026-11-20 — Market-price bulk-upsert design PR opened
- Rechecked duplicate mappings with a bounded read-only query across enabled demo pairs and active curated listings: no symbol had more than one distinct CoinGecko ID in this snapshot. This is not a permanent uniqueness guarantee.
- The next attempt to capture the full live `public.refresh_market_prices()` definition timed out; no function rewrite was attempted.
- Created isolated branch `perf/market-price-bulk-upsert-draft` and Draft PR #35: https://github.com/shahram-adim/DigiArz/pull/35. It adds only `docs/MARKET_PRICE_BULK_UPSERT_PLAN.md` (design, safety constraints and regression matrix); no SQL/migration or production change.
- PR #35 must remain Draft until the exact live function is captured, source/provider semantics are compared, PostgreSQL 17 regression tests pass, and isolated performance benchmarks are reviewed.

## 2026-11-20 — PR #35 response-boundary contract expansion
- Revalidated PR #35: open Draft, branch `perf/market-price-bulk-upsert-draft`; latest head at handoff update: `477b4415e245821507ae588fa7bda9d72a02739d`. It remains three files only: isolated PostgreSQL 17 workflow, contract fixture, and design plan. Branch remains diverged from main; no rebase/merge.
- Expanded the disposable PostgreSQL 17 fixture to cover per-response exception rollback, queue deletion after caught exceptions, processing of a later independent response, HTTP/status/timeout/content gates, KuCoin provider code gate, Gate.io top-level JSON shape, accepted/rejected price source/timestamp behavior, malformed JSON text, and missing provider keys.
- Static review caught and corrected the PL/pgSQL loop target to use a record variable before the latest CI attempt.
- CI run `44802410353` (contract fixture) passed on intermediate commit `4d45f048b87ed251a71ec4a83b3a4f272a18ff3d`; exact-decimal workflow `44802410457` also passed on that commit. These results validate only the then-current fixture and existing exact-decimal suite, not Production equivalence.
- Latest fixture after malformed/missing-key additions is commit `daae30bd349f9a011381c3435a97c5bbe152573f`; PostgreSQL 17 run `44802705359` was still in progress at last check. The subsequent docs-only head is `477b4415e245821507ae588fa7bda9d72a02739d`. Do not claim latest fixture success until run 44802705359 completes and its job output is inspected.
- No Production SQL, migration, function, index, cron, market data, order, trade, wallet, or balance changed. One-minute cadence unchanged. Live function definition capture remains blocked by database instability; no heavy Supabase query was retried.
- Next: inspect run `44802705359`; if successful, review the latest PR diff and then continue with isolated provider-parser/equivalence cases. Keep PR Draft and do not rebase/merge/deploy.



## 2026-11-20 — PR #35 latest CI and contract review
- Rechecked the current main handoff before updating it; prior blob SHA was `5d01bad9975cd7d5ebd3ad25fed8a20ad4eadcfa`.
- PR #35 remains open and Draft. Current PR head is `477b4415e245821507ae588fa7bda9d72a02739d`; changed files remain exactly the isolated PostgreSQL 17 workflow, `docs/MARKET_PRICE_BULK_UPSERT_PLAN.md`, and `supabase/tests/market_price_bulk_upsert_contract.sql`.
- Latest PR-head PostgreSQL 17 contract workflow run `44802732909` completed successfully; job `postgres-17-contract` and step `Run isolated bulk-upsert contract fixture` both succeeded.
- Latest PR-head exact-decimal workflow run `44802732606` completed successfully; all 43 substantive/setup/cleanup steps reported success, including arithmetic, schema-widening rehearsals, entrypoint integration, and two-session lifecycle/race tests.
- The latest push-triggered contract run `44802705359` also completed successfully on fixture commit `daae30bd349f9a011381c3435a97c5bbe152573f`. The PR-head runs above validate the current docs-only head `477b4415e245821507ae588fa7bda9d72a02739d`.
- Static fixture review confirms tests for PostgreSQL duplicate-key cardinality failure, explicit caller-ranked deduplication mechanics, non-positive/NULL/NaN/Infinity rejection, cross-provider duplicate target keys, per-response rollback and queue deletion, later-response continuation, provider HTTP/status/code/shape gates, source/timestamp behavior, malformed JSON, and missing provider keys.
- These are isolated PostgreSQL contract tests and synthetic models based on repository migration source. They do not prove exact deployed-function equivalence, actual provider parser equivalence, or production performance.
- PR branch compare against current main reports diverged: 19 commits ahead / 12 behind, merge base `8bbd3e228de3b342c1a07eb0ff18ec97c9d12353`. No rebase or merge was performed.
- Exact live `public.refresh_market_prices()` definition capture remains blocked by earlier database instability and timeouts. Do not retry heavy catalog/function reads until stability is demonstrated. Do not invent provider precedence or duplicate-symbol winner semantics.
- No Production function, migration, index, cron, market data, orders, trades, wallets, or balances were changed. One-minute market-price cadence remains unchanged. `supabase db push` remains prohibited while migration history is unreconciled.
- Next: continue repository-only review and wait for a safe read-only route to capture the exact deployed function; then add tests against actual provider parsing and response ordering semantics before any implementation. Keep PR #35 Draft and do not merge/deploy without separate explicit approval.


## 2026-11-20 — PR #35 numeric special-value characterization
- Re-read the current main handoff before updating; current blob SHA was `022f134b81332087e7b679af2450c55381f31a16`.
- Static source review found a compatibility distinction in the market-price bulk-upsert fixture: the proposed candidate CTE filters NaN and Infinity, while the repository migration's legacy predicate is only `v_price > 0`. PostgreSQL numeric NaN compares greater than ordinary numbers and can be stored in `numeric(38,18)`; positive Infinity cannot fit that precision-constrained column and raises `numeric_value_out_of_range` on assignment. Under the source migration's response-level exception block, that write error rolls back earlier writes in the same response; queue deletion follows outside the block.
- Added a separate isolated PostgreSQL 17 characterization test in `supabase/tests/market_price_bulk_upsert_contract.sql` using `numeric(38,18)` to assert NaN predicate/storage and Infinity overflow behavior. The stricter finite-positive candidate filter remains separate and is explicitly not claimed as exact legacy equivalence.
- Added the distinction and compatibility gate to `docs/MARKET_PRICE_BULK_UPSERT_PLAN.md`. No production code or data changed.
- PR #35 head is now `96baaadc736884a593a1d990f6ae5761a73de0f8`; it remains open Draft with exactly three files. The new PostgreSQL 17 contract PR run `44803509295`, push run `44803499920`, and exact-decimal PR run `44803509476` were still in progress at the latest check. Do not report these as passing until completed and their jobs are inspected.
- PR branch remains divergent from main and mergeability is false; do not rebase or merge during this investigation. Exact deployed `refresh_market_prices()` capture remains blocked by previous DB instability. Do not retry heavy Production catalog/function reads.
- No Production function, migration, index, cron, price, order, trade, wallet, or balance changed. One-minute market-price cadence remains unchanged; `supabase db push` remains prohibited due unresolved migration reconciliation.
- Next: inspect the new PostgreSQL 17 characterization run. If it fails, diagnose and correct only the isolated fixture; if it passes, continue provider parsing/duplicate behavior coverage while keeping PR #35 Draft.

## 2026-11-20 — PR #35 provider parser fixture expansion
- Revalidated main handoff before update; current blob SHA was `6f930dd20e73eaf59c9815ebffc92d432a2e7988`.
- Added an isolated PostgreSQL 17 parser characterization to PR #35's fixture: KuCoin hyphen normalization, Gate.io underscore normalization, uppercase USDT regex, enabled-pair filtering, empty-string-to-NULL handling, provider success/shape gates, and sequential duplicate ticker updates. The duplicate KuCoin case asserts that the later ticker in the JSON array overwrites the earlier row, matching the current row-by-row parser behavior. A subsequent Gate.io response is modeled as a separate response; no general cross-response ordering policy is inferred.
- Updated `docs/MARKET_PRICE_BULK_UPSERT_PLAN.md` to record the parser coverage and its limits. CoinGecko duplicate-symbol mapping/order remains unresolved; the exact deployed function has not been captured.
- Latest PR head is `a35d5815d7275cff87bfb4151641d5788a26ef74`; PR #35 remains open Draft with exactly three changed files. GitHub currently reports mergeable true, but no rebase or merge was performed. The branch is still a distinct draft investigation; mergeability does not establish safety or approval.
- The numeric special-value characterization fixture from commit `90bc8a90aedecc349df8b2ea0bce5cad3363bbba` passed PostgreSQL 17 contract run `44803509295` (job and fixture step success). The provider-parser fixture is newer: its contract run `44803692650` and exact-decimal run `44803692704` were still in progress at latest check. Do not claim parser coverage has passed until those jobs complete; later docs-only PR head checks were also running.
- No Production SQL, function, migration, index, cron, market data, orders, trades, wallets, or balances changed. One-minute price refresh cadence remains unchanged. `supabase db push` remains prohibited while migration reconciliation is unresolved.
- Next: inspect parser fixture CI `44803692650` and exact-decimal run `44803692704`; diagnose any failure before adding more cases. Keep PR #35 Draft and Production untouched.

## 2026-11-20 — PR #35 provider parser CI failure and correction
- Re-read current main handoff before update; blob SHA was `ff909e2884452ccacc9ae41cbafff33fcf17be4a`.
- The provider parser fixture at prior head `a35d5815d7275cff87bfb4151641d5788a26ef74` failed PostgreSQL 17 run `44803735088` (push run `44803727729` failed too). Job logs pinpointed a fixture syntax error: both KuCoin and Gate.io regex predicates had lost the closing quote and `$` anchor, causing the PL/pgSQL block to fail parsing. This was a test-fixture construction error, not evidence of a provider runtime failure.
- Corrected both predicates to the complete single-line regex `^[A-Z0-9]{2,24}USDT$` in `supabase/tests/market_price_bulk_upsert_contract.sql`. Fresh blob SHA after correction: `c018ecbdbd6e9eafd17151285cb54c36cc35aa91`; branch commit: `b85cf2405ee72afc173707dda6e255a7aeb2cdfc`.
- Re-read the file after commit and confirmed both KuCoin and Gate.io predicates now contain the complete quoted regex. The corrected head is on PR #35, which remains open Draft with three changed files. CI for corrected commit had not yet appeared in the latest Actions listing; do not claim the parser test passes until its new run completes and logs/jobs are checked.
- Exact-decimal runs on the preceding fixture heads passed; that does not validate the parser fixture. No Production SQL/function/migration/index/cron/data changes occurred; one-minute refresh cadence remains unchanged. `supabase db push` remains prohibited while migration reconciliation is unresolved.
- Next: poll Actions for commit `b85cf2405ee72afc173707dda6e255a7aeb2cdfc`; inspect PostgreSQL 17 contract and exact-decimal runs. If contract passes, continue static review of CoinGecko mapping collisions and ordering; if it fails, inspect logs and repair only the isolated fixture. Keep PR #35 Draft; no rebase, merge, or deploy.
## 2026-11-20 — corrected parser fixture CI started
- Re-read current main handoff; blob SHA was `0e1d62ea7daaaa9534265859cf0661b607a71e3b`.
- The corrected PR head `b85cf2405ee72afc173707dda6e255a7aeb2cdfc` now has new GitHub Actions runs: PostgreSQL 17 contract PR run `44803954795`, push run `44803944545`, and exact-decimal PR run `44803954954`.
- At latest check, PostgreSQL contract run `44803954795` had initialized PostgreSQL 17 and was executing `Run isolated bulk-upsert contract fixture`; exact-decimal run `44803954954` was still in checkout/setup. Both remain in progress; no success claim.
- Prior parser CI failure cause was identified from job logs: two regex SQL literals were missing the closing `$'` and caused a syntax error. Both corrected predicates were re-fetched and confirmed as `IF parsed_symbol ~ '^[A-Z0-9]{2,24}USDT$'`.
- PR #35 remains open Draft on the corrected branch. No Production changes; no merge/rebase/deploy. Next: inspect run `44803954795` after completion, then exact-decimal run `44803954954`; if failure, diagnose using job logs.
## 2026-11-20 — PR #35 CoinGecko characterization added
- Re-read current main handoff before update; blob SHA was `b67656da1c0b33812c03612c3459314abf1e4313`.
- Confirmed corrected provider-parser PostgreSQL 17 contract runs on commit `b85cf2405ee72afc173707dda6e255a7aeb2cdfc`: PR run `44803954795` success and push run `44803944545` success. Exact-decimal run `44803954954` completed success; its PostgreSQL arithmetic, disposable migration rehearsal, Market/Limit/Stop-Limit/TP-SL integration and two-session race/lifecycle steps all passed.
- Continued repository-only source review of `supabase/migrations/20261116203709_limit_primary_coingecko_batch_to_515_ids.sql` (blob SHA `92196e0074700f85d927b0552a9677cd451fef1f`). It confirms the CoinGecko mapping UNION key is `(symbol, coingecko_id)`, so distinct upstream IDs can map to the same target symbol. The mapping loop has no ORDER BY; no deterministic winner can be inferred. Request IDs are filtered by regex, sorted lexicographically and capped at 515.
- Added isolated fixture coverage in `supabase/tests/market_price_bulk_upsert_contract.sql`: two distinct CoinGecko IDs remain separate for one target symbol under the source UNION key; 516 synthetic valid IDs reduce to sorted first 515. Fixture blob SHA `32db1741ee70921bbf8c7f6b03842af683084f3a` (973 lines). It deliberately does not define a duplicate-symbol winner or call any provider.
- Updated `docs/MARKET_PRICE_BULK_UPSERT_PLAN.md`; blob SHA `c137f3f5483042381d89bdfe1050b8f977140d6d`.
- New code/test commit `0bdbb48614790a60b9cdf011f8b3ed1a0d79918e`; documentation commit advanced PR head to `0f25d2866f9eb5aaa13c3b88053ff7a85b4d7a24`. At latest check, PostgreSQL contract push run `44804236428` and exact-decimal PR run `44804247758` were in progress on code commit `0bdbb48`. Do not claim the newly added CoinGecko cases pass until the contract run completes successfully.
- PR #35 remains open Draft, exactly three changed files; GitHub reports mergeable false. No rebase, merge or deployment. No Production SQL/function/migration/index/cron/data changes; no orders, trades, wallets, balances or cadence changes. `supabase db push` remains prohibited.
- Next: inspect runs `44804236428` and `44804247758`. If PostgreSQL contract fails, inspect logs and correct only isolated fixture. If it passes, continue review of CoinGecko response parsing and the unresolved duplicate target-symbol semantics; do not invent precedence. Production remains excluded from testing while prior startup-timeout/resource-pressure evidence persists.
## 2026-11-20 — CoinGecko fixture repair after SQL-boundary corruption
- Re-read current main handoff; blob SHA was `cea22a27a8489750ff0096b69f95f195614eeadd`.
- The first CoinGecko fixture insertion was malformed: the request-ID regex line and following response-exception section were accidentally joined. PostgreSQL 17 run `44804236428` failed at that malformed boundary. A subsequent repair attempt also produced malformed intermediate commits; those commits remain in branch history, but the current branch file was rebuilt from the last known-good parser fixture at commit `b85cf2405ee72afc173707dda6e255a7aeb2cdfc` and then appended with the two CoinGecko characterization tests.
- Current fixture blob SHA `a5af6595cb226631344710c37efff0d412bf58df`, 566 lines. Re-fetched file confirms the end of the fixture is syntactically complete: mapping UNION test preserves two distinct IDs for SOLUSDT; ID selector uses a positive character-class match plus a negative invalid-character check (avoids a literal end-anchor token that was being lost in this editing path), orders IDs and limits 515; then ROLLBACK. Original parser tests from the known-good base are preserved.
- Current branch head `642c5e8e7da5401565538674a15adc6294aacf3c`; current PostgreSQL contract run `44804654491` was in_progress at latest check. Older runs on intermediate malformed commits failed and must not be treated as current-code evidence. Previous known-good parser head `b85cf2405ee72afc173707dda6e255a7aeb2cdfc` still has successful contract runs `44803954795` and `44803944545`.
- PR #35 remains open Draft with exactly three changed files; GitHub mergeable false. No rebase/merge/deploy and no Production changes. No Supabase SQL executed.
- Next: wait for and inspect run `44804654491` for current head. If it passes, update plan with verified result and continue source review; if it fails, inspect exact error before any further edits. Keep all changes isolated to fixture/docs; no production action.