# DigiArz — checkpoint شهرام ۲۲۷
تاریخ: ۲۰۲۶-۱۱-۲۸

## مبنای زنده پیش از ثبت
- Repository: `shahram-adim/DigiArz`
- PR #67: باز، Draft، ادغام‌نشده؛ `mergeable=false`
- Branch: `plan/all-catalog-assets-tradable-2026-11-27`
- HEAD پیش از این checkpoint: `ae7834802b56788f1de4cad14e138dfd41d21870`
- PR base: `main`
- Compare: واگرا؛ ۲۹۳ کامیت جلو و ۸ کامیت عقب.
- Combined commit statuses: خالی؛ PR-triggered workflow runs برای SHA بررسی‌شده: صفر. CI PASS تأیید نشده است.

## پیشرفت جدید
- [x] آزمون disposable نگاشت canonical asset به ledger key در `supabase/tests/canonical_asset_ledger_key_mapping_candidate.sql` توسعه یافت.
- [x] trigger محافظ حذف mapping اضافه شد: mapping دارای ردیف در `asset_balances` یا `order_reservations` نباید حذف شود.
- [x] آزمون منفی حذف mapping در حال استفاده اضافه شد و انتظار SQLSTATE `23514` دارد.
- [x] ترتیب شرط‌های trigger اصلاح شد تا در عملیات DELETE ابتدا شاخه مخصوص DELETE اجرا شود و خطای دقیق مورد انتظار تولید شود.
- [x] فایل از GitHub روی HEAD بازخوانی شد؛ trigger و assertion حذف در محتوا موجود است.
- [x] Workflow `.github/workflows/exact-decimal-tests.yml` بررسی شد: trigger آن `push` روی `main` و `pull_request` با base `main` است. فایل workflow مشاهده‌شده در این مرحله اجرای فایل جدید canonical-ledger candidate را در stepهای خود نشان نمی‌دهد؛ بنابراین وجود workflow به‌تنهایی به معنی اجرای این تست جدید نیست.

## محدودیت‌ها / ریسک‌های باز
- [!] تست SQL در PostgreSQL اجرا نشده؛ GitHub Actions برای HEAD بررسی‌شده run یا status قابل مشاهده برنگرداند. فقط ثبت و بازخوانی سورس تأیید است.
- [!] این triggerها candidate مخصوص disposable fixture هستند، نه migration آماده Production. قبل از طراحی deployable باید race/locking و تمام writerهای ledger بررسی شوند.
- [!] تست هنوز Market/Limit RPC، pair_id، worker settlement، cancellation، admin-disable cleanup، TP/SL و Stop-Limit را end-to-end پوشش نمی‌دهد.
- [!] PR branch همچنان ۸ کامیت از main عقب و غیرقابل‌ادغام گزارش شده؛ rebase/update branch انجام نشده است.
- [!] ۱۷ migration اعمال‌شده که منبع محلی متناظر ندارند و ۲۰ اختلاف timestamp همچنان blocker هستند.
- [!] repository-wide و Production-wide inventory همه consumerها و external writers هنوز کامل نیست.

## گام بعدی
۱. مسیر CI اختصاصی و قابل مشاهده برای اجرای setup + migration دقیق Market/Limit + mapping candidate را بررسی و به‌صورت PR-only پیشنهاد کن؛ triggerها را بدون تأیید تغییر نده.
۲. تست lifecycle رزرو را اضافه کن: رزرو فعال، مصرف جزئی، release/cancel، تکرار retry و اطمینان از عدم تغییر ledger key/asset دیگر.
۳. تست duplicate-ticker را به pair/order/trade/reservation/worker/cancel/admin-disable وصل کن؛ ابتدا source و schema دقیق هر تابع را بخوان، از حدس‌زدن نام ستون یا امضای RPC خودداری کن.
۴. فقط بعد از اجرای واقعی PostgreSQL و CI روی SHA مشخص، PASS را اعلام کن.
۵. بازیابی migrationهای مفقود و inventory بیرونی را موازی ادامه بده؛ بدون منبع معتبر، blocker را باز نگه دار.

## Release / safety gate
هیچ Production SQL/read/write، migration، DDL، backfill، re-key، تغییر balance/reservation/order/trade، worker/Cron invocation یا schedule change، Edge Function deployment، RLS/ACL/Auth، db push، merge، rebase، deploy، APK/Pages publication یا هزینه انجام نشده است.
هیچ اقدام Production یا release بدون تأیید صریح مالک مجاز نیست.
