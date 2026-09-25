import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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

/// Tema OdoMate.
///
/// Dipisah jadi fungsi publik supaya test bisa merender layar dengan tema yang
/// benar-benar dipakai app. Tanpa ini, test yang mengukur apa pun dari tema —
/// misalnya geometri AppBar — akan mengukur tema bawaan Material, dan angkanya
/// menyesatkan.
ThemeData odomateTheme(Brightness brightness) =>
    _OdoMateAppState.themeFor(brightness);

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
    // Vehicle loading and notification setup are independent. Start both
    // before awaiting either so cold launch does not serialize local I/O and
    // plugin initialization. Tracker restore stays after notifications
    // because an active ride may publish a tracking notification.
    final vehicleFuture = widget.repository.loadVehicle();
    await widget.notifications.initialize();
    final vehicle = await vehicleFuture;
    hasVehicle = vehicle != null;
    await widget.tracker.restore();
    if (vehicle != null) {
      for (final service in await widget.repository.listServices()) {
        await widget.notifications.maybeNotifyService(
          service,
          vehicle.odometerKm,
        );
      }
    }
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
    theme: odomateTheme(Brightness.light),
    darkTheme: odomateTheme(Brightness.dark),
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
                onLanguageChanged: (v) {
                  widget.notifications.setLanguage(v);
                  widget.tracker.setLanguage(v);
                  setState(() => language = v);
                },
              ),
              StatisticsScreen(repository: widget.repository),
            ],
          )
        : SetupScreen(
            repository: widget.repository,
            onSaved: () => setState(() => hasVehicle = true),
          ),
  );

  static ThemeData themeFor(Brightness brightness) {
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
          surfaceContainerHighest: dark
              ? const Color(0xFF334155)
              : const Color(0xFFE2E8F0),
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
    // DESIGN.md typography scale: Poppins 600 headline, 400 body, 500 label.
    // The family carries all five weights (see pubspec.yaml), so the weight set
    // here is what picks the face: 600 resolves to Poppins-SemiBold.ttf.
    final textTheme = base
        .copyWith(
          displayLarge: base.displayLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          displayMedium: base.displayMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          displaySmall: base.displaySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          headlineLarge: base.headlineLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          headlineMedium: base.headlineMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          headlineSmall: base.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          bodyLarge: base.bodyLarge?.copyWith(fontWeight: FontWeight.w400),
          bodyMedium: base.bodyMedium?.copyWith(fontWeight: FontWeight.w400),
          bodySmall: base.bodySmall?.copyWith(fontWeight: FontWeight.w400),
          labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w500),
          labelMedium: base.labelMedium?.copyWith(fontWeight: FontWeight.w500),
          labelSmall: base.labelSmall?.copyWith(fontWeight: FontWeight.w500),
        )
        .apply(
          fontFamily: 'Poppins',
          bodyColor: dark ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A),
          displayColor: dark
              ? const Color(0xFFE2E8F0)
              : const Color(0xFF0F172A),
        );
    return ThemeData(
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: dark
            ? const Color(0xFFF8FAFC)
            : const Color(0xFF0F172A),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 64,
        shape: Border(
          bottom: BorderSide(
            color: dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        // Jarak tombol back ke judul ditulis sekali di sini, dengan halaman
        // Setting sebagai referensinya (jaraknya 16px di sana). Asalnya:
        // leading duduk di slot selebar `leadingWidth`, judul mulai di
        // `leadingWidth + titleSpacing`, dan ikon back selalu tepat di tengah
        // slot — jadi 56 + 0 menaruh tepi kanan ikon 24 di x=40 dan judul di
        // x=56. Layar berback tidak perlu mengeset apa pun lagi; mengubah salah
        // satu angka di sini menggeser keenamnya sekaligus.
        //
        // `titleSpacing: 0` ikut berlaku untuk AppBar yang TIDAK punya leading,
        // dan di situ judulnya jadi menempel ke tepi kiri layar — AppBar
        // semacam itu (header tab) harus menulis `titleSpacing`-nya sendiri.
        leadingWidth: 56,
        titleSpacing: 0,
        // Tanpa ini, judul AppBar yang cuma mengeset weight akan mewarisi
        // titleLarge Material 3 — 22px — dan 22px tidak dipakai di satu pun layar
        // desain. Ukuran header di desain selalu ditulis eksplisit per layar
        // (16 di notifikasi/history, 18 di profile/settings/tambah servis, 20 di
        // servis/ride detail, 24 di onboarding). Nilai di sini adalah jaring
        // pengaman untuk layar yang tidak menulis ukurannya sendiri; layar yang
        // desainnya beda tetap mengeset fontSize-nya masing-masing.
        // family-nya harus ditulis ulang karena textTheme.apply() tidak sampai
        // ke titleTextStyle.
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.45, // tracking-tight dari desain
          color: dark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
        ),
      ),
      cardTheme: CardThemeData(
        color: dark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
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
    final l10n = AppLocalizations.of(context);
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
                  color: colors.surfaceContainer,
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
                l10n.t('splash_subtitle'),
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
                    l10n.t('splash_safe_offline'),
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
    final l10n = AppLocalizations.of(context);
    if (index == 4 && widget.pages.length > 4) {
      final page = widget.pages[4];
      if (page is StatisticsScreen) {
        return PopScope<void>(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) setState(() => index = 0);
          },
          child: StatisticsScreen(
            repository: page.repository,
            now: page.now,
            onBack: () => setState(() => index = 0),
          ),
        );
      }
    }
    return Scaffold(
      // Bottom bar dan tombol Start Ride harus tetap terpaku di dasar layar.
      // Dengan `resizeToAvoidBottomInset` default (true), Scaffold mengangkat
      // keduanya ke atas keyboard begitu ada TextField yang difokuskan — di
      // halaman Profile tombol Start ikut naik saat mengganti nama atau plat.
      // Body tetap membawa `viewInsets`-nya, jadi TextField yang difokuskan
      // masih di-scroll ke atas keyboard oleh scrollable di dalamnya.
      resizeToAvoidBottomInset: false,
      body: _page(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _rideButton(l10n),
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

  Widget _rideButton(AppLocalizations l10n) {
    final tracker = widget.tracker;
    if (tracker == null) {
      return FloatingActionButton(
        shape: const CircleBorder(),
        elevation: 6,
        onPressed: widget.onRide,
        tooltip: widget.rideActive ? l10n.t('stop_ride') : l10n.t('start_ride'),
        child: Icon(widget.rideActive ? Icons.stop : Icons.play_arrow),
      );
    }
    return ValueListenableBuilder<RideTrackingState>(
      valueListenable: tracker.state,
      builder: (context, state, _) => FloatingActionButton(
        shape: const CircleBorder(),
        elevation: 6,
        onPressed: () async {
          if (state.active) {
            await tracker.stop();
          } else {
            await tracker.start();
          }
          if (!context.mounted || tracker.state.value.error == null) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(tracker.state.value.error!)));
        },
        tooltip: state.active ? l10n.t('stop_ride') : l10n.t('start_ride'),
        child: Icon(
          state.active
              ? (state.waitingForFix ? Icons.gps_not_fixed : Icons.stop)
              : Icons.play_arrow,
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
