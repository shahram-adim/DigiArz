# Supabase migration history reconciliation

Checked on **2026-11-17 02:14 Asia/Tehran** against project `gfoaubfilhttnwjykaox` and the current `main` branch.

## Current inventory

- Supabase migration history contains **52 applied entries**.
- `supabase/migrations/` in GitHub contains **40 SQL files**.
- **14 applied migrations** have no corresponding SQL source file in the current repository.
- **20 local files** have timestamp prefixes that differ from the applied versions, although their descriptive suffixes map to the same applied migration names.
- **2 local files are not recorded as applied** in Supabase.
- Only **4 local files** match an applied version exactly.
- A GitHub commit-history lookup for the exact canonical paths of the 14 missing files returned no path history. This does not prove that no copy exists elsewhere; it means no authoritative source was recovered by this check.
- The migration-history table has not been edited.

## Applied migrations with no local SQL source

| Applied version | Applied name |
|---|---|
| 20261113153808 | approved_wallet_defaults_fees_and_coin_reviews |
| 20261113154323 | assign_confirmed_super_admin |
| 20261113154736 | secure_admin_wallet_management |
| 20261113154750 | add_admin_role_probe |
| 20261113154844 | use_toman_units_in_admin_credit_ui |
| 20261113154926 | move_admin_privilege_logic_to_private_schema |
| 20261115101709 | create_exchange_asset_observations |
| 20261115102729 | schedule_iran_exchange_asset_sync |
| 20261115102927 | fix_exchange_sync_response_json_cast |
| 20261115103227 | auto_list_verified_exchange_assets |
| 20261115103507 | schedule_bit24_exchange_asset_sync |
| 20261115105721 | admin_exchange_asset_sync_monitoring |
| 20261115105956 | restrict_exchange_sync_worker_execution |
| 20261116201639 | auto_activate_verified_exchange_pairs |

## Local filename prefixes that do not match applied versions

| Current local file prefix | Applied version in Supabase | Migration name |
|---|---|---|
| 20261113162202 | 20261113162154 | record_conditional_reservation_consumption |
| 20261113162244 | 20261113162233 | index_conditional_execution_order_reference |
| 20261113170000 | 20261113163743 | recover_stalled_crypto_asset_sync |
| 20261113171000 | 20261113163947 | add_admin_curated_market_assets |
| 20261113172000 | 20261113164521 | harden_admin_market_listing_access |
| 20261113180000 | 20261113165725 | add_admin_pair_activation_engine |
| 20261113180500 | 20261113165747 | fix_market_price_decimal_parser |
| 20261113181000 | 20261113165806 | show_live_prices_for_curated_assets |
| 20261113182000 | 20261113170056 | rate_limit_manual_market_refresh |
| 20261113183000 | 20261113170216 | index_market_pair_admin_audit |
| 20261113184000 | 20261113170328 | prevent_curated_ticker_collisions |
| 20261113190000 | 20261113173506 | admin_on_demand_crypto_asset_refresh |
| 20261115134500 | 20261115134357 | add_kifpool_to_scheduled_exchange_asset_sync |
| 20261115134600 | 20261115134855 | avoid_relisting_unchanged_exchange_asset_matches |
| 20261115143000 | 20261115142521 | allow_verified_kifpool_cfg_jup_exact_id_aliases |
| 20261115143200 | 20261115142620 | prioritize_exact_name_matches_for_kifpool_assets |
| 20261115145000 | 20261115143015 | allow_verified_kifpool_rebrand_aliases |
| 20261115145500 | 20261115143050 | allow_verified_kifpool_additional_name_aliases |
| 20261115150000 | 20261115143223 | allow_verified_kifpool_exact_id_name_aliases_batch |
| 20261117130000 | 20261116205451 | stagger_market_price_overflow_and_refresh_exchange_discovery |

## Local files not recorded as applied

| Local version | Migration name |
|---|---|
| 20261116203000 | add_kucoin_to_scheduled_market_price_refresh |
| 20261116203100 | add_gateio_to_scheduled_market_price_refresh |

### Confirmed regression hazard

Both local-only migrations replace `public.refresh_market_prices()` with older function definitions:

- `20261116203000_add_kucoin_to_scheduled_market_price_refresh.sql` adds CoinGecko and KuCoin but does not include Gate.io or the 515-ID primary CoinGecko cap.
- `20261116203100_add_gateio_to_scheduled_market_price_refresh.sql` adds Gate.io but still has no 515-ID cap.
- The already-applied migration `20261116203709_limit_primary_coingecko_batch_to_515_ids` installs the later capped implementation. Because that version is already recorded remotely, a normal push would not replay it after the two pending older migrations.

A read-only check of the live function confirmed that Production currently contains the 515-ID cap and CoinGecko, KuCoin, and Gate.io branches. Therefore applying the two local-only files in timestamp order would regress the live function and remove the cap unless the migration set is reconciled first.

## Live schedule verification

The current Production cron rows were read without modification:

| Job ID | Active schedule | Command |
|---|---|---|
| 13 | `*/10 * * * *` | `request_iran_exchange_asset_sync()` |
| 14 | `1-59/10 * * * *` | `process_iran_exchange_asset_sync()` |
| 17 | `5-59/10 * * * *` | `private.request_market_price_overflow()` |

As of the read-only snapshot on 2026-11-20, jobs 13 and 17 match the local SQL, but live job 14 is `1-59/10 * * * *` while the local SQL still sets `* * * * *`. The applied Supabase version is `20261116205451`, whereas the local file is version `20261117130000`; this is both a timestamp and content/schedule mismatch. Do not replay the local file or manually rewrite migration history.

## Transfer safeguards

1. **Do not run `supabase db push`.** The current local migration set is not a safe replay set; it contains 20 timestamp-mismatched files and two older local-only function replacements.
2. Do not apply either local-only KuCoin/Gate.io migration as-is. Preserve them as evidence until a reviewed reconciliation plan determines whether to archive them outside `supabase/migrations/` or replace them with a documented no-op/superseded record.
3. Recover the 14 missing SQL sources from an authoritative backup, deployment record, or trusted source. The exact canonical GitHub paths did not yield commit history in this check.
4. For each of the 20 timestamp mismatches, compare the full SQL content with the applied version before any filename repair. Similar suffixes alone are insufficient evidence.
5. Do not rename or repair Supabase migration-history rows manually.
6. Keep Production schema, functions, jobs, and financial data unchanged until the migration inventory is reproducible and the user explicitly authorizes a database transfer.
7. Before any future deployment, rehearse the reconciled migration set against a disposable PostgreSQL 17 database and verify the final `refresh_market_prices()` definition and cron schedules.

This report is an inventory and safety analysis only. It changes no database object, cron job, migration-history row, order, wallet, balance, or financial record.


## تصحیح زمان‌بندی زندهٔ بازار و مغایرت منبع Migration — ۲۰ نوامبر ۲۰۲۶
- [x] وضعیت زندهٔ `cron.job` دوباره فقط‌خواندنی خوانده شد. برنامهٔ فعلی:
  - job 13: `*/10 * * * *` — `request_iran_exchange_asset_sync()`
  - job 14: `1-59/10 * * * *` — `process_iran_exchange_asset_sync()`
  - job 17: `5-59/10 * * * *` — `private.request_market_price_overflow()`
- [!] فایل محلی `20261117130000_stagger_market_price_overflow_and_refresh_exchange_discovery.sql` در خط مربوط به job 14 هنوز `* * * * *` (هر دقیقه) را ثبت می‌کند؛ بنابراین ادعای قبلی این سند که زمان‌بندی زنده با بدنهٔ فایل محلی منطبق است، برای job 14 دیگر صحیح نیست. نسخهٔ ثبت‌شدهٔ Supabase برابر `20261116205451` است، درحالی‌که فایل محلی نسخهٔ `20261117130000` دارد؛ فایل canonical با نسخهٔ remote در مسیر migrations پیدا نشد.
- [!] این یک اختلاف واقعی بین وضعیت زنده و منبع محلی است. منشأ تغییر schedule زنده به `1-59/10` از تاریخچهٔ قابل‌دسترسی GitHub اثبات نشد؛ ممکن است تغییر بعدی مستقیم یا از مسیر دیگری اعمال شده باشد، اما این صرفاً احتمال است.
- [x] آمار اجرای ۲۴ ساعت اخیر نشان می‌دهد job 14 در مجموع 563 موفق و 136 ناموفق داشته (106 startup timeout و 30 statement timeout). این آمار شامل اجرای قبل از تغییر cadence نیز هست؛ بنابراین نباید از آن برای استنتاج cadence فعلی استفاده کرد. در شش ساعت اخیر 36 اجرا ثبت شده که با cadence فعلی 6 بار در ساعت سازگار است.
- [!] هیچ‌یک از scheduleها تغییر داده نشدند و تاریخچهٔ migration نیز دست‌کاری نشد. تا بازیابی منبع canonical و تعیین cadence مورد انتظار، `supabase db push` همچنان ممنوع است.
- [ ] اقدام بعدی: منبع معتبر تغییر job 14 به `1-59/10` را از deployment/audit record بازیابی کن؛ سپس نسخهٔ local و remote را با مقایسهٔ کامل SQL reconciliate و در PostgreSQL 17 دورریختنی replay کن. هیچ اصلاح Production بدون تأیید صریح کاربر انجام نشود.

## ممیزی تازه ۲۲ نوامبر ۲۰۲۶ — منبع Migrationها و بازیابی worker
- [x] Supabase migration ledger دوباره خوانده شد: ۵۵ Migration اعمال‌شده؛ آخرین نسخه `20261121050216` با نام `temporarily_throttle_exchange_asset_processors_20261121`.
- [x] در درخت واقعی شاخه `main` تعداد ۴۰ فایل SQL در `supabase/migrations/` وجود دارد. سه Migration جدید ledger در این شاخه فایل SQL متناظر ندارند:
  - `20261121045434` — `digiarz_backpressure_and_exchange_sync_bloat_guards`
  - `20261121045531` — `snapshot_pg_net_unlogged_queue_before_recovery`
  - `20261121050216` — `temporarily_throttle_exchange_asset_processors_20261121`
- [!] بنابراین شمار منابع اعمال‌شدهٔ فاقد SQL محلی نسبت به inventory قبلی از ۱۴ به ۱۷ افزایش یافته است (با فرض حفظ همان ۱۴ مورد قبلی). جست‌وجوی commit با نام دقیق این سه Migration نتیجه‌ای نداد؛ این بررسی نبود فایل در `main` را ثابت می‌کند، نه نبود هر نسخهٔ معتبر در تمام backupها یا شاخه‌های دیگر. محتوای Migrationها از روی نام حدس زده نشده است.
- [x] زمان‌بندی زندهٔ `cron.job` در snapshot ساعت ۲۲:۳۲ UTC دوباره تأیید شد:
  - job 13: `*/10 * * * *` — `request_iran_exchange_asset_sync()`
  - job 14: `1,31 * * * *` — `process_iran_exchange_asset_sync()` (هر ۳۰ دقیقه)
  - job 17: `5-59/10 * * * *` — `private.request_market_price_overflow()`
- [!] فایل محلی `20261117130000_stagger_market_price_overflow_and_refresh_exchange_discovery.sql` هنوز job 14 را با `* * * * *` تعریف می‌کند و با cadence زنده یکسان نیست. آخرین Migration ثبت‌شدهٔ `20261121050216` منبع محتملِ تغییر موقت است، اما چون SQL آن در `main` موجود نیست، رابطهٔ دقیق تغییر با این Migration اثبات نشده است.
- [x] پنجرهٔ شش‌ساعتهٔ `2026-11-21 16:34–22:33 UTC`: job 14 دوازده اجرای موفق و صفر شکست داشت؛ median زمان اجرا `21.392s` بود. jobهای 13 و 17 هرکدام ۳۶ اجرای موفق و صفر شکست داشتند. در همان پنجره سایر jobهای مشاهده‌شده نیز فقط موفق بودند.
- [x] در ۲۴ ساعت کامل، job 14 هنوز ۴۰ شکست و ۳۴ موفقیت دارد؛ این پنجره شکست‌های قبل از throttling را هم شامل می‌شود. آخرین شکست ثبت‌شدهٔ job 14 در `05:31 UTC` بود؛ بنابراین آمار ۲۴ساعته را نباید با پنجرهٔ شش‌ساعتهٔ پس از بازیابی یکی دانست.
- [x] صف `exchange_asset_sync_requests` در snapshot فعلی ۲٬۳۷۰ درخواست تاریخی، صفر درخواست pending و صفر درخواست pending قدیمی‌تر از ۳۰ دقیقه داشت. برای هر هفت exchange نیز pending برابر صفر بود؛ آخرین پردازش ثبت‌شده `22:31 UTC` بود.
- [!] این داده‌ها نشانهٔ پایداری بهتر worker در پنجرهٔ اخیرند، اما علت ریشه‌ای شکست‌های قبلی یا اثر مستقل هر Migration را اثبات نمی‌کنند. زمان اجرای job 14 همچنان حدود ۲۰ تا ۲۸ ثانیه است و باید در محیط ایزوله تحلیل شود.
- [x] هیچ cron، Migration، تابع، schema، grant، queue، سفارش، معامله، رزرو، کیف پول، موجودی یا سابقهٔ مالی در Production تغییر نکرد.
- [ ] اقدام بعدی: SQL سه Migration جدید را از deployment artifact/backup معتبر بازیابی کن؛ با محتوای live function و schedule تطبیق بده؛ سپس مجموعهٔ بازسازی‌شده را در PostgreSQL 17 دورریختنی replay کن. تا آن زمان `supabase db push` ممنوع بماند.

## ممیزی تکمیلی ۲۵ نوامبر ۲۰۲۶ — مسیر واقعی Worker و وضعیت نام فارسی

این بخش با خواندن فقط‌خواندنی Production در تاریخ ۲۰۲۶-۱۱-۲۵ اضافه شده است.

### تأیید زمان‌بندی زنده
- job 13 فعال است: `*/10 * * * *` و `public.request_iran_exchange_asset_sync()`.
- job 14 فعال است: `1,31 * * * *` و `public.process_iran_exchange_asset_sync()`.
- job 17 فعال است: `5-59/10 * * * *` و `private.request_market_price_overflow()`.
- این snapshot با cadence ثبت‌شده در بخش ۲۲ نوامبر (job 14 هر ۳۰ دقیقه) سازگار است؛ هیچ زمان‌بندی تغییر نکرد.

### مسیر واقعی همگام‌سازی
- Cronهای ۱۳ و ۱۴ مستقیماً توابع SQL را اجرا می‌کنند؛ این مسیر با فراخوانی Edge Function یکسان نیست.
- تعریف زندهٔ `public.process_iran_exchange_asset_sync()` پاسخ‌های صف را در `public.exchange_asset_observations` ذخیره و تطبیق می‌کند؛ در بدنهٔ فعلی آن هیچ فراخوانی به `extractPersianNameCandidate` یا افزودن کلید `_digiarz_persian_name_candidate` وجود ندارد.
- Edge Function زندهٔ `sync-iran-exchange-assets` در Production نسخهٔ ۷ و فعال است. سورس مستقر آن نیز `source_payload: o` را ذخیره می‌کند و استخراج‌کنندهٔ نام فارسی در آن وجود ندارد.
- سورس جدید شاخهٔ آزمایشی `feature/persian-asset-name-candidates-2026` شامل استخراج‌کننده است؛ اما این تفاوت هنوز به Production منتقل نشده و Worker زمان‌بندی‌شدهٔ SQL هم مستقل از آن باقی است.
- در ممیزی قبلی Production تعداد ۴٬۹۷۰ مشاهده و صفر candidate envelope ثبت شده بود. این وضعیت با سورس مستقر Edge Function و مسیر SQL زنده سازگار است؛ بنابراین وجود کد در شاخهٔ Git به‌تنهایی به معنای فعال‌شدن استخراج نام فارسی در داده‌های زنده نیست.

### وضعیت پروژهٔ آزمایشی موجود
- پروژهٔ `DigiArz-Recovery-Test` با شناسهٔ `zrriqwyolcjhbappocuw` فعال و سالم است.
- دفتر Migration آن فقط ۲ رکورد دارد و فهرست Edge Functionهای آن خالی است.
- جدول مشاهدات در آن موجود و دارای ۴٬۹۶۰ رکورد است؛ پس این پروژه نیز محیط تمیز و مستقل برای replay کامل تاریخچه نیست و نباید بدون آماده‌سازی و مجوز جداگانه برای تست Migration استفاده شود.

### نتیجه و قفل ایمنی
- هیچ Edge Function مستقر، تابع SQL، Cron، جدول، مجوز، داده یا Migration در Production یا پروژهٔ آزمایشی تغییر نکرد.
- سورس Worker آزمایشی با نسخهٔ مستقر Production متفاوت است. پیش از فعال‌سازی candidate extraction باید مسیر زمان‌بندی‌شدهٔ SQL و مسیر Edge Function به‌صورت یکپارچه طراحی و تست شوند؛ از اجرای دستی Worker روی Production برای آزمایش خودداری شود.
- بازیابی SQL سه Migration کنترل فشار/صف در ۲۱ نوامبر و ۱۴ Migration قدیمی‌تر همچنان باز است. هیچ محتوایی از روی نام Migration حدس زده نشده است.


## ممیزی تکمیلی ۲۵ نوامبر ۲۰۲۶ — شواهد زنده برای Migrationهای مفقود

این بخش فقط از متادیتا و تعریف اشیای زندهٔ PostgreSQL خوانده شده است؛ متن SQL اصلی Migrationهای مفقود از روی وضعیت فعلی بازسازی یا جعل نشده است.

### شواهد برای ۶ Migration مدیریتی/کیف پول
- `approved_wallet_defaults_fees_and_coin_reviews`: جدول‌های `public.demo_trading_fees`، `public.coin_reviews` و `public.coin_review_reports` وجود دارند و RLS روی هر سه فعال است. تابع `public.get_demo_trading_fee_rate(text,text)` نیز فعال است. Policyهای خواندن عمومی و ایجاد/ویرایش/حذف نظر با محدودیت مالکیت و وضعیت حساب مشاهده شدند.
- `assign_confirmed_super_admin` و `add_admin_role_probe`: جدول `private.admin_users` موجود است و توابع `private.is_super_admin()` و `private.is_current_user_super_admin()` به آن متکی‌اند. در این بررسی هیچ شناسهٔ کاربری یا مقدار شخصی role استخراج یا در گزارش ثبت نشد.
- `secure_admin_wallet_management`: جدول `private.admin_wallet_adjustments` موجود است. تابع `private.admin_adjust_wallet(...)` با مالک postgres، SECURITY DEFINER و search_path خالی اجرا می‌شود؛ هویت مدیر را از auth.uid() می‌گیرد، نقش super_admin را بررسی می‌کند، بدهی USDT رزروشده در سفارش‌های باز را لحاظ می‌کند و adjustment را audit می‌کند. wrapper عمومی `public.admin_adjust_wallet(...)` SECURITY DEFINER نیست.
- `use_toman_units_in_admin_credit_ui`: تابع مدیریتی زنده برای ارز `TOMAN`، تبدیل به واحد ذخیره‌سازی IRR با ضریب ۱۰ و ثبت transaction با currency برابر IRR را نشان می‌دهد. این فقط رفتار فعلی تابع را اثبات می‌کند، نه جزئیات UI تاریخی Migration.
- `move_admin_privilege_logic_to_private_schema`: توابع `private.is_super_admin()` و `private.is_current_user_super_admin()` در schema خصوصی قرار دارند؛ تابع public هم‌نام فقط wrapper بدون SECURITY DEFINER است. این با هدف انتقال منطق حساس به private سازگار است.

### شواهد برای Migrationهای exchange sync
- جدول‌های `public.exchange_asset_observations` و `public.exchange_asset_sync_requests` موجودند و RLS دارند.
- توابع `public.request_iran_exchange_asset_sync()` و `public.process_iran_exchange_asset_sync()` هر دو SECURITY DEFINER، مالک postgres و دارای search_path خالی‌اند.
- `process_iran_exchange_asset_sync()` پاسخ صف را به observations تبدیل می‌کند، نام و نماد را از payload منابع استخراج می‌کند، upsert و match انجام می‌دهد و درخواست‌ها را processed علامت می‌زند.
- تابع Trigger `private.auto_list_verified_exchange_asset()` وجود دارد و در صورت matched + active + CoinGecko ID، فهرست بازار را با قیود اعتبار قیمت/دارایی به‌روزرسانی می‌کند.
- Cronهای ۱۳ و ۱۴ مسیر SQL بالا را اجرا می‌کنند. Edge Function جداگانهٔ `sync-iran-exchange-assets` نسخهٔ ۷ فعال است؛ کد آن با مسیر SQL زمان‌بندی‌شده یکسان نیست.
- برای Migrationهای `schedule_bit24_exchange_asset_sync` و `admin_exchange_asset_sync_monitoring` در این نوبت هنوز تمام جزئیات منبع تاریخی و اشیای UI/monitoring به‌طور مستقل بازیابی نشده است؛ صرف وجود جدول و cron برای اثبات کامل بدنهٔ آن‌ها کافی نیست.
- `restrict_exchange_sync_worker_execution`: تعریف زندهٔ تابع SQL با SECURITY DEFINER و search_path خالی مشاهده شد؛ اما برای اثبات دقیق policyهای اجرا و مجوزهای نقش‌ها باید privilege matrix و cron ownership جداگانه استخراج شود.

### وضعیت CI و PR
- Commit گزارش ممیزی قبلی `2274ef2ce1d9742efe3f6936fd59bf0d2b984532` دارای دو check با نام `unit-tests` است که هر دو با conclusion برابر `success` تکمیل شدند.
- PR #62 همچنان open، Draft و merged=false است. این CI موفق فقط به همان commit مربوط است؛ پس از تغییر تازهٔ همین گزارش، CI جدید هنوز باید اجرا و بررسی شود.

### نتیجهٔ این مرحله
- شواهد زنده برای وجود و رفتار بخشی از اشیای مربوط به ۱۴ Migration مفقود به دست آمد، اما SQL اصلی هیچ‌یک از ۱۴ Migration به‌عنوان منبع معتبر بازیابی نشد.
- این شواهد برای طراحی یک baseline بازسازی‌شده مفیدند، ولی برای بازنویسی migration history یا ساخت Migrationهای جایگزین کافی نیستند.
- هیچ تغییری در Production، جدول‌ها، توابع، grants، RLS، Cronها، داده‌های مالی یا migration ledger انجام نشد.


## وضعیت اصلاح‌شدهٔ گزارش و CI — ۲۵ نوامبر ۲۰۲۶

این یادداشت، snapshotهای تاریخی بالاتر را حذف نمی‌کند؛ فقط وضعیت نهایی‌تر را مشخص می‌کند:

- inventory فعلی Migration در Production برابر **۵۵ رکورد** است؛ در شاخهٔ `main` تعداد **۴۰ فایل SQL** موجود است. در فهرست ممیزی‌شده، **۱۷ Migration اعمال‌شده فاقد فایل SQL متناظر با نام canonical** هستند. این به معنی اثبات نابودی همهٔ نسخه‌ها نیست؛ بازیابی از artifact یا backup معتبر همچنان لازم است.
- زمان‌بندی زندهٔ تأییدشده در ممیزی ۲۵ نوامبر برای job 14 برابر `1,31 * * * *` است؛ jobهای 13 و 17 نیز مطابق جدول ممیزی همان تاریخ فعال‌اند. مقادیر قدیمی‌تر در بخش‌های تاریخی، snapshot زمان خودشان هستند.
- بخش «وضعیت CI و PR» در snapshot قبلی پیش از اجرای نهایی CI نوشته شده بود و دیگر وضعیت جاری را نشان نمی‌دهد. برای commit فعلی PR #62 یعنی `ea8b541af8fa8037627c16ba3258506698370cfa`، GitHub Actions run **45563453868** (run #67) با نتیجهٔ **success** تکمیل شده است. Job `unit-tests` و هر دو مرحلهٔ «Test Persian asset-name candidate extraction» و «Type-check the isolated exchange-sync Edge Function» موفق بوده‌اند.
- PR #62 همچنان open، Draft و ادغام‌نشده است. موفقیت CI مجوز merge، deploy، اجرای SQL یا تغییر Production محسوب نمی‌شود.
- این اصلاح صرفاً مستندسازی در شاخهٔ آزمایشی است؛ هیچ Migration، جدول، تابع، grant، RLS، cron، صف یا دادهٔ Production تغییر نکرده است.
