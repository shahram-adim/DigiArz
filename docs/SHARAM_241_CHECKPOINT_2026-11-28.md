# DigiArz — checkpoint شهرام ۲۴۱
تاریخ: ۲۰۲۶-۱۱-۲۸

## وضعیت
- مخزن: `shahram-adim/DigiArz`
- PR #67: باز و Draft؛ ادغام نشده.
- شاخه: `plan/all-catalog-assets-tradable-2026-11-27`
- آخرین تغییر این مرحله: `3fbafddd181913808ecb5d69ea4aa9f9425dfac6`
- سند قرارداد مالی پس از تغییر باید از GitHub دوباره خوانده شود.
- هیچ اجرای CI جدیدی در این مرحله ادعا نمی‌شود.

## یافتهٔ فنی جدید
در تابع snapshot واقعی `get_demo_trading_fee_rate(text,text)`، شرط:
`IF p_liquidity_type NOT IN ('maker', 'taker') THEN ...`
ورودی NULL را رد نمی‌کند؛ در PostgreSQL عبارت NULL NOT IN (...) برابر NULL است و شرط IF اجرا نمی‌شود. در صورت وجود fee row فعال برای quote، CASE به ELSE می‌رسد و نرخ taker برمی‌گرداند. بنابراین NULL به‌اشتباه به‌عنوان taker پذیرفته می‌شود.

این نقص در `docs/CANONICAL_MARKET_LIMIT_FINANCIAL_CONTRACT_2026-11-28.md` ثبت شد.
- این یک یافتهٔ source-derived است، نه تغییر رفتار مطلوب.
- تابع Production دست‌نخورده ماند.
- parity baseline نباید بی‌صدا تغییر کند.
- نسخهٔ canonical آینده باید NULL را صریحاً رد کند و تست disposable جداگانه برای آن داشته باشد؛ در کنار حفظ maker/taker و quote normalization.

## وضعیت تست‌های قبلی
- تست precision-edge Market شامل کنترل wallet delta، RPC payload، trade journal و transaction journal است.
- فایل تست قبلی آخرین بار روی blob `060e63f215c166932f0cdbece2adb59fd1eb94aa` تأیید شده بود.
- هنوز CI معتبر برای آخرین SHA نداریم؛ PASS runtime اعلام نمی‌شود.

## باقی‌مانده
1. بررسی Actions policy/workflow enablement و event delivery توسط مالک repo؛ تنظیمات را بدون اجازه تغییر نده.
2. اجرای CI معتبر روی HEAD و بررسی logها.
3. بازیابی ۱۷ migration مفقود و تطبیق ۲۰ timestamp mismatch.
4. تکمیل Production schema/constraints/indexes/triggers/RLS/grants و fee configuration.
5. در طراحی canonical candidate، NULL liquidity type را fail-closed کن و تست جداگانه اضافه کن.

## ایمنی
- فقط سند قرارداد مالی در PR Draft تغییر کرد.
- هیچ Production SQL/migration اجرا نشد؛ هیچ داده مالی، wallet، balance، order، trade، reservation، fee row، Cron، worker، Auth، RLS/ACL یا Edge Function تغییر نکرد.
- هیچ Merge، rebase، db push، deployment، APK/Pages publication، تغییر تنظیمات Actions یا هزینه‌ای انجام نشد.
