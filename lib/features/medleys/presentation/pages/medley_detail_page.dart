import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/ui/app_feedback.dart';
import '../../../../core/ui/widgets/app_card_surface.dart';
import '../../../../core/ui/widgets/fade_slide_in.dart';
import '../../../../core/ui/widgets/reference_audio_player.dart';
import '../../../../core/ui/widgets/standard_section_app_bar.dart';
import '../../../../core/utils/youtube_utils.dart';
import '../../domain/entities/medley_entity.dart';
import '../../domain/entities/medley_item_entity.dart';

Future<void> openMedleyDetailPage(
  BuildContext context,
  MedleyEntity medley, {
  VoidCallback? onEdit,
}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => MedleyDetailPage(medley: medley, onEdit: onEdit),
    ),
  );
}

class MedleyDetailPage extends StatelessWidget {
  final MedleyEntity medley;
  final VoidCallback? onEdit;

  const MedleyDetailPage({super.key, required this.medley, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final mutedColor = cs.onSurfaceVariant;
    final count = medley.items.length;
    final hasNotes = medley.notes != null && medley.notes!.isNotEmpty;
    final hasAudio =
        medley.referenceAudioUrl != null &&
        medley.referenceAudioUrl!.trim().isNotEmpty;

    int staggerStep = 0;

    return Scaffold(
      appBar: StandardSectionAppBar(
        title: 'Detalhes do Medley',
        actions: [
          if (onEdit != null)
            IconButton(
              tooltip: 'Editar medley',
              icon: SvgPicture.asset(
                'assets/icons/square-pen.svg',
                width: 22,
                height: 22,
                colorFilter: ColorFilter.mode(cs.primary, BlendMode.srcIn),
              ),
              onPressed: onEdit,
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
          children: [
            // ── Header: ícone + nome + descrição ───────────────
            FadeSlideIn(
              delay: staggerDelay(staggerStep++),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer,
                      borderRadius: BorderRadius.circular(AppRadius.card),
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
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          medley.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (medley.description != null &&
                            medley.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            medley.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: mutedColor,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          count == 1 ? '1 música' : '$count músicas',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: mutedColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Notas ─────────────────────────────────────────
            if (hasNotes) ...[
              const SizedBox(height: 16),
              FadeSlideIn(
                delay: staggerDelay(staggerStep++),
                child: AppCardSurface(
                  radius: AppRadius.cardLarge,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Observações',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        medley.notes!,
                        style: TextStyle(color: mutedColor, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // ── Player de áudio de referência ──────────────────
            if (hasAudio) ...[
              const SizedBox(height: 16),
              FadeSlideIn(
                delay: staggerDelay(staggerStep++),
                child: ReferenceAudioPlayer(url: medley.referenceAudioUrl!),
              ),
            ],

            // ── Lista de músicas ────────────────────────────────
            const SizedBox(height: 16),
            if (count == 0)
              Center(
                child: Text(
                  'Nenhuma música neste medley.',
                  style: TextStyle(color: mutedColor),
                ),
              )
            else
              for (int i = 0; i < medley.items.length; i++) ...[
                FadeSlideIn(
                  delay: staggerDelay(staggerStep++),
                  child: _SongItemCard(item: medley.items[i]),
                ),
                if (i < medley.items.length - 1) const SizedBox(height: 8),
              ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Song item card
// ---------------------------------------------------------------------------

class _SongItemCard extends StatelessWidget {
  final MedleyItemEntity item;

  const _SongItemCard({required this.item});

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
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final hasNotes = item.notes != null && item.notes!.isNotEmpty;
    final hasYouTube = item.youTubeUrl != null && item.youTubeUrl!.isNotEmpty;
    final mutedColor = cs.onSurfaceVariant;
    final dividerColor = cs.outlineVariant;
    final thumbnailUrl = YoutubeUtils.getThumbnail(item.youTubeUrl);

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Thumbnail + info ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.badge),
                      child: Image.network(
                        thumbnailUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, _) => Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(AppRadius.badge),
                          ),
                          child: Icon(
                            Icons.music_note_rounded,
                            color: cs.primary,
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
                          color: cs.primary,
                          borderRadius: BorderRadius.circular(AppRadius.badge),
                        ),
                        child: Text(
                          '${item.sequence}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: cs.onPrimary,
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
                          fontWeight: FontWeight.w700,
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
                    ],
                  ),
                ),
                if (item.key != null && item.key!.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  _KeyChip(label: item.key!),
                ],
              ],
            ),
          ),

          // ── Notas ─────────────────────────────────────────────
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

          // ── Botão YouTube ──────────────────────────────────────
          if (hasYouTube) ...[
            Divider(height: 1, thickness: 1, color: dividerColor),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [_YoutubeButton(onTap: _openYouTube)],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _YoutubeButton extends StatelessWidget {
  final VoidCallback onTap;

  const _YoutubeButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: cs.errorContainer,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: cs.error.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: Icon(Icons.ondemand_video_rounded, size: 18, color: cs.error),
        ),
      ),
    );
  }
}

class _KeyChip extends StatelessWidget {
  final String label;

  const _KeyChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mutedColor = cs.onSurfaceVariant;
    final strongColor = cs.onSurfaceVariant;

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
              text: 'Tom ',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: mutedColor,
              ),
            ),
            TextSpan(
              text: label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: strongColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
