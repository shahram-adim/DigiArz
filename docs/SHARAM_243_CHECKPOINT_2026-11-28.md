# DigiArz — checkpoint شهرام ۲۴۳
تاریخ: ۲۰۲۶-۱۱-۲۸

## وضعیت زنده
- Repo: `shahram-adim/DigiArz`
- PR #67: باز، Draft و ادغام‌نشده.
- Branch: `plan/all-catalog-assets-tradable-2026-11-27`
- آخرین HEAD بررسی‌شده پیش از مستندسازی: `ab8de02fae3b9454801b0b05151ce322c129d655`
- Compare با main: ۳۳۰ ahead و ۸ behind؛ وضعیت diverged.
- پس از ثبت این checkpoint و commit مستندات، compare و CI باید دوباره بررسی شوند.

## بازیابی Migration
- سند `supabase/MIGRATION_RECONCILIATION.md` به‌روزرسانی شد.
- جست‌وجوی مجدد نسخه‌های دقیق `20261121045434`, `20261121045531`, `20261121050216` فقط ارجاعات مستنداتی/وضعیت را برگرداند، نه بدنه SQL معتبر.
- سه Migration فوق همچنان unresolved هستند.
- شمار تاریخی ۱۷ منبع SQL اعمال‌شدهٔ مفقود و ۲۰ اختلاف timestamp/name پابرجاست؛ در این مرحله Supabase ledger زنده دوباره query نشد.
- هیچ SQL از روی نام یا وضعیت زنده بازسازی نشده است.

## تشخیص CI
فایل `.github/workflows/exact-decimal-tests.yml` با blob SHA `72b7db61f01af760834770d2771c7e4fb90509e0` خوانده شد:
- push فقط روی main.
- pull_request با base=main.
- تست Node با الگوی `node --test tests/*.test.js` اجرا می‌شود و تست static جدید fee helper در این الگو قرار دارد.
- trigger از نوع workflow_dispatch تعریف نشده است.
- روی HEAD فوق workflow run و combined status قابل مشاهده نبود.
- علت عدم dispatch اثبات نشده؛ workflow و Actions settings دست‌نخورده ماندند. بررسی Actions enablement/permissions و ایجاد رویداد PR update باید توسط مالک انجام شود.

## تغییرات این مرحله
- commit مستندات Migration/CI: `4ee6500f5be7cc49c8dae63c0c6df79e0198db29`
- فایل تغییرکرده: `supabase/MIGRATION_RECONCILIATION.md`
- هدف: ثبت محدودیت‌های بازیابی منبع و تشخیص دقیق trigger CI، بدون تغییر workflow.

## گام‌های بعد
1. تأیید مالک برای push عادی و کنترل‌شده روی PR جهت ایجاد رویداد `pull_request` و بررسی Actions permissions.
2. بازیابی ۱۷ فایل SQL مفقود از artifact/backup معتبر و تطبیق checksum/source.
3. تطبیق کامل ۲۰ فایل timestamp-mismatch.
4. ساخت schema parity کامل در PostgreSQL 17 دورریختنی؛ بدون اتصال به Production.
5. اجرای تست‌های PR پس از فعال شدن CI؛ عدم ادعای PASS تا مشاهده run موفق.

## ایمنی
هیچ Supabase query یا SQL اجرا نشد؛ هیچ Production schema/function/ACL/RLS/trigger/Cron/worker/Auth یا داده مالی تغییر نکرد. هیچ migration replay، db push، merge، rebase، deploy، APK/Pages publication، Actions settings change یا هزینه‌ای انجام نشد.
