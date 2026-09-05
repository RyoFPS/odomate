# OdoMate Statistics & Ride Insights

Date: 2026-09-05  
Status: Approved for implementation planning

## Goal

Memberi pemilik motor ringkasan penggunaan kendaraan yang mudah dipahami dari data ride lokal yang sudah tersimpan, tanpa backend, akun, atau dependency chart tambahan.

## Scope

Included:

- Statistik jarak tempuh hari ini, 7 hari terakhir, dan bulan berjalan.
- Jumlah ride pada periode aktif.
- Rata-rata jarak per ride.
- Total jarak kendaraan dari seluruh ride tersimpan.
- Ringkasan servis: jumlah item, servis jatuh tempo, dan servis terdekat.
- Halaman Statistics yang tetap memakai tema dan localization aplikasi.
- Akses dari Home melalui card ringkasan dan dari tab utama tanpa mengubah bottom navigation yang ada.

Excluded:

- Grafik dengan package chart baru.
- Peta atau visualisasi rute.
- Perbandingan antar kendaraan.
- Sinkronisasi cloud atau export data.
- Prediksi konsumsi bahan bakar atau biaya servis.

## User flow

1. User membuka halaman Statistics dari card baru di Home atau tab navigasi.
2. Halaman menampilkan default periode “7 hari terakhir”.
3. User dapat memilih “Hari ini”, “7 hari”, atau “Bulan ini”.
4. Card statistik berubah berdasarkan periode tanpa mengubah data ride.
5. Card servis tetap menunjukkan kondisi servis terkini berdasarkan odometer kendaraan.
6. Jika belum ada ride, halaman menampilkan empty state dan tetap menampilkan total servis.

## Data and calculation rules

- Sumber utama adalah `rides` dan `service_items` melalui `OdomateRepository`.
- Ride dihitung berdasarkan `startedAt` lokal perangkat.
- Ride dengan `distanceKm == 0` tetap dihitung sebagai ride, tetapi tidak menambah jarak.
- “Hari ini” berarti dari awal hari lokal sampai saat ini.
- “7 hari” berarti enam hari sebelumnya ditambah hari ini.
- “Bulan ini” berarti dari hari pertama bulan lokal sampai saat ini.
- Rata-rata jarak hanya membagi total jarak dengan jumlah ride pada periode tersebut.
- Total jarak kendaraan dihitung dari seluruh ride tersimpan, bukan dari selisih odometer manual.
- Servis terdekat adalah item dengan sisa kilometer terkecil; item jatuh tempo diprioritaskan.

## UI

- Tambahkan card “Statistik perjalanan” di Home dengan jarak periode default dan jumlah ride.
- Tambahkan halaman `StatisticsScreen` dengan segmented period selector.
- Gunakan card Material 3 sederhana, tanpa chart package.
- Tampilkan unit kilometer dengan satu angka desimal.
- Sediakan empty state yang tidak error ketika data ride kosong.
- Semua copy utama tersedia dalam Indonesia, English, dan Jepang melalui localization yang sudah ada.

## Acceptance checks

- Statistik hari ini hanya menghitung ride berdasarkan tanggal lokal hari ini.
- Filter 7 hari dan bulan ini menghasilkan rentang tanggal yang benar.
- Total jarak, jumlah ride, dan rata-rata jarak sesuai data repository.
- Ride nol kilometer tidak menyebabkan pembagian nol atau crash.
- Total jarak kendaraan tetap benar setelah koreksi odometer manual.
- Status servis pada card statistik mengikuti odometer terbaru.
- Home dapat membuka Statistics dan bottom navigation tetap konsisten.
- Reopening aplikasi mempertahankan hasil karena statistik dihitung dari SQLite.
- `flutter analyze`, seluruh unit/widget test, dan `flutter build apk --debug` pass.
