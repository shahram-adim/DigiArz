# Migration replay blocker manifest — 2026-11-28

## Scope and authority

This is a repository-only reconciliation manifest for PR #67. The current `main` Git tree was read directly on 2026-11-28 and contains 40 SQL files under `supabase/migrations/`. The historical Supabase ledger counts below come from the recorded read-only audit in `supabase/MIGRATION_RECONCILIATION.md`; they were **not freshly queried from Supabase in this pass**.

This manifest does not authorize migration replay, filename repair, migration-history edits, or `supabase db push`.

## Applied migrations whose SQL source is unresolved (17)

The first 14 are the original missing-source inventory; the last three were added in the later recorded ledger audit.

| Applied version | Applied migration name |
|---|---|
| 20261113153808 | approved_wallet_defaults_fees_and_coin_reviews |
| 20261113154323 | assign_confirmed_super_admin |
| 20261113154736 | secure_admin_wallet_management |
| 20261113154750 | add_admin_role_probe |
| 20261113154844 | use_toman_units_in_admin_credit_ui |
| 20261113154926 | move_admin_privilege_logic_to_private_schema |
| 20261115101709 | create_exchange_asset_observations |
| 20261115102729 | schedule_iran_exchange_asset_sync |
| 20261115102927 | fix_exchange_sync_response_json_cast |
| 20261115103227 | auto_list_verified_exchange_assets |
| 20261115103507 | schedule_bit24_exchange_asset_sync |
| 20261115105721 | admin_exchange_asset_sync_monitoring |
| 20261115105956 | restrict_exchange_sync_worker_execution |
| 20261116201639 | auto_activate_verified_exchange_pairs |
| 20261121045434 | digiarz_backpressure_and_exchange_sync_bloat_guards |
| 20261121045531 | snapshot_pg_net_unlogged_queue_before_recovery |
| 20261121050216 | temporarily_throttle_exchange_asset_processors_20261121 |

No SQL body is inferred from these names. Exact-name commit searches recorded in prior checkpoints did not recover authoritative bodies. The searches do not cover every external backup, fork, deployment artifact, or owner-held archive.

## Local migration filename prefixes differing from recorded applied versions (20)

The following mappings are transcribed from the historical migration reconciliation inventory. Matching suffixes do not prove that file contents are identical to the applied SQL.

| Local file prefix | Recorded applied version | Migration name |
|---|---|---|
| 20261113162202 | 20261113162154 | record_conditional_reservation_consumption |
| 20261113162244 | 20261113162233 | index_conditional_execution_order_reference |
| 20261113170000 | 20261113163743 | recover_stalled_crypto_asset_sync |
| 20261113171000 | 20261113163947 | add_admin_curated_market_assets |
| 20261113172000 | 20261113164521 | harden_admin_market_listing_access |
| 20261113180000 | 20261113165725 | add_admin_pair_activation_engine |
| 20261113180500 | 20261113165747 | fix_market_price_decimal_parser |
| 20261113181000 | 20261113165806 | show_live_prices_for_curated_assets |
| 20261113182000 | 20261113170056 | rate_limit_manual_market_refresh |
| 20261113183000 | 20261113170216 | index_market_pair_admin_audit |
| 20261113184000 | 20261113170328 | prevent_curated_ticker_collisions |
| 20261113190000 | 20261113173506 | admin_on_demand_crypto_asset_refresh |
| 20261115134500 | 20261115134357 | add_kifpool_to_scheduled_exchange_asset_sync |
| 20261115134600 | 20261115134855 | avoid_relisting_unchanged_exchange_asset_matches |
| 20261115143000 | 20261115142521 | allow_verified_kifpool_cfg_jup_exact_id_aliases |
| 20261115143200 | 20261115142620 | prioritize_exact_name_matches_for_kifpool_assets |
| 20261115145000 | 20261115143015 | allow_verified_kifpool_rebrand_aliases |
| 20261115145500 | 20261115143050 | allow_verified_kifpool_additional_name_aliases |
| 20261115150000 | 20261115143223 | allow_verified_kifpool_exact_id_name_aliases_batch |
| 20261117130000 | 20261116205451 | stagger_market_price_overflow_and_refresh_exchange_discovery |

## Local-only files (2)

These files were present in the 40-file `main` migration inventory but were not recorded as applied in the historical ledger audit:

- `20261116203000_add_kucoin_to_scheduled_market_price_refresh.sql`
- `20261116203100_add_gateio_to_scheduled_market_price_refresh.sql`

The historical reconciliation documents a regression hazard: these older definitions replace `public.refresh_market_prices()` without the later 515-ID primary CoinGecko cap. Do not apply them as-is.

## Required recovery protocol

1. Obtain the exact SQL from an independently trusted deployment artifact, backup, or owner-held archive.
2. Record source provenance and a cryptographic checksum for each recovered file.
3. Compare each recovered SQL body with the deployed definition and the corresponding migration ledger version; names and timestamps alone are insufficient.
4. Reconcile the 20 filename mismatches only after content equivalence is proven.
5. Rehearse the complete reconciled set in disposable PostgreSQL 17 and verify functions, constraints, grants, RLS, triggers, indexes, and cron expectations.
6. Keep unresolved items blocked. Do not synthesize SQL, rename migration files, edit the migration ledger, or run `supabase db push`.

## Safety record

This manifest was assembled from repository files and previously recorded audit evidence only. No Supabase connection/query, SQL execution, migration replay, database/schema/function/ACL/RLS/trigger/Cron/worker change, merge, deployment, APK/Pages publication, or infrastructure spend occurred.
