# DigiArz — checkpoint شهرام ۲۳۹
تاریخ: ۲۰۲۶-۱۱-۲۸

## وضعیت زنده GitHub
- مخزن: `shahram-adim/DigiArz`
- PR #67: همچنان PR باز و Draft؛ ادغام نشده است.
- شاخه: `plan/all-catalog-assets-tradable-2026-11-27`
- آخرین commit کد در این مرحله: `a1c4cb705fc7d3402c88f88d99f6375cce133715`
- Compare با main پس از commit کد: ahead=322، behind=8، status=diverged.
- اجرای PR workflow و combined commit statuses برای commit کد خالی است؛ هیچ نتیجه runtime برای تست جدید موجود نیست.

## تغییر این مرحله
فایل `supabase/tests/authoritative_market_limit_source_parity.sql` با commit `a1c4cb705fc7d3402c88f88d99f6375cce133715` به‌روزرسانی شد.
- تست جدید رفتار گردکردن صریح Market را با amount=`0.123456789` و price=`1.23456789` پوشش می‌دهد.
- gross مورد انتظار پس از round به ۸ رقم اعشار: `0.15241579`.
- fee مورد انتظار پس از round به ۸ رقم اعشار و نرخ fixture برابر 0.001: `0.00015242`.
- کاهش مورد انتظار موجودی کیف پول: `0.15256821`.
- تست از همان entrypoint authoritative `execute_demo_trade` و fixture PostgreSQL دورریختنی استفاده می‌کند؛ این تست هیچ ادعایی دربارهٔ اجرای Production ندارد.
- فایل پس از commit دوباره از GitHub خوانده شد؛ blob SHA برابر `d8534bd589380a9ba72dbba02de828726bbb03d4` و عبارت/assertion جدید تأیید شد.

## تفسیر و محدودیت
- این تست صرفاً قرارداد گردکردن Market را تقویت می‌کند.
- گردکردن Market نباید به Limit تعمیم داده شود؛ migration authoritative Limit worker در هر fill همان فرمول مستقیم خود را دارد و تغییر آن تغییر رفتار مالی محسوب می‌شود.
- تست جدید هنوز در CI اجرا نشده است؛ PASS runtime اعلام نمی‌شود.
- تست Maker/Taker و نرمال‌سازی quote از مرحلهٔ قبلی نیز هنوز منتظر CI معتبر است.

## گام بعد
1. رفع ابهام عدم اجرای GitHub Actions از مسیر مالک repo: بررسی Actions policy، workflow enablement، permissions و PR synchronize event delivery؛ بدون تغییر تنظیمات تا تأیید مالک.
2. پس از run معتبر، بررسی دقیق head SHA و log مرحلهٔ Market/Limit parity.
3. ادامهٔ بازیابی ۱۷ migration مفقود و تطبیق ۲۰ timestamp mismatch.
4. تکمیل schema/constraints/RLS/ACL واقعی fee configuration و توسعهٔ harness canonical روی همان wallet/base-ledger/reservation/journal واقعی؛ mapping مبهم باید fail-closed بماند.

## ایمنی
- فقط فایل تست در PR Draft تغییر کرد.
- هیچ SQL یا migration روی Production اجرا نشد.
- هیچ wallet، balance، order، trade، reservation، fee row، Cron، worker، Auth، RLS/ACL یا Edge Function تغییری نکرد.
- هیچ merge، rebase، db push، deployment، انتشار APK/Pages یا هزینه‌ای انجام نشد.
