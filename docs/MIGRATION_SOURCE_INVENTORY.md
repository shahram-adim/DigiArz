# Migration source inventory (repository only)

Generated from the `main` Git tree at commit `f0f7ad7ae99be8033af25aa251e1eac48652865e` on 2026-11-20.

## Scope and limits

- This is a deterministic inventory of SQL migration source files currently present in `supabase/migrations/`.
- It does **not** represent the list of migrations applied to Supabase Production. The current encrypted application-schema backup excludes `supabase_migrations.schema_migrations`.
- Do not use this list to run `supabase db push`, mark versions applied, or reconstruct Production history.
- Applied-version reconciliation remains blocked pending an authoritative migration-history export or a safe, low-impact Production read after database stability returns.

## Current local source files

Count: **40**.

- `202` — `20261113161641_enforce_active_accounts_in_demo_trade_and_limit_engine.sql`
- `202` — `20261113162051_add_demo_take_profit_stop_loss_engine.sql`
- `202` — `20261113162130_lock_market_price_during_conditional_execution.sql`
- `202` — `20261113162202_record_conditional_reservation_consumption.sql`
- `202` — `20261113162244_index_conditional_execution_order_reference.sql`
- `202` — `20261113170000_recover_stalled_crypto_asset_sync.sql`
- `202` — `20261113171000_add_admin_curated_market_assets.sql`
- `202` — `20261113172000_harden_admin_market_listing_access.sql`
- `202` — `20261113175312_allow_existing_pair_in_admin_asset_listing.sql`
- `202` — `20261113180000_add_admin_pair_activation_engine.sql`
- `202` — `20261113180500_fix_market_price_decimal_parser.sql`
- `202` — `20261113181000_show_live_prices_for_curated_assets.sql`
- `202` — `20261113181827_add_stop_limit_order_engine.sql`
- `202` — `20261113182000_rate_limit_manual_market_refresh.sql`
- `202` — `20261113183000_index_market_pair_admin_audit.sql`
- `202` — `20261113184000_prevent_curated_ticker_collisions.sql`
- `202` — `20261113190000_admin_on_demand_crypto_asset_refresh.sql`
- `202` — `20261114143035_get_my_order_reservations_rpc.sql`
- `202` — `20261115125926_expand_market_price_precision_for_micro_assets.sql`
- `202` — `20261115130430_fetch_coin_gecko_market_price_overflow_ids.sql`
- `202` — `20261115134500_add_kifpool_to_scheduled_exchange_asset_sync.sql`
- `202` — `20261115134600_avoid_relisting_unchanged_exchange_asset_matches.sql`
- `202` — `20261115135818_prefer_kifpool_coingecko_id_with_exact_asset_name.sql`
- `202` — `20261115140035_preserve_kifpool_exact_id_matches_in_unmatched_fallback.sql`
- `202` — `20261115142131_allow_verified_kifpool_legacy_name_aliases.sql`
- `202` — `20261115142357_allow_verified_kifpool_kishu_short_name_alias.sql`
- `202` — `20261115143000_allow_verified_kifpool_cfg_jup_exact_id_aliases.sql`
- `202` — `20261115143200_prioritize_exact_name_matches_for_kifpool_assets.sql`
- `202` — `20261115143450_allow_verified_kifpool_legacy_coin_id_transition.sql`
- `202` — `20261115143827_bound_stop_limit_invalid_reservation_retries.sql`
- `202` — `20261115145000_allow_verified_kifpool_rebrand_aliases.sql`
- `202` — `20261115145500_allow_verified_kifpool_additional_name_aliases.sql`
- `202` — `20261115150000_allow_verified_kifpool_exact_id_name_aliases_batch.sql`
- `202` — `20261116195749_fix_iran_exchange_sync_gzip_responses.sql`
- `202` — `20261116195814_deduplicate_iran_exchange_sync_rows.sql`
- `202` — `20261116200009_auto_list_unmatched_iran_exchange_assets.sql`
- `202` — `20261116203000_add_kucoin_to_scheduled_market_price_refresh.sql`
- `202` — `20261116203100_add_gateio_to_scheduled_market_price_refresh.sql`
- `202` — `20261116203709_limit_primary_coingecko_batch_to_515_ids.sql`
- `202` — `20261117130000_stagger_market_price_overflow_and_refresh_exchange_discovery.sql`

## Git-history observations

The GitHub path history currently returns 44 commits for `supabase/migrations/`. Four of those commits are explained by two filename-alignment corrections, not four additional final migration files:

1. Market-price CoinGecko batch migration:
   - `2b3c53776aa61d04286d1dc24532722eebad1bed` added the source under the applied timestamp.
   - `7c756ed4e00de5640902196dbae874b9fe39f525` removed the duplicate timestamped filename.
   - The surviving source is `20261116203709_limit_primary_coingecko_batch_to_515_ids.sql`.
2. Stop-Limit retry-bound migration:
   - `eb8234f24ea32d468a6e297ced6074a1f8f38498` aligned the source filename with the applied version.
   - `db5c2ab2736f9c5d60e8faa05eae2f7488d667e8` removed the duplicate timestamped filename.

These commits explain why path history has more commits than the current file count. They do not prove the complete Production migration ledger or account for the previously reported missing applied versions.

## Next reconciliation requirements

1. Obtain an authoritative export of `supabase_migrations.schema_migrations` (or equivalent trusted deployment ledger) when safe.
2. Compare exact version strings against this local filename manifest.
3. For every applied version without local SQL, recover the exact source from Git history, CI artifacts, or a separately retained deployment bundle; verify content hashes and provenance.
4. For every local-only source, determine whether it was intentionally superseded, never applied, or applied under another version. Do not replay it.
5. Resolve timestamp-prefix mismatches only with evidence; do not rename files or alter migration history speculatively.
