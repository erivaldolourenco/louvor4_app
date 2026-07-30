import 'package:flutter/material.dart';
import 'package:louvor4_app/core/ui/widgets/app_logo.dart';
import 'package:louvor4_app/features/root/presentation/widgets/root_user_avatar.dart';
import 'package:louvor4_app/features/user_profile/domain/entities/user_detail_entity.dart';

class RootHomeHeader extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onAvatarTap;
  final UserDetailEntity? user;
  final bool isLoadingUser;

  const RootHomeHeader({
    super.key,
    required this.onAvatarTap,
    required this.user,
    required this.isLoadingUser,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final surfaceColor = theme.appBarTheme.backgroundColor ?? cs.surface;

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: surfaceColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      toolbarHeight: 68,
      leadingWidth: 68,
      leading: Center(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onAvatarTap,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: RootUserAvatar(
                  user: user,
                  radius: 18,
                  isLoading: isLoadingUser,
                ),
              ),
            ),
          ),
        ),
      ),
      title: const AppLogo(height: 34),
      actions: const [SizedBox(width: 68)],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(68);
}
