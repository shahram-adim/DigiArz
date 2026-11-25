# Production migration dependency and order map — 2026-11-25

## Purpose and evidence boundary

This is a source-derived dependency map for the 17 historical SQL bodies recovered in PR #62 and byte-verified against the Production migration ledger. It is an audit artifact, **not** a replay manifest and not permission to execute or rename migrations.

Evidence:
- Production project `gfoaubfilhttnwjykaox` was read-only inspected as ACTIVE_HEALTHY on PostgreSQL 17.11.
- Production migration ledger contains 55 applied rows through `20261121050216`.
- The 17 recovered source files in PR #62 were separately verified byte-for-byte against their corresponding `text[]` ledger statements after removing only their nine-line provenance header.
- The dependency statements below come from static inspection of those SQL bodies plus the known live catalog inventory. A dependency is not proof that an object was created by that migration unless the body explicitly does so.

## Dependency groups

| Historical version | Primary objects / prerequisites | Downstream dependencies | Side-effect class and replay restriction |
|---|---|---|---|
| `20261113153808` | Existing `public.profiles`, `public.wallets`, trading RPCs; creates fee and coin-review/report tables and policies | Wallet/admin sequence; fee-rate RPC; review UI/RPC | Changes wallet defaults and new-user setup, inserts fee seeds, creates policies, and dynamically replaces trading function bodies. Not a harmless schema-only migration. |
| `20261113154323` | `auth.users`, `public.profiles`; creates `private.admin_users` and `private.is_super_admin()` | Admin wallet functions, admin role probe, admin monitoring | Contains conditional super-admin identity/role seed. Never replay the privileged identity assignment. |
| `20261113154736` | `private.admin_users` / `private.is_super_admin()`, profiles, wallets, reservations, transactions | Toman wallet adjustment and private-schema admin move | Creates admin adjustment audit table and privileged wallet RPCs. Function invocation can change balances and write transaction/audit rows. |
| `20261113154750` | `private.is_super_admin()` | Later admin monitoring / role checks | Adds a super-admin probe RPC; its privilege boundary must be tested with synthetic identities. |
| `20261113154844` | `private.admin_wallet_adjustments` and the prior wallet-adjustment function | `20261113154926` | Revises currency constraint and wallet adjustment logic (USDT/TOMAN conversion). Replacing it out of order can revert semantics. |
| `20261113154926` | Prior private admin schema, role function, adjustment table and admin RPCs | All later private-admin callers | Moves/redefines privileged logic in `private` and adds public wrappers/grants. Requires exact prior signatures and ACL context. |
| `20261115101709` | Existing `public.crypto_assets(coingecko_id)` | Iranian exchange worker, Bit24 worker, auto-list trigger, pair activation, admin report | Creates observation evidence table, FK, indexes, RLS and service-role grants. |
| `20261115102729` | Observation table, `pg_net` request/response objects, supported exchange APIs | JSON-cast fix, admin monitor, worker ACL restriction, back-pressure rewrite | Creates request table, request/process functions and Cron schedules; request function enqueues external HTTP calls. |
| `20261115102927` | Prior `process_iran_exchange_asset_sync()` and request/observation/pg_net tables | Later worker revisions and monitoring | Replaces the processor to cast HTTP response content to JSONB. Depends on the exact earlier worker signature and tables. |
| `20261115103227` | Observation table, crypto assets, admin market listings, demo trading pairs | Auto-activation and admin market listing views | Installs observation trigger and performs a curated-market backfill. It changes catalogue rows. |
| `20261115103507` | Observation table, crypto assets, `pg_net` response objects and `pg_cron` | Admin monitoring and worker ACL restriction | Creates Bit24 request table/functions and two Cron jobs; request function enqueues real HTTP calls. |
| `20261115105721` | `private.is_current_user_super_admin()`, observation table, both provider request tables, curated listings | Admin dashboard / monitoring caller | Adds privileged monitoring and manual-request RPCs. Manual request invokes both external request workers. |
| `20261115105956` | Both Iranian and Bit24 request/process function signatures | Cron/service-role worker execution | Revokes API-role EXECUTE on four worker functions. Must be reviewed with actual Cron execution identity and service-role policy. |
| `20261116201639` | Observations, crypto assets, curated listings, market prices, demo trading pairs, `pg_cron` | Demo-pair catalogue and later trading flows | Creates auto-activation function, schedules it, and inserts eligible demo pairs. It is data-changing. |
| `20261121045434` | Existing market-price/FX and exchange-worker function definitions; private request tables; `pg_net` queue/response relations | Market/FX/exchange synchronization after back-pressure changes | Uses `pg_get_functiondef` and exact text replacement to rewrite live function bodies; also includes queue cleanup/back-pressure logic. Fails if expected source snippets differ. Never replay blindly. |
| `20261121045531` | `private` schema plus `net.http_request_queue` and `net._http_response` | Recovery/diagnostic workflows | Copies transient operational queue/response rows into persistent tables. Replaying can duplicate operational payloads. |
| `20261121050216` | `pg_cron` and existing job IDs 14 and 16 | Current exchange-processor cadence | Calls `cron.alter_job` for jobs 14 and 16. Do not execute or alter any Production schedule. |

## Minimum dependency edges

The following are direct source-level prerequisites, not a claim that every pair is a strict single-parent dependency:

- Wallet/admin: `13153808 → 13154323 → 13154736`; `13154736 → 13154844 → 13154926`; `13154323 → 13154750 → 13154926`. The admin monitoring migration later consumes the private super-admin probe.
- Exchange observations: `15101709 → 15102729 → 15102927`; `15101709 → 15103227`; `15101709 → 15103507`.
- Monitoring/ACL: `15102729 + 15103507 + 15101709 + 13154750 → 15105721 → 15105956`.
- Demo pair activation: `15101709 + 15103227 + market_prices + crypto_assets + demo_trading_pairs → 16201639`.
- Back-pressure/recovery: the 21-November function rewrite requires the previously installed market-price, FX, Iranian-exchange and Bit24 worker definitions and their request/queue relations. The queue snapshot and Cron cadence change are operational follow-ups, not schema prerequisites for a blind batch replay.

## Timestamp/content reconciliation — read-only comparison

The current reconciliation inventory reports 55 Production ledger rows, 40 local SQL files, 38 normalized-name matches, 20 timestamp-prefix mismatches, 18 exact timestamp matches, 17 missing canonical source files, and two local files without a matching ledger name.

All 20 timestamp-mismatched local SQL files were compared directly with the corresponding Production ledger body using byte length and MD5, then the four non-exact cases were inspected:

- **16/20 are byte-exact** despite the filename timestamp mismatch.
- **3/20 differ only by a single leading or trailing newline**:
  - `20261113162154` ↔ `20261113162202_record_conditional_reservation_consumption.sql` (extra final newline locally);
  - `20261113162233` ↔ `20261113162244_index_conditional_execution_order_reference.sql` (extra final newline locally);
  - `20261113173506` ↔ `20261113190000_admin_on_demand_crypto_asset_refresh.sql` (one leading newline in the ledger body).
- **1/20 is a substantive content divergence**:
  - ledger `20261115134357` ↔ local `20261115134500_add_kifpool_to_scheduled_exchange_asset_sync.sql`.
  - The local file is 230 bytes longer. In addition to formatting differences, its processor has guarded/no-op update predicates for unchanged observation matches and unmatched statuses; the ledger body updates those rows without the same predicates. This is a behavioral difference, not a timestamp-only rename. Preserve both versions as distinct evidence; do not replace the ledger source with the local file or silently rename it.

The two local-only files `20261116203000_add_kucoin_to_scheduled_market_price_refresh.sql` and `20261116203100_add_gateio_to_scheduled_market_price_refresh.sql` remain unrecorded in the Production ledger. Prior review found that they install older `refresh_market_prices()` definitions and can remove the later 515-ID cap if pushed in an unsafe sequence. Keep them out of any push/replay set pending a separate supersession decision.

## Safe next validation sequence

1. Preserve original Production ledger SQL and current local files separately; record version, normalized name, byte length, hash, and exact/whitespace/semantic classification for every row.
2. For the four non-byte-exact cases, retain the original text and document the whitespace-only cases separately from the substantive Kifpool divergence.
3. Resolve the two local-only refresh files as superseded/obsolete evidence without editing Production migration history.
4. Build a disposable PostgreSQL 17 replay fixture from the full ordered set of reviewed sources. Stub or omit external HTTP, queue snapshots, identity seeds, Cron scheduling/alteration, and all data/financial writes; use explicit synthetic fixtures only.
5. Fail closed if the test target is not the ephemeral CI database. Do not use the existing recovery test project as a clean replay target without separate preparation and approval.
6. Compare resulting function definitions, relation/constraint/policy metadata, grants, triggers, and intended Cron definitions against the read-only Production inventory. Keep Cron changes as assertions only; never apply them.
7. Only after these checks, prepare a reviewable reconciliation proposal. No `db push`, Migration execution, manual ledger rewrite, Production SQL mutation, merge, deployment, or Cron change is authorized by this map.

## Safety

This document is static analysis and read-only evidence only. No Production object, data, grant, policy, function, view, queue, Cron job, wallet, order, trade, reservation, or financial row was changed. No project/branch cost was created.
