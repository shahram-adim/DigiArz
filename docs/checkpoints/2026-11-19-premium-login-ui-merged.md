# DigiArz checkpoint — premium login UI merged (2026-11-19)

- User explicitly approved merging PR #17 and building a new Android APK.
- PR #17 (premium white / royal-blue / restrained-gold login screen) was marked ready and merged into `main` using squash merge.
- PR: https://github.com/shahram-adim/DigiArz/pull/17
- Merge commit: `685e1eef2b530e0c565a09a8cfc0962a4a6a01fe`.
- PR head tested before merge: `b3e988cf7181e7b8dac2aab0d6b34670da8a441a`; exact-decimal CI run `44496195383` completed with conclusion `success`.
- Verified PR #17 changed only `index.html` and `tests/index-syntax.test.js`. Read-back from `main` confirms the premium auth styles and reduced-motion CSS are present.
- No authentication logic, Supabase configuration, schema, wallet, order, trade, or financial data was changed by this PR.
- A new Android APK has **not yet been verified as built or uploaded** for merge commit `685e1eef2b530e0c565a09a8cfc0962a4a6a01fe`. Do not reuse the older artifact from commit `0ee8c9dbeb0c8229b2181acc2e9cb52544e6868b` as the new build.
- PR #18 (incident / cron documentation) remains open and unmerged. This checkpoint file was added to its documentation branch only; it does not merge PR #18.
- The earlier Supabase Auth HTTP 504 / PostgreSQL responsiveness issue remains unresolved based on the last observed logs. The schedule-only mitigation remains applied; core price jobs and financial workers were preserved. Do not claim Auth recovery without fresh evidence.
- Next: obtain the Android workflow run associated with merge commit `685e1eef2b530e0c565a09a8cfc0962a4a6a01fe`; verify the workflow conclusion, artifact ID, and `BUILD-INFO.txt` commit; then provide only the verified APK. If no run was triggered, use the repository's configured Android workflow dispatch only after confirming its exact workflow file and inputs.
