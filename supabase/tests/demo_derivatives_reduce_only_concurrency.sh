#!/usr/bin/env bash
set -euo pipefail

: "${PGPASSWORD:?PGPASSWORD must be set for disposable PostgreSQL tests}"

PSQL=(psql -h localhost -U postgres -d digiarz_derivatives_schema_test -X -qAt -v ON_ERROR_STOP=1)
USER_ID="10000000-0000-0000-0000-000000000001"
ACCOUNT_ID="20000000-0000-0000-0000-000000000001"
REQUEST_A="a4000000-0000-0000-0000-000000000001"
REQUEST_B="a4000000-0000-0000-0000-000000000002"
OUT_A="$(mktemp)"
OUT_B="$(mktemp)"
trap 'rm -f "$OUT_A" "$OUT_B"' EXIT

place_sql() {
  local request_id="$1"
  printf "SET ROLE authenticated; SELECT set_config('request.jwt.claim.sub','%s',false); SELECT public.place_demo_reduce_only_limit_order('%s','BTCUSDT','long',0.7,105,'%s');" \
    "$USER_ID" "$ACCOUNT_ID" "$request_id"
}

PGAPPNAME=digiarz_reduce_only_race_a "${PSQL[@]}" -c "$(place_sql "$REQUEST_A")" >"$OUT_A" 2>&1 &
PID_A=$!
PGAPPNAME=digiarz_reduce_only_race_b "${PSQL[@]}" -c "$(place_sql "$REQUEST_B")" >"$OUT_B" 2>&1 &
PID_B=$!

if wait "$PID_A"; then RC_A=0; else RC_A=$?; fi
if wait "$PID_B"; then RC_B=0; else RC_B=$?; fi

SUCCESS_COUNT=$(( (RC_A == 0) + (RC_B == 0) ))
FAIL_COUNT=$(( (RC_A != 0) + (RC_B != 0) ))
if [[ "$SUCCESS_COUNT" -ne 1 || "$FAIL_COUNT" -ne 1 ]]; then
  echo "Expected exactly one placement success and one rejection."
  cat "$OUT_A" "$OUT_B"
  exit 1
fi

if ! grep -Fq 'Reduce-only quantity exceeds unreserved position quantity' "$OUT_A" "$OUT_B"; then
  echo "Losing placement failed for an unexpected reason."
  cat "$OUT_A" "$OUT_B"
  exit 1
fi

if [[ "$RC_A" -eq 0 ]]; then WINNER_OUT="$OUT_A"; WINNER_REQUEST="$REQUEST_A"; else WINNER_OUT="$OUT_B"; WINNER_REQUEST="$REQUEST_B"; fi
WINNER_ORDER="$(grep -Eo '[0-9a-f]{8}-[0-9a-f-]{27,}' "$WINNER_OUT" | tail -n 1)"
if [[ -z "$WINNER_ORDER" ]]; then
  echo "Could not extract successful order id."
  cat "$WINNER_OUT"
  exit 1
fi

EXPECTED="$( "${PSQL[@]}" -c "SELECT CASE WHEN count(*)=1 AND sum(remaining_quantity)=0.7 THEN 'ok' ELSE 'bad' END FROM public.demo_derivative_orders WHERE client_request_id IN ('$REQUEST_A','$REQUEST_B') AND status IN ('pending','partially_filled');" )"
if [[ "$EXPECTED" != "ok" ]]; then
  echo "Concurrent placement left an unexpected active reservation state: $EXPECTED"
  exit 1
fi

"${PSQL[@]}" -c "SET ROLE authenticated; SELECT set_config('request.jwt.claim.sub','$USER_ID',false); SELECT public.cancel_demo_reduce_only_order('$WINNER_ORDER');" >/dev/null

FINAL="$( "${PSQL[@]}" -c "SELECT CASE WHEN count(*)=0 THEN 'ok' ELSE 'bad' END FROM public.demo_derivative_orders WHERE client_request_id IN ('$REQUEST_A','$REQUEST_B') AND status IN ('pending','partially_filled');" )"
if [[ "$FINAL" != "ok" ]]; then
  echo "Winner cancellation did not release the Reduce-only reservation."
  exit 1
fi

echo "Concurrent Reduce-only placement serialized correctly; exactly one order reserved 0.7 BTC and cancellation released it."
