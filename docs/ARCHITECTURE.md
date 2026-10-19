# 🏗️ Pocket Architecture Documentation

This document describes the architectural patterns, layers, data flow, and state management used throughout **Pocket**.

---

## 🏛️ High-Level Architectural Pattern

Pocket follows **Clean Architecture** principles to ensure loose coupling, high testability, and clear separation of concerns:

```
┌────────────────────────────────────────────────────────┐
│                   Presentation Layer                   │
│   (Screens, Widgets, ViewModels, Providers, Dialogs)   │
└───────────────────────────┬────────────────────────────┘
                            │
┌───────────────────────────▼────────────────────────────┐
│                      Domain Layer                      │
│   (Entities, Value Objects, Use Cases, Interfaces)     │
└───────────────────────────┬────────────────────────────┘
                            │
┌───────────────────────────▼────────────────────────────┐
│                       Data Layer                       │
│ (Repositories, Local DB SQLite, Firebase Cloud Client) │
└────────────────────────────────────────────────────────┘
```

---

## 📁 Directory Structure

- **`lib/models/`**: Domain entities representing expenses, incomes, categories, and calendar periods.
- **`lib/providers/`**: State management powered by `ChangeNotifier` / `Provider`, holding presentation state and notifying listeners.
- **`lib/repositories/`**: Repository layer abstracting persistence, handling offline caching via SQLite and remote synchronization via Cloud Firestore.
- **`lib/services/`**: Infrastructure utilities such as SMS parsing, calendar conversion (Bikram Sambat वि.सं. / Gregorian AD), and export/import helpers.
- **`lib/screens/`**: UI screens built with responsive layouts and Material 3 design specifications.
- **`lib/widgets/`**: Reusable component library including custom charts, cards, buttons, and form inputs.

---

## 🧪 Testing Strategy

Pocket maintains a robust automated testing suite with over 96 tests covering:
1. **Unit Tests**: Domain entities, parsers, calendar calculations, and validators.
2. **Provider Tests**: State transitions, filters, and computed metrics.
3. **Widget Tests**: Localization rendering, dialog interactions, and theme adaptivity.

