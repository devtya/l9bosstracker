import 'package:flutter/material.dart';
import '../models/boss_display_data.dart';
import '../models/boss_status.dart';

class BossCardItem extends StatelessWidget {
  final ValueNotifier<BossDisplayData> notifier;
  final bool isNotificationEnabled;
  final ValueChanged<bool> onToggle;

  const BossCardItem({
    super.key,
    required this.notifier,
    required this.isNotificationEnabled,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<BossDisplayData>(
      valueListenable: notifier,
      builder: (context, data, _) {
        final now = DateTime.now();
        final isNoData = data.status == BossStatus.noData;
        final remaining = data.respawnTime?.difference(now);
        final isPast = remaining != null && remaining.isNegative;
        final cs = Theme.of(context).colorScheme;

        final borderColor = isNoData
            ? cs.outlineVariant
            : data.isUrgent
                ? cs.error
                : data.isSoon
                    ? cs.tertiary
                    : cs.outlineVariant;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          elevation: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: borderColor, width: 4),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 10, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(data.config.guild.emoji, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            data.config.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => onToggle(!isNotificationEnabled),
                          child: Icon(
                            isNotificationEnabled
                                ? Icons.notifications_active
                                : Icons.notifications_off,
                            size: 20,
                            color: isNotificationEnabled
                                ? cs.primary
                                : cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (isNoData)
                      _infoRow(context, 'Menunggu data sheet...')
                    else if (data.respawnTime != null)
                      _infoRow(context, 'Respawn: ${_formatRespawn(data.respawnTime!)}'),
                    const SizedBox(height: 2),
                    if (isNoData)
                      _infoRow(context, '\u2014')
                    else if (remaining != null && !isPast)
                      _infoRow(context, '${_formatCountdown(remaining)} lagi')
                    else if (data.status == BossStatus.alive)
                      _infoRow(context, 'Sudah respawn (\u2212${_formatCountdown(remaining!)})')
                    else
                      _infoRow(context, 'Waktu respawn lewat'),
                    const SizedBox(height: 8),
                    if (!isNoData && data.respawnTime != null)
                      LinearProgressIndicator(
                        value: data.progress.clamp(0.0, 1.0),
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                        backgroundColor: cs.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          data.isUrgent
                              ? cs.error
                              : data.isSoon
                                  ? cs.tertiary
                                  : cs.primary,
                        ),
                      ),
                    const SizedBox(height: 4),
                    _buildBadge(context, data),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildBadge(BuildContext context, BossDisplayData data) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;

    String text;
    Color bg;
    Color fg;

    switch (data.status) {
      case BossStatus.noData:
        text = 'No data';
        bg = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
        fg = isDark ? Colors.grey.shade300 : Colors.grey.shade700;
      case BossStatus.alive:
        text = 'Alive';
        bg = isDark ? Colors.green.shade800 : Colors.green.shade100;
        fg = isDark ? Colors.green.shade200 : Colors.green.shade700;
      case BossStatus.today:
      case BossStatus.scheduled:
        if (data.isUrgent) {
          text = 'Urgent';
          bg = isDark ? Colors.red.shade800 : Colors.red.shade100;
          fg = isDark ? Colors.red.shade200 : Colors.red.shade700;
        } else if (data.isSoon) {
          text = 'Soon';
          bg = isDark ? Colors.orange.shade800 : Colors.orange.shade100;
          fg = isDark ? Colors.orange.shade200 : Colors.orange.shade700;
        } else {
          text = 'Scheduled';
          bg = cs.primaryContainer;
          fg = cs.onPrimaryContainer;
        }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w500),
      ),
    );
  }

  String _formatRespawn(DateTime dt) {
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

  String _formatCountdown(Duration d) {
    if (d.isNegative) {
      d = const Duration();
    }
    if (d.inDays > 0) {
      return '${d.inDays}h ${d.inHours.remainder(24)}j ${d.inMinutes.remainder(60)}m';
    }
    if (d.inHours > 0) {
      return '${d.inHours}j ${d.inMinutes.remainder(60)}m';
    }
    if (d.inMinutes > 0) {
      return '${d.inMinutes}m ${d.inSeconds.remainder(60)}d';
    }
    return '< 1m';
  }
}
