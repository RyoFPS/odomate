import 'package:flutter/services.dart';

import '../domain/models.dart';

class RideHaptics {
  static Future<void> afterRideStarted(Future<bool> Function() start) async {
    if (await start()) await HapticFeedback.mediumImpact();
  }

  static Future<void> afterRideStopped(Future<Ride?> Function() stop) async {
    if (await stop() == null) return;
    await HapticFeedback.selectionClick();
    await HapticFeedback.selectionClick();
  }
}
