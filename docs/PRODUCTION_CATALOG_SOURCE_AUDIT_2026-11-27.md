# DigiArz — Production catalog writer and uniqueness audit
**Read-only source/schema audit — 2026-11-27**

## Scope and safety
This document records read-only inspection of the linked Production database schema and function definitions. No function was invoked. No table data, grants, policies, schedules, pairs, prices, balances, orders, workers, or infrastructure were changed.

## Recovered authoritative catalog writer
The exact applied definition of `public.refresh_crypto_assets()` was retrieved with `pg_get_functiondef`.

Observed behavior:
- `SECURITY DEFINER`, empty `search_path`; execution is granted to `service_role`, not `anon` or `authenticated`.
- Acquires transaction advisory lock `(20261108, 500)`.
- Consumes queued CoinGecko market pages from `private.crypto_assets_sync_requests` and `net._http_response`.
- Inserts `crypto_assets` rows keyed by `coingecko_id`; on conflict it updates `symbol = UPPER(provider symbol)`, name, image, rank, price, volume, timestamps, and sets `is_active = TRUE`.
- It accepts any non-empty provider ID/symbol/name and positive numeric current price; the SQL does not apply the pair-format regex or ticker uniqueness before updating the catalog row.
- It does not itself provision a row in `demo_trading_pairs`.
- It marks page scan state and queues the next CoinGecko page; per-page failures are caught and scheduled for retry.

Implication: `crypto_assets.symbol` is mutable through the recurring catalog refresh path. Pair identity must therefore not be treated as a permanent derivation from an unchecked ticker string.

## Current schema constraints and indexes
Read-only catalog inspection found:
- `crypto_assets`: primary key on `coingecko_id`; no unique constraint/index on `symbol`. Existing symbol indexes are non-unique.
- `demo_trading_pairs`: primary key on `pair_symbol`; unique constraint on `base_coingecko_id`; foreign key to `crypto_assets(coingecko_id)`; quote constrained to `USDT`; pair format constrained to `^[A-Z0-9]{2,15}USDT$`.
- `admin_market_listings`: primary key on `coingecko_id`, FK to `crypto_assets`.
- A BEFORE INSERT/UPDATE trigger on `admin_market_listings` calls `private.enforce_unique_admin_market_listing_symbol()`.
- No trigger was returned for `crypto_assets` or `demo_trading_pairs` in the inspected trigger catalog.
- RLS is enabled on all four inspected tables: `crypto_assets`, `admin_market_listings`, `demo_trading_pairs`, and `market_prices`.

## Live data collision inventory
Read-only aggregate counts at inspection time:
- Active catalog assets: **19,012**.
- Active ticker groups with more than one asset ID: **2,365**.
- Active rows belonging to those duplicate-ticker groups: **6,662**.
- Enabled demo pairs: **420**.
- Enabled pairs without a matching `market_prices` row: **0**.

The duplicate inventory is a material blocker to automatically enabling every active catalog row by `UPPER(symbol) || 'USDT'`. A ticker alone is not a canonical asset identity. A large number of existing active catalog assets share tickers, so a bulk pair backfill or a unique active-symbol constraint cannot safely be added before a collision-resolution/admission policy exists.

## Additional activation-path findings
Definitions retrieved read-only show:
- `private.auto_activate_verified_exchange_pairs()` still requires curated listing, active asset, valid ticker, fresh CoinGecko price, metadata freshness, USD 1m volume, rank <= 2000 when present, recent matched exchange observation, and exactly one active catalog row for the ticker. It inserts pairs with `ON CONFLICT (pair_symbol) DO NOTHING`.
- `private.auto_list_verified_exchange_asset()` is an exchange-observation trigger function that inserts into `admin_market_listings` only when there is exactly one active catalog row for the ticker and the name/identity checks pass.
- `public.admin_enable_market_pair(text)` requires super-admin, curated listing, liquidity/rank gates, symbol validity, no pair-symbol collision, and positive CoinGecko price updated within two minutes. It uses a transaction advisory lock keyed by the CoinGecko ID.
- The current model therefore has multiple activation paths and product eligibility gates that are not yet unified.

## Consequences for the target design
1. Keep canonical provider asset ID as the primary identity; never infer identity from ticker alone.
2. Do not remove all ticker ambiguity checks. Owner intent means every admitted catalog asset is intended to be tradable, but ambiguous tickers must be resolved at catalog admission or assigned an explicitly supported alternative market symbol/quote. Do not silently select one asset.
3. Distinguish the broad discovery feed from the curated/tradable catalog. A raw provider-discovered row should not automatically become an admitted tradable asset before identity, supported market, price, and ticker mapping checks pass.
4. The current USDT-only financial model and pair constraints must be respected. A future asset with no valid USDT quote/price path cannot be marked tradable until a supported market route exists.
5. The existing active catalog contains substantial historical ambiguity. Before enabling more pairs, prepare a read-only reconciliation report identifying which duplicate IDs are already listed/paired, provider IDs, names, market observations, and any ticker migrations. Do not mutate or disable any existing row as part of this audit.
6. A safe implementation needs one canonical admission/provisioning path, transactional/idempotent behavior, collision-aware errors, and price-refresh coverage; then update all user RPCs and workers together. Preserve current financial authorization, reservation, fee, and ledger invariants.

## Next steps
- Finish writer inventory for `crypto_assets`, `admin_market_listings`, `demo_trading_pairs`, and `market_prices`, including all exchange sync functions, triggers, cron invokers, and table grants/policies.
- Produce a compact duplicate-ticker reconciliation dataset (not a write operation) and determine whether any valid collision-safe market-symbol mapping exists for each group.
- Verify price refresh coverage for all future provisioned pairs.
- Only then design disposable-PostgreSQL source-parity tests and a reviewed migration proposal.

## Explicit non-actions
No Production writes, pair activation/deactivation, migrations, db push, function execution, cron/worker changes, Edge Function changes, grants/RLS changes, merge, deployment, APK/Pages release, or paid infrastructure changes were performed or authorized.


## Follow-up reconciliation and price-freshness snapshot (read-only, 2026-11-27)
### Correct interpretation of same-ticker exchange matches
A deeper row-level inspection clarifies that some duplicate ticker groups contain distinct, legitimately matched assets rather than one incorrect match. For example, `DOT` has both:
- `polkadot` — name Polkadot, matched by AbanTether, Bit24, Kifpool, Nobitex, and Wallex.
- `dot` — name Dot, matched by Exir and Tabdeal.

This is not evidence that the `dot` record is Polkadot; it demonstrates why ticker-only joins are unsafe and why provider ID plus exchange name/market evidence must be retained. Some other same-ticker groups include unrelated provider assets (e.g. BTC has Bitcoin plus several unrelated tokens using BTC as ticker; PEPE has Pepe plus multiple unrelated assets). The matched observation set for each provider ID must be assessed independently.

### Collision-group prioritization
Corrected counts using independent correlated subqueries (avoiding row multiplication from joining listings, pairs, and observations together) show that the major already-enabled ticker groups include:
- SOL: 2 active IDs; 1 curated ID; 1 enabled pair.
- DOGE: 6 active IDs; 1 enabled pair.
- ETH: 3 active IDs; 1 enabled pair.
- BTC: 10 active IDs; 1 enabled pair.
- XRP: 3 active IDs; 1 enabled pair.
- ADA: 2 active IDs; 1 enabled pair.
- PEPE: 21 active IDs; no enabled pair in the inspected collision-group aggregate.
- DOT: 3 active IDs; no enabled pair in the inspected collision-group aggregate.
These values describe current live rows, not a recommendation to auto-enable any of them.

### Existing enabled-pair price freshness
Read-only aggregate over all 420 enabled pairs:
- 420 have a matching `market_prices` row and all 420 prices are positive.
- 415 are newer than two minutes; 5 are older than two minutes.
- 390 currently show source `Gate.io`, 14 `CoinGecko`, and 3 distinct sources overall.
- The five stale rows are NBISONUSDT, TSMONUSDT, RIVERUSDT, TQQQONUSDT, and TONUSDT. Their timestamps are 2026-11-19 22:56 UTC (approximately 7.7 days old at inspection time).
This confirms a pair-row existence check alone is not sufficient. Tradability must be gated on a live, positive, trusted, market-specific price with a strict freshness limit, and the price refresh process must demonstrably cover every provisioned pair.

### Current reconciliation status
The data now supports three distinct categories:
1. **Unambiguous provider identity with active exchange corroboration** — candidate for a canonical market mapping after verifying quote/price support.
2. **Duplicate ticker but distinct, individually corroborated assets** — cannot both use the same `BASEUSDT` pair key; requires a collision-safe symbol policy or explicit unsupported status until such a route exists.
3. **Duplicate ticker with weak/no corroboration, stale metadata, or no supported quote/price path** — must not be automatically provisioned simply because it exists in the broad provider catalog.

No rows were modified and no prices were refreshed by this audit.


## Price-refresh pipeline source audit (read-only, 2026-11-27)
### Scheduled entrypoints
- Cron job 3 `digiarz-market-price-refresh` is active every minute and invokes `public.refresh_market_prices()`.
- Cron job 17 `digiarz-market-price-overflow` is active on minute 5,15,25,35,45,55 and invokes `private.request_market_price_overflow()`.
- Recent run history showed the sampled invocations succeeded; this does not prove that every provider returned complete market data or that every pair was updated.

### Primary refresh behavior
The exact applied `public.refresh_market_prices()` source was retrieved read-only:
- It processes queued HTTP responses for CoinGecko, KuCoin, and Gate.io.
- CoinGecko response handling loops enabled `demo_trading_pairs` plus active curated `admin_market_listings`, mapping provider IDs to pair symbols.
- KuCoin and Gate.io response handling only upserts symbols that match an enabled `demo_trading_pairs.pair_symbol`.
- It enqueues the first 515 sorted distinct provider IDs from enabled pairs plus active curated listings to CoinGecko, and requests full KuCoin and Gate.io ticker feeds.
- It uses an advisory transaction lock and avoids enqueuing a new provider batch while tracked requests or provider queue entries remain.
- The CoinGecko processing branch writes the returned USD value to `market_prices` under the mapped pair symbol. Gate.io and KuCoin can overwrite the same symbol with their own last-trade value and source, so source precedence is effectively dependent on response processing order rather than a documented per-pair priority policy.

### Overflow behavior
The exact `private.request_market_price_overflow()` source was retrieved:
- It derives the same distinct ID set from enabled pairs plus active curated listings.
- It skips the first 515 IDs and queues remaining IDs in batches of 500.
- It inserts request IDs into `private.market_price_sync_requests`; the column default for provider is `CoinGecko`, so overflow requests inherit that provider.
- It checks outstanding request rows and CoinGecko HTTP queue entries before scheduling more work.

### Implications and open questions
1. The pipeline can cover more than 515 IDs through the overflow job, but the ID universe is still only enabled pairs plus active curated listings. If every admitted catalog asset is to be tradable, canonical admission must ensure a pair exists before relying on this pipeline to refresh its price.
2. The price pipeline does not refresh arbitrary unenabled catalog rows. This is appropriate only if discovery and admission are separate and the admission path creates the pair before the asset is presented as tradable.
3. Current source handling does not establish a deterministic trusted source priority for each pair: Gate.io/KuCoin can overwrite CoinGecko. A new eligibility check must validate the exact source policy and freshness expected for the pair, not just `price > 0`.
4. The five stale enabled rows all show CoinGecko as their last source and are more than seven days old. This audit did not establish why they were not refreshed. Need inspect provider response completeness, request/response history, source market coverage, and pair mapping without running refresh functions or modifying queues.
5. The overflow scheduler and primary refresh must remain untouched until separately approved; both are Production financial/market data jobs.

### Current queue snapshot
At inspection time, three tracked price requests existed (one each for CoinGecko, Gate.io, and KuCoin). This is a point-in-time in-flight snapshot only.


## Investigation of the five stale enabled prices (read-only, 2026-11-27)
### Response-level evidence
- The five stale pair rows all still have active `crypto_assets` records with positive `current_price_usd` and `last_updated` timestamps on 2026-11-27. Those catalog prices are refreshed by a separate market-page ingestion path and are not automatically copied into `market_prices` by the price refresh function.
- Recent `net._http_response` inventory (last 10 days) contained 1,283 responses, all HTTP 200, not timed out, with non-empty bodies. This only describes retained responses; it is not proof every provider symbol/asset was returned.
- At the latest CoinGecko simple-price response inspected (2026-11-27 15:39:03 UTC), none of the five exact provider IDs appeared as a JSON top-level key. An exact-key check avoids false positives from substring searches (for example, the word `river` can appear inside unrelated response text).
- The same exact-key check against the latest retained response containing the literal ID found no JSON key/value for River or Toncoin either. Three other IDs (the two Ondo tokenized stock IDs and Nebius Group tokenized) had no retained response whose body contained their exact ID at all.
- Therefore the evidence supports this immediate mechanism: the pair refresh loop does not write a price when the provider payload omits that exact CoinGecko ID; it intentionally skips the row because `v_price` is NULL. The separate `crypto_assets.current_price_usd` value being current does not fix this, because the two pipelines write different tables and the pair price function does not fall back to that field.
- This is not yet a definitive explanation of why CoinGecko omits those IDs. Possible causes (unsupported simple-price ID, provider listing/endpoint coverage, ID not in the requested batch, or pagination/overflow request mismatch) remain unproven because the historical request URL-to-response mapping is not retained after queue processing and the tracking rows are deleted.

### Safety conclusion
Do not copy `crypto_assets.current_price_usd` into `market_prices` as an ad-hoc fix and do not reactivate stale prices. A future design must explicitly validate whether the catalog page price is suitable for the executable USDT pair, or provide an independently trusted exchange quote with deterministic source policy and strict freshness. For these five pairs, the system should fail closed until a valid pair-level quote is available.

### Remaining read-only investigation
- Verify whether these IDs are present in the primary first-515 CoinGecko request universe or only in the overflow set.
- Inspect the overflow scheduler's exact ID set and the current request batching without invoking it.
- Determine whether Gate.io/KuCoin have exact market symbols for the tokenized assets and whether those quotes are currently excluded due to missing exchange listings.
- Consider adding durable request metadata (provider, requested IDs, batch number, response outcome) in a future migration proposal; do not change Production now.


## Primary-vs-overflow and exchange-market coverage check (read-only, 2026-11-27)
- Reconstructed the exact current ID universe used by the refresh/overflow functions: **898 distinct provider IDs** (enabled pair base IDs plus active curated listing IDs).
- The five stale assets rank 523, 629, 677, 773, and 789 in the sorted ID set. All five are in the overflow range (>515), not the primary batch.
- The latest retained Gate.io and KuCoin response bodies were checked for the exact enabled pair symbols. None of the five symbols (NBISONUSDT, TSMONUSDT, RIVERUSDT, TQQQONUSDT, TONUSDT) appeared in either response.
- This points to a specific coverage gap: all five stale pairs depend on the CoinGecko overflow request, but the latest CoinGecko response does not include their exact IDs, and neither exchange ticker feed supplies the exact pair symbol. The primary CoinGecko batch and exchange ticker feeds cannot refresh them under the current mapping rules.
- This does not yet prove whether the overflow request is failing to include them or CoinGecko is omitting them from its response. Historical request URLs/batch contents are not durably recorded, so the two cases cannot be separated from retained response bodies alone.
- Operational implication: all five rows have no currently observed executable market source in the inspected Gate.io/KuCoin ticker snapshots; a stale cached price must not be used to authorize demo trading. Pair admission needs a verified source/market route, not merely a catalog USD valuation.


## Overflow scheduler starvation analysis (read-only, 2026-11-27)
- Recovered exact `private.request_market_price_overflow()` body. It returns immediately when **any** `private.market_price_sync_requests` row exists, or when any CoinGecko simple-price request remains in `net.http_request_queue`. It only schedules overflow after both conditions are clear.
- The primary `public.refresh_market_prices()` job runs every minute and, after processing completed requests, enqueues a new CoinGecko request for the first 515 IDs in the same function invocation. Its Cron job is job 3, schedule `* * * * *`.
- The overflow job is job 17, schedule `5-59/10 * * * *` (at minute offsets 5,15,25,35,45,55). Its recent invocations returned successfully at those offsets, but the Cron run record only reports the SQL statement's successful execution, not the integer returned by the function.
- A live snapshot at 15:42 UTC showed one tracked CoinGecko request plus tracked KuCoin and Gate.io requests, and the CoinGecko response had exactly 515 top-level keys. No overflow requests were tracked at that instant.
- **Strong design-level starvation risk:** because the primary job is scheduled every minute and creates a new tracked CoinGecko request after processing the previous batch, the overflow job's "no tracked requests" precondition is likely never true at its 5-minute-offset schedule. The current schedule and guard create a race window that is not reliably available to the overflow job. This is consistent with the five stale assets all being beyond ordinal 515 and the primary response containing exactly 515 keys.
- This is a highly plausible root cause, not a fully proven execution trace: retained Cron rows do not expose the function's returned integer, and the current request metadata does not record batch identity/IDs. The strongest verification would be a test-only simulation/source-level regression that models primary job cadence + overflow guard; do not invoke the Production function to test it.
- A future design should remove the cross-job starvation dependency: use a durable cursor/batch state or a single scheduler that sequences primary and overflow batches after each response; record provider, batch ordinal, requested canonical IDs, response ID, returned-key count, omitted IDs, status, and retry state. Ensure back-pressure and retries are explicit and fair.
- Do not change the live Cron schedule, invoke the overflow function manually, or modify request queues without explicit approval.


## Migration-source parity check for Overflow scheduler (read-only, 2026-11-27)

A repository-level check was performed before writing a disposable PostgreSQL regression. It found an important source-parity blocker:

- The checked-in migration `20261115130430_fetch_coin_gecko_market_price_overflow_ids.sql` defines `private.request_market_price_overflow()` without the live Production early-return checks for outstanding rows in `private.market_price_sync_requests` and `net.http_request_queue` that were recovered from Production in the previous stage.
- That migration also schedules the function as `* * * * *` (every minute), while the read-only Production Cron snapshot recorded job 17 as `5-59/10 * * * *` (minute offsets 5,15,25,35,45,55).
- The migration file is therefore not an exact replay of the current Production function/schedule. Running it in disposable PostgreSQL would test a historical migration body, not the live guard/cadence that the starvation hypothesis depends on.
- The existing CI harness uses PostgreSQL 17 service containers and psql scripts, so the infrastructure to add a disposable regression exists. However, the exact Production function body and its actual schedule need to be preserved as a reviewed, provenance-labelled fixture before a test can honestly be called source-parity.
- A small abstract timing model could demonstrate that a permanent outstanding-request guard starves when a primary request is continuously re-enqueued, but it would not prove the live PL/pgSQL function follows that exact trace. No such synthetic test was added or labelled as Production-equivalent.

### Updated confidence and next evidence required
The starvation diagnosis remains a strong, evidence-consistent risk, not a proven execution trace. The next safe step is to capture the exact read-only Production function definition and Cron schedule into a clearly marked audit fixture (including retrieval timestamp and function fingerprint), compare it against the checked-in migration and current primary refresh body, then execute that captured definition only in disposable PostgreSQL with stubbed `net.http_get`/queue dependencies. The test should assert both the observed starvation interleaving and a candidate fair scheduler without invoking or modifying Production.

No Production function was invoked. No queue, Cron, pair, price, schema, grant, policy, worker, or user data was changed. No migration/db push, merge, deployment, release, or paid infrastructure action occurred.

## Catalog/pair writer inventory — repository evidence boundary (read-only, 2026-11-27)

- Repository search confirms the complete `refresh_crypto_assets()` body is not present in the searched checked-in migration history; the stale-request recovery migration only references it. Its applied Production body was recovered separately in the earlier read-only audit.
- The recovered Production catalog refresh is the confirmed application path that mutates `crypto_assets.symbol` from the provider response. The repository's exchange-sync migrations primarily upsert `exchange_asset_observations`; matcher/auto-list paths may write `admin_market_listings`, but those are not writers of `crypto_assets.symbol`.
- The current migration source for Overflow is not equivalent to Production as described above; do not use migration history alone as the canonical source for either its guard or Cron schedule.
- Search results include catalog reads and exchange-observation writes that mention `crypto_assets`; a text search hit is not evidence that the referenced function writes the catalog table. Remaining writer enumeration must distinguish SQL read references from actual INSERT/UPDATE/DELETE targets and include privileged direct SQL outside repository-controlled functions as an explicit unknown.
- No complete database-wide write-path guarantee is claimed. In particular, no unique active-symbol invariant exists on `crypto_assets`, and the existing curated-list trigger does not make ticker uniqueness permanent when the provider refresh mutates a catalog symbol.


## PostgreSQL 17 harness and migration-source qualification (read-only, 2026-11-27)

- Inspected the repository's actual CI workflow `.github/workflows/exact-decimal-tests.yml`: it provisions a disposable PostgreSQL 17 service and executes SQL regression fixtures with `psql -v ON_ERROR_STOP=1`. Existing source-parity tests also compare captured Production function snapshots with candidate/migration bodies and pin a normalized function fingerprint.
- Confirmed the repository has no npm test script in `package.json`; Node tests are invoked directly by CI as `node --test tests/*.test.js`. This matters when adding a focused regression: it must be wired into the existing workflow or discovered test glob, not assumed to run through `npm test`.
- Re-read the checked-in Overflow migration. Its function has only the advisory transaction lock; it does not contain the live Production outstanding-request checks. Its migration-time Cron schedule is `* * * * *`, whereas the previously recovered Production job 17 schedule is `5-59/10 * * * *`. The two sources are materially different in both executable guard and cadence.
- This confirms that the migration is historical evidence only, not a valid source-parity fixture. A trustworthy regression needs the exact `pg_get_functiondef` output and Cron row captured from the read-only Production inspection, labelled with retrieval timestamp, function fingerprint, job name/schedule/command, and the dependencies it assumes. The candidate scheduler must be a separate fixture so the test cannot accidentally assert candidate behavior as current Production behavior.
- The current CI architecture is sufficient for a PostgreSQL 17 isolated test. The next implementation step is to add provenance-labelled captured-source fixtures and stubs for `net.http_get`, `net.http_request_queue`, and `private.market_price_sync_requests`; then test the live guard interleaving and a fair candidate scheduler independently. No external HTTP call is needed or allowed in this regression.
- The exact Production function text and fingerprint from the earlier read-only inspection must be re-fetched before creating the fixture; the checked-in migration must not be used as a substitute. Historical batch IDs are not retained, so even a faithful deterministic test proves the starvation mechanism under the observed guard/cadence, not the exact historical cause of each of the five stale rows.

No test fixture, SQL migration, workflow, or executable source was changed in this audit step. No Production function was invoked; no queue, Cron, pair, price, schema, grant, policy, worker, or user data was changed. No db push, merge, deployment, release, or paid infrastructure action occurred.


## Exact Production source capture completed (read-only, 2026-11-27)
- Re-fetched `private.request_market_price_overflow()` from Production via `pg_get_functiondef`; exact definition MD5: `e6ed136175b0d340c9a86e51f7917a76`. Confirmed its two early-return guards: advisory lock (742019,14), and return when either any tracked request exists or any CoinGecko simple-price URL remains in `net.http_request_queue`.
- Re-fetched `public.refresh_market_prices()`; exact definition MD5: `3788666d57957a66bf59031f54ceff03`. It has its own advisory lock (742019,13), processes responses and deletes their tracking rows, then applies back-pressure if any provider queue/tracked request remains before enqueuing the next primary 515 CoinGecko IDs and KuCoin/Gate.io full ticker feeds.
- Re-read live Cron rows: job 3 active, `* * * * *`, command `SELECT public.refresh_market_prices();`; job 17 active, `5-59/10 * * * *`, command `SELECT private.request_market_price_overflow();`.
- Preserved both exact function definitions, their fingerprints, Cron metadata, retrieval date, and interpretation limits in `docs/fixtures/PRODUCTION_MARKET_PRICE_FUNCTIONS_2026-11-27.md`. This is evidence-only documentation, explicitly not a migration. Commit: `c8f3b8cf99966fea65cf3e87f65924f89df50388`.
- Important refinement: the primary refresh function itself has a back-pressure guard after processing old responses; the starvation hypothesis must model the precise order: primary refresh processes a response and may enqueue a new primary request only when all queues/tracking are empty; overflow then checks those same outstanding structures at its scheduled offsets. Do not simplify this into an assertion that the primary always blindly enqueues every minute.
- The captured source now makes a faithful disposable PostgreSQL regression possible. It still cannot prove which historical batch omitted each stale asset because requested-ID history was not durably stored.
- All Supabase reads were SELECT-only. No Production function was invoked; no queues, prices, pairs, Cron, schema, grants, RLS, workers, orders, balances, or user data were changed. No migration/db push, merge, deploy, release, or paid infrastructure action occurred.


## Production writer inventory — SQL functions, triggers, grants, policies and active Edge Functions (read-only, 2026-11-27)

### SQL function bodies referencing the four catalog/market tables

- A live `pg_proc`/`prosrc` inventory found these direct SQL mutation targets:
  - `public.refresh_crypto_assets()` — INSERT/UPSERT into `crypto_assets`; the previously captured exact body updates canonical provider ID rows and may change `symbol`.
  - `public.refresh_crypto_assets_toman()` — UPDATE of `crypto_assets.price_toman` only; does not change symbol or canonical ID.
  - `private.auto_list_verified_exchange_asset()` — INSERT into `admin_market_listings`, triggered by matched active `exchange_asset_observations`.
  - `public.admin_add_market_listing(text)` — INSERT into `admin_market_listings`.
  - `public.admin_remove_market_listing(text)` — DELETE from `admin_market_listings`.
  - `public.admin_enable_market_pair(text)` and `private.auto_activate_verified_exchange_pairs()` — INSERT into `demo_trading_pairs`.
  - `public.admin_disable_market_pair(text,text)` — UPDATE of `demo_trading_pairs` and related open orders/reservations as part of the disable workflow.
  - `public.refresh_market_prices()` — INSERT/UPSERT into `market_prices`.
- Other functions in the reference inventory read these tables or process exchange observations / financial records; a textual reference alone was not classified as a table writer. The SQL inventory is based on current `pg_proc.prosrc`, so dynamic SQL or direct statements issued by external service-role clients remain a separate evidence boundary.

### Trigger and constraint observations

- `admin_market_listings` has BEFORE INSERT OR UPDATE OF `coingecko_id` trigger `admin_market_listing_unique_ticker`, invoking `private.enforce_unique_admin_market_listing_symbol()`.
- `exchange_asset_observations` has AFTER INSERT OR UPDATE OF `match_status, coingecko_id, is_active` trigger `trg_auto_list_verified_exchange_asset`, invoking `private.auto_list_verified_exchange_asset()`.
- No non-internal trigger was returned for `crypto_assets`, `demo_trading_pairs`, or `market_prices` in the inspected Production catalog.
- Consequence: the curated-list trigger does not protect a ticker change made directly on `crypto_assets` after the asset is already listed or paired. The exact active Edge Function `admin-refresh-crypto-asset` (version 2; source SHA-256 `46615bb47902709c8a46de777ffd300be23eff9f39de98f49648f952653e2512`) updates `crypto_assets.symbol` through a service-role client after checking format, but its source does not perform a global duplicate-ticker check or atomically reconcile an existing pair symbol. This is a material canonical-identity/pair-integrity gap to close before implementing auto-provisioning; no function was invoked or changed.

### Table grants and RLS policies

- `anon` and `authenticated` have SELECT only on `crypto_assets`, `admin_market_listings`, `demo_trading_pairs`, and `market_prices`; no direct INSERT/UPDATE/DELETE grants were returned for those roles.
- `service_role` has broad table privileges (including INSERT/UPDATE/DELETE) on all four tables; `postgres` has owner-level privileges. Therefore SQL function inventory alone cannot prove all writes: every active service-role Edge Function and any external service-role client must be included in the review.
- RLS is enabled on all four tables. Policies are SELECT-only: public read on crypto assets, listings and pairs; market prices has separate anon and authenticated SELECT policies. No INSERT/UPDATE/DELETE policy was returned for anon/authenticated.

### Active Edge Function writer inventory

- `admin-refresh-crypto-asset` v2 writes `crypto_assets` via service-role `.update()`; this is the second catalog metadata/symbol writer beside `refresh_crypto_assets()`.
- `index-ts` v3 writes `market_prices` via service-role REST upsert for its hard-coded Binance symbol list; source SHA-256 `d33b150e0de08416627092fb5d7eecdcdcf21fb9ac87d5b5118f27e4480d3f86`.
- `refresh-market-prices` v5 writes `market_prices` via service-role upsert for a separate hard-coded 12-symbol list; source SHA-256 `0f234ec99750afff5f0561ab41d2d87a78f2e3a6856025f4f0a89254aabea0`.
- `sync-iran-exchange-assets` v7 writes only `exchange_asset_observations`, not the canonical asset or pair tables; source SHA-256 `5a05817feaf065bcf2f0a9134337107821dfeacfee4e7441ed01e9870fb698d6`.
- `refresh-toman-market-prices` v3 writes `market_toman_prices` and `market_toman_price_history`, not `market_prices` or `crypto_assets`.
- `market-data`, `market-ticker-stats`, and `app-assets` were inspected and did not show direct writes to the four catalog/market tables.
- No active `cron.job` row directly invokes the two hard-coded price Edge Functions; current PostgreSQL market price cron job 3 calls `public.refresh_market_prices()` every minute. External schedulers or direct authenticated secret invocations of active Edge Functions are not ruled out by the `cron.job` inventory.

### Design consequences

1. Catalog admission must be distinguished from metadata refresh. Both `refresh_crypto_assets()` and `admin-refresh-crypto-asset` can change provider metadata; symbol mutation must pass the same collision/reconciliation rule as pair provisioning or be rejected atomically.
2. Price scheduler/source precedence must account for two additional active Edge Function writers that can overwrite `market_prices` for a limited hard-coded symbol universe. They are not a substitute for full-catalog coverage and must be reconciled or explicitly excluded in a future approved design.
3. Service-role credentials are a privileged write boundary. A complete deployment inventory must cover all active Edge Functions and any external service-role callers; do not infer safety solely from anon/authenticated grants or SECURITY DEFINER RPC grants.
4. No table privileges, policies, triggers, Edge Functions, SQL functions, Cron jobs, or Production data were changed. All database operations in this inventory were SELECT-only; Edge Function source retrieval was read-only.
