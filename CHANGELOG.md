# Changelog

All notable changes to the **Pocket (Expense Tracker)** project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2026-10-18

### Added
- Comprehensive test suite with 96+ automated unit and widget tests.
- Offline-first SQLite local caching alongside Firebase Cloud Firestore synchronization.
- Bundled `MaterialIcons-Regular.otf` font for clean cross-platform icon rendering on Flutter Web.
- Bilingual localization supporting English and Nepali (नेपाली).
- Automated SMS and digital wallet transaction parser supporting eSewa, Khalti, and Fonepay.

### Fixed
- Resolved Flutter Web startup crash caused by unsupported `Platform.environment` calls on web browsers.
- Fixed square glyph box `[X]` artifacts on browser canvas by registering fallback Material Icon font asset.

### Changed
- Refactored project architecture to follow Clean Architecture with domain, data, and presentation boundaries.
- Streamlined settings and data export utilities.

## [1.1.0] - 2026-10-14

### Added
- Bikram Sambat (वि.सं.) Nepali calendar integration with bilingual month view.
- Real-time spending distribution and net balance charts.
- Dark, light, and system adaptive theme switching.

## [1.0.0] - 2026-08-30

### Added
- Initial public release of Pocket expense tracker.
- Cloud Firestore authentication and security rules.
- Category-based income and expense logging.
