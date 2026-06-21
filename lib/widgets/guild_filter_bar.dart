import 'package:flutter/material.dart';
import '../models/boss_config.dart';

class GuildFilterBar extends StatefulWidget {
  final Guild? selectedGuild;
  final ValueChanged<Guild?> onChanged;

  const GuildFilterBar({
    super.key,
    required this.selectedGuild,
    required this.onChanged,
  });

  @override
  State<GuildFilterBar> createState() => _GuildFilterBarState();
}

class _GuildFilterBarState extends State<GuildFilterBar> {
  final _scrollController = ScrollController();
  bool _isAtStart = true;
  bool _isAtEnd = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _scrollController.position;
    final atStart = position.pixels <= position.minScrollExtent + 1;
    final atEnd = position.pixels >= position.maxScrollExtent - 1;
    if (atStart != _isAtStart || atEnd != _isAtEnd) {
      setState(() {
        _isAtStart = atStart;
        _isAtEnd = atEnd;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      _Item(label: 'All', guild: null),
      _Item(label: '🌙 BloodMoon', guild: Guild.bloodMoon),
      _Item(label: '👑 Dynasty', guild: Guild.dynasty),
      _Item(label: '🖤 Requiem', guild: Guild.requiem),
      _Item(label: '⚔️ Danketsu', guild: Guild.danketsu),
      _Item(label: '🔰 Kransia', guild: Guild.kransia),
    ];

    return ShaderMask(
      shaderCallback: (rect) {
        return LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            _isAtStart ? Colors.white : Colors.transparent,
            Colors.white,
            Colors.white,
            _isAtEnd ? Colors.white : Colors.transparent,
          ],
          stops: const [0.0, 0.06, 0.94, 1.0],
        ).createShader(rect);
      },
      blendMode: BlendMode.dstIn,
      child: SizedBox(
        height: 48,
        child: ListView.separated(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(12, 0, 28, 0),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final item = items[index];
            final selected = widget.selectedGuild == item.guild;
            return FilterChip(
              label: Text(item.label, style: const TextStyle(fontSize: 13)),
              selected: selected,
              onSelected: (_) => widget.onChanged(item.guild),
              visualDensity: VisualDensity.compact,
            );
          },
        ),
      ),
    );
  }
}

class _Item {
  final String label;
  final Guild? guild;
  const _Item({required this.label, required this.guild});
}
