# DigiArz GitHub Pages preview

This preview deployment is intentionally isolated to `redesign/independent-ui-2026`.

- Expected project-site URL: https://shahram-adim.github.io/DigiArz/
- The workflow builds the PWA shell with `npm run build:web` and publishes only the generated `www/` directory.
- It does not merge the redesign into `main`, modify Supabase, or publish an Android APK.
- GitHub repository Pages must be configured to use **GitHub Actions** as its build/deployment source. The workflow cannot change that repository setting.
- The project-site URL is not sufficient for Android Digital Asset Links at the host root. A separate user-owned root-site repository or custom domain is still needed for `/.well-known/assetlinks.json`.
- A successful deployment must be verified from the GitHub Actions run and by opening the live URL; adding this workflow alone does not prove publication.
