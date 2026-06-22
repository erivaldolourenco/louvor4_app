import 'package:flutter/material.dart';

import '../../theme/app_radius.dart';
import '../../utils/youtube_utils.dart';
import 'app_card_surface.dart';
import 'app_circular_action_button.dart';

class SongListCard extends StatelessWidget {
  final String title;
  final String? artist;
  final String? musicKey;
  final String? bpm;
  final String? youTubeUrl;
  final bool isMedley;
  final bool hasAudio;
  final VoidCallback? onTap;
  final VoidCallback? onOpenYoutube;
  final VoidCallback? onEdit;
  final Future<bool> Function()? onRemove;
  final bool isRemoving;
  final String? dismissKey;

  const SongListCard({
    super.key,
    required this.title,
    this.artist,
    this.musicKey,
    this.bpm,
    this.youTubeUrl,
    this.isMedley = false,
    this.hasAudio = false,
    this.onTap,
    this.onOpenYoutube,
    this.onEdit,
    this.onRemove,
    this.isRemoving = false,
    this.dismissKey,
  });

  bool get _hasActions =>
      isRemoving || (!isMedley && onOpenYoutube != null) || onEdit != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    Widget cardContent = AppCardSurface(
      radius: 22,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Info section ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _Thumbnail(youTubeUrl: youTubeUrl, isMedley: isMedley),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                      if (artist != null && artist!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          artist!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (hasAudio) ...[
                        const SizedBox(height: 6),
                        _AudioTag(),
                      ],
                    ],
                  ),
                ),
                if (!isMedley) ...[
                  const SizedBox(width: 12),
                  _KeyBpm(musicKey: musicKey, bpm: bpm),
                ],
              ],
            ),
          ),

          // ── Actions section ───────────────────────────────────────
          if (_hasActions) ...[
            Divider(height: 1, thickness: 1, color: cs.outlineVariant),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isRemoving)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else ...[
                    if (!isMedley && onOpenYoutube != null)
                      AppCircularActionButton(
                        onPressed: onOpenYoutube,
                        assetPath: 'assets/icons/youtube.svg',
                        iconColor: cs.tertiary,
                        backgroundColor: cs.tertiaryContainer,
                        borderColor: cs.tertiary.withValues(alpha: 0.3),
                      ),
                    if (!isMedley && onOpenYoutube != null && onEdit != null)
                      const SizedBox(width: 8),
                    if (onEdit != null)
                      AppCircularActionButton(
                        onPressed: onEdit,
                        assetPath: 'assets/icons/file-music.svg',
                        iconColor: cs.onPrimaryContainer,
                        backgroundColor: cs.primaryContainer,
                        borderColor: cs.primary.withValues(alpha: 0.3),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );

    if (onRemove != null) {
      cardContent = Dismissible(
        key: ValueKey(dismissKey ?? title),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) => onRemove!(),
        background: Container(
          decoration: BoxDecoration(
            color: cs.error,
            borderRadius: BorderRadius.circular(22),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Icon(Icons.delete_outline, color: cs.onError, size: 28),
        ),
        child: cardContent,
      );
    }

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: cardContent,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _Thumbnail extends StatelessWidget {
  final String? youTubeUrl;
  final bool isMedley;

  const _Thumbnail({required this.youTubeUrl, required this.isMedley});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (isMedley) {
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: cs.secondaryContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Icon(Icons.queue_music_rounded, color: cs.onSecondaryContainer, size: 32),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        YoutubeUtils.getThumbnail(youTubeUrl, quality: 'default'),
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          YoutubeUtils.defaultThumb,
          width: 64,
          height: 64,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _KeyBpm extends StatelessWidget {
  final String? musicKey;
  final String? bpm;

  const _KeyBpm({required this.musicKey, required this.bpm});

  @override
  Widget build(BuildContext context) {
    final hasBpm = bpm != null && bpm!.isNotEmpty;
    final keyLabel = musicKey?.isNotEmpty == true ? musicKey! : '-';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        _InfoChip(label: 'Tom', value: keyLabel),
        if (hasBpm) ...[
          const SizedBox(height: 6),
          _InfoChip(label: 'BPM', value: bpm!),
        ],
      ],
    );
  }
}

class _AudioTag extends StatelessWidget {
  const _AudioTag();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.headphones_rounded, size: 11, color: cs.onSecondaryContainer),
          const SizedBox(width: 3),
          Text(
            'Áudio',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.onSecondaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
              text: '$label ',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            TextSpan(
              text: value,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
