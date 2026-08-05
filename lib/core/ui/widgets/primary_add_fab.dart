import 'package:flutter/material.dart';

class PrimaryAddFab extends StatelessWidget {
  final VoidCallback onPressed;
  final Object? heroTag;
  final IconData icon;

  const PrimaryAddFab({
    super.key,
    required this.onPressed,
    this.heroTag,
    this.icon = Icons.add_rounded,
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
      child: Icon(icon, size: 28),
    );
  }
}
