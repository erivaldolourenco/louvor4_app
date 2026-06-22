import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:louvor4_app/features/root/presentation/widgets/root_user_avatar.dart';
import 'package:louvor4_app/features/user_profile/domain/entities/user_detail_entity.dart';

class RootHomeHeader extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onAvatarTap;
  final UserDetailEntity? user;
  final bool isLoadingUser;
  final bool elevated;

  const RootHomeHeader({
    super.key,
    required this.onAvatarTap,
    required this.user,
    required this.isLoadingUser,
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final surfaceColor = theme.appBarTheme.backgroundColor ?? cs.surface;

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: surfaceColor,
      surfaceTintColor: cs.surfaceTint,
      elevation: elevated ? 3 : 0,
      scrolledUnderElevation: 0,
      shadowColor: cs.shadow,
      centerTitle: true,
      toolbarHeight: 68,
      leadingWidth: 68,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16, top: 10, bottom: 10),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onAvatarTap,
            customBorder: const CircleBorder(),
            child: RootUserAvatar(
              user: user,
              radius: 12,
              isLoading: isLoadingUser,
            ),
          ),
        ),
      ),
      title: SvgPicture.asset('assets/images/logos/logo-icon.svg', height: 34),
      actions: const [SizedBox(width: 68)],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(68);
}
