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


## بازطراحی مستقل DigiArz — ۲۰ نوامبر ۲۰۲۶، نوبت ادامه
- [x] بنا به درخواست کاربر، طرح‌های قبلی مبنای طراحی تازه قرار نگرفتند؛ شاخهٔ مستقل redesign/independent-ui-2026 مستقیماً از main در commit af0022d2ee887fe101a2403b9d7d2c8f0b1fad4b ساخته شد.
- [x] PR شمارهٔ ۳۱ به‌صورت Draft باز شد: https://github.com/shahram-adim/DigiArz/pull/31؛ مقصد main است و ادغام نشده است.
- [x] فایل تازهٔ src/digiarz-independent-ui.css با هویت بصری مستقل deep-teal/mint، RTL و واکنش‌گرا افزوده شد. پوشش آن شامل صفحه ورود، داشبورد، بازارها، میز معامله، دارایی‌ها، سفارش‌ها، تاریخچه، تنظیمات و ناوبری موبایل است.
- [x] stylesheet در انتهای head و پس از استایل‌های inline بارگذاری می‌شود تا لایهٔ تازه بر قواعد قدیمی غلبه کند؛ هیچ منطق احراز هویت، قیمت، معامله یا RPC تغییر نکرد.
- [x] Service Worker به cache نسخهٔ digiarz-shell-v59 ارتقا یافت و stylesheet جدید با همان query string ?v=1 به app shell اضافه شد.
- [x] آزمون رگرسیون برای ترتیب بارگذاری stylesheet، پوشش صفحات/رنگ‌های جدید، حفظ شناسه‌های کلیدی Auth/Trading و cache شدن فایل جدید افزوده شد.
- [x] آخرین commit شاخه هنگام این ثبت: 60986a981a944765aa019b2e1dbbb895ed0c406b.
- [x] PR #31 در CI اجرای Exact Decimal با run 44683461748 / Run #950 قرار گرفت؛ هنگام ثبت، job exact-decimal در مرحلهٔ آماده‌سازی container و هنوز بدون نتیجهٔ نهایی بود.
- [!] ساخت APK مخصوص این بازطراحی هنوز تأیید نشده است؛ Build 72 متعلق به شاخه/طرح قبلی است و نباید به‌عنوان APK این طراحی معرفی شود.
- [!] رندر واقعی Android/WebView هنوز بررسی نشده است؛ PR تا پایان CI و بررسی بصری Draft می‌ماند. main تغییر نکرده و هیچ تغییری در Supabase Production انجام نشده است.

### بررسی 504 هم‌زمان با بازطراحی
- [x] پروژهٔ Supabase gfoaubfilhttnwjykaox در زمان بررسی ACTIVE_HEALTHY و PostgreSQL 17.11.0.018 بود.
- [x] در بازهٔ ۲۴ ساعت اخیر، رویدادهای 504 در Auth /token و /user با context deadline exceeded ثبت شده‌اند؛ آخرین مورد در 2026-11-19 21:51:37 UTC.
- [x] در همان بازهٔ 21:45 تا 22:00 UTC، چندین cron job startup timeout برای jobهای متعدد و پیام‌های مکرر could not accept SSL connection: Connection reset by peer ثبت شده‌اند؛ این هم‌زمانی با اختلال گسترده‌تر مسیر اتصال/پاسخ‌گویی PostgreSQL سازگار است، اما علت ریشه‌ای زیرساختی را به‌تنهایی اثبات نمی‌کند.
- [x] در پنجرهٔ ۶ ساعت منتهی به حدود 2026-11-20 05:44 UTC، رویداد تازه‌ای با متن 504، timeout، SSL reset یا EOF در منابع بررسی‌شده دیده نشد؛ این فقط نبود رویداد در آن پنجره است و اثبات رفع پایدار نیست.
- [!] هیچ Auth setting، timeout، cron schedule، migration، RPC، policy، grant یا دادهٔ مالی در Production تغییر نکرد.
- [ ] گام بعد 504: پایش مجدد Auth و Postgres در پنجرهٔ ۲۴ ساعته و تطبیق request idهای Auth با رویدادهای Postgres/PgBouncer؛ تا شناسایی علت قطعی، تغییر Production انجام نشود.
- [ ] گام بعد UI: تکمیل CI، اصلاح شکست‌ها، اجرای build APK از همین شاخه و بررسی بصری نسخهٔ نصب‌شده؛ پس از آن دریافت بازخورد کاربر و تصمیم جداگانه برای merge.


### اصلاح خطاهای اولیهٔ CI بازطراحی مستقل — ۲۰ نوامبر ۲۰۲۶
- [x] Exact Decimal Run #950 با شناسهٔ 44683461748 روی commit قبلی شکست خورد؛ شکست از منطق معاملات یا PostgreSQL نبود و در مرحلهٔ Node/browser integration متوقف شد.
- [x] تست جدید ابتدا فرض کرده بود stylesheet در head بارگذاری می‌شود؛ بررسی HTML واقعی نشان داد آخرین بلوک inline style در انتهای فایل و پس از head قرار دارد. لینک stylesheet به بعد از آخرین بلوک style و پیش از بسته‌شدن body منتقل شد تا از تمام قواعد قبلی تقدم قطعی داشته باشد.
- [x] تست Service Worker نیز تعداد cache shell را ثابت و برابر ۱۰ فرض کرده بود؛ با اضافه‌شدن فایل CSS، تعداد درست ۱۱ شد. تست اکنون هم تعداد و هم مسیر دقیق فایل cache‌شده را بررسی می‌کند.
- [x] assertion تست ترتیب stylesheet با محل واقعی لینک جدید هماهنگ شد. بررسی مستقیم فایل‌ها در GitHub نشان داد ترتیب لینک، cache v59، query string فایل و شناسه‌های حیاتی ورود/معامله برقرارند.
- [x] آخرین commit شاخه پس از این اصلاحات: df116a8601c409cf954a08a71c35957b51fe08fe.
- [!] پس از commit اصلاحی، هنوز اجرای CI تازه‌ای از ابزار قابل مشاهده نبود؛ نتیجهٔ Run #950 مربوط به commit قبلی است و نباید موفق فرض شود.
- [ ] گام بعد: اجرای مجدد CI روی آخرین head، بررسی تمام تست‌ها، سپس ساخت APK مستقل از همین شاخه. PR #31 همچنان Draft و main بدون تغییر است.


### پایش تکمیلی 504 و CI — ۲۰ نوامبر ۲۰۲۶، حدود ۰۵:۵۲ UTC
- [x] بررسی مجدد cron.job_run_details برای jobهای 2، 3، 4، 5، 8، 9، 11، 12، 13، 14، 15، 16، 17 و 18 نشان داد آخرین شکست‌ها حداکثر تا 2026-11-19 22:36 UTC بوده‌اند؛ پس از آن اجراهای موفق تا 2026-11-20 05:51 UTC ثبت شده‌اند.
- [x] آخرین اجرای مشاهده‌شدهٔ job 14 در 05:51 UTC موفق شد و حدود 27 ثانیه طول کشید؛ سایر jobهای بررسی‌شده نیز اجرای موفق اخیر داشتند.
- [x] در لاگ‌های ۶ ساعت اخیر هیچ رویداد تازهٔ 504، timeout، SSL reset یا EOF در منابع بررسی‌شده مشاهده نشد.
- [!] این وضعیت نشان‌دهندهٔ بازیابی عملیاتی در پنجرهٔ اخیر است، نه اثبات رفع ریشه‌ای یا دائمی علت 504؛ تنظیمات Production تغییر نکرده‌اند.
- [x] فایل CSS جدید از نظر توازن آکولادها/پرانتزها و بسته‌شدن comment/string بررسی شد؛ ساختار متنی متوازن است و شناسه‌های کلیدی Auth/Trading در HTML باقی مانده‌اند.
- [!] Run #950 روی commit قدیمی‌تر شکست خورد؛ دو assertion ناسازگار با ترتیب واقعی stylesheet و تعداد precache شناسایی و اصلاح شدند. پس از اصلاحات، اجرای تازه‌ای از ابزار قابل مشاهده نبود؛ تا اجرای مجدد، CI سبز محسوب نمی‌شود.


### ادامه بازطراحی مستقل — ۲۰ نوامبر ۲۰۲۶، حدود ۰۶:۰۵ UTC
- [x] اجرای CI شماره 954 روی commit قبلی شاخه، 55 تست از 56 تست را گذراند؛ تنها تست شکست‌خورده بررسی پوشش selectorهای صفحات اصلی بود و نبود selectorهای صریح `#tab-markets`، `#tab-trade`، `#tab-assets`، `#tab-orders`، `#tab-history` و `#tab-settings` را گزارش کرد.
- [x] selectorهای صریح صفحات اصلی به `src/digiarz-independent-ui.css` افزوده شدند.
- [x] برای جلوگیری از نمایش نسخه قدیمی CSS از Cache Storage، پارامتر فایل CSS از `v=1` به `v=2` و نام cache از `digiarz-shell-v59` به `digiarz-shell-v60` ارتقا یافت.
- [x] تغییرات روی شاخه مستقل ثبت شدند؛ آخرین commit فعلی: `da1eb2f51209a042c45223c5f3eb92f5d70b25cd`.
- [!] پس از آخرین commit، اجرای CI تازه هنوز از ابزار قابل مشاهده نیست؛ نتیجه سبز محسوب نشود.
- [ ] گام بعد: بررسی اجرای CI روی آخرین head، رفع هر شکست باقی‌مانده، سپس ساخت APK مستقل و بررسی بصری روی Android.
- [!] هیچ تغییری در main، منطق ورود، موجودی، سفارش‌ها، معاملات، Supabase یا داده‌های Production انجام نشد.


### اصلاح ناسازگاری تست‌های CI — ۲۰ نوامبر ۲۰۲۶، حدود ۰۶:۳۰ UTC
- [x] اجرای CI شماره 959 بررسی شد؛ دو تست شکست‌خورده مربوط به انتظارات قدیمی در فایل‌های تست بودند: تست index هنوز stylesheet با `v=1` و cache با `v59` را انتظار داشت؛ تست Service Worker نیز CSS با `v=1` را در precache انتظار داشت.
- [x] فایل `tests/index-syntax.test.js` با نسخه واقعی stylesheet `v=2` و cache `v60` همگام شد.
- [x] فایل `tests/service-worker.test.js` با stylesheet `v=2` و حذف cacheهای قدیمی تا `v59` همگام شد.
- [x] بررسی متقاطع شاخه نشان داد لینک CSS بعد از تمام styleهای inline قرار دارد؛ شش صفحه اصلی selector صریح دارند؛ Service Worker، HTML و تست‌ها همگی نسخه `v2/v60` را به‌صورت یکسان استفاده می‌کنند و هیچ ارجاع باقی‌مانده به CSS `v1` در این فایل‌ها نیست.
- [x] مقایسه با main: شاخه مستقل 18 commit جلوتر و 0 commit عقب‌تر است؛ فایل‌های اصلی تغییرات فقط HTML، CSS مستقل، Service Worker، تست‌ها و ثبت وضعیت هستند.
- [!] اجرای تازه CI روی آخرین head هنوز از اتصال GitHub قابل مشاهده نیست؛ تست‌ها هنوز سبز اعلام نمی‌شوند. دسترسی شبکه محیط اجرای محلی نیز برای clone از GitHub برقرار نشد، بنابراین اجرای محلی جایگزین انجام نشد.
- [x] بررسی لاگ Supabase برای بازه 2026-11-20 00:00 تا 06:30 UTC هیچ رویداد تازه 504/timeout نشان نداد؛ این صرفاً نبود رخداد در بازه بررسی‌شده است و اثبات رفع دائمی نیست.
- [ ] گام بعد: مشاهده CI تازه روی آخرین head، سپس اجرای build وب/Android و بررسی APK؛ تا آن زمان PR در حالت Draft و main بدون تغییر باقی بماند.


### اصلاح assertion باقی‌ماندهٔ CI بازطراحی مستقل — ۲۰ نوامبر ۲۰۲۶، پس از ۰۶:۰۷ UTC
- [x] اجرای Exact Decimal Run #961 روی commit `aa07c31285d52894054832216c60a7c841a865e4` بررسی شد؛ ۵۵ تست از ۵۶ تست موفق بودند.
- [x] علت تست شکست‌خورده پیدا شد: در `tests/index-syntax.test.js` assertion مربوط به Service Worker هنوز query string قدیمی `v=1` را انتظار داشت، درحالی‌که فایل `sw.js` و HTML از `v=2` استفاده می‌کنند.
- [x] assertion با نسخه واقعی `v=2` هماهنگ شد و روی شاخه مستقل commit شد: `a709c970fe122353f15aae7c3f8e35505be3fec8`.
- [x] شاخه مستقل اکنون ۲۰ commit جلوتر و صفر commit عقب‌تر از `main` است؛ PR #31 همچنان Draft و ادغام‌نشده است.
- [!] اجرای CI تازه برای commit اصلاحی هنوز از اتصال GitHub قابل مشاهده نیست؛ موفقیت تست‌ها هنوز تأیید نشده است.
- [ ] گام بعد: بررسی اجرای CI روی head جدید؛ در صورت موفقیت، اجرای workflow ساخت Android از همین شاخه و بررسی artifact واقعی APK. هیچ تغییری در main یا Supabase Production انجام نشد.


### موفقیت CI و فعال‌سازی ساخت APK برای بازطراحی مستقل — ۲۰ نوامبر ۲۰۲۶
- [x] اجرای Exact Decimal Run #963 روی head قبلی بازطراحی (2cf2213d1280939d6665bae2caaec42a55ed6b3d) کامل شد؛ job واحد و تمام مراحل آن با نتیجه success ثبت شدند.
- [x] PR #31 همچنان Draft و ادغام‌نشده است؛ شاخه مستقل ۲۱ commit جلوتر و صفر commit عقب‌تر از main است.
- [x] مشخص شد workflow ساخت APK فقط برای push به main یا اجرای دستی فعال بود؛ بنابراین pushهای شاخه مستقل APK نمی‌ساختند.
- [x] workflow فقط در شاخه redesign/independent-ui-2026 اصلاح شد تا pushهای همین شاخه نیز ساخت APK را فعال کنند؛ commit اصلاح workflow: 09e16659bab3b4e4ddd71892e8aa8e72ce014d2f.
- [!] ساخت APK برای commit workflow هنوز باید در GitHub Actions اجرا و نتیجه‌اش بررسی شود. APK قابل دانلود یا نصب برای بازطراحی مستقل هنوز تأیید نشده است.
- [!] CI موفق #963 مربوط به head قبل از تغییر workflow است؛ باید CI مجدد روی head جدید نیز بررسی شود.
- [ ] گام بعد: تأیید اجرای CI و workflow اندروید روی head جدید، بررسی artifact و SHA-256 فایل APK؛ سپس ارائه لینک دقیق دانلود. PR ادغام نشود و main و Supabase Production دست‌نخورده بمانند.


### ساخت موفق APK بازطراحی مستقل — ۲۰ نوامبر ۲۰۲۶
- [x] اجرای Android APK workflow شماره 73 با run ID `44686197402` روی commit `09e16659bab3b4e4ddd71892e8aa8e72ce014d2f` با نتیجه success کامل شد.
- [x] artifact واقعی `DigiArz-Android-debug-APK` با شناسه `14606307981` تولید و دریافت شد؛ اندازه ZIP برابر 3,530,194 بایت است.
- [x] محتوای آرشیو بررسی شد: `app-debug.apk` و `BUILD-INFO.txt`. APK با نسخه 1.0.0 از شاخه `redesign/independent-ui-2026` ساخته شده است؛ زمان ساخت 2026-11-20T06:14:27Z.
- [x] SHA-256 APK: `0768464127129c68b64905b0d9205d75b10897b45653ada1b7a9aa2d264df9de`.
- [x] Exact Decimal Run #964 روی commit workflow و Run #965 روی head وضعیت پروژه `102c3f52ed07d073b2cb9bde8be0352d28d0e30d` هر دو success شدند.
- [!] APK خروجی Debug و برای آزمایش است؛ نصب و رندر واقعی روی گوشی Android کاربر هنوز تأیید نشده است.
- [x] فایل APK از آرشیو استخراج و برای دریافت در گفتگو آماده شد؛ artifact اصلی GitHub تا 2026-12-04T06:14:27Z منقضی نمی‌شود.
- [!] artifact APK روی commit `09e16659bab3b4e4ddd71892e8aa8e72ce014d2f` ساخته شده؛ CI جدیدتر روی head مستندات `102c3f52ed07d073b2cb9bde8be0352d28d0e30d` نیز سبز است، اما APK مجدداً روی head مستندات ساخته نشده است.
- [ ] گام بعد: کاربر APK را نصب و صفحات اصلی را روی گوشی بررسی کند؛ هر ایراد بصری/اجرایی ثبت و فقط در شاخه مستقل اصلاح شود. PR #31 Draft بماند و merge نشود تا تأیید بصری کاربر.
- [x] هیچ تغییری در main یا Supabase Production انجام نشد.


### ادامه بررسی بازطراحی و پایش 504 — ۲۰ نوامبر ۲۰۲۶، پس از اجرای CI #966
- [x] Exact Decimal workflow run #966 با شناسهٔ `44686514949` روی head فعلی PR #31 (`9df2561c3a143f005db4e5b715f1ac03fb2a3074`) کامل شد؛ job `exact-decimal` و تمام ۲۱ مرحلهٔ اجرایی آن موفق شدند.
- [x] فایل APK بارگذاری‌شده در گفتگو از نظر نوع Android package و محتوای ZIP بررسی شد؛ فایل `src/digiarz-independent-ui.css` در assets بسته وجود دارد. SHA-256 فایل بارگذاری‌شده با APK ساخته‌شده در workflow #73 یکسان است: `0768464127129c68b64905b0d9205d75b10897b45653ada1b7a9aa2d264df9de`. بنابراین این فایل همان APK قبلی بازطراحی مستقل است، نه تصویر صفحهٔ اجرای برنامه.
- [x] وضعیت Supabase در بررسی جدید همچنان `ACTIVE_HEALTHY` و PostgreSQL 17.11.0.018 بود.
- [!] پایش unified logs در پنجرهٔ پیش‌فرض ۲۴ ساعته هنوز 504 را نشان می‌دهد: ۲۳ رویداد Auth و ۱۵ رویداد Edge با آخرین زمان Auth برابر 2026-11-19 21:51:37 UTC و آخرین 504 Edge برابر 2026-11-19 21:50:59 UTC. این‌ها ممکن است بخشی از یک درخواست تکرارشده/هم‌بسته باشند و نباید به‌عنوان ۳۸ درخواست مستقل تعبیر شوند.
- [!] در همان پنجره، ۶۴۰ رویداد SSL connection reset تا 2026-11-19 22:34:14 UTC، و چندین سری cron startup timeout تا 2026-11-19 22:36:10 UTC ثبت شده‌اند. همچنین ۲۲۶ رویداد statement timeout با آخرین زمان 2026-11-19 22:31:03 UTC دیده شد. شواهد با اختلال گذرای اتصال/پاسخ‌گویی Postgres سازگارند، اما علت ریشه‌ای را قطعی نمی‌کنند.
- [!] آخرین 504های مشاهده‌شده مربوط به 2026-11-19 شب UTC هستند؛ نبود 504 جدیدتر در لاگ‌های فعلی به‌تنهایی رفع پایدار را ثابت نمی‌کند.
- [x] هیچ تنظیم Auth، timeout، cron، migration، RPC، policy، grant، سفارش، معامله، کیف پول، موجودی یا دادهٔ Production تغییر نکرد.
- [ ] گام بعد UI: نصب APK روی Android و ارسال screenshot واقعی از صفحهٔ بازشده؛ فایل فعلی ارسالی APK است و رندر روی گوشی هنوز قابل تأیید نیست.
- [ ] گام بعد 504: ادامهٔ پایش و تطبیق request idهای Auth با Postgres/PgBouncer و بررسی resource metrics/پشتیبانی Supabase؛ تا علت ریشه‌ای روشن نشده، هیچ تغییر Production انجام نشود.
- [!] PR #31 همچنان Draft و ادغام‌نشده باقی بماند؛ main و Supabase Production دست‌نخورده‌اند.


## بازطراحی مستقل و ساخت APK اندروید — ۲۰ نوامبر ۲۰۲۶
- [x] بازطراحی مستقل در شاخه `redesign/independent-ui-2026` روی commit `ce220214592efe49994cbc1b120fcf1b3125f10b` باقی است؛ PR شمارهٔ 31 همچنان Draft و ادغام‌نشده است.
- [x] اجرای Android APK workflow شمارهٔ 76 با شناسهٔ `44692717445` روی همین commit با نتیجهٔ `success` کامل شد؛ تمام ۱۲ مرحلهٔ اصلی build، sync، assemble، provenance، upload و انتشار Release موفق شدند.
- [x] artifact `DigiArz-Android-debug-APK` با شناسهٔ `14609775245` دریافت و ZIP بررسی شد؛ شامل `app-debug.apk` به حجم 3,913,472 بایت و `BUILD-INFO.txt` است.
- [x] مقدار SHA-256 فایل APK: `a02083b2f422166aeb904e84e171fc6ebe8ce92d4b0345e80e3d0bd51f1dcd89`؛ نسخهٔ برنامه 1.0.0؛ ساخته‌شده در `2026-11-20T07:10:35Z`.
- [!] این APK نسخهٔ Debug و آزمایشی است، نه نسخهٔ انتشار امضاشده. نصب و نمایش واقعی روی گوشی کاربر هنوز تأیید نشده است.
- [!] موفقیت workflow مربوط به ساخت APK است؛ اجرای تست‌های کامل UI در مرورگر/گوشی یا رفع قطعی خطای 504 را اثبات نمی‌کند.
- [x] هیچ merge به `main` و هیچ تغییر در Supabase Production، schema، migration، RPC، تنظیمات Auth یا داده‌های مالی انجام نشد.
- [ ] گام بعد: دریافت بازخورد نصب/نمایش APK روی Android و بررسی اسکرین‌شات صفحات؛ ادامهٔ پایش خطاهای Auth/Edge 504 به‌صورت فقط‌خواندنی تا روشن‌شدن علت ریشه‌ای.


## بازبینی و اصلاح بصری تم‌ها، ورود و داشبورد — ۲۰ نوامبر ۲۰۲۶
- [x] گزارش کاربر درباره شباهت سه تم، ظاهر ابتدایی صفحه ورود، فیروزه‌ای شدن سراسری آیکون‌ها و به‌هم‌ریختگی داشبورد به‌عنوان چهار ایراد مستقل ثبت شد.
- [x] علت CSS بررسی شد: لایهٔ مستقل قبلی رنگ دکمه‌ها و برخی آیکون‌ها را به سبزآبی ثابت می‌کرد؛ فقط برای تم روشن بخشی از متغیرها override شده بود؛ ساختار ورود قبلی نیز رنگ‌های ثابت سرمه‌ای/طلایی داشت و هویت تم‌ها را خنثی می‌کرد.
- [x] در src/digiarz-independent-ui.css لایهٔ DigiArz visual correction v3 اضافه شد: پالت مستقل برای dark (ذغالی/طلایی)، light (روشن/آبی) و luxury (سرمه‌ای شیشه‌ای/طلایی)، کنترل‌های خنثی با دکمه‌های اصلی معنایی، رنگ آیکون‌های وابسته به کاربرد، بازطراحی ظاهری فرم ورود و نظم‌دهی کارت‌ها/فیلترها/بخش‌های داشبورد.
- [x] در index.html نسخهٔ stylesheet از v=2 به v=3 تغییر کرد تا کش قدیمی مرورگر/PWA از فایل قبلی استفاده نکند.
- [x] فقط فایل‌های CSS و ارجاع نسخهٔ CSS تغییر کردند؛ handlerهای applyTheme و initTheme، انتخاب خانواده آیکون، اتصال ورود/داشبورد، منطق معاملات، داده‌ها و Supabase دست‌نخورده ماندند.
- [x] بازخوانی GitHub تأیید کرد سه پالت تم، اصلاح reset آیکون‌ها، اصلاح صفحه ورود، اصلاح داشبورد و ارجاع کش v=3 در شاخه وجود دارند.
- [!] وضعیت CI برای commit نهایی از ابزار فعلی قابل مشاهده نبود (هیچ workflow run یا status check برنگشت)؛ بنابراین موفقیت تست یا build ادعا نمی‌شود.
- [!] ظاهر نهایی هنوز روی گوشی Android مشاهده و تأیید نشده است؛ این مرحله نیازمند ساخت APK تازه از همین شاخه و بررسی هر سه تم در صفحه ورود و داشبورد است.
- [!] شاخهٔ کاری redesign/independent-ui-2026 و PR #31 همچنان مستقل از main است؛ هیچ merge یا تغییری در Production/Supabase انجام نشد.
- **آخرین commit این مرحله:** 2867369577100b019f43a51370ce17882083316d.
- **قدم بعدی:** اجرای تست‌های رابط/CI و ساخت APK از همین commit؛ سپس بررسی تصویری هر سه تم روی گوشی و رفع ایرادهای باقی‌مانده پیش از هرگونه ادغام.


### تکمیل نگاشت رنگ‌های قدیمی آیکون‌ها — ۲۰ نوامبر ۲۰۲۶
- [x] برخی اجزای قدیمی هنوز از متغیر legacy با نام --da-mint استفاده می‌کردند؛ مقدار این متغیر اکنون برای هر تم جداگانه تنظیم شد تا رنگ فیروزه‌ای قدیمی از قواعد باقی‌مانده به صفحات نشت نکند.
- [x] ارجاع stylesheet به v=4 ارتقا یافت تا نسخهٔ تازه در مرورگر و پوستهٔ PWA بارگذاری شود.
- [!] هنوز APK جدید ساخته و روی گوشی مشاهده نشده است؛ بنابراین تأیید نهایی دیداری سه تم و صفحه ورود/داشبورد در انتظار تست Android است.
- **آخرین commit کد UI:** 90917b5894804485735b5fc33d3b10a783daee5e.


### اصلاح تست بارگذاری CSS و cache آفلاین — ۲۰ نوامبر ۲۰۲۶
- [x] CI روی commit `4d0b91ede55fac83e31b3c723834e76db344d100` اجرا شد؛ ۵۵ تست از ۵۶ تست موفق بودند. تنها شکست، assertion قدیمی تست بود که نسخهٔ `v2` را برای لینک CSS انتظار داشت، درحالی‌که HTML به `v4` ارتقا یافته بود.
- [x] فایل `sw.js` از cache `digiarz-shell-v60` به `digiarz-shell-v61` ارتقا یافت و فایل CSS در precache به `v4` تغییر کرد.
- [x] تست `tests/index-syntax.test.js` با لینک CSS `v4`، cache `v61` و precache `v4` همگام شد؛ بازخوانی GitHub تطابق این مقادیر را تأیید کرد.
- [x] اجرای CI جدید روی آخرین commit کد تست `59720c00b5fbc8a4d215083c1b51c67c5f9360cb` آغاز شد (Run `44696487213`)؛ هنگام ثبت این یادداشت هنوز در حال اجرا بود.
- [x] ساخت APK جدید از شاخه مستقل آغاز شد (Run `44696455653`، commit کد برنامه `776b090129b7c6e4da3c39c0ecc277e91d1fde27`)؛ مراحل آماده‌سازی وب و همگام‌سازی Capacitor موفق شدند و مرحله assembleDebug در حال اجرا بود.
- [!] نتیجه نهایی CI و APK هنوز اعلام نشده و artifact تازه قابل دریافت تأیید نشده است.
- [!] هیچ merge به main و هیچ تغییری در Supabase Production انجام نشد.
- [ ] پس از پایان workflowها، نتیجهٔ تست‌ها و artifact APK بررسی شود؛ سپس نصب و مشاهدهٔ واقعی هر سه تم روی Android لازم است.


### نتیجه ساخت APK و اصلاح assertion نهایی precache — ۲۰ نوامبر ۲۰۲۶
- [x] خطای CI روی head `59720c00b5fbc8a4d215083c1b51c67c5f9360cb` ریشه‌یابی شد: تست `tests/service-worker.test.js` هنوز URL کش CSS با `v=2` را انتظار داشت، درحالی‌که `sw.js` به `v=4` ارتقا یافته بود. assertion به `v=4` اصلاح شد.
- [x] اجرای جدید Exact Decimal Run `44696640456` روی commit `6cd9c0852957795ae2504d86a5c009a4b2b70d27` آغاز شد؛ مرحلهٔ exact-decimal/browser integration tests موفق شد و آزمون‌های PostgreSQL regression در حال اجرا بودند. نتیجه نهایی کل workflow هنگام ثبت این یادداشت هنوز pending بود.
- [x] ساخت APK workflow `44696455653` روی commit برنامه `776b090129b7c6e4da3c39c0ecc277e91d1fde27` با نتیجه success کامل شد؛ artifact `14611445173` تولید و دریافت شد.
- [x] آرشیو APK باز شد و وجود `app-debug.apk` و `BUILD-INFO.txt` تأیید شد؛ SHA-256 APK برابر `a090e5d4066447f6695dd2768efa58d977a03b6880e995f7f022e084bfaf8a6c` است. فایل APK در محیط گفتگو آماده ارائه به کاربر است.
- [!] APK یک Debug/Test build است؛ هنوز نصب و بررسی دیداری روی گوشی کاربر تأیید نشده است. APK بر اساس commit برنامه `776b...` ساخته شده که شامل CSS `v4` و Service Worker cache `v61` است؛ commit بعدی فقط assertionهای تست را اصلاح کرده و منطق برنامه را تغییر نداده است.
- [!] PR #31 همچنان Draft/ادغام‌نشده است؛ main و Supabase Production تغییر نکرده‌اند.
- [ ] پس از پایان Exact Decimal Run `44696640456`، نتیجه کامل و هرگونه شکست احتمالی بررسی شود؛ سپس بازبینی دیداری Android با بازخورد کاربر ادامه یابد.


### تأیید نهایی اجرای CI و تطبیق APK — ۲۰ نوامبر ۲۰۲۶
- [x] اجرای CI شماره `44696640456` روی commit `6cd9c0852957795ae2504d86a5c009a4b2b70d27` کامل شد و job `exact-decimal` با نتیجه `success` پایان یافت؛ همه مراحل از جمله آزمون‌های PostgreSQL، migration rollback/lock timeout، integrationهای Limit/Stop-Limit/TP-SL و رقابت‌های دو-سشنی موفق شدند.
- [x] وضعیت artifact ساخت اندروید `14611445173` دوباره بررسی شد: منقضی نشده و مربوط به build موفق workflow `44696455653` است.
- [x] APK محلی از آرشیو استخراج و SHA-256 دوباره محاسبه شد: `a090e5d4066447f6695dd2768efa58d977a03b6880e995f7f022e084bfaf8a6c`؛ `BUILD-INFO.txt` نشان می‌دهد APK از شاخه `redesign/independent-ui-2026` و commit `776b090129b7c6e4da3c39c0ecc277e91d1fde27` ساخته شده و شامل `digiarz-independent-ui.css` و `sw.js` است.
- [!] APK از نظر نصب روی دستگاه Android کاربر یا ظاهر سه تم هنوز تأیید نشده؛ build موفق به‌تنهایی تأیید بصری نیست.
- [!] PR #31 هنوز باز و Draft است؛ head فعلی PR برابر `5e466d5ab8968cc588ec037fa8b88a85605414ec` و ۴۱ commit جلوتر از main است. هیچ merge انجام نشده و Supabase Production دست‌نخورده است.
- [ ] قدم بعدی: نصب APK روی گوشی کاربر، پاک‌کردن نسخه قدیمی در صورت تداخل نصب، و ثبت بازخورد/اسکرین‌شات از صفحه ورود و داشبورد در سه تم؛ سپس اصلاح فقط بر اساس ایرادهای مشاهده‌شده.


### اصلاح چیدمان موبایل صفحه ورود بر اساس اسکرین‌شات کاربر — ۲۰ نوامبر ۲۰۲۶
- [x] اسکرین‌شات واقعی Android بررسی شد؛ در عرض‌های موبایل، بخش معرفی صفحه ورود به‌دلیل ستون‌بندی اجباری `ref-hero-grid` متن و فهرست رمزارزها را فشرده و از کادر خارج می‌کرد؛ فرم نیز به‌علت نداشتن فاصلهٔ پایینی کافی می‌توانست زیر ناوبری ثابت قرار گیرد.
- [x] در انتهای `src/digiarz-independent-ui.css` اصلاح واکنش‌گرایی محدود به عرض حداکثر 760px افزوده شد: چیدمان کارت ورود به یک ستون، نمایش کامل نوشته‌ها، فهرست رمزارز دو ستونه با جلوگیری از سرریز، کوچک‌سازی متناسب صحنهٔ گرافیکی، فرم با عرض کامل و فضای امن برای نوار ناوبری پایین.
- [x] نسخه stylesheet در `index.html` به `v=5` و کش PWA در `sw.js` به `digiarz-shell-v62` ارتقا یافت؛ assertion تست `tests/index-syntax.test.js` نیز همگام شد.
- [x] فقط CSS، ارجاع نسخهٔ CSS، cache service worker و assertion تست تغییر کردند؛ HTML ساختاری صفحه ورود، شناسه‌ها/handlerهای ورود و ثبت‌نام، اتصال داشبورد، منطق معاملات و Supabase دست‌نخورده ماندند.
- [!] اجرای CI برای commitهای تازه هنوز از endpoint فعلی قابل مشاهده نیست؛ تا دریافت نتیجهٔ workflow، موفقیت تست/build جدید ادعا نمی‌شود.
- [!] این اصلاح هنوز روی گوشی کاربر نصب و تأیید نشده؛ APK قبلی شامل این اصلاح `v5` نیست و برای ارزیابی باید APK تازه از شاخهٔ مستقل ساخته شود.
- **آخرین commitهای اصلاح:** CSS `77990e618bf401835c90fdece67c9960bf45e97b`؛ نسخه HTML `1372a4af5ec7cda483ee9e7fe0cb0a454a6724a9`؛ service worker `dc0a9996abb160663f294c35aefa6a94f9041a67`؛ تست `241dfcfacd1143440fe3256962bcdde2807cd81f`.
- [!] PR #31 همچنان Draft و ادغام‌نشده باقی بماند؛ هیچ تغییری در `main` یا Supabase Production انجام نشود.


### بازطراحی تم سوم به آبی نیلی شیشه‌ای — ۲۰ نوامبر ۲۰۲۶
- [x] بنا به بازخورد کاربر، تم سوم از سرمه‌ای/طلایی به Indigo Glass تغییر کرد؛ تم تاریک و روشن تغییر نکردند.
- [x] پالت تم سوم اکنون آبی نیلی عمیق با هایلایت آبی یخی و بنفش ملایم، سطوح شفاف، borderهای نیمه‌شفاف، blur و saturation شیشه‌ای است.
- [x] تغییرات در پس‌زمینه کلی، هدر، ناوبری پایین، تب‌ها، کارت‌ها، داشبورد، هیرو، دکمه‌های اصلی، ورودی‌ها، بازار، جدول‌ها، صفحه ورود، فرم ورود و نشان‌های رمزارز اعمال شد؛ طلایی‌های قبلی در اجزای اصلی تم سوم با رنگ‌های نیلی/آبی جایگزین شدند.
- [x] فقط CSS تم سوم، نسخه stylesheet در index، cache PWA و assertion نسخه در تست تغییر کردند؛ تم مشکی/روشن، ساختار ورود و اتصال داشبورد، منطق معاملات و Supabase دست‌نخورده ماندند.
- [x] stylesheet به `v6` و کش PWA به `digiarz-shell-v63` ارتقا یافت.
- [!] CI جدید هنوز در وضعیت `in_progress` است و نتیجه نهایی ندارد؛ تا تکمیل آن APK جدید منتشر نمی‌شود.
- [!] PR #31 همچنان `open` و `Draft` است؛ ادغام انجام نشده و باید پس از تست و تأیید دیداری کاربر انجام شود.
- Commitهای اصلی: CSS `99429567f70b949c30bba17c2ad0732f7d0a643a`؛ index `0f05ef37d6f776bbb6f6f5532f0abc92076ae34a`؛ SW `c54cac585d9d710305d4483e1e92c25f54683e78`؛ تست `72d212c641ca8575fbf41dace961c203989fd91e`.


### ارتقای صحنهٔ سه‌بعدی و نمودار زنده صفحه ورود — ۲۰ نوامبر ۲۰۲۶
- [x] بازبینی کد موجود نشان داد کره، گوشی، سکه‌ها و نمودار قبلاً با SVG/CSS و کندل‌های واقعی پنج‌دقیقه‌ای بازار نمایش داده می‌شدند؛ اما انیمیشن صحنه محدود بود و نمودار فقط هر ۶۰ ثانیه بازخوانی می‌شد.
- [x] به صحنهٔ ورود عمق سه‌بعدی، نور و سایهٔ بیشتر، حرکت شناور کره و گوشی، چرخش/شناوری سکه‌ها، قاب فلزی و بازتاب روی بدنه گوشی اضافه شد؛ برای تم Indigo Glass سکه‌ها و سکوی نمایش نیز آبی/نیلی شدند.
- [x] نمودار کندلی حفظ شد و به‌جای داده ساختگی، آخرین کندل با قیمت واقعی BTC از endpoint امن `market-data` به‌روزرسانی می‌شود؛ تیک هر ۴ ثانیه از مسیر پشتیبانی‌شده `ticker/24hr` و فیلد `lastPrice` می‌آید. خط/نقطهٔ قیمت لحظه‌ای نیز روی نمودار نمایش داده می‌شود. تاریخچه کندل‌ها همچنان هر ۶۰ ثانیه تازه می‌شود.
- [x] حالت `prefers-reduced-motion` برای کاربرانی که حرکت کمتر درخواست می‌کنند اضافه شد.
- [x] تغییرات در `src/digiarz-independent-ui.css`, `index.html`, `sw.js` و assertion تست نسخه stylesheet انجام شد؛ stylesheet `v7` و cache `digiarz-shell-v64` است.
- [x] endpoint اشتباه اولیهٔ `ticker/price` قبل از نهایی‌سازی به endpoint پشتیبانی‌شدهٔ `ticker/24hr` تغییر کرد؛ فراخوانی قیمت فقط از secure market gateway موجود استفاده می‌کند، بدون اتصال مستقیم جدید به API خارجی.
- [!] برای commitهای این مرحله هنوز workflow/check-run جدیدی از GitHub برنگشته؛ تست و APK تازه هنوز تأیید نشده‌اند.
- [!] بازخورد کاربر درباره ظاهر سه‌بعدی پس از نصب APK جدید لازم است؛ SVG موجود بهبود یافته و متحرک شده اما جایگزین تصویر عکاسی واقعی/فایل سه‌بعدی نیست.
- Commitها: CSS `98fee027cc8429f4ef2229f9ea3e1b15babe335d`; index با حرکت نمودار `c6293b363c1a33c3ac1e29440ca3e8ff983e48a9`, سپس اصلاح endpoint `ff1274635689c3711c7832b4e8bddba6367eaa66`; SW `5c740b4055f35b26393dae8e04b2b4b643ee7ed7`; تست `9f6c82d8cd6789645dae2979bca388934efb6e04`.
- [!] PR #31 همچنان باز و Draft است؛ merge و تغییر Production ممنوع تا تأیید دیداری کاربر.


### ادامهٔ CI و همگام‌سازی assertionهای قدیمی — ۲۰ نوامبر ۲۰۲۶، ۰۸:۰۵ UTC
- [x] وضعیت واقعی شاخه و PR بررسی شد؛ PR #31 همچنان Draft و باز است و head شاخه `f2b52249dbc68659cedf87524b66349c9d6de0c2` است.
- [x] علت سه شکست تست از لاگ workflow قبلی مشخص شد: assertionهای قدیمی در `tests/index-syntax.test.js` و `tests/service-worker.test.js` هنوز انتظار عنوان/رفتار قبلی نمودار و CSS `v4` را داشتند.
- [x] تست index با عنوان نمودار کندلی زنده، `authMiniCandles` و CSS `v7` همگام شد؛ تست Service Worker نیز انتظار CSS `v7` را دارد.
- [x] آخرین check-run برای head فعلی، workflow `44699637191` / job `136164593753` است و در آخرین بررسی وضعیت `in_progress` داشت؛ نتیجه نهایی هنوز معلوم نیست. لاگ job در حال اجرا از endpoint لاگ در دسترس نبود.
- [!] APK جدید هنوز ساخته/تأیید نشده؛ فقط پس از سبز شدن CI باید build جدید درخواست/بررسی شود.
- [!] هیچ merge، تغییری روی `main` یا تغییری در Supabase Production انجام نشده است.
- Commitهای اصلاح تست: `b32f6e1b74cc46f3cd0c5aae675e20f5e01dc7da` و `f2b52249dbc68659cedf87524b66349c9d6de0c2`.


### تأیید CI برای انیمیشن صحنه ورود و نمودار زنده — ۲۰ نوامبر ۲۰۲۶، ۰۸:۰۷ UTC
- [x] workflow `44699810671` روی commit `c4aecaedf744d1194027a7414b40413c40e0f1d9` با نتیجه `success` تمام شد؛ job `exact-decimal` نیز موفق است.
- [x] PR #31 همچنان باز و Draft است؛ head شاخه با commit فوق تطابق دارد.
- [!] هنوز artifact مربوط به APK جدید برای این commit تأیید نشده است. APK قدیمی run `44696455653` مربوط به commit قدیمی‌تر است و نباید به‌عنوان نسخهٔ شامل انیمیشن/نمودار زنده معرفی شود.
- [!] merge به main و هرگونه تغییر Supabase Production همچنان متوقف است تا کاربر ظاهر را روی گوشی تأیید کند.


### اجرای مجدد ساخت APK برای بازطراحی مستقل — ۲۰ نوامبر ۲۰۲۶
- [x] فایل workflow اندروید در شاخه `redesign/independent-ui-2026` بازبینی شد؛ workflow دارای `workflow_dispatch` و trigger روی push همین شاخه و تغییر مسیرهای UI است.
- [x] چون ابزار اتصال GitHub در این نشست عملیات مستقیم `workflow_dispatch` ارائه نمی‌کند، یک تغییر بی‌اثرِ توضیحی (comment-only) به فایل `.github/workflows/android-apk.yml` اضافه شد تا trigger مجاز push اجرا شود؛ هیچ دستور build یا تنظیم workflow تغییر نکرد.
- [x] commit محرک build: `1269f6f205c7a146e1a7b047164fc16cab275864`.
- [!] wrapper مشاهدهٔ runهای commit فقط اجراهای pull_request را برمی‌گرداند؛ بنابراین اجرای push-triggered و شناسه run هنوز از این مسیر قابل تأیید نیست. artifact APK جدید هنوز تأیید نشده است.
- [!] PR #31 همچنان باید Draft و ادغام‌نشده بماند؛ هیچ تغییر در `main` یا Supabase Production انجام نشود.


### ساخت و تأیید APK بازطراحی مستقل — ۲۰ نوامبر ۲۰۲۶، ۰۸:۱۰ UTC
- [x] اجرای Android APK workflow شماره `44700246621` روی شاخه `redesign/independent-ui-2026` با نتیجه `success` کامل شد؛ job `build-debug-apk` و تمام ۱۲ مرحلهٔ اصلی آن موفق بودند.
- [x] artifact تازه `DigiArz-Android-debug-APK` با شناسه `14612551834` دریافت شد؛ artifact منقضی نشده و تا ۴ دسامبر ۲۰۲۶ نگهداری می‌شود.
- [x] آرشیو بررسی شد و شامل `app-debug.apk` و `BUILD-INFO.txt` است. فایل provenance تأیید می‌کند build از commit `1269f6f205c7a146e1a7b047164fc16cab275864` روی شاخهٔ بازطراحی ساخته شده است.
- [x] SHA-256 فایل APK استخراج‌شده: `a7584a10c16627f16c88d2b6d89a96b92aca62a8b5350becb0fee2a7a7692f3c`.
- [!] APK یک Debug/Test build است؛ نصب و بازبینی دیداری آن روی گوشی کاربر هنوز تأیید نشده است. commit ساخت `1269f6f...` شامل تغییرات UI و workflow است؛ commit فعلی شاخه `4ac3cc...` فقط مستندسازی وضعیت را پس از آن اضافه کرده است.
- [!] اجرای Exact Decimal Tests شماره `44700274154` روی head فعلی `4ac3cc...` نیز با نتیجه `success` تمام شد.
- [!] PR #31 باید تا بازبینی و تأیید صریح کاربر باز و Draft بماند؛ هیچ merge به `main` و هیچ تغییری در Supabase Production انجام نشود.
- [ ] قدم بعدی: کاربر APK تازه را روی Android نصب کند و از صفحهٔ ورود و داشبورد در هر سه تم بازخورد/تصویر بفرستد؛ سپس اصلاحات فقط بر اساس موارد مشاهده‌شده انجام شود.


### رفع باقی‌ماندن صفحه ورود و همگام‌سازی کش آفلاین — ۲۰ نوامبر ۲۰۲۶
- [x] علت باقی‌ماندن صفحه ورود پیدا شد: قانون پایهٔ `#authView{display:grid!important}` بر کلاس عمومی `.hidden{display:none!important}` غلبه می‌کرد؛ بنابراین authView حتی پس از ورود موفق همچنان نمایش داده می‌شد.
- [x] قانون اختصاصی `#authView.hidden{display:none!important}` به انتهای stylesheet افزوده شد تا هنگام مخفی‌شدن صفحه ورود، اولویت صحیح داشته باشد؛ منطق Supabase، ورود، ثبت‌نام، بازیابی رمز و اتصال داشبورد تغییر نکرد.
- [x] ارجاع CSS در `index.html` روی `v=9` باقی است و Service Worker به cache جدید `digiarz-shell-v65` ارتقا یافت و اکنون همان CSS `v=9` را در پوسته آفلاین precache می‌کند.
- [x] تست‌های رگرسیون همگام شدند: تست index وجود قانون مخفی‌سازی authView و نسخه stylesheet را بررسی می‌کند؛ تست Service Worker نیز CSS `v=9` و پاک‌سازی cacheهای قدیمی تا `v64` را بررسی می‌کند.
- [x] commitهای این مرحله: CSS `a6600bdeddd0407437333a531223de2db0ea30a1`؛ index/cache-buster `3de121e8c609430c03c3fc0dc8ebe9bea645462d`؛ Service Worker `f5be4d2af2c7dacff1ab6fa09bc2a31c7e309816`؛ تست Service Worker `bb328084b22c99283cf9031837fc9ac13d845e9e`؛ تست ورود `f41886cf129e18ac79c3b6f5ec18cf6eaa6943f6`.
- [!] اجرای CI جدید و ساخت APK شامل این اصلاحات هنوز تأیید نشده است؛ تست روی گوشی نیز لازم است.
- [!] PR #31 باید باز و Draft بماند؛ این تغییرات به `main` منتقل نشده‌اند و Supabase Production دست‌نخورده است.
- [ ] قدم بعدی: بررسی CI روی head جدید، ساخت APK تازه پس از سبزشدن تست‌ها، سپس نصب و تأیید رفتار ورود/داشبورد روی Android.


### تأیید تست خودکار پس از اصلاح مخفی‌شدن صفحه ورود — ۲۰ نوامبر ۲۰۲۶
- [x] تأیید شد commit اصلاح CSS صفحه ورود همان `a6600bdeddd0407437333a531223de2db0ea30a1` است؛ فایل CSS در انتهای خود قانون `#authView.hidden{display:none!important}` را دارد.
- [x] اجرای Exact decimal tests شماره `44704931910` روی commit وضعیت `d34a4c1151cc6b9711d335a1c89b902f713e122c` بررسی شد؛ job `exact-decimal` با نتیجه `success` بسته شد و تمام مراحل آن موفق بودند.
- [x] فایل workflow اندروید بازبینی شد: دارای `workflow_dispatch` است و push فقط با تغییر مسیرهای مشخص‌شده از جمله `index.html`، `sw.js` و `src/**` build را اجرا می‌کند.
- [!] ابزار GitHub متصل در این نشست امکان اجرای مستقیم `workflow_dispatch` یا فهرست‌کردن تمام runهای push را ارائه نمی‌کند؛ بنابراین APK جدید شامل اصلاح auth/SW هنوز ساخته یا تأیید نشده است. APK قبلی run `44700246621` روی commit قدیمی `1269f6f205c7a146e1a7b047164fc16cab275864` است و شامل اصلاحات بعدی نیست.
- [!] PR #31 باز و Draft باقی می‌ماند؛ شاخه مستقل طبق compare، ۷۴ commit جلوتر و صفر commit عقب‌تر از `main` است. هیچ merge یا تغییری در Supabase Production انجام نشده است.
- [ ] قدم بعدی: از GitHub Actions، workflow «DigiArz Android APK» را با گزینهٔ Run workflow و شاخهٔ `redesign/independent-ui-2026` اجرا کن؛ پس از اتمام، artifact همان run باید با commit فعلی تطبیق داده شود و APK روی Android آزمایش شود.


### ادامه بررسی DigiArz — ۲۰ نوامبر ۲۰۲۶
- [x] وضعیت واقعی PR #31 بررسی شد: باز، Draft و ادغام‌نشده؛ head فعلی هنگام بررسی `1a643cf06c33e0e14e102d0b9608102a75c06410` است.
- [x] مقایسهٔ شاخه با `main` نشان داد `redesign/independent-ui-2026` تعداد ۷۵ commit جلوتر و صفر commit عقب‌تر است؛ `main` بدون تغییر مانده است.
- [x] اجرای جدید Exact Decimal Run #1005 با شناسهٔ `44705173586` روی head فعلی بررسی شد؛ job `exact-decimal` با نتیجهٔ `success` کامل شد.
- [x] تأیید شد اصلاحات صفحه ورود و PWA هنوز در شاخه حاضرند: CSS دارای `#authView.hidden{display:none!important}` است، HTML از CSS `v=9` استفاده می‌کند و Service Worker cache `digiarz-shell-v65` را به‌کار می‌برد.
- [!] APK تأییدشدهٔ موجود هنوز artifact اجرای Android APK شمارهٔ 73 / run `44686197402` روی commit `09e16659bab3b4e4ddd71892e8aa8e72ce014d2f` است؛ این build پیش از اصلاحات نهایی ورود و cache ساخته شده و نباید نسخهٔ حاوی آن اصلاحات معرفی شود.
- [!] اجرای مستقیم workflow دستی Android APK از ابزار GitHub متصل در دسترس نیست و run تازه‌ای برای head فعلی قابل تأیید نشده است. workflow از `workflow_dispatch` پشتیبانی می‌کند؛ باید از GitHub Actions به‌صورت دستی روی شاخهٔ مستقل اجرا شود.
- [ ] قدم بعد: اجرای دستی workflow «DigiArz Android APK» روی شاخهٔ `redesign/independent-ui-2026`، تطبیق `BUILD-INFO.txt` با commit همان اجرا، سپس نصب APK و آزمایش ورود/داشبورد روی Android.
- [!] هیچ merge به `main`، هیچ تغییر در Supabase Production و هیچ تغییر در منطق مالی انجام نشد.


### تغییر تم سوم به آبی آسمانی — ۲۰ نوامبر ۲۰۲۶
- [x] پالت تم سوم (کلاس `luxury-theme`) از طلایی به آبی آسمانی تغییر کرد؛ رنگ تأکیدی اصلی `#78c8ff` و رنگ روشن مکمل `#a8ddff` است. پس‌زمینهٔ سرمه‌ای شیشه‌ای حفظ شد تا تم سوم از تم روشن و تیره متمایز بماند.
- [x] رنگ‌های سخت‌کدشدهٔ صفحه ورود، داشبورد، دکمه‌ها، تب فعال، کارت قهرمان، نمودار و جزئیات بازار در محدودهٔ تم سوم با پالت آبی هماهنگ شدند؛ دو تم دیگر تغییر نکردند.
- [x] نسخهٔ CSS به `v=10` و کش Service Worker به `digiarz-shell-v66` ارتقا یافت؛ CSS جدید در پوستهٔ آفلاین precache می‌شود.
- [x] assertionهای نسخهٔ CSS و پاک‌سازی cache قدیمی در تست‌ها به‌روزرسانی شدند.
- [!] این تغییرات هنوز باید در CI بررسی و APK تازه ساخته شوند؛ نمایش واقعی و رفتار ورود/داشبورد هنوز نیازمند آزمایش روی گوشی Android است.
- [!] PR #31 همچنان باید باز و Draft بماند؛ هیچ merge به `main` و هیچ تغییری در Supabase Production انجام نشود.


### پیگیری CI تم آبی آسمانی و کش PWA — ۲۰ نوامبر ۲۰۲۶
- [x] اجرای قبلی Exact Decimal با شناسهٔ `44706380693` بررسی شد؛ شکست آن ناشی از assertion قدیمی در `tests/index-syntax.test.js` بود که هنوز انتظار `digiarz-shell-v65` داشت، درحالی‌که Service Worker به `v66` ارتقا یافته بود. این مورد در تست index به `v66` اصلاح شد.
- [x] اجرای بعدی Exact Decimal با شناسهٔ `44706473268` روی commit `1a4c7d6e916c63bc8075eaa8f8fb1d9ce1b37529` بررسی شد؛ تست‌های exact-decimal/browser، PostgreSQL arithmetic، rehearsalهای migration و integration بازار/Limit تا زمان بررسی موفق بودند؛ job هنوز در حال اجرا بود و نتیجهٔ نهایی ثبت نشده است.
- [x] fixture تست Service Worker به‌روزرسانی شد تا cache فعال جدید `digiarz-shell-v66` نیز در مجموعهٔ cacheهای موجود شبیه‌سازی شود؛ انتظار حذف cacheهای قدیمی تا `v65` حفظ شده است.
- [!] این آخرین اصلاح تست بعد از شروع run شمارهٔ `44706473268` انجام شده؛ بنابراین باید اجرای CI جدید روی commit جدید `7e71e0b0323630015ce250176087f31f20197786` بررسی شود.
- [!] هیچ APK تازه‌ای هنوز تأیید نشده؛ ساخت Android APK workflow جداگانه است و باید artifact و `BUILD-INFO.txt` با commit جدید تطبیق داده شوند.
- [!] PR #31 باید باز و Draft بماند؛ هیچ merge به `main` و هیچ تغییر در Supabase Production انجام نشود.


### نتیجهٔ اجرای CI و وضعیت نهایی بررسی این نوبت — ۲۰ نوامبر ۲۰۲۶
- [x] اجرای Exact Decimal با run ID برابر `44706473268` و commit `1a4c7d6e916c63bc8075eaa8f8fb1d9ce1b37529` با نتیجهٔ نهایی `success` بسته شد؛ تمام مراحل job از جمله تست‌های exact-decimal/browser، PostgreSQL، Market/Limit، Stop-Limit، TP-SL و تست‌های race دو-جلسه‌ای موفق بودند.
- [x] این run هیچ artifactای نداشت و workflow آن Android APK نبود؛ بنابراین موفقیت این تست به‌معنای ساخته‌شدن APK نیست.
- [x] پس از اجرای فوق، fixture تست Service Worker برای حضور cache جدید `digiarz-shell-v66` تکمیل شد. آخرین commit شاخه در زمان ثبت این یادداشت `970e13c956366d76a61781c6a4edee14a527fab3` است.
- [x] وضعیت PR #31 در آخرین بررسی: open و Draft؛ شاخه `redesign/independent-ui-2026` برابر ۸۶ commit جلوتر و صفر commit عقب‌تر از `main` بود.
- [!] اجرای CI جدیدی که commit نهایی `970e13c956366d76a61781c6a4edee14a527fab3` را پوشش دهد از ابزار فعلی قابل تأیید نیست؛ run موفق بالا روی commit قبلی است.
- [!] workflow اندروید `.github/workflows/android-apk.yml` دارای `workflow_dispatch` است و job ساخت `assembleDebug` و artifact با نام `DigiArz-Android-debug-APK` را دارد؛ اجرای دستی آن از اتصال فعلی GitHub قابل آغاز نیست.
- [ ] قدم بعد: اجرای دستی workflow اندروید روی شاخهٔ `redesign/independent-ui-2026`؛ سپس تطبیق `BUILD-INFO.txt` و commit artifact با head شاخه و بررسی SHA-256 APK، پیش از معرفی آن به‌عنوان نسخهٔ نهایی.
- [!] هیچ merge به `main`، هیچ تغییر Supabase Production و هیچ تغییر در منطق مالی انجام نشد.



### بازبینی مجدد CI و APK منتشرشده — ۲۰ نوامبر ۲۰۲۶، ۰۹:۰۰ UTC
- [x] head زندهٔ شاخهٔ بازطراحی و PR #31 برابر `e769055856653c457c691962affa5b43e4bbaec8` تأیید شد؛ PR باز، Draft و ادغام‌نشده است.
- [x] اجرای Exact Decimal با شناسهٔ `44706711576` روی همین head اجرا و با نتیجهٔ `success` بسته شد؛ تمام مراحل job از جمله تست‌های مرورگر، PostgreSQL، Market/Limit، Stop-Limit، TP/SL و رقابت‌های دو-نشستی موفق بودند.
- [x] انتشار GitHub Release با نام `android-debug-98` پیدا شد؛ لینک APK: https://github.com/shahram-adim/DigiArz/releases/download/android-debug-98/app-debug.apk
- [x] metadata انتشار، digest فایل APK را به‌صورت `sha256:665863b951209e8e1340aae821f1809260f0a0c93f3759302a02e973ed5ee7da` گزارش می‌کند.
- [!] سورس Build 98 از commit `fbebf7d6a4108e0a9c4ce5a6f2d077e67892dc42` ساخته شده که ancestor head فعلی و ۱۰ commit عقب‌تر است. فایل CSS در هر دو نسخه شامل تم آبی آسمانی و قانون مخفی‌شدن auth است؛ اما APK Build 98 از ارجاع CSS نسخهٔ v9 و cache Service Worker نسخهٔ v65 استفاده می‌کند، نه نسخه‌های v10/v66 در head فعلی. تغییرات بین commit ساخت و head شامل index، sw، تست‌ها و مستندات است؛ بنابراین این APK را نباید build دقیق head فعلی معرفی کرد.
- [!] انتشار، Debug/Test است و نصب/رفتار واقعی آن روی گوشی کاربر هنوز تأیید نشده است.
- [x] compare زنده همچنان شاخه را ۸۷ commit جلوتر و صفر commit عقب‌تر از main نشان می‌دهد؛ هیچ merge یا تغییر Supabase Production انجام نشد.
- [ ] قدم بعد: ساخت APK تازه از head فعلی `e769055856653c457c691962affa5b43e4bbaec8` و سپس آزمایش روی Android؛ تا آن زمان Build 98 فقط نسخهٔ نزدیک و غیرهمسان با head است.



### آغاز ساخت APK تازه از شاخهٔ بازطراحی — ۲۰ نوامبر ۲۰۲۶، ۰۹:۰۵ UTC
- [x] برای ساخت نسخهٔ اندروید از head شاخه، یک تغییر صرفاً توضیحی در comment فایل workflow ثبت شد؛ دستورها و تنظیمات build دست‌نخورده ماندند.
- [x] push روی شاخهٔ `redesign/independent-ui-2026` اجرای Android APK workflow شمارهٔ `44707584773` (Build 102) را آغاز کرد.
- [x] commit منبع این اجرا `5143abfee3057ae6b63d93cea9a389015f1e3f8d` است؛ در زمان آغاز، این commit head شاخه بود و شامل CSS v10 و cache Service Worker v66 است.
- [x] مراحل setup، نصب Capacitor، آماده‌سازی web assets، تولید پروژهٔ Android و sync اندروید موفق شدند.
- [!] آخرین مشاهده: job ساخت APK هنوز در حال اجراست؛ مرحلهٔ `assembleDebug` تکمیل نشده، artifact و Release هنوز منتشر نشده‌اند. پس هنوز APK تازه‌ای برای دانلود/تأیید نداریم.
- [!] PR #31 باز و Draft باقی می‌ماند؛ هیچ merge به `main` یا تغییری در Supabase Production انجام نشده است.
- [ ] قدم بعد: پایش run شمارهٔ `44707584773`، دریافت artifact، تطبیق `BUILD-INFO.txt` با commit منبع و تأیید SHA-256 قبل از ارائهٔ لینک دانلود.


### تکمیل ساخت و تأیید APK تم آبی آسمانی — ۲۰ نوامبر ۲۰۲۶، ۰۹:۰۶ UTC
- [x] اجرای Android APK workflow شماره `44707584773` (Build 102) روی شاخه `redesign/independent-ui-2026` با نتیجه نهایی `success` بسته شد؛ تمام ۱۲ مرحله اصلی job از جمله `assembleDebug`، ثبت provenance، آپلود artifact و انتشار لینک مستقیم موفق بودند.
- [x] artifact با نام `DigiArz-Android-debug-APK` و شناسه `14616046395` دریافت شد؛ تا ۴ دسامبر ۲۰۲۶ معتبر است.
- [x] فایل ZIP بررسی شد و شامل `app-debug.apk` و `BUILD-INFO.txt` است. provenance، commit منبع `5143abfee3057ae6b63d93cea9a389015f1e3f8d`، شاخه بازطراحی و run ID را تأیید می‌کند.
- [x] SHA-256 فایل APK استخراج‌شده با مقدار ثبت‌شده در BUILD-INFO و digest فایل Release دقیقاً تطبیق دارد: `819a774f18781748613dae71ce8e5dfc80b9fe22a3f010ce636f4960cda89631`.
- [x] GitHub Release `android-debug-102` موجود و لینک مستقیم APK فعال است: https://github.com/shahram-adim/DigiArz/releases/download/android-debug-102/app-debug.apk
- [!] این نسخه Debug/Test است؛ نصب و رفتار واقعی آن روی گوشی Android کاربر هنوز تأیید نشده است. به‌ویژه نمایش صحیح صفحه ورود، مخفی‌شدن آن پس از ورود و سلامت داشبورد باید روی گوشی بررسی شود.
- [x] PR #31 همچنان باز و Draft است؛ شاخه ۹۰ commit جلوتر و صفر commit عقب‌تر از `main` است. هیچ merge به `main` و هیچ تغییری در Supabase Production یا منطق مالی انجام نشد.
- [ ] قدم بعد: نصب APK Build 102 روی گوشی Android و بررسی صفحه ورود، انتقال به داشبورد و تفاوت واقعی هر سه تم؛ سپس اصلاح فقط بر اساس نتیجه مشاهده‌شده.



### اصلاح کارت‌های بازار موبایل بر اساس تصویر کاربر — ۲۰ نوامبر ۲۰۲۶
- [x] تصویر ارسالی کاربر بررسی شد؛ مشکل قابل مشاهده مربوط به کارت‌های فهرست بازار است: قیمت دلاری کم‌کنتراست، نوسان ۲۴ ساعته در ردیف جدا، نام‌های فارسی ناموجود برای برخی نمادها، و قاب‌های اضافی لوگو/ستاره.
- [x] در `src/digiarz-independent-ui.css` قواعد نهایی موبایل برای کارت بازار افزوده شد: قیمت USD و تومان با کنتراست خوانا، درصد نوسان در ردیف دوم کنار هویت ارز، پنهان‌کردن sparkline در عرض موبایل برای جلوگیری از فشردگی، حذف قاب/outline/shadow از دکمه ستاره و آیکون ارز، و حذف حاشیه/سایه از نشان برند `.da-v2-logo`.
- [x] در `index.html` نام فارسی fallback برای دارایی‌هایی که در واژگان و داده‌های فارسی شناخته‌شده نیستند به «دارایی دیجیتال» تغییر کرد؛ نام فارسی اختصاصی همچنان از `name_fa`، دادهٔ بازار تومانی و واژگان شناخته‌شده گرفته می‌شود و نماد لاتین در خط جدا حفظ می‌شود.
- [x] نسخه stylesheet به `v=11` و کش پوسته به `digiarz-shell-v67` ارتقا یافت تا Android/PWA فایل CSS جدید را دریافت کند.
- [x] تست‌های regression برای نسخهٔ cache و fallback فارسی به‌روزرسانی شدند.
- [!] این تغییرات روی شاخه `redesign/independent-ui-2026` هستند؛ هنوز اجرای CI پس از آخرین commit و APK تازه از head جدید تأیید نشده است.
- [!] APK Build 102 از commit قدیمی‌تر ساخته شده و شامل این اصلاحات جدید نیست؛ کاربر باید پس از ساخت و تأیید APK جدید آن را نصب کند.
- [x] صفحه ورود، اتصال Auth، منطق معاملات، Supabase Production و داده‌های مالی دست‌نخورده ماندند. PR #31 همچنان باید باز و Draft بماند؛ هیچ merge انجام نشد.
- [ ] گام بعد: بررسی CI روی head جدید، رفع هر شکست، سپس ساخت APK Debug/Test از همان commit و تطبیق provenance و SHA-256.



### پیگیری تست‌های رگرسیون اصلاح رابط بازار — ۲۰ نوامبر ۲۰۲۶
- [x] اجرای اولیه CI دو ناسازگاری در تست‌های نگهبان را آشکار کرد: تست stylesheet هنوز نسخهٔ CSS/cache قدیمی v10/v66 را انتظار داشت و assertion جدید fallback فارسی بیش از حد وابسته به regex بود.
- [x] انتظارهای تست به نسخه‌های واقعی v11/v67 تغییر یافت و assertion fallback به بررسی سادهٔ وجود رشتهٔ دقیق تبدیل شد.
- [x] head فعلی شاخه پس از اصلاح تست‌ها: `8a8651e2ddf6994cd8497b146d2fcb505ab7df64`.
- [!] اجرای Exact Decimal برای commit قبلی `c608550fbd7769e769a53921133fab6134978e5c` در حال اجراست؛ نتیجهٔ آن، اجرای تازه برای head نهایی و Android APK هنوز باید بررسی شوند.
- [!] Android workflow برای commit منبع `b654c3c3cb01d4da0a9bc4905d154f7cb40d71ef` در صف اجراست؛ این commit شامل اصلاحات UI، index و Service Worker است. artifact فقط پس از تأیید Build-Info و hash قابل ارائه خواهد بود.


### بازسازی یکپارچه صفحه بازار پس از گزارش کاربر — ۲۰ نوامبر ۲۰۲۶
- [x] بررسی DOM واقعی تابع `renderMarkets()` نشان داد هر ردیف بازار دقیقاً پنج فرزند دارد: دکمه علاقه‌مندی، دکمه هویت ارز، sparkline، ظرف درصد/حجم و ظرف قیمت. قواعد قبلی برای چیدمان چندستونه با این ساختار و breakpointها هماهنگ نبودند و باعث تداخل شده بودند.
- [x] بازنویسی scoped و یکپارچه CSS برای کل `#tab-markets`: سربرگ/hero، دسته‌بندی‌ها، جست‌وجو و فیلترها، پنل نوسان، لیست افزایشی‌ها و کاهشی‌ها، دارایی‌های برتر و فهرست اصلی.
- [x] بازسازی ردیف واقعی بازار با Grid Areaهای مشخص؛ دسکتاپ پنج ناحیهٔ مرتب و موبایل سه ستون/دو ردیف، با درصد ۲۴ساعته زیر نام ارز، قیمت USD/تومان در ستون ثابت و حذف sparkline در موبایل برای جلوگیری از فشردگی.
- [x] اصلاح ظاهر واقعی دکمهٔ نام ارز و لوگو، حذف قاب و سایهٔ دکمه ستاره، کنترل عرض و overflow و breakpoint ویژهٔ گوشی‌های باریک.
- [x] ارتقای CSS به `v=12` و Service Worker cache به `digiarz-shell-v68`; تست نگهبان برای grid موبایل و selector واقعی قیمت اضافه شد.
- [!] این تغییرات روی شاخه `redesign/independent-ui-2026` ثبت شده‌اند؛ هنوز CI تازه و APK ساخته‌شده از commit نهایی تأیید نشده‌اند. نسخه‌های قدیمی APK این اصلاح را ندارند.
- [x] هیچ تغییری در منطق قیمت/معاملات، احراز هویت، Supabase Production یا شاخه `main` اعمال نشد؛ PR #31 باید باز و Draft بماند.


### نتیجهٔ Build 108 و اصلاح انتظارهای تست رابط بازار — ۲۰ نوامبر ۲۰۲۶، حدود ۱۰:۰۸ UTC
- [x] ریشهٔ شکست‌های تست قبلی مشخص شد: دو تست هنوز CSS `v=11` را انتظار داشتند، در حالی که فایل واقعی `v=12` بود؛ تست Service Worker نیز حذف cache قدیمی `v=67` را در فهرست انتظار نداشت.
- [x] تست‌ها با نسخه‌های واقعی stylesheet و cache هماهنگ شدند؛ workflow تست Exact Decimal برای شاخه بازطراحی نیز فعال شد تا تغییرات شاخه به‌صورت مستقل تست شوند.
- [x] اجرای جدید تست‌ها با run ID `44716464908` شروع شد؛ تست‌های JavaScript/مرورگر، PostgreSQL arithmetic، rehearsal تغییر precision، preflight منفی، lock-timeout و rollback تا مرحلهٔ فعلی موفق بوده‌اند؛ کل job هنوز در حال اجراست.
- [x] Android Build 108 با run ID `44716074701` موفق شد؛ APK از commit `5e6e1ac014d79fb677ecafdef1c122595a314d3b` ساخته شده که شامل بازسازی صفحه بازار، CSS `v=12` و Service Worker `v68` است.
- [x] Release مستقیم Build 108 تأیید شد: https://github.com/shahram-adim/DigiArz/releases/download/android-debug-108/app-debug.apk
- [x] SHA-256 فایل APK طبق BUILD-INFO و digest دارایی Release یکسان است: `cf0fd0539fdccc4929e59f979143898497b7342c58405e1371b8e5182e42aaf7`.
- [!] Build 108 نسخه Debug/Test است؛ نصب و ظاهر واقعی صفحه بازار روی گوشی کاربر هنوز تأیید نشده است. APK از commit قبل از آخرین اصلاح صرفاً تستی ساخته شده، اما شامل کد UI بازار v12 است.
- [x] PR #31 همچنان باز و Draft است؛ هیچ merge، تغییر Production، Auth یا منطق مالی انجام نشده است.


### پاک‌سازی دوبارهٔ صفحه بازار پس از گزارش «هیچی درست نیست» — ۲۰ نوامبر ۲۰۲۶
- [x] وضعیت زنده شاخه و PR #31 بررسی شد؛ PR همچنان Open و Draft است و به main ادغام نشده.
- [x] بررسی DOM واقعی تأیید کرد فهرست ردیف‌ها در `#marketList` قرار دارد و هر `.coin` پنج فرزند مستقیم دارد. لایه‌های CSS قبلی در چند نقطه با selectorهای متفاوت روی همین اجزا اعمال شده بودند.
- [x] دو بلوک انتهایی CSS بازار که جداگانه روی هم انباشته شده بودند حذف و با یک لایهٔ واحد جایگزین شدند؛ هدف‌گیری ردیف‌ها اکنون مستقیماً از `#marketList>.coin` انجام می‌شود تا وابسته به کلاس‌های wrapper احتمالی نباشد.
- [x] چیدمان دسکتاپ و موبایل از نو و در یک نقطه تعریف شد؛ موبایل سه ستون و دو ردیف دارد: ستاره، هویت ارز، قیمت USD/تومان و تغییر ۲۴ساعته. نمودار و حجم در موبایل پنهان می‌شوند تا متن‌ها فشرده نشوند.
- [x] بخش‌های hero، دسته‌بندی‌ها، جست‌وجو/مرتب‌سازی، نوسان، افزایشی/کاهشی، دارایی‌های برتر و فهرست اصلی در همان لایهٔ واحد پوشش داده شدند.
- [x] stylesheet به `v=13`، Service Worker cache به `digiarz-shell-v69` ارتقا یافت؛ تست نگهبان به selector واقعی `#marketList` تغییر کرد.
- [!] تغییرات CSS/HTML/Service Worker و تست‌ها ثبت شده‌اند؛ باید CI و APK ساخته‌شده از head جدید بررسی شوند. هیچ ادعای تأیید بصری روی گوشی وجود ندارد.
- [x] ورود، منطق معاملات، داده‌های Supabase Production و شاخه main دست‌نخورده ماندند.


### بازطراحی ناوبری بازار و فهرست دارایی بر اساس دسته انتخابی — ۲۰ نوامبر ۲۰۲۶
- [x] نوار دسته‌بندی بازار به بالای محتوای بازار، بلافاصله پس از عنوان صفحه، منتقل شد.
- [x] آیکون‌ها و برچسب دسته‌ها به یک ردیف افقی قابل پیمایش تبدیل شدند؛ در موبایل نیز ردیف افقی باقی می‌ماند.
- [x] بخش‌های «۵ ارز با بیشترین افزایش»، «۵ ارز با بیشترین کاهش» و «۱۰ ارز برتر بازار» از ساختار صفحه حذف شدند.
- [x] فهرست اصلی بازار در همه اندازه‌ها به فهرست عمودی تک‌ستونه تبدیل شد.
- [x] فهرست دارایی‌های کاربر اکنون با دستهٔ فعال بازار فیلتر می‌شود (همه، دارایی‌های من، علاقه‌مندی، افزایشی/کاهشی، حجم/ترند، جدید و دسته‌های موضوعی)؛ با تغییر دسته نیز بازنمایی دارایی‌ها تازه می‌شود. خلاصهٔ کل دارایی و ارزش پرتفوی همچنان بر مبنای کل موجودی باقی می‌ماند.
- [x] نسخهٔ stylesheet به v14 و کش Service Worker به digiarz-shell-v70 ارتقا یافت؛ انتظارهای تست به‌روز و تست رگرسیون برای جایگاه دسته‌ها، حذف پنل‌ها و فیلتر دارایی افزوده شد.
- [!] تغییرات فقط در شاخه `redesign/independent-ui-2026` ثبت شده‌اند؛ هنوز CI و APK نهایی از head جدید باید بررسی شوند و تأیید بصری روی گوشی کاربر انجام نشده است.
- [x] ورود، اتصال Auth، منطق معاملات، داده‌ها و schema در Supabase Production و شاخه `main` تغییر نکردند؛ PR #31 باید باز و Draft بماند.


### اصلاح دو assertion قدیمی CI برای چیدمان جدید بازار — ۲۰ نوامبر ۲۰۲۶، حدود ۱۴:۰۱ به وقت محلی
- [x] وضعیت زنده PR #31 بررسی شد؛ شاخه `redesign/independent-ui-2026` باز و Draft است و head پیش از این اصلاحات `eb3593e56ced2f0ba76975449a06efd23e20e035` بود.
- [x] اجرای Exact Decimal با run ID `44719822611` شکست خورد؛ لاگ دقیق نشان داد ۵۶ تست از ۵۸ تست موفق بوده‌اند و دو شکست فقط از assertionهای cache قدیمی ناشی شده‌اند: تست HTML هنوز `digiarz-shell-v69` را انتظار داشت، درحالی‌که Service Worker از `v70` استفاده می‌کند؛ تست پاک‌سازی cache نیز فهرست قدیمی را تا `v68` متوقف کرده بود و `v69` را جا انداخته بود.
- [x] assertion نسخهٔ cache در `tests/index-syntax.test.js` به `v70` به‌روزرسانی شد؛ commit: `f43a31ade7929e7e878c1b7899df86121c58b107`.
- [x] فهرست cacheهای قدیمی در `tests/service-worker.test.js` با افزودن `v69` اصلاح شد؛ commit: `44f404d2f34f102088bac070a516a47908bd6218`.
- [!] این اصلاحات فقط انتظارات تست را با نسخهٔ واقعی Service Worker هماهنگ می‌کنند؛ هنوز اجرای CI تازه روی آخرین head و ساخت APK بررسی نشده است.
- [!] تست‌های مرتبط با دسته‌بندی بازار و فیلتر دارایی‌ها در همان اجرای ناموفق موفق بودند؛ این موفقیت تستی، تأیید بصری روی گوشی نیست.
- [ ] گام بعد: بررسی CI جدید روی head فعلی، بررسی نتیجهٔ Android APK workflow، و فقط در صورت موفقیت بررسی artifact و SHA-256. PR #31 همچنان Draft بماند؛ هیچ merge یا تغییر Supabase Production انجام نشود.


### مرتب‌سازی نهایی ردیف‌های بازار و حذف برچسب‌های اضافی — ۲۰ نوامبر ۲۰۲۶
- [x] برچسب «داشبورد معاملاتی DigiArz» از بالای داشبورد مخفی شد تا عنوان تکراری در نمای اصلی دیده نشود.
- [x] برچسب «بازار جهانی رمزارزها» از سربرگ تصویری بازار حذف شد.
- [x] آیکون دسته‌های اصلی بازار بزرگ‌تر و برجسته‌تر شدند؛ ردیف دسته‌ها همچنان افقی و قابل پیمایش است.
- [x] ردیف هر ارز در موبایل و دسکتاپ به یک خط واحد تبدیل شد: علاقه‌مندی، لوگو/نام، درصد تغییر ۲۴ساعته در مرکز، و قیمت در سمت مقابل. نمودار کوچک و حجم از ردیف حذف شدند تا چیدمان فشرده نشود.
- [x] متن «قیمت تازه» و ادعای «زمان منبع حداکثر ۲ دقیقه» از HTML تولیدی ردیف‌ها حذف شد؛ متن منبع/تازگی نیز نمایش داده نمی‌شود.
- [x] CSS به v15 و کش پوسته به digiarz-shell-v71 ارتقا یافت؛ تست‌های رگرسیون برای چیدمان تک‌ردیفی، اندازه آیکون‌ها و حذف برچسب تازگی به‌روزرسانی شدند.
- [!] تغییرات فقط روی شاخه `redesign/independent-ui-2026` هستند؛ اجرای CI و ساخت APK از commit جدید باید جداگانه بررسی شوند. نمایش واقعی روی گوشی هنوز از سوی کاربر تأیید نشده است.
- [x] هیچ تغییری در Auth، منطق معاملات، موجودی‌ها، Supabase Production یا شاخه `main` اعمال نشد؛ PR #31 باز و Draft باقی می‌ماند.


### اصلاح تست‌های رگرسیون داشبورد و Service Worker — ۲۰ نوامبر ۲۰۲۶، حدود ۱۱:۲۰ UTC
- [x] بررسی لاگ اجرای تست روی head قبلی نشان داد تست داشبورد به علت تعریف‌نشدن متغیر `css` شکست می‌خورد؛ تست فایل `src/digiarz-independent-ui.css` را بارگذاری نمی‌کرد.
- [x] در `tests/index-syntax.test.js` خواندن stylesheet واقعی اضافه شد تا assertionهای layout و کنتراست داشبورد روی CSS واقعی اجرا شوند؛ commit: `3a2945eced4cf2d7242082ac9bf721ea313509f8`.
- [x] در `tests/service-worker.test.js` انتظار نسخهٔ stylesheet از v15 به v16 به‌روزرسانی شد؛ Service Worker واقعی از `digiarz-independent-ui.css?v=16` استفاده می‌کند؛ commit: `f9c4616fc612c91c9a2717d2f89f89cfa8a45514`.
- [!] اجرای تست برای commitهای اصلاحی با run IDهای `44726620864` و `44726625178` آغاز شده و در آخرین بررسی هنوز در حال اجرا بوده است؛ نتیجهٔ نهایی هنوز تأیید نشده.
- [!] APK موفق قبلی run `44724904638` از commit قدیمی‌تر `3cf866dc74c02f5cf3ca0ecd95da996d979f9058` ساخته شده و شامل آخرین تغییرات داشبورد/CSS v16 نیست؛ تا ساخت و بررسی APK از head نهایی، آن را نسخهٔ نهایی این اصلاحات معرفی نکن.
- [x] PR #31 باز و Draft باقی می‌ماند؛ هیچ merge به `main`، تغییر Supabase Production، Auth یا منطق مالی انجام نشد.
- [ ] گام بعد: دریافت نتیجهٔ runهای تست، رفع هر خطای باقی‌مانده، سپس اجرای Android APK workflow از آخرین head و تأیید BUILD-INFO و SHA-256.


### دور دوم اصلاح تست‌های بازطراحی — ۲۰ نوامبر ۲۰۲۶
- [x] بررسی اجرای CI روی commit `57820eea2de046971afa925b319f327a1d749faf` دو خطای باقی‌ماندهٔ تست را مشخص کرد: regex بررسی stylesheet در Service Worker بیش‌ازحد escape شده بود و تست داشبورد به‌اشتباه دنبال آدرس فایل CSS داخل محتوای خود CSS می‌گشت.
- [x] regex تست Service Worker به الگوی درست مسیر CSS تغییر کرد و assertion داشبورد اکنون وجود لینک نسخهٔ v16 را در `index.html` بررسی می‌کند.
- [x] اصلاحات در commit `60d8d8c84cba2e6e4912d5aafeefbb0e0a059858` ثبت شد.
- [ ] منتظر اجرای مجدد CI روی این commit هستیم؛ تا زمان دریافت نتیجه، تست‌ها تأییدشده محسوب نمی‌شوند.


## اصلاح صفحه ورود — ۲۰ نوامبر ۲۰۲۶
- [x] فیلد «نام و نام خانوادگی» از فرم ورود حذف شد.
- [x] وابستگی تابع ثبت‌نام به فیلد حذف‌شده برداشته شد؛ ثبت‌نام همچنان با ایمیل و رمز عبور کار می‌کند و metadata نام خالی/جعلی ارسال نمی‌کند.
- [x] آزمون‌های ساختاری صفحه ورود به‌روزرسانی شدند تا حذف فیلد را الزام کنند و سایر کنترل‌های ورود/ثبت‌نام/بازیابی حفظ شوند.
- [!] ورود اثر انگشتی هنوز پیاده‌سازی نشده است. کد فعلی احراز هویت فقط Supabase email/password دارد و هیچ زیرساخت Passkey/WebAuthn یا تأیید challenge سمت سرور در این شاخه وجود ندارد. افزودن دکمه‌ای که صرفاً اثر انگشت را در مرورگر نمایش دهد یا بدون تأیید سرور نشست بسازد ناامن و گمراه‌کننده است.
- [ ] گام بعد: طراحی و پیاده‌سازی کامل Passkey/WebAuthn با تأیید سمت سرور و اتصال امن آن به نشست Supabase؛ تا آن زمان نباید ورود اثر انگشتی را به‌عنوان قابلیت فعال نمایش داد.


## ورود امن با Passkey — ۲۰ نوامبر ۲۰۲۶
- [x] دکمهٔ «ورود با اثر انگشت یا Passkey» به صفحه ورود اضافه شد؛ فقط در محیط امن HTTPS و وقتی مرورگر WebAuthn را پشتیبانی کند نمایش داده می‌شود.
- [x] در تنظیمات حساب فعال، گزینهٔ ثبت Passkey اضافه شد؛ ثبت فقط پس از ورود معتبر و با فراخوانی `supabase.auth.registerPasskey()` انجام می‌شود.
- [x] ورود از `supabase.auth.signInWithPasskey()` استفاده می‌کند تا challenge را Supabase ایجاد کند، پاسخ WebAuthn را سمت سرور اعتبارسنجی کند و نشست واقعی Supabase بسازد؛ هیچ پرچم محلی یا تأیید نمایشی جایگزین احراز هویت نشده است.
- [x] opt-in آزمایشی Passkey در ساخت Supabase client فعال شد؛ API رسمی این قابلیت به `@supabase/supabase-js >=2.105.0` نیاز دارد.
- [x] دکمهٔ ثبت Passkey فقط برای حساب فعال نمایش داده می‌شود؛ stylesheet به v17 و Service Worker cache به v74 ارتقا یافت.
- [x] تست رگرسیون برای دکمه‌ها، فعال‌سازی API، ثبت/ورود سرورمحور و کنترل حساب غیرفعال اضافه شد.
- [!] فعال‌سازی سمت سرور Supabase هنوز انجام نشده است: در Dashboard باید Authentication → Passkeys فعال شود و `rp_id` و `rp_origins` با دامنهٔ واقعی PWA تنظیم شوند. ابزار متصل فعلی امکان خواندن/تغییر این تنظیمات Auth را ارائه نمی‌کند؛ تا فعال‌سازی، سرور درخواست Passkey را رد می‌کند.
- [!] APK فعلی Capacitor 6 است و هنوز افزونهٔ Native Credential Manager یا Digital Asset Links (شامل اثرانگشت گواهی امضای APK) پیکربندی نشده است. کد WebAuthn استاندارد در WebView فقط در صورت پشتیبانی WebView قابل استفاده است؛ پشتیبانی APK روی دستگاه واقعی هنوز تأیید نشده و نباید به‌عنوان آماده اعلام شود.
- [ ] گام بعد: اجرای CI و APK workflow روی head جدید؛ سپس فعال‌سازی تنظیمات Supabase Auth و اتصال دامنه/گواهی Android به Digital Asset Links. هیچ تغییری در schema، migration، کیف پول، موجودی، سفارش یا معاملهٔ Production انجام نشد.

- [!] نخستین CI روی کد Passkey، run `44728562985`، در تست مرورگر ۵۹ از ۶۰ موفق شد؛ شکست فقط از assertion قدیمی نسخهٔ CSS در تست Service Worker بود (هنوز v16 را انتظار داشت، درحالی‌که CSS به v17 ارتقا یافته بود).
- [x] assertion regex تست به v17 اصلاح شد؛ commit اصلاحی: `f898851a4c56ab3e36c32ac9d8c506b76fb3737d`.
- [ ] اجرای CI تازه روی commit اصلاحی و نتیجهٔ ساخت APK هنوز باید بررسی شود.

- [x] بازبینی رویداد کلیک نشان داد دکمهٔ ورود Passkey هم‌زمان از bridge و listener مستقیم فراخوانی می‌شد؛ listener تکراری حذف شد تا WebAuthn ceremony فقط یک‌بار اجرا شود. آخرین commit کد: `106e510782b2608017edfc360868b8bd85e05b53`.
- [x] Exact Decimal run `44728854536` روی commit کد، تست‌های Node/browser را با موفقیت گذراند؛ مراحل PostgreSQL ایزوله در زمان این ثبت هنوز در حال اجرا هستند و نتیجهٔ کامل workflow تأیید نشده است.
- [x] Android debug APK workflow run `44728854393` روی همان commit، مرحلهٔ Gradle را با `BUILD SUCCESSFUL` تمام کرد و artifact `14625641065` را بارگذاری کرد. BUILD-INFO: SHA-256 برابر `1726f3d8cbf08a18d59c2f70e5076faa47ceecd8299379be971f94e20c567cbd`.
- [!] این APK فقط build کد فعلی روی شاخهٔ Draft است؛ فعال‌سازی Auth Passkey سمت Supabase و پشتیبانی Native Credential Manager/Domain Association برای APK هنوز کامل نشده است. آن را نسخهٔ آمادهٔ ورود اثر انگشتی معرفی نکن.


### بررسی سازگاری Passkey اندروید و ثبت گام بعد — ۲۰ نوامبر ۲۰۲۶
- [x] وضعیت زنده PR #31 بررسی شد؛ همچنان Open و Draft است، مقصد main است و ادغام نشده. آخرین checkpoint ثبت‌شده روی شاخه مستقل: 0ff66a92f6a32de69a3948d48d9048703e3c4045.
- [x] Exact Decimal workflow run 44729095438 روی commit checkpoint با نتیجه success کامل شد.
- [x] Android APK workflow run 44728854393 با نتیجه success و Build 132 روی commit کد Passkey 106e510782b2608017edfc360868b8bd85e05b53 کامل شد؛ این build debug است و موفقیت build به‌تنهایی اثبات‌کنندهٔ کارکرد بیومتریک نیست.
- [x] workflow اندروید بررسی شد: پروژه native در CI با `npx cap add android` ساخته و سپس با `npx cap sync android` همگام می‌شود؛ بنابراین نصب افزونه باید از package dependency و Capacitor config قابل بازتولید باشد و نیازی به تغییر فایل Android تولیدشده در مخزن نیست.
- [x] سازگاری رسمی افزونه‌ها بررسی شد: Capgo `@capgo/capacitor-passkey` نسخه 6 برای Capacitor 6 دیگر نگهداری نمی‌شود؛ نسخه 7 برای Capacitor 7 فقط on-demand و نسخه 8 برای Capacitor 8 فعالانه نگهداری می‌شود. افزونه Capawesome نیز اکنون Capacitor 8+ را پشتیبانی می‌کند. افزودن نسخه قدیمی و بدون نگهداری برای احراز هویت امن پذیرفته نیست.
- [x] سند فنی `docs/PASSKEY_ANDROID_READINESS.md` ایجاد شد و پیش‌نیازهای دامنه RP، فایل Digital Asset Links در ریشه دامنه، اثرانگشت واقعی گواهی امضا، پیکربندی Supabase Auth و آزمون روی دستگاه واقعی را ثبت کرد.
- [!] ورود Passkey در PWA و Android هنوز فعال‌شده/تأییدشدهٔ عملیاتی نیست؛ Supabase Auth Passkeys و دامنه RP تنظیم نشده‌اند و APK هنوز bridge بومی Credential Manager ندارد.
- [ ] گام بعد: ابتدا دامنه canonical و امکان میزبانی فایل `/.well-known/assetlinks.json` در ریشه همان دامنه باید قطعی شود؛ سپس یک spike مهاجرت Capacitor 8 روی شاخه مستقل و جداگانه ساخته و CI/Android build آن ارزیابی شود. تا پیش از آن، افزونه ناسازگار یا منسوخ اضافه نشود.
- [x] هیچ تغییری در main، Supabase Production، schema، داده‌های مالی، سفارش‌ها یا معاملات انجام نشد.


## آماده‌سازی انتشار پیش‌نمایش GitHub Pages — ۲۰ نوامبر ۲۰۲۶
- [x] گردش‌کار `.github/workflows/pages-preview.yml` روی شاخه `redesign/independent-ui-2026` اضافه شد؛ فقط همان شاخه را build/deploy می‌کند و به `main` یا Supabase دست نمی‌زند.
- [x] فایل `docs/GITHUB_PAGES_PREVIEW.md` محدودیت‌های میزبانی و نیاز مستقل Digital Asset Links را مستند می‌کند.
- [x] اجرای workflow انتشار با شناسه‌های `44731843261` و `44731847433` در GitHub Actions ایجاد شد؛ نتیجهٔ نهایی هنوز باید از Actions بررسی شود.
- [!] ایجاد workflow به‌تنهایی اثبات انتشار نیست؛ تنظیم Pages روی GitHub Actions و موفقیت Deploy باید تأیید شود.
- [!] آدرس project site به‌تنهایی مسیر ریشهٔ دامنه برای `/.well-known/assetlinks.json` را فراهم نمی‌کند؛ Passkey بومی APK هنوز فعال/تأیید نشده است.
- [x] هیچ تغییری در `main`، PR#31 merge state، تنظیمات Supabase یا داده‌های مالی Production انجام نشد.


## اصلاح گردش‌کار پیش‌نمایش Pages — ۲۰ نوامبر ۲۰۲۶
- [x] اجرای قبلی Pages با شناسه `44731843261` در وضعیت `in_progress` بدون job steps و بدون logs باقی مانده بود؛ اجرای بعدی `44731847433` لغو شده بود.
- [x] گردش‌کار `.github/workflows/pages-preview.yml` در commit `c53a8e7a3cb2fc985a5335650cfb7244685755e8` سخت‌سازی شد: لغو خودکار اجرای درحال‌انجام غیرفعال شد، برای build/deploy سقف زمان گذاشته شد، پیش‌نیازهای ورودی و خروجی build صریحاً بررسی می‌شوند و فایل‌های خروجی گزارش می‌شوند.
- [ ] اجرای جدید پس از این commit باید از GitHub Actions بررسی شود؛ تا موفقیت deploy و بازشدن URL، انتشار تأییدشده نیست.
- [!] این تغییر فقط روی شاخه `redesign/independent-ui-2026` است؛ PR#31 همچنان Draft است و هیچ تغییری در `main`، Supabase یا داده‌های مالی انجام نشده است.


## مانع قطعی انتشار پیش‌نمایش GitHub Pages — ۲۰ نوامبر ۲۰۲۶
- [x] workflow پیش‌نمایش در commit `912d349afb850f413584ba1e2076d1d588642caf` اصلاح شد تا از محیط مستقل `github-pages-preview` استفاده کند و مجوزهای Pages را در job انتشار صریح کند.
- [x] اجرای Pages با شناسه `44732947274`: ساخت PWA، پیکربندی Pages و بارگذاری artifact همگی موفق شدند.
- [x] لاگ مرحله Deploy علت قطعی را نشان داد: `Invalid deployment branch and no branch protection rules set in the environment. Deployments are only allowed from main`. بنابراین Pages مخزن هنوز از شاخه `main` به‌عنوان منبع انتشار استفاده می‌کند و انتشار شاخه بازطراحی مجاز نیست.
- [!] این مانع از کد workflow یا ساخت PWA نیست؛ باید Build and deployment → Source در تنظیمات مخزن به `GitHub Actions` تغییر کند. اتصال GitHub موجود فقط ابزارهای GET و تغییر فایل/commit را در اختیار می‌گذارد و عملیات Update Pages site که به مجوزهای Pages write و Administration write نیاز دارد در دسترس نیست.
- [ ] پس از تغییر Source به GitHub Actions، اجرای workflow از شاخه `redesign/independent-ui-2026` باید دوباره اجرا و URL نهایی بررسی شود.
- [x] شاخه `main`، PR #31 (Draft)، Supabase Production و داده‌های مالی دست‌نخورده باقی ماندند.


## همگام‌سازی مستندات main — ۲۰ نوامبر ۲۰۲۶

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

### تکمیل ثبت QA Stop-Limit — ۲۰ نوامبر ۲۰۲۶
- [x] ماتریس `docs/STOP_LIMIT_QA_MATRIX.md` با آخرین نتیجهٔ ایزولهٔ CI ثبت‌شده در ۱۹ نوامبر (run `44594127811`, Run #914) و snapshot فقط‌خواندنی Production به‌روز شد؛ commit: `6171e3fc5febee5705aa6c3e76dad1a7fde80eb2`.
- [x] مرز آزمون روشن شد: CI روی PostgreSQL 17 دورریختنی موفق بوده، اما Development Branch مستقل Supabase وجود ندارد؛ صفر بودن ردیف‌های مالی Production جایگزین آزمون چرخه کامل نیست.
- [!] هیچ سفارش/معامله/رزرو/موجودی آزمایشی در Production ایجاد نشد و هیچ Worker/RPC مالی روی کاربران واقعی اجرا نشد.
