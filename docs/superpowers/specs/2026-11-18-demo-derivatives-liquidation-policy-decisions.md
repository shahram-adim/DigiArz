# Demo Futures liquidation policy decision worksheet

Date: 2026-11-18  
Status: unapproved worksheet; deliberately contains no operational values  
Scope: demo USDT-settled Futures only. No Production deployment or execution authorization.

This worksheet turns the open design gates into explicit decisions. Blank fields are intentional. Test fixtures must never be copied into these fields as policy values. Until every required item is approved, liquidation execution SQL/RPC/worker and liquidation UI remain out of scope.

## 1. Liquidation fee / surcharge

- Ordinary taker close fee: resolved from the already versioned Futures fee schedule.
- Separate liquidation surcharge rate: **NOT DECIDED**
- Per-event surcharge cap (USDT or notional-based): **NOT DECIDED**
- Recipient account / chart-of-accounts destination: **NOT DECIDED**
- Rounding rule: candidate is upward rounding to supported USDT precision; **approval required**
- Insufficient-collateral treatment: **NOT DECIDED**
- Policy version activation, retirement and grandfathering: **NOT DECIDED**

Decision must specify rate units, cap semantics, fee base (actual executed notional), destination, rounding and the exact version pinned to each event.

## 2. Execution price and slippage

- Trusted simulated execution evidence provider/contract: **NOT DECIDED**
- Maximum adverse slippage: **NOT DECIDED**
- Measurement reference and direction for Long/Short: **NOT DECIDED**
- Quote/depth freshness and minimum depth: **NOT DECIDED**
- Partial-fill behavior when depth is insufficient: **NOT DECIDED**
- Fail-closed behavior when evidence is missing/stale: required; no mark-price fallback.
- Policy version and audit fields: **NOT DECIDED**

Mark/index price remains a risk trigger only. It is not an execution price. No execution may proceed without trusted evidence and an approved bound.

## 3. Maintenance safety target and reduction strategy

- Post-action maintenance buffer / target margin ratio: **NOT DECIDED**
- Buffer formula and whether it is absolute or tier-relative: **NOT DECIDED**
- Attempt partial reduction before full close: **NOT DECIDED**
- Search/step algorithm and maximum number of sizing iterations: **NOT DECIDED**
- Behavior if no partial size can restore the target: **NOT DECIDED**
- Conservative quantity rounding and never exceeding open/unreserved quantity: required.

Approval must include Isolated and Cross examples at tier boundaries, fee/slippage effects, and cases where partial reduction worsens or fails to improve the risk ratio.

## 4. Cross position priority and sequencing

Choose and approve one deterministic priority policy; none is selected:
- Lowest liquidity / highest estimated execution cost first.
- Highest maintenance-margin contribution first.
- Highest risk contribution / lowest post-close account improvement first.
- Fixed allowlisted asset priority.
- Another explicitly specified deterministic rule.

Additional decisions:
- Tie-breaker: **NOT DECIDED**
- Sequential re-evaluation after each reduction vs precomputed all-at-once plan: **NOT DECIDED**
- Maximum positions per plan / bounded work: **NOT DECIDED**
- Treatment of stale or unpriceable positions: fail closed for the affected account; details **NOT DECIDED**

The order must not depend on database row order, browser input or nondeterministic query plans.

## 5. Insurance funding and payout

- Initial virtual seed amount and funding source: **NOT DECIDED**
- Who may authorize replenishment and under what audit event: **NOT DECIDED**
- Maximum payout per liquidation and per account/time window: **NOT DECIDED**
- Minimum reserve / payout stop threshold: **NOT DECIDED**
- Replenishment idempotency and policy version: **NOT DECIDED**

The system insurance ledger remains private, append-only and separate from user wallets. No seed amount, payout RPC or replenishment worker is authorized by this worksheet.

## 6. Residual deficit and recovery

- Recovery source(s): **NOT DECIDED**
- Recovery cap and ordering: **NOT DECIDED**
- Recovery expiry / write-off policy: **NOT DECIDED**
- Whether deficit is only an accounting exposure or has any user-facing consequence: **NOT DECIDED**
- ADL / socialized loss: **OFF; requires a separate explicit policy and approval**
- No implicit negative user balance and no silent transfer of loss to other demo users.

Insurance application and later recovery remain distinct event types; an insurance draw is not itself recovery.

## 7. Required approval record

Before any execution implementation, record:
- Approver and approval timestamp.
- Policy document version and immutable policy hash.
- Effective-from timestamp and retirement/supersession rules.
- Explicit approval for Isolated scope.
- Explicit approval for Cross scope.
- Explicit approval for fee, slippage, buffer, priority, insurance and deficit/recovery sections.
- Confirmation that the full disposable PostgreSQL test matrix and two-session races pass.
- Separate authorization for any later Production deployment (not granted here).

## 8. Current safe boundary

Until all decisions above are filled and explicitly approved:
- Keep liquidation execution RPCs, workers, triggers and UI unimplemented/disabled.
- Continue only non-executing design, accounting tests and trusted external-reduction work already scoped.
- Keep all SQL drafts in the feature branch and test only against disposable PostgreSQL.
- Do not alter Supabase Production.
