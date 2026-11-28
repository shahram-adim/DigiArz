# DigiArz — checkpoint شهرام ۲۳۶
تاریخ: ۲۰۲۶-۱۱-۲۸

## وضعیت زنده GitHub پیش از این ثبت
- PR #67: open، Draft، unmerged، mergeable=false.
- Branch: `plan/all-catalog-assets-tradable-2026-11-27`.
- HEAD پیش از checkpoint: `e2d75f91bb827bfe77fd3ab4b0f956da45cba54b`.
- Base SHA: `fbfb5e974e754088a32c9fdcd76fc2ca9ab0f98b`.
- Main SHA: `e8477b53a1b8c6fc7225572db3e559a1c75607d8`.
- Compare main...branch: diverged، 312 ahead، 8 behind.
- checkpoint 235 blob از GitHub بازخوانی شد: `d1a5452734000bc78d51eb4ab30ba617a8a5b0c0`.
- روی HEAD پیش از checkpoint، check-runs=0 و fetch_commit_workflow_runs=0.
- workflow `exact-decimal-tests.yml` روی main و branch هر دو pull_request به main را تعریف می‌کنند؛ ابزار GitHub متصل dispatch/create-run ندارد. علت عدم delivery اثبات نشده و هر توضیح دربارهٔ credential/event suppression یا Actions policy صرفاً فرضیه است.

## بازبینی معماری canonical identity
منابع بررسی‌شده:
- `docs/CANONICAL_MARKET_LIMIT_FINANCIAL_CONTRACT_2026-11-28.md`
- `docs/CANONICAL_PROTOTYPE_FINANCIAL_GAP_AUDIT_2026-11-28.md`
- `docs/CANONICAL_ASSET_LEDGER_TEXT_KEY_CONSUMER_INVENTORY_2026-11-28.md`
- `docs/CANONICAL_IDENTITY_DEPENDENCY_MANIFEST_2026-11-27.md`
- `docs/CANONICAL_PAIR_ID_CONSUMER_INVENTORY_AND_RPC_CONTRACT_2026-11-28.md`

نتیجهٔ قطعی طراحی:
1. prototype فعلی فقط جداسازی ID در مدل ساده‌شده را ثابت می‌کند؛ قابل ارتقا به موتور مالی نیست.
2. baseline مالی معتبر، migration `20261113161641_enforce_active_accounts_in_demo_trade_and_limit_engine.sql` است.
3. implementation بعدی باید همان `wallets.balance_usdt`, `asset_balances`, `order_reservations`, `orders`, `trades`, `transactions` را حفظ کند؛ ساخت generic balances موازی ممنوع.
4. pair_id/base_asset_id/quote_asset_id باید در price/order/trade/reservation حمل شوند و pair_id کلید اجرای قیمت باشد؛ ticker فقط label.
5. باید fee helper، active-account/auth checks، یک‌دقیقه freshness، 25% per-cycle Limit fill، advisory lock 739201126، SKIP LOCKED، wallet-first locking، reservation cumulative accounting و transaction journal دقیقاً حفظ شوند.
6. Market gross/fee در baseline صریحاً round(...,8) دارد؛ Limit worker همان migration صریحاً round(...,8) ندارد.
7. migration sources و schema/ACL/RLS/trigger parity برای طرح deployable کامل نیستند؛ 17 applied migration بدون source محلی همچنان blocker است.

## اصلاح جدید در candidate نگاشت دفترکل
در `supabase/tests/canonical_asset_ledger_key_mapping_candidate.sql` کشف شد trigger قبلی فقط تغییر `ledger_asset_key` را بعد از استفادهٔ مالی مسدود می‌کرد؛ canonical ID، mapping_status و evidence_ref/reviewed_at همچنان قابل تغییر بودند.

تغییر محدود به disposable candidate:
- Trigger اکنون UPDATE ستون‌های `canonical_asset_id`, `ledger_asset_key`, `mapping_status`, `evidence_ref`, `reviewed_at` را پوشش می‌دهد.
- اگر کلید قدیمی در `asset_balances` یا `order_reservations` استفاده شده باشد، تغییر هرکدام از این فیلدهای هویتی/اعتباری با SQLSTATE 23514 رد می‌شود.
- تغییر `display_symbol` همچنان مجاز است و ledger key را تغییر نمی‌دهد.
- SQL regression برای canonical ID، status، evidence و حفظ rename نمایشی اضافه شد.
- Node source guard در `tests/canonical-ledger-identity-integration-gate.test.js` اضافه شد.

Blobهای بازخوانی‌شده:
- candidate SQL: `5886e17cbd460f25953a79973484bc20a53e6f79`
- Node test: `88bc062e4d7845d392667e7e1699b688efbcf111`

## CI و شواهد
- روی HEAD قبل از ثبت checkpoint، workflow runs و check-runs صفر بود.
- Node test و SQL candidate در این نوبت اجرا نشده‌اند؛ فقط source review و بازخوانی GitHub انجام شده است.
- هیچ PASS runtime ادعا نمی‌شود.
- CI trigger/permissions تغییر نکرد و dispatch انجام نشد.

## گام بعدی
1. مالک repo در GitHub Actions page وضعیت workflow/event delivery را بررسی کند؛ ابزار فعلی dispatch یا تنظیم permissions را در اختیار ندارد.
2. پس از run معتبر روی SHA دقیق، Node tests و SQL mapping candidate را در PostgreSQL disposable اجرا و logs/race steps را بررسی کنیم.
3. بررسی کنیم جدول mapping در طرح نهایی باید FK به canonical asset registry داشته باشد و RLS/ACL/privileged writerها چگونه کنترل شوند.
4. candidate بعدی باید additive extension روی authoritative financial fixture باشد، نه generic prototype؛ همهٔ writerها و consumerها باید canonical IDs را end-to-end حمل کنند.
5. هیچ backfill یا migration تا بازیابی sourceهای ناقص و تکمیل schema/ACL/RLS/trigger parity طراحی/اجرا نشود.

## ایمنی
فقط candidate SQL آزمایشی، Node regression test و این checkpoint در branch Draft تغییر کردند. هیچ Production SQL/schema/business-row، balance/reservation/order/trade/wallet، worker/Cron schedule یا invocation، Auth/RLS/ACL، Edge Function، workflow settings، migration، merge/rebase، db push، deployment، APK/Pages publication یا هزینه‌ای انجام نشد.