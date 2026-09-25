import 'models.dart';

String buildRideGpx({required Ride ride, required List<GeoPoint> points}) {
  final trackPoints = points
      .map((point) {
        final time = point.timestamp?.toUtc().toIso8601String();
        return [
          '      <trkpt lat="${point.latitude}" lon="${point.longitude}">',
          if (time != null) '        <time>$time</time>',
          '      </trkpt>',
        ].join('\n');
      })
      .join('\n');

  return '''<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.1" creator="OdoMate" xmlns="http://www.topografix.com/GPX/1/1">
  <metadata>
    <time>${ride.startedAt.toUtc().toIso8601String()}</time>
  </metadata>
  <trk>
    <name>OdoMate ride</name>
    <trkseg>
$trackPoints
    </trkseg>
  </trk>
</gpx>
''';
}

String rideGpxFileName(Ride ride) {
  final date = ride.startedAt.toLocal();
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return 'odomate-${date.year}-$month-$day.gpx';
}
