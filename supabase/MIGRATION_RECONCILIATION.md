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
