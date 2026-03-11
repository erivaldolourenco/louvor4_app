import 'package:flutter/material.dart';

class PrimaryAddFab extends StatelessWidget {
  final VoidCallback onPressed;
  final Object? heroTag;

  const PrimaryAddFab({super.key, required this.onPressed, this.heroTag});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FloatingActionButton(
      onPressed: onPressed,
      heroTag: heroTag,
      shape: const CircleBorder(),
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      elevation: 4,
      child: const Icon(Icons.add_rounded, size: 28),
    );
  }
}
