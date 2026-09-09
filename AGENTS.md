# Repository Guidelines

## Project Structure & Module Organization

OdoMate is a Flutter application. Application entry and composition live in `lib/main.dart` and `lib/src/app.dart`. Feature screens are in `lib/src/screens/`; domain logic and models are in `lib/src/domain/`; persistence is in `lib/src/data/`; notifications, tracking, and localization are grouped under `lib/src/notifications/`, `lib/src/tracking/`, and `lib/src/i18n/`. Tests mirror these areas under `test/` (for example, `test/domain/` and `test/screens/`). Platform runners and permissions are under `android/`, `ios/`, and `web/`. Design specs and implementation plans belong in `docs/superpowers/`.

## Build, Test, and Development Commands

Run these from the repository root:

```text
flutter pub get                    # Install or refresh dependencies
flutter run                        # Run the app on a connected device/emulator
flutter analyze                    # Run Dart/Flutter static analysis
flutter test                       # Run the complete test suite
flutter build apk --debug          # Build an Android debug APK
dart format lib test               # Format source and tests
```

Use a focused test path while iterating, such as `flutter test test/domain/ride_history_test.dart`.

## Coding Style & Naming Conventions

Follow `flutter_lints` from `analysis_options.yaml` and use four-space indentation. Use `snake_case.dart` filenames, `PascalCase` for classes/enums, `camelCase` for variables and methods, and private members prefixed with `_`. Keep UI in screens/widgets, business rules in domain code, and database access in the repository layer.

## Testing Guidelines

Add or update `flutter_test` tests for behavior changes. Name files `<subject>_test.dart`, grouping domain, data, and screen tests in their corresponding directories. Run `flutter analyze` and the relevant tests before opening a PR; run the full suite for cross-cutting changes.

## Commit & Pull Request Guidelines

Use short, imperative Conventional Commit-style subjects such as `feat: add ride history` or `fix: handle empty statistics`. Keep commits focused. PRs should explain the behavior change, link the relevant issue or plan when applicable, list validation commands and results, and include emulator screenshots or recordings for UI changes. Do not include generated build output or unrelated work.

## Security & Configuration Tips

Do not commit secrets, local databases, or generated artifacts. Changes involving location, notifications, camera, or platform permissions must be checked in the affected platform manifests and tested on a real or emulated device.
