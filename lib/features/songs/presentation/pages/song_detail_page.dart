import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/ui/app_feedback.dart';
import '../../../../core/ui/widgets/app_card_surface.dart';
import '../../../../core/ui/widgets/fade_slide_in.dart';
import '../../../../core/ui/widgets/reference_audio_player.dart';
import '../../../../core/ui/widgets/standard_section_app_bar.dart';
import '../../../../core/utils/url_utils.dart';
import '../../../../core/utils/youtube_utils.dart';

Future<void> openSongDetailPage(
  BuildContext context, {
  String? songId,
  required String title,
  required String artist,
  String? musicKey,
  String? bpm,
  String? album,
  String? youTubeUrl,
  String? spotifyUrl,
  String? deezerUrl,
  String? coverUrl,
  String? notes,
  String? referenceAudioUrl,
  VoidCallback? onOpenLyrics,
  VoidCallback? onOpenChords,
  VoidCallback? onEdit,
}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => SongDetailPage(
        songId: songId,
        title: title,
        artist: artist,
        musicKey: musicKey,
        bpm: bpm,
        album: album,
        youTubeUrl: youTubeUrl,
        spotifyUrl: spotifyUrl,
        deezerUrl: deezerUrl,
        coverUrl: coverUrl,
        notes: notes,
        referenceAudioUrl: referenceAudioUrl,
        onOpenLyrics: onOpenLyrics,
        onOpenChords: onOpenChords,
        onEdit: onEdit,
      ),
    ),
  );
}

class SongDetailPage extends StatelessWidget {
  final String? songId;
  final String title;
  final String artist;
  final String? musicKey;
  final String? bpm;
  final String? album;
  final String? youTubeUrl;
  final String? spotifyUrl;
  final String? deezerUrl;
  final String? coverUrl;
  final String? notes;
  final String? referenceAudioUrl;
  final VoidCallback? onOpenLyrics;
  final VoidCallback? onOpenChords;
  final VoidCallback? onEdit;

  const SongDetailPage({
    super.key,
    this.songId,
    required this.title,
    required this.artist,
    this.musicKey,
    this.bpm,
    this.album,
    this.youTubeUrl,
    this.spotifyUrl,
    this.deezerUrl,
    this.coverUrl,
    this.notes,
    this.referenceAudioUrl,
    this.onOpenLyrics,
    this.onOpenChords,
    this.onEdit,
  });

  Future<void> _openExternalLink(
    BuildContext context,
    String url,
    String label,
  ) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      AppFeedback.showError('URL inválida.');
      return;
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      AppFeedback.showError('Não foi possível abrir o $label.');
    }
  }

  void _shareSong() {
    final buffer = StringBuffer('🎵 $title — $artist');
    final normalizedKey = musicKey?.trim();
    final normalizedBpm = bpm?.trim();

    if (normalizedKey != null && normalizedKey.isNotEmpty) {
      buffer.write('\n🗝️ Tom: $normalizedKey');
    }
    if (normalizedBpm != null && normalizedBpm.isNotEmpty) {
      buffer.write(' | ⏱️ BPM: $normalizedBpm');
    }
    if (youTubeUrl != null && youTubeUrl!.trim().isNotEmpty) {
      buffer.write('\n▶️ YouTube: $youTubeUrl');
    }

    Share.share(buffer.toString());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final mutedColor = cs.onSurfaceVariant;
    final isDark = theme.brightness == Brightness.dark;

    final normalizedKey = musicKey?.trim();
    final normalizedBpm = bpm?.trim();
    final normalizedAlbum = album?.trim();
    final normalizedNotes = notes?.trim();
    final hasKey = normalizedKey != null && normalizedKey.isNotEmpty;
    final hasBpm = normalizedBpm != null && normalizedBpm.isNotEmpty;
    final hasAlbum = normalizedAlbum != null && normalizedAlbum.isNotEmpty;
    final hasNotes = normalizedNotes != null && normalizedNotes.isNotEmpty;
    final hasYouTube = youTubeUrl != null && youTubeUrl!.trim().isNotEmpty;
    final hasSpotify = spotifyUrl != null && spotifyUrl!.trim().isNotEmpty;
    final hasDeezer = deezerUrl != null && deezerUrl!.trim().isNotEmpty;
    final hasCover = UrlUtils.isValidNetworkUrl(coverUrl);
    final hasAudio =
        referenceAudioUrl != null && referenceAudioUrl!.trim().isNotEmpty;

    int staggerStep = 0;

    return Scaffold(
      appBar: StandardSectionAppBar(
        title: 'Detalhes da Música',
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Mais opções',
            color: cs.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            icon: Icon(Icons.more_vert_rounded, color: cs.primary),
            onSelected: (value) {
              if (value == 'share') _shareSong();
              if (value == 'edit') onEdit?.call();
            },
            itemBuilder: (_) => [
              PopupMenuItem<String>(
                value: 'share',
                padding: EdgeInsets.zero,
                child: ListTile(
                  leading: SvgPicture.asset(
                    'assets/icons/shared.svg',
                    width: 20,
                    height: 20,
                    colorFilter: ColorFilter.mode(
                      cs.onSurface,
                      BlendMode.srcIn,
                    ),
                  ),
                  title: const Text('Compartilhar'),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  dense: true,
                ),
              ),
              if (onEdit != null)
                PopupMenuItem<String>(
                  value: 'edit',
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    leading: SvgPicture.asset(
                      'assets/icons/square-pen.svg',
                      width: 20,
                      height: 20,
                      colorFilter: ColorFilter.mode(
                        cs.onSurface,
                        BlendMode.srcIn,
                      ),
                    ),
                    title: const Text('Editar música'),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                    dense: true,
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
          children: [
            // ── 1. Capa, título, artista, metadados e álbum ────────
            FadeSlideIn(
              delay: staggerDelay(staggerStep++),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Capa
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.cardLarge),
                    child: Image.network(
                      hasCover
                          ? coverUrl!
                          : YoutubeUtils.getThumbnail(
                              youTubeUrl,
                              quality: 'hqdefault',
                            ),
                      width: 92,
                      height: 92,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, _) => Image.asset(
                        YoutubeUtils.defaultThumb,
                        width: 92,
                        height: 92,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        if (hasKey || hasBpm) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (hasKey)
                                _MetaChip(
                                  icon: Icons.key_rounded,
                                  iconAsset: 'assets/icons/music-2.svg',
                                  label: normalizedKey,
                                  backgroundColor: cs.tertiaryContainer,
                                  foregroundColor: cs.onTertiaryContainer,
                                ),
                              if (hasKey && hasBpm) const SizedBox(width: 8),
                              if (hasBpm)
                                _MetaChip(
                                  icon: Icons.speed_rounded,
                                  iconAsset: 'assets/icons/time.svg',
                                  label: normalizedBpm,
                                  backgroundColor: isDark
                                      ? AppColors.successSubtleDark
                                      : AppColors.successSubtleLight,
                                  foregroundColor: isDark
                                      ? AppColors.successBright
                                      : AppColors.success,
                                ),
                            ],
                          ),
                        ],
                        if (hasAlbum) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.album_rounded,
                                size: 14,
                                color: mutedColor,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  normalizedAlbum,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: mutedColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── 2. Ações principais (Letra secundária, Cifra primária) ────
            if (onOpenLyrics != null || onOpenChords != null) ...[
              const SizedBox(height: 24),
              FadeSlideIn(
                delay: staggerDelay(staggerStep++),
                child: Row(
                  children: [
                    if (onOpenLyrics != null) ...[
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: onOpenLyrics,
                          style: FilledButton.styleFrom(
                            backgroundColor: cs.secondaryContainer,
                            foregroundColor: cs.onSecondaryContainer,
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          icon: SvgPicture.asset(
                            'assets/icons/file-type-corner.svg',
                            width: 20,
                            height: 20,
                            colorFilter: ColorFilter.mode(
                              cs.onSecondaryContainer,
                              BlendMode.srcIn,
                            ),
                          ),
                          label: const Text('Ver letra'),
                        ),
                      ),
                    ],
                    if (onOpenLyrics != null && onOpenChords != null)
                      const SizedBox(width: 10),
                    if (onOpenChords != null) ...[
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: onOpenChords,
                          style: FilledButton.styleFrom(
                            backgroundColor: cs.primary,
                            foregroundColor: cs.onPrimary,
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          icon: SvgPicture.asset(
                            'assets/icons/file-music.svg',
                            width: 20,
                            height: 20,
                            colorFilter: ColorFilter.mode(
                              cs.onPrimary,
                              BlendMode.srcIn,
                            ),
                          ),
                          label: const Text('Ver cifra'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // ── 3. Observações ────────────────────────────────────
            if (hasNotes) ...[
              const SizedBox(height: 24),
              FadeSlideIn(
                delay: staggerDelay(staggerStep++),
                child: AppCardSurface(
                  radius: AppRadius.cardLarge,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Observações',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        normalizedNotes,
                        style: TextStyle(color: mutedColor, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // ── 4. Player de áudio de referência ──────────────────
            if (hasAudio) ...[
              const SizedBox(height: 24),
              FadeSlideIn(
                delay: staggerDelay(staggerStep++),
                child: ReferenceAudioPlayer(url: referenceAudioUrl!),
              ),
            ],

            // ── 5. Ouvir nas Plataformas (card único com ListTiles) ────
            if (hasYouTube || hasSpotify || hasDeezer) ...[
              const SizedBox(height: 24),
              FadeSlideIn(
                delay: staggerDelay(staggerStep++),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ouvir nas plataformas',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: mutedColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Card(
                      clipBehavior: Clip.antiAlias,
                      margin: EdgeInsets.zero,
                      child: Column(
                        children: [
                          if (hasYouTube)
                            Builder(
                              builder: (context) {
                                const youtubeRed = Color(0xFFFF0000);
                                return _PlatformTile(
                                  label: 'Abrir no YouTube',
                                  leading: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: youtubeRed,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      Icons.play_arrow_rounded,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                  onTap: () => _openExternalLink(
                                    context,
                                    youTubeUrl!,
                                    'YouTube',
                                  ),
                                );
                              },
                            ),
                          if (hasYouTube && (hasSpotify || hasDeezer))
                            const Divider(height: 1),
                          if (hasSpotify)
                            Builder(
                              builder: (context) {
                                final spotifyColor =
                                    theme.brightness == Brightness.dark
                                    ? const Color(0xFF1DB954)
                                    : const Color(0xFF168A3F);
                                return _PlatformTile(
                                  label: 'Abrir no Spotify',
                                  leading: SvgPicture.asset(
                                    'assets/icons/icon-spotify.svg',
                                    width: 28,
                                    height: 28,
                                    colorFilter: ColorFilter.mode(
                                      spotifyColor,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  onTap: () => _openExternalLink(
                                    context,
                                    spotifyUrl!,
                                    'Spotify',
                                  ),
                                );
                              },
                            ),
                          if (hasSpotify && hasDeezer) const Divider(height: 1),
                          if (hasDeezer)
                            _PlatformTile(
                              label: 'Abrir no Deezer',
                              leading: SvgPicture.asset(
                                'assets/icons/icon-deezer.svg',
                                width: 28,
                                height: 28,
                                colorFilter: const ColorFilter.mode(
                                  Color(0xFFA238FF),
                                  BlendMode.srcIn,
                                ),
                              ),
                              onTap: () =>
                                  _openExternalLink(context, deezerUrl!, 'Deezer'),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Platform tile (YouTube, Spotify, Deezer)
// ---------------------------------------------------------------------------

class _PlatformTile extends StatelessWidget {
  final Widget leading;
  final String label;
  final VoidCallback onTap;

  const _PlatformTile({
    required this.leading,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListTile(
      leading: leading,
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      trailing: Icon(
        Icons.open_in_new_rounded,
        size: 18,
        color: cs.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }
}

// ---------------------------------------------------------------------------
// Chips
// ---------------------------------------------------------------------------

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String? iconAsset;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  const _MetaChip({
    required this.icon,
    this.iconAsset,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconAsset != null
              ? SvgPicture.asset(
                  iconAsset!,
                  width: 16,
                  height: 16,
                  colorFilter: ColorFilter.mode(
                    foregroundColor,
                    BlendMode.srcIn,
                  ),
                )
              : Icon(icon, size: 16, color: foregroundColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: foregroundColor,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
