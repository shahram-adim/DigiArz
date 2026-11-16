# Supabase migration history reconciliation

Checked on 2026-11-16 against project `gfoaubfilhttnwjykaox` and the current `main` branch.

## Current state

- Supabase migration history contains **46 applied entries**.
- `supabase/migrations/` in GitHub contains **33 SQL files**.
- Thirteen applied migrations have no corresponding SQL file in the current repository.
- Nineteen local files have a timestamp prefix that differs from the applied version in Supabase, even though their descriptive suffix maps to the same migration name.
- The migration history table is not to be edited manually as a shortcut.

## Applied migrations with no local SQL source

| Applied version | Applied name |
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

## Local filename prefixes that do not match applied versions

| Current local file prefix | Applied version in Supabase | Migration name |
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

## Transfer safeguards

1. **Do not run `supabase db push` yet.** The local migration set would be interpreted as containing pending versions and the missing source files prevent a reproducible clean replay.
2. Do not rename or repair history rows based only on similar suffixes. First recover or reconstruct the thirteen missing SQL files from authoritative source/commit evidence, then verify the nineteen timestamp mappings and file contents.
3. The next financial migration must be applied as one reviewed, atomic, explicitly named migration after the preflight, schema rehearsal, function/grant checks, and rollback rehearsal pass.
4. Keep the production database unchanged until the user explicitly issues the database-transfer instruction.
5. After reconciliation, verify local and remote migration lists before any normal CLI push workflow is re-enabled.

This report is an inventory only. It changes no database object or migration-history row.
