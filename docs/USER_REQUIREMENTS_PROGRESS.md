# DigiArz — User-selected feature implementation tracker

Updated: 2026-11-23
Working branch: `features/user-selected-tools-2026-11-23`
Base: integration branch commit `82bfbb2131ca9d0ba9b6ebc91918219a36caac85`
Current feature head: `02741e9dcb9cf47d6829471bdf4e660e5dd96cd9`

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
- [x] Enable exact-decimal regression workflow on this feature branch.
- [ ] Await full GitHub Actions run `45236509157` before calling this milestone CI-verified.
- [ ] Build a new Android debug APK only after the feature branch CI passes.

## Remaining implementation queue
1. Recover and reconcile the full 36-question response record against this tracker; do not ask the user to repeat answers.
2. Implement quick-start guide and verify first-run behavior.
3. Implement low-power / reduced-network mode with explicit user control and no change to trade correctness or security refresh requirements.
4. Implement read-only service health status with truthful source/last-checked timestamps; never expose secrets.
5. Implement crypto comparison using fresh market rows only; show unavailable/stale values as unavailable, never fabricated.
6. Implement QR only for public, non-sensitive profile/public asset information; never encode secrets, account tokens, or wallet credentials.
7. Continue remaining confirmed security, notification, bilingual/Toman and app usability requirements after source audit.
8. Test all changes; keep PR draft and main/Supabase untouched.

## Safety notes
- Settings backup is device-local JSON. It does not back up or restore account data or financial records.
- Import is allowlisted and asks for confirmation before applying settings.
- Passing CI does not prove physical Android install, visual acceptance, or Production Supabase correctness.
