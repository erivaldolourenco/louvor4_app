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
    final theme = Theme.of(context);
    final activeColor = theme.colorScheme.primary;
    final inactiveColor = theme.brightness == Brightness.dark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF4D4D4D);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.brightness == Brightness.dark
                ? const Color(0xFF243041)
                : Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor:
            theme.bottomNavigationBarTheme.backgroundColor ??
            (theme.brightness == Brightness.dark
                ? const Color(0xFF111827)
                : Colors.white),
        elevation: 0,
        selectedItemColor: activeColor,
        unselectedItemColor: inactiveColor,
        selectedFontSize: 14,
        unselectedFontSize: 14,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
        items: [
          BottomNavigationBarItem(
            label: 'Início',
            icon: _buildSvgIcon(
              'assets/icons/layout-dashboard.svg',
              currentIndex == 0,
              activeColor,
              inactiveColor,
            ),
            activeIcon: _buildSvgIcon(
              'assets/icons/layout-dashboard.svg',
              true,
              activeColor,
              inactiveColor,
            ),
          ),
          BottomNavigationBarItem(
            label: 'Projetos',
            icon: _buildSvgIcon(
              'assets/icons/music.svg',
              currentIndex == 1,
              activeColor,
              inactiveColor,
            ),
            activeIcon: _buildSvgIcon(
              'assets/icons/music.svg',
              true,
              activeColor,
              inactiveColor,
            ),
          ),
          BottomNavigationBarItem(
            label: 'Músicas',
            icon: _buildSvgIcon(
              'assets/icons/audio-lines.svg',
              currentIndex == 2,
              activeColor,
              inactiveColor,
            ),
            activeIcon: _buildSvgIcon(
              'assets/icons/audio-lines.svg',
              true,
              activeColor,
              inactiveColor,
            ),
          ),
          BottomNavigationBarItem(
            label: 'Avisos',
            icon: _buildBellIcon(
              context,
              currentIndex == 3,
              activeColor,
              inactiveColor,
              unreadNotificationsCount,
            ),
            activeIcon: _buildBellIcon(
              context,
              true,
              activeColor,
              inactiveColor,
              unreadNotificationsCount,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSvgIcon(
    String assetName,
    bool isActive,
    Color activeColor,
    Color inactiveColor,
  ) {
    return SvgPicture.asset(
      assetName,
      height: isActive ? 32 : 28,
      width: isActive ? 32 : 28,
      colorFilter: ColorFilter.mode(
        isActive ? activeColor : inactiveColor,
        BlendMode.srcIn,
      ),
    );
  }

  Widget _buildBellIcon(
    BuildContext context,
    bool isActive,
    Color activeColor,
    Color inactiveColor,
    int unreadCount,
  ) {
    final borderColor = Theme.of(context).scaffoldBackgroundColor;
    final icon = Icon(
      isActive ? Icons.notifications : Icons.notifications_none_rounded,
      size: isActive ? 30 : 28,
      color: isActive ? activeColor : inactiveColor,
    );

    if (unreadCount <= 0) {
      return icon;
    }

    final badgeLabel = unreadCount > 99 ? '99+' : unreadCount.toString();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(
          top: -4,
          right: -10,
          child: Container(
            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE11D48),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: Center(
              child: Text(
                badgeLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
