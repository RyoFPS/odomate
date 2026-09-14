import 'package:flutter_test/flutter_test.dart';
import 'package:odomate/src/widgets/profile_photo_cropper.dart';

void main() {
  test('profile photo crop is locked to a square avatar', () {
    expect(profilePhotoCropAspectRatio.ratioX, 1);
    expect(profilePhotoCropAspectRatio.ratioY, 1);
  });
}
