# DigiArz — checkpoint شهرام ۲۳۷
تاریخ: ۲۰۲۶-۱۱-۲۸

## وضعیت زنده GitHub
- PR #67: open، Draft، unmerged، mergeable=false.
- Branch: plan/all-catalog-assets-tradable-2026-11-27.
- HEAD در زمان بازبینی: 2a69d186682632cc39049522df5e3d6b77a4cf21.
- Base SHA: fbfb5e974e754088a32c9fdcd76fc2ca9ab0f98b.
- checkpoint 236 موجود و بازخوانی شد؛ HEAD آن checkpoint e2d75f91bb827bfe77fd3ab4b0f956da45cba54b بود. Compare آن تا HEAD فعلی: 6 commits ahead، 0 behind.
- Main SHA: e8477b53a1b8c6fc7225572db3e559a1c75607d8؛ PR همچنان diverged/mergeable=false است.

## بررسی CI با دقت SHA
- آخرین PR run قابل مشاهده #2414 / ID 46052800147 نتیجه success دارد، ولی run واقعی head_sha=8f7925ced4c18716ee07e11890fd9572c4fcacf4 با commit time 2026-11-27 18:53:45Z است.
- workflow blob در آن SHA برابر 969f3976a0efb0002699bb156d69f899dd8b9675 است و فایل workflow آن commit فاقد stop_limit_production_process_limit_orders_snapshot.sql است.
- Step #17 با نام «Run real two-session Limit worker and cancellation race tests» در همان run success بود، اما چون workflow آن commit snapshot Worker Production را بارگذاری نمی‌کرد، این PASS آزمون race با Worker snapshot جدید را ثابت نمی‌کند.
- nested PR head در metadata run به مقدار فعلی/پویا تغییر می‌کند؛ آن را به‌عنوان SHA آزموده‌شده تلقی نکردیم.
- روی HEAD جدید check-runs=0 و fetch_commit_workflow_runs=0؛ هیچ PASS runtime برای تغییرات اخیر ادعا نمی‌شود.
- workflow روی PR branch با pull_request به main تنظیم شده؛ ابزار GitHub موجود workflow-dispatch/create-run ندارد و run شکست‌خورده‌ای برای rerun وجود ندارد. علت عدم event delivery اثبات نشده است.

## کشف منبع واقعی Fee helper
- snapshot موجود Production: supabase/tests/canonical_identity_live_public_get_demo_trading_fee_rate_snapshot.sql
- تابع: public.get_demo_trading_fee_rate(text,text)
- fingerprint: 546d80d7105228ed97da26c5ed0c7b7f
- metadata ثبت‌شده: owner=postgres، SECURITY DEFINER، search_path خالی، EXECUTE anon=false، authenticated=true، service_role=true.
- رفتار تابع: فقط maker/taker را می‌پذیرد؛ نرخ را از public.demo_trading_fees برای quote asset نرمال‌شده و is_enabled IS TRUE انتخاب می‌کند؛ در نبود تنظیم فعال خطا می‌دهد؛ 0.1% را hard-code نمی‌کند.
- setup آزمایشی parity همچنان ردیف USDT با 0.001 را صرفاً برای تست deterministic ایجاد می‌کند؛ این مقدار شاهد نرخ فعلی Production نیست.
- ساختار کامل جدول، constraints، RLS/ACL و ردیف‌های fee Production هنوز بازیابی/ممیزی نشده‌اند.

## تغییرات این مرحله
1. tests/canonical-asset-production-source.test.js:
   - snapshot تابع fee به fingerprint manifest افزوده شد.
   - تست source-level برای validation maker/taker، انتخاب maker/taker column، quote normalization، enabled filter، fail-closed و عدم hard-code 0.001 افزوده شد.
   - guard ترتیب CI اضافه شد: fee table fixture → Production helper snapshot → authoritative Market/Limit migration → parity assertions.
   - guard تصریح می‌کند setup نباید helper را با تابع stub محلی جایگزین کند.
   - آخرین blob: 75efa55a27479a934e4a3860f11086069dcbbf38.
2. docs/CANONICAL_TRADING_LEDGER_SOURCE_RECOVERY_GATE_2026-11-27.md اصلاح شد تا ادعای قدیمی «منبع تابع fee بازیابی نشده» را تصحیح کند؛ اکنون تفکیک function-body recovery از fee-table/data parity روشن است.
3. docs/CANONICAL_MARKET_LIMIT_FINANCIAL_CONTRACT_2026-11-28.md جزئیات helper snapshot و محدودیت 0.001 fixture را ثبت می‌کند.
4. Workflow اجرایی تغییر نکرد؛ branch از قبل snapshot helper را پیش از migration بارگذاری می‌کرد.

## نتیجه / محدودیت
- source helper واقعی برای disposable authoritative parity در دسترس است و regression guard به آن اضافه شد.
- این کار فقط منبع تابع را pin می‌کند؛ fee table Production و داده‌های تنظیمات را اثبات نمی‌کند.
- تست‌های Node و SQL روی HEAD فعلی اجرا نشده‌اند. این تغییرات فقط source-reviewed و از GitHub بازخوانی شده‌اند.
- canonical identity هنوز در مسیرهای واقعی مالی end-to-end پیاده نشده است؛ prototype ساده‌شده قابل promotion نیست.
- 17 migration source مفقود و full schema/ACL/RLS/trigger parity همچنان hard gate هستند.

## گام بعدی
1. اجرای CI روی SHA دقیق 2a69d186682632cc39049522df5e3d6b77a4cf21؛ بررسی logs و race step فقط در run واقعی همان SHA/merge ref مرتبط با آن.
2. در disposable PostgreSQL، fee helper snapshot را با maker/taker مختلف، quote normalization، disabled/missing config و permission boundary آزمایش کن؛ ساختار جدول fixture را با منبع معتبر کامل‌تر کن.
3. بازیابی DDL/constraints/indexes/triggers/RLS/ACL و missing migration sources را ادامه بده؛ هیچ SQL حدسی تولید نکن.
4. پس از آن canonical pair/asset IDs را روی authoritative financial ledger و تمام Market/Limit/TP-SL/Stop-Limit/admin/UI consumers طراحی و تست کن.

## ایمنی
فقط Node source regression test و مستندات در شاخه Draft تغییر کردند. هیچ Production DB، business/configuration row، balance، order، trade، reservation، RPC، Auth/RLS/ACL، Cron/Worker schedule یا invocation، migration، db push، merge، rebase، deployment، APK/Pages publication یا هزینه‌ای انجام نشد.