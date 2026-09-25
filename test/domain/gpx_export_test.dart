import 'package:flutter_test/flutter_test.dart';
import 'package:odomate/src/domain/gpx_export.dart';
import 'package:odomate/src/domain/models.dart';

void main() {
  test('builds a timestamped GPX track from ride points', () {
    final gpx = buildRideGpx(
      ride: Ride(startedAt: DateTime(2026, 9, 25, 8, 30)),
      points: [
        GeoPoint(
          latitude: -6.2,
          longitude: 106.8,
          accuracyMeters: 5,
          timestamp: DateTime.utc(2026, 9, 25, 1, 30),
        ),
        const GeoPoint(latitude: -6.201, longitude: 106.801, accuracyMeters: 5),
      ],
    );

    expect(gpx, contains('<gpx version="1.1"'));
    expect(gpx, contains('<trkpt lat="-6.2" lon="106.8">'));
    expect(gpx, contains('<time>2026-09-25T01:30:00.000Z</time>'));
    expect(gpx, contains('<trkpt lat="-6.201" lon="106.801">'));
    expect(
      rideGpxFileName(Ride(startedAt: DateTime(2026, 9, 25))),
      'odomate-2026-09-25.gpx',
    );
  });
}
