# Prompt: L9 Boss Tracker (Flutter, Android)

## Konteks
Saya punya project Flutter baru bernama **L9 Boss Tracker** (sudah di-generate via `flutter create`). Saya mau port logic dari web app boss respawn tracker (vanilla JS) ke Flutter, dengan tambahan fitur alarm/notifikasi.

Referensi logic asli (boss-timer web, ringkasan):
- Data sumber: Google Sheet via endpoint `https://opensheet.elk.sh/1RoupDDa_fQdcowVCNpL2q1mJDDAw3obvIwRQhOp7Z5E/Sheet1`, isinya array of object dengan kolom `Boss`, `H1 DeathTime`, `H3 DeathTime` (format string `M/D/YYYY HH:mm`).
- Ada 2 tipe boss:
  - **`fix`**: jadwal mingguan tetap, didefinisikan sebagai list `{d: dayOfWeek(0=Sunday), h: hour, m: minute}`. Next respawn dihitung dari hari/jam terdekat ke depan.
  - **`dyn`**: respawn dihitung dari `deathTime + hrs` jam. Boss dynamic punya 2 varian waktu kematian: `H1 DeathTime` (disebut "BloodMoon") dan `H3 DeathTime` (per-guild).
- Setiap boss terasosiasi dengan `guild` (BloodMoon, Dynasty, Requiem, Danketsu, Kransia) lewat mapping nama boss → guild.
- Refresh data sheet tiap 60 detik, refresh countdown tiap 1 detik.

## Tujuan
Buat aplikasi Flutter Android dengan fitur:
1. List card per boss, tiap card menampilkan: nama boss, guild/icon, waktu respawn, **countdown timer live**, dan **progress/loading indicator** (visual progress bar dari waktu kill → waktu respawn).
2. **Notifikasi lokal** yang muncul **5 menit sebelum** boss respawn.
3. Filter by guild (dropdown/chip: All, BloodMoon, Dynasty, Requiem, Danketsu, Kransia) — perilaku filter sama seperti versi web (BloodMoon menampilkan semua varian H1 dynamic + semua boss fixed hari ini; guild lain menampilkan H3 dynamic miliknya + boss fixed miliknya).
4. **Tab/section terpisah** untuk boss yang statusnya sudah lewat (`Alive`, yaitu waktu respawn-nya sudah lewat dari sekarang) — dipisahkan dari boss yang masih `Scheduled`/`Today`.
5. Untuk boss dynamic, karena ada 2 waktu respawn (dari H1 dan dari H3), **user bisa pilih salah satu yang ingin di-notifikasi** (toggle/switch di card, default ke salah satu — H3 yang sesuai guild-nya).

## Spesifikasi Detail

### 1. Model data
Buat enum/class untuk:
- `BossType { fixed, dynamic }`
- `Guild { bloodMoon, dynasty, requiem, danketsu, kransia }`
- `FixedSchedule { int dayOfWeek; int hour; int minute; }` (dayOfWeek: 0=Sunday … 6=Saturday, sesuaikan dengan `DateTime.weekday` Dart yang 1=Monday…7=Sunday — perhatikan konversi ini karena source JS pakai `getDay()` yang 0=Sunday)
- `BossConfig { String name; BossType type; Guild guild; List<FixedSchedule>? schedules; int? respawnHours; }`

Port semua data dari `bossConfigs` dan `guildMap` di source JS ke konstanta Dart (lihat lampiran data di bawah).

### 2. Service fetch data sheet
- HTTP GET ke `https://opensheet.elk.sh/1RoupDDa_fQdcowVCNpL2q1mJDDAw3obvIwRQhOp7Z5E/Sheet1` pakai package `http`.
- Parse response JSON jadi `Map<String bossName, {h1DeathTime: DateTime?, h3DeathTime: DateTime?}>`.
- Format tanggal dari sheet: `"M/D/YYYY HH:mm"` (contoh: `6/21/2026 14:30`). Parse manual (regex atau split), JANGAN asumsikan format ISO.
- Auto-refresh tiap 60 detik (gunakan `Timer.periodic` atau `Stream`), dengan error handling kalau fetch gagal (jangan crash, tetap pakai data lama / tampilkan indikator error kecil).

### 3. Logic hitung waktu respawn
- **Fixed boss**: fungsi `nextRespawn(FixedSchedule, DateTime now)` — cari occurrence terdekat ke depan dari hari+jam yang dijadwalkan, mirip fungsi `next(d,h,m)` di source JS. Hati-hati konversi index hari (JS `getDay()` 0-6 Sunday-start vs Dart `weekday` 1-7 Monday-start).
- **Dynamic boss**: `respawnTime = deathTime.add(Duration(hours: cfg.respawnHours))`.
- Status boss:
  - `Alive` jika `respawnTime` sudah lewat (`now > respawnTime`) → masuk tab/section "Alive".
  - `Today` jika fixed dan respawnTime di hari yang sama dengan `now`.
  - `Scheduled` untuk sisanya → masuk section utama.
- Progress untuk loading indicator: `progress = (now - killTime/scheduleStart) / (respawnTime - killTime/scheduleStart)`, clamped 0.0–1.0. Untuk fixed boss tanpa "kill time" yang jelas, progress bisa dihitung dari siklus mingguan (opsional, jelaskan asumsi di kode kalau pendekatan ini dipakai).

### 4. Notifikasi lokal
- Package: `flutter_local_notifications` (gunakan timezone-aware scheduling, dengan package `timezone` untuk `tz.TZDateTime`, set timezone sesuai device — JANGAN hardcode WITA/WIB, pakai `flutter_timezone` untuk deteksi timezone device, KECUALI saya konfirmasi semua user di WITA).
- Schedule one-shot notification di `respawnTime - 5 menit` untuk tiap boss yang aktif dipantau.
- **Untuk boss dynamic**: tambahkan toggle di card (misal `Switch` atau segmented button "Notify: H1 / H3") supaya user pilih mau di-notify berdasarkan H1 atau H3. Hanya notification dari opsi yang dipilih yang di-schedule; yang lain di-cancel.
- **Untuk boss fixed**: notifikasi default aktif untuk semua, dengan toggle on/off per boss kalau user mau matikan.
- Setiap kali data sheet di-refresh (tiap 60 detik) atau toggle diubah, **re-schedule ulang notifikasi** (cancel ID lama dulu sebelum schedule baru, supaya tidak duplikat) — gunakan ID notifikasi yang stabil & unik per boss (misal hash dari nama boss).
- Pastikan `AndroidManifest.xml` punya permission & receiver yang benar:
  - `android.permission.SCHEDULE_EXACT_ALARM` atau `USE_EXACT_ALARM` (sesuaikan target SDK)
  - `android.permission.POST_NOTIFICATIONS` (Android 13+, perlu runtime request)
  - Receiver `com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver` dan `ScheduledNotificationBootReceiver` di `<application>` tag — ini sering jadi sumber bug "notifikasi gak muncul" kalau kelewat.
- Request runtime permission notifikasi (Android 13+) saat app pertama dibuka.

### 5. UI
- Halaman utama: filter chip/dropdown guild di atas (seperti `<select>` di versi web), lalu list card boss.
- Tab/segmented control dengan 2 section: **"Aktif"** (status Today/Scheduled) dan **"Alive"** (status sudah lewat) — bisa pakai `TabBar` atau toggle button di atas list.
- Tiap card boss menampilkan:
  - Nama boss + icon guild (emoji sesuai mapping: 🌙 BloodMoon, 👑 Dynasty, 🖤 Requiem, ⚔️ Danketsu, 🔰 Kransia)
  - Waktu respawn (format readable, misal "21 Jun, 14:30 (Sunday)")
  - Countdown text live (update tiap detik, format `Xh Ym Zs`)
  - **Progress indicator** (`LinearProgressIndicator` atau custom circular) menunjukkan seberapa dekat ke waktu respawn
  - Warna/badge berbeda kalau countdown < 1 jam (urgent) vs < 6 jam (soon) — mirip `row-verysoon`/`row-soon` di versi web
  - Untuk boss dynamic: toggle pilihan notifikasi H1/H3
- Gunakan `StatefulWidget` + `Timer.periodic(Duration(seconds: 1))` untuk update countdown UI tanpa rebuild seluruh list (pertimbangkan `ValueNotifier` per card atau `AnimatedBuilder` agar efisien, supaya tidak rebuild seluruh `ListView` tiap detik).

## Constraint Teknis
- Target platform: **Android only**.
- State management: pakai yang paling simpel yang cocok dengan codebase saya saat ini (kalau belum ada state management lain, `setState` + `ValueNotifier` cukup; jangan over-engineer dengan Bloc/Riverpod kecuali saya minta).
- Sebelum implementasi, **tampilkan dulu rencana/plan dan struktur file** yang akan dibuat (nama file, package yang akan ditambahkan ke `pubspec.yaml`), saya review dulu sebelum kamu eksekusi kode.
- Setelah saya approve plan, baru implementasi bertahap: (1) model + data config, (2) service fetch sheet, (3) logic respawn/status, (4) notifikasi, (5) UI.
- Test dulu logic parsing tanggal & hitung next respawn dengan beberapa contoh kasus manual sebelum lanjut ke notifikasi.

## Lampiran: Data Boss (port persis dari source)

### guildMap (boss → guild)
```
Tumier, Benji, Chaiflock, Rakajeth, Libitina, Supore, Asta, Ordo, Secreta, Auraq, Catena, Titore, Gareth, Larba → Dynasty
Roderick, Ringor, Shuliar, Duplican, Metus, Wannitas, Milavy, Baron Braudmore, Amentis → Requiem
Thymele, General Aquleus, Lady Dalia, Neutro, Saphirus, Undomiel, Araneo, Livera, Clemantis, Ego, Viorent, Venatus → Danketsu
Icaruthia, Motti, Nevaeh, Lucus → Kransia
```
(Catatan: di source JS, boss dynamic ditampilkan di section "H1 (BloodMoon)" terlepas dari guild mapping-nya — BloodMoon bukan guild asli tapi label untuk varian H1. Pertahankan perilaku ini.)

### bossConfigs
```
Fixed:
Icaruthia: Tue 21:00, Fri 21:00
Motti: Wed 19:00, Sat 19:00
Nevaeh: Sun 22:00
Lucus: Sat 22:00
Clemantis: Mon 11:30, Thu 19:00
Saphirus: Sun 17:00, Tue 11:30
Neutro: Tue 19:00, Thu 11:30
Thymele: Mon 19:00, Wed 11:30
Milavy: Sat 15:00
Ringor: Sat 17:00
Roderick: Fri 19:00
Auraq: Fri 22:00, Wed 21:00
Chaiflock: Sun 15:00
Benji: Sun 21:00
Tumier: Sun 19:00
Libitina: Mon 21:00, Sat 21:00
Rakajeth: Tue 22:00, Sun 19:00

Dynamic (nama: jam respawn setelah death time):
Venatus: 10, Viorent: 10, Ego: 21, Livera: 24, Araneo: 24, Undomiel: 24,
Lady Dalia: 18, General Aquleus: 29, Amentis: 29, Baron Braudmore: 32,
Wannitas: 48, Metus: 48, Duplican: 48, Shuliar: 35, Larba: 35, Gareth: 32,
Titore: 37, Catena: 35, Secreta: 62, Ordo: 62, Asta: 62, Supore: 62
```
(Catatan: index hari di atas saya tulis dalam nama hari untuk kejelasan — di source asli pakai angka `d` dengan 0=Sunday. Tolong dikonversi dengan benar ke representasi yang dipakai di Dart.)

## Output yang diharapkan dari kamu sekarang
1. Konfirmasi pemahaman terhadap requirement di atas.
2. Tampilkan rencana struktur file & daftar package yang mau ditambahkan ke `pubspec.yaml`.
3. **Jangan langsung tulis kode** — tunggu saya approve plan dulu.
