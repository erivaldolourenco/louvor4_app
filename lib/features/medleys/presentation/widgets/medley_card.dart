import 'package:flutter/material.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/ui/widgets/app_card_surface.dart';
import '../../../../../core/ui/widgets/app_circular_action_button.dart';
import '../../../../../core/ui/widgets/spring_tap.dart';
import '../../domain/entities/medley_entity.dart';
import 'medley_details_sheet.dart';

class MedleyCard extends StatelessWidget {
  final MedleyEntity medley;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const MedleyCard({
    super.key,
    required this.medley,
    this.onEdit,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final count = medley.items.length;

    final card = AppCardSurface(
      radius: 22,
      borderColor: cs.secondary.withValues(alpha: 0.4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Info ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.queue_music_rounded,
                      color: cs.onSecondaryContainer,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        medley.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                      if (medley.description?.isNotEmpty == true) ...[
                        const SizedBox(height: 3),
                        Text(
                          medley.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _CountChip(count: count),
              ],
            ),
          ),

          // ── Actions ────────────────────────────────────────────────
          if (onEdit != null || onDelete != null) ...[
            Divider(height: 1, thickness: 1, color: cs.outlineVariant),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onEdit != null)
                    AppCircularActionButton(
                      onPressed: onEdit,
                      assetPath: 'assets/icons/settings-2.svg',
                      iconColor: cs.onPrimaryContainer,
                      backgroundColor: cs.primaryContainer,
                      borderColor: cs.primary.withValues(alpha: 0.3),
                    ),
                  if (onEdit != null && onDelete != null)
                    const SizedBox(width: 8),
                  if (onDelete != null)
                    AppCircularActionButton(
                      onPressed: onDelete,
                      assetPath: 'assets/icons/trash-2.svg',
                      iconColor: cs.error,
                      backgroundColor: cs.errorContainer,
                      borderColor: cs.error.withValues(alpha: 0.3),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );

    return SpringTap(
      onTap: onTap ?? () => showMedleyDetailsModal(context, medley),
      pressedScale: 0.97,
      child: card,
    );
  }
}

class _CountChip extends StatelessWidget {
  final int count;

  const _CountChip({required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.badge),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$count ',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            TextSpan(
              text: count == 1 ? 'música' : 'músicas',
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
