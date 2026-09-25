import 'package:flutter/material.dart';

import '../domain/models.dart';

/// Kosakata bersama antara halaman daftar Servis dan halaman Tambah Servis.
/// Warnanya disalin apa adanya dari kelas Tailwind di
/// `stitch_odomate_modern_ui/odomate_servis/code.html` dan
/// `stitch_odomate_modern_ui/odomate_tambah_servis/code.html`, jadi keduanya
/// tidak bisa lagi melenceng satu sama lain.
/// Theme-aware status colors shared by the service list and detail screens.
typedef ServiceTone = ({
  Color icon, // ikon di dalam kotak status
  Color soft, // latar kotak status
  Color softBorder, // garis kotak status
  Color card, // garis kartu
  Color chipBg, // latar badge status
  Color chipText, // teks badge status
  Color line, // teks baris "Lewat … km" / "Sisa … km"
  Color metricNumber, // angka di kotak metrik kartu ringkasan
  Color metricLabel, // label di kotak metrik kartu ringkasan
  FontWeight chipWeight, // desain memakai font-bold khusus kartu jatuh tempo
});

ServiceTone serviceTone(ServiceStatus status, ColorScheme colors) {
  final dark = colors.brightness == Brightness.dark;
  return switch (status) {
    ServiceStatus.due => (
      icon: dark ? colors.error : const Color(0xFFE11D48),
      soft: dark ? colors.errorContainer : const Color(0xFFFFF1F2),
      softBorder: dark
          ? colors.error.withValues(alpha: .45)
          : const Color(0xFFFFE4E6),
      card: dark
          ? colors.error.withValues(alpha: .65)
          : const Color(0xFFFECDD3),
      chipBg: dark ? colors.errorContainer : const Color(0xFFFFE4E6),
      chipText: dark ? colors.onErrorContainer : const Color(0xFFBE123C),
      line: dark ? colors.error : const Color(0xFFE11D48),
      metricNumber: dark ? colors.error : const Color(0xFFBE123C),
      metricLabel: dark ? colors.error : const Color(0xFFE11D48),
      chipWeight: FontWeight.w700,
    ),
    ServiceStatus.dueSoon => (
      icon: dark ? colors.secondary : const Color(0xFFB45309),
      soft: dark ? colors.secondaryContainer : const Color(0xFFFFFBEB),
      softBorder: dark
          ? colors.secondary.withValues(alpha: .45)
          : const Color(0xFFFEF3C7),
      card: dark
          ? colors.secondary.withValues(alpha: .65)
          : const Color(0xFFFDE68A).withValues(alpha: .8),
      chipBg: dark ? colors.secondaryContainer : const Color(0xFFFEF3C7),
      chipText: dark ? colors.onSecondaryContainer : const Color(0xFF92400E),
      line: dark ? colors.secondary : const Color(0xFFB45309),
      metricNumber: dark ? colors.secondary : const Color(0xFFB45309),
      metricLabel: dark ? colors.secondary : const Color(0xFFB45309),
      chipWeight: FontWeight.w600,
    ),
    ServiceStatus.safe => (
      icon: dark ? colors.tertiary : const Color(0xFF047857),
      soft: dark
          ? colors.tertiary.withValues(alpha: .18)
          : const Color(0xFFECFDF5),
      softBorder: dark
          ? colors.tertiary.withValues(alpha: .45)
          : const Color(0xFFD1FAE5),
      card: colors.outlineVariant.withValues(alpha: .3), // outline-variant/30
      chipBg: dark
          ? colors.tertiary.withValues(alpha: .22)
          : const Color(0xFFD1FAE5),
      chipText: dark ? colors.tertiary : const Color(0xFF065F46),
      line: colors.secondary,
      metricNumber: dark ? colors.tertiary : const Color(0xFF047857),
      metricLabel: dark ? colors.tertiary : const Color(0xFF047857),
      chipWeight: FontWeight.w600,
    ),
  };
}

/// Desain menulis semua angka kilometer dengan pemisah ribuan titik
/// (`24.582 km`), jadi tidak ada pemisah desimal.
String serviceKm(double value) => value.round().toString().replaceAllMapped(
  RegExp(r'\B(?=(\d{3})+(?!\d))'),
  (_) => '.',
);

/// Ikon untuk nama servis yang diketik bebas. Urutannya penting: "Oli Gardan"
/// harus kena cabang gardan sebelum cabang oli.
IconData serviceIcon(String name) {
  final value = name.toLowerCase();
  if (value.contains('gardan')) return Icons.settings_suggest_outlined;
  if (value.contains('oli')) return Icons.oil_barrel_outlined;
  if (value.contains('busi') || value.contains('listrik')) {
    return Icons.bolt_rounded;
  }
  if (value.contains('aki') || value.contains('baterai')) {
    return Icons.battery_charging_full_rounded;
  }
  if (value.contains('cvt') || value.contains('roller')) {
    return Icons.autorenew_rounded;
  }
  if (value.contains('filter')) return Icons.air_rounded;
  if (value.contains('rem')) return Icons.stop_circle_outlined;
  if (value.contains('ban')) return Icons.trip_origin_rounded;
  return Icons.build_outlined;
}

/// Satu tombol di katalog "Pilih Cepat Komponen" pada halaman Tambah Servis.
class ServicePreset {
  final String name;
  final IconData icon;

  /// Interval yang disarankan saat preset ini dipilih.
  ///
  /// `null` untuk komponen yang intervalnya tidak tercatat di
  /// `_defaultServices` halaman Servis — app ini tidak punya angka pabrikan
  /// yang bisa dipertanggungjawabkan untuk komponen itu, jadi kolom intervalnya
  /// sengaja dibiarkan kosong untuk diisi pengguna daripada diisi karangan.
  final double? intervalKm;

  const ServicePreset(this.name, this.icon, [this.intervalKm]);
}

const servicePresets = <ServicePreset>[
  ServicePreset('Ganti Oli Mesin', Icons.oil_barrel_outlined, 2000),
  ServicePreset('Oli Gardan', Icons.settings_suggest_outlined, 8000),
  ServicePreset('Servis CVT & Roller', Icons.autorenew_rounded),
  ServicePreset('Filter Udara', Icons.air_rounded, 12000),
  ServicePreset('Busi (Spark Plug)', Icons.bolt_rounded, 8000),
  ServicePreset('Kampas Rem', Icons.stop_circle_outlined),
  ServicePreset('Aki & Kelistrikan', Icons.battery_charging_full_rounded),
  ServicePreset('Ban Depan / Belakang', Icons.trip_origin_rounded),
];
