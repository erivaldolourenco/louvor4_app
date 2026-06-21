import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_radius.dart';
import '../../utils/youtube_utils.dart';
import '../app_feedback.dart';
import 'app_card_surface.dart';

Future<void> showSongDetailsModal(
  BuildContext context, {
  required String title,
  required String artist,
  String? musicKey,
  String? bpm,
  required String youTubeUrl,
  String? notes,
  String? referenceAudioUrl,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: SongDetailsSheet(
          title: title,
          artist: artist,
          musicKey: musicKey,
          bpm: bpm,
          youTubeUrl: youTubeUrl,
          notes: notes,
          referenceAudioUrl: referenceAudioUrl,
        ),
      );
    },
  );
}

class SongDetailsSheet extends StatelessWidget {
  final String title;
  final String artist;
  final String? musicKey;
  final String? bpm;
  final String youTubeUrl;
  final String? notes;
  final String? referenceAudioUrl;

  const SongDetailsSheet({
    super.key,
    required this.title,
    required this.artist,
    this.musicKey,
    this.bpm,
    required this.youTubeUrl,
    this.notes,
    this.referenceAudioUrl,
  });

  Future<void> _openYouTube(BuildContext context) async {
    final uri = Uri.tryParse(youTubeUrl);
    if (uri == null) {
      AppFeedback.showError('URL do YouTube inválida.');
      return;
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      AppFeedback.showError('Não foi possível abrir o YouTube.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final mutedColor =
        cs.onSurfaceVariant;

    final normalizedKey = musicKey?.trim();
    final normalizedBpm = bpm?.trim();
    final normalizedNotes = notes?.trim();
    final hasKey = normalizedKey != null && normalizedKey.isNotEmpty;
    final hasBpm = normalizedBpm != null && normalizedBpm.isNotEmpty;
    final hasNotes = normalizedNotes != null && normalizedNotes.isNotEmpty;
    final hasYouTube = youTubeUrl.trim().isNotEmpty;
    final hasAudio =
        referenceAudioUrl != null && referenceAudioUrl!.trim().isNotEmpty;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      child: AppCardSurface(
        radius: AppRadius.sheet,
        padding: const EdgeInsets.all(18),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header: cover + título + artista ──────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      YoutubeUtils.getThumbnail(
                        youTubeUrl,
                        quality: 'default',
                      ),
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, _) => Image.asset(
                        YoutubeUtils.defaultThumb,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
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
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: mutedColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),

              // ── Tom e BPM ──────────────────────────────────────
              if (hasKey || hasBpm) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (hasKey) _MetaBadge(label: 'Tom: $normalizedKey'),
                    if (hasBpm) _MetaBadge(label: '$normalizedBpm BPM'),
                  ],
                ),
              ],

              // ── Observações ────────────────────────────────────
              if (hasNotes) ...[
                const SizedBox(height: 16),
                AppCardSurface(
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
                        normalizedNotes,
                        style: TextStyle(color: mutedColor, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],

              // ── Player de áudio de referência ──────────────────
              if (hasAudio) ...[
                const SizedBox(height: 16),
                _AudioPlayer(url: referenceAudioUrl!),
              ],

              // ── Botão YouTube ──────────────────────────────────
              if (hasYouTube) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => _openYouTube(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFEF2F2),
                    foregroundColor: const Color(0xFFDC2626),
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.input),
                      side: const BorderSide(color: Color(0xFFFECACA)),
                    ),
                  ),
                  icon: const Icon(Icons.ondemand_video_rounded),
                  label: const Text(
                    'Abrir no YouTube',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ],
          ),
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
    final mutedColor =
        cs.onSurfaceVariant;
    final borderColor =
        cs.outlineVariant;
    final bgColor =
        isDark ? cs.surfaceContainerLow : cs.surfaceContainerHigh;

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
          // ── Título + botão download ──────────────────────────
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
                        constraints: BoxConstraints(),
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

          // ── Conteúdo ──────────────────────────────────────────
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
            // ── Play + slider ──────────────────────────────────
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
                            ? position.inMilliseconds
                                .toDouble()
                                .clamp(0.0, maxVal)
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
                                      thumbShape:
                                          RoundSliderThumbShape(
                                        enabledThumbRadius: 6,
                                      ),
                                      overlayShape:
                                          RoundSliderOverlayShape(
                                        overlayRadius: 14,
                                      ),
                                      activeTrackColor: cs.primary,
                                      inactiveTrackColor: borderColor,
                                      thumbColor: cs.primary,
                                      overlayColor: cs.primary
                                          .withValues(alpha: 0.15),
                                    ),
                                    child: Slider(
                                      value: curVal,
                                      min: 0,
                                      max: maxVal > 0 ? maxVal : 1,
                                      onChanged: maxVal > 0
                                          ? (v) => _player.seek(
                                                Duration(
                                                  milliseconds: v.toInt(),
                                                ),
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

            // ── Controle de tom ────────────────────────────────
            SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: isDark ? cs.surface : Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.input),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.remove_rounded, size: 20),
                    color: _semitones > -12 ? cs.primary : mutedColor,
                    onPressed:
                        _semitones > -12 ? () => _changeSemitones(-1) : null,
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
                    icon: Icon(Icons.add_rounded, size: 20),
                    color: _semitones < 12 ? cs.primary : mutedColor,
                    onPressed:
                        _semitones < 12 ? () => _changeSemitones(1) : null,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color:
            cs.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isDark ? Color(0xFF93C5FD) : cs.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
