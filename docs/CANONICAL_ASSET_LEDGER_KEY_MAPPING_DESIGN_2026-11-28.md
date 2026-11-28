# Canonical asset-to-ledger key mapping design — 2026-11-28

**Status:** design decision and disposable-test requirements only. No DDL, backfill, or Production data access/write is authorized.

## 1. Verified legacy constraint

The authoritative Market/Limit fixture defines:

- `asset_balances(user_id, asset, balance)` with primary key `(user_id, asset)`;
- `order_reservations.asset` as text;
- the existing Market/Limit function bodies derive the base ledger key from the display pair ticker (for example, split the USDT suffix);
- the current canonical prototype uses independent UUID asset IDs but a separate generic `balances(user_id,asset_id)` ledger.

Consequently, the legacy text `asset` key is not sufficient to represent two distinct canonical assets that share one display ticker. Mapping both canonical IDs to the same text key would merge their balances and reservations. This is a structural identity collision, not merely a missing unique constraint.

## 2. Decision: separate identity from ledger key and display ticker

The future candidate must distinguish three values:

1. **canonical asset ID** — immutable identity, UUID;
2. **ledger asset key** — stable, unique, non-display identifier used by `asset_balances.asset` and the corresponding reservation identity;
3. **display symbol/name** — mutable presentation metadata, never an execution or balance key.

For a canonical asset, the ledger key must be unique across canonical assets and must not be derived solely from a ticker. A candidate representation may use a reserved internal namespace such as `asset:<canonical-uuid>`, but its exact production representation is deliberately undecided pending review of every function, RPC, transaction consumer, reporting path, and compatibility contract that currently reads or writes `asset_balances.asset` and `order_reservations.asset`.

Do not silently replace a user's displayed ticker with this internal key in UI, API responses, or transaction descriptions. Resolve presentation through the canonical asset catalogue.

## 3. Mapping relation requirements

A future additive mapping relation should conceptually enforce:

- one row per canonical `asset_id` (primary/unique key);
- one unique `ledger_asset_key` per canonical asset;
- mapping provenance (source and evidence reference);
- state such as `pending`, `verified`, `ambiguous`, or `quarantined`;
- reviewer and review timestamp for manual resolution;
- no automatic activation for ambiguous or conflicting legacy symbols.

The canonical pair references this mapping for its base asset. Quote asset mapping is separately validated; the supported USDT wallet remains the existing `wallets.balance_usdt` ledger and must not be duplicated in `asset_balances` without a reviewed reason.

Orders, trades, reservations, and worker settlement must carry canonical IDs and resolve the exact ledger key from the same mapping. A reservation's canonical `asset_id` and legacy text key must be constrained to agree. The order's pair/base/quote tuple must agree with the reservation side and mapped key.

## 4. Backfill policy

Backfill is deterministic only when the existing legacy key has exactly one defensible canonical identity.

- **One-to-one, independently evidenced:** eligible for a reviewed mapping candidate.
- **No canonical match:** leave unmapped and quarantine; do not guess from ticker similarity.
- **Multiple canonical assets share one ticker:** quarantine the ticker group. Do not assign the same legacy key to both.
- **Existing balance or open reservation on an ambiguous ticker:** do not split, duplicate, rename, transfer, or reattribute funds automatically. Historical provenance and open-order/reservation ownership must be reconciled before any migration proposal.
- **Conflicting provider IDs or exchange symbols:** retain source evidence and require manual resolution; provider IDs are not assumed interchangeable.
- **USDT and other quote assets:** keep the existing wallet/ledger contract until each quote path is explicitly reviewed.

No current balances, reservations, trades, or transaction rows are to be changed as part of this design.

## 5. Disposable PostgreSQL proof required

Build a separate candidate fixture that begins with the exact authoritative Market/Limit setup and migration, then adds the mapping relation and candidate canonical functions. It must not use the prototype's generic `balances` table.

Seed at minimum:

- canonical asset A and B with the same display ticker;
- unique ledger keys A and B;
- one user with distinct balances for A and B in the existing `asset_balances` table;
- two canonical pair IDs and pair-keyed prices;
- reservations for each asset with the existing cumulative lifecycle fields.

Assertions must prove:

1. Market buy/sell A cannot change B's balance, and vice versa.
2. Limit buy/sell reserves the mapped asset key and cannot consume the other asset's funds.
3. Market available funds exclude outstanding reservations using the exact mapped key.
4. Four worker cycles fill no more than 25% of original order amount each, with per-fill trade and transaction journals.
5. Reservation consumed/released/status values remain cumulative and consistent.
6. Duplicate display ticker does not collide in orders, trades, prices, reservations, cancellation, or worker selection.
7. Ambiguous mapping is rejected before any balance or financial row changes.
8. Concurrent placement/cancel and worker/cancel races cannot double-spend or double-fill.

## 6. Explicit blockers before Production design

- Full inventory of all SQL functions, triggers, policies, views, jobs, Edge Functions, API serializers, and reporting consumers of `asset_balances.asset` and `order_reservations.asset`.
- Full Production schema/constraints/indexes/RLS/grants parity.
- Recovery and reconciliation of the 17 applied migration sources missing from the repository and the 20 ledger/name timestamp mismatches.
- Reviewed deterministic treatment of existing ambiguous balances and open reservations.
- Successful disposable PostgreSQL integration and CI on the exact candidate commit.

## 7. Release boundary

This document is not a migration specification ready for deployment. It does not authorize DDL, backfill, re-keying, balance/reservation movement, Production SQL, db push, RPC/worker/Cron changes, merge, rebase, deployment, APK/Pages publication, or infrastructure spend.
