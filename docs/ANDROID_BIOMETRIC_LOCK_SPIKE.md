# Android biometric session lock — implementation spike

Date: 2026-11-21
Status: investigation checkpoint; no runtime biometric behavior enabled.

## User requirement
- Real Android APK fingerprint/biometric unlock only.
- Browser/PWA authentication remains unchanged.
- Password login, signup, password recovery, logout, and existing dashboard handoff must keep working.
- No custom domain is required for this APK-only feature.
- Never treat a standalone `verifyIdentity()` prompt as session protection.

## Verified repository baseline
- Base: `main` at `1c2ba0f9449d64cebc6d511f646fc8857dad1f89`.
- `package.json` pins Capacitor Android/Core/CLI to `6.2.1`.
- `index.html` creates the Supabase client in `initClient()` with `persistSession: true` and `autoRefreshToken: true`; no custom auth storage adapter is currently supplied.
- The application registers `onAuthStateChange` and then calls `getSession()` during startup. The existing login uses `signInWithPassword()`; logout uses `signOut()`.
- Android CI generates the native project from scratch with `npx cap add android` and `npx cap sync android`; persistent changes must therefore live in package/config/build inputs, not generated `android/` files.
- Existing Capacitor 8 Passkey spike is unsuitable as a base: it is 184 commits ahead and 88 behind main, and changes unrelated UI/auth files. It is reference material only.
- No domain is configured or required for a native BiometricPrompt feature.

## Compatibility decision
- The biometric plugin major follows the Capacitor major. Current plugin documentation maps v8 to Capacitor 8; v6 is listed as compatible with Capacitor 6 but is no longer maintained.
- The required biometric-protected credential access controls and secure retrieval APIs are documented in current v8 releases. Therefore, do not add the old v6 plugin to the current Capacitor 6 app as if it provides the same guarantees.
- Candidate target for this isolated spike: Capacitor 8 and `@capgo/capacitor-native-biometric@8.9.3` (pin exact versions; validate package peer dependencies and Android build before adoption).
- Capacitor 8 migration is a prerequisite to evaluate in this branch, not an approved mainline upgrade.

## Security architecture requirements before coding
1. Use a Supabase Auth custom storage adapter for the native APK only; browser/PWA must retain the current default storage path.
2. Persist the serialized Supabase session only through biometric-protected native secure storage. Never leave a second refresh-token/session copy in localStorage, Preferences, or an unprotected native store.
3. Gate session restoration before `getSession()` / auth-state bootstrap. A successful standalone biometric prompt is not enough: secure decryption must be bound to BiometricPrompt/Keystore.
4. Handle session writes caused by login and refresh-token rotation, and deletes caused by logout/account switching. Avoid prompting on every internal SDK read; define a bounded in-memory unlocked-session lifecycle and clear it on background/lock.
5. Preserve recovery links and password recovery. Recovery callback URLs must not be swallowed by a biometric gate.
6. If biometrics are unavailable, cancelled, locked out, or invalidated after enrollment changes, fail closed to the existing email/password login path without deleting a valid protected session unless the user explicitly logs out.
7. Do not log tokens, passwords, serialized sessions, or native credential payloads.
8. Confirm the exact plugin API/Android implementation and test on Android 10 (Mi 9 Lite class device), including biometric enrollment changes and process death.

## Acceptance tests
- Web/PWA: login, refresh, reload, recovery, logout behavior unchanged.
- APK first login: email/password works; opt-in enrollment stores a protected credential.
- APK cold start: dashboard stays locked until native biometric-backed secure retrieval succeeds.
- APK background/resume and process death: no unlocked session is restored without the required biometric gate.
- Refresh-token rotation: latest session is securely persisted without a plaintext fallback or race.
- Cancel/failure/no enrolled biometric: user remains at login and can use password flow.
- Logout: protected session is deleted and cannot be restored.
- Android CI: clean generated project, manifest permission, Gradle build, APK artifact provenance.
- Device QA: actual Android 10 installation and tests; CI build success alone is not device verification.

## Explicit non-actions
No Production/Supabase changes, no main merge, no release publication, no change to the existing web login, and no claim that fingerprint unlock is implemented. This file records the safe implementation boundary only.
