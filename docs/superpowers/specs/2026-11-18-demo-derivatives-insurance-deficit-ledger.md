# Demo Futures platform insurance ledger and deficit journal — accounting design

Date: 2026-11-18  
Status: accounting design draft; schema/RPC execution not authorized  
Scope: USDT-settled demo Futures only. No Margin Spot, no Production changes.

## 1. Existing ledger boundary discovered

The current user derivatives ledger is deliberately user-owned:
- `demo_derivative_ledger_transactions.user_id` references `auth.users`.
- `demo_derivative_ledger_entries.user_id` is part of its transaction foreign key.
- The user ledger is balanced per asset and derives Futures cash from the `futures_cash` bucket.
- `system_clearing` is currently a balancing bucket inside a user's ledger; it is not a platform-owned insurance account and must not be repurposed as one.
- The existing external-reduction and Reduce-only fill paths post realized PnL, fee and isolated-margin movements through this user ledger.

Therefore a platform insurance fund must not be represented by a fabricated user UUID, a negative user balance, or a mutable balance column in the user ledger.

## 2. Separate platform ledger

Create a physically separate platform ledger in the non-exposed `private` schema, with no `auth.users` foreign key and no user identity column.

Proposed immutable objects:
1. `private.demo_platform_ledger_accounts`: stable platform account identities and account class; initial chart limited to:
   - `insurance_cash_usdt` — virtual asset held by the platform insurance pool;
   - `insurance_fund_equity_usdt` — accumulated insurance-fund capital;
   - `liquidation_loss_expense_usdt` — platform loss recognized when the fund absorbs a covered loss;
   - `insurance_recovery_income_usdt` — later recovery credited to the platform.
2. `private.demo_platform_ledger_transactions`: immutable transaction header, unique idempotency key, canonical payload hash, event type, event reference, policy/version metadata and transaction timestamp.
3. `private.demo_platform_ledger_entries`: append-only USDT debit/credit lines, FK to the transaction and account; no direct balance field.

All transactions must balance per asset (sum debits = sum credits), contain at least two non-zero lines, and become immutable at commit. Corrections use compensating transactions. No client role receives schema usage, table access or function execution. A trusted service function is the only future write path.

### Posting conventions

Use conventional debit/credit accounting in this platform ledger:
- Fund seed/replenishment: Dr `insurance_cash_usdt`; Cr `insurance_fund_equity_usdt`.
- Insurance payout: Dr `liquidation_loss_expense_usdt`; Cr `insurance_cash_usdt`.
- Later recovery into the fund: Dr `insurance_cash_usdt`; Cr `insurance_recovery_income_usdt`.

The spendable insurance balance is derived as the debit-normal balance of `insurance_cash_usdt` (total debits less credits), never stored independently. It must not be inferred from `system_clearing` or from a user's Futures cash.

## 3. User-ledger / platform-ledger reconciliation

A liquidation settlement spans two separate books but one PostgreSQL transaction:
- User ledger records only the user's actual collateral/cash/PnL/fees movement and its existing `system_clearing` counterpart.
- Platform ledger records only actual insurance-fund seed, payout or recovery movements.
- The liquidation event is the shared immutable correlation key and carries both ledger transaction IDs where applicable.
- A deferred consistency check must ensure the insurance payout in the platform ledger equals the insurance amount recorded by the liquidation event. The user's residual loss must never be hidden by changing a user balance below zero.

No cross-ledger “balanced” claim is made by simply summing the two ledgers: they are separate books with different ownership boundaries. Reconciliation is by event ID, asset, and exact amount.

## 4. Deficit journal is a separate memorandum record

A residual deficit is not automatically a user debt, platform payable, or socialized loss. Until a recovery/ADL policy is approved, record it as an immutable memorandum exposure, not as a cash balance or a liability posted to the insurance fund.

Proposed append-only `private.demo_derivative_deficit_events`:
- unique event ID and idempotency key;
- account/position/risk-event correlation IDs (no user UUID required for ownership);
- asset fixed to USDT for this scope;
- event kind such as `deficit_opened`, `insurance_applied`, `recovery_received`, `deficit_adjusted`;
- exact amount and source liquidation event;
- immutable payload hash and timestamp;
- optional platform-ledger transaction reference only when a real fund movement occurs.

The deficit exposure is derived from immutable events: opening deficit plus adjustments, less confirmed recoveries. Insurance application is separately linked and must not be counted as recovery. A zero/negative result is not silently clamped; invalid event ordering or over-recovery is rejected.

This journal does not authorize collecting from the user, changing their wallet, allocating losses to other users, or enabling ADL. Those remain separate policy gates.

## 5. Atomicity, idempotency and locking

- Acquire the derivatives account `FOR UPDATE` lock first, then affected orders/positions in deterministic order, matching all existing derivatives writers.
- A stable liquidation event ID maps to one canonical payload hash. Same-key/same-payload retry returns the original outcome; changed payload is rejected.
- User ledger, platform ledger, deficit memorandum events, position/order changes, reservation reconciliation and risk event must commit or roll back together.
- The platform ledger and deficit journal reject UPDATE/DELETE and late append to a finalized transaction.
- Every monetary field is PostgreSQL `numeric`; no floating-point arithmetic or client-supplied amount is accepted.

## 6. Required tests before any liquidation RPC

1. Empty fund, exact full coverage, partial coverage and zero coverage.
2. Payout never exceeds derived insurance cash; concurrent payouts cannot overspend the fund.
3. Seed, replenishment, payout and recovery balance per asset and derive the expected balance from entries.
4. Deficit opened, partially/fully covered by insurance, and later recovered; insurance application is not double-counted as recovery.
5. Duplicate event retry and same idempotency key with changed payload.
6. Attempted UPDATE/DELETE/late append and unbalanced transaction are rejected.
7. Crash/fault injection between user-ledger, platform-ledger, deficit-journal and risk-event writes proves full rollback.
8. Two-session payout race proves no negative insurance cash.
9. Client roles cannot read/write private system records or invoke trusted posting functions.
10. Cross-ledger reconciliation compares exact event-linked amounts and rejects missing/orphan counterpart references.

## 7. Explicitly unresolved policy gates

This design intentionally does not choose:
- initial insurance seed amount, funding source, replenishment authority or maximum payout;
- whether residual deficit is merely memorandum indefinitely or later recoverable, and from whom;
- recovery priority, caps and accounting treatment;
- liquidation surcharge rate/cap/recipient;
- execution slippage bound and trusted evidence contract;
- target maintenance buffer, partial sizing and Cross position priority.

No operational values may be inferred from test fixtures. Until those policies are approved, only the data model and isolated accounting tests may be built; liquidation execution, UI and automatic workers remain disabled.
