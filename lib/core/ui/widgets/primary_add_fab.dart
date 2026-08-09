import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PrimaryAddFab extends StatelessWidget {
  final VoidCallback onPressed;
  final Object? heroTag;
  final IconData icon;
  final String? iconAsset;

  const PrimaryAddFab({
    super.key,
    required this.onPressed,
    this.heroTag,
    this.icon = Icons.add_rounded,
    this.iconAsset,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FloatingActionButton(
      onPressed: onPressed,
      heroTag: heroTag,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: colorScheme.primaryContainer,
      foregroundColor: colorScheme.onPrimaryContainer,
      elevation: 2,
      child: iconAsset != null
          ? SvgPicture.asset(
              iconAsset!,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                colorScheme.onPrimaryContainer,
                BlendMode.srcIn,
              ),
            )
          : Icon(icon, size: 28),
    );
  }
}
