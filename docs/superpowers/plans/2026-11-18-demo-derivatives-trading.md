# DigiArz Demo Derivatives — Implementation Plan

Date: 2026-11-18
Branch: `feat/demo-derivatives-trading`
Spec: `docs/superpowers/specs/2026-11-18-demo-derivatives-trading-design.md`

## Phase 0 — Baseline and protection
- [x] Re-read the current `main` app entrypoint and navigation implementation.
- [x] Confirm existing Spot RPC and tables; preserve the existing spot path.
- [x] Confirm Supabase project health, PostgreSQL version, exposed public tables and migration history.
- [x] Create a dedicated feature branch from the current main commit.
- [x] Record the derivatives product and safety design.
- [ ] Reconcile every Production migration and existing trading function, grants, RLS and cron definitions with repository history. The current production migration history is not yet fully reconciled.
- [ ] Confirm no hidden/legacy derivatives tables or functions exist before creating any new object.

## Phase 1 — Domain model and formula tests
- [ ] Specify and independently test futures notional, initial margin, maintenance margin, unrealized/realized PnL, fee reserve and liquidation price.
- [x] Specify and unit-test the initial USDT futures cross-risk aggregation helper (ledger-derived account cash + all cross positions + liabilities + close-fee reserve + stale-price fail-closed).
- [ ] Specify cross risk for Margin Spot with supported collateral assets and conservative haircuts.
- [ ] Specify and test margin borrow/repay, accrued interest, short sale proceeds and debt closeout.
- [ ] Specify funding-rate calculation, settlement interval, caps and idempotency.
- [x] Add disposable PostgreSQL fixture coverage for ledger-derived Futures cash (positive transfer, zero-balance account, absence of mutable cash columns, and RLS on the projection view); execution on latest HEAD remains pending.
- [ ] Add disposable PostgreSQL fixtures for exact arithmetic, rounding, negative balances, stale prices and liquidation boundaries, including the account-level cross-risk SQL projection.
- [x] Add pure exact-decimal Available Margin unit tests for open/partially-filled limit orders and reduce-only quantity reservations (PostgreSQL reservation/race tests remain pending).
- [ ] Add concurrent-session fixtures for order duplication, account locking, partial close and liquidation races.

## Phase 2 — Backend implementation (feature branch only)
- [ ] Add separate derivative accounts, orders, positions, fills, loans, funding, risk events and immutable ledger schema.
- [ ] Add RLS policies and least-privilege grants.
- [ ] Add fixed-search_path SECURITY DEFINER RPCs for all writes.
- [ ] Add idempotency and row-version checks.
- [ ] Add a deterministic settlement/maintenance worker design with bounded batches, retries and stale-price safeguards.
- [ ] Test migrations against a disposable PostgreSQL 17 database before any deployment discussion.

## Phase 3 — User interface
- [ ] Add a Derivatives area without changing existing Spot controls or RPC behavior.
- [ ] Build Futures terminal: pair, side, order type, leverage, margin mode, preview and position management.
- [ ] Build Margin terminal: borrow/repay, long/short, collateral, debt and interest.
- [ ] Build open positions, open derivative orders, fills, funding/interest and ledger history.
- [ ] Add clear warnings, risk meters, liquidation estimates and stale-price states.
- [ ] Verify Persian RTL, 360px Android layout, dark/light theme and keyboard/accessibility behavior.

## Phase 4 — End-to-end and Android validation
- [ ] Run all existing repository tests unchanged.
- [ ] Run new unit, SQL integration, concurrency, RLS and retry/recovery suites.
- [ ] Run app syntax and browser-level smoke tests.
- [ ] Confirm web build and Android APK CI artifacts.
- [ ] Test installation and real-device flows when the user can install the new build.

## Phase 5 — Review and controlled release
- [ ] Review security, accounting, performance and migration drift.
- [ ] Prepare a production deployment plan with exact migration versions and rollback/forward-fix strategy.
- [ ] Present the completed feature branch and test evidence for user review.
- [ ] Deploy only after explicit approval; no automatic Production migration or PR merge.

## Current checkpoint
Phase 0 product/design baseline is recorded. The Futures ledger accounting contract is specified in `docs/superpowers/specs/2026-11-18-futures-ledger-accounting.md`; the draft schema now derives Futures cash from an immutable ledger view. A pure exact-decimal `futuresAvailableMarginSnapshot()` helper and nine Node unit tests now cover cross Futures equity, position/order initial margin, open and partially filled Limit reservations, Reduce-only quantity allocation, stale marks, and conservative rounding. These tests have not yet been executed on CI or PostgreSQL. No runtime RPC, Supabase Production schema, migration, cron, function, balance, order or Production data has been changed. Next task is to obtain a real test run, add disposable PostgreSQL reservation/cancellation/partial-fill fixtures, and only then design account-locked idempotent RPCs.


## Checkpoint — cross-only order validation
- [x] Tightened `futuresAvailableMarginSnapshot()`: active orders must be Futures and `marginMode='cross'`; isolated and Margin Spot orders are rejected rather than mixed into the Cross Futures account snapshot.
- [x] Updated all Available Margin order fixtures with explicit cross margin mode and added a negative test for isolated and Margin Spot orders.
- [ ] Node and PostgreSQL 17 tests remain unexecuted/unverified for this checkpoint. The current execution container has Node 22.16.0 but no repository checkout and no `psql` binary; GitHub Actions run visibility remains incomplete.
- [ ] Before relying on order previews, review the short-limit reservation price policy and enforce fill-time margin checks in the eventual account-locked RPC.
- Pre-documentation GitHub comparison for commit `0f4183e39a1f8da8b47c77ba08dff500e538d7db`: 59 ahead / 1 behind `main` (`diverged`); PR #12 remains Draft. No merge/rebase; Actions run/status unverified.
- No Supabase Production schema, migration, RPC, cron, balances, orders or data were changed.


## Checkpoint: syntax failure discovered and corrected (2026-11-18)
- GitHub Actions run `44258864323` for the preceding HEAD failed in the Node test step because a literal stray `\\n` token appeared at line 123 of `src/derivatives-math.js`.
- The token was removed in commit `4020813ede6a3fbcaff1db43e92e979ae694c664`.
- The failing run discovered 37 tests; 35 passed and two derivative test files failed to load due to the same syntax error. PostgreSQL steps were skipped after the Node step failed.
- The correction is not yet validated. Inspect the new Actions run and its logs before proceeding to PostgreSQL reservation lifecycle fixtures or RPC implementation.


## CI validation checkpoint (2026-11-18)
- Fixed stray literal escape token in `src/derivatives-math.js` in commit `4020813ede6a3fbcaff1db43e92e979ae694c664`.
- GitHub Actions completed successfully for code commit `4020813...` (run `44259730430`), status-doc commit `4e48a2d...` (run `44259762686`), and plan-doc commit `e95c055...` (run `44259768302`).
- Verified Node TAP output: 58 tests, 58 passed, 0 failed. Disposable PostgreSQL 17 job also completed successfully, including derivative schema integration and arithmetic/regression scripts.
- Expected ERROR lines in negative SQL tests were asserted and did not fail the workflow.
- Remaining gap: SQL tests for Available Margin order reserve/release, cancel, partial fills, reduce-only allocation and concurrent account locking are not yet authored/verified. Do not activate derivatives UI or production RPCs.


## Checkpoint — explicit order direction and reduce-only contract
- [x] Added an explicit `side` field (`buy`/`sell`) to derivative orders, separate from `position_side` (`long`/`short`).
- [x] Added a database CHECK invariant: Long opens/increases only with Buy non-reduce; Long reduces only with Sell reduce-only; Short opens/increases only with Sell non-reduce; Short reduces only with Buy reduce-only.
- [x] Added `side` to fill records and extended the composite FK so a fill's execution direction must match its source order.
- [x] Added PostgreSQL integration assertions rejecting ambiguous Sell-Long and Buy-Short non-reduce orders.
- [ ] Run disposable PostgreSQL 17 integration tests on this checkpoint; schema/test changes are not validated until CI completes.
- [ ] Next: design deterministic reduce-only allocation across multiple orders for the same account/symbol/position side, then test cancel release, partial fill and concurrent placement under account-first lock.
- No RPC or UI order path is activated; no Supabase Production changes.


## Checkpoint — Reduce-only reservation allocation design
- [x] Defined one open position per account/product/symbol/position side as the allocation target; a partial unique index is required before order RPCs.
- [x] Defined placement validation using position quantity minus the sum of active Reduce-only remaining quantities, all under the account-first `FOR UPDATE` lock.
- [x] Defined Market Reduce-only as immediate fill-or-reject against unreserved quantity; no resting Market order.
- [x] Defined cancel/expire/reject as reservation release without a ledger cash movement.
- [x] Defined partial fills to reduce order remaining quantity and position quantity by the same exact amount in one transaction.
- [x] Defined deterministic reconciliation for external position reductions: cancel newest active Reduce-only orders first until reservations fit the remaining position.
- [ ] Implement the partial unique index and SQL fixtures for duplicate open positions, reserve, cancel, partial fill, market reduce-only, over-allocation and two-session races.
- [ ] Implement account-locked idempotent RPCs only after those SQL tests pass.
- No UI activation or Production database changes.


## Checkpoint — unique open position and atomic Market invariant
- [x] Added a partial unique index allowing at most one open position per account/product/symbol/position side (Long and Short remain independent).
- [x] Tightened Market order CHECK constraint: either fully filled in the same transaction or rejected with zero fill; no resting/partial Market order.
- [x] Updated the schema fixture to model a fully filled Market order.
- [x] Added PostgreSQL negative tests for duplicate open positions and pending Market orders.
- [ ] Await GitHub Actions on the resulting HEAD and inspect all PostgreSQL logs before marking tests passed.
- [ ] Next: add lifecycle functions/tests for Limit reserve, cancel release, partial fill, reduce-only allocation and two-session account-lock races. No RPC/UI activation or Production deployment.

- [x] Added a partial index over active Reduce-only orders keyed by account/product/symbol/position side and newest-first ordering; schema integration now asserts both the position uniqueness and Reduce-only indexes exist.


## Checkpoint — first Reduce-only placement/cancel RPC slice
- [x] Added a private, account-serialized placement helper for Reduce-only Limit orders. It locks account first, then position, sums active remaining quantity, and rejects over-allocation.
- [x] Added idempotency: same key and same payload returns the existing order; same key with changed payload rejects.
- [x] Added account-first cancellation; terminal status releases reservation without a ledger cash movement.
- [x] Added SECURITY INVOKER public wrappers and private SECURITY DEFINER helpers with auth.uid checks and restricted grants.
- [x] Added disposable PostgreSQL lifecycle test for reservation amount, idempotent retry, over-allocation rejection, idempotency mismatch, cancel release, repeated cancel and cross-user denial.
- [x] Added the lifecycle SQL draft/test to the existing PostgreSQL CI workflow.
- [ ] CI execution on current branch HEAD and SQL logs must be observed before treating this as verified.
- [ ] Partial fill remains blocked until realized PnL, fees, margin release and immutable ledger entries can be updated atomically in the same transaction.
- [ ] Next: implement/test partial Reduce-only fills and then real two-session account-lock races. No Production deployment or UI activation.


## Checkpoint — atomic Reduce-only Limit partial-fill slice
- [x] Added a `reduce_only_fill` immutable ledger event type.
- [x] Added a server-only fill RPC: only `service_role` can execute the public SECURITY INVOKER wrapper; its private SECURITY DEFINER helper has an empty search_path. Never expose the service key to the Android app.
- [x] Fill path locks account → order → open position, checks idempotent fill ID, validates 18-decimal precision and Limit price protection, and rejects fills beyond order/position remainder.
- [x] One transaction inserts the fill, updates position quantity/realized PnL/isolated margin, updates order filled/remaining/weighted average/status, and posts a balanced ledger group for PnL, fee and margin release.
- [x] Isolated margin release is pro-rata and truncated downward to 18 decimals; a full close releases the exact residual margin.
- [x] Added PostgreSQL lifecycle assertions for two fills, idempotent replay, overfill and price-protection rejection, final close, weighted average price and ledger-derived Futures cash.
- [x] Reconciled schema fixture: position's 20 USDT isolated margin is now represented by a ledger transfer while free Futures cash remains 10 USDT.
- [x] Added the fill SQL and test to disposable PostgreSQL CI workflow.
- [ ] Await actual CI run and inspect PostgreSQL output; this change has not yet been executed in a database.
- [ ] Next: add two-session concurrency tests and design cancellation/position-reduction reconciliation; keep UI disabled.

- [x] Fill path rechecks aggregate active Reduce-only reservations under the account lock and rejects pre-existing over-reserved state before mutating a position.


## Concurrency checkpoint — Reduce-only reservation
- [x] Added a two-process PostgreSQL test that races two independent authenticated sessions, each attempting to reserve 0.7 BTC against the same 1 BTC Long position with distinct idempotency keys.
- [x] Requires exactly one successful placement and one rejection specifically for exceeding unreserved position quantity; any unrelated failure fails the test.
- [x] Cancels the winning order and verifies the active reservation is fully released.
- [x] Wired the script into disposable PostgreSQL CI before the partial-fill test.
- [ ] Await and inspect a real CI run; not executed locally because no PostgreSQL client/server is available in this environment.

- [x] Shell syntax of the concurrent placement test was checked with `bash -n`; database behavior remains unverified until CI executes it.


## Concurrent Fill checkpoint
- [x] Added a two-session race against one 0.6 ETH Reduce-only Limit order, alongside two additional 0.2 ETH reservations, with each worker attempting a 0.7 ETH fill.
- [x] The test uses a separate user's ETHUSDT Cross position so it cannot consume or mutate the BTCUSDT fixture used by the sequential accounting test.
- [x] Requires exactly one fill success, one rejection specifically for exceeding order remaining quantity, exactly one persisted fill, and consistent 0.7 filled / 0.3 remaining order and position quantities.
- [x] Wired into CI after the trusted fill RPC is installed and before the sequential PnL/margin test.
- [ ] Await a real CI run and inspect PostgreSQL logs; no local database execution is available.


## External position reduction / Reduce-only reconciliation
- [x] Add a trusted, service-role-only reconciliation RPC. It discovers ownership, locks the account first and the position second, then cancels active Reduce-only reservations newest-first until the remaining reserved quantity is no greater than the position quantity.
- [x] Add an isolated ETHUSDT integration scenario with three active orders. After a simulated external position reduction from 0.6 to 0.3, the two newest 0.2 reservations must be cancelled and the oldest 0.2 reservation must remain.
- [x] Assert authenticated callers cannot invoke the trusted RPC, cancellation order is deterministic, the final reservation invariant holds, and a retry is a no-op.
- [ ] Run the SQL in disposable PostgreSQL through GitHub Actions and inspect complete logs.
- [ ] Integrate the helper inside the eventual trusted position-reduction/liquidation transaction after its financial accounting has been applied. Do not call it as a substitute for the actual position-reduction accounting.

- [x] CI ordering verified: run the concurrent-fill fixture first, then apply and test reconciliation against the ETH state it creates, then continue with the independent BTC accounting test.

## Checkpoint — atomic trusted external Futures position reduction (2026-11-18)

- [x] Confirmed the feature branch contains no existing derivative liquidation or external position-reduction RPC; the only reduction primitive before this checkpoint was a Reduce-only order fill.
- [x] Confirmed Supabase Production is PostgreSQL 17.11 and currently has no `demo_derivative_*` tables or Futures/liquidation functions. This was a read-only inspection; no Production objects or data were changed.
- [x] Confirmed `market_prices` is a single last-price row per symbol, overwritten by CoinGecko/KuCoin/Gate.io responses. It has no per-source observation history, index price or mark price; it is not approved as a liquidation oracle.
- [x] Added a draft-only trusted external Futures reduction RPC. It serializes on the account row, is idempotent by event UUID, updates position/PnL/isolated margin, posts balanced ledger entries and calls newest-first Reduce-only reconciliation in the same transaction.
- [x] Replaced the reconciliation fixture's direct position UPDATE with an end-to-end RPC test covering the real position reduction, PnL, fee, ledger cash, newest-first cancellation, replay and invalid over-reduction.
- [ ] Run the updated PostgreSQL 17 workflow on the new branch HEAD and inspect the full SQL logs. No test is considered passed until observed.
- [ ] Add concurrency tests for external reduction racing with placement, fill and cancel.
- [ ] Design the independent mark/index-price feed, maintenance tiers and liquidation/insurance accounting before any liquidation RPC. Do not use `market_prices` as a liquidation trigger.
- No Supabase Production DDL/RPC/data, merge/rebase or derivatives UI activation was performed.


## Checkpoint — full PostgreSQL CI green for trusted external reduction (2026-11-18)

- [x] GitHub Actions run `44267541202` on commit `cd1d4aae09680e5edacefdbdf396a3ed80df820b` completed with `success`.
- [x] The complete job passed Node/browser tests, PostgreSQL 17 regression/schema rehearsals, Spot advanced-order lifecycle/concurrency tests, derivative schema/RLS/ledger tests, Reduce-only placement/cancel and race tests, concurrent Fill test, atomic external Futures reduction/reconciliation, partial Fill accounting and ledger-balance rejection.
- [x] Fixed the disposable test-role fixture by explicitly enforcing and asserting `service_role NOLOGIN BYPASSRLS`; the trusted-worker test now verifies actual row visibility under that role.
- [x] Updated `IMPLEMENTATION_STATUS.md` with the successful run, current PR divergence and the next risk-engine design gate.
- [ ] Design a separate mark/index-price observation model with source provenance, freshness, quorum/deviation/outlier checks, immutable snapshots and fail-closed behavior. Existing `market_prices` last-price is not a liquidation oracle.
- [ ] Specify maintenance-margin tiers, partial/full liquidation sizing, close-fee reserve, liquidation fee, insurance/clearing treatment, cross-account risk, idempotency and recovery behavior.
- [ ] Only after the design is approved, add disposable PostgreSQL tests for long/short, isolated/cross, stale/outlier price, threshold boundaries, concurrent fills/orders and repeated liquidation events.
- No Production changes, no merge/rebase, and no derivatives UI activation.


## Checkpoint — independent Futures mark/index oracle design (2026-11-18)

- [x] Inspected current CoinGecko/KuCoin/Gate.io scheduled market_prices writers; they overwrite one last-price row per symbol and do not preserve concurrent provider observations, index, or mark.
- [x] Recorded public market-data interfaces to evaluate: Binance USDⓈ-M premiumIndex, Bybit V5 linear tickers, and OKX SWAP mark-price plus index ticker.
- [x] Added a transport-independent exact-decimal consensus helper with unique-provider quorum, freshness/future-time rejection, per-source basis checks, cross-source outlier rejection, median aggregation, and fail-closed result states.
- [x] Added Node tests for quorum, outlier, stale/future data, duplicate provider, malformed inputs, and exact 18-decimal median.
- [ ] Next: run CI; then design private PostgreSQL observation/batch/snapshot/policy schema and trusted collector ingestion contract. No live collector or DDL yet.
- [ ] Final per-symbol deviation/freshness thresholds require historical replay and explicit risk review; no hard-coded production thresholds.
- [ ] No Supabase Production changes, no Data API exposure, no UI activation, no automatic liquidation.


## Checkpoint — private price-oracle storage draft (2026-11-18)

- [x] CI run 44268659724 passed on the exact-decimal consensus helper commit.
- [x] Added a private storage draft for versioned per-symbol policies, collection cycles, per-provider terminal results, append-only observations, and immutable snapshots.
- [x] Added integration coverage for private grants/RLS, immutable evidence, source quorum, terminal provider states, and cycle completion only after snapshot publication.
- [ ] Run the new SQL integration in disposable PostgreSQL CI; fix any test failures before proceeding.
- [ ] Next design: trusted-worker ingestion/publication RPCs, idempotent cycle creation, retry and concurrent publication semantics.
- [ ] Venue endpoints are not automatically independent underlying feeds; map index constituents and correlated source families before final quorum policy.
- No Production DDL, collector deployment, UI activation, merge, or rebase.


## Checkpoint — private price-oracle storage CI passed (2026-11-18)

- [x] GitHub Actions run 44269201438 passed on commit 7dfc68a8d98cb4c2791206e6fdcc0fdb8abadbdf (40 successful steps, no failures).
- [x] The private oracle storage draft was applied to disposable PostgreSQL and its integration test passed.
- [x] Verified private client isolation, RLS, append-only observations/snapshots, provider terminal-state requirements, healthy quorum enforcement, and cycle completion only after snapshot insertion.
- [ ] Next: design service-only ingestion and snapshot-publication RPCs with idempotency, cycle-level serialization, and retry/crash/concurrency tests. Do not deploy a live collector yet.
- [ ] Investigate source-family/index constituent overlap before calling venues independent or choosing final quorum thresholds.
- No Production changes, collector deployment, UI activation, merge, or rebase.


## Checkpoint — Oracle ingestion/publication RPC CI green (2026-11-18)
- [x] CI اجراشده روی همگام‌سازی branch، run `44302116508` (push) و run `44302126025` (pull_request)، هر دو با نتیجهٔ `success` برای HEAD `8ce5751790cc6fc5a524e50c79360f68777cb5d9`.
- [x] RPCهای draft برای شروع cycle، ثبت نتیجهٔ نهایی provider و انتشار snapshot با دسترسی service_role-only، idempotency و قفل cycle در PostgreSQL دورریختنی اجرا شدند.
- [x] تست‌ها retry یکسان/متفاوت، جلوگیری از انتشار با provider pending، quorum، محاسبه median از observations، freshness/deviation، snapshot immutable و جلوگیری از دسترسی client roles را پوشش دادند.
- [!] تست‌های موجود هنوز آزمون مستقل crash بین دریافت پاسخ provider و commit، retry پس از قطع ارتباط نامعلوم، و رقابت هم‌زمان start/result/publish را کامل پوشش نمی‌دهند.
- [ ] مرحلهٔ بعد: تست دو نشست و fault-injection برای چرخهٔ Oracle؛ بررسی اینکه شروع دوبارهٔ cycle و ثبت provider پس از crash هیچ snapshot متناقضی منتشر نکند.
- [ ] بررسی منبع‌ها: venueهای Binance/Bybit/OKX الزاماً سه feed مستقل نیستند؛ تا بررسی constituents و همبستگی خانوادهٔ منبع، quorum نهایی یا threshold عملیاتی تصویب نشود.
- [ ] سپس طراحی maintenance-margin tiers، liquidation sizing، fee reserve، insurance/deficit و cross-margin risk در fixture ایزوله؛ هیچ trigger لیکوییدیشن از `market_prices` استفاده نکند.
- هیچ Supabase Production write، deployment، merge یا فعال‌سازی UI انجام نشد.

## Checkpoint — Oracle rollback recovery and exact maintenance tiers (2026-11-18)

- [x] Added two pre-commit fault-injection scenarios for provider-result and snapshot publication; both verify atomic rollback followed by a successful exact retry.
- [x] CI run `44304369272` passed for the Oracle recovery tests.
- [x] Added exact-decimal maintenance tier validation and lookup helpers. Tier schedules require increasing notional caps, a final unbounded tier, non-decreasing maintenance rates, continuous maintenance amounts at boundaries, non-negative cumulative deductions, and non-increasing leverage caps.
- [x] Added Node coverage for tier selection, 18-decimal precision, boundary continuity, and malformed schedules.
- [x] CI runs `44305188672` (push) and `44305201068` (pull_request) passed on commit `049246e84cd3927e31e8f50fda35b56a423f79b7`, 43 successful steps each.
- [!] Tier numbers are test fixtures only; no production schedule, leverage caps, SQL tier table, or order/risk integration has been approved.
- [ ] Next: add versioned server-owned maintenance-tier configuration and integrate it into isolated/cross risk snapshots with stale-price and threshold-boundary tests.
- [ ] Then specify and test partial/full liquidation sizing, liquidation fees, insurance-fund flows, deficit accounting, idempotency and concurrent liquidation/reduction races. No automatic liquidation or UI activation.
- No Supabase Production changes, PR merge, or PR Draft status change.

## Checkpoint — tier-aware isolated risk snapshot (2026-11-18)

- [x] `riskSnapshot()` accepts a validated maintenance-tier schedule and calculates maintenance margin/tier index from current mark notional.
- [x] Added a piecewise isolated liquidation-price estimate that resolves the tier at the candidate liquidation notional, including cases where the candidate crosses a tier boundary.
- [x] Conservative 18-decimal rounding: Long threshold rounds upward and Short threshold rounds downward.
- [x] Node tests cover Long and Short candidate prices on different tiers from entry/current notional and verify risk snapshot integration.
- [x] CI runs `44305853609` (push) and `44305863707` (pull_request) passed on commit `760c240ea5bb9bff5234e9fedf54dfb873aac23d`, 43 steps each.
- [!] This is a pure isolated-position estimate only. Tier configuration is not yet loaded from a versioned server-owned database table; cross-account aggregation and all liquidation accounting remain incomplete.
- [ ] Next: draft versioned maintenance-tier storage and a trusted server-side resolver; integrate tier schedules into cross-margin account risk with stale-oracle and version-change tests.
- [ ] Then test atomic partial/full liquidation, fee/insurance/deficit ledger flows, idempotency and concurrent liquidation vs fills/reductions. No auto-liquidation or UI activation.

## Checkpoint — per-symbol maintenance tiers in Cross risk and Available Margin (2026-11-18)

- [x] Cross-margin account risk now aggregates maintenance using a trusted per-symbol tier schedule map; missing schedules fail closed.
- [x] Available Margin preview uses the same per-symbol schedule for open positions and rejects missing tier configuration.
- [x] Positive notional × maintenance rate is rounded upward to 18 decimal places before subtracting the tier's cumulative maintenance deduction.
- [x] Node tests cover multi-symbol Cross aggregation, missing schedule rejection, and Available Margin reservations with tier-derived maintenance.
- [x] CI runs `44306457201` (push) and `44306468761` (pull_request) passed on commit `4f0204423006a5da7245fcbebe640d05f6dd5e1d`, 43 steps each.
- [!] Tier maps are still injected into pure math helpers; there is no versioned database authority, server-side resolver, RLS/grant model, or audited configuration lifecycle yet.
- [ ] Next: add draft PostgreSQL schema for immutable versioned per-symbol schedules and tiers, validate monotonic/continuous tier invariants in the database, and expose only a trusted server-side resolver.
- [ ] Add PostgreSQL tests for activation/version changes, missing/overlapping schedules, exact tier boundaries and concurrent resolver reads. Then proceed to liquidation ledger/insurance accounting.

## Checkpoint — versioned private Maintenance Tier storage and resolver (2026-11-18)

- [x] Added private per-symbol versioned schedule and tier tables, draft/active/retired lifecycle, and a one-active-version-per-symbol index.
- [x] Database validator enforces contiguous tier indexes, increasing notional caps, final unbounded tier, non-decreasing rates, continuous cumulative deductions, non-increasing leverage caps, and 18-decimal ceiling arithmetic.
- [x] Added immutable active/retired schedule guards, tier mutation guards, monotonic version activation, and atomic retirement/replacement.
- [x] Added a private service_role-only resolver returning schedule version, tier, maintenance rate/deduction, leverage cap, and exact maintenance margin. No direct table grants to client or service roles.
- [x] Added PostgreSQL integration coverage for tier boundaries, invalid schedule rejection, schedule version replacement, immutability, grants, and service-role resolution.
- [x] Added the new SQL draft/test to the exact-decimal CI workflow. Runs `44307356561` (push) and `44307363912` (pull_request) passed, 45 successful steps each.
- [!] CI uses disposable PostgreSQL only. No Production schedule has been created, no worker/RPC calls the resolver yet, and no live trading/liquidation is enabled.
- [ ] Next: two-session tests for concurrent schedule activation and resolver reads; define snapshot version pinning so one risk calculation cannot mix tier schedule versions.
- [ ] Then wire the trusted resolver into server-side risk calculations and add atomic liquidation ledger/insurance/deficit accounting with partial/full reduction races.

## Checkpoint — Maintenance Tier activation/resolver concurrency (2026-11-18)

- [x] Per-symbol schedule activation now serializes with a transaction-scoped advisory lock and re-reads status/version after acquiring it.
- [x] Repeated activation of an already-active schedule is idempotent.
- [x] Added a two-session test that holds a resolver's shared lock on v2 while v3 activation waits, then concurrently retries v4 activation and asserts both calls converge on one active version.
- [x] CI runs `44308127930` (push) and `44308135188` (pull_request) passed on commit `3595a3ea535fcc477b8f3a0ce1f21e176aebb286`, 46 successful steps each.
- [!] The schedule resolver is not yet called by a full account risk RPC. A single risk snapshot must pin schedule IDs/versions inside one transaction to prevent mixed-version aggregation.
- [ ] Next: implement a transaction-scoped risk-snapshot resolver that loads all relevant symbol schedules once, pins version IDs for the entire account calculation, and fails closed on missing/stale oracle data.
- [ ] Then specify and test liquidation sizing and ledger settlement: partial/full reduction, close/liquidation fees, insurance/clearing, deficit/ADL, retries and concurrent fill/liquidation races.

## Checkpoint — private schema privilege hardening (2026-11-18)

- [x] Explicitly revoked `private` schema usage from PUBLIC, anon and authenticated; service_role retains only schema usage and function execute grants.
- [x] PostgreSQL integration tests assert client schema isolation, no direct table access for service_role, and service-role-only resolver/activation function privileges.
- [x] CI runs `44308662580` (push) and `44308674101` (pull_request) passed on commit `4c04ffd4024f671a51ec1a6ca5240df2953aec4a`, 46 successful steps each.
- [!] Still draft-only and disposable-PostgreSQL-only; Production remains unchanged and no live risk/order/worker path consumes the resolver.
- [ ] Next: create a server-side account risk snapshot RPC that pins each symbol's schedule ID/version in one transaction and calculates every position against that pinned version; add a two-session schedule-replacement race.
- [ ] Then design and test atomic liquidation/insurance/deficit ledger accounting. Keep auto-liquidation and derivatives UI disabled.

## Checkpoint — transaction-pinned account maintenance snapshot (2026-11-18)

- [x] Added a private service_role-only account snapshot function that locks the account and open positions and pins active per-symbol maintenance schedule rows for the duration of the call.
- [x] Each position uses the newest Oracle snapshot regardless of status; any newest stale/deviation/insufficient-quorum or expired snapshot fails closed rather than falling back to an older healthy price.
- [x] Snapshot output includes mark/oracle provenance, notional, unrealized PnL, maintenance tier/rate/deduction, schedule ID/version, leverage cap, and ledger-derived Futures cash.
- [x] PostgreSQL tests cover isolated and cross positions, multiple symbols/accounts, exact tier calculations, cash projection, and stale-latest-snapshot rejection.
- [x] CI runs `44310385007` (push, 46 steps) and `44310397178` (pull_request, 48 steps) passed on commit `70a637270cdd7f9ee115d6b08de3ad0c584d7280`.
- [!] This is still a maintenance/PnL snapshot, not a complete account risk engine: close-fee reserve, unposted liabilities, account equity, maintenance buffer and final margin ratio are not yet assembled in SQL. No order or liquidation worker consumes it.
- [ ] Next: add trusted fee schedule/resolution, non-duplicated unposted liabilities, and account-level equity/maintenance/margin-ratio aggregation within the same transaction.
- [ ] Then implement atomic liquidation/insurance/deficit ledger accounting and test partial/full liquidation against concurrent fills/cancels. Keep automatic liquidation and derivatives UI disabled.


## Checkpoint — SQL account-risk aggregation and full CI green (2026-11-18)

- [x] Added a versioned private Maker/Taker Futures fee schedule with immutable active/retired versions, monotonic activation and a service_role-only resolver.
- [x] Added a ledger-backed Funding settlement guard: accrued events are immutable, settlement requires a matching immutable funding ledger transaction, and the USDT Futures cash movement must equal the accrued amount.
- [x] Added a private account-level Cross risk snapshot that combines ledger-derived cash, Cross unrealized PnL, unposted Funding liabilities/receivables, close-fee reserve, Equity, Maintenance Margin and Margin Ratio; per-position snapshots include isolated equity, fee schedule version and funding accruals.
- [x] Tests cover settled versus unposted Funding, immutable accruals, no settlement without a matching ledger movement, isolated/cross aggregation, fee schedule versioning and stale-newest-oracle fail-closed behavior.
- [x] Corrected the Margin Ratio test to compare the returned ratio against the same returned Equity/Maintenance components.
- [x] Corrected the Reduce-only cash assertion to account for the already-settled 5 USDT funding debit in the shared account fixture: 10 initial free cash - 5 settled funding + 20 isolated margin released + 7 realized PnL - 0.05 fees = 31.95 USDT.
- [x] Final CI on commit `bec86d6338b8d188a8fb2406d903e19c013bda90`: push run `44326154079` and pull_request run `44326169424`, both `success`, 51/51 steps each.
- [!] All SQL remains draft-only and was exercised in disposable PostgreSQL 17. No Supabase Production DDL/RPC/policy/cron/data changes were made; PR #12 remains Open/Draft and unmerged.
- [x] Added `docs/superpowers/specs/2026-11-18-demo-derivatives-liquidation-accounting.md` defining the isolated/cross liquidation boundary, partial/full reduction safety, execution-price/slippage contract, fees, insurance/deficit accounting, idempotency and the required test matrix.
- [ ] Before writing liquidation execution SQL, resolve the six explicit policy decisions in the new spec: liquidation surcharge, slippage bound/execution evidence, target buffer/partial sizing, Cross position priority, insurance seed/replenishment, and residual deficit/recovery/ADL.
- [ ] After policy decisions, implement the system-level insurance ledger and deficit journal first, then isolated and Cross liquidation RPCs in disposable PostgreSQL with the full concurrency/fault-injection matrix. Keep auto-liquidation and UI disabled.


## Checkpoint — platform insurance ledger and deficit accounting boundary (2026-11-18)

- [x] Inspected the existing derivatives schema and trusted reduction/fill ledger postings on the live feature branch.
- [x] Confirmed the user ledger is keyed to `auth.users`; `system_clearing` is a per-user balancing bucket, not a platform insurance account. No fabricated system user or negative user wallet is acceptable.
- [x] Added `docs/superpowers/specs/2026-11-18-demo-derivatives-insurance-deficit-ledger.md` defining a separate private platform ledger, append-only deficit memorandum journal, event-linked cross-ledger reconciliation, debit/credit conventions, atomicity and required tests.
- [!] This checkpoint is design-only. No insurance/deficit SQL, RPC, migration, Production write, or liquidation worker was created or enabled.
- [ ] Next: implement the isolated private platform-ledger and deficit-journal schema plus invariant tests in the existing disposable PostgreSQL 17 CI fixture; do not implement payout/recovery RPCs until seed/replenishment and residual-deficit policies are approved.


## Checkpoint — private platform insurance ledger and deficit journal validated (2026-11-18)

- [x] The isolated private platform ledger and append-only deficit memorandum schema draft are present at `supabase/drafts/2026-11-18_demo_derivatives_insurance_deficit_ledger.sql`.
- [x] Disposable-PostgreSQL integration coverage is present at `supabase/tests/demo_derivatives_insurance_deficit_ledger.sql`, including balanced postings, seed/payout/recovery classification, overdraw rejection, over-recovery rejection, immutability, idempotency, and private access boundaries.
- [x] GitHub Actions run `44361544743` on commit `efe928d38ce2174c237abe9fae8cfb0232e72d04` completed successfully; the job steps specifically report success for applying the draft, testing insurance accounting/deficit exposure/private access, and running two-session insurance payout/deficit recovery races.
- [!] This evidence is for disposable PostgreSQL CI only. It does not authorize payout/recovery RPCs, liquidation execution, or any Supabase Production change.
- [ ] Next: keep execution paths blocked and obtain explicit policy decisions for the six liquidation gates in `docs/superpowers/specs/2026-11-18-demo-derivatives-liquidation-policy-decisions.md`. Do not infer values from fixtures.


## CI checkpoint — complete derivatives exact-decimal pipeline (2026-11-18)

- [x] GitHub Actions run `44365892534` (run 714, commit `806644414e8a2ab14ce471d1bb36fc7e1709e0e3`) completed with conclusion `success`; the `exact-decimal` job also completed successfully with no failed steps.
- [x] Retrieved job logs confirm the disposable PostgreSQL insurance/deficit integration passed, atomic rollback fault injection passed, and two-session insurance/deficit races passed (one affordable payout and one recovery won; overdraw and over-recovery were rejected).
- [x] The same run also completed the broader exact-decimal, derivative schema, maintenance tier, oracle, Reduce-only and lifecycle integration steps in the disposable test environment.
- [!] This is CI evidence only. It does not authorize applying any draft to Supabase Production or enabling liquidation execution, payout/recovery RPCs, workers, or UI.
- [ ] Continue with policy-independent work only until the six liquidation policy gates are explicitly decided; no fixture value may be promoted to policy.


## CI checkpoint — exact-decimal workflow on current feature HEAD (2026-11-18)

- [x] GitHub Actions run `44366483390` (run 717) was fetched for current feature HEAD `fec498d77a9a0776f094ff38888c9f7427d631d8`; workflow and `exact-decimal` job both completed with conclusion `success`.
- [x] All 50 substantive job steps completed successfully, including the disposable PostgreSQL derivative schema, maintenance/fee schedules, Oracle storage and trusted ingestion RPCs, Oracle two-session idempotency/publication races, Reduce-only lifecycle/concurrency, and insurance/deficit accounting plus payout/recovery races.
- [x] Retrieved job logs confirm Oracle duplicate-cycle/provider/publication retries converged idempotently; conflicting provider payloads had one winner; pre-commit provider/snapshot failures rolled back atomically and exact retries recovered. Insurance/deficit rollback and two-session race checks also passed.
- [!] Expected negative-test errors in the logs (invalid widening preflight, lock timeout, intentional missing relation, rejected duplicate/conflicting Oracle result, overdraw/over-recovery, and unbalanced ledger) were asserted test cases; the workflow/job conclusion remained success.
- [!] All database execution was against disposable CI PostgreSQL. No Supabase Production DDL/RPC/policy/cron/data changes occurred. No collector, liquidation execution, payout/recovery RPC, worker, or UI was enabled.
- [ ] Continue only with policy-independent work; keep PR #12 open and Draft and do not infer policy values from test fixtures.


## Oracle operations observability contract — design-only checkpoint (2026-11-18)

- [x] Added `docs/superpowers/specs/2026-11-18-demo-derivatives-oracle-operations-observability.md` defining lifecycle telemetry, bounded-cardinality metrics, correlated structured events, alert classes, fail-closed states, incident runbooks, evidence retention/access controls, and a disposable-CI verification matrix.
- [!] Alert thresholds, SLOs, retention periods, source quorum, and financial risk eligibility remain intentionally unset; no operational policy was inferred.
- [!] This is documentation only. No collector, telemetry sink, alert, cron, RPC, migration, production secret, liquidation path, or Supabase Production object was created or enabled.
- [ ] Next: when implementation is separately authorized, translate the verification matrix into isolated tests and add instrumentation only behind a reviewed trusted-service design; do not deploy a live collector before source-family and policy review.


## CI checkpoint — complete exact-decimal workflow on documented HEAD (2026-11-18)

- [x] GitHub Actions run `44367314575` (run 721) on commit `abf6ac3757135dd742d94f147b810c85d0e15e93` completed with workflow/job conclusion `success`; all 54 job steps completed successfully.
- [x] Retrieved job logs confirm Market/Limit entrypoints, Stop-Limit and TP/SL lifecycle, two-session cancellation/execution races, derivative schema, maintenance-tier version pinning, Oracle provider/publication idempotency and rollback races, Reduce-only accounting, and insurance/deficit ledger rollback/races passed in disposable PostgreSQL.
- [!] Expected negative-test errors in the logs were asserted rejection cases; they did not fail the job. A package repository returned HTTP 429 during setup but the workflow continued using available package indexes and the job completed successfully.
- [!] This run predates the observability documentation commits that follow; it does not validate that documentation or any live service. No Supabase Production changes or live collector/liquidation activation occurred.


## CI checkpoint — latest HEAD verified (2026-11-18)
- [x] GitHub Actions run `44367963448` (run 730, Exact decimal tests) for commit `d21057ae403f167c3ea9cd5a709fce095c5e36cd` completed with conclusion `success`.
- [x] The exact-decimal job completed its Node/browser, disposable PostgreSQL 17, derivative schema/RLS, maintenance/fee schedule, Oracle, account-risk, Reduce-only, insurance/deficit and concurrency checks.
- [!] Expected negative SQL assertions, lock-timeout rehearsal and intentional fault injection appear as ERRORs in PostgreSQL logs; the job conclusion is success.
- [!] This is disposable CI evidence only; no Supabase Production mutation or deployment is authorized.
- [ ] Continue with a policy-independent task. Do not implement per-fill fee pinning until its open contract decision is approved; keep all six liquidation policy gates closed.


## تأیید CI روی HEAD شاخه — ۱۸ نوامبر ۲۰۲۶ (run 733)
- [x] اجرای GitHub Actions شمارهٔ `44368468782` (run 733، workflow: Exact decimal tests) برای commit `a1146e1aef8d36beb49308eb574dc18e2fbc841a` با conclusion برابر `success` پایان یافت.
- [x] job اصلی `exact-decimal` با نتیجهٔ `success` تمام شد؛ ۵۰ گام اصلی workflow موفق بودند (به‌علاوهٔ مراحل setup و cleanup).
- [x] لاگ واقعی اعمال و تست draft نسخه‌بندی کارمزد Futures، resolver مورداعتماد، چرخه Reduce-only fill، رقابت fill دو نشست، حسابداری PnL/fee/margin release، دفترکل بیمه/کسری، rollback اتمیک و raceهای دو نشست را در PostgreSQL 17 دورریختنی تأیید می‌کند.
- [!] این run فقط CI ایزوله است و هیچ‌یک از draftها را روی Supabase Production اعمال نمی‌کند؛ deployment یا مجوز فعال‌سازی worker/RPC/UI ایجاد نمی‌کند.
- [!] تست فعلی fee schedule فقط activation/immutability/resolver را پوشش می‌دهد. RPC مربوط به Reduce-only fill هنوز `p_fee_usdt` را از ورودی trusted service می‌گیرد و schedule ID/version را در هر fill ثبت/اعتبارسنجی نمی‌کند. زمان pin شدن schedule per-fill هنوز تصمیم‌گیری/تصویب نشده؛ این شکاف باید باز بماند و با fixtureهای نرخ به سیاست واقعی تبدیل نشود.
- [x] PR #12 همچنان Open/Draft و unmerged است؛ هیچ merge/rebase و هیچ تغییر Supabase Production انجام نشد.
