import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/app_radius.dart';
import '../../utils/url_utils.dart';
import '../../utils/youtube_utils.dart';
import 'app_card_surface.dart';
import 'app_circular_action_button.dart';
import 'spring_tap.dart';

class SongListCard extends StatelessWidget {
  final String title;
  final String? artist;
  final String? musicKey;
  final String? youTubeUrl;
  final String? spotifyUrl;
  final String? deezerUrl;
  final String? coverUrl;
  final bool isMedley;
  final bool hasAudio;
  final VoidCallback? onTap;
  final Future<bool> Function()? onRemove;
  final VoidCallback? onDelete;
  final bool isRemoving;
  final String? dismissKey;

  const SongListCard({
    super.key,
    required this.title,
    this.artist,
    this.musicKey,
    this.youTubeUrl,
    this.spotifyUrl,
    this.deezerUrl,
    this.coverUrl,
    this.isMedley = false,
    this.hasAudio = false,
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
                _Thumbnail(
                  youTubeUrl: youTubeUrl,
                  coverUrl: coverUrl,
                  isMedley: isMedley,
                ),
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
                      if (hasAudio ||
                          youTubeUrl != null && youTubeUrl!.isNotEmpty ||
                          spotifyUrl != null && spotifyUrl!.isNotEmpty ||
                          deezerUrl != null && deezerUrl!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 3,
                          runSpacing: 2,
                          children: [
                            if (hasAudio)
                              _SongTag(
                                label: 'Áudio',
                                icon: Icons.headphones_rounded,
                                backgroundColor: cs.primaryContainer
                                    .withValues(alpha: 0.7),
                                foregroundColor: cs.primary,
                              ),
                            if (youTubeUrl != null && youTubeUrl!.isNotEmpty)
                              Builder(
                                builder: (context) {
                                  final youtubeColor =
                                      theme.brightness == Brightness.dark
                                      ? const Color(0xFFFF5252)
                                      : const Color(0xFFD32F2F);
                                  return _SongTag(
                                    label: 'YouTube',
                                    iconAsset: 'assets/icons/logo-youtube.svg',
                                    backgroundColor: youtubeColor.withValues(
                                      alpha: 0.12,
                                    ),
                                    foregroundColor: youtubeColor,
                                  );
                                },
                              ),
                            if (spotifyUrl != null && spotifyUrl!.isNotEmpty)
                              Builder(
                                builder: (context) {
                                  final spotifyColor =
                                      theme.brightness == Brightness.dark
                                      ? const Color(0xFF1DB954)
                                      : const Color(0xFF168A3F);
                                  return _SongTag(
                                    label: 'Spotify',
                                    iconAsset: 'assets/icons/icon-spotify.svg',
                                    backgroundColor: spotifyColor.withValues(
                                      alpha: 0.12,
                                    ),
                                    foregroundColor: spotifyColor,
                                  );
                                },
                              ),
                            if (deezerUrl != null && deezerUrl!.isNotEmpty)
                              _SongTag(
                                label: 'Deezer',
                                iconAsset: 'assets/icons/icon-deezer.svg',
                                backgroundColor: const Color(
                                  0xFFA238FF,
                                ).withValues(alpha: 0.12),
                                foregroundColor: const Color(0xFFA238FF),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (!isMedley) ...[
                  const SizedBox(width: 12),
                  _KeyChip(musicKey: musicKey),
                ],
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

class _Thumbnail extends StatelessWidget {
  final String? youTubeUrl;
  final String? coverUrl;
  final bool isMedley;

  const _Thumbnail({
    required this.youTubeUrl,
    this.coverUrl,
    required this.isMedley,
  });

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

    final imageUrl = UrlUtils.isValidNetworkUrl(coverUrl)
        ? coverUrl!
        : YoutubeUtils.getThumbnail(youTubeUrl, quality: 'default');

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.thumbnail),
      child: Image.network(
        imageUrl,
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

class _KeyChip extends StatelessWidget {
  final String? musicKey;

  const _KeyChip({required this.musicKey});

  @override
  Widget build(BuildContext context) {
    final keyLabel = musicKey?.isNotEmpty == true ? musicKey! : '-';
    return _InfoChip(label: 'Tom', value: keyLabel, useTertiaryTheme: true);
  }
}

class _SongTag extends StatelessWidget {
  final String label;
  final IconData? icon;
  final String? iconAsset;
  final Color backgroundColor;
  final Color foregroundColor;

  const _SongTag({
    required this.label,
    this.icon,
    this.iconAsset,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.badge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconAsset != null
              ? SvgPicture.asset(
                  iconAsset!,
                  width: 8,
                  height: 8,
                  colorFilter: ColorFilter.mode(
                    foregroundColor,
                    BlendMode.srcIn,
                  ),
                )
              : Icon(icon, size: 8, color: foregroundColor),
          const SizedBox(width: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w700,
              fontSize: 8,
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
  final bool useTertiaryTheme;

  const _InfoChip({
    required this.label,
    required this.value,
    this.useTertiaryTheme = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bgColor = useTertiaryTheme
        ? cs.tertiaryContainer.withValues(alpha: 0.85)
        : cs.surfaceContainerHigh;
    final textColor = useTertiaryTheme ? cs.onTertiaryContainer : cs.onSurface;
    final labelColor = useTertiaryTheme
        ? cs.onTertiaryContainer.withValues(alpha: 0.8)
        : cs.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.badge),
        border: Border.all(
          color: useTertiaryTheme
              ? cs.tertiary.withValues(alpha: 0.25)
              : cs.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label ',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: labelColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            TextSpan(
              text: value,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
