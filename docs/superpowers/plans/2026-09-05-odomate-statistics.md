# OdoMate Statistics & Ride Insights Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a local Statistics screen that summarizes ride distance, ride count, average distance, total vehicle distance, and current service status.

**Architecture:** Keep aggregation in a pure Dart `RideStatistics` value object/service so date-window rules are testable without Flutter. The repository supplies rides and services; the screen renders the computed summary with existing Material 3 and localization infrastructure. No new chart package, database table, or state-management dependency is needed.

**Tech Stack:** Flutter/Dart, existing `sqflite` repository, Material 3, existing custom `AppLocalizations`.

**Spec:** `docs/superpowers/specs/2026-09-05-odomate-statistics-design.md`

## Global Constraints

- Local-only data; no backend, account, cloud sync, or new database table.
- Use local device dates from `Ride.startedAt.toLocal()`.
- Supported periods are exactly today, last 7 days, and current month.
- Use one decimal place for kilometer values.
- Do not add a chart dependency; use cards and numeric summaries.
- Preserve the existing bottom navigation and circular ride action.
- All new user-facing copy must use `AppLocalizations` for Indonesian, English, and Japanese.

### Task 1: Add pure ride statistics rules

**Files:**
- Create: `lib/src/domain/ride_statistics.dart`
- Test: `test/domain/ride_statistics_test.dart`

**Interfaces:**
- `enum StatisticsPeriod { today, lastSevenDays, currentMonth }`
- `class RideStatistics { final double totalDistanceKm; final int rideCount; final double averageDistanceKm; }`
- `RideStatistics calculateRideStatistics(List<Ride> rides, DateTime now, StatisticsPeriod period)`

- [ ] Write tests for today, seven-day, and current-month inclusion boundaries using local `DateTime` values.
- [ ] Write a test proving zero-distance rides count but average remains safe when no rides exist.
- [ ] Run `flutter test test/domain/ride_statistics_test.dart`; verify it fails because the calculator does not exist.
- [ ] Implement the enum, value object, and pure calculator using inclusive start/exclusive end boundaries.
- [ ] Run the focused test and verify it passes.
- [ ] Commit the domain calculator and tests.

### Task 2: Add repository-facing summary data

**Files:**
- Modify: `lib/src/data/odomate_repository.dart`
- Test: `test/data/odomate_repository_test.dart`

**Interfaces:**
- `Future<List<Ride>> listRides()` remains the source of ride data.
- `Future<List<ServiceItem>> listServices()` remains the source of service data.
- Add no new persistence API unless the implementation needs a single in-memory summary method.

- [ ] Add a repository test proving stored rides can be consumed for statistics after reopening the repository.
- [ ] Run the focused repository test and verify failure only if a new helper is required.
- [ ] Prefer reusing existing `listRides` and `listServices`; do not add SQL aggregation prematurely.
- [ ] Run all repository tests and verify they pass.

### Task 3: Build the Statistics screen

**Files:**
- Create: `lib/src/screens/statistics_screen.dart`
- Modify: `lib/src/i18n/app_localizations.dart`
- Test: `test/screens/statistics_screen_test.dart`

- [ ] Add localization keys for the page title, period labels, distance, ride count, average, total vehicle distance, service summary, and empty state in ID/EN/JA.
- [ ] Write widget tests for the default seven-day period, period switching, empty rides, and one populated ride set.
- [ ] Run the focused widget test and verify the expected failure before implementation.
- [ ] Implement a `FutureBuilder` or equivalent local state load that reads vehicle, rides, and services from the repository.
- [ ] Render period selector, numeric cards, total vehicle distance, and service status summary.
- [ ] Use `ServiceSchedule.status` to count due/due-soon services and identify the nearest item.
- [ ] Render a stable empty state when no rides exist.
- [ ] Run the focused widget tests and verify they pass.

### Task 4: Integrate Home and navigation

**Files:**
- Modify: `lib/src/screens/home_screen.dart`
- Modify: `lib/src/app.dart`
- Test: `test/screens/navigation_test.dart` or `test/screens/statistics_navigation_test.dart`

- [ ] Add a localized Home card showing the default seven-day distance and ride count.
- [ ] Add a navigation callback/index for Statistics without moving or duplicating the Start Ride FAB.
- [ ] Add Statistics as a bottom-navigation destination while preserving Home, History, Service, and Profile labels/order; use the existing shell pattern and avoid a second global navigator key.
- [ ] Write a widget test proving the card opens Statistics and the ride action remains present.
- [ ] Run all screen tests and verify they pass.

### Task 5: Full verification and handoff

- [ ] Run `dart format lib test`.
- [ ] Run `flutter analyze` and fix all errors/warnings introduced by the feature.
- [ ] Run `flutter test` and verify all tests pass.
- [ ] Run `git diff --check`.
- [ ] Run `flutter build apk --debug`.
- [ ] Manually verify empty state, each period, localization, theme light/dark, and Home navigation on the emulator.
- [ ] Commit the completed Statistics feature with a Conventional Commit message.
