# DigiArz — checkpoint شهرام ۲۳۵
تاریخ: ۲۰۲۶-۱۱-۲۸

## بررسی زنده پس از checkpoint 234
- PR #67 HEAD = `a79d61d7c3c138174da4c6a204e24911a3267412`؛ open، Draft، unmerged، mergeable=false.
- base SHA = `fbfb5e974e754088a32c9fdcd76fc2ca9ab0f98b`.
- branch ref و checkpoint 234 از GitHub بازخوانی شدند؛ فایل checkpoint blob `f368925a75f7aec78b7e00cabc6d64e2434afe22`.
- compare base...HEAD: ahead=308، behind=0، status=ahead، 86 فایل تغییر یافته.
- check-runs روی HEAD: صفر.
- `fetch_commit_workflow_runs` برای HEAD: صفر.
- فهرست 50 workflow run اخیر هیچ run جدید PR پس از 2026-11-27 18:53Z نشان نمی‌دهد. runهای push به main روی SHAهای دیگر، شواهد این branch نیستند.
- در نتیجه تغییرات workflow و race هنوز CI PASS ندارند؛ اجرای محلی PostgreSQL نیز در این مرحله در دسترس/انجام نشده است.

## بازبینی فنی race fixture
فایل‌های زیر بازخوانی شدند:
- `supabase/tests/exact_decimal_cancel_race_setup.sql`
- `supabase/tests/exact_decimal_cancel_race.sh`
- `supabase/tests/exact_decimal_cancel_race_verify.sql`
- دو snapshot Production برای `cancel_limit_order` و `process_limit_orders`.

دو سناریوی واقعی دو-session در shell وجود دارد:
1. Worker قفل سفارش را می‌گیرد و insert معامله با trigger آزمایشی دو ثانیه متوقف می‌شود؛ cancellation پشت قفل منتظر می‌ماند؛ سپس assertions پرشدن 25٪، یک trade، مصرف/آزادسازی reservation و wallet بررسی می‌شوند.
2. Cancellation قفل سفارش را می‌گیرد؛ Worker باید به‌دلیل `FOR UPDATE SKIP LOCKED` سفارش را رد کند؛ سپس assertions عدم fill و آزادسازی reservation بررسی می‌شوند.

Fixture فقط در PostgreSQL disposable workflow است و به Production متصل نیست. Trigger تأخیر صرفاً ابزار هم‌زمان‌سازی آزمایش است.

## نتیجه و محدودیت
- اتصال هر دو Production function snapshot به race workflow از نظر فایل‌ها و ترتیب اجرا تأیید شد.
- fingerprint تابع Worker: `00ab429596fb99392666632967cde9c0`.
- fingerprint تابع cancellation: `69360684173b6aabebc5ff4e4de2eed9`.
- تست source contract worker وجود snapshot و fingerprint/قفل/partial-fill/reservation/trade/transaction و gap quantization را assert می‌کند.
- هیچ ادعای اجرای موفق SQL، race یا Node test روی HEAD جاری نداریم.
- race fixture مبتنی بر schema آزمایشی subset است، نه full Production DDL/trigger/RLS/ACL parity.
- Worker همچنان ticker/text-key محور است؛ این تغییر canonical identity و جداسازی دو asset با ticker یکسان را حل نمی‌کند.
- quantization دقیق gross/fee/net همچنان gap است.

## گام بعدی
1. علت عدم ایجاد PR Actions run را از وضعیت تنظیمات/اجازه‌های Actions در GitHub بررسی کن؛ ابزار فعلی فقط endpointهای خواندنی و rerun job شکست‌خورده را دارد و برای HEAD جاری run شکست‌خورده‌ای وجود ندارد. هیچ dispatch یا تغییر مجوزی انجام نشد.
2. با اولین run معتبر، head_sha واقعی، workflow/job/step و log کامل race را بررسی کن؛ فقط همان run مبنای PASS باشد.
3. اگر workflow اجرا نشد، اجرای امن در محیط disposable و مجوزدار لازم است؛ از Production برای تست استفاده نشود.
4. بعد از CI، به canonical ID end-to-end و settlement precision برگرد.

## ایمنی
هیچ فایل اجرایی جدیدی پس از checkpoint 234 تغییر نکرد؛ این checkpoint فقط گزارش read-only است. هیچ merge/rebase، migration، db push، Production DB یا business-row mutation، worker/Cron schedule یا invocation، Auth/RLS/ACL، deployment، APK/Pages publication یا هزینه‌ای انجام نشد.