# DigiArz — وضعیت اجرای پروژه
آخرین به‌روزرسانی: 2026-11-26
شاخه: `main`
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

## تکمیل یکپارچه‌سازی طراحی رابط کاربری — ۱۸ نوامبر ۲۰۲۶
- [x] وضعیت شاخه اصلی و آخرین نسخه فایل‌های رابط کاربری پیش از تغییر بررسی شد؛ مخزن صحیح `shahram-adim/DigiArz` و شاخه `main` است.
- [x] صفحات اصلی موجود در `index.html` شناسایی شدند: ورود، داشبورد، بازار رمزارزها، بازار تومانی، جزئیات/نمودار ارز، خریدوفروش، دارایی‌ها، سفارش‌ها، تاریخچه، تنظیمات و مدیریت.
- [x] فونت فارسی Vazirmatn به‌صورت بارگذاری وب با fallback امن به Tahoma/Arial اضافه شد؛ اعداد و قیمت‌ها همچنان با جهت و نمایش عددی تعریف‌شده در اجزای فعلی حفظ می‌شوند.
- [x] دسترسی مستقیم «سفارش‌ها» به نوار ناوبری پایین موبایل افزوده شد تا کاربر برای مشاهده سفارش‌ها مجبور به عبور از داشبورد نباشد.
- [x] لایه نهایی یکپارچه‌سازی رابط کاربری اضافه شد: هماهنگی فونت در کنترل‌ها، focus قابل مشاهده، جلوگیری از بیرون‌زدگی افقی صفحات، یکسان‌سازی فاصله‌گذاری موبایل و سازگاری نوار پایین با تعداد آیتم‌های قابل نمایش.
- [x] حالت روشن/تاریک، شناسه‌های DOM، رویدادهای معاملاتی، اتصال Supabase و منطق مالی در این تغییر دست‌نخورده باقی ماندند.
- [x] تغییر در commit `03d79dff1b238fb550b97a9703824853d4569522` روی `main` ثبت شد.
- [ ] آزمون دیداری نهایی روی اندازه‌های واقعی اندروید، بررسی اسکرول افقی/عمودی تمام صفحات، کنترل حالت روشن و تاریک و تأیید فونت پس از بارگذاری شبکه هنوز انجام نشده است؛ بنابراین مرحله طراحی از نظر کدنویسی یکپارچه‌سازی شده، اما تأیید نهایی روی دستگاه کاربر باز است.
- [ ] پس از تأیید دیداری، هر ایراد ظاهری باقی‌مانده در صفحات به‌صورت محدود و بدون بازنویسی بخش‌های سالم اصلاح شود.



## نوبت تضمین کیفیت شبانه — ۱۹ نوامبر ۲۰۲۶، ساعت ۰۲:۱۶ به وقت تهران (معادل ۱۸ نوامبر ۲۰۲۶، ۲۲:۴۶ UTC)

### وضعیت تازه GitHub و تغییرات پس از نوبت قبلی
- [x] HEAD شاخه `main` هنگام شروع بررسی: `0a1bf7b1c189be6ca92d0e3e2840e64d1cd9c4aa`؛ آخرین دو commit: `03d79dff` برای یکپارچه‌سازی فونت فارسی و ناوبری موبایل، و `0a1bf7b1` برای ثبت checkpoint طراحی.
- [x] تغییرات قبلی از آخرین بررسی شامل اصلاح فهرست دارایی‌های واقعی (USDT مرجع از `wallets.balance_usdt`، حذف دوباره‌شماری USDT در `asset_balances`، تشخیص جفت‌های USDT/IRT)، helper مستقل `src/market-holdings.js` و cache پوسته PWA نسخه ۵۶ هستند؛ این کارها در این نوبت تکرار نشدند.
- [x] فایل‌های جاری خوانده شدند: `index.html` blob SHA برابر `d34c2d041d2d7378b5fc04fdf035346d95aadeb3`؛ `sw.js` blob SHA برابر `a603939e9e223ca6372f86ef7ee8e201f50552ac`.
- [x] `IMPLEMENTATION_STATUS.md` پیش از این ثبت، blob SHA برابر `58d8361c3915d4e46f61d9576d46d05a6edbc067` داشت.

### CI، انتشار وب و APK
- [x] Exact decimal workflow برای HEAD اصلی، run `44375569642`، job `exact-decimal`: موفق. فایل workflow موجود از قبل `node --test tests/*.test.js` را اجرا می‌کند و سپس مجموعه آزمون‌های PostgreSQL 17 دورریختنی، مهاجرت دقت اعشاری، تست‌های منفی/rollback/lock-timeout و سناریوهای هم‌زمانی سفارش را اجرا می‌کند؛ بنابراین workflow تکراری Node ساخته نشد.
- [x] GitHub Pages run `44375569554`: مراحل build، گزارش وضعیت و deploy همگی موفق.
- [!] Android APK run `44375514855` در تلاش اول به‌علت پاسخ HTTP 429 از Maven Central هنگام دریافت وابستگی‌های Gradle شکست خورد؛ مراحل checkout، Node، Java، نصب Capacitor، آماده‌سازی وب و sync Android موفق بودند و شکست فقط در resolve وابستگی‌های Gradle رخ داد. این خطا با محدودیت موقت نرخ درخواست مخزن Maven سازگار است، نه خطای قطعی کد برنامه.
- [x] فقط job ناموفق APK با run attempt دوم مجدداً اجرا شد؛ در آخرین snapshot ساعت `22:47:16Z` وضعیت `in_progress` بود. نتیجه نهایی هنوز تأیید نشده و باید در نوبت بعد بررسی شود.
- [!] ساخت Debug APK قبلی برای commit `d30b5bdaadccac687e906560b80e0a9a75bbb6ce` موفق بوده، اما APK جدید حاوی تغییرات فونت/ناوبری هنوز تا پایان retry تأیید نشده است. تست نصب و اجرای واقعی روی دستگاه Android نیز انجام نشده است.

### وضعیت Pull Requestها
- [x] PR `#12`، شاخه `feat/demo-derivatives-trading`، head `224baa70c70e62c57f523e963e168a21fb2965b0`: Open و Draft؛ GitHub گزارش `mergeable=true` و `mergeable_state=clean`؛ مقایسه با main فعلی ۳۰۷ commit جلو و صفر عقب. با وجود clean بودن، به‌علت Draft بودن و ماهیت foundation مشتقات، merge انجام نشد.
- [x] PR `#11`، شاخه `perf/iran-exchange-matcher-design`، head `32a5aefa8ea2df190c004a417d258770d96250e4`: Open و Draft؛ ۴۷ commit جلو و ۲۲ commit عقب از main؛ mergeability فعلی clean گزارش شد، ولی هیچ همگرایی یا merge انجام نشد.
- [x] PRهای `#8` تا `#10` نیز Open و Draft هستند؛ هیچ PR از Draft خارج یا merge نشد.

### وضعیت زنده Supabase — فقط خواندنی
- [x] پروژه `gfoaubfilhttnwjykaox`: `ACTIVE_HEALTHY`؛ PostgreSQL `17.11.0.018`.
- [x] ۵۲ Migration ثبت‌شده؛ آخرین نسخه `20261116205451` با نام `stagger_market_price_overflow_and_refresh_exchange_discovery`. در این نوبت هیچ Migration یا DDL اجرا نشد.
- [x] Health Advisor بدون یافته.
- [!] Security Advisor: ۱۵ مورد RLS فعال بدون Policy (سطح INFO)، دو تابع SECURITY DEFINER قابل اجرا برای `anon`، ۲۳ تابع SECURITY DEFINER قابل اجرا برای `authenticated` و یک هشدار غیرفعال بودن حفاظت رمزهای افشاشده. این هشدارها نیازمند بررسی موردی‌اند؛ هیچ grant یا تنظیم Auth تغییر نکرد.
- [!] Performance Advisor: ۹ کلید خارجی بدون ایندکس پوششی، ۱۱ هشدار RLS Initialization Plan و ۷ ایندکس استفاده‌نشده. هیچ ایندکس یا policy در Production تغییر نکرد.

### پایش jobهای بازار در ۲۴ ساعت منتهی به حدود ۲۲:۴۷ UTC
- [x] پرس‌وجوها فقط روی `cron.job` و `cron.job_run_details` و صرفاً SELECT بودند. هر سه job فعال‌اند: job 13 هر ۱۰ دقیقه، job 14 هر دقیقه، job 17 از دقیقه ۵ و سپس هر ۱۰ دقیقه.
- [!] job 13: تعداد ۶۳ شکست از نوع startup timeout و ۸۱ موفقیت؛ آخرین شکست `20:50:00Z` و آخرین موفقیت `22:40:00Z`.
- [!] job 14: تعداد ۵۳۹ شکست (۳۷۶ startup timeout و ۱۶۳ statement timeout) و ۹۰۱ موفقیت؛ آخرین شکست `20:51:49Z` و آخرین موفقیت `22:47:00Z`. میانهٔ زمان اجرای موفق ۱۸٫۲۲ ثانیه و صدک ۹۵ آن ۲۱٫۳۹ ثانیه بود؛ شکست‌ها میانهٔ ۱۴٫۵۸ ثانیه و صدک ۹۵ برابر ۲۱۹٫۳۳ ثانیه داشتند.
- [!] job 17: تعداد ۶۱ شکست startup timeout و ۸۳ موفقیت؛ آخرین شکست `20:45:02Z` و آخرین موفقیت `22:45:00Z`.
- [x] در snapshot اخیر، از حدود `20:51:49Z` به بعد شکست جدیدی برای این سه job دیده نشد و اجرای موفق تا `22:47Z` ادامه داشت؛ این نشانهٔ بازیابی موقت است، نه اثبات رفع ریشه‌ای مشکل. تفکیک خطاها نشان می‌دهد job 14 هم startup timeout و هم statement timeout داشته است؛ این دو علت نباید با یکدیگر ادغام شوند.
- [!] به‌دلیل بهبود اخیر و نبود علت ریشه‌ای اثبات‌شده، هیچ تابع، شاخص، cron schedule یا timeout در Production تغییر نکرد. بررسی plan و بهینه‌سازی باید ابتدا در PostgreSQL دورریختنی انجام شود.

### اقدام این نوبت، تست و محدودیت
- [x] job ناموفق Android فقط retry شد؛ اجرای آن در آخرین snapshot همچنان در حال انجام بود.
- [x] workflow موجودِ exact-decimal به‌عنوان پوشش کامل Node و PostgreSQL بررسی شد؛ CI روی HEAD اصلی و Pages موفق بودند.
- [x] آمار cron، وضعیت پروژه، Migrationها و Advisorها فقط خوانده شدند.
- [x] این نوبت فقط مستندات را به‌روز می‌کند؛ هیچ سفارش، معامله، رزرو، موجودی، کیف پول، سابقه مالی، worker یا RPC روی کاربران Production برای تست اجرا نشد.
- [!] آزمون بصری Chrome Android، نصب APK جدید، و مشاهدهٔ رابط با حساب تست مجاز هنوز انجام نشده است.

### گام‌های بعدی
1. نتیجهٔ attempt دوم Android run `44375514855` را بررسی کن؛ اگر دوباره HTTP 429 شد، retry محدود و کنترل‌شده یا backoff برای resolve وابستگی‌ها را ارزیابی کن، نه تغییر نسخهٔ بی‌دلیل Gradle.
2. برای jobهای 13/14/17 یک پنجرهٔ ۲۴ساعتهٔ جدید ثبت کن و نرخ شکست پس از `20:51Z` را با همان تفکیک startup و statement timeout بسنج.
3. SQL و planهای بخش‌های کند worker را در PostgreSQL ایزوله بازسازی کن؛ هیچ worker/RPC یا دادهٔ مالی در Production برای تست اجرا نشود.
4. بازبینی دقیق توابع SECURITY DEFINER و ۱۵ جدول RLS بدون Policy را بر اساس حساسیت داده و intended access ادامه بده؛ هیچ grant یا policy حساس بدون تأیید و تحلیل اثر تغییر نکند.
5. تست بصری فونت Vazirmatn، نوار ناوبری موبایل، حالت روشن/تاریک و اسکرول تمام صفحات در Android واقعی را پس از دسترسی به دستگاه انجام بده.



### تکمیل نتیجهٔ retry اندروید — ۱۸ نوامبر ۲۰۲۶، ۲۲:۴۸ UTC
- [x] اجرای دوم job اندروید با run `44375514855` و attempt شماره ۲ با نتیجه `success` تمام شد؛ Gradle پیام `BUILD SUCCESSFUL` و ۸۲ task موفق ثبت کرد.
- [x] APK آزمایشی برای commit `03d79dff1b238fb550b97a9703824853d4569522` و نسخه `1.0.0` ساخته شد. SHA-256 خود APK: `a25a0871fb6147db79b400ed18c60920023aee0f31347fe655db4b6bc3a48d94`.
- [x] artifact شناسه `14478567720`، حجم ۳٬۴۹۹٬۵۱۹ بایت، digest آرشیو `153c381d98517ca1e405d6ed712b3919e2acc72b32240bed6d55a943ce355f4f` و انقضا `2026-12-02T22:48:17Z`: https://github.com/shahram-adim/DigiArz/actions/runs/44375514855/artifacts/14478567720
- [!] این APK همچنان Debug است؛ نصب و اجرای واقعی روی دستگاه Android انجام نشده است.
- [!] پس از commit مستندات این نوبت، Exact decimal run `44415120810` و Pages run `44415120636` برای HEAD `7aa319c0e223edf567bb3c8fbe64aedf57e31ee7` در snapshot ساعت `22:48:59Z` هنوز در حال اجرا بودند؛ نتیجهٔ نهایی آن‌ها در این ثبت ادعا نمی‌شود.

## اصلاح لوگوهای ارز و رتبه‌بندی نوسان بازار — ۱۹ نوامبر ۲۰۲۶
- شاخهٔ کاری: `fix/market-logo-and-ranking-consistency`؛ بر پایهٔ `main` با commit `ad8d52bf49027b20756242259b1de867c04d5ab9`.
- [x] علت قطعی مسیر لوگو بررسی شد: Edge Function فعال `app-assets` فقط مجموعهٔ SpotHQ را درخواست می‌کرد و برای نمادهای فاقد فایل، 404 می‌داد.
- [x] `index.html`: لوگو ابتدا از `image_url` معتبر HTTPS کاتالوگ (در صورت وجود) استفاده می‌کند؛ سپس به مسیر `app-assets` و بعد منبع مستقل CoinCap fallback می‌کند؛ در پایان fallback متنی حفظ شده است.
- [x] `index.html`: helper واحد `getMarketChange24h` و مرتب‌ساز پایدار `sortMarketRowsByChange` اضافه شد. فهرست بازار، ۵ صعودی، ۵ نزولی و خلاصهٔ نوسان از منبع درصد و comparator مشترک استفاده می‌کنند؛ دادهٔ ذخیره‌شده فقط در صورت تازه‌بودن پذیرفته می‌شود و مقدارهای نامعتبر/کهن در انتهای مرتب‌سازی قرار نمی‌گیرند یا از رتبه‌بندی حذف می‌شوند.
- [x] انتخاب «بیشترین افزایش» فقط از درصدهای مثبت و «بیشترین کاهش» فقط از درصدهای منفی انجام می‌شود؛ تساوی درصدها با نماد مرتب می‌شود.
- [x] منبع فعلی Edge Function در GitHub به مسیر `supabase/functions/app-assets/index.ts` اضافه شد و fallback مستقل CoinCap برای لوگوها در آن پیاده‌سازی شد.
- [x] تست‌های `tests/index-syntax.test.js` برای ترتیب صعودی/نزولی، حذف دادهٔ کهنه، یکسان‌بودن مسیرهای رتبه‌بندی و fallback لوگو اضافه شدند.
- [x] بررسی محلیِ این نشست با V8: هر ۳ بلوک JavaScript درون‌صفحه بدون خطای parse؛ آزمون عملی helperها ترتیب صعودی و نزولی مورد انتظار را تولید کرد؛ درصد کهنه `null` و fallback تازه `2.25` برگرداند.
- [!] اجرای کامل `node --test tests/*.test.js` در GitHub Actions هنوز باید روی PR تأیید شود.
- [!] Edge Function کدبندی‌شده در GitHub هنوز روی Supabase Production deploy نشده است؛ نسخهٔ فعال Supabase در این مرحله تغییر نکرده است.
- [!] آزمون بصری واقعی روی Android و آزمون زندهٔ همهٔ لوگوهای نمادهای فاقد آیکون هنوز انجام نشده است.
- [x] هیچ جدول، migration، موجودی، کیف پول، سفارش، معامله، cron یا RPC مالی Supabase تغییر نکرد.
- گام بعد: Draft PR بساز، نتیجهٔ workflow را بررسی کن، هر شکست را رفع کن؛ سپس برای تأیید نهایی و تصمیم جداگانهٔ deploy به Supabase آماده کن.

### PR #13 opened — ۱۹ نوامبر ۲۰۲۶
- [x] Draft PR شمارهٔ ۱۳ ایجاد شد: https://github.com/shahram-adim/DigiArz/pull/13
- شاخهٔ PR: `fix/market-logo-and-ranking-consistency`؛ مقصد `main`.
- [x] بازبینی تکمیلی نشان داد پیش‌نمایش بازار داشبورد نیز مرتب‌سازی مستقل داشت؛ آن بخش هم به helper و comparator مشترک ۲۴ساعته متصل شد و تست رگرسیون آن اضافه شد.
- [x] GitHub Actions run `44475074226` برای آخرین commit `693a598a0d51076e6c1981728725413074e57a6a`: مرحلهٔ `node --test tests/*.test.js` با موفقیت تمام شد.
- [!] ادامهٔ مراحل PostgreSQL در همان workflow هنوز در حال اجراست؛ نتیجهٔ کامل workflow هنوز تأیید نشده است.
- [!] PR عمداً Draft است و merge نشده؛ Edge Function فعال Supabase نیز deploy نشده است.
- گام بعد: تکمیل بررسی نتیجهٔ workflow و سپس بازبینی نهایی PR؛ هرگونه merge یا deploy Production مرحله‌ای جداگانه خواهد بود.


## تکمیل CI اصلاح لوگو و رتبه‌بندی بازار — ۱۹ نوامبر ۲۰۲۶
- [x] اجرای کامل GitHub Actions exact-decimal روی HEAD شاخه با run شناسه `44475236966` با نتیجهٔ نهایی `success` تمام شد.
- [x] تمام ۴۳ مرحلهٔ job موفق شدند؛ از جمله تست‌های JavaScript/browser، arithmetic regression، widening rehearsal و preflight/rollback، Market/Limit، رزرو و گردکردن تجمعی USDT، Stop-Limit و TP/SL، چرخه‌های لغو و آزمون‌های رقابت واقعی دو نشست PostgreSQL.
- [x] مرحلهٔ `node --test tests/*.test.js` نیز در همین workflow موفق بود.
- [!] این تست‌ها در محیط CI و PostgreSQL ایزوله اجرا شده‌اند؛ هیچ migration یا تغییر مالی روی Supabase Production اعمال نشده است.
- [!] PR شمارهٔ ۱۳ همچنان Draft و باز است؛ هنوز merge نشده و شاخهٔ `main` تغییر نکرده است.
- [!] منبع جدید Edge Function لوگو هنوز روی Supabase deploy نشده و تست بصری Android و smoke test زندهٔ نمادهای فاقد لوگو همچنان باقی است.
- گام بعد: بازبینی نهایی PR و سپس تصمیم جداگانه با تأیید کاربر برای merge/deploy؛ پیش از آن، آزمون بصری روی Android لازم است.


## تأیید نهایی اجرای دوم CI — ۱۹ نوامبر ۲۰۲۶
- [x] اجرای GitHub Actions با شناسه `44475656448` روی commit مستندات `33eb1e5b94d5fb2a2019294e3be12a5afcc4cc58` با نتیجهٔ نهایی `success` تمام شد.
- [x] تمام ۴۳ مرحله موفق شدند؛ از جمله Node/browser، PostgreSQL arithmetic، widening rehearsal، preflight، lock-timeout، rollback، Market/Limit، Stop-Limit، TP/SL، lifecycle، rounding و raceهای دو نشست.
- [!] این اجرا نیز CI ایزوله است؛ هیچ deploy یا تغییر Production در Supabase انجام نشده است.
- [!] PR #13 هنوز Draft و باز است؛ main بدون تغییر مانده است.
- [!] تست بصری Android و live logo smoke test همچنان لازم است؛ Edge Function جدید deploy نشده.
- گام بعد: آزمون بصری/زنده پس از تصمیم مستقل دربارهٔ merge و deploy؛ هیچ‌یک خودکار انجام نشود.


## انتشار اصلاح لوگوها در Supabase Production — ۱۹ نوامبر ۲۰۲۶
- [x] PR #13 با تأیید کاربر در commit ادغام `d062f4f6d9fed77bae2c1d122fb0cada0801462e` وارد شاخهٔ `main` شد.
- [x] Edge Function `app-assets` در پروژهٔ `gfoaubfilhttnwjykaox` با موفقیت به نسخهٔ ۲ deploy شد.
- [x] وضعیت پس از deploy از Supabase خوانده شد: `ACTIVE`، نسخهٔ `2`، `verify_jwt=false` (مطابق تنظیم قبلی Production) و SHA-256 برابر `1fe0c818ffd91d057fea77406dc6a6df4eb3a2daa20c73b2553a355c037cdb4f`.
- [x] محتوای نسخهٔ فعال شامل fallback مستقل SpotHQ و CoinCap و اعتبارسنجی Content-Type تصویر است.
- [!] درخواست smoke test مستقیم از محیط اجرا به endpoint عمومی به علت مشکل DNS/دسترسی شبکه انجام نشد؛ بنابراین دریافت واقعی تصویر از upstream و نمایش بصری روی Android هنوز تأیید نشده است.
- [x] هیچ migration، schema، RPC، cron یا دادهٔ مالی تغییر نکرد.
- گام بعد: کاربر برنامه را refresh کند؛ نمادهای قبلاً بدون لوگو و ترتیب صعودی/نزولی را بررسی و در صورت ایراد تصویر ارسال کند.

 
## عیب‌یابی تکمیلی لوگو و رتبه‌بندی بازار — ۱۹ نوامبر ۲۰۲۶
- [x] بررسی لاگ‌های زنده Supabase نشان داد در ۲۴ ساعت اخیر درخواست‌های لوگوی ثبت‌شده از Android شامل ۱٬۱۶۶ پاسخ 404 و ۱۰۳ پاسخ 200 بوده‌اند؛ پس fallback نسخه ۲ پوشش کافی برای نمادهای بازار ندارد.
- [x] بررسی فقط‌خواندنی Production نشان داد هر ۳۹۸ جفت‌ارز فعال در `demo_trading_pairs` از طریق `base_coingecko_id` دقیقاً به رکورد `crypto_assets` دارای `image_url` متصل هستند؛ اما `loadMarkets()` فقط `market_prices` را می‌خواند و metadata را به `marketRows` اضافه نمی‌کند.
- [x] علت دوم درصدها در مسیر داده پیدا شد: `fetchBinance24hrTickerRows()` از `Promise.all` استفاده می‌کرد؛ شکست یک batch کل پاسخ‌های batchهای موفق را دور می‌ریخت. همچنین شرط اجرای fallback فقط ۱۲ نماد اول را ارزیابی می‌کرد، نه کل ۳۹۸ جفت‌ارز فعال.
- [x] شاخه اصلاحی `fix/market-logo-metadata-and-partial-ticker-batches` از main فعلی ساخته شد.
- [x] `loadMarkets()` اکنون metadata ارزها را با شناسه یکتای CoinGecko و در دسته‌های ۱۰۰تایی می‌خواند؛ نام، تصویر و زمان واقعی metadata به ردیف بازار افزوده می‌شود. زمان metadata از زمان قیمت جدا نگه داشته می‌شود تا درصد کهنه به‌عنوان داده تازه پذیرفته نشود.
- [x] دریافت batchهای ticker به `Promise.allSettled` و تجمیع پاسخ‌های موفق تغییر کرد؛ شکست یک batch دیگر داده batchهای دیگر را حذف نمی‌کند.
- [x] آستانه fallback اکنون پوشش کل جفت‌ارزهای فعال را می‌سنجد و مقدار null را درصد معتبر صفر حساب نمی‌کند.
- [x] تست‌های رگرسیون برای اتصال metadata با `base_coingecko_id`، رد درصد کهنه، حفظ batchهای موفق و آستانه پوشش کامل اضافه شدند.
- [!] هنوز CI این شاخه و تست بصری Android اجرا/تأیید نشده است. هیچ تغییر Production، deploy تابع، migration، schema، RPC، cron یا داده مالی انجام نشده است.
- گام بعد: اجرای CI روی PR آزمایشی؛ پس از موفقیت، بررسی خروجی روی Android و سپس تصمیم مستقل برای merge. هیچ merge یا deploy خودکار انجام نشود.

## وضعیت PR اصلاحات بازار — ۱۹ نوامبر ۲۰۲۶
- [x] PR شمارهٔ ۱۴ برای اصلاح اتصال metadata لوگوها و بازیابی batchهای ticker ایجاد و برای بررسی آماده شد: https://github.com/shahram-adim/DigiArz/pull/14
- شاخه: `fix/market-logo-metadata-and-partial-ticker-batches`؛ آخرین commit کد و تست: `be3b9c3841c7acf69bb122f7e103fd8b1c4d7613`؛ فایل‌های ثبت وضعیت در همین شاخه قرار دارند.
- [!] GitHub Actions run `44479513790` (run 822) در حال اجراست؛ نتیجه نهایی هنوز دریافت نشده است.
- [!] PR باز و merge نشده؛ هیچ deploy جدید یا تغییر Supabase Production انجام نشده است. merge و deploy همچنان نیازمند اجازه جداگانه کاربر است.

## اصلاح نتیجهٔ CI برای PR #14 — ۱۹ نوامبر ۲۰۲۶
- [x] اجرای نخست run `44479513790` در مرحلهٔ parse اسکریپت درون‌صفحه شکست خورد؛ علت دقیق یک `]` اضافه در انتهای بارگذاری metadata بازار بود.
- [x] خطای نحوی در commit `6d9b4be45a4706ef7d292eee60d3440f3bf1cee1` اصلاح شد.
- [x] در اجرای بعدی run `44479671283`، مرحلهٔ `Run exact decimal and browser integration tests` با موفقیت گذشت؛ وضعیت کامل workflow هنوز در حال اجرا و آزمون‌های PostgreSQL در صف/اجرا هستند.
- [!] تا دریافت نتیجهٔ نهایی workflow، CI کلی موفق اعلام نشود. PR #14 باز است و merge نشده؛ Production تغییر نکرده است.

## نتیجه نهایی CI برای اصلاحات بازار — ۱۹ نوامبر ۲۰۲۶
- [x] اجرای مجدد GitHub Actions با run `44479671283` (run number 824) با نتیجهٔ نهایی `success` تکمیل شد.
- [x] تمام ۴۳ مرحلهٔ job موفق شدند؛ شامل تست‌های مرورگر و منطق بازار، تست‌های PostgreSQL، آزمون‌های هم‌زمانی واقعی دو نشست برای Limit، TP-SL و Stop-Limit و تست‌های lifecycle مربوطه.
- [x] خطای نحوی run قبلی در commit `6d9b4be45a4706ef7d292eee60d3440f3bf1cee1` اصلاح شده و run جدید سبز است.
- [!] این موفقیت CI، آزمایش بصری روی گوشی و اثبات دریافت زنده تصاویر upstream را جایگزین نمی‌کند. PR #14 هنوز ادغام نشده و هیچ Production deploy انجام نشده است.

## اصلاح تکمیلی لوگوهای بازار — ۱۹ نوامبر ۲۰۲۶
- [x] بررسی لاگ زنده Android پس از انتشار قبلی نشان داد درخواست‌های fallback تابع `app-assets` برای نمادهایی مانند ZRO، ICNT، ZKC، ASTER و MANTA همچنان 404 می‌گیرند.
- [x] بررسی فقط‌خواندنی Production تأیید کرد رکوردهای `crypto_assets` برای این نمادها `image_url` معتبر CoinGecko دارند؛ مسیر فعلی در صورت شکست بارگذاری مستقیم، آن URL کاتالوگ را به proxy سمت سرور منتقل نمی‌کرد.
- [x] شاخه `fix/market-logo-proxy-fallback` از main فعلی ساخته شد. `coinLogo` اکنون URL تصویر کاتالوگ را برای fallback حفظ می‌کند و مسیر بازار و پیش‌نمایش داشبورد آن را صریحاً به renderer می‌دهند.
- [x] Edge Function منبع `app-assets` اکنون می‌تواند URL تصویر را فقط از دامنه‌های مجاز CoinGecko دریافت و با اعتبارسنجی Content-Type و مقصد نهایی proxy کند؛ سپس در صورت شکست، به منابع نمادمحور قبلی می‌رود.
- [x] تست رگرسیون برای انتقال URL تصویر، مسیر بازار/داشبورد و allowlist سرور به‌روزرسانی شد.
- [!] این اصلاح هنوز فقط روی شاخه کاری است؛ PR/CI و تست بصری Android باید انجام شوند. هیچ merge به main و هیچ deploy به Supabase Production انجام نشده است.
- گام بعد: اجرای تست‌ها و ساخت PR؛ merge و deploy نیازمند تأیید جداگانه‌اند.

## انتشار اصلاح proxy لوگوها در Supabase Production — ۱۹ نوامبر ۲۰۲۶
- [x] با تأیید صریح کاربر، منبع تابع `app-assets` از شاخهٔ `main` مخزن دریافت و روی پروژهٔ `gfoaubfilhttnwjykaox` منتشر شد.
- [x] نسخهٔ فعال تابع از ۲ به ۳ ارتقا یافت؛ وضعیت `ACTIVE` و `verify_jwt=false` حفظ شد.
- [x] پس از انتشار، `get_edge_function` محتوای فعال را دوباره خواند و وجود منطق دریافت `image_url` همراه allowlist دامنه‌های CoinGecko را تأیید کرد.
- [x] SHA-256 نسخهٔ فعال: `30e3d08801c9bfc651d88cfa867aeee4943a8b8cb359c16c6ae9cf6b3154ad17`؛ blob منبع main: `5a6d2c8dd1beac78cb51a45f368c02c9ff50be68`.
- [!] درخواست HTTP زنده برای دریافت تصویر و بررسی بصری روی Android در این مرحله اجرا/تأیید نشد؛ بنابراین موفقیت نمایش لوگوها هنوز قطعی اعلام نمی‌شود.
- [x] هیچ migration، schema، RPC، cron یا دادهٔ مالی تغییر نکرد.
- گام بعد: کاربر برنامه را کامل refresh کند و نمادهای قبلاً بدون لوگو (مانند ZRO، ICNT، ZKC، ASTER و MANTA) را بررسی کند؛ در صورت باقی‌ماندن مشکل، screenshot و نام نمادها ثبت شود.


## عیب‌یابی پس از انتشار proxy لوگو — ۱۹ نوامبر ۲۰۲۶
- [x] لاگ‌های Supabase پس از فعال‌شدن `app-assets` نسخهٔ ۳ بررسی شدند. در ساعت 08:00 UTC، ۱۱۲ درخواست نمادمحور ثبت شد: ۱۰۸ پاسخ 404 و ۴ پاسخ 200؛ نمونهٔ درخواست‌ها فقط `asset=logo&symbol=...` دارند و هیچ `imageUrl/image_url` ارسال نشده است.
- [x] این شواهد نشان می‌دهد تابع نسخهٔ ۳ فعال است اما کلاینتی که در آن زمان روی Android اجرا می‌شد هنوز URL تصویر کاتالوگ را به fallback نمی‌فرستاده؛ بنابراین deploy تابع به‌تنهایی مشکل را حل نکرده است.
- [x] GitHub Pages build/deploy برای merge commit `1e5d7ee5bcc6571003bfebf6eeca57c7973d2269` با موفقیت کامل شد (run `44483387814`).
- [x] APK جدید از همان commit ساخته و artifact آن با موفقیت بارگذاری شد (run `44483387973`, artifact `14509018848`). Build info تأیید می‌کند commit دقیقاً `1e5d7ee5bcc6571003bfebf6eeca57c7973d2269` است؛ SHA-256 APK: `8d2481a4eb1582f7806aa65173ae8ecb463c466ea5fab57fc417fc550cb7c686`.
- [x] Exact-decimal CI روی merge commit با run `44483387900` و تمام ۴۳ مرحله با نتیجهٔ `success` تکمیل شد.
- [!] هنوز نصب و اجرای APK جدید روی گوشی کاربر تأیید نشده است؛ تا آن زمان نمایش لوگوها را حل‌شده اعلام نکن.
- گام بعد: نصب APK ساخته‌شده از commit merge؛ سپس بررسی لاگ‌های جدید برای وجود `imageUrl` در درخواست‌های app-assets و پاسخ موفق تصویر.


## اصلاح چیدمان و خوانایی ردیف‌های بازار — ۱۹ نوامبر ۲۰۲۶
- [x] بازبینی کد index.html در شاخه main نشان داد renderer هر ردیف بازار پنج فرزند تولید می‌کند (ستاره، هویت ارز، sparkline، تغییر ۲۴ساعته، قیمت) اما چندین override متناقض CSS در انتهای فایل تعداد/ترتیب ستون‌ها را به ۲، ۳ یا ۴ ستون تغییر داده‌اند؛ علت ساختاری به‌هم‌ریختگی ردیف‌ها.
- [x] شاخه کاری fix/market-row-layout-readability از main ساخته شد؛ هیچ تغییری روی main یا Production انجام نشده است.
- [x] یک override نهایی و محدود به #tab-markets .market-board-v34 اضافه شد: پنج ستون هم‌راستا در نمایش عریض و چیدمان دو ردیفهٔ کنترل‌شده در موبایل؛ sparkline در موبایل پنهان می‌شود تا اجزای ضروری فشرده و جابه‌جا نشوند.
- [x] لوگوی فهرست بازار روی ۴۰×۴۰ پیکسل تثبیت شد؛ حاشیه/پس‌زمینهٔ کادری ستاره علاقه‌مندی حذف شد؛ کنتراست متن فارسی، نماد انگلیسی، قیمت، درصد و اطلاعات تازگی افزایش یافت.
- [x] نمایش نام فارسی در DOM صریحاً حفظ شد و در صورت وجود از item.name_fa استفاده می‌کند؛ در غیر این صورت تابع واژگان فارسی فعلی (persianCoinName) منبع نام است. نام فارسی ساختگی تولید نمی‌شود.
- [x] تست رگرسیون در tests/index-syntax.test.js برای پنج‌ستونه بودن، لوگوی ۴۰ پیکسلی، ستاره بدون کادر، نام فارسی و layout موبایل اضافه شد.
- [!] تست کامل CI، بازبینی PR و بررسی بصری Android هنوز انجام/تأیید نشده است. PR پس از ثبت این checkpoint ایجاد می‌شود؛ merge به main و انتشار APK/Pages بدون اجازهٔ صریح کاربر انجام نخواهد شد.
- گام بعد: اجرای CI، رفع هر شکست، سپس ارائهٔ PR برای بازبینی و درخواست تست بصری کاربر.


## انتشار اصلاحات چیدمان بازار — ۱۹ نوامبر ۲۰۲۶
- [x] PR #16 با اجازه صریح کاربر merge شد: https://github.com/shahram-adim/DigiArz/pull/16
- [x] merge commit روی main: 0ee8c9dbeb0c8229b2181acc2e9cb52544e6868b
- [x] CI مربوط به PR پیش از merge موفق بود.
- [ ] پس از merge، workflow آزمون‌های Exact decimal با run ID 44486985269 در حال اجرا است.
- [ ] ساخت APK جدید با run ID 44486985383 آغاز شده؛ مرحله Gradle assembleDebug هنوز در حال اجراست و artifact هنوز منتشر نشده است.
- تغییرات Supabase/DB و داده‌های مالی انجام نشده‌اند.


## اجرای ۱۹ نوامبر ۲۰۲۶ — همسان‌سازی صفحه ورود با تم منتخب
- [x] آخرین HEAD پیش از تغییر: `685e1eef2b530e0c565a09a8cfc0962a4a6a01fe`؛ آخرین Commit شامل بازطراحی آبی/روشن صفحه ورود بود.
- [x] ساختار واقعی `#authView`، کنترل‌های ورود/ثبت‌نام/بازیابی و اسکریپت‌های آزمون بازخوانی شدند؛ شناسه‌های عملکردی فرم حفظ می‌شوند.
- [x] رنگ‌بندی scoped صفحه ورود به طرح منتخب DigiArz (پس‌زمینه مشکی/ذغالی، تأکید زرد Binance، ورودی‌های تیره و دکمه اصلی زرد) برگردانده شد؛ چیدمان واکنش‌گرای موبایل و prefers-reduced-motion حفظ شد.
- [x] آزمون رگرسیون صفحه ورود از انتظار آبی/سفید به انتظار مشکی/زرد تغییر کرد و کنترل‌های نام، ایمیل، رمز، ورود، ثبت‌نام و بازیابی را پوشش می‌دهد.
- [x] GitHub Actions برای Commit کد `84e6201cc8283bdf46ad1127ba2ce66bceac29f3` تأیید شد: `build`، `deploy`، `exact-decimal` و `build-debug-apk` همگی موفق شدند.
- [x] آزمون‌های isolated PostgreSQL شامل arithmetic regression، rehearsal افزایش دقت، Market/Limit، لغو و رقابت هم‌زمان، Stop-Limit parent-child و TP/SL در workflow مربوط به Exact Decimal با موفقیت تکمیل شدند؛ این آزمون‌ها در محیط‌های موقت CI اجرا شدند، نه روی Supabase Production.
- [x] APK آزمایشی Android برای همین Commit ساخته شد؛ artifact برابر `DigiArz-Android-debug-APK`، شناسه `14520927619`، حجم 3,503,817 بایت و اعتبار تا 2026-12-03 است.
- [x] بررسی خواندنی Supabase در 2026-11-19: پروژه `ACTIVE_HEALTHY`، PostgreSQL 17.11، شمارش سادهٔ `information_schema` برابر ۲۲ جدول عمومی، ۵۲ migration (آخرین `20261116205451`)، هشت Edge Function فعال و بدون Development Branch.
- [!] درخواست جزئیات کامل ستون‌های جدول‌ها در همان نوبت با connection timeout مواجه شد؛ شمارش سادهٔ جداول موفق بود. هیچ DDL، RPC مالی، Worker یا تغییر داده‌ای در Production انجام نشد.
- [ ] نمایش بصری روی Android واقعی هنوز تأیید نشده است.
- [x] فقط فایل‌های رابط و آزمون و این مستند تغییر می‌کنند؛ هیچ RPC مالی، Worker یا داده Supabase Production اجرا یا تغییر داده نشده است.
- گام بعدی: بررسی check-runهای Commit جدید و سپس آزمون بصری ورود/ثبت‌نام/بازیابی در عرض‌های 360px، 390px و دسکتاپ.


## تأیید نهایی workflow و APK — ۱۹ نوامبر ۲۰۲۶
- [x] پس از به‌روزرسانی قبلی، workflow آزمون‌های Exact Decimal با run ID `44486985269` برای merge commit `0ee8c9dbeb0c8229b2181acc2e9cb52544e6868b` با نتیجه `success` تکمیل شد.
- [x] workflow ساخت APK با run ID `44486985383` برای همان merge commit با نتیجه `success` تکمیل شد.
- [x] artifact با نام `DigiArz-Android-debug-APK` منتشر شده؛ حجم 3,502,401 بایت و زمان انقضا 2026-12-03T08:23:36Z است.
- [x] check-runهای commit مستندسازی `1347ecc8a08179e8658a1961bce87563a057e9f8` شامل `build`، `deploy`، `exact-decimal` و `report-build-status` همگی موفق‌اند.
- [!] این موفقیت‌ها تست CI و ساخت artifact را تأیید می‌کنند؛ نصب و نمایش واقعی روی گوشی Android هنوز از طرف کاربر/دستگاه تأیید نشده است.
- [ ] گام بعدی: کاربر APK را از workflow بالا دریافت و نصب کند؛ سپس اسکرین‌شات صفحه ورود، ثبت‌نام و داشبورد را برای بررسی بصری ارسال کند. در صورت امکان عرض‌های 360px و 390px نیز بررسی شوند.
- [x] هیچ تغییری در Supabase Production، RPCهای مالی، Worker یا داده‌های مالی انجام نشد.


## بازگردانی رنگ‌بندی صفحه ورود — ۱۹ نوامبر ۲۰۲۶
- [x] کاربر تأیید کرد فعلاً فقط صفحه ورود/ثبت‌نام با رنگ‌بندی آبی، سفید و طلایی تغییر کند؛ سایر صفحات دست‌نخورده بمانند.
- [x] شاخه کاری مستقل `fix/login-blue-white-gold` از HEAD فعلی `6702a6f5106a7ac9f5e48a85e61da6018f32e8ae` ساخته شد.
- [x] بلوک CSS صفحه ورود از commit تأییدشده `685e1eef2b530e0c565a09a8cfc0962a4a6a01fe` بازیابی می‌شود؛ فقط selectorهای `#authView` و اجزای وابسته را هدف می‌گیرد.
- [x] آزمون رگرسیون صفحه ورود به طرح روشن آبی/سفید/طلایی برمی‌گردد و شناسه کنترل‌های ورود، ثبت‌نام و بازیابی حفظ می‌شوند.
- [x] PR شماره ۱۹ باز است؛ CI مربوط به commit `c57f60cce10f70c646196fb79484e9745ddea328` با نتیجه `success` تکمیل شد.
- [x] در ادامه، پیش‌نمایش موبایلی بازار به‌صورت scoped به `#authView` اضافه شد: کندل‌های BTC از Edge Function موجود `market-data`، قیمت‌های چند ارز از همان gateway، و نوار سه‌ارزی چرخشی.
- [ ] آزمون‌های جدید پیش‌نمایش زنده و بازبینی diff commit تازه باید تکمیل شوند.
- [x] ترتیب راه‌اندازی اصلاح شد: پیش‌نمایش بازار بعد از ساخت `supabaseClient` شروع می‌شود تا درخواست‌های کندل و قیمت از ابتدا قابل اجرا باشند.
- [ ] تبلیغ ثابت معرفی و تبلیغ روزانه قابل مدیریت هنوز پیاده‌سازی نشده‌اند؛ خواندن schema دیتابیس در این نوبت timeout شد، بنابراین هیچ جدول یا دسترسی مدیریتی حدس زده یا ساخته نشده است.
- [ ] پس از ادغام مجاز، APK تازه باید ساخته و ZIP artifact استخراج و SHA-256 آن کنترل شود؛ نصب واقعی روی Android هنوز تأیید نشده است.
- [!] هیچ تغییر Supabase، RPC، Worker، migration یا داده مالی انجام نشده است.


## پیش‌نمایش زنده بازار در موبایل صفحه ورود — ۱۹ نوامبر ۲۰۲۶
- [x] قاب موبایل و نمودار کندل‌استیک کوچک داخل بخش تصویری صفحه ورود اضافه شد؛ داده‌ها از مسیر امن Edge Function موجود `market-data` درخواست می‌شوند.
- [x] نوار سه‌ارزی با چرخش خودکار BTC، ETH، SOL، BNB، XRP و ADA اضافه شد؛ قیمت‌ها از gateway موجود گرفته می‌شوند و داده ساختگی به‌عنوان قیمت واقعی نمایش داده نمی‌شود.
- [x] حالت تاریک برای فرم ورود نیز با selectorهای محدود به `#authView` اضافه شد؛ حالت روشن فعلی حفظ شده است.
- [ ] CI پس از این commit، بررسی بصری موبایل و تأیید عملکرد واقعی gateway در حالت خروج‌کرده هنوز لازم است.
- [ ] بنر ثابت و تبلیغ روزانه مدیرمحور معطل دسترسی خواندنی موفق به schema دیتابیس است؛ در این مرحله هیچ تغییری در Supabase Production انجام نشد.


## ادغام صفحه ورود آبی/سفید/طلایی و آغاز ساخت APK — ۱۹ نوامبر ۲۰۲۶
- [x] با تأیید صریح کاربر، PR شمارهٔ ۱۹ با روش squash ادغام شد: https://github.com/shahram-adim/DigiArz/pull/19
- [x] merge commit شاخهٔ main: `8d1bed4956c5ad3fd34eb572136d0237bf099343`؛ HEAD شاخهٔ main با همین SHA تطبیق داده شد.
- [x] CI پیش از ادغام برای شاخهٔ PR با run `44527138539` و نتیجهٔ `success` تکمیل شد.
- [x] با push به main، workflow ساخت APK با run `44527922677` آغاز شد؛ نتیجهٔ نهایی و artifact هنوز در انتظار است.
- [ ] workflow آزمون‌های Exact Decimal با run `44527922734` و GitHub Pages با run `44527921394` نیز هنگام ثبت این یادداشت در حال اجرا هستند.
- [!] صفحه ورود شامل تم آبی/سفید/طلایی و پیش‌نمایش زنده بازار است؛ سایر صفحات خارج از دامنه این تغییر باقی مانده‌اند.
- [!] بنر معرفی ثابت و تبلیغ روزانه قابل مدیریت از پنل مدیر هنوز پیاده‌سازی نشده‌اند؛ تلاش خواندن schema Supabase مجدداً با connection timeout مواجه شد. هیچ جدول، RLS، RPC، migration یا داده مالی در Production تغییر نکرده است.
- [ ] پس از اتمام build، artifact باید دریافت و محتویات APK و BUILD-INFO و SHA-256 بررسی شود؛ نصب و نمایش واقعی روی گوشی کاربر هنوز تأیید نشده است.


## نتیجه ساخت APK و انتشار وب پس از ادغام PR #19 — ۱۹ نوامبر ۲۰۲۶
- [x] workflow ساخت APK با run `44527922677` برای merge commit `8d1bed4956c5ad3fd34eb572136d0237bf099343` با نتیجهٔ `success` تکمیل شد.
- [x] artifact با نام `DigiArz-Android-debug-APK`، شناسهٔ `14532551419`، حجم ZIP برابر 3,506,268 بایت و انقضای 2026-12-03T12:53:35Z منتشر شد.
- [x] artifact دریافت و استخراج شد؛ شامل `app-debug.apk` با حجم 3,887,508 بایت و `BUILD-INFO.txt` است. صحت ساختار ZIP داخلی APK تأیید شد.
- [x] Build info commit را با merge commit main تطبیق می‌دهد؛ نسخه 1.0.0، run ID 44527922677 و SHA-256 APK برابر `43a40c5dcfb354ff39e7dc1e36cf35ff67d1dfb8b59b8d9cb128f627f7c49717` است.
- [x] Exact Decimal CI برای merge commit با run `44527922734` و نتیجهٔ `success` تکمیل شد.
- [x] اجرای Pages اولیه روی merge commit با run `44527921394` به علت اجرای انتشار بعدی لغو شد؛ اجرای جدید Pages برای commit مستندسازی `35103a53659ae5a74f28d873c3bcf1c26d319ae7` با run `44527984373` و نتیجهٔ `success` تکمیل شد. Exact Decimal CI برای همین commit مستندسازی نیز با run `44527985088` موفق شد.
- [!] بررسی ZIP و Build Info انجام شد؛ امضای Android و نصب/اجرای واقعی روی گوشی کاربر در این محیط تأیید نشده است.
- [ ] گام بعد: کاربر APK را روی Android نصب و صفحه ورود را بررسی کند؛ در صورت خطا screenshot یا متن خطا ارسال شود.
- [!] تبلیغات ثابت و روزانهٔ مدیرمحور همچنان باقی است و به خواندن schema و الگوی مجوزهای Supabase نیاز دارد؛ هیچ تغییر Production دیتابیس در این مرحله انجام نشده است.

## بازطراحی واقعی چیدمان صفحه ورود — ۱۹ نوامبر ۲۰۲۶
- [x] وضعیت واقعی main پیش از تغییر بررسی شد: HEAD برابر `fd275acbff1a1c57583bc9562cd62b24f3a3fbb0`؛ PR باز دیگری برای بازطراحی ورود وجود نداشت.
- [x] شاخهٔ مستقل `feat/login-screen-premium-layout` از همین HEAD ساخته شد؛ main تغییر نکرده است.
- [x] به صفحه ورود یک نوار معرفی برند و بازار زنده، سه شاخص کوتاه پلتفرم، و نوار کنترل تم روشن/تاریک اضافه شد.
- [x] چیدمان دسکتاپ و موبایل صفحه ورود بازآرایی شد؛ بخش بازار زنده، مزایا و فرم ورود در یک ترکیب بصری منسجم قرار گرفتند.
- [x] دکمهٔ تغییر تم در خود صفحه ورود به `applyTheme()` متصل شد و برچسب/آیکون آن با تم فعال هماهنگ می‌شود.
- [x] تمام تغییرات CSS جدید به صفحه ورود محدودند؛ شناسه‌های فرم ورود، ثبت‌نام، بازیابی رمز و پیش‌نمایش بازار حفظ شدند.
- [ ] آزمون CI، بررسی diff و ساخت APK هنوز باید انجام شوند؛ هیچ تغییری روی main یا Supabase Production اعمال نشده است.
- [!] تبلیغ روزانهٔ قابل مدیریت از پنل مدیر هنوز جداگانه نیازمند طراحی/تأیید ساختار داده و مجوزهاست؛ این تغییر UI هیچ جدول، RLS یا RPC جدیدی ایجاد نکرده است.
- گام بعد: اجرای CI و بازبینی PR؛ پس از تأیید، انتشار APK جدید و تست واقعی روی Android.


## ثبت وضعیت واقعی ادغام و ساخت APK — ۱۹ نوامبر ۲۰۲۶
- [x] وضعیت زندهٔ مخزن تأیید شد: شاخهٔ پیش‌فرض `main` و آخرین کامیت کد پیش از این ثبت وضعیت `9f80be997621ab5c60487fb7f29a0e18042441ab` است.
- [x] PR شمارهٔ ۲۰ با وضعیت `closed` و `merged=true` تأیید شد؛ merge commit برابر `9f80be997621ab5c60487fb7f29a0e18042441ab` است.
- [x] اجرای ساخت APK با run ID `44532653703` برای همین merge commit با نتیجهٔ `success` تکمیل شد؛ تمام گام‌های job از جمله `Build installable debug APK` و `Upload APK artifact` موفق‌اند.
- [x] Artifact با نام `DigiArz-Android-debug-APK`، شناسهٔ `14534407684`، اندازهٔ ZIP برابر 3,509,230 بایت و digest ثبت‌شدهٔ GitHub برابر `sha256:1929ed0569a478aa3a4be601bb33bec15ec30e198be2560e9a0d50bb6995feca` است؛ انقضا `2026-12-03T13:23:00Z`.
- [x] اجرای آزمون‌های Exact Decimal با run ID `44532653712` با نتیجهٔ `success` تکمیل شد؛ تمام گام‌های job از جمله آزمون‌های PostgreSQL موقت، Market/Limit، Stop-Limit، TP-SL و رقابت‌های هم‌زمان موفق‌اند.
- [!] این نتایج ساخت و CI را تأیید می‌کنند، نه نصب و اجرای APK روی گوشی کاربر؛ آزمایش واقعی Android هنوز منتظر بازخورد/تصویر کاربر است.
- [ ] گام بعد: نصب همین APK روی Android و بررسی بصری صفحهٔ ورود، ثبت‌نام و بازیابی رمز؛ در صورت بروز ایراد، ثبت تصویر یا متن خطا و اصلاح محدود به همان مورد.
- [!] در این مرحله هیچ تغییری در Supabase Production، schema، RPC مالی، Worker، migration یا داده‌های مالی انجام نشده است.
- [!] این ثبت وضعیت، یادداشت‌های قدیمی‌تر انتهای فایل را که PR #20 را ادغام‌نشده یا ساخت APK را در انتظار نشان می‌دادند، با نتیجهٔ واقعی و نهایی تکمیل می‌کند.


## طراحی و پیاده‌سازی تبلیغ روزانه تصویری — ۱۹ نوامبر ۲۰۲۶
- [x] وضعیت مبنا پیش از تغییر بررسی شد: آخرین commit ثبت‌شده روی main برابر `c11f4a7b342ebb452f81a02fc3b4fbe97255480a` است؛ تغییرات فقط روی شاخه مستقل `feat/admin-daily-image-ad` انجام می‌شوند.
- [x] نیازمندی کاربر ثبت شد: تبلیغ روزانه شامل عنوان، متن و تصویر باشد؛ هیچ لینک یا رفتار کلیکی نداشته باشد.
- [x] UI نمایش تبلیغ برای صفحه ورود و داشبورد اضافه شد؛ تصویر و متن با DOM امن نمایش داده می‌شوند و عنصر تبلیغ لینک نیست.
- [x] پنل مدیر ارشد برای بارگذاری تصویر JPG/PNG/WebP تا ۳ مگابایت، ثبت تبلیغ ۲۴ ساعته، فعال/غیرفعال‌سازی و حذف تبلیغ اضافه شد.
- [x] ماژول `src/daily-ads.js` و آزمون syntax/رفتار غیرقابل‌کلیک به `tests/index-syntax.test.js` اضافه شدند.
- [x] Service Worker به cache نسخه v57 ارتقا یافت و فایل جدید در پوسته آفلاین precache می‌شود.
- [x] بررسی فقط‌خواندنی Supabase در این مرحله: ۲۲ جدول عمومی؛ جدول `daily_ads` وجود ندارد؛ هیچ Storage bucket فعالی در فهرست `storage.buckets` برنگشت. تابع عمومی `public.is_current_user_super_admin()` برای نقش authenticated قابل اجراست و در طرح RLS استفاده می‌شود.
- [x] فایل طرح SQL در `supabase/drafts/daily_ads_and_storage.sql` ثبت شد: جدول، RLS، مجوزهای صریح Data API، bucket عمومی تصاویر و محدودیت upload/delete به مدیر ارشد.
- [!] به‌دلیل تغییر Supabase در ۲۰۲۶، جدول جدید در public نباید با فرض auto-exposure ساخته شود؛ طرح SQL مجوزهای Data API را صریحاً تعریف می‌کند.
- [!] فایل SQL عمداً در `supabase/drafts` باقی مانده است؛ هیچ migration، جدول، policy، bucket یا داده‌ای روی Supabase Production اعمال نشده است.
- [ ] اجرای CI، بازبینی diff و تأیید اینکه build وب/APK با ماژول جدید موفق است، در انتظار است.
- [ ] پس از CI و بازبینی، اجرای SQL روی Supabase Production فقط با تأیید جداگانه کاربر انجام می‌شود؛ سپس تبلیغ از پنل مدیر قابل استفاده خواهد بود.
- [!] بنر معرفی ثابت فعلی صفحه ورود (`auth-top-banner`) و اعلان بازار داشبورد موجودند و در این شاخه تغییر داده نشده‌اند؛ این PR فقط قابلیت تبلیغ روزانه تصویری را اضافه می‌کند.


### اصلاح پس از اولین اجرای CI — ۱۹ نوامبر ۲۰۲۶
- [x] اجرای اول workflow شماره `44541310349` بررسی شد: ۵۰ تست از ۵۲ تست موفق بود؛ دو شکست هر دو از آزمون قدیمی Service Worker بودند که هنوز تعداد فایل‌های پوسته را ۹ و cache قبلی را تا v55 انتظار داشت.
- [x] آزمون Service Worker با نسخه v57 هماهنگ شد: تعداد فایل‌ها ۱۰، precache ماژول `src/daily-ads.js` و حذف cache قدیمی v56 نیز بررسی می‌شود.
- [x] اجرای مجدد CI پس از این اصلاح با run `44541617563` موفق شد؛ جزئیات نتیجه در بخش «نتیجه CI و بازبینی PR تبلیغ روزانه» ثبت شده است.

### نتیجه CI و بازبینی PR تبلیغ روزانه — ۱۹ نوامبر ۲۰۲۶
- [x] اجرای مجدد workflow با run ID `44541617563` روی آخرین commit شاخه، `f15ad7d90367ffbe831ba74b2d67f5fe76182278`، با نتیجهٔ `success` تکمیل شد.
- [x] هر ۴۳ مرحلهٔ job با موفقیت پایان یافت؛ مرحلهٔ اجرای `node --test tests/*.test.js` و مراحل PostgreSQL موقت/ایزوله نیز موفق بودند.
- [x] دو انتظار قدیمی Service Worker در تست‌ها اصلاح شده‌اند: تعداد فایل‌های precache برابر ۱۰، حضور `src/daily-ads.js` و پاک‌سازی cache نسخهٔ v56.
- [x] مقایسهٔ شاخه با `main` نشان داد ۹ commit جلوتر و صفر commit عقب‌تر است؛ تغییرات به ۷ فایل محدودند: وضعیت پروژه، index، ماژول تبلیغ، طرح SQL در drafts، Service Worker و دو فایل آزمون.
- [x] بازبینی کد تبلیغ و طرح SQL انجام شد: نمایش عمومی فقط تبلیغ فعال در بازهٔ زمانی؛ مدیریت ردیف‌ها و بارگذاری/حذف تصویر محدود به super-admin از طریق RLS؛ تصویر عمومی و بدون anchor یا href در UI.
- [x] هیچ review thread یا review ثبت‌شده‌ای برای PR وجود ندارد.
- [!] workflow موفق، آزمون‌های CI را تأیید می‌کند؛ build/deploy وب یا APK و نصب واقعی Android از این اجرای PR نتیجه‌گیری نمی‌شود.
- [!] PR شمارهٔ ۲۱ همچنان Draft و ادغام‌نشده است. هیچ SQL، جدول، policy، bucket یا داده‌ای روی Supabase Production اعمال نشده است.
- [ ] گام بعدی: تصمیم جداگانهٔ کاربر برای آماده‌کردن PR جهت ادغام؛ اجرای SQL روی Supabase Production نیز فقط با مجوز صریح و رعایت شرط پشتیبان کامل و قابل‌بازیابی انجام می‌شود.


## نتیجهٔ ادغام تبلیغ روزانه — ۱۹ نوامبر ۲۰۲۶
- [x] با تأیید صریح کاربر، PR شمارهٔ ۲۱ با روش squash در شاخهٔ `main` ادغام شد: https://github.com/shahram-adim/DigiArz/pull/21
- [x] GitHub ادغام موفق را گزارش کرد؛ SHA کامیت squash برابر `56e4569692345d0a8f18f7bec4b8a4e3858b06bf` است.
- [x] CI روی head پیش از ادغام، `97df5f51bc9a0fb9030ef17862ec67c3e6b9e591`، با run ID `44542093572` و نتیجهٔ `success` تکمیل شد؛ هر ۴۳ مرحله موفق بودند.
- [x] PR پیش از ادغام Ready for review بود؛ هیچ review یا review thread ثبت نشده بود و مقایسهٔ شاخه با main برابر ۱۱ commit جلوتر و صفر عقب‌تر بود.
- [!] این ادغام فقط کد برنامه و فایل draft SQL را وارد main کرد؛ SQL روی Supabase Production اجرا نشده و جدول `daily_ads` و Storage bucket هنوز ایجاد نشده‌اند.
- [!] CI موفق به معنی deploy نهایی، ساخت APK جدید، یا نصب و آزمایش روی Android نیست.
- [ ] گام بعدی: بررسی CI و ساخت APK پس از ادغام؛ سپس برای اجرای SQL و ایجاد جدول/bucket در Supabase Production، تأیید جداگانهٔ کاربر اخذ شود.


## تأیید نهایی پس از ادغام تبلیغ روزانه و بررسی مانع بکاپ — ۱۹ نوامبر ۲۰۲۶
- [x] HEAD شاخه main بررسی شد: `3d250b8579a5b68809b12bc49d5eb322e600de55`.
- [x] اجرای ساخت APK پس از ادغام PR #21 با run `44542611200` و نتیجه success تأیید شد.
- [x] Artifact با نام `DigiArz-Android-debug-APK`، شناسه `14538493781`، حجم ZIP برابر 3,513,866 بایت و SHA-256 برابر `029baa0b03c25fe10f9e380bd87914244b9c98cba6f0dfc59157ca7d972a9598` ثبت شد؛ انقضا 2026-12-03T14:21:38Z.
- [x] آزمون Exact Decimal پس از ادغام با run `44542670717` و نتیجه success تأیید شد.
- [x] انتشار GitHub Pages پس از ادغام با run `44542670453` و نتیجه success تأیید شد.
- [x] طرح SQL تبلیغات و ماژول `src/daily-ads.js` در main بازخوانی شدند؛ مسیر فایل تصویر در کد با bucket و قید مسیر SQL تطبیق دارد.
- [!] ابزارهای متصل Supabase در این نشست endpoint مدیریت بکاپ را ارائه نمی‌کنند؛ هیچ بکاپ کامل/قابل‌بازیابی از طریق ابزارها ایجاد یا تأیید نشد. مستندات رسمی Supabase وجود Management API برای فهرست‌کردن بکاپ‌ها را تأیید می‌کند، اما دسترسی لازم و ابزار فراخوانی آن در اتصال فعلی حاضر نیست.
- [!] هیچ SQL، migration، جدول، policy یا bucket روی Supabase Production اجرا نشد. کد تبلیغات در main است، اما تا تأیید بکاپ امن، قابلیت تبلیغ در محیط اصلی فعال‌شدنی نیست.
- [!] موفقیت Build/CI/Pages به معنی نصب یا آزمایش APK روی گوشی Android کاربر نیست.
- گام بعد: پس از فراهم‌شدن بکاپ دیتابیس قابل‌بازیابی و حفاظت جداگانه از اشیای Storage، اجرای migration تبلیغات و آزمون مجوزهای super-admin و نمایش عمومی.


## پیاده‌سازی واقعی سه تم DigiArz — ۱۹ نوامبر ۲۰۲۶
- [x] پیش از تغییر، وضعیت main، PRهای #22 و #23، شاخه‌های موجود و کد واقعی پوسته بررسی شدند؛ تغییر فقط روی شاخه مستقل feat/three-theme-system انجام شده است.
- [x] سه گزینه واقعی «روشن»، «تاریک» و «لوکس شیشه‌ای» به تنظیمات پوسته اضافه شدند؛ کنترل بالای صفحه و کنترل صفحه ورود نیز با چرخه سه‌حالته کار می‌کنند.
- [x] انتخاب هر تم در localStorage با کلید digiArzTheme ذخیره و در بارگذاری بعدی بازیابی می‌شود؛ مقدارهای قدیمی light و dark بدون مهاجرت یا reset حفظ می‌شوند.
- [x] تم لوکس با پالت سرمه‌ای/آبی نفتی، آبی فیروزه‌ای، طلایی شامپاینی، پنل‌های شیشه مات، مرزهای ظریف و سایه‌های نرم در صفحه ورود و اجزای اصلی برنامه اعمال شده است.
- [x] برای نمودارهای موجود رنگ پس‌زمینه، متن و grid متناسب با هر سه تم تنظیم می‌شود؛ مسیر قیمت زنده و منطق معاملات تغییر نکرده‌اند.
- [x] fallback برای مرورگر فاقد backdrop-filter و رعایت prefers-reduced-motion اضافه شد؛ چیدمان انتخاب تم در موبایل واکنش‌گراست.
- [x] تست رگرسیون برای سه گزینه، کلاس تم لوکس، ذخیره‌سازی، سازگاری مقادیر قدیمی، fallback شیشه‌ای و کاهش حرکت اضافه شد.
- [!] تغییر فقط در شاخه مستقل است؛ هنوز CI و بازبینی نهایی GitHub اجرا/تأیید نشده و هیچ ادغامی در main انجام نشده است.
- [!] هیچ فایل migration، schema، RPC، تنظیم Auth یا داده‌ای در Supabase Production تغییر نکرده است.
- گام بعد: اجرای CI روی PR، رفع هر شکست و بررسی diff؛ ادغام فقط پس از تأیید صریح کاربر.


## نتیجهٔ ادغام تم سوم لوکس — ۱۹ نوامبر ۲۰۲۶
- [x] با تأیید صریح کاربر، PR شمارهٔ ۲۴ با روش squash در شاخهٔ main ادغام شد: https://github.com/shahram-adim/DigiArz/pull/24
- [x] GitHub ادغام موفق را گزارش کرد؛ PR بسته و merged است. SHA کامیت ادغام: f4458ac1a31109794b5e5d8dab8a0a046111569f.
- [x] آخرین head پیش از ادغام برابر 8735c2494ad5a3b153595d4544f7022b3795ca83 بود؛ PR قابل ادغام و غیر Draft بود.
- [x] اجرای CI روی آخرین head پیش از ادغام، run شمارهٔ 44552009871، با نتیجهٔ success تکمیل شد.
- [x] فایل index، تست‌های رگرسیون سه تم و این فایل وضعیت در PR تغییر کرده بودند؛ تغییرات Production در Supabase صفر است.
- [!] موفقیت CI روی PR به‌تنهایی اثبات ساخت APK جدید، انتشار وب یا نصب/آزمایش روی گوشی Android نیست.
- گام بعد: بررسی اجرای workflowهای پس از ادغام روی main و در صورت وجود، تأیید build و انتشار؛ هیچ تغییری در Supabase Production بدون تأیید جداگانه انجام نشود.

- [x] پس از ادغام، GitHub Pages روی commit ثبت وضعیت `09ecd7753749fb10f61d5f3ed85c7902ec56b78e` با run شمارهٔ `44552530581` و نتیجهٔ success build و deploy شد.
- [x] آزمون‌های Exact Decimal روی commit ادغام `f4458ac1a31109794b5e5d8dab8a0a046111569f` با run شمارهٔ `44552473905` و نتیجهٔ success تکمیل شدند؛ آزمون‌های browser integration، PostgreSQL arithmetic، Market/Limit، Stop-Limit، TP-SL و رقابت‌های هم‌زمان موفق بودند.
- [!] ساخت APK پس از ادغام با run شمارهٔ `44552473513` آغاز شده است؛ مراحل آماده‌سازی Capacitor و Android موفق‌اند، اما مرحلهٔ Gradle build هنوز در حال اجراست و artifact هنوز منتشر نشده است. این مورد تا تأیید نتیجهٔ نهایی باز می‌ماند.
- [!] اجرای مجدد Exact Decimal روی commit مستندسازی `09ecd7753749fb10f61d5f3ed85c7902ec56b78e` با run شمارهٔ `44552531392` هنگام ثبت این یادداشت هنوز در حال اجرا بود.

- [x] نتیجهٔ نهایی APK پس از ادغام: workflow شمارهٔ `44552473513` روی main و commit ادغام `f4458ac1a31109794b5e5d8dab8a0a046111569f` با conclusion برابر success پایان یافت؛ همهٔ ۱۴ مرحله از جمله Gradle build، ثبت provenance و upload artifact موفق شدند.
- [x] Artifact با نام `DigiArz-Android-debug-APK` و شناسهٔ `14543883204` ساخته شد؛ حجم ZIP برابر 3,516,563 بایت، SHA-256 برابر `1b771edb0ee5e7a5e188f2aa7bcffe11df96bd16d5e6276439f2983c81688583` و انقضا `2026-12-03T15:15:44Z` است.
- [x] محتوای ZIP بررسی شد: فایل `app-debug.apk` با حجم 3,897,200 بایت و `BUILD-INFO.txt` وجود دارند. SHA-256 فایل APK برابر `50ccfcac17653cbfcb47b4fca99864c1c87f216c0ab523fdb2f88d48aab80897` است. مشخصات build: package version 1.0.0، ref برابر main.
- [x] اجرای دوم Exact Decimal روی commit ثبت وضعیت `09ecd7753749fb10f61d5f3ed85c7902ec56b78e` با run شمارهٔ `44552531392` نیز success شد.
- [!] APK با موفقیت ساخته و artifact آن دانلود و محتویاتش بررسی شده است؛ هنوز روی گوشی Android کاربر نصب یا آزمایش نشده است.


## بازطراحی صحنه سه‌بعدی صفحه ورود — ۱۹ نوامبر ۲۰۲۶
- [x] وضعیت مبنا پیش از تغییر بررسی شد: شاخه `main` روی commit `b873fb22be5a5a6db2ca6a4fe0e38372f9f238f4` بود؛ تغییرات فقط در شاخه مستقل `feat/login-hero-premium-visual` انجام می‌شوند.
- [x] صحنه صفحه ورود بازطراحی شد: کره زمین SVG با گرادیان، سایه کروی، خطوط طول و عرض و حلقه‌های مداری مستقل از موبایل قرار گرفت تا پشت بدنه گوشی پنهان نشود.
- [x] قاب موبایل با فریم فلزی، لبه‌های جانبی، شیشه تیره، عمق و سایه طبیعی اضافه شد؛ چیدمان موبایل واکنش‌گراست.
- [x] سکه‌های شناور BTC/ETH/BNB و ردیف دارایی‌های متحرک از لوگوهای تصویری CoinCap استفاده می‌کنند؛ fallback متنی فقط در صورت شکست بارگذاری تصویر نمایش داده می‌شود.
- [x] نمودار کوچک صفحه ورود از وابستگی مستقیم به Lightweight Charts جدا شد و کندل‌های واقعی ۵ دقیقه‌ای را با SVG بومی رسم می‌کند؛ در صورت نبود داده، پیام وضعیت به‌جای پنل خالی نمایش داده می‌شود.
- [x] منبع کندل و قیمت همچنان دروازه بازار DigiArz از Supabase است؛ هیچ تغییری در مسیر قیمت‌گذاری معاملات یا منطق مالی ایجاد نشده است.
- [x] نسخه cache پوسته Service Worker به v58 ارتقا یافت تا فایل صفحه ورود به‌روزرسانی‌شده روی دستگاه‌های دارای cache قدیمی نمایش داده شود.
- [x] آزمون‌های رگرسیون برای صحنه، لوگوهای تصویری و نمودار SVG افزوده/به‌روزرسانی شدند.
- [!] تغییرات هنوز روی شاخه مستقل‌اند؛ تا پایان اجرای CI، بازبینی diff و ساخت APK جدید، ادغام در main انجام نمی‌شود.
- [!] هیچ تغییر دیتابیس، RPC، migration، Storage، تنظیمات Auth یا داده‌ای در Supabase Production انجام نشده است.
- گام بعد: اجرای کامل `node --test tests/*.test.js`، workflowهای CI، بازبینی PR و ساخت APK؛ سپس ارائه نتیجه و درخواست تأیید جداگانه برای ادغام.


### اصلاح آزمون cache پس از اجرای اول CI — ۱۹ نوامبر ۲۰۲۶
- [x] اجرای PR #26 نشان داد ۵۴ تست موفق و فقط آزمون activation مربوط به Service Worker ناموفق بود؛ علت این بود که فهرست cacheهای قدیمی در harness تست هنوز v57 را شبیه‌سازی نمی‌کرد، با اینکه انتظار پاک‌سازی v57 به‌روزرسانی شده بود.
- [x] فهرست cacheهای harness به v57 هم گسترش یافت؛ منطق Service Worker و کد برنامه تغییری نکرد.
- [ ] اجرای مجدد CI برای تأیید اصلاح در انتظار است.


### نتیجه اجرای مجدد CI برای PR #26 — ۱۹ نوامبر ۲۰۲۶
- [x] پس از اصلاح fixture کش، workflow با run ID `44589241911` روی commit `e2fae7db30729339e64032aebc796ec7948ac133` با نتیجهٔ `success` پایان یافت.
- [x] تمام مراحل ۲۴گانه موفق شدند؛ از جمله `node --test tests/*.test.js)، PostgreSQL arithmetic، rehearsal افزایش دقت، تست‌های RPC/worker و رقابت‌های هم‌زمان Limit، TP-SL و Stop-Limit.
- [x] خطای اجرای اول صرفاً از fixture آزمون cache بود؛ در کد Service Worker و برنامه نیازی به اصلاح اضافی نبود.
- [!] PR #26 هنوز Draft و ادغام‌نشده است؛ تغییرات روی main و نسخه منتشرشده قرار نگرفته‌اند.
- [ ] گام بعد: دریافت تأیید صریح کاربر برای آماده‌سازی/ادغام PR؛ پس از ادغام، workflow ساخت APK و انتشار وب را جداگانه بررسی و نتیجه را ثبت کن.



## نتیجه ادغام صحنه سه‌بعدی صفحه ورود — ۱۹ نوامبر ۲۰۲۶
- [x] با تأیید صریح کاربر، PR شمارهٔ ۲۶ با روش squash در شاخهٔ `main` ادغام شد: https://github.com/shahram-adim/DigiArz/pull/26
- [x] GitHub ادغام موفق را تأیید کرد؛ commit نهایی `b3a4f7eb0a0c854eea0627678f4b209d0aeb4a67` است و HEAD شاخهٔ main نیز همین commit شد.
- [x] PR بسته و merged است؛ تغییرات شامل صحنه کره زمین مستقل، قاب موبایل فلزی، لوگوهای تصویری BTC/ETH/BNB، نمودار زنده SVG و cache نسخهٔ v58 هستند.
- [x] CI روی شاخهٔ PR پس از اصلاح fixture با run شمارهٔ `44589241911` و نتیجهٔ success تکمیل شد؛ تمام ۲۴ مرحله موفق بودند. Exact Decimal روی head نهایی PR نیز با run شمارهٔ `44589595709` موفق شد.
- [x] workflowهای پس از ادغام روی main آغاز شدند: Android APK با run `44589924278`، Exact Decimal با run `44589924247` و GitHub Pages با run `44589923555`.
- [!] هنگام ثبت این یادداشت، build APK و Exact Decimal در حال اجرا و Pages در صف انتظار هستند؛ نتیجهٔ نهایی و artifact APK هنوز تأیید نشده‌اند.
- [!] هیچ schema، migration، RPC، Auth، کیف پول یا داده‌ای در Supabase Production تغییر نکرده است.
- [ ] گام بعد: بررسی نتیجهٔ نهایی هر سه workflow روی main؛ در صورت موفقیت APK، دریافت شناسه و مشخصات artifact و ثبت نتیجه در همین فایل. نصب و آزمایش واقعی روی گوشی Android همچنان نیازمند کاربر است.



## نتیجه نهایی انتشار APK پس از ادغام PR #26 — ۱۹ نوامبر ۲۰۲۶
- [x] workflow اندروید روی commit ادغام‌شده `b3a4f7eb0a0c854eea0627678f4b209d0aeb4a67` با run شمارهٔ `44589924278` با نتیجهٔ success تکمیل شد.
- [x] فایل APK با موفقیت ساخته و به‌عنوان Artifact بارگذاری شد: `DigiArz-Android-debug-APK`، حجم 3,520,541 بایت (حدود 3.52 MB).
- [x] شناسهٔ Artifact: `14563841548`؛ SHA-256: `da073c5f35392764e7d175345961e2e5641a40e27d0aa74013eea89e1f7587b4`؛ زمان انقضای Artifact: `2026-12-03T18:39:53Z`.
- [x] آزمون‌های Exact Decimal روی commit ادغام‌شده با run شمارهٔ `44589924247` موفق شدند.
- [x] انتشار GitHub Pages روی commit ادغام‌شده با run شمارهٔ `44589923555` موفق شد.
- [!] APK از نوع Debug است؛ هنوز نصب و اجرای واقعی روی دستگاه Android کاربر تأیید نشده است. این Artifact از صفحهٔ run مربوط به APK قابل دریافت است.
- [ ] گام بعد: کاربر APK را از GitHub Actions دریافت و روی گوشی نصب کند؛ سپس ورود، نمایش کره و موبایل، لوگوها و نمودار بازار بررسی شوند. هر ایراد مشاهده‌شده جداگانه ثبت و اصلاح شود.


## بازسازی وفادار صفحه ورود بر اساس تصویر مرجع — ۱۹ نوامبر ۲۰۲۶
- [x] مشکل گزارش‌شده از کاربر: کره زمین به‌تنهایی ناپدید می‌شد؛ طرح قبلی نیز با تصویر مرجع تطابق نداشت.
- [x] تصویر مرجع واقعی approved-login-design.jpg دوباره بررسی شد؛ ترکیب هدف شامل لوگوی طلایی DA و DigiArz، نشان بازار زنده، تیتر سمت چپ، فهرست BTC/ETH/USDT/SOL، کره نورانی، موبایل مورب، سکه‌های طلایی، فرم ورود پایین صفحه و بنر روزانه است.
- [x] شاخهٔ مستقل feat/login-reference-faithful-rebuild از main ساخته شد؛ هیچ تغییری هنوز وارد main نشده است.
- [x] بخش معرفی صفحه ورود و CSS آن در index.html بازسازی شد: طرح تمام‌عرض عمودی، چیدمان دو ستونه معرفی/صحنه، کره SVG بزرگ با visibility و opacity ثابت و بدون انیمیشن شناور، موبایل مورب، سکه‌های فلزی، چهار ردیف رمزارز و فرم سرمه‌ای/طلایی.
- [x] فهرست سمت چپ از دادهٔ ticker زنده برای BTC/ETH/SOL استفاده می‌کند؛ USDT به‌عنوان دارایی پایدار با تغییر ۰٫۰٪ نمایش داده می‌شود. نمودار زنده و قیمت‌های داخل موبایل از منطق قبلی حفظ شده‌اند.
- [x] کنترل‌های ورود، ثبت‌نام، بازیابی رمز عبور و شناسه‌های DOM موجود حفظ شده‌اند؛ هیچ منطق Supabase، کیف پول، سفارش یا معاملات تغییر نکرد.
- [ ] هنوز build/CI و بررسی بصری روی viewport واقعی Android اجرا/تأیید نشده‌اند؛ نتیجه نباید به‌عنوان طرح نهایی تأییدشده تلقی شود.
- [ ] گام بعد: اجرای آزمون‌ها و workflowهای Android/Pages؛ سپس نمایش پیش‌نمایش/نسخه آزمایشی به کاربر برای بررسی روی گوشی. فقط پس از تأیید صریح کاربر PR به main ادغام شود و APK تازه ساخته شود.


### هماهنگ‌سازی آزمون‌های رگرسیون با طرح مرجع جدید — ۱۹ نوامبر ۲۰۲۶
- [x] اجرای PR #27 نشان داد ۵۳ تست از ۵۵ تست موفق‌اند؛ دو شکست صرفاً از matcherهای قدیمی در `tests/index-syntax.test.js` بود که به کلاس‌های حذف‌شدهٔ طرح قبلی (`auth-quick-stats` و `auth-scene` مستقل) وابسته بودند.
- [x] آزمون‌های هدر/بازار به نشان زنده و فهرست چهار دارایی طرح مرجع تغییر کردند؛ آزمون صحنه نیز کره، گوشی و سکه‌های ساختار جدید را مستقیماً بررسی می‌کند.
- [x] اصلاح فقط در فایل تست و روی شاخهٔ مستقل `feat/login-reference-faithful-rebuild` ثبت شد؛ commit: `02e6ba0a921fb0b128b11c847badffca0cb86abc`.
- [ ] اجرای مجدد CI برای تأیید اصلاح هنوز در انتظار نتیجه است؛ تا موفقیت کامل، ساخت APK و ادغام انجام نشود.
- [!] هیچ تغییری در `main`، منطق برنامه، Supabase، ورود، کیف پول یا معاملات ایجاد نشده است.


### نتیجه نهایی اجرای CI پس از اصلاح آزمون‌ها — ۱۹ نوامبر ۲۰۲۶
- [x] اجرای GitHub Actions با شمارهٔ `44594127811` / Run #914 برای commit `577da09fb157307440c85a08b1f55308bb262e84` با نتیجهٔ نهایی `success` تمام شد.
- [x] آزمون‌های exact-decimal و browser integration، PostgreSQL arithmetic، preflight و rollback/lock-timeout، Market/Limit، Stop-Limit، TP-SL، چرخهٔ لغو سفارش و تست‌های race واقعی دو نشست همگی موفق شدند.
- [x] اصلاح دو matcher قدیمی آزمون‌های صفحه ورود اکنون در CI سبز تأیید شد.
- [ ] هنوز build اختصاصی Android/Pages برای این PR و بررسی ظاهری روی دستگاه واقعی کاربر تأیید نشده است؛ این نتیجهٔ CI به‌تنهایی APK یا تطابق پیکسلی با تصویر مرجع را اثبات نمی‌کند.
- [ ] PR #27 همچنان باز است؛ ادغام در main فقط پس از تأیید صریح کاربر مجاز است.


## نتیجه ادغام بازسازی وفادار صفحه ورود — ۱۹ نوامبر ۲۰۲۶
- [x] با تأیید صریح کاربر، PR شمارهٔ ۲۷ با روش squash در شاخهٔ `main` ادغام شد: https://github.com/shahram-adim/DigiArz/pull/27
- [x] GitHub ادغام موفق را تأیید کرد؛ SHA کامیت ادغام: `c627cde5fa5298fd57d5ead7baf3cd4a069db4f3`. PR بسته و merged است.
- [x] آخرین head پیش از ادغام `1b746f81d06f54b5cbc779de9e31c74ac7591ce0` بود. CI کامل Run #914 روی commit کد `577da09fb157307440c85a08b1f55308bb262e84` با نتیجهٔ success تمام شد؛ commit نهایی پیش از ادغام صرفاً ثبت همین نتیجه در فایل وضعیت بود.
- [x] Run #915 با نتیجهٔ success روی commit مستندسازی نهایی اجرا شد.
- [x] تغییرات شامل بازسازی صفحه ورود مطابق تصویر مرجع، کرهٔ SVG پایدار، موبایل مورب، سکه‌ها، فهرست BTC/ETH/USDT/SOL و حفظ کنترل‌های ورود/ثبت‌نام/بازیابی است.
- [!] ساخت APK جدید پس از این ادغام هنوز تأیید نشده است؛ موفقیت CI قبلی به معنی ساخت APK یا تست بصری روی گوشی نیست.
- [!] بررسی بصری روی دستگاه Android کاربر همچنان باز است؛ تطابق پیکسلی با تصویر مرجع ادعا نمی‌شود.
- [x] هیچ migration، schema، RPC، تنظیم Auth، کیف پول یا داده‌ای در Supabase Production تغییر نکرده است.
- گام بعد: بررسی اجرای workflowهای پس از ادغام روی main؛ در صورت موفقیت، ثبت artifact APK و ارائه مسیر دریافت. سپس کاربر نسخه را روی Android نصب و نمایش کره، موبایل، سکه‌ها و فرم ورود را بررسی کند.


## نتیجه نهایی ساخت APK پس از ادغام PR #27 — ۱۹ نوامبر ۲۰۲۶
- [x] workflow اندروید Run #66 با شناسهٔ `44594707273` روی commit ادغام `c627cde5fa5298fd57d5ead7baf3cd4a069db4f3` با نتیجهٔ `success` تکمیل شد.
- [x] تمام مراحل job ساخت اندروید موفق شدند؛ از جمله نصب وابستگی‌ها، آماده‌سازی assets وب، تولید و همگام‌سازی پروژه Android، ساخت Gradle، ثبت provenance و بارگذاری artifact.
- [x] Artifact با نام `DigiArz-Android-debug-APK` و شناسهٔ `14564697948` بارگذاری شد؛ حجم ZIP برابر 3,523,702 بایت و SHA-256 آرشیو برابر `7a16596d2fb6cd3c9d689e4a34b8ce34da734826b50b6d56fae21c5c964a9c3e` است.
- [x] لینک دریافت artifact: https://github.com/shahram-adim/DigiArz/actions/runs/44594707273 (اعتبار تا 2026-12-03T19:07:04Z).
- [!] فایل APK از نوع Debug است؛ هنوز نصب و اجرای واقعی روی دستگاه Android کاربر و بررسی بصری کره، موبایل، سکه‌ها و فرم ورود تأیید نشده است.
- [x] هیچ تغییر تازه‌ای در Supabase Production انجام نشد.
- [ ] گام بعد: کاربر artifact را از صفحهٔ اجرای workflow دانلود، ZIP را استخراج و `app-debug.apk` را نصب کند؛ سپس نتیجهٔ نصب و تصویر صفحه ورود را برای بررسی ظاهری گزارش دهد.


## انتشار لینک مستقیم APK — ۱۹ نوامبر ۲۰۲۶
- [x] workflow اندروید Run #67 با شناسهٔ `44596189517` روی commit `0b640b8538283ff3bf899d52257a5b4655a7b6a5` با نتیجهٔ نهایی `success` تکمیل شد.
- [x] تمام مراحل ساخت موفق شدند: Gradle build، ثبت provenance، بارگذاری artifact و انتشار مستقیم APK در GitHub Releases.
- [x] Release با تگ `android-debug-67` و عنوان `DigiArz Android Debug APK (Build 67)` ایجاد شد: https://github.com/shahram-adim/DigiArz/releases/tag/android-debug-67
- [x] فایل مستقیم `app-debug.apk` با حجم 3,905,016 بایت و نوع `application/vnd.android.package-archive` منتشر شد.
- [x] لینک مستقیم تأییدشده: https://github.com/shahram-adim/DigiArz/releases/download/android-debug-67/app-debug.apk
- [!] این APK از نوع Debug/test است و هنوز نصب و اجرای واقعی آن روی گوشی Android کاربر تأیید نشده است.
- [x] هیچ تغییری در Supabase Production انجام نشد.
- [ ] گام بعد: نصب APK روی Android و بررسی بازشدن برنامه، ورود و نمایش صحیح صحنهٔ صفحه ورود؛ هر ایراد مشاهده‌شده جداگانه ثبت شود.


## پایش شبانهٔ Auth/pg_cron و تطبیق schedule زنده — ۲۰ نوامبر ۲۰۲۶
- [x] وضعیت تازهٔ GitHub بررسی شد: HEAD پیش از این ثبت `b59a85370ffff91447629d4bbfaf77ada5797b96` بود. Exact Decimal روی main با run `44596513481` و GitHub Pages با run `44596512278` هر دو success هستند.
- [x] APK آزمایشی مستقیم Build 67 با run `44596189517` موفق شد؛ Release `android-debug-67` و لینک مستقیم آن ثبت شده‌اند. این فایل Debug است و نصب واقعی روی Android هنوز تأیید نشده است.
- [x] PR #30 با عنوان بازطراحی یکپارچهٔ UI همچنان Draft و ادغام‌نشده است؛ head برابر `30dac3a0271148a9cb6103188b35bbfb5bc9bd13`، 18 commit جلو، 7 فایل تغییرکرده، 580 addition و 5 deletion. Exact Decimal برای head آن با run `44617266637` موفق است؛ اجرای Android/Pages برای همین head در snapshot حاضر دیده نشد. هیچ ادغامی انجام نشد.
- [x] Supabase همچنان `ACTIVE_HEALTHY` و PostgreSQL `17.11.0.018` است. Health Advisor بدون یافته؛ Security: 15 جدول RLS فعال بدون policy، 2 تابع SECURITY DEFINER قابل اجرا برای anon، 23 برای authenticated و 1 هشدار حفاظت رمزهای افشاشده؛ Performance: 9 FK بدون ایندکس پوششی، 11 هشدار RLS initplan و 7 ایندکس استفاده‌نشده.
- [!] snapshot 24 ساعتهٔ `cron.job_run_details` (حدود 2026-11-19 23:05 UTC):
  - job 13: 67 موفق، 73 ناموفق؛ تمام 73 مورد startup timeout؛ آخرین موفقیت 23:00:00Z و آخرین شکست 22:31:27Z.
  - job 14: 563 موفق، 136 ناموفق؛ 106 startup timeout و 30 statement timeout؛ median اجرای موفق 19.66 ثانیه؛ آخرین موفقیت 23:01:16Z و آخرین شکست 22:31:41Z.
  - job 17: 74 موفق، 67 ناموفق؛ تمام 67 مورد startup timeout؛ آخرین موفقیت 23:05:00Z و آخرین شکست 21:55:10Z.
- [!] در unified logs همان بازهٔ 24 ساعته، 640 رویداد `could not accept SSL connection: Connection reset by peer`، تعداد 106 رویداد `EOF detected`، تعداد 226 رویداد `canceling statement due to statement timeout` و 23 رویداد PgBouncer `connect timeout` دیده شد. startup timeout هم‌زمان در چند job دیگر (از جمله 2، 3، 4، 8، 9، 11، 12، 15، 16 و 18) نیز ثبت شده است. این‌ها شمارش رویدادهای log هستند و لزوماً معادل اجرای یکتای cron نیستند.
- [!] خطاهای SSL و startup در چند job مستقل، فرضیهٔ اختلال گسترده‌تر در اتصال/پاسخ‌گویی PostgreSQL را تقویت می‌کنند؛ اما علت host-level یا resource bottleneck اثبات نشده است. timeoutهای providerهای بازار نیز جداگانه ثبت شده‌اند و نباید بدون شواهد به Auth نسبت داده شوند.
- [x] snapshot لحظه‌ای `pg_stat_activity` فقط 7 backend (2 active، 4 idle و 1 با state تهی) از سقف `max_connections=60` نشان داد؛ این snapshot کوتاه‌مدت، فشار گذرای ساعاتی قبل را رد نمی‌کند.
- [!] زمان‌بندی زنده با منبع local تفاوت دارد: job 14 اکنون `1-59/10 * * * *` است، ولی migration محلی `20261117130000...` مقدار `* * * * *` را ثبت می‌کند. همچنین remote version `20261116205451` است و source file با همین نسخه در migrations محلی موجود نیست. جزئیات در `supabase/MIGRATION_RECONCILIATION.md` ثبت شد.
- [!] inventory مهاجرت هنوز 52 نسخهٔ اعمال‌شده در Supabase در برابر 40 فایل محلی، 14 source مفقود، 20 timestamp متفاوت و 2 فایل local-only را نشان می‌دهد. اجرای `supabase db push` همچنان ممنوع است.
- [x] هیچ migration، تابع، grant، policy، cron schedule، index، سفارش، معامله، رزرو، موجودی، کیف پول یا سابقهٔ مالی در Production تغییر نکرد. تمام پرس‌وجوهای Supabase فقط‌خواندنی بودند.
- [ ] گام بعد: منشأ تغییر schedule job 14 را از audit/deployment record معتبر بازیابی کن؛ سپس drift را فقط در منبع و PostgreSQL 17 دورریختنی reconciliate کن. هم‌زمان شواهد SSL reset و startup timeout را با Supabase Support و resource metrics تطبیق بده؛ تا اثبات علت، تابع/timeout/cron Production را تغییر نده.

## بازبینی مجوز دو RPC عمومی بازار — ۲۰ نوامبر ۲۰۲۶

- [x] آخرین وضعیت واقعی main پیش از این بررسی خوانده شد: `af0022d2ee887fe101a2403b9d7d2c8f0b1fad4b`؛ فایل وضعیت، ماتریس QA، ساختار UI و وضعیت Supabase بازخوانی شدند.
- [x] Supabase در وضعیت `ACTIVE_HEALTHY` و PostgreSQL `17.11.0.018` است؛ ۲۲ جدول عمومی، ۵۲ migration ثبت‌شده، ۸ Edge Function فعال و صفر Development Branch مشاهده شد.
- [x] Security Advisor snapshot در `2026-11-20T10:58:49Z`: ۱۵ جدول RLS-enabled بدون policy، دو تابع SECURITY DEFINER قابل اجرا برای anon، ۲۳ تابع قابل اجرا برای authenticated و هشدار غیرفعال‌بودن leaked-password protection.
- [x] بدنه و ACL زندهٔ `get_admin_market_listings()` و `get_exchange_discovered_market_assets()` با `pg_get_functiondef` و `has_function_privilege` بررسی شد. هر دو `STABLE SECURITY DEFINER` با `search_path` خالی و مالک postgres هستند؛ شمارش catalog با Advisor هم‌خوان بود.
- [x] هر دو تابع فقط metadata عمومی بازار/کشف دارایی را می‌خوانند؛ هیچ جدول کاربر، کیف پول، سفارش، معامله یا تراکنشی در بدنه آن‌ها دیده نشد. migrationهای متناظر صریحاً PUBLIC را revoke و anon/authenticated را grant می‌کنند.
- [x] محل فراخوانی در `index.html` بررسی شد: صفحه عمومی بازار از `loadFeaturedMarketAssets()` هر دو RPC را درخواست می‌کند؛ خروجی کشف‌شده با `catalogOnly: true` صرفاً نمایشی است و جفت معاملاتی ایجاد نمی‌کند. بنابراین anon برای این دو مسیر فعلی UI یک دسترسی عمومیِ موردنیاز است؛ revoke کورکورانه می‌تواند صفحه بازار را خراب کند.
- [x] گزارش تفصیلی در `docs/SECURITY_REVIEW_2026-11-20.md` با commit `5a5756b5228993ca04b521a55168e8f608a82b70` ثبت شد.
- [!] این بررسی فقط دو تابع anon را پوشش می‌دهد؛ ۲۳ تابع SECURITY DEFINER قابل اجرا برای authenticated و ۱۵ جدول RLS بدون policy هنوز به بررسی هدفمند نیاز دارند. هشدارها به‌تنهایی اثبات آسیب‌پذیری نیستند.
- [!] هیچ grant، policy، تابع، migration، Edge Function، cron، داده مالی، سفارش، معامله، رزرو، کیف پول یا موجودی در Production تغییر نکرد. هیچ درخواست runtime ناشناس یا worker مالی اجرا نشد؛ آزمون چرخه مالی به علت نبود Supabase branch ایزوله انجام نشد.
- [x] تغییر امروز مستندسازی/ممیزی فقط‌خواندنی است؛ آزمون اجرایی کد لازم نبود و اجرا نشد.
- [ ] گام بعد: گروه‌بندی و بازبینی ۲۳ تابع authenticated، با اولویت توابع admin و هر تابع دارای اثر نوشتن؛ سپس افزودن تست رگرسیون ایستا برای قرارداد دو RPC عمومی، بدون تغییر مجوز تا آماده‌شدن جایگزین سازگار با UI و تأیید انتشار.

### تکمیل ثبت QA Stop-Limit — ۲۰ نوامبر ۲۰۲۶
- [x] ماتریس `docs/STOP_LIMIT_QA_MATRIX.md` با آخرین نتیجهٔ ایزولهٔ CI ثبت‌شده در ۱۹ نوامبر (run `44594127811`, Run #914) و snapshot فقط‌خواندنی Production به‌روز شد؛ commit: `6171e3fc5febee5705aa6c3e76dad1a7fde80eb2`.
- [x] مرز آزمون روشن شد: CI روی PostgreSQL 17 دورریختنی موفق بوده، اما Development Branch مستقل Supabase وجود ندارد؛ صفر بودن ردیف‌های مالی Production جایگزین آزمون چرخه کامل نیست.
- [!] هیچ سفارش/معامله/رزرو/موجودی آزمایشی در Production ایجاد نشد و هیچ Worker/RPC مالی روی کاربران واقعی اجرا نشد.


## ادامهٔ ممیزی امنیتی RPC و RLS — ۲۰ نوامبر ۲۰۲۶
- [x] بازبینی هدفمند ۸ تابع مدیریتی از میان ۲۳ تابع `SECURITY DEFINER` قابل اجرا برای `authenticated`: همه به کنترل `super_admin` متکی هستند؛ دو تابع گزارش/درخواست همگام‌سازی از helperای استفاده می‌کنند که `auth.uid()` تهی را رد می‌کند.
- [x] مسیرهای اصلی سفارش/معامله از هویت `auth.uid()` استفاده می‌کنند؛ مسیرهای ثبت سفارش و معاملهٔ شرطی حساب فعال را نیز کنترل می‌کنند؛ لغو سفارش به مالکیت همان کاربر محدود است.
- [x] `get_my_order_reservations` به شناسهٔ کاربر جاری محدود است؛ `get_demo_trading_fee_rate` فقط نرخ کارمزد را می‌خواند.
- [x] جدول‌های RLS-enabled بدون policy با ACL زنده تطبیق داده شدند: چهار جدول public فاقد مجوز مستقیم DML برای anon/authenticated هستند؛ جدول‌های private برای anon غیرقابل‌استفاده‌اند و مجوز مستقیم DML برای authenticated مشاهده نشد؛ جدول‌های auth نیز مجوز مستقیم DML برای نقش‌های اپلیکیشن ندارند.
- [x] گزارش تفصیلی به `docs/SECURITY_REVIEW_2026-11-20.md` افزوده شد؛ commit گزارش: `43088049037644a38538e41cf9a0c2e911bffd2e`.
- [!] این مرحله بازبینی هدفمند catalog/بدنه بود؛ آزمون runtime منفی با JWTهای anon/authenticated و بررسی عمیق همه شاخه‌های مالی هنوز انجام نشده است.
- [!] هیچ grant، policy، تابع، migration، سفارش، معامله، رزرو، کیف پول یا موجودی در Production تغییر نکرد.
- [ ] گام بعد: بررسی عمیق بدنهٔ RPCهای مالی و ترتیب قفل/مالکیت رکوردها، سپس آزمون منفی در محیط ایزوله؛ پیگیری تنظیم leaked-password protection نیز باقی است.


## بهینه‌سازی به‌روزرسانی قیمت بازار — ۲۰ نوامبر ۲۰۲۶
- [x] با تأیید کاربر، بررسی بهینه‌سازی تابع `public.refresh_market_prices()` ادامه یافت؛ cadence یک‌دقیقه‌ای باید حفظ شود.
- [x] HEAD زندهٔ main برابر `96866f6e023458f857734e30d8aff6a4051cc785` بود. PR #33 مربوط به `refresh_crypto_assets()` است و جایگزین بهینه‌سازی تابع `refresh_market_prices()` نیست؛ PR #33 همچنان Draft است.
- [x] تعریف migration اعمال‌شدهٔ محدودیت ۵۱۵ شناسه بررسی شد: هر سه provider یعنی CoinGecko، KuCoin و Gate.io، قفل advisory، صف درخواست و پاک‌سازی صف حفظ شده‌اند؛ پردازش CoinGecko در حلقه با upsert جداگانه برای هر mapping انجام می‌شود.
- [x] snapshot فقط‌خواندنی: ۳۹۸ جفت فعال، ۸۹۱ فهرست منتخب، ۳ درخواست در صف و صفر درخواست قدیمی‌تر از دو دقیقه. مشاهدات اخیر cron برای تابع قیمت حدود ۴۳٫۷ ثانیه میانگین و ۹۸٫۵ ثانیه بیشینه ثبت کرده‌اند.
- [x] Issue #34 برای طراحی upsert گروهی، تعیین قطعی تعارض نمادها و fixture رگرسیون PostgreSQL 17 ساخته شد: https://github.com/shahram-adim/DigiArz/issues/34
- [!] آخرین پرس‌وجوی فقط‌خواندنی برای تعارض نمادها به timeout خورد؛ semantics نمادهای تکراری هنوز اثبات نشده و پیاده‌سازی bulk upsert نباید حدس زده شود.
- [x] هیچ تابع، index، cron schedule، migration history، قیمت، سفارش، معامله، کیف پول یا موجودی Production تغییر نکرد. اجرای `supabase db push` به‌علت مغایرت migrationها همچنان ممنوع است.
- [ ] گام بعد: روی شاخهٔ ایزوله، پس از بازیابی تعریف دقیق تابع زنده و اثبات رفتار نمادهای تکراری، پیاده‌سازی و آزمون PostgreSQL 17 انجام شود؛ سپس CI، برابری رفتاری و benchmark بررسی شود.


## ادامهٔ بررسی upsert گروهی قیمت بازار — ۲۰ نوامبر ۲۰۲۶
- [x] پرس‌وجوی محدود فقط‌خواندنی برای تعارض نمادها بین جفت‌های فعال و فهرست دارایی‌های منتخب اجرا شد؛ هیچ نمادی با بیش از یک CoinGecko ID در snapshot فعلی پیدا نشد. این فقط نتیجهٔ لحظه‌ای است.
- [!] بازیابی دوبارهٔ تعریف کامل تابع زندهٔ `refresh_market_prices()` به timeout اتصال خورد؛ بنابراین بازنویسی تابع شروع نشد.
- [x] شاخهٔ ایزوله `perf/market-price-bulk-upsert-draft` و PR پیش‌نویس #35 ایجاد شد: https://github.com/shahram-adim/DigiArz/pull/35. تنها فایل مستندات طراحی و ماتریس تست افزوده شده؛ هیچ SQL یا migration اضافه نشده است.
- [ ] گام بعد: دریافت تعریف دقیق تابع زنده، مقایسهٔ رفتار providerها و سپس نوشتن fixture PostgreSQL 17 و پیاده‌سازی فقط در همین شاخه.
- [x] cadence یک‌دقیقه‌ای، cron، دیتابیس Production، سفارش‌ها و معاملات بدون تغییر باقی ماندند.


## ممیزی عمیق RPCهای مالی — ۲۰ نوامبر ۲۰۲۶
- [x] وضعیت Supabase زنده دوباره بررسی شد: `ACTIVE_HEALTHY`، PostgreSQL `17.11.0.018`.
- [x] بدنهٔ زنده و ACL توابع Market، Limit، لغو Limit، Conditional، Stop-Limit، workerها و helper مدیریتی کیف پول بازبینی شد.
- [x] قیمت معامله Market از جدول سرور خوانده می‌شود و باید حداکثر یک دقیقه تازه باشد؛ قیمت ارسالی مرورگر مبنای اجرا نیست.
- [x] workerهای پردازش سفارش به `service_role` محدودند؛ کنترل مالکیت، رزرو، قیمت تازه، جفت فعال و قفل ردیف‌ها در مسیرهای بررسی‌شده وجود دارد.
- [x] هفت کنترل تجمیعی یکپارچگی داده همگی صفر مغایرت گزارش کردند: موجودی منفی، رزرو نامعتبر/یتیم، سفارش باز بدون رزرو، معامله یتیم و مقادیر نامعتبر سفارش.
- [!] جداول orders/trades/order_reservations/asset_balances در snapshot خالی‌اند؛ صفر مغایرت اثبات آزمون runtime نیست.
- [!] comment زندهٔ `process_limit_orders` از wallet-first می‌گوید، اما ترتیب واقعی قفل order → reservation → wallet است. deadlock اثبات نشده؛ اصلاح comment و تطبیق ماتریس قفل‌ها باید فقط در شاخهٔ ایزوله انجام شود.
- [!] آزمون منفی runtime با JWTهای anon/authenticated و بررسی کامل همهٔ ۲۳ تابع authenticated هنوز انجام نشده؛ Security Advisor فعلی نیز به read timeout خورد.
- [x] گزارش جزئیات در `docs/FINANCIAL_RPC_AUDIT_2026-11-20.md` ثبت شد.
- [x] هیچ تغییر Production، Migration، cron، grant، policy، سفارش، معامله، رزرو، موجودی یا کیف پول انجام نشد.
- [ ] گام بعد: تکمیل ماتریس ترتیب قفل تمام RPCها/workerها و تست هم‌زمانی و دسترسی منفی در PostgreSQL 17 ایزوله؛ سپس بازبینی باقی توابع authenticated. اجرای `supabase db push` همچنان ممنوع است.


## ادامهٔ ممیزی قفل‌ها و TP/SL — ۲۰ نوامبر ۲۰۲۶
- [x] تعریف زندهٔ ۱۰ RPC/worker مالی از Supabase Production دوباره خط‌به‌خط بررسی شد: Market، Limit، لغو Limit، Stop-Limit، TP/SL و لغوهای متناظر.
- [x] تصحیح ثبت قبلی: در `process_limit_orders` ترتیب واقعی قفل‌ها order → reservation → wallet است و کیف پول پیش از تغییر `asset_balances` قفل می‌شود؛ comment «wallet-first» به ترتیب منابع مالی اشاره دارد. ناسازگاری قبلی comment پس گرفته شد؛ وارونگی قطعی wallet/asset در مسیرهای بررسی‌شده اثبات نشد.
- [!] یافته جدید در `process_conditional_orders()`: شاخهٔ اعتبارسنجی رزرو نامعتبر فقط `attempt_count` و `last_error` را به‌روز می‌کند و بدون سقف تلاش `CONTINUE` می‌زند. سقف ۱۰ تلاش فقط در بلوک exception است و این شاخه را پوشش نمی‌دهد؛ با cron هر دقیقه، سفارش معیوب می‌تواند نامحدود pending بماند.
- [x] cron زندهٔ job 9 با نام `digiarz-conditional-orders` فعال و دارای schedule یک‌دقیقه‌ای تأیید شد.
- [x] snapshot فقط‌خواندنی: ۰ سفارش شرطی pending، ۰ سفارش pending با رزرو نامعتبر و ۰ سفارش pending با ۱۰ تلاش یا بیشتر.
- [x] تابع `deactivate_my_account()` نیز بررسی شد؛ مسیرهای Limit و conditional pending را لغو و رزروهای معتبرشان را آزاد می‌کند و وضعیت Stop-Limit triggered را با child sync می‌کند.
- [!] پیشنهاد اصلاح فقط در شاخهٔ ایزوله: bounded retry برای شاخهٔ reservation-validation در TP/SL؛ پس از ۱۰ بار parent/conditional به rejected/manual review بروند، ولی رزرو نامعتبر خودکار تغییر نکند. تست PostgreSQL 17 برای missing/released/wrong-asset/invalid arithmetic و تکرار worker لازم است.
- [x] گزارش `docs/FINANCIAL_RPC_AUDIT_2026-11-20.md` با تصحیح و یافته جدید به‌روزرسانی شد.
- [x] هیچ تابع، migration، grant، policy، cron، سفارش، معامله، رزرو، کیف پول یا موجودی Production تغییر نکرد؛ cadence یک‌دقیقه‌ای حفظ شد.
- [ ] گام بعد: ساخت تست منفی و bounded-retry regression در PostgreSQL 17 ایزوله و بازبینی باقی توابع authenticated؛ Production تا تأیید تست و مجوز انتشار دست‌نخورده بماند.


## آزمون ایزولهٔ bounded retry برای TP/SL — ۲۰ نوامبر ۲۰۲۶
- [x] شاخهٔ ایزوله `security/tp-sl-bounded-reservation-retry-2026-11-20` و PR پیش‌نویس #36 ساخته شد: https://github.com/shahram-adim/DigiArz/pull/36.
- [x] کاندید CI پس از ۱۰ شکست اعتبارسنجی رزرو، parent و conditional را `rejected` با پیام `manual review required` می‌کند؛ رزرو مفقود/نامعتبر را خودکار آزاد یا بازنویسی نمی‌کند.
- [x] regression در PostgreSQL 17 برای چهار حالت missing/released/wrong-asset/undersized reservation، مرز تلاش ۹ و ۱۰ و عدم retry بعد از rejection افزوده شد.
- [x] اجرای نخست CI #1172 به‌علت دو parent order_id اشتباه در fixture تست fail شد؛ شناسه‌ها اصلاح شدند و اجرای کامل مجدد #1173 با نتیجهٔ success و هر ۲۲ گام موفق پایان یافت: https://github.com/shahram-adim/DigiArz/actions/runs/44786496205.
- [!] محدودیت مهم: فایل SQL در `supabase/drafts/` از fixture موجود CI بر پایهٔ snapshot ۱۵ نوامبر اقتباس شده و drop-in replacement تعریف کامل Production در ۲۰ نوامبر نیست. پیش از هر migration باید فقط شاخهٔ bounded-retry روی تعریف دقیق و کامل زنده port شود، تفاوت‌های بین نسخه‌ها بررسی شوند و CI دوباره اجرا شود.
- [x] PR #36 پیش‌نویس و ادغام‌نشده باقی مانده؛ هیچ migration یا تغییر تابع/cron/grant/policy/رزرو/موجودی در Production انجام نشد.
- [x] cadence یک‌دقیقه‌ای بازار و worker بدون تغییر است.
- [ ] گام بعد: بازیابی و نگهداری snapshot کامل تابع زندهٔ ۲۰ نوامبر، port حداقلی bounded-retry به همان بدنه، تست regression و بررسی diff دقیق پیش از هر تصمیم انتشار.


### نتیجهٔ نهایی کاندید بر پایهٔ تابع زنده — ۲۰ نوامبر ۲۰۲۶
- [x] تعریف کامل زندهٔ `public.process_conditional_orders()` دوباره با `pg_get_functiondef` بازیابی شد؛ کاندید PR #36 اکنون از همین snapshot دقیق ۲۰ نوامبر ساخته شده و فقط شاخهٔ invalid-reservation retry را تغییر می‌دهد.
- [x] مرحلهٔ regression در workflow از اجرای worker fixture قدیمی حذف شد؛ تست مستقیماً تعریف زندهٔ ۲۰ نوامبر را با patch محدود در دیتابیس موقت اجرا می‌کند.
- [x] اجرای نهایی full CI، run #1177، روی head `d0da205cce649faa23e9bcc50d2c840f0bf1fe6f` با نتیجهٔ success تکمیل شد؛ هر ۲۲ گام از جمله bounded retry regression موفق شدند: https://github.com/shahram-adim/DigiArz/actions/runs/44787061755.
- [!] run #1173 (نسخهٔ fixture-based) superseded است؛ نتیجهٔ مرجع برای کاندید دقیق، run #1177 است. run #1172 شکست fixture-ID داشت و پس از اصلاح superseded شد.
- [x] PR #36 همچنان Draft و ادغام‌نشده است. کاندید فقط در `supabase/drafts/` قرار دارد؛ هیچ Migration، RPC، Cron، grant، policy یا داده‌ای در Production تغییر نکرد.
- [ ] گام بعد: بررسی نهایی diff و طرح migration قابل rollback؛ قبل از هر rollout، تأیید صریح انتشار لازم است.


## نوبت تضمین کیفیت شبانه — ۲۱ نوامبر ۲۰۲۶

- HEAD واقعی main پیش از ثبت این نوبت: acafbfbedc297a8c42fc1bb54140c8dadba839e4. کامیت‌های جدید از checkpoint قبلی عمدتاً مستندات source-recovery، backup و PR #38 هستند؛ در این نوبت هیچ کد برنامه یا migration تغییر نکرد.
- PR #38 با head a6849671727fce10fe852bda607fd65b3fc2a351 همچنان open/Draft و ادغام‌نشده است. Exact-decimal run 44811642137 موفق شد؛ بااین‌حال fixture فقط interleaving primitive را مدل می‌کند و چهار RPC واقعی Market/Limit/TP-SL/Stop-Limit را اجرا نمی‌کند.
- پروژهٔ Production با get_project برابر ACTIVE_HEALTHY و PostgreSQL 17.11.0.018 است؛ ۵۲ migration ثبت‌شده باقی است. schedule زنده: job 13 هر ۱۰ دقیقه، job 14 در دقیقه‌های ۱،۱۱،۲۱،۳۱،۴۱،۵۱ و job 17 در دقیقه‌های ۵،۱۵،۲۵،۳۵،۴۵،۵۵. پرس‌وجوی تازهٔ cron.job_run_details با connection timeout شکست خورد؛ آمار success/failure تازه ادعا نمی‌شود.
- unified logs برای 2026-11-19 22:48:46Z تا 2026-11-20 22:48:46Z: تعداد ۵۷۵ SSL connection reset، ۹۳ EOF، ۱۵۲ statement timeout؛ startup-timeout رویدادها در jobهای 8/9/12/2/3 به‌ترتیب 455/455/452/450/444 و در jobهای 11/17/5/16/14/13/18/4/15 به‌ترتیب 87/52/48/46/46/46/43/41/18 ثبت شدند. این‌ها شمارش log event هستند، نه شمارش قطعی اجرای یکتای cron.
- direct read-only execute_sql و list_tables روی Production هر دو connection timeout دادند؛ Security Advisor نیز read timeout داد. Health Advisor بدون یافته بود. Performance Advisor در observed_at برابر 2026-11-20T22:59:05.512Z شامل ۹ FK بدون ایندکس پوششی، ۱۱ هشدار RLS initplan و ۷ unused index بود. هیچ grant/policy/index تغییر نکرد.
- پروژهٔ جداگانهٔ DigiArz-Recovery-Test با ref zrriqwyolcjhbappocuw ACTIVE_HEALTHY و PostgreSQL 17.11.0.019 است؛ restore run 44298621534 موفق. فقط catalog metadata خوانده شد: ۳۲ جدول، ۲۳۹ ستون، ۱۱۶ قید، ۶۳ ایندکس، ۵ trigger غیرسیستمی و ۲۱ policy. سه account-guard trigger روی INSERT orders/trades/transactions به private.guard_active_account_writes() وصل‌اند.
- fingerprintهای helper در recovery snapshot: current_account_is_active=d932cd1d0da21bb96bdc0a381f7dcbc3؛ get_demo_trading_fee_rate=546d80d7105228ed97da26c5ed0c7b7f؛ deactivate_my_account=2081e024a2b815aa2c6ebf6470fa2bce؛ guard_active_account_writes=29b8e23c1de8eb4762a8cf1a9c9343ce. این‌ها فقط snapshot Nov 18 هستند و parity با Production اثبات نشده.
- recovery-drill.yml از pg_restore --no-owner --no-acl استفاده می‌کند؛ ACLهای پروژهٔ recovery برای اثبات grantهای Production معتبر نیستند. پروژهٔ recovery دارای دادهٔ backup است؛ محتوای ردیف‌ها خوانده نشد و هیچ داده‌ای برای تست استفاده نشد. محیط آزمون بعدی باید PostgreSQL 17 تازه با schema-only DDL و دادهٔ مصنوعی باشد.
- artifact پشتیبان ID 14217201032 هنوز expired=false است و در 2026-11-23T10:26:46Z منقضی می‌شود. GitHub API digest صحیح ۶۴ کاراکتری sha256:555c1f7ebcad947e573dad659084bbcf94dc88d55fc0bc1a3b7de9606db8e4e5 است؛ digest ۶۱ کاراکتری قبلی در سه سند اصلاح شد. این artifact فاقد migration ledger است.
- اسناد به‌روز شدند: bootstrap plan commit 6ccfa3c68c47e00518508e930dc97428231c4019؛ handoff commit 8e6047f4dc357916b619581746e8c2b5419c13f5؛ financial audit commit acafbfbedc297a8c42fc1bb54140c8dadba839e4. هر فایل پس از commit مجدداً fetch و SHA/content تأیید شد.
- محدودیت اجرا: در این نوبت تست PostgreSQL جدید اجرا نشد؛ فقط CI موجود PR #38 با نتیجه success مشاهده شد و queryهای catalog روی Recovery-Test فقط خواندنی بودند. Production و Recovery-Test هیچ داده/ساختار/ACL/cron تغییر ندادند.
### گام بعد
۱. پس از رفع connection timeout، metadata schema/function/triggers/policies Production را با snapshot Recovery-Test مقایسه کن؛ اختلافات Nov 18 تا Nov 21 را مشخص کن.
۲. ACLها را از migrationهای منبع و catalog زنده بازیابی کن؛ ACLهای recovery به علت --no-acl کنار گذاشته شوند.
۳. فقط پس از اثبات schema parity، bootstrap تازه PostgreSQL 17 بدون داده backup بساز و source-faithful race test را اجرا کن؛ PR #38 را تا آن زمان primitive-only نگه دار.
۴. migration drift و اختلاف job 14 را جداگانه بررسی کن؛ supabase db push، merge، deploy و هر تغییر Production همچنان ممنوع است.

## نوبت تضمین کیفیت شبانه — ۲۱ نوامبر ۲۰۲۶ (تطبیق دقیق Recovery)

- HEAD واقعی پیش از این ثبت: `e251c6925615a1641e5267e4b339cf6bbd923f7b`. آخرین commitهای main از نوبت قبلی عمدتاً source-recovery/backup documentation بوده‌اند؛ commit برنامه یا migration تازه‌ای در top commits مشاهده نشد.
- Production با `get_project` برابر `ACTIVE_HEALTHY` و PostgreSQL `17.11.0.018` است؛ فهرست Migrationها ۵۲ نسخه دارد و آخرین نسخه `20261116205451` است. پرس‌وجوی catalog موفق شد؛ query شمارش اجرای cron در ۲۴ ساعت به خطای داخلی ابزار خورد، بنابراین آمار success/failure جدید گزارش نمی‌شود.
- زمان‌بندی زندهٔ `cron.job` دوباره تأیید شد: job 13=`*/10 * * * *`، job 14=`1-59/10 * * * *`، job 17=`5-59/10 * * * *`؛ هر سه active هستند. فایل محلی job 14 هنوز cadence هر دقیقه را ثبت می‌کند؛ منبع تغییر زنده هنوز پیدا نشده و `supabase db push` ممنوع می‌ماند.
- یک مقایسهٔ فقط‌خواندنی catalog بین Production و پروژهٔ `DigiArz-Recovery-Test` (ref `zrriqwyolcjhbappocuw`, هر دو PostgreSQL 17 و ACTIVE_HEALTHY) انجام شد؛ هیچ ردیف کاربری یا محتوای backup خوانده نشد. در scopeهای public/private:
  - Production: ۳۲ جدول، ۲۴۰ ستون، ۱۳۱ قید، ۶۳ ایندکس، ۵ trigger غیرسیستمی و ۲۱ policy.
  - Recovery-Test: ۳۲ جدول، ۲۳۹ ستون، ۱۱۶ قید، ۶۳ ایندکس، ۵ trigger و ۲۱ policy.
  - یک ستون فقط در Production وجود دارد: `private.market_price_sync_requests.provider text NOT NULL DEFAULT 'CoinGecko'`.
  - ۱۵ قید فقط در Production وجود دارد و همگی FK به `auth.users(id)` هستند: `admin_users_granted_by_fkey`, `admin_users_user_id_fkey`, `admin_wallet_adjustments_admin_user_id_fkey`, `admin_wallet_adjustments_target_user_id_fkey`, `market_pair_admin_audit_admin_user_id_fkey`, `admin_market_listings_added_by_fkey`, `asset_balances_user_id_fkey`, `coin_review_reports_reporter_user_id_fkey`, `coin_reviews_user_id_fkey`, `conditional_orders_user_id_fkey`, `orders_user_id_fkey`, `profiles_id_fkey`, `trades_user_id_fkey`, `transactions_user_id_fkey`, `wallets_user_id_fkey`. هیچ قید اضافی در Recovery-Test نسبت به Production دیده نشد.
- تعریف هر ۵ trigger و هر ۲۱ policy در دو پروژه دقیقاً یکسان بود. fingerprint بدنهٔ چهار helper حساس نیز برابر بود: `current_account_is_active=d932cd1d0da21bb96bdc0a381f7dcbc3`, `get_demo_trading_fee_rate=546d80d7105228ed97da26c5ed0c7b7f`, `deactivate_my_account=2081e024a2b815aa2c6ebf6470fa2bce`, `guard_active_account_writes=29b8e23c1de8eb4762a8cf1a9c9343ce`. این parity فقط همین چهار تابع را پوشش می‌دهد، نه تمام RPCها.
- ACL تابع‌ها در Recovery-Test برابر NULL/default است، درحالی‌که Production grantهای صریح دارد؛ این با اجرای `pg_restore --no-acl` سازگار است. پس Recovery-Test برای اثبات grant/permission Production معتبر نیست، حتی با برابری بدنهٔ چهار تابع، triggerها و policyها.
- PR #38 head برابر `a6849671727fce10fe852bda607fd65b3fc2a351` است و نسبت به main فعلی ۳ commit جلو و ۲۰ commit عقب است (diverged). diff فقط workflow و دو fixture تست race را تغییر می‌دهد. اسکریپت عمداً الگوی TOCTOU را با توابع fixture مدل می‌کند؛ RPCهای واقعی `deactivate_my_account` و سفارش‌گذاری Production را اجرا نمی‌کند. run موفق ثبت‌شده برای آن، primitive fixture را تأیید می‌کند نه source-faithful RPC parity؛ PR ادغام نشود.
- Health Advisor بدون یافته بود؛ Performance Advisor شامل ۹ FK بدون ایندکس پوششی، ۱۱ هشدار RLS initplan و ۷ unused index بود. Security Advisor دوباره به connection timeout خورد؛ بنابراین وضعیت امنیتی تازه از Advisor قابل تأیید نشد. هیچ grant/policy/index تغییر نکرد.
- محدودیت این نوبت: queryهای catalog فقط metadata بودند؛ هیچ SQL write، migration، worker/RPC، backup row، order، trade، reservation، balance یا wallet اجرا/تغییر نشد. تست PostgreSQL جدید در این نوبت اجرا نشد.

### گام بعد
1. علت اختلاف Recovery-Test را ریشه‌یابی کن: چرا ۱۵ FK به `auth.users` و ستون `provider` در restore موجود نیستند؛ مسیر dump/restore و schema source را بررسی کن، نه اینکه این اشیا را کورکورانه اضافه کنی.
2. ACLهای Production را از migration/source معتبر بازسازی و جدا از Recovery-Test نگهداری کن؛ `--no-acl` برای آزمون مجوزها کافی نیست.
3. یک PostgreSQL 17 کاملاً تازه با schema-only DDL و synthetic auth/users ایجاد کن؛ تمام FKها، triggerها، policyها و ACLهای منبع را صریحاً provision کن و سپس source-faithful race test را به RPCهای واقعی متصل کن.
4. PR #38 را تا همگام‌سازی با main، تکمیل پوشش RPC واقعی و اثبات CI نگه دار؛ merge/deploy بدون تأیید صریح انجام نشود.
5. migration drift و cadence job 14 را جداگانه حل کن؛ `supabase db push` و هر تغییر Production همچنان ممنوع است.


## اصلاح هماهنگی هویت بصری صفحه ورود — ۲۱ نوامبر ۲۰۲۶

- HEAD زنده پیش از این تغییر: `6b31da97f36be8c7f9e3c2f3e63728c759322c09`. آخرین تغییر محصولی پیش از این نوبت، merge شدن PR #42 با commit `f8fda32c35a529f4719681a91fe800d056514db0` بود؛ ثبت نام و نام خانوادگی از فرم حذف شده و signup فقط email/password می‌فرستد. login، recovery و schema حساب دست‌نخورده مانده‌اند.
- بازبینی CSS نهایی نشان داد آخرین override صفحه ورود هنوز پس‌زمینه navy/آبی داشت و با انتخاب ثبت‌شدهٔ کاربر (ظاهر شبیه Binance، مشکی و زرد) کاملاً هماهنگ نبود.
- `index.html`: فقط رنگ‌های لایهٔ نهایی صفحه ورود به charcoal/black و زرد `#f0b90b` تغییر کرد؛ چیدمان، فرم email/password، شناسه‌های کنترل، منطق login/signup/recovery، پیش‌نمایش بازار و breakpointهای موبایل تغییر نکردند.
- `tests/index-syntax.test.js`: آزمون قدیمیِ انتظاردهندهٔ رنگ‌بندی آبی با آزمون palette نهایی مشکی/زرد جایگزین شد؛ حفظ کنترل‌های ورود/ثبت‌نام/بازیابی، حذف فیلد نام، و ارسال email/password-only همچنان assert می‌شود.
- اجرای CI برای commitهای تازه در لحظهٔ ثبت هنوز از status endpoint قابل تأیید نبود؛ نتیجهٔ تست موفق ادعا نمی‌شود تا workflow run متناظر با HEAD جدید دیده شود.
- بررسی فقط‌خواندنی Supabase در 2026-11-21 حدود 10:36 UTC: پروژه `ACTIVE_HEALTHY`، PostgreSQL `17.11.0.018`؛ هشت Edge Function فعال؛ Development Branch خالی؛ سه migration تازهٔ ثبت‌شده شامل `20261121045434`, `20261121045531`, `20261121050216`. هیچ migration یا داده‌ای اعمال/تغییر نشد.
- snapshot جداول عمومی: دادهٔ مالی `orders/trades/transactions/asset_balances/order_reservations/conditional_orders` در شمارش connector صفر گزارش شد؛ این snapshot به‌تنهایی اثبات تست runtime نیست. قیمت بازار 898 ردیف، دارایی‌های بازار 18,911 ردیف و مشاهدات فهرست صرافی 4,962 ردیف گزارش شدند.
- Security Advisor در این snapshot: 2 هشدار RPC نوع SECURITY DEFINER قابل اجرا برای anon، 23 هشدار برای authenticated، 15 جدول RLS-enabled بدون policy (عمدتاً schema خصوصی/صف/کنترل)، و leaked-password protection غیرفعال. Health Advisor بدون lint؛ Performance Advisor شامل 9 FK بدون index پوششی، 11 هشدار RLS initplan، 15 unused index و 2 جدول backup بدون primary key. هیچ grant، policy، index، Auth setting یا RPC تغییر نکرد.
- محدودیت: Development Branch ایزولهٔ Supabase در پروژهٔ اصلی موجود نیست. آزمون کامل Stop-Limit همچنان باید در PostgreSQL 17 تازه با DDL و دادهٔ مصنوعی، پس از اثبات parity منبع، انجام شود. PR #38 و recovery snapshot به‌تنهایی اثبات source-faithful parity نیستند.
- هیچ سفارش، معامله، رزرو، کیف پول، موجودی، سابقه مالی، Worker، cron، RPC مالی یا Migration در Production برای تست اجرا/تغییر نشد.

### گام بعد
1. تأیید GitHub Actions برای HEAD جدید و بررسی اجرای آزمون palette و regression کامل.
2. پس از تأیید CI، بررسی بصری فرم ورود/ثبت‌نام در Android و اطمینان از حفظ نام‌نویسی email/password-only.
3. ادامهٔ QA Stop-Limit فقط روی PostgreSQL 17 تازه و synthetic؛ Production و Recovery-Test دارای backup data دست‌نخورده بمانند.


### اصلاح matcher قدیمی آزمون رنگ‌بندی — ۲۱ نوامبر ۲۰۲۶
- پس از commit آزمون جدید، بازخوانی فایل تست نشان داد یک assertion قدیمی در تست «reference login» هنوز پس‌زمینهٔ navy قبلی را انتظار می‌کشید؛ این assertion با بررسی ترتیب cascade و وجود override نهایی مشکی/زرد جایگزین شد.
- این اصلاح فقط test expectation است؛ هیچ HTML، منطق Auth، schema یا داده‌ای تغییر نکرد.
- Commit هم‌زمان دیگری روی main با SHA `e5bd65b3460ec7ed85857fa51b092cd681322409` فقط workflow دستیِ artifact-only برای APK بازبینی Android را ثبت کرده است؛ طبق handoff، PR #45 همچنان Draft و ادغام‌نشده است و این نوبت آن را اجرا/merge نکرد.
- Run شمارهٔ 1446 با ID `44895500537` برای commit `e5bd65b3460ec7ed85857fa51b092cd681322409` هنگام بررسی در حال اجرا بود؛ نتیجهٔ نهایی هنوز قابل اعلام نیست. پس از اصلاح assertion، اجرای جدید main باید جداگانه بررسی شود.


### CI regression test correction — ۲۱ نوامبر ۲۰۲۶
- اجرای main Run #1447 با ID `44895566312` مشخص کرد test جدید به‌علت escape اضافی در regex literal حتی parse نمی‌شود؛ 29 تست دیگر در آن job موفق بودند و فایل `tests/index-syntax.test.js` به‌عنوان یک فایل test fail شد. این یک شکست واقعی CI است و موفقیت اعلام نمی‌شود.
- Run #1446 (ID `44895500537`) نیز روی نسخهٔ قبل از اصلاح assertion قدیمی fail شده بود.
- تست palette با assertionهای رشته‌ای مستقیم بازنویسی شد تا از regex escape شکننده جلوگیری شود؛ کنترل‌های Auth، ثبت‌نام email/password-only و حفظ چیدمان موبایل همچنان بررسی می‌شوند.
- Commit اصلاح جدید: `2f67a54b0cb7416aaa01f13e959248b59b701ac7`. اجرای CI جدید باید روی همین commit یا descendant آن بررسی شود؛ نتیجه هنوز نامشخص است.


### جلوگیری از انتشار خودکار APK — ۲۱ نوامبر ۲۰۲۶
- بررسی workflow زندهٔ `.github/workflows/android-apk.yml` نشان داد push به `index.html` علاوه بر artifact، مرحلهٔ `softprops/action-gh-release` را نیز اجرا می‌کند؛ بنابراین commit رابط کاربری `87c171a77958b6c1ba2605813525ea61d15a20a4` باعث ساخت و انتشار خودکار GitHub Release شد.
- شواهد GitHub: Android workflow run `44895476010` / Build 187 با نتیجهٔ success؛ artifact ID `14704305123`، digest `sha256:811b75a73d90bb0f2cfb402ea38c3594853a6c325bfb6a5886caf072e019444e`؛ Release `android-debug-187` با asset `app-debug.apk`، SHA-256 `083706dec8319975f9ed6863e1944e0ed235ec5c5f45397a637d57f637979585`. این یک debug/test APK است و امضای production ندارد؛ نصب فیزیکی روی گوشی تأیید نشده.
- این انتشار خودکار با مرز «عدم انتشار نسخه بدون تأیید صریح» سازگار نبود. هیچ حذف/ویرایش Release یا asset انجام نشد تا بدون اجازه عملیات برگشت‌ناپذیر صورت نگیرد.
- برای جلوگیری از تکرار، workflow به‌صورت محافظتی اصلاح شد: مجوز contents به read محدود و مرحلهٔ GitHub Release حذف شد؛ buildهای بعدی فقط artifact ۱۴روزه تولید می‌کنند و tag/release عمومی نمی‌سازند. workflow هنوز روی تغییرات main می‌تواند APK artifact بسازد.
- Commit محافظتی workflow: `e227a4235b92a1e87a99cb62b648faa319b98620`. این تغییر به معنی حذف Release قبلی نیست؛ Release قبلی دست‌نخورده باقی مانده است.
- CI کامل اصلاحات Auth در Run #1449 و #1450 در زمان این ثبت هنوز در حال اجرا بود؛ test step در هر دو success شده بود، اما نتیجهٔ تمام مراحل PostgreSQL/Stop-Limit هنوز قطعی نبود.

### گام بعد
1. تأیید نهایی CI کامل Run #1450 و artifact-only Android build ناشی از تغییر workflow.
2. آزمایش APK روی گوشی Android؛ فقط پس از نصب واقعی می‌توان سازگاری device را تأیید کرد.
3. از این پس هیچ Release/tag جدیدی بدون اجازهٔ جداگانه ساخته نشود؛ ساخت artifact برای QA به‌تنهایی کافی است.

## نتیجهٔ نهایی اجرای روزانه — ۲۱ نوامبر ۲۰۲۶

### وضعیت GitHub و رابط کاربری
- HEAD پیش از این ثبت: 31ebb934b55d7c3610950081df0ed4483de2e672.
- صفحه ورود در index.html به رنگ‌بندی منتخب کاربر، مشکی/ذغالی و زرد Binance-inspired، هماهنگ شد. فرم ثبت‌نام همچنان فقط ایمیل/رمز دارد؛ login، recovery، شناسه‌های کنترل، نمایش بازار و breakpointهای موبایل تغییر رفتاری نکردند.
- Commit رابط: 87c171a77958b6c1ba2605813525ea61d15a20a4؛ آزمون palette در 2f67a54b0cb7416aaa01f13e959248b59b701ac7 با اصلاح matcherهای قدیمی ثبت شد.
- Full CI Run #1454، ID 44895814215، روی HEAD 31ebb934 با نتیجهٔ SUCCESS پایان یافت؛ همهٔ مراحل Node/browser و PostgreSQL 17، از جمله Market/Limit/Stop-Limit/TP-SL، workerها، لغو هم‌زمان و parent-child lifecycle موفق شدند.
- اجرای اولیهٔ آزمون palette به‌دلیل matcherهای قدیمی/escape اضافی fail شد (Runهای #1444–#1448). علت پیدا و اصلاح شد؛ Run #1454 سبز است. این شکست‌ها پنهان یا به‌عنوان موفقیت ثبت نمی‌شوند.

### Android/APK و مرز انتشار
- Android Build #188، run ID 44895810345، روی workflow artifact-only با نتیجهٔ SUCCESS پایان یافت؛ artifact ID 14703574136، digest sha256:4cb617cb85e7a8b849bd69332159e5511c139a676e89429f700b121db5f7aed4، انقضا 2026-12-05T10:46:43Z. این APK debug است؛ نصب فیزیکی روی گوشی هنوز تأیید نشده.
- workflow .github/workflows/android-apk.yml در commit e227a4235b92a1e87a99cb62b648faa319b98620 اصلاح شد: مجوز contents به read محدود و مرحلهٔ auto GitHub Release حذف شد. buildهای بعدی فقط artifact آپلود می‌کنند.
- رویداد ناخواستهٔ قابل‌توجه: پیش از این محافظ، اجرای Android Build #187 (run 44895476010) به‌طور خودکار Release android-debug-187 را منتشر کرد؛ asset debug APK SHA-256 برابر 083706dec8319975f9ed6863e1944e0ed235ec5c5f45397a637d57f637979585. این release دست‌نخورده باقی ماند؛ هیچ حذف یا تغییر برگشت‌ناپذیری انجام نشد. این build production-signed نیست.
- PR #45 با عنوان [Draft] Indigo Glass design + APK-only biometric unlock هنوز Draft/open و merge نشده است. workflow review run #4 (44895774772) موفق شد و artifact ID 14704480013 با انقضای 2026-12-05 تولید کرد؛ این candidate شامل Indigo Glass و biometric APK-only است و با انتخاب فعلی مشکی/زرد از نظر طراحی متفاوت است. بدون تأیید جداگانه merge نمی‌شود.
- هیچ Release/tag جدیدی در Build #188 ایجاد نشد.

### Supabase Production — فقط‌خواندنی
- پروژه gfoaubfilhttnwjykaox: ACTIVE_HEALTHY، PostgreSQL 17.11.0.018.
- Migration ledger: 55 نسخه؛ آخرین نسخه 20261121050216 (temporarily_throttle_exchange_asset_processors_20261121).
- هشت Edge Function فعال؛ Development Branchها: صفر.
- شمارش connector برای جداول مالی orders/trades/transactions/asset_balances/order_reservations/conditional_orders صفر بود؛ این snapshot، آزمون runtime نیست.
- Security Advisor: 2 SECURITY DEFINER RPC برای anon، 23 برای authenticated، 15 جدول RLS-enabled بدون policy و leaked-password protection خاموش. دو RPC عمومی anon یعنی get_admin_market_listings() و get_exchange_discovered_market_assets() با pg_get_functiondef بررسی شدند: هر دو STABLE/SQL/SECURITY DEFINER با search_path خالی و SELECT-only روی متادیتای عمومی بازار هستند؛ هیچ دادهٔ خصوصی/مالی کاربر برنمی‌گردانند. ACL فعلی anon/authenticated/service_role را مجاز می‌کند؛ مجوزها در این نوبت تغییر نکردند.
- Health Advisor بدون یافته؛ Performance Advisor: 9 FK بدون index پوششی، 11 هشدار RLS initplan، 15 unused index و 2 جدول backup بدون PK. هیچ index/RLS/grant/Auth setting تغییر نکرد.
- فقط خواندن catalog/metadata و تعریف دو RPC انجام شد؛ هیچ worker/RPC مالی اجرا نشد و هیچ سفارش، معامله، رزرو، کیف پول، موجودی، سابقه مالی، cron، migration یا schema Production تغییر نکرد.

### گام بعد
1. بررسی بصری APK artifact-only Build #188 روی گوشی Android؛ هیچ تست دستگاهی هنوز انجام نشده.
2. اگر biometric مدنظر باقی است، تغییرات biometric PR #45 را از طرح Indigo Glass جدا و فقط با حفظ تم مشکی/زرد بازبینی کن؛ PR فعلی Draft بماند.
3. ادامهٔ QA منبع‌وفادار Stop-Limit در PostgreSQL 17 تازه با schema/ACL دقیق؛ Supabase Production و Recovery-Test دارای backup data دست‌نخورده بمانند.

## نوبت تضمین کیفیت شبانه — ۲۲ نوامبر ۲۰۲۶

### GitHub و وضعیت UI
- HEAD شاخه `main` پیش از ثبت این نوبت: `b4fa332532f3b19e4fdb42bc84eecfc970113310`؛ جدیدترین تغییرات main عمدتاً handoff و مستندات بازبینی Sky Blue Glass/APK بودند.
- Exact decimal CI روی همین HEAD با run `44903225604` موفق شد. اجرای تازهٔ Pages برای همین HEAD در فهرست runهای بررسی‌شده مشاهده نشد؛ موفقیت Pages برای این HEAD ادعا نمی‌شود.
- PR #47 هنوز Draft و ادغام‌نشده است. candidate head `d6a8773af4b6efb0e2afc283d11822c8eaae0931` با Android review run `44902932362` موفق شد: تست biometric storage، تست‌های visual/application، نصب وابستگی‌ها و signature check، ساخت APK و بررسی `USE_BIOMETRIC` همگی موفق بودند. Artifact ID `14706801177`، SHA-256 `6f0adea22f1e9f645e161c21a10419b85284c08a8d7f30a1bc6e78ea3406450c`؛ APK فقط Debug review است و نصب فیزیکی/ثبت اثرانگشت/ورود و relock روی گوشی هنوز تأیید نشده.
- اجرای قبلی review APK با run `44901688326` روی commit قدیمی‌تر `5ff57bf` در مرحلهٔ visual/application regression شکست خورد و build را متوقف کرد؛ این شکست پنهان نشده است. اجرای بعدی روی candidate اصلاح‌شدهٔ `d6a8773` موفق شد.
- PR #48 (Pale Blue/Lavender Glass) و PR #50 (Pure-white Glass theme 2) همچنان Draft هستند؛ PR #50 بر پایهٔ شاخهٔ PR #48 است. هیچ‌کدام در main ادغام نشده‌اند؛ بنابراین نباید ظاهر آن‌ها را وضعیت live برنامه معرفی کرد.

### Supabase Production — فقط‌خواندنی
- پروژه `gfoaubfilhttnwjykaox` در `ACTIVE_HEALTHY` و PostgreSQL `17.11.0.018` است.
- Migration ledger اکنون ۵۵ نسخه دارد؛ آخرین نسخه `20261121050216`. در `main` فقط ۴۰ فایل SQL در `supabase/migrations/` موجود است و سه Migration جدید ۲۱ نوامبر SQL متناظر ندارند؛ inventory قبلی ۱۴ منبع مفقود داشت و شمار شناخته‌شده اکنون ۱۷ است. جزئیات و محدودیت شمارش در `supabase/MIGRATION_RECONCILIATION.md` ثبت شد.
- زمان‌بندی زنده: job 13 هر ۱۰ دقیقه؛ job 14 در دقیقه‌های ۱ و ۳۱ هر ساعت (هر ۳۰ دقیقه)؛ job 17 از دقیقهٔ ۵ و سپس هر ۱۰ دقیقه. فایل محلی migration `20261117130000` هنوز job 14 را هر دقیقه تعریف می‌کند؛ اختلاف منبع پابرجاست.
- در پنجرهٔ ۶ساعتهٔ `16:34–22:33 UTC`، job 14 دوازده اجرای موفق و صفر شکست داشت (median `21.392s`)، و jobهای 13 و 17 هرکدام ۳۶ اجرای موفق و صفر شکست داشتند. آمار ۲۴ساعتهٔ job 14 شامل ۴۰ شکست قدیمی و ۳۴ موفقیت است؛ آخرین شکست `05:31 UTC` بود.
- صف درخواست همگام‌سازی ۲٬۳۷۰ ردیف تاریخی، صفر pending و صفر pending قدیمی‌تر از ۳۰ دقیقه داشت؛ هر هفت exchange در snapshot بدون pending بودند.
- Health Advisor بدون یافته؛ Security Advisor: ۱۵ جدول RLS-enabled بدون policy (INFO)، دو SECURITY DEFINER قابل اجرا برای anon و ۲۳ برای authenticated (WARN)، و leaked-password protection خاموش (WARN). Performance Advisor: ۹ FK بدون index پوششی، ۱۱ RLS initplan، ۲ جدول backup بدون PK و ۱۴ unused index.

### تست، اقدام و مرز ایمنی
- این نوبت هیچ تست runtime یا SQL تغییردهنده‌ای روی Production اجرا نکرد؛ بررسی‌های Supabase فقط SELECT/catalog/Advisor بودند. نتایج CI فوق از GitHub Actions خوانده شدند، نه اینکه در این نشست دوباره اجرا شوند.
- تنها اقدام نوشتنی این نوبت، ثبت مستندات در `supabase/MIGRATION_RECONCILIATION.md` و همین فایل وضعیت است. هیچ Migration، cron، function، grant، policy، index، سفارش، معامله، رزرو، موجودی، کیف پول یا سابقهٔ مالی تغییر نکرد.
- `supabase db push` همچنان ممنوع است تا ۱۷ منبع Migration و ۲۰ timestamp mismatch با منبع معتبر حل و replay در PostgreSQL 17 دورریختنی موفق شود.

### گام بعد
1. بازیابی SQL سه Migration جدید از artifact/deployment record معتبر؛ از روی نام یا تعریف فعلی تابع SQL بازسازی حدسی نشود.
2. تعیین رابطهٔ Migration `20261121050216` با schedule زندهٔ job 14 و ثبت منبع canonical آن.
3. replay کامل migration set بازسازی‌شده در PostgreSQL 17 ایزوله و بررسی نهایی schedule، worker، ACL و RLS.
4. ادامهٔ QA candidateهای UI/APK فقط در PRهای Draft؛ تست فیزیکی Android هنوز لازم است و merge یا انتشار بدون تأیید صریح انجام نشود.

## ممیزی مسیر قیمت‌های تومانی — ۲۲ نوامبر ۲۰۲۶

- [x] آخرین main پیش از این ثبت: `91eb6f8cef2731f51135b09965e740d3576958c8`.
- [x] ساختار `index.html` بررسی شد: ۲۴۴ شناسه HTML یکتا و بدون تکرار؛ ۹ تب اصلی (داشبورد، بازار، بازار تومانی، خریدوفروش، سفارش‌ها، دارایی‌ها، تاریخچه، تنظیمات و مدیریت) به‌علاوه بخش‌های توکار جزئیات ارز، نمودار و اخبار.
- [x] مسیر بازار تومانی در UI بررسی شد: `loadTomanMarket()` از `market_toman_performance` می‌خواند؛ در صورت نبود ردیف تازه `refresh-toman-market-prices` را invoke می‌کند و هنگام بازبودن تب هر پنج دقیقه refresh خودکار دارد.
- [!] اختلاف قطعی منبع قیمت: تابع GitHub و تابع مستقر Supabase نسخه ۳ فقط `fetchNobitex()`, `fetchWallex()`, `fetchBitpin()` را اجرا می‌کنند. دو منبع موردتأیید کاربر یعنی Bit24 و Kifpool در مسیر قیمت تومانی نیستند؛ Bitpin منبع اضافی فعلی است. متن وضعیت UI نیز همین سه منبع را اعلام می‌کند.
- [x] شمارنده‌های فقط‌خواندنی: `market_prices=899`, `market_fx_rates=1`, `market_toman_prices=0`, `market_toman_price_history=0`, `exchange_asset_observations=4967`, `exchange_asset_sync_requests=2538`, `bit24_exchange_sync_requests=784`.
- [!] در بازه ۲۴ ساعته تا `2026-11-22 10:34 UTC`، ۲۵ درخواست OPTIONS با HTTP 200 و ۲۵ درخواست POST با HTTP 502 برای Edge Function ثبت شد. آخرین POST ناموفق `09:20:59 UTC` بود. لاگ gateway بدنه خطا را ندارد؛ علت دقیق ۵۰۲ (providerها در برابر cache/write) هنوز اثبات نشده است.
- [!] جدول‌های قیمت تومانی خالی‌اند؛ observationهای کشف فهرست بازار قیمت قابل اتکا محسوب نمی‌شوند. نمونه‌های Kifpool شامل `priceSellIRT` و `priceChangePercent` هستند، اما همچنین نمادهای سهامی مانند AALON/ACNON دیده شدند؛ تطبیق با کاتالوگ رمزارز و تأیید واحد/معنای bid/ask پیش از استفاده لازم است.
- [x] گزارش تفصیلی در `docs/TOMAN_MARKET_FEED_AUDIT_2026-11-22.md` ثبت شد.
- [x] این نوبت فقط خواندن GitHub/Supabase، بررسی schema و لاگ و مستندسازی بود. هیچ Edge Function deploy، RPC مالی، Migration، cron یا تغییر داده‌ای در Production انجام نشد.
- [ ] گام بعد: قرارداد و fixtureهای Bit24 و Kifpool را بررسی؛ adapterهای چهار منبع و آزمون‌های واحد/stale/timeout/partial failure را در CI آماده کن؛ logging ساختاریافته برای تفکیک علت ۵۰۲ اضافه کن. استقرار Production فقط پس از تأیید صریح کاربر.


## اصلاح مسیر ذخیره قیمت تومانی و علت تکرار 502 — ۲۳ نوامبر ۲۰۲۶
- [x] وضعیت Production فقط‌خواندنی بررسی شد: جدول `market_toman_prices` قید یکتای `(exchange, asset_symbol, quote_currency)` دارد؛ تابع قبلی هر بار POST ساده بدون `on_conflict` و بدون `resolution=merge-duplicates` ارسال می‌کرد.
- [x] snapshot فعلی: ۳۷۳ ردیف قیمت جاری و ۳۷۳ ردیف تاریخچه؛ آخرین زمان هر دو `2026-11-17 22:04:26 UTC`. داده‌های فعلی چند روز stale هستند.
- [x] در ۲۴ ساعت منتهی به `2026-11-22 23:14 UTC` تعداد ۲۱ POST با HTTP 502 و ۲۱ OPTIONS موفق برای Edge Function ثبت شد. POSTها `EDGE_FUNCTION_ERROR` داشتند؛ زمان اجرا حدود ۲٫۸ تا ۷٫۳ ثانیه بود. log داخلی قبلی علت providerها را تفکیک نمی‌کرد.
- [!] قید یکتا در کنار POST ساده، مسیر شکست قطعی هنگام تکرار کلیدهای موجود ایجاد می‌کند؛ این توضیح قوی برای stale ماندن قیمت‌هاست، هرچند خطاهای مستقل provider نیز ممکن است وجود داشته باشند.
- [x] اصلاح GitHub: upsert با `on_conflict=exchange,asset_symbol,quote_currency` و `Prefer: resolution=merge-duplicates,return=minimal`؛ حذف duplicateهای داخل batch بر اساس همان کلید؛ logging ساختاریافته و بدون پیام خام upstream/اطلاعات احراز هویت.
- [x] آزمون‌های Node برای dedupe، درخواست upsert و خلاصه امن خطاها اضافه شد؛ fixture PostgreSQL 17 با درج تکراری و rollback به CI افزوده شد.
- [!] اصلاح فقط در GitHub است؛ تابع Production هنوز نسخه ۳ است. هیچ deploy، refresh واقعی، یا نوشتن/حذف داده در Production انجام نشده است.
- [x] اجرای نهایی CI شماره `45082751825` موفق شد. [ ] گام بعد: Bit24/Kifpool را فقط پس از تأیید قرارداد API و سپس استقرار تابع فقط با تأیید صریح کاربر ادامه بده.


### نتیجه نهایی CI اصلاح upsert قیمت تومانی — ۲۳ نوامبر ۲۰۲۶
- [x] اجرای اول `45082686169` روی commit `c452d1e` یک خطای تست واقعی در دسته‌بندی HTTP نشان داد: regex به‌صورت double-escaped ذخیره شده بود و `HTTP 429` به `provider_error` تبدیل می‌شد.
- [x] اصلاح regex در commit `fe151109a9fd46c38a317f305785f0eb95449ee0` ثبت و فایل از `main` دوباره دریافت و تأیید شد.
- [x] اجرای نهایی `45082751825` روی commit `fe151109` با نتیجه `success` کامل شد؛ آزمون‌های Node/browser، آزمون PostgreSQL 17 برای upsert تکراری، تمام آزمون‌های widening، Market/Limit/Stop-Limit و آزمون‌های race همگی موفق شدند.
- [!] CI فقط کد مخزن و PostgreSQL دورریختنی را آزمود؛ Edge Function Production هنوز نسخه ۳ است و deploy/refresh واقعی انجام نشده است.

## گزارش اجرای روزانه — ۲۰۲۶-۱۱-۲۳: اصلاح نمایش تازگی بازار تومانی

### تغییر رابط و آزمون رگرسیون
- [x] HEAD مبنا در شروع این اقدام: `968010d37a175b947616167ed265953a2ed6b62c`.
- [x] Commit کد و آزمون: `83f0e3ceedaf7ce69129790a930e3916f5103e35` (`fix(market-ui): report observed Toman source freshness`).
- [x] `index.html`: شمار منبع اکنون از کلیدهای یکتای `exchange` در ردیف‌های واقعاً برگشتی محاسبه می‌شود؛ تعداد ردیف/منبع تازه و بیشترین `fetched_at` نمایش داده می‌شود. زمان خواندن مرورگر دیگر به‌جای زمان دریافت بازار معرفی نمی‌شود.
- [x] `tests/index-syntax.test.js`: آزمون مستقل helper برای تکرار منبع، تفاوت حروف بزرگ/کوچک، ردیف stale و timestamp واقعی اضافه شد.
- [x] اجرای Exact Decimal Run #1677، شناسه `45165054735`، روی همین commit شروع شد؛ مرحله Node/browser regression موفق است. در زمان ثبت این گزارش، مرحله PostgreSQL 17 و ادامه آزمون‌های مالی هنوز در حال اجرا بود؛ نتیجه کامل CI تا پایان آن ادعا نمی‌شود.
- [x] Android Build #193، شناسه `45165054765`، روی همین commit با نتیجه SUCCESS پایان یافت. Artifact: `14812559044`، حجم 3,524,865 bytes، SHA-256 `d0ad577bf805bc5b95b4037fdbad5efb5509a6f8465af9b18c12ab83706ed9ce`، انقضا `2026-12-07T11:26:38Z`. APK debug است؛ نصب فیزیکی روی Android هنوز آزمایش نشده است.

### Supabase Production — بررسی فقط‌خواندنی در ۲۳ نوامبر
- [x] پروژه `gfoaubfilhttnwjykaox` در `ACTIVE_HEALTHY` و PostgreSQL `17.11.0.018`؛ Migration ledger برابر ۵۵ و آخرین نسخه `20261121050216`.
- [x] Edge Function `refresh-toman-market-prices` در Production هنوز نسخه ۳ است. بدنه زنده هنوز POST ساده به `market_toman_prices` می‌فرستد و helperهای upsert/dedupe موجود در main را ندارد.
- [x] لاگ ۲۴ ساعت اخیر برای این تابع: ۲۳ درخواست POST با HTTP 502 و ۲۳ درخواست OPTIONS با HTTP 200. بنابراین ۲۰۰ها موفقیت refresh نیستند؛ فقط preflight هستند.
- [x] شمارش فقط‌خواندنی `market_toman_prices`: نوبیتکس ۲۲۱ ردیف و والکس ۱۵۲ ردیف؛ آخرین `fetched_at` برای هر دو `2026-11-17 22:04:26.622 UTC` و سن حدود ۸۰۰۰ دقیقه. در جدول قیمت جاری ردیفی از Bit24 یا Kifpool وجود ندارد.
- [x] Health Advisor بدون یافته بود. هشدارهای Security/Performance همچنان نیازمند بازبینی برنامه‌ریزی‌شده‌اند؛ هیچ grant، policy، index، Auth setting یا تابع Production تغییر نکرد.
- [!] کد اصلاح upsert در GitHub و تست PostgreSQL دورریختنی موجود است، اما تا استقرار صریحاً تأیید نشود، داده زنده همچنان تحت تأثیر تابع نسخه ۳ است.
- [x] هیچ refresh، worker، RPC مالی، Migration یا نوشتن/حذف داده‌ای در Production اجرا نشد؛ هیچ سفارش، معامله، رزرو، کیف پول، موجودی یا سابقه مالی تغییر نکرد.

### گام بعد
1. نتیجه نهایی Run #1677 را بررسی و فقط پس از پایان همه jobهای PostgreSQL/Stop-Limit وضعیت CI را SUCCESS اعلام کن.
2. قرارداد API رسمی Bit24 و Kifpool، معنای bid/ask، واحد تومان/ریال، نرخ‌محدودیت و مجوز استفاده از endpoint را مستند و fixture تهیه کن؛ تا پیش از آن adapter یا endpoint حدسی اضافه نشود.
3. اصلاح upsert تابع Production فقط پس از تأیید صریح کاربر deploy شود؛ سپس refresh واقعی صرفاً در چارچوب تأیید جداگانه و بدون اجرای هیچ RPC مالی انجام شود.


## گزارش تضمین کیفیت شبانه — ۲۰۲۶-۱۱-۲۴

### وضعیت تازه در آغاز نوبت
- HEAD شاخه `main` در شروع: `c7b024fc56a5e5004f8b1fbb49c71ad2fd8cab39`. آخرین تغییرات از checkpoint قبلی شامل اصلاح نمایش تازگی بازار در `83f0e3c` و ثبت گزارش آن در `c7b024f` بود؛ این نوبت آن تغییر را تکرار نکرد.
- Supabase Production `gfoaubfilhttnwjykaox`: وضعیت `ACTIVE_HEALTHY`، PostgreSQL 17.11.0.018؛ ۵۵ Migration و آخرین نسخه `20261121050216`.
- زمان‌بندی زنده بازار: job 13 هر ۱۰ دقیقه؛ job 14 در دقیقه‌های ۱ و ۳۱؛ job 17 از دقیقه ۵ و سپس هر ۱۰ دقیقه.
- Edge Function `refresh-toman-market-prices` همچنان نسخه ۳ است؛ بدنه مستقر هنوز POST ساده دارد و helper upsert/dedupe موجود در main را ندارد.
- در پنجره ۲۴ساعته لاگ تابع، ۱۰ درخواست POST با HTTP 502 و ۱۰ درخواست OPTIONS با HTTP 200 ثبت شد؛ آخرین POST در `2026-11-23T14:39:39Z` بود. پاسخ OPTIONS موفقیت دریافت قیمت نیست.
- جدول قیمت جاری ۳۷۳ ردیف دارد: Nobitex تعداد ۲۲۱ و Wallex تعداد ۱۵۲؛ آخرین `fetched_at` برای هر دو `2026-11-17 22:04:26.622 UTC` است. تاریخچه نیز ۳۷۳ ردیف و آخرین ثبت هم‌زمان دارد. تعریف زنده view، داده غیر `iran_market` را پس از ۵ دقیقه stale می‌کند؛ بنابراین قیمت‌های موجود در این snapshot قدیمی‌اند.
- Migration ledger و زمان‌بندی زنده از Production به‌صورت فقط‌خواندنی خوانده شدند؛ هیچ Migration یا تاریخچه‌ای تغییر نکرد.

### اقدام این نوبت: مقاوم‌سازی خطای خواندن بازار تومانی
- [x] در `index.html`، شکست خواندن view بازار دیگر به‌صورت promise ردشده و spinner باقی‌مانده رها نمی‌شود؛ پیام خطای فارسی امن و وضعیت خطا نمایش داده می‌شود و تابع `false` برمی‌گرداند.
- [x] `refreshTomanMarket()` اکنون بین موفقیت ذخیره و شکست بازخوانی جدول تمایز می‌گذارد و در صورت شکست خواندن، پیام موفقیت کاذب نشان نمی‌دهد.
- [x] فقط `is_stale === false` به‌عنوان داده تازه شمرده می‌شود؛ مقدار null/ناموجود با برچسب «وضعیت نامشخص» نمایش داده می‌شود و تازه تلقی نمی‌شود.
- [x] آزمون‌های رگرسیون برای خطای Supabase، جلوگیری از نشت متن خطای داخلی، تازگی نامشخص و تفاوت موفقیت نوشتن/شکست بازخوانی اضافه شد.
- [x] Commit کد: `17e8898eae8ad0ec6a57d54f50e08e7302f3aad2`.
- [x] Commit آزمون: `940cfc2514b59e328c1a87cc66c0d1bc8f94e57c`.
- [x] پس از هر commit فایل مربوطه دوباره از main دریافت و markerهای تغییر تأیید شدند.
- [!] نتیجه CI مربوط به push این نوبت باید از Actions خوانده شود؛ تا پیش از مشاهده نتیجه نهایی، موفقیت CI ادعا نشود.

### محدودیت و ایمنی
- هیچ Edge Function مستقر نشد و هیچ refresh یا worker روی Production اجرا نشد.
- هیچ سفارش، معامله، رزرو، موجودی، کیف پول، تراکنش یا سابقه مالی ایجاد یا تغییر نکرد.
- هیچ Migration، Cron، Grant، Policy، تنظیم Auth یا ایندکسی تغییر نکرد.
- ریسک عملیاتی اصلی پابرجاست: داده تومانی stale است و نسخه ۳ تابع مستقر هنوز 502 می‌دهد. استقرار اصلاح upsert همچنان نیازمند تأیید صریح کاربر است.

### گام بعد
1. وضعیت Actions برای commit آزمون را بررسی کن و هر شکست را فقط در محیط CI دورریختنی اصلاح کن.
2. پیش از هر استقرار، diff کامل نسخه main با تابع مستقر، وابستگی‌ها، verify_jwt و secret usage را بازبینی کن؛ deploy بدون تأیید صریح ممنوع است.
3. پس از تأیید استقرار، ابتدا فقط version و logs را بررسی کن؛ اجرای refresh واقعی جداگانه و با مجوز مستقل انجام شود.
4. بازیابی منابع Migration مفقود و حل اختلاف timestamp پیش از هر db push ادامه یابد.


## گزارش QA و ممیزی schema موتور Stop-Limit — ۲۰۲۶-۱۱-۲۴

### وضعیت مخزن و CI
- [x] HEAD نهایی پیش از ثبت این گزارش: `e782b54e6d9bc953dfbd94127c6aba4a4367401d`.
- [x] Commit `cc4f700269bd2c87cbd592e4c8122e420c9c5988`: افزودن fingerprint فقط‌خواندنی Production و آزمون ایمنی آن، به‌روزرسانی `docs/STOP_LIMIT_QA_MATRIX.md`.
- [x] Commit `e782b54e6d9bc953dfbd94127c6aba4a4367401d`: اصلاح escaping در تست Node fingerprint.
- [x] Exact-decimal Run #1843 (`45377434232`) روی `e782b54` با نتیجه `success` تمام شد؛ تمام مراحل Node/browser و PostgreSQL 17 دورریختنی، از جمله Stop-Limit child execution/cancel race، parent-child lifecycle و TP/SL lifecycle موفق شدند.
- [x] Run #1841 (`45377323145`) روی commit اولیهٔ artifact در مرحلهٔ Node/browser شکست خورد؛ علت، escaping نادرست regex در تست تازه بود. اصلاح در `e782b54` ثبت و Run #1843 سبز شد. شکست اولیه پنهان یا به‌عنوان موفقیت گزارش نشده است.
- [x] Exact-decimal Run #1753 (`45285146268`) روی HEAD قبلی `e5d4af7` نیز موفق بود.

### اقدام اجرایی
- [x] `supabase/audit/stop_limit_schema_fingerprint.sql` اضافه شد. یک query واحد و فقط‌خواندنی است که نسخه PostgreSQL، ستون‌ها، constraints، indexes، triggers، RLS policies، table grants، تعریف و ACL توابع مالی مرتبط، و زمان‌بندی cron را از catalog می‌گیرد.
- [x] `tests/stop-limit-production-audit.test.js` اضافه شد؛ آزمون تضمین می‌کند فایل فقط یک query خواندنی باشد، مستقیماً جدول‌های مالی را scan نکند و تمام اجزای لازم برای fingerprint را پوشش دهد.
- [x] همان query با موفقیت روی Supabase Production اجرا شد؛ فقط metadata و تعریف اشیا خوانده شد، نه ردیف‌های سفارش/معامله/کیف پول.

### وضعیت Supabase Production
- [x] پروژه `gfoaubfilhttnwjykaox`: `ACTIVE_HEALTHY`، PostgreSQL `17.11.0.018`.
- [x] Migration ledger: 55 مورد؛ آخرین نسخه `20261121050216`.
- [x] Development Branchها: فهرست خالی؛ هیچ branch یا پروژهٔ جدیدی ایجاد نشد.
- [x] cron job 8، `digiarz-limit-orders` و job 12، `digiarz-stop-limit-orders` هر دو هر دقیقه زمان‌بندی شده‌اند؛ هیچ‌کدام تغییر یا دستی اجرا نشد.
- [x] `place_stop_limit_order`، `cancel_stop_limit_order` و RPCهای ثبت/لغو TP-SL از نوع SECURITY DEFINER، با owner برابر postgres و search_path خالی‌اند؛ EXECUTE برای authenticated و service_role دارند، نه anon.
- [x] Workerهای `process_stop_limit_orders`، `process_limit_orders` و `process_conditional_orders` فقط برای service_role قابل اجرا هستند؛ anon و authenticated اجازه اجرا ندارند.
- [x] RLS روی orders، conditional_orders، order_reservations، trades، asset_balances، wallets و market_prices فعال است. policyهای جداول مالی کاربرمحور فقط ردیف‌های متعلق به همان کاربر را برای خواندن می‌دهند؛ market_prices خواندن عمومی دارد.
- [x] دو trigger پیش از INSERT روی orders و trades، تابع `private.guard_active_account_writes()` را اجرا می‌کنند.
- [x] Health Advisor بدون یافته است.
- [!] Security Advisor: 15 مورد RLS enabled/no policy، دو SECURITY DEFINER قابل اجرا برای anon، 23 مورد قابل اجرا برای authenticated و محافظت رمزهای افشاشدهٔ غیرفعال. این موارد هشدار/یافتهٔ advisor هستند و به‌تنهایی اثبات سوءاستفاده نیستند؛ هیچ grant، policy یا Auth setting تغییر نکرد.
- [!] Performance Advisor: 9 foreign key بدون index پوشاننده، 11 مورد auth_rls_initplan، دو جدول بدون primary key و 13 index بدون استفاده. هیچ index یا policy تغییر نکرد.

### بازبینی ساختار رابط کاربری
- [x] `index.html` شاخه main از نظر ساختار ایستا بررسی شد: 244 شناسه یکتا و بدون تکرار؛ 9 مقدار مسیر صفحه شامل dashboard، markets، toman، trade، orders، assets، history، settings و admin.
- [x] PR #60 با عنوان Phase 1 independent UI layer در حالت Draft باز است؛ شاخه `redesign/phase1-clean-2026`، آزمون CI شماره 1840 موفق. این تغییرات UI هنوز merge نشده و هیچ merge یا انتشار انجام نشد.

### دروازه‌های باز و گام بعد
1. fingerprint فعلی فقط snapshot metadata است؛ هنوز harness کامل PostgreSQL 17 با DDL/ACL دقیق Production ساخته نشده است. گام بعد: تولید fixture ایزوله از fingerprint و تطبیق با migration/source قبل از اجرای source-faithful Stop-Limit.
2. چرخهٔ parent Stop-Limit → child Limit باید در harness منطبق با Production با partial/full fill، لغو، مصرف/آزادسازی reservation، idempotency و race هم‌زمان دوباره اجرا شود.
3. Development Branch Supabase در دسترس نیست؛ ایجاد branch/project جدید و هزینه احتمالی بدون تأیید انجام نمی‌شود.
4. UI PR #60 پس از آزمون بصری WebView/Android بازبینی شود؛ تا قبل از تأیید و QA بصری، merge نشود.

### مرز ایمنی
- هیچ سفارش، معامله، reservation، wallet، balance، transaction یا سابقهٔ مالی Production ایجاد یا تغییر نکرد.
- هیچ worker یا RPC مالی روی کاربر واقعی اجرا نشد.
- هیچ migration، deploy، cron، grant، policy، Auth setting یا انتشار APK انجام نشد.


## Nightly QA — protect Toman current-price rows from partial provider snapshots — 2026-11-25

### Fresh starting state
- [x] Re-read `main`, the latest commits, `IMPLEMENTATION_STATUS.md`, tests, and the live Supabase project before making changes. Starting HEAD: `394c4dd9922cb2cdfa3d14e1a354a09c38840999`.
- [x] The latest completed work from 2026-11-24 was the Stop-Limit production schema fingerprint and its read-only safety test. That work was not repeated.
- [x] Production project `gfoaubfilhttnwjykaox` is `ACTIVE_HEALTHY`, PostgreSQL `17.11.0.018`; migration ledger contains 55 entries and latest version is `20261121050216`.
- [x] `refresh-toman-market-prices` is still deployed at version 3 with `verify_jwt=true`. Its deployed source still uses the older plain POST and destructive current-price cleanup. The main-branch source already uses upsert, but still contained the same cleanup block before this fix.
- [x] The live `market_toman_performance` view selects the latest row per exchange/asset and marks non-`iran_market` data stale after five minutes. Retaining older rows therefore preserves a truthful stale marker instead of presenting them as fresh.
- [x] Security Advisor: 15 RLS-enabled/no-policy findings, 2 anon-executable SECURITY DEFINER functions (`get_admin_market_listings`, `get_exchange_discovered_market_assets`), 23 authenticated-executable SECURITY DEFINER findings, and leaked-password protection disabled. Health Advisor returned no findings. Performance Advisor reported 9 unindexed foreign keys, 11 RLS initplan warnings, 2 backup tables without primary keys, and 13 unused indexes.
- [x] The 2 anon-executable functions remain a separate security-review item; no grants or function privileges were changed.

### Priority gap and correction
- [x] Found a destructive path in `refresh-toman-market-prices/index.ts`: after accepting any non-empty set of fulfilled provider rows, the function deleted every older current-price row for each exchange represented in that batch.
- [!] Because provider calls use `Promise.allSettled` and individual source responses can be partial/truncated while still non-empty, the returned rows do not prove a complete exchange snapshot. The cleanup could therefore delete valid symbols omitted from a partial response.
- [x] Removed automatic DELETE cleanup from the GitHub source. Omitted rows are retained and the existing performance view marks old `fetched_at` values stale. A separate reviewed retention policy can be designed later if table growth warrants it.
- [x] Added a regression test that rejects the destructive DELETE path and confirms the handler retains omitted rows.
- [!] This is a repository-only correction. Production Edge Function version 3 has not been deployed or changed.

### Files and commits
- `supabase/functions/refresh-toman-market-prices/index.ts` — remove automatic stale-row deletion.
- `tests/toman-market-persistence.test.js` — guard against reintroducing DELETE cleanup.
- Commits are recorded in the GitHub commit history for this section; file contents and blob SHAs were re-fetched after each commit.

### Verification and safety
- [x] The exact `market_toman_performance` view definition was read-only inspected; it marks non-Iran-market rows stale after five minutes.
- [x] The Stop-Limit production fingerprint SQL was executed as a read-only catalog query; it reads schema metadata and cron metadata, not order/trade/wallet/reservation rows.
- [x] GitHub Actions Run #1964 (`45503827911`) on final code/test commit `0baf402c211bc8165057bdd1323cd17c52d9f797` completed with `success`; all 25 steps passed, including Node/browser, PostgreSQL 17, Toman upsert, exact-decimal widening, Market/Limit, Stop-Limit/TP-SL lifecycle and two-session race tests.
- [ ] Deno type-check / deployed-function parity has not been run in this turn.
- [x] No Supabase migration, function deployment, refresh invocation, worker/RPC, cron, grant, policy, Auth setting, or financial row was changed.
- [x] No order, trade, reservation, wallet, balance, transaction, or financial-history data was created, updated, or deleted.

### Next steps
1. Review the two anon-executable SECURITY DEFINER functions and verify they expose only intentionally public market metadata; do not change grants until owner approval.
2. Add an explicit bounded-retention design only if stale-row growth becomes material; it must never prune based on a non-empty partial provider response.
3. Deploy the corrected Edge Function only after explicit user approval; then separately authorize any real refresh operation.
4. Continue reconstructing the missing migration sources and exact Production-to-test PostgreSQL 17 parity before full source-faithful Stop-Limit lifecycle testing.


### Regression-guard correction — 2026-11-25
- [x] Re-read the newly committed test and tightened its source guard to match the SQL/HTTP verb token `DELETE` directly, avoiding an over-escaped whitespace pattern.
- [x] Test file re-fetched after commit and exact content verified.
- [x] Final GitHub Actions Run #1964 (`45503827911`) completed with `success` on `0baf402`; the tightened `DELETE` regression guard passed in the Node/browser step and all remaining PostgreSQL lifecycle steps passed.


## Daily execution report — 2026-11-25 — Stop-Limit Production-source QA

### Verified starting state
- Re-read GitHub `main`, `IMPLEMENTATION_STATUS.md`, `docs/STOP_LIMIT_QA_MATRIX.md`, workflow, migrations, tests, and UI structure. Starting `main` HEAD was `ebaa65e69c0c981f9af08180ec789abcf84330f1`; no prior chat note was treated as current state.
- The exact-decimal CI Run #1964 (`45503827911`) was independently rechecked as successful on `0baf402`.
- UI static inventory: `index.html` is 492,996 bytes with 244 unique IDs, 9 navigation routes (`dashboard`, `markets`, `toman`, `trade`, `orders`, `assets`, `history`, `settings`, `admin`), RTL direction, and viewport metadata. `src/` contains `daily-ads.js`, `decimal.js`, `market-holdings.js`, and `pwa-install.js`. No UI file was changed in this Stop-Limit-focused run.
- Supabase `gfoaubfilhttnwjykaox` remains `ACTIVE_HEALTHY`, PostgreSQL `17.11.0.018`; ledger 55, local migration files 40, no Development Branch. Reconciliation still reports 17 applied SQL sources missing locally, 20 timestamp mismatches, and two local-only older market-price function replacements; `db push` remains unsafe.
- Live jobs 8 (`digiarz-limit-orders`) and 12 (`digiarz-stop-limit-orders`) remain active every minute. No worker was manually invoked.
- Aggregate-only Production counts: orders 0, trades 0, reservations 0, conditional orders 0. No financial row was read.
- Current Stop-Limit ACL snapshot: placement/cancel RPCs are executable by `authenticated` and `service_role`, not `anon`; `process_stop_limit_orders` is executable by `service_role` only. Active-account INSERT triggers remain on `orders` and `trades`.

### Work completed
- Captured the live `process_stop_limit_orders()` definition as a test-only SQL snapshot. The read-only catalog fingerprint recorded in Production is `66357ab4a2247019f22a8b6ab6eac6fe`; the snapshot is not a migration and was never applied to Production.
- Added a fail-fast `place_limit_order` sentinel and a disposable PostgreSQL regression for the Production worker's invalid-reservation branch. Ten separate autocommit calls must reject the parent and conditional order after attempt 10, retain the manual-review reason, create no child order, and leave invalid reservation arithmetic untouched.
- Added a Node source-parity test that verifies the captured worker contract, equality of the draft worker and current CI fixture, and explicitly distinguishes their child-row lock scope from Production.
- Added a dedicated PostgreSQL 17 disposable CI step and updated `docs/STOP_LIMIT_QA_MATRIX.md` with the live evidence and remaining gates.

### Important source-parity finding
- Production's synchronization query locks `conditional_orders` and the parent `orders` row (`FOR UPDATE OF c,parent SKIP LOCKED`); it reads but does not include the child row in that lock list.
- The draft and CI fixture use `FOR UPDATE OF c,parent,child SKIP LOCKED`. Their normalized bodies match each other, but not this Production lock scope. This is a concurrency-semantic difference requiring review; it is not being labeled a defect or deployed automatically.
- The new Production snapshot regression covers the fail-closed invalid-reservation branch only. Full valid trigger → child Limit execution still uses the draft candidate because the authoritative `place_limit_order` source and complete base DDL are not yet locally recoverable.

### CI result and commit trail
- Exact-decimal workflow Run #1974 (`45602256035`) completed with `success` on `e9339bdc662a35612b54b78dda5d7168dbcdf4b8`. Node/browser tests, existing PostgreSQL 17 arithmetic/lifecycle/race steps, and the new captured-Production invalid-reservation regression all passed.
- Initial runs #1970–#1973 exposed test-harness regex/SQL-terminator/fingerprint-extraction issues; these were corrected before Run #1974. Do not treat those failed attempts as successful evidence.
- Main commits for this work include `dd55b71` (Production worker snapshot), `7907411` (retry-exhaustion regression SQL), `1a3285e` (source-parity test), `42b769a` (fail-fast sentinel), `772985c` (workflow step), `22e84a7` / `f43f4f4` / `47ff5f1` / `e9339bd` (test corrections), and `b11b752` (QA matrix update).

### Other current blocker — Toman market
- Production Edge Function `refresh-toman-market-prices` is still deployed at version 3. Its live source still contains a DELETE cleanup path and uses Nobitex, Wallex, and Bitpin; Bit24 and Kifpool are not connected in this function.
- `market_toman_prices` and history each contain 373 rows, but the newest current-price `fetched_at` is 2026-11-17 and none are fresh within five minutes. In the last 24-hour log window, the function had 37 POST 502 responses and 37 OPTIONS 200 preflights.
- The safer no-prune/upsert source on GitHub is not deployed. No deployment or refresh was attempted because Production deployment requires explicit approval.

### Safety and next steps
- No Production order, trade, reservation, wallet, balance, transaction, migration, grant, RLS policy, function, cron job, or Edge Function was changed. Only aggregate counts and catalog metadata were read; all new financial-path tests ran in disposable GitHub Actions PostgreSQL 17.
1. Recover the authoritative missing `place_limit_order` and base-schema SQL from a trusted deployment artifact/backup; do not reconstruct from names or draft files.
2. Build a complete disposable PostgreSQL 17 schema/ACL parity harness, then test the exact Production worker's valid trigger, child Limit placement, partial/full fills, cancellation, idempotency, and two-session races.
3. Review the Production-versus-candidate child-row lock difference before proposing any migration.
4. Keep `supabase db push`, function deployment, grant/policy changes, and all Production financial writes blocked pending explicit approval.
5. After the Stop-Limit gate, return to the Toman market page/provider work and the four approved Iranian sources; do not report stale prices as live.


## گزارش تضمین کیفیت شبانه — ۲۰۲۶-۱۱-۲۶ — ثبت منبع واقعی RPCهای Limit

### وضعیت آغاز
- HEAD شاخه `main` در شروع این نوبت: `16913f81808c022351c05fa12c69e649db552b39`.
- آخرین کار تکمیل‌شده، آزمون شاخه fail-closed مربوط به worker واقعی Stop-Limit و ثبت تفاوت lock scope بین worker Production و candidate بود؛ تکرار نشد.
- Supabase `gfoaubfilhttnwjykaox` در وضعیت `ACTIVE_HEALTHY` و PostgreSQL `17.11.0.018` است؛ ledger برابر ۵۵ Migration و آخرین نسخه `20261121050216`.
- CI Run #1974 (`45602256035`) روی commit `e9339bd` دوباره خوانده شد؛ هر ۲۲ مرحله اصلی و cleanup موفق‌اند.
- Worker زنده `process_stop_limit_orders()` همچنان fingerprint برابر `66357ab4a2247019f22a8b6ab6eac6fe` دارد؛ بنابراین snapshot ثبت‌شده در نوبت قبل هنوز با تعریف زنده منطبق است.
- Cron job 8 و 12 فعال‌اند و هر دو هر دقیقه زمان‌بندی شده‌اند؛ هیچ‌کدام دستی اجرا نشدند.

### شکاف اولویت‌دار
- آزمون جدید Production-source قبلی فقط بدنه واقعی `process_stop_limit_orders()` و شاخه invalid-reservation را پوشش می‌داد.
- دو entrypoint واقعی که worker/لغو Stop-Limit به آن‌ها وابسته‌اند، یعنی `place_limit_order()` و `cancel_limit_order()`، هنوز snapshot منبع Production و guard مستقل در CI نداشتند. در نتیجه lifecycle کامل candidate به‌تنهایی parity واقعی این دو RPC را اثبات نمی‌کرد.

### اقدام انجام‌شده در GitHub
- [x] تعریف زنده هر دو RPC با یک SELECT از `pg_proc` و `pg_get_functiondef` خوانده شد؛ هیچ جدول سفارش، معامله، رزرو، موجودی یا کیف پول خوانده نشد.
- [x] fingerprintهای زنده ثبت شدند: `place_limit_order=3eab167c47bf8ff2e1705b9f243380ec` و `cancel_limit_order=69360684173b6aabebc5ff4e4de2eed9`.
- [x] مالک هر دو `postgres`، نوع هر دو `SECURITY DEFINER` و `search_path` خالی تأیید شد.
- [x] ACL هر دو: `anon=false`، `authenticated=true`، `service_role=true`.
- [x] دو snapshot صرفاً آزمایشی در `supabase/tests/stop_limit_production_place_limit_order_snapshot.sql` و `supabase/tests/stop_limit_production_cancel_limit_order_snapshot.sql` اضافه شد. هر دو header صریح دارند که migration نیستند و نباید روی Production اجرا شوند.
- [x] آزمون Node جدید برای fingerprint دقیق و قراردادهای امنیت/حسابداری مهم اضافه شد: احراز هویت از `auth.uid()`، فعال بودن حساب، pair مجاز، قفل ردیف wallet/asset، محاسبه رزروهای فعال، درج atomic سفارش و رزرو، لغو user-scoped و آزادسازی دقیق مانده رزرو.
- [x] workflow موجود از طریق `node --test tests/*.test.js` آزمون جدید را خودکار کشف می‌کند؛ workflow تغییر نکرد.
- [!] نتیجه CI کامیت‌های این نوبت تا زمان بازخوانی run جدید تأیید نشده و موفقیت آن ادعا نمی‌شود.

### فایل‌ها
- `supabase/tests/stop_limit_production_place_limit_order_snapshot.sql`
- `supabase/tests/stop_limit_production_cancel_limit_order_snapshot.sql`
- `tests/stop-limit-production-entrypoint-source.test.js`
- `docs/STOP_LIMIT_QA_MATRIX.md`
- `IMPLEMENTATION_STATUS.md`

### محدودیت‌ها و ایمنی
- این تغییر منبع دو RPC را برای QA قابل بازبینی می‌کند؛ جایگزین base DDL مفقود و harness کامل PostgreSQL 17 با schema/ACL دقیق Production نیست.
- ۱۷ منبع Migration اعمال‌شده هنوز در main فایل SQL ندارند، ۲۰ اختلاف timestamp و دو فایل local-only پرریسک همچنان باز هستند؛ `supabase db push` ایمن نیست.
- هیچ RPC/worker روی Production اجرا نشد؛ هیچ سفارش، معامله، رزرو، موجودی، کیف پول یا سابقه مالی ایجاد/تغییر نشد.
- هیچ Migration، تابع، grant، policy، cron، Edge Function یا تنظیم Auth تغییر نکرد.

### گام بعد
1. CI اجراشده روی commit جدید را از GitHub Actions بازخوانی کن؛ در صورت شکست فقط آزمون source-contract را اصلاح کن.
2. منبع معتبر DDL جداول `orders`, `order_reservations`, `wallets`, `asset_balances`, `conditional_orders` و trigger/constraintهای وابسته را از artifact یا migration معتبر بازیابی کن.
3. پس از بازیابی schema، snapshotهای واقعی `place_limit_order`, `cancel_limit_order` و worker را در PostgreSQL 17 دورریختنی اجرا کن؛ سپس partial/full fill، cancel/trigger race و idempotency را روی همان source اجرا کن.
4. اختلاف قفل child row در worker Production (`c,parent`) با candidate (`c,parent,child`) را جداگانه تحلیل کن؛ بدون تأیید، Production را تغییر نده.
5. `db push`، deploy تابع و هر تغییر مجوز حساس همچنان مسدود بماند.


### پس‌آزمون محلی و بازبینی نهایی — ۲۰۲۶-۱۱-۲۶
- [x] محتوای سه فایل جدید از main دریافت شد و با نسخه‌های محلی آزمون از طریق Git blob SHA تطبیق byte-for-byte داشت: test `2cadc6bc7773a15a458b648557c4d15efc249bd2`، snapshot ثبت Limit `9e9d619196bc9ce4104d6208aed7cbe853465d18`، snapshot لغو Limit `18c363097173939429756f56fe9773e554937f39`.
- [x] `node --check` با Node.js `v22.16.0` روی همان محتوای دقیق آزمون موفق شد.
- [x] `node --test` برای `stop-limit-production-entrypoint-source.test.js` اجرا شد: ۵ آزمون، ۵ موفق، صفر شکست.
- [x] تطبیق مستقیم snapshotهای GitHub با خروجی تازه `pg_get_functiondef` در Production نیز byte-for-byte موفق شد؛ fingerprintها و ACLهای ثبت‌شده با وضعیت زنده برابرند.
- [!] GitHub Combined Status برای کامیت نهایی در این اتصال خالی برگشت و ابزار workflow فقط اجراهای pull-request را نمایش می‌دهد؛ بنابراین نتیجهٔ push-triggered CI برای کامیت‌های جدید هنوز قابل تأیید نیست. CI قبلی Run #1974 روی commit `e9339bd` موفق بود، اما آن را به این commitهای جدید تعمیم نمی‌دهیم.


## تکمیل منبع‌وفاداری Worker سفارش Limit برای QA Stop-Limit — ۲۰۲۶-۱۱-۲۶

### وضعیت مبنا و اقدام
- HEAD شاخه `main` پیش از این اقدام: `9855d6ea6cd188a5621c4e2c28c55e4cfb4d2587`.
- Supabase `gfoaubfilhttnwjykaox` در وضعیت `ACTIVE_HEALTHY` و PostgreSQL `17.11.0.018`؛ ledger برابر ۵۵ Migration و آخرین نسخه `20261121050216`.
- تعریف زنده `public.process_limit_orders()` فقط از کاتالوگ PostgreSQL خوانده شد؛ fingerprint برابر `00ab429596fb99392666632967cde9c0`.
- مالک `postgres`، `SECURITY DEFINER`، `search_path=""` و ACL تأیید شد: `anon=false`، `authenticated=false`، `service_role=true`.
- [x] snapshot صرفاً آزمایشی در `supabase/tests/stop_limit_production_process_limit_orders_snapshot.sql` ثبت شد.
- [x] آزمون source-contract در `tests/stop-limit-production-limit-worker-source.test.js` اضافه شد: fingerprint، قفل advisory و ردیف سفارش، حساب فعال، جفت فعال، تازگی قیمت، اعتبار رزرو، قفل کیف پول، fill حداکثر ۲۵٪، و ثبت order/reservation/trade/transaction را بررسی می‌کند.
- [x] آزمون عمداً شکاف فعلی quantization تسویه USDT را نیز ثبت می‌کند: `v_gross` و `v_fee` بدون round صریح هشت‌رقمی محاسبه می‌شوند. این مورد هنوز اصلاح نشده و باید پیش از rollout مالی بازبینی شود.
- [x] Exact-decimal Run #2062 (`45717025545`) روی HEAD قبلی `9855d6e` موفق بود؛ نتیجه آن به commit جدید تعمیم داده نمی‌شود.

### محدودیت و ایمنی
- این snapshot برای QA است، migration نیست و روی Production اجرا نشده است.
- هیچ worker/RPC مالی اجرا نشد و هیچ سفارش، معامله، رزرو، موجودی، کیف پول یا سابقه مالی خوانده/تغییر داده نشد.
- هیچ schema، migration، grant، RLS، cron، Edge Function یا تنظیم Auth تغییر نکرد.
- هنوز ۱۷ منبع SQL از ۵۵ Migration اعمال‌شده در مخزن موجود نیست و ۲۰ اختلاف timestamp باز است؛ Development Branch ایزوله نیز در پروژه فعلی موجود نیست. ساخت محیط کامل source-faithful همچنان مسدود به بازیابی DDL معتبر است.

### نتیجه و گام بعد
- نتیجه CI برای آزمون تازه پس از push باید جداگانه بررسی شود.
- سپس DDL پایه جداول مالی و trigger/constraintهای وابسته از منبع معتبر بازیابی و harness PostgreSQL 17 دورریختنی ساخته شود.
- اجرای جزئی/کامل، لغو، idempotency و raceهای parent-child فقط در همان محیط ایزوله انجام شود.
- پیش از هر انتشار، محاسبه و quantization هشت‌رقمی USDT در worker بازبینی و با آزمون حسابداری مستقل اثبات شود.


### نتیجه CI و بازبینی داده بازار — ۲۰۲۶-۱۱-۲۶
- [x] Exact-decimal Run #2111 (`45811382494`) روی commit `882591331c8d303c4d4eeb95ebc7f99e2efeb731` با نتیجه `success` پایان یافت. مرحله Node/browser و تمام ۲۲ مرحله اصلی PostgreSQL 17، شامل Limit worker، لغو، raceهای دو نشست، Stop-Limit parent/child، regression شاخه invalid-reservation و TP/SL موفق شدند؛ cleanup نیز موفق بود.
- [x] آزمون source-contract تازهٔ `process_limit_orders()` در مرحله Node/browser اجرا شد؛ این آزمون فقط snapshot منبع را بررسی می‌کند و Worker زنده را اجرا نمی‌کند.
- [!] همهٔ سناریوهای چرخه کامل در PostgreSQL دورریختنی GitHub Actions اجرا شده‌اند؛ این نتیجه جایگزین محیط Supabase ایزوله با schema/ACL دقیق Production نیست.
- [!] شکاف quantization تسویه USDT در تابع زنده `process_limit_orders()` همچنان باز است: gross و fee بدون round صریح ۸ رقمی محاسبه می‌شوند. هیچ اصلاحی روی Production انجام نشده است.
- [x] بازبینی فقط‌خواندنی بازار تومانی: `market_toman_prices` شامل ۳۷۳ ردیف است (نوبیتکس ۲۲۱، والکس ۱۵۲)؛ آخرین `fetched_at` برابر `2026-11-17 22:04:26 UTC` و تعداد ردیف تازه در ۵ دقیقه صفر است.
- [x] لاگ ۲۴ ساعت اخیر تابع Production `refresh-toman-market-prices` نسخه ۳: تعداد ۱۵ درخواست POST با 502 و ۱۶ درخواست OPTIONS با 200. پاسخ OPTIONS موفقیت دریافت/ذخیره قیمت را ثابت نمی‌کند.
- [!] تابع Production هنوز سه provider نوبیتکس/والکس/بیت‌پین و مسیر DELETE دارد؛ نسخه main از upsert بدون prune استفاده می‌کند، اما هنوز بیت‌۲۴ و کیف پول من در این تابع متصل نشده‌اند. هیچ Deploy یا refresh دستی انجام نشد.

### گام بعد
1. بازیابی DDL معتبر جداول مالی و trigger/constraintهای پایه؛ سپس ساخت harness PostgreSQL 17 با تطبیق schema/ACL.
2. بررسی و طراحی اصلاح quantization تسویه USDT برای Worker واقعی، با آزمون‌های مرزی gross/fee/net و رزرو؛ بدون تغییر Production.
3. پس از دروازه Stop-Limit، بازگشت به اتصال چهار منبع قیمت تومانی و اصلاح مسیر UI؛ داده کهنه نباید زنده نمایش داده شود.


## ممیزی حسابداری تسویه Limit و وضعیت زنده بازار — ۲۰۲۶-۱۱-۲۷

### مبنای تازه
- [x] HEAD شاخه `main` هنگام بررسی: `6916b940f63877f0f2589ad1652791b85e01d823`؛ آخرین تغییر قبل از این ممیزی ثبت نتیجه CI برای Worker بود.
- [x] Supabase `gfoaubfilhttnwjykaox` در وضعیت `ACTIVE_HEALTHY` و PostgreSQL `17.11.0.018` است؛ ledger زنده ۵۵ Migration دارد و آخرین نسخه `20261121050216` است.
- [x] منبع زنده `public.process_limit_orders()` دوباره با `pg_get_functiondef` خوانده شد؛ MD5 همچنان `00ab429596fb99392666632967cde9c0` است. مالک `postgres`، `SECURITY DEFINER`، `search_path=""` و ACL برابر `anon=false`، `authenticated=false`، `service_role=true` تأیید شد.
- [x] نوع ستون‌ها از `information_schema.columns` فقط‌خواندنی بررسی شد: `wallets.balance_usdt numeric(24,8)`، `transactions.amount numeric(24,8)`؛ سه ستون `order_reservations.reserved_amount/consumed_amount/released_amount` از نوع `numeric` بدون typmod هستند.
- [x] یک محاسبهٔ فقط‌خواندنی با ثابت‌های ساختگی و بدون خواندن هیچ ردیف کاربر اجرا شد. با موجودی شروع `100.00000000` و fill برابر `0.000000005`، ذخیرهٔ موجودی پس از تفریق و cast به `numeric(24,8)` برابر `100.00000000` باقی می‌ماند (کاهش ثبت‌شده صفر)، مقدار تراکنش cast‌شده `0.00000001` می‌شود و رزرو می‌تواند مقدار دقیق `0.000000005` را مصرف‌شده ثبت کند. این مثال اختلاف مقیاس ذخیره‌سازی را اثبات می‌کند؛ وقوع آن در معاملات واقعی یا وجود چنین سفارش‌هایی ادعا نمی‌شود.
- [!] در Worker زنده، `v_gross := v_qty * v_market_price` و `v_fee := v_gross * v_fee_rate` بدون quantization صریح هشت‌رقمی هستند؛ سپس مقدار مصرف رزرو با دقت نامحدود محاسبه می‌شود، درحالی‌که موجودی و دفتر تراکنش فقط هشت رقم اعشار ذخیره می‌کنند. این یک دروازهٔ صحت حسابداری پیش از rollout است، نه مجوز تغییر Worker زنده.
- [x] Candidate آزمایشی `supabase/drafts/2026-11-15_exact_decimal_process_limit_orders.sql` هر fill را به ۸ رقم USDT گرد می‌کند، gross صفرشده را رد می‌کند و رزرو باقی‌مانده را بر مبنای همان مقیاس محاسبه می‌کند. Candidate همچنان Draft است.
- [x] GitHub Actions Exact-decimal Run #2111 (`45811382494`) با نتیجه `success` و ۲۲ مرحله اصلی PostgreSQL 17/Node و cleanup موفق روی commit `882591331c8d303c4d4eeb95ebc7f99e2efeb731` اجرا شده است؛ تست چرخهٔ چهار fill و تطبیق wallet/reservation/transaction روی Candidate موفق بود. این اجرا به HEAD مستندات بعدی تعمیم داده نمی‌شود؛ Combined Status برای HEAD فعلی `6916b94` خالی است.
- [x] وضعیت قیمت تومانی با query فقط‌خواندنی تازه شد: ۳۷۳ ردیف جاری (Nobitex=221، Wallex=152)، آخرین دریافت `2026-11-17 22:04:26.622 UTC` و صفر ردیف تازه در پنج دقیقه. تاریخچه نیز ۳۷۳ ردیف دارد و جدیدترین زمان آن همان timestamp است.
- [x] لاگ‌های ۲۴ ساعت اخیر Edge Function زنده `refresh-toman-market-prices` نسخه ۳: تعداد ۲۲ درخواست POST با 502 و ۲۳ درخواست OPTIONS با 200؛ بازهٔ درخواست‌های ثبت‌شده `2026-11-26 06:43:19 UTC` تا `2026-11-26 19:17:16 UTC`. پاسخ OPTIONS موفقیت refresh را ثابت نمی‌کند. نسخهٔ زنده instrumentation مرحله‌ای نسخهٔ main را ندارد؛ علت دقیق 502 از لاگ‌های فعلی قابل اثبات نشد.
- [x] نسخهٔ main تابع Toman از helperهای dedupe/upsert و بدون DELETE استفاده می‌کند؛ Production هنوز نسخهٔ ۳ قدیمی با مسیر DELETE است. هیچ deploy یا refresh دستی انجام نشد.

### تصمیم QA و گام اجرایی بعد
1. Candidate Worker را فقط در PostgreSQL 17 دورریختنی با schema/constraints/triggers/ACL منطبق با منبع معتبر اجرا کن؛ DDL مفقود Production هنوز باید از backup یا artifact معتبر بازیابی شود.
2. آزمون‌های Buy و Sell را با چند fill، مقدار gross/fee کمتر از ۸ رقم، rounding مرزی، notional صفرشده، dust remainder، overflow و رقابت Worker/Cancellation اجرا کن. برای هر fill باید کاهش واقعی wallet، مقدار transaction و افزایش consumed reservation دقیقاً از یک مبلغ quantize‌شدهٔ مشترک پیروی کنند؛ جمع ledger و رزرو در پایان باید reconcile شود.
3. fingerprint و ACL تابع Candidate را با تابع زنده مقایسه کن و تفاوت‌ها را مستند کن. تا تکمیل این دروازه، هیچ Migration، RPC/Worker Production یا انتشار مالی تغییر نکند.
4. برای Toman، خطاهای 502 را پس از استقرار مجاز نسخهٔ دارای stage logging در محیط تأییدشده ریشه‌یابی کن؛ اتصال Bit24/Kifpool و حذف prune از Production تنها در برنامهٔ انتشار جداگانه و با تأیید مالک انجام شود.

### ایمنی این ممیزی
- [x] هیچ ردیف سفارش، معامله، رزرو، موجودی، کیف پول یا تراکنش کاربر برای تست خوانده یا تغییر داده نشد.
- [x] هیچ Worker یا RPC مالی اجرا نشد؛ SQL محاسباتی فقط روی ثابت‌های ساختگی بود.
- [x] هیچ Migration، Grant، Policy، Cron، Edge Function یا تنظیم Auth تغییر نکرد؛ هیچ داده‌ای حذف نشد و هیچ نسخه‌ای منتشر نشد.


## Limit settlement precision audit and live market status — 2026-11-27

- [x] Fresh main HEAD at review: `6916b940f63877f0f2589ad1652791b85e01d823`.
- [x] Supabase remains `ACTIVE_HEALTHY`, PostgreSQL `17.11.0.018`, 55 migrations, latest `20261121050216`.
- [x] Re-read live `public.process_limit_orders()`: MD5 `00ab429596fb99392666632967cde9c0`; owner postgres, SECURITY DEFINER, empty search_path, EXECUTE denied to anon/authenticated and granted to service_role.
- [x] Read-only column metadata: wallet balance and transaction amount are `numeric(24,8)`; reservation amounts are unconstrained `numeric`.
- [x] A constant-only arithmetic probe (no user rows) demonstrated the scale mismatch: starting wallet 100.00000000 minus a 0.000000005 fill persists as 100.00000000 (zero wallet delta), while a transaction cast to numeric(24,8) is 0.00000001 and the reservation may record 0.000000005 consumed. This demonstrates a possible accounting divergence, not evidence that a real user's order experienced it.
- [!] The live worker computes gross and fee without explicit eight-place quantization before writing to differently scaled wallet, transaction, and reservation columns. Treat this as a financial release gate.
- [x] The draft candidate `supabase/drafts/2026-11-15_exact_decimal_process_limit_orders.sql` rounds each fill's USDT gross/fee and remaining reserve to eight places. Exact-decimal Run #2111 (`45811382494`) passed all 22 substantive PostgreSQL 17/Node steps and cleanup on source commit `882591331c8d303c4d4eeb95ebc7f99e2efeb731`; the four-fill wallet/reservation/transaction reconciliation passed in disposable PostgreSQL. It is not Production evidence.
- [x] Current-price table: 373 rows (Nobitex 221, Wallex 152), newest fetched_at `2026-11-17 22:04:26.622 UTC`, zero fresh within five minutes; history also has 373 rows.
- [x] Production Toman function v3 had 22 POST/502 and 23 OPTIONS/200 in the available 24-hour log window. OPTIONS is not a successful refresh. Exact 502 root cause remains unproven because the deployed v3 lacks the staged diagnostics in main.
- [!] Main Toman source has safe upsert/deduplication and no DELETE; Production v3 still has the old DELETE path. No deploy or manual refresh was attempted.

### Next actions
1. Recover authoritative base DDL and run the draft Limit worker in a disposable PostgreSQL 17 harness with schema/constraint/trigger/ACL parity.
2. Cover Buy/Sell multi-fill, sub-eight-place gross/fee, rounding boundaries, zero-notional, dust, overflow, and worker/cancellation races; assert wallet delta, transaction amount, and consumed reservation all use the same quantized per-fill amount.
3. Compare candidate fingerprint and grants with live metadata. Do not alter Production until the financial gate and explicit owner approval are satisfied.
4. Diagnose Toman 502s using staged logs only after an approved deployment; keep provider expansion and the old Production prune path behind a separate release approval.

- [x] No user financial rows were read or changed for testing; no financial worker/RPC was executed. Only catalog metadata and constant-only arithmetic were queried.
- [x] No migration, grant, policy, cron, Edge Function, Auth setting, deletion, or release was performed.


## اثبات ریشه خطای 502 بازار تومانی و Regression CI — 2026-11-27

### مبنای زنده در ابتدای این نوبت
- HEAD واقعی `main`: `df0a9927451f3b8092997b6d573e62fda235b84d`؛ Check Run مربوط به workflow `exact-decimal` روی همین SHA در `2026-11-26 22:42:21 UTC` با نتیجه `success` پایان یافته است.
- Supabase `gfoaubfilhttnwjykaox`: `ACTIVE_HEALTHY`، PostgreSQL `17.11.0.018`، ۵۵ Migration تا `20261121050216` و بدون Development Branch.
- Edge Function `refresh-toman-market-prices` در Production نسخه ۳ است؛ SHA-256 فایل مستقر `bd85141a8dbe59329235b5266ee391c6953865e97e91253f3e3e3946b155b391`.
- جدول `market_toman_prices` یک unique index روی `(exchange, asset_symbol, quote_currency)` دارد.

### علت 502 اکنون با لاگ PostgreSQL تأیید شد
- در ۲۴ ساعت لاگ قابل‌دسترسی همین Function: ۹ POST با 502 و ۹ OPTIONS با 200.
- در همان بازه ۹ خطای PostgreSQL با SQLSTATE `23505` برای قید `market_toman_prices_exchange_asset_symbol_quote_currency_key` ثبت شد.
- نمونه خطای دقیق: `Key (exchange, asset_symbol, quote_currency)=(nobitex, BTC, TOMAN) already exists.`
- خطای PostgreSQL در `2026-11-26 19:17:15.959 UTC` و POST 502 متناظر در `19:17:16.012 UTC` ثبت شده است.
- SQL ثبت‌شده از PostgREST یک INSERT ساده بدون `ON CONFLICT` است؛ این با منبع مستقر v3 که POST بدون conflict resolution می‌فرستد، منطبق است.

**نتیجه:** علت خطاهای 502 مشاهده‌شده در این بازه، درج تکراری کلید یکتا توسط Function v3 است؛ دیگر صرفاً فرضیه نیست. خطاهای مستقل provider/network در آینده همچنان ممکن‌اند.

### اقدام ملموس این نوبت
- [x] آزمون SQL `supabase/tests/toman_market_upsert_idempotency.sql` گسترش یافت: درج ساده تکراری را روی TEMP TABLE با همان نام قید Production بازتولید می‌کند و SQLSTATE `23505` را assert می‌کند؛ سپس upsert و حفظ یک ردیف/آخرین قیمت/زمان را اثبات می‌کند.
- [x] آزمون Node `tests/toman-market-persistence.test.js` guard جدیدی برای قید، SQLSTATE، conflict target و ROLLBACK دارد.
- [x] Workflow موجود این SQL را در PostgreSQL 17 دورریختنی اجرا می‌کند؛ workflow جدید یا هزینه‌زا ایجاد نشد.
- [x] گزارش ممیزی `docs/TOMAN_MARKET_FEED_AUDIT_2026-11-22.md` با شواهد مستقیم و مرز اطمینان به‌روز شد.
- [x] Commitهای این نوبت: SQL regression `a45c1e3d7f99fe7549e78470e98463c10d4e5cd6`، Node guard `9f1794b592121eec19ccffb43b480758bec367eb`، گزارش ممیزی `4cd457c1a51c7a0765356ff2f50a9e79378cebf6`.

### وضعیت داده بازار و UI
- [x] ۳۷۳ ردیف قیمت جاری فقط برای Nobitex=221 و Wallex=152 موجود است؛ آخرین دریافت `2026-11-17 22:04:26.622 UTC` و صفر ردیف تازه در پنج دقیقه.
- [x] ساختار `index.html` دوباره شمرده شد: ۲۴۴ شناسه یکتا و بدون تکرار؛ ۹ مسیر اصلی `dashboard, markets, toman, trade, orders, assets, history, settings, admin`؛ manifest و Service Worker موجودند؛ `dir=rtl` و رنگ منتخب مشکی/زرد دیده می‌شود.
- [!] Bit24 و Kifpool هنوز در تابع قیمت تومانی مستقر نیستند؛ قرارداد قیمت/واحد و parser معتبر آن‌ها باید پیش از اتصال جداگانه بررسی شود.

### گام بعد
1. پس از تأیید صریح مالک، استقرار کنترل‌شده تابع main برای رفع INSERT/23505؛ پیش از آن، تفاوت مسیر DELETE قدیمی با سیاست بدون prune در main و اثر آن بر داده‌های فعلی بازبینی شود.
2. افزودن Bit24 و Kifpool فقط پس از تأیید قرارداد API، واحد قیمت، نماد و طبقه‌بندی دارایی؛ آزمون fixture برای سهام/توکن‌شده‌ها و پاسخ ناقص.
3. ادامه QA حسابداری Limit/Stop-Limit: بازیابی DDL پایه معتبر، schema/ACL parity و آزمون quantization هشت‌رقمی USDT. CI دورریختنی به‌تنهایی اثبات محیط Supabase ایزوله Production-parity نیست.

### ایمنی این نوبت
- [x] همه بررسی‌های Supabase فقط‌خواندنی بودند؛ هیچ ردیف مالی یا داده کاربر برای تست خوانده یا تغییر داده نشد.
- [x] هیچ Worker/RPC مالی اجرا نشد.
- [x] هیچ Migration، Grant، Policy، Cron، Edge Function Deploy، refresh دستی، حذف داده یا انتشار APK انجام نشد.


## Shahram 167 — read-only Production catalog source and collision audit (2026-11-27)
- Recovered the exact applied `public.refresh_crypto_assets()` definition from Production via `pg_get_functiondef`; it is SECURITY DEFINER with empty search_path, service_role-only EXECUTE, and upserts CoinGecko catalog rows by canonical `coingecko_id`, replacing `symbol` with the uppercased provider ticker and setting `is_active=true`. It does not provision trading pairs.
- The function processes paginated CoinGecko responses under a transaction advisory lock; it validates non-empty ID/symbol/name and positive price but does not enforce ticker uniqueness or pair-symbol format before catalog upsert.
- Read-only schema inventory: `crypto_assets` has no unique symbol constraint; `demo_trading_pairs` has unique `pair_symbol` and unique `base_coingecko_id`, FK to crypto_assets, and USDT-only quote constraint. `admin_market_listings` has a before insert/update uniqueness trigger; no triggers were returned for `crypto_assets` or `demo_trading_pairs` in the inspected catalog.
- Live read-only counts: 19,012 active catalog assets; 2,365 duplicate active ticker groups containing 6,662 rows; 420 enabled pairs; 0 enabled pairs missing a market_prices row.
- Recovered current activation bodies: automatic and manual paths still impose curated-list, $1m volume, rank <= 2,000, recent exchange-observation, ticker-uniqueness, and fresh CoinGecko price conditions.
- Added `docs/PRODUCTION_CATALOG_SOURCE_AUDIT_2026-11-27.md` to PR #67 with the source/schema findings and design consequences.
- Key blocker: do not bulk-provision all active catalog rows by ticker. Canonical ID must remain authoritative; duplicate tickers require a collision-resolution or supported alternative market-symbol policy before any asset is marked tradable.
- No Production function was executed; no Production data/schema/pairs/prices/grants/RLS/Cron/workers changed. No migration, db push, merge, deploy, release, or paid infrastructure action.
- Remaining: complete writer/caller and price-refresh coverage inventory, generate a compact read-only duplicate-ticker reconciliation, then build source-faithful disposable PostgreSQL tests and a reviewed migration proposal.


## Shahram 168 — duplicate-ticker reconciliation and price coverage (2026-11-27)
- Re-ran read-only PR #67 / PR #66 checks before work: both remain open, Draft, unmerged, mergeable.
- Built corrected duplicate-ticker aggregates using independent correlated subqueries to avoid over-counting caused by one-to-many joins.
- Confirmed examples of same ticker with distinct assets: DOT maps separately to `polkadot` (Polkadot; corroborated by five Iranian exchange feeds) and `dot` (Dot; corroborated by Exir and Tabdeal). This is a legitimate identity distinction, not a reason to map either by ticker alone.
- Confirmed high-collision groups include BTC (10 active IDs), PEPE (21), DOGE (6), and DOT (3). Existing enabled pair is associated with only one canonical asset ID per ticker pair.
- Audited enabled pair prices: 420/420 rows exist and are positive, but only 415/420 are fresher than two minutes. Five stale rows: NBISONUSDT, TSMONUSDT, RIVERUSDT, TQQQONUSDT, TONUSDT; last update 2026-11-19 22:56 UTC. 390 pair prices currently identify Gate.io as source; 14 CoinGecko; three distinct sources overall.
- Added the row-level interpretation, corrected collision counts, and stale-price findings to `docs/PRODUCTION_CATALOG_SOURCE_AUDIT_2026-11-27.md`.
- Important qualification: a matching observation is not automatically proof of a unique ticker mapping; retain provider ID and exact exchange evidence. Existing pair-row presence is not proof of price freshness.
- No Production data or configuration changed; no refresh function executed; no pairs/prices/orders/balances/workers/Cron touched. No migration/db push/merge/deploy/release/cost.
- Remaining: map all price-refresh jobs/functions and their source precedence, determine why five existing prices are stale, complete all catalog/table writer and trigger caller inventory, then implement only in isolated disposable PostgreSQL with exact source-parity tests.


## Shahram 169 — price-refresh pipeline source inventory (2026-11-27)
- Read-only inspected Production Cron: job 3 `digiarz-market-price-refresh` runs every minute; job 17 `digiarz-market-price-overflow` runs every ten minutes at minute offsets 5–55. Both active; sampled recent runs reported succeeded. Neither job was modified or invoked manually.
- Recovered exact source of `public.refresh_market_prices()` and `private.request_market_price_overflow()`.
- Primary price refresh maps CoinGecko IDs from enabled pairs plus curated active catalog rows; first 515 IDs are requested by the primary function, overflow schedules the remainder in batches of 500. KuCoin/Gate.io refresh only enabled pair symbols.
- The refresh universe is enabled pairs + curated rows, not every raw provider catalog row. Therefore the future canonical admission path must create/attach the pair before price refresh coverage is guaranteed.
- CoinGecko, KuCoin, and Gate.io can all write the same `market_prices` symbol; source precedence depends on response processing order. A deterministic per-pair trusted-source policy remains to be designed.
- Column default confirms overflow requests inherit provider `CoinGecko`; three in-flight requests (CoinGecko/Gate.io/KuCoin) were present at snapshot time.
- The five stale rows remain unexplained; the audit records provider coverage and queue/response history as next read-only investigation targets.
- Updated `docs/PRODUCTION_CATALOG_SOURCE_AUDIT_2026-11-27.md` with pipeline source, scope, and risks.
- No Production writes, function executions, queue changes, Cron/worker changes, pair changes, or refresh operations. No migration/db push/merge/deploy/release/cost.
- Remaining: investigate why the five stale prices are not being refreshed, complete all writers/triggers/callers for catalog and pair tables, then design the admission/provisioning mechanism and source-faithful disposable PostgreSQL tests.


## Shahram 170 — stale price root-cause evidence (2026-11-27)
- Live-checked PR #67 and PR #66 before work; both remain open, Draft, unmerged, and mergeable. PR #67 is 7 commits ahead and 0 behind Main.
- Inspected retained HTTP responses read-only: 1,283 responses in the last ten days, all HTTP 200, not timed out, and with non-empty bodies. This is response-level status only, not a guarantee of complete asset coverage.
- All five stale pair assets still have positive, recently updated `crypto_assets.current_price_usd` values, but those belong to the separate catalog ingestion path.
- Exact JSON-key checks against the latest CoinGecko simple-price response show that none of the five stale CoinGecko IDs was returned. Substring hits were discarded as unreliable. Historical exact-key evidence for River/Toncoin is also absent; three Ondo/Nebius IDs have no retained exact-ID response match.
- Current `refresh_market_prices()` only upserts when the response contains the exact provider ID and a positive USD value. It does not fall back to `crypto_assets.current_price_usd`, so missing provider keys leave old pair prices untouched.
- Root cause narrowed to missing exact CoinGecko ID keys in simple-price responses; why those IDs are omitted (request batch membership vs endpoint coverage/provider listing) remains unproven because processed request URL metadata is not retained after tracking rows are deleted.
- Added the evidence and safe conclusion to the Production audit document. Do not copy catalog USD prices into executable USDT pairs without a validated quote/source path.
- No Production writes, function calls, queue changes, price refresh, pair mutation, Cron/worker change, migration/db push, merge/deploy/release, or paid infrastructure action.
- Remaining: determine first-515 vs overflow membership for the five IDs, inspect exact market coverage in Gate.io/KuCoin and their provider price policy, then finish all catalog and pair writers/callers inventory.


## Shahram 171 — stale pair provider coverage pinpointed (2026-11-27)
- Reconstructed the live price-refresh ID universe read-only: 898 unique provider IDs from enabled pairs + active curated listings.
- All five stale pairs rank after position 515 (523, 629, 677, 773, 789), so they rely on overflow rather than the primary CoinGecko batch.
- Latest retained Gate.io and KuCoin ticker payloads do not contain any of the five exact pair symbols. Latest CoinGecko payload likewise omitted their exact provider IDs.
- The evidence narrows the issue to overflow coverage/response inclusion plus no exchange ticker fallback for these symbols. Historical request URLs/batch membership are not retained, so it remains unknown whether the overflow scheduler requested the IDs and CoinGecko omitted them, or the request set failed to include them.
- No Production action taken; no jobs invoked, queues altered, prices refreshed, pairs modified, migrations or releases.
- Updated the Production audit document and implementation status. Next: review the overflow request scheduler and provider response lifecycle/source-parity in a disposable environment, and design persistent request metadata/coverage reporting as part of the future migration plan.


## Shahram 172 — Overflow starvation risk identified (2026-11-27)
- Rechecked PR #66 and #67 before work: both open, Draft, unmerged, mergeable. PR #67 now 11 commits ahead, 0 behind Main.
- Recovered exact Production source for `private.request_market_price_overflow()` (read-only). It refuses to enqueue overflow while any tracked market-price request exists or any CoinGecko request remains in the HTTP queue.
- Primary `refresh_market_prices()` job runs every minute and enqueues the next first-515 CoinGecko batch after processing completed requests. Overflow job runs at minute offsets 5,15,25,35,45,55.
- Current live snapshot: tracked primary CoinGecko response had exactly 515 top-level keys; three tracked provider requests were pending/processing; no overflow request batch was present.
- Strong design-level diagnosis: the primary minute-by-minute re-enqueue and overflow's requirement for an entirely empty tracked-request table create a likely starvation/race condition. This explains why all five stale pairs beyond ordinal 515 remain without prices. Not marked fully proven because Cron records don't expose the function return integer and historical requested ID batches are not retained.
- Recorded the diagnosis and safe redesign direction in the Production audit document. Future solution: durable batch cursor / single sequenced scheduler, plus durable requested-ID and response coverage metadata, retries and fairness.
- No Production function invocation, no queue or Cron changes, no pair/price writes, no migration/db push, no merge/deploy/release, no paid infrastructure action.
- Next: build disposable PostgreSQL source-parity regression for the starvation sequence and inspect all catalog/pair writer call paths before proposing any schema/function migration.


## Shahram 173 — source-parity blocker for Overflow regression (2026-11-27)
- Rechecked live GitHub: PR #67 remains open Draft and unmerged; its branch is 13 commits ahead and 0 behind current `main` (base/merge-base `fbfb5e974e754088a32c9fdcd76fc2ca9ab0f98b`). PR #66 was also found open Draft and unmerged in the repository PR search; no UI branch or Main changes were made.
- Reviewed the checked-in migration `20261115130430_fetch_coin_gecko_market_price_overflow_ids.sql` and the existing PostgreSQL 17 CI harness.
- Found a critical test-parity mismatch: the checked-in migration version of `private.request_market_price_overflow()` lacks the outstanding-request guards present in the separately recovered live Production body, and its embedded Cron schedule is every minute rather than Production's recorded offsets 5,15,25,35,45,55.
- Therefore executing the migration in disposable PostgreSQL would not reproduce the live starvation condition. Deliberately did not add a misleading lookalike or label a simplified timing test as source-parity.
- Added the exact source/schedule mismatch, confidence boundary, and evidence needed for a valid test fixture to `docs/PRODUCTION_CATALOG_SOURCE_AUDIT_2026-11-27.md`.
- Continued writer-inventory qualification: `refresh_crypto_assets()` remains absent as a full body from checked-in migrations but is recovered from Production; it mutates `crypto_assets.symbol`. Exchange-sync search hits largely target `exchange_asset_observations` or read catalog metadata, not necessarily catalog writes. No global unique active-symbol constraint exists.
- Next: preserve the exact read-only Production function definition and schedule as a provenance-labelled fixture; stub network queue dependencies in PostgreSQL 17; prove the starvation interleaving and a fair candidate scheduler; then continue exact INSERT/UPDATE target inventory for catalog/listing/pair/price tables.
- No Production function invocation or write; no Cron/queue/worker/pair/price/financial-row changes; no schema, grant, RLS, migration, db push, merge, deploy, APK/Pages release, or paid infrastructure action.


## Shahram 174 — PostgreSQL 17 test-harness and source-parity review (2026-11-27)
- [x] قبل از ادامه، وضعیت زندهٔ PRها و branch compare کنترل شد: PR #67 باز، Draft و ادغام‌نشده؛ HEAD شاخه `e058fffab27d5093a236a1a2bc4c1bcbb78d6c08`، برابر **۱۵ commit جلو و صفر عقب** از main با base `fbfb5e974e754088a32c9fdcd76fc2ca9ab0f98b`. PR #66 نیز باز، Draft و ادغام‌نشده است؛ compare زندهٔ آن 69 جلو و 0 عقب است.
- [x] workflow واقعی `.github/workflows/exact-decimal-tests.yml` بررسی شد: CI یک PostgreSQL 17 disposable اجرا می‌کند و SQL fixtureها را با `psql -v ON_ERROR_STOP=1` اجرا می‌کند. تست‌های Node مستقیماً با `node --test tests/*.test.js` اجرا می‌شوند؛ `package.json` اسکریپت `npm test` ندارد.
- [x] فایل migration قدیمی Overflow و تست‌هارنس واقعی کنار هم بررسی شدند. migration قدیمی نه guard انتظار برای خالی بودن درخواست‌های درحال‌اجرا را دارد و نه schedule زندهٔ job 17 را ثبت می‌کند؛ بنابراین منبع قابل‌استفاده برای بازتولید Production نیست.
- [x] سند `docs/PRODUCTION_CATALOG_SOURCE_AUDIT_2026-11-27.md` در commit `e058fffab27d5093a236a1a2bc4c1bcbb78d6c08` با یافته‌های هارنس، تفاوت migration/Production، و شروط fixture معتبر به‌روزرسانی شد.
- [!] در این مرحله هنوز هیچ تست source-parity جدیدی اضافه یا اجرا نشد؛ بدنهٔ دقیق Production و schedule باید دوباره از منبع read-only با timestamp و fingerprint بازیابی و در fixture مستقل ثبت شوند. سپس dependencyهای `net.http_get` و صف‌ها در PostgreSQL 17 stub می‌شوند؛ آزمون Production و candidate scheduler باید جدا باشند.
- [!] تصحیح شمارش: گزارش قبلی Stage 173 تعداد ۱۳ commit جلو را نوشته بود؛ compare زندهٔ فعلی ۱۵ جلو و صفر عقب است. این مقدار فقط وضعیت فعلی شاخه است.
- [x] هیچ SQL، workflow، migration یا کد اجرایی تغییر نکرد. هیچ تابع Production اجرا نشد و هیچ صف، Cron، جفت‌ارز، قیمت، schema، grant، policy، worker، سفارش، موجودی یا دادهٔ کاربر تغییر نکرد. هیچ db push، merge، deploy، release یا هزینه‌ای انجام نشد.

### گام بعد
1. بازیابی مجدد بدنهٔ دقیق تابع Overflow و cron job 17 از Production به‌صورت read-only؛ ثبت timestamp و fingerprint.
2. ساخت fixture provenance-labelled و stubs شبکه در PostgreSQL 17؛ آزمون مستقل interleaving فعلی و candidate عادلانه.
3. ادامهٔ inventory دقیق INSERT/UPDATE/DELETE برای catalog، listings، pairs و prices؛ سپس طراحی migration فقط در شاخهٔ تست.


## Shahram 175 — exact Production market scheduler capture (2026-11-27)
- [x] قبل از کار، PR #66 و #67 و شاخهٔ فعال از GitHub دوباره بررسی شدند؛ هر دو PR باز، Draft و ادغام‌نشده باقی مانده‌اند.
- [x] بدنهٔ واقعی `private.request_market_price_overflow()` مجدداً از Supabase Production با SELECT و `pg_get_functiondef` بازیابی شد؛ MD5: `e6ed136175b0d340c9a86e51f7917a76`.
- [x] بدنهٔ واقعی `public.refresh_market_prices()` نیز بازیابی شد؛ MD5: `3788666d57957a66bf59031f54ceff03`.
- [x] زمان‌بندی زنده تأیید شد: job 3 هر دقیقه و job 17 در دقیقه‌های 5،15،25،35،45،55؛ هر دو active.
- [x] هر دو بدنهٔ کامل، fingerprintها، Cron metadata و محدودیت تفسیر در `docs/fixtures/PRODUCTION_MARKET_PRICE_FUNCTIONS_2026-11-27.md` حفظ شدند؛ commit `c8f3b8cf99966fea65cf3e87f65924f89df50388`. سند ممیزی نیز با commit `d37a677426da554392854920d32f5d27f34c9306` تکمیل شد.
- [!] دقت مهم: تابع اصلی خودش back-pressure دارد؛ پس آزمون باید ترتیب دقیق پردازش پاسخ، پاک‌کردن tracking، بررسی صف‌ها و enqueue مجدد 515 شناسه را شبیه‌سازی کند. فرض سادهٔ «تابع اصلی هر دقیقه بدون شرط درخواست جدید می‌سازد» نادرست است.
- [ ] گام بعد: ساخت PostgreSQL 17 disposable harness با stubهای شبکه/صف و اجرای تابع‌های ثبت‌شده؛ آزمون فعلی و candidate scheduler باید جدا باشند. سپس نتایج و پوشش تست به PR #67 افزوده شوند.
- [x] همهٔ عملیات Supabase فقط SELECT بودند. هیچ تابع Production اجرا نشد و هیچ صف، قیمت، جفت‌ارز، Cron، schema، grant، RLS، worker، سفارش، موجودی یا دادهٔ کاربر تغییر نکرد. هیچ migration/db push، merge، deploy، release یا هزینه‌ای انجام نشد.


## Shahram 176 — disposable source-snapshot scheduler regression added (2026-11-27)
- [x] قبل از تغییر، وضعیت شاخه‌ها با compare زنده بررسی شد: PR #66 برابر 69 جلو و 0 عقب؛ PR #67 برابر 20 جلو و 0 عقب از `main`. هر دو PR در مسیر Draft باقی می‌مانند.
- [x] فایل `supabase/tests/market_price_scheduler_production_snapshot.sql` اضافه شد. این تست دو تابع را با بدنهٔ ثبت‌شدهٔ Production در fixture مرحلهٔ 175 اجرا می‌کند؛ fingerprintهای منبع در header تست درج شده‌اند.
- [x] وابستگی `net.http_get` به stub محلی تبدیل شده و هیچ درخواست اینترنتی ارسال نمی‌شود. تست 516 شناسهٔ فعال می‌سازد، مرز 515/516 را بررسی می‌کند، تکمیل سه درخواست provider را شبیه‌سازی می‌کند، سپس ترتیب «پردازش پاسخ‌ها → حذف tracking → enqueue مجدد batch اصلی → اجرای Overflow» را بازسازی می‌کند.
- [x] آزمون انتظار دارد Overflow در interleaving بازسازی‌شده به‌علت وجود درخواست‌های primary مسدود بماند؛ سپس با حذف صف/درخواست‌های معلق، کنترل می‌کند که Overflow به‌تنهایی شناسهٔ 516 را در batch بعدی قرار می‌دهد. بنابراین تست فرق بین مشکل guard/interleaving و خطای مرتب‌سازی IDها را مشخص می‌کند.
- [x] workflow موجود PostgreSQL 17 یک گام مستقل اضافه کرد که دیتابیس تازهٔ `digiarz_market_scheduler_test` می‌سازد و فایل تست را با `psql -v ON_ERROR_STOP=1` اجرا می‌کند. فایل workflow فقط روی شاخهٔ این PR تغییر کرده؛ `main` دست‌نخورده است.
- [!] اجرای محلی PostgreSQL در محیط فعلی در دسترس نبود؛ بنابراین نتیجهٔ تست هنوز PASS اعلام نمی‌شود. نتیجهٔ معتبر باید از GitHub Actions روی HEAD دقیق این تغییرات گرفته و job/step آن بررسی شود.
- [!] این تست یک interleaving کنترل‌شده را اثبات می‌کند، نه اینکه به‌تنهایی علت تاریخی پنج قیمت stale را ثابت کند و نه اینکه starvation در تمام ترتیب‌های هم‌زمانی قطعی باشد. طراحی scheduler عادلانه و تست مستقل candidate هنوز انجام نشده است.
- [ ] گام بعد: بررسی نتیجهٔ CI روی HEAD دقیق؛ رفع هر خطای SQL/هارنس؛ سپس افزودن candidate scheduler آزمایشی با cursor پایدار، ثبت requested-ID/response coverage و retry عادلانه، با آزمون‌های جداگانه.
- [x] هیچ Supabase/Production تابعی اجرا نشد؛ هیچ قیمت، جفت‌ارز، صف، Cron، schema، grant، RLS، worker، سفارش، موجودی یا دادهٔ کاربر تغییر نکرد. هیچ migration/db push، merge، deploy، release یا هزینه‌ای انجام نشد.


### Shahram 176 — exact-head PostgreSQL 17 CI result (2026-11-27)
- [x] GitHub Actions run **46029198859** (run #2248) روی commit دقیق `511ec081ec6fa7a700067b91f10fab19beadc56a` با نتیجهٔ **SUCCESS** تمام شد.
- [x] تمام 23 مرحلهٔ workflow موفق شدند؛ از جمله مرحلهٔ 23 با عنوان `Reproduce captured Production market scheduler interleaving in disposable PostgreSQL`. PostgreSQL 17 disposable database ساخته شد و اسکریپت source-snapshot با `ON_ERROR_STOP=1` بدون خطا اجرا شد.
- [x] تست، مرز 515/516، جلوگیری Overflow هنگام وجود tracking/queue، پردازش پاسخ‌های سه provider، enqueue مجدد batch اصلی و امکان enqueue شدن asset 516 در حالت بدون درخواست معلق را با موفقیت بررسی کرد.
- [!] این نتیجه فقط رفتار interleaving آزمایش‌شده را ثابت می‌کند؛ اثبات علت قطعی پنج قیمت stale تاریخی یا پوشش تمام interleavingهای هم‌زمانی نیست. candidate scheduler عادلانه هنوز نوشته/آزموده نشده است.
- [x] PR #67 در آخرین compare برابر 24 commit جلو و صفر عقب از `main` بود؛ PR #66 برابر 69 جلو و صفر عقب. هر دو باز، Draft و ادغام‌نشده‌اند.
- [ ] مرحلهٔ بعد: candidate طراحی‌شده با cursor پایدار و batch/response ledger را جدا از بدنهٔ Production در disposable PostgreSQL پیاده و آزمون کنیم؛ سپس inventory تمام مسیرهای نوشتن کاتالوگ/جفت‌ارز را کامل کنیم.
- [x] هیچ تغییر Production/Supabase، Cron، صف، قیمت، جفت‌ارز، Worker، Migration، db push، merge، deploy، release یا هزینه‌ای انجام نشد.


## Shahram 177 — fair scheduler candidate design (2026-11-27)
- [x] پس از موفقیت تست exact-source مرحلهٔ 176، طراحی candidate مستقل در `docs/MARKET_PRICE_SCHEDULER_FAIRNESS_DESIGN_2026-11-27.md` ثبت شد.
- [x] طرح شامل cursor لغوی پایدار و wrap-around، ledger ماندگار هر batch با requested/returned/omitted IDs، صف اولویت برای دارایی‌های تازه‌پذیرفته‌شده، retry/backoff برای IDهای حذف‌شده از پاسخ، سقف in-flight کنترل‌شده، و سیاست قطعی تقدم منبع قیمت است.
- [x] وابستگی‌های بین scheduler و نیاز «همهٔ ارزهای کاتالوگ قابل معامله باشند» مشخص شد: provisioning جفت‌ارز و enqueue اولویت قیمت باید در یک تراکنش اتمیک انجام شوند؛ معامله فقط با قیمت معتبر، تازه و نگاشت canonical یکتا مجاز است.
- [!] این مرحله فقط طراحی است؛ هیچ جدول، تابع، migration، Cron، queue یا worker جدیدی ساخته/اجرا نشده است. اندازهٔ batch، تعداد درخواست هم‌زمان، retry delays و منبع قیمت مجاز باید با تست و محدودیت providerها تعیین شوند.
- [ ] گام بعد: پیاده‌سازی candidate scheduler فقط در disposable PostgreSQL 17، با آزمون‌های fairness، retry، idempotency، concurrency و source-priority؛ سپس تکمیل inventory writerهای کاتالوگ و اتصال آن به provisioning candidate.
- [x] هیچ Production/Supabase write، migration/db push، Cron/worker change، merge، deploy، release یا هزینه‌ای انجام نشد.


## Shahram 178 — fair scheduler candidate added to disposable PostgreSQL tests (2026-11-27)
- [x] وضعیت زنده پیش از تغییر بررسی شد: PR #66 برابر 69 جلو/0 عقب و PR #67 برابر 27 جلو/0 عقب از `main`؛ هر دو باز و Draft هستند.
- [x] candidate scheduler آزمایشی در `supabase/tests/market_price_scheduler_candidate.sql` و فقط در schema جداگانهٔ `scheduler_candidate` اضافه شد؛ این migration Production نیست.
- [x] منطق candidate شامل صف اولویت برای پذیرش دارایی جدید، cursor چرخشی روی canonical ID، ledger درخواست با requested/returned/omitted IDs، جلوگیری از درخواست تکراری در batchهای in-flight، retry با backoff، تکمیل idempotent و سیاست تقدم قطعی منبع قیمت است.
- [x] آزمون‌ها پوشش 1200 دارایی در 12 batch، نبود تکرار در یک چرخه، اولویت دارایی تازه، ثبت پاسخ ناقص و retry، idempotency تحویل مجدد پاسخ، رد قیمت stale/NaN و جلوگیری از overwrite منبع با اولویت پایین‌تر را دارند.
- [x] آزمون هم‌زمانی دو session در `supabase/tests/market_price_scheduler_candidate_concurrency.sh` اضافه شد؛ session اول advisory transaction lock را نگه می‌دارد و invocation دوم باید بدون ایجاد batch خارج شود.
- [x] workflow PostgreSQL 17 یک دیتابیس مستقل برای candidate test می‌سازد و هر دو تست را اجرا می‌کند.
- [!] نتیجهٔ candidate هنوز تأیید نشده است؛ باید GitHub Actions روی HEAD دقیق اجرا و تمام مراحل بررسی شوند. اجرای محلی PostgreSQL در این محیط در دسترس نیست.
- [!] این candidate هنوز prototype آزمایشی است؛ سیاست واقعی provider، زمان مشاهدهٔ قیمت، نرخ درخواست، RLS/grants، schema نهایی و اتصال atomic به catalog admission نیازمند ممیزی و تست بیشتر است. هیچ‌یک برای Production آماده یا مجاز اعلام نشده است.
- [ ] گام بعد: نتیجهٔ CI را بررسی و خطاها را اصلاح کنیم؛ سپس آزمون‌های retry failure، cycle wrap، duplicate canonical symbol و مسیرهای امنیتی را اضافه کنیم.
- [x] هیچ Supabase/Production write، Cron/worker/Edge Function، price/pair/order/balance change، migration/db push، merge، deploy، release یا هزینه‌ای انجام نشد.


## Shahram 179 — candidate scheduler CI, cursor correction, and bounded concurrency (2026-11-27)
- [x] اولین اجرای کامل candidate scheduler در GitHub Actions، run #2259، روی commit `55366d23745573bae79aaf6a522447229931ca5f` با نتیجهٔ SUCCESS انجام شد؛ هر دو گام بازسازی منبع Production و اجرای candidate در PostgreSQL 17 موفق بودند.
- [x] در بازبینی مستقل منطق، ایراد مهم cursor پیدا شد: اگر یک batch پاسخ ناقص می‌گرفت، cursor قبلی جلو نمی‌رفت و دارایی‌های قبلاً موفق ممکن بود دوباره انتخاب شوند. cursor اکنون فقط بر مبنای آخرین canonical ID انتخاب‌شده از lane عادی پیش می‌رود؛ IDهای omitted جداگانه در retry باقی می‌مانند.
- [x] مرتب‌سازی lane عادی از `transaction_timestamp()` استفاده می‌کند تا ترتیب IDها با تغییر لحظه‌ای timestamp هر ردیف ناپایدار نشود.
- [x] آزمون wrap-around پس از پوشش 1200 دارایی اضافه شد؛ انتظار دارد پس از آخرین ID، چرخهٔ بعدی از `asset-0001` آغاز شود.
- [x] سقف configurable برای تعداد batchهای in-flight (پیش‌فرض 3، محدودهٔ candidate برابر 1 تا 10) اضافه شد؛ تست، سقف و عدم هم‌پوشانی IDهای batchهای معلق را کنترل می‌کند.
- [!] اجرای #2259 مربوط به نسخهٔ قبل از اصلاح cursor و سقف هم‌زمانی است؛ اجرای نسخه‌های اصلاح‌شده هنوز در حال انجام است و PASS نهایی برای HEAD فعلی اعلام نمی‌شود.
- [ ] گام بعد: نتیجهٔ CI روی آخرین commit شامل wrap-around و in-flight cap را بررسی کنیم؛ در صورت شکست، فقط fixture/test را اصلاح و دوباره اجرا کنیم. سپس آزمون fairness در برابر هجوم پیوستهٔ admission و آزمون retry خطای HTTP را اضافه کنیم.
- [x] هیچ Production/Supabase write، تغییر Cron/صف/قیمت/جفت‌ارز، Worker/Edge Function، Migration/db push، merge، deploy، release یا هزینه‌ای انجام نشد.


## Shahram 180 — provider failure retry and canonical pair collision tests (2026-11-27)
- [x] آزمون پاسخ HTTP ناموفق (503) اضافه شد: batch باید در ledger با وضعیت failure ثبت شود، شناسه به retry برود و پس از پاسخ موفق بعدی قیمت معتبر دریافت کند.
- [x] آزمون برخورد نماد اضافه شد: پذیرش canonical ID دوم با همان pair symbol باید با unique constraint رد شود؛ هیچ نگاشت ticker مبهمی ساخته نمی‌شود.
- [x] آزمون‌های مرحلهٔ candidate اکنون شامل 1200 دارایی، 12 batch، wrap-around، priority admission، omission و retry، HTTP failure و recovery، duplicate delivery، stale/NaN rejection، source priority، in-flight cap و عدم هم‌پوشانی شناسه‌ها هستند.
- [x] اجرای CI روی commit `8f70a67c7fdd0209e2cef7822fcac881b6d4fe57`، run #2261، با نتیجهٔ SUCCESS تکمیل شد؛ تست بازسازی Production و candidate شامل اصلاح cursor/wrap-around موفق بودند.
- [!] اجرای نسخهٔ کامل‌تر با in-flight cap و تست‌های HTTP 503/canonical collision روی HEAD جدید هنوز در GitHub Actions در حال اجراست؛ تا نتیجهٔ دقیق آن PASS نهایی اعلام نمی‌شود.
- [ ] گام بعد: تأیید CI روی آخرین HEAD؛ سپس بررسی fairness در برابر ورود پیوستهٔ دارایی‌های جدید، سقف retry، source observation timestamps و inventory کامل writerهای catalog. Candidate هنوز صرفاً fixture آزمایشی است و برای Production آماده نیست.
- [x] هیچ تغییر Production/Supabase، Cron/queue/price/pair، Worker/Edge Function، Migration/db push، merge، deploy، release یا هزینه‌ای انجام نشد.


## Shahram 181 — CI failure diagnosis and scheduler fairness hardening (2026-11-27)
- [x] وضعیت زندهٔ PR #66 و #67 و Actions بررسی شد؛ هر دو PR همچنان باز، Draft و ادغام‌نشده‌اند. PR #67 روی HEAD ab6ba198... دارای CI failure بود؛ تمام مراحل قبلی workflow موفق و مرحلهٔ candidate scheduler ناموفق بود.
- [x] بازبینی SQL نشان داد انتهای بلوک DO به‌اشتباه END $; نوشته شده بود؛ terminator به END $$; اصلاح شد. GitHub Actions log text از wrapper قابل دریافت نبود، بنابراین علت شکست با جزئیات log ادعا نمی‌شود؛ این خطای نحوی مستقل و قطعی در فایل بود.
- [x] بازبینی fairness نشان داد مرتب‌سازی laneها به‌صورت priority → retry → normal می‌توانست در صورت ورود پیوستهٔ دارایی‌های جدید، lane عادی را گرسنه نگه دارد.
- [x] انتخاب batch به سهمیهٔ وزنی تغییر کرد: در batchهای حداقل ۳تایی، حداقل ۲۰٪ برای priority، ۲۰٪ برای retryهای سررسیدشده و ۶۰٪ برای چرخش عادی؛ سهمیهٔ خالی بین laneهای باقی‌مانده پر می‌شود. برای batchهای کوچک‌تر، مسیر عادی سهمیهٔ اصلی را حفظ می‌کند.
- [x] آزمون admission storm اضافه شد: در پنج دور، هر بار ده دارایی تازه وارد صف priority می‌شوند و تست باید حداقل شش دارایی عادی را در هر batch حفظ کند.
- [!] این اصلاحات هنوز CI دقیق HEAD جدید را نگذرانده‌اند؛ تا اجرای تازهٔ PostgreSQL 17 و concurrency test موفق نشود، candidate را PASS یا Production-ready نمی‌دانیم.
- [ ] گام بعد: نتیجهٔ CI جدید را بررسی کنیم؛ اگر شکست ماند، جزئیات مرحله و SQL را جداگانه عیب‌یابی کنیم. سپس timestamp مشاهده‌شده توسط provider، سقف retry/backoff و inventory کامل تمام write-pathهای catalog را تکمیل کنیم.
- [x] فقط فایل تست candidate و این سند روی شاخهٔ Draft تغییر کردند؛ هیچ Production/Supabase write، migration/db push، Cron/queue/price/pair، Worker/Edge Function، grant/RLS، merge، deploy، release یا هزینه‌ای انجام نشد.


## Shahram 182 — weighted scheduler backfill correction and Production writer inventory (2026-11-27)
- [x] دریافت log دقیق CI نشان داد پس از اصلاح terminator، آزمون admission storm به‌درستی یک نقص دیگر را آشکار کرد: وقتی lane retry خالی بود، fill با ترتیب priority-first سهمیهٔ استفاده‌نشده را دوباره به priority می‌داد و در batch ده‌تایی چهار دارایی تازه را وارد می‌کرد؛ lane عادی همچنان شش جایگاه داشت، اما سقف ۲۰٪ priority رعایت نمی‌شد.
- [x] ترتیب backfill اصلاح شد: سهمیهٔ خالی ابتدا به normal، سپس retry و در آخر priority اختصاص می‌یابد. آزمون storm همچنان حداکثر دو priority و حداقل شش normal را در هر batch ده‌تایی مطالبه می‌کند.
- [x] ممیزی read-only Production تکمیل‌تر شد: توابع SQL، triggerها، RLS/policies و table grants بررسی شدند؛ Edge Functionهای فعال نیز فهرست و sourceهای مرتبط بازیابی شدند.
- [x] دو writer اضافی برای crypto_assets/market_prices پیدا شد: Edge Function admin-refresh-crypto-asset نماد کاتالوگ را با service_role به‌روزرسانی می‌کند، و Edge Functionهای index-ts و refresh-market-prices می‌توانند قیمت مجموعهٔ محدود و hard-coded را در market_prices upsert کنند.
- [x] نتیجهٔ مهم امنیت/یکپارچگی: anon و authenticated روی چهار جدول فقط SELECT دارند، اما service_role دسترسی مستقیم DML دارد؛ trigger یکتایی فقط admin_market_listings را پوشش می‌دهد و روی crypto_assets/demo_trading_pairs/market_prices triggerی در inventory مشاهده نشد. بنابراین همهٔ service-role writerها باید در طراحی واحد در نظر گرفته شوند.
- [x] یافته‌ها در docs/PRODUCTION_CATALOG_SOURCE_AUDIT_2026-11-27.md و docs/ALL_CATALOG_ASSETS_TRADABLE_PLAN_2026-11-27.md ثبت شدند.
- [!] اجرای CI پس از اصلاح backfill هنوز در انتظار است؛ candidate تا عبور از PostgreSQL 17 و concurrency test آماده یا تأییدشده محسوب نمی‌شود.
- [ ] گام بعد: نتیجهٔ CI روی HEAD جدید؛ سپس افزودن آزمون timestamp واقعی مشاهده‌شده توسط provider و تکمیل بررسی تمام مصرف‌کنندگان بیرونی service_role. پس از آن می‌توان طرح catalog admission/provisioning را در disposable PostgreSQL مدل کرد.
- [x] تمام کوئری‌های Supabase این مرحله SELECT-only بودند؛ هیچ Edge Function یا SQL function اجرا/تغییر نکرد، هیچ جدول/قیمت/جفت‌ارز/صف/Cron/worker/دادهٔ Production تغییر نکرد. هیچ migration/db push، merge، deploy، release یا هزینه‌ای انجام نشد.


## Shahram 183 — fair scheduler candidate PostgreSQL 17 CI passed (2026-11-27)
- [x] GitHub Actions run 46032712435 روی commit دقیق 7cefac11d5af25d845cdd101f4629564895a7b15 با نتیجهٔ SUCCESS تمام شد.
- [x] تمام 24 مرحلهٔ workflow موفق شدند؛ مرحلهٔ candidate scheduler در PostgreSQL 17 و concurrency shell test هر دو موفق بودند. این اجرا شامل اصلاح DO terminator، سهمیه‌بندی weighted lanes و backfill normal-first بود.
- [x] آزمون‌ها 1200 دارایی در 12 batch، پوشش کامل چرخه و wrap-around، priority admission، retry omission و HTTP 503، idempotent completion، رد قیمت stale/NaN، تقدم منبع، برخورد canonical pair symbol، admission storm با حداقل 60٪ سهمیهٔ normal، سقف سه batch هم‌زمان و رد invocation دوم هنگام advisory lock را پوشش دادند.
- [!] PASS فقط برای fixture candidate در PostgreSQL 17 disposable است؛ این نه اثبات رفتار Production است و نه مجوز migration/rollout. منطق provider-observed timestamp، source mapping واقعی و اتصال atomic catalog-admission هنوز باید تکمیل شود.
- [x] پس از commit تست 7ce، commitهای بعدی فقط مستندات/status بودند؛ CI روی آخرین commit مستنداتی fef1031a... در زمان ثبت این checkpoint هنوز در حال اجرا بود.
- [ ] گام بعد: تأیید آخرین docs-only CI؛ سپس اضافه‌کردن timestamp واقعی provider observation و تست‌های canonical catalog admission/identity collision در disposable PostgreSQL. بعد از آن inventory مصرف‌کنندگان بیرونی service_role را کامل کنیم.
- [x] هیچ Production/Supabase write، SQL/Edge Function invocation، تغییر Cron/queue/price/pair, Worker, grant/RLS، migration/db push، merge، deploy، release یا هزینه‌ای انجام نشد.


## Shahram 184 — provider-observed timestamp regression passed; duplicate-ticker ledger blocker mapped (2026-11-27)
- [x] Candidate price response now requires CoinGecko `last_updated_at` Unix seconds; converts it to timestamptz and passes provider-observed time—not local receive time—to freshness validation. Missing/invalid timestamp is omitted and enters retry; received time remains separate.
- [x] Test payloads were updated to carry source timestamps; a negative case verifies a positive price without `last_updated_at` is not accepted and is retried.
- [x] Official CoinGecko documentation confirms `/simple/price` supports `include_last_updated_at=true` and returns a Unix update timestamp. The captured current Production request does not request this field; current market_prices.updated_at is written at response processing time and cannot independently prove provider-observed freshness.
- [x] GitHub Actions run 46033134206 on exact HEAD `b9f7a2c31d2f9605f417ed2e39e055680a1c3944` completed SUCCESS; all 24 workflow steps passed, including candidate PostgreSQL 17 and concurrency tests. Later commits 4e897626... and 0fc43cef... only extend documentation.
- [x] Duplicate ticker architecture was mapped against live schema: orders/trades/conditional_orders.symbol, asset_balances.asset and order_reservations.asset are text; current RPC/workers derive base asset from pair symbol. A synthetic alias alone would leak into ledger/portfolio; canonical immutable asset identity must be propagated end-to-end.
- [!] Candidate success remains disposable-fixture evidence only. No Production code was changed; current production source does not yet request provider-observed timestamp and duplicate-ticker ledger identity remains a blocking architecture item for the owner's all-assets-tradable requirement.
- [ ] Next: design canonical internal asset identity across pairs/orders/trades/reservations/balances/UI and add disposable lifecycle tests for distinct canonical IDs sharing a display ticker. Then verify the latest docs-only CI and continue external service_role caller inventory.
- [x] No Production/Supabase write, SQL/Edge Function invocation, schema/pair/price/queue/Cron/worker/grant/RLS change, migration/db push, merge, deploy, release or cost was made.


## Shahram 185 — timestamp rounding fix passed; canonical-ID market-trade prototype added (2026-11-27)
- [x] A flaky timestamp regression was traced to PostgreSQL numeric-to-bigint cast rounding Unix seconds forward. Test fixtures now use floor(epoch) before conversion; receive-time is no longer accidentally newer/older due to rounding.
- [x] GitHub Actions run 46033468800 on exact candidate commit cf71096f493b8c7db2a6b562b1c282aca748bbb8 completed SUCCESS; the full workflow, fair scheduler PostgreSQL 17 fixture and concurrency test passed.
- [x] Added design-only architecture document docs/CANONICAL_ASSET_IDENTITY_DESIGN_2026-11-27.md: immutable internal asset UUID, provider-ID mapping, pair_id, prices keyed by pair, ledger balances/reservations/orders/trades by canonical asset IDs, and migration/backfill safety.
- [x] Added isolated SQL prototype supabase/tests/canonical_asset_identity_candidate.sql and wired it into CI. It models two distinct canonical assets with the same DOT display ticker and same visible DOT/USDT label, but distinct pair IDs, provider IDs, prices and balances; Market buy/sell uses pair_id and verifies no cross-asset balance contamination, fee arithmetic, provider-ID uniqueness and stale-price rejection.
- [!] The new canonical-identity SQL test is wired but not yet CI-verified on the latest branch commit; current proof is design/prototype only and covers Market buy/sell, not yet Limit, TP/SL, OCO or Stop-Limit worker lifecycle.
- [ ] Next: confirm CI on current HEAD including the new canonical identity fixture; then extend the fixture to reservations and Limit/TP-SL/Stop-Limit worker lifecycle, concurrency, unauthorized caller and UI/portfolio mapping tests.
- [x] No Production/Supabase write, SQL/Edge Function invocation, schema/pair/price/queue/Cron/worker/grant/RLS change, migration/db push, merge, deploy, release or cost was made.


## Shahram 186 — canonical duplicate-ticker Market trade prototype CI passed (2026-11-27)
- [x] GitHub Actions run 46033780380 روی commit c74bdb268c09c97b86c0dfd3131e830b8a836f13 با نتیجهٔ SUCCESS تمام شد؛ تمام 25 مرحلهٔ workflow موفق شدند.
- [x] مرحلهٔ 24 زمان‌بند عادلانه و concurrency fixture در PostgreSQL 17 موفق شد؛ مرحلهٔ 25 نیز canonical asset identity candidate را اجرا کرد و موفق شد.
- [x] آزمون canonical identity دو دارایی متفاوت با نماد نمایشی یکسان DOT و جفت نمایشی یکسان DOT/USDT را با pair_id جداگانه معامله کرد؛ خرید و فروش یکی روی موجودی دیگری اثر نگذاشت. کارمزد 0.1٪، نگاشت یکتای provider ID و رد قیمت stale هم تأیید شد.
- [!] این فقط نمونهٔ Market buy/sell در schema جداشدهٔ disposable است؛ هنوز به معنی پیاده‌سازی در Production نیست و Limit، reservations واقعی، TP/SL، OCO، Stop-Limit، worker lifecycle، RLS/authorization و UI/portfolio باید به همان شناسهٔ canonical منتقل و جداگانه تست شوند.
- [ ] گام بعد: گسترش prototype به reservation و چرخهٔ Limit/TP-SL/Stop-Limit، سپس تست concurrency/admission و UI read-pathها. هم‌زمان آخرین docs-only CI و PR status را تأیید کنیم.
- [x] هیچ Production/Supabase write، migration/db push، SQL/Edge Function invocation، تغییر schema/pair/price/queue/Cron/worker/grant/RLS، merge، deploy، release یا هزینه‌ای انجام نشد.


## Shahram 187 — canonical Limit reservations and worker lifecycle added (2026-11-27)
- [x] Disposable canonical identity fixture expanded: orders now retain order_type, pair_id, base_asset_id and quote_asset_id; limit reservations point to the exact canonical base/quote asset; worker resolves the pair and price by pair_id and never parses ticker suffixes.
- [x] Added buy-limit and sell-limit placement with fee-aware reservation, canonical asset balance locking, and worker fill/release behavior. Added stale-price worker test: pending limit order keeps its canonical reservation while stale, then fills only after a fresh provider observation.
- [x] Test expected balances include the 0.1% fee and verify that two assets sharing DOT do not contaminate each other's balances/reservations/trades.
- [!] Latest GitHub Actions run 46034202824 on commit 8761aa5320e99c9cfc8bec115e1a23138b02921d was still running at step 6 when this checkpoint was recorded; Limit lifecycle is not yet CI-confirmed. The earlier Market-only canonical identity test passed in run 46033780380.
- [ ] Next: await run 46034202824; fix any SQL or arithmetic failures, then extend canonical identity through TP/SL, OCO and Stop-Limit child worker paths and concurrency/authorization tests.
- [x] All work remains isolated to the disposable test schema and documentation. No Production/Supabase write, migration/db push, pair/price/queue/Cron/worker/grant/RLS change, merge, deploy, release or cost was made.


## Shahram 188 — Limit prototype dollar-quote CI syntax fix (2026-11-27)
- [x] CI on the Limit prototype exposed a syntax error in the two new PL/pgSQL function bodies: their opening delimiter had been written as AS $ instead of AS $$, while the closing delimiter was correct. The fixture was corrected to use proper dollar-quoted bodies for both place_limit_order and process_limit_orders.
- [!] The corrected exact file is now on commit f62acfe1c1fc2633478113edc3f95678d354d57c; GitHub Actions run 46034498934 was still in progress at Initialize containers when recorded. No PASS is claimed for Limit yet.
- [ ] Next: verify run 46034498934 through candidate PostgreSQL step 25; fix any further SQL/runtime issue, then extend canonical identity to TP/SL, OCO and Stop-Limit.
- [x] All changes remain isolated to the disposable test fixture and documentation. No Production/Supabase write, migration/db push, pair/price/queue/Cron/worker/grant/RLS change, merge, deploy, release or cost was made.

## Shahram 189 — canonical Market + Limit duplicate-ticker CI passed; TP/SL and Stop-Limit source audit (2026-11-27)
- [x] GitHub Actions run 46036165275 on exact candidate commit e04901bbeaca047742baeff677517934bb9123cc completed SUCCESS; all 29 job steps succeeded, including disposable PostgreSQL 17 canonical duplicate-ticker Market/Limit lifecycle and fair-scheduler concurrency.
- [x] Corrected the canonical fixture's malformed anonymous DO block delimiter (DO $ → DO $$); CI then compiled and ran the test successfully. Branch head is now 83 commits ahead, 0 behind main; PR #67 remains open, Draft, unmerged and mergeable.
- [x] Read the authoritative TP/SL migration 20261113162051_add_demo_take_profit_stop_loss_engine.sql and Stop-Limit migration 20261113181827_add_stop_limit_order_engine.sql on the candidate branch. Confirmed both still use ticker-string identity: conditional_orders.symbol, orders.symbol, order_reservations.asset, and asset_balances.asset; TP/SL and Stop-Limit placement derive the base asset by stripping USDT; workers locate market_prices by symbol and delegate to ticker-based Market/Limit entrypoints. No canonical pair_id/asset_id is propagated through those real paths yet.
- [!] Therefore the passing disposable canonical fixture is still a model-only proof, not source parity or end-to-end implementation. Extending only the miniature fixture would risk overstating coverage; next work must build a source-parity candidate from the authoritative migration bodies and schema, then add canonical IDs to TP/SL, Stop-Limit parent/child, reservations and worker paths. Current migration's order_kind supports TP/SL and Stop-Limit but has no OCO lifecycle; OCO remains a separate feature gap.
- [ ] Next: design the coordinated canonical-ID RPC/worker contract for TP/SL and Stop-Limit using the actual migrations; add OCO only as an explicit additional lifecycle after identity, cancellation, reservation and worker invariants are defined. Then test duplicate-ticker, stale price, invalid reservation, retry, cancellation-vs-worker races, RLS and service_role-only worker ACLs in disposable PostgreSQL.
- [x] No Production/Supabase write, SQL/Edge Function invocation, migration/db push, pair/price/queue/Cron/worker/grant/RLS change, merge, deploy, release, APK/Pages publication or cost was made.

## Shahram 190 — CI source-parity boundary clarified (2026-11-27)
- [x] Inspected the exact-decimal GitHub Actions workflow and confirmed the canonical identity CI step runs only the standalone miniature SQL fixture in a fresh database; it does not apply the authoritative Production migrations.
- [x] Confirmed existing TP/SL and Stop-Limit CI lifecycle steps load the generic setup plus 2026-11-15 draft exact-decimal entrypoint/worker candidates, not the current 2026-11-13 authoritative migration bodies.
- [!] Run 46036165275 remains a valid PostgreSQL 17 pass for the isolated canonical prototype, but is not source-parity proof for the real financial RPC/worker call graph. The source audit from Shahram 189 remains a blocker.
- [ ] Next: create a dedicated disposable source-parity harness based on the authoritative migration bodies and schema dependencies. Apply canonical-ID changes to the real TP/SL and Stop-Limit entrypoints/workers, preserve security/locking/reservation invariants, and then add OCO as a separately tested linked-order lifecycle. Do not rely on the current miniature fixture as evidence of production-function integration.
- [x] No Production/Supabase write, SQL/Edge Function invocation, migration/db push, pair/price/queue/Cron/worker/grant/RLS change, merge, deploy, release, APK/Pages publication or cost was made.

## Shahram 191 — authoritative TP/SL and Stop-Limit migration harness added (2026-11-27)
- [x] Added a disposable PostgreSQL harness that loads the exact checked-in authoritative migrations `20261113162051_add_demo_take_profit_stop_loss_engine.sql` and `20261113181827_add_stop_limit_order_engine.sql`, rather than the older draft entrypoint candidates.
- [x] The harness exercises the real migration-defined TP/SL placement + worker lifecycle and Stop-Limit parent/child trigger lifecycle; it also checks the actual migration ACL boundary (worker functions service_role-only) and conditional_orders RLS/read-only client grants.
- [!] The separate downstream Market and Limit engines are explicit test adapters in the disposable setup; therefore this is authoritative conditional-RPC/worker source coverage, not end-to-end source parity for the complete trade engine. It intentionally does not claim canonical asset identity support: the authoritative functions remain ticker-based and the schema still keys market_prices/demo_trading_pairs by display ticker.
- [!] New CI workflow step was added to apply both exact migration files in a fresh PostgreSQL 17 database. At checkpoint creation, GitHub connector returned no workflow run and no commit status for the latest head; the harness is NOT yet CI-verified.
- [ ] Next: obtain CI execution and fix compile/runtime issues; then create canonical-ID candidate versions of these exact migration functions, propagate pair_id/base_asset_id/quote_asset_id through reservations, parent/child orders and workers, and test duplicate tickers/stale prices/invalid reservations/cancel races. OCO remains a separate linked-order lifecycle.
- [x] No Production/Supabase write, SQL/Edge Function invocation, migration/db push, pair/price/wallet/order/trade/reservation/Cron/worker/grant/RLS change, merge, deploy, release, APK/Pages publication or cost was made.


## Shahram 192 — first authoritative harness CI failure diagnosed and corrected (2026-11-27)
- [x] CI run 46037457971 reached the new authoritative migration harness after earlier 23 steps succeeded; step 25 failed during the Stop-Limit placement call.
- [x] Root cause was in the test harness sequence, not the migration: the real TP/SL worker deliberately clears its temporary JWT subject claim after processing; the next authenticated test RPC therefore correctly rejected the caller as unauthenticated.
- [x] The disposable test now restores the test user's JWT subject before invoking Stop-Limit placement. This preserves the production worker's claim-clearing behavior rather than weakening the migration or worker.
- [!] The correction is on commit 776802892afc80b164e8b7907333df775e8b1e8a; a new CI run is required. No pass is claimed yet.
- [ ] Next: verify the rerun through step 25, fix any additional source/harness issues, then extend the actual migration-derived candidate to canonical pair/asset IDs and duplicate-ticker-safe pricing/reservations. OCO remains separate.
- [x] No Production/Supabase write, SQL/Edge Function invocation, migration/db push, pair/price/wallet/order/trade/reservation/Cron/worker/grant/RLS change, merge, deploy, release, APK/Pages publication or cost was made.


## Shahram 193 — authoritative TP/SL + Stop-Limit migration harness CI passed (2026-11-27)
- [x] GitHub Actions run 46037695694 completed SUCCESS on the corrected source-parity harness commit 776802892afc80b164e8b7907333df775e8b1e8a.
- [x] The new workflow step 25 applied the exact checked-in authoritative migrations 20261113162051_add_demo_take_profit_stop_loss_engine.sql and 20261113181827_add_stop_limit_order_engine.sql to a fresh PostgreSQL 17 database, then exercised the migration-defined TP conditional execution and Stop-Limit parent/child trigger lifecycle.
- [x] The harness verified conditional_orders RLS/read-only authenticated table grants and that process_conditional_orders/process_stop_limit_orders are executable by service_role but not authenticated. The canonical identity fixture (step 26) also passed in the same run.
- [!] This is source coverage of the real conditional/Stop-Limit migration bodies with explicit isolated adapters for the separate Market/Limit matching engines. It is not complete trade-engine source parity and does not establish canonical pair/asset IDs: the authoritative migrations still use ticker strings for pair lookup, price lookup and reservations. The harness currently exercises take_profit (not a separate stop_loss case); stop_loss branch coverage remains to be added.
- [ ] Next: create a canonical-ID candidate from these verified authoritative function bodies; carry pair_id/base_asset_id/quote_asset_id through conditional parent/child orders, reservations and execution workers; replace ticker-based price lookup with pair-keyed lookup; add stop_loss, stale price, malformed reservation, retry and cancellation race tests. OCO remains a separate linked-order lifecycle.
- [x] No Production/Supabase write, SQL/Edge Function invocation, migration/db push, pair/price/wallet/order/trade/reservation/Cron/worker/grant/RLS change, merge, deploy, release, APK/Pages publication or cost was made.


## Shahram 194 — authoritative Stop-Loss branch coverage added (2026-11-27)
- [x] Extended `supabase/tests/authoritative_conditional_source_parity.sql` to execute the real migration-defined `stop_loss` branch separately from `take_profit`: with observed DOTUSDT price 13 and stop-loss trigger 14, the worker must trigger and both conditional and parent order must reach filled.
- [x] Preserved the authoritative worker's JWT-claim clearing; the harness explicitly restores the test user's claim before the next authenticated RPC.
- [!] Commit: `81f64761a572338f0f348f3350ff713d3f737bb0`. At checkpoint, GitHub's PR-run/status lookup has not surfaced a new CI run for this head; Stop-Loss coverage is added but NOT yet CI-verified.
- [ ] Next: confirm CI executes the updated harness; then extend source-parity candidate with canonical `pair_id`, `base_asset_id`, `quote_asset_id` across TP/SL and Stop-Limit parent/child, reservations and execution calls. Market/Limit adapters must eventually be replaced with actual authoritative matching-engine bodies. Add stale-price, malformed-reservation and cancellation/worker race coverage for conditional paths.
- [x] No Production/Supabase write, SQL/Edge Function invocation, migration/db push, pair/price/wallet/order/trade/reservation/Cron/worker/grant/RLS change, merge, deploy, release, APK/Pages publication or cost was made.


## تأیید CI تست Stop-Loss در PR #67 — ۲۷ نوامبر ۲۰۲۶
- [x] وضعیت زنده PR #67 بازبینی شد: باز، Draft، ادغام‌نشده و mergeable؛ HEAD برابر `e7e33a1b1fea07f8d40a136e148225eb8777e7ae`، شاخه ۹۹ commit جلوتر از main و بدون commit عقب‌تر.
- [x] اجرای GitHub Actions با شناسه `46038127085` برای همین HEAD پیدا و jobها بررسی شد؛ job اصلی و هر ۲۶ مرحله موفق هستند.
- [x] مرحله ۲۵ (`Apply authoritative TP-SL and Stop-Limit migrations in disposable PostgreSQL`) موفق است. فایل `supabase/tests/authoritative_conditional_source_parity.sql` در همین HEAD مسیرهای take_profit و stop_loss را جداگانه اجرا می‌کند؛ برای Stop-Loss، trigger count=1 و وضعیت هر دو `conditional_orders` و سفارش والد `orders` برابر `filled` را assert می‌کند.
- [x] بنابراین تست Stop-Loss افزوده‌شده در commit `81f6476` اکنون در CI روی HEAD نهایی تأیید شده است. این نتیجه صرفاً برای PostgreSQL disposable است و هیچ ادعایی درباره اجرای Production ندارد.
- [ ] گام بعد: طراحی source-parity canonical identity برای TP/SL و Stop-Limit؛ انتقال `pair_id`، `base_asset_id` و `quote_asset_id` از ورودی تا parent/child، reservation و worker؛ lookup قیمت pair-keyed؛ سپس duplicate ticker، stale price، invalid reservation و cancellation/worker race tests. Market/Limit adapters باید با بدنه واقعی موتورهای authoritative جایگزین شوند.
- [x] هیچ تغییر Production، Migration/db push، SQL روی Supabase، merge، deploy/release، انتشار APK/Pages یا هزینه‌ای انجام نشد.


## گسترش تست source-parity برای قیمت stale و رزرو نامعتبر — ۲۷ نوامبر ۲۰۲۶
- [x] در `supabase/tests/authoritative_conditional_source_parity.sql` تست stale-price برای TP/SL اضافه شد: worker نباید سفارش را trigger کند و reservation باید reserved بماند؛ پس از ثبت مشاهده تازه، همان سفارش باید قابل اجرا شود.
- [x] تست stale-price برای Stop-Limit اضافه شد: سفارش والد pending و رزرو USDT محفوظ می‌ماند؛ پس از تازه‌شدن قیمت، worker باید parent/child را trigger کند.
- [x] تست reservation نامعتبر Stop-Limit اضافه شد: دارایی رزرو عمداً به شناسه/نماد نادرست تغییر می‌کند؛ worker نباید child order بسازد، باید attempt_count را افزایش دهد و parent را pending نگه دارد. پس از اصلاح fixture، retry باید موفق شود.
- [!] کد تست در commit `966a7ce00e560b200fb7fc3ab3c4cc8976047935` ثبت شد. CI run `46038710233` برای همین commit آغاز شده و در زمان این ثبت هنوز در حال اجراست؛ تا نتیجه نهایی، این سه regression را تأییدشده تلقی نکنید.
- [ ] پس از CI: بررسی لاگ step 25 و رفع هر خطا؛ سپس ثبت نتیجه نهایی و ادامه طراحی canonical IDs برای TP/SL و Stop-Limit. این harness همچنان Market/Limit adapters جداشده دارد و هنوز canonical identity را به migrationهای authoritative منتقل نمی‌کند.
- [x] فقط فایل تست و مستندات شاخه تغییر کرده‌اند؛ هیچ Production DB، migration اجرایی، Supabase SQL، cron/worker، merge، deploy/release یا هزینه‌ای تغییر نکرده است.



## Shahram 165 — authoritative conditional regressions green; canonical call-chain mapped (2026-11-27)
- [x] Rechecked live PR #67: open, Draft, unmerged, mergeable; HEAD at start of checkpoint was `ce83b53610e7daea12fbc927b7d1ca214486696d`.
- [x] CI run `46038710233` for test commit `966a7ce00e560b200fb7fc3ab3c4cc8976047935` completed SUCCESS.
- [x] CI run `46038816951` for latest code commit `ce83b53610e7daea12fbc927b7d1ca214486696d` completed SUCCESS. Both runs passed steps 17–22 (including two-session cancellation/worker races), step 25 (exact authoritative TP/SL and Stop-Limit migrations in disposable PostgreSQL), and step 26 (duplicate-ticker canonical fixture).
- [x] Therefore the added TP/SL stale-price, Stop-Limit stale-price and malformed-reservation/retry cases in `authoritative_conditional_source_parity.sql` are CI-verified on the successful runs. The harness still uses explicit Market/Limit adapters; it does not prove canonical-ID integration with those engines.
- [x] Re-read exact source bodies for `execute_demo_trade`, `place_limit_order`, `process_limit_orders`, `place_conditional_exit_order`, `cancel_conditional_exit_order`, `process_conditional_orders`, `place_stop_limit_order`, `cancel_stop_limit_order` and `process_stop_limit_orders`. Added a source-to-target call-chain matrix and structural constraints to `docs/CANONICAL_ASSET_IDENTITY_DESIGN_2026-11-27.md`.
- [!] Confirmed the next change cannot be a few nullable columns: pair resolution, price source, reservation asset, Market/Limit execution and parent/child lifecycle must move together to immutable pair/base/quote IDs. Display ticker must remain non-authoritative; ambiguous legacy symbol-only calls must fail closed.
- [ ] Next: inventory base schema and all writers/readers for `crypto_assets`, `demo_trading_pairs`, `market_prices`, balances, orders and reservations; then prepare a disposable-only coordinated canonical migration candidate and test actual Market/Limit/TP-SL/Stop-Limit bodies. OCO remains separate.
- [x] No Production/Supabase write, SQL invocation, migration/db push, pair/price/wallet/order/trade/reservation/Cron/worker/grant/RLS change, merge, deploy, release, APK/Pages publication or cost was made.



## تکمیل مرجع ساختار جدول‌ها از Recovery-Test — ۲۷ نوامبر ۲۰۲۶
- [x] وضعیت پروژهٔ موجود `DigiArz-Recovery-Test` با ref `zrriqwyolcjhbappocuw` بررسی شد: ACTIVE_HEALTHY، PostgreSQL 17.11.0.019. هیچ پروژه/branch جدید و هیچ هزینه‌ای ایجاد نشد.
- [x] فقط metadata با `list_tables(verbose=true)` در schemaهای public/private خوانده شد؛ هیچ SELECT از ردیف‌های کاربران/مالی یا اجرای تابعی انجام نشد و این پروژه برای تست استفاده نشد.
- [x] snapshot تاریخی نشان می‌دهد `crypto_assets` با `coingecko_id` کلید اصلی دارد و `symbol` کلید یکتا نیست؛ `demo_trading_pairs` با `pair_symbol` کلید اصلی و `base_coingecko_id` یکتا است؛ `market_prices` با `symbol` کلید اصلی است. این ساختار duplicate display ticker را در مسیر pair/price فعلی پشتیبانی نمی‌کند.
- [x] `orders.symbol`، `trades.symbol`، `conditional_orders.symbol`، `order_reservations.asset` و `asset_balances.asset` همگی متن هستند و شناسه canonical در آن‌ها وجود ندارد. جدول‌های مالی/بازار اصلی در این snapshot RLS-enabled گزارش شدند.
- [!] این snapshot بازیابی‌شده تاریخی است و برابری آن با Production امروز ثابت نشده؛ ACLهای Recovery-Test نیز در restore حذف شده‌اند. از این پروژه برای آزمون مالی استفاده نمی‌شود و grants/owners آن مبنای طراحی نیست.
- [ ] گام بعد: ساخت inventory دقیق از کلیدها، unique indexes، FKها، triggers، policies و writerها در یک snapshot مجاز و جاری؛ سپس طراحی migration candidate یکپارچه. هیچ Production query/write، migration، db push یا تغییر هزینه‌ای در این مرحله انجام نشد.



## تکمیل fingerprint کاتالوگ Recovery-Test برای قیود و ایندکس‌ها — ۲۷ نوامبر ۲۰۲۶
- [x] یک query صرفاً `pg_catalog` روی پروژهٔ تاریخی Recovery-Test اجرا شد؛ فقط indexes، constraints، triggers، RLS و policies جدول‌های هدف را خواند. هیچ جدول مالی/کاربری scan نشد و هیچ داده یا schema تغییر نکرد.
- [x] کلیدهای یکتا/قیود مهم snapshot مشخص شدند: `demo_trading_pairs(pair_symbol)` و `demo_trading_pairs(base_coingecko_id)`؛ `market_prices(symbol)`؛ `crypto_assets(coingecko_id)` با ایندکس غیر یکتای lower(symbol)؛ `asset_balances(user_id,asset)`؛ `order_reservations(order_id)` و FK مرکب order/user؛ `orders(id,user_id)`؛ `conditional_orders(order_id)`.
- [x] سه trigger account guard در snapshot روی INSERTهای orders، trades و transactions هستند. قیدهای حسابداری سفارش و رزرو نیز در design doc ثبت شدند تا در migration canonical حذف یا تضعیف نشوند.
- [!] این snapshot همچنان Recovery-Test تاریخی است و برابری Production امروز ثابت نشده؛ ACLهای restore حذف شده‌اند. هیچ grant یا owner از این snapshot کپی نمی‌شود.
- [ ] مرحله بعد: تولید manifest ساختاری canonical برای disposable PostgreSQL از همین DDL مستندشده و افزودن parity assertions؛ پیش از هر candidate migration باید schema source gaps و writerهای catalog تکمیل شوند.



### ابزار آماده‌سازی fingerprint جاری کاتالوگ و موتور مالی — ۲۷ نوامبر ۲۰۲۶
- [x] فایل فقط‌خواندنی `supabase/audit/canonical_asset_identity_schema_fingerprint.sql` اضافه شد. فقط metadata کاتالوگ PostgreSQL، information_schema، تعریف توابع/ACL، RLS/policies، indexes/constraints/triggers و jobهای pg_cron را جمع می‌کند؛ هیچ ردیف تجاری/کاربری را نمی‌خواند و هیچ تغییری اعمال نمی‌کند.
- [x] تست Node `tests/canonical-asset-identity-audit.test.js` اضافه شد تا query واحد، read-only بودن، عدم scan مستقیم جداول مالی/کاتالوگ و پوشش objectهای هویتی و workerها را enforce کند.
- [!] این SQL در این مرحله روی Production اجرا نشده است؛ فقط به‌عنوان ابزار آماده برای snapshot مجاز و زمان مناسب ثبت شده. اجرای آن بدون مجوز جداگانه و بررسی وضعیت DB انجام نخواهد شد.
- [ ] CI جدید باید تست Node را اجرا کند. پس از سبزشدن، در زمان پایداری سرویس و مجوز مالک، snapshot metadata جاری Production با Recovery-Test تاریخی و migration source مقایسه شود؛ تا آن زمان از Recovery-Test فقط به‌عنوان مرجع تاریخی استفاده می‌شود.



### اصلاح تست fingerprint و افزودن اجرای SQL در PostgreSQL موقت — ۲۷ نوامبر ۲۰۲۶
- [x] اجرای CI شماره `46040194262` روی commit اولیه تست fingerprint به‌دلیل خطای syntax در regex فایل Node متوقف شد؛ ۸۳ تست دیگر موفق بودند. علت دقیق از log استخراج و regexها اصلاح شدند؛ این شکست مربوط به تست جدید بود، نه موتور سفارش یا migrationها.
- [x] اجرای مجدد `46040236103` روی commit `6f705ca` مرحله Node را با موفقیت گذراند و مراحل PostgreSQL ۱ تا ۱۱ نیز سبز شدند؛ در زمان ثبت هنوز workflow در مرحلهٔ rollout rounding بود.
- [x] برای اینکه فقط regex کافی نباشد، setup کاملاً مصنوعی `canonical_asset_identity_fingerprint_setup.sql` و step جدید CI اضافه شد تا خود SQL fingerprint روی PostgreSQL موقت اجرا و syntax آن تأیید شود. setup فقط roleهای آزمایشی و جدول خالی `cron.job` می‌سازد.
- [!] اجرای کامل CI روی commit workflow جدید `780312d` هنوز باید بررسی شود؛ تا موفقیت step جدید، اجرای SQL fingerprint را تأییدشده اعلام نکنید.
- [x] هیچ query از این fingerprint روی Production اجرا نشده؛ هیچ Production/Supabase write یا migration/db push، merge، deploy/release یا هزینه‌ای انجام نشده است.



### ممیزی تکمیلی writerهای کاتالوگ و مدیریت pair — Recovery-Test تاریخی
- [x] از pg_proc فقط تعریف و fingerprint توابع مرتبط در snapshot تاریخی خوانده شد؛ هیچ ردیف تجاری/کاربری خوانده نشد. `refresh_crypto_assets()` در snapshot ۸٬۸۸۵ بایت است و `symbol` را همراه upsert بر اساس `coingecko_id` به‌روزرسانی می‌کند؛ این snapshot trigger/قید یکتای سراسری برای `crypto_assets.symbol` نشان نداد.
- [x] trigger function `private.auto_list_verified_exchange_asset()`، `admin_enable_market_pair()` و `admin_disable_market_pair()` بررسی شدند. فعال‌سازی به curated list/volume/rank محدود است؛ غیرفعال‌سازی با وجود یافتن pair بر اساس CoinGecko ID، سفارش‌ها و رزروها را با `symbol` فیلتر می‌کند.
- [!] غیرفعال‌سازی symbol-based در مدل duplicate ticker یک خطر cross-asset است؛ اصلاح باید همراه pair_id و asset_id و در همان تغییر هماهنگ Market/Limit/TP-SL/Stop-Limit انجام شود، نه به‌صورت patch مستقل روی Production.
- [x] یافته‌ها و fingerprintهای تاریخی در design doc ثبت شدند. تابع `refresh_market_prices()` در Recovery-Test قدیمی‌تر از migration محدودیت ۵۱۵ شناسه است و برای تعریف جاری Production به آن استناد نمی‌شود.
- [ ] گام بعد: آماده‌سازی manifest از writerها و lifecycle مدیریت pair و طراحی candidate canonical provisioning/disable در PostgreSQL موقت. هیچ Production query/write، migration، db push، تغییر cron یا هزینه‌ای انجام نشد.



## Shahram 166 — canonical fingerprint query verified in disposable PostgreSQL (2026-11-27)
- [x] Corrected the Node test regex syntax after CI run `46040194262` exposed the initial test-file parse error. The rerun `46040236103` passed the Node test stage and all PostgreSQL steps through step 11; run `46040272364` later completed SUCCESS on the full workflow before the fingerprint execution step was added.
- [x] Added disposable bootstrap `supabase/tests/canonical_asset_identity_fingerprint_setup.sql` and workflow step 27 to execute the exact read-only query `supabase/audit/canonical_asset_identity_schema_fingerprint.sql` in a fresh PostgreSQL 17 database.
- [x] GitHub Actions run `46040451729` on commit `780312d3fdc69e21581c405afffee322e3bdc119` completed SUCCESS. Step 27 (read-only canonical schema fingerprint) passed; all 27 main steps succeeded.
- [x] The fingerprint SQL was tested only in disposable PostgreSQL. It has not been run on Production. It reads catalogs/information_schema/pg_cron metadata only and does not scan business rows or write data.
- [x] Current PR #67 remains open, Draft, unmerged; branch remains based on main with no behind commits at the last comparison. The PR body now records the catalog-admin source findings and the new audit tooling.
- [ ] Next: check the latest docs-only head's CI, then use the verified fingerprint only when an authorized, stable current Production snapshot is appropriate. After source/schema reconciliation, prepare canonical pair/asset migration candidate and end-to-end disposable Market/Limit/TP-SL/Stop-Limit tests. OCO remains a separate state machine.
- [x] No Production/Supabase write, migration/db push, financial data change, cron/worker/grant/RLS change, merge, deploy/release, APK/Pages publication or cost was made.

## Shahram 167 — strengthen canonical pair/ledger consistency fixture (2026-11-27)
- [x] Rechecked live PR #67: open, Draft, unmerged, mergeable; branch is 118 commits ahead and 0 behind main at base fbfb5e974e754088a32c9fdcd76fc2ca9ab0f98b.
- [x] Latest CI before this change: run 46040715926 on head 593e66d709bf3894451c56574004050265022088 completed SUCCESS; all 27 main steps passed, including real two-session Limit/TP-SL/Stop-Limit race steps 17–19, authoritative conditional migrations step 25, duplicate-ticker candidate step 26 and read-only fingerprint step 27.
- [x] Reviewed the canonical fixture and found its original proof did not enforce database-level consistency between a pair ID and the base/quote IDs copied onto orders/trades, nor did it bind a reservation to the same user/order at the schema level.
- [x] Strengthened only the disposable fixture supabase/tests/canonical_asset_identity_candidate.sql: pair composite uniqueness/FK; order-to-pair composite FK; trade-to-order composite FK; one reservation per order and composite same-user FK; order filled/remaining accounting check.
- [x] Added worker fail-closed checks for mismatched order/pair identity and reservation owner; added regression assertions for pair/base mismatch rejection and malformed same-ticker reservation preservation followed by successful retry.
- [!] The new candidate-fixture CI is pending. This remains a miniature disposable Market/Limit proof, not an authoritative Production migration or proof of real Market/Limit/TP-SL/Stop-Limit canonical source parity.
- [ ] Next after CI: inspect exact step logs; if green, continue building a coordinated canonical-ID source-parity harness and catalog provisioning/disable candidate. Do not copy fixture logic into Production or treat this as rollout-ready.
- [x] No Production query/write, migration/db push, pair/price/wallet/order/trade/reservation/Cron/worker/Edge Function/grant/RLS change, merge, deploy/release, APK/Pages publication or cost was made.

## Shahram 168 — fix reservation-owner regression assertion (2026-11-27)
- [x] Rechecked CI for the previous canonical fixture change. Runs 46042843291 and 46042889895 both failed at step 26; steps 1–25 passed. The failure was in the new test assertion, not a production migration: the test attempted to mutate a reservation after its order had already filled and the worker had correctly deleted the reservation, so zero rows changed and the test's own sentinel exception fired.
- [x] Moved the owner-mismatch mutation assertion to the pending-order phase, immediately after verifying the reservation exists and before the fresh-price fill. This makes the composite same-user FK assertion exercise an actual row.
- [!] New head 742d2263b1bb23420230882166bbfed69e6ccb7b is awaiting CI. Do not mark the canonical candidate step green until step 26 and full workflow complete successfully.
- [ ] After CI, extend candidate coverage from the miniature Market/Limit harness to canonical identity through the authoritative conditional-order parent/child lifecycle and pair-scoped cancellation; then build the OCO linked-order state machine tests.
- [x] No Production/Supabase changes, merge, migration/db push, deploy/release, publication, Cron/worker/grant/RLS changes or costs.
## Shahram 169 — pair-scoped disable isolation candidate (2026-11-27)
- [x] Added a disposable pair-administration function to the canonical fixture. It disables a single pair by pair_id, cancels only that pair's pending orders, and releases only those reservations; it never filters by display ticker.
- [x] Added a duplicate-display-pair regression: two separate DOT/USDT pairs each have a pending Limit sell; disabling pair A must cancel/release A only, while pair B remains enabled, pending and reserved.
- [x] Preserved the order accounting invariant on cancellation: status changes to cancelled while filled_amount + remaining_amount continues to equal amount.
- [x] Corrected the reservation-owner test after CI runs 46042843291 and 46042889895 exposed that the prior assertion ran after fill had deleted the reservation. The assertion now runs while the pending reservation exists; prior failures were test assertion placement, not production behavior.
- [!] CI runs 46043153310 (owner assertion correction), 46043173872 (status update) and 46043222735 (pair-disable candidate) were still in progress at the time of this entry. No pass is claimed yet.
- [ ] Await CI; if pair-disable fixture passes, extend canonical pair identity through authoritative TP/SL and Stop-Limit parent/child plus pair-scoped cancellation races. OCO remains a distinct not-yet-built state machine.
- [x] This work changes only disposable tests/docs in the Draft branch. No Production/Supabase data/schema/function/ACL/RLS/Cron/worker changes, merge, deploy/release, APK/Pages publication or cost.
## Shahram 170 — correct candidate fixture assertions and SQL delimiters (2026-11-27)
- [x] Inspected completed CI failures for runs 46043153310, 46043173872, 46043222735, 46043237020 and 46043298257. Candidate step 26 exposed three test-fixture defects: (1) the expected balances after the second valid sell fill were understated; observed correct accounting was base A 1.35 and quote 9975.4485; (2) the ownership mutation assertion did not reliably prove a violating insert against an existing order, so it was replaced with a direct invalid reservation INSERT followed by restoration of the valid reservation; (3) the newly added pair-disable function and DO block had malformed dollar-quote delimiters.
- [x] Corrected the expected balances, replaced the reservation ownership assertion with a direct FK-negative INSERT test, and used named dollar-quote delimiters $disable_pair$ and $candidate_test$.
- [x] Verified the corrected source around the new function and DO block via GitHub file read. These corrections are test-only.
- [!] The corrected head commit b8f08f9322dda517443f443ab189260086ef93b9 is awaiting a new CI run; no success is claimed.
- [ ] Next: inspect the new run's step 26 and full workflow; if green, move to source-faithful canonical identity for real conditional-order and Stop-Limit parent/child paths. OCO remains separate.
- [x] No Production/Supabase data or schema changes, no merge, db push, deploy/release, APK/Pages publication, Cron/worker/grant/RLS changes or costs.
## Shahram 171 — canonical conditional parent/child identity proof (2026-11-27)
- [x] Extended only the disposable canonical candidate fixture with a conditional_orders relation carrying pair_id/base_asset_id/quote_asset_id and composite FKs for both parent order and execution child.
- [x] Added a negative regression: a child order for a different canonical pair with the same display label cannot attach to the parent; the correct same-pair child is accepted.
- [x] Extended pair-scoped disable candidate to cancel conditional parent/child rows and release the parent's reservation only for the disabled pair. The paired duplicate-label scenario asserts pair B's triggered parent, child, reservation and state remain intact when pair A is disabled.
- [!] This is a candidate invariant fixture, not a rewrite or execution of the authoritative Production TP/SL/Stop-Limit RPC bodies. It does not yet cover the full production worker retry/cancellation race or OCO.
- [!] CI run 46043559923 for commit b8f08f9322dda517443f443ab189260086ef93b9 was in progress when the conditional fixture extension was added. The new head 5116ecb896a9c216ebd18e5c16d845670e103f29 needs its own CI result; no pass is claimed.
- [ ] Next: verify current CI and step 26 for the corrected base fixture; then execute the new parent/child identity tests in disposable PostgreSQL. Build a source-faithful wrapper around actual conditional/Stop-Limit migration definitions, retaining actual reservation/worker/cancellation code, before advancing to OCO.
- [x] No Production/Supabase data/schema/function/ACL/RLS/Cron/worker changes, no merge/db push/deploy/release/publication, and no new costs.
## Shahram 172 — stabilize fresh-price precondition in pair-disable fixture (2026-11-27)
- [x] Inspected run 46043559923: the corrected SQL quoting and balance/owner assertions progressed, but the disposable test later failed because pair A's observation was no longer within the fixture's two-minute freshness window when the pair-disable lifecycle began.
- [x] Added an explicit refresh of both disposable pair observations immediately before creating the conditional parent/child and cancellation test orders. This is test-only setup; it does not weaken the stale-price negative test, which still runs earlier.
- [!] The current code head e30f4022d927a8a665287d0d34f06d6abbb8ce0b and status update require fresh CI. No green claim yet.
- [ ] Verify step 26, then verify parent/child canonical FK isolation and pair-scoped disable behavior. Do not copy fixture helpers into Production.
- [x] No Production/Supabase changes, merge, migration/db push, deploy/release, publication, worker/Cron/grant/RLS changes or costs.
## Shahram 173 — authoritative TP/SL and Stop-Limit source-chain design review (2026-11-27)
- [x] Reviewed the exact mainline TP/SL migration blob 3360c21a69b7fae83a7f2494428367d1b7658e81 and Stop-Limit migration blob 3f421c6380630d74b846cd66dc7b121786237c0f.
- [x] Recorded the full symbol-based source call chains for conditional placement/worker/cancel and Stop-Limit placement/trigger/child Limit/sync/cancel in docs/CANONICAL_ASSET_IDENTITY_DESIGN_2026-11-27.md.
- [x] Explicitly recorded that Stop-Limit sync locks conditional row and parent but not child (FOR UPDATE OF c,parent SKIP LOCKED); candidate must preserve/test source semantics unless separately reviewed.
- [x] Defined canonical tuple invariants for parent/conditional/child/reservation/trade, pair-keyed price lookup, pair-scoped cancellation, source-faithful grants/RLS/SECURITY DEFINER/locking/retries and quarantine of ambiguous symbol-only backfill.
- [x] Marked OCO as a distinct unimplemented linked-order state machine; no authoritative OCO table/RPC/worker found in source search.
- [!] The current SQL candidate is still a disposable invariant fixture, not an actual port of the authoritative TP/SL/Stop-Limit function bodies. Full source-faithful PostgreSQL harness remains outstanding.
- [ ] Await current CI run 46043897871 (code head e30f4022d927a8a665287d0d34f06d6abbb8ce0b) and 46043920340 (status/docs head 2f894c991781fca63145f46a337efd83ffe1f9bd), then verify newest branch head after this design update.
- [x] No Production/Supabase function/schema/ACL/RLS/cron/worker changes, merge, migration/db push, deploy/release, APK/Pages publication or cost.
## Shahram 174 — canonical duplicate-ticker + conditional parent/child fixture CI passed (2026-11-27)
- [x] Exact-decimal workflow run 46043897871 (Run #2345) on code commit e30f4022d927a8a665287d0d34f06d6abbb8ce0b completed SUCCESS. The job log explicitly reports `Canonical asset identity / duplicate ticker Market and Limit lifecycle: PASS` from canonical_asset_identity_candidate.sql:712.
- [x] The same successful run also passed the real two-session TP/SL conditional execution/cancellation race, real two-session Stop-Limit child execution/cancellation race, Stop-Limit parent/child integration, captured Production invalid-reservation retry, TP/SL exact-decimal integration, scheduler interleaving/fairness/idempotency and authoritative conditional source-parity harness.
- [x] Step 26 in the successful run includes the expanded disposable candidate checks: pair/base/quote composite FK; direct reservation owner-FK negative insert; malformed reservation fail-closed and retry; stale price rejection; duplicate ticker asset/balance isolation; conditional parent/child same-pair FK; cross-pair child rejection; and pair-scoped disable preserving the other same-label pair's conditional parent/child/reservation.
- [!] Run 2345 is a disposable PostgreSQL 17 CI run and does not make the candidate Production-ready. It proves fixture behavior, not a full migration/rollout or Production schema/ACL parity.
- [!] The current latest branch head is docs-only commit c879cc0a63b4c0b33b90f8460b3d6f6a06cbb4c5. Runs 46044024709 and 46044050255 on the later design/status commits were still in progress at the time of this note; do not claim those docs heads green until complete.
- [ ] Next: await docs-head CI; then build the source-faithful canonical migration candidate from actual authoritative RPC bodies and current DDL/ACL snapshots. Preserve Stop-Limit parent-only child lock semantics pending explicit concurrency review. OCO remains a separate unimplemented state machine.
- [x] No Production/Supabase changes, merge, migration/db push, deploy/release, APK/Pages publication, cron/worker/grant/RLS changes or costs.

## Shahram 175 — live Production schema/function baseline captured; source parity suite added (2026-11-27)

- [x] Rechecked live PR #67: open, Draft, unmerged, mergeable; latest checked head before this update was eaf140e70e6ced5e901c7f4cd834217cf3cd36de, 134 commits ahead / 0 behind main. CI run 2349 on that head completed SUCCESS; runs 2347 and 2348 also completed SUCCESS.
- [x] Re-read Supabase project metadata: gfoaubfilhttnwjykaox ACTIVE_HEALTHY, PostgreSQL 17.11.0.018, us-west-2.
- [x] Captured current Production table columns, primary/unique keys, foreign keys, checks, RLS state and policies for crypto_assets, demo_trading_pairs, market_prices, orders, trades, conditional_orders, order_reservations, asset_balances and wallets using metadata-only catalog queries. No business/user rows were selected.
- [x] Confirmed current live schema still uses mutable ticker text as the trade identity: crypto_assets PK coingecko_id but symbol is mutable; demo_trading_pairs PK pair_symbol and UNIQUE base_coingecko_id; market_prices PK symbol; orders/trades/conditional_orders use symbol; reservations and asset_balances use text asset. No pair_id/base_asset_id/quote_asset_id exists on the financial lifecycle relations.
- [x] Captured eight additional exact live Production function definitions as TEST FIXTURE ONLY files: execute_demo_trade, TP/SL place/cancel/worker, Stop-Limit place/cancel, admin_disable_market_pair and refresh_market_prices. Fingerprints and live ACL metadata are documented in docs/CANONICAL_ASSET_IDENTITY_DESIGN_2026-11-27.md.
- [x] Added tests/canonical-asset-production-source.test.js to pin the eight live md5 fingerprints and assert the current ticker-keyed entrypoint, conditional worker, Stop-Limit, pair-disable and market-price-refresh call chains. Existing snapshots/tests continue to cover live place/cancel Limit and both workers.
- [x] Confirmed live function execution boundary: all reviewed functions are postgres-owned SECURITY DEFINER; authenticated may execute user-facing placement/cancel/admin RPCs, while process workers are service_role-only; anon is denied. refresh_market_prices is postgres-only and uses pg_catalog search_path. Do not broaden grants.
- [!] Separate Advisor finding: two private pg_net backup tables have RLS disabled. A follow-up metadata-only check found no direct anon/authenticated/service_role table grants (only postgres grants); authenticated has private schema USAGE, anon does not, and pgrst.db_schemas was unset. Public Data API exposure was not established. RLS-disabled remains a defense-in-depth warning; no change was applied and it needs separate owner-approved review.
- [!] The current source shows live symbol-wide pair-disable cleanup and symbol-keyed market price upserts. These must be migrated to pair_id; do not treat the passing candidate fixture as proof the live RPCs are fixed.
- [!] The 17 missing applied migration SQL sources and timestamp mismatches remain unresolved, so no complete migration replay/deployment candidate can be certified yet.
- [ ] Next: run CI on the newly added live-source snapshots and Node source-contract suite. If green, create a dependency/DDL reconciliation matrix for the absent baseline table migrations and capture any missing function/trigger/ACL dependencies before drafting the canonical migration. No speculative DDL until the full current source set is accounted for.
- [x] All Production queries in this step were metadata/function-definition reads only; no business/user rows or financial records were selected. No Production change, merge, db push, migration, deploy/release, cron/worker/grant/RLS change, APK/Pages publication or cost.


## Shahram 176 — catalog/discovery dependency chain captured from live Production (2026-11-27)

- [x] Expanded the read-only pg_catalog inventory to 33 public/private functions referencing catalog, exchange matching, pair, market-price, order, reservation, balance or conditional-order relations; captured relevant live catalog/discovery definitions as 18 test-only snapshots.
- [x] Added tests/canonical-asset-catalog-source.test.js to pin exact live fingerprints and assert the current provider-symbol mutation, exchange auto-listing collision gates, curated/volume/rank pair activation gates, ticker-keyed market trade_enabled calculation, and ambiguous exchange matching behavior.
- [x] Captured private.guard_active_account_writes() live source (md5 29b8e23c1de8eb4762a8cf1a9c9343ce) and verified its three active BEFORE INSERT triggers on public.orders, public.trades and public.transactions. Added snapshot and CI assertions; canonical changes must preserve all three.
- [x] Confirmed catalog-side blockers: refresh_crypto_assets mutates ticker text on CoinGecko upsert; auto-listing and listing uniqueness reject ticker collisions; auto-activation requires curated listing, >=USD 1m volume, rank <=2,000, recent matched exchange evidence and ticker-keyed CoinGecko price; admin activation applies the same product-selection gates; get_crypto_market derives trade_enabled from ticker-keyed pair/price relations.
- [x] Rechecked current live migration ledger against GitHub main: 55 applied entries, 40 local SQL files, 17 applied sources missing locally, 20 timestamp mismatches, and 2 local-only migrations. Counts match the latest reconciliation record; no migration history was edited.
- [!] The new catalog snapshots/tests are documentation and regression fixtures only. They do not remove product gates or change any Production function. Every catalog asset becomes tradable only after a later canonical lifecycle migration is source-faithfully designed and approved.
- [ ] Next: verify CI for the new 18-function catalog source suite and active-account guard snapshot. Then prepare the staged additive canonical schema/function migration candidate in drafts, with explicit ambiguity quarantine and rollback/rehearsal plan. First resolve all missing/mismatched migration sources before any replay or db push.
- [x] All Supabase calls in this step were SELECT/catalog/function-definition reads only; no business/user rows were selected and no Production state was changed. No merge, db push, migration, deploy/release, cron/worker/grant/RLS change, APK/Pages publication or cost.


## Shahram 177 — correct market-read source contract and pin catalog pipeline (2026-11-27)

- [x] Reviewed CI run 46045360757 / Run #2366: all 18 catalog function fingerprint tests and the provider/listing/activation/matching contracts passed; one market-read assertion failed because it incorrectly expected get_crypto_market() to join demo_trading_pairs.
- [x] Re-read the exact live snapshot. Actual behavior is narrower and weaker: trade_enabled is true when a positive market_prices row exists for ca.symbol || 'USDT' within one minute; the function does not join demo_trading_pairs or check is_enabled.
- [x] Corrected tests/canonical-asset-catalog-source.test.js to assert the actual live contract and explicitly reject any assumption that the API verifies enabled pair identity. Recorded the functional gap in docs/CANONICAL_ASSET_IDENTITY_DESIGN_2026-11-27.md.
- [!] Runs 2366–2370 are expected failures from the pre-correction commit(s); the corrected test commit 415d66784f27906bd60aa2270b8123e4d091c758 and later docs/status heads require fresh CI. No green claim is made for the corrected suite yet.
- [ ] Next: verify CI for corrected market-read contract and active-account guard snapshot; then capture the full current DDL/index/trigger/policy dependency matrix and draft an isolated additive canonical migration only after the missing migration sources are accounted for.
- [x] No Production changes, no merge/db push/migration/deploy/release, no cron/worker/grant/RLS changes, no publication and no new costs.


## Shahram 178 — active-account guard source contract corrected (2026-11-27)

- [x] Inspected CI run 46045575608 / Run #2371. The corrected market-read contract passed; the remaining failure was a mistaken test assumption that private.guard_active_account_writes() calls current_account_is_active().
- [x] Verified exact live guard body: it SELECTs profiles.is_active for NEW.user_id FOR SHARE, rejects missing/inactive profiles and returns NEW only for an active account. It intentionally performs the active-account check directly inside the trigger.
- [x] Updated tests/canonical-asset-catalog-source.test.js to assert the exact SELECT/FOR SHARE/coalesce guard contract; clarified the implementation in the canonical design doc.
- [!] The corrected test commit 6119376bc08d2abf9f262681f0c20d4c9836ecca and later docs/status heads require fresh CI. No green claim yet for the complete 19-function catalog/guard suite.
- [ ] Next: verify latest CI and then capture get_my_order_reservations plus any remaining user-facing reservation/fee helper dependencies before freezing the canonical migration dependency manifest.
- [x] No Production changes, merge, migration/db push, deploy/release, cron/worker/grant/RLS changes, publication or costs.


## Shahram 179 — live catalog source suite and reservation API pinned; CI passed (2026-11-27)

- [x] Run 2379 (46045817184) completed SUCCESS on commit 30f1fbaa361c4ee3b26d48a8266781820cc1945d. Node/browser integration output: 131 tests, 131 pass, 0 fail.
- [x] The successful suite includes all 18 catalog/discovery function fingerprint snapshots, active-account guard fingerprint/trigger behavior, current market-read ticker-price contract, provider symbol mutation, curated/volume/rank gates, exchange ambiguity staging, and reservation read API source contract.
- [x] Captured additional live Production snapshots for current_account_is_active(), get_demo_trading_fee_rate(text,text), and get_my_order_reservations(uuid[]). Reservation API is owner-scoped and bounded to 1–100 order IDs, but currently returns ticker text asset only; canonical ID fields are required in the future API.
- [x] Security Advisor read-only review at 2026-11-27 17:58 UTC: 2 anon-executable SECURITY DEFINER functions (get_admin_market_listings and get_exchange_discovered_market_assets), 23 authenticated-executable SECURITY DEFINER functions, 15 RLS-enabled tables without policies, and leaked-password protection disabled. Function bodies show the two anon functions return curated market metadata / recent unmatched or ambiguous public exchange discovery fields, not user rows. Intentionality still needs owner confirmation.
- [x] The separate table listing also flags two private pg_net backup tables with RLS disabled; follow-up metadata check found no direct anon/authenticated/service_role table grants, only postgres grants, so public exposure was not established.
- [!] No grants, policies, RLS state or Auth settings were changed. Do not blanket-revoke authenticated user RPCs; inspect individual authorization checks. Do not auto-enable RLS on worker tables without an access design.
- [!] Current head docs update 784b6ee257d843eb160a459e0c60073e4b87fdac and status update require fresh CI. Run 2379 is the successful code/test head; no green claim yet for the newest docs head.
- [ ] Next: await docs-head CI; then freeze the canonical dependency manifest and build a non-executable draft of the additive canonical schema/function migration. Migration replay remains blocked by 17 missing applied SQL sources, 20 timestamp mismatches and 2 local-only migrations.
- [x] No Production data/schema/function/ACL/RLS/Cron/worker/Auth change, no merge/db push/deploy/release, no APK/Pages publication or cost.


## Shahram 181 — OCO gap documented; canonical rollout remains blocked (2026-11-27)

- [x] Rechecked PR #67 live: open, Draft, unmerged, mergeable; branch `plan/all-catalog-assets-tradable-2026-11-27`, reviewed head before this documentation change `4507cf38cbb385f53ecd2a8416126e70c3116b37`.
- [x] Latest exact-decimal workflow associated with that head: run `46046043108`, completed SUCCESS. Its job contains 27 substantive steps, including authoritative TP/SL and Stop-Limit migration lifecycle tests (with explicitly isolated Market/Limit adapters), and the independent canonical identity fixture. This does not prove canonical IDs are propagated through the authoritative trading call graph.
- [x] Confirmed authoritative checked-in migration paths expose TP/SL and Stop-Limit, but no OCO group/sibling lifecycle exists. Added `docs/OCO_LINKED_ORDER_DESIGN_2026-11-27.md` as a design-only specification covering shared reservation, atomic winner claim, cancellation races, partial-fill policy, canonical IDs, security boundaries, and disposable test matrix.
- [!] OCO is still NOT implemented. The new design document commit is `2658c9d472f4589c60e7c6c2bf8732dc577780cf`; it has not yet received a fresh CI run. Do not claim CI success for the updated documentation head.
- [!] No canonical schema/function migration has been drafted or applied. Market/Limit engine parity, end-to-end canonical IDs through TP/SL and Stop-Limit, OCO implementation, provider-observed freshness, full catalog price coverage, and migration-ledger reconciliation remain blockers.
- [x] No Production data/schema/function/ACL/RLS/Cron/worker/Auth change; no merge, db push, deploy/release, APK/Pages publication, or cost.


## Shahram 182 — canonical dependency manifest frozen (2026-11-27)

- [x] Rechecked live PR #67 before work: open, Draft, unmerged, mergeable; latest pre-step head `c2cdad0fa979e97ec3b49f499ca9cfa591fe72f8`.
- [x] Re-read the canonical identity design, Production catalog/price source audit, authoritative conditional harness setup and CI workflow. Confirmed the authoritative conditional harness executes the checked-in TP/SL and Stop-Limit migration bodies, but deliberately substitutes downstream Market/Limit entrypoints with test adapters. It is not full financial source parity.
- [x] Added `docs/CANONICAL_IDENTITY_DEPENDENCY_MANIFEST_2026-11-27.md`, commit `22dcd84e07234694e93e1dfa12d469e4af8ab0bc`. It freezes catalog admission/writers, pair/price schedulers, read APIs, Market/Limit/TP-SL/Stop-Limit RPCs and workers, reservations, account guards/deactivation, OCO, security invariants, evidence boundaries, and migration blockers.
- [!] Manifest is an audit/design artifact, not an implementation or proof that every external privileged writer is enumerated. Production-only recovered functions and Edge Function code still need fresh source fingerprints before any executable migration proposal.
- [!] No canonical migration draft created yet. Reason: migration ledger remains unreconciled (17 applied sources missing locally, 20 timestamp mismatches, 2 local-only migrations); duplicate ticker reconciliation and source-parity for actual Market/Limit remain open.
- [ ] Next: construct a dependency-complete disposable PostgreSQL 17 harness for the exact authoritative Market/Limit migration bodies, then connect canonical-ID candidate schema and test full settlement/partial-fill/reservation/account-deactivation races. Do not use miniature financial adapters as parity evidence.
- [x] No Production writes/schema/function/ACL/RLS/Cron/worker/Auth changes; no merge/db push/migration replay/history repair, deployment/release, APK/Pages publication, or cost.


## Shahram 183 — authoritative Market/Limit migration harness added (2026-11-27)

- [x] Rechecked PR #67: open, Draft, unmerged, mergeable; branch remains 190 commits ahead and 0 behind main at the latest comparison.
- [x] Added disposable PostgreSQL 17 bootstrap `supabase/tests/authoritative_market_limit_source_parity_setup.sql`.
- [x] Added `supabase/tests/authoritative_market_limit_source_parity.sql`, which exercises the exact checked-in authoritative Market/Limit migration functions: Market buy/sell settlement, caller-price non-authority, stale-price rejection, inactive-account rejection, Limit buy/sell placement, four-cycle 25% partial-fill settlement, reservation consumed/released accounting, stale worker quote preservation, and unauthenticated placement rejection.
- [x] Wired the harness into `.github/workflows/exact-decimal-tests.yml` to apply the actual `20261113161641_enforce_active_accounts_in_demo_trade_and_limit_engine.sql` migration in a fresh disposable database. No copied/miniature Market or Limit financial functions are used in this new step.
- [!] New harness is not yet CI-verified: latest head `f99969a80643d4734949838e8950579bfb9e87d6` has no associated workflow run/status at the time of this checkpoint. Do not claim these SQL assertions passed until a fresh run completes successfully.
- [!] This is an authoritative ticker-based baseline, not canonical-ID implementation. It deliberately establishes the real Market/Limit source behavior before a future canonical candidate is integrated. It does not yet test duplicate ticker isolation through these real functions.
- [ ] Next: obtain a fresh CI result, correct any disposable harness failures, then design the canonical Market/Limit candidate as a coordinated schema + RPC + worker unit and prove duplicate ticker separation with the real lifecycle.
- [x] No Production writes/schema/function/ACL/RLS/Cron/worker/Auth changes; no merge/db push/migration replay/history repair, deployment/release, APK/Pages publication, or cost.


## Shahram 184 — authoritative Market/Limit source-parity baseline passed (2026-11-27)

- [x] CI run `46048133466` / workflow run #2391 completed SUCCESS on commit `a411a73df6a47dc77b4b83950b59b6a19ee22b95`.
- [x] All substantive test steps passed, including real two-session Limit, TP/SL and Stop-Limit races; fair scheduler disposable PG17 exercise; authoritative TP/SL + Stop-Limit migration application; duplicate-ticker canonical fixture; and read-only canonical schema fingerprint.
- [x] New step 28, `Apply authoritative Market and Limit migration in disposable PostgreSQL`, completed SUCCESS. It bootstrapped disposable PostgreSQL 17, applied the exact checked-in `20261113161641_enforce_active_accounts_in_demo_trade_and_limit_engine.sql` body, then ran Market buy/sell settlement, stale-price and inactive-account rejection, Limit buy/sell placement, four 25% fills, exact reserve consumption/release, stale worker quote preservation, and unauthenticated placement rejection assertions.
- [!] This proves the current authoritative ticker-based Market/Limit baseline executes under the disposable harness. It does NOT prove canonical asset_id/pair_id is propagated into those production-source functions, nor resolve duplicate ticker execution through the actual Market/Limit path.
- [!] The test setup supplies minimal Supabase auth/profile/table scaffolding only; the financial Market/Limit functions are loaded from the exact checked-in migration, not replaced by miniature lookalikes.
- [ ] Next: create a canonical Market/Limit candidate migration in a separate disposable schema/branch artifact that preserves exact behavior while adding pair_id/asset_id and duplicate-ticker isolation; run full source-parity tests before extending TP/SL/Stop-Limit. Do not prepare a Production rollout until migration ledger reconciliation and source fingerprints are resolved.
- [x] PR #67 remains open, Draft, unmerged, mergeable; latest head at checkpoint `a411a73df6a47dc77b4b83950b59b6a19ee22b95`, 191 commits ahead and 0 behind main.
- [x] No Production writes/schema/function/ACL/RLS/Cron/worker/Auth changes; no merge/db push/migration replay/history repair, deployment/release, APK/Pages publication, or cost.


## Shahram 185 — canonical Market/Limit parity gap review (2026-11-27)

- [x] Reviewed exact authoritative Market/Limit migration source against the existing canonical duplicate-ticker fixture after CI #2391 passed.
- [x] Added `docs/CANONICAL_MARKET_LIMIT_PARITY_GAP_REVIEW_2026-11-27.md`, commit `05ab1df2295269b78878bc1bda9e0de4593762a2`.
- [x] Identified material semantic gaps that prohibit copying the prototype into a migration: production uses separate USDT wallet and base-asset ledger; fee helper + 8-decimal rounding; one-minute receive-time freshness; 25%-of-original Limit partial fills; consumed/released reservation ledger; global advisory lock + SKIP LOCKED + wallet-first lock order; active-account and auth.uid() guards; transaction ledger writes. Prototype uses a unified balance table, hardcoded fee, 2-minute observed-time freshness, one-shot fills, and deletes simplified reservations.
- [!] Existing canonical prototype proves duplicate ticker isolation only in a simplified model. It is not authoritative Market/Limit parity and must not be used as a financial migration.
- [ ] Next: create a canonical Market/Limit candidate that retains the authoritative source semantics while replacing ticker identity with pair_id/base_asset_id/quote_asset_id. Apply only after exact authoritative migration in disposable PG17 and test same-ticker pair A/B, four partial fills, exact reserve consumption/release, stale/missing/future prices, disabled pair, inactive account, auth, and two-session races.
- [x] CI #2391 / run `46048133466` completed SUCCESS on pre-review head `a411a73df6a47dc77b4b83950b59b6a19ee22b95`; step 28 authoritative Market/Limit migration baseline passed.
- [x] PR #67 remains open Draft and unmerged; branch head now advances with documentation commits; no Production writes, migration/db push, history repair, merge, deploy, APK/Pages publication, or cost.


## Shahram 186 — canonical ledger source recovery gate (2026-11-27)

- [x] Rechecked current PR #67 and latest CI; PR remains open Draft, unmerged, mergeable. CI run `46048469045` for prior documentation head completed SUCCESS.
- [x] Cross-checked the Market/Limit migration bodies against the disposable schema fixture, existing source recovery plan, and 2026-11-26 Production function snapshots.
- [x] Added `docs/CANONICAL_TRADING_LEDGER_SOURCE_RECOVERY_GATE_2026-11-27.md`, commit `1f4fcf9d25622fdca4fd74ba608ba2c3921876b2`.
- [!] Clarification to Shahram 184: CI step 28 genuinely applies and executes the exact three checked-in Market/Limit function bodies, but its minimal bootstrap is not a full authoritative Production schema/helper/trigger/RLS/grant reconstruction. Treat it as exact-function-body regression against a compatible disposable scaffold, not complete Production-schema parity.
- [!] The current production financial key `asset_balances(user_id, asset text)` and `order_reservations.asset text` cannot isolate same-ticker canonical assets. A pair_id-only patch to orders/prices would be incomplete; balance, reservation, trades, conditional lifecycle, cancellation, deactivation, readers and ingestion need coordinated identity propagation.
- [!] Fee helper source is not fully recovered by the fixture: the test bootstrap uses a constant 0.1% implementation. Do not claim authoritative fee-helper parity until the exact live helper/source and metadata are recovered.
- [!] Existing Market/Limit code enforces `market_prices.updated_at` within one minute. Keep this local receive/update-time execution gate explicit; provider-observed time is a separate field and cannot be substituted without a defined contract.
- [ ] Next: recover exact source for base financial schema, active-account helper/guard trigger, fee helper, relevant policies/grants and all ticker-based dependent functions; reconcile ambiguous legacy asset balances before implementing canonical ledger changes.
- [x] No Production query/write, migration, function, grant, RLS, trigger, cron, worker, account or financial-row change; no db push, merge, deploy, APK/Pages publication or cost.


## Shahram 187 — authoritative fee and active-account helpers added to Market/Limit harness (2026-11-27)

- [x] Rechecked live PR #67: open, Draft, unmerged; latest branch head before this step was `ba06f93519ad097a193d38b571b57d584b48eb47`, 196 commits ahead and 0 behind main.
- [x] CI run `46049038024` / workflow #2396 completed SUCCESS on the pre-helper-snapshot head `ba06f93519ad097a193d38b571b57d584b48eb47`.
- [x] Confirmed fresh read-only Production snapshots now exist for `get_demo_trading_fee_rate(text,text)` and `current_account_is_active()`, including SECURITY DEFINER/search_path/owner/EXECUTE metadata. Fee helper reads enabled maker/taker rates from `demo_trading_fees`; it rejects invalid liquidity types and missing/disabled quote-asset configuration.
- [x] Improved the disposable authoritative Market/Limit harness: removed its hardcoded constant fee helper and simplified active-account helper; added a fee table/configuration fixture and now loads the exact captured Production function bodies before applying the authoritative Market/Limit migration.
- [x] Added regression assertions for configured maker/taker fee lookup, missing quote configuration rejection, and disabled fee configuration rejection. Market/Limit financial functions remain the exact checked-in migration bodies.
- [x] Corrected and verified shell continuations in the CI workflow SQL command after the first edit; all five SQL files now execute in one psql invocation in the intended order.
- [!] Latest commit `f7a8ae868623c10955595003b42accc48553b552` has not yet returned a new CI run at checkpoint time. Do not claim the helper-snapshot harness passed until its new run completes.
- [!] This adds exact helper function bodies, not the complete authoritative table schema, fee table constraints/data, trigger/RLS/grants or full Production catalog parity. Historical/live metadata snapshots still require a separately captured, reconciled schema and ACL inventory.
- [ ] Next: confirm CI for `f7a8ae868623c10955595003b42accc48553b552`; then recover authoritative base ledger DDL/constraints/indexes and reservation/financial table metadata, and test actual helper behavior with source-faithful schema.
- [x] No Production database query/write in this step; no Production migration, schema/function/ACL/RLS/trigger/Cron/worker/Auth change; no db push, merge, deploy, APK/Pages publication or cost.


## Shahram 188 — direct helper assertions expanded (2026-11-27)

- [x] Rechecked live PR #67: open, Draft, unmerged; HEAD at start of this step `762dd36db1a23ec18314287a844e0b2f91c42785`; 201 commits ahead / 0 behind main. The transient `mergeable=false` from the prior check has since returned to `mergeable=true` before this step.
- [x] CI run #2400 / `46049313969` was in progress on the prior HEAD. At the latest poll, 16/31 steps had completed, with two-session Limit worker/cancel race tests running; no failed steps reported. This run does NOT include the subsequent helper assertion commit.
- [x] Expanded the disposable Market/Limit parity test to directly assert captured Production `current_account_is_active()` returns true for an active authenticated profile and false for an inactive one.
- [x] Added direct rejection assertion for unsupported fee liquidity type `provider`, alongside existing maker/taker, missing quote configuration and disabled configuration checks.
- [x] Commit: `95da33ca8d5c793562125ea9733e34edce623747`. The next CI run must validate this latest test revision.
- [!] Still not full Production schema parity: fixture tables, indexes, constraints, triggers, RLS and grants remain partially scaffolded; exact function-body snapshots are not equivalent to a complete source-of-truth schema capture.
- [ ] Next: poll CI #2400; then run the new commit's CI; continue recovery of base ledger DDL and all constraints/indexes/trigger/RLS/grants from a permitted metadata-only source before canonical financial migration design.
- [x] No Production database read/write performed in this step; no Production migration, schema/function/ACL/RLS/trigger/Cron/worker/Auth change; no db push, merge, deploy, APK/Pages publication or cost.


## Shahram 189 — schema recovery evidence gate clarified (2026-11-27)

- [x] Rechecked live PR #67: open, Draft, unmerged; latest head before this documentation step `8c9127307ee55ce852a313ba694af79c23ccbd85`. PR is now reported mergeable=true; no merge was attempted.
- [x] CI #2400 / run `46049313969` completed SUCCESS: all 28 substantive steps passed, including authoritative checked-in Market/Limit migration function bodies on disposable PostgreSQL, conditional/Stop-Limit migration lifecycle, duplicate-ticker canonical fixture, scheduler exercise, and schema fingerprint SQL.
- [x] CI #2401 / run `46049463567` completed SUCCESS: the new direct assertions for captured Production fee and active-account helpers passed.
- [x] CI #2402 / run `46049488286` completed SUCCESS on the status-update head `8c912730...`; all 28 substantive steps passed.
- [x] Re-examined the exact-decimal disposable fixture and Market/Limit migration source. Confirmed fixture table definitions are partial scaffolding, not authoritative base DDL. Current Market/Limit bodies still use ticker-keyed `asset_balances.asset`, `order_reservations.asset`, pair_symbol and market_prices.symbol.
- [x] Recovered the precise limitation in the 2026-11-21 Recovery-Test record: metadata snapshot had 32 tables / 239 columns / 116 constraints / 63 indexes / 5 non-system triggers / 21 policies, but Production read-only queries timed out; restore used `--no-owner --no-acl`, so its ACL evidence is not Production grant evidence. Recovery-Test also contains backup data and is not an approved financial test harness.
- [x] Added `docs/TRADING_LEDGER_SCHEMA_RECOVERY_EVIDENCE_2026-11-27.md`, commit `c8356964267cc2639177159eb22b46c4207b40f1`, documenting exact evidence, limits, canonical-identity consequences, and the next metadata-only recovery gate.
- [!] No authoritative base-table creation DDL for the financial ledger was recovered in the bounded current-source search; this is not proof it does not exist in full Git history or Production. Do not infer it from test fixtures.
- [ ] Next: obtain an authorized metadata-only Production fingerprint for financial tables, constraints/indexes/triggers/RLS/policies/grants and relevant helper ACLs; compare with Recovery-Test/source evidence. No business/user rows. Reconcile migration ledger separately before any deployable canonical migration.
- [x] No Production SQL/query/write in this step; no Production migration, schema/function/ACL/RLS/trigger/Cron/worker/Auth change; no db push, merge, deploy, APK/Pages publication or cost.


## Shahram 190 — historical ledger evidence recovered; CI 2404 green (2026-11-27)

- [x] Rechecked PR #67 and branch: open, Draft, unmerged, mergeable=true; 205 commits ahead / 0 behind main at the start of this step. No merge/rebase attempted.
- [x] CI run #2404 / `46049917020` completed SUCCESS on the then-current head `a7f4a8268c4e15617f974fdadb1b8d17c13d72c2`; all 28 substantive steps passed, including fair scheduler candidate, authoritative TP/SL and Stop-Limit migrations, duplicate-ticker canonical isolation, schema fingerprint, and authoritative Market/Limit migration on disposable PostgreSQL 17.
- [x] Expanded the schema recovery search across historical repository audit records. `docs/STOP_LIMIT_QA_MATRIX.md` and `docs/superpowers/reports/2026-11-15-exact-decimal-backend-rpc-review.md` preserve dated, read-only Production observations from 2026-11-15: historical typmods, accounting checks, FK relationships, index coverage summary, account-guard trigger placement, and RLS scope.
- [x] Added those historical observations and explicit age/source limitations to `docs/TRADING_LEDGER_SCHEMA_RECOVERY_EVIDENCE_2026-11-27.md`, commit `d717d6fd4724147ab58caccaeebe4d1cf0a3d494`.
- [!] The newly recovered material is human-authored historical audit evidence, not raw catalog DDL/export. It does not prove current Production state, provide every exact constraint/index/policy expression, or supply full defaults/nullability/ACLs. The 2026-11-21 Recovery-Test snapshot remains unverified against Production; ACL evidence there remains unusable because restore omitted owner/ACL.
- [ ] Next: continue searching version history/source records for authoritative base CREATE TABLE migrations and exact schema export; if unavailable, keep the metadata-only Production fingerprint as a hard blocker. No business/user rows. Reconcile migration ledger separately.
- [x] No Production SQL/query/write in this step; no Production migration, schema/function/ACL/RLS/trigger/Cron/worker/Auth change; no db push, merge, deploy, APK/Pages publication or cost.


## Shahram 191 — follow-up: latest CI verified; authoritative ledger DDL search remains blocked (2026-11-27)

- [x] Rechecked live PR #67: open, Draft, unmerged, mergeable=true; HEAD `f53bb310b4002046fbcf79bb640f18a1f3abedef`; 207 commits ahead / 0 behind main. No merge/rebase attempted.
- [x] CI run #2406 / `46050279429` completed SUCCESS on the exact current HEAD. All 28 substantive steps passed, including exact-decimal/browser integration, disposable PostgreSQL arithmetic and widening rehearsals, Market/Limit entrypoints, real two-session cancellation/worker races, TP/SL and Stop-Limit lifecycle tests, fair scheduler candidate, authoritative TP/SL and Stop-Limit migrations, duplicate-ticker canonical isolation, schema fingerprint, and authoritative Market/Limit migration.
- [x] Inspected the latest CI job step report directly; all 28 substantive steps and setup/teardown steps report success.
- [x] Re-read the current ledger recovery evidence, source-recovery gate, and canonical dependency manifest. They consistently distinguish exact checked-in function-body tests from complete Production schema parity; no fixture was promoted to authoritative base DDL.
- [!] A further bounded GitHub commit search for exact base-table DDL terms (`CREATE TABLE asset_balances`, `CREATE TABLE order_reservations`, wallets/transactions, and ledger schema migration) returned no matching commits. GitHub commit search is not an exhaustive Git-history or database search; this does not prove that the DDL is absent.
- [!] The current hard blocker remains: no authoritative base CREATE TABLE source or complete current Production metadata export for financial table defaults/nullability, exact constraints/indexes/triggers/RLS/policies/grants, and current migration ledger has been recovered. Historical 2026-11-15 audit summaries and the 2026-11-21 Recovery-Test snapshot are not substitutes.
- [ ] Next: pursue a source-of-truth metadata-only export through an explicitly permitted route, limited to schema/catalog metadata (no business/user rows); compare it with historical audit evidence and reconcile the migration ledger independently. If that source is unavailable, document the blocker and keep canonical financial migration design non-deployable. Do not infer DDL from disposable fixtures.
- [x] No Production SQL/query/write was performed in this step; no Production migration, schema/function/ACL/RLS/trigger/Cron/worker/Auth change; no db push, merge, deploy, APK/Pages publication or cost.


## Shahram 192 — current Production ledger fingerprint and migration reconciliation recovered (2026-11-27)

- [x] Rechecked project health: Supabase Production `gfoaubfilhttnwjykaox` reports ACTIVE_HEALTHY on PostgreSQL 17.11.0.018. Rechecked PR #67 before work: open, Draft, unmerged, mergeable; latest head before this documentation step `49912a6599c54659dd798848afc1e22f5705cd4c`.
- [x] Used only Supabase metadata interfaces and read-only catalog queries against `pg_catalog`, `information_schema`, `pg_policies`, `pg_indexes`, `pg_proc`, `pg_trigger`, `pg_constraint`, `cron.job`, and privilege predicates. No business/user row contents were selected; no Production state was changed.
- [x] Captured current metadata for 12 target public tables: 100 columns, 65 constraints, 30 indexes, 3 non-system triggers and 12 policies. RLS is enabled on all 12; FORCE RLS on none. Exact column typmods/defaults/nullability and the full scoped constraint/index/trigger/policy definitions are recorded in `docs/TRADING_LEDGER_SCHEMA_RECOVERY_EVIDENCE_2026-11-27.md`.
- [x] Confirmed current canonical-identity blocker directly from Production: asset_balances.asset and order_reservations.asset remain text; orders.symbol, trades.symbol, conditional_orders.symbol and market_prices.symbol are also ticker text/keys. asset_balances unique(user_id,asset); order_reservations unique(order_id); demo_trading_pairs keyed by pair_symbol with unique base_coingecko_id. A coordinated ID migration remains mandatory.
- [x] Captured live accounting constraints: orders filled+remaining=amount and range checks; asset balance nonnegative; reservation consumed+released <= reserved and released <= reserved; positive trade amount/price; nonnegative wallet balances. Captured 3 active account guard triggers on orders/trades/transactions, with none on asset_balances/order_reservations.
- [x] Captured scoped RLS/grants and function ACLs. Authenticated direct table privileges are read-only for the user-facing ledger; reservation table access is service_role-only; relevant placement/cancel/helper SECURITY DEFINER RPCs are authenticated-executable and not anon-executable; process_limit_orders/process_conditional_orders/process_stop_limit_orders are service_role-only. All reviewed functions are postgres-owned with empty search_path.
- [x] Captured active cron metadata without altering it: job 3 market refresh, job 8 Limit worker, job 9 conditional worker and job 12 Stop-Limit worker run every minute; job 17 price overflow every 10 minutes. All five were active. No schedule change.
- [x] Reconciled the current Production migration ledger against migration filenames on both main and this PR branch: 55 applied ledger entries vs 40 local SQL files; 18 exact version/name matches, 20 same-name timestamp mismatches, 17 applied migrations with no matching local source filename, and 2 local-only migrations (KuCoin and Gate.io price refresh). The exact mapping and all missing/local-only names are recorded in the evidence document. This reproduces the 17/20/2 discrepancy from prior audits.
- [!] Current Production `wallets.balance_irr` is numeric(24,0) DEFAULT 1,000,000,000. This differs from the currently approved 50,000,000 Toman product starting balance; unit semantics and wallet initialization path need a separate accounting/product audit. No correction was made.
- [!] This is a current catalog fingerprint, not original migration DDL/history. The 17 missing applied migration bodies and 20 timestamp variants remain unresolved; do not infer/replay/repair migration history from catalog state. External writer/source parity and OCO remain open.
- [ ] Next: recover missing applied SQL bodies from trusted historical Git objects/backups, inspect the 20 timestamp variants individually, inventory all external writers/readers/Edge Functions against this catalog, then extend the disposable source-parity harness. Only then draft coordinated canonical-ID migration for review.
- [x] No Production writes, business-row reads, migration replay/repair, schema/function/ACL/RLS/trigger/Cron/worker/Auth change, db push, merge, deploy, APK/Pages publication or cost.


### Shahram 192 addendum — cron scope corrected; catalog auto-activation writer audited (2026-11-27)

- [x] CI run #2409 / `46051536464` completed SUCCESS on status/documentation head `fbfe52ee39b7371ed3026486d5b64ba314378cc2`; the main exact-decimal job completed with success. This is the docs/status checkpoint CI, not a new canonical migration test.
- [x] Re-read `supabase/MIGRATION_RECONCILIATION.md` and the live `private.auto_activate_verified_exchange_pairs()` snapshot. The snapshot is source evidence only, not executable migration SQL. The function remains ticker-keyed, joins `market_prices.symbol`, constructs `pair_symbol` from ticker, and still enforces volume >= $1M, market-cap rank <= 2000, freshness and unique active ticker. It is not callable by anon/authenticated/service_role; scheduled execution is through its cron job.
- [x] Corrected the earlier incomplete cron summary by querying the full relevant name set. 11 active jobs were found: IDs 3,4,5,8,9,11,12,13,14,17,18. Job 14 is currently `1,31 * * * *` (twice hourly), and job 18 auto-activates verified pairs at `9-59/10 * * * *`. The exact full inventory is in the ledger evidence document. Order workers 8/9/12 remain every minute and were not changed.
- [!] The current auto-activation writer's fixed volume/rank gates conflict with the approved no-fixed-rank/no-fixed-volume-cap catalog objective; canonical identity and fresh verified price/mapping safeguards must remain. This is a source/design finding only; no function or cron changes.
- [x] Bounded historical branch sweep across eight relevant branches found no exact SQL filenames for the sampled missing migrations. This is not exhaustive proof of absence across all Git objects, backups or deployment artifacts.
- [!] Confirmed local-only KuCoin/Gate.io migration files are documented as older `refresh_market_prices()` replacements that omit the later 515-ID CoinGecko cap; do not apply or push them as-is.
- [x] Evidence and status docs updated only. No Production writes, business-row reads, migration replay/repair, function/ACL/RLS/trigger/Cron/worker/Auth change, db push, merge, deploy, APK/Pages publication or cost.
- [ ] Next: recover missing applied SQL bodies and trusted deployment artifacts; inspect timestamp variants and reconcile the live/local price-refresh implementation; then extend source-parity coverage for catalog auto-activation and every external writer. Keep PR #67 Draft and non-deployable.


### Shahram 192 follow-up — missing migration source sweep and CI 2411 verified (2026-11-27)

- [x] Rechecked live PR #67: open, Draft, unmerged, mergeable=true; current HEAD before this documentation commit was `e0e810102d7410bacfc7e03ccf029daf8bffad48`.
- [x] CI run #2411 / `46051903125` completed SUCCESS on that exact HEAD. All 28 substantive steps passed, including authoritative TP/SL and Stop-Limit migration harness, authoritative Market/Limit migration harness, exact-decimal and concurrency checks, duplicate-ticker canonical isolation, and schema fingerprint.
- [x] Performed another bounded recovery attempt for the 17 missing applied migration SQL sources: GitHub code search for four representative names returned only `supabase/MIGRATION_RECONCILIATION.md`; recursive trees of eight relevant historical branches contained none of the sampled exact missing filenames. This is not exhaustive proof of absence across all Git objects, backups, deployment artifacts or other branches.
- [x] Updated `docs/TRADING_LEDGER_SCHEMA_RECOVERY_EVIDENCE_2026-11-27.md` with the branch/code-search scope, exact CI run and remaining source-of-truth boundary.
- [!] The 17 applied migrations with no matching local SQL source and 20 same-name timestamp mismatches remain unresolved. Do not reconstruct their SQL from names, live catalog state or neighboring migration bodies. Do not repair migration history or run db push.
- [ ] Next: recover missing SQL bodies from a trusted deployment artifact/backup or historical Git object; inspect all 20 timestamp variants against authoritative deployment records; reconcile live/local price-refresh and catalog auto-activation writer source; extend disposable source-parity harness. Keep PR #67 Draft and non-deployable.
- [x] No Production writes, business-row reads, migration replay/repair, function/ACL/RLS/trigger/Cron/worker/Auth change, db push, merge, deploy, APK/Pages publication or cost.


## Shahram 193 — CI 2413 green; all 20 timestamp variants inspected (2026-11-27)

- [x] Rechecked PR #67: open, Draft, unmerged, mergeable=true; HEAD `43766d7c205dd5e934a185f34acfd59719897e79`.
- [x] CI #2413 / run `46052212399` succeeded on the exact current HEAD. The `exact-decimal` job passed all 28 substantive steps, including authoritative TP/SL/Stop-Limit and Market/Limit migration harnesses on disposable PostgreSQL 17, race/concurrency tests, canonical duplicate-ticker isolation and schema fingerprint.
- [x] Checked workflow artifact inventories for runs #2411, #2406 and #2413; none published artifacts that could serve as migration-source backups.
- [x] Individually inspected all 20 local SQL files corresponding by name to Production timestamp-mismatch entries. Categorized the conditional reservation worker/index, stale CoinGecko recovery, curated listing/pair activation/admin controls, market price parser/refresh/display, Kifpool exchange-sync/matcher alias revisions, and cron scheduling migration. This verifies local candidate contents only, not deployed-source identity.
- [!] Material discrepancy: local `20261117130000_stagger_market_price_overflow_and_refresh_exchange_discovery.sql` changes cron job 14 to every minute, while the latest metadata-only Production capture records job 14 as `1,31 * * * *`. Do not replay this local migration based on its name or timestamp.
- [!] Local pair-activation SQL still enforces volume >= $1M and rank <= 2000 and uses ticker-keyed pair/price/order paths. This conflicts with approved no-fixed-volume/rank catalog scope and canonical identity; redesign is required, not replay.
- [!] Four exact GitHub commit searches for representative missing applied migration names returned no commits. This is bounded evidence only; 17 missing SQL sources and all 20 deployment timestamp mappings remain unresolved.
- [ ] Next: obtain exact applied SQL/checksum evidence from a trusted deployment artifact or backup. If unavailable, preserve the unresolved blocker; continue source-parity inventory for catalog/market writers. No inferred SQL.
- [x] No Production writes/queries in this step; no migration replay/repair, db push, merge, deployment, Cron/worker/ACL/RLS change, APK/Pages publication or cost.



## شهرام ۱۹۹ — انتقال کنترل‌شدهٔ QA Stop-Limit از Main به شاخهٔ کاتالوگ — ۲۸ نوامبر ۲۰۲۶

### وضعیت زنده پیش از این اقدام
- [x] مخزن `shahram-adim/DigiArz` بررسی شد؛ PR #67 با عنوان `[Draft] Make every DigiArz catalog asset demo-tradable` باز، Draft و ادغام‌نشده است.
- [x] HEAD شاخه در شروع این نوبت `8f7925ced4c18716ee07e11890fd9572c4fcacf4` بود؛ Main برابر `e8477b53a1b8c6fc7225572db3e559a1c75607d8` بود. مقایسهٔ زنده: شاخه ۲۱۶ کامیت جلو و ۸ کامیت عقب از Main؛ وضعیت diverged و mergeable=false.
- [x] CI run `46052800147` روی HEAD قبلی PR با نتیجهٔ success پایان یافته بود؛ این CI فقط شواهد همان HEAD است و تغییرات این checkpoint را پوشش نمی‌دهد.

### تغییرات Main که بررسی و به‌شکل محدود منتقل شدند
- [x] آزمون `tests/stop-limit-worker-source-parity.test.js` از Main به شاخه منتقل شد. این آزمون بازسازی تابع Stop-Limit را از Migration پایه `20261113181827` به‌علاوه patch دقیق `v_old/v_new` در Migration `20261115143827` با snapshot خواندنی تابع Production مقایسه می‌کند.
- [x] پیش‌شرط انتقال بررسی شد: چهار فایل authoritative موردنیاز (دو Migration، snapshot تابع Production و آزمون retry exhaustion) در Main و شاخه blob SHA یکسان داشتند.
- [x] بخش مستند «Applied Stop-Limit migration-chain source parity — 2026-11-28» به انتهای `docs/STOP_LIMIT_QA_MATRIX.md` شاخه افزوده شد؛ شامل نتیجهٔ CI run #2419 / `46139853183` با success و محدودیت آن به PostgreSQL 17 دورریختنی GitHub Actions.
- [x] فایل `IMPLEMENTATION_STATUS.md` شاخه مستقل باقی ماند؛ نسخهٔ Main جایگزین نشد، زیرا تاریخچه و محتوای این دو فایل به‌طور اساسی واگراست و جایگزینی کامل باعث حذف وضعیت تفصیلی شاخه می‌شد.

### موانع قطعی که همچنان باز هستند
- [!] PR هنوز با Main واگراست؛ ادغام Main یا rebase انجام نشد.
- [!] ۱۷ Migration اعمال‌شدهٔ Production بدون فایل SQL منطبق در مخزن و ۲۰ اختلاف timestamp/name همچنان نیازمند مدرک deployment معتبر هستند؛ از نام فایل یا وضعیت catalog برای بازسازی SQL استفاده نشود.
- [!] شواهد schema fingerprint ثبت‌شده در مرحلهٔ ۱۹۲ شامل metadata فعلی ۱۲ جدول مالی/معاملاتی است، اما جایگزین متن authoritative همهٔ DDLهای پایه و زنجیرهٔ دقیق Migration نیست.
- [!] CI #2419 سبز است، اما محیط disposable PostgreSQL 17 معادل Supabase Development Branch با schema/ACL parity کامل نیست؛ Development Branch در آخرین بررسی ثبت‌شده خالی بود.
- [!] تفاوت قفل child-row در تابع زنده/زنجیرهٔ اعمال‌شده (`FOR UPDATE OF c,parent SKIP LOCKED`) با candidate (`FOR UPDATE OF c,parent,child SKIP LOCKED`) بازبینی مستقل می‌خواهد.

### اقدام بعدی
1. اجرای workflow Exact-decimal برای HEAD جدید PR و بررسی نتیجهٔ نهایی همهٔ مراحل؛ تا دریافت نتیجه، آزمون تازه را موفق اعلام نکن.
2. بازبینی diff و CI پس از انتقال تست؛ سپس ادامهٔ بازیابی مدرک Migrationهای مفقود و بررسی ۲۰ اختلاف نسخه.
3. حفظ PR در حالت Draft؛ هیچ merge، rebase، db push یا تغییر Production بدون تأیید صریح مالک.

### ایمنی
- [x] فقط دو فایل آزمون/مستندات ویرایش‌شده در شاخهٔ GitHub تغییر کردند؛ هیچ Migration اجرایی، تابع، schema یا دادهٔ Production تغییر نکرد.
- [x] هیچ RPC/Worker/Cron مالی اجرا نشد؛ هیچ سفارش، معامله، رزرو، کیف پول یا موجودی خوانده یا تغییر داده نشد.
- [x] هیچ Merge، rebase، انتشار APK/Pages، استقرار Edge Function، هزینه یا تغییر Supabase انجام نشد.



## شهرام ۲۰۰ — ممیزی منبع Migration و وضعیت CI شاخه — ۲۸ نوامبر ۲۰۲۶

### وضعیت GitHub پیش از ثبت این checkpoint
- [x] PR #67 با عنوان `[Draft] Make every DigiArz catalog asset demo-tradable` باز و Draft است؛ base شاخه `main)، head شاخه `plan/all-catalog-assets-tradable-2026-11-27`.
- [x] HEAD شاخه پیش از این ثبت وضعیت: `b8a49fef4b98c03eeabf4170fe4f874c904efa9a`.
- [x] آخرین Main مشاهده‌شده: `e8477b53a1b8c6fc7225572db3e559a1c75607d8`.
- [x] مقایسهٔ شاخه با Main پیش از آخرین مستندات: ۲۱۹ کامیت جلو و ۸ کامیت عقب؛ وضعیت diverged و PR mergeable_state برابر dirty بود. پس از مستندات جدید باید شمارش مجدداً تأیید شود.
- [!] برای HEAD جدید Check Runs خالی و combined status برابر pending بود؛ هیچ اجرای CI جدیدی برای HEAD جدید مشاهده نشد. اجرای موفق #2419 روی Main و #46052800147 روی HEAD قدیمی‌تر، اعتبارسنجی HEAD فعلی محسوب نمی‌شود.
- [!] workflow فعلی `.github/workflows/exact-decimal-tests.yml` روی push به main و pull_request به main تنظیم شده است؛ علت عدم مشاهدهٔ run برای commitهای اخیر از این بررسی اثبات نشد. GitHub Actions workflow-dispatch در ابزارهای متصل این نشست در دسترس نبود؛ موفقیت تست جدید را ادعا نکن.

### نتیجهٔ بازیابی منبع ۱۷ Migration
- [x] جست‌وجوی exact-name در تاریخچهٔ commit مخزن برای هر ۱۷ نام Migration مفقود انجام شد.
- [x] دو نتیجهٔ مثبت کاذب بازبینی شدند: commit مربوط به `secure_admin_wallet_management` فقط تغییر CSS در `index.html` دارد؛ نتیجهٔ `admin_exchange_asset_sync_monitoring` فقط تغییر markup رابط سفارش/مدیریت در `index.html` دارد. هیچ‌کدام SQL Migration نیستند.
- [!] در این دور هیچ SQL authoritative بازیابی نشد. آمار آخرین ledger audit ثبت‌شده همچنان ۱۷ منبع مفقود، ۲۰ اختلاف timestamp/name و دو فایل local-only ثبت‌نشده است؛ در این دور GitHub-only، ledger زندهٔ Supabase دوباره خوانده نشد.
- [!] منبع Migration از روی نام، تابع زنده یا رفتار حدس زده نشود؛ migration history دست‌کاری و `supabase db push` اجرا نشود.

### Commitهای مستنداتی این مرحله
- [x] `0f16f50ada0810a8a049e2792977d073cbcfb209` — افزودن تست تطبیق زنجیرهٔ Stop-Limit با snapshot تابع Production.
- [x] `8b1322509d7f0f5442c46e9973e0a0e774a99ab5` — انتقال گزارش QA و CI قبلی.
- [x] `02d23dc3722e5371a69516ee454e243f2cc7c9d7` — ثبت checkpoint شهرام ۱۹۹.
- [x] `b8a49fef4b98c03eeabf4170fe4f874c904efa9a` — ثبت دور جدید بازیابی منبع Migration در `supabase/MIGRATION_RECONCILIATION.md`.

### اقدام بعدی
1. تأیید HEAD نهایی و شمارش دقیق ahead/behind پس از این مستندات.
2. تعیین مسیر معتبر برای اجرای CI روی HEAD جدید؛ تا آن زمان status pending باقی بماند.
3. جست‌وجوی منبع معتبر خارج از تاریخچهٔ commit در deployment artifact/backup یا آرشیو مالک برای ۱۷ Migration.
4. پس از تثبیت CI و منابع، بازبینی conflictهای PR و تهیهٔ برنامهٔ هماهنگ‌سازی با Main؛ بدون merge/rebase خودکار.

### ایمنی و عدم اقدام
- [x] تغییرات این checkpoint مستندات و تست repository-only در شاخهٔ PR هستند.
- [x] هیچ Migration اجرایی، schema، تابع، دادهٔ مالی، ACL، RLS، trigger، cron، worker یا Edge Function در Supabase تغییر نکرد.
- [x] هیچ RPC/worker مالی اجرا نشد؛ jobهای Limit/TP-SL/Stop-Limit دست‌نخورده‌اند.
- [x] هیچ merge، rebase، db push، deploy، انتشار APK/Pages یا هزینه‌ای انجام نشد.



## Shahram 201 — PR ancestry and CI trigger diagnosis — 2026-11-28

### Main-behind analysis (read-only)
- [x] The PR base SHA recorded by GitHub is `fbfb5e974e754088a32c9fdcd76fc2ca9ab0f98b`; current Main is `e8477b53a1b8c6fc7225572db3e559a1c75607d8`.
- [x] Comparing that recorded PR base to current Main shows 8 commits ahead on Main and exactly three changed paths: `tests/stop-limit-worker-source-parity.test.js`, `docs/STOP_LIMIT_QA_MATRIX.md`, and `IMPLEMENTATION_STATUS.md`.
- [x] Current Main and PR branch blob SHAs are identical for the first two paths (test and Stop-Limit QA doc). Their content was selectively carried forward to the PR branch; no additional code/doc delta remains in those two files.
- [!] `IMPLEMENTATION_STATUS.md` intentionally differs: PR branch retains its longer project-specific history and adds Shahram 199/200 records. Do not replace it with Main's shorter status file.
- [!] The 8-commit behind count is therefore still a commit-graph/ancestry divergence even though the two non-status file contents are identical. No merge-base update, merge, rebase, cherry-pick, or force push was performed. PR #67 remains diverged and GitHub reports it non-mergeable/dirty.
- [x] The current PR contains 58 changed files, 7,704 additions and 1 deletion; its full scope remains much broader than the three paths changed on Main since the recorded base.

### CI trigger diagnosis
- [x] The branch workflow file has only `push: branches: [main]` and `pull_request: branches: [main]`; the PR targets `main`, so the declared pull_request filter itself is consistent.
- [x] The connected GitHub actions available in this session expose workflow-run inspection and rerun of failed jobs, but no `workflow_dispatch`/create-run action. The latest PR HEAD has no check runs and pending combined status.
- [!] It is not possible to start a new workflow run for the current HEAD through the available action surface. The exact cause of missing synchronize runs is unproven; token-origin suppression is a possible GitHub behavior only if the write used `GITHUB_TOKEN`, but that token type was not established. Do not claim this as confirmed root cause.
- [ ] Next CI path: use a repository-authorized GitHub UI/API actor that can trigger a fresh run for the exact PR HEAD, or establish a verified dispatch path. The run must report SHA `8a9f53db46a2717509f1f8954bfb4d22dd1104a0` or a newer explicitly verified HEAD. Do not use an unrelated older successful run as substitute.

### Next engineering sequence
1. Keep PR #67 Draft; resolve ancestry/dirty state only through a reviewed integration plan, not blind merge/rebase.
2. Preserve the current source-parity test and QA doc (their Main blobs are already identical).
3. Continue canonical Market/Limit candidate work by reconciling its behavior with the authoritative Market/Limit migration: wallet/base ledgers, fee helper and 8-decimal rounding, one-minute execution freshness, 25%-of-original partial fills, consumed/released reservation history, advisory lock/row-lock order, active-account guard, orders/trades/transactions writes. The current generic-balance fixture is explicitly not a faithful replacement.
4. Keep full Production schema/helper/trigger/RLS/ACL source recovery and migration-ledger reconciliation as separate hard gates.
5. Do not run migrations, db push, financial workers/RPCs, merge, deploy, or alter Production without explicit owner approval.

### Safety
- [x] This checkpoint records repository metadata and file-content comparisons only. No database or financial operation was performed.


## شهرام ۲۰۲ — قرارداد مالی Market/Limit و آزمون محافظ منبع — ۲۸ نوامبر ۲۰۲۶

### نتیجهٔ بازبینی منبع
- [x] Migration مرجع `20261113161641_enforce_active_accounts_in_demo_trade_and_limit_engine.sql` مجدداً بررسی شد.
- [x] مرز دقت عددی دقیق شد: تابع Market صراحتاً gross و fee را با `round(...,8)` گرد می‌کند؛ تابع worker مربوط به Limit در همین Migration چنین `round(...,8)` صریحی ندارد و gross/fee را مستقیم محاسبه می‌کند. نباید رفتار Market را به Limit تعمیم داد.
- [x] رفتار Limit از منبع استخراج شد: advisory lock `739201126`، `FOR UPDATE SKIP LOCKED)، فیلتر پروفایل فعال، قیمت حداکثر یک‌دقیقه‌ای، هر چرخه حداکثر ۲۵٪ مقدار اولیه، maker fee helper، reservation با consumed/released/status، و درج trade و transaction به‌ازای هر fill.
- [x] اختلاف‌های candidate canonical تأیید شد: generic balances به‌جای wallets + asset_balances، fee ثابت 0.001، freshness دو دقیقه و ۳۰ ثانیه آینده، پرکردن کل مقدار باقی‌مانده در یک چرخه و حذف reservation. این candidate همچنان فقط اثبات هویت pair/asset است و parity مالی نیست.

### فایل‌های افزوده‌شده
- [x] `tests/canonical-market-limit-financial-contract.test.js` — تست ایستای Node برای pin کردن قراردادهای منبع Market/Limit و جلوگیری از معرفی اشتباه candidate به‌عنوان parity مالی.
- [x] `docs/CANONICAL_MARKET_LIMIT_FINANCIAL_CONTRACT_2026-11-28.md` — سند قرارداد دقیق، اختلاف‌ها، مراحل پیاده‌سازی و release gates.

### وضعیت اعتبارسنجی
- [!] تست Node تازه به مخزن اضافه شد اما در این نشست اجرا نشده است؛ اجرای CI جدید برای HEAD فعلی در دسترس نبود. نتیجهٔ تست را pending نگه دارید تا CI روی SHA دقیق اجرا شود.
- [!] تست ایستا جایگزین اجرای Migration واقعی در PostgreSQL 17، آزمون دو جفت با ticker یکسان، آزمون تراکنش/رزرو و race دو نشست نیست.
- [!] Migrationهای مفقود و موانع schema/ACL/RLS/trigger parity همچنان hard gate هستند.

### Commitهای این گام
- `9e0892b4ed905ee9f5fe00115481c7abc08917e4` — افزودن تست قرارداد منبع.
- `f11cc5d006e8e07b66447ff9d28940fc5fcbb5f8` — اصلاح assertion تست برای رفتار full-fill candidate.
- `61d07dd0852e5ab6bc1190fd239909bd02345a66` — افزودن قرارداد مالی Market/Limit.

### ایمنی
- [x] فقط فایل تست و مستندات در شاخهٔ Draft PR تغییر کردند.
- [x] هیچ Migration اجرایی یا تغییر Supabase/Production انجام نشد.
- [x] هیچ RPC/Worker/Cron مالی اجرا نشد؛ jobهای موجود بدون تغییر ماندند.
- [x] Merge، rebase، deploy، انتشار APK/Pages یا هزینه‌ای انجام نشد.

### اقدام بعدی
1. بازبینی و اجرای تست Node جدید در CI روی HEAD دقیق.
2. ساخت candidate مالی canonical با حفظ wallets، asset_balances، fee helper و reservation ledger؛ بدون دست‌کاری Production.
3. سپس آزمون source-faithful PostgreSQL 17 و دو pair با display ticker یکسان.
4. حفظ Draft و توقف پیش از هر اقدام Production تا تأیید صریح مالک.


## شهرام ۲۰۳ — تقویت محافظ‌های ترتیب قفل و نقشهٔ اتصال هویت canonical به ledger — ۲۸ نوامبر ۲۰۲۶

### بازبینی دقیق منبع
- [x] بدنهٔ کامل Migration مرجع Market/Limit دوباره خوانده شد؛ ترتیب واقعی قفل wallet پیش از base-ledger در Market sell، Limit placement و Limit worker تأیید شد.
- [x] منطق reservation واقعی از منبع بررسی شد: موجودی رزروشدهٔ باقی‌مانده با reserved - consumed - released؛ محاسبهٔ cumulative consumed؛ محاسبهٔ حداقل released لازم برای پوشش remaining reserve؛ و محدودکردن released به reserved - consumed.
- [x] workflow موجود به‌طور صریح `node --test tests/*.test.js` را اجرا می‌کند؛ بنابراین تست جدید canonical Market/Limit در صورت اجرای workflow به‌طور خودکار در مجموعه قرار می‌گیرد. package.json اسکریپت test جداگانه ندارد.

### تغییرات این گام
- [x] تست قرارداد منبع تقویت شد تا ترتیب wallet-first در Market sell، Limit placement و Limit worker را pin کند.
- [x] تست، محاسبات cumulative reservation و lifecycle status را به‌صورت source guard بررسی می‌کند.
- [x] سند قرارداد، blueprint اتصال canonical IDs به جداول مالی موجود را اضافه کرد: pair_id برای جفت‌ارز/قیمت/سفارش، asset IDs برای سفارش/معامله/رزرو و حفظ wallet/base-balance ledger فعلی.
- [x] مرز تصمیم‌گیری روشن شد: pair_id مرجع execution است؛ ticker و symbol صرفاً snapshot سازگاری/نمایش‌اند؛ legacy asset text تا پایان mapping audit به canonical ID تبدیل خودکار نمی‌شود.

### Commitهای این گام
- `87912452434cddd1cff88463d2928867c052c644` — تقویت آزمون ترتیب قفل و reservation در Limit.
- `845a0a8057c7008b0b4dbed5cf26aa5c6bfdb7c0` — افزودن محافظ wallet-first و reserved-funds برای Market.
- `04bf5622171b8b87e599285809eb771b67ae322f` — افزودن blueprint هویت canonical روی ledger مالی موجود.

### اعتبارسنجی و محدودیت
- [!] تست‌ها به صورت source guard نوشته شده‌اند اما در این نشست اجرا نشدند؛ CI روی HEAD دقیق همچنان لازم است.
- [!] workflow روی PR هدف main تعریف شده و فرمان Node همهٔ فایل‌های tests/*.test.js را می‌گیرد؛ با این حال در HEAD بررسی‌شده Check Run تازه وجود ندارد.
- [!] هیچ candidate مالی اجرایی جدیدی ساخته نشد؛ تا رفع ابهام‌های migration/schema/ACL/RLS/trigger، تولید DDL یا توابع مالی جدید بدون اجرای disposable source-faithful می‌تواند رفتار حسابداری را حدس بزند.
- [!] ۱۷ منبع Migration اعمال‌شده هنوز بازیابی نشده و همچنان مانع سخت هر طرح deployable است.

### ایمنی
- [x] فقط تست و مستندات روی شاخهٔ Draft تغییر کردند.
- [x] هیچ SQL روی Supabase اجرا نشد؛ هیچ Migration، RPC، Worker، Cron یا دادهٔ مالی Production تغییر نکرد.
- [x] هیچ merge، rebase، deploy، انتشار APK/Pages یا هزینه‌ای انجام نشد.

### اقدام بعدی
1. CI را برای SHA دقیق از مسیر مجاز GitHub اجرا/تأیید کن؛ در غیر این صورت pending بماند.
2. طراحی fixture PostgreSQL 17 ایزوله را با اعمال Migration مرجع و prerequisiteهای معتبر آغاز کن؛ سپس canonical IDها را به همان wallet/base-ledger و reservation model متصل کن.
3. ابتدا Market buy/sell و Limit placement/worker را با pair_id-authoritative lookup پیاده‌سازی و تست کن؛ دو pair با display ticker یکسان را هم‌زمان پوشش بده.
4. قبل از هر DDL قابل انتشار، mapping ambiguity و تمام dependencyهای schema/trigger/RLS/ACL را مستند و reconcile کن.
5. PR را Draft نگه دار و تا تأیید صریح مالک هیچ اقدام Production انجام نده.



## شهرام ۲۰۴ — بازبینی زندهٔ شاخه و بررسی مستقل قرارداد مالی Market/Limit — ۲۸ نوامبر ۲۰۲۶

### وضعیت زندهٔ GitHub
- [x] PR #67 با عنوان `[Draft] Make every DigiArz catalog asset demo-tradable` باز، Draft و ادغام‌نشده است.
- [x] HEAD شاخه `plan/all-catalog-assets-tradable-2026-11-27`: `f2e53d4056938a42960a36a08754bc46056ecb63`.
- [x] Main: `e8477b53a1b8c6fc7225572db3e559a1c75607d8`.
- [x] Compare زنده: ۲۳۰ کامیت جلو و ۸ کامیت عقب؛ merge-base برابر `fbfb5e974e754088a32c9fdcd76fc2ca9ab0f98b`؛ وضعیت diverged.
- [x] GitHub برای PR مقدار `mergeable=false` و `mergeable_state=dirty` گزارش می‌کند؛ هیچ merge، rebase یا force-push انجام نشد.
- [x] برای HEAD دقیق `f2e53d4056938a42960a36a08754bc46056ecb63` تعداد Check Run برابر صفر و combined status برابر pending است.
- [x] جدیدترین اجرای Exact decimal tests که در فهرست Workflow runs دیده شد، run `46052800147` با نتیجه success روی SHA قدیمی‌تر `8f7925ced4c18716ee07e11890fd9572c4fcacf4` است؛ این نتیجه CI برای HEAD فعلی نیست.
- [!] ابزار متصل در این نشست مسیر ایجاد/dispatch اجرای تازهٔ workflow را ارائه نمی‌کند؛ اجرای Node روی HEAD دقیق همچنان تأیید نشده است.

### بازبینی مستقل منبع Market/Limit
- [x] سه فایل با blob SHAهای ثبت‌شده دوباره از شاخه خوانده شدند:
  - Migration مرجع: `de09b1cd391790fcd9d94708a916cb41cd9ccc9f`.
  - candidate هویت canonical: `42b56965140e6c7f7f20bf26126d06eebd472e24`.
  - تست قرارداد مالی: `b73a887eb5c98ce27ef26966e57a384548ed358a`.
- [x] بدنهٔ هر سه تابع authoritative از Migration استخراج شد و ۱۳ گروه بررسی ایستای مستقل برای auth/active-account، enabled pair، تازگی یک‌دقیقه‌ای، fee helper، گردکردن صریح Market، ترتیب قفل wallet-first، رزروها، advisory lock، SKIP LOCKED، partial fill بیست‌وپنج‌درصدی، ledgerهای trade/transaction و lifecycle تجمعی رزرو موفق بود.
- [x] اختلاف candidate ساده با قرارداد مالی دوباره تأیید شد: جدول generic balances به‌جای wallet/base-ledger، fee ثابت، پنجرهٔ تازگی دو دقیقه، حذف reservation و پرکردن کامل سفارش؛ بنابراین candidate همچنان فقط proof هویت canonical و جداسازی ticker است، نه موتور مالی هم‌ارز Production.
- [x] تفاوت دقت حفظ شد: Market gross/fee صراحتاً تا ۸ رقم اعشار گرد می‌شوند؛ worker مربوط به Limit چنین گردکردن صریحی در منبع ندارد و نباید بدون تصمیم مستقل تغییر کند.
- [!] این ۱۳ گروه، بازبینی patternهای منبع در محیط ابزار هستند؛ اجرای واقعی `node --test` یا تست PostgreSQL محسوب نمی‌شوند. فایل تست دارای ۹ بلوک test است و اجرای کامل آن همچنان منتظر CI روی SHA دقیق است.

### موانع و گام بعد
1. اجرای `node --test tests/*.test.js` در GitHub Actions برای HEAD فعلی و ثبت SHA دقیق نتیجه.
2. ادامهٔ طراحی fixture مالی canonical فقط در PostgreSQL disposable با Migration و prerequisiteهای کاملاً معتبر؛ دو pair با ticker نمایشی یکسان باید هم‌زمان آزموده شوند.
3. حفظ wallet + asset_balances + order_reservations + transactions؛ حذف هرگونه generic parallel balance از مسیر مالی candidate.
4. بازیابی ۱۷ منبع Migration مفقود و حل ۲۰ اختلاف timestamp/name همچنان gate مستقل پیش از هر طرح deployable است.
5. بررسی divergence هشت‌کامیتی PR از طریق برنامهٔ integration بازبینی‌شده؛ هیچ merge/rebase خودکار انجام نشود.

### ایمنی
- [x] فقط همین فایل وضعیت پروژه در شاخهٔ PR به‌روزرسانی می‌شود.
- [x] هیچ SQL روی Supabase اجرا نشد؛ هیچ Migration، RPC، Worker، Cron، Edge Function یا دادهٔ مالی Production تغییر نکرد.
- [x] هیچ سفارش، معامله، رزرو، کیف پول یا موجودی تغییر نکرد؛ jobهای زمان‌بندی‌شده بدون تغییر ماندند.
- [x] هیچ merge، rebase، deploy، انتشار APK/Pages یا هزینه‌ای انجام نشد.



## شهرام ۲۰۵ — اثبات سابقهٔ CI برای Migration واقعی Market/Limit و تفکیک شواهد canonical — ۲۸ نوامبر ۲۰۲۶

### کشف و تأیید منبع آزمون
- [x] مشخص شد Workflow `.github/workflows/exact-decimal-tests.yml` از قبل مرحلهٔ «Apply authoritative Market and Limit migration in disposable PostgreSQL» دارد؛ این مرحله setup ایزوله، snapshotهای helper، Migration مرجع و SQL یکپارچهٔ منبع را اجرا می‌کند.
- [x] فایل‌های زیر در HEAD فعلی و در SHA قدیمیِ اجرای موفق `8f7925ced4c18716ee07e11890fd9572c4fcacf4` دقیقاً blob یکسان دارند:
  - Migration `20261113161641_enforce_active_accounts_in_demo_trade_and_limit_engine.sql`: `de09b1cd391790fcd9d94708a916cb41cd9ccc9f`.
  - Setup آزمون: `3629184b9ed8e5c2cbcc6b6f74e83e790c5b3d92`.
  - SQL آزمون یکپارچه: `de0e3d260ec9a9dfaf03fd6b6a693c5975d0ec77`.
  - Workflow: `969f3976a0efb0002699bb156d69f899dd8b9675`.
- [x] اجرای GitHub Actions شماره `46052800147` روی SHA قدیمی `8f7925ced4c18716ee07e11890fd9572c4fcacf4` موفق بود؛ job `exact-decimal` و step 28 (اعمال Migration واقعی Market/Limit در PostgreSQL disposable) و step 5 (Node test suite) هر دو success ثبت شده‌اند.
- [!] این نتیجه شواهد معتبر اجرای همان چهار فایل/منبع در commit قدیمی است؛ اجرای CI روی HEAD فعلی `b397a600cca9682bf56ea681d35ee557f846a98d` را جایگزین نمی‌کند.

### دامنهٔ آزمون یکپارچهٔ موجود
- [x] SQL آزمون توابع واقعی `execute_demo_trade`، `place_limit_order` و `process_limit_orders` را روی fixture PostgreSQL 17 اجرا می‌کند؛ سناریوهای Market buy/sell، قیمت کهنه، حساب غیرفعال، Limit buy/sell، چهار fill جزئی، جمع consumed/released رزرو، ثبت trade و transaction و ورودی unauthenticated در آن وجود دارد.
- [x] fixture از schema حداقلی و دادهٔ آزمایشی استفاده می‌کند؛ این آزمون source parity رفتار توابع مرجع در محدودهٔ fixture است، نه اثبات کامل Production schema/RLS/ACL یا پوشش canonical pair_id.
- [x] آزمون duplicate display ticker در `canonical_asset_identity_candidate.sql` مستقل و ساده‌سازی‌شده است؛ هنوز به wallet/base-ledger، fee helper، قیمت market_prices، رزرو تجمعی و worker واقعی متصل نشده است.
- [x] تست جدید `tests/canonical-market-limit-financial-contract.test.js` در SHA قدیمی CI وجود نداشت؛ بنابراین اجرای Node موفق قدیمی، این فایل جدید را پوشش نداده است.

### وضعیت CI و PR فعلی
- [x] PR #67 باز، Draft، ادغام‌نشده و `mergeable=false` است.
- [x] HEAD فعلی هنگام ثبت این checkpoint: `b397a600cca9682bf56ea681d35ee557f846a98d`.
- [!] برای HEAD فعلی هنوز Check Run تازه ثبت نشده؛ CI باید روی همین SHA اجرا شود تا تست جدید Node نیز پوشش داده شود.
- [!] branch همچنان diverged است؛ compare ثبت‌شده ۲۳۱ جلو و ۸ عقب Main. هیچ merge/rebase انجام نشد.

### گام بعد
1. فراهم‌کردن اجرای Exact decimal workflow روی HEAD دقیق فعلی و بررسی تمام stepها، خصوصاً Node test suite و authoritative Market/Limit PostgreSQL integration.
2. ساخت آزمون canonical extension که به‌جای schema مالی موازی، همان wallet/base-ledger/fee helper/reservation/journal و worker واقعی را حفظ کند و دو pair با ticker نمایشی یکسان را هم‌زمان اجرا کند.
3. گسترش پوشش canonical به Market buy/sell، Limit buy/sell، چهار partial fill، stale/missing/future price، disabled pair، inactive account، insufficient balance، cancellation/release، idempotency و raceهای دو session.
4. عدم تبدیل این harness آزمایشی به migration deployable تا بازیابی ۱۷ Migration مفقود و reconciliation کامل schema/constraints/indexes/triggers/RLS/grants انجام شود.

### ایمنی
- [x] این checkpoint فقط مستندات شاخهٔ Draft را تغییر می‌دهد.
- [x] هیچ SQL اجرا نشد؛ هیچ Migration، RPC، Worker، Cron، Edge Function یا دادهٔ Production تغییر نکرد.
- [x] هیچ merge، rebase، deploy، APK/Pages publication یا هزینه‌ای انجام نشد.



## شهرام ۲۰۶ — تقویت آزمون یکپارچهٔ رزروهای باز در Market و Limit — ۲۸ نوامبر ۲۰۲۶

### تغییرات انجام‌شده در شاخهٔ Draft
- [x] در `supabase/tests/authoritative_market_limit_source_parity.sql` چهار سناریوی integration به harness موجود اضافه شد؛ هر چهار مورد از توابع authoritative واقعی پس از اعمال Migration در PostgreSQL disposable استفاده می‌کنند:
  1. Market buy نباید USDT رزروشده توسط سفارش دیگر را خرج کند.
  2. Market sell نباید دارایی پایهٔ رزروشده را خرج کند.
  3. Limit buy نباید USDT رزروشده را دوباره تخصیص دهد.
  4. Limit sell نباید دارایی پایهٔ رزروشده را دوباره رزرو کند.
- [x] هر سناریو خطای مورد انتظار insufficient available balance را assert می‌کند و ردیف reservation آزمایشی را پاک می‌کند؛ خطای موفقیت غیرمنتظره با marker مشخص دوباره raise می‌شود تا false pass رخ ندهد.
- [x] در `tests/canonical-market-limit-financial-contract.test.js` یک source guard افزوده شد که وجود محاسبات reservation در توابع مرجع و حضور هر چهار سناریوی SQL را الزام می‌کند.
- [x] بازبینی مستقل الگوهای منبع در محیط ابزار انجام شد: هر چهار marker SQL موجود، فرمول کسر رزرو USDT و base در Market موجود، و تجمیع رزروها در Limit موجود است.

### شناسه‌های فایل
- Migration authoritative (بدون تغییر): `de09b1cd391790fcd9d94708a916cb41cd9ccc9f`.
- Integration SQL جدید: `a7d30d3f2e57f511926e08f7d9bcaaf816af7d0c`.
- Node source guard جدید: `8bd9c82a950b1304f2545a577f69df8d15cd7226`.
- Workflow: `969f3976a0efb0002699bb156d69f899dd8b9675`؛ همان `node --test tests/*.test.js` و PostgreSQL 17 integration را اجرا می‌کند.

### محدودیت شواهد
- [!] هیچ اجرای Node یا PostgreSQL در این مرحله انجام نشد؛ بررسی‌های انجام‌شده فقط static pattern checks در محیط ابزار هستند.
- [!] CI قبلی موفق روی SHA قدیمی‌تر `8f7925ced4c18716ee07e11890fd9572c4fcacf4` اجرا شده بود و تغییرات جدید را پوشش نمی‌دهد.
- [!] برای SHA جدید باید اجرای کامل workflow تأیید شود؛ تا زمان ثبت Check Run موفق، این چهار سناریو را فقط «اضافه‌شده به harness» می‌دانیم، نه تست اجراشده.
- [!] آزمون canonical duplicate ticker هنوز به توابع مالی authoritative متصل نیست؛ Migration مرجع فعلی ticker-based است. اتصال pair_id به RPC/worker نیازمند طراحی نسخهٔ توسعه‌یافتهٔ schema و توابع است و نباید با fixture ساده‌شده اشتباه شود.

### وضعیت release و گام بعد
1. اجرای کامل workflow روی HEAD دقیق این checkpoint و بررسی همهٔ stepها.
2. در صورت شکست، اصلاح صرفاً در شاخهٔ Draft و تکرار آزمون.
3. پس از سبزشدن CI، طراحی extension canonical pair-keyed روی همان wallet/base-ledger/reservation/journal؛ دو pair با ticker نمایشی یکسان باید هم‌زمان اجرا شوند.
4. حل اختلاف ۸ کامیتی Main/branch و بازیابی ۱۷ Migration مفقود و ۲۰ اختلاف نام/زمان همچنان gateهای مستقل هستند.

### ایمنی
- [x] فقط فایل‌های تست و مستندات شاخهٔ Draft تغییر کردند.
- [x] هیچ SQL به Supabase یا Production ارسال نشد؛ هیچ Migration، RPC، Worker، Cron، Edge Function، RLS/ACL یا دادهٔ مالی تغییر نکرد.
- [x] هیچ سفارش، معامله، کیف پول، موجودی یا رزرو Production دستکاری نشد.
- [x] هیچ merge، rebase، deploy، انتشار APK/Pages یا هزینه‌ای انجام نشد.


## شهرام ۲۰۷ — معتبرسازی fixture سفارش‌های رزروشده و بازبینی وضعیت زنده — ۲۸ نوامبر ۲۰۲۶

### بازبینی آغاز مرحله
- [x] وضعیت زندهٔ شاخه و PR پیش از تغییر بررسی شد: HEAD برابر `066808d0aa05a94e148974541814592998282d3f`، PR #67 باز و Draft، ادغام‌نشده و `mergeable=false` بود؛ مقایسه با Main برابر ۲۳۶ جلو و ۸ عقب، Check Runs صفر و وضعیت commit برابر pending بود.
- [x] ساختار fixture PostgreSQL بازخوانی شد. جدول تست `order_reservations` در این fixture به `orders` کلید خارجی ندارد؛ بنابراین درج reservation با order_id تنها، سفارش واقعی/مرتبط را تضمین نمی‌کرد.

### اصلاحات
- [x] برای هر چهار سناریوی رزرو باز Market buy، Market sell، Limit buy و Limit sell، یک ردیف سفارش Limit آزمایشی متناظر در `public.orders` ساخته می‌شود.
- [x] پس از هر سناریو، reservation و سفارش fixture پاک می‌شوند.
- [x] Node source guard اکنون دقیقاً چهار fixture سفارش و چهار cleanup سفارش را الزام می‌کند.
- [x] تغییرات صرفاً در تست‌های disposable و guardهای Node هستند؛ Migration مرجع و توابع Production تغییر نکردند.

### شواهد و محدودیت‌ها
- [!] ساختار fixture فقط یک مدل آزمایشی تقلیل‌یافته است و چون FK ندارد، این اصلاح صرفاً انسجام منطقی دادهٔ تست را بهتر می‌کند؛ اثبات قیود FK یا parity کامل Production نیست.
- [!] در این مرحله Node و PostgreSQL اجرا نشدند؛ صحت فعلی فقط با بازبینی منبع و static guard قابل بیان است.
- [!] اجرای CI روی HEAD جدید هنوز وجود ندارد؛ Check Runs صفر است و نباید موفقیت تست‌ها ادعا شود.
- [!] مشکل canonical duplicate ticker همچنان مستقل باقی است: توابع authoritative فعلی بر اساس symbol کار می‌کنند و مسیر pair_id/asset_id canonical به آن‌ها متصل نشده است.

### وضعیت انتشار و گام بعد
1. اجرای واقعی Workflow روی HEAD فعلی و بررسی نتیجهٔ Node و PostgreSQL.
2. در صورت سبزشدن، طراحی سناریوی دو دارایی canonical با ticker نمایشی یکسان روی همان wallet، asset_balances، reservations و transactions واقعیِ fixture.
3. ادامهٔ بررسی کامل schema/index/trigger/RLS/ACL و Migrationهای مفقود، بدون حدس‌زدن SQL.

### ایمنی
- [x] فقط فایل‌های تست و این گزارش در شاخهٔ Draft تغییر کردند.
- [x] هیچ SQL، Migration، RPC، Worker، Cron، Edge Function، RLS/ACL یا دادهٔ Production/Supabase اجرا یا تغییر داده نشد.
- [x] هیچ Merge، rebase، deploy، انتشار APK/Pages یا هزینه‌ای انجام نشد.


## شهرام ۲۰۸ — طراحی آزمون مالی canonical برای tickerهای تکراری — ۲۸ نوامبر ۲۰۲۶

### بازبینی وضعیت زنده
- [x] پیش از تغییر، PR #67 و شاخهٔ کاری بررسی شدند: PR باز، Draft، ادغام‌نشده و `mergeable=false`؛ HEAD آغاز مرحله `4895ec18e1f18a924c375cf0a53f1e95bfe4e7c0`.
- [x] Main برابر `e8477b53a1b8c6fc7225572db3e559a1c75607d8` است؛ مقایسهٔ زنده ۲۳۹ commit جلو و ۸ عقب، وضعیت diverged.
- [x] Check Runs روی HEAD آغاز مرحله صفر و workflow run متصل به همان SHA یافت نشد؛ CI فعلی را سبز فرض نمی‌کنیم.

### یافتهٔ فنی مهم
- [x] fixture مرجع Market/Limit به‌صورت ticker-keyed ساخته شده: `demo_trading_pairs.pair_symbol` و `market_prices.symbol` کلید اصلی‌اند و توابع Migration مرجع نیز از همان مسیر نماد استفاده می‌کنند.
- [x] افزودن سادهٔ `pair_id` به این fixture کافی نیست؛ تا وقتی بدنهٔ RPC/worker canonical نشود، توابع همچنان با ticker lookup می‌کنند.
- [x] prototype canonical مستقل، pair و price را با ID تفکیک می‌کند اما از generic `balances(user_id,asset_id)`، fee ثابت و worker ساده‌شده استفاده می‌کند؛ بنابراین جایگزین دفترکل مالی مرجع نیست.
- [x] fixture مرجع یک schema تقلیل‌یافته است؛ نبود FK میان reservation و order در آن به‌تنهایی اثبات قیود Production نیست.

### خروجی این مرحله
- [x] سند `docs/CANONICAL_DUPLICATE_TICKER_FINANCIAL_TEST_PLAN_2026-11-28.md` ایجاد شد.
- [x] سند مسیر آزمون بعدی را مشخص می‌کند: شروع از fixture و Migration مرجع در PostgreSQL موقت، سپس افزودن candidate canonical RPC/worker فقط در همان محیط disposable.
- [x] الزامات مالی صریح حفظ شدند: wallets، asset_balances، fee helper، lifecycle رزرو، transactions/trades، active-account، wallet-first locks، advisory lock، freshness یک‌دقیقه‌ای و fill سقف ۲۵٪.
- [x] ماتریس آزمون duplicate ticker شامل Market/Limit buy/sell، partial fills، cancel/disable isolation، price validation، idempotency و race دو session ثبت شد.

### محدودیت شواهد و گام بعد
- [!] این مرحله سند طراحی و بازبینی منبع است؛ هیچ SQL یا Node test اجرا نشد و اجرای PostgreSQL canonical integration هنوز وجود ندارد.
- [!] اجرای CI روی HEAD تازه همچنان لازم است؛ Check Runs صفر بود.
- [ ] گام بعد: ساخت candidate canonical SQL منفصل که بدنهٔ RPC/worker را واقعاً pair-keyed کند، ولی همان wallet/base-ledger/fee/reservation/journal مرجع را حفظ کند؛ سپس آزمون duplicate ticker روی PostgreSQL disposable.
- [ ] بازیابی ۱۷ منبع Migration مفقود و حل ۲۰ اختلاف timestamp/name همچنان gate مستقل باقی می‌ماند.

### ایمنی
- [x] فقط سند طراحی و این فایل وضعیت در شاخهٔ Draft ثبت شدند.
- [x] هیچ SQL روی Supabase یا Production اجرا نشد؛ هیچ Migration، RPC، Worker، Cron، Edge Function، RLS/ACL یا دادهٔ مالی تغییر نکرد.
- [x] هیچ merge، rebase، db push، deploy، انتشار APK/Pages یا هزینه‌ای انجام نشد.
