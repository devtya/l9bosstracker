# L9 Boss Tracker

Aplikasi Flutter Android untuk melacak waktu respawn world boss di **LordNine** (server H3), dengan countdown timer live, progress bar per boss, filter berdasarkan guild, dan notifikasi lokal 5 menit sebelum boss respawn.

## Fitur

- 📋 Daftar boss fixed (jadwal mingguan tetap) dan dynamic (dihitung dari waktu kematian terakhir)
- ⏱️ Countdown timer live per boss, update tiap detik
- 📊 Progress bar visual menunjukkan seberapa dekat waktu respawn
- 🔔 Notifikasi lokal otomatis 5 menit sebelum boss respawn
- 🏷️ Filter berdasarkan guild (BloodMoon, Dynasty, Requiem, Danketsu, Kransia)
- 🌗 Dark/light mode (toggle manual)
- 📑 Tab terpisah untuk boss yang masih aktif/terjadwal vs yang sudah lewat ("Alive")

Data waktu kematian boss dynamic diambil secara live dari Google Sheet komunitas via [opensheet.elk.sh](https://opensheet.elk.sh/), dan direfresh otomatis setiap 60 detik.

## Kredit

Konsep dan logic perhitungan respawn boss di aplikasi ini terinspirasi dari **[boss-timer](https://github.com/romanjhefferson/boss-timer)** oleh [romanjhefferson](https://github.com/romanjhefferson) — sebuah web app sederhana berbasis HTML/JavaScript yang melacak respawn boss menggunakan sumber data Google Sheet yang sama.

Aplikasi ini adalah implementasi ulang penuh sebagai native Android app menggunakan Flutter, dengan tambahan fitur notifikasi lokal, progress bar visual, dark/light mode, dan penyesuaian lain — namun ide dasar (tipe boss fixed/dynamic, sumber data sheet, dan logic perhitungan waktu respawn) berasal dari project tersebut.

## Cara Build

### Build manual (debug)
```bash
flutter pub get
flutter build apk --debug
```

### Build manual (release)
```bash
flutter pub get
flutter build apk --release
```
APK hasil build ada di `build/app/outputs/flutter-apk/app-release.apk`.

### Build otomatis via GitHub Actions (release APK)

Setiap kali ada tag baru yang di-push dengan format `vX.Y.Z` (contoh: `v1.0.0`), GitHub Actions akan otomatis:
1. Build APK release
2. Membuat GitHub Release baru
3. Mengunggah APK ke halaman Release tersebut, siap didownload

Untuk trigger build & release baru:
```bash
git tag v1.0.0
git push origin v1.0.0
```

APK hasil build bisa didownload dari tab **[Releases](../../releases)** repo ini.

## Tech Stack

- **Flutter** (Android)
- `http` — fetch data dari Google Sheet
- `flutter_local_notifications` + `timezone` + `flutter_timezone` — notifikasi terjadwal yang timezone-aware
- `shared_preferences` — menyimpan preferensi tema (dark/light)

## Struktur Project

```
lib/
  models/      # BossConfig, BossStatus, BossDisplayData, BossDeathTime
  data/        # Konfigurasi boss statis + sheet service (fetch & parse)
  logic/       # Kalkulasi respawn, filter guild, notification service
  widgets/     # Card boss, filter bar, tab bar
  screens/     # Home screen
```

## Lisensi

Project ini dibuat untuk keperluan pribadi/komunitas, tidak berafiliasi resmi dengan LordNine atau pengembangnya.
