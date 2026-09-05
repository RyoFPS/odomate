# OdoMate MVP Design

Date: 2026-09-05
Status: Approved for specification review

## Goal

OdoMate membantu pemilik satu motor mencatat odometer dan mengingat jadwal servis berdasarkan jarak tempuh. MVP menghitung jarak dari GPS ponsel saat user mengaktifkan ride, lalu menyimpan semua data secara lokal.

## Scope

Included:

- Satu kendaraan.
- Odometer awal yang dimasukkan user.
- Start Ride dan Stop Ride manual.
- GPS tracking di background saat ride aktif.
- Perhitungan jarak dan pembaruan odometer otomatis.
- Riwayat perjalanan lokal.
- Daftar item servis dengan interval kilometer yang dapat diubah.
- Pencatatan servis selesai.
- Notifikasi tracking aktif dan pengingat servis lokal.
- Koreksi odometer manual.

Excluded from MVP:

- Peta atau visualisasi rute.
- Akun dan login.
- Sinkronisasi cloud.
- Multi-kendaraan.
- Notifikasi kompleks atau server push.
- Integrasi ECU atau sensor kendaraan.

## User flow

### First setup

1. User memasukkan nama motor dan odometer awal.
2. User memberikan izin lokasi yang diperlukan.
3. Aplikasi menampilkan Home.

### Ride

1. User menekan Start Ride.
2. Aplikasi memulai background location tracking dan notifikasi permanen.
3. Titik GPS yang valid dibandingkan dengan titik sebelumnya.
4. Jarak valid ditambahkan ke ride aktif dan odometer total.
5. User menekan Stop Ride.
6. Aplikasi menghentikan tracking, menyimpan ride, dan menyimpan odometer terbaru.

Tracking harus tetap berjalan saat layar mati atau user berganti aplikasi. Android memerlukan foreground service dengan notifikasi aktif. iOS memerlukan izin Always dan background location. Force close dari system switcher dapat menghentikan tracking di iOS.

### Service

Setiap service item memiliki nama, interval kilometer, dan odometer saat terakhir diservis. Status dihitung dari odometer saat ini:

- Mendekat: sisa jarak <= 200 km dan masih di atas 0.
- Jatuh tempo: odometer saat ini >= odometer terakhir servis + interval.
- Aman: belum masuk dua kondisi di atas.

Notifikasi lokal:

- Saat ride aktif: `OdoMate sedang merekam perjalanan`.
- 200 km sebelum jatuh tempo: `Servis mendekat`.
- Saat jatuh tempo atau terlewati: `Sudah waktunya servis`.

Setiap notifikasi servis hanya dikirim sekali per siklus. Setelah user mencatat servis selesai, titik acuan diperbarui ke odometer saat itu dan siklus notifikasi dimulai kembali.

## Screens

- Setup awal: nama motor, odometer awal, dan izin lokasi.
- Home: odometer saat ini, kontrol Start Ride/Stop Ride, ringkasan servis, dan status GPS.
- Ride aktif: durasi, jarak sementara, odometer terbaru, status GPS, dan Stop Ride.
- Servis: daftar servis, status jarak, interval, tambah/edit item, dan tandai selesai.
- Riwayat: riwayat ride dan servis serta koreksi odometer.

## Data model

- `Vehicle`: singleton untuk nama kendaraan, odometer awal, dan odometer saat ini.
- `Ride`: waktu mulai, waktu selesai, jarak GPS, durasi, dan status akurasi.
- `ServiceItem`: nama, interval kilometer, dan odometer terakhir diservis.
- `ServiceLog`: item servis, waktu, odometer, dan catatan opsional.

Semua data disimpan lokal dan harus tetap tersedia setelah aplikasi dibuka ulang. Tidak ada backend pada MVP.

## GPS and error handling

- Start Ride ditolak jika lokasi belum aktif atau izin minimum belum diberikan.
- Titik dengan akurasi buruk tidak langsung dihitung.
- Kehilangan sinyal tidak mengarang jarak; ride menunggu titik valid berikutnya.
- Lonjakan lokasi atau jarak negatif yang tidak wajar diabaikan.
- Data ride ditulis berkala sehingga ride terakhir dapat dipulihkan setelah aplikasi mati mendadak.
- User dapat mengoreksi odometer secara manual.

## Acceptance checks

- Start Ride memulai tracking background.
- Tracking tetap berjalan ketika layar mati dan saat user berganti aplikasi.
- Stop Ride menyimpan jarak dan memperbarui odometer.
- Reopening aplikasi mempertahankan data kendaraan, ride, servis, dan odometer.
- Notifikasi ride aktif tampil selama tracking dan hilang setelah Stop Ride.
- Notifikasi servis muncul 200 km sebelum jatuh tempo dan saat jatuh tempo.
- Mencatat servis selesai menghentikan notifikasi siklus lama dan memulai siklus baru.
- Titik GPS buruk, kehilangan sinyal, dan lonjakan lokasi tidak merusak odometer.
