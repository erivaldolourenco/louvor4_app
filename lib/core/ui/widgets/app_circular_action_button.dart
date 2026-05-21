import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppCircularActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String assetPath;
  final Color iconColor;
  final Color backgroundColor;
  final Color borderColor;
  final double size;
  final double iconSize;

  const AppCircularActionButton({
    super.key,
    required this.onPressed,
    required this.assetPath,
    required this.iconColor,
    required this.backgroundColor,
    required this.borderColor,
    this.size = 40,
    this.iconSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor),
          ),
          child: Center(
            child: SvgPicture.asset(
              assetPath,
              width: iconSize,
              height: iconSize,
              colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
            ),
          ),
        ),
      ),
    );
  }
}
