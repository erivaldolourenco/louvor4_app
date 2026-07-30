import 'package:flutter/material.dart';

import '../../theme/app_radius.dart';
import '../../utils/youtube_utils.dart';
import 'app_card_surface.dart';
import 'app_circular_action_button.dart';
import 'spring_tap.dart';

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
  final VoidCallback? onDelete;
  final VoidCallback? onOpenLyrics;
  final VoidCallback? onOpenChords;
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
    this.onDelete,
    this.onOpenLyrics,
    this.onOpenChords,
    this.onRemove,
    this.isRemoving = false,
    this.dismissKey,
  });

  bool get _hasLyrics => onOpenLyrics != null;

  bool get _hasChords => onOpenChords != null;

  bool get _hasActions =>
      isRemoving ||
      (!isMedley && onOpenYoutube != null) ||
      _hasLyrics ||
      _hasChords ||
      onEdit != null ||
      onDelete != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    Widget cardBody = SpringTap(
      onTap: onTap,
      pressedScale: 0.97,
      borderRadius: BorderRadius.circular(AppRadius.cardHero),
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
                      if (hasAudio) ...[const SizedBox(height: 6), _AudioTag()],
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
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
              child: isRemoving
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            if (!isMedley && onOpenYoutube != null)
                              AppCircularActionButton(
                                onPressed: onOpenYoutube,
                                assetPath: 'assets/icons/youtube.svg',
                                iconColor: cs.tertiary,
                                backgroundColor: cs.tertiaryContainer,
                                borderColor: cs.tertiary.withValues(alpha: 0.3),
                              ),
                            if (!isMedley &&
                                onOpenYoutube != null &&
                                (_hasLyrics || _hasChords))
                              const SizedBox(width: 8),
                            if (_hasLyrics)
                              _LyricsActionButton(onPressed: onOpenLyrics!),
                            if (_hasLyrics && _hasChords)
                              const SizedBox(width: 8),
                            if (_hasChords)
                              _ChordsActionButton(onPressed: onOpenChords!),
                          ],
                        ),
                        Row(
                          children: [
                            if (onEdit != null)
                              AppCircularActionButton(
                                onPressed: onEdit,
                                assetPath: 'assets/icons/file-music.svg',
                                iconColor: cs.onPrimaryContainer,
                                backgroundColor: cs.primaryContainer,
                                borderColor: cs.primary.withValues(alpha: 0.3),
                              ),
                            if (onDelete != null && onEdit != null)
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
                      ],
                    ),
            ),
          ],
        ],
      ),
    );

    Widget cardContent = DecoratedBox(
      decoration: appCardDecoration(context, radius: AppRadius.cardHero),
      child: cardBody,
    );

    if (onRemove != null) {
      cardContent = Dismissible(
        key: ValueKey(dismissKey ?? title),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) => onRemove!(),
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

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _LyricsActionButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _LyricsActionButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: 'Ver letra',
      child: AppCircularActionButton(
        onPressed: onPressed,
        assetPath: 'assets/icons/list-music.svg',
        iconColor: cs.onSecondaryContainer,
        backgroundColor: cs.secondaryContainer,
        borderColor: cs.secondary.withValues(alpha: 0.3),
      ),
    );
  }
}

class _ChordsActionButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ChordsActionButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: 'Ver cifra',
      child: AppCircularActionButton(
        onPressed: onPressed,
        assetPath: 'assets/icons/music.svg',
        iconColor: cs.onSurfaceVariant,
        backgroundColor: cs.surfaceContainerHighest,
        borderColor: cs.outline.withValues(alpha: 0.3),
      ),
    );
  }
}

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
          borderRadius: BorderRadius.circular(AppRadius.thumbnail),
        ),
        child: Center(
          child: Icon(
            Icons.queue_music_rounded,
            color: cs.onSecondaryContainer,
            size: 32,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.thumbnail),
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
        borderRadius: BorderRadius.circular(AppRadius.badge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.headphones_rounded,
            size: 11,
            color: cs.onSecondaryContainer,
          ),
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
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
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
