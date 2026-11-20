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
- GitHub Actions run `44779426017` was created for commit `3b57ad647390669e1708a8ba19a1b95b079f1df6`; at last inspection its PostgreSQL job was still initializing, so no pass is claimed.
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
