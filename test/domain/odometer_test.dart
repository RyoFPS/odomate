import 'package:flutter_test/flutter_test.dart';
import 'package:odomate/src/domain/odometer.dart';
import 'package:odomate/src/domain/models.dart';

void main() {
  test('accepts an accurate point pair', () {
    final result = OdometerMath.acceptPoint(
      const GeoPoint(latitude: -6.2, longitude: 106.8, accuracyMeters: 5),
      const GeoPoint(latitude: -6.2, longitude: 106.801, accuracyMeters: 5),
    );
    expect(result.accepted, isTrue);
    expect(result.meters, greaterThan(100));
  });

  test('rejects accuracy above 50 meters', () {
    final result = OdometerMath.acceptPoint(
      const GeoPoint(latitude: 0, longitude: 0, accuracyMeters: 5),
      const GeoPoint(latitude: 0, longitude: .001, accuracyMeters: 51),
    );
    expect(result.accepted, isFalse);
  });

  test('rejects movement under five meters', () {
    final result = OdometerMath.acceptPoint(
      const GeoPoint(latitude: -6.2, longitude: 106.8, accuracyMeters: 5),
      const GeoPoint(latitude: -6.2, longitude: 106.800001, accuracyMeters: 5),
    );

    expect(result.accepted, isFalse);
  });

  test('rejects jumps above 500 meters', () {
    final result = OdometerMath.acceptPoint(
      const GeoPoint(latitude: 0, longitude: 0, accuracyMeters: 5),
      const GeoPoint(latitude: 0, longitude: .01, accuracyMeters: 5),
    );
    expect(result.accepted, isFalse);
  });
}
