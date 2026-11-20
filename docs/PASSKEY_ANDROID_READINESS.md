# DigiArz Passkey Android Readiness

Updated: 2026-11-20

## Current implementation

- The web login flow uses Supabase Auth's experimental Passkey API: `registerPasskey()` and `signInWithPasskey()`.
- The browser flow is intended to remain WebAuthn-based; Supabase owns challenge generation, response verification, and session issuance.
- The Android wrapper is currently Capacitor 6.2.1.
- The Android Actions workflow generates the native project during CI with `npx cap add android`, then runs `npx cap sync android`. There is no checked-in `android/` project to patch manually; native plugin installation must be reproducible from package dependencies and Capacitor config.

## Plugin compatibility finding

The current Capgo `@capgo/capacitor-passkey` repository documents this compatibility matrix:

| Plugin major | Capacitor major | Maintenance |
| --- | --- | --- |
| 8 | 8 | Active |
| 7 | 7 | On demand |
| 6 | 6 | Not maintained |
| 5 | 5 | Not maintained |

Source: https://github.com/Cap-go/capacitor-passkey

Therefore, installing the Capacitor 6 plugin line would introduce an unmaintained native authentication dependency. The Capawesome passkeys plugin currently documents Capacitor 8+ as its supported baseline. A supported Android native integration consequently requires a separately tested Capacitor 8 migration (or another actively maintained implementation explicitly supporting Capacitor 6). Do not add an unmaintained plugin simply to make the build pass.

## Required prerequisites before enabling native Android Passkeys

1. Confirm the canonical HTTPS PWA origin and relying-party ID. Do not infer or hard-code a guessed GitHub Pages/custom domain.
2. Host a valid Digital Asset Links file at the relying-party host root:
   `https://<rp-domain>/.well-known/assetlinks.json`.
   A project Pages URL under `/<repository>/` does not itself provide the host-root location.
3. Determine the exact Android package ID (currently `com.digiarz.app`) and SHA-256 fingerprint of the actual APK signing certificate. Do not use a placeholder fingerprint or assume the debug key is the release key.
4. Ensure Supabase Auth Passkeys are enabled and configure the exact RP ID and allowed origins. Android Credential Manager uses an app origin derived from the signing certificate; the backend must accept that origin in addition to the web origin when required by its validation rules.
5. Integrate the native Credential Manager bridge and call its WebAuthn shim during app bootstrap before Supabase Passkey operations.
6. Build and test on a real Android device with a credential provider and a configured screen lock. A successful Gradle build alone does not prove biometric authentication works.

## Safety rules

- Keep email/password login as a fallback.
- Never create a local-only biometric flag or grant a Supabase session based only on a device biometric prompt.
- Do not modify Supabase Production Auth settings, merge PR #31, or change `main` without the required configuration and explicit approval.
- Keep the Passkey button from claiming native APK support until device-level verification succeeds.

## Next engineering sequence

1. Resolve the canonical relying-party domain and root hosting for Digital Asset Links.
2. Create an isolated Capacitor 8 migration spike on a separate branch and run the full browser test suite plus Android build.
3. Integrate a maintained Credential Manager plugin only after the migration spike passes.
4. Configure Supabase Auth and Digital Asset Links with real origins and certificate fingerprints.
5. Verify registration and sign-in on a physical Android device; then update the UI readiness state.
