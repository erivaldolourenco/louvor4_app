import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class RootBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final int unreadNotificationsCount;
  final ValueChanged<int> onTap;

  const RootBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.unreadNotificationsCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final badgeLabel = unreadNotificationsCount > 99
        ? '99+'
        : '$unreadNotificationsCount';
    final showBadge = unreadNotificationsCount > 0;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
        ),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: NavigationBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: cs.primaryContainer,
        selectedIndex: currentIndex,
        onDestinationSelected: onTap,
        destinations: [
          NavigationDestination(
            label: 'Início',
            icon: _SvgIcon(
              'assets/icons/layout-dashboard.svg',
              cs.onSurfaceVariant,
            ),
            selectedIcon: _ActiveIcon(
              child: _SvgIcon('assets/icons/layout-dashboard.svg', cs.onPrimaryContainer),
            ),
          ),
          NavigationDestination(
            label: 'Projetos',
            icon: _SvgIcon(
              'assets/icons/square-library.svg',
              cs.onSurfaceVariant,
            ),
            selectedIcon: _ActiveIcon(
              child: _SvgIcon('assets/icons/square-library.svg', cs.onPrimaryContainer),
            ),
          ),
          NavigationDestination(
            label: 'Músicas',
            icon: _SvgIcon('assets/icons/list-music.svg', cs.onSurfaceVariant),
            selectedIcon: _ActiveIcon(
              child: _SvgIcon('assets/icons/list-music.svg', cs.onPrimaryContainer),
            ),
          ),
          NavigationDestination(
            label: 'Avisos',
            icon: Badge(
              isLabelVisible: showBadge,
              label: Text(badgeLabel),
              child: _SvgIcon('assets/icons/bell.svg', cs.onSurfaceVariant),
            ),
            selectedIcon: _ActiveIcon(
              child: Badge(
                isLabelVisible: showBadge,
                label: Text(badgeLabel),
                child: _SvgIcon('assets/icons/bell.svg', cs.onPrimaryContainer),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveIcon extends StatelessWidget {
  final Widget child;

  const _ActiveIcon({required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: 1.18),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: child,
    );
  }
}

class _SvgIcon extends StatelessWidget {
  final String asset;
  final Color color;

  const _SvgIcon(this.asset, this.color);

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset,
      height: 24,
      width: 24,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
