# DigiArz — checkpoint شهرام ۲۲۹
تاریخ: ۲۰۲۶-۱۱-۲۸

## وضعیت زنده پیش از این checkpoint
- Repository: `shahram-adim/DigiArz`
- PR #67: open، Draft، unmerged، `mergeable=false`
- Branch: `plan/all-catalog-assets-tradable-2026-11-27`
- HEAD پیش از این checkpoint: `ffc99c94a447fcb28e1f29a5c259998a35745459`
- Base `main`: `e8477b53a1b8c6fc7225572db3e559a1c75607d8`
- Compare: diverged، ۲۹۶ commit جلو و ۸ commit عقب.
- برای SHA بالا: Actions runs=0، check-runs=0، combined statuses خالی.

## ممیزی دقیق lifecycle موجود
### Market/Limit authoritative migration
فایل `supabase/migrations/20261113161641_enforce_active_accounts_in_demo_trade_and_limit_engine.sql` در تست disposable با setup موجود اعمال می‌شود. منبع واقعی این migration هنوز ticker/text-key محور است:
- `execute_demo_trade(p_symbol,...)`، base asset را از ticker ورودی با حذف پسوند USDT می‌سازد.
- lookup قیمت با `market_prices.symbol` و pair با `demo_trading_pairs.pair_symbol` انجام می‌شود.
- موجودی پایه با `asset_balances.asset = v_base` خوانده/نوشته می‌شود.
- رزروها با `order_reservations.asset = v_base` جمع می‌شوند.
- سفارش، معامله و transaction description/currency همچنان نماد/کلید متنی را ثبت می‌کنند.
- `place_limit_order` و `process_limit_orders` نیز قرارداد ورودی/ذخیره‌سازی فعلی را بر اساس symbol نگه می‌دارند.

### چه چیزی در تست‌ها ثابت شده است
- `authoritative_market_limit_source_parity.sql`، توابع Market و Limit را از migration واقعی در PostgreSQL disposable اجرا می‌کند؛ شامل Market buy/sell، Limit buy/sell، چهار چرخه partial-fill، trade rows، reservation consumption/release، stale price و account/authorization guards.
- `canonical_asset_ledger_key_mapping_candidate.sql`، mapping آزمایشی دو UUID هم‌نماد را به دو ledger key یکتا نگاشت می‌کند و fail-closed، uniqueness، immutability و عدم حذف mapping مصرف‌شده را روی جدول‌های ledger فعلی بررسی می‌کند.
- این دو تست در حال حاضر به هم متصل نیستند: تست lifecycle از asset ticker مثل `DOT` استفاده می‌کند؛ mapping candidate هیچ‌یک از RPCها یا workerهای authoritative را جایگزین/متصل نمی‌کند.
- `exact_decimal_cancel_setup.sql` یک `cancel_limit_order` آزمایشی را از نو تعریف می‌کند؛ بنابراین اجرای آن، source parity با cancellation RPC واقعی Production نیست.
- race harness عمومی worker/cancel نیز fixture فعلی و کلیدهای ticker را استفاده می‌کند و هنوز duplicate canonical asset isolation را اثبات نمی‌کند.

## نتیجه و مانع فنی
ساختن یک تست end-to-end معتبر فقط با افزودن mapping table و فراخوانی migration فعلی ممکن نیست؛ چون بدنه‌های authoritative فعلی هنوز asset ID/pair ID را به ledger resolution منتقل نمی‌کنند و همچنان ticker را کلید حسابداری می‌گیرند. اگر دو دارایی هم‌نماد با همان ticker وارد این توابع شوند، مسیر فعلی به یک text ledger key مشترک می‌رسد. اجرای تستی که صرفاً helper mapping را کنار توابع فعلی قرار دهد، اثبات جداسازی مالی نیست و نتیجهٔ گمراه‌کننده خواهد بود.

## گام بعدی مجاز در شاخهٔ آزمایشی
1. یک candidate migration/RPC contract طراحی شود که ورودی canonical pair ID را بگیرد و از همان mapping تأییدشده base ledger key را resolve کند؛ mapping مبهم باید پیش از هر دسترسی مالی fail-closed شود.
2. بدنهٔ candidateهای Market، Limit placement و Limit worker باید صریحاً در disposable fixture اجرا شوند؛ صرفاً تغییر تست یا source-text assertion کافی نیست.
3. سفارش، reservation، trade و transaction باید علاوه بر display symbol، canonical pair/base/quote IDs یا ارتباط FK معتبر و قابل اثبات داشته باشند؛ هیچ ledger موازی ساخته نشود.
4. تست دو asset هم‌نماد باید balance/reservation isolation، چهار partial fill، cancellation/remainder release، retry/idempotency و worker-vs-cancel race را روی همان candidate RPC/worker اجرا کند.
5. cancellation واقعی باید از source snapshot معتبر یا migration authoritative بازیابی شود؛ fixture فعلی که تابع cancellation را از نو می‌سازد، برای این گیت کافی نیست.
6. تا پیش از تکمیل candidate و اجرای CI روی SHA دقیق، ادعای end-to-end PASS ممنوع است.

## نتیجه این مرحله
- [x] PR، branch، HEAD، main و compare زنده بررسی شد.
- [x] Actions runs و check-runs روی HEAD دقیق بررسی شد؛ هیچ‌کدام وجود نداشت.
- [x] migration authoritative و setup/testهای lifecycle و mapping از GitHub بازخوانی شدند.
- [x] فاصلهٔ واقعی بین mapping candidate و lifecycle authoritative مستند شد.
- [ ] canonical candidate RPC/worker lifecycle هنوز پیاده‌سازی نشده است.
- [ ] PostgreSQL/CI روی HEAD فعلی اجرا نشده است.

## ایمنی و release gate
این checkpoint فقط مستندسازی ممیزی در شاخهٔ PR است. هیچ Production SQL/read/write، migration، db push، backfill، re-key، balance/reservation/order/trade change، worker/Cron invocation یا schedule change، Edge Function، RLS/ACL/Auth، merge، rebase، deployment، APK/Pages publication یا هزینه‌ای انجام نشده است. PR همچنان Draft و ادغام‌نشده باقی می‌ماند.