import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../data/odomate_repository.dart';
import '../domain/models.dart';
import '../domain/odometer.dart';
import '../notifications/notification_service.dart';
import '../i18n/app_localizations.dart';

class RideTrackingState {
  final bool active;
  final bool waitingForFix;
  final String? error;
  final Ride? ride;
  final List<GeoPoint> routePoints;
  final double? gpsAccuracyMeters;
  const RideTrackingState({
    this.active = false,
    this.waitingForFix = false,
    this.error,
    this.ride,
    this.routePoints = const [],
    this.gpsAccuracyMeters,
  });
}

class RideTracker {
  final OdomateRepository repository;
  final NotificationService? notifications;
  final Stream<Position>? positionStream;
  final Future<bool> Function()? locationServiceEnabled;
  final Future<LocationPermission> Function()? checkPermission;
  final Future<LocationPermission> Function()? requestPermission;
  String languageCode = 'id';
  final ValueNotifier<RideTrackingState> _state = ValueNotifier(
    const RideTrackingState(),
  );
  StreamSubscription<Position>? _subscription;
  GeoPoint? _lastPoint;
  Ride? _ride;
  List<GeoPoint> _routePoints = const [];
  double? _gpsAccuracyMeters;
  RideTracker(
    this.repository, {
    this.positionStream,
    this.notifications,
    this.locationServiceEnabled,
    this.checkPermission,
    this.requestPermission,
  });
  ValueListenable<RideTrackingState> get state => _state;
  void setLanguage(String code) => languageCode = code;
  AppLocalizations get _l10n => AppLocalizations(Locale(languageCode));

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
        _state.value = RideTrackingState(
          error: _l10n.t('location_enable_error'),
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
        _state.value = RideTrackingState(
          error: _l10n.t('permission_permanent_error'),
        );
        return;
      }
      if (permission == LocationPermission.denied) {
        _state.value = RideTrackingState(
          error: _l10n.t('permission_required_error'),
        );
        return;
      }
      _lastPoint = null;
      _ride =
          await repository.loadActiveRide() ?? Ride(startedAt: DateTime.now());
      if (_ride!.id == null) {
        _ride = _ride!.copyWith(id: await repository.createRide(_ride!));
      }
      _routePoints = List<GeoPoint>.of(
        await repository.listRidePoints(_ride!.id!),
      );
      _lastPoint = _routePoints.isEmpty ? null : _routePoints.last;
      _gpsAccuracyMeters = _lastPoint?.accuracyMeters;
      _state.value = _trackingState(waitingForFix: _routePoints.isEmpty);
      await notifications?.showTrackingActive(_ride!.distanceKm);
      final stream =
          positionStream ??
          Geolocator.getPositionStream(
            locationSettings: AndroidSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 5,
              intervalDuration: const Duration(seconds: 5),
              foregroundNotificationConfig: ForegroundNotificationConfig(
                notificationTitle: _l10n.t('active_ride_title'),
                notificationText: _l10n.t('active_ride_background'),
                enableWakeLock: true,
              ),
            ),
          );
      _subscription = stream.listen(onPosition, onError: _onStreamError);
    } catch (_) {
      _state.value = RideTrackingState(error: _l10n.t('gps_start_error'));
    }
  }

  void _onStreamError(Object _, StackTrace stackTrace) {
    _subscription?.cancel();
    _subscription = null;
    _lastPoint = null;
    _routePoints = const [];
    _state.value = RideTrackingState(error: _l10n.t('gps_read_error'));
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
    _gpsAccuracyMeters = point.accuracyMeters;
    if (point.accuracyMeters > 50) {
      _state.value = _trackingState(waitingForFix: true);
      return;
    }
    final previous = _lastPoint;
    _lastPoint = point;
    if (previous == null) {
      await _appendRoutePoint(point);
      _state.value = _trackingState();
      return;
    }
    final result = OdometerMath.acceptPoint(previous, point);
    if (!result.accepted) {
      _state.value = _trackingState();
      return;
    }
    await _appendRoutePoint(point);
    _ride = _ride!.copyWith(
      distanceKm: _ride!.distanceKm + result.meters / 1000,
    );
    _state.value = _trackingState();
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
    _routePoints = const [];
    _gpsAccuracyMeters = null;
    _state.value = const RideTrackingState();
    await notifications?.clearTrackingActive();
    return done;
  }

  Future<void> _appendRoutePoint(GeoPoint point) async {
    final rideId = _ride?.id;
    if (rideId == null) return;
    await repository.appendRidePoint(rideId, point);
    _routePoints = [..._routePoints, point];
  }

  RideTrackingState _trackingState({bool waitingForFix = false}) =>
      RideTrackingState(
        active: true,
        waitingForFix: waitingForFix,
        ride: _ride,
        routePoints: List.unmodifiable(_routePoints),
        gpsAccuracyMeters: _gpsAccuracyMeters,
      );
}
