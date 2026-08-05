import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/ui/app_feedback.dart';
import '../../../../core/ui/widgets/app_card_surface.dart';
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

    return Scaffold(
      appBar: StandardSectionAppBar(
        title: 'Detalhes da Música',
        subtitle: title,
        actions: [
          if (onEdit != null)
            IconButton(
              tooltip: 'Editar música',
              icon: Icon(Icons.edit_outlined, color: cs.primary),
              onPressed: onEdit,
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
          children: [
            // ── Card Principal Hero ──────────────────────────
            AppCardSurface(
              radius: AppRadius.cardLarge,
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      hasCover
                          ? coverUrl!
                          : YoutubeUtils.getThumbnail(
                              youTubeUrl,
                              quality: 'hqdefault',
                            ),
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, _) => Image.asset(
                        YoutubeUtils.defaultThumb,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: mutedColor,
                          ),
                        ),
                        if (hasAlbum) ...[
                          const SizedBox(height: 2),
                          Text(
                            normalizedAlbum,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: mutedColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Tom e BPM ──────────────────────────────────────
            if (hasKey || hasBpm) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (hasKey) _MetaBadge(label: 'Tom: $normalizedKey'),
                  if (hasBpm) _MetaBadge(label: '$normalizedBpm BPM'),
                ],
              ),
            ],

            // ── Ações principais (Letra e Cifra) ──────────────
            const SizedBox(height: 18),
            Row(
              children: [
                if (onOpenLyrics != null)
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onOpenLyrics,
                      style: FilledButton.styleFrom(
                        backgroundColor: cs.secondaryContainer,
                        foregroundColor: cs.onSecondaryContainer,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.input),
                          side: BorderSide(
                            color: cs.secondary.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.lyrics_outlined),
                      label: Text(
                        'Ver letra',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                if (onOpenLyrics != null && onOpenChords != null)
                  const SizedBox(width: 12),
                if (onOpenChords != null)
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onOpenChords,
                      style: FilledButton.styleFrom(
                        backgroundColor: cs.primaryContainer,
                        foregroundColor: cs.onPrimaryContainer,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.input),
                          side: BorderSide(
                            color: cs.primary.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.music_note_rounded),
                      label: Text(
                        'Ver cifra',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // ── Botão YouTube ──────────────────────────────────
            if (hasYouTube) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () =>
                    _openExternalLink(context, youTubeUrl!, 'YouTube'),
                style: FilledButton.styleFrom(
                  backgroundColor: cs.tertiaryContainer,
                  foregroundColor: cs.onTertiaryContainer,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.input),
                    side: BorderSide(color: cs.tertiary.withValues(alpha: 0.3)),
                  ),
                ),
                icon: const Icon(Icons.ondemand_video_rounded),
                label: Text(
                  'Abrir no YouTube',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],

            // ── Botões Spotify / Deezer ─────────────────────────
            if (hasSpotify || hasDeezer) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (hasSpotify)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _openExternalLink(context, spotifyUrl!, 'Spotify'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppRadius.input,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.podcasts_rounded, size: 18),
                        label: const Text('Spotify'),
                      ),
                    ),
                  if (hasSpotify && hasDeezer) const SizedBox(width: 10),
                  if (hasDeezer)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _openExternalLink(context, deezerUrl!, 'Deezer'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppRadius.input,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.album_rounded, size: 18),
                        label: const Text('Deezer'),
                      ),
                    ),
                ],
              ),
            ],

            // ── Player de áudio de referência ──────────────────
            if (hasAudio) ...[
              const SizedBox(height: 18),
              _AudioPlayer(url: referenceAudioUrl!),
            ],

            // ── Observações ────────────────────────────────────
            if (hasNotes) ...[
              const SizedBox(height: 18),
              AppCardSurface(
                radius: AppRadius.cardLarge,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.notes_rounded, size: 18, color: cs.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Observações',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      normalizedNotes,
                      style: TextStyle(color: mutedColor, height: 1.5),
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
// Audio player
// ---------------------------------------------------------------------------

class _AudioPlayer extends StatefulWidget {
  final String url;

  const _AudioPlayer({required this.url});

  @override
  State<_AudioPlayer> createState() => _AudioPlayerState();
}

class _AudioPlayerState extends State<_AudioPlayer> {
  late final AudioPlayer _player;
  late final StreamSubscription<PlayerState> _stateSub;
  bool _hasError = false;
  bool _downloading = false;
  int _semitones = 0;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _stateSub = _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _player.seek(Duration.zero);
        _player.pause();
      }
    });
    () async {
      try {
        await _player.setUrl(widget.url);
      } catch (_) {
        if (mounted) setState(() => _hasError = true);
      }
    }();
  }

  @override
  void dispose() {
    _stateSub.cancel();
    _player.dispose();
    super.dispose();
  }

  void _changeSemitones(int delta) {
    final next = (_semitones + delta).clamp(-12, 12);
    if (next == _semitones) return;
    setState(() => _semitones = next);
    _player.setPitch(pow(2.0, next / 12.0).toDouble());
  }

  Future<void> _download() async {
    setState(() => _downloading = true);
    try {
      final dir = Platform.isAndroid
          ? await getExternalStorageDirectory()
          : await getApplicationDocumentsDirectory();
      final base = dir ?? await getTemporaryDirectory();
      final rawName = widget.url.split('/').last.split('?').first;
      final fileName = rawName.isNotEmpty ? rawName : 'audio_referencia.mp3';
      final filePath = '${base.path}/$fileName';
      await Dio().download(widget.url, filePath);
      AppFeedback.showSuccess('Áudio salvo com sucesso.');
    } catch (_) {
      AppFeedback.showError('Erro ao baixar o áudio.');
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  String _fmt(Duration? d) {
    if (d == null) return '--:--';
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String get _semitoneLabel {
    if (_semitones == 0) return 'Tom original';
    final abs = _semitones.abs();
    final unit = abs == 1 ? 'semitom' : 'semitons';
    return '${_semitones > 0 ? '+' : ''}$_semitones $unit';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mutedColor = cs.onSurfaceVariant;
    final borderColor = cs.outlineVariant;
    final bgColor = isDark ? cs.surfaceContainerLow : cs.surfaceContainerHigh;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Áudio de referência',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (!_hasError)
                _downloading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        tooltip: 'Baixar áudio',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          Icons.download_rounded,
                          size: 22,
                          color: cs.primary,
                        ),
                        onPressed: _download,
                      ),
            ],
          ),
          const SizedBox(height: 12),
          if (_hasError)
            Row(
              children: [
                Icon(Icons.error_outline, size: 18, color: mutedColor),
                const SizedBox(width: 8),
                Text(
                  'Não foi possível carregar o áudio.',
                  style: TextStyle(color: mutedColor, fontSize: 13),
                ),
              ],
            )
          else ...[
            StreamBuilder<PlayerState>(
              stream: _player.playerStateStream,
              builder: (context, snapshot) {
                final state = snapshot.data;
                final isPlaying = state?.playing ?? false;
                final isBuffering =
                    state?.processingState == ProcessingState.buffering ||
                    state?.processingState == ProcessingState.loading;

                return StreamBuilder<Duration?>(
                  stream: _player.durationStream,
                  builder: (context, durationSnap) {
                    final duration = durationSnap.data;

                    return StreamBuilder<Duration>(
                      stream: _player.positionStream,
                      builder: (context, positionSnap) {
                        final position = positionSnap.data ?? Duration.zero;
                        final maxVal =
                            duration?.inMilliseconds.toDouble() ?? 0.0;
                        final curVal = maxVal > 0
                            ? position.inMilliseconds.toDouble().clamp(
                                0.0,
                                maxVal,
                              )
                            : 0.0;

                        return Row(
                          children: [
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: isBuffering
                                  ? const Padding(
                                      padding: EdgeInsets.all(10),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: Icon(
                                        isPlaying
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                        size: 32,
                                        color: cs.primary,
                                      ),
                                      onPressed: () => isPlaying
                                          ? _player.pause()
                                          : _player.play(),
                                    ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                children: [
                                  SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 3,
                                      thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 6,
                                      ),
                                      overlayShape:
                                          const RoundSliderOverlayShape(
                                            overlayRadius: 14,
                                          ),
                                      activeTrackColor: cs.primary,
                                      inactiveTrackColor: borderColor,
                                      thumbColor: cs.primary,
                                      overlayColor: cs.primary.withValues(
                                        alpha: 0.15,
                                      ),
                                    ),
                                    child: Slider(
                                      value: curVal,
                                      min: 0,
                                      max: maxVal > 0 ? maxVal : 1,
                                      onChanged: maxVal > 0
                                          ? (v) => _player.seek(
                                              Duration(milliseconds: v.toInt()),
                                            )
                                          : null,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _fmt(position),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: mutedColor,
                                          ),
                                        ),
                                        Text(
                                          _fmt(duration),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: mutedColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.input),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_rounded, size: 20),
                    color: _semitones > -12 ? cs.primary : mutedColor,
                    onPressed: _semitones > -12
                        ? () => _changeSemitones(-1)
                        : null,
                  ),
                  Expanded(
                    child: Text(
                      _semitoneLabel,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _semitones == 0 ? mutedColor : cs.primary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_rounded, size: 20),
                    color: _semitones < 12 ? cs.primary : mutedColor,
                    onPressed: _semitones < 12
                        ? () => _changeSemitones(1)
                        : null,
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

// ---------------------------------------------------------------------------
// Badges
// ---------------------------------------------------------------------------

class _MetaBadge extends StatelessWidget {
  final String label;

  const _MetaBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: cs.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
