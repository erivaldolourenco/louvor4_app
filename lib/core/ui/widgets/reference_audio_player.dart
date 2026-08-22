import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:just_audio/just_audio.dart';

import '../../theme/app_motion.dart';
import '../../theme/app_radius.dart';

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

    // M3: Card.outlined "sutil" — fundo surface-container, borda
    // outline-variant, sem elevação/sombra, 12dp de raio (padrão de canto
    // do Card no Material 3), em vez de um Card elevado com sombra.
    return Card.outlined(
      elevation: 0,
      color: cs.surfaceContainerLow,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                              // ── Stepper de tom, acima da timeline ──────
                              Center(
                                child: _TomStepper(
                                  label: _semitoneLabel,
                                  isTransposed: isTransposed,
                                  canDecrease: _semitones > -12,
                                  canIncrease: _semitones < 12,
                                  onDecrease: () => _changeSemitones(-1),
                                  onIncrease: () => _changeSemitones(1),
                                  onReset: _resetSemitones,
                                ),
                              ),

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
                                        overlayRadius: 11,
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
                              const SizedBox(height: 16),

                              // ── Voltar 10s | Play | Avançar 10s (centralizado) ──
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  _TomStepButton(
                                    icon: Icons.replay_10_rounded,
                                    enabled: true,
                                    onTap: () =>
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
                                  _TomStepButton(
                                    icon: Icons.forward_10_rounded,
                                    enabled: true,
                                    onTap: () =>
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

/// Stepper de tom (pitch): cápsula neutra com dois botões circulares
/// preenchidos nas pontas — desenho de referência do usuário para o
/// controle de "Tom original / +N semitons".
class _TomStepper extends StatelessWidget {
  final String label;
  final bool isTransposed;
  final bool canDecrease;
  final bool canIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onReset;

  const _TomStepper({
    required this.label,
    required this.isTransposed,
    required this.canDecrease,
    required this.canIncrease,
    required this.onDecrease,
    required this.onIncrease,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TomStepButton(
            icon: Icons.remove_rounded,
            enabled: canDecrease,
            onTap: onDecrease,
            size: 30,
            iconSize: 15,
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: GestureDetector(
                onTap: isTransposed ? onReset : null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        label.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    if (isTransposed) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.close_rounded,
                        size: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          _TomStepButton(
            icon: Icons.add_rounded,
            enabled: canIncrease,
            onTap: onIncrease,
            size: 30,
            iconSize: 15,
          ),
        ],
      ),
    );
  }
}

class _TomStepButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  final double size;
  final double iconSize;

  const _TomStepButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
    this.size = 44,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // TweenAnimationBuilder (não AnimatedContainer) para que a cor anime
    // suavemente ao habilitar/desabilitar sem perder o ripple do InkWell —
    // o ripple é pintado pelo próprio Material, então a cor precisa viver
    // nele, não num Container por cima (que esconderia o ripple).
    return TweenAnimationBuilder<Color?>(
      duration: const Duration(milliseconds: 180),
      curve: appExpressiveCurve,
      tween: ColorTween(
        end: enabled ? cs.primary : cs.primary.withValues(alpha: 0.35),
      ),
      builder: (context, color, child) => Material(
        color: color,
        shape: const CircleBorder(),
        child: child,
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: iconSize, color: cs.onPrimary),
        ),
      ),
    );
  }
}
