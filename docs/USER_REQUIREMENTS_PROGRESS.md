# DigiArz — User-selected feature implementation tracker

Updated: 2026-11-23
Working branch: `features/user-selected-tools-2026-11-23`
Base: `integration/theme-market-cleanup-2026-11-23`
Verified feature head before this tracker update: `281c0e24ec1a8f491fbfbfeccbc9da9baed1d0fc`

## Confirmed user constraints
- Android-first; Persian RTL, English support requested; Toman display.
- Demo exchange only: real market data may be displayed, but balances and trades are virtual; no real deposits, withdrawals, payment gateway, or custody.
- Preserve login/dashboard integration and existing financial/backend safeguards.
- Three distinct themes: black/gold, light glass, deep indigo glass.
- Do not merge drafts or change `main`/Production Supabase without explicit authorization.
- Verify current source and tests before repeating work.

## Recovered user-selected requirements
- Security: biometric unlock, 2FA, email/SMS verification, password change/recovery and additional safeguards.
- Notifications: target-price and percentage alerts, demo-order lifecycle, market changes, security events, categorized history.
- Question 36 — user approved all: quick crypto search; QR for public information; crypto comparison; service health; settings backup/restore; quick-start guide; battery/network optimization; low-power mode.
- Visual requirements: three distinct themes, frameless market rows/logos, remove five-gainers/five-losers panels.

## Implemented on this feature branch
- [x] Allowlisted local settings backup/restore for theme, display currency, favorites and low-power preference; excludes credentials, tokens, balances and financial records.
- [x] Quick-start guide in Settings with demo-only boundary and Market/Limit/Stop-Limit workflow.
- [x] Opt-in low-power mode: automatic market refresh reduced from 1-minute to roughly 5-minute intervals; manual refresh and account/order actions unchanged.
- [x] Read-only service health: device network state, actual market refresh timestamp/source; account/database connectivity is explicitly not represented as verified.
- [x] Two-asset comparison using existing trusted price/freshness checks; stale or missing values are not fabricated.
- [x] Public-asset QR using symbol/name/public market URL only; external QR image service receives no credentials, tokens, balances or private keys.
- [x] Local notification center: target-price and 24-hour percentage alerts, active-alert removal, local notification history and optional browser/system notification permission. Alerts evaluate only against fresh trusted market prices while the app is running.
- [x] Regression tests for settings backup, quick-start, low-power, service health, comparison, QR and notifications.
- [x] Exact-decimal/browser and database regression workflow enabled on this feature branch.

## Verification
- [x] Full 24-step exact-decimal/database regression run passed for `b294feb2cbb3d630515302787edec67df139a10a`.
- [x] Full regression run passed for notification feature head `281c0e24ec1a8f491fbfbfeccbc9da9baed1d0fc` (run 45239716598).
- [x] Debug APK build passed for earlier feature commit `404eb75cff23a56ab4ec5d8e607d612db9ee12dd` (run 45239037977).
- [x] Debug APK containing the notification center built successfully on commit `58a427d372620c532c9f4212bc53a1484f4c8325` (run `45243957477`, artifact `14854160300`); APK SHA-256 `9dd45a8ee7096127dee71eaacbc62d7f3b8529dcd78a7ddcd0b270ad1de4413f`.
- [ ] Physical installation and Android device testing remain outstanding.


- [x] Add user-scoped Supabase Realtime order lifecycle notification handling for server-confirmed INSERT/UPDATE events: created, partially filled (including incremental fills), filled, cancelled, rejected and triggered.
- [x] Add account security notifications from confirmed Supabase Auth callbacks: sign-in, sign-out, password recovery start and user update; no credentials, tokens, IP addresses or private account data are included.
- [x] Disconnect the order channel and clear per-user event snapshots on sign-out; keep the Supabase client private to the notification module.
- [x] Verify the latest runtime regression test for order/security notifications: all tests passed on commit `7d6a3c1566ab9e613b4e5e8ee52e857ca2907e2a` (run `45243696819`). The final build+regression commit `58a427d372620c532c9f4212bc53a1484f4c8325` also passed exact-decimal CI (run `45243957410`). Test harness now provides `window.addEventListener` in the VM context.
- [ ] Confirm the Production Realtime publication/RLS path for the user's own `orders` rows without changing Production Supabase; do not claim real-time delivery until confirmed.

## Remaining work — do not mark complete prematurely
1. Reconcile the full 36-question response record from prior conversation/repository; do not ask the user to repeat answers.
2. Complete order lifecycle notifications (created, filled, partially filled, cancelled) and security-event notifications, using confirmed server/app events only.
3. Assess background delivery limits and implement a reliable supported Android notification path if needed; do not imply browser notifications run after app closure.
4. Implement and test English UI across all screens; current UI is still predominantly Persian.
5. Audit biometric unlock, 2FA, email/SMS verification and account security against actual auth provider support before implementing; do not modify Supabase/auth without explicit approval.
6. Test all three themes, layout and market-row requirements against the user's accepted visual reference.
7. Keep PR #59 Draft and unmerged; keep `main` and Production Supabase untouched.

## Safety notes
- Settings backup is device-local JSON and never backs up account or financial records.
- Import is allowlisted and confirms before applying preferences.
- Price alerts run when the app is open and valid market snapshots arrive; background delivery is not guaranteed.
- Passing CI does not prove physical Android install, visual acceptance or Production Supabase correctness.


## Execution checkpoint — 2026-11-23 19:00 UTC
- Current working branch head: `58a427d372620c532c9f4212bc53a1484f4c8325`.
- PR #59 remains Draft and unmerged; target remains `integration/theme-market-cleanup-2026-11-23`. `main` is unchanged.
- Fixed the order-notification VM test harness by supplying the missing `window.addEventListener` stub; regression run `45243696819` passed.
- Added `tests/**` to the Android APK workflow path filter so test-only commits also receive a matching Android build.
- Exact-decimal/database regression run `45243957410` passed on the current feature head.
- Android debug APK run `45243957477` passed on the same head; artifact `14854160300`, APK SHA-256 `9dd45a8ee7096127dee71eaacbc62d7f3b8529dcd78a7ddcd0b270ad1de4413f`.
- Production Realtime publication/RLS and physical Android installation are not verified.
- Security audit of current UI found password sign-in, email-confirmed signup flow and password recovery/change, but no current in-app language switch, TOTP enrollment/challenge UI, or biometric bridge on this feature branch. Separate biometric PR #47 uses a different theme direction and Capacitor 8; do not merge wholesale because the approved third theme is deep indigo glass and this branch currently uses Capacitor 6.
- Recovered exact 36-question answer details currently available: questions 4–21 and 35–36; questions 1–3 and 22–34 still require source-record reconciliation. Do not invent mappings or ask the user to repeat answers. Use the existing `PROJECT_MASTER_SPEC.md` as the broader product specification while reconciling the original numbering.
