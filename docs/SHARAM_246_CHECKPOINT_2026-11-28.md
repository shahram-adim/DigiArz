# DigiArz — checkpoint شهرام ۲۴۶
تاریخ: ۲۰۲۶-۱۱-۲۸

## وضعیت زنده
- PR #67: باز، Draft، ادغام‌نشده؛ base برابر main.
- شاخه: `plan/all-catalog-assets-tradable-2026-11-27`.
- HEAD هنگام ایجاد این checkpoint: `5166163671d71da051ca31a8b5d45210ead9b1a0`.
- آخرین مقایسه پیش از تغییر workflow: ۳۴۳ جلو و ۸ عقب از main، diverged.
- برای HEAD قبلی `8f74cc06e18206bd95eaf1478f6483507b13301e`، workflow-run lookup و combined status خالی بود.

## تغییر این مرحله
در `.github/workflows/exact-decimal-tests.yml`، trigger دستی `workflow_dispatch:` اضافه شد تا مالک مخزن بتواند Workflow تست‌ها را از تب Actions به‌صورت دستی اجرا کند، حتی اگر رویداد PR از مسیر connector اجرا نشود.
- triggerهای موجود push روی main و pull_request به main حفظ شدند.
- مرحلهٔ PostgreSQL disposable برای تست NULL در fee helper همچنان موجود است.
- این تغییر صرفاً تنظیم trigger در فایل Workflow شاخهٔ Draft است؛ تنظیمات Repository/Actions یا Production را تغییر نمی‌دهد.
- از اینجا ابزار متصل امکان اجرای مستقیم workflow dispatch را در اختیار نداشت؛ اجرای دستی باید توسط مالک در GitHub Actions انجام شود.

## تست fee helper
- تست SQL جدید رفتار NULL در snapshot تابع را characterize می‌کند و candidate صریحاً NULL/نوع نامعتبر را رد می‌کند.
- نرخ‌های fixture عمداً متفاوت هستند: maker=0.002 و taker=0.001.
- تست Node ساختار harness را بررسی می‌کند.
- هنوز اجرای واقعی PostgreSQL/CI ثبت نشده؛ هیچ PASS ادعا نمی‌شود.

## Migration recovery
- ۱۷ منبع SQL مفقود و ۲۰ timestamp/name mismatch هنوز unresolved هستند.
- بررسی درخت ۱۱ شاخهٔ مرتبط، نسخهٔ SQL متناظر را پیدا نکرد؛ این نتیجه تمام ۸۰ شاخه یا artifactهای بیرونی را پوشش نمی‌دهد.
- هیچ Migration از روی نام بازسازی یا replay نشده است.

## گام بعد
1. مالک از GitHub Actions، workflow با نام Exact decimal tests را با workflow_dispatch اجرا کند.
2. run و logهای تست SQL/Node بررسی و خطاها اصلاح شوند.
3. ۱۷ منبع Migration از آرشیو/backup معتبر با provenance و checksum بازیابی شوند.
4. ۲۰ اختلاف timestamp/name و دو local-only مورد تطبیق قرار گیرند.

## ایمنی
هیچ Supabase Production SQL، migration، db push، schema/function/ACL/RLS/trigger/Cron/worker/Auth یا دادهٔ مالی تغییر نکرد. هیچ merge، rebase، deploy، انتشار APK/Pages، تغییر تنظیمات Repository، یا هزینه‌ای انجام نشد.
