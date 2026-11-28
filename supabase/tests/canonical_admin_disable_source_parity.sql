-- Disposable source-parity regression for the captured Production admin-disable RPC.
-- It loads the exact 2026-11-27 pg_get_functiondef snapshot, demonstrates its
-- ticker-scoped cross-pair effects, then verifies the pair_id-scoped candidate.
-- Never apply this file or the included snapshot to Production.

CREATE SCHEMA IF NOT EXISTS auth;
CREATE SCHEMA IF NOT EXISTS private;

CREATE OR REPLACE FUNCTION auth.uid()
RETURNS uuid LANGUAGE sql STABLE AS $$
  SELECT NULLIF(current_setting('request.jwt.claim.sub', true), '')::uuid
$$;

CREATE OR REPLACE FUNCTION private.is_super_admin()
RETURNS boolean LANGUAGE sql STABLE AS $$
  SELECT auth.uid() = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid
$$;

CREATE TABLE public.demo_trading_pairs (
  pair_id uuid PRIMARY KEY,
  base_coingecko_id text NOT NULL UNIQUE,
  pair_symbol text NOT NULL,
  is_enabled boolean NOT NULL DEFAULT true,
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.orders (
  id uuid PRIMARY KEY,
  pair_id uuid NOT NULL REFERENCES public.demo_trading_pairs(pair_id),
  symbol text NOT NULL,
  order_type text NOT NULL,
  status text NOT NULL,
  amount numeric NOT NULL,
  filled_amount numeric NOT NULL DEFAULT 0,
  remaining_amount numeric NOT NULL
);

CREATE TABLE public.conditional_orders (
  id uuid PRIMARY KEY,
  order_id uuid NOT NULL REFERENCES public.orders(id),
  status text NOT NULL,
  last_error text,
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.order_reservations (
  id uuid PRIMARY KEY,
  order_id uuid NOT NULL REFERENCES public.orders(id),
  reserved_amount numeric NOT NULL,
  consumed_amount numeric NOT NULL DEFAULT 0,
  released_amount numeric NOT NULL DEFAULT 0,
  status text NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE private.market_pair_admin_audit (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  pair_symbol text NOT NULL,
  coingecko_id text NOT NULL,
  action text NOT NULL,
  admin_user_id uuid NOT NULL,
  reason text,
  validation_snapshot jsonb NOT NULL
);

-- Load the exact captured Production function body, not a rewritten copy.
\ir canonical_identity_live_admin_disable_market_pair_snapshot.sql

INSERT INTO public.demo_trading_pairs(pair_id,base_coingecko_id,pair_symbol) VALUES
('10000000-0000-0000-0000-000000000001','asset-alpha','DUPUSDT'),
('10000000-0000-0000-0000-000000000002','asset-beta','DUPUSDT');

INSERT INTO public.orders(id,pair_id,symbol,order_type,status,amount,filled_amount,remaining_amount) VALUES
('20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001','DUPUSDT','limit','pending',10,0,10),
('20000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000002','DUPUSDT','limit','pending',20,0,20),
('20000000-0000-0000-0000-000000000003','10000000-0000-0000-0000-000000000001','DUPUSDT','conditional','pending',5,0,5),
('20000000-0000-0000-0000-000000000004','10000000-0000-0000-0000-000000000002','DUPUSDT','conditional','pending',7,0,7);

INSERT INTO public.conditional_orders(id,order_id,status) VALUES
('30000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000003','pending'),
('30000000-0000-0000-0000-000000000002','20000000-0000-0000-0000-000000000004','pending');

INSERT INTO public.order_reservations(id,order_id,reserved_amount,status) VALUES
('40000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001',10,'reserved'),
('40000000-0000-0000-0000-000000000002','20000000-0000-0000-0000-000000000002',20,'reserved'),
('40000000-0000-0000-0000-000000000003','20000000-0000-0000-0000-000000000003',5,'reserved'),
('40000000-0000-0000-0000-000000000004','20000000-0000-0000-0000-000000000004',7,'reserved');

SELECT set_config('request.jwt.claim.sub','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',false);
SELECT public.admin_disable_market_pair('asset-alpha','source-parity regression');

-- The captured ticker-scoped function is expected to affect both same-symbol
-- pairs. This assertion documents the existing behavior as a failing invariant.
DO $$
BEGIN
  IF (SELECT count(*) FROM public.orders WHERE status='cancelled') <> 4 THEN
    RAISE EXCEPTION 'source snapshot behavior changed; re-review this regression';
  END IF;
  IF (SELECT count(*) FROM public.order_reservations WHERE status='released') <> 4 THEN
    RAISE EXCEPTION 'source snapshot reservation effect changed; re-review';
  END IF;
  IF (SELECT count(*) FROM public.demo_trading_pairs WHERE is_enabled) <> 0 THEN
    RAISE EXCEPTION 'source snapshot pair-symbol update behavior changed; re-review';
  END IF;
END;
$$;

-- Reset only this disposable fixture, then run the corrected pair_id-scoped candidate.
TRUNCATE TABLE private.market_pair_admin_audit RESTART IDENTITY;
TRUNCATE TABLE public.conditional_orders, public.order_reservations, public.orders, public.demo_trading_pairs CASCADE;

INSERT INTO public.demo_trading_pairs(pair_id,base_coingecko_id,pair_symbol) VALUES
('50000000-0000-0000-0000-000000000001','asset-gamma','SAMEUSDT'),
('50000000-0000-0000-0000-000000000002','asset-delta','SAMEUSDT');

INSERT INTO public.orders(id,pair_id,symbol,order_type,status,amount,filled_amount,remaining_amount) VALUES
('60000000-0000-0000-0000-000000000001','50000000-0000-0000-0000-000000000001','SAMEUSDT','limit','pending',10,0,10),
('60000000-0000-0000-0000-000000000002','50000000-0000-0000-0000-000000000002','SAMEUSDT','limit','pending',20,0,20),
('60000000-0000-0000-0000-000000000003','50000000-0000-0000-0000-000000000001','SAMEUSDT','conditional','pending',5,0,5),
('60000000-0000-0000-0000-000000000004','50000000-0000-0000-0000-000000000002','SAMEUSDT','conditional','pending',7,0,7);

INSERT INTO public.conditional_orders(id,order_id,status) VALUES
('70000000-0000-0000-0000-000000000001','60000000-0000-0000-0000-000000000003','pending'),
('70000000-0000-0000-0000-000000000002','60000000-0000-0000-0000-000000000004','pending');

INSERT INTO public.order_reservations(id,order_id,reserved_amount,status) VALUES
('80000000-0000-0000-0000-000000000001','60000000-0000-0000-0000-000000000001',10,'reserved'),
('80000000-0000-0000-0000-000000000002','60000000-0000-0000-0000-000000000002',20,'reserved'),
('80000000-0000-0000-0000-000000000003','60000000-0000-0000-0000-000000000003',5,'reserved'),
('80000000-0000-0000-0000-000000000004','60000000-0000-0000-0000-000000000004',7,'reserved');

CREATE OR REPLACE FUNCTION public.admin_disable_market_pair_candidate(
  p_pair_id uuid,
  p_reason text DEFAULT NULL
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE
  v_admin uuid := auth.uid();
  v_pair public.demo_trading_pairs%ROWTYPE;
  v_cancelled integer := 0;
  v_released integer := 0;
BEGIN
  IF v_admin IS NULL OR NOT private.is_super_admin() THEN
    RAISE EXCEPTION 'Super administrator access required' USING errcode='42501';
  END IF;
  IF p_pair_id IS NULL THEN RAISE EXCEPTION 'Pair ID is required'; END IF;

  SELECT * INTO v_pair
  FROM public.demo_trading_pairs
  WHERE pair_id=p_pair_id
  FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Trading pair not found'; END IF;

  UPDATE public.conditional_orders co
  SET status='cancelled',last_error='Pair disabled by administrator',updated_at=now()
  FROM public.orders o
  WHERE co.order_id=o.id AND o.pair_id=p_pair_id
    AND co.status='pending' AND o.status IN ('pending','partially_filled');

  UPDATE public.order_reservations r
  SET released_amount=r.reserved_amount-r.consumed_amount,
      status=CASE WHEN r.consumed_amount>=r.reserved_amount THEN 'consumed' ELSE 'released' END,
      updated_at=now()
  FROM public.orders o
  WHERE r.order_id=o.id AND o.pair_id=p_pair_id
    AND o.order_type IN ('limit','conditional')
    AND o.status IN ('pending','partially_filled')
    AND r.status='reserved';
  GET DIAGNOSTICS v_released=ROW_COUNT;

  UPDATE public.orders
  SET status='cancelled',remaining_amount=amount-filled_amount
  WHERE pair_id=p_pair_id AND order_type IN ('limit','conditional')
    AND status IN ('pending','partially_filled');
  GET DIAGNOSTICS v_cancelled=ROW_COUNT;

  UPDATE public.demo_trading_pairs
  SET is_enabled=false,updated_at=now()
  WHERE pair_id=p_pair_id;

  INSERT INTO private.market_pair_admin_audit(
    pair_symbol,coingecko_id,action,admin_user_id,reason,validation_snapshot
  ) VALUES(
    v_pair.pair_symbol,v_pair.base_coingecko_id,'disabled',auth.uid(),
    left(coalesce(p_reason,'Disabled'),500),
    jsonb_build_object('cancelled_open_orders',v_cancelled,'reservations_released',v_released)
  );

  RETURN jsonb_build_object('success',true,'pair_id',p_pair_id,
    'cancelled_open_orders',v_cancelled,'reservations_released',v_released);
END;
$$;

SELECT public.admin_disable_market_pair_candidate(
  '50000000-0000-0000-0000-000000000001','pair-scoped regression'
);

DO $$
BEGIN
  IF (SELECT count(*) FROM public.orders WHERE pair_id='50000000-0000-0000-0000-000000000001' AND status='cancelled') <> 2 THEN
    RAISE EXCEPTION 'candidate did not cancel exactly target-pair orders';
  END IF;
  IF (SELECT count(*) FROM public.order_reservations r JOIN public.orders o ON o.id=r.order_id
      WHERE o.pair_id='50000000-0000-0000-0000-000000000001' AND r.status='released') <> 2 THEN
    RAISE EXCEPTION 'candidate did not release exactly target-pair reservations';
  END IF;
  IF (SELECT count(*) FROM public.orders WHERE pair_id='50000000-0000-0000-0000-000000000002' AND status='pending') <> 2 THEN
    RAISE EXCEPTION 'candidate modified same-symbol sibling orders';
  END IF;
  IF (SELECT count(*) FROM public.order_reservations r JOIN public.orders o ON o.id=r.order_id
      WHERE o.pair_id='50000000-0000-0000-0000-000000000002' AND r.status='reserved') <> 2 THEN
    RAISE EXCEPTION 'candidate modified same-symbol sibling reservations';
  END IF;
  IF (SELECT count(*) FROM public.conditional_orders co JOIN public.orders o ON o.id=co.order_id
      WHERE o.pair_id='50000000-0000-0000-0000-000000000002' AND co.status='pending') <> 1 THEN
    RAISE EXCEPTION 'candidate modified sibling conditional order';
  END IF;
  IF (SELECT is_enabled FROM public.demo_trading_pairs WHERE pair_id='50000000-0000-0000-0000-000000000002') IS NOT TRUE THEN
    RAISE EXCEPTION 'candidate disabled sibling pair';
  END IF;
END;
$$;

-- Repeated candidate disable is idempotent and must not release twice.
DO $$
DECLARE v_result jsonb;
BEGIN
  v_result:=public.admin_disable_market_pair_candidate(
    '50000000-0000-0000-0000-000000000001','repeat'
  );
  IF (v_result->>'cancelled_open_orders')::integer<>0
     OR (v_result->>'reservations_released')::integer<>0 THEN
    RAISE EXCEPTION 'candidate repeated disable was not idempotent';
  END IF;
END;
$$;
