import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/ui/app_feedback.dart';
import '../../../../../core/ui/widgets/app_circular_action_button.dart';
import '../../../../../core/utils/youtube_utils.dart';
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
                  medley.items.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Text(
                            'Nenhuma música adicionada.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textMutedLight,
                            ),
                          ),
                        )
                      : Column(
                          children: medley.items.map((item) {
                            final isLast = item == medley.items.last;
                            return Column(
                              children: [
                                _SongItemCard(item: item, isDark: isDark),
                                if (!isLast)
                                  Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: dividerColor,
                                  ),
                              ],
                            );
                          }).toList(),
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

// ── Song item card ────────────────────────────────────────────────────────────

class _SongItemCard extends StatelessWidget {
  final MedleyItemEntity item;
  final bool isDark;

  const _SongItemCard({required this.item, required this.isDark});

  Future<void> _openYouTube() async {
    final url = item.youTubeUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) {
      AppFeedback.showError('URL do YouTube inválida.');
      return;
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) AppFeedback.showError('Não foi possível abrir o YouTube.');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasNotes = item.notes != null && item.notes!.isNotEmpty;
    final hasYouTube = item.youTubeUrl != null && item.youTubeUrl!.isNotEmpty;
    final mutedColor =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final thumbnailUrl = YoutubeUtils.getThumbnail(item.youTubeUrl);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Thumbnail com badge de sequência
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  thumbnailUrl,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceElevatedDark
                          : AppColors.primarySubtleLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.music_note_rounded,
                      color: AppColors.primaryBright,
                      size: 28,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBright,
                    borderRadius: BorderRadius.circular(AppRadius.badge),
                  ),
                  child: Text(
                    '${item.sequence}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.songTitle ?? '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (item.songArtist != null &&
                    item.songArtist!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.songArtist!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: mutedColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 5),
                Row(
                  children: [
                    if (item.key != null && item.key!.isNotEmpty)
                      _ItemBadge(label: 'Tom: ${item.key!}'),
                  ],
                ),
                if (hasNotes) ...[
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.notes_rounded, size: 12, color: mutedColor),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.notes!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: mutedColor,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (hasYouTube) ...[
            const SizedBox(width: 8),
            AppCircularActionButton(
              onPressed: _openYouTube,
              assetPath: 'assets/icons/youtube.svg',
              iconColor: const Color(0xFFDC2626),
              backgroundColor: const Color(0xFFFEF2F2),
              borderColor: const Color(0xFFFECACA),
            ),
          ],
        ],
      ),
    );
  }
}

class _ItemBadge extends StatelessWidget {
  final String label;

  const _ItemBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtleLight,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSubtleDark,
        ),
      ),
    );
  }
}
