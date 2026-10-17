# Security architecture and deployment

## Transaction vault

After authentication, Pocket creates or unlocks a transaction vault. A cryptographically random 256-bit recovery key encrypts each transaction with AES-256-GCM through the `cryptography` package. Each encryption uses a fresh nonce. Authenticated context includes the user ID and document ID, so copying ciphertext to another account or record fails authentication.

The app stores only version, nonce, ciphertext, and authentication tag in encrypted expense documents. Titles, categories, amounts, dates, notes, and income/expense type are encrypted. The recovery key is not uploaded, logged, or intentionally persisted. Keep it in a password manager. Firebase password resets cannot recover it.

The key and decrypted records exist in app memory while unlocked. Manual locking or moving the app to the background removes the unlocked view and drops the active key reference; managed runtimes do not guarantee memory zeroization. Clipboard exports, screenshots, a compromised device, malicious browser extensions, and modified application code can expose unlocked data.

Account IDs, document IDs, document counts, payload sizes, Firebase Authentication data, and network timing are not hidden. Existing backups and previously cached plaintext are not retroactively encrypted. Persistent Firestore caching is disabled for new sessions, but this does not erase old device caches. Clear old site/app data only after confirming all records are synced and the recovery key is safely saved.

### Existing records

Creating the vault blocks new plaintext writes using server rules. Existing documents are converted with per-document transactions before the dashboard opens. An interrupted conversion resumes at unlock. Failed decryption stops the process; there is no silent plaintext fallback. Server-side business-field validation is impossible inside encrypted payloads, so rules validate ownership and envelope shape/size instead.

Migration is not a single database-wide atomic operation. Older clients will no longer be able to write to an account after its vault is enabled. Close old sessions before migration. There is currently no recovery-key rotation flow or recovery service. A malicious authorized user or administrator can delete or replay stored data; authenticated encryption protects contents and detects modification, not availability or replay of valid older ciphertext.

Guest linking preserves the same account UID and vault. Automatic plaintext migration into an existing encrypted account is skipped; source records are retained. Cross-account encrypted import requires a separate explicit workflow and is not implemented.

## Access controls

- Firestore rules restrict records to the authenticated owner.
- Unknown paths and arbitrary client profile writes are denied.
- Legacy documents retain field/type/size validation until a vault is created.
- Encrypted envelopes have strict fields and size limits.
- Vault configuration is immutable through client updates.
- Email verification is an application entry gate; rules currently enforce authenticated ownership, not verified-email claims. Anonymous guest access is intentional.
- Admin SDK credentials and project IAM can bypass Firestore rules. Never distribute service-account keys or grant broad project roles.

## App Check: production setup still required

App Check is Firebase request attestation, not a device firewall or a guarantee against abuse. The SDK integration is opt-in until all deployed platforms are registered.

1. Register the apps in Firebase Console → App Check. Configure Play Integrity for Android, DeviceCheck for Apple, and reCAPTCHA v3 for web.
2. Build with `--dart-define=APP_CHECK_ENABLED=true`. Web also requires `--dart-define=APP_CHECK_WEB_SITE_KEY=YOUR_PUBLIC_SITE_KEY`.
3. Deploy and verify legitimate request metrics on each platform.
4. Enable Firestore App Check enforcement in Firebase Console. Without server-side enforcement, unauthorized clients are not blocked by App Check.
5. Configure authentication abuse protections, authorized domains, quotas, and budget alerts in the project. Do not enable enforcement before valid clients are registered.

The integration uses production providers, never automatic debug-token fallback. No WAF, IP firewall, or rate-limiting proxy is deployed by this change. Such a proxy would need a different backend architecture; client-side toggles cannot provide these protections.

## Repeatable security checks

Run from the repository root with Node.js and Java available:

```sh
npm ci --prefix security
firebase emulators:exec --only firestore --project demo-pocket-security --config firebase.security.json "npm --prefix security test"
flutter test test/vault_test.dart
flutter analyze
flutter test
```

Rules tests use a local demo project and attempt cross-account access, unauthenticated operations, malformed writes, privilege injection, vault overwrite, and plaintext writes after vault creation. Cryptography tests cover wrong keys, tampering, account/document binding, unique nonces, and migration. These are scoped automated checks, not an exhaustive penetration test.

The Node security-test dependency overrides `@grpc/grpc-js` to a patched version; keep the lockfile and audit it with `npm audit --prefix security`. This dependency belongs to test tooling, not the Flutter application.

## References

- [Firebase App Check setup](https://firebase.google.com/docs/app-check/flutter/default-providers)
- [Firestore rules testing](https://firebase.google.com/docs/rules/unit-tests)
- [Cryptography package](https://pub.dev/packages/cryptography)
