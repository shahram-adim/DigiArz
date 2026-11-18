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

The backup workflow verifies that encryption/decryption reproduces identical bytes and that expected archive entries exist. These checks validate archive integrity and expected contents.

## Recovery precautions

- Never test a restore against the live DigiArz production database.
- The automated recovery drill is hard-pinned to the isolated Supabase project `DigiArz-Recovery-Test` (project ref `zrriqwyolcjhbappocuw`) and rejects the production project ref.
- The recovery workflow drops and recreates only the `public` and `private` application schemas in that isolated test project. Do not repoint its secret to production.
- Use a PostgreSQL client compatible with the source archive (the workflow uses PostgreSQL 17).
- The target Supabase project provides managed schemas such as `auth`, but its configuration and Auth data are not copied by this application-schema archive.
- Auth user data is not included. The recovery drill therefore omits the 15 foreign-key constraints in the archive that reference `auth.users`; the associated Auth identities are not restored.
- The `private.admin_users` record is logically tied to an Auth user. Because Auth user data is not included, restoring the private schema alone may leave the admin mapping unusable until the corresponding Auth account is recreated or mapped safely.
- The backup does not include `supabase_migrations.schema_migrations`. Do not mark migrations as applied merely because their schema objects appear in the archive.
- Do not restore Vault secrets from unrelated sources or copy production secrets into a test project.
- Do not expose database URLs, database passwords, encryption passwords, service-role keys, or decrypted archives.

## Restore status

### Automated isolated restore drill — 2026-11-18

GitHub Actions run [44298621534](https://github.com/shahram-adim/DigiArz/actions/runs/44298621534) completed with conclusion `success`. All seven job steps completed successfully.

The workflow:
1. Validated the recovery database connection against the exact isolated project ref `zrriqwyolcjhbappocuw` and rejected production connection details.
2. Downloaded the known-good encrypted backup artifact from backup run `43848835281`; the downloaded artifact SHA-256 matched the expected digest.
3. Decrypted and inspected the archive; required `public` and `private` schema entries and application table data were present.
4. Restored the application schemas into the isolated recovery project. It removed only the 15 foreign-key constraints referencing `auth.users`, because Auth rows are not part of this backup.
5. Verified restored table counts: `public` = 22 tables and `private` = 10 tables.

**Result:** the encrypted application-schema backup has passed an automated restore drill into the isolated recovery project. The production database was not the target.

**Scope limitation:** this proves the archive can be decrypted and its selected application schemas restored, with the stated Auth-related constraint exclusions. It does not test restoration of Auth users, Storage, Vault, Edge Functions, Supabase project settings, migration history, or full end-to-end application behavior. This artifact is not a full Supabase disaster-recovery backup.
