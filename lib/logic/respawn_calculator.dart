import '../models/boss_config.dart';
import '../models/boss_status.dart';

class RespawnCalculator {
  /// Cari occurrence terdekat ke depan dari satu FixedSchedule.
  ///
  /// Dart `%` mengembalikan nilai negatif untuk operand negatif (berbeda dengan Python).
  /// `+7` memastikan hasil `daysUntil` selalu di rentang 0–6.
  static DateTime _nextOccurrence(FixedSchedule schedule, DateTime now) {
    int today = now.weekday % 7; // dart: 1=Mon..7=Sun → 1=Mon..0=Sun
    int targetDay = schedule.dayOfWeek; // 0=Sun
    int hour = schedule.hour;
    int minute = schedule.minute;

    int daysUntil = (targetDay - today + 7) % 7;

    bool timePassedToday =
        now.hour * 60 + now.minute >= hour * 60 + minute;
    if (daysUntil == 0 && timePassedToday) {
      daysUntil = 7;
    }

    return DateTime(now.year, now.month, now.day + daysUntil, hour, minute);
  }

  /// Cari respawn terdekat dari beberapa jadwal (multi-schedule).
  static DateTime nextRespawnFixed(List<FixedSchedule> schedules, DateTime now) {
    DateTime closest = _nextOccurrence(schedules.first, now);
    for (int i = 1; i < schedules.length; i++) {
      DateTime candidate = _nextOccurrence(schedules[i], now);
      if (candidate.isBefore(closest)) closest = candidate;
    }
    return closest;
  }

  /// Hitung respawn boss dynamic dari H3 death time.
  static DateTime? calcDynamicRespawn(DateTime? h3DeathTime, int respawnHours) {
    if (h3DeathTime == null) return null;
    return h3DeathTime.add(Duration(hours: respawnHours));
  }

  /// Tentukan status boss.
  ///
  /// Returns `(BossStatus, DateTime?)`:
  /// - Status `noData` + `respawnTime` null → data tidak tersedia (dynamic, h3DeathTime null).
  /// - Status `alive` + `respawnTime` → respawnTime sudah lewat.
  /// - Status `today` + `respawnTime` → fixed, respawnTime hari ini dan belum lewat.
  /// - Status `scheduled` + `respawnTime` → sisanya (terjadwal normal).
  static (BossStatus, DateTime?) determineStatus(
    BossConfig config,
    DateTime? h3DeathTime,
    DateTime now,
  ) {
    if (config.type == BossType.dynamic) {
      if (h3DeathTime == null) return (BossStatus.noData, null);
      DateTime respawnTime = calcDynamicRespawn(h3DeathTime, config.respawnHours!)!;
      if (now.isAfter(respawnTime)) return (BossStatus.alive, respawnTime);
      return (BossStatus.scheduled, respawnTime);
    }

    // Fixed boss
    DateTime respawnTime = nextRespawnFixed(config.schedules!, now);

    if (now.isAfter(respawnTime)) return (BossStatus.alive, respawnTime);

    bool sameDay = respawnTime.year == now.year &&
        respawnTime.month == now.month &&
        respawnTime.day == now.day;
    if (sameDay) return (BossStatus.today, respawnTime);

    return (BossStatus.scheduled, respawnTime);
  }

  /// Hitung progress 0.0–1.0.
  ///
  /// - Dynamic: `start = h3DeathTime`, `end = respawnTime`.
  /// - Fixed: `start = respawnTime - 7 days` (asumsi siklus mingguan).
  ///   Progress adalah fraksi 7 hari menuju respawn berikutnya.
  ///   Tidak menggunakan multi-schedule karena tiap occurrence dianggap
  ///   sebagai siklus mingguan independen.
  static double calcProgress({
    required DateTime? start,
    required DateTime? end,
    required DateTime now,
  }) {
    if (start == null || end == null) return 0.0;
    final totalUs = end.difference(start).inMicroseconds;
    // Edge case: start == end (teoretis, tidak tercapai oleh data config saat ini
    // karena semua dynamic boss punya respawnHours >= 10 dan fixed boss punya
    // siklus 7 hari). Jika start == end, progress dianggap 0.0 jika now <= end,
    // atau 1.0 jika now sudah lewat.
    if (totalUs <= 0) return now.isAfter(end) ? 1.0 : 0.0;
    final elapsedUs = now.difference(start).inMicroseconds;
    return (elapsedUs / totalUs).clamp(0.0, 1.0);
  }
}
