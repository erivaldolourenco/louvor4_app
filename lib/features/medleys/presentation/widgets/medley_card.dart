import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/ui/app_feedback.dart';
import '../../../../../core/ui/widgets/app_card_surface.dart';
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
      decoration: appCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Seção 1: Header ────────────────────────────────────────────
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

          // ── Seção 2: Lista de músicas ──────────────────────────────────
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
              : Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    children: [
                      for (int i = 0; i < medley.items.length; i++) ...[
                        _SongItemCard(item: medley.items[i], isDark: isDark),
                        if (i < medley.items.length - 1)
                          const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),

          Divider(height: 1, thickness: 1, color: dividerColor),

          // ── Seção 3: Ações ─────────────────────────────────────────────
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
    final dividerColor =
        isDark ? AppColors.borderSubtleDark : AppColors.borderLight;
    final thumbnailUrl = YoutubeUtils.getThumbnail(item.youTubeUrl);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceSubtleLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderSubtleDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Seção 1: Thumbnail + info ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        thumbnailUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceDark
                                : AppColors.primarySubtleLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.music_note_rounded,
                            color: AppColors.primaryBright,
                            size: 26,
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
                const SizedBox(width: 10),
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
                      if (item.key != null && item.key!.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        _ItemBadge(label: 'Tom: ${item.key!}'),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Seção 2: Notas ─────────────────────────────────────────────
          if (hasNotes) ...[
            Divider(height: 1, thickness: 1, color: dividerColor),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notes_rounded, size: 13, color: mutedColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.notes!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: mutedColor,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Seção 3: Ações ─────────────────────────────────────────────
          if (hasYouTube) ...[
            Divider(height: 1, thickness: 1, color: dividerColor),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppCircularActionButton(
                    onPressed: _openYouTube,
                    assetPath: 'assets/icons/youtube.svg',
                    iconColor: const Color(0xFFDC2626),
                    backgroundColor: const Color(0xFFFEF2F2),
                    borderColor: const Color(0xFFFECACA),
                  ),
                ],
              ),
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
