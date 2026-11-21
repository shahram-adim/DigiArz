-- Disposable PostgreSQL 17 fixture: account deactivation vs order-placement TOCTOU.
-- This intentionally models the observed source-code gate/sleep/write sequence;
-- it is NOT a copy of the full production RPCs and proves only the concurrency primitive.
CREATE SCHEMA auth;
CREATE FUNCTION auth.uid() RETURNS uuid LANGUAGE sql STABLE SET search_path TO ''
AS $$ SELECT NULLIF(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
CREATE TABLE public.profiles(id uuid PRIMARY KEY,is_active boolean NOT NULL);
CREATE TABLE public.orders(id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,user_id uuid NOT NULL,order_type text NOT NULL,status text NOT NULL,amount numeric NOT NULL);
CREATE TABLE public.order_reservations(id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,order_id bigint NOT NULL UNIQUE,user_id uuid NOT NULL,reserved_amount numeric NOT NULL,released_amount numeric NOT NULL DEFAULT 0,status text NOT NULL DEFAULT 'reserved');
INSERT INTO public.profiles VALUES
 ('81000000-0000-4000-8000-000000000001',true),
 ('82000000-0000-4000-8000-000000000002',true),
 ('83000000-0000-4000-8000-000000000003',true);

CREATE FUNCTION public.current_account_is_active() RETURNS boolean
LANGUAGE sql STABLE SET search_path TO ''
AS $$ SELECT EXISTS(SELECT 1 FROM public.profiles WHERE id=auth.uid() AND is_active) $$;

-- Deliberately mirrors the vulnerable pattern: check first, then later write.
CREATE FUNCTION public.place_order_unlocked()
RETURNS bigint LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $$
DECLARE v_id bigint;
BEGIN
 IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Authentication required'; END IF;
 IF NOT public.current_account_is_active() THEN RAISE EXCEPTION 'Account is inactive'; END IF;
 PERFORM pg_catalog.pg_sleep(2); -- deterministic interleaving window for CI only
 INSERT INTO public.orders(user_id,order_type,status,amount)
 VALUES(auth.uid(),'limit','pending',1) RETURNING id INTO v_id;
 INSERT INTO public.order_reservations(order_id,user_id,reserved_amount)
 VALUES(v_id,auth.uid(),1);
 RETURN v_id;
END
$$;

-- Candidate serialization protocol: lock the profile row before checking it.
CREATE FUNCTION public.place_order_profile_locked()
RETURNS bigint LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $$
DECLARE v_id bigint; v_active boolean;
BEGIN
 IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Authentication required'; END IF;
 SELECT is_active INTO v_active FROM public.profiles WHERE id=auth.uid() FOR UPDATE;
 IF NOT FOUND OR v_active IS NOT TRUE THEN RAISE EXCEPTION 'Account is inactive'; END IF;
 PERFORM pg_catalog.pg_sleep(2); -- deterministic interleaving window for CI only
 INSERT INTO public.orders(user_id,order_type,status,amount)
 VALUES(auth.uid(),'limit','pending',1) RETURNING id INTO v_id;
 INSERT INTO public.order_reservations(order_id,user_id,reserved_amount)
 VALUES(v_id,auth.uid(),1);
 RETURN v_id;
END
$$;

-- Same profile row is updated first; this serializes against the candidate gate.
CREATE FUNCTION public.deactivate_account_fixture(p_user uuid)
RETURNS void LANGUAGE plpgsql SET search_path TO ''
AS $$
BEGIN
 UPDATE public.profiles SET is_active=false WHERE id=p_user AND is_active;
 UPDATE public.order_reservations r SET released_amount=r.reserved_amount,status='released'
 FROM public.orders o WHERE o.id=r.order_id AND o.user_id=p_user
   AND o.status IN ('pending','partially_filled') AND r.status='reserved';
 UPDATE public.orders SET status='cancelled'
 WHERE user_id=p_user AND status IN ('pending','partially_filled');
END
$$;
