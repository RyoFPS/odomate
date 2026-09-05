import 'package:flutter/material.dart';

import 'data/odomate_repository.dart';
import 'notifications/notification_service.dart';
import 'tracking/ride_tracker.dart';
import 'screens/setup_screen.dart';
import 'screens/home_screen.dart';

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
        ? HomeScreen(repository: widget.repository, tracker: widget.tracker)
        : SetupScreen(
            repository: widget.repository,
            onSaved: () => setState(() => hasVehicle = true),
          ),
  );
}
