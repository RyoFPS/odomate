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
      if (mounted) {
        _showMessage(l10n.t('restart_picker'));
      }
    } catch (_) {
      if (mounted) {
        _showMessage(l10n.t('restart_picker'));
      }
    }
  }

  Future<void> _save() async {
    if (vehicle == null) return;
    await widget.repository.saveVehicle(
      vehicle!.copyWith(
        userName: userName.text.trim(),
        plateNumber: plate.text.trim(),
        photoPath: photoPath,
      ),
    );
    if (!mounted) return;
    setState(
      () => vehicle = vehicle!.copyWith(
        userName: userName.text.trim(),
        plateNumber: plate.text.trim(),
        photoPath: photoPath,
      ),
    );
    _showMessage(AppLocalizations.of(context).t('profile_saved'));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('profile')),
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
            icon: const Icon(Icons.settings),
            tooltip: l10n.t('settings'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onTap: _pickPhoto,
                  child: CircleAvatar(
                    radius: 52,
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primaryContainer,
                    backgroundImage: photoPath == null
                        ? null
                        : FileImage(File(photoPath!)),
                    child: photoPath == null
                        ? Icon(
                            Icons.person,
                            size: 52,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: IconButton.filled(
                    onPressed: _pickPhoto,
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                    tooltip: l10n.t('add_photo'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              userName.text.isEmpty ? l10n.t('user_name') : userName.text,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              vehicle?.name ?? '',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _sectionCard(
            context,
            title: l10n.t('user_name'),
            icon: Icons.badge_outlined,
            child: Column(
              children: [
                TextField(
                  controller: userName,
                  decoration: InputDecoration(labelText: l10n.t('user_name')),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: plate,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(labelText: l10n.t('plate')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: Icon(
                Icons.two_wheeler_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(vehicle?.name ?? l10n.t('vehicle_name')),
              subtitle: Text(
                '${plate.text.isEmpty ? '-' : plate.text} · '
                '${(vehicle?.odometerKm ?? 0).toStringAsFixed(1)} km',
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check),
            label: Text(l10n.t('save_profile')),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    ),
  );
}
