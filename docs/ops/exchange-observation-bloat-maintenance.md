# Exchange observation table bloat maintenance

## Why this exists

The production table `public.exchange_asset_observations` had approximately 4,961 live rows but occupied about 230 MB. Statistics showed 9,404 updates and zero HOT updates. The old `exchange_asset_observations_match_idx` indexed both `match_status` and `last_seen_at`, while the sync worker refreshes `last_seen_at` periodically. Updating an indexed column prevents HOT updates.

The migration `20261121062000_reduce_exchange_observation_update_bloat.sql` replaces that index with a partial index on `match_status` only and sets table fillfactor to 50. The query plan was tested against a compact copy: the relevant filter completed in about 1 ms with the partial index, versus about 2.4 ms with a sequential scan. On the bloated test copy, the partial index query completed in about 4 ms.

## One-time compaction

The index/fillfactor migration does not shrink already allocated heap pages. In the isolated recovery project, after applying the index change and setting fillfactor to 50, this command reduced the table from approximately 229 MB to approximately 6 MB:

```sql
VACUUM (FULL, ANALYZE) public.exchange_asset_observations;
```

**Do not run this command on Production during normal traffic.** `VACUUM FULL` takes an ACCESS EXCLUSIVE lock and blocks reads and writes to this table while it rewrites the relation. Schedule a maintenance window, confirm no long-running sync job is active, ensure sufficient free disk space, and communicate the short service impact before execution. Run it as a standalone statement in autocommit mode; it cannot run inside a transaction block.

## Post-maintenance verification

Run:

```sql
SELECT
  pg_size_pretty(pg_total_relation_size('public.exchange_asset_observations'::regclass)) AS total_size,
  n_live_tup,
  n_dead_tup,
  n_tup_upd,
  n_tup_hot_upd,
  round(100.0 * n_tup_hot_upd / NULLIF(n_tup_upd, 0), 1) AS hot_update_pct,
  last_vacuum,
  last_autovacuum
FROM pg_stat_user_tables
WHERE relid = 'public.exchange_asset_observations'::regclass;
```

Confirm that the partial index exists and that the query filtering active pending/ambiguous/unmatched observations uses it. After the next scheduled sync cycle, check that `n_tup_hot_upd` increases materially. The isolated test with fillfactor 50 and the partial index recorded 4,869 HOT updates out of 4,869 updates in the final test pass.

## Safety

- This maintenance changes no wallet, balance, order, trade, or user records.
- Do not disable `trg_auto_list_verified_exchange_asset`.
- Do not delete exchange observations or sync request history.
- Do not change Cron schedules as part of this maintenance.
