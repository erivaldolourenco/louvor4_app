import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/ui/app_feedback.dart';
import '../../../../core/ui/widgets/app_card_surface.dart';
import '../../../../core/ui/widgets/fade_slide_in.dart';
import '../../../../core/ui/widgets/reference_audio_player.dart';
import '../../../../core/ui/widgets/spring_tap.dart';
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
            // ── 1. Capa, título, artista e álbum (sem card) ────────
            FadeSlideIn(
              delay: staggerDelay(staggerStep++),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Capa
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.thumbnail),
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
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 21,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              size: 15,
                              color: mutedColor,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: mutedColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (hasAlbum) ...[
                          const SizedBox(height: 4),
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
                  // Tom e BPM alinhados à direita do cabeçalho
                  if (hasKey || hasBpm) ...[
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hasKey)
                          _MetaChip(
                            icon: Icons.key_rounded,
                            iconAsset: 'assets/icons/music-2.svg',
                            label: 'Tom: $normalizedKey',
                            backgroundColor: cs.primaryContainer,
                            foregroundColor: cs.onPrimaryContainer,
                          ),
                        if (hasKey && hasBpm) const SizedBox(height: 8),
                        if (hasBpm)
                          _MetaChip(
                            icon: Icons.speed_rounded,
                            iconAsset: 'assets/icons/time.svg',
                            label: '$normalizedBpm BPM',
                            backgroundColor: cs.secondaryContainer,
                            foregroundColor: cs.onSecondaryContainer,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // ── 2. Ações principais (Letra e Cifra em tamanho padrão) ────────
            if (onOpenLyrics != null || onOpenChords != null) ...[
              const SizedBox(height: 18),
              FadeSlideIn(
                delay: staggerDelay(staggerStep++),
                child: Column(
                  children: [
                    if (onOpenLyrics != null) ...[
                      _ActionButton(
                        label: 'Ver letra',
                        icon: Icons.menu_book_rounded,
                        iconAsset: 'assets/icons/file-type-corner.svg',
                        backgroundColor: cs.secondaryContainer,
                        foregroundColor: cs.onSecondaryContainer,
                        onTap: onOpenLyrics!,
                      ),
                    ],
                    if (onOpenLyrics != null && onOpenChords != null)
                      const SizedBox(height: 10),
                    if (onOpenChords != null) ...[
                      _ActionButton(
                        label: 'Ver cifra',
                        icon: Icons.queue_music_rounded,
                        iconAsset: 'assets/icons/file-music.svg',
                        backgroundColor: cs.primaryContainer,
                        foregroundColor: cs.onPrimaryContainer,
                        onTap: onOpenChords!,
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // ── 3. Observações ────────────────────────────────────
            if (hasNotes) ...[
              const SizedBox(height: 20),
              FadeSlideIn(
                delay: staggerDelay(staggerStep++),
                child: AppCardSurface(
                  radius: AppRadius.cardLarge,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: cs.primaryContainer,
                              borderRadius: BorderRadius.circular(
                                AppRadius.badge,
                              ),
                            ),
                            child: Icon(
                              Icons.sticky_note_2_rounded,
                              size: 16,
                              color: cs.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Observações',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
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
              const SizedBox(height: 20),
              FadeSlideIn(
                delay: staggerDelay(staggerStep++),
                child: ReferenceAudioPlayer(url: referenceAudioUrl!),
              ),
            ],

            // ── 5. Ouvir nas Plataformas (Stack em tamanho total) ──────────
            if (hasYouTube || hasSpotify || hasDeezer) ...[
              const SizedBox(height: 20),
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
                    if (hasYouTube) ...[
                      Builder(
                        builder: (context) {
                          final youtubeColor = theme.brightness == Brightness.dark
                              ? const Color(0xFFFF5252)
                              : const Color(0xFFD32F2F);

                          return _ActionButton(
                            label: 'Abrir no YouTube',
                            icon: Icons.play_circle_fill_rounded,
                            iconAsset: 'assets/icons/logo-youtube.svg',
                            backgroundColor: youtubeColor.withValues(alpha: 0.12),
                            foregroundColor: youtubeColor,
                            showExternalIcon: true,
                            onTap: () =>
                                _openExternalLink(context, youTubeUrl!, 'YouTube'),
                          );
                        },
                      ),
                    ],
                    if (hasSpotify) ...[
                      if (hasYouTube) const SizedBox(height: 10),
                      Builder(
                        builder: (context) {
                          final spotifyColor = theme.brightness == Brightness.dark
                              ? const Color(0xFF1DB954)
                              : const Color(0xFF168A3F);

                          return _ActionButton(
                            label: 'Abrir no Spotify',
                            icon: Icons.podcasts_rounded,
                            iconAsset: 'assets/icons/icon-spotify.svg',
                            backgroundColor: spotifyColor.withValues(alpha: 0.12),
                            foregroundColor: spotifyColor,
                            showExternalIcon: true,
                            onTap: () => _openExternalLink(
                              context,
                              spotifyUrl!,
                              'Spotify',
                            ),
                          );
                        },
                      ),
                    ],
                    if (hasDeezer) ...[
                      if (hasYouTube || hasSpotify) const SizedBox(height: 10),
                      _ActionButton(
                        label: 'Abrir no Deezer',
                        icon: Icons.equalizer_rounded,
                        iconAsset: 'assets/icons/icon-deezer.svg',
                        backgroundColor: cs.primaryContainer,
                        foregroundColor: cs.onPrimaryContainer,
                        showExternalIcon: true,
                        onTap: () =>
                            _openExternalLink(context, deezerUrl!, 'Deezer'),
                      ),
                    ],
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
// Action Button (Ver letra, Ver cifra, YouTube, Spotify, Deezer)
// ---------------------------------------------------------------------------

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? iconAsset;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onTap;
  final bool showExternalIcon;

  const _ActionButton({
    required this.label,
    required this.icon,
    this.iconAsset,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
    this.showExternalIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SpringTap(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.input),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppRadius.input),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            iconAsset != null
                ? SvgPicture.asset(
                    iconAsset!,
                    width: 22,
                    height: 22,
                    colorFilter: ColorFilter.mode(
                      foregroundColor,
                      BlendMode.srcIn,
                    ),
                  )
                : Icon(icon, size: 22, color: foregroundColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: foregroundColor,
                ),
              ),
            ),
            if (showExternalIcon)
              Icon(
                Icons.open_in_new_rounded,
                size: 16,
                color: foregroundColor,
              ),
          ],
        ),
      ),
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
