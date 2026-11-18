#!/usr/bin/env bash
set -euo pipefail

: "${PGPASSWORD:?PGPASSWORD must be set for disposable PostgreSQL tests}"

PSQL=(psql -h localhost -U postgres -d digiarz_derivatives_schema_test -X -qAt -v ON_ERROR_STOP=1)
USER_ID="10000000-0000-0000-0000-000000000002"
ACCOUNT_ID="20000000-0000-0000-0000-000000000002"
POSITION_ID="4e000000-0000-0000-0000-000000000001"
ORDER_REQUEST="a5000000-0000-0000-0000-000000000001"
OLDER_EXTRA_REQUEST="a5000000-0000-0000-0000-000000000004"
NEWER_EXTRA_REQUEST="a5000000-0000-0000-0000-000000000005"
FILL_A="a5000000-0000-0000-0000-000000000002"
FILL_B="a5000000-0000-0000-0000-000000000003"
OUT_A="$(mktemp)"
OUT_B="$(mktemp)"
trap 'rm -f "$OUT_A" "$OUT_B"' EXIT

# Dedicated ETHUSDT Cross position avoids altering the BTCUSDT fixture used
# by the sequential PnL/margin accounting integration test.
"${PSQL[@]}" -c "INSERT INTO public.demo_derivative_positions(
  id,user_id,account_id,product_type,symbol,position_side,margin_mode,
  leverage,quantity,entry_price,isolated_margin_usdt
) VALUES (
  '$POSITION_ID','$USER_ID','$ACCOUNT_ID','futures','ETHUSDT','long',
  'cross',5,1,100,0
);" >/dev/null

ORDER_ID="$( "${PSQL[@]}" -c "SET ROLE authenticated; SELECT set_config('request.jwt.claim.sub','$USER_ID',false); SELECT public.place_demo_reduce_only_limit_order('$ACCOUNT_ID','ETHUSDT','long',0.6,100,'$ORDER_REQUEST');" | tail -n 1 )"
if [[ ! "$ORDER_ID" =~ ^[0-9a-f]{8}-[0-9a-f-]{27,}$ ]]; then
  echo "Could not create or parse the Reduce-only order id: $ORDER_ID"
  exit 1
fi

fill_sql() {
  local fill_id="$1"
  printf "SET ROLE service_role; SELECT public.apply_demo_reduce_only_limit_fill('%s','%s',0.4,100,0);" \
    "$ORDER_ID" "$fill_id"
}

PGAPPNAME=digiarz_fill_race_a "${PSQL[@]}" -c "$(fill_sql "$FILL_A")" >"$OUT_A" 2>&1 &
PID_A=$!
PGAPPNAME=digiarz_fill_race_b "${PSQL[@]}" -c "$(fill_sql "$FILL_B")" >"$OUT_B" 2>&1 &
PID_B=$!

if wait "$PID_A"; then RC_A=0; else RC_A=$?; fi
if wait "$PID_B"; then RC_B=0; else RC_B=$?; fi

SUCCESS_COUNT=$(( (RC_A == 0) + (RC_B == 0) ))
FAIL_COUNT=$(( (RC_A != 0) + (RC_B != 0) ))
if [[ "$SUCCESS_COUNT" -ne 1 || "$FAIL_COUNT" -ne 1 ]]; then
  echo "Expected exactly one 0.4 ETH fill to succeed and the competing fill to reject."
  cat "$OUT_A" "$OUT_B"
  exit 1
fi

if ! grep -Fq 'Fill quantity exceeds order remaining quantity' "$OUT_A" "$OUT_B"; then
  echo "Losing fill failed for an unexpected reason."
  cat "$OUT_A" "$OUT_B"
  exit 1
fi

STATE="$( "${PSQL[@]}" -c "SELECT CASE
  WHEN o.filled_quantity=0.4
   AND o.remaining_quantity=0.2
   AND o.status='partially_filled'
   AND p.quantity=0.6
   AND p.status='open'
   AND (SELECT count(*) FROM public.demo_derivative_fills f WHERE f.order_id=o.id)=1
  THEN 'ok' ELSE 'bad' END
  FROM public.demo_derivative_orders o
  JOIN public.demo_derivative_positions p ON p.id='$POSITION_ID'
  WHERE o.id='$ORDER_ID';" )"
if [[ "$STATE" != "ok" ]]; then
  echo "Concurrent fill race left inconsistent order/position state: $STATE"
  exit 1
fi

echo "Concurrent fills serialized correctly: one 0.4 ETH fill committed; competing fill rejected; order retains 0.2 ETH and position retains 0.6 ETH; two additional 0.2 ETH reservations remain active."
