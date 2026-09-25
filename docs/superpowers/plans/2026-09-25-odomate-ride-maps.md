# OdoMate Ride Route Maps Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (- [ ]) syntax for tracking.

**Goal:** Persist GPS route points, show a live map during an active ride on Home, and render the saved route interactively in Ride Detail.

**Architecture:** Add local ride_points storage separate from the Ride summary. RideTracker owns an in-memory route, persists the first accurate point plus later accepted points, and publishes immutable point snapshots. A single RideMap widget is shared by Home and Detail; History stays map-free.

**Tech Stack:** Flutter/Dart, sqflite, geolocator, flutter_map, latlong2, OpenStreetMap raster tiles, Material 3.

**Spec:** docs/superpowers/specs/2026-09-25-odomate-ride-maps-design.md

## Global Constraints

- Store route data locally; do not add backend/cloud sync.
- Keep History free of map previews.
- Use OSM tiles with userAgentPackageName: 'com.ryo.odomate' and visible OSM attribution.
- A tile/network failure must not interrupt tracking or lose route data.
- Store the first accurate fix as the start marker with zero distance; store later points only when the existing odometer filter accepts them.
- Older and duplicated rides without points show localized unavailable-route UI; never draw a fake route.
- Preserve current permission, odometer, force-close restore, theme, and ID/EN/JA behavior.
- Do not add route editing, offline tiles, navigation, traffic, elevation, or copying points during duplicate.

## Review Focus

- The first valid fix creates a marker but does not increase kilometers.
- Inaccurate and too-close GPS updates do not create route segments.
- A restored active ride shows saved points before the next GPS update.
- Old/duplicated rides have no fabricated route.
- A tile failure still allows stop and preserves the trace.

---

### Task 1: Persist route points

**Files:**

- Modify: pubspec.yaml
- Modify: lib/src/domain/models.dart
- Modify: lib/src/data/local_database.dart
- Modify: lib/src/data/odomate_repository.dart
- Modify: test/data/odomate_repository_test.dart

**Interfaces:**

- Produces Future<void> appendRidePoint(int rideId, GeoPoint point).
- Produces Future<List<GeoPoint>> listRidePoints(int rideId), ordered by insertion.
- Makes deleteRide(int id) delete its points in the same transaction.

- [ ] **Step 1: Write failing repository tests**

~~~dart
test('stores points in order and deletes them with the ride', () async {
  final id = await repository.createRide(
    Ride(startedAt: DateTime(2026, 9, 25, 8)),
  );
  const first = GeoPoint(latitude: -6.2, longitude: 106.8, accuracyMeters: 5);
  const second = GeoPoint(latitude: -6.201, longitude: 106.801, accuracyMeters: 6);

  await repository.appendRidePoint(id, first);
  await repository.appendRidePoint(id, second);
  expect(await repository.listRidePoints(id), [first, second]);

  await repository.deleteRide(id);
  expect(await repository.listRidePoints(id), isEmpty);
});

test('does not copy route points when duplicating a ride', () async {
  final source = await repository.createRide(
    Ride(startedAt: DateTime(2026, 9, 25, 8), distanceKm: 2),
  );
  await repository.appendRidePoint(
    source,
    const GeoPoint(latitude: -6.2, longitude: 106.8, accuracyMeters: 5),
  );
  final duplicate = await repository.duplicateRide(
    Ride(id: source, startedAt: DateTime(2026, 9, 25, 8), distanceKm: 2),
  );
  expect(await repository.listRidePoints(duplicate), isEmpty);
});
~~~

- [ ] **Step 2: Run the test and verify failure**

Run: flutter test test/data/odomate_repository_test.dart

Expected: FAIL because route-point methods do not exist.

- [ ] **Step 3: Add map dependencies and value equality**

~~~yaml
dependencies:
  flutter_map: ^8.2.2
  latlong2: ^0.9.1
~~~

~~~dart
@override
bool operator ==(Object other) =>
    other is GeoPoint &&
    latitude == other.latitude &&
    longitude == other.longitude &&
    accuracyMeters == other.accuracyMeters &&
    timestamp == other.timestamp;

@override
int get hashCode => Object.hash(latitude, longitude, accuracyMeters, timestamp);
~~~

Run: flutter pub get

- [ ] **Step 4: Add schema migration**

Raise database version from 7 to 8. In both _create and _ensureColumns,
create the table and index:

~~~dart
await db.execute(
  'CREATE TABLE IF NOT EXISTS ride_points ('
  'id INTEGER PRIMARY KEY, ride_id INTEGER NOT NULL, '
  'latitude REAL NOT NULL, longitude REAL NOT NULL, '
  'accuracy_m REAL NOT NULL, recorded_at TEXT NOT NULL)',
);
await db.execute(
  'CREATE INDEX IF NOT EXISTS idx_ride_points_ride_id_id '
  'ON ride_points(ride_id, id)',
);
~~~

- [ ] **Step 5: Implement repository storage**

~~~dart
Future<void> appendRidePoint(int rideId, GeoPoint point) async =>
    (await db).insert('ride_points', {
      'ride_id': rideId,
      'latitude': point.latitude,
      'longitude': point.longitude,
      'accuracy_m': point.accuracyMeters,
      'recorded_at': (point.timestamp ?? DateTime.now()).toIso8601String(),
    });

Future<List<GeoPoint>> listRidePoints(int rideId) async =>
    (await (await db).query(
      'ride_points',
      where: 'ride_id = ?',
      whereArgs: [rideId],
      orderBy: 'id ASC',
    )).map((row) => GeoPoint(
      latitude: (row['latitude'] as num).toDouble(),
      longitude: (row['longitude'] as num).toDouble(),
      accuracyMeters: (row['accuracy_m'] as num).toDouble(),
      timestamp: DateTime.parse(row['recorded_at'] as String),
    )).toList();
~~~

Change deleteRide into one transaction: delete ride_points by ride_id, then
delete the rides row.

- [ ] **Step 6: Run focused tests**

Run: flutter test test/data/odomate_repository_test.dart

Expected: PASS.

- [ ] **Step 7: Commit Task 1**

~~~bash
git add pubspec.yaml pubspec.lock lib/src/domain/models.dart lib/src/data/local_database.dart lib/src/data/odomate_repository.dart test/data/odomate_repository_test.dart
git commit -m "feat: persist ride route points"
~~~

### Task 2: Persist and publish the active route

**Files:**

- Modify: lib/src/tracking/ride_tracker.dart
- Modify: test/tracking/ride_tracker_test.dart

**Interfaces:**

- Extends RideTrackingState with final List<GeoPoint> routePoints.
- Consumes Task 1 repository methods.
- Publishes an immutable ordered route snapshot.

- [ ] **Step 1: Write failing tracker tests**

Extend the in-memory repository fake with points, appendRidePoint, and
listRidePoints.

~~~dart
Future<RideTracker> startedTracker(_Repository repository) async {
  final tracker = RideTracker(
    repository,
    positionStream: const Stream.empty(),
    locationServiceEnabled: () async => true,
    checkPermission: () async => LocationPermission.always,
  );
  await tracker.start();
  return tracker;
}

test('persists the start fix and later accepted fix', () async {
  final repository = _Repository();
  final tracker = await startedTracker(repository);
  await tracker.onLocation(const GeoPoint(
    latitude: -6.2, longitude: 106.8, accuracyMeters: 5,
  ));
  await tracker.onLocation(const GeoPoint(
    latitude: -6.2, longitude: 106.8001, accuracyMeters: 5,
  ));

  expect(repository.points, hasLength(2));
  expect(tracker.state.value.routePoints, repository.points);
  expect(tracker.state.value.ride!.distanceKm, greaterThan(0));
});

test('does not persist inaccurate or too-close fixes', () async {
  final repository = _Repository();
  final tracker = await startedTracker(repository);
  await tracker.onLocation(const GeoPoint(
    latitude: -6.2, longitude: 106.8, accuracyMeters: 5,
  ));
  await tracker.onLocation(const GeoPoint(
    latitude: -6.2, longitude: 106.8, accuracyMeters: 80,
  ));
  await tracker.onLocation(const GeoPoint(
    latitude: -6.2, longitude: 106.800001, accuracyMeters: 5,
  ));

  expect(repository.points, hasLength(1));
});
~~~

Add a restore test where loadActiveRide returns id 1 and listRidePoints(1)
returns two points; start must publish those two points.

- [ ] **Step 2: Run the test and verify failure**

Run: flutter test test/tracking/ride_tracker_test.dart

Expected: FAIL because routePoints is absent and points are not persisted.

- [ ] **Step 3: Add route state and restore it**

~~~dart
class RideTrackingState {
  // existing members
  final List<GeoPoint> routePoints;

  const RideTrackingState({
    this.active = false,
    this.waitingForFix = false,
    this.error,
    this.ride,
    this.routePoints = const [],
  });
}
~~~

Keep List<GeoPoint> _routePoints = const []. After an active ride exists in
start, load repository.listRidePoints(_ride!.id!). Every state publication
uses List.unmodifiable(_routePoints).

- [ ] **Step 4: Store the start marker and accepted segments**

~~~dart
if (point.accuracyMeters > 50) return;
if (_lastPoint == null) {
  _lastPoint = point;
  await _appendRoutePoint(point);
  _publish(active: true);
  return;
}
final result = OdometerMath.acceptPoint(_lastPoint!, point);
_lastPoint = point;
if (!result.accepted) return;
await _appendRoutePoint(point);
// Preserve current distance checkpoint and notification code.
~~~

_appendRoutePoint appends through the repository and adds to _routePoints.
Clear route state in stop and _onStreamError. Do not change current odometer
checkpoint arithmetic.

- [ ] **Step 5: Run focused tests**

Run: flutter test test/tracking/ride_tracker_test.dart

Expected: PASS.

- [ ] **Step 6: Commit Task 2**

~~~bash
git add lib/src/tracking/ride_tracker.dart test/tracking/ride_tracker_test.dart
git commit -m "feat: track active ride route"
~~~

### Task 3: Create a reusable interactive route map

**Files:**

- Create: lib/src/widgets/ride_map.dart
- Create: test/widgets/ride_map_test.dart

**Interfaces:**

- Produces RideMap({required List<GeoPoint> points, required bool followCurrentLocation, required double height}).
- Zero points render localized unavailable UI.
- One point renders a start marker and center; two or more render a polyline and start/end markers.

- [ ] **Step 1: Write failing widget tests**

~~~dart
testWidgets('shows unavailable UI for a route with no points', (tester) async {
  await tester.pumpWidget(testApp(const RideMap(
    points: [], followCurrentLocation: false, height: 260,
  )));
  expect(find.byKey(const ValueKey('ride-map-empty')), findsOneWidget);
});

testWidgets('builds start, end, and route layers for saved points', (tester) async {
  await tester.pumpWidget(testApp(RideMap(
    points: const [
      GeoPoint(latitude: -6.2, longitude: 106.8, accuracyMeters: 5),
      GeoPoint(latitude: -6.201, longitude: 106.801, accuracyMeters: 5),
    ],
    followCurrentLocation: false,
    height: 260,
  )));
  expect(find.byKey(const ValueKey('ride-map')), findsOneWidget);
  expect(find.byKey(const ValueKey('ride-map-start')), findsOneWidget);
  expect(find.byKey(const ValueKey('ride-map-end')), findsOneWidget);
});
~~~

Use the app's Material and localization setup so no user-visible test copy is
hardcoded.

- [ ] **Step 2: Run the test and verify failure**

Run: flutter test test/widgets/ride_map_test.dart

Expected: FAIL because RideMap does not exist.

- [ ] **Step 3: Implement the widget**

~~~dart
FlutterMap(
  key: const ValueKey('ride-map'),
  mapController: _controller,
  options: MapOptions(initialCenter: _latLng(points.first), initialZoom: 16),
  children: [
    const TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.ryo.odomate',
      maxNativeZoom: 19,
      maxZoom: 19,
    ),
    if (points.length > 1)
      PolylineLayer(polylines: [
        Polyline(points: points.map(_latLng).toList(), strokeWidth: 4),
      ]),
    MarkerLayer(markers: _markers(points)),
    const RichAttributionWidget(
      attributions: [TextSourceAttribution('© OpenStreetMap contributors')],
    ),
  ],
)
~~~

Use Theme.of(context).colorScheme for route and marker colors. On initial
map-ready, center one point at zoom 16; for two or more, call
fitCamera(CameraFit.bounds(...)) with EdgeInsets.all(32) and max zoom 17.
With followCurrentLocation true, refit/move only when new points arrive; with
false, never override a user's later pan/zoom.

- [ ] **Step 4: Run focused tests**

Run: flutter test test/widgets/ride_map_test.dart

Expected: PASS.

- [ ] **Step 5: Commit Task 3**

~~~bash
git add lib/src/widgets/ride_map.dart test/widgets/ride_map_test.dart
git commit -m "feat: add reusable ride route map"
~~~

### Task 4: Integrate Home and Ride Detail

**Files:**

- Modify: lib/src/screens/home_screen.dart
- Modify: lib/src/screens/ride_detail_screen.dart
- Modify: lib/src/i18n/app_localizations.dart
- Modify: test/screens/navigation_test.dart
- Modify: test/screens/ride_detail_screen_test.dart

**Interfaces:**

- Consumes Task 2 RideTrackingState.routePoints, Task 3 RideMap, and Task 1 listRidePoints.
- Home shows maps only while active; Detail loads points once by ride id.

- [ ] **Step 1: Write failing screen tests**

~~~dart
testWidgets('Home only shows the live map during an active ride', (tester) async {
  final tracker = RideTracker(fakeRepository);
  await tester.pumpWidget(testApp(HomeScreen(
    repository: fakeRepository, tracker: tracker,
  )));
  expect(find.byKey(const ValueKey('home-live-ride-map')), findsNothing);

  await startRideWithTwoPoints(tracker);
  await tester.pump();
  expect(find.byKey(const ValueKey('home-live-ride-map')), findsOneWidget);
});

testWidgets('detail shows unavailable UI for an older ride', (tester) async {
  await tester.pumpWidget(testApp(RideDetailScreen(
    ride: Ride(id: 1, startedAt: DateTime(2026, 9, 14)),
    repository: emptyPointsRepository,
  )));
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('ride-map-empty')), findsOneWidget);
});
~~~

Add a detail test with two stored points and assert ride-map-start and
ride-map-end. Change the existing placeholder assertion to assert ride-map
only for a route with points.

- [ ] **Step 2: Run the tests and verify failure**

Run: flutter test test/screens/navigation_test.dart test/screens/ride_detail_screen_test.dart

Expected: FAIL because neither screen renders RideMap.

- [ ] **Step 3: Localize all new map copy**

Add these keys to all ID/EN/JA maps:

~~~dart
'live_route': 'Rute langsung',
'route_unavailable': 'Rute GPS tidak tersedia untuk perjalanan ini',
'route_unavailable_hint': 'Rute hanya tersimpan untuk perjalanan baru.',
'route_start': 'Mulai',
'route_end': 'Selesai',
~~~

Translate every value in English and Japanese; do not hardcode widget/screen
copy.

- [ ] **Step 4: Render Home map only during tracking**

After _vehicleCard(context, state, l10n) in Home's ListView, add:

~~~dart
if (state.active) ...[
  const SizedBox(height: 12),
  Card(
    key: const ValueKey('home-live-ride-map'),
    clipBehavior: Clip.antiAlias,
    child: RideMap(
      points: state.routePoints,
      followCurrentLocation: true,
      height: 220,
    ),
  ),
],
~~~

Keep the existing Start/Stop and waiting-for-GPS behavior unchanged.

- [ ] **Step 5: Replace Detail's painted placeholder**

Remove _RoutePreviewPainter and the disabled expand button. Add
late Future<List<GeoPoint>> _routePoints to _RideDetailScreenState; initialize
to an empty future when no id/repository is available, otherwise
repository!.listRidePoints(ride.id!). Replace _routePreview with a
FutureBuilder whose data path is:

~~~dart
RideMap(
  points: snapshot.data ?? const [],
  followCurrentLocation: false,
  height: 300,
)
~~~

Retain the route-section heading and all summary/timeline/notes cards. Treat
a repository error as the same localized unavailable route state, without
failing the detail page.

- [ ] **Step 6: Run focused tests**

Run: flutter test test/screens/navigation_test.dart test/screens/ride_detail_screen_test.dart

Expected: PASS.

- [ ] **Step 7: Commit Task 4**

~~~bash
git add lib/src/screens/home_screen.dart lib/src/screens/ride_detail_screen.dart lib/src/i18n/app_localizations.dart test/screens/navigation_test.dart test/screens/ride_detail_screen_test.dart
git commit -m "feat: show live and saved ride maps"
~~~

### Task 5: Verify the integrated feature

**Files:**

- Modify only feature files if verification exposes a defect.

**Interfaces:**

- Verifies Task 1-4 persistence, tracking, map, and screen behavior together.

- [ ] **Step 1: Format and run automated gates**

Run: dart format lib test

Run: flutter analyze

Expected: no analyzer errors or warnings.

Run: flutter test

Expected: PASS.

- [ ] **Step 2: Check the diff and build Android debug APK**

Run: git diff --check

Expected: no whitespace errors.

Run: flutter build apk --debug

Expected: successful debug APK build.

- [ ] **Step 3: Perform device GPS QA**

1. Start a ride and wait for an accurate fix: Home shows the start marker and distance remains 0 km.
2. Move enough for two accepted points: marker/polyline update and odometer behavior remains correct.
3. Force-close and relaunch: the route line returns before new movement.
4. Stop: History stays map-free; Detail has route, start/end markers, camera fit, zoom, and pan.
5. Open an old or duplicated ride: localized unavailable state appears.
6. Disable network after recording: tracking and stopping still work; the saved route renders when tiles are available again.
7. Inspect ID/EN/JA plus light/dark themes.

- [ ] **Step 4: Commit a verification fix only if one was needed**

~~~bash
git add pubspec.yaml pubspec.lock lib/src/domain/models.dart lib/src/data/local_database.dart lib/src/data/odomate_repository.dart lib/src/tracking/ride_tracker.dart lib/src/widgets/ride_map.dart lib/src/screens/home_screen.dart lib/src/screens/ride_detail_screen.dart lib/src/i18n/app_localizations.dart test/data/odomate_repository_test.dart test/tracking/ride_tracker_test.dart test/widgets/ride_map_test.dart test/screens/navigation_test.dart test/screens/ride_detail_screen_test.dart
git commit -m "fix: polish ride map behavior"
~~~

Skip this commit when verification required no code changes.
