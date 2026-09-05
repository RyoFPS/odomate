import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../data/odomate_repository.dart';
import '../domain/models.dart';
import '../domain/odometer.dart';
import '../notifications/notification_service.dart';

class RideTrackingState {
  final bool active;
  final String? error;
  final Ride? ride;
  const RideTrackingState({this.active = false, this.error, this.ride});
}

class RideTracker {
  final OdomateRepository repository;
  final NotificationService? notifications;
  final Stream<Position>? positionStream;
  final ValueNotifier<RideTrackingState> _state = ValueNotifier(
    const RideTrackingState(),
  );
  StreamSubscription<Position>? _subscription;
  GeoPoint? _lastPoint;
  Ride? _ride;
  RideTracker(this.repository, {this.positionStream, this.notifications});
  ValueListenable<RideTrackingState> get state => _state;
  Future<void> start() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      _state.value = const RideTrackingState(
        error: 'Aktifkan lokasi terlebih dahulu.',
      );
      return;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      _state.value = const RideTrackingState(
        error: 'Izin lokasi ditolak permanen.',
      );
      return;
    }
    if (permission == LocationPermission.denied) {
      _state.value = const RideTrackingState(error: 'Izin lokasi diperlukan.');
      return;
    }
    _ride =
        await repository.loadActiveRide() ?? Ride(startedAt: DateTime.now());
    if (_ride!.id == null) {
      _ride = _ride!.copyWith(id: await repository.createRide(_ride!));
    }
    _state.value = RideTrackingState(active: true, ride: _ride);
    await notifications?.showTrackingActive(_ride!.distanceKm);
    final stream =
        positionStream ??
        Geolocator.getPositionStream(
          locationSettings: AndroidSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
            intervalDuration: Duration(seconds: 10),
          ),
        );
    _subscription = stream.listen(onPosition);
  }

  Future<void> onPosition(Position p) async => onLocation(
    GeoPoint(
      latitude: p.latitude,
      longitude: p.longitude,
      accuracyMeters: p.accuracy,
      timestamp: p.timestamp,
    ),
  );
  Future<void> onLocation(GeoPoint point) async {
    if (!_state.value.active) return;
    final previous = _lastPoint;
    _lastPoint = point;
    if (previous == null) return;
    final result = OdometerMath.acceptPoint(previous, point);
    if (!result.accepted) return;
    _ride = _ride!.copyWith(
      distanceKm: _ride!.distanceKm + result.meters / 1000,
    );
    _state.value = RideTrackingState(active: true, ride: _ride);
    await repository.saveActiveRideCheckpoint(_ride!);
    await notifications?.showTrackingActive(_ride!.distanceKm);
    for (final service in await repository.listServices()) {
      await notifications?.maybeNotifyService(
        service,
        (await repository.loadVehicle())?.odometerKm ?? 0,
      );
    }
  }

  Future<Ride> stop() async {
    await _subscription?.cancel();
    final ride = _ride ?? await repository.loadActiveRide();
    if (ride == null) throw StateError('Tidak ada ride aktif');
    final done = ride.copyWith(endedAt: DateTime.now());
    await repository.finishRide(done.id!, done.endedAt!, done.distanceKm);
    _ride = null;
    _lastPoint = null;
    _state.value = const RideTrackingState();
    await notifications?.clearTrackingActive();
    return done;
  }
}
