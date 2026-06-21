import '../lib/models/boss_config.dart';
import '../lib/models/boss_status.dart';
import '../lib/logic/respawn_calculator.dart';
import '../lib/logic/guild_filter_logic.dart';

void main() {
  print('╔══════════════════════════════════════════════╗');
  print('║       RespawnCalculator — Manual Tests       ║');
  print('╚══════════════════════════════════════════════╝\n');

  // ─── Test 1: nextRespawnFixed, modulo fix ───
  print('─── Test 1: nextRespawnFixed (Nevaeh, Sun 22:00) ───');

  // Case A: Tuesday 10:00 → should get next Sunday 22:00
  DateTime tue = DateTime(2026, 6, 23, 10, 0); // Tuesday
  DateTime resA = RespawnCalculator.nextRespawnFixed(
    [FixedSchedule(dayOfWeek: 0, hour: 22, minute: 0)],
    tue,
  );
  print('  Tue 10:00 → respawn: ${_fmt(resA)}');
  assert(resA.weekday == 7, 'Expected Sunday');
  assert(resA.hour == 22, 'Expected 22:00');

  // Case B: Sunday 10:00 → should get same day 22:00 (not passed yet)
  DateTime sun10 = DateTime(2026, 6, 21, 10, 0);
  DateTime resB = RespawnCalculator.nextRespawnFixed(
    [FixedSchedule(dayOfWeek: 0, hour: 22, minute: 0)],
    sun10,
  );
  print('  Sun 10:00 → respawn: ${_fmt(resB)}');
  assert(resB.weekday == 7, 'Expected Sunday');
  assert(resB.day == sun10.day, 'Expected same day');
  assert(resB.hour == 22, 'Expected 22:00');

  // Case C: Sunday 23:00 → should get next Sunday 22:00 (already passed)
  DateTime sun23 = DateTime(2026, 6, 21, 23, 0);
  DateTime resC = RespawnCalculator.nextRespawnFixed(
    [FixedSchedule(dayOfWeek: 0, hour: 22, minute: 0)],
    sun23,
  );
  print('  Sun 23:00 → respawn: ${_fmt(resC)}');
  assert(resC.weekday == 7, 'Expected Sunday');
  assert(resC.day != sun23.day, 'Expected different day (next week)');
  assert(resC.hour == 22, 'Expected 22:00');

  // Case D: Saturday 10:00 → Roderick (Fri 19:00) → should get next Friday
  DateTime sat = DateTime(2026, 6, 27, 10, 0);
  DateTime resD = RespawnCalculator.nextRespawnFixed(
    [FixedSchedule(dayOfWeek: 5, hour: 19, minute: 0)],
    sat,
  );
  print('  Sat 10:00 → Roderick (Fri 19:00): ${_fmt(resD)}');
  assert(resD.weekday == 5, 'Expected Friday');
  assert(resD.hour == 19, 'Expected 19:00');

  print('  ✅ All nextRespawnFixed assertions passed\n');

  // ─── Test 2: nextRespawnFixed, multi-schedule ───
  print('─── Test 2: multi-schedule (Icaruthia: Tue 21:00, Fri 21:00) ───');

  DateTime wed = DateTime(2026, 6, 24, 15, 0); // Wednesday
  DateTime multi = RespawnCalculator.nextRespawnFixed(
    [
      FixedSchedule(dayOfWeek: 2, hour: 21, minute: 0), // Tue
      FixedSchedule(dayOfWeek: 5, hour: 21, minute: 0), // Fri
    ],
    wed,
  );
  print('  Wed 15:00 → closest: ${_fmt(multi)}');
  assert(multi.weekday == 5, 'Expected Friday (closer than next Tue)');
  assert(multi.hour == 21, 'Expected 21:00');

  DateTime friLate = DateTime(2026, 6, 26, 22, 0); // Friday 22:00 (after 21:00)
  DateTime multi2 = RespawnCalculator.nextRespawnFixed(
    [
      FixedSchedule(dayOfWeek: 2, hour: 21, minute: 0), // Tue
      FixedSchedule(dayOfWeek: 5, hour: 21, minute: 0), // Fri
    ],
    friLate,
  );
  print('  Fri 22:00 → closest: ${_fmt(multi2)}');
  assert(multi2.weekday == 2, 'Expected Tuesday (next week)');
  assert(multi2.hour == 21, 'Expected 21:00');

  print('  ✅ Multi-schedule assertions passed\n');

  // ─── Test 3: determineStatus ───
  print('─── Test 3: determineStatus ───');

  // Dynamic boss with data
  DateTime now = DateTime(2026, 6, 21, 12, 0);
  var (status3a, rt3a) = RespawnCalculator.determineStatus(
    BossConfig(name: 'Venatus', type: BossType.dynamic, guild: Guild.danketsu, respawnHours: 10),
    DateTime(2026, 6, 21, 16, 13), // h3DeathTime → respawn = 6/22 02:13
    now,
  );
  print('  Venatus (H3=Jun21 16:13, +10h) at Jun21 12:00 → status=$status3a, respawn=${rt3a != null ? _fmt(rt3a) : 'null'}');
  assert(status3a == BossStatus.scheduled, 'Expected scheduled');

  // Dynamic boss — respawn already passed
  DateTime nowAfter = DateTime(2026, 6, 21, 12, 0); // after 6/21 02:13
  var (status3b, rt3b) = RespawnCalculator.determineStatus(
    BossConfig(name: 'Venatus', type: BossType.dynamic, guild: Guild.danketsu, respawnHours: 10),
    DateTime(2026, 6, 20, 16, 13), // h3DeathTime → respawn = 6/21 02:13
    nowAfter,
  );
  print('  Venatus (H3=Jun20 16:13, +10h) at Jun21 12:00 → status=$status3b, respawn=${rt3b != null ? _fmt(rt3b) : 'null'}');
  assert(status3b == BossStatus.alive, 'Expected alive');

  // Dynamic boss with null h3DeathTime → should be noData, not scheduled
  var (status3c, rt3c) = RespawnCalculator.determineStatus(
    BossConfig(name: 'Venatus', type: BossType.dynamic, guild: Guild.danketsu, respawnHours: 10),
    null,
    now,
  );
  print('  Venatus (h3DeathTime=null) at Jun21 12:00 → status=$status3c, respawn=${rt3c != null ? _fmt(rt3c) : 'null'}');
  assert(status3c == BossStatus.noData, 'Expected noData when h3DeathTime is null');
  assert(rt3c == null, 'Expected respawnTime null when no data');

  // Fixed boss — today
  DateTime nowToday = DateTime(2026, 6, 21, 18, 0); // Sunday
  var (status3d, rt3d) = RespawnCalculator.determineStatus(
    BossConfig(name: 'Nevaeh', type: BossType.fixed, guild: Guild.kransia, schedules: [
      FixedSchedule(dayOfWeek: 0, hour: 22, minute: 0),
    ]),
    null,
    nowToday,
  );
  print('  Nevaeh (Sun 22:00) at Sun 18:00 → status=$status3d, respawn=${rt3d != null ? _fmt(rt3d) : 'null'}');
  assert(status3d == BossStatus.today, 'Expected today');
  assert(rt3d!.hour == 22, 'Expected 22:00');

  print('  ✅ determineStatus assertions passed\n');

  // ─── Test 4: calcProgress ───
  print('─── Test 4: calcProgress ───');

  // Dynamic boss: halfway through
  double p4a = RespawnCalculator.calcProgress(
    start: DateTime(2026, 6, 21, 12, 0),
    end: DateTime(2026, 6, 21, 14, 0),
    now: DateTime(2026, 6, 21, 13, 0),
  );
  print('  Dynamic (12:00→14:00, now=13:00) → progress: ${p4a.toStringAsFixed(3)}');
  assert((p4a - 0.5).abs() < 0.01, 'Expected ~0.5 progress');

  // Dynamic boss: null start → 0.0
  double p4b = RespawnCalculator.calcProgress(
    start: null,
    end: DateTime(2026, 6, 21, 14, 0),
    now: DateTime(2026, 6, 21, 13, 0),
  );
  print('  Dynamic (start=null) → progress: $p4b');
  assert(p4b == 0.0, 'Expected 0.0 when start is null');

  // Fixed boss: 7-day cycle, halfway through
  DateTime respawnSun = DateTime(2026, 6, 28, 22, 0); // next Sun 22:00
  double p4c = RespawnCalculator.calcProgress(
    start: respawnSun.subtract(Duration(days: 7)),
    end: respawnSun,
    now: respawnSun.subtract(Duration(days: 3, hours: 11)), // ~3.5 days before = ~0.5
  );
  print('  Fixed (7-day cycle, ~halfway) → progress: ${p4c.toStringAsFixed(3)}');
  assert((p4c - 0.5).abs() < 0.05, 'Expected ~0.5 progress');

  // Fixed boss: just after respawn → 1.0
  double p4d = RespawnCalculator.calcProgress(
    start: respawnSun.subtract(Duration(days: 7)),
    end: respawnSun,
    now: respawnSun.add(Duration(hours: 1)),
  );
  print('  Fixed (1h after respawn) → progress: ${p4d.toStringAsFixed(3)}');
  assert(p4d == 1.0, 'Expected 1.0 when after respawn');

  // Edge: start == end → 0.0
  double p4e = RespawnCalculator.calcProgress(
    start: now,
    end: now,
    now: now,
  );
  print('  Edge (start==end) → progress: $p4e');
  assert(p4e == 0.0, 'Expected 0.0 for zero-duration');

  print('  ✅ calcProgress assertions passed\n');

  // ─── Test 5: guild_filter_logic ───
  print('─── Test 5: GuildFilterLogic ───');

  final allBosses = [
    BossConfig(name: 'A', type: BossType.fixed, guild: Guild.dynasty, schedules: [FixedSchedule(dayOfWeek: 0, hour: 10, minute: 0)]),
    BossConfig(name: 'B', type: BossType.fixed, guild: Guild.requiem, schedules: [FixedSchedule(dayOfWeek: 0, hour: 10, minute: 0)]),
    BossConfig(name: 'C', type: BossType.fixed, guild: Guild.danketsu, schedules: [FixedSchedule(dayOfWeek: 0, hour: 10, minute: 0)]),
    BossConfig(name: 'D', type: BossType.fixed, guild: Guild.kransia, schedules: [FixedSchedule(dayOfWeek: 0, hour: 10, minute: 0)]),
    BossConfig(name: 'E', type: BossType.fixed, guild: Guild.bloodMoon, schedules: [FixedSchedule(dayOfWeek: 0, hour: 10, minute: 0)]),
  ];

  // All
  var all = GuildFilterLogic.filterBosses(allBosses, null);
  print('  All filter → ${all.length} bosses');
  assert(all.length == 5, 'Expected 5');

  // Dynasty
  var dyn = GuildFilterLogic.filterBosses(allBosses, Guild.dynasty);
  print('  Dynasty filter → ${dyn.length} boss(es) (${dyn.map((b) => b.name).join(', ')})');
  assert(dyn.length == 1 && dyn[0].name == 'A', 'Expected 1 Dynasty');

  // BloodMoon (no mapping → empty)
  var bm = GuildFilterLogic.filterBosses(allBosses, Guild.bloodMoon);
  print('  BloodMoon filter → ${bm.length} boss(es)');
  assert(bm.length == 1, 'Expected 1 (test data has bloodMoon boss)');

  print('  ✅ GuildFilterLogic assertions passed\n');

  print('╔══════════════════════════════════════════════╗');
  print('║      ALL TESTS PASSED                        ║');
  print('╚══════════════════════════════════════════════╝');
}

String _fmt(DateTime dt) {
  final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  return '${dt.year}-${_p(dt.month)}-${_p(dt.day)} ${_p(dt.hour)}:${_p(dt.minute)} (${days[dt.weekday % 7]})';
}

String _p(int n) => n.toString().padLeft(2, '0');
