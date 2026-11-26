-- READ-ONLY live preflight for the exact-decimal rollout.
-- Run immediately before the approved migration. This file contains SELECTs only.

SELECT 'orders' AS table_name,count(*) AS row_count FROM public.orders
UNION ALL SELECT 'trades',count(*) FROM public.trades
UNION ALL SELECT 'asset_balances',count(*) FROM public.asset_balances
UNION ALL SELECT 'order_reservations',count(*) FROM public.order_reservations
UNION ALL SELECT 'conditional_orders',count(*) FROM public.conditional_orders;

SELECT table_name,column_name,data_type,numeric_precision,numeric_scale
FROM information_schema.columns
WHERE table_schema='public'
AND (
 (table_name='orders' AND column_name IN ('amount','price','filled_amount','remaining_amount'))
 OR (table_name='trades' AND column_name IN ('amount','price'))
 OR (table_name='asset_balances' AND column_name='balance')
 OR (table_name='order_reservations' AND column_name IN ('reserved_amount','released_amount','consumed_amount'))
 OR (table_name='conditional_orders' AND column_name IN ('amount','trigger_price','limit_price','executed_price'))
 OR (table_name='wallets' AND column_name='balance_usdt')
 OR (table_name='transactions' AND column_name='amount')
)
ORDER BY table_name,column_name;

SELECT
 (SELECT count(*) FROM public.orders
   WHERE amount IS NULL OR amount<=0 OR amount>1000000 OR scale(amount)>18
      OR (price IS NOT NULL AND (price<=0 OR price>=10000000000000000::numeric OR scale(price)>18))
      OR filled_amount IS NULL OR filled_amount<0 OR filled_amount>amount OR scale(filled_amount)>18
      OR remaining_amount IS NULL OR remaining_amount<0 OR remaining_amount>amount OR scale(remaining_amount)>18
      OR filled_amount+remaining_amount<>amount) AS invalid_orders,
 (SELECT count(*) FROM public.trades
   WHERE amount IS NULL OR amount<=0 OR scale(amount)>18 OR abs(amount)>=10000000000000000::numeric
      OR price IS NULL OR price<=0 OR price>=10000000000000000::numeric OR scale(price)>18) AS invalid_trades,
 (SELECT count(*) FROM public.asset_balances
   WHERE balance IS NULL OR balance<0 OR scale(balance)>18
      OR abs(balance)>=100000000000000000000::numeric) AS invalid_asset_balances,
 (SELECT count(*) FROM public.order_reservations
   WHERE reserved_amount IS NULL OR reserved_amount<=0 OR scale(reserved_amount)>18
      OR released_amount IS NULL OR released_amount<0 OR scale(released_amount)>18
      OR consumed_amount IS NULL OR consumed_amount<0 OR scale(consumed_amount)>18
      OR consumed_amount+released_amount>reserved_amount) AS invalid_reservations,
 (SELECT count(*) FROM public.conditional_orders
   WHERE amount IS NULL OR amount<=0 OR amount>1000000 OR scale(amount)>18
      OR trigger_price IS NULL OR trigger_price<=0 OR trigger_price>=10000000000000000::numeric OR scale(trigger_price)>18
      OR (limit_price IS NOT NULL AND (limit_price<=0 OR limit_price>=10000000000000000::numeric OR scale(limit_price)>18))
      OR (executed_price IS NOT NULL AND (executed_price<=0 OR executed_price>=10000000000000000::numeric OR scale(executed_price)>18))) AS invalid_conditional_orders;

WITH target_cols AS (
 SELECT c.oid AS relid,a.attnum,a.attname,n.nspname,c.relname
 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
 JOIN pg_attribute a ON a.attrelid=c.oid
 WHERE n.nspname='public'
   AND c.relname IN ('orders','trades','asset_balances','order_reservations','conditional_orders')
   AND a.attname IN ('amount','price','filled_amount','remaining_amount','balance','reserved_amount','released_amount','consumed_amount','trigger_price','limit_price','executed_price')
   AND a.attnum>0 AND NOT a.attisdropped
)
SELECT t.relname AS table_name,t.attname AS column_name,
       dn.nspname AS dependent_schema,dc.relname AS dependent_view,dc.relkind
FROM target_cols t
JOIN pg_depend d ON d.refobjid=t.relid AND d.refobjsubid=t.attnum
JOIN pg_rewrite rw ON rw.oid=d.objid
JOIN pg_class dc ON dc.oid=rw.ev_class
JOIN pg_namespace dn ON dn.oid=dc.relnamespace
WHERE dc.relkind IN ('v','m')
ORDER BY t.relname,t.attname,dn.nspname,dc.relname;

SELECT version,name
FROM supabase_migrations.schema_migrations
WHERE name='atomic_exact_decimal_rollout';

SELECT pid,usename,state,now()-xact_start AS transaction_age,wait_event_type,wait_event,left(query,200) AS query_excerpt
FROM pg_stat_activity
WHERE datname=current_database()
  AND xact_start IS NOT NULL
  AND now()-xact_start>interval '30 seconds'
ORDER BY xact_start;
