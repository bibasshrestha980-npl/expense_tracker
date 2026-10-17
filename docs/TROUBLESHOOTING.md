# Troubleshooting

Record your platform, commit ID, and exact error message. Remove personal data before sharing logs.

| Symptom | Check |
| --- | --- |
| Firebase fails at startup | Generate configuration for your own project and include the target platform. |
| Sign-in provider is disabled | Enable the matching provider in Firebase Authentication. |
| Google sign-in fails on web | Check authorized domains and Google provider configuration. |
| Verification email is missing | Check spam, the registration address, Firebase email quotas, and delivery-request errors. Respect the resend cooldown. |
| Firestore permission denied | Check the signed-in UID, document ownership, and whether rules were deployed to the app's configured project. |
| Nepali event details are unavailable | The external source may not cover that month. Date conversion and transactions are separate from event data. |
| A new change is missing | Check the project folder and branch, then restart Flutter. Building does not update a running debug app or hosted site. |
| Dart SDK constraint fails | Use a Flutter installation whose bundled Dart satisfies pubspec.yaml. |

## Useful diagnostics

```sh
flutter --version
flutter doctor -v
git rev-parse --short HEAD
flutter analyze
flutter test
```

Use fictional records in bug reports. Do not include tokens, passwords, service-account keys, or personal transaction exports.

[Report a bug](https://github.com/bibasshrestha980-npl/expense_tracker/issues/new?template=bug_report.md)
