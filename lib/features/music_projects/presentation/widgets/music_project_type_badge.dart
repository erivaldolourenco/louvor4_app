import 'package:flutter/material.dart';

import '../../domain/entities/music_project_entity.dart';
import '../utils/music_project_ui_utils.dart';

class MusicProjectTypeBadge extends StatefulWidget {
  final MusicProjectType type;
  final bool pulse;

  const MusicProjectTypeBadge({
    super.key,
    required this.type,
    this.pulse = false,
  });

  @override
  State<MusicProjectTypeBadge> createState() => _MusicProjectTypeBadgeState();
}

class _MusicProjectTypeBadgeState extends State<MusicProjectTypeBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
      lowerBound: 0.8,
      upperBound: 1.3,
    );

    if (widget.pulse) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant MusicProjectTypeBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulse && !oldWidget.pulse) {
      _controller.repeat(reverse: true);
    } else if (!widget.pulse && oldWidget.pulse) {
      _controller.stop();
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _badgeColor(MusicProjectType type) {
    switch (type) {
      case MusicProjectType.ministry:
        return const Color(0xFF0E7490);
      case MusicProjectType.band:
        return const Color(0xFF0166FF);
      case MusicProjectType.singer:
        return const Color(0xFF9333EA);
      case MusicProjectType.unknown:
        return const Color(0xFF475569);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _badgeColor(widget.type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => Transform.scale(
              scale: widget.pulse ? _controller.value : 1,
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            MusicProjectUiUtils.typeLabel(widget.type),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
