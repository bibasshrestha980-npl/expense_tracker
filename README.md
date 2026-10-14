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

The separate Firebase project `pocket-exp-2610142142` (Pocket Expense Tracker) and Android, iOS, and web registrations are configured. The free-tier Firestore database in asia-south1 is created and the security rules are deployed.

Open https://console.firebase.google.com/project/pocket-exp-2610142142/authentication
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

## Calendar API integration

Public calendar details are fetched from the requested source:
https://bibhuticoder.github.io/nepali-calendar-api/api/{BS_YEAR}.json

The repository is deprecated. When its requested month is missing or the request fails, the app tries the successor linked by that repository:
https://the-value-crew.github.io/nepali-calendar-api/data/{BS_YEAR}/{MONTH}.json

In BS mode, select a day under Insights or in the expense date picker to see published tithi, events and holidays. Each result names its source. Missing records remain explicitly unavailable; they are not treated as confirmed non-holidays. The API augments date conversion and never changes expense timestamps or totals. No expense details or Firebase tokens are sent. Requests contain only public year/month paths.

Successful month responses are cached in memory (up to 24 months); concurrent matching requests are shared. Each request times out after 10 seconds. Missing-data and request-error states provide retry controls. Devanagari digits, blank calendar padding, original and successor JSON formats are supported.

Live checks on 2026-10-14: the original 2073 endpoint and successor 2076/2 endpoint respond; both sources return 404 for 2083/6. Those two archive sources cannot supply current-month details; the current-data source below now covers this gap. The offline BS calendar remains usable.

Run `dart run tool/check_calendar_api.dart` to check representative live endpoints. Mock HTTP tests cover parsing, fallback, caching, missing years and retry after malformed data.


## Fix: current BS calendar data (2083/6)

Recent years now try https://raw.githubusercontent.com/sajanm/nepali-lunar-calendar-events/master/{YEAR}.json first. Both nested month arrays and flat year arrays are supported. Records are selected by their explicit BS year/month; blank event markers are not displayed. Original APIs remain archival fallbacks. The source is shown on screen.

Live verification: 2083/6 returns 31 days, including tithi and events, and the endpoint allows browser cross-origin access. All 13 tests pass. Restart the running Flutter app (or reload a newly deployed web build) to use the updated source. Public source data is displayed as provided, not official holiday certification.

## Add money and income tracking

The Add money button appears beside Add expense on every main screen. Record Salary, Freelance, Allowance, Gift, Refund, Opening balance or Other income. Use Opening balance once for funds already held when starting your ledger; do not add the same funds again as salary.

Overview shows Recorded balance (all recorded income minus all recorded expenses), Money in and Money out for the selected AD/BS month, and monthly net. This is a manual personal ledger, not a bank-linked balance or payment/top-up service. Negative balances are shown when recorded spending exceeds recorded income.

Transactions includes income and expenses, signed amounts, type/category filters, editing, deletion, and a Type column in CSV. Spending charts and Pocket Journal continue to use expenses only. Existing documents without a type field are treated as expenses. Firestore rules now validate transaction type and matching categories; these updated rules were deployed to pocket-expenses-bibas-261014.

Income tests cover form saving, exact paisa amounts, legacy records, balance calculations, excluding income from spending charts, filtering, income edits, and deletion using a fake Firestore database. Production authenticated CRUD was not exercised by those tests.

## SIP (Systematic Investment Plan) tracking

The app includes dedicated mutual fund & investment tracking accessible via the **SIPs** tab in the main navigation.

- **Portfolio overview**: Total monthly commitment, total invested to date, and estimated current corpus value.
- **Scheme management**: Add, edit, pause, and delete SIP plans with custom scheme names, monthly installment amount, expected annual return rate (%), monthly debit day, and start date.
- **One-click expense logging**: Log any recurring monthly SIP installment directly into your expense ledger under the `Investment` category with a single tap.
- **Compound growth calculator**: Interactive wealth projection calculator estimating total invested capital, estimated returns, and total future value based on monthly contribution, expected CAGR, and investment horizon (years).
- **Firestore security rules**: Stored under `/users/{userId}/sips/{sipId}` with strict field-level validation and owner-only access.

## Share & export monthly financial reports

Access the comprehensive financial summary modal directly from the app bar via the **Share Report** button (`Icons.summarize_outlined`).

- **Executive breakdown**: Shows monthly income, expenses, net savings, and savings rate percentage for the selected month (AD or BS calendar).
- **Category allocation**: Visual progress bars showing spend distribution across categories with percentage shares.
- **1-Click Share Summary**: Formats a clean, readable financial snapshot with emojis and amounts ready to copy to clipboard for WhatsApp, email, or messaging.
- **CSV export**: Export your complete monthly ledger as a `.csv` spreadsheet for record keeping.

## Dual BS (Bikram Sambat) and AD calendar display

The app defaults to Nepali (BS) as its primary calendar system while maintaining full dual display of both BS and AD:

- **BS-first defaults**: App launches into Nepali (BS) mode with BS positioned first on all calendar toggles.
- **Dual date representations**: Transaction history, month selector, expense editor, Nepali date picker, SIP schemes, and financial reports display the Nepali BS date first, followed by the English AD date (e.g., `Asoj 28, 2083 BS (Oct 14, 2026 AD)`).
- **Synchronized conversions**: Accurate bidirectional date conversion between Bikram Sambat and Gregorian calendars preserving leap years and official Nepali month day lengths.

