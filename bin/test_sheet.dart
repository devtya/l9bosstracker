import '../lib/data/sheet_service.dart';

void main() async {
  final service = SheetService();
  print('Fetching from sheet...\n');

  final data = await service.fetchBossDeathTimes();

  if (data.isEmpty) {
    print('ERROR: returned empty map — check network / endpoint');
    service.dispose();
    return;
  }

  print('Total bosses fetched: ${data.length}\n');

  // Show first 5 entries
  int count = 0;
  for (final entry in data.entries) {
    if (count >= 5) break;
    count++;
    print('${count}. ${entry.key}');
    print('   H3 DeathTime: ${entry.value.h3DeathTime}');
    print('');
  }

  // Example: null H3 case
  final nullH3 = data.entries
      .where((e) => e.value.h3DeathTime == null)
      .toList();
  print('--- Null H3 entries: ${nullH3.length} ---');
  for (final entry in nullH3) {
    print('  ${entry.key}: H3=null');
  }

  // Verify boss count matches dynamic configs
  print('\n--- Boss count ---');
  print('Sheet: ${data.length}');
  print('Dynamic configs in boss_data.dart: 22');
  print('Match: ${data.length == 22}');

  service.dispose();
}
