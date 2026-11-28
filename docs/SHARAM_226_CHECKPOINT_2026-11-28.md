# DigiArz — checkpoint شهرام ۲۲۶
تاریخ: ۲۰۲۶-۱۱-۲۸

## وضعیت زنده GitHub
- مخزن: `shahram-adim/DigiArz`
- PR #67: باز، Draft، ادغام‌نشده، `mergeable=false`
- شاخه: `plan/all-catalog-assets-tradable-2026-11-27`
- HEAD جدید: `32f22a302d4af7386d5833ac3ff5457b4e9328b8`
- Main: `e8477b53a1b8c6fc7225572db3e559a1c75607d8`
- Compare: واگرا؛ ۲۹۰ کامیت جلو و ۸ کامیت عقب.
- Check Runs و PR-triggered workflow runs روی HEAD جدید: صفر. CI این commit تأیید نشده است.

## پیشرفت این مرحله
- [x] فایل `supabase/tests/canonical_asset_ledger_key_mapping_candidate.sql` در شاخه PR تقویت شد.
- [x] آزمون روی همان جدول‌های authoritative `asset_balances` و `order_reservations` اجرا می‌شود؛ هیچ جدول balances موازی ایجاد نمی‌کند.
- [x] دو canonical asset با نماد نمایشی یکسان `ABC` به ledger keyهای داخلی و یکتا نگاشت می‌شوند.
- [x] نگاشت تکراری ledger key با unique constraint رد می‌شود.
- [x] mapping مبهم/تأییدنشده پیش از دسترسی مالی fail-closed می‌شود.
- [x] جداسازی موجودی و رزرو دو دارایی هم‌نماد و محاسبه available balance مستقل آزموده می‌شود.
- [x] آزمون جدید اضافه شد: تغییر نام نمایشی نباید ledger key را تغییر دهد.
- [x] آزمون جدید اضافه شد: پس از استفاده مالی از ledger key در balances یا reservations، تغییر/re-key آن باید با SQLSTATE 23514 رد شود؛ این کار مانع جا ماندن یا نسبت‌دهی مجدد موجودی و رزروهای موجود می‌شود.
- [x] فایل توسط GitHub بازخوانی شد و محتوای به‌روزشده تأیید شد.

## محدودیت شواهد
- [!] تست SQL در این نشست اجرا نشده است؛ ابزار محلی PostgreSQL/Docker در دسترس نبود و GitHub Actions نیز برای HEAD جدید run ایجاد نکرده است. بنابراین فقط «کد آزمون ثبت و بازخوانی شده» تأیید است، نه «تست PASS».
- [!] این آزمون فقط نگاشت ledger-key را در disposable fixture پوشش می‌دهد؛ هنوز Market/Limit canonical RPC و worker را به pair_id واقعی متصل نمی‌کند و اثبات end-to-end duplicate-ticker financial parity نیست.
- [!] CI workflow موجود است و روی PR branch و main وجود دارد؛ تشخیص قبلی علت عدم اجرای آخرین event را قطعی نکرده است. تنظیمات Actions یا triggerها بدون اجازه مالک تغییر داده نمی‌شود.
- [!] ۱۷ migration مفقود Production و ۲۰ اختلاف timestamp همچنان blocker بازیابی منبع‌اند.
- [!] inventory کامل Production و external service-role/Edge Function/Cron writerها همچنان باز است.

## گام بعدی
۱. اجرای قابل مشاهدهٔ همین workflow روی HEAD دقیق `32f22a3` را از مسیر عادی و مجاز GitHub پیگیری کن؛ تا آن زمان PASS اعلام نکن.
۲. پس از CI، تست mapping را با آزمون‌های order/reservation lifecycle ادغام کن: تغییر وضعیت mapping، لغو، مصرف جزئی، release، worker retry و race.
۳. سپس canonical Market/Limit entrypoints را روی همان authoritative ledger fixture طراحی و پیاده‌سازی کن؛ RPC باید pair_id بگیرد و تمام price/order/trade/reservation/worker/cancel مسیرها pair_id و asset_id را نگه دارند.
۴. منبع دقیق migrationهای مفقود و deployed writer fingerprints را بازیابی کن؛ در نبود سند معتبر، blocker باز بماند.

## Release / safety gate
هیچ Production SQL/write، business-row read، migration، DDL، backfill، re-key، balance/reservation تغییر، worker/Cron invocation یا تغییر schedule، Edge Function deployment، RLS/ACL/Auth، db push، merge، rebase، deploy، APK/Pages publication یا هزینه انجام نشده است.
هیچ اقدام Production یا release بدون تأیید صریح مالک مجاز نیست.
