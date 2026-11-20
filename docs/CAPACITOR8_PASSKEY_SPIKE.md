# DigiArz Capacitor 8 / Native Passkey Spike

Updated: 2026-11-20

## Isolation and intent

This is an isolated engineering spike on branch `spike/capacitor8-passkey`, based on the latest independent redesign checkpoint. It does not replace PR #31 and must not be merged to `main` without review and explicit approval.

## Dependency changes in this spike

- `@capacitor/core`: 8.6.2
- `@capacitor/android`: 8.6.2
- `@capacitor/cli`: 8.6.2
- `@capgo/capacitor-passkey`: 8.5.10

The Capgo plugin documents that v8 targets Capacitor 8 and is maintained; its v6 line targets Capacitor 6 and is no longer maintained. It provides a WebAuthn-compatible shim for `navigator.credentials.create/get` backed by Android Credential Manager, which is the closest fit for the existing Supabase Passkey WebAuthn calls.

References:
- https://github.com/Cap-go/capacitor-passkey
- https://www.npmjs.com/package/@capgo/capacitor-passkey
- https://capacitorjs.com/docs/updating/8-0
- https://capacitorjs.com/docs/getting-started/environment-setup

## CI changes

- Capacitor 8 requires Node.js 22+, so both regression and Android build workflows use Node 22 on this spike branch.
- Both workflows explicitly include this branch.
- The Android workflow uploads its debug APK artifact but does not publish a GitHub Release from this experimental branch.
- Android build continues to generate the native project in CI using `npx cap add android` and `npx cap sync android`.

## Deliberately not enabled yet

`CapacitorPasskey.autoShim` is set to false in this spike config. The native plugin is registered for dependency/build compatibility testing, but the WebAuthn shim is not activated until the canonical relying-party origin and host-root Digital Asset Links location are confirmed. No guessed domain or certificate fingerprint is inserted.

## Validation required

1. Exact Decimal/browser regression workflow succeeds on this branch.
2. Android workflow completes dependency installation, `cap sync`, and Gradle debug build.
3. Inspect the generated APK/package metadata and confirm the plugin is included in the Android build.
4. Only after the canonical RP domain and signing certificate fingerprint are available, enable the plugin config, host `/.well-known/assetlinks.json`, and add the native bootstrap shim.
5. Configure Supabase Auth Passkeys with exact web and Android origins and verify registration/sign-in on a physical Android device.

## Safety

- No Supabase Auth settings, database schema, migrations, RPCs, wallet balances, orders, trades, or production data were changed.
- The existing email/password login remains the fallback.
- No GitHub Release is published from this experimental branch.
- PR #31 and `main` remain untouched.
