import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../data/odomate_repository.dart';
import '../domain/models.dart';
import '../i18n/app_localizations.dart';
import '../widgets/odometer_correction_sheet.dart';
import '../widgets/profile_photo_cropper.dart';
import '../widgets/photo_source_sheet.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  final OdomateRepository repository;
  final ThemeMode themeMode;
  final String language;
  final ValueChanged<ThemeMode> onThemeChanged;
  final ValueChanged<String> onLanguageChanged;

  const ProfileScreen({
    super.key,
    required this.repository,
    required this.themeMode,
    required this.language,
    required this.onThemeChanged,
    required this.onLanguageChanged,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Vehicle? vehicle;
  final userName = TextEditingController();
  final plate = TextEditingController();

  // Tiga controller untuk sheet "Perbarui Nomor Plat". Umurnya sengaja mengikuti
  // halaman ini, sama seperti `userName`/`plate` — bukan mengikuti sheet-nya.
  //
  // Sheet-nya sendiri masih hidup selama animasi keluar (~200ms) sesudah
  // `await showModalBottomSheet` selesai: selama itu field-nya masih membangun
  // ulang dan mencabut fokus. Keduanya menyentuh controller, jadi membuangnya
  // tepat setelah `await` membuat Flutter melempar "A TextEditingController was
  // used after being disposed" (dan setelah itu pohon widget-nya rusak:
  // `_dependents.isEmpty`, "Tried to build dirty widget in the wrong build
  // scope"). Isinya di-set ulang setiap sheet dibuka, jadi tidak ada sisa
  // ketikan dari pembukaan sebelumnya.
  final plateRegion = TextEditingController();
  final plateNumber = TextEditingController();
  final plateSuffix = TextEditingController();
  String? photoPath;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    userName.dispose();
    plate.dispose();
    plateRegion.dispose();
    plateNumber.dispose();
    plateSuffix.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    final overlay = Overlay.of(context);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Positioned(
        left: 0,
        right: 0,
        bottom: 80,
        child: Material(
          color: Colors.transparent,
          child: SafeArea(
            top: false,
            child: Container(
              color: Theme.of(context).colorScheme.inverseSurface,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: Text(
                message,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onInverseSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future<void>.delayed(const Duration(seconds: 2), entry.remove);
  }

  Future<void> _load() async {
    final value = await widget.repository.loadVehicle();
    if (!mounted) return;
    vehicle = value;
    if (value != null) {
      userName.text = value.userName;
      plate.text = value.plateNumber;
      photoPath = value.photoPath;
    }
    setState(() {});
  }

  Future<void> _pickPhoto() async {
    final l10n = AppLocalizations.of(context);
    final source = await showPhotoSourceSheet(context);
    if (source == null) return;
    try {
      final photo = await ImagePicker().pickImage(
        source: source,
        imageQuality: 80,
      );
      if (photo != null && mounted) {
        final croppedPath = await cropProfilePhoto(context, photo.path);
        if (croppedPath != null && mounted) {
          setState(() => photoPath = croppedPath);
        }
      }
    } on MissingPluginException {
      if (mounted) _showMessage(l10n.t('restart_picker'));
    } catch (_) {
      if (mounted) _showMessage(l10n.t('restart_picker'));
    }
  }

  Future<void> _showPlateSheet() async {
    final current = plate.text.trim().toUpperCase().split(RegExp(r'\s+'));
    plateRegion.text = current.elementAtOrNull(0) ?? '';
    plateNumber.text = current.elementAtOrNull(1) ?? '';
    plateSuffix.text = current.elementAtOrNull(2) ?? '';
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: Material(
          color: Theme.of(sheetContext).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Perbarui Nomor Plat',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Masukkan nomor plat kendaraan',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _plateInput(
                          controller: plateRegion,
                          label: 'Kode',
                          maxLength: 2,
                          keyboardType: TextInputType.text,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 4,
                        child: _plateInput(
                          controller: plateNumber,
                          label: 'Angka',
                          maxLength: 4,
                          keyboardType: TextInputType.number,
                          digitsOnly: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: _plateInput(
                          controller: plateSuffix,
                          label: 'Seri',
                          maxLength: 3,
                          keyboardType: TextInputType.text,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        final values = [
                          plateRegion.text.trim().toUpperCase(),
                          plateNumber.text.trim(),
                          plateSuffix.text.trim().toUpperCase(),
                        ].where((value) => value.isNotEmpty).toList();
                        if (plateRegion.text.trim().isEmpty ||
                            plateNumber.text.trim().isEmpty) {
                          return;
                        }
                        Navigator.pop(sheetContext, values.join(' '));
                      },
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Simpan Nomor Plat'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() => plate.text = result);
      await _save();
    }
  }

  Future<void> _correctOdometer() async {
    final value = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OdometerCorrectionSheet(
        initialValue: vehicle?.odometerKm ?? 0,
        vehicle: vehicle,
      ),
    );
    if (value == null || value < 0) return;
    await widget.repository.updateOdometer(value);
    await _load();
  }

  Widget _plateInput({
    required TextEditingController controller,
    required String label,
    required int maxLength,
    required TextInputType keyboardType,
    bool digitsOnly = false,
  }) {
    return TextField(
      controller: controller,
      textAlign: TextAlign.center,
      textCapitalization: TextCapitalization.characters,
      keyboardType: keyboardType,
      maxLength: maxLength,
      inputFormatters: [
        if (digitsOnly)
          FilteringTextInputFormatter.digitsOnly
        else
          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
      ],
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      ),
    );
  }

  Future<void> _save() async {
    if (vehicle == null || saving) return;
    setState(() => saving = true);
    final updated = vehicle!.copyWith(
      userName: userName.text.trim(),
      plateNumber: plate.text.trim(),
      photoPath: photoPath,
    );
    try {
      await widget.repository.saveVehicle(updated);
      if (!mounted) return;
      setState(() => vehicle = updated);
      _showMessage(AppLocalizations.of(context).t('profile_saved'));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final name = userName.text.trim();

    return Scaffold(
      appBar: AppBar(
        // Header tab ini tidak punya tombol back; lihat catatan di
        // appBarTheme soal `titleSpacing: 0` yang berlaku untuk leading kosong.
        titleSpacing: 16,
        title: Text(
          l10n.t('profile'),
          // Desain: `text-lg font-bold tracking-tight` = 18px w700.
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.45,
          ),
        ),
        shape: Border(bottom: BorderSide(color: colors.outlineVariant)),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SettingsScreen(
                  themeMode: widget.themeMode,
                  language: widget.language,
                  onThemeChanged: widget.onThemeChanged,
                  onLanguageChanged: widget.onLanguageChanged,
                ),
              ),
            ),
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.t('settings'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _card(
            context,
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      key: ValueKey(
                        photoPath == null
                            ? 'profile-avatar-fallback'
                            : 'profile-avatar-photo',
                      ),
                      radius: 48,
                      backgroundColor: colors.primaryContainer,
                      child: ClipOval(
                        child: Image(
                          image: ResizeImage.resizeIfNeeded(
                            192,
                            192,
                            photoPath == null
                                ? const AssetImage(
                                    'stitch_odomate_modern_ui/odomate_rider_avatar_updated_full/screen.png',
                                  )
                                : FileImage(File(photoPath!)),
                          ),
                          fit: BoxFit.cover,
                          width: 96,
                          height: 96,
                          errorBuilder: (context, error, stackTrace) =>
                              Image.asset(
                                'stitch_odomate_modern_ui/odomate_rider_avatar_updated_full/screen.png',
                                cacheWidth: 192,
                                cacheHeight: 192,
                                fit: BoxFit.cover,
                                width: 96,
                                height: 96,
                              ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: -4,
                      bottom: -2,
                      child: IconButton.filled(
                        onPressed: _pickPhoto,
                        icon: const Icon(Icons.photo_camera_outlined, size: 18),
                        tooltip: l10n.t('add_photo'),
                        style: IconButton.styleFrom(
                          minimumSize: const Size.square(36),
                          side: BorderSide(
                            color: Theme.of(context).cardColor,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  name.isEmpty ? l10n.t('user_name') : name,
                  textAlign: TextAlign.center,
                  // Desain: `text-xl font-bold tracking-tight` = 20px w700. Bukan
                  // titleLarge (22px) dan bukan w800 — w800 di desain selalu angka.
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _card(
            context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader(
                  context,
                  icon: Icons.badge_outlined,
                  title: l10n.t('profile'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: userName,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: l10n.t('user_name'),
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _card(
            context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader(
                  context,
                  icon: Icons.two_wheeler_outlined,
                  title: l10n.t('vehicle_name'),
                  trailing: vehicle == null
                      ? null
                      : Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primaryContainer.withValues(
                                alpha: 0.14,
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              vehicle!.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 14),
                // Dua kotak sejajar dengan bahasa yang sama: label kecil di
                // dalam kotak, nilainya di bawahnya — persis pasangan "Nomor
                // Pelat"/"Odometer Terkini" di desain. Sebelumnya yang kiri
                // memakai field Material dengan label melayang dan ikon di
                // dalamnya, sehingga kotaknya 9px lebih tinggi dan labelnya
                // tidak sebaris dengan yang kanan.
                //
                // Keduanya juga bukan input lagi: menyentuh salah satu kotak
                // membuka sheet-nya masing-masing (`_showPlateSheet` /
                // `_correctOdometer`), jadi isinya murni tampilan.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      // Seluruh kotak jadi sasaran ketuk, bukan hanya chip-nya
                      // yang cuma setinggi teksnya (~26px).
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _showPlateSheet,
                        child: _bentoCell(
                          context,
                          label: l10n.t('plate'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              // Desain: `bg-on-surface text-surface-bright` —
                              // dibalik di tema gelap, dan `colors.surface`
                              // memang kebalikan `onSurface` di kedua tema.
                              color: colors.onSurface,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              plate.text,
                              maxLines: 1,
                              style: TextStyle(
                                // Desain: `font-bold tracking-wider text-xs`.
                                color: colors.surface,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _correctOdometer,
                        child: _bentoCell(
                          context,
                          label: l10n.t('odometer'),
                          child: Text(
                            '${(vehicle?.odometerKm ?? 0).toStringAsFixed(1)} km',
                            // Desain: `text-lg font-extrabold` = 18px w800. Ini
                            // angka, jadi w800 memang benar di sini.
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: vehicle == null || saving ? null : _save,
            icon: saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(l10n.t('save_profile')),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.verified_user_outlined,
                size: 18,
                color: colors.tertiary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  l10n.t('offline_notifications'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, {required Widget child}) => Card(
    child: Padding(padding: const EdgeInsets.all(16), child: child),
  );

  /// Satu sel "bento" dari desain: kotak berbingkai, label kecil di dalamnya di
  /// bagian atas, nilainya di bawah.
  ///
  /// Tingginya dipaku ke satu angka yang dipakai **kedua** sel, bukan diserahkan
  /// ke isinya. Dulu hanya kotak odometer yang punya batas tinggi sendiri (`56`,
  /// disamakan dengan field di sebelahnya) dan isinya jadi 65 — tepi bawahnya
  /// menonjol 9px. Menyamakan dua kotak lewat `IntrinsicHeight` juga tidak bisa
  /// di sini: `InputDecorator` melaporkan tinggi intrinsik yang jauh lebih besar
  /// dari yang benar-benar dirender (101 vs 71), jadi barisnya ikut melar.
  ///
  /// `minHeight` (bukan `height`) supaya teks yang diperbesar pengaturan
  /// aksesibilitas menambah tinggi kotak, bukan meluber keluar.
  Widget _bentoCell(
    BuildContext context, {
    required String label,
    required Widget child,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(minHeight: 76),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        // Desain: `flex flex-col justify-between` — label menempel atas, nilai
        // menempel bawah, sisa ruang di antaranya.
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              // Desain: `text-[11px] font-medium`; `height` dipadatkan supaya
              // barisnya tidak menambah tinggi kotak.
              fontSize: 11,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  Widget _sectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    Widget? trailing,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colors.primary),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          if (trailing != null) ...[const SizedBox(width: 8), trailing],
        ],
      ),
    );
  }
}
