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
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.t('theme'), style: Theme.of(context).textTheme.titleMedium),
          SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(
                value: ThemeMode.light,
                label: Text(l10n.t('light')),
                icon: const Icon(Icons.light_mode),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text(l10n.t('dark')),
                icon: const Icon(Icons.dark_mode),
              ),
            ],
            selected: {themeMode},
            onSelectionChanged: (value) {
              setState(() => themeMode = value.first);
              widget.onThemeChanged(value.first);
            },
          ),
          const Divider(),
          DropdownButtonFormField<String>(
            initialValue: language,
            decoration: InputDecoration(labelText: l10n.t('language')),
            items: [
              DropdownMenuItem(value: 'id', child: Text(l10n.t('indonesian'))),
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
        ],
      ),
    );
  }
}
