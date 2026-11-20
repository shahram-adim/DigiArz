# طرح بازسازی محیط آزمون وفادار به منبع برای رقابت غیرفعال‌سازی حساب — ۲۱ نوامبر ۲۰۲۶

## هدف و مرز ایمنی

ساخت یک PostgreSQL 17 کاملاً موقت در GitHub Actions برای آزمودن interleaving بین `deactivate_my_account()` و چهار RPC واقعی کاربرمحور:

- `execute_demo_trade(text,text,numeric,numeric)` — Market
- `place_limit_order(text,text,numeric,numeric)` — Limit
- `place_conditional_exit_order(text,text,numeric,numeric)` — TP/SL
- `place_stop_limit_order(text,text,numeric,numeric,numeric)` — Stop-Limit

این طرح مجوز تغییر Production نیست. هیچ migration یا RPC اصلی نباید برای ایجاد barrier آزمایشی دست‌کاری شود. PR #38 فعلاً فقط آزمون primitive هم‌زمانی باقی می‌ماند.

## منابع واقعی که در ۲۱ نوامبر دوباره fetch شدند

| منبع | ref | blob SHA |
|---|---|---|
| Market و Limit entrypoints | `main` | `de09b1cd391790fcd9d94708a916cb41cd9ccc9f` |
| TP/SL و نسخهٔ deactivation | `main` | `3360c21a69b7fae83a7f2494428367d1b7658e81` |
| Stop-Limit و نسخهٔ deactivation | `main` | `3f421c6380630d74b846cd66dc7b121786237c0f` |
| Workflow فعلی | `main` | `50936f9c8b59a44112ae59730092a91b0d2d17d8` |
| Stop-Limit fixture setup | `main` | `6e0a714bcb8463f15f9cc89e963be79293d99737` |
| TP/SL fixture setup | `main` | `8e2b8a8cda3f77c4bbebd18b444c1acbd9c99b95` |
| PR #38 race setup | `test/account-deactivation-order-race` | `e12ec74f3baf845f0063bfea190f3e11530db921` |

## نقشهٔ وابستگی entrypointها

### Market
- RPC: `public.execute_demo_trade`
- جدول‌ها/داده‌ها: `profiles` از مسیر active-check، `demo_trading_pairs`، `market_prices`، `wallets`، `asset_balances`، `order_reservations`، `orders`، `trades`، `transactions`.
- helperهای مشاهده‌شده: `auth.uid()`، `public.current_account_is_active()`، `public.get_demo_trading_fee_rate()`.

### Limit
- RPC: `public.place_limit_order`
- جدول‌ها: `profiles` از مسیر active-check، `demo_trading_pairs`، `wallets`، `asset_balances`، `order_reservations`، `orders`.
- helperها: `auth.uid()`، `public.current_account_is_active()`، `public.get_demo_trading_fee_rate()`.

### TP/SL
- RPC: `public.place_conditional_exit_order`
- جدول‌ها: `profiles` از مسیر active-check، `demo_trading_pairs`، `wallets`، `asset_balances`، `order_reservations`، `orders`، `conditional_orders`.
- helperها: `auth.uid()`، `public.current_account_is_active()`، `public.get_demo_trading_fee_rate()`.
- برای چرخهٔ کامل باید رفتار لغو و پاک‌سازی conditionalها نیز با تعریف واقعی سنجیده شود.

### Stop-Limit
- RPC: `public.place_stop_limit_order`
- جدول‌ها: `profiles` از مسیر active-check، `demo_trading_pairs`، `wallets`، `asset_balances`، `order_reservations`، `orders`، `conditional_orders`.
- helperها: `auth.uid()`، `public.current_account_is_active()`، `public.get_demo_trading_fee_rate()`.
- worker/child lifecycle به `place_limit_order()` و `cancel_limit_order()` متصل است؛ این‌ها dependency سطح دوم‌اند و نباید با stub بی‌اثر شوند.

### Deactivation
- دو تعریف در TP/SL و Stop-Limit migration وجود دارد. نسخهٔ نهایی انتخاب‌شده باید از snapshot مشخص‌شده در آزمون استخراج و با نسخهٔ دیگر diff شود.
- تغییرات مستقیم: `profiles`، `order_reservations`، `orders`، `conditional_orders`.
- تست باید cleanup رزرو و سفارش را هم بسنجد، نه فقط مقدار `profiles.is_active`.

## شکاف‌های اثبات‌شده در harnessهای فعلی

1. PR #38 setup فقط سه جدول `profiles`، `orders` و `order_reservations` می‌سازد و توابع miniature به نام‌های `place_order_unlocked` و `place_order_profile_locked` و `deactivate_account_fixture` را تعریف می‌کند؛ هیچ‌کدام RPC واقعی نیستند.
2. PR #38 از `pg_sleep(2)` برای بازکردن پنجرهٔ رقابت استفاده می‌کند. این barrier در منطق نمونه است و راهی برای متوقف‌کردن RPC واقعی در نقطهٔ بین active-check و نوشتن مالی نیست.
3. setupهای فعلی Stop-Limit و TP/SL schemaهای ساده‌شده می‌سازند. آن‌ها می‌توانند برای rehearsal بعضی lifecycleها مفید باشند، اما به‌تنهایی schema کامل Production نیستند.
4. در fixture widening، `current_account_is_active()` به `SELECT true` تقلیل یافته و trigger آزمایشی no-op است؛ چنین setupی برای تست این نقص قابل استفاده نیست.
5. Migrationهای سه‌گانهٔ بالا تعریف توابع را دارند، اما DDL پایهٔ همهٔ جدول‌های مشترک، تعریف authoritative همهٔ helperها، trigger inventory، role grants و schema کامل Auth را در خود ندارند. جست‌وجوی مخزن در این مرحله منبع پایهٔ authoritative و کامل برای تمام این اجزا را بازیابی نکرده است. این نتیجه به معنی نبودن آن‌ها در دیتابیس یا در تمام تاریخچهٔ مخزن نیست.

## طرح bootstrap و معیارهای پذیرش

### فاز A — بازیابی منبع
- تمام migrationهای پایه‌ای که ابتدا جدول‌های فوق و helperها را می‌سازند از Git history و فهرست migrationها پیدا شوند.
- برای هر جدول، ستون‌ها، نوع‌ها، defaultها، checkها، unique/FK، triggerها، RLS و grants از DDL منبع بازیابی شوند.
- تعریف نهایی `deactivate_my_account()` و ترتیب migration اعمال‌کنندهٔ آن مشخص شود.
- هر dependency که منبع authoritative آن پیدا نشد، صریحاً به‌عنوان blocker ثبت شود؛ حدس از روی fixture مجاز نیست.

### فاز B — نصب در PostgreSQL موقت
- فقط در service container نسخهٔ pin شدهٔ PostgreSQL 17 در GitHub Actions اجرا شود.
- schemaهای لازم `auth` و role/JWT test harness فقط برای رفتارهای موردنیاز بازسازی شوند؛ `auth.uid()` باید از claim نشست خوانده شود و هیچ نقش/claim آزمایشی نباید امکان جعل هویت کاربر دیگر را بدهد.
- توابع اصلی از فایل migration با استخراج مکانیکی و بدون بازنویسی business logic نصب شوند.
- helperها یا triggerها فقط اگر منبع اصلی‌شان در دسترس نیست stub شوند؛ هر stub باید در manifest نام‌گذاری شود و نباید active-check، قفل profile، نوشتن order/trade، رزرو یا cleanup را حذف/تغییر دهد.
- grants، SECURITY DEFINER، `search_path` و مالکیت تابع در حدی که رفتار امنیتی را تغییر می‌دهد حفظ و assert شوند.

### فاز C — barrier قطعی بدون تغییر منطق RPC
- ابتدا بررسی شود آیا barrier بیرونی با قفل ردیف/جدول یا advisory lock و مشاهدهٔ `pg_stat_activity` می‌تواند نقطهٔ مطلوب را قطعی کند.
- اگر تنها راه، افزودن hook داخل بدنهٔ RPC باشد، آن تست دیگر «اجرای بدون تغییر تابع واقعی» نیست؛ باید جداگانه به‌عنوان instrumented copy برچسب بخورد و به‌هیچ‌وجه جایگزین تست parity نشود.
- از `pg_sleep` به‌عنوان تنها همگام‌ساز استفاده نشود؛ timeoutها صرفاً حفاظ fail-fast باشند.

### فاز D — ماتریس سناریوها
برای هر چهار entrypoint، هر دو ترتیب زیر اجرا شوند:
1. عملیات مالی ابتدا قفل/حق نوشتن را می‌گیرد؛ سپس deactivation آغاز می‌شود. پس از commit هر دو، نتیجه باید با سیاست واقعی سازگار باشد و deactivation تمام سفارش/رزروهای باز عملیات برنده را cleanup کند.
2. deactivation ابتدا حساب را غیرفعال می‌کند؛ سپس RPC مالی شروع می‌شود. RPC باید رد شود و هیچ order/trade/reservation جدید باقی نماند.

برای هر سناریو assert شود:
- وضعیت نهایی profile؛
- تعداد و وضعیت orders و conditional_orders؛
- trades و transactions ایجادشده؛
- reservationهای reserved/consumed/released و سازگاری مقادیر؛
- wallet و asset_balances؛
- عدم باقی‌ماندن order/trade/reservation غیرمجاز پس از deactivation.

### فاز E — parity gate
- digest/متن بدنهٔ هر RPC نصب‌شده با استخراج همان تابع از migration منبع مقایسه شود.
- schema manifest شامل ستون‌ها/قیود/indexها/triggerها و role grants با منبع مقایسه شود.
- تمام stubs و تفاوت‌های عمدی در خروجی CI چاپ شوند.
- تا وقتی dependency مؤثر بر concurrency یا financial write stub است، نتیجه فقط «partial harness» است و نباید به‌عنوان آزمون source-faithful گزارش شود.

## تصمیم فعلی
در ۲۱ نوامبر هنوز migration پایهٔ authoritative برای schema مشترک و helperهای حساب/fee، و trigger inventory کامل در این مرور بازیابی نشده است. بنابراین هنوز کد harness جدیدی نوشته یا اجرا نمی‌شود. گام بعد فقط فاز A است: بازیابی migrationهای پایه از Git history و تعیین blockerهای دقیق. هیچ Production query/write، migration، RPC، trigger، cron، financial row، merge/rebase/deploy یا `supabase db push` در این مرحله انجام نشده است.
