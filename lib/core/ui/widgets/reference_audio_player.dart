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

class _ReferenceAudioPlayerState extends State<ReferenceAudioPlayer>
    with TickerProviderStateMixin {
  late final AudioPlayer _player;
  late final StreamSubscription<PlayerState> _stateSub;
  late final AnimationController _wavePhaseController;
  late final AnimationController _waveAmplitudeController;
  bool _isLoading = true;
  bool _hasError = false;
  bool _downloading = false;
  int _semitones = 0;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _wavePhaseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _waveAmplitudeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _stateSub = _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _player.seek(Duration.zero);
        _player.pause();
      }
      if (state.playing) {
        _waveAmplitudeController.forward();
        if (!_wavePhaseController.isAnimating) _wavePhaseController.repeat();
      } else {
        _waveAmplitudeController.reverse();
        _wavePhaseController.stop();
      }
    });
    _loadAudio();
  }

  Future<void> _loadAudio() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      await _player.setUrl(widget.url);
      if (mounted) setState(() => _isLoading = false);
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _stateSub.cancel();
    _player.dispose();
    _wavePhaseController.dispose();
    _waveAmplitudeController.dispose();
    super.dispose();
  }

  void _changeSemitones(int delta) {
    final next = (_semitones + delta).clamp(-12, 12);
    if (next == _semitones) return;
    setState(() => _semitones = next);
    _player.setPitch(pow(2.0, next / 12.0).toDouble());
  }

  void _resetSemitones() {
    if (_semitones == 0) return;
    setState(() => _semitones = 0);
    _player.setPitch(1.0);
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
    final isTransposed = _semitones != 0;

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
            // ── Cabeçalho M3 Expressive ──────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.badge),
                  ),
                  child: SvgPicture.asset(
                    'assets/icons/headphones.svg',
                    width: 20,
                    height: 20,
                    colorFilter: ColorFilter.mode(
                      cs.onPrimaryContainer,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Áudio de referência',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (isTransposed)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            _semitoneLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (!_hasError)
                  _downloading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: cs.primary,
                          ),
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
                            width: 18,
                            height: 18,
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

            // ── Estado de Erro M3 ───────────────────────────────────
            if (_hasError)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.errorContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(
                    color: cs.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 20,
                      color: cs.error,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Não foi possível carregar o áudio.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onErrorContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _loadAudio,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Tentar novamente'),
                      style: TextButton.styleFrom(
                        foregroundColor: cs.error,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              // ── Cápsula Expressiva de Tom (Pitch Shift) ───────────
              Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isTransposed
                        ? cs.tertiaryContainer.withValues(alpha: 0.7)
                        : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: isTransposed
                          ? cs.tertiary.withValues(alpha: 0.4)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        icon: const Icon(Icons.remove_rounded, size: 18),
                        color: _semitones > -12
                            ? (isTransposed
                                ? cs.onTertiaryContainer
                                : cs.onSurfaceVariant)
                            : cs.onSurfaceVariant.withValues(alpha: 0.3),
                        onPressed: _semitones > -12
                            ? () => _changeSemitones(-1)
                            : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: GestureDetector(
                          onTap: isTransposed ? _resetSemitones : null,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _semitoneLabel,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: isTransposed
                                      ? cs.onTertiaryContainer
                                      : cs.onSurface,
                                ),
                              ),
                              if (isTransposed) ...[
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: cs.onTertiaryContainer,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        color: _semitones < 12
                            ? (isTransposed
                                ? cs.onTertiaryContainer
                                : cs.onSurfaceVariant)
                            : cs.onSurfaceVariant.withValues(alpha: 0.3),
                        onPressed: _semitones < 12
                            ? () => _changeSemitones(1)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ── Stream de Estado & Progresso do Áudio ─────────────
              StreamBuilder<PlayerState>(
                stream: _player.playerStateStream,
                builder: (context, snapshot) {
                  final state = snapshot.data;
                  final isPlaying = state?.playing ?? false;
                  final isBuffering = _isLoading ||
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
                              // ── Slider M3 Expressive (trilha em onda) ──
                              AnimatedBuilder(
                                animation: Listenable.merge([
                                  _wavePhaseController,
                                  _waveAmplitudeController,
                                ]),
                                builder: (context, _) {
                                  return SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 8,
                                      trackShape: _WavySliderTrackShape(
                                        phase:
                                            _wavePhaseController.value *
                                            2 *
                                            pi,
                                        amplitude:
                                            4.5 *
                                            _waveAmplitudeController.value,
                                      ),
                                      thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 8,
                                      ),
                                      overlayShape:
                                          const RoundSliderOverlayShape(
                                        overlayRadius: 18,
                                      ),
                                      activeTrackColor: cs.primary,
                                      inactiveTrackColor:
                                          cs.primary.withValues(alpha: 0.18),
                                      thumbColor: cs.primary,
                                      overlayColor:
                                          cs.primary.withValues(alpha: 0.15),
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
                                  );
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _fmt(position),
                                      style:
                                          theme.textTheme.labelMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: cs.primary,
                                      ),
                                    ),
                                    Text(
                                      _fmt(duration),
                                      style:
                                          theme.textTheme.labelMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),

                              // ── Controles Principais M3 Morphing ───
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton.filledTonal(
                                    tooltip: 'Voltar 10 segundos',
                                    style: IconButton.styleFrom(
                                      backgroundColor: cs.secondaryContainer,
                                      foregroundColor: cs.onSecondaryContainer,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.badge,
                                        ),
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.replay_10_rounded,
                                      size: 22,
                                    ),
                                    onPressed: () =>
                                        _skip(const Duration(seconds: -10)),
                                  ),
                                  const SizedBox(width: 20),

                                  // Botão Principal Play/Pause com Shape Morphing M3
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.fastOutSlowIn,
                                    width: isPlaying ? 64 : 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: cs.primary,
                                      borderRadius: BorderRadius.circular(
                                        isPlaying
                                            ? AppRadius.card
                                            : AppRadius.pill,
                                      ),
                                      boxShadow: isPlaying
                                          ? [
                                              BoxShadow(
                                                color: cs.primary.withValues(
                                                  alpha: 0.35,
                                                ),
                                                blurRadius: 12,
                                                offset: const Offset(0, 4),
                                              )
                                            ]
                                          : [],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(
                                          isPlaying
                                              ? AppRadius.card
                                              : AppRadius.pill,
                                        ),
                                        onTap: () {
                                          if (isBuffering) return;
                                          if (isPlaying) {
                                            _player.pause();
                                          } else {
                                            _player.play();
                                          }
                                        },
                                        child: Center(
                                          child: AnimatedSwitcher(
                                            duration: const Duration(
                                              milliseconds: 250,
                                            ),
                                            transitionBuilder: (child, anim) {
                                              return ScaleTransition(
                                                scale: anim,
                                                child: child,
                                              );
                                            },
                                            child: isBuffering
                                                ? SizedBox(
                                                    key: const ValueKey(
                                                      'buffering',
                                                    ),
                                                    width: 26,
                                                    height: 26,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 3,
                                                      color: cs.onPrimary,
                                                    ),
                                                  )
                                                : SvgPicture.asset(
                                                    isPlaying
                                                        ? 'assets/icons/pause.svg'
                                                        : 'assets/icons/play.svg',
                                                    key: ValueKey(
                                                      isPlaying
                                                          ? 'pause'
                                                          : 'play',
                                                    ),
                                                    width: 28,
                                                    height: 28,
                                                    colorFilter:
                                                        ColorFilter.mode(
                                                      cs.onPrimary,
                                                      BlendMode.srcIn,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 20),

                                  IconButton.filledTonal(
                                    tooltip: 'Avançar 10 segundos',
                                    style: IconButton.styleFrom(
                                      backgroundColor: cs.secondaryContainer,
                                      foregroundColor: cs.onSecondaryContainer,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.badge,
                                        ),
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.forward_10_rounded,
                                      size: 22,
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

/// Track shape M3 Expressive: a parte já reproduzida é desenhada como uma
/// onda senoidal (o padrão de "wavy slider" introduzido no Material 3
/// Expressive para players de mídia); o restante permanece uma linha reta.
/// [amplitude] controla o quão "achatada" a onda está (0 = reto, parado) e
/// [phase] anima o deslocamento horizontal enquanto o áudio toca.
class _WavySliderTrackShape extends SliderTrackShape with BaseSliderTrackShape {
  final double phase;
  final double amplitude;
  final double wavelength;

  const _WavySliderTrackShape({
    required this.phase,
    required this.amplitude,
    this.wavelength = 24,
  });

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isEnabled = false,
    bool isDiscrete = false,
    required TextDirection textDirection,
  }) {
    final trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    final centerY = trackRect.center.dy;

    final inactivePaint = Paint()
      ..color = sliderTheme.inactiveTrackColor ?? Colors.transparent
      ..style = PaintingStyle.stroke
      ..strokeWidth = trackRect.height * 0.45
      ..strokeCap = StrokeCap.round;
    context.canvas.drawLine(
      Offset(thumbCenter.dx, centerY),
      Offset(trackRect.right, centerY),
      inactivePaint,
    );

    final activeWidth = thumbCenter.dx - trackRect.left;
    if (activeWidth <= 0) return;

    final activePaint = Paint()
      ..color = sliderTheme.activeTrackColor ?? Colors.transparent
      ..style = PaintingStyle.stroke
      ..strokeWidth = trackRect.height
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final steps = (activeWidth / 2).ceil().clamp(2, 400);
    for (var i = 0; i <= steps; i++) {
      final x = trackRect.left + activeWidth * i / steps;
      final y = amplitude == 0
          ? centerY
          : centerY + amplitude * sin((x / wavelength) * 2 * pi + phase);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    context.canvas.drawPath(path, activePaint);
  }
}
