import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/boss_death_time.dart';

class SheetService {
  final http.Client _client;

  static const _url =
      'https://opensheet.elk.sh/1RoupDDa_fQdcowVCNpL2q1mJDDAw3obvIwRQhOp7Z5E/Sheet1';
  static const _timeout = Duration(seconds: 10);

  SheetService({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, BossDeathTime>> fetchBossDeathTimes() async {
    try {
      final response =
          await _client.get(Uri.parse(_url)).timeout(_timeout);

      if (response.statusCode != 200) {
        print('[SheetService] HTTP ${response.statusCode} — returning empty');
        return {};
      }

      final List<dynamic> jsonList = jsonDecode(response.body) as List<dynamic>;
      final Map<String, BossDeathTime> result = {};

      for (final row in jsonList) {
        final Map<String, dynamic> map = row as Map<String, dynamic>;
        final bossName = map['Boss']?.toString().trim();
        if (bossName == null || bossName.isEmpty) continue;

        result[bossName] = BossDeathTime(
          h3DeathTime: _parseDeathTime(map['H3 DeathTime']?.toString()),
        );
      }

      return result;
    } catch (e) {
      print('[SheetService] Error: $e — returning empty');
      return {};
    }
  }

  DateTime? _parseDeathTime(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    // Sheet may contain literal string "null" for empty cells
    if (raw.trim().toLowerCase() == 'null') return null;
    // Format: "M/D/YYYY HH:mm:ss" or "M/D/YYYY HH:mm" (seconds are optional)
    final re = RegExp(r'^(\d+)/(\d+)/(\d+) (\d+):(\d+)(:\d+)?$');
    final m = re.firstMatch(raw.trim());
    if (m == null) return null;
    // JS source: new Date(year, month-1, day, hour, minute)
    return DateTime(
      int.parse(m.group(3)!), // year
      int.parse(m.group(1)!), // month (JS m[1]-1 → Dart 1-indexed, no conversion needed)
      int.parse(m.group(2)!), // day
      int.parse(m.group(4)!), // hour
      int.parse(m.group(5)!), // minute
    );
  }

  void dispose() {
    _client.close();
  }
}
