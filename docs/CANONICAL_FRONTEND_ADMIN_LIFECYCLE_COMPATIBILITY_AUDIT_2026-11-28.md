# Canonical identity — frontend and administrative lifecycle compatibility audit — 2026-11-28

**Status:** source evidence and risk analysis only. No application or database code changed.

## 1. New source evidence

The following checked-in client and read-only Production snapshots were inspected on the Draft branch:

- `index.html` (blob `33f4acf028b1cdf799a9b55643ef9d9b2bd0ac5b`)
- `src/market-holdings.js` (blob `c778aa7e12a011b38d4ec09b9e78a9662cd426a9`)
- `get_my_order_reservations(uuid[])` migration (blob `c105e6a900c901057ca21100eb62e55137aff20c`)
- `cancel_conditional_exit_order(uuid)` Production snapshot (blob `b623fc646141da378224527fdbcd2f91431c1ef3`)
- `cancel_stop_limit_order(uuid)` Production snapshot (blob `5a3658ea57467459b4a2d5c4b14e914ed9f8c257`)
- `admin_disable_market_pair(text,text)` Production snapshot (blob `059aef1da555554263c2b8c3ca91fa24528e350c`)

Production snapshots identify themselves as read-only pg_catalog captures and fixture-only SQL. Their recorded metadata says owner postgres, SECURITY DEFINER, empty search_path, authenticated/service_role execution as noted in each snapshot. They are historical snapshots, not proof of the current live Production hash on this date.

## 2. Client contracts are ticker/text-key dependent

### Spot and Limit entry
- Market execution RPC is called with `p_symbol`, not `pair_id`.
- Limit placement is called with `p_symbol`.
- Conditional and Stop-Limit placement are called with `p_symbol`.
- Trade form locates a market row by `symbol` and calculates sellable balance by comparing `assetRows[].asset` to the ticker-derived base symbol.

### Active orders and reservation UI
- Conditional/Stop-Limit/open Limit views select `symbol` and join price rows by `market_prices.symbol`.
- Reservation RPC returns `asset text`, not canonical `asset_id` or `pair_id`.
- UI labels reservation balances using that returned text key.
- These are not cosmetic-only fields: they drive price lookup, balance selection, and user-visible reservation interpretation.

### Holdings and market filters
- `src/market-holdings.js` indexes balances by uppercased `asset`.
- It derives base asset by stripping `USDT` or `IRT` from the display symbol.
- Dashboard "mine" filtering similarly compares ticker-derived base symbol to `assetRows[].asset`.

**Conclusion:** A backend-only re-key would break or misattribute holdings, trade sizing, market filters, active-order price freshness and reservation display. The UI/API contract must carry canonical asset/pair IDs while retaining ticker/name solely as display metadata.

## 3. Administrative pair-disable collision risk

The captured `admin_disable_market_pair(text,text)` source selects one pair by `base_coingecko_id`, but its cleanup statements operate on orders using:

- `orders.symbol = v_pair.pair_symbol`;
- reservations joined to those symbol-selected orders;
- conditional orders joined to those symbol-selected orders.

It then disables the pair by `pair_symbol`.

This creates a concrete collision hazard if two distinct canonical pairs share a display symbol: disabling one selected pair can cancel/release orders belonging to another pair with the same symbol. The current curated ticker uniqueness check may reduce today's exposure but cannot be a canonical identity guarantee and conflicts with the requirement that duplicate display tickers remain distinct.

**Required behavior:** admin disable must select by exact `pair_id` (or immutable canonical pair identity), and every cancellation/reservation release must be constrained to that same pair identity. Add a disposable two-pair/same-symbol regression test proving the unrelated pair's orders and reservations remain untouched.

## 4. Reservation read/cancel lifecycle

- `get_my_order_reservations` is owner-scoped and bounds input to 1–100 order IDs; preserve both controls.
- It returns legacy `asset` text and must be extended to canonical `asset_id` and `pair_id` once the authoritative relation exists.
- Conditional cancellation locks the conditional order and reservation, checks reservation accounting, releases remaining amount, then changes order and conditional state.
- Stop-Limit cancellation locks parent/conditional and may delegate triggered child cancellation to `cancel_limit_order`; parent/child canonical identity must be checked before delegating.
- Do not simplify or replace the existing cumulative reservation accounting, owner checks, active-account checks where present, or lock ordering while adding canonical IDs.

## 5. Candidate implementation sequence

1. Finish a read-only inventory of current Production definitions and all client/API consumers; obtain live fingerprints before claiming current parity.
2. Design additive pair/asset ID fields and mapping relation in a disposable fixture only.
3. Adapt read APIs first in the fixture to return canonical IDs plus display metadata; assert old owner/bounds behavior.
4. Adapt UI models and filters to key by canonical IDs; preserve display symbols as labels and ensure duplicate symbols can coexist in lists, selection, chart routing, and order history.
5. Adapt all placement, worker, cancellation, account deactivation and admin pair-disable paths to the same pair identity.
6. Add a two-pair/same-symbol matrix for admin disable, Market/Limit/conditional/Stop-Limit, reservation lookup, cancellation races, holdings, and UI selectors.
7. Execute tests on exact candidate commit in disposable PostgreSQL and CI; only then prepare a reviewed non-executable Production migration proposal.

## 6. Explicit limits

This audit does not establish that the historical snapshots still equal current Production. No live Production metadata query was run in this stage. No Production rows, balances, orders, reservations, schema, RPCs, grants, policies, triggers, jobs, or Edge Functions were changed. No UI or SQL source was modified. No test was executed. No merge, rebase, db push, deployment, APK/Pages publication, or cost was incurred.
