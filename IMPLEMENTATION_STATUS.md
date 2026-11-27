# DigiArz — وضعیت اجرای پروژه
آخرین به‌روزرسانی: 2026-11-19
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


## UI بازطراحی سه‌تم — انتقال امن به Main جاری — ۲۰۲۶-۱۱-۲۶

### وضعیت شروع و یافته‌ها
- HEAD شاخه `main` در زمان انتقال: `9855d6ea6cd188a5621c4e2c28c55e4cfb4d2587`.
- PR #61 روی شاخه `redesign/ui-clean-rebuild-2026` با ۲۴ commit عقب‌ماندگی نسبت به Main جاری و وضعیت diverged قرار داشت؛ به همین دلیل ادغام یا rebase کور انجام نشد.
- بررسی compare نشان داد تغییرات Main پس از merge-base عمدتاً مستندات QA، snapshotهای Stop-Limit و کد تابع بازار تومانی بوده و فایل‌های UI هدف را تغییر نداده است.
- شاخه تازه `redesign/ui-mainline-clean-2026-11-26` مستقیماً از Main جاری ساخته شد و PR #64 به‌صورت Draft باز شد؛ در زمان ایجاد ۰ commit عقب‌تر از Main بود.

### کارهای منتقل‌شده
- [x] فقط ۹ فایل UI/QA/APK از candidate قبلی منتقل شد: `index.html`, `src/digiarz-independent-ui.css`, `sw.js`, سه فایل آزمون UI، و دو workflow مستقل UI visual و candidate APK.
- [x] اصلاحات حذف قاب پس‌زمینه لوگوها و سربرگ تکراری داشبورد در candidate حفظ شد.
- [x] harness تصویری Playwright با داده‌های ساختگی و قطعی بازار/کیف پول seed شد تا در نبود Supabase هم ردیف‌های بازار، قیمت USD، معادل تومان، تغییر ۲۴ساعته، حجم و دارایی‌ها قابل بررسی باشند.
- [x] داده‌های fixture فقط در مرورگر CI ایجاد می‌شوند؛ درخواست Supabase همچنان مسدود است و هیچ داده‌ای به backend ارسال یا ذخیره نمی‌شود.
- [x] آزمون source-level اضافه شد تا وجود fixtureها و فراخوانی renderهای بازار، داشبورد، top assets و portfolio کنترل شود.

### CI و APK
- CIهای PR #64 برای Exact Decimal، UI Visual Review و Android Candidate APK در حال اجرا هستند؛ تا زمان ثبت این یادداشت هیچ‌کدام را موفق اعلام نمی‌کنیم.
- APK قبلی PR #61 از commit `0129a83b3cada2646e5c3547ea6130b988a3533f` ساخته شده بود؛ آن فایل نمایندهٔ head جدید PR #64 نیست و برای این candidate جدید باید APK تازه ساخته شود.
- اسکرین‌شات‌های قبلی بدون fixture، داده زنده یا دارایی حساب واقعی را تأیید نمی‌کنند؛ fixtureهای جدید فقط چیدمان را می‌آزمایند.

### محدودیت‌ها و ایمنی
- PR #64 Draft و ادغام‌نشده است؛ PR #61 نیز باز و بدون ادغام باقی مانده است.
- هیچ تغییری در Main، Supabase Production، migration، RPC، Edge Function، cron، wallet، balance، order یا trade اعمال نشده است.
- تست فیزیکی APK روی گوشی Android و بررسی حساب واقعی با داده زنده هنوز انجام نشده است.
- هیچ قیمت ساختگی نباید به‌عنوان قیمت بازار واقعی معرفی شود.

### گام بعد
1. نتیجهٔ دقیق هر سه workflow روی head فعلی PR #64 را بازخوانی کن؛ شکست احتمالی فقط در harness/آزمون را اصلاح کن.
2. تصاویر جدید را بررسی کن تا چیدمان داشبورد، بازار و لوگوها با داده fixture قابل مشاهده باشد.
3. APK تازهٔ همین head را از artifact بگیر و برای نصب آزمایشی ارائه کن.
4. پس از نصب، رفتار واقعی هر سه تم، فهرست بازار، قیمت تومانی، کیف پول، ورود و خروج روی دستگاه بررسی شود.
5. PR #64 تا تأیید صریح مالک Draft بماند؛ هیچ merge یا Production deploy انجام نشود.


### به‌روزرسانی پس از اجرای CI — ۲۰۲۶-۱۱-۲۶
- [x] اجرای اولیه Exact Decimal روی commit `38fcd484` با ۱۴۲ تست، ۱۴۱ موفق و ۱ شکست پایان یافت؛ تنها شکست، assertion قدیمی تست cache بود که هنوز `digiarz-shell-v61` انتظار داشت، درحالی‌که shell cache عمداً به `v62` ارتقا یافته بود.
- [x] assertion به `v62` اصلاح شد؛ commit اصلاحی `704be545f2b137fb60cce2b1d11fe31c54588077`.
- [!] نتیجهٔ اجرای مجدد Exact Decimal، UI Visual Review و Android APK روی head جدید تا زمان این یادداشت هنوز pending/in progress است؛ موفقیت نهایی اعلام نمی‌شود.
- گام بعد: فقط نتیجهٔ سه workflow روی head `704be545` را بررسی کن؛ اگر UI visual fixture در مرورگر خطا داشت، همان harness را اصلاح کن؛ APK تنها از artifact همین head یا head جدیدتر و پس از موفقیت workflow ارائه شود.


### کنترل اجرای موازی CI — ۲۰۲۶-۱۱-۲۶
- [x] workflow تصویری از `cancel-in-progress: true` به `false` تغییر کرد تا اجرای screenshotهای سه‌تم هنگام رسیدن commit بعدی لغو نشود.
- [x] مسیر `tests/**` به triggerهای Android candidate اضافه شد تا تغییر تست‌های UI نیز APK متناسب با همان candidate را بازسازی کند.
- [x] commit تنظیم workflowها: `33386c21a4ce5f889265fe05210e15e6dce58c1a`.
- [!] روی همین head، Exact Decimal / UI Visual Review / Android APK در حال اجرا یا صف هستند؛ artifact APK جدید هنوز دریافت نشده است.


## بازبینی نهایی حذف قاب لوگو و خروجی APK — ۲۰۲۶-۱۱-۲۶

### اصلاحات رابط کاربری
- [x] بازبینی تصویری ۶۰ حالت (۲ اندازه نمایش × ۳ تم × ۱۰ صفحه) انجام شد.
- [x] در بررسی تصاویر مشخص شد بخشی از پس‌زمینه آبی لوگوی داشبورد از قانون عمومی دکمه‌های اصلی به دکمهٔ هویت ارز `da-market-identity` منتقل می‌شد، نه فقط از خود wrapper لوگو.
- [x] پس‌زمینه/گرادیان، border و shadow دکمه‌های هویت بازار و داشبورد در هر سه تم به‌صورت شفاف و بدون قاب override شد.
- [x] اولویت CSS theme-specific اصلاح شد و escape اشتباه newline در فهرست selectorها حذف شد؛ اکنون selectorها با newline واقعی و معتبر CSS جدا شده‌اند.
- [x] رگرسیون تست برای شفافیت لوگوها و دکمه‌های هویت بازار/داشبورد در سه تم اضافه شد.
- [x] harness تصویری از توابع private اپ مستقل شد و داده‌های synthetic فقط در DOM مرورگر برای نمایش چیدمان درج می‌شوند؛ هیچ درخواست write به Supabase انجام نمی‌شود.
- [x] تصاویر جدید نشان می‌دهند ردیف‌های بازار و داشبورد با لوگوهای بدون tile/پس‌زمینه رنگی نمایش داده می‌شوند.

### CI و APK روی head نهایی این مرحله
- Branch head: `6ed150a3a101404ac2c282f38b2e282dee19d3ba`.
- PR #64: باز، Draft و ادغام‌نشده؛ base برابر Main با SHA `9855d6ea6cd188a5621c4e2c28c55e4cfb4d2587`؛ صفر commit عقب‌تر از Main؛ mergeable گزارش شده است.
- Exact Decimal / PostgreSQL / Market & Limit / Stop-Limit و TP-SL integration/race tests: موفق.
- UI Visual Review: موفق؛ ۶۰ تصویر با داده‌های synthetic DOM-only تولید شد.
- Android Candidate APK workflow: موفق؛ artifact `15097163433` دریافت و بررسی شد.
- APK: `DigiArz-UI-Candidate-2026-11-26.apk`; حجم حدود ۳٫۸ MB؛ SHA-256 `b532c1a7c41f1fbd9824bb4b724a95675d2daadeebd18437eff7ca4d35b509ec`; ساختار ZIP داخلی APK و امضای آن بررسی شد.
- فایل BUILD-INFO نشان می‌دهد نسخه از `refs/pull/64/merge` ساخته شده است؛ این نسخه Debug/Candidate است، نه Release امضاشده برای انتشار عمومی.

### محدودیت‌های تأیید
- تصاویر CI با داده‌های ساختگی صرفاً چیدمان و CSS را بررسی می‌کنند؛ قیمت زنده، اتصال Supabase، ورود واقعی و دادهٔ واقعی حساب را تأیید نمی‌کنند.
- نصب و آزمون روی دستگاه فیزیکی Android هنوز انجام نشده و باید پس از نصب توسط مالک بررسی شود.
- ظاهر کلی صفحات هنوز نیازمند بازبینی انسانی روی گوشی است؛ موفقیت تست‌ها به‌تنهایی تأیید نهایی کیفیت بصری/انتشار نیست.

### ایمنی و مرحله بعد
- [x] هیچ merge، release، Pages deploy، Supabase deployment، migration یا تغییر Production انجام نشده است.
- [ ] مالک APK را روی گوشی نصب و صفحهٔ داشبورد و بازار را با دادهٔ واقعی بررسی کند.
- [ ] پس از بازخورد دستگاه، فاصله‌ها/تراکم ردیف‌ها و لوگوهای واقعی در صورت نیاز اصلاح شود.
- [ ] PR #64 تا تأیید صریح مالک Draft باقی بماند؛ هیچ merge یا تغییر Production بدون اجازه انجام نشود.


## اصلاح چیدمان داشبورد/بازار و تم سوم — ۲۰۲۶-۱۱-۲۶
- [x] علت اصلی دیده‌شدن هم‌زمان صفحات پیدا شد: قواعد display:flex/block!important برای #tab-dashboard و #tab-markets از کلاس .hidden اولویت بالاتری داشتند؛ قاعدهٔ scoped با اولویت بالاتر اضافه شد تا صفحات غیرفعال واقعاً از جریان نمایش خارج شوند.
- [x] گرید ردیف بازار اصلاح شد؛ پنج ستون و پنج ناحیهٔ هم‌نام برای علاقه‌مندی، هویت دارایی، نمودار، تغییر ۲۴ساعته و قیمت دوارزی در دسکتاپ و موبایل تعریف شد. نسخهٔ قبلی موبایل چهار ناحیه در برابر پنج ستون داشت و چیدمان را ناپایدار می‌کرد.
- [x] تم سوم از سرمه‌ای تیره به شیشه‌ای روشن نیلی/آبی یخی تغییر کرد؛ پس‌زمینهٔ روشن، سطوح سفید، متن نیلی و accent آبی مستقل دارد و با مشکی/طلایی تم اول اشتباه نمی‌شود.
- [x] سه تست regression جدید برای جداسازی صفحات، تطابق گرید بازار و روشن‌بودن تم سوم افزوده شد.
- [ ] اجرای CI و بررسی اسکرین‌شات‌های جدید موبایل/دسکتاپ در هر سه تم هنوز باید تأیید شود.
- [ ] APK تازه فقط پس از سبز شدن تست‌ها ساخته و تحویل می‌شود؛ APK قبلی نمایندهٔ این اصلاحات نیست.
- ایمنی: فقط CSS و تست UI در شاخهٔ Draft PR #64 تغییر کرده‌اند؛ هیچ Merge، انتشار، تغییر Supabase، migration یا دست‌کاری دادهٔ Production انجام نشده است.


## تمیزکاری کنتراست تم سوم پس از بازبینی تصویری — ۲۰۲۶-۱۱-۲۶
- [x] بازبینی تصاویر CI نشان داد لایهٔ قدیمی CSS برای کارت حساب و پنل بازار هنوز سطح سرمه‌ای را روی تم سوم تحمیل می‌کند؛ این override با سطوح سفید/یخی، متن نیلی تیره، حاشیهٔ آبی ملایم و سایهٔ روشن جایگزین شد.
- [x] کارت کیف پول، موجودی، آمار حساب، میان‌برها، ردیف دارایی‌های کیف پول و پیش‌نمایش بازار در داشبورد برای تم سوم صریحاً روشن شدند.
- [x] رنگ متن نام ارز/قیمت/اطلاعات فرعی و فیلترهای بازار برای کنتراست بهتر تنظیم شد.
- [x] تست regression برای جلوگیری از بازگشت سطوح تیرهٔ قدیمی به تم روشن اضافه شد.
- [ ] اجرای دوبارهٔ CI، اسکرین‌شات‌های تم سوم و APK پس از این دور اصلاحات در انتظار است.
- ایمنی: فقط CSS و تست‌ها در Draft PR #64 تغییر کرده‌اند؛ بدون merge یا تغییر Production/DB.


## اصلاح دور سوم چیدمان موبایل — ۲۰۲۶-۱۱-۲۶
- [x] تصاویر واقعی نشان دادند نوار پایین در full-page screenshot به‌علت fixed بودن در مختصات viewport دیده می‌شود؛ capture موبایل به viewport واقعی تغییر کرد تا بازبینی جایگاه منو معتبر باشد (نمای دسکتاپ همچنان full-page است).
- [x] ردیف‌های پیش‌نمایش بازار داشبورد بازطراحی شبکه‌ای شدند تا نام فارسی فضای واقعی داشته باشد، قیمت USD و تومان در ستون مشخص بماند و نمودار کوچک در عرض بسیار محدود موبایل حذف شود.
- [x] سربرگ بازار، معرفی، دسته‌بندی‌ها و فاصلهٔ پنل‌ها در موبایل فشرده شدند تا فهرست دارایی‌ها زودتر و خواناتر دیده شود.
- [x] تست‌های regression برای ردیف‌های موبایل و فشردگی سربرگ بازار اضافه شدند.
- [ ] CI، اسکرین‌شات viewport واقعی موبایل و APK تازه هنوز در انتظار اجرا هستند.
- ایمنی: فقط CSS، تست و اسکریپت screenshot در Draft PR #64 تغییر کردند؛ بدون merge، Production DB یا migration.


### بازبینی واقعی تصاویر سه‌تم و اصلاح کنتراست — ۲۰۲۶-۱۱-۲۶
- [x] هر دو workflow جدید روی PR #64 با موفقیت پایان یافتند؛ APK و ۶۰ تصویر مرور بصری از همان ref ساخته شدند.
- [x] APK candidate دریافت و اعتبارسنجی ZIP/ساختار Android انجام شد؛ BUILD-INFO به merge-ref همین PR اشاره می‌کند و SHA-256 فایل با manifest یکسان است.
- [x] بازبینی دستی تصاویر موبایل نشان داد تم سفید خواناست و تم مشکی/طلایی هویت مستقل خود را حفظ کرده است.
- [!] بازبینی تم سوم (نیلی/آبی یخی) یک ایراد واقعی کنتراست در دکمه‌های Hero بازار و نوار پایین نشان داد؛ بعضی دکمه‌ها پس‌زمینهٔ نیلی تیره و متن کم‌کنتراست داشتند. در تصویر بازار، فهرست دارایی‌ها نیز هنوز به حالت «در حال دریافت» مانده است؛ بنابراین fixture فعلی برای اثبات رندر ردیف‌های زنده کافی نیست.
- [x] override تکمیلی برای دکمه‌های Hero، ابزارهای بازار، نوار پایین و کنترل تم در تم سوم اضافه شد؛ تست regression متناظر نیز اضافه شد.
- [ ] پس از این اصلاح، CI و تصاویر تازه باید دوباره اجرا و به‌صورت بصری بازبینی شوند؛ APK فعلی فقط candidate میانی است و به‌عنوان نسخه نهایی طراحی معرفی نمی‌شود.
- [ ] harness باید در گام بعد ردیف‌های synthetic را در حالت واقعی DOM و پس از render تزریق کند تا تصاویر داشبورد/بازار، ردیف‌های دارای نام، لوگو، USD، تومان و درصد ۲۴ساعته را واقعاً نشان دهند.
- ایمنی: فقط شاخه Draft PR #64 تغییر می‌کند؛ هیچ merge، انتشار، Production DB، migration یا تغییر Supabase انجام نشده است.


### پوشش واقعی ردیف‌های دارایی در تصاویر موبایل — ۲۰۲۶-۱۱-۲۶
- [x] مشخص شد اسکرین‌شات viewport اولیه، فقط بخش بالایی داشبورد و سربرگ بازار را ثبت می‌کرد؛ ردیف‌های دارایی پایین‌تر از viewport بودند، نه اینکه الزاماً رندر نشده باشند.
- [x] harness اکنون پس از seed کردن داده‌های DOM-only، برای هر سه تم موبایل به پیش‌نمایش دارایی داشبورد و فهرست واقعی بازار scroll می‌کند و ۶ نمای نزدیک اضافی ذخیره می‌کند.
- [x] تعداد تصاویر مورد انتظار از ۶۰ به ۶۶ افزایش یافت و تست regression برای حضور هر دو capture اضافه شد.
- [ ] CI جدید باید ثابت کند ۶۶ تصویر کامل تولید می‌شود؛ سپس close-upهای موبایل بررسی شوند.


### اصلاح کنتراست پس از بازبینی ۶۶ تصویر — ۲۰۲۶-۱۱-۲۶
- [x] ۶۶ تصویر مرور بصری روی commit d8255e6 تولید شد.
- [!] بازبینی نمای نزدیک بازار تم نیلی نشان داد متن قیمت USD و نوار پایین هنوز تیره/کم‌خوانا هستند؛ override قبلی به اندازه کافی بر قواعد قدیمی غلبه نکرد.
- [x] اصلاح با specificity بالاتر برای متن قیمت USD، قیمت تومان، sparkline و نوار پایین در تم سوم اضافه شد؛ تست regression اختصاصی اضافه شد.
- [ ] APK و تصاویر نهایی باید از commit جدید ساخته شوند و دوباره بازبینی شوند؛ APK فعلی run قبلی تحویل نهایی نیست.


### تأیید نهایی CI و APK پس از اصلاح داشبورد/بازار و تم سوم — ۲۰۲۶-۱۱-۲۶
- [x] آخرین head شاخه و PR #64: `dc00fef08110f302eb381c3728dedd785e671570`.
- [x] Exact decimal workflow run #2098 / run ID `45784971096`: موفق.
- [x] UI visual review run #72 / run ID `45784971069`: موفق؛ artifact شامل تصاویر مرور بصری با حجم 21,732,325 بایت، artifact ID `15099098867`.
- [x] Android Candidate APK run #96 / run ID `45784971225`: موفق؛ artifact ID `15099619204`، حجم 3,606,203 بایت، SHA-256 آرشیو artifact: `685944d9429bf3ec397c4f6b10ef4675c1ca8d7fd8134ca2fbd67944a7397712`.
- [x] هر سه workflow دقیقاً به head فوق متصل‌اند؛ jobهای اصلی هر سه completed/success هستند.
- [!] APK فقط Debug/Candidate است، نه Release امضاشده برای انتشار عمومی؛ نصب و تست فیزیکی روی Android هنوز توسط مالک تأیید نشده است.
- [!] اسکرین‌شات‌ها تست بصری با fixtureهای synthetic هستند؛ اتصال واقعی Supabase، قیمت زنده، ورود و کیف پول واقعی را اثبات نمی‌کنند.
- [ ] مالک artifact APK را از صفحه Actions دانلود و روی گوشی نصب کند؛ داشبورد، بازار، جابه‌جایی صفحات و تم سوم روشن را بررسی کند.
- [ ] PR #64 همچنان Draft و ادغام‌نشده بماند تا بازخورد دستگاه دریافت شود.
- ایمنی: هیچ merge، release، Pages deploy، Supabase deployment، migration یا Production mutation انجام نشد.


## اصلاح فهرست بازار و جایگاه تتر — ۲۶ نوامبر ۲۰۲۶
- [x] نوار آیکون‌های دسته‌بندی بازار از بخش بالایی بازار به داخل سرصفحهٔ «فهرست دارایی‌ها» منتقل شد تا دقیقاً زیر عنوان فهرست و پیش از ردیف ارزها نمایش داده شود.
- [x] ردیف مستقل USDT به‌صورت ثابت در ابتدای فهرست بازار قرار گرفت؛ مستقل از مرتب‌سازی و فیلتر دسته‌ها، همیشه بالاتر از سایر ارزها می‌ماند.
- [x] لوگوی تتر به SVG اختصاصی با نشان سبز Tether تبدیل شد تا نمایش آن به سرویس پراکسی یا فایل لوگوی بیرونی وابسته نباشد؛ قیمت مرجع نمایشی آن ۱ دلار و معادل تومانی آن از نرخ معتبر دلار محاسبه می‌شود.
- [x] ردیف تتر به‌عنوان استیبل‌کوین/ارز مبنا مشخص شده و کنترل علاقه‌مندی آن نیز فعال است؛ ردیف اطلاعاتی USDT به جفت‌ارز معاملاتی ساختگی تبدیل نشده است.
- [x] قواعد CSS برای سه تم و نمایش موبایل افزوده شد؛ ظاهر بدون قاب و پس‌زمینهٔ لوگو حفظ شده است.
- [x] آزمون‌های منبع برای ترتیب دسته‌بندی‌ها، پین‌شدن USDT و سبک لوگو اضافه شد.
- [!] تغییرات فقط روی شاخهٔ Draft رابط کاربری redesign/ui-mainline-clean-2026-11-26 و PR #64 ثبت می‌شوند؛ هنوز merge یا انتشار نشده‌اند.
- [ ] اجرای CI پس از این تغییرات و بازبینی تصویری ردیف بازار در هر سه تم باقی است.
- [ ] ساخت APK کاندید جدید پس از سبزشدن CI باقی است؛ APK قبلی شامل این تغییرات نیست.
- [x] هیچ تغییر Backend، Supabase، دیتابیس، کیف پول، سفارش یا Production انجام نشد.


## ورود بیومتریک و نگهداری امن اطلاعات ورود — ۲۶ نوامبر ۲۰۲۶
- [x] وضعیت فعلی بررسی شد: ورود Supabase فقط با ایمیل/رمز بود و APK فاقد پل بومی بیومتریک بود.
- [x] گزینهٔ ذخیره اطلاعات ورود به‌صورت انتخابی اضافه شد؛ پیش‌فرض خاموش است و فقط پس از ورود موفق و تأیید اثر انگشت، ایمیل و رمز در مخزن رمزنگاری‌شدهٔ همان دستگاه ذخیره می‌شوند.
- [x] مسیر ورود بعدی با اثر انگشت به API احراز هویت Supabase متصل شد؛ رمز خام در localStorage، فایل‌ها یا دیتابیس برنامه ذخیره نمی‌شود.
- [x] افزونهٔ بومی Android با BiometricPrompt و Android Keystore (AES-GCM، کلید نیازمند احراز هویت بیومتریک) به پروژهٔ Capacitor افزوده شد؛ تغییر enrollment اثر انگشت، کلید قبلی را نامعتبر می‌کند.
- [x] کنترل دسترسی‌پذیری بیومتریک و وجود اطلاعات ذخیره‌شده پیش از نمایش دکمه انجام می‌شود؛ در وب‌اپ بدون افزونه، کنترل بیومتریک نمایش داده نمی‌شود.
- [x] workflow ساخت APK اکنون پل بومی و وابستگی AndroidX Biometric را پیش از sync/build نصب می‌کند.
- [ ] CI و build واقعی APK باید روی همین head اجرا شوند؛ سازگاری با حسگر و سیاست امنیتی دستگاه فیزیکی هنوز تأیید نشده است.
- [ ] پس از ساخت، روی Android 10 و دستگاه‌های دارای اثر انگشت/تشخیص چهره واجد شرایط آزمایش شود؛ در صورت پشتیبانی‌نشدن Biometric Strong، ورود عادی رمز عبور همچنان کار می‌کند.
- ایمنی: فقط شاخهٔ Draft PR #64 تغییر می‌کند؛ بدون merge، release، Supabase/Production، migration یا تغییر داده‌های حساب.


### تکمیل کنترل‌های ورود بیومتریک — ۲۶ نوامبر ۲۰۲۶
- [x] پس از ذخیره موفق اطلاعات، دکمهٔ ورود با اثر انگشت و کنترل حذف اطلاعات ذخیره‌شده نمایش داده می‌شوند.
- [x] کاربر می‌تواند هر زمان اطلاعات ورود رمزنگاری‌شده را از همان گوشی پاک کند؛ حذف از مخزن امن و حذف کلید Android Keystore انجام می‌شود.
- [x] نام فیلدهای ایمیل و رمز نیز برای سازگاری بهتر با مدیر گذرواژهٔ Android مشخص شدند.
- [ ] نتیجهٔ CI و APK هنوز دریافت/تأیید نشده است؛ تا آن زمان فعال‌بودن عملی روی دستگاه ادعا نمی‌شود.


## یکپارچه‌سازی وضعیت آیکون‌ها در هر سه تم — ۲۰۲۶-۱۱-۲۶
- [x] بنا به درخواست مالک، اصلاح کنتراست آیکون‌ها از تم سوم به هر سه تم گسترش یافت؛ هر تم رنگ فعال مستقل خود را حفظ می‌کند.
- [x] آیکون‌های غیرفعال در ناوبری دسکتاپ/موبایل، دسته‌بندی بازار و میان‌برهای داشبورد کم‌اشباع‌تر و ملایم‌تر شدند.
- [x] حالت فعال با رنگ اختصاصی تم، پس‌زمینهٔ ملایم، نشانگر زیرین و درخشش بسیار محدود برای تشخیص سریع تقویت شد؛ حالت focus صفحه‌کلید نیز حفظ شد.
- [x] حرکت‌ها در تنظیمات prefers-reduced-motion غیرفعال می‌شوند.
- Commit: `635e205b9cf770899ed7f78586f01f38d71fa03a` روی شاخه `redesign/ui-mainline-clean-2026-11-26` و در PR #64.
- [ ] اجرای workflowها و بازبینی اسکرین‌شات هر سه تم پس از این commit هنوز تأیید نشده است.
- ایمنی: فقط stylesheet در شاخهٔ Draft تغییر کرد؛ PR #64 ادغام‌نشده باقی می‌ماند. هیچ merge، انتشار، migration یا تغییر Supabase/Production انجام نشد.


## ارتقای بصری آیکون‌ها و رابط کاربری به سطح پریمیوم — ۲۰۲۶-۱۱-۲۶
- [x] لایهٔ طراحی یکپارچه برای کل بخش اپ اضافه شد: ناوبری دسکتاپ/موبایل، دسته‌بندی‌های بازار، میان‌برهای داشبورد، کارت‌ها، فرم‌ها، اعلان‌ها و ردیف دارایی‌ها.
- [x] آیکون‌ها از حالت تخت و پراکنده به ارائهٔ یکپارچهٔ stroke، اندازه، فاصله و رفتار تعاملی ارتقا یافتند؛ برای میان‌برهای داشبورد زمینهٔ آیکونی مستقل و شیشه‌ای تعریف شد.
- [x] کنترل‌ها دارای بازخورد hover/press/focus، هایلایت ظریف و انیمیشن کوتاه شده‌اند؛ برای دستگاه لمسی hover مصنوعی حذف و برای prefers-reduced-motion حرکت‌ها غیرفعال می‌شود.
- [x] کارت‌ها، تب‌ها و دسته‌بندی‌ها دارای عمق، مرزبندی کم‌رنگ، هایلایت لبه و سایه‌های کنترل‌شده شدند؛ از قاب‌های سنگین و نئون اغراق‌شده اجتناب شد.
- [x] استایل نهایی برای هر سه تم جداگانه تعریف شد: مشکی/طلایی، سفید شیشه‌ای، نیلی/آبی یخی.
- [x] commit اصلی این ارتقا: `4d0b61b00eae23adc83d96446f156369bd49ecdb`.
- [ ] اجرای UI Visual Review روی head جدید و بازبینی ۶۶ تصویر خروجی هنوز تأیید نشده است؛ تا آن زمان کیفیت نهایی بصری را تأییدشده اعلام نمی‌کنیم.
- [ ] ساخت APK جدید از head نهایی این مرحله پس از موفقیت workflowها و بررسی اسکرین‌شات‌ها لازم است.
- ایمنی: فقط CSS در شاخهٔ Draft PR #64 تغییر کرد؛ هیچ merge، انتشار، تغییر Supabase/Production، migration یا تغییر داده انجام نشد.



## ممیزی وضعیت PR طراحی پس از درخواست بازبینی — ۲۶ نوامبر ۲۰۲۶

### وضعیت GitHub
- [x] PR #64 دوباره از GitHub خوانده شد: باز، Draft، ادغام‌نشده؛ head فعلی هنگام ممیزی `64c2db8710d0e77d55ac155f4d7ef85fe6a77ebd`.
- [x] مقایسه با Main جاری نشان داد شاخه ۷۳ commit جلو و ۲ commit عقب است؛ وضعیت compare برابر `diverged` و `mergeable=false` گزارش شده است.
- [x] دو commit جدید Main هر دو `IMPLEMENTATION_STATUS.md` را تغییر داده‌اند؛ این فایل نقطهٔ احتمالی تعارض هنگام همگام‌سازی است. تعارض قطعی بدون mergeability detail اعلام نمی‌شود.
- [!] Combined status برای head فعلی خالی است و wrapper اجراهای PR-triggered نیز هیچ workflow run برای SHA فعلی برنگرداند؛ CI سبز برای head فعلی قابل تأیید نیست.

### یافته‌های فنی
- [!] فایل `src/digiarz-independent-ui.css` حدود ۳۸۲٬۷۷۰ نویسه دارد و چندین تعریف متوالی و متناقض برای `body.luxury-theme` نگه داشته است؛ تعریف روشن نیلی/یخی در انتهای فایل وجود دارد، اما لایه‌های قدیمی تیره و overrideهای متعدد باقی مانده‌اند. لازم است قبل از تأیید نهایی، قواعد تجمیع و تکرارها پاک‌سازی و computed styles هر سه تم بررسی شوند.
- [!] تست منبع تم سوم با تطبیق یک تعریف قدیمی تیره (#111027) پاس‌پذیر است و اثبات نمی‌کند آخرین computed style روشن است؛ assertion باید آخرین override مؤثر را کنترل کند.
- [!] fixture اسکرین‌شات، محتوای `#marketList` را با هشت دارایی ساختگی جایگزین می‌کند و USDT را در فهرست نمی‌گذارد؛ بنابراین جایگاه ثابت تتر و SVG واقعی آن در خروجی بصری این harness بررسی نمی‌شود.
- [!] fixtureها برای هویت دارایی از glyphهای متنی (مانند ₿ و ◆) استفاده می‌کنند، نه لوگوهای واقعی؛ اسکرین‌شات فعلی نمی‌تواند صحت و کیفیت لوگوهای بازار را تأیید کند.
- [!] harness بخش‌ها را مستقیماً با تغییر کلاس و style نمایش می‌دهد؛ بنابراین مسیر واقعی کلیک ناوبری و اتصال واقعی Supabase/قیمت/حساب را اعتبارسنجی نمی‌کند.
- [x] کد بیومتریک از Android Keystore و AES-GCM با احراز هویت بیومتریک قوی استفاده می‌کند؛ رمز به‌صورت متن ساده در localStorage ذخیره نمی‌شود. سازگاری واقعی با دستگاه و حسگر هنوز به build و تست فیزیکی نیاز دارد.

### مشکل اجرای خودکار تست‌ها
- [!] فایل‌های `.github/workflows/android-candidate-apk.yml` و `ui-visual-review.yml` در همین PR اضافه شده‌اند؛ workflowهای تازه‌افزوده‌شده تا زمانی که در شاخهٔ base موجود نباشند، مبنای قابل اتکایی برای اجرای خودکار `pull_request` نیستند و `workflow_dispatch` نیز به workflow موجود در default branch وابسته است.
- [!] trigger از نوع push در workflow ساخت APK به شاخهٔ قدیمی `redesign/ui-clean-rebuild-2026` اشاره می‌کند، نه شاخهٔ فعال `redesign/ui-mainline-clean-2026-11-26`.
- [!] در نتیجه، نباید انتظار داشت workflowهای جدید به‌تنهایی روی همین PR اجرا شوند؛ باید از مسیر CI موجود در base یا روش اجرایی مجاز دیگری برای آزمون candidate استفاده شود.

### نتیجه و گام بعد
- [x] ممیزی read-only انجام شد؛ هیچ فایل اجرایی، Main، Supabase، Production، migration، wallet، order یا trade تغییر نکرد.
- [ ] پیش از APK جدید: همگام‌سازی کنترل‌شدهٔ دو commit Main با شاخهٔ PR، با توجه ویژه به `IMPLEMENTATION_STATUS.md`؛ بدون rebase/merge کور.
- [ ] اصلاح triggerهای workflow یا استفاده از CI موجود در base، سپس اجرای تست‌های source، UI visual و APK روی head تازه.
- [ ] اصلاح harness برای نمایش ردیف واقعی‌ساختار USDT با SVG تتر و لوگوهای دارایی؛ بررسی نهایی computed style تم سوم و اسکرین‌شات‌های جدید.
- [ ] پس از موفقیت build، نصب و تست روی گوشی Android؛ تا آن زمان APK جدید و عملکرد بیومتریک تأییدشده اعلام نمی‌شود.
- [ ] PR #64 همچنان Draft بماند؛ هیچ merge، release، Pages deploy یا تغییر Production بدون تأیید صریح مالک.


## اصلاح هماهنگی تم سوم، نمودارها و آزمون ردیف ثابت تتر — ۲۶ نوامبر ۲۰۲۶
- [x] تم نیلی/آبی یخی در لایهٔ نهایی CSS اکنون متغیرهای اصلی و legacy را به پالت روشن واحد محدود می‌کند؛ از باقی‌ماندن رنگ‌های تیره/بنفش قدیمی در کنترل‌های وابسته جلوگیری می‌شود.
- [x] applyTheme برای تم سوم اکنون color-scheme روشن را روی سند اعمال می‌کند؛ پس‌زمینهٔ نمودار، متن، خطوط شبکه و نوار وضعیت Android با پالت روشن نیلی (#edf2ff) هماهنگ شد.
- [x] harness تصویری، ردیف ثابت USDT را پیش از سایر دارایی‌های بازار با SVG اختصاصی تتر (#26A17B)، نمایش peg دلاری و تومان درج می‌کند؛ تعداد ردیف بازار در fixture از ۸ به ۹ تغییر کرد.
- [x] آزمون‌های source-level به‌جای تأیید پالت تیرهٔ قدیمی، آخرین بلوک مؤثر تم سوم را کنترل می‌کنند و تطبیق palette نمودار و fixture تتر را بررسی می‌کنند.
- [ ] اجرای واقعی Node tests، Playwright screenshots و APK روی GitHub Actions هنوز باید از مسیر workflowهای موجود در base یا مسیر CI مجاز تأیید شود؛ صرف تغییر کد به معنی موفقیت تست نیست.
- [ ] همگام‌سازی دو commit جدید Main همچنان بدون merge/rebase کور و بدون تغییر Main پیگیری می‌شود؛ PR #64 Draft باقی می‌ماند.
- ایمنی: فقط فایل‌های UI، آزمون و مستندات در شاخهٔ Draft تغییر کردند؛ هیچ merge، انتشار، Pages deploy، Supabase، migration یا تغییر Production انجام نشد.

- [x] trigger شاخهٔ push در workflow APK از نام شاخهٔ قدیمی به شاخهٔ فعال PR #64 اصلاح شد و workflow_dispatch نیز برای استفاده پس از در دسترس قرارگرفتن workflow در base افزوده شد.
- [!] این اصلاح به‌تنهایی workflow را روی PR فعلی اجرا نمی‌کند؛ فایل workflow هنوز فقط در head PR موجود است و نتیجهٔ Actions همچنان باید از workflow موجود در base یا پس از فعال‌شدن فایل در base دریافت شود.


### Checkpoint پس از اصلاحات تم سوم و fixture تتر — ۲۶ نوامبر ۲۰۲۶
- HEAD شاخه و PR #64: `2d6c875bd416c1055ab7470aa5d161ef15a1e041`.
- PR #64 باز، Draft و ادغام‌نشده است؛ compare با Main همچنان ۸۱ commit جلو و ۲ commit عقب (`diverged`) و `mergeable=false`.
- بازخوانی GitHub تأیید کرد همهٔ اصلاحات ثبت شده‌اند: پالت نمودار نیلی روشن، color-scheme روشن، متغیرهای نهایی CSS، fixture ردیف اول USDT با SVG سبز تتر، تست‌های جدید و اصلاح شاخهٔ trigger ساخت APK.
- برای SHA نهایی هیچ workflow run در دسترس این اتصال برنگشت؛ بنابراین Node/Playwright/APK هنوز اجراشده یا موفق محسوب نمی‌شوند.
- گام بعد: اجرای تست‌ها از محیط CI معتبر/موجود در base، بررسی تصاویر واقعی و سپس ساخت APK candidate. PR همچنان Draft؛ بدون merge یا Production action.


## اصلاح لایه‌های قدیمی تم نیلی/آبی یخی — ۲۶ نوامبر ۲۰۲۶
- [x] بازبینی selectorهای قدیمی نشان داد کارت‌های خلاصه دارایی، ردیف‌های تنظیمات و جدول تاریخچه در بلوک‌های بعدی CSS دوباره به پالت تیره/بنفش برمی‌گشتند؛ همچنین Hero داشبورد و صحنه ورود هنوز طیف آبی آسمانی پررنگ داشتند.
- [x] لایه نهایی CSS به انتهای src/digiarz-independent-ui.css اضافه شد تا کارت‌های خلاصه دارایی، تنظیمات و تاریخچه به سطوح سفید شیشه‌ای با مرزبندی نیلی و متن تیره تبدیل شوند.
- [x] رنگ سرستون‌ها، ردیف‌های زوج/hover جدول تاریخچه و انتخابگر فعال تم سوم به پالت نیلی روشن تغییر کرد.
- [x] Hero داشبورد و صحنه بصری ورود از گرادیان آبی آسمانی به سفید یخی/نیلی روشن اصلاح شدند؛ فرم ورود و ورودی‌های آن نیز سطح روشن هماهنگ گرفتند.
- [x] تست رگرسیون منبع به tests/independent-ui.test.js اضافه شد تا وجود لایه نهایی و selectorهای کلیدی تم سوم را کنترل کند.
- [x] بررسی ایستای فایل‌های دریافت‌شده از GitHub: توازن آکولادهای CSS برابر صفر اختلاف است؛ تمام tokenهای اصلی override نهایی و تست رگرسیون در شاخه وجود دارند.
- [!] این بررسی ایستا است؛ Node tests، Playwright screenshotها و computed style مرورگر هنوز روی HEAD جدید اجرا نشده‌اند. وجود selector در CSS به‌تنهایی نتیجه بصری نهایی را ثابت نمی‌کند.
- [x] commitهای کد: ef761602cb321313812082b92e046da9377cdc37 و d444d1e668c2c001ca8705f5ecff428148207c3f.
- [x] compare فعلی شاخه با Main: ۸۴ commit جلو، ۲ commit عقب، وضعیت diverged.
- [!] برای commit تست جدید هیچ workflow run برگشتی وجود ندارد؛ CI/APK تأییدشده نیست.
- [ ] گام بعد: اجرای Node regression و Playwright از مسیر CI معتبر، بازبینی اسکرین‌شات تم سوم و مقایسه با تم دوم، سپس بررسی یکپارچگی داشبورد/بازار در هر سه تم.
- ایمنی: فقط stylesheet، تست و این مستندات در شاخه Draft تغییر می‌کنند؛ هیچ merge، release، Pages deploy، Supabase، migration یا تغییر Production انجام نشد.


## فعال‌سازی مسیر تست روی push شاخه candidate — ۲۶ نوامبر ۲۰۲۶
- [x] workflow بازبینی بصری UI به‌روزرسانی شد تا pushهای شاخه redesign/ui-mainline-clean-2026-11-26 را نیز دریافت کند.
- [x] اجرای تست‌های منبع Node با دستور node --test برای independent-ui، index-syntax و service-worker پیش از نصب Playwright به workflow اضافه شد.
- [x] تغییر workflow در commit 8257c2797dadd82322a38319f3d42c0d484ea3f0 ثبت شد.
- [!] بررسی اجراهای متصل به این SHA هنوز workflow run برنگرداند؛ بنابراین نمی‌توان گفت workflow اجرا شده یا تست‌ها موفق‌اند. باید وضعیت Actions در GitHub نیز بررسی شود؛ احتمال دارد اجرای workflow برای این شاخه/مخزن غیرفعال یا در دسترس اتصال نباشد.
- [x] compare تازه: شاخه ۸۶ commit جلو و ۲ commit عقب از Main، وضعیت diverged؛ همگام‌سازی انجام نشد تا از merge/rebase ناخواسته جلوگیری شود.
- [ ] گام بعد: دریافت نتیجه واقعی Actions؛ در صورت نبود اجرا، بررسی تنظیمات Actions و workflowهای base با دسترسی مجاز، سپس اجرای visual screenshotها و build APK candidate.
- ایمنی: فقط workflow تست و مستندات در شاخهٔ PR تغییر کردند؛ Main، Production، Supabase، migration و انتشار دست‌نخورده‌اند.


## بازبینی مجدد وضعیت PR #64 و مسیر CI — ۲۶ نوامبر ۲۰۲۶
- [x] وضعیت زندهٔ PR #64 از GitHub خوانده شد: باز، Draft، ادغام‌نشده؛ head برابر `6d1d39bcdc7cb38e2795c35cb2259559a88bdf8b` و base برابر `9855d6ea6cd188a5621c4e2c28c55e4cfb4d2587` در متادیتای PR است.
- [x] compare تازه با شاخهٔ جاری Main نشان داد ۸۷ commit جلو و ۲ commit عقب، وضعیت `diverged` و `mergeable=false`. دو commit جدید Main از آخرین merge-base آمده‌اند؛ هیچ merge/rebase انجام نشد.
- [x] workflowهای `ui-visual-review.yml` و `android-candidate-apk.yml` در head شاخه وجود دارند؛ trigger push هر دو به نام شاخهٔ فعال اشاره می‌کند.
- [!] فایل `ui-visual-review.yml` در `main` یافت نشد (404)، پس workflow تازه‌افزوده‌شده در base موجود نیست. wrapper اجراهای commit فقط runهای PR-triggered را برمی‌گرداند و برای head فعلی آرایهٔ خالی داد؛ combined status نیز check ثبت‌شده‌ای برای این SHA برنگرداند. بنابراین عدم مشاهدهٔ run در این اتصال، اثبات قطعی عدم اجرا در GitHub نیست، اما هیچ CI موفقی برای head فعلی قابل تأیید نیست.
- [!] وجود workflow در head به‌تنهایی اجرای push را اثبات نمی‌کند؛ APK قبلی/قدیمی را نباید به‌عنوان خروجی این head معرفی کرد. ساخت APK جدید، screenshotهای Playwright و تست فیزیکی Android هنوز تأیید نشده‌اند.
- [ ] گام بعد: یافتن مسیر معتبر اجرای workflow روی head بدون تغییر Main یا ادغام PR؛ سپس اجرای Node regression، گرفتن و بازبینی screenshotهای هر سه تم و ساخت APK candidate از همین SHA.
- ایمنی: این checkpoint فقط مستند وضعیت است؛ هیچ کد اجرایی، Main، PR state، Pages، Supabase، Production، migration، wallet، order یا trade تغییر نکرد.


## اصلاح دقت شبیه‌سازی تم سوم در تست تصویری و بازبینی CI — ۲۶ نوامبر ۲۰۲۶
- [x] وضعیت زندهٔ PR #64 بازخوانی شد: باز و Draft است؛ عنوان «Port premium three-theme UI rebuild onto current main». متن PR در زمان ایجاد، merge-base را 9855d6ea6cd188a5621c4e2c28c55e4cfb4d2587 ثبت کرده بود.
- [x] compare تازهٔ main...redesign/ui-mainline-clean-2026-11-26: شاخه ۸۸ commit جلو و ۲ commit عقب، وضعیت diverged؛ Main فعلی روی 6916b940f63877f0f2589ad1652791b85e01d823 است و merge-base همان 9855d6e مانده است. هیچ همگام‌سازی، merge یا rebase انجام نشد.
- [x] بازبینی workflowها تأیید کرد هر دو workflow تست بصری و APK فقط در شاخهٔ PR وجود دارند و در main وجود ندارند. workflowهای تازه در base حاضر نیستند؛ trigger pull_request از این جهت قابل اتکا نیست و workflow_dispatch نیز از این اتصال قابل فراخوانی نیست. ابزار GitHub موجود فقط اجراهای PR-triggered یک commit را برمی‌گرداند و ابزار فهرست‌کردن/dispatch تمام workflow runها در دسترس نیست.
- [!] برای HEAD قبلی 6d1d39bcdc7cb38e2795c35cb2259559a88bdf8b، combined status خالی و wrapper workflow runها نیز خالی بود؛ این فقط یعنی اجرای موفق قابل تأیید نیست، نه اثبات قطعی اینکه GitHub Actions هیچ اجرا نداشته است.
- [x] ممیزی harness تصویری یک ایراد واقعی یافت: در زمان capture، تم سوم (luxury) به‌اشتباه document.documentElement.style.colorScheme='dark' می‌گرفت، درحالی‌که پالت تم سوم روشن نیلی/یخی است. خط به شرط درست تغییر کرد تا فقط تم مشکی dark و هر دو تم روشن light بگیرند.
- [x] اصلاح harness در commit f57db07bac3460d8d6060b94daf7aa8b8ea42b9b ثبت شد و تست رگرسیون محافظ در commit 05c1a1ea8c286af24f1595b0a8db374292a8aaeb اضافه شد.
- [!] harness هنوز fixtureهای مصنوعی DOM را به کار می‌برد؛ لوگوی تتر در آن SVG سبز اختصاصی است، اما برای بیشتر ارزها glyph متنی (مانند ₿ و ◆) استفاده می‌شود. این تصاویر صحت لوگوهای واقعی در داده/رابط زنده را اثبات نمی‌کنند و باید در مرحلهٔ visual review از placeholderها تفکیک شوند.
- [!] تست‌های Node، Playwright، screenshots و APK پس از این دو commit هنوز اجرا/موفقیت‌شان از GitHub قابل تأیید نیست. package.json فقط build:web و prepare:android را تعریف می‌کند؛ APK نیازمند اجرای واقعی زنجیرهٔ Capacitor/Gradle در محیط Android است.
- [ ] گام بعد: یافتن راه معتبر اجرای push workflow و دریافت artifact بدون افزودن workflow به Main؛ سپس اجرای Node regression، Playwright و APK روی HEAD تازه و بازبینی screenshotها. اگر GitHub Actions برای push شاخه اجرا نمی‌شود، برای فعال‌سازی مسیر base باید از مالک اجازهٔ اقدام مشخص در تنظیمات/شاخهٔ Main گرفته شود؛ تا آن زمان هیچ merge یا تغییر Main انجام نشود.
- ایمنی: فقط harness تست، تست رگرسیون و مستندات در شاخهٔ Draft تغییر کردند؛ Main، Pages، Supabase، Production، migration، کیف پول، سفارش و معامله دست‌نخورده‌اند.


## تأیید نهایی اصلاح harness — ۲۶ نوامبر ۲۰۲۶
- [x] assertion تست رگرسیون بازبینی شد؛ به‌جای regex مبهم، اکنون دقیقاً وجود عبارت تنظیم color-scheme صحیح را در فایل harness بررسی می‌کند.
- [x] commit اصلاح assertion: 3573d0331af1ab23eba9df113a2d613e3b510e29.
- [!] compare بلافاصله پیش از این اصلاح: ۹۱ commit جلو و ۲ commit عقب؛ با این commit تست و checkpoint مستندات جدید، شمارش جلوتر از Main افزایش می‌یابد. این اختلاف فقط تغییرات شاخهٔ candidate را نشان می‌دهد و هیچ merge/rebase صورت نگرفته است.
- [!] combined status و wrapper اجراهای PR برای commit مستندات قبلی خالی بودند؛ هیچ نتیجهٔ CI برای کد جدید قابل تأیید نیست. تست محلی نیز در این محیط اجرا نشده است.
- [ ] گام بعد: بررسی اجرای واقعی Actions و گرفتن screenshots/APK از آخرین HEAD؛ در صورت نبود مسیر قابل دسترسی، باید اجرای workflow از GitHub UI یا فعال‌سازی کنترل‌شدهٔ Actions توسط مالک انجام شود. هیچ تغییر Main/Production بدون تأیید انجام نمی‌شود.


## بازبینی تکمیلی مسیر اجرا و بستهٔ اندروید — ۲۶ نوامبر ۲۰۲۶
- [x] آخرین فایل‌های workflow، harness تصویری، package.json، capacitor.config.json و اسکریپت نصب پل native دوباره از شاخه خوانده شدند.
- [x] برخلاف برداشت قبلی، workflow تصویری و APK هر دو trigger صریح push روی شاخهٔ candidate دارند؛ پس صرفاً نبود workflow در main مانع اجرای push روی شاخه نیست. workflow تصویری paths شامل tests/** است و اصلاح تست commit 3573d03 باید trigger را پوشش دهد. workflow APK نیز مسیرهای src/**، android-native/**، scripts/** و package.json را پوشش می‌دهد.
- [!] ابزار متصل fetch_commit_workflow_runs فقط اجراهای pull_request را برمی‌گرداند و combined status خالی نیز نبود اجرای push را ثابت نمی‌کند. بنابراین وضعیت push workflow هنوز از این اتصال قابل مشاهده/تأیید نیست؛ به‌جای نتیجه‌گیری اشتباه، به عنوان محدودیت مشاهده ثبت شد.
- [x] پیکربندی build اندروید شامل Capacitor 6.2.1، appId برابر com.digiarz.app، webDir برابر www و Java 17 است. workflow مراحل build:web، cap add android، نصب پل بیومتریک، cap sync و assembleDebug را تعریف می‌کند.
- [!] APK هنوز artifact تأییدشده نیست؛ workflow فقط تعریف شده و اجرای موفق/فایل خروجی از GitHub قابل مشاهده نیست. نصب و تست واقعی روی دستگاه هم انجام نشده است.
- [!] بازبینی harness نشان می‌دهد fixtureهای بازار/داشبورد/دارایی‌ها مصنوعی‌اند و برای هفت/هشت ارز از glyph متنی استفاده می‌کنند؛ اسکرین‌شات‌ها فقط ساختار/پوستهٔ UI را ارزیابی می‌کنند، نه صحت لوگوها یا دادهٔ زنده. تتر با SVG اختصاصی در fixture نمایش داده شده است.
- [ ] گام بعد: با دسترسی به فهرست همهٔ workflow runها یا اجرای دستی workflow در GitHub UI، وضعیت run commit مربوط به tests/** را بازیابی کنیم؛ سپس artifact 66 screenshot را دانلود و بازبینی کنیم. پس از تأیید تست UI، workflow APK را اجرا و SHA-256 و BUILD-INFO را کنترل کنیم.
- ایمنی: این مرحله فقط بازبینی read-only و ثبت مستندات بود؛ هیچ فایل اجرایی، Main، PR state، Pages، Supabase، Production، migration، سفارش یا معامله تغییر نکرد.


## اصلاح تست‌های UI و بازیابی artifactها — ۲۶ نوامبر ۲۰۲۶
- [x] مسیر واقعی GitHub Actions از REST API بازیابی شد؛ برخلاف محدودیت wrapper قبلی، push runها و artifactهایشان قابل مشاهده بودند.
- [x] اجرای UI قبلی روی commit `83dab6d286c3fce761bbc5e1af4b4e79671871e0` موفق بود: Playwright همهٔ ۶۶ تصویر را ثبت و artifact `DigiArz-UI-visual-review` با شناسه `15111190348` ایجاد کرد.
- [x] اجرای APK روی commit `ef761602cb321313812082b92e046da9377cdc37` موفق بود: artifact `DigiArz-Candidate-Android-debug-APK` با شناسه `15114799839` ایجاد شد. فایل APK واقعی بازیابی شد؛ نسخه `1.0.0`، workflow run `45817559554` و SHA-256 برابر `15f6455eb2e33916ee697774244a2c0ebc8271a3a4130e435498ded8235a70f9` است. این APK از کد برنامهٔ commit فوق ساخته شده؛ نصب فیزیکی روی دستگاه هنوز تأیید نشده است.
- [x] بازبینی نمونه‌ای از تصاویر موبایل انجام شد. تم سوم در تصاویر خروجی روشن نیلی/یخی است و از تم مشکی متمایز دیده می‌شود؛ با این حال harness از داده‌های ساختگی و glyphهای متنی برای بیشتر لوگوها استفاده می‌کند، بنابراین تأیید لوگوهای واقعی/دادهٔ زنده نیست و polish نهایی چیدمان باید پس از اجرای تازه ادامه یابد.
- [x] لاگ اجرای UI روی commit `3573d0331af1ab23eba9df113a2d613e3b510e29` نشان داد ۱۲۰ از ۱۲۲ تست موفق و دو تست به‌دلیل assertionهای منسوخ شکست خورده‌اند: انتظار پالت قدیمی تیره برای تم سوم و انتظار الگوی قدیمی assignment در harness.
- [x] دو assertion در `tests/independent-ui.test.js` با رفتار واقعی کد هماهنگ شدند: پالت نمودار تم سوم `#edf2ff/#202b55/#dbe4ff/#b9c7ef` و ساخت ردیف بازار با tetherRow پیش‌گذاشته‌شده.
- [x] commit اصلاح اول `aacef29b339f66ae208c760ff4639c9d69096a23` به‌علت escape نادرست regexها همچنان شکست خورد؛ این شکست نیز ثبت شد و به‌عنوان موفقیت گزارش نشد.
- [x] commit اصلاح نهایی `7e278642c05c956bb9276b4e15d79290e40fa027` با assertionهای literal ثبت شد. اجرای push شماره `45822362280` تا زمان ثبت این checkpoint مرحلهٔ ۱۲۲ تست منبعی را با موفقیت گذرانده و در مرحلهٔ Playwright capture در حال اجراست؛ نتیجهٔ نهایی و artifact تازه هنوز تأیید نشده‌اند.
- [ ] پس از پایان run `45822362280`، نتیجه و artifact ۶۶ تصویر را بازیابی و بازبینی کنیم؛ سپس workflow APK را روی HEAD به‌روز اجرا/تأیید کنیم تا APK با آخرین commit شاخه منطبق باشد.
- ایمنی: فقط تست‌ها و این مستندات در شاخهٔ Draft تغییر می‌کنند؛ هیچ merge/rebase، تغییر Main، انتشار Pages، Supabase، Production، migration، wallet، order یا trade انجام نشده است.


## نتیجه اجرای تست و بازبینی وضعیت شاخه — ۲۶ نوامبر ۲۰۲۶
- [x] اجرای UI push run شماره `45822362280` روی commit `87a6bc663675c36a47c0dff94223f4928d13d428` با نتیجه `success` پایان یافت؛ مرحله Node regression و Playwright capture و بارگذاری artifact موفق گزارش شدند.
- [x] artifact تصویری تازه با شناسه `15118652157` و نام `DigiArz-UI-visual-review` ایجاد شد؛ حجم حدود 21.3 MB و ۶۶ تصویر طبق harness. تصاویر از fixtureهای ساختگی DOM-only استفاده می‌کنند.
- [!] commit نهایی‌تر تست‌ها `7e278642c05c956bb9276b4e15d79290e40fa027` نیز workflow جداگانه `45822444984` را trigger کرده است؛ در زمان این ثبت، تست منبعی آن موفق شده اما نصب Chromium هنوز در حال اجراست. نتیجهٔ نهایی این اجرای دوم هنوز تأیید نشده است.
- [x] compare تازهٔ شاخه با Main: ۹۸ commit جلو، ۲ commit عقب، وضعیت diverged؛ PR #64 همچنان باز و Draft است. هیچ merge یا rebase انجام نشده است.
- [ ] پس از پایان run `45822444984`، نتیجه نهایی آن را ثبت کنیم. سپس در صورت نیاز workflow APK را برای آخرین HEAD به‌صورت مستقل اجرا کنیم؛ APK موجود از نظر فایل‌های اجرایی با این تغییرات تست/مستندات هم‌کد است، اما SHA provenance آن به commit `ef761602...` تعلق دارد.
- ایمنی: فقط تست و مستندات در شاخهٔ candidate تغییر کرده‌اند؛ Main، Production، Supabase، Pages، migration، wallet، order و trade دست‌نخورده‌اند.


## یکپارچه‌سازی سطوح معاملات تم سوم — ۲۶ نوامبر ۲۰۲۶
- [x] artifact اجرای موفق UI شماره `45822444984` روی commit `7e278642c05c956bb9276b4e15d79290e40fa027` بازیابی شد؛ هر ۱۲۲ تست منبعی، Chromium، ثبت ۶۶ تصویر و آپلود artifact موفق شدند.
- [x] بازبینی واقعی تصاویر موبایل نشان داد تم سوم در بازار/فهرست دارایی‌ها روشن و نیلی است، اما کارت‌های معامله، orderbook، شاخص‌ها و نواحی نمودار هنوز از پس‌زمینه‌های legacy تیره استفاده می‌کنند.
- [x] اصلاح CSS روی شاخهٔ candidate ثبت شد: commit `d1bcc43e1d368df93eab8b1ddeb1c17a8aef8a6f`. سطوح معامله، سفارش، شاخص‌ها، کارت‌های عمومی و پنل‌های نمودار به سطوح سفید شیشه‌ای نیلی تغییر داده شدند؛ بازه‌های زمانی و دکمه‌های نوع نمودار نیز حالت فعال نیلی روشن دارند.
- [ ] اجرای CI تازه روی commit اصلاح CSS را بررسی و تصاویر تازهٔ موبایل/دسکتاپ را بازبینی کنیم؛ هنوز ادعای موفقیت بصری برای این اصلاح ثبت نمی‌شود تا screenshot جدید دیده شود.
- [ ] پس از تأیید بصری، APK جدید از HEAD بسازیم و artifact را تأیید کنیم.
- ایمنی: تغییر فقط CSS در شاخهٔ Draft است؛ هیچ merge/rebase یا تغییر Main/Production/Supabase انجام نشده است.


## تأیید CI و خروجی‌های هم‌نسخه با اصلاح تم سوم — ۲۶ نوامبر ۲۰۲۶
- [x] اجرای UI شماره `45823319520` روی commit `d1bcc43e1d368df93eab8b1ddeb1c17a8aef8a6f` با نتیجه success پایان یافت؛ تست‌های منبعی، نصب Chromium، ثبت تصاویر و بارگذاری artifact موفق شدند.
- [x] artifact تصویری `DigiArz-UI-visual-review` شناسه `15118534104`، حجم 22,929,991 بایت، digest برابر `sha256:0e495762dd3abffc47d2b8dee73e71911b051a93b72b430b8beb2800272df59c`؛ شامل ۶۶ تصویر (۲ viewport × ۳ تم × ۱۰ بخش به‌علاوهٔ close-upهای بازار/داشبورد).
- [x] بازبینی انسانی تصاویر انجام شد. تم سوم در صفحات بازار و داشبورد روشن/نیلی است؛ ردیف USDT بالای لیست و لوگوی سبز تتر در fixture دیده می‌شود. در صفحهٔ معاملات، بعضی نوارهای تبلیغ/hero قدیمی هنوز سرمه‌ای‌اند و نمودارها در fixture خالی هستند؛ بنابراین یکپارچگی کامل بصری و کارکرد نمودار از این تست اثبات نمی‌شود و نیازمند اصلاح بعدی است.
- [x] README artifact تأیید می‌کند درخواست‌های Supabase مسدود شده و داده‌های بازار/داشبورد/دارایی fixture ساختگی‌اند؛ این تصاویر صحت دادهٔ زنده و لوگوی رسمی همهٔ دارایی‌ها را اثبات نمی‌کنند.
- [x] اجرای APK شماره `45823319523` روی همان commit با نتیجه success پایان یافت؛ artifact `DigiArz-Candidate-Android-debug-APK` شناسه `15118374282`، حجم ZIP برابر 3,688,529 بایت.
- [x] APK بازیابی و از داخل ZIP استخراج شد: `DigiArz-candidate-d1bcc43e-debug.apk`، حجم 4,136,157 بایت، نسخه 1.0.0، commit سازنده `d1bcc43e1d368df93eab8b1ddeb1c17a8aef8a6f`، workflow run `45823319523`، SHA-256 برابر `99e4c5e3e8f68c7bd98c96b91463cd9b02cee34b083bfa16bf2e701ac23524de`.
- [ ] نصب فیزیکی APK روی گوشی، بررسی ورود/بیومتریک، نمودارها، ناوبری و رفتار واقعی بازار هنوز انجام نشده است.
- [ ] اصلاح نوارهای سرمه‌ای باقی‌مانده در صفحهٔ معامله و بازبینی مجدد screenshotها؛ سپس build نهایی candidate APK.
- وضعیت مخزن پس از ثبت خروجی‌ها: PR #64 باز و Draft؛ HEAD فعلی مستندات `c4573e407c4904b883dfa899d5e49996e6039ca1`، شاخه ۱۰۱ commit جلو و ۲ commit عقب از Main، diverged. APK و تصاویر از commit کد `d1bcc43...` ساخته شده‌اند؛ commit بعدی فقط مستندات بوده است.
- ایمنی: هیچ merge/rebase، تغییر Main/Production، Supabase، migration یا انتشار انجام نشده است.


## اصلاح باقی‌ماندهٔ Heroهای سرمه‌ای در تم سوم — ۲۶ نوامبر ۲۰۲۶
- [x] بازبینی تصاویر artifact `15118534104` نشان داد پنل‌های `market-hero-v34` و `trade-workspace-banner-v35` هنوز گرادیان سرمه‌ای legacy داشتند؛ فرم‌ها و بیشتر کارت‌ها روشن شده بودند اما این دو banner استثنا بودند.
- [x] CSS هدفمند برای هر دو کلاس اضافه شد: گرادیان سفید/یخی با هالهٔ نیلی ملایم، متن نیلی تیره، badgeهای شیشه‌ای روشن و حذف پس‌زمینهٔ navy. commit `9d3dc1b80811dc3c3a8590191754a41e98af9f43`.
- [ ] اجرای تازهٔ screenshot و APK روی این commit را بررسی کنیم؛ تا مشاهدهٔ خروجی جدید، رفع بصری این دو بخش تأییدشده محسوب نمی‌شود.
- [ ] نصب واقعی APK روی دستگاه و تست عملی ورود/بیومتریک، نمودار و ناوبری هنوز لازم است.
- APK هم‌نسخهٔ commit قبلی `d1bcc43...` در دسترس است؛ SHA-256: `99e4c5e3e8f68c7bd98c96b91463cd9b02cee34b083bfa16bf2e701ac23524de`. این فایل شامل اصلاح جدید bannerها نیست و صرفاً candidate مرحلهٔ قبلی است.
- ایمنی: فقط CSS و این گزارش در شاخهٔ Draft تغییر کرده‌اند؛ هیچ merge/rebase، Main، Production، Supabase یا انتشار تغییر نکرده است.


## نتیجهٔ بازبینی اصلاح دوم تم سوم و APK جدید — ۲۶ نوامبر ۲۰۲۶
- [x] UI visual review run `45823862255` روی commit `9d3dc1b80811dc3c3a8590191754a41e98af9f43` با موفقیت پایان یافت؛ artifact `15118549180` با digest `sha256:df385cf7272c29d8fc9221d2b1f7e41feaa58308ed0206fb22c950a27fb1995c`.
- [x] بازبینی `desktop-luxury-trade.png` تأیید می‌کند بنر اصلی «میز معامله حرفه‌ای» اکنون روشن و نیلی است؛ ردیف بازار موبایل نیز چیدمان روشن و لوگوی Tether در ردیف نخست را نشان می‌دهد.
- [ ] در همان تصویر دسکتاپ، یک پنل مدیریت ریسک/سناریو در پایین صفحه هنوز سرمه‌ای است؛ این مورد با دو کلاس hero قبلی پوشش داده نشده و باید کلاس دقیق آن از DOM/JS پیدا و در تم سوم روشن شود.
- [ ] تصویر موبایل معامله فضای خالی بزرگی در ناحیهٔ نمودار نشان می‌دهد؛ README و fixture تست، درخواست‌های Supabase را مسدود کرده‌اند، بنابراین دادهٔ زنده و نمودار واقعی از این screenshot قابل تأیید نیست.
- [x] APK workflow `45823862251` با موفقیت پایان یافت؛ artifact `15120035456`، build info تأیید می‌کند commit `9d3dc1b80811dc3c3a8590191754a41e98af9f43` و run `45823862251`.
- [x] APK استخراج شد: `app-debug.apk`، نسخه 1.0.0، حجم 4,136,411 بایت، SHA-256 `d88f5df382812c2b78b103f7e49421baccf2679423a200229852f4b1f46a71f5`.
- [ ] نصب فیزیکی روی گوشی و تست عملی بیومتریک/ورود/ناوبری/نمودار هنوز انجام نشده است.
- وضعیت ایمنی: فقط شاخهٔ مستقل و Draft به‌روزرسانی شده؛ هیچ merge/rebase، Main/Production، Supabase یا انتشار تغییری نکرده است.


## نتیجهٔ نهایی اصلاح پنل‌های معامله و قیمت — ۲۶ نوامبر ۲۰۲۶
- [x] UI visual review run `45825892090` روی commit `8f692f1c32f722a369d3a7b12109fe8a1d7ada67` با موفقیت پایان یافت؛ artifact `15119678093`، digest `sha256:1ca4b90f43c5738fababbec5f01b387f04392d0934d152d7aedeaa5d882cc327`.
- [x] APK workflow `45825892142` موفق شد؛ artifact `15120487116`، build info commit `8f692f1c32f722a369d3a7b12109fe8a1d7ada67`، نسخه 1.0.0، حجم APK برابر 4,137,112 بایت، SHA-256 `3f733cc9201aaae801d90da83bf76ab86cc59385c963e40c3ceedf90745f8eed`.
- [x] بازبینی screenshot دسکتاپ تم سوم تأیید می‌کند سه کارت «آخرین قیمت / بیشترین قیمت نمودار / کمترین قیمت نمودار» از پنل سرمه‌ای به سفید یخی تغییر کرده‌اند؛ پنل مدیریت استراتژی نیز روشن است. اصلاح اصلی روی selector دقیق `.market-summary .stat` و پس‌زمینهٔ والد `.market-summary` اعمال شد.
- [x] پنل‌های دیگر سفارش/ریسک/استراتژی و hero نیز در تست تصویری روشن و هماهنگ دیده می‌شوند.
- [ ] هنوز بخش‌های ورودی/فرم و بعضی سطوح داخلی بازار سفارش، داده‌های ساختگی/placeholder دارند؛ fixture تست اتصال Supabase را مسدود می‌کند، پس داده زنده/نمودار زنده تأیید نشده است.
- [ ] نصب APK روی گوشی واقعی، تست login/biometric، ناوبری و تعامل واقعی همچنان باقی است.
- وضعیت شاخه: PR #64 باید Draft و ادغام‌نشده باقی بماند؛ هیچ merge/rebase، Main، Production، Supabase یا انتشار انجام نشده است.


## ادامهٔ بررسی و تأیید artifactهای UI/APK — ۲۶ نوامبر ۲۰۲۶
- [x] وضعیت واقعی PR #64 بازخوانی شد: Draft و ادغام‌نشده؛ شاخه `redesign/ui-mainline-clean-2026-11-26`، HEAD برابر `d20a8b5141d7f6715eaf110aa0fcf86a73df1647` و والد مستقیم آن commit کد `8f692f1c32f722a369d3a7b12109fe8a1d7ada67` است؛ commit HEAD فقط همین گزارش وضعیت را تغییر داده و کد UI/APK همان کد commit 8f692f1 است.
- [x] مقایسه با Main: صفر commit عقب، ۱۱۰ commit جلو؛ GitHub در snapshot فعلی وضعیت mergeability را `dirty / mergeable=false` گزارش کرده است. این وضعیت باید پیش از هر تصمیم ادغام جداگانه بررسی شود؛ هیچ ادغامی انجام نشود.
- [x] UI Visual Review run `45825892090` روی commit کد `8f692f1` موفق شد؛ artifact `15119678093` شامل ۶۶ تصویر، حجم ZIP حدود 22.7 MB.
- [x] Android Candidate APK run `45825892142` روی همان commit موفق شد؛ artifact `15120487116` دریافت و محتوای ZIP بررسی شد.
- [x] APK استخراج و شناسایی شد: `app-debug.apk`، نسخه 1.0.0، حجم 4,137,112 بایت، SHA-256 برابر `3f733cc9201aaae801d90da83bf76ab86cc59385c963e40c3ceedf90745f8eed`. مسیر استخراج‌شده در محیط کاری: `/mnt/data/digiarz_apk_candidate/app-debug.apk`.
- [!] این APK فقط Debug Candidate است، نه نسخهٔ Release امضاشده برای انتشار عمومی. لینک artifact GitHub موقت است و تا ۱۰ دسامبر ۲۰۲۶ اعتبار دارد.
- [ ] آزمون Exact Decimal در آخرین اجرای PR که قابل مشاهده است روی commit قدیمی‌تر `83dab6d` موفق بوده؛ برای commit کد `8f692f1` اجرای تازهٔ مستقل آن در فهرست PR-runها مشاهده نشد. UI Visual Review و APK روی 8f692f1 موفق‌اند.
- [ ] نصب فیزیکی APK روی گوشی Android و بررسی ورود/بیومتریک، ناوبری، صفحات و داده‌های واقعی بازار/کیف پول همچنان باقی است. تصاویر بصری با fixture ساختگی تولید شده‌اند و صحت داده زنده را ثابت نمی‌کنند.
- [ ] پیش از ادغام، علت `mergeable=false / dirty` روشن و وضعیت تست Exact Decimal روی head جاری تکمیل شود.
- ایمنی: فقط فایل وضعیت در شاخه Draft به‌روزرسانی می‌شود؛ هیچ Merge، Release، Pages deploy، Supabase، migration یا تغییر Production مجاز/انجام‌شده نیست.


## اصلاح تکمیلی دفتر سفارش تم سوم — ۲۶ نوامبر ۲۰۲۶
- [x] بازبینی artifact تصویری قبلی و CSS نشان داد رنگ‌های legacy داخلی دفتر سفارش (orderbook headers/rows) هنوز نیازمند لایهٔ نهایی مستقل بودند.
- [x] CSS محدود به تم سوم و صفحهٔ معامله اضافه شد تا header و rowهای دفتر سفارش سفید/شیشه‌ای با متن نیلی شوند؛ رنگ‌های معنایی خرید/فروش حفظ شدند.
- [x] تست رگرسیون جدید در `tests/independent-ui.test.js` اضافه شد تا وجود overrideهای دفتر سفارش در لایهٔ نهایی بررسی شود.
- [x] commit CSS: `15ab906a7b2818f8126308cdb13e54376d37eae7`؛ commit تست: `4a6820e5d8d8fa0c974abecceba44bbbdbe50353`.
- [ ] UI screenshot run `45827668888` و APK run `45827668767` روی commit CSS در زمان ثبت این گزارش در حال اجرا هستند؛ اجرای UI روی commit تست `45827673989` در صف است. تا پایان و بازبینی artifact جدید، اصلاح بصری تأیید نهایی محسوب نمی‌شود.
- [ ] Exact Decimal workflow روی head جاری هنوز در runهای تازهٔ مشاهده‌شده ظاهر نشده؛ آخرین موفقیت ثبت‌شده متعلق به commit قدیمی‌تر `83dab6d` است.
- [ ] PR #64 همچنان Draft و ادغام‌نشده است؛ نصب فیزیکی APK و بررسی داده زنده نیز باقی است.
- ایمنی: فقط CSS و تست در شاخهٔ مستقل تغییر کرده‌اند؛ هیچ Merge، Release، Pages deploy، Supabase، migration یا تغییر Production انجام نشده است.


## اصلاح سیستم آیکون و وضعیت فعال ناوبری — ۲۶ نوامبر ۲۰۲۶
- [x] بازبینی artifact موبایل نشان داد fallback آیکون‌ها در حالت نبود کتابخانهٔ Lucide به نویسه‌های ساده (مانند خانه/فلش/مربع) تبدیل می‌شود؛ این عامل بخشی از ظاهر ابتدایی آیکون‌ها بود.
- [x] renderLucideIcons() در index.html به fallback برداری SVG با مسیرهای مشخص برای آیکون‌های اصلی ناوبری و کنترل‌ها تغییر کرد؛ در صورت موجودبودن Lucide همچنان renderer اصلی حفظ می‌شود.
- [x] وضعیت فعال تب خانه در شروع صریح شد و switchTab و setAccountMode علاوه بر کلاس active، ویژگی دسترس‌پذیری aria-current="page" را نیز همگام می‌کنند.
- [x] لایهٔ نهایی CSS برای هر سه تم افزوده شد: آیکون‌های غیرفعال آرام‌تر، آیکون فعال پررنگ‌تر با stroke مشخص، حرکت ظریف، خط انتخاب و پس‌زمینهٔ هماهنگ با تم؛ تم سوم از آبی-نیلی ملایم استفاده می‌کند.
- [x] تست رگرسیون برای fallback برداری، حذف placeholderهای متنی و همگام‌سازی وضعیت فعال به tests/independent-ui.test.js افزوده شد.
- کد در شاخهٔ redesign/ui-mainline-clean-2026-11-26 ثبت شد؛ commitهای این مرحله: b2ea1944ada60b75f6ff8227dd2580400cffea27 (index)، 0b245d3339b963c405b9c7a9b2453df3b43a4796 (CSS)، e60816a4b401791eb2e85f38b36f256e32c7b9e8 (tests).
- [ ] اجرای تازهٔ CI و بازبینی اسکرین‌شات/APK روی HEAD جدید e60816a4b401791eb2e85f38b36f256e32c7b9e8 هنوز تأیید نشده؛ وضعیت checkهای قابل‌دریافت در لحظهٔ ثبت خالی بود.
- [ ] PR #64 همچنان Draft و ادغام‌نشده باقی می‌ماند؛ مقایسهٔ زنده با main در این لحظه ۱۱۷ commit جلو و ۲ commit عقب (diverged) گزارش شد. هیچ rebase/merge یا تغییر Main/Production/Supabase انجام نشده است.
- [ ] نصب APK روی گوشی واقعی و تأیید رفتار فعال‌بودن آیکون‌ها در تعامل واقعی هنوز انجام نشده است.
- اقدام بعدی: تکمیل CI و بررسی artifact تازه روی همین HEAD؛ سپس تحویل APK بازبینی‌شده برای آزمون گوشی واقعی.


## بازبینی بصری و اصلاح قاب ردیف‌های بازار — ۲۶ نوامبر ۲۰۲۶
- [x] وضعیت زنده PR #64 بازخوانی شد: باز، Draft و ادغام‌نشده؛ HEAD برابر `9c6c534c0e0ac115c4783ff75a1f352a65ab8424`؛ شاخه نسبت به Main دارای ۱۲۴ commit جلو و ۲ commit عقب است و GitHub همچنان `mergeable=false` گزارش می‌کند. هیچ rebase یا merge انجام نشد.
- [x] artifact تصویری run `45832803245` (artifact `15123420669`) بررسی شد؛ در تصاویر موبایل مشخص شد اسکرول باقی‌مانده از close-up صفحه بازار/داشبورد، تصاویر صفحات بعدی را از وسط صفحه ثبت می‌کند.
- [x] تابع `resetPageScroll(page)` به harness افزوده شد تا قبل از هر تصویر اصلی، window و همه scroll containerها به ابتدای صفحه بازگردند؛ commit `4bba5b8bf8e0b96fb01f80d30c76b4027d13d452`.
- [x] UI visual run `45850303108` روی همان commit موفق شد؛ artifact `15132478097` شامل ۶۶ تصویر، حجم 23,845,599 بایت، digest برابر `sha256:e1ed0cc28e33408906e6e9240a5510606cd4398edffb61b3a0f1b211fe27b022`. بازبینی نمونه‌های موبایل نشان داد هر سه تم از ابتدای داشبورد ثبت شده‌اند و تم سوم روشن/نیلی است.
- [x] در تصاویر بازار، قاب ظریف دور ردیف دارایی‌ها هنوز دیده می‌شد؛ CSS انتهای لایه مستقل اصلاح شد تا ردیف‌های غیر از تتر در صفحه بازار در هر سه تم border/outline/box-shadow نداشته باشند و پس‌زمینه شفاف بماند؛ hover بسیار ملایم و متناسب با تم حفظ شد. commit `1856f8dab046a13b0e224bdd3527ab0f265b6d1d`.
- [x] تست رگرسیون اختصاصی برای عدم قاب ردیف‌های بازار افزوده شد؛ commit `9c6c534c0e0ac115c4783ff75a1f352a65ab8424`.
- [!] در لحظه ثبت: UI visual run `45850651631` و Android Candidate APK run `45850651655` روی commit CSS `1856f8d` هنوز در حال اجرا هستند؛ UI run `45850688818` برای commit تست `9c6c534` در صف است. تا پایان و بازبینی artifactها نتیجه نهایی اعلام نمی‌شود.
- [x] APK artifact قبلی `15123665127` از run `45832472333` بازیابی و SHA-256 آن بررسی شد: `948b4f462d0284365ca22ab3284289fefb2c5e1441087cb6c8dd5d00f07873e6`. این APK از commit `63ffbad` ساخته شده؛ مقایسه نشان می‌دهد سه commit بعدی تا HEAD فعلی فقط فایل‌های تست را تغییر داده‌اند، نه فایل‌های اجرایی برنامه. بااین‌حال APK جدیدِ شامل CSS حذف قاب باید از run `45850651655` دریافت شود.
- [ ] artifact UI جدید پس از اصلاح قاب‌ها را بازبینی کن؛ به‌ویژه market rows در تم مشکی، سفید و نیلی.
- [ ] APK جدید را پس از موفقیت run دریافت و SHA-256/BUILD-INFO آن را بررسی کن؛ سپس فقط برای آزمون Debug روی گوشی ارائه شود.
- [ ] نصب فیزیکی APK، ورود/خروج، اثرانگشت، ناوبری، داده واقعی بازار و کیف پول همچنان تأییدنشده‌اند.
- ایمنی: تمام تغییرات فقط در شاخه مستقل PR #64 و تست‌های تصویری/کد UI هستند؛ هیچ merge، release، Pages deployment، Supabase، Production، migration، wallet، order یا trade انجام نشده است.


## نتیجهٔ حذف قاب ردیف‌های بازار و APK بازبینی — ۲۶ نوامبر ۲۰۲۶
- [x] UI Visual Review run `45850651631` روی commit CSS `1856f8dab046a13b0e224bdd3527ab0f265b6d1d` با نتیجه success پایان یافت؛ artifact `15133641874` شامل ۶۶ تصویر، حجم 23,933,774 بایت، digest برابر `sha256:d6fadd37eb7754816eb9c660b46b402302bcdd2437c386b08c30869d38f435d2`.
- [x] بازبینی تصاویر موبایل هر سه تم تأیید کرد ردیف‌های بازار دیگر قاب بیرونی، border یا shadow ندارند؛ تتر همچنان با نشان سبز و SVG اختصاصی در بالای فهرست باقی است. تصاویر سایر ارزها در این harness از glyphهای fixture استفاده می‌کنند و لوگوهای واقعی همه دارایی‌ها را تأیید نمی‌کنند.
- [x] Android Candidate APK run `45850651655` روی همان commit با نتیجه success پایان یافت؛ artifact `15132828012`، حجم ZIP برابر 3,693,560 بایت، digest برابر `sha256:9f1dcca0b54c7b321af3d92160b8810ad543266aca4f1c614eb2a667191834a8`.
- [x] APK استخراج و SHA-256 آن با BUILD-INFO تطبیق داده شد: `DigiArz-candidate-frameless-rows.apk`، نسخه 1.0.0، حجم 4,139,659 بایت، source commit `1856f8dab046a13b0e224bdd3527ab0f265b6d1d`، workflow run `45850651655`، SHA-256 `e91ad69bcbe6b1dc08b29bea99c346ec66b269da9266ae0cf16ec868107f9332`.
- [!] UI Visual Review run `45850688818` برای commit تست `9c6c534c0e0ac115c4783ff75a1f352a65ab8424` هنوز در حال اجراست؛ این commit فقط تست رگرسیون را تغییر داده و فایل اجرایی برنامه نسبت به APK ساخته‌شده تغییر نکرده است.
- [ ] نتیجهٔ نهایی run `45850688818` را تأیید و در صورت موفقیت checkpoint را ببند.
- [ ] APK Debug را برای نصب آزمایشی ارائه کن؛ کاربر باید نصب، ورود/خروج، اثرانگشت، ناوبری و صفحات را روی گوشی واقعی بررسی کند. داده زندهٔ بازار/کیف پول از fixtureهای screenshot قابل تأیید نیست.
- [ ] پیش از هر ادغام، دو commit عقب‌ماندگی Main و `mergeable=false` در PR #64 باید در یک برنامهٔ کنترل‌شده بررسی شوند؛ فعلاً Draft باقی بماند.
- ایمنی: هیچ merge، release، Pages deployment، Supabase، Production، migration، wallet، order یا trade انجام نشده است.


### تکمیل اجرای رگرسیون UI روی commit تست نهایی — ۲۶ نوامبر ۲۰۲۶
- [x] UI Visual Review run `45850688818` روی commit `9c6c534c0e0ac115c4783ff75a1f352a65ab8424` با نتیجه success پایان یافت؛ source-level regression، Playwright/Chromium، ثبت ۶۶ تصویر و آپلود artifact همگی موفق شدند.
- [x] artifact نهایی تست `15133567077`، نام `DigiArz-UI-visual-review`، حجم 23,933,822 بایت، digest برابر `sha256:46ee930e35856f8231f7d152679e6036465d6142c6272709928b6eafdd70513e`؛ این commit فقط تست را نسبت به APK ساخته‌شده تغییر داده است.
- [x] checkpoint تست تصویری این مرحله بسته شد؛ UI و APK workflows روی commit CSS موفق‌اند و تست تصویری روی commit تست بعدی نیز موفق است.
- [ ] گام بعد: APK Debug تأییدشده را برای آزمون فیزیکی ارائه کن و نتیجهٔ نصب/ورود/اثر انگشت/ناوبری را از مالک دریافت کن. PR #64 همچنان Draft بماند تا آزمون دستگاه و بررسی divergence/mergeability تکمیل شود.


## حذف قاب لوگو/ستاره و fallback پایدار لوگو — ۲۶ نوامبر ۲۰۲۶
- [x] بازبینی تصاویر واقعی artifact قبلی نشان داد CSS داشبورد هنوز برای لوگوها حلقهٔ سایه‌دار و برای ستارهٔ علاقه‌مندی قاب/پس‌زمینه داشت؛ این با خواستهٔ «لوگو و ستاره بدون قاب» سازگار نبود.
- [x] CSS نهایی هر سه تم اصلاح شد: قاب، outline، shadow و background از لوگوهای داشبورد حذف شد؛ دکمهٔ ستاره نیز بدون قاب و پس‌زمینه است و فقط ستارهٔ انتخاب‌شده رنگ تم را می‌گیرد. ستاره‌های صفحهٔ بازار نیز صریحاً frameless شدند. commit CSS `0a6020309c54b6ae8246499819ee4ad1633d1c9a`.
- [x] تست رگرسیون برای frameless logo/favorite در هر سه تم افزوده شد؛ commit `f9c94cf113fdcea70591e869e7f78601349cad0a`.
- [x] ممیزی منبع لوگوها نشان داد مسیر تولیدی از metadata/image_url، تابع Supabase app-assets و سپس CoinCap استفاده می‌کند؛ ولی اگر هر دو منبع تصویر fail شوند، کد قبلی لوگو را پنهان می‌کرد و فقط یک حرف کم‌رنگ می‌گذاشت.
- [x] تابع `renderCoinLogoFallback` اضافه شد: پس از شکست هر دو منبع، به‌جای فضای خالی، نشان SVG برداری با رنگ شناخته‌شده و نماد کوتاه ارز نمایش داده می‌شود؛ برای BTC/ETH/SOL/BNB/XRP/DOGE/ADA/AAVE و چند دارایی پرکاربرد رنگ‌های مشخص تعریف شد. این نشان جایگزینِ قابل‌تشخیص است، نه ادعای لوگوی رسمی؛ دریافت لوگوی اصلی از منابع موجود دست‌نخورده است. commit `b10e3fea634b313cef07c60324bca0c02df9d0d3`.
- [x] CSS fallback برداری بدون قاب و تست رگرسیون برای عدم مخفی‌شدن لوگو اضافه شد؛ commit CSS `8d9755db97cd06cf4ae27c8d1045c02cd3ea3ee2` و commit تست `79e88872e99e83731d1febaa9893fdeec1f4f9c8`.
- [x] اجرای UI Visual Review روی commit `b10e3fea634b313cef07c60324bca0c02df9d0d3` با نتیجه success پایان یافت؛ artifact `15134460766` (run `45852473182`، ۶۶ تصویر). APK build روی همان commit نیز موفق شد؛ artifact `15134433169` (run `45852473357`).
- [!] اجرای نهایی UI Visual Review برای commit تست `79e88872e99e83731d1febaa9893fdeec1f4f9c8` در لحظهٔ ثبت: source-level regression موفق، Playwright screenshot capture در حال اجرا (run `45852515856`).
- [!] APK شامل CSS نهایی fallback در حال build/verify است (run `45852509484`, source CSS commit `8d9755d`).
- [!] بررسی تصاویر قبلی نشان داد screenshot harness از glyphهای ساختگی استفاده می‌کند و تصاویر آن اثبات لوگوهای واقعی نیستند؛ fallback برداری در برنامهٔ اصلی افزوده شد، اما لوگوهای اصلی بازار فقط پس از اتصال و آزمون واقعی اپ با دادهٔ زنده تأیید می‌شوند.
- [ ] پس از اتمام runها، artifact UI و APK نهایی را دریافت و SHA-256/BUILD-INFO را بررسی کن؛ سپس APK فقط برای تست Debug فیزیکی ارائه شود.
- [ ] PR #64 همچنان Draft و ادغام‌نشده بماند. main فعلی `6916b940f63877f0f2589ad1652791b85e01d823` است، در حالی که base ثبت‌شده PR `9855d6ea6cd188a5621c4e2c28c55e4cfb4d2587` است؛ مقایسهٔ head فعلی با main: ۱۳۲ commit جلو و ۲ commit عقب، merge base برابر `9855d6e`. دو commit جدید main شامل تغییرات `IMPLEMENTATION_STATUS.md` و QA/SQL مربوط به Stop-Limit هستند؛ بدون بررسی و برنامهٔ کنترل‌شده هیچ update/rebase/merge انجام نشود.
- ایمنی: هیچ merge، release، Pages deployment، Supabase، Production، migration، wallet، order یا trade انجام نشده است.


### تأیید نهایی fallback لوگو، frameless UI و APK — ۲۶ نوامبر ۲۰۲۶
- [x] UI Visual Review run `45852515856` روی commit تست `79e88872e99e83731d1febaa9893fdeec1f4f9c8` با نتیجه success پایان یافت؛ source-level regression، Playwright/Chromium و ۶۶ تصویر تکمیل شدند. artifact `15134570757`، حجم 23,933,758 بایت، digest `sha256:3c699a990e886a3576f4f3d2fea8945728fdbb08b7a509eb13d1d4857f604639`.
- [x] Android Candidate APK run `45852509484` روی commit CSS `8d9755db97cd06cf4ae27c8d1045c02cd3ea3ee2` با نتیجه success پایان یافت؛ artifact `15133558941`، حجم ZIP برابر 3,694,427 بایت، digest `sha256:65781fc58a658fc07baf0535fd784c6dcfe721345588bd60514960917d301a8e`.
- [x] APK استخراج و BUILD-INFO بررسی شد: نسخه `1.0.0`، workflow run `45852509484`، build time `2026-11-26T15:49:50Z`، APK size 4,140,443 bytes، SHA-256 `4199f3f01caa93fc52a7e7eab4fe905efe3ff57de711700cd8be0a39d4e112be`. مسیر استخراج‌شده: `/mnt/data/DigiArz-candidate-logo-fallback.apk`.
- [!] artifact تصاویر از fixtureهای DOM ساختگی استفاده می‌کند؛ ۶۶ تصویر برای ساختار و تم‌هاست، نه اثبات دریافت لوگوهای رسمی یا داده‌های زنده. منطق اصلی لوگو اکنون در خطای هر دو provider یک SVG monogram جایگزین رنگی نشان می‌دهد؛ لوگوهای رسمی باید روی گوشی با اتصال واقعی و دادهٔ زنده بررسی شوند.
- [ ] آزمون فیزیکی APK (نصب، ورود/خروج، بیومتریک، ناوبری، هر سه تم، فهرست بازار و لوگوهای واقعی) از سوی مالک باقی است.
- [ ] PR #64 هنوز Draft/open/unmerged است. main روی `6916b940f63877f0f2589ad1652791b85e01d823` قرار دارد و PR base روی `9855d6ea6cd188a5621c4e2c28c55e4cfb4d2587`؛ اختلاف ۲ commit عقب و ۱۳۲ جلو. دو commit جدید main شامل فایل وضعیت و QA/SQL Stop-Limit هستند؛ برای جلوگیری از از دست رفتن آن‌ها، update/rebase/merge انجام نشده است.
- ایمنی: هیچ merge، release، Pages deployment، Supabase، Production، migration، wallet، order یا trade انجام نشده است.


## اصلاح اولویت نام فارسی در جست‌وجوی بازار — ۲۶ نوامبر ۲۰۲۶
- [x] ممیزی کد شاخه نشان داد رندر بازار نام فارسی صریح را نمایش می‌داد، اما مسیر جست‌وجوی بازار همان فیلد `name_fa/asset_name_fa` را به تابع تبدیل آوانویسی انگلیسی می‌داد؛ متن فارسی در آن مسیر می‌توانست به نماد fallback شود و جست‌وجوی نام فارسی بعضی دارایی‌ها را از دست بدهد.
- [x] تابع مشترک `marketPersianName(item)` اضافه شد: ابتدا نام فارسی صریح رکورد را با اولویت `name_fa` سپس `asset_name_fa` می‌خواند؛ مقادیر خالی/فاصله‌ای را رد می‌کند؛ در نبود آن به نام‌های معتبر محلی/شناخته‌شده و سپس آوانویسی نام انگلیسی می‌رسد.
- [x] رندر ردیف‌های بازار، کارت‌های ۱۰ دارایی برتر، فیلتر جست‌وجوی بازار و جست‌وجوی بازار داشبورد به resolver مشترک متصل شدند تا نمایش و جست‌وجو از یک اولویت واحد استفاده کنند. نام انگلیسی و نماد همچنان جداگانه حفظ می‌شوند.
- [x] تغییرات در شاخه مستقل ثبت شد: کد `866c7d4917559eb4ce46429484c12682ba0a044f`؛ تست‌های اولیه `8645f18047f1ef3350d0af5e6f1339aac30e71be`؛ اصلاح قالب تست `80a30b86fd8d5f555a218b4ed530a2865c0e4847`؛ مقاوم‌سازی انتخاب نام خالی `641bf87acc6301db4bf38fef1a5257ccf091b590`؛ تست نهایی `9092ba21dc37f3e12a5214bbd86ceeaaa1dafa1e`.
- [!] اجرای CI برای HEAD جدید هنوز از وضعیت‌های قابل‌دریافت تأیید نشده است؛ هیچ نتیجه‌ای به‌عنوان موفق اعلام نمی‌شود. باید تست‌های Node و UI Visual Review روی HEAD نهایی اجرا و بررسی شوند.
- [ ] پس از CI، آزمون واقعی نام فارسی و لوگوهای رسمی با داده بازار روی APK و گوشی Android لازم است؛ fixtureهای تصویری، داده زنده را اثبات نمی‌کنند.
- [ ] PR #64 همچنان Draft و ادغام‌نشده باقی می‌ماند. شاخه نسبت به `main` واگراست و دو commit عقب است؛ بدون برنامه و تأیید صریح، rebase/merge انجام نمی‌شود.
- ایمنی: فقط کد فرانت‌اند و تست‌های رگرسیون در شاخه مستقل تغییر کردند؛ هیچ Supabase، Production، migration، wallet، order، trade، deployment یا release تغییر نکرد.


- [x] ممیزی تکمیلی داشبورد: مرتب‌سازی بر اساس نام قبلاً فقط نام محلی مبتنی بر نماد را می‌دید و نام فارسی صریح رکورد را نادیده می‌گرفت؛ اکنون مرتب‌سازی نیز از `marketPersianName(item)` استفاده می‌کند تا با متن نمایشی و جست‌وجو هماهنگ باشد. کد `d40988a9e9f471f219d16cab6599d0eafc3513c7` و تست رگرسیون `c67520646f0963dbf25df2f2d7c006e1286ddb35`.
- [!] workflow بصری روی push به همین شاخه پیکربندی شده است؛ ابزار وضعیت موجود فقط runهای PR-triggered را برمی‌گرداند و در بررسی فعلی status check قابل مشاهده‌ای برای HEAD تازه ثبت نشده است. نتیجهٔ CI تا مشاهدهٔ مستقیم اعلام نمی‌شود.


## بازیابی نام‌های فارسی صرافی‌های ایرانی در شروع بازار — ۲۶ نوامبر ۲۰۲۶
- [x] ممیزی نشان داد نام‌های فارسی صرافی‌های ایرانی از نمای فقط‌خواندنی `market_toman_performance` در صفحهٔ تومانی خوانده می‌شدند؛ اما این صفحه فقط هنگام بازکردن تب «تومان» بارگذاری می‌شد. در نتیجه بازار و داشبورد در شروع برنامه غالباً فقط از فرهنگ محلی/آوانویسی استفاده می‌کردند.
- [x] تابع `buildTomanAssetNameIndex` اضافه شد تا نام‌های فارسی بر اساس تازگی رکورد، سپس اولویت منبع و زمان ثبت انتخاب شوند؛ دادهٔ تازه بر دادهٔ قدیمی مقدم است.
- [x] بارگذاری محدود و فقط‌خواندنی ستون‌های `asset_symbol, asset_name_fa, exchange, is_stale, fetched_at` در شروع بارگذاری بازار آغاز می‌شود؛ پس از آماده‌شدن شاخص، بازار و پیش‌نمایش داشبورد دوباره render می‌شوند. بارگذاری صفحهٔ تومان نیز از همان سازندهٔ مشترک استفاده می‌کند.
- [x] هیچ ستون جدیدی در `crypto_assets` فرض یا به query اضافه نشد؛ شواهد مخزن برای تأیید وجود `name_fa` در آن جدول کافی نبود. نام فارسی از نمای تومانی موجود دریافت می‌شود.
- [x] تست رگرسیون برای بارگذاری زودهنگام شاخص و انتخاب دادهٔ تازه اضافه شد. دو تست قدیمی که هنوز شکل پیشین resolver را انتظار داشتند، با resolver مشترک فعلی همگام شدند.
- [!] دو اجرای UI Visual Review قبلی روی commitهای `d40988a9` و `c6752064` به علت همین دو assertion قدیمی شکست خورده بودند؛ Playwright و screenshotها اجرا نشدند. این شکست به معنی اثبات باگ runtime در بازار نیست، اما گیت CI را قرمز کرده است. اجرای جدید روی HEAD تازه باید بررسی شود.
- [ ] تأیید CI جدید و سپس آزمون واقعی روی دستگاه Android با نام‌های دریافتی از صرافی‌ها باقی است.
- ایمنی: فقط فرانت‌اند، تست و این گزارش در شاخهٔ مستقل تغییر کردند؛ هیچ Supabase، Production، migration، wallet، order، trade، deployment یا release تغییر نکرد.


## اولویت منبع نام فارسی و مقاوم‌سازی تست — ۲۶ نوامبر ۲۰۲۶
- [x] اولویت نام‌های فارسی با قاعده تأییدشده پروژه هماهنگ شد: Bit24، سپس Kifpool، سپس Nobitex، Wallex و در نهایت Bitpin. تازگی داده همچنان پیش از اولویت منبع بررسی می‌شود؛ داده تازه منبع کم‌اولویت‌تر بر داده قدیمی منبع بالاتر مقدم است.
- [x] assertion جست‌وجوی بازار از regex حساس به quoting به بررسی وجود فراخوانی resolver مشترک تغییر کرد تا شکست کاذب ناشی از شکل رشته در فایل HTML رخ ندهد.
- [!] اجرای UI Visual Review شماره ۱۲۳ روی commit قبلی شکست خورده بود: ۱۲۸ از ۱۲۹ تست موفق و یک assertion در تست نام فارسی قرمز شد؛ screenshot اجرا نشد. تغییر assertion و اولویت منبع در commit جدید نیازمند اجرای CI مجدد است.
- [ ] CI سبز، اسکرین‌شات‌های هر سه تم، و نصب فیزیکی APK هنوز تأیید نشده‌اند.
- ایمنی: فقط فرانت‌اند، تست و گزارش در شاخه Draft تغییر می‌کنند؛ هیچ Production، Supabase، migration، سفارش، معامله، کیف پول، deployment یا release تغییر نمی‌کند.


## تأیید CI نام فارسی، تصاویر هر سه تم و APK — ۲۶ نوامبر ۲۰۲۶
- [x] آخرین کد برنامه در commit `75ea8ddac8883860aacf8cbd902b1f3834271952` قرار دارد؛ اصلاح اولویت منابع نام فارسی و مقاوم‌سازی assertion در این commit ثبت شده است.
- [x] UI Visual Review run `45859021958` با نتیجه success پایان یافت. مراحل source-level regression، نصب Playwright، نصب Chromium، ثبت تصاویر همه تم‌ها و بخش‌های برنامه و آپلود artifact همگی موفق‌اند.
- [x] artifact تصاویر `15138205275` با نام `DigiArz-UI-visual-review`، حجم 23,933,448 بایت؛ لینک اجرا: https://github.com/shahram-adim/DigiArz/actions/runs/45859021958 . این تصاویر با fixtureهای بصری ساخته می‌شوند و اثبات داده زنده یا لوگوی رسمی تمام دارایی‌ها نیستند.
- [x] Android Candidate APK run `45859021880` با نتیجه success پایان یافت. مراحل تولید دارایی وب، ساخت پروژه Capacitor، نصب پل بومی بیومتریک، sync اندروید، build و verify APK و آپلود artifact همگی موفق‌اند.
- [x] artifact APK `15138390207` با نام `DigiArz-Candidate-Android-debug-APK`، حجم ZIP برابر 3,695,108 بایت، digest برابر `sha256:edb97858cbfa463e21a57873d4d121c44c242ee3b8ceccfa6b4bb520176010c9`؛ مهلت انقضا 2026-12-10T16:29:41Z. لینک دریافت از صفحه اجرا: https://github.com/shahram-adim/DigiArz/actions/runs/45859021880
- [!] APK یک build آزمایشی Debug است؛ نصب فیزیکی روی گوشی، ورود/خروج واقعی، اثرانگشت/چهره، ناوبری، و دریافت بازار واقعی هنوز از سوی مالک آزموده نشده‌اند.
- [!] ممیزی لوگو: مسیر اصلی image_url/metadata، سپس app-assets و CoinCap حفظ شده است؛ در شکست منابع، SVG نمادین جایگزین نمایش داده می‌شود. SVG fallback لوگوی رسمی نیست و harness تصویری از glyphهای fixture استفاده می‌کند؛ پوشش لوگوهای رسمی باید روی دستگاه و با داده واقعی سنجیده شود.
- [ ] گام بعد: بازبینی خروجی تصویری هر سه تم از artifact، سپس ممیزی تکمیلی پوشش لوگو/منابع برای دارایی‌ها و ارائه APK Debug برای تست فیزیکی.
- [ ] PR #64 باز، Draft، ادغام‌نشده و `mergeable=false` است. شاخه نسبت به main برابر 148 commit جلو و 2 commit عقب و وضعیت `diverged` دارد؛ هیچ rebase/merge انجام نشود مگر با برنامه و تأیید صریح مالک.
- ایمنی: هیچ merge، release، Pages deployment، Supabase، Production، migration، wallet، order یا trade انجام نشده است.


## ممیزی ایمنی و پایداری بارگذاری لوگوها — ۲۶ نوامبر ۲۰۲۶
- [x] ممیزی کد نشان داد URL تصویر دریافتی از metadata در دو مسیر اصلی (ردیف بازار و صفحه جزئیات ارز) ابتدا مستقیماً در مرورگر بارگذاری می‌شد؛ این رفتار، دامنه مقصد تصویر را به اعتبارسنجی سمت سرور محدود نمی‌کرد.
- [x] هر دو مسیر اصلاح شدند تا تصویر کاتالوگ از ابتدا از Edge Function موجود `app-assets?asset=logo` عبور کند. این تابع فقط URLهای HTTPS متعلق به دامنه‌های مجاز CoinGecko را برای تصویر سفارشی می‌پذیرد و نوع محتوای تصویری و میزبان نهایی را بررسی می‌کند.
- [x] جست‌وجوی metadata اکنون ردیف هم‌نمادِ دارای URL تصویر معتبر را انتخاب می‌کند؛ ردیف خالی یا نامعتبر مانع استفاده از URL معتبر بعدی نمی‌شود.
- [x] پس از شکست تصویر سفارشی، زنجیره fallback از مسیر عمومی proxy استفاده می‌کند و در نهایت نشان SVG نمادین باقی می‌ماند؛ SVG همچنان به‌عنوان لوگوی رسمی معرفی نمی‌شود.
- [x] آزمون رگرسیون جدید به `tests/independent-ui.test.js` اضافه شد تا مسیر proxy برای بازار و جزئیات و انتخاب metadata معتبر را کنترل کند.
- [!] تغییرات فقط در کد وب و تست شاخه مستقل ثبت شده‌اند؛ Edge Function یا Supabase Production تغییر یا deploy نشده است. تا اجرای CI، موفقیت آزمون این commit تأییدشده نیست.
- [ ] بررسی همه بخش‌های دیگر که تصویر ارز نشان می‌دهند، به‌ویژه مسیر پیش‌نمایش ورود و تاریخچه، و سپس بررسی artifact تصویری و آزمون فیزیکی APK.
- ایمنی: هیچ تغییر در دیتابیس، Migration، wallet، order، trade، cron، deployment، release، merge یا rebase انجام نشده است.


## نتیجه CI ممیزی لوگو و APK — ۲۶ نوامبر ۲۰۲۶
- [x] UI Visual Review run `45863962701` روی commit کد `dfb4a0d11df3e0fd27618df070c4096087f56a79` موفق شد؛ آزمون‌های source-level، تصویربرداری Playwright/Chromium از همه تم‌ها و بخش‌ها و بارگذاری artifact همگی سبز شدند.
- [x] artifact تصویری `15140645125` با نام `DigiArz-UI-visual-review` و حجم 23,933,456 بایت؛ صفحه اجرا: https://github.com/shahram-adim/DigiArz/actions/runs/45863962701 . داده‌های تصویری fixture هستند، نه آزمون live-production.
- [x] Android Candidate APK run `45863962939` روی همان commit موفق شد؛ build، verify و upload artifact همگی موفق شدند.
- [x] artifact APK `15140440455` با نام `DigiArz-Candidate-Android-debug-APK`، حجم ZIP برابر 3,695,132 بایت، digest برابر `sha256:9adc8bc03a847206071e1010a2d776ac3abb4184bf3e882c5b9a8200d966094a` و انقضا `2026-12-10T17:02:07Z`. صفحه دریافت: https://github.com/shahram-adim/DigiArz/actions/runs/45863962939
- [!] این CI روی commit کد `dfb4a0d` اجرا شد. commit بعدی `d2f494e` تست جدید را اضافه کرد و UI Visual Review run `45864030917` هنوز در وضعیت pending است؛ تا پایان آن، تست assertion جدید روی آخرین تست‌commit نهایی تلقی نمی‌شود. APK روی تغییرات کد `dfb4a0d` ساخته شده و گزارش مستندسازی بعدی در `70773e0` کد برنامه را تغییر نداده است.
- [ ] تست فیزیکی APK و کنترل لوگوهای رسمی با داده واقعی همچنان نیازمند بررسی مالک است.
- ایمنی: فقط فایل‌های فرانت‌اند، تست و گزارش روی شاخه مستقل تغییر کرده‌اند؛ هیچ Edge Function یا Supabase Production deploy یا تغییری نداشته است.


## اصلاح شکست assertion در آزمون ممیزی لوگو — ۲۶ نوامبر ۲۰۲۶
- [!] UI Visual Review run `45864030917` روی commit تست `d2f494e` در مرحله source-level regression شکست خورد؛ ۱۲۸ تست دیگر موفق بودند و Playwright اجرا نشد.
- علت از کد اجرایی لوگو نبود: assertion تازه، عبارت fallback را از برش کد `coinLogo` می‌خواند، در حالی که `handleCoinLogoError` پیش از آن تعریف شده است؛ بنابراین تست محل اشتباه را بررسی می‌کرد.
- [x] برش تست اصلاح شد تا fallback را از محدوده صحیح `handleCoinLogoError` بخواند. commit اصلاح تست: `f3121cebea5deafe08766ac099d804dad89a5a04`.
- [ ] اجرای CI جدید برای commit اصلاح‌شده در انتظار نتیجه است؛ تا آن زمان تست جدید را سبز اعلام نمی‌کنیم.
- ایمنی: فقط تست تغییر کرد؛ منطق برنامه، Supabase و Production تغییری نکرده‌اند.


## تأیید اصلاح آزمون لوگو و تصویربرداری مجدد — ۲۶ نوامبر ۲۰۲۶
- [x] UI Visual Review run `45864455434` روی commit تست `f3121cebea5deafe08766ac099d804dad89a5a04` مرحله source-level regression را با موفقیت گذراند؛ اصلاح assertion جدید تأیید شد.
- [x] Playwright و Chromium نیز نصب شدند.
- [ ] مرحله ثبت تصاویر همه تم‌ها و بخش‌ها در زمان ثبت این گزارش هنوز در حال اجراست؛ آپلود artifact و نتیجه نهایی run پس از تکمیل تأیید می‌شود.
- [!] این run فقط تست و تصویربرداری را اجرا می‌کند؛ APK قبلی روی کد تغییرنیافته `dfb4a0d` ساخته شده بود. تغییر جدید فقط در تست و گزارش است و منطق برنامه پس از build قبلی تغییر نکرده است.


## نتیجه نهایی اجرای مجدد ممیزی لوگو — ۲۶ نوامبر ۲۰۲۶
- [x] UI Visual Review run `45864455434` روی commit `f3121cebea5deafe08766ac099d804dad89a5a04` با نتیجه success کامل شد.
- [x] آزمون‌های منبعی، نصب Playwright/Chromium، تصویربرداری همه تم‌ها و بخش‌های برنامه و آپلود artifact همگی موفق‌اند.
- [x] artifact تصویری `15139312461` با نام `DigiArz-UI-visual-review`، حجم 23,933,420 بایت و انقضا `2026-12-10T17:05:33Z`؛ صفحه اجرا: https://github.com/shahram-adim/DigiArz/actions/runs/45864455434
- [!] این تصویربرداری با داده‌های fixture انجام شده و پوشش واقعی لوگوهای رسمی یا فید Production را اثبات نمی‌کند.
- [x] آخرین وضعیت PR #64 در زمان ثبت: باز، Draft، ادغام‌نشده و `mergeable=false`. شاخه نسبت به main برابر 156 commit جلو و 2 commit عقب و وضعیت `diverged` دارد.
- [ ] گام بعد: ممیزی مسیرهای لوگوی ثابت صفحه ورود و مرور تاریخچه، سپس آماده‌سازی تست فیزیکی APK؛ انتشار یا ادغام فقط با تأیید صریح مالک.
- ایمنی: هیچ Supabase/Production، migration، cron، wallet، order، trade، deployment، release، merge یا rebase انجام نشده است.
## اصلاح ردیف بازار موبایل پس از بررسی تصاویر واقعی — ۲۶ نوامبر ۲۰۲۶
- [x] artifact تصویری DigiArz-UI-visual-review دریافت و تصاویر واقعی موبایل/دسکتاپ بررسی شد.
- [x] در نمای موبایل، CSS نمودارهای کوچک را مخفی می‌کرد؛ این با الزام نمایش mini-chart فعال مغایر بود.
- [x] چیدمان ردیف موبایل اصلاح شد: ستون مستقل برای sparkline، حفظ فضای قیمت USD/تومان، ستاره و هویت ارز؛ تغییر روی شاخه redesign/ui-mainline-clean-2026-11-26 ثبت شد.
- [x] commit اصلاح: 0e14fc1370191ffd75287c7593cb5cf30992efc5.
- [!] پس از commit هنوز CI جدیدی در GitHub برای این SHA گزارش نشده؛ نتیجه را سبز اعلام نمی‌کنیم.
- [ ] گام بعد: اجرای visual CI مجدد و بررسی عرض موبایل باریک؛ سپس رفع fallback لوگوها و خوانایی متن تم سوم.
- [!] تصاویر قبلی با fixture ساخته شده‌اند؛ نمودار واقعی نیازمند دسترسی شبکه به منبع کندل و فید واقعی نیازمند آزمون جداگانه است.
- ایمنی: فقط فایل UI روی شاخه مستقل تغییر کرده؛ هیچ merge، deployment، release، Supabase یا Production تغییری انجام نشده است.
## بازبینی جزئیات artifact موبایل و trigger تست — ۲۶ نوامبر ۲۰۲۶
- [x] تصاویر موبایل تم تیره و تم نیلی از artifact قبلی مستقیماً بازبینی شدند.
- [!] در تصاویر fixture، محل sparkline در ردیف‌ها با خط‌چین/placeholder دیده می‌شود؛ این تصویر اثبات دریافت کندل واقعی نیست.
- [!] چند لوگوی ارز در تصاویر به شکل نشان حرف/نماد جایگزین دیده می‌شوند؛ کد fallback موجود است اما اصالت و پوشش لوگوهای رسمی با fixture قابل اثبات نیست.
- [x] workflow بصری بررسی شد: روی push شاخه هدف با تغییر index.html اجرا می‌شود؛ همچنین workflow_dispatch دارد.
- [ ] نتیجه اجرای workflow پس از commit 0e14fc1370191ffd75287c7593cb5cf30992efc5 از طریق ابزار موجود هنوز قابل مشاهده/تأیید نیست؛ نباید موفق اعلام شود.
- [ ] مرحله بعد: دریافت نتیجه اجرای push-triggered workflow یا اجرای دستی آن از GitHub Actions؛ سپس بررسی تصاویر تازه و آزمون عرض‌های موبایل باریک.
- ایمنی: هیچ Production، Supabase، migration، merge یا انتشار انجام نشده است.
## ممیزی آبشاری CSS سه تم — ۲۶ نوامبر ۲۰۲۶
- [x] ترتیب cascade فایل src/digiarz-independent-ui.css تا انتهای بخش تم‌ها بررسی شد.
- [!] تم سوم با selector کلاس luxury-theme در لایه‌های قدیمی دارای رنگ‌بندی بنفش/سرمه‌ای است (حدود خطوط 1352–1429) و لایه‌های جدیدتر آن را به نیلی/آبی روشن تغییر داده‌اند (حدود خطوط 1885–1961 و 1970 به بعد). این انباشت override خطر ناهماهنگی بین صفحات دارد.
- [x] تم سفید در لایه اصلاح نهایی صریحاً پس‌زمینه سفید خالص دارد (حدود خطوط 1431–1509 و 1532 به بعد)؛ گرادیان آبی بسیار ملایم در پس‌زمینه صفحه در لایه بعدی باقی است و باید با خواسته «بدون خاکستری» از نظر بصری تأیید شود.
- [!] نام luxury-theme برای تم سوم اکنون با هویت نیلی/آبی روشن جدید هم‌معنا نیست؛ نام کلاس فعلاً برای سازگاری ساختاری حفظ شده، نه برای تعیین رنگ.
- [ ] گام بعد: یکپارچه‌سازی overrideهای تم سوم در یک بلوک نهایی واحد و حذف/خنثی‌سازی قواعد بنفش قدیمی، فقط پس از بررسی selectorهای وابسته و اجرای تست تصویری همه صفحات.
- [ ] تست دسترس‌پذیری کنتراست متن/آیکون فعال و مقایسه عرض 360/390/430 پیکسل در هر سه تم.
- ایمنی: در این مرحله فقط ممیزی read-only انجام شد؛ CSS تغییر نکرد، هیچ merge/deploy/Production/Supabase انجام نشد.
## بررسی انتهای CSS و آیکون‌های ناوبری — ۲۶ نوامبر ۲۰۲۶
- [x] انتهای فایل CSS در بازه خطوط 5800–5963 بررسی شد.
- [x] اصلاحات نهایی موجود برای سطوح دفتر سفارش/شاخص‌ها/خلاصه بازار در صفحه معامله، تم سوم را به سفید یخی و نیلی روشن تغییر می‌دهند.
- [x] آیکون‌های ناوبری پایین در هر سه تم حالت غیرفعال کم‌رنگ‌تر و حالت فعال برجسته‌تر دارند؛ برای تم سوم رنگ فعال آبی نیلی (#3659ca) تعریف شده است.
- [!] این اصلاحات نشان می‌دهد تم سوم در برخی زیرصفحه‌های معامله اصلاح شده، اما به‌تنهایی یکپارچگی تمام صفحات را ثابت نمی‌کند؛ لایه‌های قدیمی بنفش همچنان در CSS بالاتر وجود دارند.
- [ ] اصلاح سراسری انجام نشد؛ برای جلوگیری از بازنویسی پرریسک cascade، ابتدا باید خروجی تصویری تازه از همه صفحات و سه تم تولید و مقایسه شود.
- [ ] بررسی بعدی: تست‌های رگرسیون CSS و screenshots در viewportهای 360، 390 و 430 پیکسل، سپس یکپارچه‌سازی کنترل‌شده قواعد تم سوم.
- ایمنی: فقط خواندن فایل و ثبت گزارش؛ هیچ CSS/HTML اجرایی، Production، Supabase، merge یا deploy تغییر نکرد.
## پیگیری وضعیت PR و امکان اجرای تست تصویری — ۲۶ نوامبر ۲۰۲۶
- [x] PR #64 مجدداً بررسی شد؛ همچنان Draft و باز است. متن توضیحات PR هنوز مبنای قدیمی 9855d6e را ذکر می‌کند، اما main فعلی 6916b940 است.
- [!] مقایسه واقعی main با شاخه طراحی: 161 کامیت جلو، 2 کامیت عقب، status=diverged؛ مبنای مشترک 9855d6ea است. توضیحات PR باید بعداً با واقعیت مقایسه به‌روزرسانی شود؛ هیچ rebase/merge انجام نشد.
- [!] ابزار متصل فعلی فقط خواندن workflow runs مرتبط با PR و artifactها را پشتیبانی می‌کند و امکان dispatch دستی workflow در این نشست ارائه نشده؛ بنابراین تست تازه را نمی‌توان از اینجا راه‌اندازی یا موفق اعلام کرد.
- [ ] اقدام بعدی: اجرای دستی workflow از GitHub Actions یا دریافت push-triggered run از مخزن؛ سپس بررسی artifact تازه و تطبیق سه تم در صفحات/viewportها.
- ایمنی: هیچ تغییر اجرایی در UI انجام نشد؛ هیچ merge، rebase، deploy، Production یا Supabase انجام نشد.

## بررسی دو کامیت عقب‌مانده main و CI مالی — ۲۶ نوامبر ۲۰۲۶
- [x] مقایسه دوطرفه تأیید کرد main شامل دو کامیت خارج از شاخه UI است: `882591331c8d303c4d4eeb95ebc7f99e2efeb731` (ثبت snapshot و آزمون منبع Worker سفارش Limit) و `6916b940f63877f0f2589ad1652791b85e01d823` (ثبت نتیجه CI و وضعیت بازار تومانی).
- [x] این دو کامیت شامل تغییرات QA/مستندات Stop-Limit و وضعیت بازارند؛ هیچ‌کدام را به شاخه UI منتقل نکردم تا scope PR طراحی با تغییرات مالی مخلوط نشود.
- [x] Run #2111 با شناسه `45811382494` روی commit `8825913` از طریق جزئیات job بررسی شد: job با نتیجه success؛ همه ۲۲ مرحله اصلی PostgreSQL 17 و تست Node/browser و cleanup موفق بودند.
- [!] این CI فقط harness دورریختنی GitHub Actions را پوشش می‌دهد؛ معادل تست Supabase ایزوله با schema/ACL دقیق Production نیست.
- [!] یافته مهم QA: تابع زنده `process_limit_orders()` هنوز gross و fee را صریحاً تا ۸ رقم quantize نمی‌کند؛ این مانع حسابداری برای هر rollout است و در Production اصلاح نشده.
- [!] داده بازار تومانی در snapshot main که در commit ثبت شده کهنه است: ۳۷۳ ردیف، آخرین دریافت ۱۷ نوامبر ۲۰۲۶، صفر ردیف تازه در پنج دقیقه؛ لاگ refresh نیز POST/502 داشته. این موضوع باید در مسیر جداگانه بازار بررسی شود، نه با PR طراحی.
- [ ] گام امن بعدی UI: ساخت candidate تازه بر پایه HEAD فعلی main و انتقال گزینشی ۹ فایل UI با بازبینی دقیق، نه merge کردن تاریخچه diverged فعلی.
- ایمنی: هیچ تغییر Supabase/Production، migration، worker، cron، merge، rebase یا deploy انجام نشد.

## بازبینی پیش از ساخت candidate مستقل بر پایه main — ۲۶ نوامبر ۲۰۲۶
- [x] مقایسه تازه انجام شد: شاخه UI اکنون 164 commit جلو و 2 commit عقب main است؛ merge-base همچنان 9855d6ea است. این عدد نسبت به گزارش قبلی افزایش یافته و مبنای قبلی 161 دیگر به‌روز نیست.
- [x] فهرست واقعی PR #64 شامل 13 فایل است، نه 9 فایل: دو workflow، گزارش وضعیت، افزونه بایومتریک، index.html، package.json، اسکریپت آماده‌سازی Android، CSS مستقل، service worker و چهار فایل تست.
- [!] بنابراین پیشنهاد قبلی «انتقال گزینشی ۹ فایل UI» دقیق نبود و اصلاح شد؛ انتقال باید بر اساس وابستگی‌ها و محتوای هر فایل تصمیم‌گیری شود، نه صرفاً تعداد.
- [!] workflow تصویری فعلی فقط push روی نام شاخه قدیمی `redesign/ui-mainline-clean-2026-11-26` را trigger می‌کند. اگر candidate روی شاخه جدید ساخته شود، باید trigger آن workflow نیز به‌صورت کنترل‌شده به‌روزرسانی شود یا workflow_dispatch اجرا شود.
- [x] بازبینی `prepare-android-native.sh` نشان داد اسکریپت فایل افزونه را به مسیر Android کپی، plugin را در MainActivity ثبت و وابستگی androidx.biometric را به Gradle اضافه می‌کند؛ اجرای واقعی APK و سازگاری با قالب دقیق MainActivity هنوز باید تست شود.
- [!] افزونه بایومتریک و اسکریپت Android از نظر امنیت و قابلیت نصب بخشی از بسته مستقل‌اند و نباید به اشتباه از انتقال candidate حذف شوند؛ با این حال تا بررسی JS bridge و تست دستگاه واقعی، فعال بودن end-to-end آن تأیید نیست.
- [x] تست‌های UI شامل assertionهای وابسته به متن دقیق CSS و نام cache نسخه‌دار هستند؛ پس از هر انتقال/بازآرایی باید روی candidate جدید اجرا شوند. تست تصویری به‌تنهایی جای تست واقعی فید، لوگو و APK را نمی‌گیرد.
- [ ] گام بعد: ممیزی دقیق تغییرات index.html، CSS و service worker در برابر main و تعیین فایل‌های حداقلی وابسته؛ سپس ساخت شاخه candidate از HEAD فعلی main و انتقال کنترل‌شده. هنوز شاخه جدید ساخته یا هیچ فایل اجرایی منتقل نشده است.
- ایمنی: فقط خواندن GitHub و ثبت گزارش؛ هیچ branch، merge، rebase، migration، Production یا Supabase تغییر نکرد.


## ممیزی تطبیق شاخه طراحی با main — ۲۶ نوامبر ۲۰۲۶، ۲۱:۰۲
- [x] وضعیت واقعی GitHub دوباره خوانده شد: main روی `6916b940f63877f0f2589ad1652791b85e01d823` است؛ شاخه `redesign/ui-mainline-clean-2026-11-26` نسبت به آن 165 commit جلو و 2 commit عقب و همچنان `diverged` است؛ merge-base برابر `9855d6ea6cd188a5621c4e2c28c55e4cfb4d2587` است.
- [!] PR #64 هنوز Draft است و متن توضیحاتش ادعا می‌کند candidate از HEAD برابر `9855d6e` ساخته شده و صفر commit عقب است؛ این متن با main فعلی و مقایسه واقعی ناسازگار/کهنه است. PR #61 نیز باز و دست‌نخورده است.
- [x] مقایسه واقعی 13 فایل تغییرکرده را تأیید کرد. در main، `index.html` هنوز stylesheet مستقل را بارگذاری نمی‌کند؛ در شاخه، `src/digiarz-independent-ui.css?v=3` در انتهای سند بارگذاری شده است. فایل CSS شاخه 401,660 بایت است.
- [x] `sw.js` در main از cache `digiarz-shell-v58` استفاده می‌کند؛ شاخه از `v62` استفاده می‌کند و stylesheet مستقل را به app shell اضافه کرده است. این تغییر وابسته به انتقال HTML/CSS است و نباید جداگانه حذف شود.
- [x] `package.json` در شاخه اسکریپت `prepare:android` را اضافه کرده؛ وابستگی‌های اصلی Capacitor همان نسخه‌های 6.2.1 باقی مانده‌اند.
- [x] اتصال UI بیومتریک در `index.html` وجود دارد: کد از `window.Capacitor?.Plugins?.BiometricCredential` برای `saveCredentials/getCredentials/clearCredentials` استفاده می‌کند؛ نام کلاس Java در HTML مستقیماً ذکر نشده و ثبت native توسط اسکریپت آماده‌سازی Android انجام می‌شود. بنابراین آزمون JS bridge، قالب MainActivity، build و تست دستگاه واقعی همچنان شرط تأیید end-to-end است.
- [!] فایل اصلی `index.html` در شاخه 513,792 بایت و در main 492,996 بایت است؛ تغییرات UI شامل بازنویسی لوگوی Tether و مسیر fallback لوگو نیز هست. انتقال کامل فایل بدون مرور diff و اجرای regression می‌تواند تغییرات خارج از ظاهر را هم وارد کند.
- [x] بررسی PRهای باز، PR #64 را به‌عنوان candidate UI فعلی تأیید کرد؛ PRهای #61 و #60 نیز باز هستند و نباید به‌طور موازی با #64 ادغام شوند.
- [ ] اقدام بعدی: تهیه patch گزینشی از تغییرات HTML/CSS و وابستگی‌های SW/package/native، بازبینی diff در برابر main و ساخت candidate تمیز فقط پس از روشن شدن تمام تغییرات رفتاری. فعلاً هیچ شاخه جدیدی ساخته و هیچ کدی منتقل نشده است.
- ایمنی: فقط خواندن GitHub و افزودن این گزارش به شاخه موجود؛ هیچ merge، rebase، deployment، release، Production، Supabase، migration، wallet، order یا trade تغییری نکرد.


## اصلاح خطای نحوی راه‌اندازی بیومتریک — ۲۶ نوامبر ۲۰۲۶
- [x] ممیزی کد واقعی شاخه نشان داد تابع `setupBiometricControls()` حاوی `await vault.isAvailable()` بود اما با `function` معمولی تعریف شده بود؛ این ترکیب در JavaScript خطای نحوی ایجاد می‌کند و می‌تواند اجرای کل اسکریپت اصلی را متوقف کند.
- [x] فقط همان declaration در شاخه آزمایشی به `async function setupBiometricControls()` اصلاح شد؛ فراخوانی در `start()` بدون await باقی ماند، چون تابع خطاهای داخلی را catch می‌کند و عملیات اختیاری بیومتریک نباید راه‌اندازی سایر بخش‌ها را مسدود کند.
- Commit اصلاح: `f6c2e05e562679ee66ac07d54e24fc8c9932c8fa`.
- [ ] تست syntax و UI workflow برای commit اصلاح‌شده باید در GitHub Actions تأیید شود؛ نتیجه اجرا هنوز در این مرحله در دسترس نیست.
- [!] مقایسه تازه: شاخه اکنون 166 commit جلو و 2 عقب، همچنان diverged است؛ merge-base هنوز `9855d6ea6cd188a5621c4e2c28c55e4cfb4d2587` و PR #64 همچنان Draft است. توضیحات PR درباره «ساخته‌شده از main فعلی 9855d6e با صفر commit عقب» نادرست/قدیمی است؛ main فعلی `6916b940...` است.
- ایمنی: اصلاح فقط روی شاخه candidate؛ هیچ merge، deploy، release، Pages، Supabase، migration یا Production data change انجام نشد.


## نقطه توقف و ادامه — «شهرام ۱۲۰» — ۲۶ نوامبر ۲۰۲۶
- آخرین اصلاح ثبت‌شده: commit `f6c2e05e562679ee66ac07d54e24fc8c9932c8fa`؛ تابع `setupBiometricControls` به async تغییر کرد تا `await vault.isAvailable()` خطای نحوی ایجاد نکند.
- آخرین ثبت وضعیت: commit `ad5506adaa65003d394d622394c4274e993f9bb2`.
- شاخه کاری: `redesign/ui-mainline-clean-2026-11-26`؛ آخرین مقایسه گزارش‌شده با main: 167 commit جلو، 2 عقب، diverged؛ merge-base برابر `9855d6ea6cd188a5621c4e2c28c55e4cfb4d2587`؛ main برابر `6916b940f63877f0f2589ad1652791b85e01d823`.
- PR #64 باز و Draft است؛ توضیحات PR درباره پایه فعلی main قدیمی و نادرست است و باید بعداً اصلاح شود.
- CI برای کامیت اصلاح بیومتریک هنوز نتیجه تأییدشده ندارد؛ تست روی دستگاه Android واقعی نیز انجام نشده است.
- ادامه از این نقطه: ابتدا وضعیت Actions/CI کامیت `f6c2e05` و تست‌های syntax/UI را بررسی کن؛ سپس ممیزی امنیتی افزونه BiometricCredential (لغو/تلاش ناموفق، تغییر enrollment، حذف کلید، ثبت plugin در MainActivity و Gradle) را کامل کن.
- هیچ Merge، Rebase، انتشار، Pages deploy، Supabase/Production، migration، یا تغییر wallet/order/trade انجام نشده است؛ این محدودیت‌ها همچنان پابرجا هستند.


## گزارش ادامهٔ بازبینی UI سه تم و APK — ۲۶ نوامبر ۲۰۲۶
- [x] GitHub Actions رابط کاربری Run #45872620358 روی commit `a2b88dcecf15cebf444b3f6a09978da207093074` با نتیجه `success` پایان یافت؛ تست‌های source-level، نصب Playwright/Chromium، capture تمام ۳ تم و ۱۰ بخش برنامه در دو viewport و بارگذاری تصاویر موفق شدند.
- [x] Artifact تصاویر `DigiArz-UI-visual-review` با شناسه `15142893554` دریافت و بازبینی شد. README آن تصریح می‌کند درخواست‌های Supabase مسدود بوده‌اند و market/wallet/asset/top-volume fixtureها synthetic و DOM-only هستند؛ پس تصاویر، داده زنده یا صحت فید واقعی را اثبات نمی‌کنند.
- [x] بازبینی بصری تصاویر موبایل: تم مشکی/طلایی هویت جدا دارد؛ تم سفید روشن است؛ تم سوم هویت icy-indigo دارد اما در نماهای موبایل به تم سفید نزدیک است و باید تمایز نیلی/آبی آن تقویت شود. ردیف‌های بازار بدون قاب و Tether در ابتدای فهرست دیده می‌شوند.
- [x] Android candidate APK Run #45872608229 روی commit `e3407fea4e1896eb457ad09bb619abe7218ed310` با نتیجه `success` پایان یافت؛ build، verify/provenance و upload همگی موفق شدند.
- [x] Artifact APK با شناسه `15143119247` دریافت شد؛ فایل `app-debug.apk` برابر 4,141,296 بایت است. SHA-256: `ae612bb333da4bf24ad0a75eb1e6f192e1dae64bf31a5e22c651a77d50cb175d`.
- [!] APK یک debug candidate است؛ نصب واقعی روی دستگاه Android، ورود Supabase واقعی و جریان end-to-end اثرانگشت/چهره هنوز آزموده نشده‌اند.
- [!] PR #64 همچنان open و Draft و merged=false است. آخرین head `a2b88dcecf15cebf444b3f6a09978da207093074`، base ثبت‌شده در PR `9855d6ea6cd188a5621c4e2c28c55e4cfb4d2587` است؛ main فعلی `6916b940f63877f0f2589ad1652791b85e01d823` است. مقایسه واقعی main...branch برابر 176 ahead و 2 behind و diverged است.
- [x] دو commit عقب‌مانده main در QA/مستندات Stop-Limit و تست‌های source snapshot قرار دارند؛ فایل مشترک با شاخه UI، `IMPLEMENTATION_STATUS.md` است. فایل‌های SQL/QA مالی در این شاخه وارد نشده‌اند؛ هیچ rebase/merge انجام نشد.
- [ ] گام بعد: تقویت تمایز تم سوم و اجرای دوباره visual regression؛ سپس بررسی نصب APK روی گوشی واقعی و تست بیومتریک. جداگانه، مرور تعارض/اختلاف مستندات `IMPLEMENTATION_STATUS.md` پیش از هر sync با main.
- ایمنی: هیچ merge، rebase، release، Pages deployment، Supabase، migration، Production DB، wallet، order یا trade تغییری انجام نشد.


## اصلاح هویت بصری تم سوم و آزمون رگرسیون — ۲۶ نوامبر ۲۰۲۶
- [x] بازبینی آخرین لایه CSS نشان داد تم سوم روشن و نیلی است، اما در نماهای موبایل به تم سفید نزدیک می‌ماند؛ به‌جای تیره‌کردن آن، شدت tint آبی/نیلی و تفاوت سطوح شیشه‌ای تقویت شد.
- [x] در انتهای `src/digiarz-independent-ui.css` لایه `Icy-indigo refinement v2` اضافه شد: پس‌زمینه چندلایه نیلی-یخی، کارت‌ها و پنل‌های شیشه‌ای با tint متمایزتر، هدر/تب‌ها، Hero و نوار ناوبری فعال. `color-scheme:light` و خوانایی متن تیره حفظ شده‌اند.
- [x] تست رگرسیون اختصاصی در `tests/independent-ui.test.js` اضافه شد تا رنگ‌های کلیدی، گرادیان‌ها، حالت روشن و reduced-motion را کنترل کند.
- Commit CSS: `eb6065e17978cbc93cabb95abc4ded114c82da9b`.
- Commit تست: `59e7a7cb93dd4e0ca52b0be002eebe59fe7f163c`.
- [!] UI visual review Run #45873474786 برای commit تست `59e7a7c` در آخرین بررسی pending بود؛ خروجی تازه هنوز بازبینی نشده است. چند اجرای میانی به‌علت pushهای متوالی cancelled شدند؛ آن‌ها را موفق محسوب نکن.
- [!] APK build مربوط به CSS جدید نیز باید از آخرین commit ساخته شود؛ APK قبلی قبل از این تغییر CSS است و نسخهٔ تازه محسوب نمی‌شود.
- [ ] پس از پایان CI، تصاویر تم سوم را در تمام صفحات و viewportهای موبایل بررسی کن؛ سپس APK جدید را بساز/بررسی کن و نصب واقعی روی Android را انجام بده.
- ایمنی: فقط CSS و تست روی شاخه Draft تغییر کردند؛ هیچ merge، rebase، release، Pages deploy، Supabase، migration یا Production data change انجام نشد.


## رفع ناسازگاری آزمون‌های تم نیلی — ۲۶ نوامبر ۲۰۲۶
- [x] تحلیل لاگ Run #45873474786 نشان داد ۳ مورد از ۱۳۸ تست شکست خورده‌اند؛ هر سه assertionهای قدیمی پالت بودند: انتظار `color-scheme:light` در آخرین بلوک، مقدار قدیمی theme-color/chart و مقدار قدیمی chart foundation. ۱۳۵ تست دیگر موفق بودند.
- [x] CSS تم سوم صریحاً `color-scheme:light!important` دارد؛ پالت جدید پس‌زمینه `#dce4ff` و accent `#344fc5` است.
- [x] `index.html` رنگ نوار وضعیت Android و chart canvas را با پالت جدید همگام کرد: پس‌زمینه `#dce4ff` و متن chart `#263b91`.
- [x] تست‌های قدیمی `tests/independent-ui.test.js` با مقادیر جدید همگام شدند.
- Commit CSS: `f0cbf84a753cf4e32b0ac2aa0fee395b7fda6a05`; commit تست: `939429755b691fbed6af5f1c69c49b87ab8b3d3a`; commit هماهنگی HTML: `caf2723cb64e9a6b5d53e0fe866f4deeec0b30be`.
- [!] Run #45873990436 روی commit تست `9394297` هنگام آخرین بررسی in_progress بود؛ Run #45874005767 visual review و #45874005846 APK برای آخرین commit `caf2723` pending بودند. APK قبلی #45873974389 روی CSS-only commit `f0cbf84` در حال اجرا بود و جای build آخرین commit را نمی‌گیرد.
- [ ] منتظر نتیجه UI regression و APK build روی آخرین commit بمان؛ در صورت موفقیت، artifactها را دریافت و تصاویر را بازبینی کن.
- ایمنی: هیچ merge، rebase، release، Pages deploy، Supabase، migration یا Production data change انجام نشد.


## پیگیری شکست آزمون‌های پالت تم سوم — ۲۶ نوامبر ۲۰۲۶
- [x] اجرای UI review شماره `45874005767` روی commit `caf2723` شکست خورد؛ لاگ نشان داد دو assertion قدیمی باقی مانده بودند (theme-color انتظار `#edf2ff` و chart palette قدیمی `#edf2ff/#202b55/#dbe4ff/#b9c7ef`).
- [x] هر دو assertion دقیقاً با palette فعلی `#dce4ff/#263b91/#cbd5ff/#aebdf5` همگام شدند.
- Commit اصلاح تست: `4b6861a63721edbda1193a2ebc1e7096bd4b5015`.
- [ ] باید UI visual review و APK build برای همین commit نهایی دوباره اجرا و بررسی شوند؛ اجرای APK قبلی روی commit قدیمی‌تر هنوز در حال اجرا/صف بوده و معادل آخرین نسخه نیست.
- هیچ merge/rebase/deploy/Production یا Supabase تغییری انجام نشد.


## اصلاح دقیق assertionهای تم سوم — پیگیری تکمیلی ۲۶ نوامبر ۲۰۲۶
- [!] Run #45874174729 روی commit `4b6861a` نشان داد اصلاح قبلی assertion اول به‌علت جایگزینی ناموفق در فایل تست اعمال نشده بود؛ خطا هنوز مقدار legacy `#edf2ff` را انتظار می‌کشید. این خطا در منطق برنامه نبود، بلکه در تست باقی مانده بود.
- [x] هر چهار مقدار legacy در `tests/independent-ui.test.js` با palette جاری جایگزین شدند.
- Commit نهایی اصلاح تست: `75464c4956170c6d09cb325122f55ff839e1454b`.
- [ ] اجرای UI visual review مجدد روی commit `75464c4` در صف قرار گرفت؛ تا پایان موفق آن، اسکرین‌شات/رگرسیون تأییدشده محسوب نمی‌شود.
- [x] APK workflow #45874005846 موفق شد؛ artifact `DigiArz-Candidate-Android-debug-APK` شناسه `15143862233`، حجم 3,696,673 بایت، SHA-256 `adb80d8da3086da503f779614e3b954c3ee0c9d262a4929df580714b30e76e6c`. این APK از commit اجرایی `caf2723` ساخته شده؛ تغییر بعدی فقط اصلاح تست بوده، نه فایل اجرایی برنامه.
- PR #64 همچنان Draft و باز است؛ compare فعلی نسبت به main برابر 194 ahead و 2 behind، پس هنوز نیازمند بررسی اختلافات main و تعارض‌ها است.
- بدون merge، rebase، deploy یا تغییر Production/Supabase.


## همگام‌سازی assertionهای گرادیان تم سوم — ۲۶ نوامبر ۲۰۲۶
- [x] اجرای #45874523937 مشخص کرد دو assertion دیگر در تست تم سوم از گرادیان‌های قدیمی استفاده می‌کردند؛ CSS جاری در refinement v2 از گرادیان `#e8edff → #d8e1ff → #e1edff` استفاده می‌کند و کنترل بازار از `#fff → #edf2ff`.
- [x] فقط assertionهای تست با CSS واقعی همگام شدند؛ هیچ رنگ یا رفتار UI برای عبور صوری از تست تغییر نکرد.
- Commit تست: `b67c40c03971f6850ecd6c1fcb09528476a72292`.
- [ ] UI review #45874657768 در صف است؛ تا نتیجهٔ آن، رگرسیون تصویری و screenshotها هنوز تأیید نشده‌اند.
- [x] بررسی اختلاف main: دو commit عقب‌افتاده شامل فقط `IMPLEMENTATION_STATUS.md` و مستندات/تست QA مربوط به Stop-Limit هستند؛ فایل SQL snapshot تستی جدید نیز در main وجود دارد. این تغییرات Production نیستند، اما پیش از هر همگرایی باید محتوا و تعارض احتمالی فایل وضعیت بررسی شود.
- PR #64 باز، Draft و ادغام‌نشده است؛ compare فعلی 194 ahead / 2 behind. هیچ rebase یا merge انجام نشده است.


## تأیید تصویربرداری و بازبینی بصری سه تم — ۲۶ نوامبر ۲۰۲۶
- [x] UI visual review Run #45874657768 روی commit اجرایی `b67c40c03971f6850ecd6c1fcb09528476a72292` با نتیجه `success` پایان یافت؛ هر ۱۳۸ آزمون منبعی موفق شدند و Playwright/Chromium تمام بخش‌ها را در دو viewport تصویربرداری کرد.
- [x] Artifact تصویری `DigiArz-UI-visual-review` شناسه `15144252754`، شامل ۶۶ تصویر، دریافت و بررسی شد.
- [x] بازبینی تصاویر موبایل: تم مشکی/طلایی هویت مستقل و کنتراست مناسب دارد؛ تم سفید روشن و بدون قاب‌های اضافی است؛ تم سوم هویت نیلی-یخی و سطوح شیشه‌ای متمایزتری از تم سفید دارد. ردیف‌های بازار در هر سه تم بدون قاب و با نام فارسی/انگلیسی، قیمت، درصد تغییر و کنترل ستاره نمایش داده می‌شوند.
- [x] نماهای دسکتاپ و صفحات بازار، دارایی‌ها، نمودار، سفارش‌ها، تاریخچه، تنظیمات و مدیریت نیز در artifact وجود دارند؛ ثبت تصاویر موفق بوده است.
- [!] README artifact تأیید می‌کند درخواست‌های Supabase مسدود بوده‌اند؛ ردیف‌های بازار/داشبورد/دارایی/حجم، fixtureهای مصنوعی صرفاً DOM هستند و به backend نوشته نشده‌اند. بنابراین این بازبینی فقط چیدمان/ظاهر را تأیید می‌کند، نه قیمت زنده، احراز هویت، کیف پول واقعی یا عملکرد RPC.
- [!] APK موفق قبلی #45874005846 روی commit اجرایی `caf2723cb64e9a6b5d53e0fe866f4deeec0b30be` ساخته شده است؛ چون تغییرات پس از آن عمدتاً تست و مستندات بوده‌اند، باید یک build نهایی روی head فعلی برای provenance روشن تهیه شود. نصب فیزیکی و تست بیومتریک روی Android همچنان باز است.
- PR #64 همچنان Draft و ادغام‌نشده است؛ head مستندات `3dc2f746293b5aba50c61fc285f46c7f06fa57a1` و base ثبت‌شده `9855d6ea6cd188a5621c4e2c28c55e4cfb4d2587` است. GitHub آن را در حال حاضر `mergeable=false` گزارش می‌کند؛ پیش از هر همگرایی باید علت و اختلاف main به‌صورت جداگانه بررسی شود.
- ایمنی: هیچ merge، rebase، deploy، انتشار، Supabase، migration یا تغییر Production انجام نشد.
- [ ] گام بعد: اجرای APK روی head فعلی و بازبینی provenance؛ سپس آزمون نصب واقعی Android، ورود واقعی Supabase و جریان بیومتریک. جداگانه، بررسی علت `mergeable=false` و اختلاف فایل وضعیت با main، بدون همگام‌سازی خودکار.


## اصلاح دسترس‌پذیری پاک‌سازی مخزن بیومتریک — ۲۶ نوامبر ۲۰۲۶
- [x] ممیزی افزونه نشان داد اگر اطلاعات ورود قبلاً ذخیره شده باشد ولی دستگاه دیگر BIOMETRIC_STRONG را در دسترس نداشته باشد، تابع setup پیش از نمایش دکمه حذف، زود بازمی‌گشت؛ در نتیجه کاربر از داخل برنامه نمی‌توانست ciphertext محلی را پاک کند.
- [x] اصلاح محدود در index.html: وضعیت hasCredentials قبل از خروج به‌علت unavailable بررسی می‌شود؛ اگر اعتبارنامه ذخیره‌شده وجود داشته باشد، پنل و دکمه حذف نمایش داده می‌شوند؛ گزینه opt-in و ورود بیومتریک در دستگاه ناسازگار پنهان می‌مانند.
- [x] تست منبعی اختصاصی برای سناریوی «اعتبارنامه ذخیره‌شده، بیومتریک قوی در دسترس نیست» افزوده شد.
- Commit کد: e556526beec417160a37ae528f27e75fe28eb2d8؛ commit تست: bb0c350d62e47bd3afae3881aebb8f2ebd1f2331.
- [x] در UI visual workflow مربوط به commit کد، مرحله source-level regression tests موفق شد.
- [ ] UI visual review #45875527160 و APK build #45875527103 در آخرین بررسی هنوز در حال اجرا بودند؛ تا پایان موفق هر دو، نتیجه نهایی و artifact تازه تأییدشده محسوب نمی‌شوند.
- [!] تست فیزیکی روی گوشی Android، تغییر/حذف enrollment، ورود واقعی Supabase و بررسی تغییر رمز حساب همچنان انجام نشده‌اند.
- [!] PR #64 همچنان Draft و باز است؛ head اکنون bb0c350d62e47bd3afae3881aebb8f2ebd1f2331، main برابر 6916b940f63877f0f2589ad1652791b85e01d823 و merge-base برابر 9855d6ea6cd188a5621c4e2c28c55e4cfb4d2587 است؛ اختلاف 200 ahead / 2 behind و mergeable=false.
- [x] دو commit عقب‌مانده main مربوط به QA/مستندات Stop-Limit و snapshot فقط‌خواندنی تابع Limit هستند؛ هیچ کدام به Production اعمال نشده‌اند. هیچ sync/rebase/merge انجام نشد.
- ایمنی: فقط UI و تست در شاخه Draft تغییر کردند؛ هیچ Supabase، migration، wallet، order، trade، release یا deploy تغییر نکرد.


## اعتبارسنجی APK و بازبینی بصری نامزد UI — ۲۶ نوامبر ۲۰۲۶
- [x] ساخت APK مستقل PR موفق: workflow run `45875527103`، commit کد `e556526beec417160a37ae528f27e75fe28eb2d8`، artifact ID `15144198897`.
- [x] APK از artifact دریافت و استخراج شد؛ `BUILD-INFO.txt` با commit و run مطابقت دارد.
- [x] SHA-256 واقعی فایل `app-debug.apk`: `e75b489392975eb4ab0e9078a30ad500b33292d777da85b914388bc8c13987a6`؛ اندازهٔ فایل 4,142,927 bytes. Digest آرشیو artifact در GitHub جداگانه `d5c00c1eea4a880fe97c0ab2180668cc1864be3ed1e116bda045e0ba2a1cceb3` است.
- [x] UI visual review برای commit کد `e556526` موفق: run `45875527160`، artifact ID `15145292069`.
- [x] بازبینی بصری ۶۶ تصویر در ۲ viewport، سه تم و ۱۰ بخش انجام شد؛ سه هویت بصری تاریک/طلایی، سفید و نیلی-یخی از هم قابل تشخیص‌اند.
- [x] اجرای تصویری بعدی روی commit تست `bb0c350d62e47bd3afae3881aebb8f2ebd1f2331` capture و upload تصاویر را انجام داد؛ run `45875541965`، artifact ID `15143444393`.
- [!] README تصاویر تأیید می‌کند درخواست‌های Supabase مسدود بوده‌اند و ردیف‌های بازار/داشبورد/دارایی fixtureهای synthetic و DOM-only هستند؛ قیمت زنده، اتصال backend و صحت دادهٔ واقعی تأیید نشده‌اند.
- [!] APK یک debug candidate است؛ نصب روی گوشی فیزیکی، ورود واقعی، biometric enrollment و حذف credential هنوز آزمایش نشده‌اند.
- لینک‌ها: APK `https://github.com/shahram-adim/DigiArz/actions/runs/45875527103`؛ UI `https://github.com/shahram-adim/DigiArz/actions/runs/45875527160`؛ visual retest `https://github.com/shahram-adim/DigiArz/actions/runs/45875541965`.
- هیچ merge/rebase/deploy، انتشار یا تغییر Supabase/Production انجام نشده است.


## پاک‌سازی اعتبارنامهٔ بیومتریک پس از تغییر رمز — ۲۶ نوامبر ۲۰۲۶
- [x] ممیزی جریان بازیابی رمز نشان داد پس از `auth.updateUser({password})`، اعتبارنامهٔ رمزنگاری‌شدهٔ قدیمی در Android Keystore باقی می‌ماند و تلاش ورود بیومتریک بعدی با رمز منقضی‌شده شکست می‌خورد.
- [x] پس از تغییر موفق رمز، برنامه اکنون `clearCredentials()` را اجرا و دکمه‌های ورود/حذف بیومتریک را پنهان می‌کند؛ اگر پاک‌سازی ناموفق شود، هشدار داده می‌شود و کنترل حذف دستی باقی می‌ماند.
- [x] اگر Supabase هنگام ورود بیومتریک خطای `invalid_credentials` برگرداند، vault قدیمی پاک می‌شود و کاربر به ورود دستی با رمز جدید هدایت می‌شود؛ خطاهای شبکه یا 504 باعث حذف خودکار vault نمی‌شوند.
- [x] تست‌های منبعی برای هر دو مسیر اضافه شد؛ مرحلهٔ source-level regression در UI workflow جدید موفق گزارش شده است.
- Commitهای تغییر: `f1ad70839d1fd8e3f7e98b5903440367fb269f8a` و تست `ee40da2e60719851685d034100189b6284a90ac0`.
- [ ] APK جدید run `45876178982` هنوز در مرحلهٔ Build installable debug APK بود؛ artifact تازه تا پایان verify/upload تأیید نشده است.
- [ ] UI visual review run `45876179024` تست‌های منبعی را پشت سر گذاشته و در مرحلهٔ نصب Chromium بود؛ capture/upload هنوز نهایی نشده است.
- [!] تغییر رمز و ورود بیومتریک هنوز روی گوشی واقعی و حساب واقعی آزمایش نشده‌اند؛ هیچ رمز یا دادهٔ کاربری واقعی دستکاری نشده است.
- وضعیت PR #64: باز و Draft، mergeable=false، merged=false؛ شاخه 204 commit جلو و 2 عقب از main است. دو commit عقب‌مانده مربوط به QA و snapshot فقط‌خواندنی Stop-Limit هستند و دست‌نخورده باقی مانده‌اند.
- هیچ merge، rebase، deploy، انتشار، migration یا تغییر Supabase/Production انجام نشد.


## نتیجهٔ بازبینی بصری و تلاش ساخت APK — ۲۶ نوامبر ۲۰۲۶
- [x] اجرای UI visual review روی commit `f1ad70839d1fd8e3f7e98b5903440367fb269f8a` موفق شد: run `45876179024`، artifact `15144788757`، ۶۶ تصویر (دو viewport × سه تم × ده بخش + دو close-up). فایل‌ها دریافت و README و تصاویر بررسی شدند.
- [x] بازبینی close-up بازار تم نیلی-یخی انجام شد؛ ساختار ردیف‌ها، نام فارسی/نماد، قیمت USD/تومان، درصد تغییر و ستاره دیده می‌شود. داده‌های market/dashboard همچنان fixture مصنوعی هستند و Supabase API در محیط تصویربرداری مسدود بوده است.
- [!] ساخت APK همان commit در run `45876178982` شکست خورد؛ خطا ناشی از HTTP 429 Too Many Requests از Maven Central هنگام دریافت dependencyهای Gradle از جمله Kotlin stdlib و jsr305 بود، نه خطای compile شناخته‌شده در کد DigiArz. build، verify و upload artifact اجرا نشدند.
- [x] فقط job ناموفق در workflow ساخت APK مجدداً صف شد؛ run `45876178982` اکنون queued است. لینک: `https://github.com/shahram-adim/DigiArz/actions/runs/45876178982`.
- [ ] UI review جدیدتر روی commit تست `ee40da2` با run `45876183333` هنوز در حال اجرا/تکمیل است.
- وضعیت PR #64: باز و Draft، head فعلی `5f3c73519057b761236c8b125fe09a1a63bc2847`، merged=false، mergeable=false؛ شاخه 205 جلو و 2 عقب از main است. دو commit عقب‌ماندهٔ main مربوط به QA و snapshot فقط‌خواندنی Stop-Limit حفظ شده‌اند.
- هیچ merge/rebase/deploy، انتشار، migration یا تغییر Supabase/Production انجام نشده است.


## تأیید APK بیومتریک و بازبینی UI — ۲۶ نوامبر ۲۰۲۶
- [x] تلاش دوم workflow ساخت APK با run `45876178982`، attempt 2، روی commit کد `f1ad70839d1fd8e3f7e98b5903440367fb269f8a` با نتیجه `success` پایان یافت؛ تمام مراحل build، verify و upload موفق شدند.
- [x] Artifact با شناسه `15144869028` دریافت شد؛ آرشیو ZIP سالم است و شامل `app-debug.apk` و `BUILD-INFO.txt` است.
- [x] منشأ داخل BUILD-INFO با run و commit تطبیق دارد؛ نسخه `1.0.0`، ref شاخه `redesign/ui-mainline-clean-2026-11-26` و زمان ساخت UTC ثبت شده است.
- [x] SHA-256 مستقل APK برابر `4bf34abeb25b5ca3a41905305407bd8daab1f3b2d186e2457c734ae71c05ed72` (4,143,313 bytes) است و با BUILD-INFO تطبیق دارد. SHA-256 آرشیو ZIP برابر `1fef4aff97cccf0b9f19740c9a61cc144bcf8491466851c3cb616d5b6a6fa97e` و با digest اعلام‌شده GitHub برابر است.
- [x] UI visual review run `45876183333` روی commit تست `ee40da2e60719851685d034100189b6284a90ac0` با نتیجه `success` پایان یافت؛ artifact `15144374522` دریافت شد و ۶۶ تصویر در دو viewport، سه تم و ده بخش به‌همراه close-upها بازبینی شدند.
- [x] بازبینی منتخب نشان می‌دهد تم مشکی/طلایی، سفید روشن و نیلی-یخی از هم متمایزند و ردیف‌های بازار در هر سه تم بدون قاب اضافی، با نام/نماد، قیمت، درصد تغییر و ستاره ارائه شده‌اند.
- [!] README تصویربرداری تأیید می‌کند درخواست‌های Supabase مسدود بوده و ردیف‌های بازار/داشبورد/دارایی/حجم fixtureهای مصنوعی DOM-only هستند؛ این تست، قیمت زنده، اتصال backend، کیف پول یا RPC را تأیید نمی‌کند.
- [!] APK از commit `f1ad708` ساخته شده، در حالی که head مستندات/تست PR اکنون `b41d745` است؛ compare نشان می‌دهد سه commit بعدی فقط `IMPLEMENTATION_STATUS.md` و `tests/biometric-credential.test.js` را تغییر داده‌اند، نه فایل‌های اجرایی APK. با این حال APK را دقیقاً با commit خودش معرفی می‌کنیم و آن را build روی آخرین head نمی‌نامیم.
- [!] نصب روی گوشی واقعی، ورود با حساب واقعی Supabase، تغییر رمز و ورود مجدد با بیومتریک هنوز آزمایش نشده‌اند.
- PR #64 همچنان Draft، باز، ادغام‌نشده و `mergeable=false` است؛ شاخه نسبت به main در آخرین compare برابر 206 جلو و 2 عقب است. دو commit عقب‌ماندهٔ QA/مستندات Stop-Limit و snapshot فقط‌خواندنی حفظ شده‌اند؛ هیچ merge/rebase انجام نشد.
- ایمنی: هیچ deploy، انتشار، migration، db push یا تغییر Production/Supabase انجام نشد.
- [ ] گام بعد: نصب APK روی دستگاه Android و اجرای تست کنترل‌شدهٔ enrollment، تغییر رمز، پاک‌سازی vault، ورود با رمز جدید و ثبت مجدد بیومتریک؛ سپس بررسی علت `mergeable=false` و اختلاف main به‌صورت جداگانه، بدون همگام‌سازی خودکار.


### تصحیح وضعیت شاخه پس از ثبت گزارش — ۲۶ نوامبر ۲۰۲۶
- [x] پس از ثبت گزارش APK/UI، commit مستندات `96c5a20922a31b74716a0abc14c28c1434907610` ایجاد و از GitHub بازخوانی شد.
- [x] PR #64 اکنون head برابر `96c5a20922a31b74716a0abc14c28c1434907610` دارد؛ هنوز open، Draft، merged=false و mergeable=false است.
- [x] compare تازه: شاخه 207 commit جلو و 2 commit عقب از main، با merge-base برابر `9855d6ea6cd188a5621c4e2c28c55e4cfb4d2587`. دو commit عقب‌مانده همچنان حفظ شده‌اند.
- [!] APK تأییدشده همچنان دقیقاً از `f1ad70839d1fd8e3f7e98b5903440367fb269f8a` ساخته شده؛ تغییرات بعدی شامل تست/مستندات‌اند و نباید این APK را build روی head فعلی PR معرفی کرد.

## اصلاح دقت ارزش‌گذاری پورتفولیو و پایش بازار تومانی — ۲۷ نوامبر ۲۰۲۶
- [x] ممیزی فقط‌خواندنی کد UI نشان داد ارزش دارایی‌ها با Number(qty) * Number(price) و جمع پورتفولیو با floating-point انجام می‌شد؛ این مسیر از محاسبات دقیق سفارش جدا بود.
- [x] ماژول مستقل src/portfolio-valuation.js اضافه شد؛ ضرب و جمع ارزش دارایی‌ها با DigiDecimal و دقت ۱۸ رقم اعشار انجام می‌شود. تبدیل به Number فقط برای نسبت‌های گرافیکی/مرتب‌سازی و عناصر نمایشی باقی مانده است.
- [x] نرخ FX دقیق به‌صورت رشته نگهداری می‌شود و ارزش تومانی کل و ارزش تومانی واحد از مقدار دقیق نرخ استفاده می‌کنند.
- [x] تست‌های مستقل tests/portfolio-valuation.test.js برای ضرب دقیق، حفظ ۱۸ رقم اعشار، جمع کیف پول و دارایی، مقادیر منفی/نامعتبر و ورودی خراب افزوده شد.
- [x] workflow ui-visual-review.yml به اجرای تست جدید مجهز شد.
- [!] اجرای source-level regression در run قبلی 45963048974 موفق بود؛ مراحل Chromium و visual هنوز تکمیل نشده بود. runهای میانی به‌دلیل pushهای پیاپی لغو شدند. run نهایی 45963179978 روی commit 1328f538bbc5108a5ccaf63be8a87787a40a1ff2 در صف/در حال اجراست و باید نتیجهٔ نهایی آن بازبینی شود.
- [x] کد Edge Function نسخه ۳ فقط‌خواندنی بازبینی شد: پاسخ 502 زمانی صادر می‌شود که هیچ‌یک از سه provider قیمت معتبر ندهند یا خطای بیرونی/ذخیره‌سازی رخ دهد؛ هر سه provider با Promise.allSettled اجرا می‌شوند. در لاگ‌های موجود 502ها دارای EDGE_FUNCTION_ERROR هستند؛ برای executionهای بررسی‌شده لاگ خطای runtime یا stack trace وجود ندارد، بنابراین provider failure در برابر runtime/infra failure هنوز تفکیک قطعی نشده است.
- [x] هیچ فراخوانی دستی به تابع Production انجام نشد؛ هیچ داده‌ای نوشته/پاک‌سازی نشد و Cron/Worker دست‌نخورده باقی ماند.
- [!] market_toman_prices در snapshot قبلی ۳۷۳ ردیف و صفر ردیف تازه در پنج دقیقه داشت؛ باید فقط‌خواندنی دوباره سنجیده شود.
- [!] PR #64 همچنان Draft و ادغام‌نشده است. تغییرات روی شاخهٔ موجود ثبت شده‌اند؛ هیچ merge/rebase/deploy یا انتشار انجام نشد.
- [ ] گام بعد: تکمیل و بازبینی run 45963179978، اجرای مجدد آزمون‌های منبعی/تصویری در صورت نیاز، بررسی sort و donut صرفاً نمایشی، و ادامهٔ تشخیص 502 با لاگ‌های امن provider-level در محیط آزمایشی؛ هیچ تغییر Production بدون تأیید مالک.
### تکمیل دقت کامل پورتفولیو و اصلاح CI — ۲۷ نوامبر ۲۰۲۶
- [x] اصلاح قرارداد خطای sum برای ورودی نامعتبر؛ تست اولیه ۱۵۳/۱۵۴ را گذراند و تنها assertion متن خطا نیاز به یکسان‌سازی داشت. ماژول اکنون خطای Invalid portfolio amount را به‌صورت پایدار برمی‌گرداند.
- [x] دامنهٔ داخلی ماژول ارزش‌گذاری با numeric(24,8) و قیمت‌های numeric(38,18) سازگار شد: parse/compare/add/multiply از مسیرهای دارای maxIntegerDigits=24 استفاده می‌کنند؛ دقت ارزش‌گذاری و جمع ۱۸ رقم اعشار است.
- [x] تست اضافه برای محدودهٔ کامل ۲۴ رقم صحیح، جمع بدون float drift، ورودی منفی و خطای ورودی نامعتبر ثبت شد.
- [x] روی commit نهایی کد 87aa23b3acc7511b488f2716cea22e14152bdb87، مرحلهٔ source-level regression در UI workflow run 45963746304 موفق شده است؛ نصب Chromium و capture تصویری هنوز در حال اجراست.
- [ ] APK workflow run 45963723457 برای commit کد 91d85d9a6fb18061452ce435590514e1be13114 در صف ساخت است؛ پس از اتمام باید build provenance و Artifact بررسی شود.
- [!] UI workflow run 45963550080 روی commit 05e42355a5a1f74ecc6f9b6c169bb56ea20642be با 153/154 تست شکست خورد؛ تنها شکست assertion متن خطای ورودی نامعتبر بود و در commit بعدی اصلاح شد. run جدید 45963746304 مرحلهٔ منبعی را با موفقیت گذرانده است.
- [!] PR #64 باز، Draft، merged=false و mergeable=false باقی است؛ compare با main فعلی df0a9927451f3b8092997b6d573e62fda235b84d برابر 265 commit جلو و 3 commit عقب است. هیچ merge/rebase انجام نشد.
- [x] وضعیت Production همچنان فقط‌خواندنی است؛ هیچ Edge Function، Cron، Worker، DB، Wallet، سفارش یا تنظیم Auth تغییر نکرده است.
## تأیید ریشه‌ای 502 بازار تومانی با تطبیق PostgreSQL و Edge logs — ۲۷ نوامبر ۲۰۲۶
- [x] نسخهٔ واقعاً مستقر Supabase برای refresh-toman-market-prices نسخه ۳ و SHA-256 برابر bd85141a8dbe59329235b5266ee391c6953865e97e91253f3e3e3946b155b391 است؛ source آن ۱۳٬۵۷۶ کاراکتر دارد، upsert/dedupe/provider-summary/stage logging ندارد و DELETE cleanup دارد.
- [x] فایل منبع هم‌نام در GitHub main با blob SHA برابر 9ad3d944bcf61a22296b4b124dda8120d39933f4 و طول ۱۴٬۱۹۹ کاراکتر، upsert با on_conflict دقیق، dedupe، provider summary ساختاریافته، stage logging و بدون DELETE دارد. بنابراین منبع GitHub main و کد Production واقعاً متفاوت‌اند؛ اصلاحات از قبل در main موجودند و نباید دوباره پیاده‌سازی شوند.
- [x] PostgreSQL در ۲۴ ساعت لاگ در دسترس دقیقاً ۱۲ خطای duplicate key با SQLSTATE 23505 روی constraint market_toman_prices_exchange_asset_symbol_quote_currency_key ثبت کرده است.
- [x] Edge logs در همان بازه دقیقاً ۱۲ پاسخ POST/502 و ۱۳ پاسخ POST/200 ثبت کرده‌اند. تطبیق زمانی self-join نشان داد هر ۱۲ خطای duplicate key با یکی از ۱۲ پاسخ 502 در فاصله کمتر از ۱۰۰۰ms جفت می‌شود؛ میانگین فاصله ۵۲٫۵ms و بیشینه ۶۴ms است. این ۱۲/۱۲ تطبیق، علت تمام 502های موجود در بازه را به‌طور قطعی به INSERT تکراری نسخه مستقر نسبت می‌دهد.
- [x] snapshot تازه فقط‌خواندنی: market_toman_prices برابر ۳۷۳ ردیف، صفر ردیف تازه در پنج دقیقه، آخرین fetched_at برابر ۱۷ نوامبر؛ market_prices برابر ۸۹۹ ردیف و ۶۶۸ ردیف تازه در پنج دقیقه.
- [x] کد اصلاحی و تست‌های persistence از قبل در GitHub main وجود دارند؛ تغییر لازم برای رفع این علت، استقرار کنترل‌شدهٔ همان کد اصلاحی موجود پس از بررسی کامل و تأیید مالک است، نه Migration یا تغییر schema.
- [!] Production دست‌نخورده باقی ماند: هیچ Edge Function deploy، refresh دستی، DELETE، upsert، Cron change یا DB write انجام نشد. استقرار تا تأیید صریح مالک متوقف است.
- [x] UI visual workflow run 45963746304 روی کد 87aa23b3acc7511b488f2716cea22e14152bdb87 با نتیجه success پایان یافت؛ source-level tests و capture تصویری موفق شدند.
- [ ] APK workflow run 45963723457 هنوز باید از نظر build، provenance و artifact نهایی بررسی شود.
- [!] PR #64 همچنان Draft، باز، ادغام‌نشده و mergeable=false است؛ وضعیت compare با main فعلی: ۲۶۸ جلو و ۳ عقب. هیچ merge/rebase انجام نشد.