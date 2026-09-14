import 'package:flutter/material.dart';

import '../domain/models.dart';

/// Kosakata bersama antara halaman daftar Servis dan halaman Tambah Servis.
/// Warnanya disalin apa adanya dari kelas Tailwind di
/// `stitch_odomate_modern_ui/odomate_servis/code.html` dan
/// `stitch_odomate_modern_ui/odomate_tambah_servis/code.html`, jadi keduanya
/// tidak bisa lagi melenceng satu sama lain.
const serviceBlue = Color(0xFF2563EB);
const serviceRed = Color(0xFFBE123C);
const serviceAmber = Color(0xFFB45309);
const serviceGreen = Color(0xFF047857);

/// Tint per status servis. `serviceRed`, `serviceAmber`, dan `serviceGreen`
/// kebetulan sudah sama persis dengan shade -700 yang dipakai desain untuk
/// angka metrik dan ikon, jadi yang perlu didefinisikan di sini hanya tint muda
/// dan shade -600 / -800.
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

ServiceTone serviceTone(ServiceStatus status, ColorScheme colors) =>
    switch (status) {
      ServiceStatus.due => (
        icon: const Color(0xFFE11D48), // rose-600
        soft: const Color(0xFFFFF1F2), // rose-50
        softBorder: const Color(0xFFFFE4E6), // rose-100
        card: const Color(0xFFFECDD3), // rose-200
        chipBg: const Color(0xFFFFE4E6), // rose-100
        chipText: serviceRed, // rose-700
        line: const Color(0xFFE11D48), // rose-600
        metricNumber: serviceRed, // rose-700
        // Satu-satunya kotak metrik yang labelnya lebih muda dari angkanya:
        // desain menulis `text-rose-600` untuk label "Jatuh Tempo".
        metricLabel: const Color(0xFFE11D48), // rose-600
        chipWeight: FontWeight.w700,
      ),
      ServiceStatus.dueSoon => (
        icon: serviceAmber, // amber-700
        soft: const Color(0xFFFFFBEB), // amber-50
        softBorder: const Color(0xFFFEF3C7), // amber-100
        card: const Color(0xFFFDE68A).withValues(alpha: .8), // amber-200/80
        chipBg: const Color(0xFFFEF3C7), // amber-100
        chipText: const Color(0xFF92400E), // amber-800
        line: serviceAmber, // amber-700
        metricNumber: serviceAmber, // amber-700
        metricLabel: serviceAmber, // amber-700
        chipWeight: FontWeight.w600,
      ),
      ServiceStatus.safe => (
        icon: serviceGreen, // emerald-700
        soft: const Color(0xFFECFDF5), // emerald-50
        softBorder: const Color(0xFFD1FAE5), // emerald-100
        card: colors.outlineVariant.withValues(alpha: .3), // outline-variant/30
        chipBg: const Color(0xFFD1FAE5), // emerald-100
        chipText: const Color(0xFF065F46), // emerald-800
        line: colors.secondary, // text-secondary, bukan hijau
        metricNumber: serviceGreen, // emerald-700
        metricLabel: serviceGreen, // emerald-700
        chipWeight: FontWeight.w600,
      ),
    };

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

  /// Warna ikon, disalin dari shade -600 kotak emoji di desain.
  final Color tint;

  /// Latar kotak ikon (shade -100 di desain).
  final Color soft;

  /// Interval yang disarankan saat preset ini dipilih.
  ///
  /// `null` untuk komponen yang intervalnya tidak tercatat di
  /// `_defaultServices` halaman Servis — app ini tidak punya angka pabrikan
  /// yang bisa dipertanggungjawabkan untuk komponen itu, jadi kolom intervalnya
  /// sengaja dibiarkan kosong untuk diisi pengguna daripada diisi karangan.
  final double? intervalKm;

  const ServicePreset(this.name, this.icon, this.tint, this.soft, [
    this.intervalKm,
  ]);
}

const servicePresets = <ServicePreset>[
  ServicePreset(
    'Ganti Oli Mesin',
    Icons.oil_barrel_outlined,
    Color(0xFFE11D48),
    Color(0xFFFFE4E6),
    2000,
  ),
  ServicePreset(
    'Oli Gardan',
    Icons.settings_suggest_outlined,
    Color(0xFFD97706),
    Color(0xFFFEF3C7),
    8000,
  ),
  ServicePreset(
    'Servis CVT & Roller',
    Icons.autorenew_rounded,
    Color(0xFF4F46E5),
    Color(0xFFE0E7FF),
  ),
  ServicePreset(
    'Filter Udara',
    Icons.air_rounded,
    Color(0xFFEA580C),
    Color(0xFFFFEDD5),
    12000,
  ),
  ServicePreset(
    'Busi (Spark Plug)',
    Icons.bolt_rounded,
    Color(0xFF047857),
    Color(0xFFD1FAE5),
    8000,
  ),
  ServicePreset(
    'Kampas Rem',
    Icons.stop_circle_outlined,
    Color(0xFF2563EB),
    Color(0xFFDBEAFE),
  ),
  ServicePreset(
    'Aki & Kelistrikan',
    Icons.battery_charging_full_rounded,
    Color(0xFF0D9488),
    Color(0xFFCCFBF1),
  ),
  ServicePreset(
    'Ban Depan / Belakang',
    Icons.trip_origin_rounded,
    Color(0xFF9333EA),
    Color(0xFFF3E8FF),
  ),
];
