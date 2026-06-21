import '../models/boss_config.dart';

const Map<String, Guild> guildMap = {
  'Tumier': Guild.dynasty,
  'Benji': Guild.dynasty,
  'Chaiflock': Guild.dynasty,
  'Rakajeth': Guild.dynasty,
  'Libitina': Guild.dynasty,
  'Supore': Guild.dynasty,
  'Asta': Guild.dynasty,
  'Ordo': Guild.dynasty,
  'Secreta': Guild.dynasty,
  'Auraq': Guild.dynasty,
  'Catena': Guild.dynasty,
  'Titore': Guild.dynasty,
  'Gareth': Guild.dynasty,
  'Larba': Guild.dynasty,
  'Roderick': Guild.requiem,
  'Ringor': Guild.requiem,
  'Shuliar': Guild.requiem,
  'Duplican': Guild.requiem,
  'Metus': Guild.requiem,
  'Wannitas': Guild.requiem,
  'Milavy': Guild.requiem,
  'Baron Braudmore': Guild.requiem,
  'Amentis': Guild.requiem,
  'Thymele': Guild.danketsu,
  'General Aquleus': Guild.danketsu,
  'Lady Dalia': Guild.danketsu,
  'Neutro': Guild.danketsu,
  'Saphirus': Guild.danketsu,
  'Undomiel': Guild.danketsu,
  'Araneo': Guild.danketsu,
  'Livera': Guild.danketsu,
  'Clemantis': Guild.danketsu,
  'Ego': Guild.danketsu,
  'Viorent': Guild.danketsu,
  'Venatus': Guild.danketsu,
  'Icaruthia': Guild.kransia,
  'Motti': Guild.kransia,
  'Nevaeh': Guild.kransia,
  'Lucus': Guild.kransia,
};

const List<BossConfig> bossConfigs = [
  // ── Fixed Bosses ──
  BossConfig(name: 'Icaruthia', type: BossType.fixed, guild: Guild.kransia, schedules: [
    FixedSchedule(dayOfWeek: 2, hour: 21, minute: 0),
    FixedSchedule(dayOfWeek: 5, hour: 21, minute: 0),
  ]),
  BossConfig(name: 'Motti', type: BossType.fixed, guild: Guild.kransia, schedules: [
    FixedSchedule(dayOfWeek: 3, hour: 19, minute: 0),
    FixedSchedule(dayOfWeek: 6, hour: 19, minute: 0),
  ]),
  BossConfig(name: 'Nevaeh', type: BossType.fixed, guild: Guild.kransia, schedules: [
    FixedSchedule(dayOfWeek: 0, hour: 22, minute: 0),
  ]),
  BossConfig(name: 'Lucus', type: BossType.fixed, guild: Guild.kransia, schedules: [
    FixedSchedule(dayOfWeek: 6, hour: 22, minute: 0),
  ]),
  BossConfig(name: 'Clemantis', type: BossType.fixed, guild: Guild.danketsu, schedules: [
    FixedSchedule(dayOfWeek: 1, hour: 11, minute: 30),
    FixedSchedule(dayOfWeek: 4, hour: 19, minute: 0),
  ]),
  BossConfig(name: 'Saphirus', type: BossType.fixed, guild: Guild.danketsu, schedules: [
    FixedSchedule(dayOfWeek: 0, hour: 17, minute: 0),
    FixedSchedule(dayOfWeek: 2, hour: 11, minute: 30),
  ]),
  BossConfig(name: 'Neutro', type: BossType.fixed, guild: Guild.danketsu, schedules: [
    FixedSchedule(dayOfWeek: 2, hour: 19, minute: 0),
    FixedSchedule(dayOfWeek: 4, hour: 11, minute: 30),
  ]),
  BossConfig(name: 'Thymele', type: BossType.fixed, guild: Guild.danketsu, schedules: [
    FixedSchedule(dayOfWeek: 1, hour: 19, minute: 0),
    FixedSchedule(dayOfWeek: 3, hour: 11, minute: 30),
  ]),
  BossConfig(name: 'Milavy', type: BossType.fixed, guild: Guild.requiem, schedules: [
    FixedSchedule(dayOfWeek: 6, hour: 15, minute: 0),
  ]),
  BossConfig(name: 'Ringor', type: BossType.fixed, guild: Guild.requiem, schedules: [
    FixedSchedule(dayOfWeek: 6, hour: 17, minute: 0),
  ]),
  BossConfig(name: 'Roderick', type: BossType.fixed, guild: Guild.requiem, schedules: [
    FixedSchedule(dayOfWeek: 5, hour: 19, minute: 0),
  ]),
  BossConfig(name: 'Auraq', type: BossType.fixed, guild: Guild.dynasty, schedules: [
    FixedSchedule(dayOfWeek: 5, hour: 22, minute: 0),
    FixedSchedule(dayOfWeek: 3, hour: 21, minute: 0),
  ]),
  BossConfig(name: 'Chaiflock', type: BossType.fixed, guild: Guild.dynasty, schedules: [
    FixedSchedule(dayOfWeek: 0, hour: 15, minute: 0),
  ]),
  BossConfig(name: 'Benji', type: BossType.fixed, guild: Guild.dynasty, schedules: [
    FixedSchedule(dayOfWeek: 0, hour: 21, minute: 0),
  ]),
  BossConfig(name: 'Tumier', type: BossType.fixed, guild: Guild.dynasty, schedules: [
    FixedSchedule(dayOfWeek: 0, hour: 19, minute: 0),
  ]),
  BossConfig(name: 'Libitina', type: BossType.fixed, guild: Guild.dynasty, schedules: [
    FixedSchedule(dayOfWeek: 1, hour: 21, minute: 0),
    FixedSchedule(dayOfWeek: 6, hour: 21, minute: 0),
  ]),
  BossConfig(name: 'Rakajeth', type: BossType.fixed, guild: Guild.dynasty, schedules: [
    FixedSchedule(dayOfWeek: 2, hour: 22, minute: 0),
    FixedSchedule(dayOfWeek: 0, hour: 19, minute: 0),
  ]),

  // ── Dynamic Bosses ──
  BossConfig(name: 'Venatus', type: BossType.dynamic, guild: Guild.danketsu, respawnHours: 10),
  BossConfig(name: 'Viorent', type: BossType.dynamic, guild: Guild.danketsu, respawnHours: 10),
  BossConfig(name: 'Ego', type: BossType.dynamic, guild: Guild.danketsu, respawnHours: 21),
  BossConfig(name: 'Livera', type: BossType.dynamic, guild: Guild.danketsu, respawnHours: 24),
  BossConfig(name: 'Araneo', type: BossType.dynamic, guild: Guild.danketsu, respawnHours: 24),
  BossConfig(name: 'Undomiel', type: BossType.dynamic, guild: Guild.danketsu, respawnHours: 24),
  BossConfig(name: 'Lady Dalia', type: BossType.dynamic, guild: Guild.danketsu, respawnHours: 18),
  BossConfig(name: 'General Aquleus', type: BossType.dynamic, guild: Guild.danketsu, respawnHours: 29),
  BossConfig(name: 'Amentis', type: BossType.dynamic, guild: Guild.requiem, respawnHours: 29),
  BossConfig(name: 'Baron Braudmore', type: BossType.dynamic, guild: Guild.requiem, respawnHours: 32),
  BossConfig(name: 'Wannitas', type: BossType.dynamic, guild: Guild.requiem, respawnHours: 48),
  BossConfig(name: 'Metus', type: BossType.dynamic, guild: Guild.requiem, respawnHours: 48),
  BossConfig(name: 'Duplican', type: BossType.dynamic, guild: Guild.requiem, respawnHours: 48),
  BossConfig(name: 'Shuliar', type: BossType.dynamic, guild: Guild.requiem, respawnHours: 35),
  BossConfig(name: 'Larba', type: BossType.dynamic, guild: Guild.dynasty, respawnHours: 35),
  BossConfig(name: 'Gareth', type: BossType.dynamic, guild: Guild.dynasty, respawnHours: 32),
  BossConfig(name: 'Titore', type: BossType.dynamic, guild: Guild.dynasty, respawnHours: 37),
  BossConfig(name: 'Catena', type: BossType.dynamic, guild: Guild.dynasty, respawnHours: 35),
  BossConfig(name: 'Secreta', type: BossType.dynamic, guild: Guild.dynasty, respawnHours: 62),
  BossConfig(name: 'Ordo', type: BossType.dynamic, guild: Guild.dynasty, respawnHours: 62),
  BossConfig(name: 'Asta', type: BossType.dynamic, guild: Guild.dynasty, respawnHours: 62),
  BossConfig(name: 'Supore', type: BossType.dynamic, guild: Guild.dynasty, respawnHours: 62),
];
