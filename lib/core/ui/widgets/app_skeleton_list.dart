import 'package:flutter/material.dart';

import '../../theme/app_radius.dart';
import 'app_shimmer.dart';

/// Formato dos itens placeholder de [AppSkeletonList].
enum AppSkeletonVariant {
  /// Card com miniatura/avatar à esquerda + duas linhas de texto.
  /// Usado em listas de músicas, projetos e membros.
  avatarRow,

  /// Card só de texto (título + corpo), sem miniatura.
  /// Usado em listas de avisos/notificações.
  textCard,
}

/// Skeleton loading reutilizável — lista de placeholders com efeito
/// shimmer, para usar no lugar de um spinner genérico enquanto o
/// conteúdo real carrega.
class AppSkeletonList extends StatelessWidget {
  final int itemCount;
  final AppSkeletonVariant variant;
  final EdgeInsetsGeometry padding;

  const AppSkeletonList({
    super.key,
    this.itemCount = 6,
    this.variant = AppSkeletonVariant.avatarRow,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  });

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, _) => switch (variant) {
          AppSkeletonVariant.avatarRow => const _SkeletonAvatarRow(),
          AppSkeletonVariant.textCard => const _SkeletonTextCard(),
        },
      ),
    );
  }
}

class _SkeletonAvatarRow extends StatelessWidget {
  const _SkeletonAvatarRow();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final lineColor = isDark ? cs.surfaceContainer : const Color(0xFFE5EDF6);
    final cardFill = isDark
        ? cs.surfaceContainerLow
        : cs.surfaceContainerLowest;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardFill,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: lineColor,
              borderRadius: BorderRadius.circular(AppRadius.input),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 180,
                  height: 16,
                  decoration: BoxDecoration(
                    color: lineColor,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 110,
                  height: 12,
                  decoration: BoxDecoration(
                    color: lineColor,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonTextCard extends StatelessWidget {
  const _SkeletonTextCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final lineColor = isDark ? cs.surfaceContainer : const Color(0xFFE5EDF6);
    final cardFill = isDark
        ? cs.surfaceContainerLow
        : cs.surfaceContainerLowest;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardFill,
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 160,
            height: 16,
            decoration: BoxDecoration(
              color: lineColor,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            height: 12,
            decoration: BoxDecoration(
              color: lineColor,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 220,
            height: 12,
            decoration: BoxDecoration(
              color: lineColor,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
        ],
      ),
    );
  }
}
