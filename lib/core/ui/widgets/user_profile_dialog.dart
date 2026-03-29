import 'package:flutter/material.dart';

import 'app_cached_network_image.dart';
import 'app_card_surface.dart';

Future<void> showUserProfileDialog(
  BuildContext context, {
  required String name,
  String? profileImageUrl,
  String? username,
  String? email,
  String? projectPermission,
  List<String>? musicSkills,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => UserProfileDialog(
      name: name,
      profileImageUrl: profileImageUrl,
      username: username,
      email: email,
      projectPermission: projectPermission,
      musicSkills: musicSkills,
    ),
  );
}

class UserProfileDialog extends StatelessWidget {
  final String name;
  final String? profileImageUrl;
  final String? username;
  final String? email;
  final String? projectPermission;
  final List<String>? musicSkills;

  const UserProfileDialog({
    super.key,
    required this.name,
    this.profileImageUrl,
    this.username,
    this.email,
    this.projectPermission,
    this.musicSkills,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = theme.textTheme.titleLarge?.color;
    final subtitleColor = theme.textTheme.bodyMedium?.color?.withValues(
      alpha: 0.74,
    );
    final hasImage =
        profileImageUrl != null && profileImageUrl!.trim().isNotEmpty;
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    final normalizedUsername = _normalizedValue(username);
    final normalizedEmail = _normalizedValue(email);
    final normalizedPermission = _normalizedValue(projectPermission);
    final normalizedSkills = (musicSkills ?? const <String>[])
        .map((skill) => skill.trim())
        .where((skill) => skill.isNotEmpty)
        .toList();
    final infoColor = theme.textTheme.bodyLarge?.color;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: AppCardSurface(
        radius: 28,
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 18),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.82,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          color: isDark
                              ? const Color(0xFF172554)
                              : const Color(0xFFEFF6FF),
                          child: hasImage
                              ? Image(
                                  image: appCachedImageProvider(
                                    profileImageUrl,
                                  )!,
                                  fit: BoxFit.cover,
                                )
                              : Center(
                                  child: Text(
                                    initial,
                                    style: const TextStyle(
                                      color: Color(0xFF0166FF),
                                      fontSize: 72,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Material(
                        color: Colors.black.withValues(alpha: 0.18),
                        shape: const CircleBorder(),
                        child: IconButton(
                          tooltip: 'Fechar',
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                  ),
                ),
                if (normalizedUsername != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '@$normalizedUsername',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: subtitleColor,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (normalizedEmail != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    normalizedEmail,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: infoColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (normalizedPermission != null) ...[
                  const SizedBox(height: 18),
                  _ProfileSectionTitle(label: 'Permissões de acesso'),
                  const SizedBox(height: 12),
                  _ProfilePermissionPill(value: normalizedPermission),
                ],
                if (normalizedSkills.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _ProfileSkillsBlock(
                    title: 'Funções musicais',
                    skills: normalizedSkills,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String? _normalizedValue(String? value) {
    final normalized = value?.trim() ?? '';
    return normalized.isEmpty ? null : normalized;
  }
}

class _ProfileSectionTitle extends StatelessWidget {
  final String label;

  const _ProfileSectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 2.4,
          color: theme.textTheme.titleSmall?.color?.withValues(alpha: 0.62),
        ),
      ),
    );
  }
}

class _ProfilePermissionPill extends StatelessWidget {
  final String value;

  const _ProfilePermissionPill({required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF132033) : const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFBFDBFE),
          ),
        ),
        child: Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF0166FF),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ProfileSkillsBlock extends StatelessWidget {
  final String title;
  final List<String> skills;

  const _ProfileSkillsBlock({required this.title, required this.skills});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProfileSectionTitle(label: title),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFD9DEE8),
              style: BorderStyle.solid,
            ),
          ),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: skills
                .map(
                  (skill) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF132033)
                          : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF1E3A5F)
                            : const Color(0xFFBFDBFE),
                      ),
                    ),
                    child: Text(
                      skill,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: const Color(0xFF0166FF),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}
