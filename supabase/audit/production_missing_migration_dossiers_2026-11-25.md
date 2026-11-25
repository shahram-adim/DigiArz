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


## پیوست ممیزی: تطبیق اشیای زنده و fingerprintها — 2026-11-25

**روش:** تطبیق نام‌های ثبت‌شده در recovery map با snapshot زندهٔ ۴۶ تابع SECURITY DEFINER، شش trigger binding و inventory روابط. این crosswalk فقط «ارتباط مشاهده‌شده در وضعیت فعلی» را ثبت می‌کند؛ اثبات نمی‌کند کدام Migration تاریخی شیء را ایجاد یا تغییر داده است. هیچ SQL تاریخی از روی این تطبیق بازسازی نشده است.

**محدودیت انتساب:** شناسهٔ Migration به‌تنهایی provenance یک routine یا trigger نیست. اگر ارتباط مستقیم در snapshot وجود ندارد، صریحاً «no direct live attribution» ثبت شده است. برای cron فقط job id/name/schedule/active موجود در recovery map ثبت می‌شود؛ command text یا fingerprint آن در این مجموعه‌فایل‌ها موجود نیست.

### گروه 1: wallet defaults, fee configuration, coin reviews, super-admin authorization and admin wallet operations

**Migration IDs:** `20261113153808`, `20261113154323`, `20261113154736`, `20261113154750`, `20261113154844`, `20261113154926`

**روابط زندهٔ مرتبط (نام/متادیتا):**
- `public.wallets`: owner `postgres`، RLS `true`، forced RLS `false`، columns=5، indexes=2، constraints=4، policies=1، triggers=0.
- `public.coin_reviews`: در relation dependency inventory مستقیم موجود نیست.
- `public.demo_trading_fees`: owner `postgres`، RLS `true`، forced RLS `false`، columns=5، indexes=1، constraints=4، policies=0، triggers=0.
- `public.profiles`: owner `postgres`، RLS `true`، forced RLS `false`، columns=5، indexes=1، constraints=2، policies=1، triggers=0.
- `private.admin_users`: owner `postgres`، RLS `true`، forced RLS `false`، columns=4، indexes=1، constraints=4، policies=0، triggers=0.
- `private.admin_wallet_adjustments`: owner `postgres`، RLS `true`، forced RLS `false`، columns=10، indexes=1، constraints=7، policies=0، triggers=0.

**روتین‌های زنده و fingerprint:**
- `private.admin_adjust_wallet(p_user_id uuid, p_currency text, p_direction text, p_amount numeric, p_reason text)` — return `jsonb`; owner `postgres`; `search_path=""`; MD5 `85c4d10adc62c3159e9d82acea1ca71f`.
- `private.admin_list_users()` — return `TABLE(user_id uuid, email text, is_active boolean, created_at timestamp with time zone, balance_usdt numeric, balance_irr numeric)`; owner `postgres`; `search_path=""`; MD5 `8545473ad46d598dc6fd8a13e96e8630`.
- `private.is_current_user_super_admin()` — return `boolean`; owner `postgres`; `search_path=""`; MD5 `83d42c9299632d2a6c66fe39d6d01936`.
- `private.is_super_admin()` — return `boolean`; owner `postgres`; `search_path=""`; MD5 `324c3a171280546dc16429d7ccf4aa86`.

**Trigger bindings زنده:**
- هیچ trigger binding مستقیم از توابع فهرست‌شدهٔ این گروه در snapshot ثبت نشده است؛ این به‌معنای نبودن triggerهای دیگر در Production نیست.

**Cron metadata ثبت‌شده:**
- در recovery map برای این گروه cron مشخصی ثبت نشده است.

**نتیجهٔ provenance:** اشیای بالا candidateهای تطبیق فعلی‌اند، نه اثبات منشأ تاریخی. برای تعیین اینکه هر Migration دقیقاً چه چیزی ایجاد/تغییر داده، همچنان SQL اصلی یا transcript معتبر قبل/بعد لازم است.

### گروه 2: Iranian exchange asset observations, request queues, workers, Bit24 and admin monitoring

**Migration IDs:** `20261115101709`, `20261115102729`, `20261115102927`, `20261115103227`, `20261115103507`, `20261115105721`, `20261115105956`

**روابط زندهٔ مرتبط (نام/متادیتا):**
- `public.exchange_asset_observations`: owner `postgres`، RLS `true`، forced RLS `false`، columns=13، indexes=4، constraints=5، policies=0، triggers=1.
- `public.exchange_asset_sync_requests`: owner `postgres`، RLS `true`، forced RLS `false`، columns=6، indexes=1، constraints=2، policies=0، triggers=0.
- `public.bit24_exchange_sync_requests`: owner `postgres`، RLS `true`، forced RLS `false`، columns=5، indexes=1، constraints=1، policies=0، triggers=0.
- `public.admin_market_listings`: owner `postgres`، RLS `true`، forced RLS `false`، columns=3، indexes=2، constraints=3، policies=1، triggers=1.

**روتین‌های زنده و fingerprint:**
- `public.request_iran_exchange_asset_sync()` — return `integer`; owner `postgres`; `search_path=""`; MD5 `22e4150dd0ae30a2e3abf81887c52897`.
- `public.process_iran_exchange_asset_sync()` — return `jsonb`; owner `postgres`; `search_path=""`; MD5 `889c3728e54154a799e55ed8b9bc2edb`.
- `public.request_bit24_exchange_sync()` — return `integer`; owner `postgres`; `search_path=""`; MD5 `629da0df67c74eeb41948f368b584043`.
- `public.process_bit24_exchange_sync()` — return `jsonb`; owner `postgres`; `search_path=""`; MD5 `9f3e6d7e20586ea79b7c021eebc6ab62`.
- `public.admin_exchange_asset_sync_report()` — return `jsonb`; owner `postgres`; `search_path=""`; MD5 `fb633c495a9dec841d57c30a4a06972b`.
- `public.admin_request_exchange_asset_sync()` — return `jsonb`; owner `postgres`; `search_path=""`; MD5 `5fd277d145c28193cc5110f9acdb358a`.
- `private.auto_list_verified_exchange_asset()` — return `trigger`; owner `postgres`; `search_path=""`; MD5 `49880c0892cad6081acb6ce071090a5d`.

**Trigger bindings زنده:**
- `trg_auto_list_verified_exchange_asset` روی `public.exchange_asset_observations`: `CREATE TRIGGER trg_auto_list_verified_exchange_asset AFTER INSERT OR UPDATE OF match_status, coingecko_id, is_active ON public.exchange_asset_observations FOR EACH ROW EXECUTE FUNCTION private.auto_list_verified_exchange_asset()`

**Cron metadata ثبت‌شده:**
- jobid `13`, name `digiarz-iran-exchange-request`, schedule `*/10 * * * *`, active `true`. command text/fingerprint در این crosswalk موجود نیست.
- jobid `14`, name `digiarz-iran-exchange-process`, schedule `1,31 * * * *`, active `true`. command text/fingerprint در این crosswalk موجود نیست.

**نتیجهٔ provenance:** اشیای بالا candidateهای تطبیق فعلی‌اند، نه اثبات منشأ تاریخی. برای تعیین اینکه هر Migration دقیقاً چه چیزی ایجاد/تغییر داده، همچنان SQL اصلی یا transcript معتبر قبل/بعد لازم است.

### گروه 3: automatic activation of verified exchange pairs

**Migration IDs:** `20261116201639`

**روابط زندهٔ مرتبط (نام/متادیتا):**
- `public.crypto_assets`: owner `postgres`، RLS `true`، forced RLS `false`، columns=14، indexes=6، constraints=1، policies=1، triggers=0.
- `public.admin_market_listings`: owner `postgres`، RLS `true`، forced RLS `false`، columns=3، indexes=2، constraints=3، policies=1، triggers=1.
- `public.market_prices`: owner `postgres`، RLS `true`، forced RLS `false`، columns=4، indexes=1، constraints=2، policies=2، triggers=0.
- `public.exchange_asset_observations`: owner `postgres`، RLS `true`، forced RLS `false`، columns=13، indexes=4، constraints=5، policies=0، triggers=1.
- `public.demo_trading_pairs`: owner `postgres`، RLS `true`، forced RLS `false`، columns=6، indexes=2، constraints=5، policies=1، triggers=0.

**روتین‌های زنده و fingerprint:**
- `private.auto_activate_verified_exchange_pairs()` — return `jsonb`; owner `postgres`; `search_path=""`; MD5 `fd177baeee1a5bdd927458413f69bfb6`.

**Trigger bindings زنده:**
- هیچ trigger binding مستقیم از توابع فهرست‌شدهٔ این گروه در snapshot ثبت نشده است؛ این به‌معنای نبودن triggerهای دیگر در Production نیست.

**Cron metadata ثبت‌شده:**
- jobid `18`, name `digiarz-auto-activate-verified-exchange-pairs`, schedule `9-59/10 * * * *`, active `true`. command text/fingerprint در این crosswalk موجود نیست.

**نتیجهٔ provenance:** اشیای بالا candidateهای تطبیق فعلی‌اند، نه اثبات منشأ تاریخی. برای تعیین اینکه هر Migration دقیقاً چه چیزی ایجاد/تغییر داده، همچنان SQL اصلی یا transcript معتبر قبل/بعد لازم است.

### گروه 4: request backpressure, pg_net queue/response backup and temporary worker throttling

**Migration IDs:** `20261121045434`, `20261121045531`, `20261121050216`

**روابط زندهٔ مرتبط (نام/متادیتا):**
- `private.digiarz_pg_net_queue_backup_20261121`: در relation dependency inventory مستقیم موجود نیست.
- `private.digiarz_pg_net_response_backup_20261121`: در relation dependency inventory مستقیم موجود نیست.
- `public.exchange_asset_sync_requests`: owner `postgres`، RLS `true`، forced RLS `false`، columns=6، indexes=1، constraints=2، policies=0، triggers=0.
- `public.bit24_exchange_sync_requests`: owner `postgres`، RLS `true`، forced RLS `false`، columns=5، indexes=1، constraints=1، policies=0، triggers=0.

**روتین‌های زنده و fingerprint:**
- recovery map اولیه routine مستقیمی نام‌گذاری نکرده بود؛ query فقط‌خواندنی cron بعدی نشان داد job 11 تابع `public.recover_stale_crypto_assets_sync()` را فراخوانی می‌کند. این انتساب، اجرای فعلی job را ثابت می‌کند نه اینکه کدام Migration آن را ایجاد/تغییر داده باشد.

**Trigger bindings زنده:**
- هیچ trigger binding مستقیم از توابع فهرست‌شدهٔ این گروه در snapshot ثبت نشده است؛ این به‌معنای نبودن triggerهای دیگر در Production نیست.

**Cron metadata ثبت‌شده:**
- jobid `11`, name `digiarz-crypto-assets-stale-request-recovery`, schedule `3-59/5 * * * *`, active `true`. command text/fingerprint در این crosswalk موجود نیست.
- jobid `13`, name `digiarz-iran-exchange-request`, schedule `*/10 * * * *`, active `true`. command text/fingerprint در این crosswalk موجود نیست.
- jobid `14`, name `digiarz-iran-exchange-process`, schedule `1,31 * * * *`, active `true`. command text/fingerprint در این crosswalk موجود نیست.

**نتیجهٔ provenance:** اشیای بالا candidateهای تطبیق فعلی‌اند، نه اثبات منشأ تاریخی. برای تعیین اینکه هر Migration دقیقاً چه چیزی ایجاد/تغییر داده، همچنان SQL اصلی یا transcript معتبر قبل/بعد لازم است.

### کنترل‌های ایمنی
- شمار توابع در snapshot: 46; روابط schema-qualified resolved در dependency scan: 27/27; unresolved candidates: 0.
- Trigger bindings ثبت‌شده: 6.
- هیچ row از wallets، users، transactions، pg_net queues یا backup tables خوانده نشده است.
- هیچ grant/revoke، policy، function، trigger، cron، queue، دادهٔ مالی یا schema در Production تغییر نکرده است.
- این پیوست صرفاً سند ممیزی است و executable نیست.


### پیوست تکمیلی: fingerprint واقعی cron و فهرست کامل triggerها

این بخش با query فقط‌خواندنی روی metadata جدول `cron.job` در Production تهیه شده است. متن فرمان cron، payload صف‌ها یا داده‌های مالی خوانده نشده‌اند؛ فقط طول فرمان و MD5 آن ثبت شده است.

| Job ID | Job name | Schedule | Active | Command length | Command MD5 |
|---:|---|---|---:|---:|---|
| 11 | `digiarz-crypto-assets-stale-request-recovery` | `3-59/5 * * * *` | true | 49 | `5c182585822f912c390e2ed687cf9e74` |
| 13 | `digiarz-iran-exchange-request` | `*/10 * * * *` | true | 49 | `62655c28a0daceec20aca5364a5fcce3` |
| 14 | `digiarz-iran-exchange-process` | `1,31 * * * *` | true | 49 | `3e06c306d02133389ef070049aa6576c` |
| 18 | `digiarz-auto-activate-verified-exchange-pairs` | `9-59/10 * * * *` | true | 55 | `a6a3e9093cf3b72ab84897f43d320f41` |

Metadata اتصال ثبت‌شده برای هر چهار job: database=`postgres`، username=`postgres`. این fingerprintها وضعیت فعلی command را ثبت می‌کنند و تاریخچهٔ تغییر schedule/command یا انتساب قطعی به یک Migration خاص را ثابت نمی‌کنند.

**تمام شش trigger binding ثبت‌شده در snapshot Production:**

| Trigger | Relation | Function | Function MD5 |
|---|---|---|---|
| `trg_auto_list_verified_exchange_asset` | `public.exchange_asset_observations` | `private.auto_list_verified_exchange_asset()` | `49880c0892cad6081acb6ce071090a5d` |
| `admin_market_listing_unique_ticker` | `public.admin_market_listings` | `private.enforce_unique_admin_market_listing_symbol()` | `6e9a7e9f7d8cd5f0ac20f3216ee5f0b3` |
| `guard_active_account_orders` | `public.orders` | `private.guard_active_account_writes()` | `29b8e23c1de8eb4762a8cf1a9c9343ce` |
| `guard_active_account_trades` | `public.trades` | `private.guard_active_account_writes()` | `29b8e23c1de8eb4762a8cf1a9c9343ce` |
| `guard_active_account_transactions` | `public.transactions` | `private.guard_active_account_writes()` | `29b8e23c1de8eb4762a8cf1a9c9343ce` |
| `on_auth_user_created` | `auth.users` | `public.new_user_setup()` | `9ad150e007399b8feeca58399d8187d7` |

این فهرست تمام trigger bindingهای موجود در snapshot ممیزی است، نه ادعای جامعیت همهٔ triggerهای دیتابیس؛ scope manifest فقط توابع SECURITY DEFINER است.

**محدودیت ایمنی:** jobهای 11/13/14/18 فقط fingerprint شدند؛ هیچ jobی متوقف، کند، زمان‌بندی مجدد یا اجرا نشد. به‌ویژه هیچ تغییری در jobهای موتور سفارش اعمال نشد.


### اصلاح انتساب cron به routine — query فقط‌خواندنی تکمیلی

برای چهار job، فقط نام routine فراخوانی‌شده از متن فرمان با regex استخراج شد؛ متن کامل command نمایش یا ذخیره نشد. این نتیجه، انتساب اجرای فعلی job به routine را روشن می‌کند، اما منشأ تاریخی Migration را اثبات نمی‌کند.

| Job ID | Invoked routine | Routine definition MD5 | Command MD5 |
|---:|---|---|---|
| 11 | `public.recover_stale_crypto_assets_sync()` | `9ab6efcdb72cce454244f81aecc1da86` | `5c182585822f912c390e2ed687cf9e74` |
| 13 | `public.request_iran_exchange_asset_sync()` | `22e4150dd0ae30a2e3abf81887c52897` | `62655c28a0daceec20aca5364a5fcce3` |
| 14 | `public.process_iran_exchange_asset_sync()` | `889c3728e54154a799e55ed8b9bc2edb` | `3e06c306d02133389ef070049aa6576c` |
| 18 | `private.auto_activate_verified_exchange_pairs()` | `fd177baeee1a5bdd927458413f69bfb6` | `a6a3e9093cf3b72ab84897f43d320f41` |

**تطبیق گروهی دقیق‌تر:**
- گروه Migrationهای 2026-11-15: job 13 مستقیماً `public.request_iran_exchange_asset_sync()` و job 14 مستقیماً `public.process_iran_exchange_asset_sync()` را فراخوانی می‌کند.
- گروه Migrationهای 2026-11-16: job 18 مستقیماً `private.auto_activate_verified_exchange_pairs()` را فراخوانی می‌کند.
- گروه Migrationهای 2026-11-21: job 11 مستقیماً `public.recover_stale_crypto_assets_sync()` را فراخوانی می‌کند. این routine در snapshot manifest موجود است؛ fingerprint بالا از همان manifest گرفته شده است.

این crosswalk اجرای فعلی job را به routine وصل می‌کند؛ برای اثبات اینکه کدام یک از Migrationهای گروه، آن routine یا cron job را ایجاد/تغییر داده، همچنان SQL اصلی یا transcript تاریخی معتبر لازم است. هیچ job یا routine اجرا یا تغییر داده نشد.


### تأیید دوبارهٔ fingerprint چهار routine در Production

برای اطمینان از اینکه اتصال cron-to-routine صرفاً متکی به snapshot قبلی نیست، fingerprint تعریف زندهٔ هر چهار routine با `pg_get_functiondef` دوباره محاسبه شد. هر چهار مقدار با manifest تاریخ 2026-11-25 یکسان است.

| Routine | Result type | Live definition MD5 | Owner | search_path |
|---|---|---|---|---|
| `public.recover_stale_crypto_assets_sync()` | `void` | `9ab6efcdb72cce454244f81aecc1da86` | `postgres` | `""` |
| `public.request_iran_exchange_asset_sync()` | `integer` | `22e4150dd0ae30a2e3abf81887c52897` | `postgres` | `""` |
| `public.process_iran_exchange_asset_sync()` | `jsonb` | `889c3728e54154a799e55ed8b9bc2edb` | `postgres` | `""` |
| `private.auto_activate_verified_exchange_pairs()` | `jsonb` | `fd177baeee1a5bdd927458413f69bfb6` | `postgres` | `""` |

**نتیجه:** تطبیق fingerprint فعلی Production با manifest برای این چهار routine برابر است (۴/۴). این فقط یکسان‌بودن تعریف فعلی را تأیید می‌کند و هیچ ادعایی دربارهٔ نسخهٔ اولیه یا محتوای تاریخی Migrationها ندارد.
