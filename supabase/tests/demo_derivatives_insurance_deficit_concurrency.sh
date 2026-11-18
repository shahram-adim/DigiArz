#!/usr/bin/env bash
set -euo pipefail
: "${PGPASSWORD:?PGPASSWORD must be set for disposable PostgreSQL tests}"
PSQL=(psql -h localhost -U postgres -d digiarz_derivatives_schema_test -X -qAt -v ON_ERROR_STOP=1)
A="$(mktemp)"; B="$(mktemp)"
trap 'rm -f "$A" "$B"' EXIT

payout() {
  local tx="$1" ref="$2" key="$3"
  printf "BEGIN; INSERT INTO private.demo_platform_ledger_transactions(id,idempotency_key,payload_hash,event_type,event_reference,policy_version) VALUES ('%s','%s',repeat('a',64),'insurance_payout','%s','race-v1'); INSERT INTO private.demo_platform_ledger_entries(transaction_id,account_code,debit_amount) VALUES ('%s','liquidation_loss_expense_usdt',40); INSERT INTO private.demo_platform_ledger_entries(transaction_id,account_code,credit_amount) VALUES ('%s','insurance_cash_usdt',40); COMMIT;" "$tx" "$key" "$ref" "$tx" "$tx"
}
SQL_A="$(payout a1000000-0000-0000-0000-000000000101 a2000000-0000-0000-0000-000000000101 race-payout-a)"
SQL_B="$(payout a1000000-0000-0000-0000-000000000102 a2000000-0000-0000-0000-000000000102 race-payout-b)"
PGAPPNAME=insurance_payout_a "${PSQL[@]}" -c "$SQL_A" >"$A" 2>&1 & PA=$!
PGAPPNAME=insurance_payout_b "${PSQL[@]}" -c "$SQL_B" >"$B" 2>&1 & PB=$!
if wait "$PA"; then RA=0; else RA=$?; fi
if wait "$PB"; then RB=0; else RB=$?; fi
if [[ $(( (RA == 0) + (RB == 0) )) -ne 1 ]] || ! grep -Fq 'Insurance payout exceeds available platform insurance cash' "$A" "$B"; then
 echo "Concurrent payouts did not serialize correctly."; cat "$A" "$B"; exit 1
fi
[[ "$("${PSQL[@]}" -c "SELECT CASE WHEN (SELECT insurance_cash_usdt FROM private.demo_platform_insurance_balance)=20 AND (SELECT count(*) FROM private.demo_platform_ledger_transactions WHERE id IN ('a1000000-0000-0000-0000-000000000101','a1000000-0000-0000-0000-000000000102'))=1 THEN 'ok' ELSE 'bad' END;")" == "ok" ]]

SOURCE=a2000000-0000-0000-0000-000000000110
"${PSQL[@]}" -c "INSERT INTO private.demo_derivative_deficit_events(id,idempotency_key,payload_hash,source_liquidation_event_id,account_id,event_type,amount_usdt) VALUES ('a3000000-0000-0000-0000-000000000110','race-open',repeat('b',64),'$SOURCE','a4000000-0000-0000-0000-000000000110','deficit_opened',10);" >/dev/null
recovery() {
 local tx="$1" ref="$2" ev="$3" key="$4"
 printf "BEGIN; INSERT INTO private.demo_platform_ledger_transactions(id,idempotency_key,payload_hash,event_type,event_reference,policy_version) VALUES ('%s','%s',repeat('c',64),'insurance_recovery','%s','race-v1'); INSERT INTO private.demo_platform_ledger_entries(transaction_id,account_code,debit_amount) VALUES ('%s','insurance_cash_usdt',7); INSERT INTO private.demo_platform_ledger_entries(transaction_id,account_code,credit_amount) VALUES ('%s','insurance_recovery_income_usdt',7); INSERT INTO private.demo_derivative_deficit_events(id,idempotency_key,payload_hash,source_liquidation_event_id,account_id,event_type,amount_usdt,platform_ledger_transaction_id) VALUES ('%s','%s',repeat('d',64),'%s','a4000000-0000-0000-0000-000000000110','recovery_received',7,'%s'); COMMIT;" "$tx" "$key" "$ref" "$tx" "$tx" "$ev" "$key-event" "$SOURCE" "$tx"
}
RA_SQL="$(recovery a1000000-0000-0000-0000-000000000111 a2000000-0000-0000-0000-000000000111 a3000000-0000-0000-0000-000000000111 race-recovery-a)"
RB_SQL="$(recovery a1000000-0000-0000-0000-000000000112 a2000000-0000-0000-0000-000000000112 a3000000-0000-0000-0000-000000000112 race-recovery-b)"
PGAPPNAME=deficit_recovery_a "${PSQL[@]}" -c "$RA_SQL" >"$A" 2>&1 & PA=$!
PGAPPNAME=deficit_recovery_b "${PSQL[@]}" -c "$RB_SQL" >"$B" 2>&1 & PB=$!
if wait "$PA"; then RA=0; else RA=$?; fi
if wait "$PB"; then RB=0; else RB=$?; fi
if [[ $(( (RA == 0) + (RB == 0) )) -ne 1 ]] || ! grep -Fq 'Insurance and recovery events exceed the opened deficit' "$A" "$B"; then
 echo "Concurrent recoveries did not prevent over-recovery."; cat "$A" "$B"; exit 1
fi
[[ "$("${PSQL[@]}" -c "SELECT CASE WHEN (SELECT remaining_deficit_usdt FROM private.demo_derivative_deficit_exposure WHERE source_liquidation_event_id='$SOURCE')=3 AND (SELECT count(*) FROM private.demo_derivative_deficit_events WHERE source_liquidation_event_id='$SOURCE' AND event_type='recovery_received')=1 AND (SELECT count(*) FROM private.demo_platform_ledger_transactions WHERE id IN ('a1000000-0000-0000-0000-000000000111','a1000000-0000-0000-0000-000000000112'))=1 THEN 'ok' ELSE 'bad' END;")" == "ok" ]]


# Inject a failure after both accounting journals have been written but before
# commit. The platform ledger and deficit exposure must roll back together.
FAULT_SOURCE=a2000000-0000-0000-0000-000000000120
FAULT_TX=a1000000-0000-0000-0000-000000000120
"${PSQL[@]}" -c "INSERT INTO private.demo_derivative_deficit_events(
 id,idempotency_key,payload_hash,source_liquidation_event_id,account_id,event_type,amount_usdt
) VALUES (
 'a3000000-0000-0000-0000-000000000120','fault-open',repeat('e',64),
 '$FAULT_SOURCE','a4000000-0000-0000-0000-000000000120','deficit_opened',5
);" >/dev/null
FAULT_SQL="$(cat <<SQL
BEGIN;
INSERT INTO private.demo_platform_ledger_transactions(
 id,idempotency_key,payload_hash,event_type,event_reference,policy_version
) VALUES (
 '$FAULT_TX','fault-recovery',repeat('f',64),'insurance_recovery',
 'a2000000-0000-0000-0000-000000000120','fault-test-v1'
);
INSERT INTO private.demo_platform_ledger_entries(transaction_id,account_code,debit_amount)
VALUES ('$FAULT_TX','insurance_cash_usdt',2);
INSERT INTO private.demo_platform_ledger_entries(transaction_id,account_code,credit_amount)
VALUES ('$FAULT_TX','insurance_recovery_income_usdt',2);
INSERT INTO private.demo_derivative_deficit_events(
 id,idempotency_key,payload_hash,source_liquidation_event_id,account_id,event_type,amount_usdt,platform_ledger_transaction_id
) VALUES (
 'a3000000-0000-0000-0000-000000000121','fault-recovery-event',repeat('1',64),
 '$FAULT_SOURCE','a4000000-0000-0000-0000-000000000120','recovery_received',2,'$FAULT_TX'
);
SELECT 1/0;
COMMIT;
SQL
)"
if "${PSQL[@]}" -c "$FAULT_SQL" >"$A" 2>&1; then
 echo "Expected injected failure before commit, but transaction succeeded."
 exit 1
fi
ROLLBACK_STATE="$("${PSQL[@]}" -c "SELECT CASE
 WHEN NOT EXISTS (SELECT 1 FROM private.demo_platform_ledger_transactions WHERE id='$FAULT_TX')
  AND NOT EXISTS (SELECT 1 FROM private.demo_platform_ledger_entries WHERE transaction_id='$FAULT_TX')
  AND (SELECT remaining_deficit_usdt FROM private.demo_derivative_deficit_exposure
       WHERE source_liquidation_event_id='$FAULT_SOURCE')=5
 THEN 'ok' ELSE 'bad' END;")"
if [[ "$ROLLBACK_STATE" != "ok" ]]; then
 echo "Injected fault left a partial ledger or deficit journal."
 exit 1
fi

echo "Atomic rollback fault injection passed: both journals remained unchanged after a pre-commit failure."

echo "Insurance/deficit two-session races passed: one affordable payout and one recovery won; overdraw and over-recovery were rejected atomically."
