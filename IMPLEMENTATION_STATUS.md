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


## Daily execution report — 2026-11-25 — Production RPC security manifest and anonymous access review

### Work completed (read-only Production inspection)
- Captured all 46 live `SECURITY DEFINER` functions from Supabase Production using PostgreSQL catalogs: complete `pg_get_functiondef`, identity arguments, result type, owner, volatility, `search_path`, raw ACL and MD5 fingerprint.
- Captured 34 public/private base relations, their RLS flags and role privileges, 21 policies, and six live trigger bindings to SECURITY DEFINER functions.
- Captured anonymous effective function/table/view privilege metadata and the definitions of the two anon-granted public views.
- Added `tests/production-rpc-manifest.test.js` to verify manifest completeness, the anon RPC allowlist, trigger-to-function references, RLS/view grant constraints and explicit super-admin guards for all ten `admin_*` RPCs.
- Created draft PR #63: https://github.com/shahram-adim/DigiArz/pull/63 . It remains open, draft and unmerged.

### Findings
- Exactly two of the 46 captured SECURITY DEFINER functions are executable by `anon`: `public.get_admin_market_listings()` and `public.get_exchange_discovered_market_assets()`. Their current return fields and SQL bodies expose market/exchange-discovery metadata, not user identity, wallet, balance, order, trade, reservation or transaction records.
- All ten `admin_*` functions in the snapshot contain an explicit `private.is_super_admin()` or `private.is_current_user_super_admin()` guard. Their captured ACLs do not grant `anon`.
- `anon` has excess DML/TRUNCATE grants on `coin_reviews`; the captured RLS policy set gives anon SELECT only, while write policies are authenticated-only.
- `anon` has SELECT on `conditional_orders`, but the captured SELECT policy is authenticated-only.
- `anon` has broad grants on `market_prices_with_toman` and `market_toman_performance`; both are `security_invoker=true` views. Underlying anon grants currently restrict the former to base-table SELECT and provide no base-table access for the latter's Toman sources.
- These are least-privilege hardening opportunities, not confirmed anonymous write/read exploits. No anonymous API request was executed; conclusions are based on the captured ACL, RLS and view metadata.

### CI status
- Workflow Run #45633511235 on commit `b67d2754ffcd234a629a131bb048a928bba201cf` passed all 25 workflow steps, including all 73 Node tests present at that commit and the PostgreSQL 17 regression/lifecycle/race suite.
- A subsequent admin-guard test addition exposed an invalid regular-expression escape in the new test; that failure was diagnosed from the Actions log and corrected in commit `3830c0df2e659db1b4abeb68c45da10dd83eeb24`.
- The Actions run for corrected commit `3830c0df2e659db1b4abeb68c45da10dd83eeb24` was still in progress at report time; its final result must be checked before marking the new test verified.

### Safety and next steps
- No Production grants, RLS policies, functions, views, migrations, cron jobs, Edge Functions or financial rows were changed. No user/financial row data was read.
1. Verify the latest CI run on the corrected PR head; fix only test defects found by evidence.
2. Reconstruct table/function dependencies for the 46 bodies using reviewed SQL and authoritative migration sources; empty `pg_depend` entries are not evidence of no PL/pgSQL table references.
3. Review the four excess-grant findings against actual application call sites before proposing least-privilege changes; do not apply GRANT/REVOKE or RLS changes without owner approval.
4. Continue recovering authoritative migration sources and building the isolated PostgreSQL 17 ACL/RLS/function parity harness.
5. Keep merge, Production migrations, grants, policies, function/view changes and financial writes blocked pending explicit approval.


### Relation dependency inventory — 2026-11-25
- [x] Static-scanned all 46 live Production function bodies for schema-qualified relation references.
- [x] Resolved all 27 unique candidates against the live Production catalog; no unresolved candidates remained.
- [x] Captured 175 live columns plus relation owner, RLS/forced-RLS flags, effective anon/authenticated/service_role table privileges, constraints, indexes, policies and user triggers.
- [x] Added `supabase/audit/production_rpc_relation_dependencies_2026-11-25.json` and extended `tests/production-rpc-manifest.test.js` to validate its counts and references.
- [!] Static scanning does not prove full dependency coverage for dynamic SQL, unqualified identifiers, trigger-only dependencies or indirect calls.
- CI Run #45634861182 on test commit `311d2e0f9f5ad57aa29090a3165c6ed5d17dfa21` completed with `success`; all 26 workflow steps passed, including the Node/browser suite and disposable PostgreSQL arithmetic, widening, lifecycle and two-session race tests.


### Production migration-source recovery — reconciliation completed 2026-11-25
- [x] Re-read the live Supabase migration ledger and GitHub `main` recursive tree; exact count: 55 Production ledger entries and 40 local SQL files.
- [x] Matched migration identities by normalized migration name rather than timestamp alone: 38 names match, of which 18 timestamps match and 20 have timestamp drift.
- [x] Confirmed 17 ledger entries have no matching SQL source file in `main`; two local SQL files have no matching ledger name.
- [x] Searched 12 relevant existing branches for the missing migration source files; none of the 17 files was present in those branch trees.
- [x] Added `supabase/audit/production_migration_source_reconciliation_2026-11-25.json` and CI assertions so timestamp drift is not misreported as a missing source.
- [!] No missing migration was reconstructed from live catalog state, no SQL was applied, and no db push was run.
- Next: seek original source artifacts from authoritative backup/CI/developer artifacts; if unavailable, prepare per-migration evidence packages from live definitions, ACL/RLS, triggers and dependency metadata, clearly labeled as reconstructions and requiring manual approval. Keep db push and Production changes blocked.


### Missing-migration live-evidence map — 2026-11-25
- [x] Grouped all 17 missing sources into four evidence domains: admin/wallet/roles (6), Iranian exchange observation and workers (7), verified pair activation (1), and backpressure/pg_net queue snapshot/throttling (3).
- [x] Read-only catalog inspection captured current schema metadata for `wallets`, `coin_reviews`, `demo_trading_fees`, `profiles`, `private.admin_users`, `private.admin_wallet_adjustments`, `exchange_asset_observations`, exchange request queues and pg_net backup-table definitions.
- [x] Captured current relevant routine signatures/fingerprints and cron job IDs/schedules/active flags. No table rows or queue payloads were read.
- [x] Added `supabase/audit/production_missing_migration_recovery_map_2026-11-25.json` and a CI completeness guard.
- [!] The live `wallets` schema currently declares defaults `balance_usdt=200` and `balance_irr=1000000000`; reconcile this with the separately approved product defaults before any future onboarding/default changes. No data/default was changed.
- [!] Live function bodies and cron metadata represent current state, not the exact historical SQL/order or dropped intermediate states. The recovery map is evidence-only and must not be used as an executable migration.
- Next: obtain original SQL from a trusted backup/developer artifact; otherwise prepare review-only per-object reconstruction dossiers with explicit provenance and unknowns. Keep `db push`, migrations, grants, RLS changes, cron changes and all Production writes blocked.
