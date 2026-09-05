# OdoMate Ride History & Trip Details

Date: 2026-09-05  
Status: Draft for review

## Goal

Membuat riwayat perjalanan OdoMate lebih berguna dengan filter periode dan halaman detail untuk setiap ride yang tersimpan, tanpa mengubah sistem tracking GPS atau menambah backend.

## Scope

Included:

- Riwayat ride dalam card yang menampilkan tanggal, jarak, waktu mulai, dan status selesai.
- Filter `Hari ini`, `7 hari terakhir`, dan `Bulan ini` menggunakan aturan periode yang sudah dipakai Statistics.
- Halaman detail ride saat card dipilih.
- Detail waktu mulai, waktu selesai, durasi bila tersedia, dan jarak perjalanan.
- Empty state, loading state, dan repository error state.
- Localization Indonesia, English, dan Japanese.
- Reuse `OdomateRepository.listRides()` dan `RideStatistics` tanpa tabel baru.
- Bottom navigation dan Start Ride FAB tetap tidak berubah.

Excluded:

- Peta, polyline, atau replay rute GPS.
- Edit atau hapus ride pada MVP ini; penghapusan membutuhkan aturan pembalikan odometer yang aman setelah koreksi manual.
- Export, share, cloud sync, multi-vehicle, dan backend.
- Perubahan terhadap algoritma tracking atau penyimpanan titik GPS.

## User flow

1. User membuka Riwayat dari bottom navigation atau card Riwayat di Home.
2. Halaman menampilkan ride terbaru dengan default filter `Semua` agar seluruh histori tetap terlihat.
3. User memilih periode untuk menyaring ride berdasarkan `startedAt` lokal perangkat.
4. User mengetuk sebuah ride untuk membuka detail.
5. User kembali memakai tombol back halaman atau bottom navigation yang tetap tersedia pada shell aplikasi.

## Data and calculation rules

- Sumber data adalah `OdomateRepository.listRides()`.
- Ride diurutkan dari `startedAt` terbaru ke terlama.
- Filter memakai batas lokal inklusif pada awal periode dan eksklusif pada awal periode berikutnya.
- Ride aktif ditampilkan sebagai `Sedang berlangsung` dan tidak memiliki waktu selesai/durasi final.
- Durasi ride selesai adalah `endedAt - startedAt`; jika timestamp tidak valid, tampilkan fallback tanpa crash.
- Jarak menggunakan satu angka desimal dan unit kilometer.
- Tidak ada perubahan odometer saat user hanya membuka histori atau detail.

## UI

- App bar berjudul `Riwayat` dengan filter segmented/chips di bagian atas.
- Ride ditampilkan sebagai card ringkas dengan ikon rute, tanggal, jarak, dan durasi/status.
- Detail memakai halaman internal dengan AppBar back button karena ini adalah nested detail flow.
- Semua teks baru melewati `AppLocalizations` untuk ID/EN/JA.
- Tampilan mengikuti tema terang/gelap dan Poppins yang sudah digunakan aplikasi.

## Acceptance checks

- Histori menampilkan ride terbaru berdasarkan data repository.
- Filter hari ini, 7 hari, dan bulan ini memakai batas tanggal lokal yang benar.
- Card ride membuka detail yang menampilkan data ride yang sama.
- Ride aktif tidak menyebabkan crash dan menunjukkan status yang jelas.
- Empty, loading, dan error state stabil.
- Bahasa ID/EN/JA berubah untuk seluruh copy baru.
- Tema terang/gelap tetap terbaca.
- Bottom navigation lima slot dan Start Ride FAB tetap konsisten.
- `flutter analyze`, seluruh test, dan `flutter build apk --debug` pass.
