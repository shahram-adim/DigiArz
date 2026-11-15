# DigiArz exact-decimal implementation checkpoint — 2026-11-15

Repository: \`shahram-adim/DigiArz\`
Branch: \`main\`
Supabase project inspected read-only: \`gfoaubfilhttnwjykaox\`

## Completed in this checkpoint

- Added \`src/decimal.js\`: dependency-free decimal-string arithmetic using BigInt coefficients/scales. It provides parsing, canonical string conversion, comparison, addition, subtraction, multiplication, division, and formatting. The helper does not use binary floating point for decimal operations.
- Added \`tests/decimal.test.js\`: 7 Node tests cover leading/trailing zeros, 18 fractional places, 16 integer digits, malformed/exponent/whitespace/negative inputs, arithmetic invariants, half-away-from-zero rounding, formatting, and string-valued RPC payloads.
- Added \`tests/index-syntax.test.js\`: checks parsing of inline JavaScript, all four trading RPC call paths, and the production compatibility gate.
- Added \`.github/workflows/exact-decimal-tests.yml\` to run \`node --test tests/*.test.js\` on pushes and pull requests to main.
- Integrated exact decimal strings into Market, Limit, Stop-Limit, and conditional-exit RPC calls. The amount/price values are canonical strings; the four order-entry functions no longer use \`Number\`, \`parseFloat\`, or \`toFixed\` for their submitted financial values.
- Changed Limit/Stop-Limit/conditional reservation arithmetic and price-trigger comparisons to exact decimal operations in the browser.
- Kept wallet USDT and asset-balance values as strings where used for financial checks and exact display; valuation/chart analytics remain non-authoritative and may still use Number.
- Added the decimal helper to the PWA shell cache and bumped the service-worker cache from v46 to v47 so offline shell startup can load it.
- Added a compatibility guard: user-entered order amounts/prices are currently limited to 8 fractional digits until the coordinated database migration is tested and released. The utility itself supports 18 digits; the browser must not send 18-place amounts into the current 8-place Production columns.

## Test results

Local execution of \`node --test tests/decimal.test.js\` passed all 7 tests (0 failures).

The new inline-script and RPC integration test is committed and wired into GitHub Actions, but no workflow result was available from the repository status endpoint at the time of this report. Do not describe the CI run or Android browser checks as passed yet.

## Numeric range proposal for the database migration

This proposal preserves the existing integer capacity while widening fractional scale:

| Column group | Current | Proposed target |
|---|---|---|
| \`orders.amount\`, \`orders.price\` | numeric(24,8) | numeric(34,18) |
| \`orders.filled_amount\`, \`orders.remaining_amount\` | unconstrained numeric | numeric(34,18) |
| \`trades.amount\`, \`trades.price\` | numeric(24,8) | numeric(34,18) |
| \`asset_balances.balance\` | numeric(28,8) | numeric(38,18) |
| \`order_reservations.reserved_amount/released_amount/consumed_amount\` | unconstrained numeric | numeric(38,18) |
| \`conditional_orders.amount/trigger_price/limit_price/executed_price\` | unconstrained numeric | numeric(38,18) |
| \`market_prices.price\` | numeric(38,18) | unchanged |
| \`wallets.balance_usdt\`, \`transactions.amount\` | numeric(24,8) | unchanged |

Rationale: the order/trade price columns currently allow 16 integer digits; numeric(34,18) preserves that range. Asset balances, reservation amounts, and conditional metadata are proposed at numeric(38,18), preserving up to 20 integer digits. The Market RPC currently caps order amount at 1,000,000. USDT settlement and wallet/transaction storage remain 8 decimal places. These targets still require isolated migration rehearsal and an explicit business-range sign-off before use.

## Read-only backend findings

- All 7 trading/worker functions were inspected as \`SECURITY DEFINER\` with an empty search_path.
- The authenticated user-facing RPCs are executable by \`authenticated\`; anonymous execution is denied. The Limit, Stop-Limit, and conditional worker functions are not executable by \`authenticated\`; worker execution is restricted to privileged roles.
- \`execute_demo_trade\` reads the authoritative market price from \`market_prices\` and rejects prices older than one minute. It rounds gross and fee to 8 places, but it does not enforce an 18-place amount/storage policy.
- \`place_limit_order\` and \`place_stop_limit_order\` validate positivity and pair enablement but do not yet enforce the new scale/range policy. Their buy-side reserve calculation needs a single 8-place quantization point.
- \`process_limit_orders\` fills up to 25% of the original amount per cycle. The quantity can exceed 8 decimal places while current trade and asset-balance columns round to 8. Quote gross/fee/net and reservation consumption also need one shared 8-place settlement value.
- Stop-Limit delegates to the Limit engine when triggered; conditional exits delegate to Market execution. These functions must be upgraded as one coordinated accounting unit.
- No numeric target column was found in an index. Existing constraints and reservation accounting checks must be preserved.
- Production snapshot during read-only inspection: 3 orders, 3 trades, 1 asset-balance row, 0 reservations, and 0 conditional-order rows. Table sizes ranged from 32–112 kB; small current size does not remove the need to assess lock and rewrite behavior.

## Explicit blockers / not done

- No disposable Supabase test project is connected. The only connected project is Production. Production must not be used for test fixtures, simulated fills, migration rehearsal, or destructive rollback experiments.
- No schema migration or RPC replacement migration has been committed or applied. No Production DDL/DML or financial-row mutation was performed in this checkpoint.
- RPC accounting tests (Market buy/sell, repeated partial fills, final residual fill, fee/reserve rounding boundaries, Stop-Limit handoff, cancellation/worker races) remain unrun.
- Browser integration syntax test and Android keyboard/viewport behavior remain unverified until CI and real-device testing complete.
- 18-place order input must remain disabled until the schema and RPC migrations have passed isolated tests and a separate release authorization is granted.

## Go / no-go

**NO-GO for 18-decimal Production release.** The browser-side exact-decimal foundation and safe compatibility gate are in place, but the database/RPC accounting migration cannot be safely completed or validated without an isolated database. The next safe step is to run the committed CI checks, then obtain an isolated Supabase/PostgreSQL test environment for schema/RPC rehearsal. Production rollout remains a separate approval gate.

## Verification update — 2026-11-15 22:36 (+03:30)

- [x] GitHub Actions workflow `Exact decimal tests` completed successfully for commit `d4b2b4737be3d3c1ca2d83928aa298e6261b2c46` (run `43749642323`, attempt 1).
- [x] The job step `Run exact decimal and browser integration tests` completed with conclusion `success`; this confirms the committed `node --test tests/*.test.js` suite, including the inline-script/RPC integration checks, passed in GitHub Actions.
- [x] GitHub Pages build and deployment for the same commit completed with conclusion `success` (run `43749642302`).
- [x] Re-read the Supabase migration history: latest applied migration remains `20261115143827_bound_stop_limit_invalid_reservation_retries`; no exact-decimal schema/RPC migration is applied.
- [x] Re-read Supabase development branches: none exist. No paid branch was created; no Production test data or schema was changed during this continuation.
- [ ] Backend precision migration and accounting RPC changes remain unimplemented and untested. Keep the 8-fractional-digit UI gate in place.
- [ ] 18-decimal Production release remains NO-GO until isolated database tests validate settlement quantization, partial/final fills, reservations, fees, Stop-Limit handoff, cancellation, and worker concurrency.
