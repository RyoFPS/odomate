import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../i18n/app_localizations.dart';

const profilePhotoCropAspectRatio = CropAspectRatio(ratioX: 1, ratioY: 1);
const _maxProfilePhotoDimension = 512;

Future<String?> cropProfilePhoto(
  BuildContext context,
  String sourcePath,
) async {
  final colors = Theme.of(context).colorScheme;
  final l10n = AppLocalizations.of(context);
  final cropped = await ImageCropper().cropImage(
    sourcePath: sourcePath,
    aspectRatio: profilePhotoCropAspectRatio,
    compressFormat: ImageCompressFormat.jpg,
    compressQuality: 88,
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: l10n.t('adjust_photo'),
        toolbarColor: colors.surface,
        toolbarWidgetColor: colors.onSurface,
        statusBarLight: Theme.of(context).brightness == Brightness.light,
        navBarLight: Theme.of(context).brightness == Brightness.light,
        activeControlsWidgetColor: colors.primary,
        initAspectRatio: CropAspectRatioPreset.square,
        aspectRatioPresets: const [CropAspectRatioPreset.square],
        lockAspectRatio: true,
        hideBottomControls: true,
      ),
      IOSUiSettings(
        title: l10n.t('adjust_photo'),
        doneButtonTitle: l10n.t('save'),
        cancelButtonTitle: l10n.t('cancel'),
        aspectRatioLockEnabled: true,
        resetAspectRatioEnabled: false,
        aspectRatioPickerButtonHidden: true,
      ),
    ],
  );
  if (cropped == null) return null;
  return persistProfilePhoto(cropped.path);
}

Future<String> persistProfilePhoto(String sourcePath) async {
  final documents = await getApplicationDocumentsDirectory();
  final directory = Directory(p.join(documents.path, 'profile_photos'));
  await directory.create(recursive: true);

  final source = File(sourcePath);
  final alreadyPersistent =
      p.normalize(p.dirname(source.path)) == p.normalize(directory.path);
  // ponytail: pure Dart decodes once at source size; use native compression if
  // migration peak memory remains a problem.
  final decoded = img.decodeImage(await source.readAsBytes());
  if (decoded == null) throw FormatException('Unsupported profile photo');
  if (alreadyPersistent &&
      decoded.width <= _maxProfilePhotoDimension &&
      decoded.height <= _maxProfilePhotoDimension) {
    return source.path;
  }

  final resized =
      decoded.width > _maxProfilePhotoDimension ||
          decoded.height > _maxProfilePhotoDimension
      ? img.copyResize(
          decoded,
          width: decoded.width >= decoded.height
              ? _maxProfilePhotoDimension
              : null,
          height: decoded.height > decoded.width
              ? _maxProfilePhotoDimension
              : null,
          interpolation: img.Interpolation.average,
        )
      : decoded;
  final bytes = img.encodeJpg(resized, quality: 88);
  if (alreadyPersistent) {
    final temporary = File(
      '${source.path}.${DateTime.now().microsecondsSinceEpoch}.tmp',
    );
    try {
      await temporary.writeAsBytes(bytes, flush: true);
      await temporary.rename(source.path);
    } catch (_) {
      if (await temporary.exists()) await temporary.delete();
      rethrow;
    }
    return source.path;
  }

  final destination = p.join(
    directory.path,
    'profile_${DateTime.now().microsecondsSinceEpoch}.jpg',
  );
  return (await File(destination).writeAsBytes(bytes, flush: true)).path;
}
