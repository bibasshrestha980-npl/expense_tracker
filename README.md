# Pocket — Personal Expense Tracker

<p align="center">
  <img src="web/icons/Icon-192.png" alt="Pocket Logo" width="100" height="100" />
</p>

<p align="center">
  <strong>Small habits. Smarter spending.</strong><br>
  A modern, responsive, and privacy-focused cross-platform expense tracker built with Flutter, Provider, Firebase Authentication, and Cloud Firestore.
</p>

<p align="center">
  <a href="https://github.com/bibasshrestha980-npl/expense_tracker/actions/workflows/ci.yml"><img src="https://github.com/bibasshrestha980-npl/expense_tracker/actions/workflows/ci.yml/badge.svg" alt="CI Status" /></a>
  <img src="https://img.shields.io/badge/Flutter-3.47+-02569B?logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.13+-0175C2?logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore-FFCA28?logo=firebase&logoColor=black" alt="Firebase" />
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-4CAF50" alt="Platforms" />
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License: MIT" /></a>
</p>

---

## ✨ Features

- 🔐 **Secure Authentication**: Email & password authentication with input validation, session management, and password reset.
- ⚡ **Real-Time Cloud Sync**: Powered by Cloud Firestore — changes synchronize instantaneously with reactive UI updates.
- 📊 **Spending Analytics**:
  - Monthly budget tracking with interactive month-by-month navigation.
  - Ranked category breakdowns with proportional progress indicators.
  - Average transaction size and comparisons against previous months.
- 📖 **The Pocket Journal**:
  - Interactive daily calendar view highlighting spending hotspots.
  - Automatic detection of repeated expense titles.
  - **What-If Studio**: In-memory financial simulator to test spending adjustments without modifying actual records.
- 💰 **Zero Rounding Errors**: All currency amounts are stored and computed in integer cents/paisa, eliminating floating-point inaccuracies.
- 📱 **Adaptive Material 3 Design**: Responsive layout that transitions between a compact bottom navigation bar on mobile and a comfortable sidebar on desktop/web.
- 📤 **Data Export**: Export filtered transactions directly to CSV for spreadsheet analysis.

---

## 🛠️ Architecture & Tech Stack

```
lib/
├── firebase_options.dart      # Platform Firebase configuration (FlutterFire CLI)
├── main.dart                  # App bootstrap, Material 3 theme & AuthGate
├── theme.dart                 # Color schemes, typography & component themes
├── models/
│   ├── expense.dart           # Expense entity, category definitions & currency parser
│   └── spending_story.dart    # Journal computation models (calendar, recurrence, scenarios)
├── providers/
│   ├── auth_provider.dart     # Authentication state and user session management
│   └── expense_provider.dart  # Firestore streams, CRUD actions, search & filters
└── screens/
    ├── auth_screen.dart       # Sign in, account registration & password recovery
    ├── dashboard.dart         # Main view: Overview, Transactions & Insights navigation
    ├── expense_editor.dart    # Add/Edit expense dialog with form validation
    └── spending_stories.dart  # Pocket Journal & What-If Studio interface
```

### Core Technologies
- **Framework**: [Flutter](https://flutter.dev/) (Channel Stable)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Backend**: [Firebase Authentication](https://firebase.google.com/docs/auth) & [Cloud Firestore](https://firebase.google.com/docs/firestore)
- **Design System**: Material Design 3

---

## 🚀 Getting Started

### Prerequisites

Ensure you have the following installed on your machine:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`^3.13.0` or higher)
- [Git](https://git-scm.com/)
- [Firebase CLI](https://firebase.google.com/docs/cli) (optional, for cloud reconfiguration)

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/bibasshrestha980-npl/expense_tracker.git
   cd expense_tracker
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the application**:
   - **Web (Chrome)**:
     ```bash
     flutter run -d chrome
     ```
   - **Android / iOS**:
     Connect a device or launch an emulator, then execute:
     ```bash
     flutter run
     ```

---

## 🔒 Security & Firestore Rules

User data is secured at the database layer using rules defined in `firestore.rules`. Each user can only read, write, and delete expenses within their own isolated subcollection (`/users/{userId}/expenses/{expenseId}`):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/expenses/{expenseId} {
      function owner() { return request.auth != null && request.auth.uid == userId; }
      function valid() {
        let d = request.resource.data;
        return d.keys().hasAll(['title', 'category', 'amountCents', 'date', 'note'])
          && d.keys().hasOnly(['title', 'category', 'amountCents', 'date', 'note'])
          && d.title is string && d.title.size() > 0 && d.title.size() <= 80
          && d.category in ['Food', 'Transport', 'Shopping', 'Bills', 'Health', 'Education', 'Other']
          && d.amountCents is int && d.amountCents > 0 && d.amountCents <= 99999999999
          && d.date is timestamp && d.note is string && d.note.size() <= 300;
      }
      allow read, delete: if owner();
      allow create, update: if owner() && valid();
    }
  }
}
```

---

## 🧪 Testing & Quality Assurance

Pocket maintains a comprehensive suite of unit and widget tests covering business logic, financial calculations, and responsive layouts:

```bash
# Verify formatting
dart format --output=none --set-exit-if-changed .

# Run static analysis
flutter analyze

# Execute all tests
flutter test
```

---

## 🤝 Contributing

Contributions, issues, and feature suggestions are welcome! Please check the [Contributing Guidelines](CONTRIBUTING.md) before submitting pull requests.

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

## Nepali calendar

Use English (AD) / Nepali (BS) above the month selector. BS mode uses real Bikram Sambat month boundaries for totals, transactions, category summaries, charts and the Pocket Journal. Nepali calendar weeks begin on Sunday. Expense forms provide both AD and BS date pickers and display both dates. The BS picker supports year/month selection and prevents future dates. Firestore timestamps remain unchanged; no migration is needed. CSV dates remain ISO Gregorian dates for spreadsheet compatibility.

Calendar conversion uses nepali_utils month data with civil-date arithmetic to avoid historical Windows timezone differences. Package documentation: https://pub.dev/packages/nepali_utils
