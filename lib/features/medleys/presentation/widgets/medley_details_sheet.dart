import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/ui/app_feedback.dart';
import '../../../../../core/ui/widgets/app_card_surface.dart';
import '../../../../../core/utils/youtube_utils.dart';
import '../../domain/entities/medley_entity.dart';
import '../../domain/entities/medley_item_entity.dart';

Future<void> showMedleyDetailsModal(BuildContext context, MedleyEntity medley) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.bottomSheet),
      ),
    ),
    builder: (sheetContext) => _MedleyDetailsSheet(medley: medley),
  );
}

class _MedleyDetailsSheet extends StatelessWidget {
  final MedleyEntity medley;

  const _MedleyDetailsSheet({required this.medley});

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

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header: ícone + nome + descrição ───────────────
                Row(
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
                        child: Icon(
                          Icons.queue_music_rounded,
                          color: cs.onSecondaryContainer,
                          size: 32,
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

                // ── Notas ─────────────────────────────────────────
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
                          medley.notes!,
                          style: TextStyle(color: mutedColor, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Player de áudio de referência ──────────────────
                if (hasAudio) ...[
                  const SizedBox(height: 16),
                  _AudioPlayer(url: medley.referenceAudioUrl!),
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
                    _SongItemCard(item: medley.items[i]),
                    if (i < medley.items.length - 1) const SizedBox(height: 8),
                  ],
              ],
            ),
          ),
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
    final mutedColor = cs.onSurfaceVariant;
    final borderColor = cs.outlineVariant;
    final bgColor = cs.surfaceContainerLow;

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
          // ── Título + botão download ──────────────────────────────
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
            // ── Play + slider ──────────────────────────────────────
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
                                      thumbShape: RoundSliderThumbShape(
                                        enabledThumbRadius: 6,
                                      ),
                                      overlayShape: RoundSliderOverlayShape(
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

            // ── Controle de tom ────────────────────────────────────
            SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(AppRadius.input),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.remove_rounded, size: 20),
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
                    icon: Icon(Icons.add_rounded, size: 20),
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
