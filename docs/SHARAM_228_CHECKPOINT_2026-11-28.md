# DigiArz — checkpoint شهرام ۲۲۸
تاریخ: ۲۰۲۶-۱۱-۲۸

## وضعیت زنده قبل از checkpoint
- Repository: `shahram-adim/DigiArz`
- PR #67: open، Draft، unmerged، `mergeable=false`
- Branch: `plan/all-catalog-assets-tradable-2026-11-27`
- HEAD قبل از checkpoint: `0728acbf2607c75042467afdc21bf210ab1749a9`
- Compare با main: واگرا؛ ۲۹۵ commit جلو و ۸ commit عقب.
- Check-runs برای HEAD: صفر؛ combined statuses خالی؛ workflow run با `head_sha` دقیق HEAD: صفر.
- آخرین run موفق قابل مشاهده روی branch، run #2414 با SHA `8f7925ced4c18716ee07e11890fd9572c4fcacf4` است؛ این SHA با HEAD فعلی یکی نیست و PASS فعلی محسوب نمی‌شود.

## کار انجام‌شده
- [x] آزمون `supabase/tests/canonical_asset_ledger_key_mapping_candidate.sql` توسعه یافت.
- [x] محافظ حذف mapping که در balances یا reservations استفاده شده، با trigger اختصاصی disposable fixture موجود است.
- [x] تست جدید محافظ رزرو را مستقل می‌آزماید: ردیف balance دارایی B حذف می‌شود، اما reservation باقی می‌ماند؛ حذف mapping باید رد شود.
- [x] تست جدید محافظ موجودی را مستقل می‌آزماید: reservation دارایی A حذف می‌شود، اما balance باقی می‌ماند؛ حذف mapping باید رد شود.
- [x] متغیر محلی استفاده‌نشده `v_resolved` حذف شد.
- [x] کد test روی GitHub از commit جدید بازخوانی شد و دو assertion مستقل وجود دارد.
- [x] workflow شاخه `.github/workflows/exact-decimal-tests.yml` بررسی شد. دو اجرای disposable مجزا دارد: authoritative Market/Limit source parity و canonical ledger mapping؛ اجرای دوم setup، helper snapshots، migration دقیق و candidate mapping test را به ترتیب اجرا می‌کند.
- [x] تست‌های عمومی lifecycle/cancel در repo نیز بررسی شدند: `exact_decimal_cancel_setup.sql` و `exact_decimal_cancel_integration.sql` شامل مصرف جزئی، لغو و آزادسازی باقیمانده رزرو و بررسی مالکیت هستند؛ workflow شامل تست‌های دو-نشستی worker/cancel race هم هست. اینها هنوز اثبات اتصال canonical asset key به تمام lifecycleها نیستند.

## محدودیت شواهد
- [!] هیچ workflow یا check run روی SHA دقیق `0728acb` دیده نشد. تغییر test ثبت و بازخوانی شده اما PostgreSQL execution و CI PASS تأیید نشده‌اند.
- [!] اجرای موفق run #2414 روی SHA قدیمی‌تر، اجرای تست تغییرات فعلی را اثبات نمی‌کند.
- [!] workflow mapping test فقط جداسازی asset ledger mapping را اجرا می‌کند؛ هنوز end-to-end duplicate ticker با pair_id در Market/Limit/worker/cancel/admin-disable پیاده نشده است.
- [!] ۱۷ migration اعمال‌شده بدون منبع محلی متناظر و ۲۰ اختلاف timestamp همچنان blocker هستند.
- [!] inventory همه clientها، Edge Function/service-role writers و Production metadata هنوز کامل نیست.

## گام بعدی
۱. پس از trigger شدن PR workflow روی HEAD جدید، run دقیق SHA را دنبال کن؛ در صورت failure، logs همان step را بررسی و فقط در branch اصلاح کن.
۲. پس از اجرای موفق mapping test، lifecycle لغو و worker را با دو ledger key هم‌نماد در disposable harness ترکیب کن؛ pair ID و asset ID باید در order/reservation/trade/worker/cancel حفظ شوند.
۳. برای race دو-نشستی، از harnessهای موجود استفاده کن و اثبات کن دو سفارش هم‌نماد روی دو asset مجزا نه double-spend می‌کنند نه cross-fill.
۴. تا زمان CI واقعی و source parity کامل، PASS یا آمادگی Production اعلام نشود.

## Release / safety gate
هیچ Production SQL/read/write، migration، DDL، backfill، re-key، balance/reservation/order/trade تغییر، worker/Cron invocation یا schedule change، Edge Function deployment، RLS/ACL/Auth، db push، merge، rebase، deploy، APK/Pages publication یا هزینه انجام نشده است.
هیچ اقدام Production یا release بدون تأیید صریح مالک مجاز نیست.
