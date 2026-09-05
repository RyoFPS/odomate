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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.t('restart_picker'))));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.t('restart_picker'))));
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).t('profile_saved'))),
    );
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
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickPhoto,
              child: CircleAvatar(
                radius: 52,
                backgroundImage: photoPath == null
                    ? null
                    : FileImage(File(photoPath!)),
                child: photoPath == null
                    ? const Icon(Icons.person, size: 52)
                    : null,
              ),
            ),
          ),
          Center(
            child: TextButton.icon(
              onPressed: _pickPhoto,
              icon: const Icon(Icons.photo_camera),
              label: Text(l10n.t('add_photo')),
            ),
          ),
          TextField(
            controller: userName,
            decoration: InputDecoration(labelText: l10n.t('user_name')),
          ),
          TextField(
            controller: plate,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(labelText: l10n.t('plate')),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: _save, child: Text(l10n.t('save_profile'))),
        ],
      ),
    );
  }
}
