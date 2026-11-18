# DigiArz — وضعیت اجرای پروژه
آخرین به‌روزرسانی: 2026-11-18
شاخهٔ جاری این ثبت: `feat/demo-derivatives-trading`
مخزن: https://github.com/shahram-adim/DigiArz

## مرحله انجام‌شده: زیرساخت اولیه PWA
- [x] افزودن manifest وب‌اپ فارسی و RTL
- [x] افزودن نشان‌های SVG در اندازه‌های 192 و 512
- [x] افزودن ثبت Service Worker با شرط HTTPS یا localhost
- [x] ذخیره پوسته HTML و فایل‌های نصب در Cache Storage
- [x] راهبرد شبکه‌اول برای درخواست‌های ناوبری و fallback به پوسته ذخیره‌شده
- [x] عدم رهگیری درخواست‌های خارجی Supabase و APIهای بازار توسط Service Worker
- [x] حفظ فایل‌های قبلی و نسخه‌های پشتیبان
- [x] بازخوانی فایل‌های ثبت‌شده از GitHub و تأیید وجود تغییرات

## فایل‌های اضافه/تغییریافته
- `index.html` — manifest، متاتگ‌های موبایل و ثبت Service Worker
- `manifest.webmanifest` — مشخصات نصب و آیکون‌ها
- `sw.js` — پوسته آفلاین
- `icon.svg`، `icon-192.svg`، `icon-512.svg` — نشان برنامه

## محدودیت‌های تأییدنشده
- نصب‌پذیری نهایی وابسته به میزبانی HTTPS و پشتیبانی مرورگر است.
- اجرای واقعی روی Android، Lighthouse و سناریوی قطع اینترنت هنوز تست نشده است.
- آفلاین بودن فقط پوسته برنامه را پوشش می‌دهد؛ قیمت زنده، ورود، دیتابیس و معاملات به اینترنت نیاز دارند.
- وجود آیکون SVG به‌تنهایی تضمین سازگاری همه نصب‌کننده‌ها یا بسته‌بندی APK نیست؛ در مرحله بسته‌بندی ممکن است PNG لازم شود.

## موانع مهم بعدی
1. اتصال مستقیم Supabase اکنون برقرار است؛ تعریف کامل `public.new_user_setup()` در 2026-11-13 بررسی شد و تا پایان طراحی تغییرات ثبت‌نام/کیف پول، دست‌نخورده می‌ماند.
2. منطق معاملات فرانت‌اند در `index.html`، قیمت را از جدول می‌خواند و به RPC ارسال می‌کند؛ باید اطمینان حاصل شود RPC قیمت را مستقل و معتبر از منبع سرور کنترل می‌کند و به قیمت ارسالی مرورگر اعتماد نمی‌کند.
3. موتور Limit و Stop-Limit باید به رابط کاربری متصل و سناریوهای رزرو/لغو/اجرای جزئی تست شوند.
4. بررسی stale بودن قیمت‌ها و همگام‌سازی کاتالوگ بازار باز است.

## دستور مرحله بعد
- تأیید نشانی میزبانی فعلی برنامه (GitHub Pages یا دامنه/میزبان دیگر) و اجرای تست نصب PWA روی Android.
- سپس بررسی و تکمیل UI سفارش‌های Market/Limit/Stop-Limit بدون تغییر بی‌دلیل در داده‌های موجود.
- هرگونه تغییر دیتابیس مالی فقط پس از بررسی تابع ثبت‌نام، مجوزها، قیود و امکان rollback.

## به‌روزرسانی ممیزی ۱۶ نوامبر ۲۰۲۶ — پیش‌بررسی دقت اعشاری
- [x] وضعیت پروژه Supabase با شناسه `gfoaubfilhttnwjykaox` بررسی شد؛ پروژه `DigiArz` در وضعیت `ACTIVE_HEALTHY` و PostgreSQL 17.11 است.
- [x] پیش‌بررسی فقط‌خواندنی حدود پیشنهادی numeric(34,18) و numeric(38,18) روی ستون‌های سفارش، معامله، موجودی، رزرو و سفارش شرطی اجرا شد؛ هیچ مقدار نامعتبر گزارش نشد.
- [x] شمارش رکوردها نیز انجام شد: `orders`, `trades`, `asset_balances`, `order_reservations` و `conditional_orders` هرکدام فعلاً صفر رکورد دارند.
- [!] بنابراین صفر بودن تخلف‌ها به معنی اثبات سازگاری داده‌های واقعی نیست؛ این جداول خالی‌اند و آزمون داده‌ای روی Production هنوز پوشش واقعی ندارد. قبل از rollout باید دوباره پیش‌بررسی شود و پس از ایجاد داده‌های آزمایشی نیز سناریوها در دیتابیس ایزوله پوشش داده شوند.
- [x] فایل منفی CI اصلاح شد تا سفارش fixture همه فیلدهای اجباری (`user_id`, `symbol`, `side`, `order_type`, `amount`, `remaining_amount`) را داشته باشد و به preflight عددی برسد.
- [ ] اجرای CI برای commit اصلاح‌شده هنوز از ابزار در دسترس این نشست قابل تأیید نیست؛ helper موجود فقط اجراهای pull-request را برمی‌گرداند و status خالی به‌تنهایی اثبات اجرای موفق نیست.
- [x] فایل draft افزایش دقت همچنان در `supabase/drafts` است و به مسیر migrations منتقل نشده؛ هیچ تغییر schema یا داده‌ای در Production اعمال نشد.
- [x] اختلاف نسخهٔ ثبت‌شدهٔ migration مربوط به bounded retry با نام فایل موجود در GitHub همچنان باز است و نباید با rename یا اجرای کورکورانهٔ migration حل شود.

## بررسی ساختار فعلی ستون‌های مالی — ۱۶ نوامبر ۲۰۲۶
- [x] نوع ستون‌ها از `information_schema.columns` فقط‌خواندنی خوانده شد.
- [x] `orders.amount` و `orders.price` و نیز `trades.amount` و `trades.price` در حال حاضر `numeric(24,8)` هستند.
- [x] `asset_balances.balance` در حال حاضر `numeric(28,8)` است.
- [x] `orders.filled_amount`, `orders.remaining_amount`، ستون‌های عددی `order_reservations` و چهار ستون عددی `conditional_orders` از نوع `numeric` بدون precision/scale محدود گزارش شدند.
- [!] این تفاوت مهم است: draft افزایش دقت برای ستون‌های بدون محدودیت نیز precision/scale مشخص می‌کند؛ بنابراین فقط تست نمونه‌های فعلی کافی نیست و باید قرارداد دامنه مقادیر، توابع RPC و محاسبات رزرو/تسویه برای هر ستون جداگانه تطبیق داده شود. مخصوصاً تبدیل numeric نامحدود به numeric(34,18) یا numeric(38,18) باید با آزمون overflow و round-trip پوشش داده شود.
- [x] تعریف زنده `public.process_stop_limit_orders()` دوباره خوانده شد و branch محدودیت ۱۰ تلاش و ثبت `manual review required` در تابع فعال است.

## گام بعد
1. دستیابی به وضعیت اجرای push workflow و رفع هر شکست با لاگ دقیق.
2. تطبیق تاریخچه migration مربوط به Stop-Limit با وضعیت واقعی تابع زنده و فایل‌های GitHub؛ بدون دست‌کاری جدول تاریخچه تا روشن‌شدن منشأ اختلاف.
3. تکمیل تست‌های ایزولهٔ RPCهای Market/Limit/Stop-Limit و آزمون‌های حسابداری رزرو/لغو/اجرای جزئی.
4. بازبینی دامنه عددی هر ستون و زنجیره RPC قبل از نهایی‌کردن draft افزایش دقت؛ هیچ rollout روی Production در این مرحله انجام نشود.

## تفکیک دقت دارایی پایه از تسویه USDT — ۱۶ نوامبر ۲۰۲۶
- [x] بررسی تمام ستون‌های عددی عمومی نشان داد `wallets.balance_usdt` و `transactions.amount` هر دو `numeric(24,8)` هستند؛ این‌ها مقادیر تسویه/دفترکل USDT هستند و نباید بدون طراحی مستقل به ۱۸ رقم اعشار تغییر کنند.
- [x] `market_prices.price` از قبل `numeric(38,18)` است؛ قیمت مرجع بازار، دقت ۱۸ رقم را پشتیبانی می‌کند.
- [x] `orders.amount/price` و `trades.amount/price` اکنون `numeric(24,8)` هستند و برای مقدار دارایی پایه/قیمت نیازمند افزایش دقت بررسی‌شده‌اند؛ `asset_balances.balance` نیز `numeric(28,8)` است.
- [x] تعریف `execute_demo_trade` نشان می‌دهد مبلغ ناخالص و کارمزد USDT صریحاً با `round(...,8)` محاسبه می‌شوند؛ این رفتار باید برای حفظ واحد تسویه ۸ رقمی باقی بماند، درحالی‌که `p_amount` دارایی پایه نباید ناخواسته به ۸ رقم گرد شود.
- [!] تعریف `process_limit_orders` در حال حاضر محاسبه `v_gross` و `v_fee` را بدون round صریح انجام می‌دهد و نتیجه را در ستون‌های ۸ رقمی کیف پول/تراکنش ثبت می‌کند. این تفاوت باید با آزمون حسابداری دقیق و بررسی گردکردن نهایی USDT پوشش داده شود؛ هنوز تغییری در تابع اعمال نشده است.
- [x] هیچ‌یک از این بررسی‌ها تابع، schema، موجودی یا سفارش Production را تغییر نداده‌اند.



## ادامه اجرای دقت اعشاری و تطبیق Migration — ۱۶ نوامبر ۲۰۲۶
- [x] منشأ اختلاف نام Migration پیدا شد: commit اصلی `3cba43bda2c18e7c7e2a45790a1a3bf9be681763` فایل bounded retry را با نسخهٔ `20261115143827` ثبت کرده بود؛ فایل در commit بعدی با نام اشتباه `20261115153000` اضافه شده بود، درحالی‌که Supabase نسخهٔ `20261115143827` را ثبت کرده است.
- [x] فایل در GitHub به مسیر `supabase/migrations/20261115143827_bound_stop_limit_invalid_reservation_retries.sql` منتقل و فایل تکراری `20261115153000...` حذف شد. تاریخچهٔ Supabase تغییر نکرد.
- [x] تابع زندهٔ `process_stop_limit_orders()` فقط‌خواندنی بررسی شد؛ عبارت manual review، شرط سقف ۱۰ تلاش و پیام خطای مورد انتظار وجود دارند.
- [x] اجرای کامل workflow مربوط به دقت اعشاری برای commit `db5c2ab2736f9c5d60e8faa05eae2f7488d667e8` موفق شد: همهٔ ۲۰ مرحله/گام گزارش‌شده موفق هستند.
- [x] آزمون‌های PostgreSQL 17 شامل arithmetic regression، اجرای rehearsal برای widening، رد preflight نامعتبر به‌صورت atomic، lock timeout پنج‌ثانیه‌ای، rollback پس از شکست میانی DDL، entrypointهای Market/Limit و Stop-Limit/TP-SL، worker سفارش Limit، لغو سفارش، چرخه parent-child در Stop-Limit و خروجی‌های شرطی TP/SL همگی موفق شدند.
- [x] کاندیدهای RPC و worker در `supabase/drafts` باقی مانده‌اند؛ تست‌ها آن‌ها را فقط در دیتابیس‌های موقت اجرا کرده‌اند.
- [!] موفقیت CI به معنی تأیید rollout روی Supabase اصلی نیست. هیچ Migration افزایش دقت یا جایگزینی تابع مالی روی Production اجرا نشده است.
- [!] قبل از rollout همچنان باید بازبینی نهایی توابع candidate، grants/RLS، قفل‌گذاری و تطبیق قرارداد عددی انجام شود؛ سپس یک برنامهٔ انتشار با backup/rollback و preflight تازه تهیه شود.

## گام بعد از CI سبز
1. بازبینی دقیق کاندیدهای `execute_demo_trade`, `place_limit_order`, `place_stop_limit_order`, `place_conditional_exit_order` و `process_limit_orders` در کنار تعریف زنده و grants آن‌ها.
2. افزودن آزمون‌های مرزی حسابداری برای گردکردن کارمزد و gross/net در مرز ۸ رقم USDT، مخصوصاً مقادیر نیمه‌راه و dust.
3. تنها پس از تکمیل این بازبینی، آماده‌سازی migration نهایی در مسیر migrations؛ Production همچنان بدون تغییر تا اخذ تأیید انتشار.


## آزمون تکمیلی حسابداری Limit — ۱۶ نوامبر ۲۰۲۶
- [x] در commit `91fb191b40bb93b60f50856c1637917271cfa0af` تست worker سفارش Limit تقویت شد: fixture قیمت بازار و سفارش‌ها دارای ۱۸ رقم اعشار شد؛ آزمون حفظ قیمت دقیق در هر چهار trade خرید/فروش و تطبیق دفترکل USDT اضافه شد.
- [x] CI برای همین commit با موفقیت کامل شد: run `43806364073`، نتیجه `success`. تست JavaScript/browser، arithmetic regression، widening rehearsal، preflight نامعتبر atomic، lock timeout، rollback میانی DDL، Market/Limit، Stop-Limit/TP-SL، Limit worker، cancellation و چرخه‌های parent-child/conditional exit همگی موفق شدند.
- [x] آزمون جدید خرید: چهار fill با قیمت `10.000000000000000001`، مجموع تسویه و transaction برابر `10.01 USDT` و مقدار پایه `1.000000000000000001` را بررسی می‌کند.
- [x] آزمون جدید فروش: چهار fill، مجموع خالص و transaction برابر `9.99 USDT`، مقدار پایه و قیمت ۱۸ رقمی را بررسی می‌کند.
- [!] این CI در PostgreSQL 17 موقت اجرا شده است؛ تغییر schema و worker هنوز روی Supabase اصلی اعمال نشده است.
- [ ] گام بعدی: بازبینی end-to-end برای Stop-Limit و TP/SL شامل قیمت/مقدار ۱۸ رقمی، تسویه ۸ رقمی، رزرو/آزادسازی و idempotency؛ سپس طراحی انتشار کنترل‌شده، نه اجرای خودکار روی Production.


## آزمون‌های تکمیلی Stop-Limit و TP/SL — ۱۶ نوامبر ۲۰۲۶
- [x] در commit `390c4427eeba78ec15151a9c239bab0a3fb35f30` آزمون چرخهٔ Stop-Limit تقویت شد: قیمت مرجع، trigger/limit child، قیمت trade، مقدار دارایی پایه، تسویه ۸ رقمی USDT، رزرو والد/فرزند و اجرای مجدد worker بدون ثبت تکراری بررسی می‌شوند.
- [x] اجرای CI مربوط به Stop-Limit با موفقیت کامل شد: run `43806624476`، نتیجهٔ نهایی `success`.
- [x] در commit `62d80f55d4dc1c273e8ee095b41ccb8fcc826dda` آزمون TP/SL تقویت شد: قیمت دقیق trade و executed_price، تعداد و مقدار trade rowهای execution child، رزرو مصرف‌شده، تسویه و دفترکل USDT و اجرای مجدد worker بدون duplicate بررسی می‌شوند.
- [x] اجرای CI مربوط به TP/SL با موفقیت کامل شد: run `43806628559`، نتیجهٔ نهایی `success`.
- [!] این تست‌ها در PostgreSQL موقت CI اجرا شده‌اند؛ هیچ تغییر schema یا تابعی روی Supabase Production انجام نشده است.
- [ ] اجرای Pages برای commit مربوط به Stop-Limit هنوز در زمان ثبت این یادداشت در حال اجرا بود و نتیجهٔ نهایی آن باید جداگانه بررسی شود.
- [ ] گام بعدی: بازبینی کاندیدهای RPC/worker و تطبیق کامل قرارداد تسویه، رزرو و قفل‌گذاری؛ سپس آماده‌سازی برنامهٔ rollout با preflight و rollback. افزایش precision در Production همچنان متوقف است تا بررسی و تأیید انتشار انجام شود.

## آزمون واقعی هم‌زمانی لغو و اجرای سفارش Limit — ۱۶ نوامبر ۲۰۲۶
- [x] دو سناریوی رقابت واقعی با دو نشست مستقل PostgreSQL به workflow اضافه شد؛ اجرای Worker و لغو سفارش از دو اتصال جداگانه انجام می‌شود.
- [x] سناریوی اول: Worker ابتدا قفل سفارش را می‌گیرد و هنگام درج trade مکث کنترل‌شده دارد؛ درخواست لغو واقعاً پشت قفل سفارش منتظر می‌ماند. پس از پایان Worker، لغو ادامه می‌یابد و نتیجه نهایی باید یک fill جزئی، وضعیت cancelled، مصرف رزرو ۲٫۵۰۲۵ USDT، آزادسازی ۷٫۵۰۷۵ USDT و مانده کیف پول ۹۷٫۴۹۷۵ USDT باشد.
- [x] سناریوی دوم: تراکنش لغو ابتدا قفل سفارش را می‌گیرد و آن را تا پایان مکث کنترل‌شده نگه می‌دارد؛ Worker هم‌زمان اجرا می‌شود و به‌واسطهٔ FOR UPDATE SKIP LOCKED نباید سفارش را اجرا کند. نتیجه باید سفارش cancelled بدون fill، رزرو کاملاً آزاد و بدون تغییر کیف پول باشد.
- [x] اجرای اولیه تست، ایراد جداسازی fixtureها را آشکار کرد؛ سفارش سناریوی دوم در دور اول Worker هم واجد شرایط بود و زودتر fill جزئی گرفت. fixture اصلاح شد تا حساب دوم در دور اول غیرفعال و فقط پیش از سناریوی دوم فعال شود.
- [x] اجرای نهایی CI برای commit 3b27908ddc68a4651d1ce2d346f20f1e8c2f48d9 موفق شد: run 43807599281. هر دو سناریوی هم‌زمانی، تست‌های قبلی دقت اعشاری، cancellation، Stop-Limit و TP/SL موفق شدند.
- [x] GitHub Pages برای همین commit با run 43807599017 با موفقیت Build و Deploy شد.
- [!] این تست‌ها فقط در PostgreSQL موقت GitHub Actions اجرا شدند؛ هیچ تابع، schema، سفارش، رزرو یا موجودی در Supabase Production تغییر نکرده است.
- [x] توضیح نادرست wallet-first lock order در draft Worker اصلاح شد؛ ترتیب واقعی کاندید Worker برابر order row → reservation row → wallet row است و با پیشوند قفل‌گذاری تابع لغو (order row → reservation row) سازگار است.
- [ ] گام بعد: بازبینی تطبیقی ترتیب قفل در سایر RPCهای ثبت سفارش/Stop-Limit/TP-SL و بررسی idempotency لغو/اجرای parent-child؛ سپس تهیه برنامه rollout جداگانه برای تغییر precision و Worker. هنوز هیچ rollout مالی روی Production مجاز یا انجام‌شده نیست.


## تکمیل آزمون‌های هم‌زمانی و آماده‌سازی انتقال — ۱۶ نوامبر ۲۰۲۶
- [x] CI کامل برای commit `afcf0b32ce288b87f307b4a1a7b9a6e92ffe82d8` موفق شد: run `43809106406`. تست واقعی دو نشست برای رقابت اجرای فرزند Stop-Limit و لغو والد، همراه با کنترل وضعیت والد/فرزند، رزرو، کیف پول، دارایی و دفترکل اضافه شد.
- [x] CI کامل برای commit `168787637b26654f4f980c371f11c2d648883aa9` موفق شد: run `43809379144`. تست واقعی دو نشست TP/SL برای اجرای شرطی در برابر لغو، در هر دو ترتیب قفل، موفق شد.
- [x] کاندید Worker همگام‌سازی Stop-Limit اصلاح شد تا در مسیر sync، ردیف child نیز همراه conditional و parent با `FOR UPDATE ... SKIP LOCKED` قفل شود؛ تست رقابت child fill و parent sync اضافه شد.
- [x] CI کامل برای commit `ed3075bdcc56425fdac11be74e8da32434a5e7a2` موفق شد: run `43809559272`. تست‌های child/parent sync race، Stop-Limit cancellation race، TP/SL cancellation race و کل ۲۰ مرحلهٔ قبلی موفق شدند.
- [x] یک ریسک مرزی در تطبیق رزرو USDT با گردکردن چند fill شناسایی شد: مجموع gross/feeهای ۴ fill می‌تواند تا چند واحد ۱e-8 از reserve گرد‌شدهٔ یک‌باره بیشتر شود. کاندیدهای ثبت Limit و Stop-Limit و target reserve در Worker با حاشیهٔ بسیار کوچک `0.0000001 USDT` به‌روزرسانی شدند؛ این حاشیه تا زمان باقی‌بودن سفارش حفظ و پس از fill کامل آزاد می‌شود.
- [x] تست رگرسیون مستقل برای مقدار/قیمت ۱۸ رقمی و چهار fill، تطبیق مصرف رزرو با دفترکل و آزادسازی باقیمانده اضافه شد؛ نتیجهٔ نهایی آن در CI جدید باید تأیید شود.
- [!] **مانع انتقال دیتابیس:** تاریخچهٔ Supabase شامل ۴۶ migration اعمال‌شده است، اما مخزن فقط ۳۳ فایل migration دارد؛ ۱۳ فایل منبع در مخزن موجود نیست و ۱۹ فایل timestamp متفاوتی با نسخهٔ ثبت‌شده در Supabase دارند. گزارش کامل در `supabase/MIGRATION_RECONCILIATION.md` ثبت شد.
- [!] تا رفع این اختلاف، `supabase db push` نباید اجرا شود؛ ممکن است migrationهای اعمال‌شده دوباره به‌عنوان pending تشخیص داده شوند. تاریخچهٔ Supabase نیز نباید دستی دست‌کاری شود.
- [x] هیچ تغییر schema، تابع مالی، رزرو، سفارش یا موجودی در Supabase Production انجام نشده است.

## شرط ورود به مرحلهٔ انتقال
1. CI آخرین commit شامل رگرسیون rounding buffer باید success شود.
2. تاریخچه و فایل‌های migration باید بدون حدس و با منبع معتبر تطبیق داده شوند؛ نسخه‌های مفقود یا باید بازیابی شوند یا روش انتشار مستقیم و کنترل‌شده برای Migration جدید مستند شود.
3. کاندیدهای widening و توابع مالی باید در یک بستهٔ atomic با preflight، محدودیت lock/statement timeout، حفظ grants، rollback و post-check نهایی جمع شوند.
4. پس از تکمیل این موارد، فقط آمادهٔ اجرای انتقال خواهیم بود؛ اجرای Production منوط به دستور صریح کاربر است.


## تأیید بستهٔ یکپارچهٔ انتقال — ۱۶ نوامبر ۲۰۲۶
- [x] کاندید واحد `supabase/drafts/2026-11-16_exact_decimal_rollout_candidate.sql` ساخته شد؛ شامل preflight، widening، توابع Market/Limit/Stop-Limit/TP-SL، دو Worker، grants و postflight در یک تراکنش.
- [x] بستهٔ واحد روی PostgreSQL 17 موقت با سه مسیر مجزا rehearsal شد: مرز گردکردن و چهار fill، رقابت اجرای فرزند/لغو Stop-Limit و رقابت اجرای TP/SL/لغو. همه موفق شدند.
- [x] CI کامل commit `acfc058a4da5f1901773554bbd95c3249333df23` با run `43810949526` موفق شد؛ GitHub Pages run `43810949798` نیز موفق شد.
- [x] regression گردکردن تجمعی: رزرو خرید با حاشیهٔ `0.0000001 USDT` ثبت می‌شود؛ Worker همین حاشیه را تا زمان باقی‌بودن مقدار سفارش در reserve target حفظ می‌کند و پس از fill کامل آن را آزاد می‌کند. چهار fill، trade rows، مصرف رزرو، دفترکل USDT و موجودی دارایی همگی تطبیق داده شدند.
- [x] فایل راهنمای انتقال و rollback در `supabase/EXACT_DECIMAL_ROLLOUT.md` ثبت شد.
- [!] هنوز Migration روی Supabase Production اعمال نشده است. گام بعدی در صورت دستور صریح «انتقال به دیتابیس»، اجرای preflight تازه، تأیید backup/PITR و سپس یک `apply_migration` واحد با همین SQL است؛ `supabase db push` تا زمان تطبیق تاریخچهٔ قدیمی استفاده نمی‌شود.


## آخرین کنترل پیش از انتقال — ۱۶ نوامبر ۲۰۲۶
- [x] تست‌های نگهبان جدید، باقی‌ماندن بستهٔ rollout در پوشهٔ drafts و فقط‌خواندنی بودن فایل preflight را کنترل می‌کنند.
- [x] CI نهایی commit `01e7f20795318eab47d7d075bc340372797b35e1` موفق شد: run `43811390095`; GitHub Pages run `43811390709` نیز موفق شد.
- [x] preflight فقط‌خواندنی روی Supabase Production در این نوبت: تعداد ردیف‌های orders/trades/asset_balances/order_reservations/conditional_orders همگی صفر؛ شمار رکوردهای نامعتبر در هر پنج جدول صفر؛ نام Migration جدید تکراری نیست؛ وابستگی view/materialized view برای ستون‌های هدف در بررسی قبلی صفر بود.
- [!] این نتیجه فقط snapshot زمان بررسی است؛ همان preflight باید بلافاصله پیش از انتقال دوباره اجرا شود.
- [x] مسیر انتقال کنترل‌شده آماده است: اجرای یک `apply_migration` واحد با SQL بستهٔ کاندید و ثبت نسخهٔ برگشتی در مخزن. اجرای `supabase db push` همچنان تا رفع drift تاریخچه ممنوع است.

## تکمیل مسیر قیمت‌های بازار تومانی — ۱۶ نوامبر ۲۰۲۶
- [x] علت خالی‌بودن صفحه بازار تومانی مشخص شد: رابط کاربری تابع `refresh-toman-market-prices` را فراخوانی می‌کرد، اما این Edge Function در پروژه فعال Supabase وجود نداشت.
- [x] تابع `supabase/functions/refresh-toman-market-prices/index.ts` به مخزن اضافه و در پروژه `gfoaubfilhttnwjykaox` با نسخه ۱ و `verify_jwt=true` مستقر شد.
- [x] منبع‌های عمومی Nobitex، Wallex و Bitpin به تابع اضافه شدند. قیمت‌های Nobitex از ریال به تومان تبدیل می‌شوند؛ منابع دیگر فقط جفت‌های IRT/TMN را می‌پذیرند.
- [x] نوشتن قیمت‌ها در `market_toman_prices` و snapshotهای تاریخچه با فاصله حداقل ۶ ساعت در `market_toman_price_history` پیاده‌سازی شد. درخواست‌های تکراری در بازه ۴۵ ثانیه از cache پاسخ می‌گیرند.
- [x] رابط صفحه بازار تومانی با منبع‌های واقعی پیاده‌سازی‌شده هماهنگ شد؛ برچسب بیت‌پین افزوده شد.
- [!] آزمون runtime پس از استقرار هنوز انجام نشده است؛ اولین اجرای دکمه «دریافت قیمت‌های تازه» باید با کنترل شمار ردیف‌های هر دو جدول و خروجی منابع بررسی شود.
- [!] تا زمان تأیید اجرای واقعی، نباید ادعا شود قیمت‌های تومانی یا تاریخچه اکنون پر شده‌اند. این تغییر هیچ schema، کیف پول، سفارش یا معامله‌ای را تغییر نداده است.
- [x] آزمون syntax یک خطای قدیمی در دو پیام وضعیت دفتر سفارش و معاملات اخیر را آشکار کرد: نویسهٔ نامرئی U+200B باعث نامعتبرشدن JavaScript اصلی صفحه شده بود. هر دو خط اصلاح شدند و هر سه بلوک JavaScript در بررسی ایستا بدون خطا parse شدند.
- [!] نسخه APK نهایی باید از commit اصلاح‌شده `01189bed` ساخته شود؛ APK قبلی این اصلاح نحوی را ندارد.
- [x] برای جلوگیری از رشد بی‌رویهٔ جدول جاری قیمت‌ها، تابع به نسخه ۲ ارتقا یافت: پس از درج موفق snapshot تازه، رکوردهای قدیمی سه منبع فعال از جدول جاری پاک می‌شوند؛ تاریخچهٔ بلندمدت در `market_toman_price_history` جداگانه حفظ می‌شود. نسخه ۲ با موفقیت در Supabase مستقر شد.
- [x] در نسخه ۳ تابع، پاک‌سازی جدول جاری فقط برای صرافی‌هایی انجام می‌شود که در همان نوبت واقعاً دادهٔ تازه داده‌اند؛ دادهٔ آخرین منبعی که موقتاً قطع شده حذف نمی‌شود و وضعیت stale آن قابل مشاهده می‌ماند. نسخه ۳ فعال است.
- [x] آزمون کامل Exact decimal در commit `01189bed` با نتیجه SUCCESS تمام شد؛ تمام تست‌های JavaScript، PostgreSQL، Market/Limit، Stop-Limit و TP/SL موفق بودند.
- [x] ساخت APK اندروید از همان commit `01189bed` با نتیجه SUCCESS تمام شد؛ Artifact با شناسه `14255993475` دریافت و APK امضاشده از آرشیو استخراج شد. SHA-256: `ab37a050212a45ca9e9c8ed1e64685ca2a313ec4dce75da4dbcf165c2bf91f8a`.
- [!] این APK شامل اصلاحات صفحه و بازار تومانی تا commit `01189bed` است. نسخه ۳ Edge Function بازار تومانی بعداً فقط در backend مستقر شد و به ساخت APK جدید نیاز ندارد.


## تضمین کیفیت شبانه و تطبیق تازهٔ Supabase — ۱۷ نوامبر ۲۰۲۶
- [x] وضعیت تازهٔ شاخه `main` بررسی شد؛ HEAD پیش از مستندسازی این نوبت `f99a1cc588ce90446fe49f5060ccf2a4c4e1f298` بود. تغییرات جدید نسبت به گزارش قبلی شامل اصلاح پاسخ‌های فشردهٔ همگام‌سازی صرافی‌های ایرانی، حذف ردیف‌های تکراری، فهرست‌کردن دارایی‌های unmatched، فعال‌سازی جفت‌های تأییدشده، محدودکردن batch اصلی CoinGecko به ۵۱۵ شناسه و زمان‌بندی staggered است.
- [x] GitHub Actions برای HEAD بررسی شد: workflow «Exact decimal tests» با run `43954662389` و Pages با run `43954660654` هر دو `success` هستند.
- [x] آخرین ساخت Android APK با run `43952314873` روی commit `aa8a8b9` موفق بوده است. SHA محتوای `index.html` در HEAD فعلی و همان commit دقیقاً یکسان است؛ پس از ساخت APK تغییر فرانت‌اندی در این فایل ثبت نشده و تغییرات بعدی این بازه عمدتاً migration/backend بوده‌اند.
- [x] Supabase با شناسه `gfoaubfilhttnwjykaox` در وضعیت `ACTIVE_HEALTHY` و PostgreSQL `17.11.0.018` است؛ تاریخچهٔ Migration اکنون ۵۲ نسخهٔ اعمال‌شده دارد.
- [!] شمارش تازه نشان داد گزارش قبلی Migration drift قدیمی شده بود: مخزن ۴۰ فایل migration دارد؛ ۱۴ نسخهٔ اعمال‌شده منبع محلی ندارند؛ ۲۰ فایل محلی timestamp متفاوت از نسخهٔ اعمال‌شده دارند؛ و دو فایل محلی اصلاً در تاریخچهٔ Production ثبت نشده‌اند. فایل `supabase/MIGRATION_RECONCILIATION.md` با فهرست دقیق جدید به‌روزرسانی شد.
- [!] دو فایل pending عبارت‌اند از `20261116203000_add_kucoin_to_scheduled_market_price_refresh.sql` و `20261116203100_add_gateio_to_scheduled_market_price_refresh.sql`. هر دو تابع `refresh_market_prices()` را با نسخهٔ قدیمی‌تر جایگزین می‌کنند؛ نسخهٔ دوم Gate.io را دارد اما سقف ۵۱۵ شناسه را ندارد. چون Migration بعدیِ سقف ۵۱۵ قبلاً در Production ثبت شده، اجرای `supabase db push` می‌تواند تابع زنده را به نسخهٔ بدون سقف برگرداند. **تا رفع این مورد، اجرای db push ممنوع است.**
- [x] بررسی فقط‌خواندنی تابع زنده تأیید کرد که اکنون CoinGecko، KuCoin، Gate.io و محدودیت ۵۱۵ شناسه فعال‌اند. cronهای Production نیز فعال و مطابق برنامه‌اند: job 13 هر ۱۰ دقیقه، job 14 هر دقیقه، job 17 از دقیقهٔ ۵ و سپس هر ۱۰ دقیقه.
- [!] فایل زمان‌بندی محلی `20261117130000_stagger_market_price_overflow_and_refresh_exchange_discovery.sql` با نسخهٔ ثبت‌شدهٔ `20261116205451` تطبیق محتوایی دارد، اما timestamp آن متفاوت است؛ اجرای دوبارهٔ آن لازم نیست.
- [x] Advisorهای تازه: Health بدون یافته؛ Security شامل ۱۵ جدول RLS-enabled بدون policy، دو تابع SECURITY DEFINER قابل اجرا برای anon، ۲۳ تابع قابل اجرا برای authenticated و غیرفعال‌بودن leaked-password protection؛ Performance شامل ۹ FK بدون ایندکس پوششی، ۱۱ هشدار RLS initplan و ۹ ایندکس استفاده‌نشده. این موارد نیازمند بازبینی هدفمندند و صرف هشدار به معنی آسیب‌پذیری قطعی نیست.
- [x] هیچ migration، تغییر مجوز، cron، Edge Function، سفارش، معامله، رزرو، کیف پول، موجودی یا سابقهٔ مالی در Supabase Production در این نوبت اجرا یا تغییر داده نشد؛ تمام پرس‌وجوهای دیتابیس فقط‌خواندنی بودند.

### گام بعدی اولویت‌دار
1. از منبع معتبر، ۱۴ فایل SQL مفقود را بازیابی یا برای هرکدام سند بازسازی با checksum و تعریف زنده تهیه کن؛ جست‌وجوی تاریخچهٔ GitHub برای مسیر canonical هر ۱۴ فایل در این نوبت commitی برنگرداند.
2. دو migration محلی KuCoin/Gate.io را با تاریخچهٔ Production تطبیق بده و فقط پس از review مشخص کن چگونه از مسیر `supabase/migrations/` خارج/به‌عنوان superseded ثبت شوند؛ فایل‌ها را کورکورانه حذف یا اجرا نکن.
3. ۲۰ timestamp mismatch را یکی‌یکی با محتوای SQL مقایسه کن؛ هیچ تاریخچه‌ای را دستی تغییر نده.
4. پس از reconciliation، کل مجموعه را روی PostgreSQL 17 دورریختنی replay کن و وجود سقف ۵۱۵، سه provider و cron schedule نهایی را در post-check اثبات کن.
5. افزایش precision مالی Production همچنان منوط به دستور صریح انتقال و preflight تازه است.


## اجرای مستقل روزانه — ۱۷ نوامبر ۲۰۲۶ (PWA و آزمون‌های ایزوله)

- [x] وضعیت واقعی `main` و درخت فایل‌ها دوباره خوانده شد؛ HEAD پیش از این اجرا `47210d019f3008db772fdb88faaadaa13f0e7b4e` بود. پس از اصلاحات این اجرا، تغییر Service Worker در `348ebd4a222401023549a3cb484806b1e772db65` و آزمون‌ها در `bfc6d9b30bc9e109daf7df2a35b0d0efc33cec5c` ثبت شدند.
- [x] `sw.js` از v53 به v54 ارتقا یافت. کش runtime دیگر پاسخ‌های دلخواه same-origin را ذخیره نمی‌کند؛ فقط app shell از پیش تعیین‌شده cache-first است و navigation ریشه/صفحه اصلی network-first با fallback آفلاین باقی می‌ماند.
- [x] آیکون‌های `icon-192.svg` و `icon-512.svg` نیز به app shell افزوده شدند تا فایل‌های معرفی‌شده در manifest در نصب/راه‌اندازی آفلاین موجود باشند.
- [x] فایل `tests/service-worker.test.js` با ۷ آزمون اضافه شد: manifest فارسی RTL و standalone، precache پوسته و آیکون‌ها، bypass درخواست خارجی Supabase و متدهای غیر GET، عدم ذخیره پاسخ‌های same-origin خارج از پوسته، به‌روزرسانی index در navigation، fallback آفلاین و پاک‌سازی cache قدیمی.
- [x] آزمون محلی Node 22 برای فایل جدید: ۷ از ۷ موفق.
- [x] GitHub Actions روی main: run `44068551988` برای commit `bfc6d9b30bc9e109daf7df2a35b0d0efc33cec5c` با نتیجه `success`؛ تمام مراحل workflow، از جمله تست Node/browser و آزمون‌های PostgreSQL 17 برای Market/Limit، Stop-Limit، TP/SL و رقابت‌های دو نشست، موفق شدند.
- [x] GitHub Pages run `44068551980` برای همان commit با نتیجه `success`.
- [x] ساخت Android APK run `44068495018` روی commit کد `348ebd4a222401023549a3cb484806b1e772db65` با نتیجه `success`؛ artifact با نام `DigiArz-Android-debug-APK` و شناسه `14320943624` تولید شد. commit بعدی فقط آزمون اضافه کرد و فایل UI را تغییر نداد.
- [x] گزارش QA در `docs/STOP_LIMIT_QA_MATRIX.md` به‌روزرسانی شد؛ commit آن `565f7e9e4b6bdc03c537c8a21af3d07a85436413` است.
- [x] Supabase project `gfoaubfilhttnwjykaox` در ابزار پروژه با وضعیت `ACTIVE_HEALTHY` و PostgreSQL `17.11.0.018` مشاهده شد. فهرست development branchها خالی بود؛ پس branch ایزوله Supabase در دسترس نیست.
- [!] تلاش‌های بعدی برای خواندن فهرست جدول‌ها و اجرای SELECTهای catalog به connection timeout خورد؛ بنابراین شمارش تازهٔ ردیف‌ها و دریافت کامل تعریف زندهٔ تابع در این اجرا تأیید نشد. هیچ ادعای تازه‌ای دربارهٔ شمارش سفارش‌ها/رزروها یا بدنهٔ توابع Production ثبت نمی‌شود.
- [!] PR شماره ۸ با عنوان `fix(db): prevent Iran exchange sync queue race` همچنان Draft و باز است؛ شاخه‌اش ۳۱ commit جلوتر از main است و CI شماره ۳۲۲ موفق شده، اما تطبیق کامل بدنه و ACL تابع زندهٔ Production هنوز gate باز است. PR ادغام نشد و هیچ Migration/SQL Production اجرا نشد.
- [!] گزارش تطبیق Migration همچنان معتبر است: ۱۴ نسخهٔ اعمال‌شده بدون SQL محلی، ۲۰ timestamp mismatch و دو فایل local-only؛ دو فایل local-only بازنویسی قدیمی `refresh_market_prices()` دارند. اجرای `supabase db push` همچنان ممنوع است.
- [x] هیچ سفارش، معامله، رزرو، کیف پول، موجودی، تراکنش، تابع، مجوز، cron یا Migration در Supabase Production تغییر نکرد.

### صفحات/قابلیت‌های تکمیل‌شده و باقی‌مانده
- [x] زیرساخت PWA: manifest فارسی RTL، app shell آفلاین، cache boundary محدود و آزمون‌های Service Worker.
- [x] ساخت APK در CI برای نسخه دارای Service Worker v54 موفق شد.
- [ ] نصب و اجرای واقعی PWA/APK روی گوشی Android، قطع اینترنت و نمایش آیکون‌ها هنوز دستی تأیید نشده است.
- [ ] چرخه Stop-Limit در CI/PostgreSQL دورریختنی موفق است؛ آزمون روی Supabase branch ایزوله در دسترس نیست و سازگاری کامل تابع زنده Production همچنان جداگانه نیازمند بررسی است.
- [ ] بازبینی کامل و در صورت تأیید، آماده‌سازی PR شماره ۸؛ تا زمان رفع gate بدنه/ACL نباید Merge یا deploy شود.
- [ ] تطبیق ۱۴ migration مفقود، ۲۰ timestamp mismatch و دو فایل local-only پیش از هر `db push`.

### گام بعدی
1. آزمون نصب و حالت آفلاین APK/PWA روی Android و ثبت نتیجه واقعی.
2. پس از بازیابی اتصال پایدار Supabase، فقط خواندن تعریف کامل تابع `process_iran_exchange_asset_sync()` و ACL برای بستن یا رد gate PR شماره ۸.
3. ادامهٔ reconciliation مهاجرت‌ها؛ بدون `db push` و بدون تغییر Production تا رفع کامل اختلاف‌ها و اخذ مجوز لازم.

## اجرای مستقل روزانه — ۱۷ نوامبر ۲۰۲۶ (دکمه نصب PWA اندروید)

### اقدام ملموس روی رابط کاربری
- [x] در index.html یک نوار نصب فارسی و واکنش‌گرا اضافه شد. نوار فقط زمانی ظاهر می‌شود که مرورگر رویداد استاندارد beforeinstallprompt را ارسال کند؛ در مرورگرهای فاقد این قابلیت، دکمهٔ غیرواقعی نمایش داده نمی‌شود.
- [x] کنترل نصب در فایل مستقل src/pwa-install.js پیاده‌سازی شد: prompt فقط یک بار مصرف می‌شود، هنگام بازشدن prompt دکمه غیرفعال است و پس از انتخاب کاربر یا رویداد appinstalled نوار بسته می‌شود.
- [x] Service Worker به v55 ارتقا یافت و فایل کنترل نصب به فهرست صریح app shell افزوده شد.
- [x] workflow ساخت وب Capacitor از قبل کل پوشه src را کپی می‌کند؛ بنابراین فایل جدید در خروجی وب/APK نیز قرار می‌گیرد. ساخت APK جدید پس از این تغییر هنوز باید با CI تأیید شود.

### فایل‌ها و Commitها
- src/pwa-install.js — 23359ab6cbe54fdcdd5dfc22766cf54c54ea677c
- index.html — 68e9c6d86a2a7c7f57e70fd9655e34560b16d29a
- sw.js — 05197c1ae2f955e3aa1d53d570513022e80c338a
- tests/service-worker.test.js — 3f9358fbb07fb57621c1774a0187581d933bc6d1
- tests/pwa-install.test.js — b7ad171c2f1a038d21040bfe63043deb140533b2
- Commit کد و آزمون کنترل نصب: b7ad171c2f1a038d21040bfe63043deb140533b2

### آزمون‌ها
- [x] اجرای محلی Node 22 با دستور node --test tests/*.test.js: تعداد ۱۲ از ۱۲ موفق (۵ آزمون کنترل نصب و ۷ آزمون Service Worker).
- [x] بازخوانی GitHub پس از commitها: وجود نوار نصب، دکمه، اسکریپت defer و قانون واکنش‌گرا تأیید شد؛ مسیر خطای prompt نیز در آزمون جداگانه پوشش داده شد.
- [x] بازخوانی Service Worker: نسخه v55 و precache فایل src/pwa-install.js تأیید شد.
- [ ] اجرای GitHub Actions برای HEAD جدید از ابزار خواندن workflow در این اجرا قابل تأیید نبود؛ CI را موفق اعلام نکن.
- [ ] نصب واقعی APK/PWA، نمایش prompt و اجرای آفلاین روی گوشی Android هنوز تست فیزیکی نشده است.

### Supabase و مرز ایمنی
- [x] پروژه gfoaubfilhttnwjykaox همچنان ACTIVE_HEALTHY و PostgreSQL 17.11 گزارش شد؛ یک SELECT سبک برای تأیید اتصال و زمان سرور موفق بود.
- [!] خواندن فهرست جدول‌ها، Migrationها و یک snapshot کاتالوگ بزرگ‌تر با timeout اتصال مواجه شد؛ شمارش تازه یا تعریف زندهٔ توابع مالی از این اجرا ادعا نمی‌شود.
- [x] فهرست Development Branchها خالی بود؛ محیط Supabase ایزوله از طریق branch در دسترس نیست.
- [x] هیچ SQL، migration، function، grant، cron، سفارش، معامله، رزرو، کیف پول، موجودی یا سابقه مالی در Production تغییر نکرد.

### وضعیت صفحات و گام بعدی
- [x] صفحه ورود/پوسته اصلی: نوار نصب شرطی و RTL اضافه شد.
- [x] زیرساخت PWA: کنترل نصب در app shell و Cache v55 قرار گرفت.
- [ ] آزمون واقعی Android و تأیید APK جدید در CI باقی است.
- [ ] Stop-Limit: آزمون‌های PostgreSQL دورریختنی CI در checkpoint قبلی سبز بوده‌اند؛ سازگاری با تابع زنده Production و branch ایزوله هنوز gate جداگانه دارد.
- [ ] Migration drift، PR شماره ۸ و ACL تابع process_iran_exchange_asset_sync() همچنان نیازمند بازبینی فقط‌خواندنی و reconciliation هستند.

### گام اجرایی بعد
1. تأیید CI و تولید artifact جدید APK برای HEAD شامل install controller.
2. آزمون نصب و حالت آفلاین روی گوشی Android.
3. پس از پایداری اتصال Supabase، بازخوانی فقط‌خواندنی جدول‌ها، Migrationها، تابع sync و ACL؛ بدون db push یا تغییر Production.

## پیگیری وضعیت شاخه اصلی و بسته اندروید — ۱۷ نوامبر ۲۰۲۶، ۱۴:۱۱ به وقت محلی

- [x] HEAD شاخه `main` در شروع بررسی برابر `8cf54011e0c618589a4564da78e2ea1581faab68` بود؛ تغییرات جدید PWA شامل کنترل نصب مرورگر، مدیریت رد/خطای prompt و precache اسکریپت نصب در Service Worker v55 هستند.
- [x] پنج سناریوی کنترل نصب در `tests/pwa-install.test.js` و هفت سناریوی Service Worker در `tests/service-worker.test.js` در گزارش اجرای محلی Node 22 با نتیجه ۱۲ از ۱۲ ثبت شده‌اند.
- [x] فایل workflow ساخت APK بررسی شد: تغییرات `src/**`، `index.html` و `sw.js` روی main باید workflow اندروید را فعال کنند؛ خروجی مورد انتظار artifact با نام `DigiArz-Android-debug-APK` است.
- [!] در این بررسی، اجرای GitHub Actions برای commitهای جدید کنترل نصب از طریق ابزار قابل مشاهده تأیید نشد؛ بنابراین APK شامل کنترل نصب را هنوز موفق/منتشرشده اعلام نمی‌کنیم. آخرین APK قطعی ثبت‌شده مربوط به commit قدیمی‌تر پیش از افزودن کنترل نصب است.
- [x] PR شماره ۸ دوباره با GitHub بررسی شد: باز، Draft، ادغام‌نشده؛ مقایسهٔ فعلی `main...fix/iran-exchange-sync-response-race` برابر ۳۱ commit جلو و ۱۴ commit عقب و وضعیت compare برابر `diverged` است؛ GitHub مقدار `mergeable=false` برگرداند.
- [!] به دلیل divergence، PR شماره ۸ نباید Merge یا Ready شود. اصلاح صف صرافی‌ها باید پس از همگام‌سازی کنترل‌شده با main و اجرای مجدد CI بازبینی شود؛ هیچ rebase، merge یا force-push در این بررسی انجام نشد.
- [x] بازبینی کد کنترل نصب و Service Worker انجام شد؛ prompt فقط در صورت دریافت رویداد `beforeinstallprompt` نمایش داده می‌شود و پس از accepted/dismissed/error یا `appinstalled` بسته می‌شود. این مسیر در Capacitor WebView الزاماً prompt بومی PWA ندارد و مخفی ماندن نوار در آن محیط رفتار مورد انتظار است.
- [!] نصب واقعی روی گوشی Android، اجرای آفلاین APK، و تأیید artifact تازه همچنان نیازمند تست دستگاه هستند.
- [x] هیچ تغییر Supabase Production، Migration، تابع، مجوز، cron، داده مالی یا وضعیت PR انجام نشد.

### گام بعدی
1. یافتن و تأیید اجرای APK workflow روی commitهای پس از `b7ad171c`؛ در صورت نبود artifact تازه، اجرای workflow از GitHub Actions و سپس بررسی artifact.
2. آزمون نصب PWA در Chrome Android و آزمون نصب APK در Capacitor جداگانه؛ این دو مسیر نصب متفاوت‌اند.
3. پس از تثبیت main، بازسازی شاخه اصلاح race از روی HEAD جدید و اجرای مجدد CI؛ PR قدیمی را تا رفع divergence ادغام نکن.
4. ادامهٔ migration reconciliation؛ `supabase db push` همچنان ممنوع تا رفع کامل drift و تأیید صریح انتشار.

### اصلاح وضعیت اجرای APK و اختلاف PR — ۱۷ نوامبر ۲۰۲۶

- [x] HEAD فعلی `main` در زمان این ثبت برابر `1c19ad19e321e4e461008cc37b324aca9683d911` است؛ commit با پیام `ci(android): include APK build provenance and checksum` فقط workflow اندروید را تغییر داده است.
- [x] فایل `.github/workflows/android-apk.yml` از روی `main` بازخوانی شد. فیلتر push شامل خود فایل workflow است؛ بنابراین تغییر workflow روی `main` واجد شرایط trigger است. مرحلهٔ `Record APK build provenance` فایل `BUILD-INFO.txt` را کنار APK تولید می‌کند و SHA-256 APK را ثبت می‌کند.
- [!] وضعیت commit در combined status خالی است و wrapper موجود برای فهرست workflowهای یک commit فقط runهای مربوط به pull_request را برمی‌گرداند؛ خروجی خالی آن اثبات نمی‌کند که run مربوط به push وجود ندارد. شناسهٔ run و artifact جدید از مسیر ابزار فعلی قابل تأیید نشد؛ ساخت APK را موفق اعلام نکن.
- [x] مقایسهٔ تازهٔ `main...fix/iran-exchange-sync-response-race` برابر `diverged`، با ۳۱ commit جلو و ۱۶ commit عقب است؛ `mergeable=false`. این عدد جایگزین گزارش قدیمی ۱۴ commit عقب در یادداشت پیشین است.
- [x] PR شماره ۸ همچنان open، Draft، ادغام‌نشده و دارای head `82bf2cc70643a5c747f4ff097c8d4a7444995032` است. فقط متن توضیحات PR برای ثبت عدد ۱۶ به‌روزرسانی شد؛ شاخه، کد و وضعیت Draft دست‌نخورده ماند.
- [!] تا زمانی که run تازه و artifact دارای `BUILD-INFO.txt` بررسی نشده‌اند، APK جدید تأییدشده نیست. نصب و تست آفلاین واقعی روی گوشی نیز همچنان انجام‌نشده است.
- [x] هیچ Migration، SQL، داده، تابع، ACL، cron، سفارش یا دارایی Production تغییر نکرد؛ هیچ merge، rebase یا force-push انجام نشد.


## آغاز توسعه معاملات مشتقه مجازی — ۱۸ نوامبر ۲۰۲۶

### تصمیم محصول
- [x] کاربر تأیید کرد تمام انواع معامله به‌صورت مجازی اضافه شوند: Spot، Futures، Margin و Leverage.
- [x] قیمت بازار می‌تواند زنده باشد؛ تمام موجودی وثیقه، وام، سود و زیان، کارمزد، Funding، بهره، لیکوییدیشن و تسویه صرفاً مجازی است.
- [x] بخش مشتقه باید از موتور Spot جدا بماند؛ جدول‌ها و RPCهای فعلی سفارش و معامله Spot نباید برای پوزیشن مشتقه بازاستفاده شوند.

### مخزن و شاخه
- [x] مخزن صحیح `shahram-adim/DigiArz` و شاخه اصلی `main` بررسی شد.
- [x] HEAD مبنای main در شروع کار: `1514668bc76dc697fa26b22edb2ebfd80b2199b8`.
- [x] شاخه اختصاصی `feat/demo-derivatives-trading` ایجاد شد.
- [x] مشخصات طراحی در `docs/superpowers/specs/2026-11-18-demo-derivatives-trading-design.md` ثبت شد.
- [x] برنامه مرحله‌ای در `docs/superpowers/plans/2026-11-18-demo-derivatives-trading.md` ثبت شد.
- [x] ماژول محاسبات دقیق اولیه `src/derivatives-math.js` و تست‌های `tests/derivatives-math.test.js` اضافه شدند.
- [x] PR شماره ۱۲ به‌صورت Draft ایجاد شد: `https://github.com/shahram-adim/DigiArz/pull/12`.
- [ ] CI مربوط به PR #12 هنوز در حال اجراست؛ نتیجه نهایی تا مشاهده پایان run اعلام نمی‌شود.

### ممیزی فقط‌خواندنی Supabase
- [x] پروژه `gfoaubfilhttnwjykaox` در وضعیت `ACTIVE_HEALTHY` و PostgreSQL `17.11` است.
- [x] فهرست جداول public بررسی شد؛ جدول مشتقه/فیوچرز/مارجین/پوزیشن یا تابعی با این نام‌ها وجود ندارد.
- [x] جداول فعلی Spot شامل `wallets`, `orders`, `trades`, `asset_balances`, `order_reservations`, `market_prices`, `demo_trading_pairs` و `conditional_orders` هستند.
- [x] توابع فعلی Spot از جمله `execute_demo_trade`, `place_limit_order`, `place_conditional_exit_order`, `cancel_limit_order`, `cancel_stop_limit_order` و Workerهای مربوط بررسی اولیه شدند.
- [x] Cronهای فعال خوانده شدند؛ Workerهای فعلی برای Limit، TP/SL، Stop-Limit و همگام‌سازی بازار فعال‌اند. هیچ Cron جدیدی ایجاد نشد.
- [x] هیچ شیء، Migration، تابع، Grant، RLS، Cron، سفارش، کیف پول، موجودی یا داده Production تغییر نکرد.

### مانع حیاتی قبل از هر DDL
- [!] تاریخچه Production شامل ۵۲ Migration اعمال‌شده است، اما مخزن فقط ۴۰ فایل Migration دارد.
- [!] گزارش reconciliation موجود: ۱۴ Migration اعمال‌شده منبع SQL محلی ندارند؛ ۲۰ فایل محلی timestamp متفاوت با نسخه اعمال‌شده دارند؛ ۲ فایل محلی اصلاً در تاریخچه Production ثبت نشده‌اند.
- [!] دو Migration محلی KuCoin/Gate.io نسخه قدیمی تابع `refresh_market_prices()` را جایگزین می‌کنند و اجرای کورکورانه آن‌ها می‌تواند نسخه زنده دارای سقف ۵۱۵ شناسه و منابع Gate.io/KuCoin را تنزل دهد.
- [!] شاخه توسعه Supabase در دسترس نیست؛ بنابراین هیچ محیط ایزوله Supabase برای اجرای Migration مشتقه وجود ندارد.
- [x] تصمیم ایمنی: تا زمان بازیابی schema/function/grant/RLS/cron و تطبیق Migrationها، هیچ DDL یا Migration در Production اعمال نمی‌شود؛ `supabase db push` ممنوع باقی می‌ماند.

### گام بعدی
1. تکمیل بررسی فقط‌خواندنی تعریف کامل توابع Spot، ACLها، RLS policyها و جزئیات دقیق جداول مرتبط.
2. ساخت fixture مستقل PostgreSQL 17 برای فرمول‌ها و چرخه‌های Futures/Margin.
3. توسعه backend مشتقه در شاخه GitHub و افزودن تست‌های تراکنش، idempotency، رقابت هم‌زمان، RLS و بازیابی.
4. سپس رابط کاربری فارسی RTL؛ تا آماده شدن backend امن، هیچ دکمه ثبت سفارش مشتقه به کاربر نمایش داده نشود.


## آزمون ایزولهٔ اولیهٔ Schema مشتقه — ۱۸ نوامبر ۲۰۲۶

- [x] برای draft مشتقه fixture مستقل PostgreSQL 17 اضافه شد؛ نقش‌های anon و authenticated، جدول آزمایشی auth.users و تابع آزمایشی auth.uid() فقط در دیتابیس دورریختنی CI ساخته می‌شوند.
- [x] تست یکپارچه برای درج حساب، سفارش، پوزیشن، Fill، وام، Funding، رویداد ریسک و دفترکل اضافه شد.
- [x] تست RLS تأیید می‌کند کاربر فقط حساب و سفارش خودش را می‌بیند و نقش authenticated مجوز نوشتن مستقیم در جدول حساب‌ها ندارد.
- [x] تست immutability برای جلوگیری از UPDATE/DELETE روی ردیف‌های دفترکل اضافه شد.
- [x] تست منفی جداگانه برای رد تراکنش دفترکل نامتوازن اضافه شد.
- [x] مراحل جدید به workflow موجود Exact decimal tests افزوده شد تا در اجرای PR همراه با مجموعه تست‌های قبلی اجرا شوند؛ workflow موازی و تکراری حذف شد.
- [ ] اجرای تازه GitHub Actions برای commitهای این تغییر هنوز مشاهده و تأیید نشده است؛ تا دریافت نتیجه، تست Schema مشتقه را موفق اعلام نکن.
- [!] بازبینی ساختاری هنوز باید قیود تطبیق account/order/position، جلوگیری از افزودن ردیف به تراکنش دفترکل پس از نهایی‌شدن و اتصال موجودی‌های حساب به دفترکل را پوشش دهد.
- [x] همهٔ فایل‌ها و تست‌ها فقط در شاخه feat/demo-derivatives-trading هستند؛ هیچ Migration به مسیر فعال منتقل نشده و هیچ SQL، جدول، تابع، Grant، RLS، Cron یا داده‌ای در Supabase Production تغییر نکرده است.

### گام بعدی
1. بررسی اجرای CI تازه و رفع هر خطای واقعی از روی لاگ.
2. بستن شکاف‌های integrity در Schema مشتقه با تست‌های منفی و مثبت.
3. سپس افزودن RPCهای تراکنشی و تست رقابت هم‌زمان؛ تا آن زمان رابط ثبت سفارش مشتقه نباید فعال شود.


## تقویت یکپارچگی Schema مشتقه — ۱۸ نوامبر ۲۰۲۶

- [x] کلیدهای خارجی مرکب اضافه شدند تا Fill نتواند به سفارش/پوزیشن حساب دیگر وصل شود؛ وام، Funding و Risk event نیز به همان account مالک پوزیشن محدود شدند.
- [x] تست‌های منفی cross-account برای Fill، Margin Loan، Funding و Risk Event اضافه شدند.
- [x] دفترکل با شناسه تراکنش PostgreSQL (xid8) قفل شد تا پس از commit تراکنش، درج ردیف جدید در همان گروه دفترکل رد شود؛ تست late-append اضافه شد.
- [x] تست fixture حساب دوم برای همان کاربر اضافه و تعدادهای مورد انتظار RLS اصلاح شدند.
- [ ] اجرای تازه workflow پس از آخرین تغییرات هنوز در دسترس/قابل مشاهده نیست؛ نتیجه CI و اجرای واقعی PostgreSQL تأیید نشده است.
- [!] این Schema هنوز draft است؛ مانده‌های cash در حساب هنوز به‌صورت aggregate از دفترکل مشتق نمی‌شوند و RPCهای تراکنشی/قفل‌گذاری و آزمون race هنوز ساخته نشده‌اند.
- [x] تغییرات فقط در شاخه feat/demo-derivatives-trading و PR #12 باقی مانده‌اند؛ Production دست‌نخورده است.

### گام بعدی
1. گرفتن نتیجه اجرای کامل workflow PostgreSQL 17 و اصلاح هر خطای واقعی.
2. طراحی و پیاده‌سازی دفترکل به‌عنوان منبع حقیقت موجودی؛ سپس RPCهای idempotent برای انتقال، سفارش، Fill، کارمزد، PnL، Funding، بهره و تسویه.
3. آزمون race چندجلسه‌ای، retry و rollback پیش از هرگونه فعال‌سازی رابط مشتقه.


## اصلاح محدودهٔ محاسبه ریسک Cross Margin — ۱۸ نوامبر ۲۰۲۶

- [x] بازبینی مستقل ماژول محاسبات نشان داد نسخه اولیهٔ riskSnapshot برای Cross Margin همچنان equity، margin ratio و atRisk را با ورودی margin یک پوزیشن محاسبه می‌کرد؛ این خروجی می‌توانست به‌اشتباه ریسک حساب را شبیه ریسک یک پوزیشن نشان دهد.
- [x] در Cross Margin اکنون equity، marginRatio و atRisk عمداً null هستند تا موتور تجمیعی حساب ساخته شود؛ liquidationPrice نیز null باقی می‌ماند. خروجی riskScope برابر account است.
- [x] برای marginMode ناشناخته خطای صریح اضافه شد.
- [x] تست‌ها برای Cross Margin بدون isolatedMargin و برای رد حالت ناشناخته به‌روزرسانی شدند.
- [ ] اجرای تازه GitHub Actions برای commitهای جدید هنوز مشاهده نشده؛ تغییرات محاسباتی هم تا آن زمان اجراشده/موفق اعلام نمی‌شوند.
- [!] موتور تجمیعی Cross Margin هنوز پیاده‌سازی نشده است؛ UI نباید اعداد ریسک حساب را از این تابع حدس بزند.
- [x] تغییرات فقط در شاخه feat/demo-derivatives-trading ثبت شدند؛ Supabase Production دست‌نخورده است.

### گام بعدی
1. تأیید اجرای CI کامل روی head فعلی PR و رفع خطاها.
2. ساخت مدل حساب‌محور Cross Margin که تمام پوزیشن‌ها، بدهی‌ها، کارمزد بستن، بهره و Funding را زیر قفل حساب تجمیع کند.
3. سپس طراحی RPCهای تراکنشی با دفترکل به‌عنوان منبع حقیقت مانده‌ها و تست‌های race/idempotency.


## موتور محاسبه تجمیعی Cross Margin فیوچرز — ۱۸ نوامبر ۲۰۲۶

- [x] اجرای ناموفق قدیمی CI با run 44188333770 و job 134410702774 بررسی شد؛ تنها شکست تست قدیمی انتظار قیمت لیکوییدیشن ایزوله بود (90.488638648702995 در برابر مقدار دقیق 90.488638648702996179). این انتظار در commit بعدی اصلاح شده است؛ این run روی وضعیت قبلی بوده و نتیجهٔ HEAD فعلی محسوب نمی‌شود.
- [x] مدل اولیهٔ تجمیع Cross Margin فقط برای Futures تسویه‌شونده با USDT تعریف شد؛ پوزیشن‌های Margin Spot و وثیقهٔ چنددارایی عمداً خارج از این تابع هستند تا haircut و تبدیل وثیقه بدون قرارداد مستقل حدس زده نشود.
- [x] تابع خالص crossMarginRiskSnapshot اضافه شد: موجودی نقدی ledger-derived، PnL تمام پوزیشن‌های Cross، Maintenance Margin کل، ذخیرهٔ کارمزد بستن و تعهدات دیگر/بهره/Funding/کارمزد تسویه‌نشده را در سطح حساب تجمیع می‌کند.
- [x] اگر حتی یک mark price تازه نباشد، خروجی ریسک حساب stale_price و مقادیر equity/ratio/atRisk را null می‌کند؛ قیمت لیکوییدیشن واحد برای حساب چندپوزیشنی ساخته نمی‌شود.
- [x] تست‌های چندپوزیشن long/short، بدهی و کارمزد، عبور از Maintenance، stale price و رد پوزیشن isolated/non-futures اضافه شدند.
- [!] این helper فقط لایهٔ محاسباتی است؛ ورودی cash باید از projection معتبر دفترکل در سمت سرور تأمین شود. هنوز projection دفترکل، RPC قفل‌دار حساب، snapshot قیمت معتبر، تست SQL و race وجود ندارد؛ بنابراین این تابع به‌تنهایی موتور اجرایی یا مجوز لیکوییدیشن نیست.
- [ ] CI روی HEAD جدید هنوز باید اجرا و نتیجهٔ واقعی ثبت شود.
- [x] هیچ تغییر Supabase Production، Migration فعال، RPC، Cron، موجودی یا دادهٔ مالی انجام نشد.

### گام بعدی
1. اجرای CI روی آخرین HEAD و اصلاح هر خطای جدید با لاگ.
2. تکمیل طراحی projection دفترکل برای futures_cash و تعریف دقیق نحوهٔ نمایش/رزرو سفارش‌های باز در Equity و Available Margin.
3. سپس پیاده‌سازی تابع حساب‌محور در PostgreSQL و آزمون‌های دو نشست برای سفارش/بستن/لیکوییدیشن؛ قبل از این مرحله هیچ UI ثبت سفارش مشتقه فعال نشود.


## قرارداد حسابداری دفترکل و Available Margin فیوچرز — ۱۸ نوامبر ۲۰۲۶

- [x] وضعیت واقعی شاخه پیش از ادامه بررسی شد: HEAD برابر `e55808b46b94457658aae9a9ef7bb580a777b9ba`؛ PR #12 باز و Draft؛ شاخه نسبت به main برابر ۳۴ commit جلو و ۱ commit عقب است.
- [x] بازبینی Schema draft نشان داد `futures_cash_usdt` و `margin_cash_usdt` در جدول حساب کنار دفترکل مستقل تعریف شده‌اند؛ اگر هر دو منبع حقیقت باشند خطر اختلاف مانده وجود دارد.
- [x] قرارداد حسابداری در `docs/superpowers/specs/2026-11-18-futures-ledger-accounting.md` ثبت شد: دفترکل immutable تنها منبع حقیقت cash؛ ماندهٔ Futures از مجموع debit-credit در bucket برابر `futures_cash` و asset برابر USDT محاسبه می‌شود.
- [x] تفکیک Wallet Cash، Unrealized PnL، Equity، Maintenance Margin، Initial Margin و Available Margin تعریف شد.
- [x] رزرو سفارش Limit به‌عنوان تعهد مشتق‌شده از سفارش‌های باز تعریف شد، نه برداشت نقدی یا ردیف دفترکل؛ سفارش Reduce-only فقط مقدار قابل‌بستن را رزرو می‌کند.
- [x] قواعد جلوگیری از دوباره‌شماری کارمزد/Funding ثبت شد: مواردی که در دفترکل ثبت شده‌اند نباید دوباره از Equity کم شوند؛ بدهی و بهرهٔ Margin Spot از حساب Futures جدا هستند.
- [x] قفل حساب با `FOR UPDATE` به‌عنوان mutex تمام RPCها و workerها، همراه با idempotency و ترتیب قفل ثابت، تعریف شد.
- [!] این commit فقط سند طراحی است؛ ستون‌های فعلی Schema draft هنوز حذف/اصلاح نشده‌اند و هیچ projection یا RPC پیاده‌سازی نشده است.
- [ ] اجرای CI روی HEAD جدید هنوز مشاهده نشده است.
- [x] هیچ Migration، DDL، RPC، Cron، موجودی یا داده‌ای در Supabase Production تغییر نکرد.

### گام بعدی
1. بازنگری draft schema بر اساس قرارداد: حذف balanceهای موازی یا تعریف cache غیرمرجع، افزودن projection فقط‌خواندنی و آزمون حسابداری آن در PostgreSQL دورریختنی.
2. ساخت تست‌های محاسبهٔ Available Margin و رزرو سفارش‌های باز/نیمه‌پر.
3. سپس RPCهای تراکنشی account-lock/idempotency و آزمون race چندنشستی.


## حذف موجودی موازی و Projection دفترکل Futures — ۱۸ نوامبر ۲۰۲۶

- [x] دو ستون mutable `futures_cash_usdt` و `margin_cash_usdt` از جدول حساب در Schema draft حذف شدند؛ cash دیگر در دو منبع مستقل نگهداری نمی‌شود.
- [x] View فقط‌خواندنی `demo_derivative_futures_cash_balances` اضافه شد که USDT bucket برابر `futures_cash` را با قرارداد debit-normal یعنی `SUM(debit-credit)` محاسبه می‌کند.
- [x] View با `security_invoker=true` ساخته شده و RLS جداول حساب و دفترکل را حفظ می‌کند؛ دسترسی SELECT فقط برای authenticated داده شده است.
- [x] fixture ناسازگار سه حساب برای دو کاربر اصلاح شد؛ اکنون با قید یک حساب به‌ازای هر user سازگار است و پوزیشن حساب دوم متعلق به کاربر دوم است تا FKهای cross-account همچنان آزمون شوند.
- [x] تست‌های SQL برای cash برابر ۱۰ پس از انتقال، صفر برای دفترکل خالی، نبود ستون‌های موجودی موازی و محدودیت RLS روی View اضافه/اصلاح شدند.
- [!] اجرای PostgreSQL CI برای این تغییر هنوز مشاهده نشده؛ تا زمان اجرای workflow، صحت اجرای View و fixture تأییدشده اعلام نمی‌شود.
- [x] فقط فایل‌های draft و test در شاخه GitHub تغییر کردند؛ Supabase Production دست‌نخورده است.

### گام بعدی
1. اجرای CI روی HEAD تازه و رفع خطاهای واقعی SQL از لاگ.
2. افزودن تست‌های دقیق Available Margin و رزرو سفارش Limit/Reduce-only.
3. طراحی RPCهای تراکنشی با قفل حساب و idempotency؛ بدون فعال‌سازی UI تا پایان آزمون race.


## بازبینی و تثبیت Projection دفترکل — ۱۸ نوامبر ۲۰۲۶

- [x] دوباره تأیید شد که مدل حساب مشتقه یک ردیف به‌ازای هر کاربر دارد؛ fixture قبلی با سه حساب برای دو کاربر با UNIQUE(user_id) ناسازگار بود و اکنون به دو حساب مستقل برای دو کاربر اصلاح شده است.
- [x] پوزیشن دوم fixture اکنون متعلق به حساب و کاربر دوم است؛ تست‌های FK همچنان تلاش‌های اتصال پوزیشن به حساب/کاربر اشتباه را رد می‌کنند.
- [x] Projection فقط‌خواندنی از طریق View با `security_invoker=true` انجام می‌شود؛ آزمون SQL مقدار حساب اول برابر ۱۰ USDT و حساب دوم برابر صفر را از دفترکل بررسی می‌کند و RLS را برای نقش authenticated می‌آزماید.
- [x] بررسی ساختار آخرین HEAD نشان می‌دهد هیچ workflow run یا check-run تازه‌ای برای commitهای اخیر در GitHub قابل مشاهده نیست؛ runهای قبلی متعلق به SHAهای قدیمی‌اند و نتیجهٔ آن‌ها برای HEAD فعلی قابل تعمیم نیست.
- [!] SQL جدید هنوز در PostgreSQL اجرا نشده؛ محیط محلی این نشست فاقد `psql` است و CI تازه نیز هنوز ظاهر نشده است.
- [x] هیچ تغییری در Supabase Production انجام نشده است.

### گام بعدی
1. پیگیری CI و اجرای واقعی PostgreSQL روی آخرین HEAD؛ پیش از سبز شدن آن، projection را فقط draft محسوب کن.
2. سپس Available Margin و رزرو سفارش‌های باز را در ماژول دقیق و fixture SQL طراحی و آزمایش کن.
3. بعد از آن RPCهای account-lock/idempotency و آزمون race چندنشستی.


## محاسبهٔ دقیق Available Margin و رزرو سفارش‌ها — ۱۸ نوامبر ۲۰۲۶

- [x] تابع خالص `futuresAvailableMarginSnapshot()` به ماژول محاسبات دقیق اضافه شد؛ دامنهٔ آن فقط Futures تسویه‌شونده با USDT و Cross Margin است و Spot/Isolated/Margin Spot را وارد محاسبه نمی‌کند.
- [x] Equity از cash دفترکل، PnL تحقق‌نیافته، بدهی‌های صریحاً تسویه‌نشده و ذخیرهٔ کارمزد بستن پوزیشن محاسبه می‌شود؛ بدهی‌های ثبت‌شده در دفترکل نباید دوباره در ورودی بدهی تسویه‌نشده وارد شوند.
- [x] Initial Margin پوزیشن‌ها بر اساس mark notional و leverage و رزرو سفارش‌های باز/نیمه‌پر بر اساس remaining quantity و limit price محاسبه می‌شود.
- [x] رزرو وجه سفارش Limit شامل Initial Margin و کارمزد افتتاحیه است؛ Reduce-only وجه افتتاحیه رزرو نمی‌کند، اما مقدار قابل‌بستن را در سطح نماد/سمت تجمیع می‌کند و over-allocation را رد می‌کند.
- [x] Market order باز/نیمه‌پر رد می‌شود؛ قرارداد اجرایی آن باید fill اتمیک یا rejection باشد.
- [x] mark price نامعتبر/کهنه باعث خروجی stale و null شدن Equity و Available Margin می‌شود؛ محاسبات ذخیرهٔ وجه و کارمزد با گردکردن محافظه‌کارانه به بالا تا ۱۸ رقم اعشار انجام می‌شوند.
- [x] ۹ تست واحد جدید برای محاسبه حساب، سفارش نیمه‌پر، Reduce-only، رزرو بیش‌ازحد، قیمت stale، Market order، بدهی تسویه‌نشده و rounding اضافه شد.
- [!] این مرحله فقط ماژول خالص و تست‌های Node را اضافه کرده است؛ تست‌ها هنوز روی CI یا محیط محلی اجرا و تأیید نشده‌اند. تست SQL برای رزرو و قفل هم‌زمانی هنوز لازم است.
- [!] این helper به‌تنهایی منبع معتبر موجودی یا موتور اجرایی نیست؛ ورودی cash/positions/orders باید از سمت سرور و زیر قفل حساب خوانده شود. هیچ RPC یا UI ثبت سفارش مشتقه فعال نشده است.
- [x] PR #12 باز و Draft باقی مانده؛ شاخه همچنان با main واگراست و در این مرحله هیچ merge یا rebase انجام نشد.
- [x] بررسی دوبارهٔ Actions برای HEAD جدید هنوز هیچ run مرتبطی برنگرداند؛ run موفق برای این HEAD گزارش نمی‌شود.
- [x] هیچ Migration، DDL، RPC، Cron، موجودی یا داده‌ای در Supabase Production تغییر نکرد.

### گام بعدی
1. روشن‌کردن علت اجرا نشدن/قابل‌مشاهده نبودن workflow برای PR و اجرای واقعی تست‌های Node و PostgreSQL 17 روی HEAD فعلی.
2. افزودن fixtureهای PostgreSQL برای محاسبهٔ Available Margin، ذخیرهٔ سفارش‌های Limit، آزادسازی هنگام لغو، partial fill و تخصیص Reduce-only.
3. سپس طراحی RPCهای account-lock/idempotency و آزمون race چندنشستی؛ تا پایان آن‌ها UI مشتقه غیرفعال بماند.


## اصلاح محرک CI برای شاخهٔ مشتقات — ۱۸ نوامبر ۲۰۲۶

- [x] بررسی مستقیم نشان داد `.github/workflows/exact-decimal-tests.yml` هم در شاخهٔ قابلیت و هم در `main` وجود دارد؛ بنابراین فرض قبلیِ نبودن Workflow در base branch درست نبود.
- [x] علت قطعیِ نبودن run هنوز از APIهای در دسترس اثبات نشده است؛ ابزار بررسی runها فقط runهای pull_request را برمی‌گرداند و check/status برای SHA قبلی نیز خالی بود.
- [x] محرک `push` به Workflow گسترش یافت تا علاوه بر `main`، Push مستقیم به `feat/demo-derivatives-trading` را نیز اجرا کند؛ محرک `pull_request` به `main` حفظ شد.
- [!] پس از commit تغییر محرک، هنوز run یا status check قابل مشاهده نیست؛ بنابراین تست‌ها همچنان اجراشده یا سبز محسوب نمی‌شوند.
- [x] در بررسی بلافاصله پس از تغییر Workflow، HEAD برابر `3156a1a44e316ed5fbb45d414150fe7759abcee0` بود؛ سپس این یادداشت وضعیت به‌روزرسانی شد.
- [x] هیچ تغییری در Supabase Production انجام نشد.

### گام بعدی
1. بررسی مجدد run/status برای HEAD جدید و تشخیص اینکه GitHub Actions در مخزن فعال و مجاز است یا خیر.
2. در صورت عدم اجرای CI، اجرای تست Node در محیط محلی/runner ایزوله و ثبت خروجی واقعی؛ تست PostgreSQL 17 نیز باید اجرا شود.
3. پس از دریافت نتایج واقعی، خطاهای تست را اصلاح کن و سپس fixtureهای SQL مربوط به Available Margin و lifecycle رزرو سفارش را اضافه کن.

- [x] بازبینی نهایی همین مرحله: PR #12 باز و Draft؛ شاخه در مقایسهٔ نهایی ۵۴ commit جلو و ۱ commit عقب main و همچنان واگراست. هیچ merge/rebase انجام نشد.


## محدودسازی ورودی Available Margin به سفارش‌های Cross Futures — ۱۸ نوامبر ۲۰۲۶

- [x] بازبینی قرارداد تابع نشان داد `futuresAvailableMarginSnapshot()` فقط برای Futures با Cross Margin تعریف شده، اما سفارش‌های ورودی را از نظر `marginMode` محدود نمی‌کرد؛ بنابراین سفارش Isolated یا Margin می‌توانست اشتباهاً وارد preview حساب Cross شود.
- [x] تابع اکنون سفارش‌های فعال را فقط در صورت `productType='futures'` و `marginMode='cross'` می‌پذیرد؛ سایر سفارش‌ها صریحاً رد می‌شوند.
- [x] fixtureهای سفارش در تست Available Margin با `marginMode='cross'` کامل شدند و تست منفی برای رد سفارش Isolated و Margin Spot اضافه شد.
- [!] تست Node و PostgreSQL برای این تغییر هنوز اجرا نشده‌اند. محیط این نشست Node.js 22.16.0 دارد اما فایل‌های مخزن به‌صورت checkout محلی در دسترس نیستند؛ `psql` نیز نصب نیست. وضعیت Actions برای SHAهای قبلی خالی بوده و از ابزار موجود نمی‌توان اجرای push-trigger را مستقل فهرست کرد.
- [x] بازبینی GitHub پس از اصلاح کد/تست‌ها: commit بررسی‌شده `0f4183e39a1f8da8b47c77ba08dff500e538d7db`؛ مقایسه با main برابر ۵۹ commit جلو و ۱ commit عقب (diverged) است. PR #12 همچنان Draft باقی می‌ماند؛ هیچ merge/rebase انجام نشد. اجرای Actions برای این SHA از خروجی‌های در دسترس تأیید نشد.
- [x] تغییرات فقط در شاخه `feat/demo-derivatives-trading` انجام شده‌اند؛ هیچ تغییر Supabase Production، Migration فعال، RPC، Cron، موجودی یا داده مالی اعمال نشده است.

### گام بعدی
1. تأیید SHA نهایی شاخه و PR #12 و بررسی اجرای Actions برای commitهای تازه؛ در صورت عدم اجرا، فراهم‌کردن runner واقعی Node/PostgreSQL 17.
2. پس از اجرای تست‌ها، طراحی SQL برای رزرو، لغو، partial fill و Reduce-only زیر قفل حساب و آزمون رقابت دو نشست.
3. بررسی قرارداد قیمت مرجع و رزرو سفارش short-limit پیش از استفاده از این helper در RPC؛ این تابع صرفاً preview است و نباید منبع تصمیم اجرای سفارش باشد.


## اصلاح خطای نحوی در محاسبات مشتقه و بررسی CI — ۱۸ نوامبر ۲۰۲۶

- [x] اجرای GitHub Actions برای HEAD قبلی `ff5627dadef903b8ad737d63a31fb2c5912b7424` مستقیماً از API بررسی شد؛ run شماره `44258864323` با شکست پایان یافت.
- [x] لاگ job نشان داد خطای قطعی `SyntaxError: Invalid or unexpected token` در `src/derivatives-math.js:123` رخ داده است؛ یک توالی متنی اضافی `\\n` پیش از comment تابع گردکردن محافظه‌کارانه وارد فایل شده بود.
- [x] همان توالی دقیق حذف شد؛ commit اصلاحی `4020813ede6a3fbcaff1db43e92e979ae694c664` ثبت شد. این اصلاح صرفاً خطای نحوی را رفع می‌کند و هنوز نتیجه تست جدید محسوب نمی‌شود.
- [!] در run شکست‌خورده ۳۷ تست کشف‌شده، ۳۵ موفق و ۲ فایل تست مشتقه به‌دلیل SyntaxError بارگذاری‌نشده بودند؛ مراحل PostgreSQL به‌دلیل توقف زودهنگام job اجرا نشدند.
- [ ] باید run جدید روی commit اصلاحی بررسی شود؛ تا مشاهده نتیجه کامل Node و PostgreSQL هیچ تستی سبز اعلام نشود.
- [x] PR #12 همچنان Draft است؛ هیچ merge/rebase و هیچ تغییر Supabase Production انجام نشد.

### گام بعدی
1. بررسی run تازهٔ Actions روی commit اصلاحی و دریافت لاگ کامل.
2. رفع خطاهای واقعی باقی‌مانده در تست Node و سپس اجرای تمام مراحل PostgreSQL 17.
3. فقط پس از سبز شدن تست‌ها، افزودن fixtureهای SQL برای lifecycle رزرو سفارش و رقابت تراکنشی.


## تأیید موفق CI پس از اصلاح SyntaxError — ۱۸ نوامبر ۲۰۲۶

- [x] اجرای Node + PostgreSQL 17 روی commit اصلاح کد `4020813ede6a3fbcaff1db43e92e979ae694c664` با run `44259730430` موفق شد.
- [x] همان workflow روی commit ثبت وضعیت `4e48a2dc1246e01b2aed04471882b2f6510b46b1` با run `44259762686` موفق شد.
- [x] workflow روی commit برنامه `e95c055524cde94ca7118f29ba3a769c20b2e820` با run `44259768302` نیز موفق شد.
- [x] لاگ Node در run دوم: ۵۸ تست، ۵۸ موفق، صفر ناموفق.
- [x] PostgreSQL 17 disposable job با موفقیت پایان یافت؛ لاگ شامل پیام موفق `demo derivatives schema integration passed` و اجرای اسکریپت‌های arithmetic و regression است. پیام‌های ERROR مورد انتظار در تست‌های منفی (ledger نامتوازن، lock timeout، relation عمداً ناموجود و رد cancel نامعتبر) بخشی از assertionها هستند؛ job در نهایت success شده است.
- [!] این سبز شدن CI، فقط کد/fixtureهای فعلی را پوشش می‌دهد؛ هنوز تست SQL برای lifecycle رزرو Available Margin شامل reserve/release/cancel/partial fill/reduce-only و race تراکنشی اضافه نشده است.
- [x] آخرین commit مستندات بررسی‌شده `e95c055524cde94ca7118f29ba3a769c20b2e820` است؛ PR #12 باز و Draft و شاخه با main واگراست (در بررسی آخر ۶۴ جلو و ۱ عقب).
- [x] هیچ Merge/Rebase و هیچ تغییر Supabase Production انجام نشد.

### گام بعدی
1. طراحی قرارداد رزرو سفارش و allocation دقیق Reduce-only در SQL؛ ابتدا روشن‌کردن سمت سفارش در برابر positionSide و نحوه تخصیص چند سفارش کاهنده.
2. افزودن integration tests برای reserve، cancel release، partial fill، reduce-only over-allocation و رقابت دو نشست با قفل ردیف حساب.
3. سپس RPCهای اتمیک با auth.uid، idempotency و ledger append-only؛ UI مشتقه تا تکمیل این مراحل غیرفعال بماند.


## تفکیک جهت سفارش از سمت پوزیشن — ۱۸ نوامبر ۲۰۲۶

- [x] بازبینی رابطهٔ Order/Position نشان داد `position_side` به‌تنهایی جهت اجرای خرید/فروش را ثبت نمی‌کند؛ در نتیجه تشخیص بازکردن Long/Short از بستن آن‌ها مبهم بود.
- [x] به Schema draft ستون مستقل `side` با مقادیر `buy/sell` اضافه شد.
- [x] چهار حالت مجاز صریح شد: Buy+Long+non-reduce برای افزایش Long؛ Sell+Long+reduce-only برای کاهش Long؛ Sell+Short+non-reduce برای افزایش Short؛ Buy+Short+reduce-only برای کاهش Short.
- [x] این قرارداد با CHECK constraint در دیتابیس enforce می‌شود؛ Fill نیز side را ثبت می‌کند و FK مرکب آن را با سفارش مبدأ تطبیق می‌دهد.
- [x] تست PostgreSQL برای رد سفارش Sell-Long و Buy-Short غیر Reduce-only افزوده شد.
- [!] این تغییر هنوز در PostgreSQL 17 یا CI اجرا نشده؛ موفقیت آن اعلام نمی‌شود.
- [x] هیچ RPC، رابط سفارش مشتقه یا Supabase Production تغییر نکرده است.

### گام بعدی
1. اجرای CI روی commit جدید و بررسی لاگ PostgreSQL.
2. طراحی تخصیص قطعی Reduce-only میان چند سفارش هم‌زمان برای یک نماد و سمت پوزیشن، همراه با آزادسازی در cancel و partial fill.
3. سپس آزمون چندنشستی زیر قفل حساب؛ RPC فقط بعد از عبور تست‌ها.


## قرارداد تخصیص قطعی سفارش‌های Reduce-only — ۱۸ نوامبر ۲۰۲۶

- [x] سیاست رزرو Reduce-only در سند حسابداری ثبت شد: مقدار رزروشده برابر مجموع remaining_quantity سفارش‌های فعال برای همان حساب/محصول/نماد/سمت پوزیشن است.
- [x] سفارش Limit جدید فقط در صورت کمتر یا مساوی بودن مقدار درخواستی با position quantity منهای رزروهای فعال پذیرفته می‌شود؛ تمام محاسبه زیر قفل ردیف حساب انجام خواهد شد.
- [x] Market Reduce-only فقط fill اتمیک یا reject است و باید از مقدار رزرو‌نشده استفاده کند؛ Market باز باقی نمی‌ماند.
- [x] در partial fill، مقدار پوزیشن و remaining سفارش به یک اندازه و در یک تراکنش کاهش می‌یابد؛ در لغو/انقضا/رد، رزرو با terminal status آزاد می‌شود و cash دفترکل تغییر نمی‌کند.
- [x] برای کاهش پوزیشن خارج از سفارش Reduce-only، سیاست محافظه‌کارانه لغو سفارش‌های فعال از جدیدترین به قدیمی‌ترین (`created_at DESC, id DESC`) ثبت شد تا رزرو از اندازه پوزیشن بیشتر نشود.
- [!] این مرحله فقط قرارداد طراحی است؛ هنوز partial unique index، RPC و تست SQL/race پیاده‌سازی نشده‌اند.
- [!] commitهای Schema و integration test مربوط به تفکیک side از position_side هنوز run قابل مشاهده‌ای در GitHub Actions ندارند؛ Combined status برای HEAD فعلی خالی است. موفقیت CI اعلام نمی‌شود.
- [x] PR #12 باز و Draft است؛ شاخه نسبت به main در بررسی اخیر ۷۱ commit جلو و ۱ عقب است. هیچ merge/rebase انجام نشد.
- [x] Supabase Production بدون تغییر باقی مانده است.

### گام بعدی
1. اجرای واقعی workflow روی HEAD و بررسی تست‌های PostgreSQL برای side/reduce-only.
2. افزودن partial unique index و fixtureهای چرخه رزرو/لغو/partial fill/Market و رقابت دو نشست.
3. سپس RPCهای account-lock/idempotency؛ رابط مشتقه تا تکمیل آن‌ها خاموش بماند.


## پوزیشن باز یکتا و سفارش Market اتمیک — ۱۸ نوامبر ۲۰۲۶

- [x] قید یکتایی جزئی برای هر `(account_id, product_type, symbol, position_side)` در پوزیشن‌های باز اضافه شد؛ Long و Short مستقل باقی می‌مانند.
- [x] Market فقط می‌تواند در همان تراکنش کامل Fill شود یا بدون Fill رد شود؛ حالت pending یا partial برای Market با CHECK دیتابیس ممنوع شد.
- [x] Fixture سفارش Market به حالت کاملاً پرشده اصلاح شد.
- [x] تست PostgreSQL برای رد پوزیشن باز تکراری و Market pending افزوده شد.
- [!] اجرای CI روی HEAD جدید هنوز بررسی نشده؛ نتیجه موفق اعلام نمی‌شود.
- [x] Supabase Production و UI/RPC سفارش مشتقه بدون تغییر مانده‌اند.

### گام بعدی
1. مشاهده CI و لاگ PostgreSQL.
2. افزودن توابع/تست چرخه Limit reserve، لغو و آزادسازی، partial fill، Reduce-only و race دو نشست با قفل حساب.


## ایندکس رزرو سفارش‌های کاهنده — ۱۸ نوامبر ۲۰۲۶

- [x] ایندکس جزئی برای سفارش‌های Reduce-only فعال بر اساس حساب/محصول/نماد/سمت پوزیشن و ترتیب جدیدترین به قدیمی‌ترین اضافه شد؛ سفارش‌های terminal در ایندکس وارد نمی‌شوند.
- [x] تست Schema وجود ایندکس یکتایی پوزیشن باز و ایندکس رزرو Reduce-only را بررسی می‌کند.
- [!] CI برای HEAD فعلی هنوز از ابزار GitHub قابل مشاهده نیست؛ تست موفق اعلام نمی‌شود.


## اصلاح وضعیت پس از تکمیل ایندکس‌ها — ۱۸ نوامبر ۲۰۲۶

این checkpoint جدید، موارد قدیمی‌تر بالا را در مورد partial unique index به‌روزرسانی می‌کند:
- [x] partial unique index پوزیشن باز `demo_derivative_positions_one_open_side_uidx` در Schema draft وجود دارد.
- [x] partial index سفارش‌های فعال Reduce-only با نام `demo_derivative_orders_reduce_only_active_idx` اضافه شده است.
- [x] Integration test وجود هر دو index و رد پوزیشن باز تکراری و Market pending را بررسی می‌کند.
- [!] در آخرین بررسی HEAD شاخه `ad71db32ebcdc16af51c83d2b4503acfaa3856f3` بود؛ Combined commit status و wrapper مربوط به runهای PR هر دو خالی بودند. اجرای تست جدید از این ابزار قابل تأیید نیست.
- [x] PR #12 باز و Draft؛ شاخه ۸۴ کامیت جلو و ۱ عقب `main` است.
- [x] هیچ تغییر Production، merge یا rebase انجام نشده است.

گام بعدی: به‌دست‌آوردن نتیجه CI قابل‌مشاهده؛ سپس ساخت و تست تراکنش‌های واقعی رزرو/لغو/partial fill و رقابت دو نشست. تا آن زمان RPC و UI مشتقه غیرفعال می‌مانند.


## اولین RPC رزرو و لغو Reduce-only — ۱۸ نوامبر ۲۰۲۶

- [x] فایل draft جدید `supabase/drafts/2026-11-18_demo_derivatives_reduce_only_rpcs.sql` اضافه شد؛ هنوز migration Production نیست.
- [x] ثبت سفارش Limit کاهنده فقط روی پوزیشن باز موجود انجام می‌شود؛ جهت اجرا از سمت پوزیشن استخراج می‌شود (Long→Sell، Short→Buy).
- [x] قفل‌گذاری ابتدا روی ردیف حساب و سپس پوزیشن انجام می‌شود؛ جمع رزرو سفارش‌های فعال قبل از درج محاسبه و سقف مقدار کنترل می‌شود.
- [x] idempotency با `(user_id, client_request_id)` پیاده شد؛ تکرار یکسان همان سفارش را برمی‌گرداند و استفاده مجدد با پارامتر متفاوت رد می‌شود.
- [x] لغو سفارش فعال نیز قفل حساب را اول می‌گیرد؛ وضعیت terminal رزرو را آزاد می‌کند و هیچ ورودی نقدی دفترکل نمی‌سازد.
- [x] wrapperهای عمومی `SECURITY INVOKER` هستند؛ helperهای نوشتن در schema غیرنمایش‌داده‌شده `private` با `SECURITY DEFINER`، `search_path` خالی، کنترل `auth.uid()` و مجوزهای محدود قرار دارند.
- [x] تست SQL برای رزرو ۰٫۶، جلوگیری از رزرو بیش از مقدار آزاد، idempotency، رد تغییر payload، آزادسازی در لغو، لغو تکراری و جلوگیری از دسترسی کاربر دیگر اضافه شد.
- [x] workflow CI برای اجرای draft و تست lifecycle در PostgreSQL موقت گسترش یافت.
- [!] اجرای CI روی HEAD فعلی هنوز از ابزار قابل مشاهده/تأیید نیست؛ نتیجه تست را موفق اعلام نمی‌کنم.
- [!] partial fill، Market Reduce-only و race دو نشست هنوز پیاده‌سازی نشده‌اند. partial fill تا تعیین ثبت اتمیک PnL، کارمزد، آزادسازی مارجین و دفترکل انجام نمی‌شود.
- [x] Supabase Production، UI و مسیر سفارش مشتقه کاربر بدون تغییر مانده‌اند.

### گام بعدی
1. مشاهده اجرای CI و لاگ کامل تست PostgreSQL.
2. تکمیل طراحی/پیاده‌سازی partial fill با دفترکل اتمیک.
3. اجرای آزمون واقعی دو نشست برای رقابت سفارش‌ها زیر قفل حساب.


## وضعیت نهایی ادامه — ۱۸ نوامبر ۲۰۲۶

- آخرین HEAD بررسی‌شده: `29ac6a790ff33aa95faacde4dad6dbc5e7251f97`.
- PR #12 همچنان Open و Draft است؛ شاخه `feat/demo-derivatives-trading` نسبت به `main` تعداد ۹۲ commit جلو و ۱ commit عقب است (diverged؛ merge/rebase انجام نشد).
- فایل‌های RPC draft، تست lifecycle و workflow CI در GitHub موجودند.
- تست‌های تازه در CI هنوز قابل مشاهده نیستند: Combined status خالی است و ابزار runهای PR نیز برای این SHA موردی برنگرداند. این به معنی موفقیت یا شکست تست نیست؛ وضعیت نامشخص است.
- SQL محلی در این محیط اجرا نشد؛ ابزار PostgreSQL محلی در دسترس نبود. تنها تأیید این مرحله، ثبت فایل‌ها و بازخوانی محتوای آن‌ها از GitHub است.
- هیچ تغییری در Supabase Production یا UI/مسیر معاملاتی مشتقات انجام نشده است.


## اجرای جزئی اتمیک سفارش Reduce-only — ۱۸ نوامبر ۲۰۲۶

- [x] نوع رویداد دفترکل `reduce_only_fill` به Schema draft اضافه شد.
- [x] RPC اجرای Fill فقط برای `service_role` مجاز است؛ wrapper عمومی `SECURITY INVOKER` و helper داخلی `SECURITY DEFINER` با `search_path` خالی است. کلید service هرگز نباید وارد APK یا مرورگر شود.
- [x] ترتیب قفل حساب ← سفارش ← پوزیشن رعایت می‌شود؛ شناسه Fill برای retry idempotent است و payload متفاوت با همان شناسه رد می‌شود.
- [x] کنترل دقت ۱۸ رقم اعشار، سقف مقدار سفارش/پوزیشن و محافظت قیمت Limit اضافه شد.
- [x] درج Fill، کاهش مقدار پوزیشن، ثبت PnL تحقق‌یافته، آزادسازی متناسب مارجین ایزوله، به‌روزرسانی مقدار پرشده/باقی‌مانده و میانگین قیمت سفارش و ثبت دفترکل USDT در یک تراکنش انجام می‌شوند.
- [x] دفترکل یک گروه متوازن برای PnL، کارمزد و انتقال مارجین ثبت می‌کند؛ آزادسازی مارجین جزئی به سمت پایین تا ۱۸ رقم اعشار گرد می‌شود و در بستن کامل، باقیمانده دقیق آزاد می‌شود.
- [x] تست SQL برای Fill جزئی، retry، overfill، نقض قیمت Limit، بستن کامل، میانگین قیمت و مانده نقدی مشتق‌شده از دفترکل اضافه شد.
- [x] Fixture اولیه اصلاح شد: مارجین ایزوله ۲۰ USDT پوزیشن اکنون در دفترکل نیز ثبت می‌شود و وجه آزاد Futures همچنان ۱۰ USDT است.
- [x] workflow CI برای اجرای RPC و تست Fill در PostgreSQL موقت گسترش یافت.
- [!] این SQL هنوز در PostgreSQL اجرا نشده و CI جدید قابل تأیید نیست؛ موفقیت تست اعلام نمی‌شود.
- [!] آزمون race دو نشست، لغو/کاهش خارجی پوزیشن و هماهنگی سفارش‌های Reduce-only دیگر باقی است.
- [x] هیچ تغییری در Supabase Production یا رابط مشتقات انجام نشده است.

### گام بعدی
1. اجرای CI و بررسی لاگ کامل PostgreSQL.
2. تست هم‌زمان دو Fill/Placement روی یک حساب با دو نشست واقعی.
3. طراحی لغو سفارش‌های Reduce-only جدیدتر در صورت کاهش خارجی پوزیشن.


## کنترل نهایی سقف رزرو پیش از Fill — ۱۸ نوامبر ۲۰۲۶

- [x] پیش از اجرای Fill، مجموع remaining سفارش‌های Reduce-only فعال برای همان حساب/محصول/نماد/سمت پوزیشن دوباره زیر قفل حساب محاسبه می‌شود؛ اگر از مقدار پوزیشن بیشتر باشد، عملیات Fail-closed رد می‌شود.
- [x] با Fill، مقدار پوزیشن و رزرو باقی‌مانده همان سفارش به یک اندازه کم می‌شوند؛ بنابراین نامساوی سقف رزرو حفظ می‌شود.
- [!] این اصلاح هم هنوز منتظر اجرای PostgreSQL CI است.


## آزمون هم‌زمان رزرو Reduce-only — ۱۸ نوامبر ۲۰۲۶

- [x] اسکریپت PostgreSQL دو نشست مستقل را هم‌زمان برای ثبت دو سفارش Reduce-only به مقدار ۰٫۷ BTC روی پوزیشن ۱ BTC اجرا می‌کند.
- [x] انتظار تست: دقیقاً یکی از درخواست‌ها موفق شود و دیگری به علت عبور از مقدار آزاد پوزیشن رد شود؛ خطای نامرتبط باعث شکست تست می‌شود.
- [x] سفارش برنده لغو می‌شود و تست آزادشدن رزرو و نبود سفارش فعال باقی‌مانده را بررسی می‌کند.
- [x] این آزمون در CI پس از تست چرخه placement/cancel و پیش از تست Fill اضافه شد.
- [!] اسکریپت هنوز در GitHub Actions اجرا و تأیید نشده؛ این فقط تست اضافه‌شده است، نه نتیجه موفق.

- [x] نحو Bash اسکریپت هم‌زمانی با `bash -n` بررسی شد؛ صحت نحوی تأیید شد، اما آزمون دیتابیسی همچنان منتظر CI است.


## آزمون رقابت دو Fill روی یک سفارش — ۱۸ نوامبر ۲۰۲۶

- [x] اسکریپت جدید برای یک حساب/پوزیشن مجزای ETHUSDT در حالت Cross ساخته شد تا Fixture تست حسابداری BTCUSDT دست‌نخورده بماند.
- [x] دو نشست `service_role` هم‌زمان هرکدام Fill به مقدار ۰٫۴ ETH روی یک سفارش ۰٫۶ ETH ارسال می‌کنند؛ دو سفارش Reduce-only دیگر هرکدام ۰٫۲ ETH رزرو می‌کنند تا مجموع رزرو اولیه دقیقاً ۱ ETH باشد.
- [x] انتظار: دقیقاً یک Fill موفق و Fill دیگر با خطای عبور از remaining سفارش رد شود.
- [x] پس از رقابت، مقدار پرشده سفارش باید ۰٫۴، مقدار باقی‌مانده سفارش ۰٫۲، مقدار پوزیشن ۰٫۶ و تعداد Fillها دقیقاً یک باشد.
- [x] تست به CI پس از نصب RPC و پیش از تست ترتیبی PnL/مارجین متصل شد.
- [!] این تست هنوز در دیتابیس اجرا نشده و نتیجه CI قابل مشاهده نیست.


## هماهنگی رزرو Reduce-only پس از کاهش خارجی پوزیشن — ۱۸ نوامبر ۲۰۲۶

- [x] RPC داخلی trusted برای بازگرداندن invariant رزرو پس از کاهش پوزیشن اضافه شد؛ ابتدا حساب و سپس پوزیشن قفل می‌شوند.
- [x] اگر مجموع رزروهای فعال از مقدار پوزیشن بیشتر باشد، سفارش‌ها به ترتیب جدیدترین `created_at DESC, id DESC` لغو می‌شوند تا رزروها دوباره در سقف پوزیشن قرار گیرند.
- [x] لغو سفارش فقط وضعیت را terminal می‌کند و هیچ حرکت وجهی در دفترکل ندارد؛ تابع فقط برای `service_role` قابل اجراست.
- [x] تست سناریوی ETHUSDT با سه سفارش فعال اضافه شد: پس از کاهش فرضی پوزیشن از ۰٫۶ به ۰٫۳، دو سفارش جدیدتر باید لغو شوند و قدیمی‌ترین رزرو ۰٫۲ باقی بماند.
- [x] تست دسترسی authenticated، ترتیب لغو، سقف رزرو نهایی و اجرای مجدد idempotent را بررسی می‌کند.
- [x] workflow پس از نصب Fill RPC، ابتدا رقابت دو Fill را اجرا می‌کند؛ سپس RPC reconciliation را نصب و تست می‌کند و در پایان تست حسابداری ترتیبی BTC را اجرا می‌کند.
- [!] SQL و تست هنوز در PostgreSQL اجرا نشده‌اند؛ نتیجه CI همچنان باید از GitHub Actions تأیید شود.
- [!] این helper هنوز به RPC نهایی لیکوییدیشن/کاهش پوزیشن متصل نشده است؛ اتصال باید در همان تراکنش و پس از کاهش معتبر پوزیشن انجام شود.
- [x] هیچ تغییری در Supabase Production یا UI مشتقات انجام نشده است.

- [x] ترتیب workflow پس از بازبینی اصلاح شد: رقابت Fill قبل از reconciliation اجرا می‌شود، زیرا reconciliation به Fixture ETH ساخته‌شده در تست رقابت وابسته است.

- [x] نحو Bash اسکریپت رقابت Fill پس از افزودن دو رزرو اضافی با `bash -n` بررسی شد؛ این فقط صحت نحوی است و اجرای دیتابیسی را ثابت نمی‌کند.

## کاهش اتمیک خارجی پوزیشن Futures و تطبیق رزروها — ۱۸ نوامبر ۲۰۲۶

- [x] بررسی مجدد وضعیت واقعی مخزن: PR #12 باز و Draft؛ HEAD پیش از ثبت این checkpoint برابر `0bea0ddd1979f99d62961e02fd876940bca25441` بود؛ شاخه نسبت به `main` تعداد ۱۳۱ کامیت جلو و ۱ کامیت عقب است (`diverged`).
- [x] در Supabase Production فقط‌خواندنی بررسی شد: پروژه `ACTIVE_HEALTHY` و PostgreSQL `17.11.0.018` است؛ هیچ جدول `demo_derivative_*` و هیچ تابع عمومی Futures/derivatives/liquidation وجود ندارد.
- [x] منبع فعلی `market_prices` بررسی شد: ۸۹۸ ردیف، ۸۹۷ ردیف تازه‌تر از ۶۰ ثانیه هنگام snapshot، منابع CoinGecko/KuCoin/Gate.io؛ جدول فقط یک last-price برای هر symbol نگه می‌دارد و refresh worker منبع آخر را جایگزین می‌کند. این داده، index/mark price یا liquidation oracle نیست.
- [x] در commit `0bea0ddd1979f99d62961e02fd876940bca25441` فایل Draft `supabase/drafts/2026-11-18_demo_derivatives_external_reduction_rpc.sql` اضافه شد. RPC فقط برای `service_role` است، account-first lock دارد، رویداد را با UUID idempotent می‌کند، PnL/fee/isolated margin را محاسبه و ledger متوازن ثبت می‌کند و سپس helper تطبیق Reduce-only را در همان تراکنش فراخوانی می‌کند.
- [x] قید نوع رویداد Schema برای `external_reduction` در risk events و `position_reduction` در ledger به‌روزرسانی شد.
- [x] تست reconciliation دیگر position را مستقیم UPDATE نمی‌کند؛ اکنون RPC واقعی را برای کاهش ETH از ۰٫۶ به ۰٫۳، PnL برابر ۳ USDT، کارمزد ۰٫۰۱، مانده ledger برابر ۲٫۹۹، لغو دو رزرو جدیدتر، retry و رد payload متفاوت/over-reduction آزمایش می‌کند.
- [x] assertion آرایهٔ سفارش‌های لغوشده null-safe شد تا نبود cancellation به‌اشتباه از تست عبور نکند.
- [x] Workflow جدید به نصب RPC و اجرای تست end-to-end متصل شد. اجرای GitHub Actions شماره `44265930201` برای commit `0bea0ddd...` شروع شده است؛ نتیجه هنوز تأیید نشده و نباید موفق اعلام شود.
- [ ] پس از پایان run، لاگ SQL مربوط به external reduction و کل PostgreSQL job بررسی شود؛ هر شکست واقعی اصلاح و دوباره اجرا شود.
- [ ] رقابت هم‌زمان external reduction با placement/fill/cancel اضافه شود.
- [ ] موتور لیکوییدیشن تا طراحی منبع مستقل index/mark price، risk tiers و مدل fee/insurance ساخته یا فعال نشود.
- [x] هیچ DDL/RPC/migration/data در Supabase Production اجرا نشد؛ UI مشتقات خاموش ماند؛ merge/rebase انجام نشد.
- [x] تست end-to-end کاهش خارجی یک assertion مستقل هم دارد: مجموع رزروهای فعال پس از لغو دو سفارش جدیدتر باید دقیقاً ۰٫۲ و حداکثر برابر مقدار پوزیشن باقی‌مانده ۰٫۳ باشد.
- [!] CI run `44265930201` exposed a failure in the external-reduction integration test at the persisted position-state assertion; the workflow did not pass.
- [x] The test failure is being instrumented: the RPC now checks that exactly one locked position row was updated and that persisted quantity/PnL/status match the calculated values; the test failure message reports the actual row snapshot. This is a diagnostic/correctness hardening change, not a verified fix.
- [ ] Re-run PostgreSQL CI and use the reported row state to identify and correct the underlying cause before marking this slice complete.
- [!] اجرای PostgreSQL CI شماره `44266382034` در مرحلهٔ ساخت RPC خارجی شکست خورد؛ لاگ قطعی علت را syntax error در مقایسهٔ `CASE` داخل IF نشان داد. شکست قبلی ناشی از اختلاف دادهٔ پوزیشن نبود؛ پیام قبلی دربارهٔ آن علت را اصلاح می‌کنیم.
- [x] مقایسه به `IS DISTINCT FROM (CASE ... END)` تغییر کرد تا عبارت شرطی در PL/pgSQL بدون ابهام parse شود.
- [ ] منتظر اجرای کامل workflow روی commit اصلاح‌شده هستیم؛ هنوز هیچ تستی برای RPC کاهش خارجی موفق اعلام نمی‌شود.
- [!] PostgreSQL run `44266662836` successfully compiled/installed the external-reduction RPC, but the end-to-end assertion's observer SELECT returned no row (`v_position_state=<NULL>`) while executing as the synthetic `service_role` in the disposable test harness.
- [x] Adjusted the integration test observer to run as the disposable database owner (so RLS cannot hide the verification row), while separately asserting `service_role` has EXECUTE and `authenticated` does not. The actual RPC remains SECURITY DEFINER/private with service_role-only wrapper grant.
- [ ] Re-run the full PostgreSQL workflow to determine whether the missing row was test-observer visibility or a real position-state issue. No production changes.
- [!] CI run `44267138721` confirmed the atomic external-reduction RPC and its reconciliation assertions pass. The following existing partial-fill test then failed because its `service_role` observer could not see the order row.
- [x] Root cause isolated to the disposable role setup: it only created `service_role BYPASSRLS` if absent, and did not normalize an already-existing role. The schema setup now explicitly enforces `NOLOGIN BYPASSRLS` and asserts the role attributes.
- [x] Restored the external-reduction integration observer to `service_role`, so both the new RPC and existing fill test verify the actual trusted role's row visibility after setup normalization.
- [ ] Re-run CI. Do not mark the overall workflow green until the full run, including the partial-fill/ledger tests, passes.

## تأیید اجرای کامل PostgreSQL برای کاهش خارجی و چرخه Reduce-only — ۱۸ نوامبر ۲۰۲۶

- [x] GitHub Actions run `44267541202` روی HEAD برابر `cd1d4aae09680e5edacefdbdf396a3ed80df820b` با conclusion برابر `success` تمام شد.
- [x] کل job موفق بود: Node exact-decimal و browser integration، تست‌های regression و arithmetic در PostgreSQL 17، rehearsalهای migration/DDL و همه تست‌های موجود Spot advanced orders.
- [x] تست‌های مشتقات نیز موفق شدند: schema/RLS/ledger immutability، placement/cancel و رقابت رزرو Reduce-only، رقابت دو Fill، نصب و تست reconciliation، کاهش اتمیک خارجی Futures و لغو newest-first، partial Fill/PnL/fees/margin release و رد ledger نامتوازن.
- [x] علت شکست‌های متوالی تست قبلی رفع شد: fixture اکنون نقش disposable `service_role` را صریحاً `NOLOGIN BYPASSRLS` می‌کند و این ویژگی را assert می‌کند؛ تست نهایی نیز با همان نقش trusted اجرا و مشاهده می‌شود.
- [x] وضعیت واقعی GitHub مجدداً بررسی شد: PR #12 باز و Draft است؛ feature branch برابر ۱۳۷ کامیت جلو و ۱ کامیت عقب `main` است (`diverged`). Merge/rebase انجام نشد.
- [!] این موفقیت فقط تست در PostgreSQL موقت CI است؛ به معنی استقرار در Supabase Production، تأیید نهایی طراحی لیکوییدیشن یا فعال‌سازی UI نیست.
- [!] RPC کاهش خارجی فعلی ورودی `execution_price` را از فراخوان trusted می‌گیرد و برای worker داخلی طراحی شده؛ خودش mark/index price را از منبع مستقل تأیید نمی‌کند و نباید به‌عنوان liquidation engine یا endpoint کاربر استفاده شود.
- [x] مرور کد فعلی تأیید کرد در شاخه feature هیچ liquidation/risk worker یا منبع مستقل mark/index price وجود ندارد. `market_prices` فعلی فقط last-price را نگه می‌دارد و منبع/زمان آخرین refresh را ثبت می‌کند؛ history چندمنبعی و mark/index مستقل ندارد.
- [ ] گام بعدی: طراحی و تست منبع مستقل mark/index price، شامل provenance چندمنبعی، stale/outlier/deviation guard، ثبت snapshot و fail-closed behavior؛ سپس طراحی maintenance tiers و هزینه/insurance accounting. تا تکمیل این موارد liquidation RPC ساخته یا فعال نشود.
- [x] Supabase Production، UI مشتقات و Spot موجود دست‌نخورده ماندند.


## تأیید CI و آغاز طراحی Oracle قیمت مشتقات — ۱۸ نوامبر ۲۰۲۶

- [x] GitHub Actions run 44268110397 روی commit 59fca3a0be00aae2fd9df326e09cfcfdc2acf9c9 با conclusion برابر success تمام شد؛ مستندات ثبت وضعیت و برنامه نیز روی همان شاخه تأیید شدند.
- [x] مسیر فعلی market_prices بررسی شد: CoinGecko/KuCoin/Gate.io هر بار همان یک ردیف آخرین قیمت هر نماد را overwrite می‌کنند؛ history هم‌زمان per-provider، index و mark ندارد.
- [x] endpointهای عمومی برای ارزیابی adapterها ثبت شدند: Binance USDⓈ-M premiumIndex، Bybit V5 linear tickers و OKX SWAP mark-price/index ticker.
- [x] helper مستقل exact-decimal برای quorum/median/freshness/outlier نوشته شد؛ تست‌های Node آن در CI بعدی اجرا خواهند شد.
- [ ] اجرای CI روی commit جدید و سپس طراحی schema خصوصی observation/batch/snapshot/policy و قرارداد ingestion worker.
- [!] این helper به‌تنهایی منبع قیمت یا liquidation oracle نیست؛ تا زمانی که collector معتبر، snapshot اتمیک و policyهای بازپخش‌شده پیاده نشوند، risk worker و liquidation ساخته/فعال نمی‌شوند.
- [x] Supabase Production، زمان‌بندی‌ها، secrets، داده‌ها، Data API و UI مشتقات دست‌نخورده ماندند.


## تأیید Oracle consensus و طراحی ذخیره‌سازی خصوصی — ۱۸ نوامبر ۲۰۲۶

- [x] CI run 44268659724 روی commit f76cc88a749ae6e16a17b906f9ba990d810429ee با نتیجه success تمام شد؛ Job دارای ۳۸ مرحلهٔ موفق و بدون failure بود.
- [x] طراحی schema خصوصی برای policyهای نسخه‌دار، چرخهٔ جمع‌آوری، وضعیت هر provider، observations و snapshotهای immutable تهیه شد.
- [x] draft SQL و تست یکپارچگی برای private schema، RLS، عدم دسترسی anon/authenticated، عدم UPDATE/DELETE شواهد immutable، quorum و atomic cycle completion اضافه شد.
- [!] این DDL فقط draft است و در CI باید روی PostgreSQL موقت اجرا شود؛ هیچ migration یا تغییر Supabase Production انجام نشده است.
- [!] سه venue endpoint الزاماً سه feed مستقل زیرساختی نیستند؛ constituent overlap و منبع Indexها باید پیش از تعیین quorum نهایی بررسی شود.
- [ ] گام بعدی: CI این draft را اجرا کند؛ سپس طراحی RPCهای ingestion/publish محدود به trusted worker و تست retry/concurrency. تا آن زمان collector زنده، risk worker و liquidation وجود ندارد.
- [x] PR #12 باز و Draft؛ شاخه feature در مقایسهٔ فعلی ۱۴۰ کامیت جلو و ۱ کامیت عقب main است؛ merge/rebase انجام نشده است.


## تأیید ذخیره‌سازی Oracle قیمت در PostgreSQL موقت — ۱۸ نوامبر ۲۰۲۶

- [x] GitHub Actions run 44269201438 روی commit 7dfc68a8d98cb4c2791206e6fdcc0fdb8abadbdf با conclusion برابر success تمام شد؛ ۴۰ مرحله موفق و صفر مرحله ناموفق.
- [x] دو مرحلهٔ جدید Oracle به‌طور مشخص در CI اجرا و تأیید شدند: اعمال draft ذخیره‌سازی خصوصی در PostgreSQL موقت و تست provenance/quorum/atomic publication/immutability.
- [x] تست‌ها تأیید کردند: تکمیل cycle با provider pending رد می‌شود؛ snapshot پیش از پاسخ terminal همهٔ providerها منتشر نمی‌شود؛ cycle تکمیل‌شده باید snapshot داشته باشد؛ healthy snapshot حداقل quorum را می‌خواهد؛ observations و snapshots قابل UPDATE/DELETE نیستند؛ anon/authenticated به جداول Oracle دسترسی ندارند.
- [x] policy نسخه‌دار، provider cycle، observation و snapshot در schema خصوصی و با RLS فعال طراحی شدند؛ collector هنوز وجود ندارد و service_role فقط برای trusted server-side در نظر گرفته شده است.
- [!] این نتیجه فقط PostgreSQL موقت CI است؛ هیچ DDL، migration، secret، function، schedule یا داده‌ای در Supabase Production تغییر نکرده است.
- [ ] گام بعدی: طراحی RPCهای محدود ingestion و snapshot publication، با idempotency، قفل چرخه و رفتار retry/crash/concurrency؛ قبل از collector زنده باید تست شوند.
- [!] سه venue endpoint لزوماً سه منبع underlying مستقل نیستند؛ constituent overlap و استقلال source-family هنوز نیازمند بررسی است.
- [x] وضعیت مقایسهٔ GitHub هنگام ثبت این checkpoint: PR #12 باز و Draft؛ شاخه ۱۴۲ کامیت جلو و ۱ کامیت عقب main است. Merge/rebase انجام نشده است.


## RPCهای امن Ingestion و انتشار Oracle قیمت — ۱۸ نوامبر ۲۰۲۶

- [x] قبل از تغییر، HEAD واقعی PR #12 و فایل‌های Oracle روی شاخه feature بازخوانی شدند؛ PR همچنان Draft و شاخه از main واگراست. تغییرات قبلی بازنویسی نشدند.
- [x] Draft ذخیره‌سازی Oracle سخت‌گیرانه‌تر شد: فهرست sourceهای snapshot اکنون باید دقیقاً با observationهای accepted منطبق باشد؛ providerهای صرفاً received/rejected نمی‌توانند به‌عنوان منبع قیمت سالم شمرده شوند.
- [x] دسترسی مستقیم DML نقش service_role به جداول Oracle حذف شد؛ نوشتن باید از RPCهای محدود و trusted انجام شود.
- [x] سه تابع خصوصی SECURITY DEFINER با search_path خالی اضافه شد: شروع cycle با idempotency روی cycle UUID و instrument map؛ ثبت پاسخ provider با idempotency و رد payload متفاوت؛ انتشار snapshot با قفل cycle، کنترل quorum، freshness/future skew، median دقیق numeric، انحراف per-source و mark/index و تکمیل اتمیک cycle.
- [x] توابع فقط به service_role مجوز EXECUTE می‌دهند و داخل بدنه claim نقش service_role را کنترل می‌کنند؛ anon/authenticated دسترسی ندارند. service_role نباید در Android/browser قرار گیرد.
- [x] تست PostgreSQL جدید برای cycle creation/idempotency، رد payload متفاوت، جلوگیری از انتشار با provider pending، ثبت و retry provider، median و snapshot publication، retry انتشار و مجوزهای نقش‌ها اضافه شد.
- [x] workflow موجود به نصب draft RPC و اجرای تست جدید در همان PostgreSQL 17 موقت متصل شد.
- [!] این تغییرات فقط در GitHub feature branch و تست disposable قرار دارند؛ هنوز CI روی HEAD جدید تأیید نشده است. تا دیدن نتیجه کامل PostgreSQL، موفقیت اعلام نمی‌شود.
- [!] هنوز collector واقعی HTTP، adapterهای provider، بررسی استقلال constituentهای index، backtest آستانه‌ها و زمان‌بندی worker وجود ندارد. این RPCها خودشان به اینترنت متصل نمی‌شوند و به‌تنهایی Oracle زنده نیستند.
- [x] هیچ migration، DDL، RPC، secret، cron، schedule، داده یا تنظیمی در Supabase Production تغییر نکرد؛ UI مشتقات خاموش است؛ merge/rebase انجام نشد.

### گام بعدی
1. بررسی CI روی HEAD جدید و اصلاح هر شکست واقعی در SQL/fixture/workflow.
2. پس از سبز شدن CI، افزودن تست‌های race دو نشست برای duplicate cycle/provider result/publication و crash/retry مرزی.
3. سپس طراحی collector و adapterهای واقعی Binance USDⓈ-M، Bybit Linear و OKX SWAP؛ پیش از تعیین quorum نهایی باید هم‌پوشانی constituentها و معنای index هر venue بررسی شود.
4. فقط پس از backtest و تأیید منبع مستقل mark/index، سراغ risk tiers و maintenance/liquidation accounting برویم.


## اصلاح خطای parse در RPCهای Oracle و اجرای مجدد CI — ۱۸ نوامبر ۲۰۲۶

- [x] CI run `44283184610` روی commit `9a72e7200534d2510af88d4a01906f0aef124117` همه مراحل قبلی از جمله schema و storage Oracle را با موفقیت گذراند، اما در مرحلهٔ اعمال RPCهای Oracle متوقف شد.
- [x] علت قطعی از لاگ PostgreSQL: دو regex در شرط نماد و SHA-256 به‌دلیل کوتیشن/خط‌بندی ناقص، رشتهٔ SQL را باز نگه می‌داشتند؛ در نتیجه parser خطای unterminated quoted string داد.
- [x] فایل RPC بازبینی و از تکه‌های تکراری/ناقص پاک‌سازی شد؛ اکنون دقیقاً سه تعریف تابع، یک BEGIN/COMMIT و دو regex بسته و دارای THEN دارد.
- [x] فایل تست Oracle همچنان یک نسخهٔ ۱۴۹ خطی است و در این اصلاح تغییر نکرد.
- [!] اصلاح فقط در feature branch است؛ CI جدید هنوز باید همه مراحل را اجرا کند. تست‌های RPC تا نتیجهٔ آن سبز اعلام نمی‌شوند.
- [!] Supabase Production، داده‌ها، secrets، cron و UI همچنان دست‌نخورده‌اند؛ PR #12 همچنان Draft می‌ماند.

### گام بعدی
1. بررسی اجرای CI جدید تا عبور از نصب RPC و اجرای تست‌های آن.
2. اگر تست‌ها سبز شدند، افزودن تست‌های race دو نشست برای cycle/provider result/publication و crash/retry؛ اگر شکست خوردند، فقط بر اساس خطای دقیق اصلاح شود.
3. سپس طراحی collector و adapterهای واقعی و ارزیابی استقلال feedها؛ هنوز هیچ Oracle زنده یا liquidation engine فعال نیست.


## تأیید CI برای RPCهای Oracle — ۱۸ نوامبر ۲۰۲۶

- [x] اجرای GitHub Actions شمارهٔ `44284543586` با نتیجهٔ `success` و هر ۳۸ مرحلهٔ اصلی موفق تمام شد.
- [x] این اجرا commit کد `aa90a91e4728e0ec83353c3ed70aa59ea2188fe6` را checkout کرد؛ فایل SQL اصلاح‌شدهٔ RPC و تست Oracle در همین commit حضور داشتند.
- [x] مراحل ۲۲ تا ۲۸ موفق: ساخت دیتابیس مشتقات موقت، اعمال schema، بررسی RLS/ledger/immutability، اعمال storage اوراکل و تست provenance/quorum/atomic publication، سپس اعمال هر سه RPC مورداعتماد و تست چرخهٔ provider/idempotency/انتشار اتمیک.
- [x] تمام مراحل بعدی Reduce-only، reconciliation، fill، external reduction و ledger نیز سبز شدند.
- [!] PR #12 در زمان ثبت این یادداشت همچنان Draft است. HEAD فعلی PR برابر `9e27b132111b498df0bb9a6c927c4ca99e5878f0` است؛ این commit پس از commit تست‌شده فقط ثبت وضعیت را به‌روزرسانی کرده و فایل‌های اجرایی Oracle را تغییر نداده است.
- [!] مقایسهٔ فعلی feature با main: ۱۵۳ commit جلو و ۱ commit عقب؛ GitHub هنوز وضعیت را diverged گزارش می‌کند. ادغام/بازپایه‌سازی انجام نشد.
- [x] هیچ تغییری در Supabase Production، داده‌ها، secrets، cron یا UI انجام نشد.

### گام بعدی
1. اضافه‌کردن آزمون‌های واقعی دو نشست PostgreSQL برای raceهای start-cycle با UUID یکسان، ثبت هم‌زمان نتیجهٔ یک provider، انتشار هم‌زمان یک snapshot، و retry پس از قطع/خطای client.
2. اجرای CI مجدد و بررسی نتیجهٔ آزمون‌های جدید.
3. پس از آن، طراحی collector و adapterهای Binance USDⓈ-M، Bybit Linear و OKX SWAP و بررسی استقلال واقعی feedها؛ تا آن زمان Oracle زنده محسوب نمی‌شود.


## افزودن تست‌های هم‌زمانی واقعی برای Price Oracle — ۱۸ نوامبر ۲۰۲۶

- [x] پیش از افزودن، workflow، تست ترتیبی RPC و الگوی race دو نشست PostgreSQL موجود بازخوانی شد؛ تست قبلی دست‌نخورده باقی ماند.
- [x] فایل جدید `supabase/tests/demo_derivatives_price_oracle_concurrency.sh` اضافه شد. دو اتصال مستقل PostgreSQL این سناریوها را اجرا می‌کنند:
  - ساخت هم‌زمان یک cycle با UUID و درخواست یکسان؛ انتظار یک cycle و دقیقاً دو source row.
  - تحویل هم‌زمان نتیجهٔ یکسان برای provider؛ انتظار یک observation و پاسخ idempotent برای هر دو فراخوانی.
  - تحویل هم‌زمان دو payload متفاوت برای یک provider/cycle؛ انتظار یک برنده، یک رد idempotency و بدون overwrite.
  - انتشار هم‌زمان یک snapshot یکسان؛ انتظار تکمیل cycle و فقط یک snapshot.
  - retry پس از commit با فرض گم‌شدن پاسخ موفق client برای start-cycle، provider-result و publication.
- [x] مرحلهٔ جدید اجرای این shell test به workflow `.github/workflows/exact-decimal-tests.yml` اضافه شد.
- [x] تست از policy نسخهٔ immutable استفاده می‌کند و آن را update نمی‌کند؛ بازهٔ freshness و expiry همان مقدار fixture است.
- [!] تست‌های جدید هنوز در CI اجرا نشده‌اند؛ هیچ نتیجهٔ سبزی برای این بخش ادعا نمی‌شود. اجرای CI پس از آخرین commit باید بررسی شود.
- [x] تغییرات فقط در feature branch و disposable PostgreSQL workflow هستند؛ Supabase Production، داده‌ها، secrets، cron و UI تغییری نکرده‌اند. PR #12 همچنان Draft است.

### گام بعدی
1. بررسی CI جدید و اصلاح صرفاً بر اساس خطای واقعی shell/SQL یا race.
2. اگر raceها سبز شدند، بررسی adapterهای HTTP و قرارداد timestamp/precision/normalization برای Binance USDⓈ-M، Bybit Linear و OKX SWAP.
3. سپس سنجش استقلال feedها و backtest آستانه‌ها؛ هنوز هیچ worker یا Oracle زنده‌ای فعال نیست.


## اصلاح race ساخت هم‌زمان Price Cycle — ۱۸ نوامبر ۲۰۲۶

- [x] اجرای اولیهٔ race fixture در CI شمارهٔ `44285940192` به مرحلهٔ جدید رسید اما شکست واقعی را آشکار کرد: در دو نشست هم‌زمان، `INSERT ... ON CONFLICT (id) DO NOTHING` فقط قید primary key را به‌عنوان arbiter می‌پذیرفت و برخورد روی قید یکتای مرکب `(id,symbol)` را مدیریت نمی‌کرد.
- [x] در تابع `demo_derivative_price_start_cycle` عبارت به `ON CONFLICT DO NOTHING` تغییر کرد تا همهٔ قیود یکتا پوشش داده شوند؛ مسیر بعدی همچنان ردیف موجود را قفل و symbol/providers/instrument map را مقایسه می‌کند و درخواست متفاوت را رد می‌کند.
- [x] خطای قبلی fixture دربارهٔ تغییر `max_age_ms` نیز حذف شده است؛ policy نسخه‌ای immutable می‌ماند و تست از پنجرهٔ اصلی ۵۰۰۰ms استفاده می‌کند.
- [!] اجرای جدید روی commit اصلاح‌شده هنوز باید تمام شود؛ raceهای provider و snapshot هنوز تأیید نشده‌اند.
- [x] هیچ تغییری در Supabase Production یا داده‌های واقعی انجام نشد.

### گام بعدی
1. بررسی CI جدید روی commit اصلاح conflict؛ به‌ویژه step دو نشست Oracle.
2. در صورت عبور، بررسی raceهای provider-result و publication و سپس طراحی collector.


## نتیجهٔ نهایی تست‌های هم‌زمانی Oracle — ۱۸ نوامبر ۲۰۲۶

- [x] CI run `44286245890` روی HEAD ثبت‌شده در وضعیت پروژه با نتیجهٔ کامل `success` تمام شد.
- [x] مرحلهٔ ۲۹ `Run real two-session Futures price-oracle idempotency and publication races` موفق شد.
- [x] خروجی صریح تست: دو درخواست هم‌زمان برای ساخت یک cycle به یک رکورد همگرا شدند؛ تحویل تکراری یک provider فقط یک observation ساخت؛ payloadهای متفاوت فقط یک برنده داشتند؛ publication هم‌زمان فقط یک snapshot ساخت؛ retryهای پس از commit idempotent ماندند.
- [x] مراحل ۲۵ تا ۲۸ نیز در همان اجرا موفق بودند: storage Oracle، کنترل provenance/quorum/immutability، نصب RPCها و تست ترتیبی RPCها.
- [x] اصلاح `ON CONFLICT DO NOTHING` روی HEAD فعلی آزمایش شد؛ خطای duplicate key قید `(id,symbol)` دیگر در race ایجاد نشد.
- [!] این تأیید مربوط به PostgreSQL 17 موقت CI است، نه Supabase Production و نه feed زندهٔ بازار.
- [x] PR #12 همچنان Draft است؛ Production، داده‌ها، secrets، cron و UI دست‌نخورده‌اند.

### گام بعدی
1. طراحی قرارداد collector و adapterهای HTTP برای Binance USDⓈ-M، Bybit Linear و OKX SWAP: symbol mapping، timestamp semantics، decimal parsing، timeout/retry، response hashing و health classification.
2. پیش از انتخاب quorum نهایی، استقلال feedها و هم‌پوشانی constituentهای index بررسی شود.
3. سپس backtest آستانه‌های freshness/deviation و بررسی مسیر fail-closed انجام شود. تا پایان این مراحل Oracle و Futures UI زنده نمی‌شوند.


## قرارداد Adapterها و کشف هم‌پوشانی منابع — ۱۸ نوامبر ۲۰۲۶

- [x] پس از موفقیت CI شمارهٔ `44286245890`، مستند طراحی adapterها و وابستگی constituentها در `docs/superpowers/specs/2026-11-18-demo-derivatives-oracle-adapter-contract.md` اضافه شد.
- [x] endpointهای candidate و فیلدهای mark/index برای Binance USDⓈ-M، Bybit Linear و OKX SWAP ثبت شدند؛ timestampهای چند endpointی OKX باید جدا نگه داشته شوند.
- [x] endpointهای constituent برای Binance و Bybit مستند شدند؛ endpoint OKX شناسایی شده ولی schema دقیق آن تا مشاهدهٔ نمونهٔ زنده تأییدنشده باقی مانده است.
- [x] یافتهٔ مهم: طبق مستند رسمی Binance، index آن می‌تواند از Bybit و OKX و چندین صرافی دیگر قیمت constituent بگیرد؛ Bybit نیز index شش‌جفتی spot با وزن‌های پویا می‌سازد. بنابراین سه venue را نمی‌توان بدون تحلیل overlap سه feed مستقل شمرد.
- [x] سند اصلی Oracle به این قرارداد و یافتهٔ هم‌پوشانی ارجاع می‌دهد.
- [!] هیچ collector، WebSocket worker، cron، migration Production، secret یا Futures UI فعال نشده است؛ هیچ quorum/threshold نهایی تصویب نشده.
- [!] CI پس از تغییرات مستنداتی اخیر ممکن است دوباره اجرا شود؛ این تغییرات صرفاً docs هستند و نتیجهٔ قبلی ۳۸ مرحله‌ای همچنان برای کد تست‌شده معتبر است.

### گام بعدی
1. نمونهٔ زندهٔ عمومی endpointهای constituent هر سه venue را برای BTCUSDT و ETHUSDT بررسی و alias/weight/timestamp را تطبیق بده.
2. بر اساس دادهٔ واقعی، draft ذخیره‌سازی immutable برای constituent snapshots و endpoint-level hashes طراحی کن؛ schema فعلی یک provider timestamp/hash دارد و برای چند endpoint کامل نیست.
3. بعد از تثبیت provenance، collector adapterها و تست‌های parser/timeout/rate-limit ساخته شوند. تا آن زمان liquidation و Futures UI خاموش می‌مانند.


## طراحی provenance برای constituentهای Oracle — ۱۸ نوامبر ۲۰۲۶

- [x] پیش از ادامه، HEAD شاخه و فایل ثبت وضعیت/قرارداد adapter بازخوانی شدند؛ تغییرات قبلی تکرار نشدند.
- [x] تلاش برای دریافت نمونهٔ زندهٔ Binance constituents و Bybit index components برای BTCUSDT و ETHUSDT و OKX index components انجام شد؛ مسیر دسترسی فعلی پاسخ API را در دسترس قرار نداد. بنابراین هیچ schema یا فیلد OKX به‌عنوان نمونهٔ زنده تأییدشده ادعا نمی‌شود.
- [x] سند طراحی `docs/superpowers/specs/2026-11-18-demo-derivatives-oracle-constituent-provenance.md` اضافه شد؛ مدل پیشنهادی endpoint-level evidence، raw response hash، timestamp مستقل هر endpoint، immutable constituent snapshot/header/rows، alias mapping نسخه‌دار و linkage به observation را مشخص می‌کند.
- [x] طراحی برای پاسخ‌های provider-specific انعطاف‌پذیر است: raw JSON و schema marker حفظ می‌شوند و canonical exchange/instrument/source type تا زمان تأیید mapping حدسی پر نمی‌شوند.
- [!] این مرحله فقط طراحی مستنداتی است؛ هیچ جدول، RPC، collector یا adapter اجرایی اضافه نشده است. هیچ تغییر Supabase Production، secret، cron یا UI انجام نشده است.
- [ ] گام بعدی: دریافت نمونه‌های واقعی API از یک مسیر قابل دسترس و تطبیق response schema، به‌خصوص OKX؛ سپس پیاده‌سازی DDL draft و تست‌های PostgreSQL موقت برای append-only، RLS، hash/timestamp provenance و linkage اتمیک.
- [!] تا اندازه‌گیری overlap واقعی constituentها و تصویب effective quorum، هیچ venue به‌تنهایی به‌عنوان feed مستقل شمرده نمی‌شود و liquidation/Futures UI خاموش می‌مانند.


## تأیید CI طراحی provenance برای constituentهای Oracle — ۱۸ نوامبر ۲۰۲۶

- [x] اجرای GitHub Actions شمارهٔ `44288878922` روی commit سند طراحی `fbbc0e12f52da4907afed395f4112fe0584512ce` با نتیجهٔ `success` تمام شد.
- [x] اجرای GitHub Actions شمارهٔ `44288898171` روی HEAD شاخه `bf79fb9a7d9c791929053ecfc614e9e9b4bd0f99` نیز با نتیجهٔ `success` تمام شد.
- [x] هر دو اجرا job اصلی `exact-decimal` را با موفقیت و تمام ۳۸ مرحلهٔ تست/رگرسیون/تست هم‌زمانی موجود به پایان رساندند؛ مرحلهٔ تست دو نشست Oracle نیز موفق بود.
- [!] این اجراها طراحی provenance را به‌عنوان مستندات تأیید می‌کنند و تست‌های فعلی schema/RPC را روی PostgreSQL موقت اجرا می‌کنند؛ هنوز DDL جدید constituent provenance، adapter یا نمونهٔ زندهٔ API وجود ندارد.
- [x] PR #12 همچنان باز و Draft است و merge نشده. در بررسی فعلی شاخه نسبت به `main` تعداد ۱۶۸ commit جلو و ۷ commit عقب گزارش شد؛ هیچ merge یا rebase انجام نشد.
- [x] هیچ تغییری در Supabase Production، داده‌ها، secrets، cron، collector یا Futures UI انجام نشد.

### گام بعدی
1. دریافت پاسخ واقعی endpointهای constituent از مسیر قابل دسترس، به‌خصوص OKX؛ نمونهٔ مستندات رسمی جایگزین نمونهٔ زنده محسوب نشود.
2. پس از مشاهدهٔ shape واقعی، طراحی و تست DDL provenance فقط در draft و PostgreSQL موقت.
3. تا تأیید mapping و overlap واقعی، quorum مستقل تصویب نشود و collector/Oracle زنده و liquidation/Futures UI غیرفعال بمانند.


## نمونه‌برداری زندهٔ constituentهای OKX و محدودیت دسترسی Binance/Bybit — ۱۸ نوامبر ۲۰۲۶

- [x] چون دسترسی مستقیم API از مسیر جست‌وجوی وب پاسخ قابل اتکا نداد، یک workflow تشخیصی یک‌باره در `.github/workflows/oracle-constituent-sample.yml` اضافه شد؛ فقط با push همان فایل اجرا می‌شود، schedule/cron ندارد، secret نمی‌خواند و هیچ داده‌ای به Production نمی‌نویسد.
- [x] اجرای تشخیصی `44290583897` موفق شد و artifact موقت `oracle-constituent-api-samples` را تولید کرد. artifact تا ۳ روز نگه داشته می‌شود؛ پاسخ‌های OKX به‌صورت fixture پایدار در مخزن ثبت شدند.
- [x] OKX برای هر دو درخواست پاسخ HTTP 200 و `code=0` برگرداند. شکل واقعی پاسخ: `data.index`, `data.last`, `data.ts` و آرایهٔ `data.components[]` با فیلدهای `wgt`, `exch`, `symbol`, `symPx`, `cnvPx`.
- [x] BTC-USDT در نمونهٔ زنده ۵ constituent داشت: Coinbase، Bitget، Binance، OKX و Bybit؛ مجموع وزن‌ها دقیقاً 1 بود. timestamp منبع `1794999591686` برابر `2026-11-18T10:59:51.686Z` است.
- [x] ETH-USDT نیز ۵ constituent با همان پنج venue و مجموع وزن 1 داشت؛ timestamp منبع `1794999586930` برابر `2026-11-18T10:59:46.930Z` است. این overlap مستقیم نشان می‌دهد دو index constituent set مشترک دارند؛ venueهای Binance/Bybit/OKX را نباید مستقل از یکدیگر شمرد.
- [x] در هر دو نمونه، Coinbase با pair خام `BTC/USD` یا `ETH/USD` آمده و `cnvPx` با `symPx` تفاوت دارد؛ بنابراین raw pair و قیمت تبدیل‌شده باید جداگانه حفظ شوند و canonical mapping بدون قرارداد روشن نباید حدس زده شود.
- [x] fixtureهای تأییدشده:
  - `docs/superpowers/fixtures/2026-11-18-okx-index-components-btc-usdt.json` — raw body SHA-256: `38f79b87d7849abcc7c6030226aed63f813664d0838f799586b0f0651a958f04`
  - `docs/superpowers/fixtures/2026-11-18-okx-index-components-eth-usdt.json` — raw body SHA-256: `81e1ec7f0cca3230e71fab90eddbc067824bd0d88faac4f3cf04c647af7a1c7f`
- [!] Binance برای هر دو نماد HTTP 451 با پیام محدودیت جغرافیایی runner داد؛ Bybit برای هر دو نماد HTTP 403 داد. این‌ها محدودیت دسترسی همین runner هستند و به معنی نامعتبر بودن endpoint یا schema نیستند؛ پاسخ constituent زندهٔ آن دو provider هنوز تأیید نشده است.
- [x] نمونه‌ها در fixtureها برای بررسی parser آینده ثبت شدند؛ هنوز adapter اجرایی، collector، schema جدید یا quorum ساخته/فعال نشده است.
- [x] اجرای تشخیصی به‌صورت workflow موقت، بدون زمان‌بندی و بدون دسترسی نوشتن به مخزن/Production انجام شد؛ PR #12 همچنان Draft است.

### گام بعدی
1. برای Binance و Bybit مسیر دسترسی عمومی مجاز و قابل تکرار پیدا شود؛ تا آن زمان schema آن‌ها را از روی حدس پیاده‌سازی نکن.
2. برای OKX parser دقیق مبتنی بر رشته‌های decimal و fixtureهای BTC/ETH نوشته و در PostgreSQL/Node CI تست شود؛ raw exchange/pair و قیمت‌های `symPx` و `cnvPx` جدا بمانند.
3. پس از دریافت نمونهٔ مستقل Binance/Bybit، overlap و استقلال constituentها دوباره سنجیده شود؛ تا آن زمان quorum و live Oracle تصویب نشوند.


## پیاده‌سازی Parser دقیق OKX بر اساس نمونه‌های زنده — ۱۸ نوامبر ۲۰۲۶

- [x] ماژول مستقل `src/okx-index-components.js` اضافه شد؛ فقط envelope موفق OKX را می‌پذیرد و index درخواستی را با پاسخ تطبیق می‌دهد.
- [x] timestamp منبع باید رشتهٔ ۱۳ رقمی میلی‌ثانیه‌ای باشد؛ قیمت‌ها و وزن‌ها فقط به‌صورت decimal string پذیرفته می‌شوند و هیچ parseFloat/Number یا تبدیل دودویی برای مقادیر مالی استفاده نمی‌شود.
- [x] parser فیلدهای خام exchange label و spot pair را بدون canonicalization نگه می‌دارد، `symPx` و `cnvPx` را جدا حفظ می‌کند و مجموع وزن‌ها را با decimal arithmetic دقیقاً برابر 1 کنترل می‌کند.
- [x] تست‌های fixture برای BTC و ETH و تست‌های رد پاسخ ناموفق، index mismatch، timestamp نامعتبر، مجموع وزن نادرست، قیمت عددی JSON و scientific notation اضافه شدند.
- [x] در اجرای CI شمارهٔ `44291063482`، مرحلهٔ Node exact-decimal/browser integration شامل تست‌های جدید با موفقیت تمام شد؛ اجرای کامل workflow هنگام ثبت این checkpoint هنوز در حال انجام است و نتیجهٔ نهایی آن ادعا نمی‌شود.
- [x] کد و fixtureها فقط در feature branch هستند؛ هیچ collector، live worker، cron، migration یا Production write ایجاد نشده است.

### گام بعدی
1. نتیجهٔ کامل CI روی commit `485d45855af5495e5a1c46d822482af763d5632d` را بررسی کن؛ در صورت شکست فقط بر اساس لاگ اصلاح شود.
2. نمونهٔ واقعی Bybit و Binance هنوز در دسترس نیست؛ مستند رسمی Bybit endpoint و فیلدهای مورد انتظار را مشخص می‌کند، اما پاسخ زندهٔ این runner برای Bybit 403 و برای Binance 451 بوده است.
3. پس از سبز شدن CI، parser و fixtureهای بعدی را فقط با شواهد واقعی providerهای دیگر گسترش بده؛ هنوز quorum یا Oracle زنده تصویب نشده است.


## تأیید نهایی CI برای Parser زندهٔ OKX — ۱۸ نوامبر ۲۰۲۶

- [x] اجرای کامل GitHub Actions شمارهٔ `44291063482` روی commit `485d45855af5495e5a1c46d822482af763d5632d` با نتیجهٔ نهایی `success` تمام شد؛ مرحلهٔ Node exact-decimal/browser integration و تمام مراحل PostgreSQL موقت و تست‌های هم‌زمانی موفق شدند.
- [x] اجرای CI مربوط به checkpoint وضعیت پروژه، شمارهٔ `44291217444` روی HEAD فعلی `21ccb7057c39e77242e2e4f8d55c96364185b514` نیز با نتیجهٔ نهایی `success` تمام شد.
- [x] وضعیت نهایی PR #12 بررسی شد: باز، Draft و ادغام‌نشده؛ HEAD شاخه با commit بالا یکسان است.
- [!] موفقیت CI فقط اعتبار parser و regressionهای موجود را در محیط موقت تأیید می‌کند؛ پاسخ زندهٔ Binance و Bybit همچنان به‌دلیل محدودیت دسترسی runner تأیید نشده‌اند. quorum و Oracle زنده تصویب یا فعال نشده‌اند.
- [x] هیچ merge/rebase، Production migration، Supabase write، collector، cron یا فعال‌سازی Futures UI انجام نشد.

### گام بعدی
1. پیش از هر توسعهٔ چند-provider، دسترسی مجاز و قابل تکرار به نمونهٔ واقعی Binance و Bybit فراهم یا محدودیت فعلی به‌عنوان مانع ثبت شود؛ schema آن‌ها از روی حدس ساخته نشود.
2. سپس قرارداد parser و provenance هر provider جداگانه با fixture واقعی و تست منفی پوشش داده شود.
3. پس از تأیید overlap و استقلال واقعی منابع، دربارهٔ quorum تصمیم‌گیری شود؛ تا آن زمان Oracle و liquidation غیرفعال بمانند.


## سخت‌گیری بیشتر در اعتبارسنجی Parser OKX — ۱۸ نوامبر ۲۰۲۶

- [x] بازبینی آخرین CI: اجرای `44291516105` روی commit `f158c32dd426be414468598521b9cb6ec6edd150` با نتیجهٔ `success`؛ PR #12 باز و Draft باقی ماند.
- [x] Parser اکنون payload آرایه‌ای را به‌عنوان `data` معتبر نمی‌پذیرد و componentهای آرایه‌ای را رد می‌کند.
- [x] تکرار دقیق یک جفت exchange label خام و spot pair در یک snapshot رد می‌شود تا وزن یک منبع دوباره شمرده نشود.
- [x] تست منفی برای component تکراری، component آرایه‌ای و data آرایه‌ای افزوده شد.
- [!] اجرای CI برای این تغییرات جدید هنوز باید تکمیل شود؛ تا نتیجهٔ سبز، این اصلاحات تأیید نهایی محسوب نمی‌شوند.
- [!] این تغییر فقط در feature branch است؛ هیچ Production write، Supabase migration، collector، cron، merge یا rebase انجام نشده است.

### گام بعدی
1. نتیجهٔ CI commitهای اصلاح Parser را بررسی کن و در صورت شکست، فقط بر اساس لاگ اصلاح کن.
2. تا دریافت نمونهٔ واقعی مجاز از Binance و Bybit، adapterهای آن‌ها و quorum مستقل را حدس نزن.


## تأیید CI برای سخت‌گیری Parser OKX — ۱۸ نوامبر ۲۰۲۶

- [x] اجرای CI شمارهٔ `44292212493` برای commit `5397b981eaf1fdde05b7d5417e7fe9f0b72791c3` با نتیجهٔ `success`.
- [x] اجرای CI شمارهٔ `44292219101` برای commit `43d0a3110a1eb29eca67566382623ac97adef7d1` با نتیجهٔ `success`.
- [x] اجرای CI شمارهٔ `44292226177` برای commit `305017908cc8caaf79ad8fe02964c4e248c7e4ef` با نتیجهٔ `success`.
- [x] بنابراین Parser، تست‌های duplicate/malformed و همین checkpoint وضعیت در CI کامل فعلی سبز هستند.
- [x] PR #12 همچنان open و Draft و merged=false است؛ شاخه نسبت به main برابر 180 ahead و 8 behind است. هیچ merge یا rebase انجام نشده است.
- [!] محدودیت نمونه‌برداری Binance/Bybit همچنان باز است؛ تا دریافت دادهٔ واقعی و مجاز، adapter و quorum مستقل ساخته یا تصویب نمی‌شود.

### گام بعدی
1. حفظ شواهد OKX به‌عنوان fixture تشخیصی؛ آن را به‌تنهایی منبع کافی برای Oracle چند-provider تلقی نکن.
2. دسترسی مجاز به endpointهای constituent برای Binance و Bybit را از محیطی که مجاز به استفاده از آن هستیم بررسی کن؛ محدودیت منطقه‌ای را دور نزن.
3. پس از دریافت نمونه‌های واقعی، fixture و parser provider-specific را جداگانه بساز و weighted overlap را محاسبه کن.



---

## گزارش‌های main پس از نقطهٔ انشعاب


## ممیزی شبانهٔ عملیاتی و بررسی صف همگام‌سازی — ۱۸ نوامبر ۲۰۲۶، ساعت ۰۲:۳۸ تهران

### وضعیت تازهٔ GitHub و CI
- [x] HEAD شاخه `main` پیش از این ثبت برابر `1514668bc76dc697fa26b22edb2ebfd80b2199b8` بود. چهار commit اخیر پس از checkpoint قبلی فقط فایل `PROJECT_HANDOFF.md` را تغییر داده‌اند؛ کد برنامه یا Migration جدیدی روی main اضافه نشده است.
- [x] GitHub Actions روی HEAD فعلی main: آزمون Exact decimal با run `44184330023` و Pages با run `44184326443` هر دو `success` هستند.
- [x] PR شماره ۱۱ هنوز Open و Draft است؛ head برابر `32a5aefa8ea2df190c004a417d258770d96250e4` و base قدیمی آن `a74e4c35111f94a8142771a59d7882587d110bdc` است. مقایسه با main فعلی `diverged` و برابر ۴۷ commit جلو / ۷ commit عقب است؛ Merge یا rebase انجام نشد.
- [x] دو check روی head فعلی PR شماره ۱۱ هر دو موفق‌اند: matcher fixture run `44184273727` و exact-decimal run `44184273886`. لاگ matcher صریحاً موفقیت آزمون‌های recovery، interleaving و concurrent-worker را گزارش می‌کند. این آزمون‌ها در PostgreSQL موقت CI اجرا شده‌اند و به معنی تأیید Production یا مجوز ادغام PR نیستند.

### شواهد تازه از worker زندهٔ همگام‌سازی
- [x] پروژه Supabase همچنان `ACTIVE_HEALTHY` و PostgreSQL `17.11.0.018` است. تعریف زندهٔ `public.process_iran_exchange_asset_sync()` فقط‌خواندنی بازخوانی شد؛ تابع `SECURITY DEFINER`، مالک `postgres` و دارای `search_path` خالی است.
- [x] زمان‌بندی زنده تأیید شد: job 13 درخواست sync هر ۱۰ دقیقه، job 14 اجرای worker هر دقیقه، و job 17 دریافت overflow در دقیقه‌های ۵،۱۵،۲۵،۳۵،۴۵،۵۵. هیچ cron تغییر نکرد.
- [!] snapshot دوازده‌ساعتهٔ `cron.job_run_details` برای job 14 شامل ۴۲۲ اجرای failed، ۳۳۵ اجرای succeeded و یک اجرای running بود. برای failedها: میانهٔ زمان ۲۷٫۰۲۸ ثانیه، صدک ۹۵ برابر ۱۸۱٫۲۴۴ ثانیه و بیشینه ۳۲۳٫۸۸۹ ثانیه. برای succeededها: میانه ۲٫۰۶۹ ثانیه، صدک ۹۵ برابر ۱۰٫۱۸۵ ثانیه و بیشینه ۱۰۸٫۴۴۱ ثانیه.
- [!] دسته‌های خطای پرتکرار در runهای ناموفق: ۲۳۶ مورد `job startup timeout`، ۱۲۰ مورد `statement timeout` در upsert ورودی تابع (خط ۴)، ۵۹ مورد timeout در matcher update (خط ۴۴) و ۲ مورد در پاک‌سازی unmatched (خط ۱۵۷). چند شکست دیگر در parsing/به‌روزرسانی درخواست‌ها نیز ثبت شده‌اند.
- [!] در لاگ‌های PostgreSQL طی ۱۷ نوامبر ۲۰۲۶ از ۱۱:۱۰ تا ۲۳:۱۰ UTC، تعداد ۳۷۹ رویداد SQLSTATE `57014` مشاهده شد؛ آخرین مورد در ۲۰:۵۰ UTC بود. این شمارش کل رویدادهای cancellation پروژه است و نباید همهٔ آن‌ها را بدون context به job 14 نسبت داد.
- [x] در بخش پایانی همین بازه، runهای موفق متوالی job 14 با زمان‌های حدود ۳ تا ۱۰ ثانیه دیده شدند؛ آخرین snapshot یک اجرای جدید را در حال اجرا نشان می‌داد. بنابراین وضعیت اخیر بهتر شده، اما سابقهٔ شکست‌های متعدد هنوز یک ریسک عملیاتی واقعی است.
- [x] آمار تجمعی PostgreSQL (نه فقط ۱۲ ساعت اخیر): `crypto_assets` حدود ۱۸٬۸۷۵ ردیف زنده، ۵۹۴٬۸۰۰ sequential scan و ۱۱٬۲۱۸٬۵۹۳٬۱۳۰ sequential tuple read؛ `exchange_asset_observations` حدود ۴٬۹۶۰ ردیف زنده و ۷٬۱۴۴٬۰۴۶ update ثبت‌شده دارد. این counters cumulative هستند و علت دقیق هر scan/update را به‌تنهایی مشخص نمی‌کنند.
- [x] شاخص `crypto_assets_symbol_idx` فقط ۲۶ بار استفاده ثبت کرده است؛ matcher زنده روی `upper(ca.symbol)=upper(o.base_symbol)` تطبیق می‌کند و شاخص موجود `lower(symbol)` با این expression یکسان نیست. این مشاهده به‌تنهایی مجوز ساخت شاخص Production نیست.
- [!] آزمایش پنج‌تکراری PR شماره ۱۱ روی fixture مصنوعی، median دستهٔ ۱۰۰تایی را از ۶٫۱۸۸ به ۰٫۱۷۰ میلی‌ثانیه و join کامل ۴٬۹۶۰ مشاهده را از ۱۰٫۵۴۹ به ۷٫۴۲۲ میلی‌ثانیه نشان داده است؛ اما fixture هنوز رفتار نمادهای تکراری/مبهم، اولویت منبع، هزینهٔ نگهداری شاخص و رفتار سخت‌افزار Production را کامل مدل نمی‌کند. این نتایج فقط شواهد آزمایشگاهی‌اند.

### Migration و Advisor
- [x] تطبیق تازه همچنان ۵۲ Migration اعمال‌شده در Supabase در برابر ۴۰ فایل محلی را نشان می‌دهد: ۱۴ منبع SQL مفقود، ۲۰ timestamp mismatch، دو فایل محلی ثبت‌نشده و فقط چهار تطبیق دقیق. جزئیات در `supabase/MIGRATION_RECONCILIATION.md` باقی است.
- [!] دو فایل محلی KuCoin/Gate.io هنوز در مسیر migrations ثبت‌نشده‌اند و نسخهٔ قدیمی تابع قیمت بازار را جایگزین می‌کنند؛ اجرای `supabase db push` همچنان ممنوع است.
- [x] Advisor تازه: Health بدون lint؛ Security شامل ۱۵ جدول RLS-enabled بدون policy (INFO)، دو تابع SECURITY DEFINER قابل اجرا برای anon، ۲۳ تابع قابل اجرا برای authenticated و هشدار leaked-password protection؛ Performance شامل ۹ FK بدون index پوششی، ۱۱ هشدار RLS initplan و ۷ index استفاده‌نشده. هشدارها نیازمند بررسی هدفمندند و به‌تنهایی اثبات آسیب‌پذیری نیستند.

### تصمیم ایمنی و اقدام بعدی
- [x] هیچ schema، تابع، grant، cron، Migration، index، سفارش، معامله، رزرو، کیف پول، موجودی یا سابقهٔ مالی در Supabase Production تغییر نکرد. هیچ worker/RPC روی کاربران واقعی به‌عنوان تست اجرا نشد.
- [!] به‌دلیل خطاهای startup/statement timeout، تغییر cron یا جایگزینی تابع زنده در این نوبت ایمن تشخیص داده نشد. همچنین آزمایش index در PR #11 هنوز برای تصمیم Production کافی نیست.
- [ ] گام بعدی: PR #11 را فقط پس از همگام‌سازی کنترل‌شده با main فعلی و اجرای دوبارهٔ CI بررسی کن؛ fixture طرح اجرا را با نمادهای تکراری/مبهم، aliasها، اولویت منبع، write amplification و هزینهٔ index maintenance تکمیل کن. سپس فقط در محیط PostgreSQL دورریختنی یا staging ایزوله plan و timing را مقایسه کن.
- [ ] هم‌زمان job 14 را با پنجرهٔ زمانی جدید پایش کن و startup timeoutها را از statement timeoutهای خط ۴ و خط ۴۴ جدا نگه دار. تا زمان اثبات ریشهٔ مشکل، Production index/function/cron را تغییر نده.


## اصلاح نمایش دارایی‌های واقعی و فیلتر جفت‌ارزهای USDT/IRT — ۱۸ نوامبر ۲۰۲۶

### اقدام فرانت‌اند
- [x] بررسی آخرین main پیش از تغییر: `413268e89dda132fa5c29a4ded61669a7454e79a`؛ تغییرات این نوبت روی همان شاخه و بدون merge یا rebase ثبت شدند.
- [x] فایل مستقل `src/market-holdings.js` اضافه شد تا تشخیص دارایی‌های واقعاً متعلق به کاربر در صفحه کیف پول و دسته «ارزهای من» یکسان باشد.
- [x] دارایی‌های غیر USDT فقط از ردیف‌های مثبت `asset_balances` خوانده می‌شوند؛ USDT فقط از `wallets.balance_usdt` به فهرست اضافه می‌شود. ردیف احتمالی USDT در `asset_balances` برای جلوگیری از دوباره‌شماری نادیده گرفته می‌شود.
- [x] شمارنده دارایی داشبورد و صفحه کیف پول از همان فهرست یکپارچه محاسبه می‌شود؛ موجودی صفر، منفی یا نامعتبر نمایش داده نمی‌شود.
- [x] فیلتر «ارزهای من» نماد پایه را برای هر دو پسوند مظنه `USDT` و `IRT` تشخیص می‌دهد؛ برای مثال دارایی BTC می‌تواند هر دو جفت `BTCUSDT` و `BTCIRT` را در این دسته نشان دهد.
- [x] Service Worker به `digiarz-shell-v56` ارتقا یافت و ماژول جدید به پوسته آفلاین صریح اضافه شد. ساخت Capacitor از قبل کل پوشه `src` را کپی می‌کند؛ workflow ساخت وب/APK نیازمند تغییر جداگانه نبود.

### آزمون و بررسی
- [x] آزمون‌های مستقل `tests/market-holdings.test.js`: پنج سناریو برای USDT مرجع، صفر/منفی/نامعتبر، مقادیر علمی، استخراج base asset و فیلتر جفت‌های USDT/IRT.
- [x] اجرای محلی Node.js 22 برای پنج آزمون holdings و هفت آزمون Service Worker: مجموع ۱۲ از ۱۲ موفق.
- [x] سه اسکریپت inline موجود در `index.html` پس از تغییر با بررسی نحوی V8 کامپایل شدند؛ فایل helper نیز با `node --check` معتبر است.
- [x] بازخوانی GitHub پس از commitها وجود helper، استفاده آن در صفحه دارایی و بازار، Cache v56 و به‌روزرسانی آزمون پاک‌سازی cache را تأیید کرد.
- [!] combined status برای commit نهایی helper از ابزار GitHub هیچ status entry برنگرداند؛ بنابراین CI مربوط به HEAD جدید را موفق اعلام نمی‌کنیم. آزمون محلی جایگزین تأیید CI یا تست دستگاه نیست.
- [ ] آزمون بصری واقعی در Chrome Android و بررسی داده واقعی حساب پس از ورود همچنان باقی است.

### فایل‌ها و commitها
- `src/market-holdings.js`: افزودن `dd4651a24256ed04f552bbdc1f283f55f51ac308`؛ اصلاح نهایی regex در `d30b5bdaadccac687e906560b80e0a9a75bbb6ce`.
- `tests/market-holdings.test.js`: `f239d2234981a2e7f1d8b955e88b86790417962d`.
- `sw.js`: `24017b3d9d1da44b2e98d16df8d56f85dcd7cfc2`.
- `tests/service-worker.test.js`: `c3934d857b41ab56a6239b55ec1f09932e13241d`.
- `index.html`: `f7aa8bd5afd477df10f4a4d74e4b62c9f11600d6`.

### وضعیت Supabase در همین نوبت — فقط خواندنی
- [x] پروژه `gfoaubfilhttnwjykaox` در وضعیت `ACTIVE_HEALTHY` و PostgreSQL `17.11.0.018` گزارش شد.
- [x] فهرست public tables با موفقیت خوانده شد؛ ۲۲ جدول گزارش شدند. شمارنده‌ها: `profiles=1`، `wallets=1` و `orders/trades/transactions/asset_balances/order_reservations/conditional_orders=0`.
- [x] فهرست Migrationها با موفقیت خوانده شد: ۵۲ نسخه اعمال‌شده، آخرین نسخه `20261116205451`. در این نوبت هیچ Migration یا SQL اجرا نشد.
- [x] فهرست Development Branchها خالی است؛ محیط Supabase ایزوله از نوع branch در دسترس نیست.
- [x] فهرست Edge Functionها هشت تابع فعال نشان داد.
- [x] هیچ جدول، داده، تابع، مجوز، زمان‌بندی یا سابقه مالی Production تغییر نکرد؛ هیچ سفارش/معامله/رزرو/موجودی برای تست ایجاد نشد.

### گام بعد
1. تأیید اجرای CI برای HEAD جدید و اجرای کامل `node --test tests/*.test.js` در GitHub Actions.
2. آزمایش بصری «ارزهای من» با یک حساب تست مجاز و بدون تغییر موجودی Production؛ صرفاً مشاهده داده موجود.
3. ادامه QA سفارش‌های Stop-Limit در PostgreSQL دورریختنی CI؛ تا ایجاد محیط ایزوله Supabase، هیچ چرخه مالی روی Production اجرا نشود.


## ساخت APK اندروید — ۱۸ نوامبر ۲۰۲۶، ساعت ۱۱:۵۹ UTC
- [x] اجرای workflow اندروید برای commit `d30b5bdaadccac687e906560b80e0a9a75bbb6ce` با run `44289193772` در تلاش دوم (run_attempt=2) با نتیجه `success` کامل شد.
- [x] ساخت Gradle با پیام `BUILD SUCCESSFUL` و ۸۲ task موفق انجام شد؛ مرحلهٔ ثبت provenance و بارگذاری artifact نیز موفق بود.
- [x] artifact با نام `DigiArz-Android-debug-APK` و شناسهٔ `14424998502`، حجم ۳٬۴۹۸٬۳۳۷ بایت و مهلت نگهداری تا ۲۰۲۶-۱۲-۰۲T11:59:47Z ثبت شد. شامل APK و `BUILD-INFO.txt` است.
- [x] BUILD-INFO: نسخهٔ برنامه `1.0.0`، commit `d30b5bdaadccac687e906560b80e0a9a75bbb6ce`، run `44289193772`، زمان ساخت `2026-11-18T11:59:47Z`، SHA-256 APK برابر `c8a0743f38080190b1d0b45c5050a95e5a3da1859174158144fa2e8560143e04`.
- [!] این خروجی Debug برای نصب/آزمایش است؛ امضای انتشار، انتشار Play Store و تست نصب/اجرای واقعی روی گوشی هنوز تأیید نشده‌اند.
- [x] artifact از مسیر GitHub Actions قابل دریافت است: https://github.com/shahram-adim/DigiArz/actions/runs/44289193772
- [x] هیچ تغییر Supabase Production یا merge کردن PRها در این مرحله انجام نشد.

### گام بعد
1. نصب APK روی Android و تست بازشدن برنامه، ورود، بازار، دارایی‌ها و اتصال شبکه؛ ثبت هر خطا با تصویر/پیام دقیق.
2. ادامهٔ QA باقی‌مانده در CI/محیط ایزوله؛ PRهای ۸ تا ۱۲ همچنان Draft و ادغام‌نشده‌اند و هیچ‌کدام بدون بازبینی/تأیید صریح Merge نشوند.
3. پس از تست دستگاه، طراحی workflow امضای Release و مدیریت امن keystore؛ هیچ کلید امضایی در چت یا مخزن قرار نگیرد.


## بررسی دوبارهٔ PR شماره ۱۲ — ۱۸ نوامبر ۲۰۲۶
- [x] PR `#12` با عنوان `feat: add demo futures and margin trading foundation` همچنان Open و Draft است؛ شاخه `feat/demo-derivatives-trading`، commit سرشاخه `66f7175bf1b923c3d5aaa86512f5372f3c8394eb`.
- [x] check با نام `exact-decimal` برای همین commit در run `44295856332` موفق است؛ job `134772566597` با نتیجه `success` تکمیل شد.
- [x] فهرست فایل‌های PR نشان می‌دهد بخش مشتقات شامل محاسبات BigInt، تست‌های Node، طرح‌ها/قراردادهای طراحی، SQLهای صرفاً draft و تست‌های PostgreSQL است.
- [!] وضعیت PR از GitHub در این بررسی `mergeable=false` گزارش شد؛ علت آن هنوز بررسی نشده است. PR را Merge یا از Draft خارج نکن.
- [!] سبز بودن این check، تأیید کامل سامانه معاملات مشتقه یا مجوز Production نیست؛ هیچ migration، RPC، schema، grant، cron یا معامله مشتقه‌ای در Production اعمال نشده است.
- [ ] ادامه: بازبینی مستقل چرخه کامل مشتقات (ثبت/رزرو/مارک‌پرایس/لیکوییدیشن/کاهش فقط/تسویه/دفترکل/هم‌زمانی و RLS) در دیتابیس ایزوله و بررسی علت `mergeable=false` پیش از هر تصمیم درباره PR.


## بازبینی مستقل PR مشتقات و وضعیت همگرایی — ۱۸ نوامبر ۲۰۲۶
- [x] بررسی مستقیم GitHub Actions run `44295856332` برای HEAD برابر `66f7175bf1b923c3d5aaa86512f5372f3c8394eb`: نتیجه نهایی `success`.
- [x] لاگ Node TAP همین run: `63 tests`، `63 pass`، `0 fail`، `0 skipped`. Job همچنین تست‌های PostgreSQL 17 و fixtureهای schema/ledger را اجرا کرد؛ پیام‌های ERROR در تست‌های منفی عمدی و assertion‌شده بودند.
- [x] مقایسهٔ دقیق HEAD این PR با main فعلی (پس از ثبت وضعیت‌های اخیر): `diverged`، شاخهٔ PR دارای ۱۸۱ commit جلوتر و ۱۱ commit عقب‌تر از main است؛ merge base برابر `9d115c0320786e5c430865605a7775a188cb2518`.
- [!] این فاصلهٔ ۱۱ commitی و divergence، نیازمند بررسی/reconcile کنترل‌شده است. PR را merge یا rebase خودکار نکن؛ پیش از هر همگرایی باید تغییرات main در ۱۱ commit اخیر و تداخل احتمالی بررسی و یک مسیر ایمن انتخاب شود.
- [!] پاسخ قبلی API با `mergeable=false` قطعی نبود؛ فیلد بعدی API `mergeable=null` و `mergeable_state=unknown` برگرداند. بنابراین conflict قطعی اعلام نمی‌کنیم؛ علت دقیق هنوز نامشخص است.
- [x] بازبینی طرح مشتقات نشان داد خود طرح صریحاً Phase 0 تطبیق کامل Migrationهای Production، Phase 1 تست‌های کامل وام/بهره/funding/liquidation و raceها، Phase 2 RPCها/RLS و worker، Phase 3 UI، و Phase 4 تست دستگاه را ناتمام می‌داند. این PR صرفاً foundation است، نه موتور معاملات کامل.
- [x] محدودیت ایمنی در طرح حفظ شده: منبع قیمت فعلی بازار برای لیکوییدیشن کافی نیست؛ تا تکمیل oracle چندمنبعی، ریسک‌تیِر، مدل insurance/deficit و تست هم‌زمانی، لیکوییدیشن خودکار نباید فعال شود.
- [x] هیچ merge/rebase، تغییر Supabase Production، migration، RPC، cron، سفارش یا تغییر موجودی انجام نشد.
- [ ] گام بعد: بررسی اختلاف ۱۱ commit main نسبت به شاخه PR و تعیین دقیق تداخل‌ها، بدون تغییر شاخه تا مشخص شدن طرح همگرایی؛ سپس تکمیل تست‌های SQL برای reservation/cancel/partial-fill/reduce-only concurrency و ادامهٔ backend فقط در branch.

## بررسی دقیق اختلاف PR شماره ۱۲ با main — ۱۸ نوامبر ۲۰۲۶
- [x] وضعیت زنده هنگام بررسی: main برابر `5bc1996a1412a138c42887dff68207d76436d0a3` و head شاخه PR برابر `66f7175bf1b923c3d5aaa86512f5372f3c8394eb`.
- [x] مقایسهٔ `66f7175...main` نشان داد main نسبت به شاخه PR دارای ۱۲ commit و شاخه PR نسبت به main دارای ۱۸۱ commit است؛ وضعیت `diverged` و merge base برابر `1514668bc76dc697fa26b22edb2ebfd80b2199b8` است. عدد قبلی ۱۱ عقب‌ماندگی با وضعیت تازه جایگزین شد.
- [x] ۱۲ commit موجود فقط در main:
  - `413268e` — ثبت ممیزی قابلیت اطمینان worker همگام‌سازی.
  - `dd4651a`, `f239d22`, `24017b3`, `c3934d8`, `f7aa8bd`, `d30b5bd` — پیاده‌سازی و تست اصلاح «ارزهای من»، موجودی مرجع USDT، جفت‌های USDT/IRT و cache آفلاین v56.
  - `532187e` — ثبت وضعیت اصلاح بازار.
  - `20f0286` — ثبت تمرین بازیابی دیتابیس ایزوله.
  - `5fff07c` — ثبت ساخت موفق APK آزمایشی.
  - `9d115c0` و `5bc1996` — ثبت وضعیت و اعتبارسنجی PR12.
- [x] فایل‌های تغییرکرده در سمت main: `IMPLEMENTATION_STATUS.md`, `docs/DATABASE_BACKUP_RECOVERY.md`, `index.html`, `src/market-holdings.js`, `sw.js`, `tests/market-holdings.test.js`, `tests/service-worker.test.js`.
- [x] اشتراک فهرست فایل‌های تغییرکردهٔ دو شاخه فقط `IMPLEMENTATION_STATUS.md` است. main فایل‌های بازار/دارایی و Service Worker را اضافه کرده که در head فعلی PR وجود ندارند؛ وارد کردن main این اصلاحات را به شاخه مشتقات می‌آورد.
- [!] هر دو شاخه `IMPLEMENTATION_STATUS.md` را از نقطهٔ مشترک به‌صورت append توسعه داده‌اند؛ بنابراین ادغام مستقیم احتمالاً در همین فایل تعارض متنی می‌سازد. این تعارض را نباید با حذف یا جایگزینی تاریخچهٔ وضعیت حل کرد؛ بخش‌های هر دو شاخه باید حفظ و به‌ترتیب زمانی ترکیب شوند.
- [x] فایل‌های اصلی مشتقات، SQL draftها و تست‌های مشتقه در فهرست تغییرات main نیستند؛ در مقایسهٔ فایل‌ها تعارض مستقیم دیگری مشاهده نشد. این نتیجه صرفاً تحلیل تغییرات فایل است و جایگزین اجرای merge آزمایشی و CI نیست.
- [!] مسیر پیشنهادی در صورت اجازهٔ کاربر: merge commit از main به شاخه feature (نه rebase و نه force-push)، حل دستی تعارض فقط در `IMPLEMENTATION_STATUS.md` با حفظ هر دو مجموعهٔ یادداشت، سپس اجرای کامل workflow و بازبینی diff نهایی. تا پیش از تأیید صریح، شاخه PR تغییر نمی‌کند.
- [x] در این بررسی هیچ merge، rebase، force-push، تغییر PR، Supabase یا Production انجام نشد.

### گام بعدی
1. پس از تأیید کاربر، همگام‌سازی کنترل‌شدهٔ main به شاخه PR12 با merge commit و حل تعارض مستندات.
2. اجرای کامل CI روی head همگام‌شده و بررسی دوبارهٔ mergeability؛ PR همچنان Draft بماند.
3. سپس ادامهٔ تکمیل تست‌های SQL مشتقات و کارهای باقی‌ماندهٔ backend؛ هیچ DDL یا RPC در Production اجرا نشود.



## همگام‌سازی کنترل‌شدهٔ main به شاخهٔ مشتقات — ۱۸ نوامبر ۲۰۲۶
- [x] وضعیت قبل از نوشتن دوباره بررسی شد: main `88cf562ea4bdd1bccece5c980b45b0883a295dd3` و head شاخه `66f7175bf1b923c3d5aaa86512f5372f3c8394eb`؛ PR #12 باز و Draft بود.
- [x] مقایسهٔ سه‌طرفهٔ Git tree در سطح فایل انجام شد. فایل مشترک واقعاً تغییرکرده در هر دو شاخه فقط `IMPLEMENTATION_STATUS.md` است؛ تفاوت پوشه‌های `docs`، `src` و `tests` ناشی از فایل‌های مستقل دو شاخه بود.
- [x] شش فایل تغییرکرده فقط در main به شاخه منتقل شدند: `docs/DATABASE_BACKUP_RECOVERY.md`, `index.html`, `src/market-holdings.js`, `sw.js`, `tests/market-holdings.test.js`, `tests/service-worker.test.js`.
- [x] فایل وضعیت با حفظ تاریخچهٔ مشترک، ادامهٔ مشتقات در شاخه و گزارش‌های main پس از نقطهٔ انشعاب ترکیب شد.
- [x] شاخه با merge commit دووالدی (ابتدا head شاخه، سپس main) همگام شد؛ rebase و force-push انجام نشد.
- [!] این همگام‌سازی فقط روی feature branch است؛ PR merge، انتشار، Supabase write و Production migration انجام نشده است.
- [ ] اجرای CI روی merge commit و بازبینی نهایی diff لازم است.


## اعتبارسنجی پس از همگام‌سازی main و تکمیل لایهٔ Oracle — ۱۸ نوامبر ۲۰۲۶
- [x] اجرای push روی commit `8ce5751790cc6fc5a524e50c79360f68777cb5d9`: run `44302116508`، workflow `Exact decimal tests`، نتیجهٔ نهایی `success`.
- [x] اجرای مستقل رویداد `pull_request` برای همان HEAD: run `44302126025`، نتیجهٔ نهایی `success`.
- [x] job `exact-decimal` در هر دو اجرا موفق شد؛ ۳۹ مرحلهٔ اصلی job push شامل Node/browser، PostgreSQL 17، atomic migration rehearsal، Spot advanced-order lifecycle/races، Futures schema/RLS/ledger، oracle storage/RPC، دو نشست هم‌زمان، Reduce-only fill/reconciliation و رد ledger نامتوازن همگی موفق شدند.
- [x] اجرای runها روی شاخهٔ `feat/demo-derivatives-trading` و commit همگام‌سازی‌شده بود؛ main تغییر نکرد.
- [!] سبز بودن CI صرفاً اعتبارسنجی fixtureها و SQL draftها در PostgreSQL دورریختنی است؛ هیچ migration، RPC، policy، cron، worker یا داده‌ای در Supabase Production اعمال نشده و هیچ مجوز فعال‌سازی معاملات مشتقه ایجاد نمی‌کند.
- [x] PR #12 همچنان Open و Draft و merged=false است؛ PR از Draft خارج یا merge نشد.
- [ ] گام بعدی فنی: بازبینی مستقل قراردادهای Oracle برای provider-family/constituent overlap و کامل‌کردن تست‌های crash/retry/concurrency بین start-cycle، provider-result و publish-snapshot؛ سپس ریسک‌مدل maintenance margin، liquidation و insurance در fixture ایزوله.
- [ ] گام بعدی محصول: UI مشتقات، live order entry و auto-liquidation تا تکمیل risk-engine، تست‌های lifecycle/race و تأییدهای جداگانه غیرفعال بمانند.

- [x] Post-documentation CI run `44303387834` on commit `119a527e49defa0ec8dfc50ac118d334f83d8536`: completed `success`, all 43 steps passed, including real two-session Stop-Limit child execution/cancellation races and derivative schema/RLS/ledger immutability checks.
- [x] Post-documentation CI run `44303393491` on branch HEAD `52709186288209630864c3e9bf1913bcbbb9be29`: completed `success`, all 43 steps passed, including exact-decimal rollout rehearsal, TP-SL concurrent execution/cancellation, and Futures price-oracle idempotency/publication races.
- [x] Both documentation-triggered CI runs completed successfully; no failed steps.
## تکمیل Fault Injection و نخستین لایهٔ Maintenance Margin — ۱۸ نوامبر ۲۰۲۶

- [x] CI run `44304369272` روی commit `6980ec6eba38e73779c024e58bfbdee96e95d0e2` با نتیجهٔ `success`؛ تست‌های دو نشست Oracle و fault-injection برای rollback پیش از commit و retry موفق provider-result و snapshot گذشتند.
- [x] در `supabase/tests/demo_derivatives_price_oracle_concurrency.sh` دو شکست کنترل‌شده قبل از commit اضافه شد؛ در هر دو حالت نبود اثر نیمه‌کاره پس از rollback و تکمیل دقیقاً یک‌باره با retry بررسی می‌شود.
- [x] در `src/derivatives-math.js` توابع مستقل `validateMaintenanceTiers`, `maintenanceTierForNotional` و `maintenanceMarginFromTiers` اضافه شدند؛ مدل محاسبه `notional × maintenanceRate − cumulative maintenanceAmount` است.
- [x] اعتبارسنجی پلکان شامل سقف‌های افزایشی و tier نهایی نامحدود، نرخ غیرکاهشی، مقدار تعدیل غیرمنفی، پیوستگی در مرز tierها و حداکثر اهرم غیر افزایشی است.
- [x] تست‌های Node برای انتخاب tier، مرزها، دقت ۱۸ رقم اعشار، پیوستگی و ورودی‌های نامعتبر اضافه شدند.
- [x] پس از اصلاح دو انتظار نادرست تست (precision محدود به ۱۸ رقم و assertion غیرقابل‌دستیابی)، CI نهایی روی commit `049246e84cd3927e31e8f50fda35b56a423f79b7` موفق شد: run `44305188672` (push) و `44305201068` (pull_request)، هر دو ۴۳ مرحله موفق و بدون شکست.
- [!] اعداد tier فقط fixture آزمایشی‌اند؛ هیچ schedule واقعی بازار یا leverage cap عملیاتی تصویب نشده است. این helper هنوز به SQL، ریسک‌موتور cross/isolated یا مسیر سفارش وصل نشده است.
- [!] Oracle provider-family/constituent independence هنوز نیازمند بررسی است؛ سه venue لزوماً سه feed مستقل نیستند.
- [ ] گام بعد: اتصال کنترل‌شدهٔ schedule نسخه‌دار و server-owned به محاسبهٔ maintenance در risk snapshotهای isolated/cross، همراه تست‌های مرز و stale price در Node و PostgreSQL دورریختنی.
- [ ] سپس طراحی/تست فرمول liquidation sizing، partial/full reduction، liquidation fee، insurance fund و deficit accounting؛ تا آن زمان auto-liquidation و معاملات مشتقه در UI غیرفعال بمانند.
- [x] PR #12 همچنان Open و Draft و merged=false است؛ هیچ merge انجام نشد.
- [x] هیچ Supabase Production migration/RPC/schema/policy/cron/worker یا تغییر داده‌ای انجام نشد.
## اتصال پلکان به برآورد ریسک موقعیت ایزوله — ۱۸ نوامبر ۲۰۲۶

- [x] `riskSnapshot()` اکنون در صورت دریافت schedule پلکانی، Maintenance Margin را از notional و tier مربوط محاسبه می‌کند و tier index را گزارش می‌دهد؛ حالت قدیمی نرخ ثابت برای تست‌ها/سازگاری باقی مانده است.
- [x] برآورد قیمت لیکوییدیشن ایزولهٔ tiered اضافه شد؛ حل معادله به‌صورت piecewise انجام می‌شود و tier بر اساس notional قیمت کاندید انتخاب می‌شود، نه tier قیمت ورود. برای محافظه‌کاری، قیمت Long رو به بالا و Short رو به پایین در مقیاس ۱۸ رقم گرد می‌شود.
- [x] تست‌های Long/Short عبورکننده از مرز tier و اتصال به risk snapshot اضافه شدند.
- [x] CI روی commit `760c240ea5bb9bff5234e9fedf54dfb873aac23d` سبز شد: run `44305853609` (push) و `44305863707` (pull_request)، هر دو ۴۳ مرحله موفق.
- [!] این محاسبه صرفاً preview ریاضی برای موقعیت ایزوله است؛ schedule هنوز از منبع server-owned/versioned در دیتابیس بارگذاری نمی‌شود و به RPC اجرا یا liquidation worker وصل نیست.
- [ ] گام بعد: تعریف schema draft برای maintenance-tier versioning و resolver امن server-side؛ سپس اتصال همان schedule به cross-account risk aggregation و تست SQL مرز tier/تغییر نسخه/stale oracle.
- [ ] پس از آن طراحی و تست partial/full liquidation accounting، fees، insurance fund و deficit handling در PostgreSQL ایزوله؛ auto-liquidation همچنان غیرفعال.
- [x] هیچ Supabase Production تغییر نکرده و PR #12 همچنان Draft و ادغام‌نشده است.
## اتصال scheduleهای Maintenance Margin به ریسک Cross و Available Margin — ۱۸ نوامبر ۲۰۲۶

- [x] `crossMarginRiskSnapshot()` اکنون schedule پلکانی را به تفکیک نماد می‌پذیرد و Maintenance Margin هر موقعیت را با tier متناسب با mark notional جمع می‌کند.
- [x] `futuresAvailableMarginSnapshot()` نیز در صورت ارائهٔ schedule per-symbol از tier و cumulative deduction استفاده می‌کند؛ نبود schedule برای نماد موقعیت، خطای صریح است و fallback خاموش ندارد.
- [x] محاسبهٔ tiered maintenance با گردکردن محافظه‌کارانهٔ حاصل‌ضرب مثبت به بالا در ۱۸ رقم اعشار انجام می‌شود؛ continuity نیز بر همان قاعده اعتبارسنجی می‌شود.
- [x] تست‌های Cross برای چند نماد، schedule گمشده، Available Margin و maintenance tier هر نماد اضافه شدند.
- [x] CI روی HEAD `4f0204423006a5da7245fcbebe640d05f6dd5e1d` سبز شد: run `44306457201` (push) و `44306468761` (pull_request)، هر دو ۴۳ مرحله موفق.
- [!] scheduleها هنوز آرگومان ورودی helperهای خالص هستند؛ resolver نسخه‌دار server-owned، schema SQL، کنترل مجوز و ثبت audit هنوز ساخته نشده‌اند. هیچ کلاینتی نباید این schedule را منبع حقیقت تعیین کند.
- [ ] گام بعد: ساخت draft دیتابیس برای schedule نسخه‌دار per-symbol و tierها، اعتبارسنجی constraint/trigger در PostgreSQL و resolver فقط server-side؛ سپس تست تغییر نسخه و مرزهای tier در SQL.
- [ ] پس از resolver، تکمیل liquidation accounting، liquidation fee، insurance/deficit و raceهای اجرا در fixture ایزوله. هیچ auto-liquidation یا UI activation.
## ساخت و اعتبارسنجی مخزن نسخه‌دار Maintenance Tier در PostgreSQL ایزوله — ۱۸ نوامبر ۲۰۲۶

- [x] Draft خصوصی `supabase/drafts/2026-11-18_demo_derivatives_maintenance_tiers.sql` ساخته شد؛ شامل schedule per-symbol با version/status، tier rows، فعال‌سازی اتمیک نسخه، resolver و دسترسی service_role-only.
- [x] validator دیتابیس پیوستگی فرمول، tier_index پیوسته از ۱، سقف‌های افزایشی، tier نهایی نامحدود، نرخ غیرکاهشی، deduction غیرمنفی، max leverage غیر افزایشی و گردکردن محافظه‌کارانهٔ ۱۸ رقم اعشار را بررسی می‌کند.
- [x] schedule و tierهای فعال/بازنشسته immutable هستند؛ نسخهٔ جدید ابتدا draft ساخته و فقط پس از اعتبارسنجی فعال می‌شود؛ نسخهٔ قدیمی در همان تراکنش retire می‌شود و downgrade نسخه رد می‌شود.
- [x] resolver فقط از طریق تابع private قابل فراخوانی service_role است؛ جدول‌ها برای anon/authenticated/service_role دسترسی مستقیم ندارند.
- [x] تست `supabase/tests/demo_derivatives_maintenance_tiers.sql` فعال‌سازی، انتخاب tier در مرز، رد schedule ناپیوسته، تعویض نسخه، immutability، grants و resolver service_role را پوشش می‌دهد.
- [x] workflow کامل PostgreSQL 17 برای draft و تست جدید اجرا شد: run `44307356561` (push) و run `44307363912` (pull_request)، هر دو `success` با ۴۵ مرحله موفق.
- [!] این SQL فقط در PostgreSQL دورریختنی CI اجرا شده؛ هیچ‌یک از scheduleها در Supabase Production ساخته یا فعال نشده‌اند. هنوز RPCهای سفارش/لیکوییدیشن از resolver استفاده نمی‌کنند.
- [ ] گام بعد: تست دو نشست برای تعویض هم‌زمان schedule و resolver، و بررسی snapshot/risk calculation در برابر تغییر نسخه؛ سپس اتصال resolver به backendهای محاسبه ریسک بدون اعتماد به ورودی مرورگر.
- [ ] پس از آن، طراحی دفترکل liquidation fee، insurance fund و deficit/ADL policy، و تست اتمیک partial/full liquidation در fixture ایزوله. Auto-liquidation غیرفعال می‌ماند.
## آزمون هم‌زمانی تعویض Maintenance Tier و resolver — ۱۸ نوامبر ۲۰۲۶

- [x] فعال‌سازی schedule برای هر نماد با advisory transaction lock سریال شد؛ نسخهٔ schedule پس از گرفتن قفل دوباره خوانده می‌شود تا race نسخهٔ قدیمی/جدید باعث downgrade نشود.
- [x] retry فعال‌سازی همان schedule در صورت active بودن، idempotent است و همان نسخه را برمی‌گرداند.
- [x] اسکریپت دو نشست `supabase/tests/demo_derivatives_maintenance_tiers_concurrency.sh` اضافه شد: یک resolver نسخهٔ ۲ را در تراکنش باز pin می‌کند، فعال‌سازی نسخهٔ ۳ تا پایان snapshot منتظر می‌ماند، سپس دو retry هم‌زمان فعال‌سازی نسخهٔ ۴ به یک نتیجه converged می‌شوند.
- [x] تست هم‌زمانی و کل workflow روی commit `3595a3ea535fcc477b8f3a0ce1f21e176aebb286` موفق شد: run `44308127930` (push) و run `44308135188` (pull_request)، هر دو ۴۶ مرحله موفق و بدون شکست.
- [!] این رفتار فقط در PostgreSQL دورریختنی CI اثبات شده؛ هنوز risk RPCهای واقعی از resolver استفاده نمی‌کنند و scheduleها در Production وجود ندارند.
- [ ] گام بعد: اتصال resolver به محاسبهٔ risk snapshot در یک تراکنش واحد و pin کردن `schedule_id/version` برای کل حساب/نماد؛ تست دو نشست برای اینکه هیچ snapshot واحدی tierهای دو نسخه را مخلوط نکند.
- [ ] سپس طراحی دفترکل liquidation: partial/full sizing، close fee، liquidation fee، انتقال کسری به insurance/clearing، deficit/ADL policy و idempotent worker. Auto-liquidation همچنان خاموش.
## تکمیل مرز دسترسی private schema و اجرای مجدد CI — ۱۸ نوامبر ۲۰۲۶

- [x] draft Maintenance Tier اکنون دسترسی schema `private` را از `PUBLIC`, `anon` و `authenticated` صریحاً revoke می‌کند و فقط `service_role` را برای اجرای resolver/activation مجاز می‌سازد.
- [x] تست PostgreSQL بررسی می‌کند که نقش‌های client به schema دسترسی ندارند، service_role فقط به توابع مجاز دسترسی دارد و هیچ دسترسی مستقیم به جدول‌های schedule/tier ندارد.
- [x] CI کامل پس از این سخت‌سازی روی HEAD `4c04ffd4024f671a51ec1a6ca5240df2953aec4a` موفق شد: run `44308662580` (push) و `44308674101` (pull_request)، هر دو ۴۶ مرحله موفق.
- [!] این تغییرات همچنان draft و CI-only هستند؛ Production Supabase دست‌نخورده است و هیچ worker/سفارش/لیکوییدیشنی از resolver استفاده نمی‌کند.
- [ ] گام بعد: ساخت risk snapshot RPC server-side که در یک تراکنش، schedule_id/version هر نماد را pin کند و همهٔ positionهای همان حساب را با همان نسخه محاسبه کند؛ تست race در زمان تعویض schedule.
- [ ] سپس مدل و دفترکل liquidation/insurance/deficit را طراحی و در PostgreSQL دورریختنی آزمایش کن؛ auto-liquidation و UI مشتقات غیرفعال بمانند.
## پیاده‌سازی account maintenance snapshot با Oracle تازه و schedule نسخه‌پین‌شده — ۱۸ نوامبر ۲۰۲۶

- [x] تابع خصوصی `private.demo_derivative_account_maintenance_snapshot(uuid)` اضافه شد؛ فقط service_role می‌تواند آن را اجرا کند.
- [x] تابع ابتدا account row را `FOR SHARE` قفل می‌کند، سپس positionهای باز را با ترتیب پایدار می‌خواند و scheduleهای فعال را `FOR SHARE` نگه می‌دارد؛ تغییر وضعیت سفارش/موقعیت و تعویض tier در میانهٔ یک فراخوانی نمی‌تواند محاسبه را مخلوط کند.
- [x] برای هر موقعیت، جدیدترین Oracle snapshot صرف‌نظر از status انتخاب می‌شود؛ فقط snapshot سالم و هنوز معتبر پذیرفته می‌شود. snapshot جدیدتر stale/deviation/insufficient-quorum باعث رد کل محاسبه می‌شود و به قیمت سالم قدیمی fallback نمی‌کند.
- [x] خروجی شامل mark price و شناسه/زمان snapshot، notional، PnL، maintenance margin، tier index، schedule_id/version، leverage cap و ledger-derived Futures cash است.
- [x] تست PostgreSQL حساب‌های مجزا، موقعیت isolated و cross، چند نماد، محاسبات tier/version، cash projection و رد snapshot stale جدیدتر را پوشش می‌دهد.
- [x] CI روی commit `70a637270cdd7f9ee115d6b08de3ad0c584d7280` سبز شد: run `44310385007` (push، ۴۶ مرحله) و `44310397178` (pull_request، ۴۸ مرحله)، بدون شکست.
- [!] این خروجی هنوز فقط position maintenance snapshot است؛ close-fee reserve، unposted liabilities، account equity/margin ratio و available margin نهایی در SQL RPC تجمیع نشده‌اند. هیچ order RPC یا liquidation worker آن را مصرف نمی‌کند.
- [ ] گام بعد: افزودن fee schedule معتبر و محاسبهٔ close-fee reserve، liabilities بدون دوباره‌شماری، account equity، maintenance buffer و margin ratio در همان تراکنش؛ تست چندموقعیتی و stale-price fail-closed.
- [ ] سپس طراحی liquidation/insurance/deficit accounting و تست‌های اتمیک partial/full liquidation و race با fill/cancel. Auto-liquidation و UI مشتقات خاموش می‌مانند.


## تکمیل تجمیع ریسک حساب مشتقات و طراحی دروازه لیکوییدیشن — ۱۸ نوامبر ۲۰۲۶

- [x] Draft خصوصی و نسخه‌دار کارمزد Futures برای Maker/Taker اضافه شد؛ نسخه‌های فعال/بازنشسته immutable هستند، فعال‌سازی نسخه به‌صورت اتمیک و صعودی انجام می‌شود و resolver فقط برای `service_role` قابل اجراست.
- [x] Funding accrualها immutable شدند؛ تسویه فقط با تراکنش دفترکل Funding متناظر و حرکت دقیق USDT در `futures_cash` مجاز است. رویداد settled از liabilities محاسبه ریسک کنار گذاشته می‌شود تا دوباره‌شماری رخ ندهد.
- [x] تابع خصوصی `private.demo_derivative_account_risk_snapshot(uuid)` اضافه شد: cash دفترکل‌محور، PnL موقعیت‌های Cross، Funding پرداختنی/دریافتنی تسویه‌نشده، ذخیره کارمزد بستن، Equity، Maintenance Margin و Margin Ratio را در یک snapshot تجمیع می‌کند. برای هر موقعیت نیز snapshot جداگانه شامل tier/schedule version، fee version، isolated equity و Funding ارائه می‌شود.
- [x] تست‌های PostgreSQL برای Funding تسویه‌شده/نشده، immutability، جلوگیری از تسویه بدون دفترکل متناظر، تجمیع Isolated/Cross، نسخه‌بندی کارمزد و رد Oracle جدیدتر stale اضافه شدند.
- [x] دو انتظار تستی اصلاح شدند: Margin Ratio با اجزای همان snapshot مقایسه می‌شود؛ cash پس از دو fill با احتساب Funding تسویه‌شده برابر 31.95 USDT است (10 اولیه - 5 Funding + 20 آزادسازی وثیقه + 7 سود تحقق‌یافته - 0.05 کارمزد).
- [x] CI نهایی روی commit `bec86d6338b8d188a8fb2406d903e19c013bda90` موفق شد: run پوش `44326154079` و run رویداد pull_request برابر `44326169424`؛ هر دو ۵۱ از ۵۱ مرحله موفق، بدون شکست.
- [!] تمام SQLهای جدید همچنان draft هستند و فقط در PostgreSQL 17 دورریختنی CI اجرا شده‌اند. هیچ DDL/RPC/policy/cron یا داده‌ای در Supabase Production تغییر نکرده است.
- [x] سند طراحی `docs/superpowers/specs/2026-11-18-demo-derivatives-liquidation-accounting.md` ساخته شد؛ مرز Isolated/Cross، partial/full reduction، execution price/slippage، کارمزدها، insurance/deficit، idempotency و ماتریس تست را تعریف می‌کند.
- [!] اجرای لیکوییدیشن هنوز مجاز/پیاده‌سازی نشده است. نرخ liquidation surcharge، سقف slippage، safety buffer، اولویت موقعیت‌های Cross، تأمین/شارژ insurance fund و سیاست deficit/recovery/ADL هنوز تصمیم‌گیری نشده‌اند.
- [x] PR شماره ۱۲ همچنان Open و Draft و ادغام‌نشده است؛ شاخه feature نسبت به main همگام است و ۲۳۳ commit جلوتر است.
- [x] هیچ Supabase Production write، merge/rebase، فعال‌سازی UI مشتقات یا auto-liquidation انجام نشد.

### گام بعد
1. تعیین و ثبت سیاست‌های باز در سند liquidation، بدون استفاده از اعداد fixture به‌عنوان نرخ عملیاتی.
2. ساخت دفترکل مستقل و immutable برای insurance fund و deficit journal در PostgreSQL دورریختنی؛ سپس آزمون کامل پوشش کامل/جزئی/صفر insurance.
3. پس از تثبیت accounting، پیاده‌سازی و آزمون isolated liquidation و سپس Cross account liquidation، همراه race با fill/cancel/reduce-only و fault-injection.
4. تا عبور تمام gates، UI و auto-liquidation خاموش بمانند و Production دست‌نخورده بماند.


## تکمیل طراحی مرز دفترکل بیمه و دفتر ثبت کسری — ۱۸ نوامبر ۲۰۲۶

- [x] وضعیت زنده PR شماره ۱۲ بررسی شد: Open، Draft، ادغام‌نشده، بدون تعارض؛ HEAD شاخه `feat/demo-derivatives-trading` برابر `7f093b089dd6878904523f668458c84d86e1a61a` بود.
- [x] ساختار واقعی دفترکل مشتقات بررسی شد: جدول‌های user ledger به `auth.users` وابسته‌اند و `system_clearing` فقط bucket ترازکننده در دفترکل کاربر است؛ بنابراین برای صندوق بیمه نباید user ساختگی یا موجودی منفی کاربر ایجاد شود.
- [x] سند طراحی مستقل `docs/superpowers/specs/2026-11-18-demo-derivatives-insurance-deficit-ledger.md` اضافه شد؛ دفترکل پلتفرمی جداگانه، ثبت append-only کسری، تراز بدهکار/بستانکار، محاسبه موجودی از entries، پیوند event-based بین دو دفترکل، idempotency و ماتریس تست را مشخص می‌کند.
- [!] این مرحله فقط طراحی است؛ هنوز SQL دفترکل بیمه/کسری، RPC، migration، پرداخت بیمه یا لیکوییدیشن ساخته/اجرا نشده است.
- [!] سیاست seed/replenishment و سقف پرداخت بیمه، بازیابی کسری، کارمزد لیکوییدیشن، slippage، buffer و اولویت Cross هنوز تعیین نشده‌اند.
- [ ] گام بعد: ساخت schema خصوصی دفترکل پلتفرمی و deficit journal به‌همراه invariant tests در PostgreSQL 17 دورریختنی CI؛ تا تصویب سیاست‌ها هیچ payout/recovery RPC یا liquidation worker ساخته/فعال نشود.
- [x] هیچ تغییر Supabase Production، merge/rebase یا فعال‌سازی UI و auto-liquidation انجام نشد.


## ساخت draft دفترکل مستقل بیمه و ثبت کسری مشتقات — ۱۸ نوامبر ۲۰۲۶

- [x] پیش از ادامه، وضعیت واقعی PR و شاخه‌ها دوباره خوانده شد: PR #12 باز و Draft است؛ HEAD پیش از این مرحله `78022ed7078a82ef03d29e4f71d7f0808e6f8065` بود؛ شاخه مشتقات ۲۴۰ commit جلوتر و صفر commit عقب‌تر از `main` قرار داشت. بنابراین همگام‌سازی main لازم نبود و انجام نشد.
- [x] آخرین CI پیش از تغییرات، run `44328614153` روی HEAD قبلی بود و نتیجه `success` داشت.
- [x] draft مستقل `supabase/drafts/2026-11-18_demo_derivatives_insurance_deficit_ledger.sql` اضافه شد: chart حساب پلتفرمی چهارحسابی، دفترکل دوطرفه USDT، transaction idempotency/payload hash، append-only و immutable، balance مشتق‌شده از entries، قفل ردیف cash برای سریال‌سازی payoutها و رد موجودی منفی.
- [x] deficit journal مستقل و بدون FK به `auth.users` اضافه شد؛ رویدادهای opening، insurance application و recovery با تطبیق مبلغ/نوع تراکنش پلتفرمی و کنترل over-recovery زیر advisory transaction lock ثبت می‌شوند. بیمه به‌اشتباه recovery شمرده نمی‌شود.
- [x] viewهای خصوصی فقط برای محاسبه balance صندوق و exposure باقی‌مانده کسری از رویدادهای immutable ساخته شدند؛ هیچ balance قابل‌نوشتن یا user ساختگی اضافه نشد.
- [x] تست `supabase/tests/demo_derivatives_insurance_deficit_ledger.sql` اضافه شد: seed، پوشش کامل، پوشش جزئی، پوشش صفر، recovery، رد overdraw، رد posting نامتوازن، جلوگیری از over-recovery، immutability، idempotency uniqueness و عدم دسترسی client/service_role به جداول private.
- [x] workflow `.github/workflows/exact-decimal-tests.yml` به اجرای draft و تست جدید در همان PostgreSQL 17 دورریختنی derivatives CI مجهز شد.
- [!] CI این تغییرات هنوز باید از روی HEAD جدید اجرا و نتیجه واقعی آن بررسی شود؛ تا دریافت نتیجه، تست‌ها را موفق اعلام نکن.
- [!] این مرحله فقط schema/test draft است؛ هیچ posting RPC، seed/replenishment عملیاتی، payout worker، recovery worker، liquidation RPC یا UI ساخته/فعال نشده است. هیچ DDL/RPC/policy/cron یا داده‌ای در Supabase Production تغییر نکرد.
- [!] سیاست‌های seed، سقف payout، مجوز replenishment، recovery authority/cap و liquidation fee/slippage/buffer/Cross priority همچنان باز هستند و از fixtureها مقدار عملیاتی استنتاج نمی‌شود.
- [ ] گام بعد: بررسی CI و رفع هر خطای واقعی؛ سپس تست دو نشست برای payoutهای هم‌زمان و over-recovery هم‌زمان، و آزمون rollback اتمیک در صورت شکست بین دو دفترکل. تا تصویب سیاست‌ها هیچ RPC اجرایی یا auto-liquidation اضافه نشود.


## نتیجه CI دفترکل بیمه و تست‌های رقابت دو نشست — ۱۸ نوامبر ۲۰۲۶

- [x] اجرای CI شماره `44358314022` روی commit `dbf1ad53f4e455a7b5c337ccdef71148ed509d16` با نتیجه نهایی `success` تأیید شد؛ هر ۹۹ step موفق بودند، از جمله اعمال draft دفترکل بیمه/کسری در PostgreSQL 17 دورریختنی و تست یکپارچگی آن.
- [x] اسکریپت `supabase/tests/demo_derivatives_insurance_deficit_concurrency.sh` اضافه شد تا دو نشست مستقل را برای رقابت دو پرداخت ۴۰ USDT از مانده ۶۰ USDT و دو recovery هفت USDT در برابر کسری ده USDT اجرا کند؛ انتظار می‌رود دقیقاً یک درخواست در هر race موفق شود و تراکنش بازنده کاملاً rollback شود.
- [x] workflow به اجرای تست رقابت بیمه/کسری متصل شد.
- [!] CI commit جدید هنوز باید کامل شود؛ نتیجه تست race و syntax اسکریپت را موفق فرض نکن تا اجرای واقعی تأیید شود.
- [ ] پس از CI، در صورت مشاهده شکست، علت را رفع کن؛ سپس fault-injection برای rollback اتمیک بین ledger و deficit journal را به تست اضافه کن.
- [!] تمام تغییرات همچنان فقط در branch و PostgreSQL دورریختنی CI هستند. هیچ Supabase Production write، merge، فعال‌سازی UI یا liquidation انجام نشده است.


## نتیجهٔ CI رقابت بیمه/کسری و افزودن fault-injection — ۱۸ نوامبر ۲۰۲۶

- [x] CI شماره `44359636179` روی HEAD قبلی `787e52ab429020ea6530dd56c952553ae2f858c0` با نتیجه نهایی `success` تأیید شد؛ هر ۵۰ مرحله اصلی موفق بودند.
- [x] تست دو نشست واقعی برای پرداخت‌های رقابتی بیمه و بازیابی رقابتی کسری در PostgreSQL 17 دورریختنی موفق شد؛ دقیقاً یک درخواست در هر رقابت پذیرفته و درخواست بیش‌ازحد رد شد.
- [x] تست fault-injection به `supabase/tests/demo_derivatives_insurance_deficit_concurrency.sh` افزوده شد: پس از درج هر دو دفترکل، خطای عمدی پیش از COMMIT ایجاد می‌شود و باید هم دفترکل پلتفرم و هم deficit journal به‌طور کامل rollback شوند.
- [!] commit جدید این تست باید CI را دوباره بگذراند؛ نتیجهٔ fault-injection هنوز تأیید نشده است.
- [ ] پس از CI، گام بعدی تکمیل مستندات/تصمیم‌های سیاستی liquidation و مرور طرح اجرایی است؛ هیچ نرخ یا حد عملیاتی از اعداد تست استخراج نمی‌شود.
- [!] payout/recovery هنوز RPC اجرایی یا worker ندارند؛ تمام SQLها draft و تمام اجراها در PostgreSQL دورریختنی CI هستند. Supabase Production، merge و UI مشتقات تغییری نکرده‌اند.


## تأیید نهایی CI برای fault-injection دفترکل بیمه/کسری — ۱۸ نوامبر ۲۰۲۶

- [x] اجرای CI شماره `44360144878` روی commit وضعیت `16d33498985a11f4ad5c5ba7e3edb03595ca6006` با نتیجه نهایی `success` تأیید شد؛ job کامل شد و stepهای اصلی ۵۰/۵۰ موفق بودند.
- [x] از job log، پیام موفقیت تست race و پیام `Atomic rollback fault injection passed` به‌طور مستقیم پیدا شد.
- [x] fault-injection عمداً پس از نوشتن platform ledger و deficit event و پیش از COMMIT خطای division-by-zero ایجاد کرد؛ اسکریپت تأیید کرد هیچ transaction/entry پلتفرمی باقی نمانده و remaining deficit بدون تغییر روی ۵ باقی مانده است.
- [x] اجرای قبلی تست race روی commit تست `b16faed7db4d1aa0e8fb3e18b378b2a51931564c` نیز run شماره `44360105824` با نتیجه `success` داشت.
- [!] تست‌ها فقط در PostgreSQL 17 دورریختنی CI اجرا شده‌اند. این نتیجه به معنی تأیید سیاست اقتصادی یا مجوز استقرار نیست.
- [ ] گام بعدی: ثبت تصمیم‌های سیاستی پیش‌نیاز لیکوییدیشن (surcharge/cap، slippage، maintenance buffer، Cross priority، insurance funding و residual-deficit/recovery)؛ تا تعیین و تصویب این موارد هیچ liquidation execution RPC/worker ساخته یا فعال نشود.
- [!] PR #12 باز و Draft باقی مانده است؛ هیچ merge/rebase، Supabase Production write، UI مشتقات یا auto-liquidation انجام نشده است.


## آماده‌سازی کاربرگ تصمیم‌های سیاستی لیکوییدیشن — ۱۸ نوامبر ۲۰۲۶

- [x] کاربرگ `docs/superpowers/specs/2026-11-18-demo-derivatives-liquidation-policy-decisions.md` اضافه شد تا شش دسته تصمیم باز را به‌صورت صریح و قابل تصویب ثبت کند: surcharge/cap، execution slippage/evidence، maintenance buffer و partial/full، ترتیب Cross، seed/replenishment/payout بیمه، و deficit/recovery/ADL.
- [x] هیچ نرخ، سقف، buffer، اولویت یا مقدار seed حدس زده یا از fixtureهای تست استخراج نشد؛ تمام فیلدهای اقتصادی عمداً NOT DECIDED باقی مانده‌اند. ADL همچنان OFF است.
- [!] این سند فقط worksheet است و تأیید سیاست یا مجوز اجرا نیست. تا تصویب صریح همه موارد، liquidation RPC/worker/UI ساخته یا فعال نمی‌شود.
- [!] تست CI قبلی شماره `44360144878` موفق بود و fault-injection rollback نیز از job log تأیید شد؛ commit worksheet اکنون باید CI را بگذراند.
- [ ] گام بعد: بازبینی کاربرگ و ثبت تصمیم‌های صریح؛ سپس طراحی تست‌ها بر اساس مقادیر مصوب، بدون تغییر Supabase Production.
- [!] PR #12 باز و Draft؛ هیچ merge/rebase، Production write، UI مشتقات یا auto-liquidation انجام نشده است.


## قرارداد مدرک اجرای شبیه‌سازی‌شده برای لیکوییدیشن — ۱۸ نوامبر ۲۰۲۶

- [x] طراحی حسابداری لیکوییدیشن تکمیل شد: مدرک اجرای شبیه‌سازی‌شده باید رکورد immutable سمت سرور باشد و به نماد، سمت بستن، موقعیت/مقدار، snapshot اوراکل و نسخه سیاست متصل شود.
- [x] قرارداد ثبت hash پاسخ خام، timestamp منبع و دریافت، نسخه adapter/normalizer، سطوح دقیق order book، مصرف یک‌باره evidence و ثبت اتمیک همراه رویداد/دفترکل مشخص شد.
- [x] جهت شبیه‌سازی عمق مشخص شد: بستن Long از bidها و بستن Short از askها؛ قیمت اجرا با VWAP دقیق محاسبه می‌شود و جایگزینی قیمت Mark ممنوع است.
- [x] محاسبه لغزش به‌صورت جهت‌دار تعریف شد؛ Long در قیمت پایین‌تر از Mark و Short در قیمت بالاتر از Mark دچار لغزش نامطلوب است. مرجع نهایی، قرارداد مخرج و سقف عددی هنوز نیازمند تصویب سیاستی‌اند.
- [!] provider، تازگی مجاز داده، حداکثر لغزش و رفتار partial-fill در عمق ناکافی هنوز NOT DECIDED هستند؛ هیچ مقدار عملیاتی انتخاب نشده است.
- [!] RPC فعلی external reduction قیمت و fee را به‌عنوان ورودی سمت سرویس می‌گیرد؛ برای لیکوییدیشن نباید بدون مسیر اعتبارسنجی evidence-ID-based دوباره استفاده شود.
- [!] این تغییر فقط مستندات در شاخه است؛ هیچ SQL اجرایی، worker، UI یا Supabase Production تغییر نکرده است.
- [ ] گام بعد: تصویب provider/evidence source و سقف لغزش، سپس نوشتن تست‌های disposable PostgreSQL برای شواهد stale، عمق ناکافی، مصرف مجدد evidence، تطبیق سمت Long/Short و atomic rollback.


## تأیید CI پس از قرارداد مدرک اجرای لیکوییدیشن — ۱۸ نوامبر ۲۰۲۶

- [x] اجرای GitHub Actions شماره `44361544743` روی commit `efe928d38ce2174c237abe9fae8cfb0232e72d04` با نتیجه نهایی `success` تأیید شد.
- [x] هر ۱۰۱ step/job گزارش‌شده موفق بودند؛ از جمله اجرای تست‌های exact-decimal، integration مشتقات در PostgreSQL دورریختنی و تست‌های حسابداری بیمه/کسری.
- [x] لاگ مرحله رقابت دو نشست صریحاً پیام `Insurance/deficit two-session races passed` را ثبت کرد: یک payout مجاز و یک recovery مجاز برنده شدند و overdraw/over-recovery به‌صورت اتمیک رد شدند.
- [x] همان لاگ پیام `Atomic rollback fault injection passed` را ثبت کرد؛ پس از خطای عمدی پیش از commit، هر دو journal بدون تغییر باقی ماندند.
- [!] این CI فقط در محیط PostgreSQL دورریختنی اجرا شده و تأیید استقرار یا مجوز تغییر Supabase Production نیست.
- [!] تصمیم‌های سیاستی liquidation همچنان تصویب‌نشده‌اند؛ هیچ liquidation RPC/worker/UI یا Production change مجاز نشده است.
- [ ] گام بعد: تکمیل تصمیم‌های سیاستی و طراحی تست‌های مربوط به evidence/slippage پس از تعیین قرارداد provider و حدود مجاز؛ تا آن زمان اجرای لیکوییدیشن پیاده‌سازی نشود.


## قرارداد طراحی کارمزد و هزینه نگهداری مشتقات — ۱۸ نوامبر ۲۰۲۶

- [x] در سند طراحی، Maker/Taker بر اساس نقش واقعی هر fill تعریف شد؛ Limit قابل‌تطبیق فوری می‌تواند Taker باشد و نوع سفارش به‌تنهایی تعیین‌کننده نیست.
- [x] مرز محاسبه کارمزد روی notional واقعی fill، تفکیک fillهای جزئی، رزرو محافظه‌کارانه کارمزد و جلوگیری از ثبت دوباره کارمزد مشخص شد.
- [x] Funding فیوچرز از کارمزد معامله و بهره وام Margin Spot جدا شد؛ نیاز به نرخ علامت‌دار، پنجره تسویه، snapshot مرجع و idempotency ثبت شد.
- [x] بهره Margin Spot به‌عنوان بدهی مستقل در دارایی قرض‌گرفته‌شده تعریف شد؛ مبنای روزشمار، تناوب، ترکیب بهره و اولویت بازپرداخت هنوز تصمیم‌نشده‌اند.
- [!] هیچ نرخ Maker/Taker، funding، بهره، دوره تسویه، rounding، fee cap یا schedule-pinning تصویب نشده است؛ اعداد fixture تست سیاست عملیاتی نیستند.
- [!] این مرحله فقط سند طراحی را تغییر داده است؛ SQL/RPC/worker/UI و Supabase Production تغییر نکرده‌اند.
- [ ] گام بعد: تصویب قاعده زمان pin شدن نسخه کارمزد و سیاست funding؛ سپس طراحی تست‌های exact-decimal و idempotency بدون مقداردهی حدسی نرخ‌ها.


## قرارداد پیشنهادی علامت Funding و مرز تسویه — ۱۸ نوامبر ۲۰۲۶

- [x] قرارداد طراحی، جهت علامت پیشنهادی را مشخص کرد: نرخ مثبت یعنی Long پرداخت‌کننده و Short دریافت‌کننده؛ نرخ منفی جهت را معکوس می‌کند.
- [x] مرزهای لازم برای تعیین eligibility در لحظه تسویه، قفل‌گذاری در برابر تغییر هم‌زمان پوزیشن، کلید idempotency، و ثبت اتمیک رویداد و دفترکل مستند شد.
- [x] پیشنهاد pin شدن نسخه کارمزد در لحظه ایجاد هر fill واقعی ثبت شد؛ سفارش فقط تخمین می‌گیرد و هر fill نسخه نرخ خودش را ذخیره می‌کند. این پیشنهاد هنوز تصویب نشده است.
- [!] فاصله تسویه، منبع و سقف نرخ، مبنای notional، زمان eligibility، rounding و حساب clearing هنوز NOT DECIDED هستند؛ هیچ نرخ یا زمان‌بندی اجرایی تعیین نشد.
- [!] فقط اسناد branch تغییر کردند؛ SQL/RPC/worker/UI و Supabase Production دست‌نخورده‌اند.
- [ ] گام بعد: تأیید یا اصلاح قرارداد علامت و سیاست pin شدن fee schedule؛ سپس ساخت تست‌های exact-decimal، رقابت هم‌زمان با settlement و retry idempotency در PostgreSQL دورریختنی.


## ماتریس آزمون طراحی Funding — ۱۸ نوامبر ۲۰۲۶

- [x] ماتریس آزمون پیش از پیاده‌سازی ثبت شد: تقارن علامت نرخ، exact-decimal، snapshot pinning، مرز eligibility، رقابت هم‌زمان با کاهش/بستن پوزیشن، retry idempotency، rollback اتمیک، تطبیق حساب clearing، جداسازی نسخه سیاست و audit trail.
- [!] این مرحله فقط طراحی تست است؛ هیچ تست جدیدی نوشته یا اجرا نشده و هیچ CI موفقی برای آن ادعا نمی‌شود.
- [!] مقادیر fixture فقط مصنوعی خواهند بود؛ تا تصویب مبنای notional، زمان eligibility، rounding، مدل clearing و رفتار کسری موجودی، هیچ سیاست مالی عملیاتی تعیین نشده است.
- [!] فقط سند طراحی branch تغییر کرد؛ SQL/RPC/worker/UI و Supabase Production بدون تغییر باقی ماندند.
- [ ] گام بعد: گرفتن تأیید کاربر برای قرارداد علامت Funding و زمان pin شدن fee schedule؛ سپس نوشتن تست‌ها در PostgreSQL دورریختنی، نه Production.


## ماتریس طراحی آزمون بهره Margin و pin شدن کارمزد — ۱۸ نوامبر ۲۰۲۶

- [x] آزمون‌های طراحی بهره Margin Spot ثبت شد: جداسازی دارایی، مرز accrual، pin شدن اصل و نرخ، exact-decimal، منع compounding ضمنی، تخصیص بازپرداخت، رقابت هم‌زمان، idempotency، rollback و audit trail.
- [x] آزمون‌های طراحی کارمزد ثبت شد: تعیین schedule در مرز اجرای Fill، رقابت activation با Fill، partial fill، retry، نقش واقعی Maker/Taker، مبنای notional واقعی، تفکیک reserve از debit و جداسازی fee باز و بسته‌شدن.
- [!] هیچ SQL تست جدیدی نوشته یا اجرا نشد؛ این مرحله صرفاً تکمیل طرح آزمون است. هیچ ادعای CI موفق مطرح نیست.
- [!] نرخ بهره، APR، day-count، compounding، اولویت بازپرداخت، rounding، fee cap/rebate/tier و سیاست‌های مالی همچنان تصویب نشده‌اند.
- [!] هیچ migration/RPC/worker/UI یا تغییر Supabase Production انجام نشد.
- [ ] گام بعد: پس از تصویب قرارداد علامت Funding و زمان pin شدن fee schedule، پیاده‌سازی تست‌های disposable PostgreSQL آغاز شود؛ تصمیم‌های بهره Margin جداگانه اخذ شوند.


## ثبت تکمیل و تأیید CI دفترکل بیمه پلتفرمی و کسری — ۱۸ نوامبر ۲۰۲۶

- [x] پیش‌نویس schema دفترکل مستقل و خصوصی بیمه پلتفرمی و ژورنال append-only کسری در شاخه وجود دارد: `supabase/drafts/2026-11-18_demo_derivatives_insurance_deficit_ledger.sql`.
- [x] تست یکپارچه PostgreSQL دورریختنی در `supabase/tests/demo_derivatives_insurance_deficit_ledger.sql` موجود است؛ توازن سند، تفکیک seed/payout/recovery، جلوگیری از overdraw و over-recovery، تغییرناپذیری، idempotency و مرز دسترسی private را پوشش می‌دهد.
- [x] اجرای GitHub Actions شمارهٔ `44361544743` روی commit `efe928d38ce2174c237abe9fae8cfb0232e72d04` با نتیجهٔ موفق بررسی شد. سه گام مربوط به اعمال draft در PostgreSQL دورریختنی، تست حسابداری بیمه/نمایش کسری/مرز دسترسی و race دو نشست برای payout/recovery همگی success بودند.
- [!] این تأیید فقط مربوط به PostgreSQL دورریختنی CI است؛ هیچ payout/recovery RPC، اجرای liquidation یا تغییر Supabase Production مجاز یا انجام نشده است.
- [ ] گام بعد: شش دروازهٔ سیاستی لیکوییدیشن در worksheet مربوطه باید با تصمیم صریح تعیین شوند؛ تا آن زمان مسیرهای اجرا، worker و UI لیکوییدیشن غیرفعال/پیاده‌سازی‌نشده بمانند و از fixtureها سیاست واقعی استنباط نشود.


## تأیید اجرای کامل CI مشتقات و دفترکل بیمه/کسری — ۱۸ نوامبر ۲۰۲۶

- [x] اجرای GitHub Actions شمارهٔ `44365892534` (run 714) روی commit `806644414e8a2ab14ce471d1bb36fc7e1709e0e3` با conclusion برابر `success` پایان یافت؛ job با نام `exact-decimal` نیز موفق و بدون step ناموفق بود.
- [x] لاگ واقعی job تأیید می‌کند تست یکپارچه دفترکل بیمه و کسری، fault-injection برای rollback اتمیک و race دو نشست بیمه/کسری موفق شدند؛ از دو payout رقیب فقط پرداخت قابل‌تأمین و از recoveryهای رقیب فقط بازیابی مجاز پذیرفته شد؛ overdraw و over-recovery رد شدند.
- [x] همان run مراحل گستردهٔ exact-decimal، schema مشتقات، maintenance tier، oracle، Reduce-only و lifecycle را در محیط تست PostgreSQL دورریختنی با موفقیت گذراند.
- [!] این صرفاً شواهد CI است؛ هیچ draft به Supabase Production اعمال نشده و هیچ liquidation execution، payout/recovery RPC، worker یا UI فعال نشده است.
- [ ] ادامه فقط روی کارهای مستقل از policy انجام شود تا شش دروازهٔ سیاستی لیکوییدیشن صریحاً تعیین شوند؛ اعداد fixture به سیاست واقعی تبدیل نشوند.


## تأیید اجرای CI روی آخرین HEAD شاخه — ۱۸ نوامبر ۲۰۲۶

- [x] اجرای GitHub Actions شمارهٔ `44366483390` (run 717) روی HEAD شاخه `fec498d77a9a0776f094ff38888c9f7427d631d8` بازیابی شد؛ workflow و job با نام `exact-decimal` هر دو با نتیجهٔ `success` پایان یافتند.
- [x] هر ۵۰ گام اصلی job موفق شدند؛ از جمله schema مشتقات در PostgreSQL دورریختنی، maintenance/fee schedule، ذخیره‌سازی و RPCهای Oracle، raceهای دو نشست Oracle، چرخه و هم‌زمانی Reduce-only و حسابداری بیمه/کسری به همراه raceهای payout/recovery.
- [x] لاگ واقعی تأیید می‌کند retryهای تکراری چرخه/provider/publication در Oracle idempotent بودند؛ payload متناقض provider فقط یک برنده داشت؛ خطاهای پیش از commit در provider/snapshot به‌صورت اتمیک rollback شدند و retry دقیق بازیابی شد. rollback و raceهای بیمه/کسری نیز موفق بودند.
- [!] خطاهای مورد انتظار در لاگ‌ها مربوط به تست‌های منفیِ عمداً ردشونده بودند (preflight نامعتبر، lock timeout، relation عمداً ناموجود، نتیجهٔ متناقض Oracle، overdraw/over-recovery و سند نامتوازن)؛ نتیجهٔ کل workflow و job همچنان success بود.
- [!] تمام اجراهای دیتابیس فقط در PostgreSQL دورریختنی CI انجام شدند. هیچ DDL/RPC/policy/cron/data در Supabase Production تغییر نکرد؛ collector، اجرای liquidation، payout/recovery RPC، worker یا UI فعال نشد.
- [ ] ادامه فقط روی کارهای مستقل از policy انجام شود؛ PR شمارهٔ ۱۲ باز و Draft بماند و اعداد fixture به سیاست واقعی تبدیل نشوند.


## قرارداد پایش و عملیات Oracle — طراحی مستقل از سیاست مالی — ۱۸ نوامبر ۲۰۲۶

- [x] سند `docs/superpowers/specs/2026-11-18-demo-derivatives-oracle-operations-observability.md` اضافه شد: معیارهای چرخه و provider، محدودیت cardinality متریک‌ها، رخدادهای ساخت‌یافته و trace، طبقه‌بندی هشدارها، حالت‌های fail-closed، runbook رخدادها، نگهداری/دسترسی شواهد و ماتریس تست CI دورریختنی.
- [!] آستانه هشدار، SLO، دوره نگهداری، quorum منبع و صلاحیت قیمت برای ریسک عمداً تعیین نشدند؛ هیچ سیاست مالی از fixture یا حدس استخراج نشده است.
- [!] این مرحله فقط مستندات است؛ collector، telemetry sink، alert، cron، RPC، migration، secret عملیاتی، مسیر liquidation یا شیء Supabase Production ساخته یا فعال نشد.
- [ ] گام بعد: پس از مجوز جداگانه، ماتریس را به تست‌های ایزوله تبدیل و instrumentation را فقط پشت طراحی trusted-service بازبینی‌شده اضافه کنیم؛ پیش از بررسی source-family و سیاست‌ها collector زنده deploy نشود.


## تأیید CI کامل روی commit پیش از سند پایش Oracle — ۱۸ نوامبر ۲۰۲۶

- [x] اجرای GitHub Actions شمارهٔ `44367314575` (run 721) روی commit `abf6ac3757135dd742d94f147b810c85d0e15e93` با نتیجهٔ workflow/job برابر `success` پایان یافت؛ هر ۵۴ گام job کامل شدند.
- [x] لاگ واقعی، موفقیت entrypointهای Market/Limit، چرخه Stop-Limit و TP/SL، raceهای دو نشست اجرا/لغو، schema مشتقات، pin شدن نسخه maintenance tier، idempotency و rollback Oracle، حسابداری Reduce-only و rollback/race دفترکل بیمه و کسری را در PostgreSQL دورریختنی تأیید می‌کند.
- [!] خطاهای تست منفی در لاگ‌ها، rejectionهای مورد انتظار بودند و job را ناموفق نکردند. مخزن بسته‌ها در setup پاسخ HTTP 429 داد، اما workflow با indexهای موجود ادامه یافت و job موفق شد.
- [!] این اجرا قبل از commitهای مستندات پایش انجام شده و آن مستندات یا سرویس زنده را validate نمی‌کند. هیچ تغییر Supabase Production یا فعال‌سازی collector/liquidation رخ نداد.
