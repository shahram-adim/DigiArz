# DigiArz — checkpoint شهرام ۲۴۵
تاریخ: ۲۰۲۶-۱۱-۲۸

## وضعیت زنده GitHub
- مخزن: `shahram-adim/DigiArz`
- PR #67 با عنوان `[Draft] Make every DigiArz catalog asset demo-tradable`: باز، Draft و ادغام‌نشده.
- شاخه: `plan/all-catalog-assets-tradable-2026-11-27`
- آخرین HEAD هنگام ثبت: `9f429034127b36db83bb812e8d1886dca7736504`
- مقایسه با main: **۳۴۲ کامیت جلو، ۸ کامیت عقب، diverged**.
- برای HEAD بالا، GitHub workflow-run lookup خالی و combined commit statuses خالی بود؛ CI هنوز PASS یا حتی اجراشده محسوب نمی‌شود.

## بازیابی Migrationها
- ۱۱ درخت شاخهٔ مرتبط (از جمله main، شاخهٔ sync، auto-list، admin audit و شاخهٔ جاری) به‌صورت recursive بررسی شد؛ درخت‌ها truncated نبودند و هیچ‌یک از ۱۷ نسخهٔ Migration مفقود را در `supabase/migrations/` نداشتند.
- این بررسی محدود به همان ۱۱ شاخه است؛ کل ۸۰ شاخه یا تمام Git objectها و artifactهای بیرونی را پوشش نمی‌دهد.
- ۱۷ منبع SQL مفقود و ۲۰ اختلاف timestamp/name همچنان unresolved و hard deployment blockers هستند. هیچ SQL از روی نام یا وضعیت زنده بازسازی نشد.

## کشف و تست جدید: NULL در fee helper
- snapshot تابع Production `get_demo_trading_fee_rate(text,text)` نشان می‌دهد guard فعلی `p_liquidity_type NOT IN ('maker','taker')` ورودی NULL را رد نمی‌کند؛ با پیکربندی فعال، CASE به ELSE می‌رود و نرخ taker را می‌دهد.
- فایل جدید `supabase/tests/canonical_fee_helper_null_regression.sql` فقط برای PostgreSQL دورریختنی است:
  - نرخ maker/taker را عمداً متفاوت می‌کند (0.002 و 0.001) تا fall-through به taker قابل مشاهده باشد.
  - رفتار snapshot فعلی را characterize می‌کند.
  - helper کاندیدای جداگانه را با guard صریح NULL می‌سازد و NULL/نوع نامعتبر را رد می‌کند.
  - نرخ‌های تنظیم‌شده، نرمال‌سازی quote و خطای quote بدون پیکربندی را بررسی می‌کند.
- تست Node در `tests/canonical-market-limit-financial-contract.test.js` به این SQL اضافه شد.
- workflow `.github/workflows/exact-decimal-tests.yml` یک database مجزای disposable برای اجرای harness جدید دارد.
- این تست به تابع Production دست نمی‌زند و رفتار فعلی Production را patch نمی‌کند.

## محدودیت اعتبارسنجی
- در محیط فعلی `psql` یا PostgreSQL محلی در دسترس نبود؛ بنابراین SQL harness این مرحله هنوز runtime اجرا نشده است.
- روی HEAD فعلی workflow run و commit status وجود نداشت؛ در نتیجه هیچ ادعای CI PASS یا SQL runtime PASS نداریم.
- تست‌های static و محتوای فایل‌ها از GitHub دوباره خوانده و بررسی ساختاری شدند؛ اجرای واقعی باید از GitHub Actions/PG17 disposable تأیید شود.

## فایل‌ها و تغییرات
- `supabase/tests/canonical_fee_helper_null_regression.sql` — تست جدید.
- `tests/canonical-market-limit-financial-contract.test.js` — guard استاتیک برای تست جدید.
- `.github/workflows/exact-decimal-tests.yml` — مرحلهٔ اجرای PostgreSQL مجزا.
- `docs/CANONICAL_MARKET_LIMIT_FINANCIAL_CONTRACT_2026-11-28.md` — شرح harness و محدودیت runtime verification.

## باقی‌مانده و گام بعد
1. ایجاد event معتبر PR update توسط مالک/تأیید اجرای workflow، سپس مشاهدهٔ run روی HEAD واقعی.
2. رفع هر خطای SQL یا Node در CI و ثبت PASS واقعی؛ تا آن زمان تست اجراشده محسوب نشود.
3. ادامهٔ بازیابی ۱۷ migration از آرشیو/backup معتبر همراه checksum و provenance.
4. تطبیق کامل ۲۰ timestamp mismatch و دو local-only migration.
5. ادامهٔ canonical identity candidate فقط روی مبنای financial source parity واقعی و fixture disposable.

## ایمنی
هیچ Production SQL اجرا نشد؛ هیچ Production schema/function/ACL/RLS/trigger/Cron/worker/Auth یا داده مالی تغییر نکرد. هیچ Migration replay، db push، merge، rebase، deploy، APK/Pages publication، Actions settings change یا هزینه‌ای انجام نشد.
