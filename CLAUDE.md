# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

OdoMate is an offline-first Flutter app for tracking motorcycle rides, mileage, and
service records. All state is local SQLite; there is no backend or network layer.
`README.md` covers features and `AGENTS.md` covers naming, commit, and PR conventions.

## Commands

```bash
flutter pub get
flutter run                          # needs a connected Android/iOS device
flutter analyze
flutter test
flutter test test/domain/ride_history_test.dart   # focused
dart format lib test
flutter build apk --debug
```

There is no code generation step (no `build_runner`/`freezed`). Models in
`lib/src/domain/models.dart` are hand-written with `copyWith`. `analysis_options.yaml`
uses `flutter_lints` and excludes the platform directories.

This project is developed on Windows, so iOS builds and iOS-only notification paths
are not verifiable locally; Android is the practical target for `flutter run`.

## Architecture

Data flows one way through four layers, all constructed by hand in `lib/main.dart`:

```
main.dart  →  OdomateRepository  (SQLite)
           →  NotificationService
           →  RideTracker  →  OdoMateApp  →  screens
```

**Manual dependency injection — no Provider/Riverpod/Bloc.** `main.dart` builds the
three services and passes them into `OdoMateApp`, which passes `repository` (and
sometimes `tracker`) down to each screen via constructor. Theme and language live as
plain `setState` fields in `_OdoMateAppState`. When adding cross-screen state, follow
this same pattern rather than introducing a state-management package.

**Platform code is injected, not mocked.** Every class that touches a plugin takes
optional overrides so tests can avoid the platform channel — no mockito anywhere:

- `OdomateRepository(databaseFactory:)` — tests pass a `sqflite_common_ffi` factory
  (see `test/data/odomate_repository_test.dart`), or subclass the repository and
  override methods (see `_FakeRepository` in `test/screens/navigation_test.dart`).
- `RideTracker(…, positionStream, locationServiceEnabled, checkPermission, requestPermission)`
- `NotificationService(…, plugin, initializePlugin, requestNotificationsPermission, cancelTrackingNotification)`

Add a new platform dependency as a constructor override in this style.

### The odometer invariant

The vehicle odometer is *not* derived from rides — it is incremented by deltas, and
`rides.odometer_applied_km` records how much of a ride has already been applied. Two
methods maintain this in `odomate_repository.dart`:

- `saveActiveRideCheckpoint` — called on every accepted GPS point mid-ride; adds only
  the increment since the last checkpoint.
- `finishRide` — adds only `distanceKm - odometer_applied_km`, the remainder.

This split is what makes a crash, app kill, or `restore()` mid-ride safe: the vehicle
odometer never double-counts distance from a resumed ride. Any change to odometer
accounting must preserve that, and the test database schema must include
`odometer_applied_km` for these paths to run.

### Domain layer is pure

`lib/src/domain/` has no Flutter imports and holds the testable business rules:
`OdometerMath.acceptPoint` (haversine distance with 50 m accuracy and 500 m
teleport filters), `ServiceSchedule.status`/`reminderType`, `filterRides`,
`calculateRideStatistics`. Put new rules here and test them under `test/domain/`
rather than inside a screen or the tracker.

`ServiceSchedule.reminderType` returns `null` when the computed reminder equals the
persisted `NotificationState.lastReminder`, so each service reminder fires once per
state transition. The state is stored in the `notification_state` table.

### Database schema changes

`local_database.dart` runs `_ensureColumns` from both `onOpen` and `onUpgrade`, using
`PRAGMA table_info` to add missing columns idempotently. To add a column: bump
`version` in `open()`, add the `ALTER TABLE` guard to `_ensureColumns`, and add it to
`_create`. Note that `test/data/odomate_repository_test.dart` hand-rolls its own schema
and must be updated in step manually.

### Tracking

`RideTracker` owns a `ValueNotifier<RideTrackingState>` that `MainNavigation`'s
center FAB listens to. `restore()` runs at startup and resumes any ride with
`ended_at IS NULL`. On Android the ongoing-ride notification is owned by Geolocator's
`foregroundNotificationConfig`, so `NotificationService.showTrackingActive` returns
early there and only does work on iOS.

### Localization and design system

`AppLocalizations.t(key)` looks up a flat `Map` keyed by `id`/`en`/`ja`, falling back
to Indonesian and then to the key itself. Indonesian is the default locale. Some
user-facing strings (tracker errors, notification titles) are still hardcoded
Indonesian in code rather than routed through `t()`.

`stitch_odomate_modern_ui/odomate_modern_utility/DESIGN.md` is the source of truth for
the palette, radii, and Poppins weights (400/500/600/700/800, all bundled in
`pubspec.yaml`). `_theme()` in `lib/src/app.dart` implements it with explicit hex
values per brightness rather than relying only on `ColorScheme.fromSeed`. Consult
DESIGN.md before restyling; the output directories beside it are generated design
references.

## Docs workflow

Design specs and implementation plans live in `docs/superpowers/specs/` and
`docs/superpowers/plans/` (dated `<date>-<feature>.md`). Per-task briefs, reports, and
reviews from spec-driven development runs are under `.superpowers/sdd/<feature>/`.
Write a spec before implementing a non-trivial feature, matching the existing
`-design.md` structure.
