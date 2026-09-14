import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../data/odomate_repository.dart';
import '../domain/models.dart';
import '../domain/odometer.dart';
import '../notifications/notification_service.dart';

class RideTrackingState {
  final bool active;
  final bool waitingForFix;
  final String? error;
  final Ride? ride;
  const RideTrackingState({
    this.active = false,
    this.waitingForFix = false,
    this.error,
    this.ride,
  });
}

class RideTracker {
  final OdomateRepository repository;
  final NotificationService? notifications;
  final Stream<Position>? positionStream;
  final Future<bool> Function()? locationServiceEnabled;
  final Future<LocationPermission> Function()? checkPermission;
  final Future<LocationPermission> Function()? requestPermission;
  final ValueNotifier<RideTrackingState> _state = ValueNotifier(
    const RideTrackingState(),
  );
  StreamSubscription<Position>? _subscription;
  GeoPoint? _lastPoint;
  Ride? _ride;
  RideTracker(
    this.repository, {
    this.positionStream,
    this.notifications,
    this.locationServiceEnabled,
    this.checkPermission,
    this.requestPermission,
  });
  ValueListenable<RideTrackingState> get state => _state;

  Future<void> restore() async {
    final activeRide = await repository.loadActiveRide();
    if (activeRide == null) {
      await notifications?.clearTrackingActive();
      return;
    }
    await start();
  }

  Future<void> start() async {
    if (_state.value.active) return;
    try {
      if (!await (locationServiceEnabled?.call() ??
          Geolocator.isLocationServiceEnabled())) {
        _state.value = const RideTrackingState(
          error: 'Aktifkan lokasi terlebih dahulu.',
        );
        return;
      }
      var permission =
          await (checkPermission?.call() ?? Geolocator.checkPermission());
      if (permission == LocationPermission.denied) {
        permission =
            await (requestPermission?.call() ?? Geolocator.requestPermission());
      }
      if (permission == LocationPermission.deniedForever) {
        _state.value = const RideTrackingState(
          error: 'Izin lokasi ditolak permanen.',
        );
        return;
      }
      if (permission == LocationPermission.denied) {
        _state.value = const RideTrackingState(
          error: 'Izin lokasi diperlukan.',
        );
        return;
      }
      _lastPoint = null;
      _ride =
          await repository.loadActiveRide() ?? Ride(startedAt: DateTime.now());
      if (_ride!.id == null) {
        _ride = _ride!.copyWith(id: await repository.createRide(_ride!));
      }
      _state.value = RideTrackingState(
        active: true,
        waitingForFix: true,
        ride: _ride,
      );
      await notifications?.showTrackingActive(_ride!.distanceKm);
      final stream =
          positionStream ??
          Geolocator.getPositionStream(
            locationSettings: AndroidSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 5,
              intervalDuration: const Duration(seconds: 5),
              foregroundNotificationConfig: const ForegroundNotificationConfig(
                notificationTitle: 'OdoMate sedang merekam perjalanan',
                notificationText: 'Perjalanan tetap direkam di latar belakang',
                enableWakeLock: true,
              ),
            ),
          );
      _subscription = stream.listen(onPosition, onError: _onStreamError);
    } catch (_) {
      _state.value = const RideTrackingState(
        error: 'GPS tidak dapat dimulai. Periksa lokasi dan coba lagi.',
      );
    }
  }

  void _onStreamError(Object _, StackTrace stackTrace) {
    _subscription?.cancel();
    _subscription = null;
    _lastPoint = null;
    _state.value = const RideTrackingState(
      error: 'GPS tidak dapat dibaca. Coba mulai ulang.',
    );
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
    if (point.accuracyMeters > 50) return;
    final previous = _lastPoint;
    _lastPoint = point;
    if (previous == null) {
      _state.value = RideTrackingState(active: true, ride: _ride);
      return;
    }
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
