# Market-price bulk-upsert optimization — experimental plan

**Status:** design-only draft; no production SQL changes.

## Objective

Reduce the runtime and database write overhead of `public.refresh_market_prices()` without changing the one-minute schedule, market symbols, provider behavior, prices, or any trading workflow.

## Confirmed production facts (read-only observations, 2026-11-20)

- The live function has CoinGecko, KuCoin, and Gate.io paths.
- The primary CoinGecko request is capped at 515 IDs.
- CoinGecko price writes currently occur inside a PL/pgSQL loop, with an individual `INSERT ... ON CONFLICT` per mapped symbol.
- Recent observations recorded approximately 43.7 seconds average and 98.5 seconds maximum runtime.
- Inventory snapshot: 398 enabled demo pairs, 891 curated listings, 3 queued requests, and 0 requests older than two minutes.
- A bounded duplicate-mapping query over enabled demo pairs and active curated listings returned no symbols mapped to more than one distinct CoinGecko ID at the time of the check. This is a point-in-time observation, not a permanent uniqueness guarantee.
- A fresh attempt to capture the full live function definition timed out. Therefore no replacement function body is authored in this draft.

## Proposed implementation shape — subject to source-equivalence review

1. Capture the exact current production function definition and identify every query, ordering rule, provider precedence rule, conflict target, and queue state transition.
2. Build normalized provider result sets in temporary/CTE relations, validating numeric values before writes.
3. Resolve duplicate target symbols deterministically before each upsert. Never feed multiple source rows for the same conflict key to one `INSERT ... ON CONFLICT DO UPDATE` statement.
4. Keep CoinGecko, KuCoin, and Gate.io source selection and fallback semantics byte-for-byte equivalent in behavior.
5. Keep the CoinGecko 515-ID cap, existing HTTP URLs/timeouts, advisory lock, retry behavior, queue cleanup, permissions, price precision, and transaction boundaries.
6. Compare resulting rows and queue state against the current function using deterministic fixtures before considering any migration.

## Required regression coverage

- CoinGecko primary request with 515 IDs and paging/fallback behavior.
- KuCoin and Gate.io parsing, symbol normalization, and provider precedence.
- Duplicate symbols and multiple upstream IDs targeting one symbol; deterministic winner or explicit rejection.
- Missing, null, malformed, zero, negative, and valid positive prices.
- Enabled trading pairs versus inactive/curated assets.
- Existing conflict behavior, source labels, timestamps, and numeric precision.
- Queue success, pending response, timeout, retry, and cleanup behavior.
- Advisory lock prevents concurrent overlapping refreshes.
- No changes to orders, fills, wallets, balances, reservations, or demo-trading logic.

## Verification and release gates

- Disposable PostgreSQL 17 regression fixture must pass.
- Full-function equivalence review against captured production definition.
- Representative before/after latency, buffer, and WAL measurements in an isolated environment.
- Review migration history drift before creating or applying a migration.
- Keep this PR Draft until every gate passes.

## Explicit safety constraints

- Do not run `supabase db push`; migration reconciliation is unresolved and local-only historical migrations may replace the live function with a version missing the 515-ID cap.
- Do not modify the Production function, indexes, cron jobs, market data, order/trade data, wallets, or balances during this investigation.
- Do not alter the one-minute refresh cadence or order-processing schedules.
- No merge or deployment without a separate explicit approval.


## Isolated PostgreSQL 17 contract fixture — 2026-11-20

- Added `supabase/tests/market_price_bulk_upsert_contract.sql` to prove PostgreSQL's duplicate-conflict-key cardinality failure, statement atomicity, explicit caller-ranked deduplication, and rejection of NULL, zero, negative, NaN, and positive Infinity prices.
- Added `.github/workflows/market-price-bulk-upsert-tests.yml` to run the fixture against disposable PostgreSQL 17 on PR/push.
- This fixture tests PostgreSQL mechanics only. It does not establish live CoinGecko/KuCoin/Gate.io precedence or equivalence with `public.refresh_market_prices()`.
- The branch remains isolated and Draft. No Production database, migration, cron, price, order, trade, wallet, or balance was changed. One-minute cadence remains untouched.
- Next: confirm this fixture CI result, then obtain the exact live function definition through a reliable read-only route before defining provider-specific ranking or writing replacement SQL.

- CI confirmation update: workflow run `44779426017` completed with conclusion `success` on PostgreSQL 17.12; the isolated contract-fixture step passed. This confirms only the fixture's PostgreSQL mechanics, not live provider precedence or production-function equivalence.


### Follow-up verification — 2026-11-20
- The isolated PostgreSQL 17 contract workflow `44779426017` completed successfully.
- The full existing exact-decimal workflow `44779548999` completed successfully on code commit `7a895b4e0c46080813ec9c7958348de13960ad59`; all substantive test steps passed, including two-session Limit cancellation, TP-SL conditional execution/cancellation, Stop-Limit child execution/cancellation, and lifecycle integration. The branch head subsequently advanced to `74f2b3d188ae4d5d870766639c050090e0369a0a` for documentation only.
- Read-only Supabase unified logs for 16:55–17:05 UTC show six occurrences each of startup timeouts for cron jobs 2, 3, 8, 9, and 12; two observed `refresh_market_prices()` executions took 46.952 s and 50.744 s. A separate statement-timeout event was also logged. These observations are consistent with the previously reported resource/startup pressure; they do not identify a single root cause.
- Project status reports `ACTIVE_HEALTHY`, PostgreSQL 17.11.0.018. However, repeated cron startup timeouts and long market refresh duration mean the live database is not a safe target for further catalog/function-definition reads right now. Do not retry the timed-out function-definition SQL while this pressure persists.
- Next gate: wait for database/log stability, then capture the exact live `public.refresh_market_prices()` definition through a read-only path before authoring any provider-ranking or replacement SQL. No Production changes, cron changes, migration changes, or cadence changes were made. PR #35 remains Draft.


### Current branch and stability check — 2026-11-20 17:08 UTC
- GitHub Actions run `44779548999` is completed/successful; its test suite passed on code commit `7a895b4e0c46080813ec9c7958348de13960ad59`. Run `44779426017` also passed the isolated PostgreSQL contract fixture. The earlier initializing-only note above is superseded by these confirmed results.
- The documentation-only branch head was `156f9ea5a37fd7510ec5d4dc4bf7cfbe55d15b7b`. Relative to current main `06a23cc9f6e45ba18dfa0c1d88785778e137da17`, compare reported diverged: 6 commits ahead and 2 behind, with merge base `8bbd3e228de3b342c1a07eb0ff18ec97c9d12353`. No rebase/merge performed.
- Latest retrieved production logs through 17:08:10 UTC still contain repeated startup timeouts for jobs 2, 3, 8, 9, 11, and 12. The market refresh was starting at 17:08:02; no completion duration for that invocation is present in the retrieved slice. A postgres_exporter statement-timeout remains present at 17:06:52.
- Because the startup-timeout pattern persists, do not retry heavyweight catalog/function-definition reads. No live changes or schedule changes. PR #35 stays Draft.


### Static source review from repository migrations — 2026-11-20
- Read the repository's 515-ID migration `20261116203709_limit_primary_coingecko_batch_to_515_ids.sql` and the preceding KuCoin/Gate.io migrations. This is repository migration source, not proof of the exact currently deployed function body.
- The source confirms: advisory transaction lock `(742019, 13)`; queued HTTP response processing; provider-specific CoinGecko, KuCoin, and Gate.io branches; CoinGecko ID aggregation ordered and capped at 515; request timeouts 20s/15s/15s; 10-minute queue cleanup; and execution restricted to postgres.
- Critical duplicate-key observation: the CoinGecko mapping uses `UNION` across `(symbol, coingecko_id)`, so it deduplicates identical pairs, not necessarily symbols. Two different CoinGecko IDs can still target one `market_prices.symbol` key.
- Neither the queued-response loop nor the CoinGecko mapping loop specifies a deterministic `ORDER BY`. Therefore, a set-based bulk statement must not invent a provider or duplicate-symbol winner. A deterministic winner policy would change potentially observable behavior unless the live function and expected semantics establish it.
- Static source review is sufficient to refine the test plan, but not to authorize a replacement. Exact live definition capture and runtime duplicate semantics remain blocked by Production startup timeouts. No SQL implementation or Production change was made.


### Latest recheck — 2026-11-20 17:10 UTC
- GitHub confirms PR #35 remains open and Draft, with head `8106042185f021b8183d9a4dd6b1511366d1e9f2`. Current `main` is `06a23cc9f6e45ba18dfa0c1d88785778e137da17`.
- Fresh compare reports the branch is diverged: 8 commits ahead and 2 behind, merge base `8bbd3e228de3b342c1a07eb0ff18ec97c9d12353`. The compare lists only the three intended files: the isolated PostgreSQL 17 workflow, its contract fixture, and this design/verification plan. No rebase or merge was performed.
- Supabase project status is `ACTIVE_HEALTHY`, PostgreSQL 17.11.0.018. However, unified Postgres logs retrieved through 17:10:12 UTC continue to show repeated `job startup timeout` events. At 17:10:11–17:10:12 UTC, timeouts were logged for cron jobs 2, 3, 8, 9, 12, and 13; at 17:09:14 UTC, timeouts also included job 18. The same log slice shows scheduled work starting again at 17:10:00–17:10:02 UTC, including `refresh_market_prices()` and the order processors. These logs establish continued startup failures, not the underlying root cause or whether every invocation failed.
- The Production database remains an unsafe target for heavy catalog/function-definition reads while these startup timeouts persist. Do not retry the timed-out function capture yet. Continue offline/isolated fixture analysis only.
- No Production SQL, migrations, cron schedules, market data, orders, trades, wallets, or balances were changed. One-minute market/order cadence remains unchanged; PR #35 remains Draft.


### Cross-provider duplicate-symbol contract — 2026-11-20
- Extended the disposable PostgreSQL 17 fixture with a single target symbol receiving four candidate rows: two distinct CoinGecko upstream IDs, one KuCoin row, and one Gate.io row.
- The fixture verifies that passing all four rows directly into one INSERT ... ON CONFLICT DO UPDATE raises PostgreSQL cardinality_violation and leaves the target table unchanged.
- The test deliberately does not choose a winning provider or claim any production precedence. It proves only that duplicate target keys must be resolved before a single bulk upsert; the correct resolution policy still depends on exact live-function semantics.
- This is an isolated SQL fixture change only. No live function, market price, cron schedule, order, wallet, or balance was touched. One-minute cadence remains unchanged.


### CI and Production recheck — 2026-11-20 17:13 UTC
- The latest PostgreSQL 17 cross-provider contract run `44781021310` on branch commit `c6bdc2edff9e48351aa1a1fae1046496295c21fc` completed successfully. It includes the four-candidate same-symbol scenario (two CoinGecko IDs, KuCoin, Gate.io), checks the expected `cardinality_violation`, and verifies no partial target write remains.
- The exact-decimal workflow `44781021461` on the same commit was still in progress at the time of this check; do not report the full test matrix as complete until it finishes.
- Supabase remains `ACTIVE_HEALTHY` on PostgreSQL 17.11.0.018, but bounded unified Postgres logs for 17:10–17:12 UTC still show repeated pg_cron `job startup timeout` events for jobs 2, 3, 8, 9, 12, and 16. The logs also show later job-start messages, so the timeouts alone do not prove every invocation failed. Root cause is not established.
- Because startup timeouts persist, exact live-function capture remains blocked. No further heavy catalog query was attempted. No Production SQL, migrations, cron schedules, market data, orders, trades, wallets, or balances were changed. One-minute market/order cadence remains unchanged; PR #35 remains Draft.



### Follow-up source comparison — 2026-11-20 (repository-only, no Production read)
- Re-read the current repository's 515-ID migration plus the two historical provider migrations. These files provide source-history evidence only; they do not prove the exact deployed function body.
- The historical KuCoin migration processes only HTTP 200, non-timeout responses with non-null content, requires response code `200000`, normalizes `-` from symbols, accepts enabled USDT pairs, and upserts source `KuCoin`. The Gate.io version requires a JSON array, normalizes `_`, accepts enabled USDT pairs, and upserts source `Gate.io`.
- The later 515-ID function source retains both exchange-provider paths and the same per-row upsert approach. It uses an advisory transaction lock, consumes queued responses with an unordered SELECT, deletes each processed request, removes requests older than 10 minutes, and schedules new CoinGecko/KuCoin/Gate.io HTTP requests with 20s/15s/15s timeouts. The CoinGecko request IDs are aggregated in sorted order and capped at 515.
- Important semantic boundary: the response queue loop has no ORDER BY, the CoinGecko symbol-to-ID mapping loop has no ORDER BY, and the KuCoin/Gate.io ticker loops have no ORDER BY. The current source therefore does not declare a deterministic last-writer precedence across responses/providers or duplicate rows within one provider. A bulk rewrite that adds a provider rank or stable tie-breaker would define new behavior, not merely optimize the same behavior.
- Safer candidate design to investigate only after exact Production source capture: batch each response/provider separately, preserving the existing response-processing transaction and provider-specific filters; separately detect and report duplicate target symbols within a single provider result. Do not combine all providers into one upsert and do not silently invent precedence. Even separate per-provider batching requires a documented policy for duplicate symbols inside CoinGecko mappings, because one multi-row ON CONFLICT statement rejects repeated target keys.
- The current PostgreSQL 17 fixture proves duplicate-key cardinality failure and caller-ranked deduplication mechanics. It does not yet test provider parsing, response ordering, malformed JSON/numeric casts, per-response exception behavior, or exact source-label/timestamp equivalence. These are explicit gaps, not assumed successes.
- Rechecked PR #35: open Draft; its three changed files remain limited to the contract workflow, SQL fixture, and design document. The branch is diverged from main (12 commits ahead / 11 behind; merge base `8bbd3e228de3b342c1a07eb0ff18ec97c9d12353`). Do not rebase/merge until controlled reconciliation.
- Latest PR-head checks observed: PostgreSQL 17 contract run `44781193805` and exact-decimal run `44781193616` both completed successfully on head `d5cc28cba91624a618f438a058521d44a37be88f`. The green contract remains a mechanics test, not production equivalence.
- No Production query was retried, and no database, cron, function, migration, market-price, order, trade, wallet, or balance state was changed. Keep the one-minute market-price cadence unchanged and PR #35 Draft.



### Exception-boundary and queue-semantics review — 2026-11-20
- Further static review of the current repository migration identifies an important behavior that the existing fixture does not cover: all provider-specific row loops for one queued response execute inside a single PL/pgSQL `BEGIN ... EXCEPTION WHEN OTHERS` block.
- If a ticker's numeric text is malformed (for example, a non-empty non-numeric `last` value), the cast raises an exception. PostgreSQL rolls back database writes performed earlier inside that exception block for the same response; the function emits a warning, exits that response's provider-processing block, then proceeds to delete that response's queue row outside the block. Thus a malformed later ticker can cause earlier valid ticker writes from that same response to be rolled back, while other queued responses can still be processed.
- A set-based rewrite must deliberately preserve or explicitly revise this response-level atomicity and queue deletion behavior. Silently filtering malformed rows and retaining earlier writes would change current behavior; moving queue deletion into/out of a different exception scope could change retry/loss behavior.
- Existing fixture gaps now explicitly include: (a) valid ticker followed by malformed numeric within one response, verifying response-level rollback; (b) queue-row deletion after caught processing exception; (c) separate response continues after one response fails; (d) malformed JSON shape and missing keys; (e) provider-specific status/code gates; (f) source/timestamp updates only for accepted positive prices.
- No live function capture or Production query was attempted. These conclusions are based on the repository migration source only and must be checked against the exact deployed function before any implementation.
- PR #35 remains open Draft and contains only the test workflow, isolated contract fixture, and design document. It remains 13 commits ahead / 11 behind main, with only those three files in the compare. No rebase, merge, deployment, Production DB change, cron change, or cadence change was made.

### Response exception, queue, and provider-gate fixtures — 2026-11-20

- Extended the disposable PostgreSQL 17 contract fixture to model the repository migration's per-response PL/pgSQL exception boundary.
- Verifies that a valid write earlier in a response is rolled back when a later non-empty malformed numeric value raises; the response queue row is then deleted outside the caught exception block.
- Verifies that a later independent queued response still processes after an earlier response fails, and that both processed queue rows are removed.
- Adds isolated acceptance-gate checks for non-200 HTTP status, timed-out response, missing content, KuCoin non-success provider code, and a Gate.io payload with the wrong top-level JSON shape.
- Adds source/price/timestamp assertions: a rejected non-positive price leaves the previous row unchanged, while an accepted positive price updates price, source, and timestamp.
- These are behavioral fixtures based on repository migration semantics, not proof that the exact deployed Production function is byte-for-byte equivalent. The live function capture remains blocked by database instability. No Production SQL, migration, cron, market data, order, wallet, or balance was changed; one-minute cadence remains unchanged.
- Next: inspect the PostgreSQL 17 workflow result for this commit and review any failure output before expanding provider parsing coverage.

- Follow-up coverage: malformed JSON text is caught inside the response boundary, and missing provider keys produce no target price write. These remain isolated payload-contract tests, not a substitute for exact deployed-function equivalence.


### Numeric special-value compatibility finding — 2026-11-20
- Repository schema history establishes `market_prices.price` as `numeric(38,18)`; the refresh migration's legacy acceptance predicate is only `v_price > 0`.
- PostgreSQL numeric semantics mean `NaN > 0` is true, and NaN can be stored in `numeric(38,18)`. By contrast, positive Infinity cannot fit a precision-constrained `numeric(38,18)` column and raises `numeric_value_out_of_range` during the target write. In the current per-response exception scope, that error rolls back earlier writes from the same response and the response queue row is then deleted outside the exception block.
- The existing bulk candidate fixture deliberately filters both NaN and Infinity. That is a stricter finite-positive policy, not exact legacy equivalence. Do not label it behavior-preserving until product requirements explicitly approve rejecting NaN, and the migration design documents the intended behavior change.
- Added a separate PostgreSQL 17 characterization block using the actual `numeric(38,18)` target typmod to assert the legacy NaN predicate/storage behavior and Infinity overflow behavior. This test distinguishes legacy characterization from the proposed stricter candidate filter.
- This is isolated fixture-only work. It does not query or change Production. The exact deployed function remains unverified, and repository migration source is not proof of the live body.


### Provider parser characterization — 2026-11-20
- Extended the disposable PostgreSQL 17 fixture to model the repository migration's KuCoin and Gate.io parsing paths: `symbol` hyphen removal, `currency_pair` underscore removal, uppercase USDT regex, enabled-pair membership, positive numeric value, empty-string-to-NULL behavior, KuCoin success code, and Gate.io top-level array gate.
- Added a duplicate KuCoin ticker for the same symbol and asserted sequential processing leaves the later ticker's price/source, matching the current row-by-row loop's observable last-write behavior for an ordered JSON array. A subsequent Gate.io response then overwrites that symbol in the separate response loop; this fixture does not define response queue order or cross-response precedence.
- This parser fixture is a direct model of repository migration predicates, not a call to external providers and not proof of exact deployed-function equivalence. CoinGecko duplicate mapping/order semantics remain unresolved; exact live-function capture remains a release gate.
