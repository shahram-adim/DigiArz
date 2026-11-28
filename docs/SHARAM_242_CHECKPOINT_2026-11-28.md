# DigiArz — checkpoint شهرام ۲۴۲
تاریخ: ۲۰۲۶-۱۱-۲۸

## وضعیت
- مخزن: `shahram-adim/DigiArz`
- PR #67: باز، Draft و ادغام‌نشده.
- شاخه: `plan/all-catalog-assets-tradable-2026-11-27`
- آخرین commit تغییر تست: `3ac9da091a3f8ce4eacd6be110ae2f3bdf44275b`
- فایل تست پس از تغییر از GitHub دوباره خوانده شد؛ blob SHA: `797f1df7063753f1dc2c3a4128ac5f5366362be6`.

## کار انجام‌شده
در `tests/canonical-market-limit-financial-contract.test.js` یک static source-contract test افزوده شد تا:
1. guard فعلی snapshot تابع Production fee را استخراج کند.
2. وجود `p_liquidity_type NOT IN ('maker','taker')` را ثبت کند.
3. نبود بررسی صریح `IS NULL` را ثبت کند.
4. مسیر ELSE به نرخ taker را در snapshot تأیید کند.
5. وجود توضیح نقص و الزام fail-closed در قرارداد مالی را کنترل کند.

این تست برای حفظ شواهد نقص فعلی و جلوگیری از ادعای اشتباه fail-closed بودن snapshot است؛ **تست اصلاح‌شدن تابع نیست** و انتظار ندارد snapshot فعلی رفتار صحیح داشته باشد. تابع Production و parity fixture دست‌نخورده‌اند.

## اعتبارسنجی
- تغییر از GitHub reread و regexها از نظر متنی اصلاح و تأیید شدند.
- اجرای محلی Node test یا CI در این مرحله انجام نشده؛ PASS runtime ادعا نمی‌شود.
- آخرین بررسی workflow روی checkpoint قبلی بدون run و status بود. لازم است وضعیت Actions روی SHA جدید دوباره بررسی شود.

## باقی‌مانده
1. اجرای `node --test tests/canonical-market-limit-financial-contract.test.js` در CI معتبر و بررسی log.
2. افزودن تست runtime disposable برای candidate آینده که NULL را رد کند؛ نه تغییر baseline snapshot.
3. بازیابی ۱۷ migration مفقود و تطبیق ۲۰ اختلاف timestamp.
4. تکمیل schema/constraints/indexes/triggers/RLS/grants و fee configuration واقعی.
5. حل فاصله شاخه با main در زمان مناسب؛ بدون rebase یا merge خودکار.

## ایمنی
- فقط تست static در PR Draft تغییر کرد.
- هیچ Production SQL/migration اجرا نشد؛ هیچ داده مالی، wallet, balance, order, trade, reservation, fee config, Cron, worker, Auth, RLS/ACL یا Edge Function تغییر نکرد.
- هیچ Merge، rebase، db push، deployment، APK/Pages publication، تغییر تنظیمات Actions یا هزینه‌ای انجام نشد.
