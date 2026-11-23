# DigiArz — User-selected feature implementation tracker

Updated: 2026-11-23
Working branch: `features/user-selected-tools-2026-11-23`
Base: integration branch commit `82bfbb2131ca9d0ba9b6ebc91918219a36caac85`
Current feature head: `e722b0b6c9233396973d5b634f6938d06ef76e5b` (QR panel + regression test; verify latest branch head before release).

## Confirmed user constraints
- Android-first; Persian RTL and English support; display currency includes Toman.
- Demo exchange only: real market data may be displayed, but balances/trades are virtual; no real deposit, withdrawal, payment gateway, or custody.
- Preserve login/dashboard integration and existing financial/backend safeguards.
- Three distinct themes: black/gold, light glass, deep indigo glass.
- Do not merge drafts or change `main`/Production Supabase without explicit authorization.
- Do not repeat already completed work; verify current source and tests first.

## Recovered user-selected features
- Security: biometric unlock, 2FA, email/SMS verification, password change/recovery and additional safeguards.
- Notifications: price target and percentage alerts, demo-order lifecycle, market changes, security events, categorized notification history.
- Question 36 — user approved all: quick crypto search; QR for public information; crypto comparison; service health; settings backup/restore; quick-start guide; battery/network optimization; low-power mode.
- Visual requirements: three distinct themes and frameless market rows/logos; remove the five-gainers/five-losers panels.

## First implementation milestone
- [x] Add local settings backup/restore for the explicitly allowlisted preferences: theme, display currency, favorite symbols.
- [x] Exclude credentials, authentication/session tokens, wallet balances and financial records from backup.
- [x] Validate backup format/version and preference values; deduplicate favorites and cap list size.
- [x] Add settings UI controls and accessible status feedback.
- [x] Add automated validation tests in `tests/settings-backup.test.js`.
- [x] Include the low-power preference in the same allowlisted backup/restore format.
- [x] Enable exact-decimal regression workflow on this feature branch.
- [x] Full 24-step GitHub Actions run passed for feature head `2012a59a383735b7f62ad3b58a24d973f0a16182`; later health-panel commits still require their own full CI run.
- [ ] Build a new Android debug APK only after the latest feature branch CI passes.
- [x] Add the quick-start guide to Settings, including demo-only boundary and Market/Limit/Stop-Limit workflow; regression test added.
- [x] Add opt-in low-power mode: automatic market refresh is reduced from 1-minute intervals to roughly 5-minute intervals; manual refresh and account/order actions remain unchanged; regression test added.

## Remaining implementation queue
1. Recover and reconcile the full 36-question response record against this tracker; do not ask the user to repeat answers.
2. Verify quick-start, low-power, service health, comparison and QR behavior in the latest feature-branch CI and Android debug build.
3. [x] Implement read-only service health status with network state, actual market refresh timestamp/source, and an explicit note that account/database connectivity is not independently checked; never expose secrets.
4. [x] Add two-asset comparison using the app's existing trusted price/freshness checks; unavailable or stale values are labeled rather than fabricated.
5. [x] Add public-asset QR generation containing only public symbol/name/market URL; it uses an external QR image service and does not include credentials, tokens, balances or private keys.
6. Verify the comparison, service-health and QR tests in the latest full CI; continue remaining confirmed security, notification, bilingual/Toman and app usability requirements after source audit.
7. Test all changes; keep PR draft and main/Supabase untouched.

## Safety notes
- Settings backup is device-local JSON. It does not back up or restore account data or financial records.
- Import is allowlisted and asks for confirmation before applying settings.
- Passing CI does not prove physical Android install, visual acceptance, or Production Supabase correctness.
