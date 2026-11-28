# DigiArz — checkpoint شهرام ۲۳۰
تاریخ: ۲۰۲۶-۱۱-۲۸

## وضعیت مبنا
- Repository: `shahram-adim/DigiArz`
- PR #67: باز، Draft، ادغام‌نشده، `mergeable=false`
- Branch: `plan/all-catalog-assets-tradable-2026-11-27`
- HEAD مبنا پیش از این checkpoint: `fca6be28d3d924e7a2724c6bca261ebefe1e1c46`
- Main در مقایسهٔ قبلی: `e8477b53a1b8c6fc7225572db3e559a1c75607d8`
- Compare قبلی: diverged، ۲۹۷ جلو و ۸ عقب.
- برای SHA مبنا: Actions runs=0، check-runs=0، combined statuses خالی.

## کار تکمیل‌شده در این مرحله
- فایل `tests/canonical-ledger-identity-integration-gate.test.js` بازبینی شد.
- در آزمون دوم، الگوهای RegExp بیش از حد escape شده بودند: به‌جای تشخیص نقطه/فاصله‌سفید و هر کاراکتر، دنبال backslash literal می‌گشتند. بنابراین assertionهای امضای RPC و join قیمت worker می‌توانستند به‌صورت نادرست شکست بخورند.
- الگوها اصلاح شدند تا امضای واقعی `p_symbol text`، join با `mp.symbol = v_order.symbol` و نبود pair_id/canonical resolver را درست تشخیص دهند.
- blob جدید فایل تست: `c891fae4bda2869e20a316283e6b863250bcdb49`.
- معادل assertionهای اصلی تست روی migration واقعی اجرا شد: ۱۰ از ۱۰ assertion درست ارزیابی شدند. این اجرای دستی معادل الگوهاست، نه اجرای کامل `node --test` و نه CI.

## نتیجهٔ منبع‌کاوی تکمیلی
- workflow و تست‌های موجود هنوز migration authoritative Market/Limit را روی scaffold disposable اجرا می‌کنند؛ scaffold شامل fee helper ثابت 0.1% است و full Production schema/ACL/RLS/trigger parity را ثابت نمی‌کند.
- فایل `exact_decimal_cancel_setup.sql` تابع `cancel_limit_order` را خودش تعریف می‌کند؛ بنابراین تست cancellation فعلی source-parity تابع Production نیست.
- در فهرست فایل‌های تغییرکردهٔ PR، snapshot مستقل `cancel_limit_order` وجود ندارد. snapshot لغو Stop-Limit تنها wrapperای را نشان می‌دهد که به `cancel_limit_order` فراخوانی می‌زند؛ این برای بازیابی بدنهٔ دقیق تابع کافی نیست.
- مستندات source recovery همچنان ۱۷ migration اعمال‌شدهٔ بدون منبع محلی و ۲۰ اختلاف timestamp را ثبت می‌کنند. fixtureهای disposable جایگزین DDL معتبر Production نیستند.
- در نتیجه، پیاده‌سازی candidate مالی end-to-end در این مرحله متوقف شد تا از ساختن schema موازی یا حدس‌زدن ستون‌ها/قیود/triggerها جلوگیری شود. مسیر مجاز بعدی، بازیابی منبع معتبر تابع لغو و schema/migrationهای پایه، سپس ساخت candidate روی ledger واقعی در PostgreSQL disposable است.

## وضعیت پس از تغییر فایل تست
- [x] RegExpهای معیوب در blocker test اصلاح شدند.
- [x] ۱۰ assertion معادل با migration واقعی به‌صورت دستی بررسی شدند.
- [ ] اجرای کامل Node test توسط CI روی commit جدید هنوز تأیید نشده است.
- [ ] PostgreSQL candidate lifecycle برای دو دارایی هم‌نماد هنوز ساخته/اجرا نشده است.
- [ ] cancellation واقعی Production source هنوز بازیابی نشده است.

## ایمنی و release gate
فقط یک فایل تست در شاخهٔ Draft تغییر کرد. هیچ Production SQL/read/write، migration، db push، backfill، re-key، wallet/balance/reservation/order/trade change، worker/Cron invocation یا schedule change، Edge Function، RLS/ACL/Auth، merge، rebase، deployment، APK/Pages publication یا هزینه‌ای انجام نشد.