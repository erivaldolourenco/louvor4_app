import 'package:flutter/material.dart';

class AppFeedback {
  AppFeedback._();

  static final navigatorKey = GlobalKey<NavigatorState>();

  static void showError(String message) {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: cs.onError)),
        backgroundColor: cs.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void showSuccess(String message) {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: cs.onPrimaryContainer)),
        backgroundColor: cs.primaryContainer,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void showInfo(String message) {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: cs.onPrimary)),
        backgroundColor: cs.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
