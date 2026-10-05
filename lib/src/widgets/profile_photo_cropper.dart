import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../i18n/app_localizations.dart';

const profilePhotoCropAspectRatio = CropAspectRatio(ratioX: 1, ratioY: 1);

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
  if (p.dirname(source.path) == directory.path) return source.path;

  final destination = p.join(
    directory.path,
    'profile_${DateTime.now().microsecondsSinceEpoch}.jpg',
  );
  return (await source.copy(destination)).path;
}
