# OdoMate MVP Implementation Plan

> For agentic workers: REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox syntax for tracking.

Goal: Build a single-motor Flutter app that tracks rides from background GPS, updates a local odometer, records service history, and sends local service reminders.

Architecture: Offline-first SQLite storage, pure Dart rules for GPS distance and service status, and one tracking coordinator around geolocator. Use Flutter ValueNotifier/ChangeNotifier; no extra state-management package or backend. Configure Android foreground location and iOS background location.

Tech Stack: Flutter/Dart, geolocator, sqflite, path, flutter_local_notifications, sqflite_common_ffi for database tests, Flutter Material widgets.

Spec: docs/superpowers/specs/2026-09-05-odomate-mvp-design.md

## Global Constraints

- Local-only data; no account, backend, cloud sync, route map, or multi-vehicle support.
- One vehicle record and one active ride maximum.
- GPS distance uses accepted valid points only; signal loss adds no distance.
- Tracking continues with screen off or another app foregrounded while a ride is active.
- Service reminders trigger 200 km before due and at due/overdue, once per service cycle.
- Manual odometer correction must not create a ride or service log.
- User-facing copy is Indonesian and uses Start Ride, Stop Ride, Servis mendekat, and Sudah waktunya servis.

## File Map

- Modify pubspec.yaml, AndroidManifest.xml, Info.plist, and lib/main.dart.
- Create lib/src/domain/models.dart, odometer.dart, and service_schedule.dart.
- Create lib/src/data/local_database.dart and odomate_repository.dart.
- Create lib/src/tracking/ride_tracker.dart.
- Create lib/src/notifications/notification_service.dart.
- Create lib/src/app.dart and screens/setup_screen.dart, home_screen.dart, services_screen.dart, history_screen.dart.
- Create tests under test/domain, test/data, test/tracking, test/notifications, and test/screens.

### Task 1: Add dependencies and pure domain rules

Files:
- Modify pubspec.yaml.
- Create lib/src/domain/models.dart, odometer.dart, service_schedule.dart.
- Create test/domain/odometer_test.dart and service_schedule_test.dart.

Interfaces:
- OdometerMath.acceptPoint(previous, current, options) -> DistanceResult.
- OdometerMath.addDistance(currentOdometerKm, acceptedDistanceMeters) -> double.
- ServiceSchedule.status(currentOdometerKm, item) -> ServiceStatus.
- ServiceSchedule.reminderType(currentOdometerKm, item, notificationState) -> ServiceReminder?.

- [ ] Step 1: Add dependencies with flutter pub add geolocator sqflite path flutter_local_notifications and flutter pub add --dev sqflite_common_ffi.
- [ ] Step 2: Write failing tests for accepting an accurate GeoPoint pair, rejecting accuracy above 50 meters, rejecting jumps above 500 meters, and returning dueSoon at 200 km remaining and due at zero remaining.
- [ ] Step 3: Run flutter test test/domain/odometer_test.dart test/domain/service_schedule_test.dart; expect failure because the domain types do not exist.
- [ ] Step 4: Implement immutable GeoPoint, DistanceResult, Vehicle, Ride, ServiceItem, ServiceLog, ServiceStatus, ServiceReminder, and NotificationState. Use Haversine distance. Make dueSoon mean remaining distance greater than 0 and less than or equal to 200.
- [ ] Step 5: Run the same tests; expect PASS.
- [ ] Step 6: Commit with git add pubspec.yaml pubspec.lock lib/src/domain test/domain and git commit -m "feat: add odometer and service domain rules".

### Task 2: Build local SQLite persistence

Files:
- Create lib/src/data/local_database.dart, lib/src/data/odomate_repository.dart.
- Create test/data/local_database_test.dart.

Interfaces:
- loadVehicle() -> Future<Vehicle?>
- saveVehicle(Vehicle vehicle) -> Future<void>
- createRide(Ride ride) -> Future<int>
- finishRide(int rideId, DateTime endedAt, double distanceKm) -> Future<void>
- loadActiveRide() -> Future<Ride?>
- listRides() -> Future<List<Ride>>
- listServices() -> Future<List<ServiceItem>>
- saveService(ServiceItem item) -> Future<void>
- recordService(ServiceLog log) -> Future<void>
- saveActiveRideCheckpoint(Ride ride) -> Future<void>

- [ ] Step 1: Write tests that persist vehicle, ride, service, and active-ride checkpoint, then read them from a second repository instance.
- [ ] Step 2: Run flutter test test/data/local_database_test.dart; expect failure because the database and repository do not exist.
- [ ] Step 3: Implement a version-1 schema with vehicle, rides, service_items, service_logs, and notification_state tables. Store distances as REAL, timestamps as ISO-8601 text, and active rides with ended_at IS NULL.
- [ ] Step 4: Implement parameterized row mapping and an injectable in-memory database factory. Wrap finishing a ride and updating the vehicle odometer in one transaction.
- [ ] Step 5: Run the test; expect PASS.
- [ ] Step 6: Commit with git add lib/src/data test/data and git commit -m "feat: persist odometer and service data locally".

### Task 3: Implement background GPS ride tracking

Files:
- Create lib/src/tracking/ride_tracker.dart and test/tracking/ride_tracker_test.dart.
- Modify lib/main.dart, android/app/src/main/AndroidManifest.xml, and ios/Runner/Info.plist.

Interfaces:
- RideTracker.start() -> Future<void>
- RideTracker.stop() -> Future<Ride>
- RideTracker.state -> ValueListenable<RideTrackingState>
- RideTracker.onLocation(Position position) -> Future<void>

- [ ] Step 1: Add Android ACCESS_FINE_LOCATION, ACCESS_COARSE_LOCATION, ACCESS_BACKGROUND_LOCATION, FOREGROUND_SERVICE, and FOREGROUND_SERVICE_LOCATION permissions. Add iOS location usage descriptions and UIBackgroundModes containing location.
- [ ] Step 2: Write a fake-position-stream test asserting an accurate pair increases distance while an inaccurate point does not.
- [ ] Step 3: Run flutter test test/tracking/ride_tracker_test.dart; expect failure because the tracker does not exist.
- [ ] Step 4: Implement geolocator permission checks, disabled-location handling, denied-forever handling, high accuracy, a 10-second Android interval, and a 10-meter distance filter. Configure Android foreground notification and iOS background location settings.
- [ ] Step 5: On each position, call OdometerMath.acceptPoint, update the active ride and vehicle odometer, and persist a checkpoint. Load an unfinished ride at startup instead of creating a second one.
- [ ] Step 6: Make stop cancel the subscription, save the final ride, and clear the active marker. Empty streams and signal gaps add no distance.
- [ ] Step 7: Run flutter test test/tracking/ride_tracker_test.dart and flutter analyze; expect PASS and no analyzer errors.
- [ ] Step 8: Commit with git add lib/main.dart lib/src/tracking android/app/src/main/AndroidManifest.xml ios/Runner/Info.plist test/tracking and git commit -m "feat: track rides with background GPS".

### Task 4: Add tracking and service notifications

Files:
- Create lib/src/notifications/notification_service.dart and test/notifications/notification_service_test.dart.
- Modify lib/main.dart and lib/src/tracking/ride_tracker.dart.

Interfaces:
- NotificationService.initialize() -> Future<void>
- showTrackingActive(double distanceKm) -> Future<void>
- clearTrackingActive() -> Future<void>
- maybeNotifyService(ServiceItem item, double odometerKm) -> Future<void>

- [ ] Step 1: Write tests proving the 200 km reminder is not duplicated in one cycle and recording service starts a new cycle.
- [ ] Step 2: Run flutter test test/notifications/notification_service_test.dart; expect failure because service and fakes do not exist.
- [ ] Step 3: Create one ongoing tracking channel and one service-reminder channel. Request platform notification permission where required. Persist last reminder type/cycle so restarts do not duplicate notifications.
- [ ] Step 4: Show the tracking notification while active and clear it after Stop Ride. Send Servis mendekat at 200 km and Sudah waktunya servis at due/overdue. Evaluate services whenever odometer changes and after startup.
- [ ] Step 5: Run the notification test and flutter analyze; expect PASS.
- [ ] Step 6: Commit with git add lib/main.dart lib/src/notifications lib/src/tracking test/notifications and git commit -m "feat: notify about active rides and due service".

### Task 5: Build setup, home, service, and history screens

Files:
- Create lib/src/app.dart.
- Create lib/src/screens/setup_screen.dart, home_screen.dart, services_screen.dart, history_screen.dart.
- Modify lib/main.dart.
- Create test/screens/app_test.dart.

Interfaces:
- OdoMateApp receives OdomateRepository, RideTracker, and NotificationService.
- Screens use those interfaces and never access SQLite or platform plugins directly.

- [ ] Step 1: Write widget tests for setup when no vehicle exists and Home switching from Start Ride to Stop Ride.
- [ ] Step 2: Run flutter test test/screens/app_test.dart; expect failure because the app shell and screens do not exist.
- [ ] Step 3: Implement setup with non-empty motor name and non-negative odometer validation, save the vehicle, seed Oli mesin, Oli gardan, Busi, and Filter udara with editable intervals, then navigate to Home.
- [ ] Step 4: Implement Home with odometer, service summary, GPS state, and one Start Ride/Stop Ride button. Active state shows duration, ride distance, and current odometer; permission errors appear inline.
- [ ] Step 5: Implement Services with add/edit interval, remaining kilometers, status, mark serviced at current odometer, and optional note using a basic dialog/form.
- [ ] Step 6: Implement History with newest-first rides and service logs. Add a confirmation dialog for manual odometer correction that creates no ride or service log.
- [ ] Step 7: Run dart format lib test, flutter test, and flutter analyze; expect all checks to pass.
- [ ] Step 8: Commit with git add lib test and git commit -m "feat: add OdoMate MVP screens".

### Task 6: Verify platform builds and acceptance behavior

- [ ] Step 1: Run flutter test, flutter analyze, and flutter build apk --debug; expect all to pass.
- [ ] Step 2: On a physical Android device, verify setup persistence, permission flows, ongoing tracking notification, screen-off/app-switch tracking, Stop Ride finalization, GPS gaps, 200 km and due reminders, and service-cycle reset.
- [ ] Step 3: Where an iOS signed device/simulator is available, verify Always location permission, locked-screen tracking, and the force-close limitation.
- [ ] Step 4: Fix only acceptance failures in the narrowest responsible layer, rerun the smallest relevant check, then repeat the full checks. Do not add maps, accounts, cloud sync, multi-vehicle support, or new abstractions.
- [ ] Step 5: Commit verification fixes with git add . and git commit -m "chore: verify OdoMate MVP".

## Self-review

- Spec coverage: setup, one motor, local persistence, Start/Stop Ride, background GPS, valid-point filtering, recovery, service intervals, 200 km and due notifications, history, manual correction, and platform limitations map to Tasks 1–6.
- Placeholder scan: no TBD, TODO, or unspecified error-handling steps remain.
- Type consistency: domain types are introduced in Task 1 and consumed by repository, tracker, notifications, and screens.
- Scope check: maps, accounts, cloud sync, multi-vehicle, server push, and ECU integration remain excluded.

