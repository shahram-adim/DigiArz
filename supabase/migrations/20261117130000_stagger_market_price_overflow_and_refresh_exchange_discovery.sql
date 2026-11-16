-- Refresh Iranian exchange listings more frequently while staggering the CoinGecko overflow batch.
-- This avoids sending the primary and overflow CoinGecko requests in the same minute.
select cron.alter_job(13, schedule => '*/10 * * * *');
select cron.alter_job(14, schedule => '* * * * *');
select cron.alter_job(17, schedule => '5-59/10 * * * *');
