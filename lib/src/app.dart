import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import 'data/odomate_repository.dart';
import 'i18n/app_localizations.dart';
import 'notifications/notification_service.dart';
import 'screens/history_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/services_screen.dart';
import 'screens/setup_screen.dart';
import 'screens/statistics_screen.dart';
import 'tracking/ride_tracker.dart';

class OdoMateApp extends StatefulWidget {
  final OdomateRepository repository;
  final RideTracker tracker;
  final NotificationService notifications;
  const OdoMateApp({
    super.key,
    required this.repository,
    required this.tracker,
    required this.notifications,
  });
  @override
  State<OdoMateApp> createState() => _OdoMateAppState();
}

class _OdoMateAppState extends State<OdoMateApp> {
  bool loading = true, hasVehicle = false;
  ThemeMode themeMode = ThemeMode.light;
  String language = 'id';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    hasVehicle = await widget.repository.loadVehicle() != null;
    await widget.notifications.initialize();
    await widget.tracker.restore();
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'OdoMate',
    themeMode: themeMode,
    locale: Locale(language),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    themeAnimationDuration: const Duration(milliseconds: 300),
    theme: _theme(Brightness.light),
    darkTheme: _theme(Brightness.dark),
    debugShowCheckedModeBanner: false,
    home: loading
        ? const _SplashScreen()
        : hasVehicle
        ? MainNavigation(
            tracker: widget.tracker,
            pages: [
              HomeScreen(
                repository: widget.repository,
                tracker: widget.tracker,
              ),
              HistoryScreen(repository: widget.repository),
              ServicesScreen(repository: widget.repository),
              ProfileScreen(
                repository: widget.repository,
                themeMode: themeMode,
                language: language,
                onThemeChanged: (v) => setState(() => themeMode = v),
                onLanguageChanged: (v) => setState(() => language = v),
              ),
              StatisticsScreen(repository: widget.repository),
            ],
          )
        : SetupScreen(
            repository: widget.repository,
            onSaved: () => setState(() => hasVehicle = true),
          ),
  );

  ThemeData _theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: brightness,
        ).copyWith(
          primary: dark ? const Color(0xFF93B4FF) : const Color(0xFF2563EB),
          onPrimary: dark ? const Color(0xFF0F172A) : Colors.white,
          primaryContainer: dark
              ? const Color(0xFF1D4ED8)
              : const Color(0xFF2563EB),
          secondary: dark ? const Color(0xFFB7C8E1) : const Color(0xFF505F76),
          tertiary: dark ? const Color(0xFF79DB8D) : const Color(0xFF15803D),
          surface: dark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          surfaceContainer: dark
              ? const Color(0xFF1E293B)
              : const Color(0xFFEDEDF9),
          surfaceContainerLow: dark
              ? const Color(0xFF172033)
              : const Color(0xFFF8FAFC),
          outlineVariant: dark
              ? const Color(0xFF475569)
              : const Color(0xFFE2E8F0),
          onSurface: dark ? const Color(0xFFF0F0FB) : const Color(0xFF191B23),
          onSurfaceVariant: dark
              ? const Color(0xFFCBD5E1)
              : const Color(0xFF434655),
        );
    final base = dark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;
    return ThemeData(
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark ? scheme.surface : const Color(0xFFF8FAFC),
      textTheme: GoogleFonts.interTextTheme(base).apply(
        bodyColor: dark ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A),
        displayColor: dark ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: dark ? scheme.surface : Colors.white,
        foregroundColor: dark
            ? const Color(0xFFF8FAFC)
            : const Color(0xFF0F172A),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: dark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: dark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: dark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      useMaterial3: true,
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Spacer(flex: 3),
              Container(
                width: 112,
                height: 112,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: .16),
                      blurRadius: 36,
                    ),
                  ],
                ),
                child: Image.asset(
                  'stitch_odomate_modern_ui/odomate_transparent_mark/screen.png',
                ),
              ),
              const SizedBox(height: 24),
              Text.rich(
                TextSpan(
                  text: 'Odo',
                  children: [
                    TextSpan(
                      text: 'Mate',
                      style: TextStyle(color: colors.primary),
                    ),
                  ],
                ),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Buku Log & Perawatan Kendaraan Roda Dua',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.secondary,
                ),
              ),
              const SizedBox(height: 28),
              const LinearProgressIndicator(minHeight: 5),
              const Spacer(flex: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 17,
                    color: colors.secondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Aman & 100% Offline-First',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  final List<Widget> pages;
  final RideTracker? tracker;
  final bool rideActive;
  final VoidCallback? onRide;
  const MainNavigation({
    super.key,
    required this.pages,
    this.tracker,
    this.rideActive = false,
    this.onRide,
  });
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    final active = widget.tracker?.state.value.active ?? widget.rideActive;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: _page(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        elevation: 6,
        onPressed:
            widget.onRide ??
            () async {
              if (active) {
                await widget.tracker!.stop();
              } else {
                await widget.tracker!.start();
              }
              if (mounted) setState(() {});
            },
        tooltip: active ? l10n.t('stop_ride') : l10n.t('start_ride'),
        child: Icon(active ? Icons.stop : Icons.play_arrow),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).colorScheme.surface
            : Colors.white,
        elevation: 0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _tab(0, Icons.home_outlined, l10n.t('home')),
            _tab(1, Icons.history, l10n.t('history')),
            const SizedBox(width: 48),
            _tab(2, Icons.build_outlined, l10n.t('service')),
            _tab(3, Icons.person_outline, l10n.t('profile')),
          ],
        ),
      ),
    );
  }

  Widget _page() {
    final page = widget.pages[index];
    if (page is HomeScreen) {
      return HomeScreen(
        repository: page.repository,
        tracker: page.tracker,
        onNavigate: _select,
      );
    }
    return page;
  }

  void _select(int value) => setState(() => index = value);
  Widget _tab(int value, IconData icon, String label) {
    final selected = index == value;
    final color = selected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return IconButton(
      onPressed: () => setState(() => index = value),
      tooltip: label,
      color: color,
      icon: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
