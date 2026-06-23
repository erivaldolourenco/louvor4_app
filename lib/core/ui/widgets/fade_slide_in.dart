import 'dart:async';

import 'package:flutter/material.dart';

/// Atraso em stagger para animações de entrada de itens de lista, limitado
/// a [maxSteps] para não deixar os últimos itens lentos em listas grandes.
Duration staggerDelay(
  int index, {
  Duration step = const Duration(milliseconds: 45),
  int maxSteps = 8,
}) {
  return step * index.clamp(0, maxSteps);
}

/// Anima a entrada de um widget com fade + slide sutil, opcionalmente com
/// um atraso para permitir efeito de stagger entre múltiplos elementos.
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 420),
    this.offset = const Offset(0, 0.08),
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _fade = curved;
    _slide = Tween<Offset>(
      begin: widget.offset,
      end: Offset.zero,
    ).animate(curved);

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _delayTimer = Timer(widget.delay, () => _controller.forward());
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fade.value,
          child: FractionalTranslation(translation: _slide.value, child: child),
        );
      },
      child: widget.child,
    );
  }
}
