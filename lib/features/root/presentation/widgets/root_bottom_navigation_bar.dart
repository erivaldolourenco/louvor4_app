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

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      destinations: [
        NavigationDestination(
          label: 'Início',
          icon: _SvgIcon('assets/icons/layout-dashboard.svg', cs.onSurfaceVariant),
          selectedIcon: _SvgIcon('assets/icons/layout-dashboard.svg', cs.onPrimaryContainer),
        ),
        NavigationDestination(
          label: 'Projetos',
          icon: _SvgIcon('assets/icons/square-library.svg', cs.onSurfaceVariant),
          selectedIcon: _SvgIcon('assets/icons/square-library.svg', cs.onPrimaryContainer),
        ),
        NavigationDestination(
          label: 'Músicas',
          icon: _SvgIcon('assets/icons/list-music.svg', cs.onSurfaceVariant),
          selectedIcon: _SvgIcon('assets/icons/list-music.svg', cs.onPrimaryContainer),
        ),
        NavigationDestination(
          label: 'Avisos',
          icon: Badge(
            isLabelVisible: showBadge,
            label: Text(badgeLabel),
            child: _SvgIcon('assets/icons/bell.svg', cs.onSurfaceVariant),
          ),
          selectedIcon: Badge(
            isLabelVisible: showBadge,
            label: Text(badgeLabel),
            child: _SvgIcon('assets/icons/bell.svg', cs.onPrimaryContainer),
          ),
        ),
      ],
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
