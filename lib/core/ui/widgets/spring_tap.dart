import 'package:flutter/material.dart';

/// M3 emphasized-decelerate: começa rápido e assenta com uma leve
/// "ultrapassagem" (overshoot), a curva de mola característica do
/// Material 3 Expressive.
const Curve _m3Emphasized = Cubic(0.05, 0.7, 0.1, 1.0);

/// Encolhe o [child] ao toque e o "estica" de volta com uma curva de mola
/// expressiva ao soltar, somado a uma state layer (tingimento de cor) que
/// aparece durante a pressão — dando uma resposta tátil clara de que o
/// elemento foi tocado, no padrão Material 3 Expressive.
class SpringTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final BorderRadius borderRadius;

  const SpringTap({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.92,
    this.borderRadius = BorderRadius.zero,
  });

  @override
  State<SpringTap> createState() => _SpringTapState();
}

class _SpringTapState extends State<SpringTap> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final stateLayerColor = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: enabled ? (_) => _setPressed(true) : null,
      onTapUp: enabled ? (_) => _setPressed(false) : null,
      onTapCancel: enabled ? () => _setPressed(false) : null,
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: Duration(milliseconds: _pressed ? 100 : 380),
        curve: _pressed ? Curves.easeOut : _m3Emphasized,
        child: ClipRRect(
          borderRadius: widget.borderRadius,
          child: Stack(
            children: [
              widget.child,
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: _pressed ? 1.0 : 0.0,
                    duration: Duration(milliseconds: _pressed ? 100 : 220),
                    curve: Curves.easeOut,
                    child: ColoredBox(color: stateLayerColor.withValues(alpha: 0.08)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
