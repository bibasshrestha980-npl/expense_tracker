<p align="center"><img src="docs/banner.svg" alt="Pocket: Personal finance, made clear" width="100%"></p>

[![Flutter CI](https://github.com/bibasshrestha980-npl/expense_tracker/actions/workflows/ci.yml/badge.svg)](https://github.com/bibasshrestha980-npl/expense_tracker/actions/workflows/ci.yml)
![Flutter](https://img.shields.io/badge/Flutter-Material%203-02569B?logo=flutter)
![Provider](https://img.shields.io/badge/State-Provider-155f53)
![Firebase](https://img.shields.io/badge/Storage-Firestore-FFCA28?logo=firebase)
[![MIT](https://img.shields.io/badge/License-MIT-155f53)](LICENSE)

# Pocket — Expense Tracker

Track everyday income and expenses in Nepali rupees, browse transactions with Bikram Sambat or Gregorian dates, and understand your spending through monthly summaries.

Pocket is a Flutter personal finance project built with **Firebase Authentication**, **Cloud Firestore**, and **Provider**, with English and Nepali localization.

[Features](#features) · [Getting started](#getting-started) · [Architecture](#architecture) · [Contributing](CONTRIBUTING.md)

## Features

| Area | What you can do |
| --- | --- |
| Transactions | Record, edit, search, and delete income and expenses with categories and notes. |
| Overview | Review income, spending, balance, and recent transactions. |
| Insights | Explore monthly spending, category totals, and comparisons. |
| Nepali calendar | Switch between BS and AD dates and browse daily activity. |
| Calendar details | View available event and tithi data from external sources. |
| Reports | Copy financial summaries and monthly transactions as CSV to the clipboard. |
| Languages | English and Nepali localization resources. |
| Appearance | Light, dark, or system theme, with your preference saved on this device. |
| Authentication | Email/password, Google, and guest sign-in when enabled in Firebase. |
| Email verification | Firebase emails a verification link; unverified accounts confirm their email before entering the dashboard. |
| Storage | Firestore synchronization with user-scoped access rules. |

Amounts are stored as integer paisa to avoid floating-point rounding errors in transaction totals.

### Light and dark mode

Open **Settings → Preferences → Appearance** and choose **Light**, **Dark**, or **Follow system**. Pocket remembers the choice on your device; **Follow system** adapts to your device's appearance setting.

| Light | Dark |
| --- | --- |
| ![Pocket dashboard in light mode](docs/light-mode.png) | ![Pocket dashboard in dark mode](docs/dark-mode.png) |

Previews use sample transaction data.

## Getting started

### Requirements

- Flutter with **Dart 3.13 or later**, matching [pubspec.yaml](pubspec.yaml).
- Firebase CLI and FlutterFire CLI.
- Your own Firebase project.
- Chrome or a configured Android/iOS development environment.

### 1. Clone and install

```sh
git clone https://github.com/bibasshrestha980-npl/expense_tracker.git
cd expense_tracker
flutter pub get
```

### 2. Configure Firebase

```sh
firebase login
flutterfire configure --project=YOUR_PROJECT_ID
```

In Firebase Console:

1. Create a Cloud Firestore database.
2. Enable Email/Password authentication.
3. Enable Google and Anonymous authentication if you want those options.
4. Configure authorized web domains and the platform settings needed for Google sign-in.
5. Review the verification email template under **Authentication → Templates**. Email/password users receive a link at their registered address (including Gmail). They open the link, return to Pocket, and choose **I've verified my email**. The app offers resend with a 60-second cooldown and displays delivery-request errors.

The checked-in Firebase configuration identifies the original project. Generate your own configuration for a separate deployment.

```sh
firebase deploy --only firestore:rules --project=YOUR_PROJECT_ID
```

### 3. Run

```sh
flutter run -d chrome
```

For a device or emulator, use its actual ID:

```sh
flutter devices
flutter run -d DEVICE_ID
```

The repository includes web, Android, and iOS targets. Each needs Firebase configuration; building iOS requires macOS and Xcode.

### 4. Validate and build

```sh
flutter analyze
flutter test
flutter build web
```

Web output is written to `build/web`. Building does not automatically publish a hosted site.

## Architecture

```mermaid
flowchart LR
    UI[Flutter screens] --> State[Provider / ChangeNotifier]
    State --> Auth[Firebase Authentication]
    State --> Repository[Expense repository]
    Repository --> DB[Cloud Firestore]
    State --> Calendar[Nepali calendar service]
```

| Path | Responsibility |
| --- | --- |
| `lib/main.dart` | Startup and authentication routing |
| `lib/models/` | Transactions, calendar periods, and summaries |
| `lib/providers/` | Authentication, data streams, and state |
| `lib/screens/` | Dashboard, forms, reports, calendar, and settings |
| `lib/services/` | Calendar integration, account deletion, and expense repository |
| `lib/l10n/` | English and Nepali localization resources |
| `lib/theme.dart` | Shared visual styling |
| `firestore.rules` | Ownership and document validation |
| `test/` | Unit and widget tests |

Transactions live at `users/{userId}/expenses/{expenseId}`. Firestore rules require the authenticated user to own the path and validate document fields.

## Current limitations

- Calendar event coverage depends on the external source. Missing event data does not mean a date or transaction is missing.
- Email verification confirms ownership of the registered address; it is not multi-factor authentication. Delivery depends on Firebase email quotas and the recipient's spam filters.
- Guest access should not be treated as a durable account across devices.
- Account deletion removes transaction records and the user profile before the authentication account. Network requests time out after 20 seconds each and show an error; deletion is not atomic, so some records may already be removed if a later step fails. Pocket has no file uploads and does not contact Firebase Storage during normal account deletion.
- Platform folders alone do not establish that every authentication flow has been tested on every platform.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for checks and pull request guidance. Use the issue templates for reproducible bugs or feature suggestions. Do not include real financial records, passwords, or tokens in reports.

## Acknowledgments

Built with Flutter, Firebase, Provider, and `nepali_utils`. Calendar integration uses [bibhuticoder/nepali-calendar-api](https://github.com/bibhuticoder/nepali-calendar-api).

## License

[MIT](LICENSE).
