import 'package:flutter/material.dart';
import 'package:louvor4_app/core/ui/widgets/app_cached_network_image.dart';
import 'package:louvor4_app/features/user_profile/domain/entities/user_detail_entity.dart';

class RootUserAvatar extends StatelessWidget {
  final UserDetailEntity? user;
  final double radius;
  final bool isLoading;

  const RootUserAvatar({
    super.key,
    required this.user,
    required this.radius,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileImage = user?.profileImage?.trim();
    final hasProfileImage = profileImage != null && profileImage.isNotEmpty;
    final backgroundColor = theme.brightness == Brightness.dark
        ? const Color(0xFF172554)
        : const Color(0xFFE8F0FF);

    if (isLoading) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        child: SizedBox(
          width: radius,
          height: radius,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      foregroundImage: hasProfileImage
          ? appCachedImageProvider(profileImage)
          : null,
      backgroundColor: backgroundColor,
      child: !hasProfileImage
          ? Text(
              _buildInitial(),
              style: TextStyle(
                color: const Color(0xFF0166FF),
                fontSize: radius * 0.9,
                fontWeight: FontWeight.w800,
              ),
            )
          : null,
    );
  }

  String _buildInitial() {
    if (user == null) return '?';

    final fullName = '${user!.firstName} ${user!.lastName}'.trim();
    if (fullName.isNotEmpty) {
      return fullName.characters.first.toUpperCase();
    }

    final email = user!.email.trim();
    if (email.isNotEmpty) {
      return email.characters.first.toUpperCase();
    }

    return '?';
  }
}
