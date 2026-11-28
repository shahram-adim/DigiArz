# DigiArz — checkpoint شهرام ۲۳۲
تاریخ: ۲۰۲۶-۱۱-۲۸

## وضعیت زنده
- Repository: `shahram-adim/DigiArz`
- PR #67: open، Draft، unmerged، `mergeable=false`
- Branch: `plan/all-catalog-assets-tradable-2026-11-27`
- HEAD: `f688c91a1c1150b78c7536d49563e1b9376ad660`
- Base SHA در PR: `fbfb5e974e754088a32c9fdcd76fc2ca9ab0f98b`

## اصلاح گزارش CI checkpoint ۲۳۱
در checkpoint قبلی، جست‌وجوی Actions با فیلتر `head_sha=<PR head>` صفر نتیجه داد و به اشتباه «CI اجرا نشده» برداشت شد. برای event از نوع pull_request، Actions run از synthetic merge SHA استفاده می‌کند؛ باید run را با pull_requests[].head.sha و شماره PR تطبیق داد، نه فقط run.head_sha.

- GitHub Actions run: `46051489315` (workflow run #2408)
- Event: `pull_request`
- PR مرتبط: #67
- PR head در metadata خود run: `f688c91a1c1150b78c7536d49563e1b9376ad660`، دقیقاً برابر HEAD شاخه
- synthetic merge SHA در run: `b9df48758834fd624ad0d3c85d96caa35d12db91`
- نتیجه run: `completed / success`
- Job `exact-decimal`: success
- Node command `node --test tests/*.test.js`: success
- PostgreSQL disposable: مرحلهٔ «Compile and run isolated Limit cancellation lifecycle integration» موفق
- PostgreSQL disposable: مرحلهٔ «Run real two-session Limit worker and cancellation race tests» موفق
- کل ۲۶ مرحلهٔ اصلی workflow در این run موفق؛ cleanup هم موفق.
- لینک: https://github.com/shahram-adim/DigiArz/actions/runs/46051489315

## معنای دقیق این موفقیت
- CI نشان می‌دهد snapshot ثبت‌شدهٔ `cancel_limit_order(uuid)` در disposable PostgreSQL بارگذاری و lifecycle cancellation با fixture موجود اجرا شده است.
- Node regression guard نیز در همان workflow موفق بوده است.
- Race دو نشست با worker اجرا شده و assertions نهایی wallet/reservation/order/trade موفق بوده‌اند.
- اما worker در این race از `supabase/drafts/2026-11-15_exact_decimal_process_limit_orders.sql` می‌آید، نه snapshot authoritative فعلی Production. این worker صریحاً Draft است و ticker-based باقی مانده است.
- schema مورد استفاده subset آزمایشی است؛ این CI parity کامل Production constraints، triggers، policies، grants، تمام writerها یا pair_id canonical را ثابت نمی‌کند.
- بنابراین فقط cancellation RPC source snapshot + تست disposable آن تأیید شده؛ نه end-to-end Production worker parity و نه جداسازی canonical duplicate ticker.

## یافته‌های کد تأییدشده
- snapshot لغو سفارش: `supabase/tests/stop_limit_production_cancel_limit_order_snapshot.sql`، fingerprint `69360684173b6aabebc5ff4e4de2eed9`.
- setup cancellation فقط `auth.uid()` را فراهم می‌کند و دیگر تابع synthetic لغو سفارش را تعریف نمی‌کند.
- lifecycle test سفارش partially_filled را لغو و reservation را reconcile می‌کند؛ تست مالکیت نیز اجرا می‌شود.
- race script دو ترتیب را می‌آزماید: worker-first و cancel-first؛ در هر دو حالت invariantهای تست fixture بررسی می‌شوند.

## گام بعد
1. منبع authoritative و fingerprint واقعی `process_limit_orders()` را بازیابی یا capture معتبر موجود را پیدا کن؛ سپس به‌جای worker draft، snapshot واقعی را در disposable harness آزمایش کن.
2. schema واقعی لازم برای worker و cancellation (constraints/triggers/indexes/ACL) را با منابع ثبت‌شده reconcile کن؛ از حدس زدن DDL اجتناب شود.
3. سپس تست duplicate-ticker را از Market/Limit RPC واقعی و worker واقعی عبور بده؛ mapping helper به‌تنهایی کافی نیست.

## ایمنی
فقط بررسی read-only GitHub و ثبت این checkpoint انجام شد. هیچ SQL روی Production، migration، db push، تغییر داده مالی، worker/Cron، RLS/ACL/Auth، merge، deployment، APK/Pages publication یا هزینه‌ای انجام نشد.