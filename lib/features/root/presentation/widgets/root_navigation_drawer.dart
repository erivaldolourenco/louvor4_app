import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:louvor4_app/features/root/presentation/widgets/root_user_avatar.dart';
import 'package:louvor4_app/features/user_profile/domain/entities/user_detail_entity.dart';
import '../../../../../core/theme/app_radius.dart';

class RootNavigationDrawer extends StatelessWidget {
  final UserDetailEntity? user;
  final bool isLoadingUser;
  final VoidCallback onProfileTap;
  final VoidCallback onUnavailabilityTap;

  const RootNavigationDrawer({
    super.key,
    required this.user,
    required this.isLoadingUser,
    required this.onProfileTap,
    required this.onUnavailabilityTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final username = _buildUsername();
    final drawerBackground = cs.surface;
    final secondaryTextColor = cs.onSurfaceVariant;

    return Drawer(
      backgroundColor: drawerBackground,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              RootUserAvatar(user: user, radius: 28, isLoading: isLoadingUser),
              const SizedBox(height: 14),
              Text(
                _buildFullName(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (username != null) ...[
                const SizedBox(height: 4),
                Text(
                  username,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: secondaryTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              const Divider(height: 1),
              const SizedBox(height: 12),
              _DrawerEntry(
                leading: SvgPicture.asset(
                  'assets/icons/circle-user-round.svg',
                  width: 22,
                  height: 22,
                  colorFilter: ColorFilter.mode(
                    theme.iconTheme.color ?? theme.colorScheme.onSurface,
                    BlendMode.srcIn,
                  ),
                ),
                label: 'Perfil',
                onTap: onProfileTap,
              ),
              _DrawerEntry(
                icon: Icons.event_busy_outlined,
                label: 'Indisponibilidades',
                onTap: onUnavailabilityTap,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildFullName() {
    if (isLoadingUser) return 'Carregando...';
    if (user == null) return 'Seu perfil';

    final fullName = '${user!.firstName} ${user!.lastName}'.trim();
    if (fullName.isNotEmpty) return fullName;
    if (user!.email.trim().isNotEmpty) return user!.email.trim();
    return 'Seu perfil';
  }

  String? _buildUsername() {
    if (isLoadingUser || user == null) return null;

    final username = user!.username.trim();
    if (username.isEmpty) return null;
    return '@$username';
  }
}

class _DrawerEntry extends StatelessWidget {
  final IconData? icon;
  final Widget? leading;
  final String label;
  final VoidCallback onTap;

  const _DrawerEntry({
    this.icon,
    this.leading,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: leading ?? Icon(icon, color: theme.iconTheme.color),
      title: Text(
        label,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
      onTap: onTap,
    );
  }
}
