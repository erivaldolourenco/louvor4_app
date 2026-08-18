import 'dart:async';

import 'package:flutter/material.dart';

class AppFeedback {
  AppFeedback._();

  static var navigatorKey = GlobalKey<NavigatorState>();
  static OverlayEntry? _currentEntry;

  static void showError(String message) =>
      _show(message, icon: Icons.error_outline_rounded, type: _Type.error);

  static void showSuccess(String message) =>
      _show(message, icon: Icons.check_circle_outline_rounded, type: _Type.success);

  static void showInfo(String message) =>
      _show(message, icon: Icons.info_outline_rounded, type: _Type.info);

  static void _show(String message, {required IconData icon, required _Type type}) {
    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return;

    _currentEntry?.remove();
    _currentEntry = null;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _FeedbackToast(
        message: message,
        icon: icon,
        type: type,
        onDismiss: () {
          entry.remove();
          if (identical(_currentEntry, entry)) _currentEntry = null;
        },
      ),
    );
    _currentEntry = entry;
    overlay.insert(entry);
  }
}

enum _Type { error, success, info }

class _FeedbackToast extends StatefulWidget {
  final String message;
  final IconData icon;
  final _Type type;
  final VoidCallback onDismiss;

  const _FeedbackToast({
    required this.message,
    required this.icon,
    required this.type,
    required this.onDismiss,
  });

  @override
  State<_FeedbackToast> createState() => _FeedbackToastState();
}

class _FeedbackToastState extends State<_FeedbackToast> {
  static const _enterDuration = Duration(milliseconds: 260);
  static const _visibleDuration = Duration(seconds: 3);

  bool _visible = false;
  Timer? _autoHideTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _visible = true);
      _autoHideTimer = Timer(_visibleDuration, _hide);
    });
  }

  void _hide() {
    _autoHideTimer?.cancel();
    if (!mounted) return;
    setState(() => _visible = false);
    Future.delayed(_enterDuration, () {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _autoHideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (bg, fg) = switch (widget.type) {
      _Type.error => (cs.errorContainer, cs.onErrorContainer),
      _Type.success => (cs.primaryContainer, cs.onPrimaryContainer),
      _Type.info => (cs.secondaryContainer, cs.onSecondaryContainer),
    };

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
          child: AnimatedSlide(
            offset: _visible ? Offset.zero : const Offset(0, 1.5),
            duration: _enterDuration,
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              opacity: _visible ? 1 : 0,
              duration: _enterDuration,
              child: Material(
                color: Colors.transparent,
                child: Dismissible(
                  key: UniqueKey(),
                  direction: DismissDirection.down,
                  onDismissed: (_) => widget.onDismiss(),
                  child: GestureDetector(
                    onTap: _hide,
                    child: Container(
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Icon(widget.icon, color: fg, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.message,
                              style: TextStyle(
                                color: fg,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
