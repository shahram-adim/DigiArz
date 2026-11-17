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
4. Which catalog update paths can enqueue affected observations, including alias-map changes?
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
- exact ordinary matching, ambiguous symbol candidates, pending short-name behavior, unmatched symbols, inactive observations, and one verified Kifpool legacy alias (Kishu);
- a heartbeat-only `last_seen_at` update that must not enqueue work;
- an actual match-input change (`asset_name`) that must enqueue exactly one observation and produce the same result as the full-scan baseline;
- bounded dirty-queue processing with `FOR UPDATE SKIP LOCKED`.

**Important limits:** this is a deliberately minimal synthetic schema, not a production-schema reconstruction. The original applied table-creation migration is missing from the repository. The fixture's verified-alias table includes only the Kishu example, not the full production alias set; it does not exercise the HTTP response ingestion/acknowledgement queue, production triggers, grants, ownership, catalog-change reconciliation, multi-session races, or production query plans. A passing fixture therefore validates only the isolated behaviors listed above. It does not authorize a production migration or establish full matcher parity. Expand the alias matrix and add real two-session worker tests only after recovering the authoritative schema and reviewing the full alias source.
