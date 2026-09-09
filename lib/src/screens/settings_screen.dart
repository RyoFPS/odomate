import 'package:flutter/material.dart';

import '../i18n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final String language;
  final ValueChanged<ThemeMode> onThemeChanged;
  final ValueChanged<String> onLanguageChanged;
  const SettingsScreen({
    super.key,
    required this.themeMode,
    required this.language,
    required this.onThemeChanged,
    required this.onLanguageChanged,
  });
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late ThemeMode themeMode = widget.themeMode;
  late String language = widget.language;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('settings'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _card(
            context,
            icon: Icons.palette_outlined,
            title: l10n.t('theme'),
            child: SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text(l10n.t('light')),
                  icon: const Icon(Icons.light_mode_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text(l10n.t('dark')),
                  icon: const Icon(Icons.dark_mode_outlined),
                ),
              ],
              selected: {themeMode},
              onSelectionChanged: (value) {
                setState(() => themeMode = value.first);
                widget.onThemeChanged(value.first);
              },
            ),
          ),
          const SizedBox(height: 12),
          _card(
            context,
            icon: Icons.translate_outlined,
            title: l10n.t('language'),
            child: DropdownButtonFormField<String>(
              initialValue: language,
              decoration: InputDecoration(labelText: l10n.t('language')),
              items: [
                DropdownMenuItem(
                  value: 'id',
                  child: Text(l10n.t('indonesian')),
                ),
                DropdownMenuItem(value: 'en', child: Text(l10n.t('english'))),
                DropdownMenuItem(value: 'ja', child: Text(l10n.t('japanese'))),
              ],
              onChanged: (v) {
                if (v != null) {
                  setState(() => language = v);
                  widget.onLanguageChanged(v);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(
    BuildContext context, {
    required IconData icon,
    required String title,
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
