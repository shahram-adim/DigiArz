# ممیزی عمیق RPCهای مالی DigiArz — ۲۰ نوامبر ۲۰۲۶

## دامنه
بررسی فقط‌خواندنی روی Supabase Production با ref `gfoaubfilhttnwjykaox` و PostgreSQL `17.11.0.018` انجام شد. تعریف زندهٔ RPCها از `pg_proc/pg_get_functiondef`، ACL، ساختار جدول‌ها و قیود FK خوانده شد. هیچ تابع، grant، policy، migration، cron، سفارش، معامله، رزرو، موجودی یا کیف پولی تغییر نکرد.

## یافته‌های مثبت

- `execute_demo_trade`: هویت از `auth.uid()` گرفته می‌شود؛ حساب غیرفعال رد می‌شود؛ جفت باید فعال باشد؛ قیمت از `market_prices` خوانده و حداکثر یک دقیقه تازه بودنش کنترل می‌شود؛ قیمت ارسالی مرورگر مبنای اجرا نیست. کیف پول با `FOR UPDATE` قفل می‌شود و مبلغ قابل استفاده پس از کسر رزروها محاسبه می‌شود.
- `place_limit_order`: مالکیت از `auth.uid()` می‌آید؛ حساب فعال و جفت معتبر کنترل می‌شوند؛ کیف پول و در فروش موجودی دارایی قفل می‌شوند؛ رزروهای قبلی از موجودی قابل استفاده کم می‌شوند؛ سفارش و رزرو در یک تراکنش ساخته می‌شوند.
- `cancel_limit_order`: سفارش با `id + user_id` و `FOR UPDATE` پیدا می‌شود؛ فقط سفارش Limit قابل لغو است؛ دقیقاً یک رزرو معتبر باید آزاد شود و به‌روزرسانی سفارش نیز باید دقیقاً یک ردیف را تغییر دهد.
- `process_limit_orders`: فقط `service_role` مجاز به اجراست؛ advisory transaction lock از اجرای هم‌زمان چرخه جلوگیری می‌کند؛ سفارش‌ها با `FOR UPDATE SKIP LOCKED` گرفته می‌شوند؛ قیمت تازه، جفت فعال، مالکیت رزرو و حساب فعال کنترل می‌شوند؛ fill هر چرخه حداکثر ۲۵٪ مانده است؛ به‌روزرسانی موجودی، سفارش، رزرو، trade و transaction در همان تراکنش انجام می‌شود.
- `process_conditional_orders` و `process_stop_limit_orders`: دسترسی اجرایی به workerها محدود به `service_role` است؛ قفل advisory و قفل ردیف‌ها، اعتبارسنجی رزرو و مسیر fail-closed/تلاش مجدد در بدنه دیده شد. در Stop-Limit مسیر parent/child و اجرای Limit فرزند نیز بررسی شد.
- `admin_adjust_wallet`: wrapper عمومی به helper خصوصی `SECURITY DEFINER` می‌رسد؛ helper هویت مدیر و `private.is_super_admin()` را الزام می‌کند، مقدار/جهت/دلیل را اعتبارسنجی می‌کند، کیف پول را قفل می‌کند و برداشت USDT را با احتساب رزروهای باز محدود می‌کند. ثبت transaction و audit adjustment نیز انجام می‌شود.

## بررسی یکپارچگی داده‌های فعلی

پرس‌وجوی تجمیعی فقط‌خواندنی هفت کنترل را اجرا کرد:
- کیف پول منفی: ۰
- موجودی دارایی منفی: ۰
- رزرو با مقدار یا حساب نامعتبر: ۰
- رزرو یتیم: ۰
- سفارش باز بدون رزرو: ۰
- معامله بدون سفارش معتبر: ۰
- مقادیر نامعتبر سفارش: ۰

محدودیت مهم: جدول‌های سفارش، معامله، رزرو و موجودی دارایی در snapshot فعلی خالی‌اند؛ پس این نتیجه فقط نبود مغایرت در دادهٔ موجود را نشان می‌دهد و جایگزین آزمون runtime نیست.

## تصحیح ترتیب قفل‌ها بر اساس بازخوانی مجدد تعریف زنده

بازخوانی خط‌به‌خط تابع زنده نشان داد توضیح قبلی دربارهٔ ناسازگاری comment دقیق نبود و اصلاح می‌شود: `process_limit_orders` ابتدا ردیف سفارش را قفل می‌کند، سپس رزرو را، و بعد کیف پول را با `FOR UPDATE` قفل می‌کند؛ این قفل کیف پول پیش از تغییر `asset_balances` انجام می‌شود. بنابراین عبارت «wallet-first» در comment به ترتیب قفل منابع مالی (کیف پول پیش از دارایی) اشاره دارد و با مسیر `execute_demo_trade` هم‌راستاست. در این مسیرهای بازبینی‌شده، وارونگی قطعی قفل کیف پول/دارایی اثبات نشد. ادعای قبلی مبنی بر ناهماهنگی comment پس گرفته می‌شود.

## یافتهٔ جدید: retry نامحدود در اعتبارسنجی رزرو TP/SL

در تعریف زندهٔ `process_conditional_orders()`، شاخهٔ نامعتبر بودن رزرو (رزرو مفقود، وضعیت نامعتبر، دارایی ناهماهنگ، مقدار رزرو ناکافی یا حساب ریاضی ناسازگار) فقط `attempt_count` را زیاد و `last_error` را ثبت می‌کند و سپس `CONTINUE` می‌زند. این شاخه خارج از بلوک exception قرار دارد؛ بنابراین سقف ۱۰ تلاش و انتقال به `rejected` که در مسیر exception وجود دارد، شامل این خطا نمی‌شود. با cron فعال `digiarz-conditional-orders` هر دقیقه، چنین سفارشی می‌تواند به‌صورت نامحدود pending بماند و هر دقیقه دوباره بررسی شود. این الگو با نقص قبلی Stop-Limit شباهت دارد که برای آن bounded retry جداگانه اضافه شده است.

- Production line scan: شاخهٔ validation در خطوط 57–65 از تعریف فعلی، بدون شرط `attempt_count >= 10` است؛ بلوک exception و سقف تلاش در خطوط بعدی مسیر جداگانه‌ای دارد.
- Cron زنده: job 9، نام `digiarz-conditional-orders`، فعال، schedule برابر `* * * * *`.
- snapshot داده در زمان ممیزی: ۰ سفارش شرطی pending، ۰ سفارش pending با رزرو نامعتبر، و ۰ سفارش pending با `attempt_count >= 10`. بنابراین در snapshot فعلی مورد آسیب‌دیده‌ای مشاهده نشد؛ یافته مربوط به مسیر کد است، نه اثبات وجود سفارش گیرکرده.
- سیاست امن پیشنهادی برای شاخهٔ ایزوله: پس از ۱۰ شکست اعتبارسنجی، وضعیت parent و conditional به `rejected/manual review` منتقل شود، اما رزرو نامعتبر خودکار آزاد یا دست‌کاری نشود. برای جلوگیری از باقی‌ماندن وضعیت مبهم، خطا باید برای اپراتور قابل مشاهده باشد.
- هنوز هیچ migration یا تغییر تابع Production انجام نشده است.

## محدودیت‌ها و گام بعد

- آزمون منفی runtime با JWTهای anon/authenticated و آزمون هم‌زمانی روی Supabase Development Branch انجام نشده؛ در snapshot این پروژه Development Branch وجود ندارد.
- این مرحله همهٔ ۲۳ تابع SECURITY DEFINER قابل اجرا برای authenticated را به‌طور کامل پوشش نمی‌دهد؛ اولویت بعدی بررسی باقی‌ماندهٔ توابع مالی/حساب کاربر و سپس آزمون منفی ایزوله است.
- Security Advisor در اجرای فعلی به read timeout خورد؛ نتیجهٔ تازهٔ Security Advisor قابل تأیید نیست.
- هیچ تغییری در Production انجام نشد و `supabase db push` همچنان به علت drift تاریخچهٔ Migration ممنوع می‌ماند.


## پیگیری آزمون bounded retry — ۲۰ نوامبر ۲۰۲۶
کاندید ایزوله و regression مربوط به شاخهٔ اعتبارسنجی رزرو TP/SL در PR پیش‌نویس #36 ساخته شد. CI PostgreSQL 17 در run #1173 با نتیجهٔ success تکمیل شد؛ چهار وضعیت رزرو مفقود، آزادشده، دارایی اشتباه و مقدار ناکافی در مرز تلاش ۱۰ بررسی شدند. هیچ‌یک از رزروهای نامعتبر تغییر داده نشدند. اجرای اول به‌علت اشتباه در دو شناسهٔ parent در fixture تست شکست خورد؛ fixture اصلاح و اجرای کامل مجدد موفق شد.

**وضعیت اصلاح‌شدهٔ محدودیت انتشار:** این توضیح مربوط به نسخهٔ اولیهٔ کاندید بود و با بازسازی بعدی superseded شد. فایل فعلی PR #36 از تعریف کامل و دقیق زندهٔ ۲۰ نوامبر گرفته شده و فقط شاخهٔ اعتبارسنجی رزرو نامعتبر را تغییر می‌دهد؛ اجرای نهایی PostgreSQL 17 run #1177 موفق است. PR همچنان پیش‌نویس و ادغام‌نشده است؛ Production و cadence یک‌دقیقه‌ای تغییر نکرده‌اند.


### نتیجهٔ نهایی آزمون روی تعریف زندهٔ ۲۰ نوامبر
تعریف کامل زندهٔ `process_conditional_orders()` مجدداً بازیابی شد و کاندید PR #36 از همین بدنه، با تغییر محدود در شاخهٔ اعتبارسنجی رزرو نامعتبر، بازسازی شد. گام CI دیگر worker fixture قدیمی را برای این regression بارگذاری نمی‌کند؛ تست روی snapshot زندهٔ ۲۰ نوامبر و دیتابیس موقت PostgreSQL 17 اجرا می‌شود. اجرای نهایی full workflow، run #1177، با نتیجهٔ success و هر ۲۲ گام موفق تکمیل شد. PR #36 همچنان Draft و ادغام‌نشده است؛ هیچ تغییر Production انجام نشده است.


## یافتهٔ تکمیلی: مسیر غیرفعال‌سازی حساب و رزروهای نامعتبر

بازبینی منبع کامل `deactivate_my_account()` در دو migration زیر انجام شد:
- `20261113162051_add_demo_take_profit_stop_loss_engine.sql` (blob `3360c21a69b7fae83a7f2494428367d1b7658e81`)
- `20261113181827_add_stop_limit_order_engine.sql` (blob `3f421c6380630d74b846cd66dc7b121786237c0f`)

هر دو نسخه الگوی مهم یکسانی دارند:
1. حساب را ابتدا `is_active=false` می‌کنند.
2. فقط رزروهای `status='reserved'` را آزاد می‌کنند که `consumed_amount >= 0` و `consumed_amount <= reserved_amount` دارند.
3. سپس سفارش‌های Limit و Conditional در وضعیت باز را لغو می‌کنند، حتی اگر رزرو متناظر به‌دلیل نامعتبر بودن از UPDATE آزادسازی جا مانده باشد.
4. تابع تعداد سفارش‌های لغوشده و رزروهای آزادشده را برمی‌گرداند، اما تعداد/شناسهٔ رزروهای باقی‌مانده و نامعتبر را گزارش نمی‌کند.
5. اگر حساب از قبل غیرفعال باشد، تابع زودتر با صفر برمی‌گردد و پاک‌سازی باقیمانده را دوباره اجرا نمی‌کند.

**ریسک عملیاتی:** اگر رزروی با arithmetic نامعتبر (برای نمونه `consumed_amount > reserved_amount`) وجود داشته باشد، سفارش والد می‌تواند cancelled شود ولی رزرو همچنان `reserved` باقی بماند. این fail-closed از آزادسازی اشتباه جلوگیری می‌کند، اما ممکن است دارایی را برای همیشه در محاسبهٔ موجودی قابل‌استفاده بلوکه کند؛ فراخوانی مجدد همین RPC پس از غیرفعال‌شدن حساب نیز آن را پاک‌سازی نمی‌کند. در sourceهای بررسی‌شده مسیر اپراتوری/تطبیق دستی قابل اجرا یا گزارش شناسهٔ رزروهای جا‌مانده پیدا نشد.

این یک نقص مشاهده‌شده در منبع است، نه اثبات وجود ردیف آسیب‌دیده در Production. هیچ query زنده یا تغییر داده‌ای برای سنجش وقوع آن انجام نشد. پیشنهاد ایمن: مسیر گزارش‌گیری فقط‌خواندنی برای رزروهای نامعتبر/یتیم و یک گردش‌کار اپراتوری با تأیید دوگانه و تطبیق دقیق دفترکل طراحی شود؛ آزادسازی خودکار یا تغییر ارقام رزرو ممنوع بماند. هر اصلاح تابع غیرفعال‌سازی باید رفتار idempotent و retry پس از inactive بودن را صریحاً پوشش دهد.


## یافتهٔ تکمیلی: قفل فرزند در همگام‌سازی Stop-Limit

بازبینی Migration فعلی `20261113181827_add_stop_limit_order_engine.sql` (blob `3f421c6380630d74b846cd66dc7b121786237c0f`) نشان داد حلقهٔ اول `process_stop_limit_orders()` وضعیت child را از طریق JOIN می‌خواند، اما قفل آن حلقه فقط `FOR UPDATE OF c,parent SKIP LOCKED` است؛ ردیف child قفل نمی‌شود. در همان migration، `cancel_stop_limit_order()` ترتیب قفل conditional → parent → child را اجرا می‌کند و سپس برای لغو child به `cancel_limit_order()` واگذار می‌کند. منبع fixture لغو Limit نیز ترتیب child order → reservation را نشان می‌دهد.

در مقابل، کاندید ایزولهٔ موجود در `supabase/tests/exact_decimal_stop_limit_worker.sql` (blob `6ca50aae244a494a897dfcc71f495242dc44aac6`) و فایل کاندید rollout `supabase/drafts/2026-11-16_exact_decimal_rollout_candidate.sql`، حلقهٔ sync را با `FOR UPDATE OF c,parent,child SKIP LOCKED` اجرا می‌کنند. یعنی child در کنار parent و conditional قفل می‌شود؛ اگر Limit worker child را در اختیار داشته باشد، sync آن را skip می‌کند و چرخهٔ بعدی همگام می‌سازد.

تست دو نشست `supabase/tests/exact_decimal_stop_limit_cancel_race.sh` (blob `e88607d4afea2e41d25872f41fcdd3ed79f1fd85`) سه interleaving را پوشش می‌دهد: child worker-first سپس cancellation، cancellation-first سپس worker، و child partial-fill هم‌زمان با parent sync. فایل verify (blob `47e6f192b45715dd3f18c114b998d42904542ab2`) وضعیت parent/child، تعداد trade، مقدار مصرف/آزادسازی reservation و balances را بررسی می‌کند. مستند rollout نتیجهٔ این rehearsal را در disposable PostgreSQL ثبت کرده است؛ این شواهد به کاندید آزمایشی مربوط است، نه تعریف فعلی Migration در Production.

**نتیجه:** تغییر لازم از نظر طراحی در مخزن و تست race موجود است؛ اما source Migration ثبت‌شده در `main` هنوز نسخهٔ بدون قفل child را دارد. بنابراین اختلاف candidate-vs-migration باید پیش از هر rollout با تطبیق کامل snapshot زنده و CI مجدد بسته شود. تست‌های قدیمی یا موفقیت قبلی کاندید، به‌تنهایی اثبات نمی‌کنند که Migration فعلی یا تابع زندهٔ امروز همین رفتار را دارد. هیچ Production query یا تغییر اجرایی در این مرحله انجام نشد.


## راستی‌آزمایی منشأ تست Stop-Limit در Workflow فعلی

Workflow فعلی `.github/workflows/exact-decimal-tests.yml` (blob `50936f9c8b59a44112ae59730092a91b0d2d17d8`) دو مسیر مجزا برای race دارد:

1. مرحلهٔ «Rehearse the combined atomic exact-decimal rollout candidate» دیتابیس موقت `digiarz_rollout_stop_race_test` را از `exact_decimal_stop_limit_setup.sql` + کاندید ترکیبی `2026-11-16_exact_decimal_rollout_candidate.sql` + race setup می‌سازد و سپس `exact_decimal_stop_limit_cancel_race.sh` را اجرا می‌کند. این همان مسیر race است که تابع کاندید ترکیبی با قفل child را آزمایش می‌کند.
2. مرحلهٔ قدیمی‌تر «Run real two-session Stop-Limit child execution and cancellation races» از entrypoint candidate مورخ ۱۵ نوامبر و فایل worker تست استفاده می‌کند؛ این نیز child lock دارد، اما از مسیر ترکیبی ۱۶ نوامبر مستقل است.

Race script واقعاً دو نشست مجزا را اجرا می‌کند: worker-first و cancellation-first، سپس parent-sync در حالی که child worker ردیف فرزند را قفل کرده است باید `synced=0` بدهد؛ چرخهٔ بعدی باید پس از پایان worker وضعیت parent را به fill دوم child برساند. Verify script تعداد tradeها، filled/remaining، رزرو مصرف/آزادشده، wallet و asset balance را کنترل می‌کند.

**مرزبندی شواهد:** تعریف Migration فعلی `20261113181827...` همچنان `FOR UPDATE OF c,parent SKIP LOCKED` دارد. Workflow به‌جای اجرای همین Migration، کاندید draft را در دیتابیس disposable نصب می‌کند. بنابراین سبز بودن این job (در صورت مشاهدهٔ run موفق) فقط رفتار کاندید را تأیید می‌کند؛ نه parity با Migration یا Production. این بررسی، تعریف Workflow و ورودی‌هایش را تأیید می‌کند، اما در این مرحله run ID تازه‌ای برای همین HEAD بازیابی نشد؛ پس وضعیت اجرای تازه را ادعا نمی‌کنیم.


## Source-contract guard for Stop-Limit child locking (PR #37)

- Added Draft PR #37: https://github.com/shahram-adim/DigiArz/pull/37
- Branch: \`test/stop-limit-child-lock-source-contract\`; head commit \`d727a6593323bed5f8370da97b64281e3464a6e0\`.
- Adds one Node source-contract regression to \`tests/exact-decimal-sql-drafts.test.js\`: extracts the first sync loop from the combined rollout candidate and checked-in migration, requires the candidate to lock \`c,parent,child\`, and explicitly asserts the checked-in migration still has only \`c,parent\`. This deliberately makes the known divergence visible; if the migration is later reconciled, the assertion must be updated intentionally.
- The PR was created Draft and is unmerged. Immediately after creation, GitHub returned no workflow runs and no combined statuses for the head; CI has not yet been verified for PR #37.
- Separately retrieved fresh PR #35 run #1233 (\`44807862279\`) on head \`baa5a6381c381965037feb6ebe02f42894d69ad4\`: PostgreSQL 17 job succeeded, all 22 named workflow steps succeeded, including combined rollout rehearsal and real two-session Stop-Limit child execution/cancellation race. This validates the candidate fixtures only, not the checked-in migration or Production.
- PR #36 run #1177 (\`44787061755\`) remains successful for its distinct TP/SL bounded-retry fixture.
- No Production changes, migration edits, merge/rebase/deploy, or \`supabase db push\`.


### PR #37 first CI attempt and correction
- First PR #37 workflow run #1251 (\`44810577661\`) failed at Node test step 5. The new test failed before reaching its lock assertions because the extractor stopped at the opening \`$function$\` delimiter instead of reading the function body. All later PostgreSQL steps were skipped; this was a test-harness defect, not a PostgreSQL race-test failure.
- Corrected the extractor to capture the body between \`AS $function$\` and the closing \`$function$\` in commit \`bdb0c8f583a0596f1bf4b1a6982dba16b25d2df7\` (same Draft PR #37).
- After the correction, the GitHub connector returned no workflow run or combined status for the new head at the time of recheck. Therefore the fix is not yet CI-validated.
- Branch comparison now reports 3 commits ahead / 2 behind main because documentation-only handoff/audit commits landed after PR creation. Do not rebase or update branch automatically; PR remains Draft.


### PR #37 corrected-head CI progress
- Corrected head \`bdb0c8f583a0596f1bf4b1a6982dba16b25d2df7\` now has workflow run #1254, ID \`44810724098\`, in progress.
- Node/browser integration step passed, including the new Stop-Limit source-contract regression. PostgreSQL arithmetic, schema widening rehearsal, negative preflight, and lock-timeout preflight setup have also passed; the lock-timeout atomicity step is still running at last check.
- The full two-session Stop-Limit candidate race is a later step and has not yet run in this attempt. No overall CI success claim is justified yet.


### PR #37 corrected-head CI — completed successfully
- On 2026-11-20, corrected head `bdb0c8f583a0596f1bf4b1a6982dba16b25d2df7` completed workflow run #1254, ID `44810724098`, with overall conclusion `success`.
- Retrieved the full job-step list: all 21 substantive steps completed successfully. This includes the Node/browser integration suite and source-contract regression; PostgreSQL arithmetic; schema-widening rehearsal; invalid-data, lock-timeout and mid-migration rollback atomicity checks; Market/Limit and Stop-Limit/TP-SL entrypoint integration; combined exact-decimal rollout-candidate rehearsal; cumulative per-fill rounding; Limit and TP-SL two-session races; the real two-session Stop-Limit child execution/cancellation race; and parent-child/conditional lifecycle integration.
- The run validates the corrected source-contract guard and the draft combined rollout candidate in disposable PostgreSQL 17. It does not make the checked-in Stop-Limit migration equivalent to the candidate: main migration `20261113181827_add_stop_limit_order_engine.sql` remains recorded as locking only `c,parent`, while the candidate locks `c,parent,child`. It does not establish current Production function parity or authorize rollout.
- PR #37 remains Draft and unmerged. No branch rebase, migration change, Production query/write, RPC/cron/financial data change, deployment, or `supabase db push` occurred.
- Next: continue source-level financial lifecycle audit and separately plan authoritative Stop-Limit migration/Production parity reconciliation. Do not change the migration or Production without explicit approval.


## بررسی تکمیلی: هم‌زمانی غیرفعال‌سازی حساب با ثبت معامله/سفارش

در منبع Migrationهای فعلی، چهار مسیر کاربرمحور در ابتدای اجرا فعال‌بودن حساب را با `public.current_account_is_active()` بررسی می‌کنند: `execute_demo_trade()`، `place_limit_order()`، `place_conditional_exit_order()` و `place_stop_limit_order()`. سپس مسیرهای مالی قفل کیف پول/دارایی را می‌گیرند و عملیات را ادامه می‌دهند.

در مقابل، `deactivate_my_account()` ابتدا ردیف `profiles` را به `is_active=false` تغییر می‌دهد و بعد رزروها و سفارش‌های باز را پاک‌سازی/لغو می‌کند. در بدنهٔ این چهار entrypoint، قفل صریح همان ردیف `profiles` یا بازبینی مجدد فعال‌بودن حساب در انتهای مسیر دیده نشد. بنابراین یک interleaving قابل بررسی وجود دارد: درخواست معامله/ثبت سفارش فعال‌بودن حساب را بخواند؛ درخواست غیرفعال‌سازی حساب را غیرفعال و پاک‌سازی خود را انجام دهد؛ سپس درخواست اول نوشتن مالی را commit کند. اگر هیچ trigger یا سازوکار هم‌زمان‌سازی دیگری در schema زنده مانع آن نباشد، ممکن است پس از غیرفعال‌شدن حساب یک معامله/سفارش جدید ثبت شود.

**سطح اطمینان: فرضیهٔ منبعی، نه نقص اثبات‌شده.** جست‌وجوی مخزن، نام trigger `guard_active_account_writes` را فقط در fixture آزمون widening نشان داد؛ همان fixture بدنهٔ trigger را به‌صورت no-op تعریف می‌کند و مدرک Production نیست. این جست‌وجوی متنی نیز جای فهرست authoritative تمام triggerهای schema زنده را نمی‌گیرد. هیچ آزمون دو‌نشستی برای interleaving ثبت سفارش در برابر `deactivate_my_account()` در این مرحله اجرا نشده و هیچ Production query انجام نشده است.

**گام ایمن بعدی:** ساخت fixture مستقل PostgreSQL 17 با دو نشست و barrierهای قطعی برای چهار حالت (Market، Limit، TP/SL، Stop-Limit) در برابر غیرفعال‌سازی؛ سپس بررسی triggerها و قفل واقعی profile در snapshot authoritative، پیش از هر پیشنهاد اصلاح. معیار قبولی: پس از commit غیرفعال‌سازی، هیچ entrypoint قدیمی/درحال‌اجرا نتواند order/trade/reservation تازه‌ای برای آن کاربر commit کند؛ و اگر عملیات مالی پیش از غیرفعال‌سازی برنده شد، cleanup باید همان عملیات را به‌طور کامل و اتمیک پوشش دهد. هیچ trigger، تابع، Migration یا Production تغییری در این بررسی انجام نشده است.


## PR #38 — fixture هم‌زمانی غیرفعال‌سازی حساب و ثبت سفارش
- Branch: `test/account-deactivation-order-race`; PR #38: https://github.com/shahram-adim/DigiArz/pull/38; Draft/open/unmerged.
- Added `supabase/tests/account_deactivation_race_setup.sql` and `supabase/tests/account_deactivation_race.sh`, plus a workflow step in `.github/workflows/exact-decimal-tests.yml`.
- Fixture سه ترتیب را در PostgreSQL 17 جداگانه می‌آزماید: (1) الگوی بدون قفل، که در آن deactivation وسط فاصلهٔ check/write commit می‌شود و سفارش pending + reservation reserved پس از غیرفعال‌شدن ایجاد می‌شود؛ (2) قفل ردیف profile توسط ثبت سفارش، سپس deactivation منتظر می‌ماند و بعد از commit سفارش آن را لغو و reservation را آزاد می‌کند؛ (3) deactivation-first، که باعث می‌شود مسیر قفل‌شده سفارش را رد کند.
- **محدودیت مهم:** این fixture یک مدل concurrency کوچک و مستقل است؛ بدنهٔ کامل چهار RPC واقعی را اجرا نمی‌کند و ثابت نمی‌کند Production فاقد trigger یا قفل دیگری است. Candidate profile-row locking فقط در fixture آزمایشی است؛ هیچ Migration/Production تغییر نکرده است.
- PR ساخته شد ولی در اولین بررسی، `fetch_commit_workflow_runs` برای head `a6849671727fce10fe852bda607fd65b3fc2a351` هنوز runی برنگرداند. تا مشاهدهٔ run و بررسی نتیجه، تست را اجراشده/سبز اعلام نکن.
- Next: monitor PR #38 CI; if it fails inspect exact job logs and repair only the Draft branch. If green, extend fixture toward full entrypoint bodies and establish authoritative trigger/profile-lock inventory from a safe schema snapshot before proposing any rollout.


### PR #38 CI progress checkpoint — 2026-11-20
- Run #1263 / ID `44811642137` is active on head `a6849671727fce10fe852bda607fd65b3fc2a351`.
- Steps 1–18 have completed successfully, including exact-decimal, Market/Limit integration, Limit race, TP/SL execution/cancellation race, and completed rollout rehearsal checks. Step 19 (Stop-Limit child execution/cancellation race) is currently in progress; steps 20–22 (Stop-Limit lifecycle, TP/SL lifecycle, and new account-deactivation/order race) have not run yet. Therefore the new race test has **not** passed yet and the overall workflow is not complete.
- Additional repository code searches for trigger declarations and references around `deactivate_my_account`, `current_account_is_active`, and financial tables did not produce authoritative evidence of all live triggers. This is only a repository-search observation, not proof that no Production trigger exists.
- No Production query or change was made. PR #38 remains Draft.
