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


## 2026-11-21 — CI build passed; Auth storage review findings

### CI evidence
- Android workflow run [44876814094](https://github.com/shahram-adim/DigiArz/actions/runs/44876814094) completed successfully. All steps passed, including clean Capacitor install, web asset preparation, generated Android project, Capacitor sync, Gradle debug APK build, provenance recording, and artifact upload.
- Artifact: `DigiArz-Android-debug-APK`, artifact ID `14696063423`, size 6,100,929 bytes, SHA-256 `c2a4006bb9ef5205322585f92ff64b3f0032c687791ac21c27d48bb66d039d05`, expires 2026-12-05T06:44:18Z.
- Exact-decimal regression workflow run [44876814102](https://github.com/shahram-adim/DigiArz/actions/runs/44876814102) completed successfully; all 21 substantive test steps passed, including DDL rollback/lock-timeout checks and real two-session order/cancel race tests.
- The APK workflow artifact records head SHA `30a73ec504945d36ae7d186924c74804b99db33a`; PR #41 currently points to `d628796fb27c32d02ad1ef0e7d8bcb2c73ee6a7e`. The later commit only updates the package description; nevertheless, artifact provenance must not be described as a build of the newer SHA.

### Auth bootstrap and dependency findings
- The current client initializer is at `index.html:2263`; it calls `createClient(..., {auth:{persistSession:true,autoRefreshToken:true,detectSessionInUrl:true}})` and does not supply custom storage.
- Auth boot sequence registers `onAuthStateChange` first, then awaits `getSession()` (around lines 3595–3630). It explicitly handles `PASSWORD_RECOVERY`, `SIGNED_OUT`, `SIGNED_IN`, and recovery query/hash parameters. Preserve this ordering and all recovery behavior when introducing native storage.
- Existing login/signup, password reset/update, logout, account reactivation, and dashboard entrypoints must remain functional; do not replace the auth flow wholesale.
- The active Production Edge Function `app-assets` is version 3 and currently serves Supabase JS from unpinned URLs `@supabase/supabase-js@2` on jsDelivr with an unpinned unpkg fallback. This means the exact Auth SDK version can change independently of Git commits. **Do not modify/deploy this Production function as part of the spike.** Before implementing a custom Auth storage adapter, pin and vendor/bundle a reviewed SDK version within this Android-only branch/build path so APK tests are reproducible and web behavior remains unchanged.
- Supabase current docs confirm custom Auth storage may implement async `getItem`, `setItem`, and `removeItem`; refresh tokens are single-use with a reuse interval, so rotation writes and concurrency must be handled carefully. See [Supabase sessions](https://supabase.com/docs/guides/auth/sessions) and [custom storage example](https://supabase.com/docs/guides/auth/sessions#using-http-only-cookies-to-store-access-and-refresh-tokens).
- Supabase JS changelog shows current release 2.119.0 (2026-11-04); no Auth-specific breaking change relevant to custom storage was identified in the latest 2026 changelog review. Pinning remains mandatory rather than relying on a floating major tag.

### Current implementation status
- Capacitor 8.6.2 + native biometric plugin 8.9.3 clean Android build is validated by CI.
- The generated debug APK is a build artifact only. No biometric prompt, biometric-protected storage adapter, manifest inspection, or real-device verification has been completed.
- No Supabase Production function, Auth settings, database, secrets, main branch, merge, or release was changed.

### Next safe implementation step
1. Add a pinned Supabase JS dependency and reproducible lockfile to this isolated branch; serve the pinned UMD bundle locally for this APK build without changing the browser/PWA path on main or the deployed `app-assets` function.
2. Verify plugin 8.9.3 exact API and generated Android manifest/Keystore access-control behavior.
3. Implement a native-only async Auth storage adapter with explicit unlock lifecycle and in-memory session cache; do not write tokens to localStorage/Preferences.
4. Add automated tests for refresh-token rotation, app process death, background/resume, recovery callbacks, logout, cancellation, biometric lockout, and enrollment changes before any merge or device-testing claim.


## 2026-11-21 — APK-only Supabase SDK pinning experiment
- Added `scripts/prepare-android-web.sh` and `npm run build:android` on the isolated branch. The script downloads the exact UMD asset for `@supabase/supabase-js@2.119.2` from jsDelivr and unpkg, requires byte-for-byte equality, copies it to `www/vendor/supabase-2.119.2.js`, and rewrites only the generated `www/index.html` loader. The tracked source `index.html` and web/PWA loader are not modified.
- Android workflow now invokes `npm run build:android`; it does not change the deployed Production `app-assets` function.
- The two-source equality check is a consistency check, not a cryptographic publisher signature or committed SHA-256 pin. The workflow logs the resulting bundle SHA-256. A committed lockfile / verified npm provenance and stable bundle digest remain required before production adoption.
- CI triggered on commit `205430991573d73e584f208b70f14529b19f626e`: Android run `44877219663` is pending at the last check; exact-decimal run `44877219671` is queued/in progress. No success is claimed for these new runs yet.
- No Auth adapter, runtime biometric prompt, local session changes, Production changes, merge, or release.


## 2026-11-21 — pinned SDK build verified
- Android workflow run [44877219663](https://github.com/shahram-adim/DigiArz/actions/runs/44877219663) completed successfully on commit `205430991573d73e584f208b70f14529b19f626e`. The pinned-Supabase preparation step, generated Android project, Capacitor sync, Gradle debug APK build, provenance, and artifact upload all passed.
- Supabase JS UMD asset `www/vendor/supabase-2.119.2.js` SHA-256 observed in CI: `8816af04d9915dbba1882d6f84f0b402dc40268063a63d9c66d24f52f371c263`. APK SHA-256: `fd4d57e62a85fc8cd51606f292a43e82f2ad44b29d23fb29dee9fb4b1c3acddd`.
- Artifact `DigiArz-Android-debug-APK`, ID `14696064416`, size 6,172,011 bytes. Exact-decimal workflow run `44877219671` also completed successfully.
- The Android preparation script now checks both CDN byte equality and the observed SHA-256 digest before packaging. This is a pinned-content integrity check; npm publisher provenance and a committed dependency lockfile are still separate supply-chain requirements.
- Official plugin 8.9.3 API review confirms `setData({accessControl: BIOMETRY_CURRENT_SET|BIOMETRY_ANY})` and `getSecureData()` are the appropriate arbitrary-data APIs. Android requires `USE_BIOMETRIC`; this CI build log did not expose the merged manifest, so permission presence remains unverified. `authValidityDuration` defaults to 0, requiring fresh biometric authentication for every protected key operation; any nonzero window is a deliberate security/convenience tradeoff.
- No runtime Auth adapter or biometric lock was implemented. No production Supabase changes, merge, or release occurred. PR #41 remains Draft.
- Next: verify the generated merged Android manifest includes `USE_BIOMETRIC`; add pinned `@supabase/supabase-js` dependency and lockfile/provenance; then design and test the native-only Auth storage adapter before enabling runtime behavior.


## 2026-11-21 — merged biometric permission verified
- Android workflow run [44877584070](https://github.com/shahram-adim/DigiArz/actions/runs/44877584070) completed successfully on commit `ed3496188ca8241f4230974d40f299a7f5f6d9d1`.
- Clean Capacitor 8 project generation, sync, Gradle debug APK build, and the explicit **Verify merged biometric permission** step all passed. The CI check located the generated merged debug manifest and confirmed `android.permission.USE_BIOMETRIC` is present.
- APK artifact and build provenance were uploaded successfully. Direct GitHub Release publication was intentionally skipped because this is the isolated biometric spike branch.
- This verifies manifest permission inclusion, not that biometric unlock is implemented or device-tested. There is still no runtime biometric prompt or Auth storage adapter.
- Current package manifest still has no direct `@supabase/supabase-js` dependency and no committed `package-lock.json`. The local APK bundle is SHA-pinned, but dependency-tree lockfile and npm provenance remain prerequisites before Auth adapter implementation.
- Supabase JS 2.119.2 release notes show only a Storage URL-boundary validation fix; no Auth change in that patch. Supabase docs explicitly support async custom Auth storage methods `getItem`, `setItem`, and `removeItem`. Refresh tokens are single-use, so session rotation must be serialized and tested. References: https://github.com/supabase/supabase-js/releases and https://supabase.com/docs/guides/auth/sessions.
