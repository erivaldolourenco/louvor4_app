import 'package:flutter/material.dart';

class AppFeedback {
  AppFeedback._();

  static var navigatorKey = GlobalKey<NavigatorState>();

  static void showError(String message) =>
      _show(message, icon: Icons.error_outline_rounded, type: _Type.error);

  static void showSuccess(String message) =>
      _show(message, icon: Icons.check_circle_outline_rounded, type: _Type.success);

  static void showInfo(String message) =>
      _show(message, icon: Icons.info_outline_rounded, type: _Type.info);

  static void _show(String message, {required IconData icon, required _Type type}) {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    final cs = Theme.of(context).colorScheme;

    final (bg, fg) = switch (type) {
      _Type.error   => (cs.errorContainer, cs.onErrorContainer),
      _Type.success => (cs.primaryContainer, cs.onPrimaryContainer),
      _Type.info    => (cs.secondaryContainer, cs.onSecondaryContainer),
    };

    ScaffoldMessenger.maybeOf(context)
      ?..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: bg,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Row(
            children: [
              Icon(icon, color: fg, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: fg, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      );
  }
}

enum _Type { error, success, info }
