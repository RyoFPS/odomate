import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

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
  return cropped?.path;
}
