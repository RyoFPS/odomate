import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:odomate/src/data/odomate_repository.dart';
import 'package:odomate/src/domain/models.dart';
import 'package:odomate/src/tracking/ride_tracker.dart';

class _Repository extends OdomateRepository {
  Ride? activeRide;
  Ride? checkpoint;

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
  Future<List<ServiceItem>> listServices() async => const [];
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
}
