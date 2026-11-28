# DigiArz — checkpoint شهرام ۲۳۶
تاریخ: ۲۰۲۶-۱۱-۲۸

## وضعیت زنده GitHub
- PR #67: open، Draft، unmerged، mergeable=false.
- Branch: `plan/all-catalog-assets-tradable-2026-11-27`.
- HEAD: `d4f33ed2e41ecf80dd96dfbc6bf147c998a83a8f`.
- Base: `fbfb5e974e754088a32c9fdcd76fc2ca9ab0f98b`.
- Compare base...HEAD: 309 ahead، 0 behind، status=ahead، 87 files.
- checkpoint 235 blob از GitHub بازخوانی شد: `d1a5452734000bc78d51eb4ab30ba617a8a5b0c0`.
- روی HEAD جاری check-runs=0 و fetch_commit_workflow_runs=0.
- Workflow exact-decimal-tests در main وجود دارد (blob `358f8009deb51d789fc85404b7887e4264a3c3ba`) و در branch نیز موجود است (blob `72b7db61f01af760834770d2771c7e4fb90509e0`)، هر دو pull_request به main را تعریف می‌کنند. بنابراین «workflow در base وجود ندارد» یا «base با filter نمی‌خواند» توضیح معتبر نیست.
- ابزار GitHub متصل، workflow dispatch/create-run را ارائه نمی‌کند؛ تنها rerun job شکست‌خورده موجود است و در HEAD جاری run شکست‌خورده‌ای وجود ندارد. علت عدم event delivery هنوز اثبات نشده است. احتمال credential/event suppression یا Actions policy صرفاً فرضیه است.

## بازبینی معماری canonical identity
منابع موجود بازخوانی شدند:
- `docs/CANONICAL_MARKET_LIMIT_FINANCIAL_CONTRACT_2026-11-28.md`
- `docs/CANONICAL_PROTOTYPE_FINANCIAL_GAP_AUDIT_2026-11-28.md`
- `docs/CANONICAL_ASSET_LEDGER_TEXT_KEY_CONSUMER_INVENTORY_2026-11-28.md`
- `docs/CANONICAL_IDENTITY_DEPENDENCY_MANIFEST_2026-11-27.md`
- `docs/CANONICAL_PAIR_ID_CONSUMER_INVENTORY_AND_RPC_CONTRACT_2026-11-28.md`

نتیجهٔ قطعی طراحی:
1. prototype فعلی فقط جداسازی ID در مدل ساده‌شده را ثابت می‌کند؛ قابل ارتقا به مالی نیست.
2. baseline مالی معتبر، migration `20261113161641_enforce_active_accounts_in_demo_trade_and_limit_engine.sql` است.
3. implementation بعدی باید همان `wallets.balance_usdt`، `asset_balances`، `order_reservations`، `orders`، `trades` و `transactions` را حفظ کند؛ ساخت generic balances موازی ممنوع.
4. pair_id/base_asset_id/quote_asset_id باید در price/order/trade/reservation حمل شوند و pair_id کلید اجرای قیمت باشد؛ ticker فقط label.
5. باید fee helper، active-account/auth checks، یک‌دقیقه freshness، 25% per-cycle Limit fill، advisory lock 739201126، SKIP LOCKED، wallet-first locking، reservation cumulative accounting و transaction journal دقیقاً حفظ شوند.
6. Market gross/fee در منبع baseline صریحاً round(...,8) دارد؛ Limit worker همان migration صریحاً round(...,8) ندارد. نباید رفتار این دو را یکی فرض کرد.
7. migration sources و schema/ACL/RLS/trigger parity هنوز برای طرح deployable کامل نیستند؛ 17 applied migration بدون source محلی همچنان blocker است.

## گام بعدی
1. مالک repo در GitHub Actions page وضعیت workflow و event timeline/synchronize را بررسی کند؛ ابزار فعلی مجوز/اکشن dispatch ندارد و من settings را تغییر نمی‌دهم.
2. پس از run معتبر روی SHA دقیق، logs و race step را بررسی کنیم؛ تا آن زمان PASS runtime ادعا نشود.
3. در مسیر فنی، candidate بعدی باید additive extension روی authoritative financial fixture باشد، نه generic prototype؛ اجرای آن فقط در PostgreSQL disposable و پس از تأمین exact prerequisites.
4. ابتدا طراحی mapping یکتای canonical asset ID به کلید فعلی asset_balances را با ambiguity fail-closed و consumer inventory کامل کنیم؛ هیچ backfill یا migration اکنون مجاز نیست.

## ایمنی
این checkpoint فقط ثبت نتایج read-only است. هیچ workflow dispatch، تنظیم Actions permissions، repository settings، SQL/database، Production row، financial RPC/worker/Cron invocation، migration، merge/rebase، deployment، APK/Pages publication یا هزینه‌ای انجام نشد.