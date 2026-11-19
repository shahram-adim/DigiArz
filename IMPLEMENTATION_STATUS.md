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
