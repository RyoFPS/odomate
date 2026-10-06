import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

import '../diagnostics/diagnostic_log.dart';
import '../i18n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final String language;
  final bool usesKilometers;
  final bool serviceReminders;
  final int serviceInterval;
  final ValueChanged<ThemeMode> onThemeChanged;
  final ValueChanged<String> onLanguageChanged;
  final ValueChanged<bool>? onUsesKilometersChanged;
  final ValueChanged<bool>? onServiceRemindersChanged;
  final ValueChanged<int>? onServiceIntervalChanged;

  const SettingsScreen({
    super.key,
    required this.themeMode,
    required this.language,
    required this.onThemeChanged,
    required this.onLanguageChanged,
    this.usesKilometers = true,
    this.serviceReminders = true,
    this.serviceInterval = 2000,
    this.onUsesKilometersChanged,
    this.onServiceRemindersChanged,
    this.onServiceIntervalChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();
  late ThemeMode _themeMode = widget.themeMode;
  late String _language = widget.language;
  late bool _usesKilometers = widget.usesKilometers;
  late bool _serviceReminders = widget.serviceReminders;
  late int _serviceInterval = widget.serviceInterval;
  bool _diagnosticLogsEnabled = DiagnosticLog.instance.enabled;
  bool _sharingDiagnostics = false;

  @override
  void didUpdateWidget(covariant SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _themeMode = widget.themeMode;
    _language = widget.language;
    _usesKilometers = widget.usesKilometers;
    _serviceReminders = widget.serviceReminders;
    _serviceInterval = widget.serviceInterval;
  }

  String _t(String key) => AppLocalizations.of(context).t(key);

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
              _t('settings_subtitle'),
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
            title: _t('settings_theme_title'),
            description: _t('settings_theme_description'),
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
                    label: Text(_t('settings_theme_system')),
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
            title: _t('settings_language_units_title'),
            description: _t('settings_language_units_description'),
            child: Column(
              children: [
                _languageTile(
                  colors,
                  code: 'id',
                  country: 'ID',
                  title: 'Bahasa Indonesia',
                  subtitle: _t('settings_language_device_default'),
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
                      _t('settings_distance_format'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _t('settings_active_unit').replaceAll('{unit}', _unit()),
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
                        label: Text(_t('settings_kilometers')),
                      ),
                      ButtonSegment(
                        value: false,
                        icon: const Icon(Icons.pin_drop_outlined),
                        label: Text(_t('settings_miles')),
                      ),
                    ],
                    selected: {_usesKilometers},
                    onSelectionChanged: (values) {
                      final value = values.first;
                      setState(() => _usesKilometers = value);
                      widget.onUsesKilometersChanged?.call(value);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _section(
            context,
            icon: Icons.two_wheeler_outlined,
            title: _t('settings_tracking_title'),
            description: _t('settings_tracking_description'),
            child: Column(
              children: [
                _switchTile(
                  colors,
                  title: _t('settings_service_alerts_title'),
                  subtitle: _t('settings_service_alerts_description'),
                  value: _serviceReminders,
                  onChanged: (value) {
                    setState(() => _serviceReminders = value);
                    widget.onServiceRemindersChanged?.call(value);
                  },
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
            title: _t('settings_storage_title'),
            description: _t('settings_storage_description'),
            child: _storageStatus(colors),
          ),
          const SizedBox(height: 16),
          _section(
            context,
            icon: Icons.privacy_tip_outlined,
            title: _t('settings_diagnostics_title'),
            description: _t('settings_diagnostics_description'),
            child: Column(
              children: [
                _switchTile(
                  colors,
                  title: _t('settings_diagnostics_opt_in'),
                  subtitle: _t('settings_diagnostics_opt_in_description'),
                  value: _diagnosticLogsEnabled,
                  onChanged: _setDiagnosticLogsEnabled,
                ),
                Divider(height: 1, color: colors.outlineVariant),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _diagnosticLogsEnabled && !_sharingDiagnostics
                        ? _exportDiagnostics
                        : null,
                    icon: const Icon(Icons.ios_share_outlined),
                    label: Text(_t('settings_diagnostics_export')),
                  ),
                ),
              ],
            ),
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
          ? colors.surfaceContainer
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
    shadowColor: WidgetStatePropertyAll(colors.shadow.withValues(alpha: .12)),
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
          _t('settings_offline_active'),
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
      _t('settings_reminder_interval_title'),
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    ),
    subtitle: Text(
      _t('settings_reminder_interval_description'),
      style: TextStyle(color: colors.onSurfaceVariant, fontSize: 10),
    ),
    trailing: PopupMenuButton<int>(
      initialValue: _serviceInterval,
      onSelected: (value) {
        setState(() => _serviceInterval = value);
        widget.onServiceIntervalChanged?.call(value);
      },
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

  Future<void> _setDiagnosticLogsEnabled(bool value) async {
    setState(() => _diagnosticLogsEnabled = value);
    final saved = await DiagnosticLog.instance.setEnabled(value);
    if (!mounted || saved) return;
    setState(() => _diagnosticLogsEnabled = DiagnosticLog.instance.enabled);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_t('settings_diagnostics_save_failed'))),
    );
  }

  Future<void> _exportDiagnostics() async {
    setState(() => _sharingDiagnostics = true);
    try {
      final file = await DiagnosticLog.instance.exportFile();
      if (!mounted) return;
      if (file == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_t('settings_diagnostics_empty'))),
        );
        return;
      }
      await SharePlus.instance.share(
        ShareParams(
          files: [file],
          fileNameOverrides: [file.name],
          subject: _t('settings_diagnostics_export'),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_t('settings_diagnostics_export_failed'))),
        );
      }
    } finally {
      if (mounted) setState(() => _sharingDiagnostics = false);
    }
  }

  String _unit() => _usesKilometers ? 'km' : 'mi';

  String _distance(int kilometers) {
    final value = _usesKilometers
        ? kilometers
        : (kilometers * 0.621371).round();
    final separator = _language == 'en' ? ',' : '.';
    final formatted = value.toString().replaceAllMapped(
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
                _t('settings_local_storage'),
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
              ),
              Text(
                _t('settings_offline_ready'),
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
            _t('settings_optimal'),
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
            FutureBuilder<PackageInfo>(
              future: _packageInfo,
              builder: (context, snapshot) {
                final info = snapshot.data;
                return Text(
                  info == null
                      ? 'OdoMate'
                      : 'OdoMate v${info.version} (Build ${info.buildNumber})',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Text(
        _t('settings_footer'),
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
