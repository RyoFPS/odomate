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
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2D65B7)),
      textTheme: GoogleFonts.poppinsTextTheme(),
      useMaterial3: true,
    ),
    darkTheme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF5E9BE6),
        brightness: Brightness.dark,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
      useMaterial3: true,
    ),
    debugShowCheckedModeBanner: false,
    home: loading
        ? const Scaffold(body: Center(child: CircularProgressIndicator()))
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
  Widget _tab(int value, IconData icon, String label) => IconButton(
    onPressed: () => setState(() => index = value),
    tooltip: label,
    icon: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    ),
  );
}
