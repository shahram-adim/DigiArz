#!/usr/bin/env bash
set -euo pipefail
export PGPASSWORD="${PGPASSWORD:-postgres}"
DB_HOST="${PGHOST:-localhost}"
DB_USER="${PGUSER:-postgres}"
DB_NAME="${PGDATABASE:-digiarz_inactive_account_rpc_race_test}"
PSQL=(psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -X -q)
USER_ID='77777777-7777-4777-8777-777777777777'
PARENT_ID='77777777-7777-4777-8777-000000000001'
CHILD_ID='77777777-7777-4777-8777-000000000002'
COND_ID='77777777-7777-4777-8777-000000000003'

wait_for_sleep_query() {
  local app="$1"
  for attempt in {1..120}; do
    if "${PSQL[@]}" -At -c "SELECT 1 FROM pg_stat_activity WHERE application_name='$app' AND state='active' AND query LIKE '%pg_sleep(2)%'" | grep -q '^1$'; then
      return 0
    fi
    sleep 0.05
  done
  echo "Timed out waiting for child-fill transaction to hold its row lock."
  exit 1
}

"${PSQL[@]}" <<SQL
INSERT INTO public.profiles(id,is_active)
VALUES ('$USER_ID',true);
INSERT INTO public.orders(id,user_id,symbol,side,order_type,amount,price,status,filled_amount,remaining_amount)
VALUES
  ('$PARENT_ID','$USER_ID','BTCUSDT','buy','conditional',0.1,90,'triggered',0,0.1),
  ('$CHILD_ID','$USER_ID','BTCUSDT','buy','limit',0.1,90,'pending',0,0.1);
INSERT INTO public.conditional_orders(
  id,order_id,user_id,symbol,side,order_kind,trigger_price,limit_price,amount,status,execution_order_id
)
VALUES (
  '$COND_ID','$PARENT_ID','$USER_ID','BTCUSDT','buy','stop_limit',90,90,0.1,'triggered','$CHILD_ID'
);
SQL

# Simulate the matching Limit worker committing a child fill while Stop-Limit
# synchronization is reading the child. This test deliberately characterizes
# the captured Production lock scope: the Stop-Limit worker locks c and parent,
# but does not lock child in its first synchronization SELECT.
(PGAPPNAME=digiarz_child_fill_hold "${PSQL[@]}" <<SQL
BEGIN;
UPDATE public.orders
SET status='filled',filled_amount=amount,remaining_amount=0
WHERE id='$CHILD_ID';
SELECT pg_sleep(2);
COMMIT;
SQL
) >/tmp/digiarz-stop-child-fill-hold.log 2>&1 &
FILL_PID=$!
wait_for_sleep_query digiarz_child_fill_hold

"${PSQL[@]}" -c "SELECT public.process_stop_limit_orders();" >/tmp/digiarz-stop-worker-first-pass.log 2>&1
wait "$FILL_PID"

# The first pass read the child's pre-commit version, so parent/conditional
# remain triggered for one cycle even though the child is now filled.
"${PSQL[@]}" -c "DO \$\$ BEGIN
  IF (SELECT status FROM public.orders WHERE id='$CHILD_ID') IS DISTINCT FROM 'filled' THEN
    RAISE EXCEPTION 'child fill did not commit';
  END IF;
  IF (SELECT status FROM public.orders WHERE id='$PARENT_ID') IS DISTINCT FROM 'triggered' THEN
    RAISE EXCEPTION 'expected one-cycle parent lag; observed different parent state';
  END IF;
  IF (SELECT status FROM public.conditional_orders WHERE id='$COND_ID') IS DISTINCT FROM 'triggered' THEN
    RAISE EXCEPTION 'expected one-cycle conditional lag; observed different state';
  END IF;
END \$\$;"

# A subsequent worker cycle observes the committed child terminal state and
# converges both parent and conditional records.
"${PSQL[@]}" -c "SELECT public.process_stop_limit_orders();" >/tmp/digiarz-stop-worker-second-pass.log 2>&1
"${PSQL[@]}" -c "DO \$\$ BEGIN
  IF (SELECT status FROM public.orders WHERE id='$PARENT_ID') IS DISTINCT FROM 'filled' THEN
    RAISE EXCEPTION 'parent did not converge to child filled state';
  END IF;
  IF (SELECT status FROM public.conditional_orders WHERE id='$COND_ID') IS DISTINCT FROM 'filled' THEN
    RAISE EXCEPTION 'conditional did not converge to child filled state';
  END IF;
END \$\$;"
echo "PASS: captured Stop-Limit worker exhibits one-cycle child/parent sync lag under concurrent child fill, then converges on the next pass."
