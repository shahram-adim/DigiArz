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
## 2026-11-20 — CoinGecko PostgreSQL fixture passed
- Re-fetched current main handoff before update; prior blob SHA `6686b1ebba9c4ee066f897b67b9f906942f35082`.
- Current PR #35 branch head at this check: `642c5e8e7da5401565538674a15adc6294aacf3c`. The repaired SQL fixture blob is `a5af6595cb226631344710c37efff0d412bf58df` (566 lines), rebuilt from known-good provider-parser fixture `b85cf2405ee72afc173707dda6e255a7aeb2cdfc` with the CoinGecko mapping and 515-ID cases appended.
- PostgreSQL 17 contract run `44804654491` completed success; duplicate PR contract run `44804664803` also completed success on the same SHA. The new CoinGecko tests therefore pass in isolated PostgreSQL 17.
- Exact-decimal workflow `44804664444` on the same SHA remains in progress. Completed steps so far: browser/exact decimal, PostgreSQL arithmetic, schema widening rehearsal and atomicity/lock-timeout checks, Market/Limit entrypoint integration; combined rollout rehearsal is currently in progress. Do not report the full exact-decimal/race suite as passed until the workflow completes.
- Plan file updated on PR branch in commit `8d0853ad0f1846c960907cf05907e482939ddb2a`, blob `fa94f93620315656baecff4ad968c6845de761c1`, recording contract success and exact-decimal workflow pending.
- PR #35 remains open Draft, three changed files, mergeable false. No merge/rebase/deploy, no Supabase SQL, and no Production changes. One-minute refresh cadence unchanged.
- Next: poll exact-decimal run `44804664444`; if successful, proceed with static duplicate-symbol/ordering design analysis. Do not infer CoinGecko duplicate winner because mapping loop has no ORDER BY.
## 2026-11-20 — CoinGecko fixture and full exact-decimal CI passed
- Re-fetched main handoff before update; prior blob SHA `34314c0a7457e31ad3a8fc484eb9888608f2a04f`.
- PostgreSQL 17 contract run `44804654491` completed success on code commit `642c5e8e7da5401565538674a15adc6294aacf3c`; duplicate PR run `44804664803` also success.
- Exact-decimal workflow `44804664444` completed success on the same code commit. All steps passed, including PostgreSQL arithmetic and widening atomicity, Market/Limit integrations, Stop-Limit/TP-SL placement, cumulative per-fill USDT rounding, Limit worker/cancel races, TP-SL conditional execution/cancel races, Stop-Limit child execution/cancel races, parent-child lifecycle, and TP-SL exit lifecycle.
- The fixture code commit is followed by documentation-only commit `8d0853ad0f1846c960907cf05907e482939ddb2a` and another plan-status documentation commit `44b5930596bf912506129f398ada72ee314df60a`. Current PR branch head should be re-fetched; no code changes after the successful test commit are intended.
- Plan file updated to record the successful results; new blob SHA `bec570865c7bf78b8958382ea0680bef5f575f32`.
- CI success validates isolated fixtures and integration tests only. It does not prove deployed Supabase function equivalence, Production performance, or resolve the nondeterministic duplicate CoinGecko target-symbol winner. The source mapping loop has no ORDER BY; no precedence should be invented.
- PR #35 remains open Draft; no merge/rebase/deploy. No Production SQL, migration, cron, function, market data, order, trade, wallet, or balance changes. One-minute refresh cadence unchanged; `supabase db push` remains prohibited.
- Next: re-fetch PR #35 and current branch files, then continue static review of CoinGecko duplicate-target behavior and determine what explicit product/source-precedence decision is needed before any bulk-upsert implementation is considered.
## 2026-11-20 — Static CoinGecko duplicate-symbol review
- Re-fetched main handoff; prior blob SHA `159632533678991d6ae66f40acbf3bf8103cc05d`.
- Re-read migration `20261116203709_limit_primary_coingecko_batch_to_515_ids.sql`, blob `92196e0074700f85d927b0552a9677cd451fef1f`, lines 27–42. Both the mapping `FOR v_map` query and the response queue `FOR r` query have no `ORDER BY`.
- Distinct CoinGecko IDs can map to one market symbol because UNION deduplicates the pair `(symbol, coingecko_id)`. Legacy per-row upsert then updates that symbol multiple times in unspecified iteration order. A bulk upsert with duplicate conflict keys can instead raise PostgreSQL cardinality_violation. Cross-response provider precedence is also unspecified because response queue order is not explicit.
- This is a real unresolved behavior decision before implementation. Do not invent winner precedence or call a chosen policy exact legacy equivalence. Product/engineering must decide whether to define deterministic ID/source precedence, skip/reject ambiguous mappings with diagnostics, or explicitly accept another documented behavior change. Plan records these alternatives in commit `3f6cdadbbdbdeaf80c40379c90580b1555373f74`, blob `91900caafd23ca4388155cd6214e463c0dfb6849`.
- Current PR #35 is still Draft/open; latest branch head after plan docs commit is expected `3f6cdadbbdbdeaf80c40379c90580b1555373f74` (re-fetch before further work), three changed files, mergeable false. CI passed on code commit `642c5e8e7da5401565538674a15adc6294aacf3c`: PostgreSQL `44804654491`/`44804664803`, exact-decimal integration and races `44804664444`.
- No Production SQL or Supabase operations. No merge/rebase/deploy. Refresh cadence remains one minute. Next: re-fetch current PR head and plan, then wait for an explicit duplicate mapping precedence decision before any bulk SQL implementation.

## 2026-11-20 — Fresh PR #35 and CI recheck
- Re-fetched `PROJECT_HANDOFF.md` from `main` before this update; prior blob SHA `3b9ff9643b2d5fc693000a44b1952ac84b5e33e3`.
- Fresh PR #35 metadata: open, not merged, Draft, 35 commits, exactly 3 changed files, head branch `perf/market-price-bulk-upsert-draft`, head SHA `3f6cdadbbdbdeaf80c40379c90580b1555373f74`, base `main` at `8bbd3e228de3b342c1a07eb0ff18ec97c9d12353`. GitHub now reports `mergeable=true` (previous handoff said false); this is metadata only, not a merge approval or semantic sign-off.
- Fresh PR-triggered workflow runs on current head both completed successfully: PostgreSQL 17 market-price bulk-upsert contract run `44804990498`; exact-decimal tests run `44804990427`. The contract fixture remains isolated/synthetic; green CI does not prove deployed-function equivalence, production performance, or choose duplicate-symbol precedence.
- Re-fetched branch fixture `supabase/tests/market_price_bulk_upsert_contract.sql`: blob SHA `a5af6595cb226631344710c37efff0d412bf58df`, 566 lines. Its tail confirms the existing CoinGecko two-ID/one-symbol characterization and 515-ID cap test; no fixture edits made in this recheck.
- PR discussion timeline returned no comments/reviews. PR description claims a bounded read-only duplicate-symbol query found no conflicting CoinGecko IDs in the then-current enabled-pair/active-listing snapshot; this is only a point-in-time claim recorded in the PR body and does not remove the structural duplicate-key case or establish a permanent uniqueness constraint.
- Current plan file on the PR branch remains blob `91900caafd23ca4388155cd6214e463c0dfb6849`. No code or plan edits made. No Supabase queries, Production SQL, migrations, cron changes, merge, rebase, or deployment. One-minute refresh cadence unchanged; `supabase db push` remains prohibited.
- Next gate: do not invent duplicate-symbol/provider precedence. Await an explicit product decision or verified invariant/constraint that rules out duplicate target symbols, then re-evaluate the safe batching design. Keep PR #35 Draft.


## 2026-11-20 — Repository guard review added to PR #35 plan
- Re-fetched main handoff before update; prior blob SHA `a8f0da591ef89d1eb82e259cfd8e97e78e4776ab`.
- Static repository review found meaningful normal-path collision safeguards: `admin_market_listings.coingecko_id` is a primary key; trigger `admin_market_listing_unique_ticker` rejects curated ticker collisions against other curated listings and different-ID demo pairs; `admin_enable_market_pair` rejects pair-symbol conflicts; the auto-list path requires exactly one active crypto asset for a ticker and checks conflicting listings/pairs.
- These do not prove a database-wide invariant. The reviewed trigger is on `admin_market_listings.coingecko_id`, not `crypto_assets.symbol`; `demo_trading_pairs.pair_symbol` uniqueness does not enforce unique `base_coingecko_id` or consistency with a mutable asset symbol. Thus the duplicate-target mapping remains a structural possibility unless all write paths and current data are verified. No deterministic provider/ID winner is inferred.
- Recorded this source-only finding in PR #35 plan, documentation commit `8c330a75fa9b26293b7df38862d6cef9bf544cb5`, plan blob `32f0c559fc5151e532ae5cb7d0eb10787c0b9c96`. No SQL fixture/code changes.
- Fresh PR #35 status after the docs commit: open, not merged, Draft, 3 changed files, head `8c330a75fa9b26293b7df38862d6cef9bf544cb5`; GitHub currently reports `mergeable=false`. Workflow-runs lookup for this docs-only head returned no PR-triggered runs; do not transfer the prior head’s green CI as if this new docs commit had fresh CI. Prior code commit `642c5e8e7da5401565538674a15adc6294aacf3c` remains covered by the previously verified passing PostgreSQL 17 and exact-decimal runs.
- No Supabase query/SQL, Production mutation, migration, cron, merge, rebase, or deployment. One-minute cadence unchanged; `supabase db push` remains prohibited. Next: inspect the actual current data/write paths only when database stability permits; until then, keep the duplicate-symbol blocker explicit and PR Draft.


## 2026-11-20 — Catalog symbol write-path source gap and latest PR #35 CI
- Re-fetched main handoff immediately before update; previous blob SHA `ff946f2ded42af0ab0a20bbfa8ec574dc6aaeba3`.
- Re-fetched PR #35: open, not merged, Draft; current head before this docs update `8c330a75fa9b26293b7df38862d6cef9bf544cb5`; GitHub currently reports `mergeable=true` (metadata only). Branch plan updated in docs-only commit `e924d0d6d21c3a09278107f763b4341840cde579`, plan blob `9b70cb029acfcfbf64aa4647e244691d6a00b150`.
- Further static review: `get_exchange_discovered_market_assets()` is read-only; `auto_list_verified_exchange_asset()` reads `crypto_assets` and writes only `admin_market_listings`, with uniqueness/eligibility filters. These do not change `crypto_assets.symbol`.
- Repository migration-directory/code search found the checked-in `20261113170000_recover_stalled_crypto_asset_sync.sql` defines stale-request recovery only and references `refresh_crypto_assets()`; the complete catalog refresh function body was not found in the checked-in migration sources searched. The existing migration-reconciliation record documents applied Production SQL whose local source is missing. Therefore all `crypto_assets.symbol` write paths cannot yet be enumerated, and no database-wide ticker uniqueness invariant can be claimed.
- Latest CI on previous PR head `8c330a75fa9b26293b7df38862d6cef9bf544cb5`: PostgreSQL 17 contract run `44805417363` success; exact-decimal workflow run `44805417201` now completed success. These synthetic/isolated tests do not establish Production equivalence or close the missing-source evidence gap.
- Next: recover and review the exact applied `refresh_crypto_assets()` definition as part of migration reconciliation; then enumerate every symbol-writing path and decide whether a permanent invariant is feasible. Do not run stressed Production SQL or create a schema constraint before that. No Production query/mutation, migration, cron, merge, rebase or deploy. One-minute refresh cadence unchanged; `supabase db push` remains prohibited.


## 2026-11-20 — Provider response ordering is a second price conflict dimension
- Re-fetched main handoff before update; prior blob `f2824503d990913b4245e06a8b714403637419f6`.
- Re-read the complete 112-line checked-in `refresh_market_prices()` definition from migration `20261116203709_limit_primary_coingecko_batch_to_515_ids.sql`, blob `92196e0074700f85d927b0552a9677cd451fef1f`.
- Confirmed the response cursor over `private.market_price_sync_requests` has no `ORDER BY`. Accepted CoinGecko, KuCoin and Gate.io responses can all upsert the same `market_prices.symbol`; KuCoin/Gate.io are restricted to enabled pairs while CoinGecko also includes curated listings. The final price/source can depend on unspecified response-row order. `updated_at=now()` is processing time, not upstream event time.
- CoinGecko mapping cursor independently has no `ORDER BY` and can contain distinct IDs for the same symbol. Thus two conflict dimensions exist: duplicate candidate rows within one response, and different providers writing the same symbol across response rows.
- Existing fixture lines ~105–150 intentionally builds four SOL candidates (two CoinGecko IDs, KuCoin, Gate.io) and proves one raw multi-row upsert fails; it deliberately defines no winner. Parser tests cover per-provider ticker-array sequential updates, not response-queue provider precedence.
- Recorded this in PR #35 plan, docs-only commit `73b50c9e1f2c1665543607f3af831356e6aae7c1`, plan blob `534397f48e246780b7e57642baf7e3fcf08d8a57`. No SQL fixture/code change.
- PR #35 remains Draft; latest branch head after the plan update is `73b50c9e1f2c1665543607f3af831356e6aae7c1`. Before this update, contract run `44805687316` on previous docs head `e924d0d6d21c3a09278107f763b4341840cde579` was still in progress; previous head `8c330a75fa9b26293b7df38862d6cef9bf544cb5` had both PostgreSQL 17 and exact-decimal CI successful. Verify CI on the new head before claiming current-head success.
- Migration source reconciliation remains blocked: local source for the complete `refresh_crypto_assets()` definition is missing; backup documentation states the encrypted application-schema archive includes schema definitions but excludes `supabase_migrations.schema_migrations`. It may help recover a current schema/function snapshot through the isolated recovery drill, but it cannot reconstruct original migration history/source by itself.
- Next: verify latest PR CI; continue source recovery/reconciliation and keep the provider-precedence decision explicit. No Production query/mutation, migrations, cron, merge, rebase, or deployment. One-minute market-price cadence unchanged; `supabase db push` remains prohibited.


## 2026-11-20 — Downstream market-price source contract and current-head CI
- Re-fetched main handoff before update; prior blob `7046b8b18ec38b3525ee4e117b93a7bdf17028c9`.
- Static source review of `get_admin_market_listings()` (migration `20261113181000_show_live_prices_for_curated_assets.sql`, blob `56afc4506bfefdbadb62519e4b49d651c46dc8ca`) confirms curated-market price is exposed only when positive, no older than 2 minutes, and `source='CoinGecko'`.
- Static source review of `admin_get_market_pair_candidates()` / `admin_enable_market_pair()` (migration `20261113180000_add_admin_pair_activation_engine.sql`, blob `1473664435f7c70b100fbc7496a51cb3cadab8d0`) confirms pair eligibility and activation require a positive fresh CoinGecko-sourced price. A KuCoin/Gate.io last-writer value can therefore make a curated listing ineligible for pair activation even when positive and recent.
- Inspected trading/conditional price consumers: they use positive/fresh `market_prices.price` (typically one-minute freshness) without a source predicate in the reviewed paths. Therefore `source` is a behavioral contract for admin curated/activation flows, not just display metadata. A future bulk design must preserve this distinction; a simple global provider rank cannot be assumed.
- Recorded the consumer contract in PR #35 plan, docs-only commit `22795a74797276d70f5f43f7e160a1d939c0f45e`, plan blob `ad9a7b04d2967e2c73e0d0584c0c9d76a454a2e7`.
- Verified prior current PR head `73b50c9e1f2c1665543607f3af831356e6aae7c1`: PostgreSQL 17 contract run `44805784202` success; exact-decimal workflow `44805784195` success. This new docs commit is a new head and its own CI must be checked separately.
- PR #35 remains open Draft and unmerged; no SQL fixture/code changed. No Production query/mutation, migration, cron, merge, rebase, or deployment. One-minute market-price cadence unchanged; `supabase db push` remains prohibited.
- Next: inspect CI for docs head `22795a74797276d70f5f43f7e160a1d939c0f45e`; then continue building an explicit behavior matrix for CoinGecko-only curated/activation consumers versus provider-agnostic fresh-price trading consumers. Do not choose a provider winner or implement SQL until the semantic contract is approved/fully derived.


## 2026-11-20 — Added downstream source-contract regression fixture
- Re-fetched main handoff before update; prior blob `522300babfd414d8fc52f95aad5dc48ad89b3f2b`.
- Confirmed from repository source that curated-market display and admin pair activation require `source='CoinGecko'`, positive price and freshness <=2 minutes; reviewed trade/conditional price reads require positive price and freshness <=1 minute but do not filter source.
- Added an isolated fixture test to `supabase/tests/market_price_bulk_upsert_contract.sql` (commit `a747734bb67da5ef5384cf5509608a5aca1da7e7`, blob `dd9a1a5ca456b89d09ee54c26dc8dcc499bff7e0`) to lock these two consumer contracts without choosing a provider ranking or winner. Plan documentation updated in commit `1c81d1e3c2b799faf998bbffcbe46e7e6b224c0c`, blob `f2e2a55fbfc45ad55d90d09732fd42f6126d1d45`.
- CI for fixture commit `a747734bb67da5ef5384cf5509608a5aca1da7e7`: PR contract run `44806172205`, push contract run `44806163615`, exact-decimal PR run `44806172263` were in progress at handoff update. Documentation head `1c81d1e3c2b799faf998bbffcbe46e7e6b224c0c` also had contract push run `44806194362` in progress and exact-decimal PR run `44806202179` queued. No claim of success until all relevant jobs finish.
- PR #35 remains Draft/open/unmerged; latest head `1c81d1e3c2b799faf998bbffcbe46e7e6b224c0c`; three changed files only. No Production SQL/query, migration, cron, merge, rebase or deploy. One-minute cadence unchanged; `supabase db push` remains prohibited.
- Next: inspect run IDs above, diagnose any failure from job logs, and only then proceed with further source/provider equivalence work. Do not implement a bulk writer or infer source precedence while duplicate mapping and queue ordering remain unresolved.



## 2026-11-20 — Removed unspecified ticker/provider winner assumptions from PR #35 fixture
- Re-fetched live main handoff before update; prior blob SHA `ac10ee14e0030140ab69b0451f8bf8875624d86c`.
- Re-fetched PR #35 and confirmed it remains open, Draft, unmerged; current head before this test-only correction was `1c81d1e3c2b799faf998bbffcbe46e7e6b224c0c`.
- Static review of `supabase/tests/market_price_bulk_upsert_contract.sql` found the parser characterization asserted that the later duplicate KuCoin ticker must win, and then asserted Gate.io must overwrite KuCoin. The repository migration's provider ticker loops and queued-response cursor have no `ORDER BY`; those winner assertions were stronger than the source contract and contradicted the explicit unresolved-precedence analysis.
- Corrected only the isolated fixture on PR #35: removed the duplicate KuCoin BTC ticker assumption, asserted the single accepted KuCoin ticker's normalization, and truncated the fixture target before the independent Gate.io parser test so it no longer encodes cross-provider precedence. No production SQL or behavior was changed.
- Test-only commit: `2f69eda1578d005e0887d3ef9a75a0dd42a943e2`; changed fixture blob SHA `779210a402782169cf984a24c443b25e067de88d`.
- CI on corrected head: PostgreSQL 17 contract push run `44806791079` (in progress at handoff update); PR contract run `44806801853` (in progress); exact-decimal PR run `44806801857` (in progress). Do not claim corrected fixture green until all complete.
- PR #35 remains Draft and unmerged. GitHub reports `mergeable=true` at this check, which is metadata only. No Supabase SQL, Production query, migration, cron, index, market data, order, trade, wallet, or balance was changed. `supabase db push` remains prohibited; one-minute cadence unchanged.
- Next: poll the three CI runs above, inspect any failures, and retain the unresolved duplicate-ID/provider precedence gate. Do not implement a bulk writer or choose a winner without verified invariant or explicit product approval.


## 2026-11-20 — PR #35 fixture correction follow-up
- CI for test-only commit `2f69eda1578d005e0887d3ef9a75a0dd42a943e2`: PostgreSQL 17 contract runs `44806791079` and `44806801853` failed at fixture line 293 because the previous edit mistakenly truncated nonexistent relation `parser_price_target`. Exact error confirmed in both logs; not a production/database failure. Exact-decimal run `44806801857` passed, including PostgreSQL arithmetic, schema widening rehearsal/rollback checks, market/limit/stop-limit/TP-SL integration, and two-session race tests.
- Corrected the fixture relation to `gated_response_target` on PR #35 branch. New commit `56c4ea64525bbb35265f673ab4d97d92a0cc3ad0`, blob SHA `d3048961f182fc8bbe3c2b27f1cc46197fd71194`.
- New head checks observed in progress: PostgreSQL contract PR check `136534577946` / run `44807302190`; PostgreSQL contract push check `136534542201` / run `44807291120`; exact-decimal check `136534578992` / run `44807302227`. Poll before claiming success.
- PR #35 still Draft, open, unmerged; current head `56c4ea64525bbb35265f673ab4d97d92a0cc3ad0`. GitHub mergeable metadata true at this observation; do not merge.
- No Production changes. Next: poll the three checks, inspect failure logs if needed, then resume migration/source reconciliation. No DB SQL against unstable Supabase, no migration replay or `supabase db push`.


## 2026-11-20 — PR #35 CI and source-level market-price audit
- Re-fetched PR #35 live head: `56c4ea64525bbb35265f673ab4d97d92a0cc3ad0`; PR remains open, Draft, unmerged. No production actions.
- Corrected fixture PostgreSQL runs both passed: PR run `44807302190` and push run `44807291120`.
- Exact-decimal run `44807302227` remains in progress at this check. All completed steps passed, including browser/exact-decimal, PostgreSQL arithmetic, widening rehearsal and rollback/preflight checks, market/limit/stop-limit/TP-SL entrypoint tests, and limit cancellation lifecycle. Three two-session race/lifecycle steps remain running or pending; do not call this run green yet.
- Re-read source migrations on main:
  - `20261116203709_limit_primary_coingecko_batch_to_515_ids.sql` confirms the CoinGecko mapping UNION is over (symbol, coingecko_id), so distinct IDs can map to the same market_prices.symbol. Its mapping cursor has no ORDER BY; response queue cursor also has no ORDER BY.
  - CoinGecko, KuCoin, and Gate.io each write market_prices by symbol with ON CONFLICT DO UPDATE. Therefore both duplicate target symbols within a provider response and cross-provider winner order remain undefined; no safe bulk conflict winner can be inferred.
  - Response processing is wrapped in EXCEPTION WHEN OTHERS, then queue row is deleted after the block. A response-level SQL error can therefore be converted to a warning and the queued response removed; this is an additional reliability concern to analyze in an isolated fixture before proposing any change.
  - `get_admin_market_listings()`, `admin_review_market_listings()`, and `admin_enable_market_pair()` explicitly require positive fresh CoinGecko source (2-minute window) for curated market visibility/activation. KuCoin/Gate.io overwrites can make those consumers ineligible.
  - Trading/conditional price consumers use positive freshness checks but no provider source predicate, per earlier source audit. A single global provider precedence policy would not preserve both contracts.
  - Existing ticker collision trigger protects curated-listing insert/update paths and checks current curated assets plus demo pairs; it does not prove uniqueness across all crypto_assets symbol mutation paths.
- GitHub code search for `refresh_crypto_assets` found only a reference in the recovery migration and status documentation; full function body is not present in the checked-in migration source located. Do not claim complete crypto_assets symbol-write-path coverage.
- No Supabase SQL, migrations, cron, indexes, financial data, orders, trades, wallets, or balances were changed. `supabase db push` remains prohibited.
- Next: poll exact-decimal run `44807302227`; then investigate response deletion-on-error using isolated PostgreSQL fixtures and continue recovering missing applied migration/function source from authoritative backup/source artifacts. Keep PR #35 Draft and do not implement provider precedence without verified invariant or explicit product decision.


## 2026-11-20 — CI completion and parser-fixture correction
- Rechecked exact-decimal workflow run 44807302227 on PR #35 head 56c4ea64525bbb35265f673ab4d97d92a0cc3ad0: completed success. Its two-session Limit, TP-SL, and Stop-Limit race/lifecycle steps all completed successfully. Both PostgreSQL 17 contract runs 44807302190 and 44807291120 also completed success.
- PR #35 remains open, Draft, unmerged. No Production action.
- A source review of the parser fixture found that KuCoin and Gate.io were being written sequentially into one temporary table, with an assertion that Gate.io overwrote KuCoin BTC. This inadvertently encoded an unapproved cross-provider precedence in a test intended only to characterize each parser.
- Corrected supabase/tests/market_price_bulk_upsert_contract.sql on the PR branch in commit e3c826b97c1780fa3e2068db22c78e8b7f97a8b0 (new blob 6442d939c577e65ba78217b9e6c6f6ee4710e906): KuCoin and Gate.io now use separate temporary target tables and independently assert parsing/filtering. Four-candidate duplicate-key cardinality test remains provider-neutral. Updated PR design note in a subsequent docs-only branch commit.
- CI for corrected head must pass before calling this correction validated. This remains test-only/documentation-only on Draft PR #35.
- No Production SQL, migration, cron, market data, orders, trades, wallets, or balances changed. No supabase db push; cadence unchanged.
- Next: poll corrected-head PostgreSQL contract and exact-decimal CI; if green, continue static source and migration-reconciliation review. Preserve Draft status and avoid Production queries while DB instability persists.


## 2026-11-20 — Corrected provider parser fixture CI
- The corrected SQL fixture commit e3c826b97c1780fa3e2068db22c78e8b7f97a8b0 passed PostgreSQL 17 contract run 44807797106. The PR/push workflow triggered a duplicate contract run; run 44807787523 also completed success on the same fixture commit.
- Exact-decimal workflow run 44807797093 on fixture commit e3c826b97c1780fa3e2068db22c78e8b7f97a8b0 was still in progress at this check. Two contract runs 44807862263 and 44807849603 on documentation-only head baa5a6381c381965037feb6ebe02f42894d69ad4 were also in progress; do not report those as complete.
- PR #35 remains open Draft, unmerged. The fixture correction separates KuCoin and Gate.io parser targets and no longer asserts a Gate.io-over-KuCoin winner. The four-provider duplicate-target test remains a cardinality-mechanics test only.
- No Production database/function/cron/migration or financial data changes. No supabase db push; one-minute cadence unchanged.


## 2026-11-20 — Final CI confirmation and remaining source blocker
- Rechecked current PR #35 head `baa5a6381c381965037feb6ebe02f42894d69ad4`: PostgreSQL 17 contract runs `44807862263` and `44807849603` both completed success. Exact-decimal run `44807797093` completed success on code commit `e3c826b97c1780fa3e2068db22c78e8b7f97a8b0`; the later head advance to `baa5a6381c381965037feb6ebe02f42894d69ad4` changed only the design documentation. PR remains open Draft and unmerged.
- Re-read the 515-ID migration body on main (blob `92196e0074700f85d927b0552a9677cd451fef1f`). Confirmed response cursor has no ORDER BY; each response's provider loop is inside a nested exception block; the queue row is deleted after that block even when processing raises. A malformed ticker numeric cast rolls back earlier writes in that response, is converted to a warning, and then the response queue row is deleted. This is repository migration semantics only, not verified live deployed body.
- GitHub source search for `refresh_crypto_assets` again found only references in the recovery migration and status docs; full function definition still absent from checked-in migration source. Searches for crypto_assets writes show exchange observation ingestion and matching logic, but do not establish every `crypto_assets.symbol` mutation path. Do not claim a database-wide symbol uniqueness invariant or use PR #33 as proof of complete source recovery.
- Current evidence supports two separate unresolved dimensions: duplicate target symbol within a single provider response (especially CoinGecko's multiple IDs per symbol), and same symbol written by multiple queued provider responses in unspecified queue order. A bulk rewrite cannot combine raw rows into one ON CONFLICT statement, and no provider winner can be safely inferred. In addition, admin curated activation requires fresh positive CoinGecko source while trade execution checks positive freshness without a source predicate.
- No Production query/write, migration, cron, market data, order, trade, wallet, or balance change. `supabase db push` remains prohibited. Preserve one-minute cadence and PR #35 Draft.
- Next safe work: obtain authoritative missing applied function source / exact deployed function capture only after DB stability returns; otherwise continue static repository inventory and isolated fixtures. Any provider precedence or malformed-response retry behavior change requires explicit design approval and full regression coverage.


## 2026-11-20 — Continuation recheck: response exception semantics and CI
- Re-fetched `PROJECT_HANDOFF.md` from `main` before work (blob `8fdd98c0c5ee51ecf9bb1f14764456ddcf938ec3`); no newer handoff entry was present.
- Rechecked PR #35: open, Draft, unmerged; head `baa5a6381c381965037feb6ebe02f42894d69ad4`; mergeable metadata false. Changed files remain limited to the contract workflow, design note, and isolated SQL fixture. No rebase, merge, or deployment.
- Rechecked workflow runs on that exact head: PostgreSQL 17 contract run `44807862263` and exact-decimal run `44807862279` both completed successfully. This confirms the isolated test suite only, not live-function equivalence.
- Re-read main migration `20261116203709_limit_primary_coingecko_batch_to_515_ids.sql` (blob `92196e0074700f85d927b0552a9677cd451fef1f`). Exact control flow: each accepted provider response is processed inside a nested PL/pgSQL exception block; any error rolls back all writes made in that block for that response; `WHEN OTHERS` emits a warning and exits the block; the queue row is then deleted outside that nested block. The outer response cursor has no `ORDER BY`. The per-response queue deletion is therefore not a retry/dead-letter policy: ordinary caught processing failures are acknowledged/deleted rather than retried. The whole function still runs in its caller transaction, so a later uncaught failure that aborts the function transaction can roll back earlier queue deletions/writes; do not overstate deletion as durable before transaction commit.
- Re-read PR fixture (blob `6442d939c577e65ba78217b9e6c6f6ee4710e906`): it characterizes valid-write-then-malformed-cast rollback, caught-error queue deletion, continuation to a later independent response, provider response gates, malformed JSON/missing keys, and numeric edge cases. PostgreSQL 17 CI is green. These are isolated characterization tests, not a retry implementation.
- Design decision remains open: changing failed-response deletion into retry/dead-letter handling would alter queue semantics and requires explicit approval plus a bounded retry policy, attempt count/visibility, poison-message handling, and regression tests. No such behavior was changed.
- No Production SQL/query/write, migration, cron, index, market data, orders, trades, wallets, or balances were changed. No `supabase db push`; one-minute cadence unchanged.
- Next safe step: continue static inventory of migration-history/source gaps and test design offline; do not query unstable Production DB or infer exact deployed function equivalence from repository migrations.


## 2026-11-20 — Recovered crypto-asset refresh source from isolated backup
- Re-fetched this handoff from `main` before editing (prior blob `b2392c0f855d6a952aaf22a0cae9b3f408c1c73f`).
- The repository-only search had missed the complete `public.refresh_crypto_assets()` body. Recovered it read-only from the isolated `DigiArz-Recovery-Test` project (`zrriqwyolcjhbappocuw`), which reports `ACTIVE_HEALTHY`. This was NOT the Production project. Recovery documentation confirms the isolated restore used encrypted backup artifact from GitHub backup run `43848835281`, created 2026-11-16 10:26:20 UTC (head commit `e05ab44f94488bad942bf19aff031a27b2132230`), restored by isolated recovery drill run `44298621534` on 2026-11-18.
- Captured function definition size: 8,885 bytes. Treat this as a historical application-schema snapshot from the Nov 16 backup, not proof of the exact live Production definition on Nov 20. No Production query was made.
- Source findings in that snapshot:
  - `refresh_crypto_assets()` upserts `public.crypto_assets` on `coingecko_id` and explicitly updates `symbol = EXCLUDED.symbol` from the CoinGecko response. Thus this function is a confirmed symbol-mutation path in the recovered snapshot.
  - Its INSERT SELECT does not deduplicate by symbol; the only conflict target is `coingecko_id`. Different CoinGecko IDs can therefore carry the same normalized ticker into `crypto_assets` unless another constraint/trigger blocks it.
  - Catalog inspection of the restored snapshot found `crypto_assets` primary key only on `coingecko_id`; no unique constraint on `symbol`. No user trigger was attached to `crypto_assets`.
  - The `admin_market_listing_unique_ticker` trigger is attached to `admin_market_listings` (BEFORE INSERT/UPDATE OF coingecko_id), not `crypto_assets`. It checks collisions when a curated listing is inserted/updated, but does not guard subsequent symbol changes in `crypto_assets`.
  - `auto_list_verified_exchange_asset` is attached to `exchange_asset_observations`; it conditionally inserts into curated listings only when exactly one active crypto asset currently matches that ticker. This is a point-in-time admission check, not a permanent invariant on `crypto_assets.symbol`.
  - The recovered `process_iran_exchange_asset_sync()` and `process_bit24_exchange_sync()` write/update `exchange_asset_observations` and matcher fields, not `crypto_assets.symbol`. Admin add/enable functions read crypto asset symbols and write listing/pair tables; they do not update `crypto_assets.symbol`.
- Conclusion bounded to the restored Nov 16 snapshot: `refresh_crypto_assets()` is the confirmed application-function writer of `crypto_assets.symbol`; current schema does not enforce global ticker uniqueness there. This materially strengthens the duplicate-symbol risk analysis for CoinGecko mapping and market-price target collisions, but does not establish Nov 20 Production state or exclude other privileged/direct writers outside the captured application function inventory.
- Backup artifact is explicitly not a full Supabase backup and excludes `supabase_migrations.schema_migrations`; it can recover schema/function definitions but cannot reconstruct original migration history. Do not mark migrations applied based on this snapshot.
- No Production query/write, migration, function, index, cron, market data, orders, trades, wallets, or balances changed. No `supabase db push`; PR #35 remains Draft; one-minute cadence unchanged.
- Next safe step: use this recovered historical definition to build a source-vs-snapshot comparison checklist and enumerate the remaining missing applied migration sources; only capture the exact live Production function again after database stability returns.


## 2026-11-20 — Offline migration-source inventory continuation
- Re-fetched handoff from `main` before editing (blob `6130e0dbacbd25d1f9304708572b829234e001da`).
- Enumerated the current `main` `supabase/migrations/` directory through GitHub Contents API: exactly 40 SQL migration files are present.
- Re-read the two crypto-asset migrations most likely to be mistaken for the missing function source:
  - `20261113170000_recover_stalled_crypto_asset_sync.sql` (blob `122db694d7979c631e8dc3196decc289d104afb8`) defines only `recover_stale_crypto_assets_sync()`, its one-minute recovery cron, and immediate recovery call. It does not define `refresh_crypto_assets()`.
  - `20261113190000_admin_on_demand_crypto_asset_refresh.sql` (blob `fab27f28da6ba24abdd2abbc05d0e20cca664f6f`) defines the admin refresh rate-limit claim and admin search RPC; it does not define `refresh_crypto_assets()`.
- Re-read the market-price migration `20261116203709_limit_primary_coingecko_batch_to_515_ids.sql` (blob `92196e0074700f85d927b0552a9677cd451fef1f`): it replaces `refresh_market_prices()`, not `refresh_crypto_assets()`. Its current source confirms three independent provider branches and response-row deletion after the nested catch block.
- Re-read backup/recovery documentation (blob `4df5ba404854195949f084c911b477acc9440552`): the encrypted archive deliberately excludes `supabase_migrations.schema_migrations`; it cannot establish applied migration versions or repair migration history. The documented restore drill is isolated and does not include Auth, Storage, Vault, Edge Functions, project settings, or migration history.
- The current repository count remains 40 local migration files. Previously recorded inventory comparison (52 applied vs 40 local, 14 applied versions without local SQL source, 20 timestamp-prefix mismatches, and two local-only older KuCoin/Gate.io refresh definitions) remains a historical finding that cannot be revalidated from this archive. Do not present it as a fresh Production check. Exact version-by-version reconciliation is blocked until a low-impact read can safely run against Production or an authoritative migration-history export is obtained.
- No Production SQL/query/write was performed in this continuation. No migration, function, index, cron, market data, orders, trades, wallets, or balances changed. No `supabase db push`; PR #35 remains Draft and unmerged.
- Next safe step: build a deterministic local filename/version manifest and keep the applied-version side explicitly unknown until an authoritative export is available; never infer it from restored schema objects.


## 2026-11-20 — Deterministic local migration manifest added
- Re-fetched `PROJECT_HANDOFF.md` from `main` before editing (blob `8e94065555fed128dc63f719df27f9794bce0e4c`).
- Enumerated the full recursive Git tree at prior main commit `f0f7ad7ae99be8033af25aa251e1eac48652865e`; confirmed exactly 40 current `supabase/migrations/*.sql` files.
- Queried GitHub commit history scoped to `supabase/migrations/`: 44 commits. Inspected the four filename-correction commits and their diffs:
  - Market-price batch source was added under the applied timestamp in `2b3c53776aa61d04286d1dc24532722eebad1bed`, then the duplicate timestamped file was removed in `7c756ed4e00de5640902196dbae874b9fe39f525`; surviving file is `20261116203709_limit_primary_coingecko_batch_to_515_ids.sql`.
  - Stop-Limit retry-bound source was aligned in `eb8234f24ea32d468a6e297ced6074a1f8f38498`, then its duplicate timestamped file was removed in `db5c2ab2736f9c5d60e8faa05e2f7488d667e8`.
- These four commits explain the difference between 44 path-history commits and 40 current files; they do not explain or resolve the previously reported applied-version/source gaps.
- Added `docs/MIGRATION_SOURCE_INVENTORY.md` on `main` in commit `0d3527f0f74e66d89969482f72fd9e3f0d62096d`. It records all 40 exact local migration filenames, the two proven rename corrections, and the limits/requirements for authoritative applied-version reconciliation.
- Applied Production migration ledger remains unknown in this step. No Production SQL/query/write, migration, function, index, cron, market data, orders, trades, wallets, or balances changed. No `supabase db push`; PR #35 remains Draft and unmerged.
- Next safe step: inspect Git history and workflow artifacts for the missing source definitions without inferring applied status. If no trustworthy artifact exists, record each unrecoverable source as unresolved rather than fabricating or replaying SQL.


## 2026-11-20 — GitHub Actions artifact provenance check
- Re-fetched `PROJECT_HANDOFF.md` from `main` before editing (blob `27e34a232a9f9651e7aa25620966d429b0617cad`).
- Queried artifacts for known successful backup workflow run `43848835281`: exactly one non-expired artifact was returned, `DigiArz-database-backup` (artifact ID `14217201032`, 2,231,010 bytes, created `2026-11-16T10:26:47Z`).
- Queried artifacts for isolated recovery drill run `44298621534`: zero artifacts returned.
- Queried artifacts for recent contract-test run `44807862263`: zero artifacts returned.
- Recent Actions run listing (first 100 of 2,323) contained no workflow names matching backup/recovery/migration/schema; this is only a recent-page observation, not an exhaustive history search. The API wrapper does not expose a usable workflow-specific run listing in the current connection.
- This confirms the known backup archive is the only artifact surfaced by the specifically inspected backup run; it does not prove that no older/other artifact exists. No new source SQL or applied migration ledger was recovered.
- Do not download/restore the archive again solely to repeat already completed schema-source recovery. It excludes migration history and cannot prove applied versions.
- No Production SQL/query/write, migration, function, index, cron, market data, orders, trades, wallets, or balances changed. No `supabase db push`; PR #35 remains Draft and unmerged.
- Next safe step: obtain the exact list of missing applied version strings from a trusted migration-ledger export or previously retained audit evidence. Without those identifiers, searching Git history/artifacts for individual missing SQL sources is underdetermined; do not guess filenames or fabricate SQL.


## 2026-11-20 — Migration manifest formatting correction and live PR inventory
- Re-fetched `PROJECT_HANDOFF.md` from `main` before work (blob `d72a8885ce7fcb511681e6156da326962f8fed00`).
- Re-read `docs/MIGRATION_SOURCE_INVENTORY.md` (blob `a2442039f397a930ab5e54cfa3d6a964744272ad`) and found a formatting defect: all 40 entries displayed the literal prefix `202` instead of the full 14-digit migration version. The underlying filenames were intact, but the manifest was not usable for exact version comparison.
- Corrected all 40 manifest entries to show the full 14-digit version extracted from each exact filename. Guard check confirmed exactly 40 versioned entries. Inventory update commit: `1767b8843b1a81a92b920d0071cc60c2b5c42d77`.
- Rechecked live open PR inventory. In addition to previously tracked PRs, PR #36 is now open: “Draft: bound TP/SL retries for invalid reservations”. PR #35 remains open; do not infer draft/head/check state from the title-only search result. Existing PR #32/#33 remain open as well. No PR was modified.
- Applied Production migration ledger remains unavailable in this safe offline step; do not treat the corrected local manifest as the applied ledger. No Production SQL/query/write, migration, function, index, cron, market data, orders, trades, wallets, or balances changed. No `supabase db push`.
- Next: use the corrected 14-digit local version list only when an authoritative applied-version export becomes available; otherwise continue bounded offline source recovery and verify PR #36/#35 live details before relying on their status.


## 2026-11-20 — PR #36 live verification and manual-review safety gate
- Re-fetched this handoff from `main` before work (blob `66601c036943ca6c6aad72173af6ac42837bc0a5`).
- Rechecked PR #36 via GitHub API: open, Draft, unmerged, head `d0da205cce649faa23e9bcc50d2c840f0bf1fe6f`, base `main`, mergeable metadata true. Changed files are the exact-decimal workflow, isolated draft SQL `supabase/drafts/2026-11-20_bounded_conditional_reservation_retry.sql`, and regression `supabase/tests/exact_decimal_conditional_reservation_retry.sql`.
- Exact-decimal check on PR #36 head completed successfully: run `44787061755`, all 22 steps reported successful in the PR description; live commit check-run also reports completed/success. This is disposable PostgreSQL 17 CI only.
- Re-read the full candidate SQL and regression. The validation-failure branch increments attempts and on attempt 10 rejects the parent order and conditional row, while intentionally leaving missing/released/wrong-asset/undersized reservation rows unchanged. Fixture verifies 9 pending attempts, rejection on 10, reservation non-mutation, and no later retries.
- Safety gate: a rejected order with a still-reserved but invalid reservation can leave funds/assets unavailable until separately reconciled. This is the explicit fail-closed policy in the PR, not a release defect to “fix” automatically; before any future production rollout, require a documented operator/manual-reconciliation path and verify that no invalid reservation can be released or reassigned incorrectly. Targeted repository search found existing manual-review wording and Stop-Limit precedent, but did not establish a complete operator workflow.
- PR #35 was also rechecked: open, Draft, unmerged, head `baa5a6381c381965037feb6ebe02f42894d69ad4`; both PostgreSQL 17 contract runs and exact-decimal check on that head completed successfully. Keep Draft; synthetic tests do not establish live-function equivalence or authorize deployment.
- No PR was modified or merged. No Production SQL/query/write, migration, function, cron, index, orders, reservations, wallets, balances, or market data changed. No `supabase db push`.
- Next: review the remaining authenticated financial RPCs for reservation-state invariants and operator recovery semantics using repository source/tests only; avoid Production reads while database instability remains.


## 2026-11-20 — Deactivation path reservation recovery audit
- Re-fetched `PROJECT_HANDOFF.md` from `main` before this step (blob `5509368136cd12b7815bbb8fa3326e2d7d4261f0`).
- Re-read full `deactivate_my_account()` definitions in migration `20261113162051_add_demo_take_profit_stop_loss_engine.sql` (blob `3360c21a69b7fae83a7f2494428367d1b7658e81`) and later Stop-Limit replacement `20261113181827_add_stop_limit_order_engine.sql` (blob `3f421c6380630d74b846cd66dc7b121786237c0f`). Both have the same cleanup pattern.
- Finding: deactivation releases only reserved rows with `0 <= consumed_amount <= reserved_amount`, but cancels open Limit/Conditional parent orders regardless of whether their reservation matched the release UPDATE. An invalid reservation can therefore remain `reserved` while its order is cancelled. Return JSON reports only counts of cancelled orders/released reservations, not skipped invalid reservation IDs/counts.
- Additional idempotency gap: if profile is already inactive, function returns immediately with zero counts and does not retry cleanup. Thus an invalid reservation repaired later cannot be reconciled by simply retrying this RPC. Repository source review did not identify a dedicated operator reconciliation RPC/workflow. This is a source-level operational risk, not proof of affected Production rows.
- Updated `docs/FINANCIAL_RPC_AUDIT_2026-11-20.md` with evidence and safe remediation direction (read-only exception report + audited/manual reconciliation; never auto-release or rewrite suspect amounts). Audit update commit: `5b4fc8f357f00929a014e9f8c061f50e6de2428e`.
- No Production query/write, migration, RPC, cron, grants, policies, orders, reservations, wallets, balances, or market prices changed. No PR merged; no `supabase db push`.
- Next: inspect cancellation/worker concurrency and reservation lifecycle invariants across Limit, TP/SL, and Stop-Limit source, focusing on exact lock acquisition order and whether terminal parent states can strand reservations; document only proven paths and build disposable PostgreSQL 17 tests if a safe fixture exists.


## 2026-11-20 — Stop-Limit child-row synchronization lock audit
- Re-fetched `PROJECT_HANDOFF.md` from `main` before work (blob `37baa51aefa869e1f381ec8f7268c780852a5bde`).
- Re-read live repository Migration `supabase/migrations/20261113181827_add_stop_limit_order_engine.sql` (blob `3f421c6380630d74b846cd66dc7b121786237c0f`). In the first parent/child sync loop of `process_stop_limit_orders()`, the query joins child status/fill values but locks only `c,parent` using `FOR UPDATE OF c,parent SKIP LOCKED`; child is not locked. `cancel_stop_limit_order()` locks conditional → parent → child and delegates open child cancellation to `cancel_limit_order()`.
- Found an existing isolated candidate: `supabase/tests/exact_decimal_stop_limit_worker.sql` (blob `6ca50aae244a494a897dfcc71f495242dc44aac6`) uses `FOR UPDATE OF c,parent,child SKIP LOCKED`; the rollout candidate also contains this child lock. With the child lock, parent sync skips a child currently held by Limit worker and catches up on a later cycle.
- Existing two-session race script `supabase/tests/exact_decimal_stop_limit_cancel_race.sh` (blob `e88607d4afea2e41d25872f41fcdd3ed79f1fd85`) covers worker-first/cancel-first and partial-fill-vs-parent-sync interleavings; verification checks parent/child state, trades, reservation arithmetic, and balances. `supabase/EXACT_DECIMAL_ROLLOUT.md` records prior disposable-PostgreSQL rehearsal. These are candidate tests and historical CI evidence, not proof the current Production function or migration has the lock.
- Recorded the source-vs-candidate discrepancy in `docs/FINANCIAL_RPC_AUDIT_2026-11-20.md`; audit update commit: `5744e27c0e1d29617d0b46d49ea7fe11a9aebe00`.
- No Production query/write, function, migration, cron, grants, policies, orders, reservations, wallets, balances, or market prices changed. No PR merged; no `supabase db push`.
- Next: inspect current exact-decimal workflow/run provenance and compare the candidate function against current main migration and the latest known live snapshot; if the candidate remains appropriate, add a narrowly scoped source-contract regression so the missing child lock cannot silently reappear. Keep all changes non-production and PRs Draft.


## 2026-11-20 — Stop-Limit CI provenance clarification
- Re-fetched `PROJECT_HANDOFF.md` from `main` before this step (blob `9162188302c8d337fe4010ff78605abcbd4a3829`).
- Inspected current workflow `.github/workflows/exact-decimal-tests.yml` (blob `50936f9c8b59a44112ae59730092a91b0d2d17d8`). It contains two distinct Stop-Limit two-session race paths. The combined rollout rehearsal creates disposable DB `digiarz_rollout_stop_race_test` using setup + `supabase/drafts/2026-11-16_exact_decimal_rollout_candidate.sql` + race setup, then runs `exact_decimal_stop_limit_cancel_race.sh`. The older standalone race path uses the Nov 15 entrypoint candidate and test worker SQL.
- Inspected race setup (blob `0e0458b49ec88bceb96a8fb76207154c1a39c8ed`) and verify (blob `47e6f192b45715dd3f18c114b998d42904542ab2`): test includes child-worker-first/cancel-waits, cancel-first/worker skips, and child second partial fill while parent sync must report synced=0 then catch up on next cycle; verifies trade counts, fill amounts, reservation arithmetic, wallet and asset balances.
- Important evidence boundary: current main migration blob `3f421c6380630d74b846cd66dc7b121786237c0f` still locks only `c,parent`; CI installs the draft candidate, not this migration. Thus workflow design tests candidate behavior in disposable PostgreSQL, not migration parity or live Production. Workflow definition was verified; a fresh run ID for current HEAD was not retrieved in this step, so no claim of a new passing run.
- Added this provenance clarification to `docs/FINANCIAL_RPC_AUDIT_2026-11-20.md`; commit `0d9ff26c47aaa0a90db3546c6d2cc728be583373`.
- No Production query/write, migration, RPC, cron, financial data, or deployment. No PR merged; no `supabase db push`.
- Next: determine whether an isolated source-contract check can assert candidate lock behavior and explicitly report migration divergence without making the main CI fail; separately recover a fresh workflow run record before stating current green status.


## 2026-11-20 — Stop-Limit source-contract guard PR #37
- Re-fetched this handoff from \`main\` before updating (blob \`34f2b2626a6b0a89bbc5bbdb367de4ed170e5d53\`).
- Created Draft PR #37: https://github.com/shahram-adim/DigiArz/pull/37, branch \`test/stop-limit-child-lock-source-contract\`, head \`d727a6593323bed5f8370da97b64281e3464a6e0\`.
- New source-contract test in \`tests/exact-decimal-sql-drafts.test.js\` extracts the first sync loop from the combined rollout candidate and the checked-in Stop-Limit migration. It requires candidate child locking (\`c,parent,child\`) and explicitly records that the checked-in migration still lacks child locking (\`c,parent\`). This is a visibility/anti-drift guard, not a migration fix. If the migration is deliberately reconciled, update the test's expected divergence.
- PR #37 is open, Draft, unmerged. At first status retrieval after creation, no workflow run or combined status had appeared for head \`d727a659...\`; do not claim its CI passed until a run is retrieved.
- Retrieved PR #35 exact-decimal run #1233, run ID \`44807862279\`, on head \`baa5a638...\`: PostgreSQL 17 job success; all 22 workflow steps succeeded, including combined candidate rehearsal and real two-session Stop-Limit race. This validates disposable candidate test path only, not migration parity or Production.
- PR #36 exact-decimal run #1177 (\`44787061755\`) remains successful for the separate TP/SL retry fixture.
- Audit report updated in commit \`95869c29d9be639b585f973132916070345efd38\`.
- No Production query/write, migration/RPC/cron/financial data change, merge, rebase, deployment, or \`supabase db push\`.
- Next: retrieve PR #37 CI result; if it passes, continue with a separate parity review against the latest authoritative live Stop-Limit function snapshot and decide whether the draft candidate is safe to propose for migration reconciliation. Do not modify Production or merge any PR.


## 2026-11-20 — PR #37 initial CI failure and correction
- PR #37 first workflow run #1251, ID \`44810577661\`, failed at Node test step 5. The source-contract test could not extract the function body because its regex stopped at the opening \`$function$\` delimiter. All subsequent PostgreSQL steps were skipped; this was a test-harness bug, not a failure of the PostgreSQL Stop-Limit race fixture.
- Corrected extractor in PR #37 commit \`bdb0c8f583a0596f1bf4b1a6982dba16b25d2df7\` to capture text between \`AS $function$\` and the closing delimiter. Re-fetched the updated test file and verified the corrected source.
- Fresh workflow/status lookup for corrected head returned no run and no combined status yet. Do not claim CI pass. The original failing run remains attached to prior head \`d727a659...\`.
- Branch comparison: 3 commits ahead / 2 behind main, because main audit/handoff docs changed after PR creation. Keep Draft; do not rebase or force-update.
- Audit report update commit: \`521d0d8d768361b28e0d6391a341a63fd91cfbcc\`.
- No Production changes, merge, rebase, deployment, or \`supabase db push\`.
- Next: wait for/retrieve CI for corrected PR #37 head \`bdb0c8f...\`; if no run appears, diagnose Actions trigger/status retrieval without changing Production or synchronizing branches.


## 2026-11-20 — PR #37 corrected CI is running
- Rechecked corrected head \`bdb0c8f583a0596f1bf4b1a6982dba16b25d2df7\`: workflow run #1254, ID \`44810724098\`, is in progress.
- Confirmed Node/browser test step passed, including new Stop-Limit source-contract test. PostgreSQL arithmetic, widening rehearsal, negative preflight, and lock-timeout preflight setup passed; lock-timeout atomicity step remained in progress at last check.
- Combined rollout candidate rehearsal and the two-session Stop-Limit race occur later in the workflow and have not yet run in this attempt. Do not claim full CI success.
- Audit report update commit: \`d9719b9846b806f55b84f2c32b50cfd06a194096\`.
- No Production change, PR merge/rebase, deployment, or \`supabase db push\`.
- Next: retrieve run #1254 again; only after all steps complete can PR #37 be described as passing.


## 2026-11-20 — PR #37 corrected-head CI completed successfully
- Re-fetched this handoff from `main` before update; verified current blob SHA `36140e324620a8e376b4dfd3a2c4fd53c7bc2741`.
- Re-fetched `docs/FINANCIAL_RPC_AUDIT_2026-11-20.md` before update; verified current blob SHA `1bbfb0ba9ca8aca6b2f381591fba8a6bd773ad9f`.
- Rechecked PR #37 corrected head `bdb0c8f583a0596f1bf4b1a6982dba16b25d2df7`: workflow run #1254, ID `44810724098`, completed with overall conclusion `success`.
- Retrieved all job steps. All 21 substantive workflow steps completed successfully, including Node source-contract regression, PostgreSQL arithmetic/schema-widening/rollback checks, combined candidate rehearsal, Limit and TP-SL two-session races, real two-session Stop-Limit child execution/cancellation race, and lifecycle integration tests.
- Evidence boundary unchanged: the tests install the combined draft rollout candidate in disposable PostgreSQL 17. The checked-in main Stop-Limit migration still has the recorded candidate-vs-migration child-lock divergence; CI success does not prove migration parity or live Production compatibility.
- Updated `docs/FINANCIAL_RPC_AUDIT_2026-11-20.md` with exact run ID, head SHA, full-success result, coverage, and limitations.
- PR #37 remains Draft/open/unmerged. No rebase, merge, deployment, Production SQL/query/write, migration/RPC/cron/financial-data change, or `supabase db push`.
- **Next action:** continue non-production source audit of financial reservation/order lifecycle and separately define an authoritative parity-reconciliation plan for Stop-Limit. Keep all PRs Draft; no Production change without explicit approval.


## 2026-11-20 — بررسی فرضیهٔ race بین deactivate و ثبت مالی
- Re-fetched handoff و audit report از `main` پیش از ویرایش؛ blobهای ورودی به‌ترتیب `11e3be0cf3cb052ded12816bab5ad51f70fdca9c` و `d2a75f5700a4e2225579b68a547186f641989bba` بودند.
- منبع Migration نشان می‌دهد `execute_demo_trade`, `place_limit_order`, `place_conditional_exit_order`, و `place_stop_limit_order` در ابتدای مسیر `current_account_is_active()` را می‌خوانند؛ سپس عملیات مالی را انجام می‌دهند. `deactivate_my_account()` ابتدا `profiles.is_active=false` می‌نویسد و سپس رزروها/سفارش‌های باز را پاک‌سازی می‌کند.
- در بدنهٔ entrypointهای بررسی‌شده، قفل صریح مشترک روی ردیف profile یا recheck انتهایی مشاهده نشد. این یک interleaving بالقوه برای آزمون دو‌نشستی است، نه نقص اثبات‌شده.
- جست‌وجوی مخزن نام `guard_active_account_writes` را فقط در fixture widening یافت؛ بدنهٔ fixture no-op است و دربارهٔ Production چیزی ثابت نمی‌کند. فهرست authoritative triggerهای Production در این مرحله در دسترس نبود.
- گزارش ممیزی با مرزبندی شواهد و طرح fixture دو‌نشستی به‌روزرسانی شد. هیچ تست race اجرا یا Migration/trigger/RPC/Production تغییر داده نشد.
- **گام بعد:** ساخت fixture PostgreSQL 17 مستقل برای race بین deactivation و Market/Limit/TP-SL/Stop-Limit، با barrierهای قطعی و بررسی وضعیت نهایی order/trade/reservation. پیش از هر اصلاح، triggerها و قفل profile در schema authoritative باید تأیید شوند.
- PRها Draft باقی می‌مانند؛ بدون Production change، merge/rebase/deploy یا `supabase db push`.


## 2026-11-20 — PR #38 fixture account-deactivation/order race
- Re-fetched `PROJECT_HANDOFF.md` and audit from `main` before edits; current input blobs were `3e2a1a5d3be8ce99c7b53d87f84d994dc4c6a5e2` and `f02d588a415934857aeaf9e9013cd69bd4ab1e59`.
- Created Draft PR #38: https://github.com/shahram-adim/DigiArz/pull/38, branch `test/account-deactivation-order-race`, head `a6849671727fce10fe852bda607fd65b3fc2a351`.
- Added disposable PostgreSQL 17 setup and two-session shell race fixture. Case 1 reproduces the stale active-check / later-write pattern and verifies a pending order plus reserved funds can appear after deactivation in the deliberately unlocked model. Cases 2/3 exercise candidate profile-row serialization in both orderings: placement-first is cleaned up after deactivation waits; deactivation-first rejects placement.
- Added the fixture to `.github/workflows/exact-decimal-tests.yml`. Re-fetched all three branch files and verified the workflow step and fixture content.
- First CI lookup for PR head returned no workflow runs; CI is **not yet confirmed**, do not report test pass until run appears and all relevant steps are inspected.
- Evidence boundary: fixture models the concurrency primitive; it does not execute the full four production RPC bodies and cannot rule out unseen Production triggers/locks. No Production schema query/write, migration/RPC/cron/financial-data change, merge, rebase, deployment or `supabase db push`.
- Next: monitor PR #38 CI, inspect logs if failure, and if green expand toward full entrypoint integration. Obtain authoritative trigger/profile-lock inventory from safe schema snapshot before any remediation proposal.
- Keep PR #38 Draft and all prior PRs Draft; no Production changes without explicit user approval.


## 2026-11-20 — PR #38 CI progress / trigger search checkpoint
- Re-fetched current main handoff and audit before recording this checkpoint; input blobs: `4ab12723e306d3bed49ff4bfaa28a7b3aa6d08d5` and `d8992aedc4d99c0b35325892237fe74eee480ddd`.
- Run #1263 (ID `44811642137`) on PR #38 head `a6849671727fce10fe852bda607fd65b3fc2a351` is in progress. Steps 1–18 succeeded; step 19 (Stop-Limit child execution/cancellation race) is running; steps 20–22 remain pending. The new account deactivation test is step 22 and has not run; do not report PR CI green.
- Repository code searches for trigger declarations and relevant account-active/deactivation references did not surface an authoritative complete live trigger inventory. This is not evidence that Production has no trigger.
- Audit report updated with this boundary. No Production DB query/write, RPC/Migration/cron/data change, merge/rebase/deploy, or db push.
- Next: monitor run #1263 through steps 19–22 and inspect logs on failure; after completion record the exact result. Keep PR #38 Draft.


## 2026-11-20 — PR #38 CI final success
- Re-fetched main handoff and audit before this update; current input blobs: `e423482f53e73928345a4364bae985f55390577d` and `e2584bf826c38dd8860fcaf66e897f4662b323d9`.
- PR #38 run #1263 / ID `44811642137` on head `a6849671727fce10fe852bda607fd65b3fc2a351` completed with conclusion `success`. All 22 substantive workflow steps passed; cleanup and job completion passed too.
- Step 22, `Run isolated two-session account deactivation/order placement race`, passed. The isolated fixture reproduced the unlocked TOCTOU scenario and validated the profile-row serialization protocol in both lock orderings.
- Evidence boundary unchanged: this is a simplified disposable PostgreSQL concurrency fixture, not full execution of the four Production financial RPCs; repository searches are not an authoritative live trigger inventory. No Production change/query, migration, cron, financial data, merge/rebase/deploy, or `supabase db push`.
- PR #38 remains Draft/open/unmerged. Next safe task: strengthen fixture to run the actual source-faithful entrypoint function bodies and/or obtain authoritative schema snapshot trigger inventory before any remediation design. No Production changes without explicit approval.


## 2026-11-21 — source-faithful feasibility review for PR #38
- Re-fetched main handoff before this step (blob `68cf1ecd83e8b8d5ee404b32de7b9cf0bb7f9a61`) and re-fetched the actual main migration sources and workflow.
- Confirmed PR #38's race fixture is a miniature concurrency model, not the four actual financial entrypoints: it defines `place_order_unlocked`, `place_order_profile_locked`, and a fixture-only deactivation function, with a two-second sleep between check and write.
- Main workflow Market/Limit and conditional integration steps load draft exact-decimal candidate SQL, not the checked-in Production migration bodies. Several setup fixtures intentionally simplify schemas/helpers; one fixture uses `current_account_is_active() RETURNS true` and a no-op trigger. Those are not evidence of Production account gating.
- Mapped source entrypoints and dependencies: Market `execute_demo_trade`; Limit `place_limit_order`; TP/SL `place_conditional_exit_order`; Stop-Limit `place_stop_limit_order`; plus `deactivate_my_account`. They require the real auth/JWT and SECURITY DEFINER context, profile active-check, financial tables, fee/pair helpers, and lifecycle dependencies. The complete dependency surface cannot safely be represented by the current three-table race fixture.
- Decision: did not add a weak or misleading "integration" test. A source-faithful test needs a dependency-complete disposable PostgreSQL bootstrap, explicit inventory of any remaining stubs/triggers, structural parity checks against selected migration source, and an external deterministic barrier that does not alter business logic.
- Updated `docs/FINANCIAL_RPC_AUDIT_2026-11-20.md` with the dependency map, fixture limitations, and next safe design step; audit commit `222830ca3024df77a3ec2b438e90af670ed2394f`, blob `85ad216ac50374bd42d10b6121f24135326619b5`.
- No PR branch edits, main migration/workflow changes, Supabase/Production queries or writes, trigger/RPC/cron/financial-data changes, merge/rebase/deploy, or `supabase db push`. PR #38 remains Draft and must not be merged.
- Next: design and statically verify a dependency-complete disposable PostgreSQL bootstrap from the migration source before adding a race harness. If full source fidelity cannot be achieved without stubbing the tested behavior, retain PR #38 only as a concurrency-primitive demonstration and label it accordingly.


## 2026-11-21 — dependency-complete PostgreSQL race bootstrap plan
- Re-fetched current `PROJECT_HANDOFF.md` before update; input blob `1dbfa77e4f1554e0e3768e49bffc34e29e8e6985`.
- Re-fetched the actual Market/Limit, TP/SL, Stop-Limit migration sources, the current workflow, both relevant shared setup fixtures, and PR #38 setup on its own branch.
- Created `docs/FINANCIAL_RACE_BOOTSTRAP_PLAN_2026-11-21.md` (commit `757c14155f448fe79aaf6087615c6fd138afd931`). It maps the four real entrypoints and deactivation dependencies, identifies existing fixture substitutions, defines source recovery/bootstrap/parity gates, and sets both race orderings and financial lifecycle assertions.
- Key blocker: checked-in financial migrations contain the RPC bodies but do not provide a complete authoritative base schema/helper/trigger/role inventory. Repository code search in this pass did not recover the complete original DDL for profiles/orders/wallets/asset_balances/order_reservations, `current_account_is_active()`, `get_demo_trading_fee_rate()`, or all relevant triggers/grants. This is a repository-evidence gap, not proof those objects do not exist.
- No new harness code was written or run because a dependency-complete, source-faithful bootstrap cannot yet be proven. PR #38 remains only a concurrency-primitive demonstration; do not label it a full RPC integration test.
- No Production query/write, Supabase project change, migration/RPC/trigger/cron/financial-data change, PR branch edit, merge/rebase/deploy, or `supabase db push`.
- Next: recover the foundational migration history/DDL and exact helper/trigger sources (including renamed/removed Git history) before implementing the disposable bootstrap. If source parity cannot be established, stop at a documented partial harness.


## 2026-11-21 — workflow provenance and schema source recovery refined
- Re-read the exact-decimal workflow and entrypoint assertion SQL. Existing Market/Limit integration loads the fixture plus `supabase/drafts/2026-11-15_exact_decimal_entrypoint_candidates.sql`; Stop-Limit/TP-SL placement and lifecycle steps also load draft candidate SQL. These are useful disposable PostgreSQL candidate integration tests, but not executions of the current Production migration RPC bodies.
- Verified the assertion scripts do substantive precision/reservation/rejection checks: Market/Limit test blob `3d324573b8304cf1820a5be4bc958a50130b1551`; conditional entrypoint test blob `d520cb9bdecc255b743f0750d14900984fc457f6`.
- Refined recoverable source inventory: TP/SL migration defines `conditional_orders` DDL/RLS/policy/grants and its real RPCs; Stop-Limit migration defines related ALTERs, RPCs and grants; Market/Limit migration defines its three RPCs but not base table DDL. Current fixtures themselves define base financial tables and helper functions, so those fixture definitions are not authoritative Production schema sources.
- Remaining evidence gap: authoritative base DDL for profiles/orders/wallets/asset_balances/order_reservations, actual account/fee helper definitions, and complete trigger inventory. Continue recovering these from Git history or an authoritative schema snapshot; do not infer them from fixtures.
- Updated bootstrap plan: commit `c1854310dbe2506e1e0043a552839bdd513de108`, blob `97a5bc8c093d7b31d1c12309ee66ad516b9ae760`.
- Updated financial audit: commit `d3180ab2c588a786cfac5e2d6ea9018b6895ff3c`, blob `1204e6dabca3c59ca76e73a0cd008338f83bc791`.
- No test/workflow/migration/PR branch changes, no Production query/write, no Supabase mutation, no merge/rebase/deploy, no `supabase db push`.
- Next: continue source recovery through historical commits/tree and existing schema snapshots, then build only if schema/helper/trigger parity is provable.


## 2026-11-21 — encrypted database backup located; source recovery boundary
- Located and downloaded still-valid GitHub Actions artifact from run `43848835281`: `DigiArz-database-backup`, artifact ID `14217201032`, GitHub-reported archive SHA-256 `555c1f7ebcad947e573dad659084bbcf94dc88d55fc0bc1a3b7de9606db8e4e5`; expiry `2026-11-23T10:26:46Z`.
- ZIP inspection shows `README-backup.txt` plus `digiarz-database.dump.enc`. README describes PostgreSQL 17.12 custom dump of public/private schemas, encrypted AES-256-CBC + PBKDF2; includes private queue table structures and selected private admin/audit/control data. It reports archive integrity and pg_restore list checks but not a live restore drill.
- Decryption key is not available in this working context. No decryption/restore was attempted; no key was requested, exposed, or written to repository/logs. Do not ask the user to paste secrets into chat.
- Prior archive review found no `supabase_migrations.schema_migrations` ledger in the artifact, so even a restored schema snapshot would not establish applied migration history.
- Updated bootstrap plan: commit `a883effeb2ed3e425e9576ffa2907b7fa4a4f104`, blob `ecf0cee9a97d55bda008ca4dd4e913b42c22c773`.
- Updated financial audit: commit `34a7bf7a0aa581975d7e24a1153e2096b19b95e8`, blob `4a65139a09bdfe95137a554124e2cef071c1bd0f`.
- No workflow/secrets changes, Supabase/Production access, schema/RPC/trigger/cron/data mutation, PR branch edit, merge/rebase/deploy, or `supabase db push`.
- Next: use a secure already-authorized environment that can consume the encryption secret without logging it, or request an approved schema-only export. Do not expose the key in chat/repository.


## 2026-11-21 — recovery schema metadata and Production read-timeout checkpoint
- Reconfirmed main HEAD before this update: c868ffe3349ee25abbc74499169db355e7b4fc3e. Recent main commits since the prior checkpoint are documentation-only source-recovery, backup, and PR #38 evidence notes; no application code or migration was changed.
- Recovery project DigiArz-Recovery-Test (zrriqwyolcjhbappocuw) is ACTIVE_HEALTHY on PostgreSQL 17.11.0.019; isolated restore run 44298621534 is success. Read-only catalog inventory: 32 tables, 239 columns, 116 constraints, 63 indexes, 5 non-system triggers, 21 policies. Core account-guard triggers on orders/trades/transactions and helper function definitions were identified.
- Important limitation: recovery-drill.yml restores with --no-owner --no-acl. Recovery project ACLs are not source-of-truth; use migrations and live Production catalog for grants. The recovery project contains restored data; only schema metadata was queried, no row contents were inspected or used for tests.
- Production remains ACTIVE_HEALTHY by project metadata, but direct read-only execute_sql and list_tables calls timed out; Security Advisor also timed out. Health Advisor returned no lints; Performance Advisor snapshot 2026-11-20T22:59:05Z reports 9 unindexed FKs, 11 RLS initplan warnings, 7 unused indexes. Logs over 2026-11-19 22:48:46Z–2026-11-20 22:48:46Z show 575 SSL resets, 93 EOF, 152 statement timeouts and startup-timeout events across multiple cron jobs.
- Live market schedules rechecked: job 13 */10, job 14 1-59/10, job 17 5-59/10. The current cron run-details query timed out, so no fresh 24-hour success/failure totals are claimed.
- PR #38 remains open Draft, head a6849671727fce10fe852bda607fd65b3fc2a351; its exact-decimal run 44811642137 succeeded, but the fixture remains a concurrency-primitive model, not full execution of the four production RPCs.
- Artifact 14217201032 remains unexpired at this check and expires 2026-11-23T10:26:46Z. GitHub API reports the exact 64-character digest sha256:555c1f7ebcad947e573dad659084bbcf94dc88d55fc0bc1a3b7de9606db8e4e5; earlier notes contained a truncated 61-character digest and have been corrected in the bootstrap plan.
- Bootstrap plan updated in commit 6ccfa3c68c47e00518508e930dc97428231c4019; it records schema metadata, ACL exclusion, Production parity blocker and next safe step.
- No Production migration/RPC/trigger/cron/grant/policy/schema/data change, no test with restored records, no merge/rebase/deploy, and no supabase db push.


## 2026-11-21 — registration form simplification
- User explicitly clarified that the first-name/last-name removal applies to the registration form.
- Created isolated branch `ui/remove-signup-name-fields-2026-11-21` from main `1c2ba0f9449d64cebc6d511f646fc8857dad1f89`; did not modify the APK biometric spike branch or main.
- Updated `index.html` in commit `10429774dd9115508141e1b11001e399a555a322`: removed the combined name input from the shared auth form and removed the `full_name` signup metadata payload. Registration now submits email and password only. Existing login, dashboard, profile/database columns, and existing users' stored metadata were not changed.
- Static exact-string verification in the edit step confirmed the signup form no longer contains `id="fullName"`, the signup handler no longer reads `$('fullName')`, and no longer submits `full_name:name`. No CI or browser/device test has yet been run for this change.
- Next: create a Draft PR targeting main, inspect its diff, and run available CI. Do not merge or deploy without explicit authorization.


## 2026-11-21 — registration form change merged
- User explicitly authorized merge after the final CI run succeeded.
- PR #42 was marked ready for review and squash-merged successfully: https://github.com/shahram-adim/DigiArz/pull/42.
- Merge commit on main: f8fda32c35a529f4719681a91fe800d056514db0. Verified PR state is closed/merged and main points to the same merge commit.
- Final pre-merge CI run 44881264590 completed SUCCESS on exact PR head 1c73251a991448e54b5f39d8e71b3eb499ef5c34: https://github.com/shahram-adim/DigiArz/actions/runs/44881264590.
- Application change: registration form no longer asks for first/last name and signup submits email/password only. Existing login, dashboard, stored account metadata, and database schema/data were not changed. Tests assert name field absence and email/password-only signup.
- No production database migration, schema/data update, release, or deployment was performed. No physical-device test has been performed. The separate APK-only biometric PR #41 remains separate and unaffected.
- Next: verify the hosted/PWA registration form after the normal deployment pipeline when deployment is separately authorized; do not deploy automatically.

 
## 2026-11-21 — combined Indigo Glass + APK-only biometric candidate
- Rechecked ancestry using GitHub compare: PR #41 biometric branch is **47 commits ahead and 2 commits behind** current main (not 47 commits behind). The two main-only commits include PR #42's already-merged removal of registration name fields and its handoff record.
- To avoid importing unrelated branch history, created build/indigo-glass-biometric-apk-2026-11-21 directly from current main and ported only the reviewed biometric implementation files from PR #41, plus the exact Indigo Glass index.html and regression tests from PR #44's visual branch.
- Preflight verified the APK injection script's three source anchors each match exactly once: decimal.js script anchor, forgot-password button anchor, and existing initClient implementation. Signup name field remains absent; email/password registration and all existing login controls remain present.
- APK build injects biometric adapter and unlock button into generated www assets only. Source index.html does not load the biometric plugin; hosted web/PWA authentication remains unchanged.
- Combined Android workflow uses Capacitor 8.6.2, native biometric plugin 8.9.3, strong-biometric protected session storage, cancellation/retry, password fallback, logout deletion and background/foreground relock. The workflow has read-only repository permissions, uploads DigiArz-Indigo-Glass-Biometric-APK, and contains no GitHub Release or publishing step.
- No main merge, Production deployment, Supabase/database change, release, or physical-device test performed. Await CI and artifact verification.

- CI validation for combined PR #45: Exact decimal workflow run 44894527842 completed **SUCCESS** on branch head 822938e5f10c626077d3d48122821c83a07f8ef4. The UI/browser regression tests passed, as did PostgreSQL arithmetic, type-widening/atomicity, Market/Limit, Stop-Limit, TP-SL lifecycle and two-session concurrency/race tests.
- PR #45 remains Draft/open/unmerged and mergeable; current main remains unchanged. The APK workflow is prepared with workflow_dispatch and a branch-specific build trigger, but no combined APK artifact has yet been verified. To build it, manually run the Android workflow on branch build/indigo-glass-biometric-apk-2026-11-21; it uploads the review artifact only and cannot publish a GitHub Release.
- The prior PR #41 APK build is not the combined visual version and must not be presented as the final APK. Physical-device biometric acceptance testing remains outstanding.
