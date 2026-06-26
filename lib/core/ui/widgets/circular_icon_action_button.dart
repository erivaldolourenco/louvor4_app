import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Botão circular tonal usado para ações rápidas em cards (editar, excluir...).
class CircularIconActionButton extends StatelessWidget {
  final String tooltip;
  final VoidCallback? onPressed;
  final String assetPath;
  final Color iconColor;
  final Color backgroundColor;
  final Color borderColor;

  const CircularIconActionButton({
    super.key,
    required this.tooltip,
    required this.onPressed,
    required this.assetPath,
    required this.iconColor,
    required this.backgroundColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: backgroundColor,
        shape: CircleBorder(side: BorderSide(color: borderColor)),
        minimumSize: const Size(40, 40),
        padding: EdgeInsets.zero,
      ),
      icon: SvgPicture.asset(
        assetPath,
        width: 18,
        height: 18,
        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
      ),
    );
  }
}
