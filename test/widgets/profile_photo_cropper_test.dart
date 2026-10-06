import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:odomate/src/widgets/profile_photo_cropper.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  late Directory temporaryDirectory;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'profile-photo-test-',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (call) async {
          if (call.method == 'getApplicationDocumentsDirectory') {
            return temporaryDirectory.path;
          }
          throw MissingPluginException();
        });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    await temporaryDirectory.delete(recursive: true);
  });

  test('profile photo crop is locked to a square avatar', () {
    expect(profilePhotoCropAspectRatio.ratioX, 1);
    expect(profilePhotoCropAspectRatio.ratioY, 1);
  });

  test('persisted and migrated photos are downsampled to 512 pixels', () async {
    final photo = img.Image(width: 1200, height: 800);
    for (var y = 0; y < photo.height; y++) {
      for (var x = 0; x < photo.width; x++) {
        final value = (x * 7 + y * 13) % 256;
        photo.setPixelRgb(x, y, value, value, value);
      }
    }
    final originalBytes = img.encodeJpg(photo, quality: 100);
    final source = File('${temporaryDirectory.path}/source.jpg');
    await source.writeAsBytes(originalBytes);

    final persistedPath = await persistProfilePhoto(source.path);
    final persistedBytes = await File(persistedPath).readAsBytes();
    final persisted = img.decodeImage(persistedBytes)!;
    expect(persisted.width, 512);
    expect(persisted.height, lessThanOrEqualTo(512));
    expect(persistedBytes.length, lessThan(originalBytes.length));

    final legacy = File(
      p.join(temporaryDirectory.path, 'profile_photos', 'legacy.jpg'),
    );
    await legacy.writeAsBytes(originalBytes);
    expect(await persistProfilePhoto(legacy.path), legacy.path);
    final migrated = img.decodeImage(await legacy.readAsBytes())!;
    expect(migrated.width, 512);
    expect(migrated.height, lessThanOrEqualTo(512));
  });
}
