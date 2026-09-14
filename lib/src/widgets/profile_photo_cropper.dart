import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

const profilePhotoCropAspectRatio = CropAspectRatio(ratioX: 1, ratioY: 1);

Future<String?> cropProfilePhoto(
  BuildContext context,
  String sourcePath,
) async {
  final colors = Theme.of(context).colorScheme;
  final cropped = await ImageCropper().cropImage(
    sourcePath: sourcePath,
    aspectRatio: profilePhotoCropAspectRatio,
    compressFormat: ImageCompressFormat.jpg,
    compressQuality: 88,
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: 'Sesuaikan foto',
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
        title: 'Sesuaikan foto',
        doneButtonTitle: 'Simpan',
        cancelButtonTitle: 'Batal',
        aspectRatioLockEnabled: true,
        resetAspectRatioEnabled: false,
        aspectRatioPickerButtonHidden: true,
      ),
    ],
  );
  return cropped?.path;
}
