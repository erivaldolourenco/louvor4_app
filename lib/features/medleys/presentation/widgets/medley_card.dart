import 'package:flutter/material.dart';

import '../../domain/entities/medley_entity.dart';

class MedleyCard extends StatelessWidget {
  final MedleyEntity medley;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MedleyCard({
    super.key,
    required this.medley,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final itemCount = medley.items.length;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE5EDF6),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.18)
                : const Color(0xFF0166FF).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF172554)
                    : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.queue_music_rounded,
                color: Color(0xFF2563EB),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medley.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (medley.description != null &&
                      medley.description!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      medley.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  _ItemCountBadge(count: itemCount, isDark: isDark),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ActionButton(
                  icon: Icons.edit_outlined,
                  color: const Color(0xFF0166FF),
                  bgColor: isDark
                      ? const Color(0xFF172554)
                      : const Color(0xFFEFF6FF),
                  onPressed: onEdit,
                ),
                const SizedBox(height: 6),
                _ActionButton(
                  icon: Icons.delete_outline_rounded,
                  color: const Color(0xFFEF4444),
                  bgColor: isDark
                      ? const Color(0xFF3F1114)
                      : const Color(0xFFFEE2E2),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemCountBadge extends StatelessWidget {
  final int count;
  final bool isDark;

  const _ItemCountBadge({required this.count, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Text(
        '$count ${count == 1 ? 'música' : 'músicas'}',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onPressed,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}
