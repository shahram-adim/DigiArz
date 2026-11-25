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


## شواهد تکمیلی زنده برای Migrationهای Bit24، پایش و محدودیت Worker — ۲۵ نوامبر ۲۰۲۶

این بررسی فقط SELECT از کاتالوگ PostgreSQL، تعریف توابع و جدول `cron.job` بود.

### زمان‌بندی Bit24 و جدول درخواست
- Cron job 15 با نام `digiarz-bit24-request` فعال است؛ schedule برابر `*/30 * * * *` و command برابر `select public.request_bit24_exchange_sync();` است.
- Cron job 16 با نام `digiarz-bit24-process` فعال است؛ schedule برابر `16,46 * * * *` و command برابر `select public.process_bit24_exchange_sync();` است.
- جدول `public.bit24_exchange_sync_requests` وجود دارد، مالک آن postgres است و RLS آن فعال است (FORCE RLS خاموش).
- توابع `request_bit24_exchange_sync()` و `process_bit24_exchange_sync()` هر دو SECURITY DEFINER، مالک postgres و دارای search_path خالی هستند.
- این شواهد، وجود مسیر عملیاتی Bit24 و زمان‌بندی آن را تأیید می‌کند؛ اما متن SQL اصلی Migration `schedule_bit24_exchange_asset_sync` هنوز بازیابی نشده و تطبیق کامل محتوایی با Migration ثبت‌شده انجام نشده است.

### تابع پایش مدیریتی
- تابع `public.admin_exchange_asset_sync_report()` وجود دارد؛ بدون آرگومان، خروجی JSONB، مالک postgres، SECURITY DEFINER و search_path خالی.
- بدنهٔ زنده قبل از ساخت گزارش، `private.is_current_user_super_admin()` را بررسی می‌کند و در غیر این صورت خطای 42501 می‌دهد.
- گزارش summary، وضعیت منابع و حداکثر ۱۰۰ مورد نیازمند بررسی تطبیق را از جدول‌های observations و sync requests می‌سازد.
- ACL زنده: postgres، authenticated و service_role مجاز؛ anon فاقد EXECUTE است.
- Commit تاریخی `987ef541a797e3078c5ca6f41d1f46bba2a3e723` فقط تغییر `index.html` برای UI پایش را نشان می‌دهد؛ فایل SQL Migration در همان Commit وجود ندارد.
- بنابراین وجود UI و تابع پایش و رفتار فعلی آن تأیید شده، ولی SQL اصلی Migration `admin_exchange_asset_sync_monitoring` هنوز بازیابی نشده است.

### محدودیت اجرای Worker
- ACL توابع `request_iran_exchange_asset_sync()`, `process_iran_exchange_asset_sync()`, `request_bit24_exchange_sync()` و `process_bit24_exchange_sync()`: postgres و service_role مجازند؛ anon و authenticated مجوز مستقیم ندارند.
- چهار Cron مرتبط (jobs 13 تا 16) در زمان snapshot فعال بودند؛ زمان‌بندی‌های زنده:
  - job 13: `*/10 * * * *`
  - job 14: `1,31 * * * *`
  - job 15: `*/30 * * * *`
  - job 16: `16,46 * * * *`
- این privilege matrix با هدف محدودکردن اجرای مستقیم Worker سازگار است، اما مالکیت/نقش اجراکنندهٔ Cron و متن SQL اصلی Migration `restrict_exchange_sync_worker_execution` باید جداگانه از منبع تاریخی تأیید شود؛ صرف ACL تابع برای بازسازی کامل Migration کافی نیست.

### نتیجهٔ این بررسی
- شواهد زنده برای سه Migration بالا قوی‌تر شد، اما هیچ‌یک از SQLهای اصلی آن‌ها از این مرحله بازیابی نشد.
- هیچ Cron، تابع، grant، RLS، جدول، صف، داده، Migration یا تنظیم Production تغییر نکرد.
- این شواهد را نباید به‌عنوان مجوز db push، تغییر ACL یا بازنویسی migration ledger تفسیر کرد.


## ممیزی تکمیلی صف pg_net و اجرای Worker — ۲۵ نوامبر ۲۰۲۶

این بخش از SELECTهای فقط‌خواندنی روی Production به دست آمده است. زمان مشاهدهٔ داده‌های runtime حدود ۲۰۲۶-۱۱-۲۵ ساعت ۰۶:۵۷ UTC بود.

### وضعیت صف درخواست‌های همگام‌سازی
- جدول `public.exchange_asset_sync_requests` دارای ۳٬۴۹۷ رکورد تاریخی است؛ ۷ درخواست هنوز `processed_at IS NULL` دارند، اما هیچ درخواست pending قدیمی‌تر از ۳۰ دقیقه نیست.
- ۳٬۴۱۲ درخواست دارای HTTP status موفق ۲xx و ۴ درخواست دارای status خطای ۴xx/۵xx هستند؛ سایر رکوردها لزوماً شکست محسوب نمی‌شوند و ممکن است status نداشته باشند.
- جدیدترین درخواست ثبت‌شده در این snapshot ساعت ۰۶:۴۰ UTC بود.
- جدول `public.bit24_exchange_sync_requests` نیز وجود دارد؛ در این مرحله آمار تفصیلی صف آن جداگانه محاسبه نشده است.

### وضعیت واقعی pg_net
- هر دو جدول `net.http_request_queue` و `net._http_response` از نوع UNLOGGED هستند؛ `relpersistence='u'`.
- اندازهٔ کل `net._http_response` حدود **۱۲۸ MiB** و اندازهٔ `net.http_request_queue` حدود **۲۴۰ KiB** بود.
- تعداد ردیف‌های فعلی `http_request_queue` صفر بود.
- `net._http_response` در snapshot شامل ۱٬۲۴۶ پاسخ بود؛ قدیمی‌ترین پاسخ ساعت ۰۰:۵۸ UTC و جدیدترین ساعت ۰۶:۵۷ UTC ثبت شده بود. سه پاسخ timeout داشتند و پاسخ با HTTP status خطا در این بازه صفر بود.
- تعداد ۱٬۱۱۴ پاسخ در `net._http_response` با شناسهٔ درخواست‌های دو جدول عمومی `exchange_asset_sync_requests` و `bit24_exchange_sync_requests` تطبیق داده نشد. این فقط به معنی «عدم تطبیق با این دو جدول» است؛ نمی‌توان بدون بررسی سایر مصرف‌کنندگان pg_net آن‌ها را درخواست یتیم یا قابل‌حذف نامید.
- تخمین آماری PostgreSQL برای `net._http_response` حدود ۱٬۲۴۶ ردیف زنده و ۲۱۱ ردیف مرده و برای `net.http_request_queue` صفر ردیف زنده و ۴۹ ردیف مرده نشان می‌داد. این‌ها تخمین pg_stat هستند، نه شمارش دقیق heap.
- روی `net._http_response` شاخص `_http_response_created_idx` برای ستون `created` وجود دارد؛ شاخص دیگری در خروجی این بررسی مشاهده نشد.

### سلامت اجرای Cron در پنجرهٔ اخیر
- در ۲۴ ساعت منتهی به snapshot، برای هر یک از jobهای ۱۳، ۱۴، ۱۵ و ۱۶ دقیقاً ۴۸ یا ۱۴۴ اجرای زمان‌بندی‌شده مطابق cadence ثبت‌شده مشاهده شد؛ همهٔ اجراهای برگشتی در این چهار job با status برابر `succeeded` بودند.
- میانگین زمان اجرا در همین پنجره: job 13 حدود ۰٫۰۶ ثانیه، job 14 حدود ۲۳٫۵۳ ثانیه، job 15 حدود ۰٫۰۵ ثانیه و job 16 حدود ۱٫۲۰ ثانیه.
- آخرین اجرای job 14 در این snapshot ساعت ۰۶:۳۱ UTC پایان یافت؛ job 13 آخرین بار ساعت ۰۶:۵۰ و job 16 ساعت ۰۶:۴۶ UTC اجرا شده بود.
- این snapshot نشانهٔ موفقیت اجرای زمان‌بندی‌شده در پنجرهٔ اخیر است، اما به‌تنهایی سلامت کامل شبکهٔ بیرونی، کامل‌بودن داده‌های هر صرافی یا علت اندازهٔ ۱۲۸ MiB جدول پاسخ را اثبات نمی‌کند.

### ارتباط با Migrationهای مفقود ۲۱ نوامبر
- اندازه و نوع UNLOGGED جدول‌های pg_net با موضوع Migration دارای نام `snapshot_pg_net_unlogged_queue_before_recovery` مرتبط است، اما هیچ مدرکی در این مرحله نشان نمی‌دهد که Migration مذکور چه snapshotی گرفته، کجا ذخیره کرده، چه داده‌ای را بازیابی کرده یا چه cleanupی انجام داده است.
- وجود صف خالی و ۷ درخواست pending بدون تأخیر بیش از ۳۰ دقیقه، رفتار فعلی را توصیف می‌کند؛ این داده‌ها محتوای Migrationهای `digiarz_backpressure_and_exchange_sync_bloat_guards` و `temporarily_throttle_exchange_asset_processors_20261121` را بازسازی نمی‌کنند.
- **هیچ پاک‌سازی، VACUUM، DELETE، snapshot، بازیابی، تغییر Cron، اجرای دستی Worker یا تغییر در pg_net انجام نشد.** برای بازیابی SQL اصلی همچنان باید deployment artifact یا backup معتبر پیدا شود.



## بررسی مسیر Backup و امکان بازیابی Migration Source — ۲۵ نوامبر ۲۰۲۶

در درخت شاخهٔ `main` دو سند و یک Workflow مرتبط با پشتیبان‌گیری پیدا شد:
- `docs/DATABASE_BACKUP_RECOVERY.md`
- `docs/MIGRATION_SOURCE_INVENTORY.md`
- `.github/workflows/manual-database-backup.yml`

### دامنهٔ Backup موجود
- Workflow با PostgreSQL 17 از schemaهای `public` و `private` آرشیو custom-format رمزگذاری‌شده می‌سازد.
- دادهٔ سه صف موقت خصوصی `private.crypto_assets_sync_requests`، `private.market_fx_sync_requests` و `private.market_price_sync_requests` عمداً از dump حذف می‌شود؛ ساختار جدول‌ها در آرشیو می‌ماند.
- مستند رسمی مخزن صریحاً می‌گوید آرشیو شامل `supabase_migrations.schema_migrations`، Auth users، Storage، Vault secrets، Edge Functions یا تنظیمات پروژه نیست.
- در نتیجه این Backup می‌تواند برای بازسازی بخشی از وضعیت schema و توابع فعلی کمک کند، اما **منبع SQL Migrationهای تاریخی یا Migration ledger را در خود ندارد** و به‌تنهایی شکاف ۱۷ Migration را حل نمی‌کند.
- رمز Backup در GitHub Secret نگهداری می‌شود؛ هیچ Secret یا credential خوانده یا استخراج نشد.

### بررسی artifactهای Drill شناخته‌شده
- مستند بازیابی به Backup run شمارهٔ `43848835281` و Restore drill شمارهٔ `44298621534` اشاره می‌کند.
- فهرست artifactهای قابل‌دسترسی برای هر دو run در زمان این بررسی خالی برگشت. با توجه به retention هفت‌روزهٔ Workflow، این artifactها اکنون از طریق این endpoint قابل بازیابی نیستند؛ این نتیجه به معنی حذف نسخه‌های مستقل یا خارج از GitHub نیست.
- Restore drill موفق ۱۸ نوامبر صرفاً بازگردانی schemaهای public/private به پروژهٔ ایزوله را ثابت می‌کند و نه بازیابی Migration source یا تاریخچهٔ Migration را.

### تصمیم ایمنی
- Workflow پشتیبان‌گیری دستی اجرا نشد؛ اجرای آن مستلزم export داده‌های Production و استفاده از Secretهای مخزن است و برای این ممیزی لازم نبود.
- پروژهٔ Recovery-Test پاک‌سازی یا بازنویسی نشد.
- هیچ Secret، artifact رمزگشایی‌شده، backup، Migration ledger یا دادهٔ Production تغییر نکرد.

### نتیجه و مسیر بازیابی معتبر
- مسیر Backup فعلی برای schema recovery مفید است، ولی منبع Migrationهای مفقود نیست.
- مسیر بعدی باید artifactهای مستقلِ deployment/release یا نسخه‌های محفوظ خارج از retention هفت‌روزه را هدف بگیرد. هر فایل بازیابی‌شده باید با commit provenance، hash، نام Migration و مقایسهٔ محتوایی با وضعیت زنده اعتبارسنجی شود.
- تا یافتن منبع معتبر، ۱۷ Migration همچنان «فاقد فایل canonical بازیابی‌شده» هستند؛ از این عبارت نباید نتیجه گرفت که همهٔ نسخه‌ها قطعاً نابود شده‌اند.

### اصلاح وضعیت CI برای Commit مستندات قبلی
- GitHub Actions بعد از Commit `8f7a3ec558bfbd79f0504acd1539663c37eec12f` دو run مرتبط ثبت کرده است: run #72 با event از نوع push و run #73 با event از نوع pull_request؛ هر دو conclusion برابر `success` هستند.
- این نتیجه، وضعیت قبلی گزارش که «برای این Commit اجرای CI ثبت نشده» را اصلاح می‌کند. موفقیت این Workflow فقط همان تست‌های تعریف‌شده در `DigiArz Persian asset-name candidate tests` را نشان می‌دهد؛ جایگزین CI کامل برنامه، تست PostgreSQL Migration یا تست Production نیست.
- PR #62 همچنان Draft و ادغام‌نشده است؛ این موفقیت‌ها مجوز merge، deploy یا اجرای SQL نیستند.


## بررسی مستقیم Snapshotهای pg_net در Production — ۲۵ نوامبر ۲۰۲۶

این بررسی فقط SELECT روی کاتالوگ PostgreSQL و دو جدول Snapshot موجود انجام شد. هیچ محتوای درخواست HTTP، URL خصوصی، header یا body در گزارش کپی نشده است.

### نسخه افزونه و ساختار
- افزونه pg_net در schema برابر extensions و نسخه 0.20.4 نصب است.
- جدول زنده net._http_response ستون‌های id، status_code، content_type، headers، content، timed_out، error_msg و created دارد.
- جدول زنده net.http_request_queue ستون‌های id، method، url، headers، body و timeout_milliseconds دارد.
- جدول Snapshot صف شامل captured_at و ستون‌های صف اصلی است؛ Snapshot پاسخ نیز captured_at و ستون‌های پاسخ اصلی را حفظ کرده است.

### آمار Snapshot صف
- private.digiarz_pg_net_queue_backup_20261121: تعداد ۴٬۶۴۰ ردیف.
- بازه capture: ۲۱ نوامبر ۲۰۲۶، از ۰۴:۵۵:۳۱ تا ۰۵:۰۵:۲۱ UTC.
- روش‌ها: ۴٬۵۳۳ درخواست GET و ۱۰۷ درخواست POST.
- بازه شناسه‌ها: ۲۹٬۱۳۶ تا ۳۳٬۷۷۹.
- حجم کل جدول Snapshot حدود ۷٬۰۴۰ KiB است.

### آمار Snapshot پاسخ
- private.digiarz_pg_net_response_backup_20261121: تعداد ۵۴۱ ردیف.
- بازه زمان ایجاد پاسخ‌ها: ۱۹ نوامبر ۲۰۲۶، از ۱۶:۵۷:۲۲ تا ۲۲:۵۷:۰۰ UTC.
- ۴۵۹ پاسخ HTTP 2xx، یک پاسخ 4xx، صفر پاسخ 5xx، ۷۸ ردیف با timed_out=true و ۸۱ ردیف دارای error_msg ثبت شده‌اند.
- میانگین طول content حدود ۲۹۶٬۶۱۰ نویسه و بیشینه ۷۳۸٬۱۷۵ نویسه است؛ ۸۱ ردیف content تهی دارند.
- حجم کل جدول Snapshot پاسخ حدود ۴۰ MiB است.

### تفسیر زمانی و محدودیت تطبیق
- Snapshot صف در ۲۱ نوامبر گرفته شده، درحالی‌که پاسخ‌های Snapshotشده در ۱۹ نوامبر ایجاد شده‌اند. بنابراین این دو جدول Snapshot هم‌زمان نیستند.
- تطبیق مستقیم شناسه id بین دو جدول Snapshot در این بررسی صفر ردیف مشترک نشان داد. به‌دلیل اختلاف زمانی capture و ماهیت دو Snapshot، این نتیجه به‌تنهایی نشانه خرابی یا از دست‌رفتن پاسخ نیست و نباید برای نتیجه‌گیری درباره ارتباط request/response استفاده شود.
- پاسخ‌های ذخیره‌شده Snapshot به‌طور متوسط حجیم‌اند؛ این با یافته قبلی غالب بودن TOAST در حجم جدول زنده net._http_response سازگار است، اما رابطه مستقیم هر پاسخ Snapshot با رشد فعلی TOAST هنوز اثبات نشده است.
- جست‌وجوی GitHub برای نام دقیق دو جدول Snapshot، نام Migration snapshot_pg_net_unlogged_queue_before_recovery و timestamp آن، commit منبعی برنگرداند. این فقط نتیجه جست‌وجوی فعلی است و نبود نسخه در تمام artifactها یا مخازن را اثبات نمی‌کند.

### نتیجه و اقدام بعدی
- اکنون وجود واقعی دو Snapshot و دامنه زمانی/حجمی آن‌ها تأیید شده است؛ بااین‌حال SQL اصلی Migration، منطق انتخاب ردیف‌ها، روش capture، هرگونه restore و cleanup همچنان از منبع canonical بازیابی نشده‌اند.
- قبل از هر طراحی بازیابی باید DDL/constraints/indexes/ACLهای دو جدول Snapshot، زمان و مالکیت ساخت آن‌ها، و محتوای Migration از deployment artifact معتبر بازیابی شود.
- هیچ Snapshot جدیدی گرفته نشد؛ هیچ ردیفی از صف یا پاسخ حذف/بازیابی نشد؛ هیچ VACUUM، Cron، Worker، Migration، grant یا تنظیم Production تغییر نکرد.


### کنترل دسترسی و ساختار فیزیکی جدول‌های Snapshot — ۲۵ نوامبر ۲۰۲۶
- هر دو جدول Snapshot مالک postgres هستند؛ RLS و FORCE RLS روی آن‌ها خاموش است.
- در خروجی pg_indexes هیچ indexی برای این دو جدول ثبت نشد و در pg_constraint نیز هیچ constraintی پیدا نشد.
- در role_table_grants فقط postgres برای این دو جدول مجوز داشت؛ grant مستقیمی برای anon، authenticated یا service_role در خروجی مشاهده نشد.
- این وضعیت با جدول‌های پشتیبان موقت و محدود به مالک سازگار است، اما از روی آن نمی‌توان سیاست دقیق Migration تاریخی یا intent سازنده را اثبات کرد.
- PR #62 در بازبینی تازه همچنان open، Draft و merged=false است؛ GitHub در زمان این بررسی mergeable=true گزارش کرد. بنابراین مقدار mergeable=false که در گزارش قبلی ثبت شده بود، یک snapshot قدیمی/متغیر بود و با وضعیت تازه جایگزین شد. Commit مستنداتی d0770af2a48b81536a2ceddb446a2dab1aa5594d workflow run مستقلی ندارد؛ تغییر Markdown است و نباید CI-tested معرفی شود. هیچ تلاش merge انجام نشد.


### دوام فیزیکی Snapshotها و نبود سازوکار خودکارِ ثبت‌شده — ۲۵ نوامبر ۲۰۲۶
- کاتالوگ PostgreSQL هر دو جدول Snapshot را با relpersistence='p' گزارش می‌کند؛ یعنی هر دو جدول permanent هستند، نه TEMP و نه UNLOGGED.
- ستون captured_at در هر دو جدول nullable است و default ندارد. ستون‌های دیگر نیز nullable و بدون default ثبت شده‌اند.
- هیچ تابعی با نام حاوی snapshot در schemaهای public/private/net پیدا نشد. جست‌وجوی قبلی نیز تابع اپلیکیشنی مشخصی برای purge/retention پاسخ‌ها پیدا نکرده بود. این شواهد وجود هر نوع cleanup بیرونی یا اجرای SQL با نام متفاوت را رد نمی‌کند.
- آمار pg_stat_user_tables برای این دو جدول هنوز صفر/NULL است و قابل استفاده برای نتیجه‌گیری دربارهٔ تعداد ردیف یا vacuum نیست؛ تعداد واقعی ردیف‌ها از COUNT مستقیم در بررسی قبلی گرفته شده است.
- نکتهٔ مهم: permanent بودن جدول‌ها به‌معنای ماندگاری تا زمان حذف صریح است؛ در شواهد فعلی TTL، partitioning یا cleanup خودکار برای این دو Snapshot دیده نشد. بنابراین نباید آن‌ها را «موقت» توصیف کرد. همچنین اندازهٔ ۴۰ MiB Snapshot پاسخ شامل دادهٔ ذخیره‌شده است و به‌خودی‌خود bloat محسوب نمی‌شود.


### یادداشت پایداری وضعیت mergeability — ۲۵ نوامبر ۲۰۲۶
در چند دریافت متوالی از GitHub، فیلد mergeable برای PR #62 به‌ترتیب false، سپس true و مجدداً false گزارش شد، درحالی‌که state=open، draft=true و merged=false ثابت ماند. بنابراین mergeability در این بازه ناپایدار/در حال محاسبه بوده و نباید مقدار لحظه‌ای را به‌عنوان رفع قطعی conflict تفسیر کرد. PR ادغام نشده و هیچ اقدام merge یا update-branch انجام نشده است. Commit فعلی گزارش cb5c7ef02fb8d5af9064a8f3bb632b2ecc036452 است؛ برای این commit workflow run ثبت نشده است.


## بازیابی منبع اصلی سه Migration مورخ ۲۱ نوامبر از ledger زنده Production — ۲۵ نوامبر ۲۰۲۶

### روش و اعتبار منبع
با SELECT فقط‌خواندنی از ستون `statements` جدول `supabase_migrations.schema_migrations`، متن SQL هر سه رکورد زیر بازیابی شد. این منبع از جست‌وجوی نام فایل یا استنتاج از وضعیت فعلی قوی‌تر است و متن ثبت‌شدهٔ Migration زمان اجرا را حفظ می‌کند. منبع کامل در فایل بازبینی‌پذیر زیر ذخیره شده است:

`supabase/drafts/2026-11-25_recovered-production-migration-sources.md`

Commit: `7ef1932c49744b88408f3b80118eb3e574ed9c8a` (branch `feature/persian-asset-name-candidates-2026`). این فایل در پوشه drafts است و جزو مسیر migrations نیست.

### 1) 20261121045434 — digiarz_backpressure_and_exchange_sync_bloat_guards
- ایجاد index جزئی `crypto_assets_upper_symbol_active_idx` روی `upper(symbol)` برای دارایی‌های فعال.
- بازنویسی محافظه‌کارانهٔ `public.refresh_market_prices()`: درخواست‌های بیش از ۳۰ دقیقه فقط وقتی حذف می‌شوند که شناسه در هیچ‌یک از صف یا پاسخ pg_net نباشد؛ تا وقتی درخواست‌های قبلی در صف یا جدول پیگیری باقی‌اند، batch جدید ارسال نمی‌شود.
- `private.request_market_price_overflow()` تا خالی‌شدن batch قبلی صبر می‌کند.
- `public.refresh_market_fx_rate()` برای درخواست‌های معوق و تکراری محافظت اضافه می‌کند.
- توابع درخواست و پردازش کشف دارایی‌های ایران و Bit24 از enqueue تکراری جلوگیری می‌کنند و ردیف‌های observation بدون تغییر را بی‌جهت بازنویسی نمی‌کنند.
- `public.recover_stale_crypto_assets_sync()` هنگام retry/delete وجود درخواست در صف pg_net را نیز بررسی می‌کند.
- این Migration شامل دستور مستقیم پاک‌کردن `net._http_response` یا `net.http_request_queue` نیست. DELETEهای آن روی صف‌های پیگیری داخلی و فقط پس از نبود شناسه در هر دو جدول pg_net انجام می‌شوند.

### 2) 20261121045531 — snapshot_pg_net_unlogged_queue_before_recovery
- دقیقاً دو جدول permanent با CTAS ایجاد می‌کند و تمام ردیف‌های موجود صف و پاسخ را همراه `captured_at` کپی می‌کند.
- هیچ DELETE، TRUNCATE، تغییر Cron یا restore در متن آن وجود ندارد.
- بنابراین نام Migration شامل unlogged است، اما جدول‌های خروجی با CREATE TABLE معمولی ساخته شده‌اند و permanent هستند؛ مشاهدهٔ relpersistence='p' این موضوع را تأیید می‌کند.

### 3) 20261121050216 — temporarily_throttle_exchange_asset_processors_20261121
متن اصلی فقط دو دستور است:
- `cron.alter_job(14, schedule := '1,31 * * * *')`
- `cron.alter_job(16, schedule := '16,46 * * * *')`
این تغییر فقط دو processor کشف دارایی ایران و Bit24 را زمان‌بندی مجدد می‌کند؛ در این Migration تغییری به job موتور سفارش‌های معاملاتی داده نشده است. schedule فعلی این دو job در snapshot زنده نیز با همین مقادیر گزارش شده بود.

### اصلاح شمارش reconciliation
این سه Migration همچنان در درخت SQL محلی شاخه‌ها فاقد فایل canonical هم‌نام‌اند، اما اکنون متن اصلی هر سه از ledger Production بازیابی و در draft artifact ذخیره شده است. بنابراین آن‌ها دیگر «منبع SQL ناشناخته» محسوب نمی‌شوند؛ وضعیت درست «منبع اصلی بازیابی شده، فایل migrations محلی هنوز بازسازی/تطبیق نشده» است. این تفاوت مهم است و شمار ۱۷ مورد فاقد فایل محلی را نباید با ۱۷ مورد فاقد منبع SQL یکی دانست.

### کنترل ایمنی
فقط SELECT از ledger اجرا شد و فایل Markdown/SQL متنی در پوشه drafts شاخهٔ آزمایشی ایجاد شد. هیچ Migration اجرا یا ledger ویرایش نشد؛ هیچ Cron، Worker، جدول، داده یا تابع Production تغییر نکرد؛ هیچ Merge یا هزینه‌ای ایجاد نشد.


### بازبینی نهایی زمان‌بندی Cron و وضعیت PR — ۲۵ نوامبر ۲۰۲۶
- Cron job 8 با نام `digiarz-limit-orders` فعال و روی `* * * * *` باقی است؛ command آن `public.process_limit_orders()` است.
- Jobهای 13 و 15 (request) فعال و با برنامه‌های قبلی خود باقی‌اند: ایران هر ۱۰ دقیقه و Bit24 هر ۳۰ دقیقه.
- Jobهای 14 و 16 (processor) فعال‌اند و دقیقاً schedule ثبت‌شده در Migration throttling را دارند: دقیقه‌های 1 و 31 برای ایران، و 16 و 46 برای Bit24.
- Job 17 (market-price overflow) فعال و روی `5-59/10` باقی است.
- نتیجهٔ روشن: تغییر زمان‌بندی Migration شمارهٔ 20261121050216 محدود به processorهای کشف دارایی است؛ موتور سفارش‌های limit همچنان هر دقیقه فعال است. هیچ jobی تغییر داده نشد.
- در آخرین دریافت GitHub، PR #62 همچنان open، Draft و merged=false است و mergeable=false گزارش شد. این فیلد در دریافت‌های متوالی ناپایدار بوده است؛ به‌عنوان وضعیت قطعی conflict تفسیر نشود. هیچ Merge یا update-branch انجام نشده است.


## تطبیق قطعات Migration Backpressure با تعریف زندهٔ توابع Production — ۲۵ نوامبر ۲۰۲۶

### روش
- متن اصلی statement از ledger Production برای Migration `20261121045434` با SELECT خوانده شد.
- از هر بخش `v_def := pg_get_functiondef(...)`، قطعات مقصد `v_new := $new$...$new$` استخراج شدند.
- این قطعات با تعریف زندهٔ همان تابع از `pg_get_functiondef` مقایسه شدند؛ فقط whitespace برای مقایسه نرمال شد، محتوای SQL/کامنت‌ها تغییر داده نشد.

### نتیجه
هر ۱۴ قطعه در تابع مقصد فعلی Production به‌صورت کامل پیدا شد:

| تابع | قطعات | نتیجه |
|---|---:|---|
| `public.refresh_market_prices()` | ۱/۱ | تطبیق کامل |
| `private.request_market_price_overflow()` | ۱/۱ | تطبیق کامل |
| `public.refresh_market_fx_rate()` | ۲/۲ | تطبیق کامل |
| `public.request_iran_exchange_asset_sync()` | ۱/۱ | تطبیق کامل |
| `public.request_bit24_exchange_sync()` | ۱/۱ | تطبیق کامل |
| `public.recover_stale_crypto_assets_sync()` | ۲/۲ | تطبیق کامل |
| `public.process_iran_exchange_asset_sync()` | ۳/۳ | تطبیق کامل |
| `public.process_bit24_exchange_sync()` | ۳/۳ | تطبیق کامل |
| **جمع** | **۱۴/۱۴** | **همهٔ قطعات حاضرند** |

این تطبیق ثابت می‌کند قطعات مقصدی که Migration قصد درج/جایگزینی آن‌ها را داشته، در تعریف فعلی توابع وجود دارند. این کار به‌تنهایی سلامت اجرایی همهٔ مسیرها، صحت داده‌ها یا ایمنی replay را اثبات نمی‌کند و مجوز اجرای دوباره نیست. Migration شامل CREATE INDEX نیز جداگانه از نظر وجود/تعریف index باید با catalog بررسی شود؛ این بررسی در گام بعد انجام می‌شود.

### PR #62
آخرین fetch در همین مرحله: PR باز، Draft و merged=false؛ فیلد mergeable در آن لحظه true بود. این فیلد قبلاً نوسان داشته و فقط snapshot لحظه‌ای است؛ mergeability را به‌عنوان مجوز ادغام یا تضمین عدم conflict تلقی نکنید. هیچ merge یا update-branch انجام نشد.

### ایمنی
تمام دستورات Supabase این مرحله SELECT روی ledger و کاتالوگ/تعریف توابع بودند. هیچ Migration، DDL، DML، Cron یا Worker اجرا/تغییر نشد. هیچ داده‌ای حذف یا بازنویسی نشد و هزینه‌ای ایجاد نشد.


### کنترل ایندکس و نگهداری فایل‌های منبع تاریخی به‌صورت SQL قابل بازبینی
- کاتالوگ `pg_indexes` در Production، ایندکس `public.crypto_assets_upper_symbol_active_idx` را روی `public.crypto_assets` با تعریف دقیق `USING btree (upper(symbol)) WHERE (is_active IS TRUE)` نشان داد؛ با دستور CREATE INDEX در Migration اصلی مطابقت دارد.
- برای سه Migration بازیابی‌شده، فایل‌های SQL مستقل در پوشهٔ `supabase/drafts/` شاخهٔ آزمایشی ایجاد شدند؛ هر فایل header هشدار دارد که منبع تاریخیِ قبلاً اجراشده است و Migration اجرایی نیست:
  - `recovered_20261121045434_digiarz_backpressure_and_exchange_sync_bloat_guards.sql` — commit `31677f3f41fcbb2bc2cab0189b75a4a569f2df4d`
  - `recovered_20261121045531_snapshot_pg_net_unlogged_queue_before_recovery.sql` — commit `210e24e516c7c4a30e6482c6a0edce6f19956f3f`
  - `recovered_20261121050216_temporarily_throttle_exchange_asset_processors.sql` — commit `7d8402a602b5553fad9534aa89b5b4450a774a5c`
- این فایل‌ها عمداً زیر `supabase/drafts/` هستند و در مسیر `supabase/migrations/` قرار نگرفته‌اند؛ هیچ‌کدام اجرا نشده‌اند.
- همراه با فایل تجمیعی `2026-11-25_recovered-production-migration-sources.md`، اکنون متن کامل هر سه منبع هم به‌صورت سند و هم SQL جداگانه در شاخهٔ آزمایشی قابل بازبینی است.


## ممیزی سیاست نگهداری pg_net و تفکیک آن از Snapshotهای دائمی — ۲۵ نوامبر ۲۰۲۶

### تنظیمات واقعی و worker
- `pg_net.ttl = 6 hours` و source آن `default` است؛ `pg_net.batch_size=200` نیز default است.
- worker نسخهٔ `pg_net 0.20.4` در `pg_stat_activity` حاضر و active دیده شد.
- در لحظهٔ بررسی، `net._http_response` شامل 1,246 ردیف بود؛ قدیمی‌ترین پاسخ 2026-11-25 01:14:00 UTC و جدیدترین 07:13:00 UTC. تعداد پاسخ‌های قدیمی‌تر از ۶ ساعت، ۲۴ ساعت و ۷ روز همگی صفر بود. اندازهٔ relation برابر 128 MB بود.
- صف زندهٔ `net.http_request_queue` در همان snapshot صفر ردیف داشت.
- در Cron هیچ jobی با ارجاع به `net._http_response`، `net.http_request_queue` یا دو جدول Snapshot پیدا نشد؛ در schema `net` نیز تابع app-level با نام/تعریف cleanup و trigger غیرسیستمی یافت نشد.

### تفسیر صحیح با اتکا به مستندات رسمی Supabase/pg_net
- TTL پاسخ‌های زنده توسط تنظیم داخلی `pg_net.ttl` مدیریت می‌شود؛ worker هنگام پردازش درخواست‌ها پاسخ‌های منقضی را پاک می‌کند. بنابراین برای این سازوکار Cron اختصاصی لازم نیست. مستندات رسمی می‌گویند TTL پیش‌فرض ۶ ساعت است و پاک‌سازی هنگام پردازش worker انجام می‌شود: https://supabase.com/docs/guides/database/extensions/pg_net و https://supabase.com/kb/troubleshooting/database-roles-can-read-request-headers-queued-by-pg_net
- این رفتار فقط برای جدول پاسخ متعلق به خود extension است؛ به دو جدول کپی‌شدهٔ `private.digiarz_pg_net_queue_backup_20261121` و `private.digiarz_pg_net_response_backup_20261121` تعمیم ندارد.
- Snapshotها permanent هستند و در جدول‌های مستقل ذخیره شده‌اند؛ TTL شش‌ساعتهٔ pg_net آن‌ها را پاک نمی‌کند. در بررسی فعلی هیچ retention یا cleanup خودکار برای Snapshotها پیدا نشد. بنابراین وجود 128 MB در جدول زنده با TTL/worker توضیح‌پذیر است، اما حجم Snapshot پاسخ حدود 41.7 MB یک کپی مستقل و ماندگار است؛ هیچ‌یک به‌تنهایی اثبات bloat نیست.

### نتیجهٔ ممیزی retention
- پاسخ‌های زنده: TTL شش‌ساعتهٔ پیش‌فرض، worker فعال، بدون Cron cleanup اختصاصی؛ snapshot فعلی با TTL سازگار است.
- صف زنده: در snapshot فعلی خالی.
- Snapshotهای Recovery: ماندگار و خارج از TTL pg_net؛ نیازمند تصمیم مستقل مالک دربارهٔ retention/آرشیو/حذف هستند. در این مرحله هیچ حذف یا تغییر retention انجام نمی‌شود.


## بازیابی کامل منابع ۱۷ Migration فاقد فایل canonical هم‌نام — ۲۵ نوامبر ۲۰۲۶

### نتیجهٔ مهم
هر ۱۷ رکوردی که در reconciliation قبلی در ledger Production وجود داشتند اما فایل canonical هم‌نام آن‌ها در شاخهٔ بررسی‌شده پیدا نشده بود، اکنون مستقیماً از ستون `statements` در `supabase_migrations.schema_migrations` بازیابی شدند. برای هر رکورد یک فایل SQL مستقل در `supabase/drafts/` ساخته شد؛ هر فایل header هشدار دارد و منبع تاریخیِ قبلاً اجراشده را «غیرقابل اجرا» معرفی می‌کند.

### کنترل صحت فایل‌ها
پس از ایجاد فایل‌ها، محتوای انتهایی هر فایل با statement متناظر در ledger Production مقایسه شد. نتیجه: **۱۷ از ۱۷ فایل، متن SQL منبع را دقیقاً حفظ کرده‌اند** (بدون تغییر محتوا؛ فقط header هشدار به ابتدای فایل اضافه شده است). این تطبیق، صحت بازیابی متن را تأیید می‌کند؛ هنوز تطبیق کامل هر Migration با وضعیت جاری schema، ترتیب وابستگی‌ها، و drift شاخه انجام نشده است.

### فهرست فایل‌های بازیابی‌شده
- `20261113153808` — `approved_wallet_defaults_fees_and_coin_reviews`: `supabase/drafts/recovered_20261113153808_approved_wallet_defaults_fees_and_coin_reviews.sql`
- `20261113154323` — `assign_confirmed_super_admin`: `supabase/drafts/recovered_20261113154323_assign_confirmed_super_admin.sql`
- `20261113154736` — `secure_admin_wallet_management`: `supabase/drafts/recovered_20261113154736_secure_admin_wallet_management.sql`
- `20261113154750` — `add_admin_role_probe`: `supabase/drafts/recovered_20261113154750_add_admin_role_probe.sql`
- `20261113154844` — `use_toman_units_in_admin_credit_ui`: `supabase/drafts/recovered_20261113154844_use_toman_units_in_admin_credit_ui.sql`
- `20261113154926` — `move_admin_privilege_logic_to_private_schema`: `supabase/drafts/recovered_20261113154926_move_admin_privilege_logic_to_private_schema.sql`
- `20261115101709` — `create_exchange_asset_observations`: `supabase/drafts/recovered_20261115101709_create_exchange_asset_observations.sql`
- `20261115102729` — `schedule_iran_exchange_asset_sync`: `supabase/drafts/recovered_20261115102729_schedule_iran_exchange_asset_sync.sql`
- `20261115102927` — `fix_exchange_sync_response_json_cast`: `supabase/drafts/recovered_20261115102927_fix_exchange_sync_response_json_cast.sql`
- `20261115103227` — `auto_list_verified_exchange_assets`: `supabase/drafts/recovered_20261115103227_auto_list_verified_exchange_assets.sql`
- `20261115103507` — `schedule_bit24_exchange_asset_sync`: `supabase/drafts/recovered_20261115103507_schedule_bit24_exchange_asset_sync.sql`
- `20261115105721` — `admin_exchange_asset_sync_monitoring`: `supabase/drafts/recovered_20261115105721_admin_exchange_asset_sync_monitoring.sql`
- `20261115105956` — `restrict_exchange_sync_worker_execution`: `supabase/drafts/recovered_20261115105956_restrict_exchange_sync_worker_execution.sql`
- `20261116201639` — `auto_activate_verified_exchange_pairs`: `supabase/drafts/recovered_20261116201639_auto_activate_verified_exchange_pairs.sql`
- `20261121045434` — `digiarz_backpressure_and_exchange_sync_bloat_guards`: `supabase/drafts/recovered_20261121045434_digiarz_backpressure_and_exchange_sync_bloat_guards.sql`
- `20261121045531` — `snapshot_pg_net_unlogged_queue_before_recovery`: `supabase/drafts/recovered_20261121045531_snapshot_pg_net_unlogged_queue_before_recovery.sql`
- `20261121050216` — `temporarily_throttle_exchange_asset_processors`: `supabase/drafts/recovered_20261121050216_temporarily_throttle_exchange_asset_processors.sql`

### وضعیت reconciliation پس از بازیابی
- شمار Migrationهای دارای رکورد ledger ولی فاقد فایل canonical هم‌نام که قبلاً ۱۷ بود، از نظر «منبع SQL ناشناخته» اکنون **صفر** است.
- از نظر «فایل canonical در مسیر migrations شاخه» این موارد هنوز فاقد فایل هستند؛ عمداً فقط در `supabase/drafts/` ذخیره شده‌اند تا هیچ db push یا migration runner آن‌ها را اجرا نکند.
- ۲۰ مورد اختلاف timestamp/نام‌گذاری دیگر که قبلاً شناسایی شده بودند، هنوز نیازمند تطبیق نام/محتوا هستند و نباید با این ۱۷ مورد یکی شمرده شوند.
- دو فایل محلی `20261116203000_add_kucoin_to_scheduled_market_price_refresh.sql` و `20261116203100_add_gateio_to_scheduled_market_price_refresh.sql` همچنان در ledger به‌عنوان Migration مستقل ثبت نشده‌اند و طبق بررسی قبلی به‌دلیل بازنویسی قدیمی `refresh_market_prices()` نباید بدون اصلاح و تطبیق اعمال شوند.

### کنترل ایمنی
منبع هر ۱۷ Migration فقط با SELECT از ledger Production خوانده شد. همهٔ فایل‌ها فقط در شاخهٔ آزمایشی و پوشهٔ `supabase/drafts/` ایجاد شدند. هیچ فایل به `supabase/migrations/` اضافه نشد؛ هیچ Migration یا SQL بازیابی‌شده اجرا نشد؛ هیچ تغییر DDL/DML، Cron، Worker، Merge یا Production انجام نشد.


### کنترل نهایی دامنهٔ PR پس از بازیابی ۱۷ منبع — ۲۵ نوامبر ۲۰۲۶
- PR #62 شامل ۲۶ فایل تغییر‌یافته است؛ ۱۸ فایل SQL در `supabase/drafts/` قرار دارند (۱۷ منبع تاریخی بازیابی‌شده + یک draft طراحی جدول تأیید نام فارسی).
- هیچ‌یک از فایل‌های PR زیر `supabase/migrations/` نیستند؛ بررسی فهرست کامل فایل‌های PR این موضوع را تأیید کرد.
- PR همچنان open، Draft و merged=false است. در آخرین fetch فیلد mergeable=false گزارش شد؛ چون این فیلد در همین جلسه true/false نوسان داشته، آن را فقط snapshot لحظه‌ای می‌دانیم، نه حکم قطعی conflict.
- هیچ workflow run جدیدی برای آخرین commit مستنداتی گزارش نشد؛ مستندات و بازیابی منبع را CI-tested معرفی نکنید.


## ممیزی اثر زندهٔ ۱۱ Migration مدیریتی، کیف پول و همگام‌سازی — ۲۵ نوامبر ۲۰۲۶

این بخش با مقایسهٔ SQL بازیابی‌شده از ledger با catalogهای Production تهیه شده است. تمام پرس‌وجوهای پایگاه داده در این مرحله فقط SELECT و خواندن metadata بوده‌اند. دسته‌بندی‌ها دربارهٔ اثر فعلی هستند، نه مجوز اجرای مجدد Migration.

### خلاصهٔ دسته‌بندی

| نسخه | Migration | دسته | نتیجهٔ تطبیق |
|---|---|---|---|
| 20261113153808 | approved_wallet_defaults_fees_and_coin_reviews | ۱ — اثر اصلی موجود و منطبق | defaults کیف پول، جداول fee/reviews/reports، محدودیت‌ها و سیاست‌های اصلی مشاهده شد؛ سه تابع معامله نیز از نرخ fee قابل‌تنظیم استفاده می‌کنند. |
| 20261113154323 | assign_confirmed_super_admin | ۲ — اثر موجود با محدودیت اثبات | schema/table/check/FK و تابع بررسی super-admin موجود است؛ یک رکورد super_admin به حساب فعال متصل است و granted_by همان حساب است. UUID و شرایط تاریخی لحظهٔ انتساب عمداً افشا یا از وضعیت فعلی استنتاج نشده‌اند. |
| 20261113154736 | secure_admin_wallet_management | ۲ — اثر موجود اما تکامل‌یافته | جدول audit و منطق کنترل دسترسی/رزرو/ثبت transaction موجود است؛ منطق فعلی در private قرار دارد و currency در audit برابر USDT/TOMAN است، نه USDT/IRR نسخهٔ اولیه. |
| 20261113154926 | move_admin_privilege_logic_to_private_schema | ۲ — اثر موجود با تفاوت ACL تکمیلی | توابع privileged در private با SECURITY DEFINER و search_path خالی قرار دارند؛ wrapperهای public از نوع SECURITY INVOKER هستند. ACL زنده شامل service_role نیز هست و از grantهای صریح تاریخی گسترده‌تر است. |
| 20261115101709 | create_exchange_asset_observations | ۱ — ساختار اصلی منطبق | جدول، identity، ستون‌ها، FK، unique constraint، دو index، RLS و دسترسی service_role با منبع سازگارند؛ Triggerهای بعدی جداگانه ثبت شده‌اند. |
| 20261115102729 | schedule_iran_exchange_asset_sync | ۲ — اثر موجود با تغییرات بعدی | جدول درخواست‌ها و توابع worker موجودند؛ فهرست منابع و منطق backpressure توسعه یافته و cadence زنده با دو schedule اولیه متفاوت است. |
| 20261115102927 | fix_exchange_sync_response_json_cast | ۲ — نسخهٔ اولیه superseded شده | پردازش پاسخ JSON وجود دارد، اما تابع زنده از private.try_parse_jsonb و رد پاسخ‌های غیرقابل‌تجزیه استفاده می‌کند، نه cast مستقیم r.content::jsonb در متن بازیابی‌شده. |
| 20261115103227 | auto_list_verified_exchange_assets | ۲ — اثر موجود با guard تکمیلی | تابع private و Trigger مربوط به آن وجود دارند؛ تابع زنده علاوه بر شروط اولیه، فقط INSERT یا تغییر واقعی وضعیت تطبیق/شناسه/فعال‌بودن را پردازش می‌کند. اثر تاریخی backfill به‌تنهایی از catalog فعلی قابل انتساب قطعی نیست. |
| 20261115105721 | admin_exchange_asset_sync_monitoring | ۲ — اثر موجود با ACL تکمیلی | هر دو تابع گزارش و درخواست sync وجود دارند و بررسی super-admin دارند؛ SECURITY DEFINER و search_path خالی‌اند. ACL زنده service_role را نیز مجاز می‌کند. |
| 20261115105956 | restrict_exchange_sync_worker_execution | ۱ — اثر امنیتی منطبق | برای چهار تابع request/process مربوط به worker، EXECUTE فقط برای postgres و service_role مشاهده شد؛ authenticated و anon مجوز ندارند. |
| 20261116201639 | auto_activate_verified_exchange_pairs | ۲ — منطق موجود، cadence متفاوت | تابع private با SECURITY DEFINER، search_path خالی و ACL محدود وجود دارد؛ Cron فعال است اما schedule زنده 9-59/10 است، نه هر دقیقهٔ تعریف‌شده در منبع تاریخی. |

### شواهد جزئی و نکات مهم

#### کیف پول، fee و بازخورد دارایی
- مقدار پیش‌فرض زندهٔ wallets.balance_usdt برابر ۲۰۰ و balance_irr برابر ۱٬۰۰۰٬۰۰۰٬۰۰۰ است؛ تابع new_user_setup() نیز همین مقادیر را هنگام ساخت حساب درج می‌کند. این با متن Migration بازیابی‌شده منطبق است، اما با تصمیم محصولی متأخرتر ۵۰ میلیون تومان (۵۰۰ میلیون IRR) یکسان نیست. این اختلاف صرفاً ثبت شد و هیچ default یا موجودی تغییر نکرد.
- نرخ‌های فعال زنده: USDT maker=0.001 و taker=0.0013؛ IRR maker/taker=0.0025. هر سه تابع execute_demo_trade, place_limit_order, process_limit_orders از get_demo_trading_fee_rate استفاده می‌کنند؛ مقدار ثابت 0.001 در مسیرهای بررسی‌شده باقی نمانده است.
- coin_reviews و coin_review_reports دارای RLS و محدودیت‌های اصلی مالکیت/اعتبارسنجی هستند. خواندن review برای anon/authenticated مجاز است؛ گزارش‌کردن فقط برای authenticated و با reporter_user_id برابر auth.uid و حساب فعال است. سیاست حذف review همان شرط مالکیت را دارد و شرط فعال‌بودن حساب را اضافه نمی‌کند؛ این دقیقاً با SQL بازیابی‌شده سازگار است.
- جدول fee دارای RLS است و دسترسی مستقیم عمومی/کاربری مشاهده نشد؛ نرخ‌ها از تابع کنترل‌شده خوانده می‌شوند.

#### مدیریت و امنیت
- private.admin_users و private.admin_wallet_adjustments هر دو RLS فعال دارند و هیچ policy کاربری برای دسترسی مستقیم به آن‌ها مشاهده نشد.
- private.admin_adjust_wallet با SECURITY DEFINER، مالک postgres و search_path خالی اجرا می‌شود؛ تابع هویت caller را با auth.uid می‌گیرد، super-admin را بررسی می‌کند، USDT رزروشده در سفارش‌های باز را از مبلغ قابل برداشت کم می‌کند، تغییر را در wallet و transactions ثبت می‌کند و audit جداگانه می‌نویسد.
- wrapper عمومی public.admin_adjust_wallet از نوع SECURITY INVOKER است؛ این نکته مهم است و نباید با نسخهٔ اولیهٔ SECURITY DEFINER اشتباه گرفته شود.
- توابع private.admin_list_users و private.is_current_user_super_admin نیز SECURITY DEFINER و search_path خالی دارند و ACL آن‌ها برای authenticated محدود شده است؛ wrapperهای public متناظر SECURITY INVOKER هستند.
- تابع گزارش و تابع درخواست sync مدیریتی در public از نوع SECURITY DEFINER هستند، اما در بدنه بررسی super-admin دارند. این‌ها endpointهای حساس‌اند و در هر تغییر آتی باید بررسی بدنه و ACL با هم انجام شود.
- Migration اولیهٔ secure_admin_wallet_management تابع عمومی با ارز USDT/IRR تعریف کرده بود؛ نسخهٔ بعدی آن را به private منتقل و واحد TOMAN را با تبدیل ×۱۰ به IRR ذخیره‌شده اضافه کرده است. وضعیت فعلی با نسخهٔ تکامل‌یافته سازگار است، نه با متن اولیه به‌تنهایی.

#### جدول مشاهدات و Worker
- exchange_asset_observations.id به‌صورت GENERATED ALWAYS AS IDENTITY است؛ unique(exchange,market_symbol)، FK به crypto_assets، checkهای exchange و match_status و indexهای upper(base_symbol) و (match_status,last_seen_at DESC) وجود دارند.
- RLS فعال است و مجوزهای جدول برای anon/authenticated مشاهده نشد؛ service_role دسترسی عملیاتی دارد.
- Trigger زندهٔ trg_auto_list_verified_exchange_asset روی INSERT و UPDATE ستون‌های match_status/coingecko_id/is_active نصب است و تابع private را اجرا می‌کند.
- جدول exchange_asset_sync_requests و تابع پردازش زنده از منبع اولیه تکامل یافته‌اند؛ تابع زنده از private.try_parse_jsonb استفاده می‌کند و برای پاسخ malformed آن را از پردازش کنار می‌گذارد.
- زمان‌بندی زندهٔ مشاهده‌شده:
  - job 13، digiarz-iran-exchange-request: */10 * * * *
  - job 14، digiarz-iran-exchange-process: 1,31 * * * *
  - job 18، digiarz-auto-activate-verified-exchange-pairs: 9-59/10 * * * *
- دو cadence نخست با */30 و */2 در Migration اولیه فرق دارند؛ cadence سوم نیز با * * * * * متن تاریخی فرق دارد. این اختلاف‌ها نشان‌دهندهٔ تکامل بعدی هستند، اما منشأ دقیق هر تغییر فقط با مقایسهٔ همهٔ Migrationهای بعدی و deployment history قابل اثبات است.
- مجوز اجرای چهار تابع اصلی Worker برای postgres و service_role است؛ برای authenticated و anon هیچ EXECUTE مشاهده نشد. Cronهای فعال دست‌نخورده باقی ماندند.

### مواردی که هنوز اثبات نشده‌اند
1. اینکه رکورد super-admin در زمان اجرای Migration دقیقاً از همان شرط count(profiles)=1 و همان UUID ثابت تاریخی عبور کرده باشد؛ بررسی فعلی فقط تعداد یک مدیر، فعال‌بودن حساب مرتبط و self-grant را بدون افشای شناسه تأیید می‌کند.
2. اینکه همهٔ ردیف‌های اولیهٔ backfill در admin_market_listings مشخصاً توسط Migration 20261115103227 ایجاد شده باشند؛ وضعیت فعلی تابع و Trigger قابل اثبات است، نه منشأ تک‌تک ردیف‌ها.
3. منشأ deploymentی تغییر scheduleها و همهٔ ACLهای تکمیلی service_role؛ برای انتساب قطعی باید deployment/audit history کامل‌تر بررسی شود.
4. تطبیق کامل رفتار همهٔ مسیرهای Worker در برابر تمام Migrationهای بعدی خارج از ۱۱ فایل این ممیزی هنوز باز است.

### قفل ایمنی
- این ممیزی فقط catalog/metadata و SELECT بوده است؛ هیچ ردیف کاربر، شناسهٔ شخصی، wallet balance، transaction، order یا reservation تغییر نکرد.
- هیچ تابع، Trigger، policy، grant، Cron، Edge Function یا Migration اجرا یا اصلاح نشد.
- این ۱۱ فایل همچنان در supabase/drafts/ و صرفاً مرجع تاریخی هستند؛ هیچ‌کدام به supabase/migrations/ منتقل یا replay نمی‌شوند.
- هیچ merge، update-branch، تغییر Production یا هزینه‌ای انجام نشد.


## تکمیل تطبیق چهار Migration باقیمانده و راستی‌آزمایی نسخه‌های تکامل‌یافته — ۲۵ نوامبر ۲۰۲۶

این تکمیل، سه Migration بازیابی‌شدهٔ باقیمانده و نسخه‌های بعدی مربوط به role probe، واحد تومان و Worker بیت۲۴ را با Production مقایسه می‌کند؛ همچنین snapshot و دو Migration نهایی backpressure/throttle را دوباره به شواهد catalog متصل می‌کند.

| نسخه | Migration | دستهٔ اثر فعلی | نتیجه |
|---|---|---|---|
| 20261113154750 | add_admin_role_probe | ۲ — superseded | تابع عمومی role probe وجود دارد، اما نسخهٔ زنده SECURITY INVOKER و wrapper تابع private است؛ نه SECURITY DEFINER تعریف‌شده در این Migration. این تغییر با انتقال بعدی منطق به private سازگار است. |
| 20261113154844 | use_toman_units_in_admin_credit_ui | ۲ — اثر موجود و تکامل‌یافته | constraint ارز audit اکنون USDT/TOMAN است و منطق TOMAN با ضریب ۱۰ به IRR ذخیره‌شده تبدیل می‌کند؛ ولی تابع حساس در private و SECURITY DEFINER قرار دارد و تابع public فقط wrapper SECURITY INVOKER است. |
| 20261115103507 | schedule_bit24_exchange_asset_sync | ۲ — اثر موجود با backpressure و cadence اصلاح‌شده | جدول درخواست‌ها، RLS، دو تابع Worker و دو Cron فعال موجودند؛ تابع درخواست اکنون درخواست‌های معلق را حفظ می‌کند و از enqueue تکراری جلوگیری می‌کند. |
| 20261121045434 | digiarz_backpressure_and_exchange_sync_bloat_guards | ۱ — قطعات تابعی بررسی‌شده منطبق | index و ۱۴ قطعهٔ جایگزینی بررسی‌شده با تعریف زنده تطبیق داده شده‌اند؛ این صرفاً تطبیق قطعات تعریف تابع است، نه اثبات سلامت کامل رفتار runtime. |
| 20261121045531 | snapshot_pg_net_unlogged_queue_before_recovery | ۱ — اثر ساختاری منطبق | هر دو جدول snapshot در private وجود دارند و permanent ordinary table هستند؛ snapshotها TTL خودکار pg_net ندارند. |
| 20261121050216 | temporarily_throttle_exchange_asset_processors | ۱ — scheduleهای هدف منطبق | job 14 برابر 1,31 * * * * و job 16 برابر 16,46 * * * * فعال‌اند؛ job 8 موتور سفارش در این Migration تغییر نکرده و فعال باقی مانده است. |

### جزئیات تکمیلی

#### role probe و انتقال privilege
- Migration مربوط به role probe در زمان خود تابع public.is_current_user_super_admin() را SECURITY DEFINER با search_path خالی ایجاد می‌کرد و EXECUTE را برای authenticated مجاز می‌ساخت.
- نسخهٔ زندهٔ public همین نام، SECURITY INVOKER است و صرفاً private.is_current_user_super_admin() را فراخوانی می‌کند. تابع private مقصد SECURITY DEFINER، search_path خالی و ACL کنترل‌شده دارد.
- بنابراین Migration role probe نباید به‌صورت مستقل replay شود؛ نسخهٔ فعلی از تغییرات بعدی private-schema تبعیت می‌کند.

#### واحد تومان و تعدیل کیف پول
- Migration واحد تومان constraint را به USDT/TOMAN تغییر داده و مقدار TOMAN را هنگام ثبت transaction به IRR ×۱۰ تبدیل می‌کند. این منطق در private.admin_adjust_wallet زنده است.
- نسخهٔ public.admin_adjust_wallet در Production SECURITY INVOKER است و به تابع private واگذار می‌کند؛ تابع private SECURITY DEFINER است، auth.uid و super-admin را بررسی می‌کند، مبلغ USDT رزروشده در order_reservations را از برداشت قابل‌دسترس کم می‌کند، سپس wallet، transactions و audit را در یک منطق واحد به‌روزرسانی می‌کند.
- ACL تابع private شامل postgres و authenticated است؛ wrapper public شامل postgres، authenticated و service_role است. این تفاوت ACL باید در ممیزی جامع endpointها لحاظ شود؛ از صرف وجود SECURITY INVOKER نمی‌توان دسترسی غیرمجاز به عملیات privileged را نتیجه گرفت، چون تابع private کنترل super-admin دارد.
- هیچ تعدیل آزمایشی برای اثبات runtime انجام نشد؛ اجرای آزمایشی تابع می‌توانست موجودی یا ledger را تغییر دهد و خارج از محدودهٔ read-only بود.

#### Worker بیت۲۴
- جدول public.bit24_exchange_sync_requests موجود، RLS فعال و permanent است.
- request_bit24_exchange_sync() و process_bit24_exchange_sync() هر دو SECURITY DEFINER، search_path خالی و ACL محدود به postgres و service_role دارند؛ authenticated و anon EXECUTE ندارند.
- تابع درخواست زنده پاک‌سازی صف معلق را فقط وقتی انجام می‌دهد که request id نه در pg_net queue و نه در response باشد؛ اگر درخواست پردازش‌نشده باقی مانده باشد، درخواست تازه enqueue نمی‌کند.
- تابع پردازش زنده از no-op update guards برای observationها استفاده می‌کند تا ردیف‌های بدون تغییر بی‌دلیل بازنویسی نشوند.
- Cronهای زنده و فعال: job 15 با */30 * * * * و job 16 با 16,46 * * * *. schedule دوم با */2 در Migration اولیه متفاوت است و با Migration throttle بازیابی‌شده تطابق دارد.

#### Snapshot و backpressure
- دو snapshot table زنده private.digiarz_pg_net_queue_backup_20261121 و private.digiarz_pg_net_response_backup_20261121 با relkind='r' و relpersistence='p' مشاهده شدند؛ یعنی permanent ordinary tables هستند، نه TEMP یا UNLOGGED.
- snapshotهای ساخته‌شده با CTAS حاوی دادهٔ کپی‌شده در زمان capture هستند و cleanup خودکار TTL شش‌ساعتهٔ pg_net شامل آن‌ها نمی‌شود.
- Migration backpressure ایندکس crypto_assets_upper_symbol_active_idx را با تعریف مورد انتظار دارد و ۱۴ قطعهٔ جایگزینی استخراج‌شده از آن با تعریف زندهٔ توابع متناظر تطبیق داده شده‌اند.
- این مقایسه صحت تطبیق متن قطعات را نشان می‌دهد؛ آزمون عملی enqueue، پاسخ HTTP، retry، queue drain یا عملکرد runtime انجام نشده است.

### اصلاح و شفاف‌سازی طبقه‌بندی کلی
- در بخش قبلی، Migrationهای اولیهٔ fee/wallet، جدول observation و محدودسازی اجرای Worker به‌عنوان اثرهای اصلی منطبق ثبت شده بودند. این طبقه‌بندی دربارهٔ اثرهای مورد انتظار آن نسخه‌هاست؛ نسخه‌های بعدی، به‌ویژه role probe و تومان، در این بخش به‌صراحت superseded/evolved ثبت شده‌اند.
- scheduleهای زندهٔ Bit24 و پردازش ایران با Migrationهای اولیه متفاوت‌اند، اما با Migrationهای throttling بازیابی‌شده سازگارند.
- شمارش ۱۷ فایل بازیابی‌شده کامل است؛ با این حال برای چند نسخهٔ تاریخی که بعداً superseded شده‌اند، انتساب هر تغییر به یک Migration خاص بدون اجرای timeline کامل همهٔ ledger statements ممکن نیست.

### قفل ایمنی تکمیلی
- فقط catalog و تعاریف تابع و scheduleها خوانده شدند. هیچ تابعی فراخوانی نشد؛ هیچ درخواست HTTP، تغییر صف، تغییر موجودی، ledger write، grant، policy، Cron یا Migration اجرا نشد.
- job 8 موتور سفارش و همهٔ Cronهای دیگر دست‌نخورده‌اند.
- هیچ snapshot یا backup حذف یا restore نشد.
- همهٔ فایل‌های recovered همچنان در supabase/drafts/ هستند و هیچ فایل اجرایی به supabase/migrations/ اضافه نشده است.


## ممیزی جامع توابع SECURITY DEFINER عمومی، ACL و default privileges — ۲۵ نوامبر ۲۰۲۶

این بررسی فقط metadata و متن توابع را خوانده است؛ هیچ تابعی فراخوانی نشده است.

### نتیجهٔ شمارشی
- تعداد توابع SECURITY DEFINER در schema عمومی: ۳۷.
- تابعی با EXECUTE مستقیم برای role PUBLIC مشاهده نشد.
- هیچ‌یک از این ۳۷ تابع search_path باز و نامحدود ندارند: ۳۵ تابع با search_path خالی و دو تابع refresh_market_prices() و refresh_market_fx_rate() با search_path=pg_catalog تنظیم شده‌اند.
- ۲۳ تابع برای authenticated قابل اجرا هستند؛ این موضوع به‌تنهایی آسیب‌پذیری نیست و باید همراه با guard داخل بدنه ارزیابی شود.
- دو تابع برای anon قابل اجرا هستند؛ هر دو در ادامه از نظر ماهیت داده بررسی شده‌اند.

### توابع SECURITY DEFINER قابل دسترسی برای anon
1. get_admin_market_listings() داده‌های فهرست عمومی بازار را می‌خواند: شناسهٔ CoinGecko، نماد، نام، تصویر، رتبه، قیمت، درصد تغییر، حجم و زمان به‌روزرسانی. تعریف فعلی از admin_market_listings به‌عنوان فهرست curated بازار استفاده می‌کند؛ هیچ دادهٔ wallet، هویت مدیر یا ledger در خروجی آن دیده نشد.
2. get_exchange_discovered_market_assets() دادهٔ مشاهدات عمومی بازار را برای نمادهای تازه کشف‌شده برمی‌گرداند: نام، منابع صرافی، تعداد منابع، زمان مشاهده و وضعیت تطبیق. بدنه، مشاهده‌های فعال و تازه را فیلتر می‌کند و نمادهایی را که در فهرست curated یا جفت معاملاتی فعال هستند کنار می‌گذارد. این endpoint دادهٔ عملیاتی sync را تا حدی به anon آشکار می‌کند؛ در بررسی فعلی هیچ URL خصوصی، توکن، request id، payload خام یا شناسهٔ کاربر در projection خروجی مشاهده نشد.
- این دو مورد را «دسترسی عمومی عمدی به دادهٔ بازار» طبقه‌بندی می‌کنیم، نه اثبات آسیب‌پذیری. با این حال نام get_admin_market_listings گمراه‌کننده است و بهتر است در بازبینی API مشخص شود این endpoint عمداً public است.

### بررسی توابع مدیریتی
- توابع admin_add_market_listing, admin_remove_market_listing, admin_enable_market_pair, admin_disable_market_pair, admin_search_market_assets در بدنه هم auth.uid() را بررسی می‌کنند و هم private.is_super_admin() را فراخوانی می‌کنند.
- admin_exchange_asset_sync_report() و admin_request_exchange_asset_sync() از private.is_current_user_super_admin() استفاده می‌کنند. نبودن فراخوانی مستقیم auth.uid() در این دو تابع به‌تنهایی نقص نیست، چون guard خصوصی هویت جاری را ارزیابی می‌کند.
- تابع عمومی admin_adjust_wallet() wrapper از نوع SECURITY INVOKER است؛ منطق تغییر موجودی در تابع private و SECURITY DEFINER انجام می‌شود و آن تابع کنترل super-admin را اعمال می‌کند.
- claim_admin_asset_refresh() فقط به service_role مجوز دارد و user-supplied p_admin_user_id را با جدول private.admin_users تطبیق می‌دهد؛ authenticated و anon مجوز اجرای مستقیم ندارند.
- توابع معاملاتی/سفارشی که برای authenticated مجازند، از auth.uid() و مالکیت order/user یا اعتبارسنجی حساب فعال استفاده می‌کنند؛ این توابع در این گزارش به‌عنوان عملیات کاربر طبقه‌بندی شده‌اند، نه عملیات مدیریتی.

### مورد مهم: default privileges برای توابع آینده
- default ACL توابع در schema عمومی برای سازنده با نقش postgres، EXECUTE را به anon, authenticated و service_role اعطا می‌کند.
- default ACL توابع عمومی برای سازنده با نقش supabase_admin نیز همین دسترسی‌ها را دارد.
- این مورد به معنای وجود EXECUTE برای PUBLIC روی ۳۷ تابع فعلی نیست؛ بررسی ACL مؤثر توابع موجود، صفر تابع با PUBLIC EXECUTE نشان داد.
- با این حال، هر تابع جدیدی که با این ownerها ساخته شود ممکن است به‌صورت پیش‌فرض برای anon/authenticated قابل اجرا شود، مگر آنکه Migration سازنده در همان تراکنش ACL را محدود کند یا default privileges اصلاح شده باشد. این یک ریسک حاکمیتی/پیکربندی برای توسعه‌های آینده است و باید پیش از افزودن توابع privileged جدید حل و در CI کنترل شود.
- default privileges فعلی تغییر داده نشد؛ اصلاح آن نیازمند Migration مجزا، بررسی اثر روی توابعی که باید public باشند و تأیید مالک است.

### دو تابع با search_path غیرخالی
- refresh_market_prices() و refresh_market_fx_rate() دارای SET search_path=pg_catalog هستند، نه search_path پیش‌فرض کاربر. این تنظیم به‌صورت صریح به pg_catalog محدود شده و از shadowing اشیای schemaهای دیگر جلوگیری می‌کند. در تعریف‌های بررسی‌شده، اشیای برنامه با نام schema-qualified فراخوانی می‌شوند.
- بنابراین این دو مورد در این مرحله به‌عنوان نقص search_path طبقه‌بندی نشدند؛ با این حال در بازبینی تغییرات آینده باید همین تنظیم محدود حفظ شود.

### ارزیابی ریسک و اقدام پیشنهادی (بدون اجرا)
1. اولویت بالا — default privileges: طراحی یک Migration صرفاً پیشنهادی برای محدودکردن EXECUTE پیش‌فرض توابع تازه در schema عمومی برای anon/authenticated؛ سپس فهرست allowlist توابع عمومی و کنترل خودکار در CI. هیچ تغییر ACL اکنون انجام نشده است.
2. اولویت متوسط — allowlist endpointهای anon: مستندسازی دو تابع بازار فوق به‌عنوان API عمومی و افزودن تستی که ثابت کند خروجی آن‌ها شامل دادهٔ حساس یا payload خام sync نمی‌شود.
3. اولویت متوسط — کنترل CI: تست catalog برای هر SECURITY DEFINER جدید: search_path محدود، نبود PUBLIC EXECUTE، ACL صریح و guard هویتی/مالکیت متناسب با نوع endpoint.
4. تکمیل لازم: بازبینی تمام ۳۷ بدنه در برابر dynamic SQL، EXECUTE, استفاده از نام‌های بدون schema، فراخوانی توابع زنجیره‌ای و مرز اعتماد به service_role. شمارش و اسکن این مرحله جایگزین بازبینی دستی تک‌تک شاخه‌های اجرایی نیست.

### قفل ایمنی
- هیچ ALTER DEFAULT PRIVILEGES, REVOKE, GRANT, CREATE OR REPLACE FUNCTION, Migration یا اجرای تابع انجام نشد.
- هیچ تغییر Production، Cron، worker، داده یا هزینه‌ای انجام نشد.
- این بخش صرفاً به فایل Markdown گزارش در branch آزمایشی افزوده شد.


## تکمیل ممیزی SECURITY DEFINER، هشدارهای Supabase Advisors و دسترسی جدول‌ها — ۲۵ نوامبر ۲۰۲۶

### بررسی dynamic SQL و مسیرهای اجرای پویا
- متن هر ۳۷ تابع SECURITY DEFINER عمومی خوانده و برای دستورهای dynamic EXECUTE و format() بررسی شد.
- هیچ دستور dynamic SQL واقعی در این ۳۷ تابع پیدا نشد. تنها تطبیق واژه execute در admin_disable_market_pair مربوط به توضیح کامنت دربارهٔ اجرای trigger بود، نه دستور PL/pgSQL.
- این نتیجه فقط دربارهٔ متن تعریف فعلی این ۳۷ تابع است؛ تغییرات بعدی باید در CI دوباره کنترل شوند.

### توابع بدون auth.uid یا guard مدیریتی که برای نقش‌های API قابل اجرا هستند
سه مورد در بررسی متنی باقی ماندند:
1. get_admin_market_listings(): برای anon و authenticated مجاز است؛ خروجی فقط اطلاعات بازار و فهرست curated است. این endpoint عمومی/خواندنی به نظر می‌رسد، اما نام admin در ابتدای آن ممکن است مصرف‌کننده را دربارهٔ سطح دسترسی گمراه کند.
2. get_exchange_discovered_market_assets(): برای anon و authenticated مجاز است؛ خروجی فقط نمای تجمیعی مشاهدات بازار تازه است. هیچ payload خام، شناسهٔ درخواست یا دادهٔ کاربر در projection فعلی دیده نشد.
3. get_demo_trading_fee_rate(p_quote_asset,p_liquidity_type): برای authenticated مجاز است و نرخ کارمزد پیکربندی‌شده را می‌خواند؛ تابع هیچ تغییر داده‌ای انجام نمی‌دهد و ورودی liquidity type را به maker/taker محدود می‌کند. anon مجوز آن را ندارد.
این سه مورد در این مرحله به‌عنوان endpointهای خواندنی/دادهٔ عمومی یا تنظیمات قابل نمایش طبقه‌بندی شدند، نه اثبات نقص مجوز. برای دو endpoint نخست باید تصمیم public بودن و نام‌گذاری آن‌ها در allowlist مستند شود.

### توابع private و trigger
- توابع private.admin_adjust_wallet و private.admin_list_users دارای auth.uid() و super-admin guard هستند؛ EXECUTE فقط postgres و authenticated است و PUBLIC/anon/service_role در ACL مؤثرشان دیده نشد.
- private.is_super_admin و private.is_current_user_super_admin در schema خصوصی قرار دارند و مسیر اجرای آن‌ها محدود است.
- توابع private مربوط به trigger و scheduler از جمله auto_list_verified_exchange_asset، enforce_unique_admin_market_listing_symbol، guard_active_account_writes و auto_activate_verified_exchange_pairs فقط postgres را در ACL مؤثر دارند؛ نبود auth.uid در توابع trigger/scheduler به‌خودی‌خود نقص نیست، چون از مسیرهای داخلی دیتابیس فراخوانی می‌شوند.
- توابع عمومی worker که عملیات sync/پردازش انجام می‌دهند، در ACL بررسی‌شده برای anon/authenticated قابل اجرا نیستند و دسترسی اجرایی آن‌ها به service_role/postgres محدود است.

### Supabase Security Advisors — snapshot خواندنی
Advisor امنیتی Production در 2026-11-25 این موارد را گزارش کرد:
- ۲ هشدار anon SECURITY DEFINER: get_admin_market_listings و get_exchange_discovered_market_assets. این دو endpoint عمداً خروجی بازار را منتشر می‌کنند؛ هشدار واقعی ابزار است، اما public بودن باید در allowlist و تست خروجی تثبیت شود.
- ۲۳ هشدار authenticated SECURITY DEFINER. این عدد شامل RPCهای موردنیاز کاربران، endpointهای مدیریتی دارای super-admin guard و توابع read-only است؛ بنابراین شمارش هشدار به‌تنهایی معادل ۲۳ آسیب‌پذیری نیست.
- ۱۵ مورد RLS enabled without policy. بررسی مستقیم مجوز جدول‌ها نشان داد anon و authenticated روی هیچ‌یک از این ۱۵ جدول SELECT/INSERT/UPDATE مستقیم ندارند. برای ۱۰ جدول private نیز هیچ‌یک از این دو نقش مجوز مستقیم نداشتند. پنج جدول public هم RLS فعال و بدون policy دارند و مجوز مستقیم anon/authenticated برای آن‌ها مشاهده نشد؛ service_role مجوز SELECT دارد. دسترسی از طریق SECURITY DEFINERهای محدود، جداگانه بررسی شده است.
- یک هشدار Auth: محافظت در برابر گذرواژه‌های افشاشده غیرفعال است. این یک تنظیم امنیتی حساس است و بدون تأیید صریح مالک تغییر داده نمی‌شود.
لینک‌های راهنمای Advisor:
  - https://supabase.com/docs/guides/database/database-linter?lint=0028_anon_security_definer_function_executable
  - https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable
  - https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy
  - https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection

### پیشنهاد default ACL به‌صورت فایل غیرقابل‌اجرا
- فایل supabase/drafts/2026-11-25_proposed_restrict_default_public_function_exec.sql اضافه شد.
- این فایل کاملاً comment-only است و هیچ دستور فعال SQL ندارد.
- پیشنهاد آن فقط برای توابع جدید schema عمومی است: حذف EXECUTE پیش‌فرض anon و authenticated برای سازندگان postgres و supabase_admin، حفظ service_role و سپس اعطای EXECUTE صریح به allowlist.
- ALTER DEFAULT PRIVILEGES توابع موجود را تغییر نمی‌دهد؛ بنابراین مجوزهای RPC فعلی نیازمند بررسی و allowlist مستقل هستند.
- قبل از هر اجرای احتمالی باید توانایی نقش اجراکننده برای تغییر default privileges متعلق به supabase_admin، اثر روی توابع لازم اپلیکیشن و تست در پروژهٔ آزمایشی بررسی شود.

### وضعیت ایمنی
- هیچ تنظیم Auth، ACL، default privilege، جدول، policy، تابع، trigger یا Cron در Production تغییر نکرد.
- هیچ Migration اجرایی ساخته یا اعمال نشده؛ فایل پیشنهادی فقط در drafts و کامنتی است.


## ممیزی مسیر RPC از Frontend تا توابع Production — ۲۵ نوامبر ۲۰۲۶

این بخش با بررسی فقط‌خواندنی کد رابط کاربری در شاخه `redesign/ui-clean-rebuild-2026` و کاتالوگ توابع Production تهیه شده است. هیچ RPC یا Edge Function اجرا نشد.

### مسیرهای احرازشده در Frontend
- `index.html` در ابتدای نشست، پس از دریافت پروفایل، `is_current_user_super_admin()` را فراخوانی می‌کند؛ تب مدیریت فقط وقتی نمایش داده می‌شود که پاسخ دقیقاً `true` باشد. این کنترل صرفاً UX است و جای کنترل سمت سرور را نمی‌گیرد.
- عملیات مدیریتی بازار از RPCهای `admin_search_market_assets`, `admin_review_market_listings`, `admin_add_market_listing`, `admin_remove_market_listing`, `admin_enable_market_pair`, `admin_disable_market_pair` عبور می‌کند. بدنهٔ توابع حساس بررسی‌شده `auth.uid()` و `private.is_super_admin()` را کنترل می‌کند.
- پنل همگام‌سازی مدیریتی از `admin_exchange_asset_sync_report()` و `admin_request_exchange_asset_sync()` استفاده می‌کند. هر دو تابع در Production کنترل `private.is_current_user_super_admin()` دارند؛ تابع درخواست سپس Workerهای محدودشده را فراخوانی می‌کند.
- پنل کاربران از wrapperهای عمومی `admin_list_users()` و `admin_adjust_wallet(...)` استفاده می‌کند. این wrapperها SECURITY INVOKER هستند و به helperهای خصوصی SECURITY DEFINER می‌رسند؛ helperها وجود `auth.uid()` و نقش super_admin را بررسی می‌کنند.
- معاملات و سفارش‌های کاربر از RPCهای `execute_demo_trade`, `place_limit_order`, `place_stop_limit_order`, `place_conditional_exit_order` و توابع لغو استفاده می‌کنند. همهٔ امضاهای بررسی‌شده فقط برای authenticated قابل اجرا هستند و بدنه‌ها هویت کاربر را از `auth.uid()` می‌گیرند.
- `request_market_price_refresh()` برای authenticated قابل اجراست؛ بدنه نشست معتبر، حساب فعال و فاصلهٔ حداقل ۳۰ ثانیه بین درخواست‌ها را بررسی می‌کند. این RPC یک درخواست به‌روزرسانی ثبت می‌کند و endpoint عمومی/ناشناس نیست.

### ماتریس ACL و کنترل سمت سرور
- توابع حساس فهرست‌شده در Frontend برای anon قابل اجرا نیستند؛ استثنا فقط دو RPC دادهٔ عمومی بازار است: `get_admin_market_listings()` و `get_exchange_discovered_market_assets()`. هر دو فقط metadata بازار را برمی‌گردانند و در migrationهای موجود، PUBLIC صریحاً revoke و anon/authenticated به‌صورت مشخص مجاز شده‌اند.
- توابع Worker شامل `request_iran_exchange_asset_sync()` و `request_bit24_exchange_sync()` برای service_role قابل اجرا هستند و برای anon/authenticated مجوز ندارند.
- توابع خصوصی `private.admin_list_users()` و `private.admin_adjust_wallet(...)` برای authenticated قابل اجرا هستند، اما guard داخلی super-admin دارند؛ schema خصوصی به‌عنوان مسیر مستقیم Frontend استفاده نشده است. wrapperهای public نقش واسط SECURITY INVOKER را دارند.
- در نمونهٔ توابع مدیریتی بررسی‌شده، `search_path` خالی است. بدنهٔ `admin_disable_market_pair` به‌صورت دستی مرور شد؛ عبارت جست‌وجوی اولیه برای dynamic SQL به‌دلیل وجود واژهٔ «execute» در توضیحات/متن، false positive بود و دستور اجرای SQL پویا در بدنهٔ تابع مشاهده نشد.
- فهرست Edge Functionهای Production شامل `sync-iran-exchange-assets` نسخهٔ ۷ با `verify_jwt=true` است. نسخهٔ مستقر همان نسخهٔ قدیمی است و استخراج‌کنندهٔ جدید نام فارسی در آن فعال نیست. سورس شاخهٔ PR به‌تنهایی به معنی deploy شدن نیست.
- در سورس Frontend بررسی‌شده هیچ فراخوانی مستقیم به schema خصوصی یا استفاده از `service_role` مشاهده نشد. هیچ کلید محرمانه‌ای از طریق این بررسی به کاربر یا گزارش منتقل نشده است.

### ارزیابی و محدودیت شواهد
- در مسیرهای RPC مدیریتی مشاهده‌شده، کنترل UI با guard سمت سرور همراه است؛ اتکا به مخفی‌کردن تب مدیریت به‌تنهایی کافی نیست، اما guardهای دیتابیس لایهٔ اصلی کنترل‌اند.
- service_role یک نقش مورداعتماد backend است و در کد مرورگر نباید استفاده شود. این بررسی، نبود رشتهٔ service_role در فایل اصلی Frontend را نشان می‌دهد، نه ممیزی جامع تمام artifactهای build و متغیرهای deploy.
- این مرحله static/catalog audit است؛ هیچ آزمون منفی با JWT کاربر عادی یا anon اجرا نشده، هیچ endpointای فراخوانی نشده و هیچ تغییر مجوزی انجام نشده است.
- نتیجه: در مسیرهای مشخص‌شده، موردی از RPC مدیریتی بدون guard سمت سرور پیدا نشد. گام بعدی مناسب، افزودن تست‌های CI مبتنی بر کاتالوگ و تست‌های منفی در پروژهٔ آزمایشی ایزوله است؛ Production همچنان read-only باقی می‌ماند.


## طراحی CI و آزمون منفی RPC — ۲۵ نوامبر ۲۰۲۶

### قرارداد کاتالوگ Production
ممیزی تازهٔ کاتالوگ Production تعداد ۴۶ تابع SECURITY DEFINER را در schemaهای public/private نشان داد:
- ۴۴ تابع با search_path خالی و ۲ تابع فقط با `search_path=pg_catalog` تنظیم شده‌اند؛ هر دو الگو در این قرارداد مجازند.
- هیچ‌یک از ۴۶ تابع EXECUTE برای نقش PUBLIC ندارند.
- فقط دو تابع دادهٔ بازار برای anon قابل اجرا هستند: `public.get_admin_market_listings()` و `public.get_exchange_discovered_market_assets()`.
- ۲۶ تابع SECURITY DEFINER برای authenticated قابل اجرا هستند؛ allowlist دقیق نام آن‌ها در `tests/rpc-security-catalog.sql` ثبت شده است.
- نقش service_role جداگانه بررسی می‌شود و نباید با PUBLIC یا anon اشتباه گرفته شود.

### فایل‌های تست جدید
- `tests/rpc-security-catalog.sql`: قرارداد read-only برای inventory توابع SECURITY DEFINER، search_path امن، نبود EXECUTE برای PUBLIC و allowlist نقش‌های anon/authenticated. هر تابع جدید یا تغییر مجوز خارج از allowlist، تست را fail می‌کند تا بازبینی صریح انجام شود.
- `tests/rpc-security.integration.sql`: آزمون نقش‌محور روی RPC گزارش مدیریتی فقط‌خواندنی. GRANTهای حداقلی در همان تراکنش موقت‌اند و در انتها ROLLBACK می‌شوند. هیچ کیف پول، سفارش، صف، Cron، Migration یا دادهٔ دائمی تغییر نمی‌کند.
- `.github/workflows/persian-asset-name-tests.yml`: job یکپارچه‌سازی RPC به‌صورت gated اضافه شد. فقط وقتی متغیر مخزن `DIGIARZ_ENABLE_RPC_SECURITY_TESTS=true` فعال شود اجرا می‌شود؛ اتصال باید با secret `DIGIARZ_TEST_DB_URL` و شناسهٔ پروژهٔ تست `zrriqwyolcjhbappocuw` منطبق باشد. ابتدا catalog contract و سپس role tests اجرا می‌شوند.

### اجرای واقعی آزمون روی پروژهٔ تست فعلی
فایل `tests/rpc-security.integration.sql` در پروژهٔ تست اجرا شد:
- anon: فراخوانی RPC با SQLSTATE 42501 رد شد.
- authenticated عادی با شناسهٔ آزمایشی: با SQLSTATE 42501 رد شد.
- super-admin ثبت‌شده در `private.admin_users`: همان RPC گزارش فقط‌خواندنی را با خروجی JSON object اجرا کرد.
- پس از ROLLBACK، مجوز موقت USAGE روی schema public باقی نماند.

محدودیت مهم محیط تست: `auth.users` خالی است، یک رکورد super-admin در `private.admin_users` وجود دارد، و نقش‌های anon/authenticated در baseline مجوز USAGE روی schemaهای public/private ندارند. همچنین ACLهای EXECUTE توابع SECURITY DEFINER در این پروژه با Production یکسان نیستند. آزمون نقش‌ها بنابراین با claim آزمایشی و دسترسی موقت تراکنشی، guard داخل تابع را سنجید؛ آزمون end-to-end با حساب واقعی Auth انجام نشده است. به همین دلیل job یکپارچه‌سازی CI تا همسان‌سازی ACL/schema در محیط تست، به‌صورت gated باقی می‌ماند و catalog contract فعلاً روی این پروژه نباید به‌عنوان تست سبز گزارش شود.

### وضعیت Mergeable
در بررسی فعلی PR #62، `mergeable=true` است. مقایسهٔ branchها نشان می‌دهد head تعداد ۸۳ commit جلوتر و صفر commit عقب‌تر از base است و merge-base دقیقاً برابر base است. بنابراین در snapshot فعلی واگرایی یا conflict ثبت نشده است. مقدار `false` در بررسی قبلی احتمالاً وضعیت محاسبهٔ موقت GitHub بوده؛ علت تاریخی قطعی از API فعلی قابل اثبات نیست.

### محدودیت انتشار
تمام بررسی‌های Production فقط SELECT روی catalog بوده‌اند. هیچ تابع Production اجرا نشده است. هیچ Merge، migration، db push، grant پایدار، Auth change، Cron/Worker change، یا هزینه‌ای انجام نشده است.


### نتیجهٔ اجرای قرارداد کاتالوگ روی محیط تست
فایل `tests/rpc-security-catalog.sql` عمداً روی پروژهٔ تست فعلی اجرا شد تا اختلاف محیط آشکار شود؛ تست با خطای کنترل‌شده fail شد:
- محیط تست برای تعداد زیادی از توابع SECURITY DEFINER مجوز EXECUTE به PUBLIC دارد؛ این دقیقاً با baseline Production که صفر تابع دارای PUBLIC EXECUTE دارد، مغایر است.
- با وجود EXECUTE، نقش‌های anon/authenticated در baseline تست USAGE روی schema عمومی ندارند؛ بنابراین ACL و schema privileges این پروژه با Production هم‌تراز نیستند.
- این شکست به‌عنوان کشف drift محیط تست ثبت می‌شود، نه شکست امنیتی Production.
- هیچ اصلاح ACL یا schema در محیط تست انجام نشد. اجرای قرارداد فقط catalog read بود و تغییری ایجاد نکرد.
- نتیجهٔ اجرایی: job یکپارچه‌سازی CI باید تا آماده‌شدن یک clone آزمایشی با ACL و schema grants همسان Production خاموش بماند؛ روشن‌کردن آن روی پروژهٔ فعلی به شکست قابل‌انتظار منجر می‌شود.


## به‌روزرسانی ممیزی PR #62 و هم‌ترازی جدول مشاهدات — ۲۵ نوامبر ۲۰۲۶

این الحاقیه بر اساس آخرین snapshot GitHub و پرس‌وجوهای صرفاً خواندنی از Production و پروژهٔ تست تهیه شد.

### وضعیت GitHub و CI در آخرین Commit
- آخرین head بررسی‌شده: `15df27f659a9f3a5586f38712a01ca34b4e667e4`.
- PR #62 همچنان Open و Draft و ادغام‌نشده است؛ تعداد فایل‌های تغییرکرده ۲۹.
- compare زنده: شاخهٔ head تعداد ۸۹ commit جلوتر و صفر commit عقب‌تر از base است؛ merge-base برابر base است.
- مقدار mergeable در هر دو پاسخ تازهٔ GitHub برابر true بود. این فقط snapshot فعلی است و علت اختلاف mergeable در snapshotهای قدیمی‌تر را به‌صورت تاریخی اثبات نمی‌کند.
- گزارش قبلی در همین سند عدد ۸۳ commit جلوتر را ثبت کرده بود؛ آن عدد برای snapshot فعلی منسوخ است و مقدار تازه ۸۹ است.
- اجرای CI شمارهٔ ۱۵۶ روی همین head با نتیجهٔ کلی success تمام شد. job مربوط به unit-tests موفق بود: تست‌های Node و type-check تابع Edge Function هر دو موفق شدند.
- job با نام rpc-security-integration در همین اجرا skipped بود؛ بنابراین CI هنوز تست RPC را روی دیتابیس اجرا نکرده و نباید موفقیت اجرای تست امنیتی RPC گزارش شود. فعال‌سازی آن همچنان منوط به همسان‌سازی محیط تست و تنظیم امن متغیر/secret است.

### مقایسهٔ زندهٔ public.exchange_asset_observations
- هر دو محیط دقیقاً ۱۳ ستون با نوع، nullability و default یکسان، و ۵ constraint متناظر دارند.
- RLS در هر دو فعال و FORCE RLS خاموش است؛ هیچ policy مستقیمی روی این جدول در هیچ‌یک از دو محیط ثبت نشده است.
- در هر دو محیط anon و authenticated هیچ مجوز مستقیم SELECT/INSERT/UPDATE/DELETE روی جدول ندارند.
- Production مالک جدول را postgres دارد و service_role مجوزهای کامل جدول را دارد. در پروژهٔ تست، service_role مجوز مستقیم جدول ندارد؛ پس این جدول از نظر مجوز backend نیز clone همسان Production نیست.
- Trigger با نام `trg_auto_list_verified_exchange_asset` در هر دو محیط موجود و فعال است؛ تعریف trigger در دو محیط یکسان است و پس از INSERT یا UPDATE ستون‌های match_status، coingecko_id یا is_active اجرا می‌شود.
- تعداد و ساختار کلی indexها در هر دو محیط چهار مورد است، اما یک index متفاوت است:
  - Production: `exchange_asset_observations_match_idx (match_status, last_seen_at DESC)`.
  - Test: `exchange_asset_observations_match_status_active_idx` به‌صورت partial روی وضعیت‌های pending/ambiguous/unmatched و is_active=true.
  - بنابراین test از نظر index plan و عملکرد query، همسان Production نیست.
- در Production، sequence هویتی `public.exchange_asset_observations_id_seq` به anon و authenticated نیز مجوزهای SELECT، UPDATE و USAGE دارد؛ در پروژهٔ تست sequence فقط برای postgres مجاز است. این مجوزها به معنای دسترسی مستقیم به جدول نیستند، اما برای اصل حداقل‌سازی دسترسی یک مورد بازبینی جداگانه‌اند.
- Default ACL مربوط به sequenceهای schema public در Production برای نقش‌های postgres و supabase_admin به anon، authenticated و service_role مجوزهای sequence می‌دهد؛ در پروژهٔ تست رکورد default ACL متناظر برای public وجود ندارد. این اختلاف با تفاوت ACL توابع جدید هم‌راستا است و صرفاً با GRANT روی جدول حل نمی‌شود.

### ارزیابی و اقدام بعدی
- پروژهٔ تست موجود برای آزمون برابری مجوزها، رفتار sequence و planهای وابسته به index، جایگزین قابل‌اعتماد Production نیست.
- فایل تاریخی `recovered_20261115101709_create_exchange_asset_observations.sql` منبع بازیابی‌شدهٔ Migration است و همچنان فقط مرجع بازبینی در drafts باقی می‌ماند؛ اجرا یا replay نمی‌شود.
- پیش از هر Migration احتمالی باید تصمیم مستقل دربارهٔ مجوز sequence برای anon/authenticated، ACL پیش‌فرض sequence و index متفاوت test ثبت شود. هیچ‌یک از این موارد در این مرحله اصلاح نشد.
- گام امن بعدی: تهیهٔ قرارداد parity برای schema usage، table ACL، sequence ACL/default ACL، function ACL/default ACL، trigger و index؛ سپس اجرای آن روی یک دیتابیس دورریختنی/ایزوله که از snapshot معتبر Production ساخته شده باشد. پروژهٔ تست فعلی تا رفع drift نباید به‌عنوان clone Production معرفی شود.
- هرگونه تغییر پایدار در Production یا پروژهٔ تست، اجرای Migration، db push، تغییر Cron/Worker، Merge، ایجاد هزینه یا ارتقای زیرساخت همچنان متوقف و نیازمند تأیید صریح مالک است.

### قفل ایمنی این الحاقیه
- تمام پرس‌وجوهای دیتابیس فقط خواندنی و مبتنی بر کاتالوگ PostgreSQL بودند.
- هیچ جدول، index، policy، ACL، default privilege، sequence، trigger، تابع، داده، Cron یا Worker تغییر نکرد.
- هیچ Migration اجرا نشد و PR #62 ادغام نشد.


## گزارش تکمیلی ممیزی و اعتبارسنجی تست‌های کاتالوگ — ۲۵ نوامبر ۲۰۲۶

این بخش، snapshotهای قدیمی‌تر همین گزارش را برای وضعیت فعلی جایگزین می‌کند.

### وضعیت شاخه و PR
- آخرین commit کد/تست پیش از این گزارش: `2e30ba2daa76022c633cb0d46c1b340413685658`.
- PR #62 در آخرین بررسی باز، Draft و ادغام‌نشده است؛ mergeable=true.
- مقایسهٔ head با base در آخرین snapshot پیش از این گزارش: ۹۱ commit جلوتر و صفر عقب‌تر.
- فایل جدید `tests/exchange-asset-observations-catalog.sql` به قرارداد تست افزوده شد و workflow طوری به‌روزرسانی شد که پس از تست RPC، قرارداد کاتالوگ جدول مشاهدات را نیز روی همان دیتابیس تست اجرا کند.
- تعداد فایل‌های PR با اضافه‌شدن تست جدید باید در snapshot بعدی GitHub دوباره تأیید شود؛ اعداد ۲۹ فایل و commitهای قبلی دیگر مبنای وضعیت نهایی نیستند.

### اصلاح اشکال‌های کشف‌شده در تست RPC
اجرای read-only قرارداد کاتالوگ روی Production دو ایراد SQL در فایل تست را آشکار کرد:
1. شمارش overloadها از aggregate تو در تو استفاده می‌کرد و خطای PostgreSQL 42803 می‌داد؛ با subquery گروه‌بندی‌شده اصلاح شد.
2. CTEهای allowlist ستون‌های `nspname/proname` برمی‌گرداندند، در حالی که query بیرونی `schema_name/function_name` می‌خواند؛ aliasها اصلاح شدند.

پس از اصلاح، اجرای `tests/rpc-security-catalog.sql` روی Production با موفقیت تمام شد. این اجرا فقط catalog SELECT داشت و هیچ تابع برنامه‌ای، RPC، داده یا ACL را تغییر نداد.

### قرارداد مستقل جدول مشاهدات
فایل جدید `tests/exchange-asset-observations-catalog.sql` اضافه شد. این تست به‌صورت read-only موارد زیر را با baseline ثبت‌شدهٔ Production تطبیق می‌دهد:
- ۱۳ ستون، نوع داده، nullability، default و identity.
- ۵ constraint و تعریف دقیق آن‌ها.
- چهار index، تعریف و وضعیت معتبر/آماده.
- فعال بودن RLS، خاموش بودن FORCE RLS و نبود policy.
- ACL مستقیم جدول و سطح دسترسی anon/authenticated/service_role.
- ACL sequence هویتی.
- تعریف و وضعیت Trigger خودکار فهرست‌کردن دارایی تأییدشده.

در اجرای آزمایشی این قرارداد روی Production ابتدا دو خطای تست (نمایش boolean به شکل t/f و cast وضعیت trigger) اصلاح شد. پس از اصلاح، اجرای نهایی روی Production موفق شد.

اجرای همین قرارداد روی پروژهٔ تست عمداً با خطای کنترل‌شدهٔ index drift متوقف شد؛ Production دارای `exchange_asset_observations_match_idx (match_status, last_seen_at DESC)` است، ولی پروژهٔ تست index متفاوت و partial به نام `exchange_asset_observations_match_status_active_idx` دارد. ممیزی قبلی همچنین نشان داده بود service_role در پروژهٔ تست مجوز مستقیم جدول ندارد و ACL sequence آن با Production یکسان نیست. بنابراین شکست، اختلاف محیط را ثابت می‌کند و نشانهٔ خرابی Production نیست.

### نکتهٔ امنیتی مهم دربارهٔ Default ACL
در Production، Default ACL مربوط به توابع schema عمومی برای grantorهای `postgres` و `supabase_admin` شامل EXECUTE برای نقش‌های anon، authenticated و service_role است. Default ACL مربوط به sequenceهای عمومی نیز SELECT/UPDATE/USAGE را برای همین نقش‌ها دارد. این مجوزها به‌صورت پیش‌فرض روی اشیای جدید اثر می‌گذارند؛ بنابراین هر تابع جدید public باید با سیاست مجوزدهی صریح و بررسی‌شده ساخته شود. فایل پیشنهادی محدودسازی Default EXECUTE همچنان فقط draft است و اجرا نشده است.
پروژهٔ تست فعلی رکوردهای Default ACL متناظر در schema public را ندارد؛ این اختلاف باید در مرحلهٔ parity به‌صورت مستقل پوشش داده شود.

### وضعیت اجرای CI و قفل انتشار
- تست‌های کاتالوگ روی Production به‌صورت مستقیم و فقط خواندنی اعتبارسنجی شدند؛ این به معنی اجرای موفق Job یکپارچه‌سازی CI نیست.
- Job یکپارچه‌سازی RPC در workflow همچنان با متغیر `DIGIARZ_ENABLE_RPC_SECURITY_TESTS` محافظت می‌شود و تا آماده‌شدن دیتابیس تست همسان، skipped باقی می‌ماند.
- هیچ secret یا repository variable تغییر نکرد.
- هیچ Migration، db push، GRANT/REVOKE پایدار، تغییر schema، trigger، index، sequence، داده، Auth، Cron یا Worker انجام نشد.
- هیچ Merge، هزینه یا ارتقای زیرساخت انجام نشد.

### گام بعدی
1. اجرای CI روی آخرین commit پس از اصلاح تست‌ها و ثبت نتیجهٔ هر job.
2. تکمیل parity قرارداد Default ACL و ACLهای role/service_role بدون تغییر دادن محیط‌ها.
3. تهیهٔ طرح clone دورریختنی و fixture احراز هویت آزمایشی برای آزمون end-to-end؛ تا آن زمان پروژهٔ تست موجود برای اجرای job RPC قابل اعتماد نیست.
4. بازبینی مستقل draft محدودسازی Default EXECUTE، به‌ویژه اثر آن بر توابع public فعلی و مسیرهای worker، پیش از هر پیشنهاد اجرا.
