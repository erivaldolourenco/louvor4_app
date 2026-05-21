import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/ui/widgets/app_circular_action_button.dart';
import '../../domain/entities/medley_entity.dart';
import '../../domain/entities/medley_item_entity.dart';

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
    final dividerColor =
        isDark ? AppColors.borderSubtleDark : AppColors.borderLight;

    return Container(
      clipBehavior: Clip.antiAlias,
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
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: AppColors.primaryBright),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Seção 1: Header ──────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
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
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textMutedLight,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  Divider(height: 1, thickness: 1, color: dividerColor),

                  // ── Seção 2: Lista de músicas ────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: medley.items.isEmpty
                        ? Text(
                            'Nenhuma música adicionada.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textMutedLight,
                            ),
                          )
                        : Column(
                            children: medley.items
                                .map(
                                  (item) => _SongRow(
                                    item: item,
                                    isDark: isDark,
                                    isLast: item == medley.items.last,
                                  ),
                                )
                                .toList(),
                          ),
                  ),

                  Divider(height: 1, thickness: 1, color: dividerColor),

                  // ── Seção 3: Ações ───────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
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
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Song row ──────────────────────────────────────────────────────────────────

class _SongRow extends StatelessWidget {
  final MedleyItemEntity item;
  final bool isDark;
  final bool isLast;

  const _SongRow({
    required this.item,
    required this.isDark,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasKey = item.key != null && item.key!.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.primarySubtleDark
                  : AppColors.primarySubtleLight,
              borderRadius: BorderRadius.circular(AppRadius.badge),
            ),
            child: Center(
              child: Text(
                '${item.sequence}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.songTitle ?? '—',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (hasKey) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.primarySubtleDark
                    : AppColors.primarySubtleLight,
                borderRadius: BorderRadius.circular(AppRadius.badge),
              ),
              child: Text(
                item.key!,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
