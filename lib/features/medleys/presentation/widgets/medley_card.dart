import 'package:flutter/material.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/ui/widgets/app_card_surface.dart';
import '../../../../../core/ui/widgets/spring_tap.dart';
import '../../domain/entities/medley_entity.dart';
import '../../domain/entities/medley_item_entity.dart';
import 'medley_details_sheet.dart';

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
          () => showMedleyDetailsModal(context, medley, onEdit: onEdit),
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
                if (onEdit != null) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: onEdit,
                  ),
                ],
                if (onDelete != null) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: onDelete,
                  ),
                ],
              ],
            ),
          ),
          if (medley.items.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: _MedleySequencePreview(items: medley.items),
            ),
          ],
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

class _MedleySequencePreview extends StatelessWidget {
  final List<MedleyItemEntity> items;

  const _MedleySequencePreview({required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final sortedItems = List<MedleyItemEntity>.from(items)
      ..sort((a, b) => a.sequence.compareTo(b.sequence));

    final displayItems = sortedItems.take(3).toList();
    final remainingCount = sortedItems.length - displayItems.length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < displayItems.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 13,
                  color: cs.primary,
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppRadius.badge),
                border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayItems[i].songTitle ?? 'Música',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  if (displayItems[i].key?.isNotEmpty == true) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: cs.tertiaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        displayItems[i].key!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: cs.onTertiaryContainer,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (remainingCount > 0) ...[
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: cs.secondaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.badge),
              ),
              child: Text(
                '+$remainingCount mais',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                  color: cs.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
