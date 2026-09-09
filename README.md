# OdoMate

OdoMate is a Flutter app for tracking rides, monitoring vehicle mileage, and
keeping service records in one place. It includes local persistence, ride
statistics, service reminders, notifications, profile settings, and Indonesian,
English, and Japanese localization.

## Features

- Start and stop ride tracking with odometer-based distance recording.
- Review ride history and open individual trip details.
- View statistics for today, the last seven days, or the current month.
- Manage service schedules, service history, and due-soon reminders.
- Configure vehicle and profile details, theme, and language.
- Store app data locally with SQLite.

## Requirements

- Flutter SDK with Dart 3.13.2 or newer.
- A connected Android/iOS device or emulator for `flutter run`.

## Getting Started

```bash
flutter pub get
flutter run
```

For a debug Android package:

```bash
flutter build apk --debug
```

## Quality Checks

Run static analysis, tests, and formatting before submitting changes:

```bash
flutter analyze
flutter test
dart format lib test
```

Focused tests can be run by path, for example:
`flutter test test/domain/ride_history_test.dart`.

## Project Layout

- `lib/src/screens/` — application screens and UI flows.
- `lib/src/domain/` — domain models and ride/service calculations.
- `lib/src/data/` — SQLite database and repository access.
- `lib/src/notifications/` and `lib/src/tracking/` — platform-facing services.
- `test/` — domain, data, navigation, and screen tests.
- `docs/superpowers/` — design specifications and implementation plans.

See [AGENTS.md](AGENTS.md) for contributor workflow, naming conventions, and
pull request expectations.
