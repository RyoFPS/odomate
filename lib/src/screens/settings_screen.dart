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
  late ThemeMode _themeMode = widget.themeMode;
  late String _language = widget.language;
  bool _usesKilometers = true;
  bool _autoTrack = true;
  bool _serviceReminders = true;
  int _serviceInterval = 2000;

  String _copy(String id, String en, String ja) => switch (_language) {
    'en' => en,
    'ja' => ja,
    _ => id,
  };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        ),
        // Jaraknya ke judul datang dari appBarTheme — halaman inilah yang jadi
        // referensinya, jadi tidak ada yang perlu ditulis ulang di sini.
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.t('settings'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            Text(
              _copy(
                'Konfigurasi OdoMate Motor',
                'Configure OdoMate Motor',
                'OdoMate Motor の設定',
              ),
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: _offlineBadge(colors)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _section(
            context,
            icon: Icons.palette_outlined,
            title: _copy('Tema Tampilan', 'Display Theme', '表示テーマ'),
            description: _copy(
              'Pilih mode kenyamanan layar saat berkendara siang atau malam.',
              'Choose a comfortable display for daytime or night riding.',
              '昼夜の走行に合う表示モードを選択します。',
            ),
            child: _segmentedTrack(
              colors,
              SegmentedButton<ThemeMode>(
                expandedInsets: EdgeInsets.zero,
                showSelectedIcon: false,
                style: _segmentedStyle(colors, 44),
                segments: [
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: const Icon(Icons.light_mode_outlined),
                    label: Text(l10n.t('light')),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: const Icon(Icons.dark_mode_outlined),
                    label: Text(l10n.t('dark')),
                  ),
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: const Icon(Icons.brightness_auto_outlined),
                    label: Text(_copy('Sistem', 'System', 'システム')),
                  ),
                ],
                selected: {_themeMode},
                onSelectionChanged: (values) {
                  final mode = values.first;
                  setState(() => _themeMode = mode);
                  widget.onThemeChanged(mode);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          _section(
            context,
            icon: Icons.translate_outlined,
            title: _copy('Bahasa & Satuan', 'Language & Units', '言語と単位'),
            description: _copy(
              'Tentukan preferensi bahasa antarmuka dan penghitungan jarak.',
              'Choose the interface language and distance unit.',
              '表示言語と距離単位を選択します。',
            ),
            child: Column(
              children: [
                _languageTile(
                  colors,
                  code: 'id',
                  country: 'ID',
                  title: 'Bahasa Indonesia',
                  subtitle: _copy(
                    'Bawaan perangkat',
                    'Device default',
                    '端末のデフォルト',
                  ),
                ),
                const SizedBox(height: 6),
                _languageTile(
                  colors,
                  code: 'en',
                  country: 'US',
                  title: 'English (US)',
                  subtitle: 'United States',
                ),
                const SizedBox(height: 6),
                _languageTile(
                  colors,
                  code: 'ja',
                  country: 'JP',
                  title: '日本語 (Japanese)',
                  subtitle: '日本 (Japan)',
                ),
                const SizedBox(height: 16),
                Divider(height: 1, color: colors.outlineVariant),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _copy('Format Metrik Jarak', 'Distance Format', '距離単位'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _copy(
                        'Aktif: ${_unit()}',
                        'Active: ${_unit()}',
                        '選択中: ${_unit()}',
                      ),
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _segmentedTrack(
                  colors,
                  SegmentedButton<bool>(
                    expandedInsets: EdgeInsets.zero,
                    showSelectedIcon: false,
                    style: _segmentedStyle(colors, 40),
                    segments: [
                      ButtonSegment(
                        value: true,
                        icon: const Icon(Icons.speed_outlined),
                        label: Text(
                          _copy('Kilometer (km)', 'Kilometers (km)', 'キロ (km)'),
                        ),
                      ),
                      ButtonSegment(
                        value: false,
                        icon: const Icon(Icons.pin_drop_outlined),
                        label: Text(
                          _copy('Mil (mi)', 'Miles (mi)', 'マイル (mi)'),
                        ),
                      ),
                    ],
                    selected: {_usesKilometers},
                    onSelectionChanged: (values) =>
                        setState(() => _usesKilometers = values.first),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _section(
            context,
            icon: Icons.two_wheeler_outlined,
            title: _copy(
              'Pencatatan & Odometer',
              'Tracking & Odometer',
              '走行記録とオドメーター',
            ),
            description: _copy(
              'Preferensi lokal untuk sesi pengaturan ini.',
              'Local preferences for this settings session.',
              'この設定セッション内のローカル設定です。',
            ),
            child: Column(
              children: [
                _switchTile(
                  colors,
                  title: 'Auto-track via GPS',
                  subtitle: _copy(
                    'Aktif saat kecepatan di atas 15 km/jam',
                    'Active above 15 km/h',
                    '時速15 km以上で有効',
                  ),
                  value: _autoTrack,
                  onChanged: (value) => setState(() => _autoTrack = value),
                ),
                Divider(height: 1, color: colors.outlineVariant),
                _switchTile(
                  colors,
                  title: _copy(
                    'Pemberitahuan Jadwal Servis',
                    'Service Schedule Alerts',
                    '整備スケジュール通知',
                  ),
                  subtitle: _copy(
                    'Pengingat sebelum jadwal servis',
                    'Reminder before service is due',
                    '整備時期の前に通知',
                  ),
                  value: _serviceReminders,
                  onChanged: (value) =>
                      setState(() => _serviceReminders = value),
                ),
                Divider(height: 1, color: colors.outlineVariant),
                _intervalTile(colors),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _section(
            context,
            icon: Icons.save_outlined,
            title: _copy(
              'Data & Penyimpanan Offline',
              'Data & Offline Storage',
              'データとオフライン保存',
            ),
            description: _copy(
              'Log perjalanan tersimpan lokal tanpa koneksi internet terus-menerus.',
              'Ride logs stay on this device without a constant connection.',
              '走行ログは常時接続なしで端末内に保存されます。',
            ),
            child: _storageStatus(colors),
          ),
          const SizedBox(height: 24),
          _footer(colors),
        ],
      ),
    );
  }

  ButtonStyle _segmentedStyle(ColorScheme colors, double height) => ButtonStyle(
    minimumSize: WidgetStatePropertyAll(Size(0, height)),
    padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 6)),
    backgroundColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? Colors.white
          : Colors.transparent,
    ),
    foregroundColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? colors.primary
          : colors.onSurface,
    ),
    elevation: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected) ? 2 : 0,
    ),
    shadowColor: WidgetStatePropertyAll(Colors.black.withValues(alpha: .12)),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    textStyle: const WidgetStatePropertyAll(
      TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
    ),
    side: const WidgetStatePropertyAll(BorderSide(color: Colors.transparent)),
  );

  Widget _segmentedTrack(ColorScheme colors, Widget child) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
    ),
    child: child,
  );

  Widget _offlineBadge(ColorScheme colors) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: colors.tertiary.withValues(alpha: .08),
      border: Border.all(color: colors.tertiary.withValues(alpha: .24)),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 8, color: colors.tertiary),
        const SizedBox(width: 6),
        Text(
          _copy('Offline Aktif', 'Offline Ready', 'オフライン対応'),
          style: TextStyle(
            color: colors.tertiary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  Widget _section(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Widget child,
  }) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary
                      .withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    ),
  );

  Widget _languageTile(
    ColorScheme colors, {
    required String code,
    required String country,
    required String title,
    required String subtitle,
  }) {
    final selected = _language == code;
    return Material(
      color: selected
          ? colors.primary.withValues(alpha: .05)
          : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? colors.primary : colors.outlineVariant,
          width: selected ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          setState(() => _language = code);
          widget.onLanguageChanged(code);
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(country, style: const TextStyle(fontSize: 11)),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  color: selected ? colors.primary : colors.outline,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _switchTile(
    ColorScheme colors, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    dense: true,
    title: Text(
      title,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    ),
    subtitle: Text(
      subtitle,
      style: TextStyle(color: colors.onSurfaceVariant, fontSize: 10),
    ),
    value: value,
    onChanged: onChanged,
  );

  Widget _intervalTile(ColorScheme colors) => ListTile(
    contentPadding: EdgeInsets.zero,
    dense: true,
    title: Text(
      _copy(
        'Interval Pengingat Servis',
        'Service Reminder Interval',
        '整備通知の間隔',
      ),
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    ),
    subtitle: Text(
      _copy(
        'Berdasarkan akumulasi odometer',
        'Based on odometer distance',
        'オドメーター距離を基準',
      ),
      style: TextStyle(color: colors.onSurfaceVariant, fontSize: 10),
    ),
    trailing: PopupMenuButton<int>(
      initialValue: _serviceInterval,
      onSelected: (value) => setState(() => _serviceInterval = value),
      itemBuilder: (_) => [1000, 2000, 5000]
          .map(
            (value) =>
                PopupMenuItem(value: value, child: Text(_distance(value))),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _distance(_serviceInterval),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 4),
            Icon(Icons.expand_more, size: 16, color: colors.onSurfaceVariant),
          ],
        ),
      ),
    ),
  );

  String _unit() => _usesKilometers ? 'km' : 'mi';

  String _distance(int kilometers) {
    final value = _usesKilometers
        ? kilometers
        : (kilometers * 0.621371).round();
    final separator = _language == 'en' ? ',' : '.';
    final formatted = value.toString().replaceFirstMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (match) => '${match[1]}$separator',
    );
    return '$formatted ${_unit()}';
  }

  Widget _storageStatus(ColorScheme colors) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: colors.surfaceContainerLow,
      border: Border.all(color: colors.outlineVariant),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(Icons.storage_outlined, color: colors.onSurfaceVariant),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _copy('Penyimpanan Log Lokal', 'Local Log Storage', 'ローカルログ保存'),
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
              ),
              Text(
                _copy('Offline siap', 'Offline ready', 'オフライン対応'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: colors.tertiary.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            _copy('Optimal', 'Optimal', '正常'),
            style: TextStyle(
              color: colors.tertiary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _footer(ColorScheme colors) => Column(
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.verified_outlined,
              size: 14,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              'OdoMate v0.1.0 (Build 1)',
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Text(
        _copy(
          'Dibuat untuk pengendara roda dua • Aman & Offline-First',
          'Built for two-wheel riders • Safe & Offline-First',
          '二輪ライダーのために • 安全でオフライン優先',
        ),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: colors.onSurfaceVariant.withValues(alpha: .65),
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}
