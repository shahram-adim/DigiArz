# DigiArz — وضعیت اجرای پروژه
آخرین به‌روزرسانی: 2026-11-17
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
- [x] دو نشست `service_role` هم‌زمان هرکدام Fill به مقدار ۰٫۷ ETH روی یک سفارش یک ETH ارسال می‌کنند.
- [x] انتظار: دقیقاً یک Fill موفق و Fill دیگر با خطای عبور از remaining سفارش رد شود.
- [x] پس از رقابت، مقدار پرشده سفارش باید ۰٫۷، مقدار باقی‌مانده سفارش و پوزیشن هر دو ۰٫۳ و تعداد Fillها دقیقاً یک باشد.
- [x] تست به CI پس از نصب RPC و پیش از تست ترتیبی PnL/مارجین متصل شد.
- [!] این تست هنوز در دیتابیس اجرا نشده و نتیجه CI قابل مشاهده نیست.


## هماهنگی رزرو Reduce-only پس از کاهش خارجی پوزیشن — ۱۸ نوامبر ۲۰۲۶

- [x] RPC داخلی trusted برای بازگرداندن invariant رزرو پس از کاهش پوزیشن اضافه شد؛ ابتدا حساب و سپس پوزیشن قفل می‌شوند.
- [x] اگر مجموع رزروهای فعال از مقدار پوزیشن بیشتر باشد، سفارش‌ها به ترتیب جدیدترین `created_at DESC, id DESC` لغو می‌شوند تا رزروها دوباره در سقف پوزیشن قرار گیرند.
- [x] لغو سفارش فقط وضعیت را terminal می‌کند و هیچ حرکت وجهی در دفترکل ندارد؛ تابع فقط برای `service_role` قابل اجراست.
- [x] تست سناریوی ETHUSDT با سه سفارش فعال اضافه شد: پس از کاهش فرضی پوزیشن از ۰٫۶ به ۰٫۳، دو سفارش جدیدتر باید لغو شوند و قدیمی‌ترین رزرو ۰٫۲ باقی بماند.
- [x] تست دسترسی authenticated، ترتیب لغو، سقف رزرو نهایی و اجرای مجدد idempotent را بررسی می‌کند.
- [x] workflow ابتدا رقابت دو Fill را اجرا می‌کند، سپس RPC reconciliation را نصب و تست می‌کند.
- [!] SQL و تست هنوز در PostgreSQL اجرا نشده‌اند؛ نتیجه CI همچنان باید از GitHub Actions تأیید شود.
- [!] این helper هنوز به RPC نهایی لیکوییدیشن/کاهش پوزیشن متصل نشده است؛ اتصال باید در همان تراکنش و پس از کاهش معتبر پوزیشن انجام شود.
- [x] هیچ تغییری در Supabase Production یا UI مشتقات انجام نشده است.
