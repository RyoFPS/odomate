import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Settings')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Tema', style: Theme.of(context).textTheme.titleMedium),
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(
              value: ThemeMode.light,
              label: Text('Terang'),
              icon: Icon(Icons.light_mode),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              label: Text('Gelap'),
              icon: Icon(Icons.dark_mode),
            ),
          ],
          selected: {themeMode},
          onSelectionChanged: (value) => onThemeChanged(value.first),
        ),
        const Divider(),
        DropdownButtonFormField<String>(
          initialValue: language,
          decoration: const InputDecoration(labelText: 'Bahasa'),
          items: const [
            DropdownMenuItem(value: 'id', child: Text('Bahasa Indonesia')),
            DropdownMenuItem(value: 'en', child: Text('English')),
          ],
          onChanged: (v) {
            if (v != null) onLanguageChanged(v);
          },
        ),
      ],
    ),
  );
}
