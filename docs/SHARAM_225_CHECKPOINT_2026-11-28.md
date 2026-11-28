# DigiArz — checkpoint شهرام ۲۲۵
تاریخ: ۲۰۲۶-۱۱-۲۸

## مبنای زنده پیش از ثبت checkpoint
- مخزن: `shahram-adim/DigiArz`
- PR: [#67 — Make every DigiArz catalog asset demo-tradable](https://github.com/shahram-adim/DigiArz/pull/67)
- وضعیت PR: باز، Draft، ادغام‌نشده؛ `mergeable=false`
- شاخه: `plan/all-catalog-assets-tradable-2026-11-27`
- HEAD مشاهده‌شده: `6f62aa642b0321f18f638a46faedcbbb37ece1e9`
- Main: `e8477b53a1b8c6fc7225572db3e559a1c75607d8`
- Compare با Main: واگرا؛ ۲۸۸ کامیت جلو و ۸ کامیت عقب
- Check Runs روی HEAD: صفر؛ ابزار بازیابی workflow run نیز برای این SHA اجرای PR را برنگرداند. بنابراین CI روی HEAD فعلی تأییدشده نیست و نباید PASS اعلام شود.

## کار ثبت‌شده تا این checkpoint
- [x] در commit `6f62aa6` سند `docs/CANONICAL_PAIR_ID_CONSUMER_INVENTORY_AND_RPC_CONTRACT_2026-11-28.md` اضافه شد.
- [x] یک call site برای Market RPC و یک call site برای Limit RPC در `index.html` با ورودی `p_symbol` شناسایی شده‌اند؛ قرارداد پیشنهادی نسخه‌دار `execute_demo_trade_by_pair(p_pair_id,...)` و `place_limit_order_by_pair(p_pair_id,...)` است.
- [x] وابستگی UI بازار، قیمت‌ها، سفارش‌های فعال، رزروها، holdings و admin-disable به ticker/text key ثبت شده است.
- [x] ریسک admin-disable با ticker تکراری مستند است: انتخاب pair بر مبنای CoinGecko ID، اما cleanup سفارش با `orders.symbol = pair_symbol`.
- [x] سند نگاشت canonical asset ID به ledger key مجزا تأکید می‌کند که ticker نباید کلید مالی باشد و `asset_balances.asset` و `order_reservations.asset` برای دو دارایی هم‌نماد نباید یکسان شوند.
- [x] آخرین status record پروژه، checkpoint شهرام ۲۲۴ را ثبت کرده است؛ این فایل checkpoint ۲۲۵ را تکمیل می‌کند.

## موانع و شواهدی که هنوز حل نشده‌اند
- [ ] inventory repository-wide و Production-wide همه خواننده‌ها/نویسنده‌های `asset_balances.asset` و `order_reservations.asset` کامل نشده است؛ deployed Edge Functionها، Cron commandها و service-role writerهای بیرونی باید fingerprint شوند.
- [ ] ۱۷ migration اعمال‌شده در Production منبع محلی متناظر ندارند و ۲۰ migration هم‌نام دارای اختلاف timestamp هستند؛ منبع دقیق SQL/checksum باید از artifact یا backup معتبر بازیابی شود. SQL مفقود نباید حدس زده یا از وضعیت فعلی DB بازسازی و replay شود.
- [ ] candidate مالی باید روی PostgreSQL دورریختنی از setup و migrationهای authoritative آغاز شود و از همان ledgerهای واقعی `wallets`، `asset_balances`، `orders`، `trades`، `transactions` و `order_reservations` استفاده کند؛ prototype با جدول balances مستقل جایگزین معتبر نیست.
- [ ] canonical pair ID باید از ورودی RPC تا price lookup، order، trade، reservation، worker، cancellation و admin-disable باقی بماند؛ تست duplicate ticker، race، retry/fail-closed و source parity لازم است.
- [ ] TP/SL و Stop-Limit authoritative migration harness دارند، اما اتصال canonical ID به این مسیرها هنوز کامل نیست؛ OCO نیز lifecycle جداگانه و هنوز پیاده‌سازی‌نشده است.
- [ ] CI دقیقاً روی HEAD فعلی باید با اجرای واقعی و قابل مشاهده تأیید شود. نبود Check Run یا خروجی خالی ابزار، موفقیت CI را ثابت نمی‌کند.

## گام بعدی
۱. پیش از هر تغییر، وضعیت GitHub را دوباره بخوان و از HEAD تازه شروع کن.
۲. inventory باقی‌ماندهٔ کلیدهای ledger را با جست‌وجوی همه فایل‌های repository و manifest وابستگی‌ها کامل کن؛ موارد Production-only و external writer را صریحاً unknown نگه دار تا مدرک زنده و مجاز به دست آید.
۳. بازیابی migrationهای مفقود را فقط از منبع مستقل معتبر دنبال کن؛ در نبود منبع، blocker را باز نگه دار.
۴. سپس candidate نسخه‌دار Market/Limit را در disposable PostgreSQL، روی migrationهای authoritative، با ledger فعلی و بدون wallet/ledger موازی بساز و تست کن.

## Release / safety gate
- هیچ Merge، rebase، Migration، db push، Production SQL write، تغییر داده مالی، balance/reservation، RPC/worker/Cron، Edge Function، RLS/ACL/Auth، deploy، APK/Pages publication یا هزینه‌ای انجام نشده است.
- زمان‌بندی workerهای Limit، Conditional و Stop-Limit باید دست‌نخورده بماند.
- هیچ Production یا release اقدامی بدون تأیید صریح مالک مجاز نیست.
