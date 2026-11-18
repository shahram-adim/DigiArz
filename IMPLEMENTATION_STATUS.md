# DigiArz — وضعیت اجرای پروژه
آخرین به‌روزرسانی: 2026-11-18
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
