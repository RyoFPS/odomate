import 'package:flutter/material.dart';

import 'data/odomate_repository.dart';
import 'notifications/notification_service.dart';
import 'tracking/ride_tracker.dart';
import 'screens/setup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/services_screen.dart';
import 'screens/history_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';

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
  final navigatorKey = GlobalKey<NavigatorState>();
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    hasVehicle = await widget.repository.loadVehicle() != null;
    await widget.notifications.initialize();
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'OdoMate',
    navigatorKey: navigatorKey,
    themeMode: themeMode,
    theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
    darkTheme: ThemeData.dark(useMaterial3: true),
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
                onSettings: () => navigatorKey.currentState!.push(
                  MaterialPageRoute(
                    builder: (_) => SettingsScreen(
                      themeMode: themeMode,
                      language: language,
                      onThemeChanged: (v) => setState(() => themeMode = v),
                      onLanguageChanged: (v) => setState(() => language = v),
                    ),
                  ),
                ),
              ),
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
              setState(() {});
            },
        tooltip: active ? 'Stop Ride' : 'Start Ride',
        child: Icon(active ? Icons.stop : Icons.play_arrow),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _tab(0, Icons.home_outlined, 'Home'),
            _tab(1, Icons.history, 'Riwayat'),
            const SizedBox(width: 48),
            _tab(2, Icons.build_outlined, 'Service'),
            _tab(3, Icons.person_outline, 'Profile'),
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
