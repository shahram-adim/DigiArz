# پرونده‌های شواهد بازسازی Migrationهای مفقود DigiArz
تاریخ تهیه: 2026-11-25
شاخه: `audit/production-rpc-manifest-2026-11-25`
وضعیت: فقط مستندات بازبینی؛ غیرقابل اجرا

## هدف و محدودیت
این سند برای هر ۱۷ نسخه ثبت‌شده در دفتر Migration Production که فایل SQL متناظر آن در مخزن یافت نشده، پرونده شواهد مستقل ایجاد می‌کند. این پرونده‌ها «بازسازی SQL اصلی» نیستند. هیچ دستور DDL/DML/GRANT/REVOKE، تغییر policy، تغییر تابع یا دستور زمان‌بندی از روی وضعیت فعلی حدس زده نشده است. تعریف زنده اشیا ممکن است حاصل چند Migration بعدی باشد و ترتیب تاریخی، داده‌های seed/backfill و وضعیت‌های میانی را ثابت نمی‌کند.

## شواهد مشترک
- دفتر Migration Production: ۵۵ ورودی.
- فایل‌های SQL محلی در main: ۴۰.
- تطبیق اسمی: ۳۸؛ فایل منبع مفقود: ۱۷؛ تطبیق timestamp دقیق: ۱۸؛ اختلاف timestamp در موارد تطبیق‌یافته: ۲۰.
- جست‌وجوی شاخه‌ای قبلی: ۱۲ شاخه، بدون یافتن فایل متناظر.
- جست‌وجوی تاریخچه/PR/CI قبلی محدود و مستند شده؛ عدم یافتن در آن محدوده اثبات عدم وجود در backup یا cloneهای خارج از مخزن نیست.
- نقشهٔ شواهد: `supabase/audit/production_missing_migration_recovery_map_2026-11-25.json`
- تطبیق منبع: `supabase/audit/production_migration_source_reconciliation_2026-11-25.json`
- جست‌وجوی منابع: `supabase/audit/production_migration_authority_search_2026-11-25.json`
- Manifest توابع: `supabase/audit/production_security_definer_manifest_2026-11-25.json`
- وابستگی‌ها: `supabase/audit/production_rpc_relation_dependencies_2026-11-25.json`

## پرونده‌های مستقل

### A. کیف پول، کارمزد، بررسی سکه و نقش مدیر — ۶ مورد

#### 20261113153808 — approved_wallet_defaults_fees_and_coin_reviews
- حوزه: defaultهای کیف پول، تنظیم کارمزد demo و جدول/سیاست‌های coin_reviews.
- شواهد زندهٔ ثبت‌شده: metadata جدول‌های `public.wallets`, `public.demo_trading_fees`, `public.coin_reviews`؛ ستون‌ها، defaultها، قیود، indexها، RLS/policy و privilegeها در snapshotهای ممیزی.
- اختلاف مهم: default زندهٔ `balance_usdt=200` و `balance_irr=1000000000` (۱۰۰ میلیون تومان) است؛ مقدار مصوب محصول برای حساب پیش‌فرض ۲۰۰ دلار و ۵۰ میلیون تومان است. این اختلاف باید جداگانه تعیین تکلیف شود و به‌هیچ‌وجه مجوز تغییر default یا داده نیست.
- نامعلوم: متن دقیق CREATE/ALTER، مقدار seed اولیهٔ کارمزد، منطق backfill، زمان و شرط اعمال default، و ترتیب فعال‌سازی RLS.
- مدرک لازم: SQL اصلی یا transcript اجرا + snapshot قبل/بعد همان زمان + تأیید مالک برای هر تصمیم درباره defaultها.
- نتیجه: منبع تاریخی قابل بازیابی نیست؛ بازسازی اجرایی ممنوع.

#### 20261113154323 — assign_confirmed_super_admin
- حوزه: تخصیص مدیر ارشد اولیه.
- شواهد زنده: جدول `private.admin_users` و helperهای فعلی `private.is_super_admin()` و `private.is_current_user_super_admin()` در manifest؛ بررسی guardهای فعلی توابع admin.
- نامعلوم: شناسه/شرط انتخاب حساب اولیه، دادهٔ درج‌شده، زمان‌بندی، idempotency و حالت‌های شکست.
- مدرک لازم: SQL اصلی و مدرک تأییدشدهٔ هویت/انتساب مدیر از سوابق مالکانه؛ دادهٔ شخصی یا credential نباید در پرونده عمومی ثبت شود.
- نتیجه: وضعیت فعلی مجوز، سابقهٔ انتساب اولیه را ثابت نمی‌کند؛ بازسازی اجرایی ممنوع.

#### 20261113154736 — secure_admin_wallet_management
- حوزه: عملیات مدیریتی کیف پول و تغییرات اعتباری.
- شواهد زنده: `private.admin_wallet_adjustments`, `public.wallets` و routine فعلی `private.admin_adjust_wallet(uuid,text,text,numeric,text)`؛ manifest امنیتی و inventory وابستگی‌ها.
- نامعلوم: نسخهٔ اولیه و تغییرات بعدی تابع، قیود حسابداری، ثبت audit، سیاست‌های خطا/تکرار و grants دقیق تاریخی.
- مدرک لازم: SQL اصلی، transcriptهای deployment و snapshotهای audit/ledger در زمان اجرا؛ بررسی مستقل سازگاری حسابداری.
- نتیجه: تعریف فعلی برای انتساب تغییرات به این Migration کافی نیست؛ بازسازی اجرایی ممنوع.

#### 20261113154750 — add_admin_role_probe
- حوزه: probe تشخیص نقش مدیر.
- شواهد زنده: helperهای role-check فعلی و ACL/مالکیت/search_path در manifest توابع.
- نامعلوم: نام و signature دقیق نسخهٔ تاریخی، خروجی، نقش‌های مجاز، grants اولیه و اینکه probe بعداً حذف/جایگزین شده یا نه.
- مدرک لازم: SQL اصلی یا dump تاریخی schema/function و لاگ deployment.
- نتیجه: نمی‌توان از helperهای امروزی بدنهٔ این Migration را استنتاج کرد؛ بازسازی اجرایی ممنوع.

#### 20261113154844 — use_toman_units_in_admin_credit_ui
- حوزه: تغییر واحد نمایشی اعتبار مدیر به تومان.
- شواهد زنده: ساختار فعلی wallet/admin adjustment و شواهد UI در تاریخچهٔ کد در صورت بازیابی commit دقیق.
- نامعلوم: تبدیل واحد، قرارداد API، اینکه تغییر صرفاً UI بوده یا RPC/schema را هم تغییر داده، و سازگاری با ریال ذخیره‌شده.
- مدرک لازم: نسخهٔ دقیق frontend و SQL/edge/API transcript هم‌زمان با Migration، به‌همراه نمونه‌های تست واحد (بدون دادهٔ شخصی).
- نتیجه: وضعیت فعلی واحد ذخیره‌سازی، رفتار تاریخی UI را اثبات نمی‌کند؛ بازسازی اجرایی ممنوع.

#### 20261113154926 — move_admin_privilege_logic_to_private_schema
- حوزه: انتقال منطق privilege مدیر به schema خصوصی.
- شواهد زنده: helperهای `private.is_super_admin()` و `private.is_current_user_super_admin()`، ACL، مالکیت، search_path و بدنهٔ توابع SECURITY DEFINER فعلی.
- نامعلوم: توابع عمومی قبلی، ترتیب انتقال/حذف، grants و revokeهای دقیق، سازگاری call siteها و وضعیت میانی در زمان deploy.
- مدرک لازم: SQL اصلی + dump قبل/بعد + migration transcript؛ بازبینی امنیتی مستقل برای هر grant.
- نتیجه: snapshot فعلی تنها انتهای زنجیره را نشان می‌دهد؛ بازسازی اجرایی ممنوع.

### B. مشاهدات دارایی صرافی‌های ایرانی و workerها — ۷ مورد

#### 20261115101709 — create_exchange_asset_observations
- حوزه: جدول مشاهدهٔ دارایی، قیود، indexها و RLS.
- شواهد زنده: metadata فعلی `public.exchange_asset_observations` و وابستگی routineها.
- نامعلوم: schema اولیه، کلید یکتا، سیاست نگهداری/پاکسازی، backfill و policyهای نسخهٔ اول.
- مدرک لازم: SQL اصلی و snapshot تاریخی جدول/index/policy.
- نتیجه: schema کنونی ممکن است توسط Migrationهای بعدی تغییر کرده باشد؛ بازسازی اجرایی ممنوع.

#### 20261115102729 — schedule_iran_exchange_asset_sync
- حوزه: زمان‌بندی درخواست/پردازش sync ایران.
- شواهد زنده: job 13 `digiarz-iran-exchange-request` با schedule فعلی `*/10 * * * *` و job 14 `digiarz-iran-exchange-process` با schedule فعلی `1,31 * * * *`؛ هر دو active.
- نامعلوم: command text تاریخی، زمان‌بندی اولیه، ترتیب ایجاد تابع و job، و تغییرات بعدی.
- مدرک لازم: SQL اصلی و خروجی کامل cron job definition از نسخه/زمان مرتبط، بدون اجرای مجدد job.
- نتیجه: زمان‌بندی فعلی معادل دستور تاریخی نیست؛ بازسازی اجرایی ممنوع. هیچ cronی تغییر نکند.

#### 20261115102927 — fix_exchange_sync_response_json_cast
- حوزه: اصلاح cast پاسخ JSON در مسیر sync.
- شواهد زنده: بدنهٔ فعلی workerها و signatureها در manifest، به‌عنوان وضعیت انتهایی.
- نامعلوم: بدنهٔ پیش از اصلاح، خطای واقعی، نوع پاسخ‌های provider و محل دقیق cast اصلاح‌شده.
- مدرک لازم: SQL اصلی، CI failure/log یا transcript خطای زمان اصلاح و نسخهٔ قبلی تابع.
- نتیجه: بدنهٔ فعلی diff تاریخی را نشان نمی‌دهد؛ بازسازی اجرایی ممنوع.

#### 20261115103227 — auto_list_verified_exchange_assets
- حوزه: فهرست‌کردن خودکار دارایی‌های تأییدشده.
- شواهد زنده: `private.auto_list_verified_exchange_asset()` و رابطه‌های فعلی observation/admin listings؛ trigger bindingهای snapshot.
- نامعلوم: شرط‌های تأیید اولیه، تعریف trigger در زمان ایجاد، جلوگیری از duplicate، و تغییرات بعدی.
- مدرک لازم: SQL اصلی، trigger/function قبل و بعد و fixtureهای تست معتبر.
- نتیجه: trigger فعلی ممکن است بعداً اصلاح شده باشد؛ بازسازی اجرایی ممنوع.

#### 20261115103507 — schedule_bit24_exchange_asset_sync
- حوزه: زمان‌بندی worker صرافی Bit24.
- شواهد زنده: جدول `public.bit24_exchange_sync_requests` و routineهای request/process فعلی در manifest؛ jobهای مرتبط در snapshot cron در حد metadata.
- نامعلوم: command دقیق، cadence اولیه، secret/config وابسته و سیاست retry تاریخی.
- مدرک لازم: SQL اصلی و خروجی زمان‌دار cron definition؛ secrets نباید استخراج یا ثبت شوند.
- نتیجه: از metadata فعلی نمی‌توان command امن تولید کرد؛ بازسازی اجرایی ممنوع.

#### 20261115105721 — admin_exchange_asset_sync_monitoring
- حوزه: گزارش و کنترل مدیریتی sync.
- شواهد زنده: `public.admin_exchange_asset_sync_report()` و `public.admin_request_exchange_asset_sync()`؛ ACL و guardهای فعلی در manifest.
- نامعلوم: خروجی دقیق تاریخی، فیلتر داده‌ها، محدودیت نقش، grants اولیه و احتمال تغییر signature.
- مدرک لازم: SQL اصلی و snapshot ACL/function در زمان اجرا.
- نتیجه: مجوز فعلی، grants اولیه را ثابت نمی‌کند؛ بازسازی اجرایی ممنوع.

#### 20261115105956 — restrict_exchange_sync_worker_execution
- حوزه: محدودسازی اجرای workerهای sync.
- شواهد زنده: ACL، owner، SECURITY DEFINER، search_path و امضای routineهای sync فعلی.
- نامعلوم: grants/revokes دقیق پیش و پس از Migration، نقش اجرای cron، و ترتیب revoke/grant برای جلوگیری از وقفه.
- مدرک لازم: SQL اصلی و audit log مجوزها/نسخهٔ قبل و بعد.
- نتیجه: چون این حوزه امنیتی است، هیچ grant یا revoke حدسی مجاز نیست؛ بازسازی اجرایی ممنوع.

### C. فعال‌سازی خودکار جفت‌ارزهای تأییدشده — ۱ مورد

#### 20261116201639 — auto_activate_verified_exchange_pairs
- حوزه: فعال‌سازی خودکار pairهای تأییدشده.
- شواهد زنده: routine `private.auto_activate_verified_exchange_pairs()`، رابطه‌های `crypto_assets`, `admin_market_listings`, `market_prices`, `exchange_asset_observations`, `demo_trading_pairs` و job 18 با schedule فعلی `9-59/10 * * * *` (active).
- نامعلوم: معیار تأیید، ترتیب upsert/activation، شرط عدم‌تداخل ticker، اثر triggerها، rollback و نسخه‌های قبلی.
- مدرک لازم: SQL اصلی، تعریف تابع/trigger قبل و بعد و تست‌های deterministic روی fixture ایزوله.
- نتیجه: وضعیت فعلی اثر چند مرحله را درهم دارد؛ بازسازی اجرایی ممنوع. job 18 نباید تغییر کند.

### D. Backpressure، صف pg_net و throttle موقت — ۳ مورد

#### 20261121045434 — digiarz_backpressure_and_exchange_sync_bloat_guards
- حوزه: کنترل backpressure و رشد صف sync.
- شواهد زنده: relationهای queue مربوط به `exchange_asset_sync_requests` و `bit24_exchange_sync_requests`، routineها و metadata jobهای مرتبط.
- نامعلوم: thresholds، قفل‌ها، شاخص‌ها، retry policy، سقف درخواست و تغییرات دقیق cron/function.
- مدرک لازم: SQL اصلی، metric snapshot همان زمان، incident notes و نسخهٔ قبلی توابع/jobها.
- نتیجه: threshold حدسی ممکن است sync را مختل کند؛ بازسازی اجرایی ممنوع.

#### 20261121045531 — snapshot_pg_net_unlogged_queue_before_recovery
- حوزه: snapshot از صف/پاسخ pg_net پیش از recovery.
- شواهد زنده: schema جدول‌های `private.digiarz_pg_net_queue_backup_20261121` و `private.digiarz_pg_net_response_backup_20261121`.
- محدودیت مهم: هیچ ردیف backup، payload صف یا response خوانده نشده است.
- نامعلوم: ستون‌ها و انتخاب ردیف‌های snapshot، ترتیب transaction، mapping شناسه‌ها، idempotency و restore/replay contract.
- مدرک لازم: SQL اصلی، schema dump همان زمان، backup export مجاز و incident/deployment transcript.
- نتیجه: ممنوعیت صریح هرگونه queue replay, restore, drain, cleanup یا snapshot مجدد در جریان این ممیزی.

#### 20261121050216 — temporarily_throttle_exchange_asset_processors_20261121
- حوزه: throttle موقت پردازشگرهای دارایی صرافی.
- شواهد زنده: metadata jobهای 11، 13 و 14 در نقشهٔ بازیابی؛ همگی active با schedule ثبت‌شده در snapshot.
- نامعلوم: schedule پیش از throttle، مقدار throttle، زمان انقضا/بازگردانی، ترتیب عملیات و اینکه کدام processor دقیقاً تغییر کرده است.
- مدرک لازم: SQL اصلی و transcript اجرا/بازگردانی به‌همراه تاریخچهٔ cron.
- نتیجه: هیچ scheduleی از روی حدس تغییر یا بازگردانی نشود؛ بازسازی اجرایی ممنوع.

## دروازهٔ پذیرش منبع اصلی
هر پرونده فقط وقتی می‌تواند از «مفقود» به «بازیابی‌شده» تغییر کند که:
1. SQL کامل و byte-preserved از منبع قابل اعتماد (backup، transcript اصلی، یا clone/reflog توسعه‌دهنده) به دست آید.
2. نام، version و checksum با ledger Production تطبیق داده شود.
3. هر dependency و شیء ایجاد/تغییریافته با snapshotهای موجود تطبیق داده شود.
4. ترتیب نسبت به Migrationهای قبل/بعد و عملیات داده‌ای مشخص شود.
5. grants/RLS/owner/search_path و trigger/job side effects جداگانه بررسی شوند.
6. آزمون در PostgreSQL 17 موقت، با fixture مستقل و بدون اتصال به Production اجرا شود.
7. پروندهٔ اختلاف‌ها و تأیید بازبین ثبت شود؛ تنها پس از آن می‌توان دربارهٔ مسیر همگام‌سازی مخزن تصمیم گرفت.

## ممنوعیت‌های جاری
- هیچ Migration یا SQL بازسازی‌شده اجرا نشود؛ `supabase db push` متوقف بماند.
- هیچ merge، deploy، grant/revoke، policy/function change، cron reschedule، queue replay یا financial write انجام نشود.
- موتور سفارش‌ها و زمان‌بندی‌های آن دست‌نخورده بمانند.
- default کیف پول ۱۰۰ میلیون تومان در برابر مقدار مصوب ۵۰ میلیون تومان، موضوعی مستقل برای تصمیم مالک است؛ در این پرونده‌ها اصلاح نمی‌شود.

## جمع‌بندی
تعداد پرونده‌ها: ۱۷ از ۱۷.
تعداد SQL اصلی بازیابی‌شده در این گام: صفر.
تعداد SQL اجرایی ساخته‌شده: صفر.
وضعیت: آمادهٔ بررسی شواهد جدید؛ تا دریافت منبع معتبر، بازسازی اجرایی و replay مسدود است.
