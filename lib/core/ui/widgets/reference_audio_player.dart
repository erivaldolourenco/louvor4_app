import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import '../../theme/app_radius.dart';
import '../app_feedback.dart';

class ReferenceAudioPlayer extends StatefulWidget {
  final String url;

  const ReferenceAudioPlayer({super.key, required this.url});

  @override
  State<ReferenceAudioPlayer> createState() => _ReferenceAudioPlayerState();
}

class _ReferenceAudioPlayerState extends State<ReferenceAudioPlayer> {
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

  void _skip(Duration offset) {
    final duration = _player.duration;
    var target = _player.position + offset;
    if (target < Duration.zero) target = Duration.zero;
    if (duration != null && target > duration) target = duration;
    _player.seek(target);
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
    const playShape = BorderRadius.all(Radius.circular(20));

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.badge),
                ),
                child: SvgPicture.asset(
                  'assets/icons/headphones.svg',
                  width: 18,
                  height: 18,
                  colorFilter: ColorFilter.mode(
                    cs.onPrimaryContainer,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Áudio de referência',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
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
                    : IconButton.filledTonal(
                        tooltip: 'Baixar áudio',
                        visualDensity: VisualDensity.compact,
                        style: IconButton.styleFrom(
                          backgroundColor: cs.secondaryContainer,
                          foregroundColor: cs.onSecondaryContainer,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppRadius.badge,
                            ),
                          ),
                        ),
                        icon: SvgPicture.asset(
                          'assets/icons/arrow-down-to-line.svg',
                          width: 20,
                          height: 20,
                          colorFilter: ColorFilter.mode(
                            cs.onSecondaryContainer,
                            BlendMode.srcIn,
                          ),
                        ),
                        onPressed: _download,
                      ),
            ],
          ),
          const SizedBox(height: 16),

          if (_hasError)
            Row(
              children: [
                Icon(Icons.error_outline_rounded, size: 18, color: mutedColor),
                const SizedBox(width: 8),
                Text(
                  'Não foi possível carregar o áudio.',
                  style: TextStyle(color: mutedColor, fontSize: 13),
                ),
              ],
            )
          else ...[
            // ── Seletor de tom, em cápsula centralizada ────────────
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton.filledTonal(
                      visualDensity: VisualDensity.compact,
                      style: IconButton.styleFrom(
                        backgroundColor: _semitones > -12
                            ? cs.secondaryContainer
                            : Colors.transparent,
                        foregroundColor: _semitones > -12
                            ? cs.onSecondaryContainer
                            : mutedColor.withValues(alpha: 0.4),
                      ),
                      icon: const Icon(Icons.remove_rounded, size: 18),
                      onPressed: _semitones > -12
                          ? () => _changeSemitones(-1)
                          : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        _semitoneLabel,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: _semitones == 0 ? cs.onSurface : cs.primary,
                        ),
                      ),
                    ),
                    IconButton.filledTonal(
                      visualDensity: VisualDensity.compact,
                      style: IconButton.styleFrom(
                        backgroundColor: _semitones < 12
                            ? cs.secondaryContainer
                            : Colors.transparent,
                        foregroundColor: _semitones < 12
                            ? cs.onSecondaryContainer
                            : mutedColor.withValues(alpha: 0.4),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      onPressed: _semitones < 12
                          ? () => _changeSemitones(1)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

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

                        return Column(
                          children: [
                            // ── Barra de progresso ──────────────────
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 6,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 8,
                                ),
                                overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 18,
                                ),
                                activeTrackColor: cs.primary,
                                inactiveTrackColor: cs.primary.withValues(
                                  alpha: 0.15,
                                ),
                                thumbColor: cs.onSurfaceVariant,
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
                                      fontWeight: FontWeight.w700,
                                      color: cs.primary,
                                    ),
                                  ),
                                  Text(
                                    _fmt(duration),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: cs.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // ── Controles de reprodução ─────────────
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton.filledTonal(
                                  style: IconButton.styleFrom(
                                    backgroundColor: cs.secondaryContainer,
                                    foregroundColor: cs.onSecondaryContainer,
                                  ),
                                  icon: const Icon(
                                    Icons.replay_10_rounded,
                                    size: 24,
                                  ),
                                  onPressed: () =>
                                      _skip(const Duration(seconds: -10)),
                                ),
                                const SizedBox(width: 20),
                                SizedBox(
                                  width: 58,
                                  height: 58,
                                  child: isBuffering
                                      ? const Padding(
                                          padding: EdgeInsets.all(16),
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : IconButton.filled(
                                          style: IconButton.styleFrom(
                                            backgroundColor: cs.primary,
                                            foregroundColor: cs.onPrimary,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: playShape,
                                            ),
                                            minimumSize: const Size(58, 58),
                                            padding: EdgeInsets.zero,
                                          ),
                                          icon: SvgPicture.asset(
                                            isPlaying
                                                ? 'assets/icons/pause.svg'
                                                : 'assets/icons/play.svg',
                                            width: 32,
                                            height: 32,
                                            colorFilter: ColorFilter.mode(
                                              cs.onPrimary,
                                              BlendMode.srcIn,
                                            ),
                                          ),
                                          onPressed: () => isPlaying
                                              ? _player.pause()
                                              : _player.play(),
                                        ),
                                ),
                                const SizedBox(width: 20),
                                IconButton.filledTonal(
                                  style: IconButton.styleFrom(
                                    backgroundColor: cs.secondaryContainer,
                                    foregroundColor: cs.onSecondaryContainer,
                                  ),
                                  icon: const Icon(
                                    Icons.forward_10_rounded,
                                    size: 24,
                                  ),
                                  onPressed: () =>
                                      _skip(const Duration(seconds: 10)),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ],
        ),
      ),
    );
  }
}
