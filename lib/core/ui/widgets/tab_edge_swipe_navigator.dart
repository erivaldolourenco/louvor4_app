import 'package:flutter/material.dart';

/// Wraps a horizontally-swipeable [child] (typically a [TabBarView]) so
/// that dragging past its first or last tab can advance/retreat a parent
/// page carousel, instead of just rubber-banding with no effect.
///
/// - [onSwipePastLast] fires when the user drags past the last tab while
///   already on it (i.e. trying to go further "forward").
/// - [onSwipePastFirst] fires when the user drags past the first tab while
///   already on it (trying to go further "backward").
/// - Bump [arrivalToken] (e.g. an incrementing counter) to make this tab
///   set land on its first or last tab — used when it becomes the
///   destination of a cross-page swipe, so the whole app feels like one
///   continuous carousel of tabs. Because the page hosting this widget is
///   typically rebuilt fresh (not reused) on every navigation, the token
///   is honored both on first build and on later updates.
class TabEdgeSwipeNavigator extends StatefulWidget {
  final TabController controller;
  final Widget child;
  final VoidCallback? onSwipePastLast;
  final VoidCallback? onSwipePastFirst;
  final Object? arrivalToken;
  final bool arrivalLandOnLast;

  const TabEdgeSwipeNavigator({
    super.key,
    required this.controller,
    required this.child,
    this.onSwipePastLast,
    this.onSwipePastFirst,
    this.arrivalToken,
    this.arrivalLandOnLast = false,
  });

  @override
  State<TabEdgeSwipeNavigator> createState() => _TabEdgeSwipeNavigatorState();
}

class _TabEdgeSwipeNavigatorState extends State<TabEdgeSwipeNavigator> {
  static const _commitThreshold = 32.0;

  double _accumulatedOverscroll = 0;

  @override
  void initState() {
    super.initState();
    if (widget.arrivalToken != null) {
      _scheduleJump();
    }
  }

  @override
  void didUpdateWidget(covariant TabEdgeSwipeNavigator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.arrivalToken != null &&
        widget.arrivalToken != oldWidget.arrivalToken) {
      _scheduleJump();
    }
  }

  /// Anima até a aba de chegada em vez de simplesmente aparecer nela —
  /// tanto na primeira montagem (a página host é recriada a cada
  /// navegação) quanto em atualizações posteriores.
  void _scheduleJump() {
    final target = widget.arrivalLandOnLast ? widget.controller.length - 1 : 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.controller.animateTo(target);
    });
  }

  bool _handleNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.horizontal) return false;

    if (notification is ScrollStartNotification) {
      _accumulatedOverscroll = 0;
    } else if (notification is OverscrollNotification) {
      _accumulatedOverscroll += notification.overscroll;
    } else if (notification is ScrollEndNotification) {
      final overscroll = _accumulatedOverscroll;
      _accumulatedOverscroll = 0;
      final controller = widget.controller;
      if (overscroll > _commitThreshold &&
          controller.index == controller.length - 1) {
        widget.onSwipePastLast?.call();
      } else if (overscroll < -_commitThreshold && controller.index == 0) {
        widget.onSwipePastFirst?.call();
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _handleNotification,
      child: widget.child,
    );
  }
}
