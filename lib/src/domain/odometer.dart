import 'dart:math' as math;

import 'models.dart';

class OdometerMath {
  static DistanceResult acceptPoint(
    GeoPoint previous,
    GeoPoint current, {
    double maxAccuracyMeters = 50,
    double maxJumpMeters = 500,
  }) {
    if (current.accuracyMeters > maxAccuracyMeters ||
        previous.accuracyMeters > maxAccuracyMeters) {
      return const DistanceResult(false, 0);
    }
    final p1 = previous.latitude * math.pi / 180,
        p2 = current.latitude * math.pi / 180;
    final dp = (current.latitude - previous.latitude) * math.pi / 180;
    final dl = (current.longitude - previous.longitude) * math.pi / 180;
    final a =
        math.sin(dp / 2) * math.sin(dp / 2) +
        math.cos(p1) * math.cos(p2) * math.sin(dl / 2) * math.sin(dl / 2);
    final meters = 6371000 * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return meters <= maxJumpMeters
        ? DistanceResult(true, meters)
        : const DistanceResult(false, 0);
  }

  static double addDistance(
    double currentOdometerKm,
    double acceptedDistanceMeters,
  ) => currentOdometerKm + acceptedDistanceMeters / 1000;
}
