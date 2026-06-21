enum BossType { fixed, dynamic }

enum Guild {
  bloodMoon,
  dynasty,
  requiem,
  danketsu,
  kransia;

  String get emoji {
    switch (this) {
      case Guild.bloodMoon:
        return '🌙';
      case Guild.dynasty:
        return '👑';
      case Guild.requiem:
        return '🖤';
      case Guild.danketsu:
        return '⚔️';
      case Guild.kransia:
        return '🔰';
    }
  }

  String get label {
    switch (this) {
      case Guild.bloodMoon:
        return 'BloodMoon';
      case Guild.dynasty:
        return 'Dynasty';
      case Guild.requiem:
        return 'Requiem';
      case Guild.danketsu:
        return 'Danketsu';
      case Guild.kransia:
        return 'Kransia';
    }
  }
}

class FixedSchedule {
  final int dayOfWeek; // 0=Sunday ... 6=Saturday (JS getDay() convention)
  final int hour;
  final int minute;

  const FixedSchedule({
    required this.dayOfWeek,
    required this.hour,
    required this.minute,
  });

  int get dartWeekday => dayOfWeek == 0 ? 7 : dayOfWeek;
}

class BossConfig {
  final String name;
  final BossType type;
  final Guild guild;
  final List<FixedSchedule>? schedules;
  final int? respawnHours;

  const BossConfig({
    required this.name,
    required this.type,
    required this.guild,
    this.schedules,
    this.respawnHours,
  });
}
