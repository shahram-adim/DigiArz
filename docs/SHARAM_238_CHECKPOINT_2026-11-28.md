# DigiArz — checkpoint شهرام ۲۳۸
تاریخ: ۲۰۲۶-۱۱-۲۸

## وضعیت زنده GitHub پس از ادامه از شهرام ۲۳۵
- مخزن: `shahram-adim/DigiArz`
- PR #67: open، Draft، unmerged، mergeable=false.
- شاخه: `plan/all-catalog-assets-tradable-2026-11-27`
- HEAD پس از این مرحله: `fc11b5e0df945e8368e89b195cdfcc3cd25ea4f9`
- Base SHA: `fbfb5e974e754088a32c9fdcd76fc2ca9ab0f98b`
- Main SHA در آخرین compare: `e8477b53a1b8c6fc7225572db3e559a1c75607d8`
- Compare main...branch: ahead=320، behind=8، status=diverged.
- PR metadata: 320 commits، 89 changed files.

## تغییر این مرحله
فایل `supabase/tests/authoritative_market_limit_source_parity.sql` در commit `fc11b5e0df945e8368e89b195cdfcc3cd25ea4f9` به‌روزرسانی شد:
- نرخ‌های Maker و Taker به‌صورت متمایز (0.0007 و 0.0013) در fixture آزمایشی تنظیم می‌شوند.
- فراخوانی helper با quote ورودی دارای فاصله و حروف کوچک (' usdt ') بررسی می‌شود.
- انتخاب جداگانه maker_fee_rate و taker_fee_rate و نرمال‌سازی quote asset assert می‌شود.
- نرخ‌های fixture به 0.001/0.001 بازگردانده می‌شوند تا assertionهای مالی پایین‌تر رفتار deterministic قبلی را حفظ کنند.
- blob بازخوانی‌شده پس از commit: `5623bc1b4b3f9c1ea7113ec0760f6106766b2b1b`.

این یک تست روی helper snapshot واقعی در PostgreSQL disposable است؛ schema کامل جدول `demo_trading_fees` و تنظیمات واقعی Production همچنان بازیابی/ممیزی نشده‌اند.

## CI و راستی‌آزمایی
- پس از commit، PR و فایل از GitHub دوباره خوانده شدند؛ HEAD دقیقاً `fc11b5e0df945e8368e89b195cdfcc3cd25ea4f9` است.
- برای همین SHA، endpoint اجراهای PR workflow هیچ run برنگرداند و combined commit statuses نیز خالی است.
- بنابراین تست جدید هنوز اجرا نشده و هیچ PASS runtime ادعا نمی‌شود.
- علت عدم تحویل event/اجرای Actions همچنان اثبات نشده است. workflow روی main وجود دارد و فیلتر pull_request آن base=main است؛ این دو مورد علت مشکل نیستند. وضعیت Actions policy و event delivery باید توسط مالک repo در GitHub بررسی شود.

## گام‌های باقی‌مانده
1. مالک repo، صفحه Actions و workflow state/permissions و PR timeline را برای synchronize event پس از commit بررسی کند؛ بدون تغییر permissions یا default-branch workflow تا تأیید صریح.
2. پس از ایجاد run معتبر، head_sha دقیق و logs مرحله Market/Limit source parity و raceها بررسی شود.
3. تست Maker/Taker و quote normalization روی همان run واقعی تأیید شود؛ سپس schema/constraints/RLS/ACL جدول fee از منبع معتبر بازیابی شود.
4. بازیابی 17 applied migration فاقد source و تطبیق 20 timestamp mismatch ادامه یابد؛ `supabase db push` همچنان ممنوع است.
5. طراحی canonical identity باید با حفظ wallet USDT، asset ledger، رزرو cumulative، 25% partial fill، fee helper، round semantics، freshness یک‌دقیقه‌ای و lock ordering انجام شود؛ prototype ساده‌شده قابل promotion نیست.

## ایمنی
- فقط فایل تست در PR Draft تغییر کرد.
- هیچ Migration یا SQL روی Production اجرا نشد.
- هیچ fee row، wallet، balance، order، trade یا reservation تغییر نکرد.
- هیچ Worker/Cron، Auth/RLS/ACL، workflow settings، merge/rebase، db push، deployment، APK/Pages publication یا هزینه‌ای انجام نشد.
