# DigiArz — checkpoint شهرام ۲۴۰
تاریخ: ۲۰۲۶-۱۱-۲۸

## وضعیت
- مخزن: `shahram-adim/DigiArz`
- PR #67 در شاخه `plan/all-catalog-assets-tradable-2026-11-27` باز و Draft است؛ ادغام نشده.
- آخرین commit کد: `af5812f5824acef7ebcd43dffc909131895716a0`
- commit قبلی سناریوی precision edge: `a1c4cb705fc7d3402c88f88d99f6375cce133715`
- فایل تست پس از آخرین تغییر از GitHub دوباره خوانده شد؛ blob SHA: `060e63f215c166932f0cdbece2adb59fd1eb94aa`.
- هیچ ادعای اجرای runtime یا PASS CI وجود ندارد؛ CI هنوز باید روی SHA جدید اجرا شود.

## کار انجام‌شده
در `supabase/tests/authoritative_market_limit_source_parity.sql` تست Market precision-edge تکمیل شد.
- ورودی amount=`0.123456789` و قیمت واقعی fixture=`1.23456789`.
- gross گرد‌شده=`0.15241579`؛ fee با نرخ taker fixture برابر 0.001 و گرد‌شده=`0.00015242`؛ total=`0.15256821`.
- علاوه بر کنترل اختلاف موجودی کیف پول، اکنون پاسخ RPC (price/fee/total)، رکورد trade (amount/price) و رکورد transactions (amount) نیز کنترل می‌شوند.
- قیمت ارسالی جعلی RPC همچنان `999999` است تا تست ثابت کند قیمت بازار منبع اجراست، نه قیمت caller.
- تغییر فقط در تست PostgreSQL دورریختنی است؛ تابع authoritative و کد Production تغییر نکرده‌اند.

## محدودیت‌ها و گام بعد
1. GitHub Actions هنوز run معتبر روی آخرین SHA ارائه نکرده؛ مالک repo باید Actions policy، workflow enablement، permissions و PR synchronize delivery را بررسی کند.
2. پس از CI، log مرحله exact Market/Limit source parity و تست‌های fee/precision بررسی شوند.
3. ۱۷ migration مفقود و ۲۰ اختلاف timestamp همچنان باید بازیابی/تطبیق شوند.
4. full Production schema/constraints/indexes/triggers/RLS/grants و fee configuration هنوز اثبات نشده‌اند.
5. Canonical identity باید روی ledger واقعی wallet/base balance/reservations/journal و pair-keyed prices ساخته شود؛ fixture مستقل canonical به‌تنهایی source parity نیست.

## ایمنی
- فقط فایل تست و این checkpoint در PR Draft تغییر کردند.
- هیچ Production SQL/migration اجرا نشد؛ هیچ داده مالی، wallet، balance، order، trade، reservation، fee config، Cron، worker، Auth، RLS/ACL یا Edge Function تغییر نکرد.
- هیچ Merge، rebase، db push، deployment، APK/Pages publication، تغییر تنظیمات Actions یا هزینه‌ای انجام نشد.
