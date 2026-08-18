import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:louvor4_app/features/root/presentation/widgets/root_user_avatar.dart';
import 'package:louvor4_app/features/user_profile/domain/entities/user_detail_entity.dart';

class RootNavigationDrawer extends StatelessWidget {
  final UserDetailEntity? user;
  final bool isLoadingUser;
  final VoidCallback onProfileTap;
  final VoidCallback onUnavailabilityTap;
  final VoidCallback onSongCategoriesTap;

  const RootNavigationDrawer({
    super.key,
    required this.user,
    required this.isLoadingUser,
    required this.onProfileTap,
    required this.onUnavailabilityTap,
    required this.onSongCategoriesTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return NavigationDrawer(
      selectedIndex: null,
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            onProfileTap();
          case 1:
            onUnavailabilityTap();
          case 2:
            onSongCategoriesTap();
        }
      },
      children: [
        _DrawerHeader(user: user, isLoadingUser: isLoadingUser),
        Divider(
          indent: 28,
          endIndent: 28,
          height: 1,
          color: cs.outlineVariant,
        ),
        const SizedBox(height: 8),
        NavigationDrawerDestination(
          icon: _SvgIcon('assets/icons/circle-user-round.svg', cs.onSurfaceVariant),
          selectedIcon: _SvgIcon('assets/icons/circle-user-round.svg', cs.onSecondaryContainer),
          label: const Text('Perfil'),
        ),
        NavigationDrawerDestination(
          icon: _SvgIcon('assets/icons/calendar.svg', cs.onSurfaceVariant),
          selectedIcon: _SvgIcon('assets/icons/calendar.svg', cs.onSecondaryContainer),
          label: const Text('Indisponibilidades'),
        ),
        NavigationDrawerDestination(
          icon: _SvgIcon('assets/icons/tags.svg', cs.onSurfaceVariant),
          selectedIcon: _SvgIcon('assets/icons/tags.svg', cs.onSecondaryContainer),
          label: const Text('Categorias'),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  final UserDetailEntity? user;
  final bool isLoadingUser;

  const _DrawerHeader({required this.user, required this.isLoadingUser});

  String get _fullName {
    if (isLoadingUser) return 'Carregando...';
    if (user == null) return 'Seu perfil';
    final fullName = '${user!.firstName} ${user!.lastName}'.trim();
    if (fullName.isNotEmpty) return fullName;
    if (user!.email.trim().isNotEmpty) return user!.email.trim();
    return 'Seu perfil';
  }

  String? get _username {
    if (isLoadingUser || user == null) return null;
    final username = user!.username.trim();
    return username.isEmpty ? null : '@$username';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
      child: Row(
        children: [
          RootUserAvatar(user: user, radius: 30, isLoading: isLoadingUser),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (_username != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _username!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
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
      width: 22,
      height: 22,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
