import 'boss_config.dart';
import 'boss_status.dart';

class BossDisplayData {
  final BossConfig config;
  final DateTime? respawnTime;
  final BossStatus status;
  final double progress; // 0.0–1.0
  final DateTime? h3DeathTime;
  final bool isUrgent; // countdown < 1 hour
  final bool isSoon; // countdown < 6 hours

  const BossDisplayData({
    required this.config,
    this.respawnTime,
    required this.status,
    required this.progress,
    this.h3DeathTime,
    this.isUrgent = false,
    this.isSoon = false,
  });

  BossDisplayData copyWith({
    BossConfig? config,
    DateTime? respawnTime,
    BossStatus? status,
    double? progress,
    DateTime? h3DeathTime,
    bool? isUrgent,
    bool? isSoon,
  }) {
    return BossDisplayData(
      config: config ?? this.config,
      respawnTime: respawnTime ?? this.respawnTime,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      h3DeathTime: h3DeathTime ?? this.h3DeathTime,
      isUrgent: isUrgent ?? this.isUrgent,
      isSoon: isSoon ?? this.isSoon,
    );
  }
}
