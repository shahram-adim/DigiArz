# DigiArz APK build verified — 2026-11-19

- Premium login UI PR #17 is merged to `main` at `685e1eef2b530e0c565a09a8cfc0962a4a6a01fe`.
- Android workflow: `DigiArz Android APK`, run `44498554161`, completed successfully.
- GitHub artifact: `DigiArz-Android-debug-APK`, artifact ID `14515334940`, expires 2026-12-03T09:41:34Z.
- Artifact contains `app-debug.apk` and `BUILD-INFO.txt`.
- BUILD-INFO read-back confirms:
  - git_commit=`685e1eef2b530e0c565a09a8cfc0962a4a6a01fe`
  - git_ref=`refs/heads/main`
  - workflow_run_id=`44498554161`
  - built_at_utc=`2026-11-19T09:41:34Z`
  - apk_sha256=`79957474d406b6d8a0e148afe6472a44e30d3718faa31e251231fdee3182a539`
- APK was downloaded from the GitHub artifact, extracted, and independently checked: file identifies as an Android package (APK); SHA-256 matches BUILD-INFO.
- Pages deployment for the same merge commit also completed successfully: run `44498553540`.
- Exact decimal workflow on the same commit completed successfully: run `44498554204`.
- This is a debug APK, not a Play Store release-signed production package.
- Auth 504 / database responsiveness issue remains separate and was not fixed by this UI-only merge or APK build. Do not ask user to repeatedly retry login; verify backend recovery separately before expecting successful authentication.
- PR #18 remains open and unmerged. This checkpoint is recorded on its documentation branch only.
