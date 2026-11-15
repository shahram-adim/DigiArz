-- Compare the complete relevant fixture catalog snapshot before/after widening.
DO $verify$
DECLARE
  v_diff text;
BEGIN
  WITH current_objects AS (
    SELECT 'constraint'::text AS object_kind,c.relname||'.'||con.conname AS object_name,
           pg_get_constraintdef(con.oid) AS definition
    FROM pg_constraint con JOIN pg_class c ON c.oid=con.conrelid
    JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE n.nspname='public' AND c.relname IN ('orders','trades','asset_balances','order_reservations','conditional_orders')
    UNION ALL
    SELECT 'index',t.relname||'.'||i.relname,pg_get_indexdef(i.oid)
    FROM pg_index x JOIN pg_class t ON t.oid=x.indrelid JOIN pg_class i ON i.oid=x.indexrelid
    JOIN pg_namespace n ON n.oid=t.relnamespace
    WHERE n.nspname='public' AND t.relname IN ('orders','trades','asset_balances','order_reservations','conditional_orders')
    UNION ALL
    SELECT 'trigger',c.relname||'.'||tr.tgname,pg_get_triggerdef(tr.oid,true)
    FROM pg_trigger tr JOIN pg_class c ON c.oid=tr.tgrelid JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE n.nspname='public' AND c.relname IN ('orders','trades','asset_balances','order_reservations','conditional_orders')
      AND NOT tr.tgisinternal
    UNION ALL
    SELECT 'default',c.relname||'.'||a.attname,pg_get_expr(d.adbin,d.adrelid)
    FROM pg_attrdef d JOIN pg_class c ON c.oid=d.adrelid JOIN pg_namespace n ON n.oid=c.relnamespace
    JOIN pg_attribute a ON a.attrelid=c.oid AND a.attnum=d.adnum
    WHERE n.nspname='public' AND c.relname IN ('orders','trades','asset_balances','order_reservations','conditional_orders')
    UNION ALL
    SELECT 'column',c.relname||'.'||a.attname,'not_null='||a.attnotnull
    FROM pg_attribute a JOIN pg_class c ON c.oid=a.attrelid JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE n.nspname='public' AND c.relname IN ('orders','trades','asset_balances','order_reservations','conditional_orders')
      AND a.attnum>0 AND NOT a.attisdropped
    UNION ALL
    SELECT 'grant',table_name||'.'||grantee||'.'||privilege_type,is_grantable
    FROM information_schema.role_table_grants
    WHERE table_schema='public' AND table_name IN ('orders','trades','asset_balances','order_reservations','conditional_orders')
    UNION ALL
    SELECT 'policy',c.relname||'.'||p.polname,
      p.polcmd||'|'||p.polpermissive||'|'||p.polroles::text||'|'||
      COALESCE(pg_get_expr(p.polqual,p.polrelid),'')||'|'||
      COALESCE(pg_get_expr(p.polwithcheck,p.polrelid),'')
    FROM pg_policy p JOIN pg_class c ON c.oid=p.polrelid JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE n.nspname='public' AND c.relname IN ('orders','trades','asset_balances','order_reservations','conditional_orders')
    UNION ALL
    SELECT 'rls',c.relname,c.relrowsecurity||'|'||c.relforcerowsecurity
    FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE n.nspname='public' AND c.relname IN ('orders','trades','asset_balances','order_reservations','conditional_orders')
  ),
  differences AS (
    (SELECT object_kind,object_name,definition FROM public.widening_schema_snapshot
     EXCEPT SELECT object_kind,object_name,definition FROM current_objects)
    UNION ALL
    (SELECT object_kind,object_name,definition FROM current_objects
     EXCEPT SELECT object_kind,object_name,definition FROM public.widening_schema_snapshot)
  )
  SELECT string_agg(object_kind||':'||object_name||' => '||definition,'; ')
  INTO v_diff FROM differences;

  IF v_diff IS NOT NULL THEN
    RAISE EXCEPTION 'schema objects changed during widening: %',v_diff;
  END IF;
END
$verify$;
