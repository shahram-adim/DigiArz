-- Run in a transaction so transaction_timestamp() is a stable worker cutoff.
BEGIN;

INSERT INTO public.exchange_asset_sync_requests(exchange, request_id, requested_at)
VALUES
 ('nobitex', 1001, transaction_timestamp() - interval '1 minute'),
 ('nobitex', 1002, transaction_timestamp() - interval '1 minute'),
 ('nobitex', 1003, transaction_timestamp() + interval '1 minute');

INSERT INTO net._http_response(id, created, status_code, content, error_msg)
VALUES
 (1001, transaction_timestamp() - interval '1 minute', 200,
  '{"coins":[{"coin":"BTC","name":"Bitcoin"}]}', NULL),
 (1002, transaction_timestamp() + interval '1 minute', 200,
  '{"coins":[{"coin":"ETH","name":"Ethereum"}]}', NULL),
 (1003, transaction_timestamp() - interval '1 minute', 200,
  '{"coins":[{"coin":"SOL","name":"Solana"}]}', NULL);

SELECT public.process_iran_exchange_asset_sync();

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.exchange_asset_sync_requests
    WHERE request_id=1001 AND processed_at IS NOT NULL AND http_status=200
  ) THEN
    RAISE EXCEPTION 'eligible old request was not ingested and marked processed';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.exchange_asset_sync_requests
    WHERE request_id IN (1002,1003) AND processed_at IS NOT NULL
  ) THEN
    RAISE EXCEPTION 'late HTTP response or future request was incorrectly marked processed';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.exchange_asset_observations
    WHERE exchange='nobitex' AND market_symbol='BTC' AND base_symbol='BTC'
  ) THEN
    RAISE EXCEPTION 'eligible old response was not ingested';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.exchange_asset_observations
    WHERE exchange='nobitex' AND market_symbol IN ('ETH','SOL')
  ) THEN
    RAISE EXCEPTION 'late response or future request was ingested';
  END IF;
END;
$$;

ROLLBACK;
