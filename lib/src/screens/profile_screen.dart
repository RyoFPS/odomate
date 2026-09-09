import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../data/odomate_repository.dart';
import '../domain/models.dart';
import '../i18n/app_localizations.dart';
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
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.t('gallery')),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(l10n.t('camera')),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      final photo = await ImagePicker().pickImage(
        source: source,
        imageQuality: 80,
      );
      if (photo != null && mounted) {
        setState(() => photoPath = photo.path);
      }
    } on MissingPluginException {
      if (mounted) _showMessage(l10n.t('restart_picker'));
    } catch (_) {
      if (mounted) _showMessage(l10n.t('restart_picker'));
    }
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
        title: Text(
          l10n.t('profile'),
          style: const TextStyle(fontWeight: FontWeight.w700),
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
                      radius: 48,
                      backgroundColor: colors.primaryContainer,
                      backgroundImage: photoPath == null
                          ? null
                          : FileImage(File(photoPath!)),
                      child: photoPath == null
                          ? Icon(
                              Icons.person,
                              size: 52,
                              color: colors.onPrimaryContainer,
                            )
                          : null,
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
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: plate,
                        textCapitalization: TextCapitalization.characters,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: l10n.t('plate'),
                          prefixIcon: const Icon(Icons.pin_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 56),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.outlineVariant),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.t('odometer'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: colors.onSurfaceVariant),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${(vehicle?.odometerKm ?? 0).toStringAsFixed(1)} km',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ],
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
