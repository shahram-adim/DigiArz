# DigiArz — checkpoint شهرام ۲۳۱
تاریخ: ۲۰۲۶-۱۱-۲۸

## وضعیت مبنا و PR
- Repository: `shahram-adim/DigiArz`
- PR #67: open، Draft، unmerged، `mergeable=false`
- Branch: `plan/all-catalog-assets-tradable-2026-11-27`
- HEAD نهایی این checkpoint: `15656005399e70161554a86d8778a3f4b0bd1d6a`
- Base SHA گزارش‌شده توسط PR: `fbfb5e974e754088a32c9fdcd76fc2ca9ab0f98b`
- روی HEAD نهایی: Actions runs=0، check-runs=0، combined statuses خالی.

## کشف منبع معتبر cancellation
- فایل `supabase/tests/stop_limit_production_cancel_limit_order_snapshot.sql` در main و شاخهٔ PR موجود است.
- منبع فایل: `pg_get_functiondef('public.cancel_limit_order(uuid)'::regprocedure)`، capture date: 2026-11-26.
- fingerprint ثبت‌شده در snapshot: `69360684173b6aabebc5ff4e4de2eed9`؛ این با fingerprint مستند در ممیزی مالی Production تطابق دارد.
- blob در شاخهٔ PR: `18c363097173939429756f56fe9773e554937f39`.
- snapshot تابع کامل `public.cancel_limit_order(p_order_id uuid)` را شامل می‌شود؛ owner=postgres، SECURITY DEFINER، search_path خالی و metadata اجرای ثبت‌شده anon=false/authenticated=true/service_role=true.
- این فایل صرفاً fixture برای PostgreSQL موقت است؛ migration یا SQL قابل اجرا روی Production نیست.

## تغییرات این مرحله
1. `supabase/tests/exact_decimal_cancel_setup.sql`
   - تعریف synthetic تابع `public.cancel_limit_order` حذف شد.
   - helper مورد نیاز `auth.uid()` باقی ماند.
   - blob جدید: `030cbb310b6ebff8f09ad52f067c5d339023fa42`.
2. `.github/workflows/exact-decimal-tests.yml`
   - قبل از تست lifecycle لغو و قبل از تست race دو نشست، snapshot ثبت‌شدهٔ Production پس از helper setup بارگذاری می‌شود.
   - snapshot در دو محل workflow استفاده می‌شود.
   - blob جدید: `42e070d61b6ff4b39a5eea531dd1685a259f44f0`.
3. `tests/cancel-limit-production-snapshot.test.js`
   - regression guard جدید برای fingerprint، تعریف واقعی تابع، SECURITY DEFINER/search_path، قفل سفارش، شرط دقیق یک رزرو معتبر، حذف stub synthetic و اتصال snapshot به هر دو مرحلهٔ workflow اضافه شد.
   - blob: `0306a554fdb17644012fdeaffeb677b8c77a0cd2`.

## نتیجه و محدودیت
- [x] منبع cancellation واقعیِ capture‌شده در Production بازیابی و fingerprint آن با ممیزی قبلی تطبیق داده شد.
- [x] fixture مصنوعی cancellation از setup حذف شد.
- [x] workflow lifecycle و race به snapshot واقعی متصل شد.
- [x] guard ایستا برای جلوگیری از بازگشت stub اضافه شد.
- [ ] اجرای Node test و PostgreSQL lifecycle/race توسط CI روی HEAD دقیق هنوز انجام/تأیید نشده است؛ API روی SHA نهایی در لحظهٔ ثبت، Actions=0 و Check Runs=0 نشان داد.
- [ ] این تغییر فقط cancellation source parity را تقویت می‌کند؛ canonical pair_id و جداسازی دو دارایی هم‌نماد هنوز در Market/Limit RPCها و workerها پیاده نشده است.
- [ ] schema fixture فعلی همچنان subset آزمایشی است و parity کامل schema/constraints/triggers/RLS/ACL Production را اثبات نمی‌کند.

## گام بعدی
1. بررسی CI دقیق روی SHA بالا و رفع هر شکست در Node یا PostgreSQL disposable.
2. اگر source snapshot cancellation و race سبز شدند، بررسی نسخهٔ واقعی `cancel_limit_order` در برابر schema/trigger/constraintهای لازم و سپس طراحی candidate canonical-aware؛ تا پیش از بازیابی schema کامل و منبع تمام writerها، از ساخت ledger موازی خودداری شود.
3. آزمون duplicate-ticker باید همان RPC/workerهای candidate واقعی را اجرا کند، نه صرفاً helper mapping.

## ایمنی
فقط فایل‌های تست و workflow در شاخهٔ Draft تغییر کردند. هیچ Production query/write، migration، db push، wallet/balance/order/trade/reservation change، worker/Cron invocation یا schedule change، Edge Function، RLS/ACL/Auth، merge، rebase، deployment، APK/Pages publication یا هزینه‌ای انجام نشد. PR همچنان Draft و ادغام‌نشده است.