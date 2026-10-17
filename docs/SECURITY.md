# Security architecture and deployment

## Standard account storage

Recovery-key encryption has been removed at the user's request. New accounts open the dashboard after normal authentication and email verification. No recovery key is generated or needed.

Transactions use standard Firestore storage with owner-only access rules. Transaction fields are readable to authorized project administrators; this is not end-to-end encryption. Authentication, document validation, and the App Check integration remain in place. Persistent local Firestore caching remains disabled for new sessions.

### Previously encrypted records

A compatibility screen detects existing encrypted transactions and asks for their original key once to convert them to standard storage. It validates all ciphertext before starting conversion, preserves document IDs, converts each document transactionally, and removes vault metadata after success. Interrupted conversion can be retried. Incorrect keys do not delete records. If the key is lost, existing ciphertext cannot be decrypted; the app does not silently erase it or show an empty account.

New vault creation and encrypted writes are denied by server rules, so old clients cannot re-enable the feature during conversion. Close old app sessions before converting. Historical backups and old device caches are not changed by this update.

## Access controls

- Firestore rules restrict records to the authenticated owner.
- Unknown paths and arbitrary client profile writes are denied.
- Transaction documents require strict field, type, category, and amount validation.
- New encrypted writes are denied; existing ciphertext is retained for safe conversion.
- Retired vault metadata can only be read/deleted by its owner; new creation is denied.
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

Rules tests use a local demo project and attempt cross-account access, unauthenticated operations, malformed writes, privilege injection, retired vault writes, and safe conversion to validated transactions. Cryptography tests cover wrong keys, tampering, account/document binding, unique nonces, and migration/conversion. These are scoped automated checks, not an exhaustive penetration test.

The Node security-test dependency overrides `@grpc/grpc-js` to a patched version; keep the lockfile and audit it with `npm audit --prefix security`. This dependency belongs to test tooling, not the Flutter application.

## References

- [Firebase App Check setup](https://firebase.google.com/docs/app-check/flutter/default-providers)
- [Firestore rules testing](https://firebase.google.com/docs/rules/unit-tests)
- [Cryptography package](https://pub.dev/packages/cryptography)
