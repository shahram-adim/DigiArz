# DigiArz — checkpoint شهرام ۲۴۷
تاریخ: ۲۰۲۶-۱۱-۲۸

## وضعیت مخزن
- PR #67 باز، Draft و ادغام‌نشده؛ مقصد main.
- شاخه: `plan/all-catalog-assets-tradable-2026-11-27`.
- تغییر این مرحله: ایجاد `docs/MIGRATION_REPLAY_BLOCKER_MANIFEST_2026-11-28.md` برای یکپارچه‌سازی فهرست Migrationهای مسدودکننده.
- Commit ایجاد manifest: `edc369b233d0d8f99e7325f6e809309995a8a237`.
- HEAD پیش از ایجاد این checkpoint: `edc369b233d0d8f99e7325f6e809309995a8a237`.

## کار انجام‌شده
- درخت Git شاخه main مستقیماً بررسی شد: دقیقاً ۴۰ فایل SQL در `supabase/migrations/`.
- فهرست ۱۷ Migration اعمال‌شده با منبع SQL بازیابی‌نشده، ۲۰ اختلاف timestamp/name و دو فایل local-only در یک سند واحد گردآوری شد.
- سند تصریح می‌کند ledger عدد ۵۵ و inventory مربوط به ۱۷/۲۰/۲ فقط بر اساس ممیزی تاریخی ثبت‌شده است؛ در این مرحله Supabase دوباره query نشده است.
- خطر regression دو فایل KuCoin/Gate.io و لزوم حفظ cap 515 در reconciliation ذکر شد.
- پروتکل بازیابی با provenance و checksum و replay صرفاً در PostgreSQL 17 دورریختنی مستند شد.

## محدودیت‌ها
- هیچ SQL مفقودی بازسازی نشد.
- ۲۰ اختلاف filename با تغییر نام یا تغییر ledger حل نشد.
- هیچ CI یا تست PostgreSQL جدیدی در این مرحله اجرا نشد.
- علت نبود اجرای CI روی آخرین HEAD همچنان اثبات نشده است.

## گام بعد
1. بازیابی منبع دقیق ۱۷ Migration از deployment artifact/backup/آرشیو معتبر و ثبت checksum.
2. تطبیق محتوایی ۲۰ فایل timestamp-mismatch با نسخه‌های اعمال‌شده.
3. بررسی دو فایل local-only برای جلوگیری از بازگرداندن تعریف قدیمی refresh_market_prices.
4. اجرای تست‌ها فقط در محیط disposable پس از بازیابی source معتبر.

## ایمنی
هیچ اتصال یا query به Supabase، SQL execution، migration replay، db push، تغییر Production، cron/worker، merge، deploy، انتشار APK/Pages، تغییر تنظیمات GitHub یا هزینه‌ای انجام نشد.
