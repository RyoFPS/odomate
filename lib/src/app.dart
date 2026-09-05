import 'package:flutter/material.dart';

import 'data/odomate_repository.dart';
import 'notifications/notification_service.dart';
import 'tracking/ride_tracker.dart';
import 'screens/setup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/services_screen.dart';
import 'screens/history_screen.dart';

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
              const _ProfilePage(),
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
      body: widget.pages[index],
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton.extended(
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
        icon: Icon(active ? Icons.stop : Icons.play_arrow),
        label: Text(active ? 'Stop Ride' : 'Start Ride'),
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

class _ProfilePage extends StatelessWidget {
  const _ProfilePage();
  @override
  Widget build(BuildContext context) => const Center(child: Text('Profile'));
}
