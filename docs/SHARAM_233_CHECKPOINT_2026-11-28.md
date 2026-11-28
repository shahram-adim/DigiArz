# DigiArz — checkpoint شهرام ۲۳۳
تاریخ: ۲۰۲۶-۱۱-۲۸

## اصلاح دقت شواهد CI در checkpoint ۲۳۲
- PR #67 همچنان open، Draft، unmerged و mergeable=false است.
- Branch HEAD هنگام شروع این مرحله `f688c91a1c1150b78c7536d49563e1b9376ad660` بود و پس از ثبت checkpointهای ۲۳۲ و ۲۳۳ به‌ترتیب جلو رفت.
- Actions run شماره `46051489315` (workflow #2408) واقعاً یک PR event مرتبط با PR #67 بوده و کل job `exact-decimal` آن success است؛ Node test step و هر دو مرحلهٔ cancellation lifecycle/race در همان run success بوده‌اند.
- با این حال `run.head_sha` خود آن اجرا `b9df48758834fd624ad0d3c85d96caa35d12db91` است؛ PR metadata داخل run فیلد head به وضعیت فعلی PR به‌روزرسانی می‌شود و به‌تنهایی ثابت نمی‌کند که اجرای قدیمی دقیقاً روی branch HEAD فعلی بوده است.
- بنابراین run #2408 را فقط به‌عنوان **شواهد اجرای موفق قبلی در PR #67** نگه می‌داریم؛ نه PASS قطعی برای تغییرات cancellation snapshot که بعداً در شاخه ثبت شده‌اند.
- API جست‌وجوی Actions با `head_sha=f688c91...` نتیجه‌ای نداد. برای synthetic/PR runs این فیلتر کافی نیست؛ با این وجود تا وقتی run با commit SHA قابل انتساب به تغییرات cancellation جدید پیدا نشود، CI این تغییرات را تأییدشده اعلام نمی‌کنیم.

## نتیجه فنی که همچنان معتبر است
- snapshot `cancel_limit_order(uuid)` با fingerprint `69360684173b6aabebc5ff4e4de2eed9` در تست disposable قرار گرفته و synthetic cancellation function از setup حذف شده است.
- workflow فایل snapshot را قبل از integration و race بارگذاری می‌کند.
- race worker هنوز از Draft `supabase/drafts/2026-11-15_exact_decimal_process_limit_orders.sql` استفاده می‌کند، نه snapshot authoritative worker Production.
- fixture همچنان subset آزمایشی است و parity کامل schema/ACL/RLS/triggerهای Production را اثبات نمی‌کند.
- canonical identity هنوز به Market/Limit RPC و workerهای authoritative وصل نشده است.

## اقدام بعدی
1. اجرای جدید CI را فقط با run ID و commit SHA واقعیِ مرتبط با تغییرات cancellation جدید تأیید کن؛ PR association به‌تنهایی کافی نیست.
2. منبع Production برای `process_limit_orders()` و schema/trigger/ACLهای لازم را بازیابی کن تا worker Draft از race حذف شود.
3. تا قبل از source parity کامل، هیچ canonical financial SQL یا Production rollout نساز.

## ایمنی
در این مرحله فقط read-only GitHub بررسی و checkpoint اصلاحی ثبت شد. هیچ Production DB operation، migration، db push، تغییر داده مالی، worker/Cron، RLS/ACL/Auth، merge، deploy، APK/Pages publication یا هزینه‌ای انجام نشد.