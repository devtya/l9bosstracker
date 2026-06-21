import 'dart:async';
import 'package:flutter/material.dart';
import '../data/boss_data.dart';
import '../data/sheet_service.dart';
import '../logic/respawn_calculator.dart';
import '../logic/notification_service.dart';
import '../logic/guild_filter_logic.dart';
import '../models/boss_config.dart';
import '../models/boss_death_time.dart';
import '../models/boss_display_data.dart';
import '../models/boss_status.dart';
import '../widgets/boss_card_item.dart';
import '../widgets/guild_filter_bar.dart';
import '../theme_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final SheetService _sheetService = SheetService();
  final NotificationService _notifService = NotificationService();

  late TabController _tabController;

  Map<String, ValueNotifier<BossDisplayData>> _cardNotifiers = {};
  bool _isLoading = true;
  String? _errorMessage;
  Guild? _selectedGuild;

  Timer? _tickTimer;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchAndCompute();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateCountdowns());
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) => _fetchAndCompute());
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _refreshTimer?.cancel();
    _tabController.dispose();
    _sheetService.dispose();
    for (final n in _cardNotifiers.values) {
      n.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchAndCompute() async {
    Map<String, BossDeathTime> deathTimes;
    try {
      deathTimes = await _sheetService.fetchBossDeathTimes();
      setState(() => _errorMessage = null);
    } catch (_) {
      deathTimes = <String, BossDeathTime>{};
      setState(() => _errorMessage = 'Gagal memuat data sheet');
    }

    final now = DateTime.now();
    final newMap = <String, ValueNotifier<BossDisplayData>>{};

    for (final config in bossConfigs) {
      final deathTime = deathTimes[config.name];
      final h3DeathTime = deathTime?.h3DeathTime;

      final (status, respawnTime) =
          RespawnCalculator.determineStatus(config, h3DeathTime, now);

      final start = config.type == BossType.dynamic
          ? h3DeathTime
          : respawnTime?.subtract(const Duration(days: 7));

      final progress = RespawnCalculator.calcProgress(
        start: start,
        end: respawnTime,
        now: now,
      );

      final remaining = respawnTime?.difference(now);
      final isUrgent = remaining != null &&
          !remaining.isNegative &&
          remaining.inMinutes < 60 &&
          status != BossStatus.alive;
      final isSoon = remaining != null &&
          !remaining.isNegative &&
          remaining.inHours < 6 &&
          !isUrgent &&
          status != BossStatus.alive;

      final data = BossDisplayData(
        config: config,
        respawnTime: respawnTime,
        status: status,
        progress: progress,
        h3DeathTime: h3DeathTime,
        isUrgent: isUrgent,
        isSoon: isSoon,
      );

      final existing = _cardNotifiers[config.name];
      if (existing != null) {
        existing.value = data;
        newMap[config.name] = existing;
      } else {
        newMap[config.name] = ValueNotifier(data);
      }
    }

    for (final entry in _cardNotifiers.entries) {
      if (!newMap.containsKey(entry.key)) {
        entry.value.dispose();
      }
    }

    setState(() {
      _cardNotifiers = newMap;
      _isLoading = false;
    });

    final allData =
        _cardNotifiers.values.map((n) => n.value).toList();
    await _notifService.rescheduleAll(allData);
  }

  void _updateCountdowns() {
    final now = DateTime.now();
    for (final entry in _cardNotifiers.entries) {
      final current = entry.value.value;
      if (current.status == BossStatus.noData) continue;
      if (current.respawnTime == null) continue;

      final start = current.config.type == BossType.dynamic
          ? current.h3DeathTime
          : current.respawnTime!.subtract(const Duration(days: 7));

      final newProgress = RespawnCalculator.calcProgress(
        start: start,
        end: current.respawnTime,
        now: now,
      );

      final remaining = current.respawnTime!.difference(now);
      final isUrgent = !remaining.isNegative &&
          remaining.inMinutes < 60 &&
          current.status != BossStatus.alive;
      final isSoon = !remaining.isNegative &&
          remaining.inHours < 6 &&
          !isUrgent &&
          current.status != BossStatus.alive;

      final changed = newProgress != current.progress ||
          isUrgent != current.isUrgent ||
          isSoon != current.isSoon;
      if (!changed) continue;

      entry.value.value = current.copyWith(
        progress: newProgress,
        isUrgent: isUrgent,
        isSoon: isSoon,
      );
    }
  }

  Future<void> _handleToggle(String bossName, bool enabled) async {
    _notifService.setBossNotificationEnabled(bossName, enabled);
    if (enabled) {
      final data = _cardNotifiers[bossName]?.value;
      if (data != null &&
          data.status != BossStatus.noData &&
          data.status != BossStatus.alive &&
          data.respawnTime != null) {
        await _notifService.scheduleBossNotification(
          bossName: bossName,
          respawnTime: data.respawnTime!,
          guildLabel: data.config.guild.label,
        );
      }
    } else {
      await _notifService.cancelBossNotification(bossName);
    }
    setState(() {});
  }

  List<BossDisplayData> _filteredList() {
    var all = _cardNotifiers.values.map((n) => n.value).toList();
    final filtered = GuildFilterLogic.filterBosses(
      all.map((d) => d.config).toList(),
      _selectedGuild,
    );
    final filterSet = filtered.map((c) => c.name).toSet();
    return all.where((d) => filterSet.contains(d.config.name)).toList();
  }

  List<BossDisplayData> _aktifList() {
    final list = _filteredList();
    final scheduled = list.where((d) =>
        d.status == BossStatus.today ||
        d.status == BossStatus.scheduled).toList();
    final noData = list.where((d) => d.status == BossStatus.noData).toList();

    scheduled.sort((a, b) {
      if (a.respawnTime == null && b.respawnTime == null) return 0;
      if (a.respawnTime == null) return 1;
      if (b.respawnTime == null) return -1;
      return a.respawnTime!.compareTo(b.respawnTime!);
    });

    return [...scheduled, ...noData];
  }

  List<BossDisplayData> _aliveList() {
    final list = _filteredList();
    return list.where((d) => d.status == BossStatus.alive).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('L9 Boss Tracker'),
        actions: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeProvider,
            builder: (context, mode, _) {
              final isDark = mode == ThemeMode.dark;
              return IconButton(
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                tooltip: isDark ? 'Mode terang' : 'Mode gelap',
                onPressed: () => themeProvider.toggle(),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Aktif'),
            Tab(text: 'Alive'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                GuildFilterBar(
                  selectedGuild: _selectedGuild,
                  onChanged: (g) => setState(() => _selectedGuild = g),
                ),
                if (_errorMessage != null)
                  MaterialBanner(
                    content: Text(_errorMessage!),
                    leading: Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                    actions: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _errorMessage = null;
                          });
                          _fetchAndCompute();
                        },
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _bossListView(_aktifList(), 'Tidak ada boss aktif'),
                      _bossListView(_aliveList(), 'Tidak ada boss yang lewat'),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _bossListView(List<BossDisplayData> list, String emptyText) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _selectedGuild != null
                ? 'Tidak ada boss di guild ${_selectedGuild!.label}'
                : emptyText,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _isLoading = true);
        await _fetchAndCompute();
      },
      child: ListView.builder(
        itemCount: list.length,
        itemBuilder: (context, index) {
          final data = list[index];
          final notifier = _cardNotifiers[data.config.name]!;
          return BossCardItem(
            key: ValueKey(data.config.name),
            notifier: notifier,
            isNotificationEnabled:
                _notifService.isBossNotificationEnabled(data.config.name),
            onToggle: (enabled) => _handleToggle(data.config.name, enabled),
          );
        },
      ),
    );
  }
}
