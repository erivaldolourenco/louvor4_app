import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/ui/widgets/app_circular_action_button.dart';
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
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE5EDF6),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.18)
                : AppColors.primaryBright.withValues(alpha: 0.04),
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
                    ? AppColors.primarySubtleDark
                    : AppColors.primarySubtleLight,
                borderRadius: BorderRadius.circular(AppRadius.input),
              ),
              child: const Icon(
                Icons.queue_music_rounded,
                color: AppColors.primary,
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
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  _ItemCountBadge(count: itemCount, isDark: isDark),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppCircularActionButton(
                  onPressed: onEdit,
                  assetPath: 'assets/icons/settings-2.svg',
                  iconColor: AppColors.primary,
                  backgroundColor: AppColors.primarySubtleLight,
                  borderColor: AppColors.primaryBorderLight,
                ),
                const SizedBox(width: 8),
                AppCircularActionButton(
                  onPressed: onDelete,
                  assetPath: 'assets/icons/trash-2.svg',
                  iconColor: AppColors.dangerBright,
                  backgroundColor: AppColors.dangerSubtleLight,
                  borderColor: AppColors.dangerBorderLight,
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
        color: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceSubtleLight,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: isDark ? AppColors.borderSubtleDark : AppColors.borderLight,
        ),
      ),
      child: Text(
        '$count ${count == 1 ? 'música' : 'músicas'}',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textMutedLight,
        ),
      ),
    );
  }
}

