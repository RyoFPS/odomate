import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:odomate/src/data/odomate_repository.dart';
import 'package:odomate/src/domain/models.dart';
import 'package:odomate/src/tracking/ride_tracker.dart';

class _Repository extends OdomateRepository {
  Ride? activeRide;
  Ride? checkpoint;
  final List<GeoPoint> points = [];

  @override
  Future<int> createRide(Ride ride) async {
    activeRide = ride.copyWith(id: 1);
    return 1;
  }

  @override
  Future<Ride?> loadActiveRide() async => activeRide;

  @override
  Future<void> saveActiveRideCheckpoint(Ride ride) async {
    checkpoint = ride;
    activeRide = ride;
  }

  @override
  Future<void> appendRidePoint(int rideId, GeoPoint point) async {
    points.add(point);
  }

  @override
  Future<List<GeoPoint>> listRidePoints(int rideId) async => points;

  @override
  Future<List<ServiceItem>> listServices() async => const [];
}

Future<RideTracker> _startedTracker(_Repository repository) async {
  final tracker = RideTracker(
    repository,
    positionStream: const Stream.empty(),
    locationServiceEnabled: () async => true,
    checkPermission: () async => LocationPermission.always,
  );
  await tracker.start();
  return tracker;
}

void main() {
  test('starts recording after a valid first GPS fix', () async {
    final repository = _Repository();
    final tracker = RideTracker(
      repository,
      positionStream: const Stream.empty(),
      locationServiceEnabled: () async => true,
      checkPermission: () async => LocationPermission.always,
    );

    await tracker.start();
    expect(tracker.state.value.active, isTrue);
    expect(tracker.state.value.waitingForFix, isTrue);

    await tracker.onLocation(
      const GeoPoint(latitude: -6.2, longitude: 106.8, accuracyMeters: 5),
    );
    await tracker.onLocation(
      const GeoPoint(latitude: -6.2, longitude: 106.8001, accuracyMeters: 5),
    );

    expect(tracker.state.value.waitingForFix, isFalse);
    expect(repository.checkpoint!.distanceKm, greaterThan(0));
  });

  test('shows a recoverable error when the GPS stream fails', () async {
    final positions = StreamController<Position>();
    final tracker = RideTracker(
      _Repository(),
      positionStream: positions.stream,
      locationServiceEnabled: () async => true,
      checkPermission: () async => LocationPermission.always,
    );

    await tracker.start();
    positions.addError(StateError('GPS unavailable'));
    await Future<void>.delayed(Duration.zero);

    expect(tracker.state.value.active, isFalse);
    expect(tracker.state.value.error, contains('GPS tidak dapat dibaca'));
    await positions.close();
  });

  test('persists the start fix and later accepted fix', () async {
    final repository = _Repository();
    final tracker = await _startedTracker(repository);
    await tracker.onLocation(
      const GeoPoint(latitude: -6.2, longitude: 106.8, accuracyMeters: 5),
    );

    expect(repository.points, hasLength(1));
    expect(tracker.state.value.ride!.distanceKm, 0);

    await tracker.onLocation(
      const GeoPoint(latitude: -6.2, longitude: 106.8001, accuracyMeters: 5),
    );

    expect(repository.points, hasLength(2));
    expect(tracker.state.value.routePoints, repository.points);
    expect(tracker.state.value.ride!.distanceKm, greaterThan(0));
  });

  test('does not persist inaccurate or too-close fixes', () async {
    final repository = _Repository();
    final tracker = await _startedTracker(repository);
    await tracker.onLocation(
      const GeoPoint(latitude: -6.2, longitude: 106.8, accuracyMeters: 5),
    );
    await tracker.onLocation(
      const GeoPoint(latitude: -6.2, longitude: 106.8, accuracyMeters: 80),
    );
    await tracker.onLocation(
      const GeoPoint(latitude: -6.2, longitude: 106.800001, accuracyMeters: 5),
    );

    expect(repository.points, hasLength(1));
  });

  test(
    'reports the latest GPS accuracy even when a fix is too inaccurate',
    () async {
      final repository = _Repository();
      final tracker = await _startedTracker(repository);

      await tracker.onLocation(
        const GeoPoint(latitude: -6.2, longitude: 106.8, accuracyMeters: 80),
      );

      expect(tracker.state.value.gpsAccuracyMeters, 80);
      expect(tracker.state.value.waitingForFix, isTrue);
      expect(repository.points, isEmpty);
    },
  );

  test('restores persisted route points for an active ride', () async {
    final repository = _Repository()
      ..activeRide = Ride(id: 1, startedAt: DateTime(2026, 9, 25, 8))
      ..points.addAll([
        GeoPoint(
          latitude: -6.2,
          longitude: 106.8,
          accuracyMeters: 5,
          timestamp: DateTime(2026, 9, 25, 8),
        ),
        GeoPoint(
          latitude: -6.201,
          longitude: 106.801,
          accuracyMeters: 5,
          timestamp: DateTime(2026, 9, 25, 8, 1),
        ),
      ]);
    final tracker = await _startedTracker(repository);

    expect(tracker.state.value.routePoints, repository.points);
  });
}
