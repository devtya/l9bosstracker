import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

import '../models/boss_display_data.dart';
import '../models/boss_status.dart';

class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  late final String _localTimeZoneName;
  late final tz.Location _localLocation;
  bool _initialized = false;

  // In-memory toggle: set of boss names whose notifications are DISABLED.
  // Persistent storage (shared_preferences) is NOT used to avoid adding
  // a dependency without confirmation. Toggles reset on app restart.
  final Set<String> _disabledBosses = {};

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    final TimezoneInfo tzInfo = await FlutterTimezone.getLocalTimezone();
    _localTimeZoneName = tzInfo.identifier;
    debugPrint('[Notif] timezone identifier = $_localTimeZoneName');
    _localLocation = tz.getLocation(_localTimeZoneName);
    tz.setLocalLocation(_localLocation);

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInit =
        DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(settings: initSettings);

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      debugPrint('[Notif] Android plugin resolved, creating channel...');
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'boss_respawn_channel',
          'Boss Respawn',
          description: 'Notifikasi 5 menit sebelum boss respawn',
          importance: Importance.high,
          playSound: true,
        ),
      );
      debugPrint('[Notif] Channel created');

      final permGranted = await androidPlugin.requestNotificationsPermission();
      debugPrint('[Notif] requestNotificationsPermission result = $permGranted');

      final canExact = await androidPlugin.canScheduleExactNotifications();
      debugPrint('[Notif] canScheduleExactNotifications = $canExact');
    } else {
      debugPrint('[Notif] WARN: androidPlugin is NULL — not Android?');
    }

    _initialized = true;
  }

  int _notificationId(String bossName) => bossName.hashCode;

  Future<void> scheduleBossNotification({
    required String bossName,
    required DateTime respawnTime,
    String? guildLabel,
  }) async {
    debugPrint('[Notif] scheduleBossNotification called for $bossName');

    if (!_initialized) {
      debugPrint('[Notif] SKIP: not initialized');
      return;
    }
    if (_disabledBosses.contains(bossName)) {
      debugPrint('[Notif] SKIP: boss disabled');
      return;
    }

    final notifyTime = respawnTime.subtract(const Duration(minutes: 5));
    final now = DateTime.now();

    debugPrint('[Notif] respawnTime=$respawnTime');
    debugPrint('[Notif] notifyTime=$notifyTime (respawn - 5min)');
    debugPrint('[Notif] now=$now');
    debugPrint('[Notif] notifyTime.isAfter(now)=${notifyTime.isAfter(now)}');

    if (!notifyTime.isAfter(now)) {
      debugPrint('[Notif] SKIP: notifyTime is NOT after now (past or same)');
      return;
    }

    final tzNotifyTime = tz.TZDateTime.from(notifyTime, _localLocation);

    final title = '\u2694\uFE0F $bossName respawn 5 menit lagi!';
    final body = guildLabel != null
        ? 'Guild: $guildLabel  \u2022  ${_formatTime(respawnTime)}'
        : 'Respawn: ${_formatTime(respawnTime)}';

    const androidDetails = AndroidNotificationDetails(
      'boss_respawn_channel',
      'Boss Respawn',
      channelDescription: 'Notifikasi 5 menit sebelum boss respawn',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    debugPrint('[Notif] calling zonedSchedule...');
    debugPrint('[Notif] tzNotifyTime=$tzNotifyTime');
    debugPrint('[Notif] tzNotifyTime.isUtc=${tzNotifyTime.isUtc}');
    debugPrint('[Notif] tzNotifyTime.timeZoneName=${tzNotifyTime.timeZoneName}');

    try {
      await _plugin.zonedSchedule(
        id: _notificationId(bossName),
        title: title,
        body: body,
        scheduledDate: tzNotifyTime,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      debugPrint('[Notif] zonedSchedule completed without error');
    } catch (e) {
      debugPrint('[Notif] zonedSchedule THREW: $e');
    }
  }

  Future<void> cancelBossNotification(String bossName) async {
    if (!_initialized) return;
    await _plugin.cancel(id: _notificationId(bossName));
  }

  Future<void> cancelAll() async {
    if (!_initialized) return;
    await _plugin.cancelAll();
  }

  /// Re-schedule notifications for all valid bosses.
  ///
  /// - Skip `noData` — no respawn time available.
  /// - Skip `alive` — boss already respawned; notification would be stale
  ///   until a new death time is recorded on the sheet.
  /// - Skip bosses whose notification time is already past.
  /// - Cancels all existing schedules first, then re-schedules valid ones.
  ///   This is slightly wasteful (cancel + re-schedule even if unchanged)
  ///   but keeps the logic simple and race-condition-free. Optimization
  ///   (diff old vs new respawnTime) is not needed at this scale (≤40 ops/min).
  Future<void> rescheduleAll(List<BossDisplayData> bosses) async {
    if (!_initialized) return;

    await cancelAll();

    for (final boss in bosses) {
      if (boss.status == BossStatus.noData) continue;
      if (boss.status == BossStatus.alive) continue;
      if (boss.respawnTime == null) continue;

      await scheduleBossNotification(
        bossName: boss.config.name,
        respawnTime: boss.respawnTime!,
        guildLabel: boss.config.guild.label,
      );
    }
  }

  void setBossNotificationEnabled(String bossName, bool enabled) {
    if (enabled) {
      _disabledBosses.remove(bossName);
    } else {
      _disabledBosses.add(bossName);
    }
  }

  bool isBossNotificationEnabled(String bossName) =>
      !_disabledBosses.contains(bossName);

  void dispose() {
    _disabledBosses.clear();
  }

  // ── DEBUG ONLY — remove or guard before release ──
  /// Directly schedules a test notification without the 5-minute offset
  /// used by [scheduleBossNotification]. The caller provides the exact
  /// [notifyTime] (already adjusted) for when the notification should fire.
  /// This bypasses the `isAfter` guard that assumes respawn times are hours
  /// in the future. Intended solely for manual testing via the test UI.
  Future<void> scheduleTestNotification({
    required String bossName,
    required DateTime notifyTime,
    String? guildLabel,
  }) async {
    debugPrint('[Notif-TEST] scheduleTestNotification called for $bossName');
    if (!_initialized) {
      debugPrint('[Notif-TEST] SKIP: not initialized');
      return;
    }

    final now = DateTime.now();
    debugPrint('[Notif-TEST] notifyTime=$notifyTime');
    debugPrint('[Notif-TEST] now=$now');
    debugPrint('[Notif-TEST] notifyTime.isAfter(now)=${notifyTime.isAfter(now)}');

    if (!notifyTime.isAfter(now)) {
      debugPrint('[Notif-TEST] SKIP: notifyTime is NOT after now');
      return;
    }

    final tzNotifyTime = tz.TZDateTime.from(notifyTime, _localLocation);

    final title = '\u2694\uFE0F $bossName TEST — respawn now!';
    final body = guildLabel != null
        ? 'Guild: $guildLabel  \u2022  ${_formatTime(notifyTime)}'
        : 'TEST: ${_formatTime(notifyTime)}';

    const androidDetails = AndroidNotificationDetails(
      'boss_respawn_channel',
      'Boss Respawn',
      channelDescription: 'Notifikasi 5 menit sebelum boss respawn (TEST)',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    debugPrint('[Notif-TEST] calling zonedSchedule...');
    debugPrint('[Notif-TEST] tzNotifyTime=$tzNotifyTime');
    debugPrint('[Notif-TEST] tzNotifyTime.isUtc=${tzNotifyTime.isUtc}');

    try {
      await _plugin.zonedSchedule(
        id: _notificationId(bossName),
        title: title,
        body: body,
        scheduledDate: tzNotifyTime,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      debugPrint('[Notif-TEST] zonedSchedule completed');
    } catch (e) {
      debugPrint('[Notif-TEST] zonedSchedule THREW: $e');
    }
  }
  // ── END DEBUG ONLY ──

  String _formatTime(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return '${dt.day} ${months[dt.month - 1]}, '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')} '
        '(${days[dt.weekday % 7]})';
  }
}
