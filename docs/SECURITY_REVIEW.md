# Historical security review - 17 October 2026

> The recovery-key feature was subsequently removed at the user's request. Current behavior uses standard account storage, with one-time conversion for previously encrypted records. See [current security documentation](SECURITY.md).

Scope: local Flutter source, Firestore rules, encrypted transaction storage, and targeted automated tests. No destructive tests were run against live user data. This is not an independent penetration test or a guarantee against compromise.

## Findings and changes

| Finding | Action |
| --- | --- |
| Transactions were readable plaintext to the database service | Added a recovery-key AES-256-GCM vault and resumable conversion at first unlock. Actual user data migrates only after the owner saves and confirms a key. |
| Client profile documents accepted arbitrary fields | Denied unused profile creates/updates and user enumeration. Owner deletion remains available. |
| Unlimited persistent cache retained financial records | Disabled persistence for new sessions. Previously stored caches and backups require separate handling. |
| No client attestation integration | Added opt-in Firebase App Check initialization with production providers. Registration and server enforcement remain pending. |
| Security rules lacked executable negative tests | Added local emulator tests and a GitHub workflow. |
| Test-tool dependency had reported high-severity advisories | Overrode grpc-js to 1.14.6; npm audit reported zero vulnerabilities in the locked Node test dependencies at review time. |

## Validation

- 82 Flutter tests passed, including key confirmation, wrong-key rejection, background locking, migration, ciphertext tampering, and account/document binding.
- 21 Firestore emulator tests passed, including unauthenticated access, cross-account access, malformed payloads, profile privilege injection, immutable vault configuration, and rejecting plaintext after vault creation.
- Flutter analysis reported no issues.
- Final web release build succeeded.
- Updated Firestore rules were deployed to `pocket-exp-2610142142` successfully.
- A limited tracked-file pattern scan found no private-key blocks, service-account credentials, or GitHub personal tokens. This is not a complete secret-history audit.

## Remaining boundaries

App Check is not enforced by this change alone, and no network WAF is installed. The public web site key/domain and platform provider registration are still needed. IAM, production authentication quotas, email enumeration settings, and cloud-wide firewall posture were not independently audited.

Encryption protects transaction contents after migration, not metadata, deleted-data recovery, compromised devices, malicious client updates, clipboard exports, replay, or denial of service. Email verification remains an application gate rather than a verified-email Firestore rule. Recovery-key rotation and cross-account encrypted imports are not implemented.

See [deployment and threat boundaries](SECURITY.md). Keep the recovery key outside the app; password resets cannot restore encrypted data without it.
