# Pocket 👛

A clean, fast, no-nonsense personal expense and income tracker built with Flutter and Firebase.

Designed for everyday personal finance tracking — log daily expenses, manage income streams, review monthly category breakdowns, and export clean financial summaries.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore-FFCA28?logo=firebase)](https://firebase.google.com)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-4CAF50)](#)

---

## Preview

<!-- Replace with your app screenshots -->
```
┌────────────────────────────────────────────────────────┐
│                                                        │
│            [ App Screenshot / Demo GIF ]               │
│                                                        │
└────────────────────────────────────────────────────────┘
```
*(Add your screenshot to `assets/screenshots/` and update this section)*

---

## Features

- **Income & Expense Tracking**: Record money in (Salary, Freelance, Allowance, Opening balance) and daily spending across categorized tags with notes.
- **Monthly Analytics & Insights**: Daily spending charts, ranked category breakdowns, savings rate percentages, and previous-month comparisons.
- **Dual Calendar System (BS & AD)**: Native Bikram Sambat (Nepali calendar) support with bidirectional AD/BS date conversion and tithi/event data.
- **Shareable Financial Reports**: 1-click executive snapshot formatted for messaging (WhatsApp, Telegram) plus full CSV spreadsheet export.
- **Multi-Provider Auth & Two-Step Verification**: Sign in with Email/Password, Google, or Anonymous Guest access, protected by a 6-digit verification code gate.
- **Paisa-Exact Accuracy**: Stored and calculated in integer cents (paisa) to eliminate floating-point rounding errors.
- **Cross-Platform**: Single codebase runs responsively on Android, iOS, and Web (desktop & mobile).

---

## Architecture Overview

State management is handled with `provider`, and data persistence uses Cloud Firestore with owner-only security rules.

```
lib/
├── main.dart                 # App entrypoint, theme, and authentication gate
├── firebase_options.dart     # Auto-generated Firebase platform configs
├── theme.dart                # Material 3 design tokens and color scheme
├── models/
│   ├── expense.dart          # Transaction data model & exact paisa parser
│   └── calendar_period.dart  # Bikram Sambat (BS) / Gregorian (AD) period logic
├── providers/
│   ├── auth_provider.dart    # Firebase Auth, Google/Guest sign-in, and 2FA state
│   └── expense_provider.dart # Real-time Firestore stream, filters, and totals
└── screens/
    ├── auth_screen.dart      # Login, registration, Google & Guest sign-in
    ├── verify_code_screen.dart # 6-digit two-step verification screen
    ├── dashboard.dart        # Main hub: Overview, Transactions, Insights
    ├── expense_editor.dart   # Add/edit transaction modal form
    ├── report_dialog.dart    # Monthly financial summary & CSV export
    └── spending_stories.dart # Monthly journal, daily calendar, and scenario studio
```

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`^3.13.0` or higher)
- [Firebase CLI](https://firebase.google.com/docs/cli) & [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/)
- Android Studio, Xcode (macOS), or Chrome for web preview

### 1. Clone the repository

```bash
git clone https://github.com/bibasshrestha980-npl/expense_tracker.git
cd expense_tracker
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Set up Firebase

1. Create a project in the [Firebase Console](https://console.firebase.google.com/).
2. Link your Flutter app with FlutterFire CLI:
   ```bash
   flutterfire configure
   ```
3. In **Firebase Console > Authentication > Sign-in method**, enable:
   - **Email/Password**
   - **Google**
   - **Anonymous**
4. Deploy the Firestore security rules:
   ```bash
   firebase deploy --only firestore:rules
   ```

### 4. Run the app

```bash
# Run in Chrome
flutter run -d chrome

# Run on Android device / emulator
flutter run -d android

# Run on iOS simulator (macOS only)
flutter run -d ios
```

---

## Running Tests

Run the full automated widget and unit test suite:

```bash
flutter test
```

Run static analysis:

```bash
flutter analyze
```

---

## Security Rules

Firestore data is isolated per authenticated user at path `users/{userId}/expenses/{expenseId}`. Deployed rules enforce:
- Authenticated user ID must match the document path (`request.auth.uid == userId`).
- Strict schema validation for transaction fields, string limits, and valid category types.

---

## License

This project is open-source under the [MIT License](LICENSE).
