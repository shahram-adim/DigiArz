# Iran Exchange Asset Matcher: Bounded Incremental Design

Status: design-only; no production SQL, schema change, cron change, or migration is included.

## Context

The current `public.process_iran_exchange_asset_sync()` performs response ingestion and then runs Kifpool exact matching, ordinary symbol/name candidate matching, and the unmatched fallback across the observation table. Log review on 2026-11-17 found statement timeouts in both the ingestion portion and the matching portion. The current matcher therefore has two separate cost centers; limiting only HTTP response ingestion would not address the repeated full-table matching work.

PR #8 contains a response-ID snapshot intended to prevent a READ COMMITTED queue race. Keep that correctness property. Do not rebase, merge, or rewrite PR #8 as part of this work: its branch has diverged from main.

## Goals

1. Match only observations whose match-relevant inputs changed during the normal sync path.
2. Bound the amount of work in each sync invocation.
3. Preserve all existing matching semantics, especially Kifpool CoinGecko-ID/name checks and verified aliases.
4. Ensure pending, ambiguous, and unmatched observations can be retried when the asset catalog changes.
5. Provide a low-frequency, bounded reconciliation path for already-matched observations when catalog attributes change.
6. Preserve response queue correctness and avoid marking a response processed unless its frozen response set has been handled safely.
7. Keep ingestion durable even if a separate matching batch later times out.

## Non-goals

- No production hotfix or direct database mutation.
- No change to market prices, user balances, orders, or trading logic.
- No automatic change to pg_cron schedules until workload and overlap behavior are tested.
- No weakening of Kifpool exact-ID or alias rules to improve speed.

## Proposed architecture

### A. Bounded response claiming and ingestion

- Retain PR #8's frozen response-ID set so responses arriving after the worker's snapshot cannot be accidentally marked processed by that worker.
- Add a deterministic maximum batch size and stable ordering to the claim/snapshot step.
- Define a concurrency-safe claim protocol before implementation (for example, a durable claimed state/lease or row locking with `SKIP LOCKED`). A plain `LIMIT` over unclaimed rows is not sufficient if concurrent workers can select the same rows.
- Define retry and lease-expiry behavior so a worker crash cannot strand requests.
- Preserve explicit handling of invalid JSON and non-200 HTTP responses.

### B. Incremental matching for changed observations

- The ingest stage must identify rows whose *match inputs* changed, not merely rows whose `last_seen_at` heartbeat changed.
- Match-input changes include at least exchange, market/base symbol, asset name, active state, and Kifpool `source_payload.nameId`; review any other fields consumed by the current matching SQL before coding.
- Do not treat every `ON CONFLICT DO UPDATE` row as dirty if the only change is `last_seen_at`. The current upsert refreshes that timestamp on every sync, so a naïve `RETURNING id` would still feed the entire active observation set into the matcher.
- Select and implement one concurrency-safe dirty-row mechanism after testing: conditional upsert plus separate heartbeat handling, a durable dirty queue/version, or a carefully designed input fingerprint. Document how concurrent upserts and matcher workers interact.
- Apply the existing Kifpool exact matcher and ordinary candidate matcher only to the selected dirty IDs. Keep the candidate-count rule that distinguishes unique matches from ambiguous matches.

### C. Bounded retry/backfill

- Retry `pending`, `ambiguous`, and `unmatched` records in small deterministic batches.
- Do not permanently exclude `unmatched`: a CoinGecko asset may be added or activated later.
- Avoid repeatedly selecting the same first page. Use a stable cursor or durable work-queue state, and define behavior when rows become dirty while a batch is running.
- A retry batch must be safe to run more than once (idempotent).

### D. Catalog-change reconciliation

A change to `crypto_assets.symbol`, `name`, `is_active`, or alias/legacy mapping data can invalidate previous decisions. Add a low-frequency bounded reconciliation mechanism for affected observations. Do not assume `last_seen_at` is a dirty marker; it is refreshed by normal exchange syncs.

A candidate design for testing (not yet implemented) is a durable catalog-change work queue. Each event should retain the asset ID plus the old and new normalized symbol/name and active state, or an alias-map key when that mapping changes. A bounded worker then walks observations in primary-key order using a persisted cursor and re-evaluates rows that could be affected by either the old or new catalog values. The cursor/event must remain resumable until the scan is complete; new events must not reset or starve older work. For symbol changes and deactivation, include observations that were previously matched to the changed asset, not only currently unmatched rows, so stale matches can be cleared. Alias changes must target Kifpool observations whose source ID/name can be affected. Reprocessing must remain idempotent and must not arbitrarily resolve ambiguous candidates.

Required synthetic tests before production design:
- insert/activate an asset and rematch a previously unmatched or pending observation;
- rename an asset and clear or update a stale previous match;
- deactivate an asset and ensure affected observations are no longer left matched to it;
- change a verified alias/legacy mapping and reconsider only the affected Kifpool observations;
- use more affected observations than one batch and prove cursor progress, restart recovery, and no starvation;
- interleave a new catalog event while a prior event is part-way through its scan.

### E. Transaction boundaries and failure isolation

Evaluate separating ingestion/response acknowledgement from matching so a matcher timeout does not roll back successfully ingested observations. If separate functions are introduced, explicitly review:
- SECURITY DEFINER ownership and empty `search_path`;
- EXECUTE grants and whether the functions are callable by PUBLIC/anon/authenticated;
- cron invocation permissions;
- atomicity of response acknowledgement versus ingestion;
- retry behavior after partial failure.

Do not introduce a public SECURITY DEFINER entry point merely to make cron calls work.

## Required compatibility invariants

- Preserve every verified Kifpool alias and exact-ID/name condition currently present in main and PR #8.
- Preserve exact symbol matching and candidate cardinality semantics.
- Never convert an ambiguous candidate set into an arbitrary single match.
- A stale match must be clearable if its source observation becomes inactive or the catalog no longer supports it.
- An unmatched record must be eligible for future rematching.
- Responses outside a worker's frozen/claimed set must remain available to a later worker.
- A failed batch must not silently acknowledge unprocessed responses.

## Test plan / acceptance criteria

1. **Golden equivalence:** run old and new matching logic against the same fixture; compare `coingecko_id` and `match_status` for every observation. Differences require explicit reviewed explanations.
2. **Kifpool regression:** cover exact CoinGecko ID, exact normalized name, every verified alias/legacy transition, wrong ID, wrong symbol, and duplicate candidate cases.
3. **Ordinary matcher:** cover unique, ambiguous, no candidate, inactive asset, and symbol collisions.
4. **Incremental behavior:** unchanged observations with only a newer `last_seen_at` are not rematched; changed match inputs are rematched.
5. **Backfill fairness:** with more rows than one batch, repeated runs eventually process every eligible row without starvation or duplicates.
6. **Catalog changes:** adding/activating/renaming an asset causes the relevant previously unmatched/pending observations to be reconsidered; deactivation or symbol changes invalidate stale matches safely.
7. **Concurrency:** two workers cannot claim/process the same response incorrectly; a response arriving after the snapshot is left for a later worker.
8. **Failure recovery:** simulate timeout/crash after ingestion, during matching, and before acknowledgement; verify no lost response and no permanently stuck lease.
9. **Load test:** use realistic observation/catalog cardinalities and record rows scanned, rows matched, elapsed time, buffers, and lock waits. Set explicit upper bounds for each batch.
10. **Security and deployment:** inspect function owner, SECURITY DEFINER, search_path, grants, cron caller, migration ordering, and migration-history reconciliation before any production release.

## Rollout gates

- Keep this work on a branch separate from PR #8.
- Run unit/regression tests and disposable PostgreSQL integration/race fixtures.
- Compare query plans and execution statistics on representative data.
- Reconcile migration history before proposing any migration.
- Do not run `supabase db push`, apply a migration to Production, alter cron, or merge this PR until compatibility, tests, grants, and production rollout steps are explicitly reviewed.

## Open implementation decisions

1. Which dirty-row mechanism best fits the actual observation table schema and current upsert semantics?
2. What batch size and claim lease are safe under the project's current compute limits?
3. Should matching be a separate function/cron job or a bounded phase invoked after ingestion?
4. Which catalog update paths can enqueue affected observations, including alias-map changes, and can the event queue retain old and new values safely?
5. What observability fields/counters are needed to detect queue age, retry starvation, and matcher backlog?

These decisions must be resolved against the actual schema and disposable PostgreSQL tests before writing the production migration.


## Repository review findings (2026-11-17)

The current `main` implementation confirms that the observation upsert assigns `last_seen_at = now()` on every conflict update, while also replacing `source_payload` and refreshing `is_active`. Therefore, using the upsert's affected-row count or an unconditional `RETURNING id` as the dirty set would rematch rows on every sync. The implementation must compare the actual match-relevant fields (including Kifpool `nameId`) or use a separately maintained fingerprint/version.

The current matcher has three broad-table phases after ingestion:
- Kifpool exact-ID/name/verified-alias candidate matching;
- ordinary symbol/name candidate matching with per-observation candidate counts;
- fallback to `unmatched` when no active asset has the observation's symbol, with a Kifpool exception.

The verified Kifpool alias rules are embedded in the current SQL and include legacy-name transitions plus the special `arpa-chain` source-ID mapping. They must be extracted/reused without changing their conditions; do not replace them with a generic fuzzy match.

The repository's checked-in migration history does not contain the original table-creation migration for `public.exchange_asset_observations` or its base constraints. The table is assumed by later migrations. The live catalog has not been safely re-read in this work because prior Supabase SQL connections repeatedly timed out. Consequently, do not write a production migration or assume column defaults, identity behavior, constraints, indexes, trigger definitions, or grants from the function's column references alone. First obtain the authoritative table/trigger/index/function metadata or construct a fully explicit disposable fixture from a verified schema snapshot.

## CI result for the design-only PR

GitHub Actions run [44161434376](https://github.com/shahram-adim/DigiArz/actions/runs/44161434376) completed successfully (all 21 workflow steps passed). This is the repository's existing exact-decimal/browser and trading lifecycle/race suite. It does **not** execute an Iran exchange matcher test and must not be described as validation of the proposed matcher design.


## Isolated fixture added (2026-11-17)

A test-only PostgreSQL 17 fixture now exists under `supabase/tests/iran_exchange_matcher_fixture_*.sql`, with its own workflow `.github/workflows/iran-exchange-matcher-tests.yml`.

It exercises:
- full-scan versus dirty-queue result equivalence for a controlled seed set;
- exact ordinary matching, ambiguous symbol candidates, pending short-name behavior, unmatched symbols, inactive observations, and the full 39-entry verified Kifpool legacy-name alias tuple list plus the separate ARPA legacy source-ID transition;
- a heartbeat-only `last_seen_at` update that must not enqueue work;
- an actual match-input change (`asset_name`) that must enqueue exactly one observation and produce the same result as the full-scan baseline;
- bounded dirty-queue processing with `FOR UPDATE SKIP LOCKED`;
- a disposable PostgreSQL two-session contention test using independent `dblink` connections: worker A holds two row locks while worker B claims the next two rows; assertions verify disjoint claims and full four-row coverage. Both worker transactions are rolled back after the assertion.

**Important limits:** this is a deliberately minimal synthetic schema, not a production-schema reconstruction. The original applied table-creation migration is missing from the repository. The fixture's verified-alias table includes all 39 legacy-name tuples and the separate ARPA source-ID transition from the current main-branch matcher. The two-session test proves PostgreSQL row-lock/skip-locked behavior for a simple claim query; it does not exercise the production dirty-worker function, lease expiry/recovery, HTTP response ingestion/acknowledgement, production triggers, grants, ownership, catalog-change reconciliation, or production query plans. A passing fixture therefore validates only the isolated behaviors listed above. It does not authorize a production migration or establish full matcher parity.


## Isolated HTTP response queue fixture (2026-11-17)

A second disposable PostgreSQL fixture, `supabase/tests/iran_exchange_response_queue_fixture.sql`, now models bounded response claiming separately from the matcher fixture. It uses synthetic request/response tables and a claim function with a bounded limit, `FOR UPDATE SKIP LOCKED`, claim tokens, lease expiry, and attempt counts. It also exercises idempotent response ingestion, acknowledgement in the same transaction, invalid-JSON terminal handling, and a response inserted after an earlier batch.

The fixture includes:
- rollback of an uncommitted claim to model a worker crash before claim commit;
- expiry and reclaim of a previously leased batch;
- valid JSON ingestion with a unique response key, so retry cannot duplicate the fixture's ingest record;
- explicit terminal reason for invalid JSON and HTTP failures;
- two independent dblink sessions holding transactions concurrently, asserting two disjoint claims each and four total claimed rows, then rolling both transactions back.

**Scope limits:** all queue tables and functions are synthetic test objects, not the production `exchange_asset_sync_requests` or `net._http_response` definitions. The test proves a bounded claim/lease pattern and transaction-level behavior in the fixture only. It does not establish that Production has the required columns, indexes, constraints, pg_net retention behavior, privileges, or compatible cron scheduling. It does not yet test lease-heartbeat extension, maximum-attempt/dead-letter policy, worker termination after external HTTP effects, or end-to-end atomicity against the actual production ingestion function. PR #8 remains untouched and Draft; no Production SQL or cron changes were made.


## Retry cap and dead-letter fixture coverage (2026-11-17)

The synthetic HTTP response queue fixture now also models transient worker failures with a configurable maximum-attempt policy (default test value: 3). A failed claimed item is released for retry while below the cap; once the claim attempt count reaches the cap, the fixture records a distinct `dead_lettered_at` timestamp and terminal reason. Dead-lettered rows are excluded from subsequent claims and remain distinct from successfully processed rows. The test verifies two retry releases, terminal dead-lettering on attempt three, and that a later claim cannot pick the terminal row.

This remains test-only behavior. It does not define the Production retry cap, error classification, alerting/administrative replay process, or actual queue schema. Production policy must be selected from measured upstream failure behavior and operational requirements before implementation.


## CI validation update (2026-11-18)

The isolated matcher and response-queue workflow passed on commit `58a2b5dfa22c9d5b61bc107cfa0b197ff42c65e3`:
- [Iran exchange matcher fixture tests](https://github.com/shahram-adim/DigiArz/actions/runs/44174085683) — success.

The separate exact-decimal workflow for the same commit was still running at the time of this update; do not infer its result from the matcher workflow.

The response-queue fixture now covers bounded claims, lease expiry/reclaim, stale-token rejection, idempotent ingestion, terminal invalid-JSON handling, retry release, dead-lettering at the configured test cap, and two-session disjoint claims. This remains synthetic PostgreSQL-only evidence, not production compatibility or deployment approval.

### Operational replay requirement

Before any production dead-letter policy is implemented, specify a controlled replay path: authorization limited to operators, explicit selection of a dead-lettered request, recorded reason/operator/time, bounded replay rate, idempotent re-ingestion, and a clear rule for whether attempts are reset or retained. Replay must not silently clear terminal history or permit stale claim tokens to acknowledge a newer lease. This is an unresolved operational design item, not implemented by the fixture.


## Synthetic catalog and alias reconciliation fixture (2026-11-18)

The matcher fixture now includes a durable catalog-event queue with:
- asset insert/update/delete events retaining old and new symbol/name/active values;
- Kifpool verified-alias insert/update/delete events retaining old/new legacy names and the CoinGecko source ID;
- a bounded observation-ID scan cursor (test bound 1–1000), with event cursor progress and dirty-row enqueueing committed in the same transaction;
- independent events so a later catalog change does not reset an earlier event's cursor.

The integration fixture verifies:
- adding an asset rematches a previously unmatched observation;
- renaming a symbol revisits the old match and clears it;
- deactivating an asset clears its old match;
- more affected observations than one scan page are eventually processed;
- adding a verified Kifpool alias rematches the targeted observation;
- removing that alias re-evaluates the observation and does not leave a stale match identifier.

The synthetic matcher now clears the prior match state for scoped active observations before recalculating candidates. This is necessary for the alias-removal test: otherwise a previously matched row could retain an obsolete match when the old symbol still exists for unrelated assets. This behavior is a proposed invariant in the fixture and must be explicitly compared with the current Production function before any rollout; it is not evidence that Production already has this stale-match protection.

**Limits:** this queue scans the observation ID space in bounded pages for each event. It is a correctness prototype, not a measured production-optimal query plan. Alias coverage here targets the verified legacy-name tuple table; the separate ARPA legacy source-ID mapping remains covered by the matcher regression test but is not yet wired to a catalog-change trigger. Lease/retry behavior for catalog events, queue retention/cleanup, indexes, function ACLs, and production schema compatibility remain open.


## Production plan evidence and isolated scale experiment — 2026-11-18

A read-only Production review found:
- crypto_assets: 18,874 live rows; existing symbol index is on lower(symbol).
- exchange_asset_observations: 4,960 live rows; existing symbol index is on upper(base_symbol).
- The live matcher join compares upper(ca.symbol)=upper(o.base_symbol).
- A plan-only EXPLAIN of the simplified join chose a Hash Join with a sequential scan of all 18,874 crypto_assets rows; the observation side used its upper(base_symbol) index. This shows the existing lower(symbol) index does not match the catalog-side expression in that simplified query. It does not establish that an upper(symbol) index will improve the complete matcher or that this alone caused the observed timeouts.

A new disposable PostgreSQL 17 experiment, supabase/tests/iran_exchange_matcher_plan_fixture.sql, is wired into the matcher workflow. It seeds 18,874 synthetic catalog rows and 4,960 synthetic observations, then records EXPLAIN ANALYZE plans, execution times, and buffer counts for:
1. a 100-row dirty batch with only the existing lower(symbol) index shape;
2. a full scan with only that index;
3. the same dirty batch with a candidate upper(symbol) expression index;
4. the same full scan with the candidate index.

The candidate index exists only on temporary fixture tables. This experiment does not create or recommend a Production index. CI results must be inspected before deciding whether the expression index is useful for bounded incremental batches; full-scan and dirty-batch behavior may differ. The fixture is a plan/scale comparison, not a complete replay of the Production matcher SQL and not a substitute for Production query-plan validation.

Production safety remains unchanged: no DDL, index, function, cron, migration-history, or data change was made. Do not run supabase db push while migration reconciliation remains open.


### Repeated warm-cache experiment results — 2026-11-18

The five-run fixture refinement passed on commit b19273edc94a98c603b3e10529f86c88499c680d (GitHub Actions run 44182855849, PostgreSQL 17.12). Each scenario was warmed once, then measured five times.

| Scenario | Median | Min–max |
|---|---:|---:|
| 100-row dirty batch, lower(symbol) only | 6.188 ms | 6.169–6.314 ms |
| 100-row dirty batch, candidate upper(symbol) | 0.170 ms | 0.170–0.189 ms |
| Full 4,960-row scan, lower(symbol) only | 10.549 ms | 10.518–10.591 ms |
| Full 4,960-row scan, candidate upper(symbol) | 7.422 ms | 7.340–7.730 ms |

In this synthetic fixture, the candidate changed the dirty-batch catalog side from a full sequential scan/Hash Join to an upper(symbol) index scan/Merge Join. The median dirty-batch time was about 36x lower; the full-scan median was about 30% lower. This is stronger evidence for the *incremental dirty-batch access pattern* than for a full-scan optimization.

Limitations remain important: the fixture uses unique synthetic symbols, only 18,874 catalog rows and 4,960 observations, warm-cache measurements, and a simplified join rather than the full Production matcher function. It does not model duplicate/ambiguous symbols, alias matching, source-priority logic, concurrent writes, index maintenance cost, or actual Production hardware/cache state. It therefore supports a further test-only investigation, not a Production index decision. No Production DDL/index/function/cron/data was changed.

Exact-decimal workflow on the same head was still executing at last check; matcher fixture success does not imply that separate workflow passed.


## Catalog queue recovery, interleaving, and concurrent workers — 2026-11-18

Added focused test file supabase/tests/iran_exchange_matcher_catalog_queue_concurrency.sql and wired it into .github/workflows/iran-exchange-matcher-tests.yml. This file deliberately does not repeat existing matcher semantics, multipage convergence, alias insertion/removal, response-queue lease/retry, or response-worker SKIP LOCKED tests.

New coverage:
1. **Worker crash/recovery:** a catalog page is processed inside a transaction and rolled back. The test asserts both cursor advancement and dirty-row enqueueing roll back together. A restarted invocation then resumes from the durable cursor over separately committed pages and completes the same job.
2. **Interleaved catalog event:** event A is advanced to a partial cursor, then event B is inserted. The test verifies A's cursor is unchanged, B starts with its own cursor, and both events eventually complete and match their respective observations.
3. **Concurrent catalog workers:** two independent dblink PostgreSQL sessions hold transactions concurrently. Worker A locks the oldest event; worker B must skip that locked row and advance the next event. After B commits, A's uncommitted cursor remains invisible/unchanged to the main session; after A commits, the oldest event resumes. Both jobs must eventually complete and match all observations (bounded convergence guard).

The first CI execution exposed an incorrect expected cursor in the test assertion (it expected the first row rather than the second row after a two-row page). The assertion was corrected to expect the maximum ID in the committed two-row page; this was a test-only correction, not a Production code change.

Validation:
- GitHub Actions matcher fixture run 44184100854 on commit d121c4cc303774ab0012acde93f7efc7ec710c73: **success**.
- Log explicitly reports “Catalog queue recovery, interleaving, and concurrent-worker tests passed”.
- The independent exact-decimal workflow on the same commit, run 44184100898, was still in progress at the last check. Do not infer its status from the matcher fixture.
- No Production DDL, index, function, cron, migration, data, order, wallet, or balance changes were made. PR #11 remains Draft.
