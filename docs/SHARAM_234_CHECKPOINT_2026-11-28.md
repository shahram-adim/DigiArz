# DigiArz — checkpoint شهرام ۲۳۴
تاریخ: ۲۰۲۶-۱۱-۲۸

## وضعیت شروع
- PR #67: open، Draft، unmerged، mergeable=false.
- Branch: `plan/all-catalog-assets-tradable-2026-11-27`.
- HEAD مبنا: `5177832e7a3a86214afe76effaa0e0a3824acfdd`.
- checkpoint ۲۳۳ از GitHub بازخوانی شد.
- بررسی runهای قبلی نشان داد Actions PR metadata می‌تواند head فعلی PR را در runهای قدیمی نمایش دهد؛ run SHA واقعی باید جداگانه بررسی شود. هیچ‌یک از runهای قبلی به‌عنوان PASS تغییر جدید استفاده نشد.

## کشف مهم
- snapshot واقعی Production برای `public.process_limit_orders()` از قبل در شاخه موجود بود:
  `supabase/tests/stop_limit_production_process_limit_orders_snapshot.sql`
- منبع: `pg_get_functiondef('public.process_limit_orders()'::regprocedure)`، capture 2026-11-26.
- fingerprint: `00ab429596fb99392666632967cde9c0`.
- metadata ثبت‌شده: owner=postgres، SECURITY DEFINER، search_path خالی، EXECUTE فقط برای service_role.
- فایل source contract مستقل `tests/stop-limit-production-limit-worker-source.test.js` fingerprint و رفتارهای lock/fresh-price/reservation/settlement را assert می‌کند.
- بنابراین blocker «نبود snapshot worker» رفع شد؛ اما این snapshot همان worker ticker-based فعلی است و canonical ID ندارد.

## تغییرات این مرحله
1. Workflow `.github/workflows/exact-decimal-tests.yml` در مرحلهٔ «Run real two-session Limit worker and cancellation race tests» اکنون پس از cancellation snapshot، snapshot واقعی `process_limit_orders()` را هم در disposable PostgreSQL بارگذاری می‌کند.
   - race از این پس worker Production snapshot + cancellation Production snapshot را اجرا می‌کند، نه Draft worker.
   - blob workflow پس از تغییر: `72b7db61f01af760834770d2771c7e4fb90509e0`.
2. `tests/cancel-limit-production-snapshot.test.js` گسترش یافت تا:
   - fingerprint و تعریف worker snapshot را کنترل کند؛
   - وجود هر دو snapshot در race workflow را الزام کند؛
   - عدم بارگذاری `2026-11-15_exact_decimal_process_limit_orders.sql` در همان race را assert کند.
   - blob تست: `f9bf26cd930e86c9e8e5a1df96b911484bad8a8a`.

## مرزبندی تست‌ها
- مرحلهٔ «exact-decimal Limit worker integration» همچنان Draft candidate را برای تست candidate behavior اجرا می‌کند؛ عمداً به آن دست نزدیم.
- مرحلهٔ race لغو سفارش، worker ثبت‌شدهٔ Production را در کنار cancellation snapshot ثبت‌شدهٔ Production اجرا می‌کند.
- setup همچنان schema آزمایشی subset است؛ این تست parity کامل schema/trigger/ACL/RLS/تمام writerهای Production را اثبات نمی‌کند.
- worker Production هنوز symbol/ticker-keyed است؛ `v_base_asset` از ticker استخراج و ledger در `asset_balances.asset` با متن ticker به‌روزرسانی می‌شود. این تست جداسازی دارایی‌های canonical هم‌نماد را اثبات نمی‌کند.
- snapshot worker محاسبهٔ gross/fee/net را بدون quantization صریح ۸ رقم انجام می‌دهد؛ این نقص حسابداری شناخته‌شده است و در این مرحله تغییر نکرد.

## CI و وضعیت
- Workflow روی pull_request به main اجرا می‌شود و push فقط برای main تنظیم شده است؛ بنابراین باید اجرای جدید PR synchronize شود.
- هنوز نتیجهٔ CI برای HEAD جدید در لحظهٔ ثبت checkpoint مشاهده نشده است؛ هیچ PASS runtime ادعا نمی‌شود.
- PR همچنان Draft و ادغام‌نشده است.

## گام بعدی
1. اجرای جدید PR را با run SHA واقعی و commit ancestry بررسی کن؛ Node tests و race step باید روی commit جدید موفق باشند.
2. اگر race fail شد، خطای compile/fixture را در محیط disposable اصلاح کن؛ هیچ production تغییر نده.
3. پس از تست واقعی، schema fixture را با metadata ثبت‌شدهٔ Production reconcile کن و سپس canonical-ID architecture را در تمام writerها و readerها طراحی کن. mapping helper مستقل کافی نیست.

## ایمنی
فقط فایل workflow، تست regression و این checkpoint در شاخهٔ Draft تغییر کردند. هیچ Production SQL، migration، db push، business-row read/write، balance/order/trade/reservation mutation، worker/Cron schedule/invocation، RLS/ACL/Auth، merge، rebase، deployment، APK/Pages publication یا هزینه‌ای انجام نشد.