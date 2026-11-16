# DigiArz database backup and recovery

## What this artifact contains

The GitHub Actions artifact named `DigiArz-database-backup` contains an encrypted PostgreSQL custom-format archive for the application's `public` and `private` schemas, plus a small metadata file.

The backup intentionally excludes row data (but not table definitions) from these transient private request queues:

- `private.crypto_assets_sync_requests`
- `private.market_fx_sync_requests`
- `private.market_price_sync_requests`

Other selected `private` data, including admin, audit, control, and synchronization state records, is included.

**This is not a full Supabase project backup.** It does not include Auth users/identities/sessions, Storage objects or settings, Vault secrets, Edge Functions, project Auth/Realtime settings, or the Supabase migration history. Storage object bytes are stored outside PostgreSQL. Do not treat this artifact as sufficient by itself to recreate an entire Supabase project.

## Download and decrypt

1. In GitHub, open **Actions → DigiArz manual database backup**, select a successful run, then download the `DigiArz-database-backup` artifact.
2. Extract the ZIP. It should contain `digiarz-database.dump.enc` and `README-backup.txt`.
3. Obtain the exact `BACKUP_ENCRYPTION_PASSWORD` from the repository secret owner through a secure channel. Never put it in a command-line argument, chat, issue, commit, or log.
4. With OpenSSL installed, decrypt locally. The command prompts for the password; do not add it directly to the command:

```sh
openssl enc -d -aes-256-cbc -pbkdf2 -iter 600000 \
  -in digiarz-database.dump.enc \
  -out digiarz-database.dump
```

5. Check that the archive can be listed:

```sh
pg_restore --list digiarz-database.dump
```

The workflow itself verifies that encryption/decryption reproduces identical bytes and that expected archive entries exist. These checks validate archive integrity and expected contents; **they do not prove that a database restore succeeds**.

## Recovery precautions

- Never test a restore against the live DigiArz production database.
- Prefer a separate, empty Supabase project intended for recovery testing. Creating a project may incur charges; check pricing and obtain approval before creating or upgrading anything.
- Use a PostgreSQL client compatible with the source archive (the workflow uses PostgreSQL 17).
- Before restoring, inspect the archive list and identify required extensions, schemas, functions, triggers, policies, and grants. Supabase-managed schemas and roles are not included in this application-schema archive.
- A target Supabase project provides managed schemas such as `auth`, but its configuration and Auth data are not copied by this artifact. Functions and policies that refer to `auth.uid()`, Supabase roles, or other managed objects must be checked against the target.
- The `private.admin_users` record is logically tied to an Auth user. Because Auth user data is not included, restoring the private schema alone may leave the admin mapping unusable until the corresponding Auth account is recreated or mapped safely.
- The backup does not include `supabase_migrations.schema_migrations`. Do not mark migrations as applied merely because their schema objects appear in the archive.
- Do not restore Vault secrets from unrelated sources or copy production secrets into a test project.
- Do not expose database URLs, database passwords, encryption passwords, service-role keys, or decrypted archives.

## Restore status

As of 2026-11-16, the latest workflow run (`43848835281`) completed successfully and produced the expected artifact. No live restore drill has been performed. A recovery test must be conducted in an isolated target and documented separately before this backup can be described as restore-tested.
