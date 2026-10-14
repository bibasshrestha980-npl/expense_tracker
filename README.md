# Pocket - Expense Tracker

Final project built with Flutter, Provider, Firebase Authentication, and Cloud Firestore.

## Run

```powershell
cd C:\Users\BIBAS\Desktop\expense_tracker
flutter pub get
flutter run -d chrome
```

For Android, start an emulator or connect a phone with USB debugging and run `flutter run`. iOS builds require macOS and Xcode.

## One remaining Firebase console step

The separate Firebase project `pocket-expenses-bibas-261014` and Android, iOS, and web registrations are configured. The free-tier Firestore database in asia-south1 is created and the security rules are deployed.

Open https://console.firebase.google.com/project/pocket-expenses-bibas-261014/authentication
Select Get started, then Sign-in method > Email/Password > Enable > Save. Use ordinary Firebase Authentication; no paid Identity Platform upgrade is needed for this app. Authentication could not be enabled automatically because the admin initialization endpoint required billing and browser automation was unavailable.

Then create an account from the app. No demo credentials are included.

## Features

- Email/password registration, login, logout, and password reset.
- Live per-user expense storage with add, edit, and confirmed delete.
- Monthly totals and category spending breakdowns.
- Search by title/note and filter by category and month.
- NPR currency; amounts stored as integer paisa to avoid floating-point errors.
- Validated forms, loading indicators, empty states, and error messages.
- Responsive Material 3 interface.

## Structure

- lib/main.dart: Firebase initialization, theme, authentication gate.
- lib/models/expense.dart: expense model and exact currency parsing.
- lib/providers/auth_provider.dart: authentication state and operations.
- lib/providers/expense_provider.dart: Firestore subscription, CRUD, totals and filters.
- lib/screens/: authentication, dashboard and expense editor.
- lib/firebase_options.dart: generated platform configuration.
- firestore.rules: owner-only access with field validation.
- test/expense_test.dart: amount validation and startup error-screen tests.

Firestore path: users/{uid}/expenses/{expenseId}. The auth UID scopes all reads and writes, enforced by deployed rules. Provider subscriptions are disposed on logout/account changes.

## Verification

Passed: flutter analyze, flutter test (2 tests), flutter build web.
Live signup/login and authenticated CRUD still need verification after enabling Email/Password in the console. Android and iOS builds were not tested.

Suggested demonstration: register, add two expenses, edit one, filter by category, browse months, delete an expense, sign out, then sign in to confirm persistence. A second account should see only its own expenses.

## Reconfigure for another Firebase project

Run `flutterfire configure --project=YOUR_PROJECT_ID --platforms=android,ios,web`, create Firestore, enable Email/Password, and deploy rules with `firebase deploy --only firestore:rules --project=YOUR_PROJECT_ID`.

Official setup reference: https://firebase.google.com/docs/flutter/setup

## Professional interface update

The app now offers Overview, Transactions and Insights navigation, a desktop sidebar and mobile navigation bar, daily spending charts, ranked category breakdowns, average transaction amount, previous-month comparisons, amount/date sorting, and copying filtered transactions as CSV. The forms have clearer currency entry, category icons, password confirmation, and save/delete feedback. Layout/navigation tests cover 360px and 1440px screens.

Firebase Email/Password enablement remains the console step described above; live authentication and Firestore CRUD were not verified in this update.

## Pocket Journal

Open Insights to use the Pocket Journal: a summary of the largest spending category, a calendar with daily expense details, repeated-title purchase groups, and an interactive What-if Studio. The studio changes only an in-memory scenario; it never modifies stored expenses. Calculations use recorded transactions, with no external AI service. Missing entries do not establish no-spend days, and matching titles do not establish subscriptions.

Verification for this update: Flutter analysis and all 6 tests passed, including phone/desktop layouts, calendar interaction, scenario reset, and calculation edge cases.
