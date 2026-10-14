# Pocket — Personal Expense Tracker

<p align="center">
  <img src="web/icons/Icon-192.png" alt="Pocket Logo" width="100" height="100" />
</p>

<p align="center">
  <strong>Small habits. Smarter spending.</strong><br>
  A modern, responsive, and privacy-focused cross-platform expense tracker built with Flutter, Provider, Firebase Authentication, Cloud Firestore, and Bikram Sambat (BS) Nepali Calendar integration.
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
- ⚡ **Real-Time Cloud Sync**: Powered by Cloud Firestore — per-user isolated subcollections with reactive UI updates.
- 🇳🇵 **Dual Calendar (AD & BS)**: Full Bikram Sambat (Nepali calendar) support with real month boundaries, BS date picker, and lunar calendar integration (tithi, events & holidays).
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
├── firebase_options.dart        # Platform Firebase configuration (FlutterFire CLI)
├── main.dart                    # App bootstrap, Material 3 theme & AuthGate
├── theme.dart                   # Color schemes, typography & component themes
├── models/
│   ├── calendar_period.dart     # AD & BS calendar period computations & boundaries
│   ├── expense.dart             # Expense entity, category definitions & currency parser
│   └── spending_story.dart      # Journal computation models (calendar, recurrence, scenarios)
├── providers/
│   ├── auth_provider.dart       # Authentication state and user session management
│   ├── calendar_provider.dart   # Nepali lunar calendar API state & memory caching
│   └── expense_provider.dart    # Firestore streams, CRUD actions, search & filters
├── screens/
│   ├── auth_screen.dart         # Sign in, account registration & password recovery
│   ├── calendar_details.dart    # Lunar calendar event details modal
│   ├── dashboard.dart           # Main view: Overview, Transactions & Insights navigation
│   ├── expense_editor.dart      # Add/Edit expense dialog with form validation
│   ├── nepali_picker.dart       # Custom Bikram Sambat date picker dialog
│   └── spending_stories.dart    # Pocket Journal & What-If Studio interface
└── services/
    └── nepali_calendar_api.dart # Multi-source resilient Nepali calendar REST client
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

## 📅 Nepali Calendar & Lunar API Integration

Public calendar details are fetched with automatic fallback handling across multiple sources:
- **Primary Source**: `https://raw.githubusercontent.com/sajanm/nepali-lunar-calendar-events/master/{YEAR}.json`
- **Fallback Sources**: `https://the-value-crew.github.io/nepali-calendar-api/` and `https://bibhuticoder.github.io/nepali-calendar-api/`

In BS mode, selecting a day under Insights or in the date picker surfaces published tithi, events, and holidays.
Responses are cached in memory (up to 24 months), with automatic request deduplication and a 10-second timeout.

To check representative live endpoints:
```bash
dart run tool/check_calendar_api.dart
```

---

## 🧪 Testing & Quality Assurance

Pocket maintains unit, widget, and integration tests covering business logic, financial arithmetic, responsive layouts, and calendar integrations:

```bash
# Verify code formatting
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
