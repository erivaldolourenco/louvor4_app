import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/ui/widgets/app_card_surface.dart';
import '../../../../../core/ui/widgets/app_circular_action_button.dart';
import '../../../../../core/ui/widgets/spring_tap.dart';
import '../../domain/entities/medley_entity.dart';
import '../pages/medley_detail_page.dart';

class MedleyCard extends StatelessWidget {
  final MedleyEntity medley;
  final VoidCallback? onEdit;
  final VoidCallback? onTap;
  final Future<bool> Function()? onRemove;
  final VoidCallback? onDelete;
  final bool isRemoving;
  final String? dismissKey;

  const MedleyCard({
    super.key,
    required this.medley,
    this.onEdit,
    this.onTap,
    this.onRemove,
    this.onDelete,
    this.isRemoving = false,
    this.dismissKey,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final count = medley.items.length;

    Widget cardBody = SpringTap(
      onTap:
          onTap ??
          () => openMedleyDetailPage(context, medley, onEdit: onEdit),
      pressedScale: 0.97,
      borderRadius: BorderRadius.circular(AppRadius.cardHero),
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
                    borderRadius: BorderRadius.circular(AppRadius.thumbnail),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/icons/disc-album.svg',
                      width: 32,
                      height: 32,
                      colorFilter: ColorFilter.mode(
                        cs.onSecondaryContainer,
                        BlendMode.srcIn,
                      ),
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
                if (onDelete != null) ...[
                  const SizedBox(width: 4),
                  AppCircularActionButton(
                    onPressed: onDelete,
                    assetPath: 'assets/icons/trash-2.svg',
                    iconColor: cs.error,
                    backgroundColor: cs.errorContainer,
                    borderColor: cs.error.withValues(alpha: 0.3),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    Widget cardContent = DecoratedBox(
      decoration: appCardDecoration(context, radius: AppRadius.cardHero),
      child: cardBody,
    );

    if (isRemoving) {
      cardContent = Stack(
        children: [
          cardContent,
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: cs.surface.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppRadius.cardHero),
              ),
              child: const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ),
        ],
      );
    }

    final removeCallback = onRemove ?? (onDelete != null ? () async { onDelete!(); return true; } : null);

    if (removeCallback != null && onDelete == null) {
      cardContent = Dismissible(
        key: ValueKey(dismissKey ?? medley.name),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) => removeCallback(),
        background: Container(
          decoration: BoxDecoration(
            color: cs.error,
            borderRadius: BorderRadius.circular(AppRadius.cardHero),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Icon(Icons.delete_outline, color: cs.onError, size: 28),
        ),
        child: cardContent,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: cardContent,
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
    final textLabel = '$count ${count == 1 ? "música" : "músicas"}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.badge),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Text(
        textLabel,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: cs.onSurface,
        ),
      ),
    );
  }
}
