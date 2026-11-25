# Live catalog comparison for dynamic fee rewrites — 2026-11-25

## Scope and method

Read-only Production catalog inspection on Supabase project `gfoaubfilhttnwjykaox`, PostgreSQL `17.11.0.018`. The queries selected `pg_get_functiondef`, owner, language, volatility, SECURITY mode, parallel-safety, function settings, ACLs, and deterministic PostgreSQL MD5/byte-length fingerprints for the three affected signatures and the fee helper.

No function was called. No DDL/DML, migration, ACL, policy, Cron, order, wallet, reservation, or other Production state was changed.

## Current live function fingerprints

| Signature | Definition MD5 | Bytes | Owner | Security | search_path | EXECUTE ACL |
|---|---|---:|---|---|---|---|
| `execute_demo_trade(text,text,numeric,numeric)` | `4289e358b0c7293fc33f86c2511486d7` | 5,370 | postgres | SECURITY DEFINER | empty | postgres, service_role, authenticated |
| `place_limit_order(text,text,numeric,numeric)` | `3eab167c47bf8ff2e1705b9f243380ec` | 4,572 | postgres | SECURITY DEFINER | empty | postgres, authenticated, service_role |
| `process_limit_orders()` | `00ab429596fb99392666632967cde9c0` | 10,070 | postgres | SECURITY DEFINER | empty | postgres, service_role |
| `get_demo_trading_fee_rate(text,text)` | `546d80d7105228ed97da26c5ed0c7b7f` | 772 | postgres | SECURITY DEFINER | empty | postgres, service_role, authenticated |

All three trading functions are PL/pgSQL, volatile, parallel-unsafe, owned by postgres, and configured with an empty search_path. The live ACLs are recorded above as returned by `pg_proc.proacl`; this report does not alter them.

## Current body observations

### Market entry point

- Exactly one `get_demo_trading_fee_rate` call was counted in the current definition.
- The old declaration `v_fee_rate numeric := 0.001;` is absent.
- The current body obtains the USDT taker rate immediately before calculating gross and fee.
- The original gross-calculation anchor remains present.
- The live body computes `v_fee := round(v_gross * v_fee_rate, 8)`.

### Limit placement

- Exactly one fee-helper call was counted.
- The old hard-coded 1.001 reservation expression is absent.
- The live buy-side reservation uses `p_amount * p_limit_price * (1 + v_fee_rate)`.
- The current response includes the selected `fee_rate` and the reservation amount.

### Limit worker

- Exactly one fee-helper call was counted.
- The old hard-coded `v_fee := v_gross * 0.001;` anchor is absent.
- The live worker computes the maker fee from `v_fee_rate`.
- The live buy-side remaining reservation uses `v_new_remaining * v_order.price * (1 + v_fee_rate)`.
- The live worker returns the `fee_rate` field in its summary JSON.

These observations show that the current live definitions contain the intended dynamic fee logic at the inspected call sites. They do **not** prove that every historical replacement anchor was unique or present at the moment the migration ran, nor do they prove behavioral equivalence for all edge cases.

## Historical evidence limitation

The recovered Migration body is byte-verified against the Production migration ledger, but it contains only the transformation logic, not the complete three function definitions immediately before the migration. The current catalog is a post-migration snapshot and may include later edits. A search of available repository commit messages for the three function names did not locate a preserved pre-migration source snapshot.

Therefore:
- Do not label the current live functions as defective based solely on the weak migration guards.
- Do retain the migration's lack of exact anchor-count and post-transform assertions as a historical migration-quality finding.
- Do not claim exact before/after semantic parity until the true pre-migration definitions are recovered from an authoritative historical backup, dump, or audit artifact.
- Do not replay the migration or rerun its DO blocks.

## Updated decision

**Current live-state inspection: no obvious missing fee-helper insertion or hard-coded fee/reservation anchor was observed in the three current definitions.**

**Historical rewrite proof: still BLOCKED** because the exact pre-migration definitions are unavailable. The next safe action is to search existing retained backups/audit artifacts for the pre-2026-11-13 function definitions, without creating a new paid backup or restoring anything. If no authoritative source exists, mark the historical before-state as unrecoverable and rely on isolated tests of the current live behavior plus the original source-level guard review.

No Production mutation, Migration execution, Cron change, order-engine interruption, merge, deployment, or cost was incurred.
