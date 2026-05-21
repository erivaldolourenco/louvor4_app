import 'package:flutter/material.dart';
import 'package:louvor4_app/features/events/domain/entities/event_participant_entity.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
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
  String? eventSkill,
  EventParticipantStatus? eventStatus,
  Future<bool> Function()? onAcceptInvite,
  Future<bool> Function()? onDeclineInvite,
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
      eventSkill: eventSkill,
      eventStatus: eventStatus,
      onAcceptInvite: onAcceptInvite,
      onDeclineInvite: onDeclineInvite,
    ),
  );
}

class UserProfileDialog extends StatefulWidget {
  final String name;
  final String? profileImageUrl;
  final String? username;
  final String? email;
  final String? projectPermission;
  final List<String>? musicSkills;
  final String? eventSkill;
  final EventParticipantStatus? eventStatus;
  final Future<bool> Function()? onAcceptInvite;
  final Future<bool> Function()? onDeclineInvite;

  const UserProfileDialog({
    super.key,
    required this.name,
    this.profileImageUrl,
    this.username,
    this.email,
    this.projectPermission,
    this.musicSkills,
    this.eventSkill,
    this.eventStatus,
    this.onAcceptInvite,
    this.onDeclineInvite,
  });

  @override
  State<UserProfileDialog> createState() => _UserProfileDialogState();
}

class _UserProfileDialogState extends State<UserProfileDialog> {
  bool _isAccepting = false;
  bool _isDeclining = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = theme.textTheme.titleLarge?.color;
    final subtitleColor = theme.textTheme.bodyMedium?.color?.withValues(
      alpha: 0.74,
    );
    final hasImage =
        widget.profileImageUrl != null &&
        widget.profileImageUrl!.trim().isNotEmpty;
    final initial = widget.name.trim().isEmpty
        ? '?'
        : widget.name.trim()[0].toUpperCase();
    final normalizedUsername = _normalizedValue(widget.username);
    final normalizedEmail = _normalizedValue(widget.email);
    final normalizedPermission = _normalizedValue(widget.projectPermission);
    final normalizedEventSkill = _normalizedValue(widget.eventSkill);
    final normalizedSkills = (widget.musicSkills ?? const <String>[])
        .map((skill) => skill.trim())
        .where((skill) => skill.isNotEmpty)
        .toList();
    final infoColor = theme.textTheme.bodyLarge?.color;
    final eventStatus = widget.eventStatus;
    final showInviteActions =
        eventStatus == EventParticipantStatus.pending &&
        widget.onAcceptInvite != null &&
        widget.onDeclineInvite != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: AppCardSurface(
        radius: AppRadius.sheet,
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
                          color: isDark ? AppColors.primarySubtleDark : AppColors.primarySubtleLight,
                          child: hasImage
                              ? Image(
                                  image: appCachedImageProvider(
                                    widget.profileImageUrl,
                                  )!,
                                  fit: BoxFit.cover,
                                )
                              : Center(
                                  child: Text(
                                    initial,
                                    style: const TextStyle(
                                      color: AppColors.primaryBright,
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
                  widget.name,
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
                if (normalizedEventSkill != null) ...[
                  const SizedBox(height: 18),
                  _ProfileSectionTitle(label: 'Função neste evento'),
                  const SizedBox(height: 12),
                  _ProfileInfoPill(value: normalizedEventSkill),
                ],
                if (eventStatus != null) ...[
                  const SizedBox(height: 18),
                  _ProfileSectionTitle(label: 'Status do convite'),
                  const SizedBox(height: 12),
                  if (showInviteActions)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isBusy ? null : _handleDecline,
                            child: _isDeclining
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Recusar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: _isBusy ? null : _handleAccept,
                            child: _isAccepting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Aceitar'),
                          ),
                        ),
                      ],
                    )
                  else
                    _ProfileStatusPill(status: eventStatus),
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

  bool get _isBusy => _isAccepting || _isDeclining;

  Future<void> _handleAccept() async {
    final callback = widget.onAcceptInvite;
    if (callback == null) return;

    setState(() => _isAccepting = true);
    final success = await callback();
    if (!mounted) return;
    setState(() => _isAccepting = false);
    if (success) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleDecline() async {
    final callback = widget.onDeclineInvite;
    if (callback == null) return;

    setState(() => _isDeclining = true);
    final success = await callback();
    if (!mounted) return;
    setState(() => _isDeclining = false);
    if (success) {
      Navigator.of(context).pop();
    }
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
          color: isDark ? const Color(0xFF132033) : AppColors.primarySubtleLight,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isDark ? const Color(0xFF1E3A5F) : AppColors.primaryBorderLight,
          ),
        ),
        child: Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.primaryBright,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ProfileInfoPill extends StatelessWidget {
  final String value;

  const _ProfileInfoPill({required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceElevatedLight,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isDark ? AppColors.borderSubtleDark : const Color(0xFFD9DEE8),
          ),
        ),
        child: Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ProfileStatusPill extends StatelessWidget {
  final EventParticipantStatus status;

  const _ProfileStatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    late final Color backgroundColor;
    late final Color foregroundColor;

    switch (status) {
      case EventParticipantStatus.accepted:
        backgroundColor = isDark
            ? const Color(0xFF123227)
            : const Color(0xFFDCFCE7);
        foregroundColor = isDark
            ? const Color(0xFF86EFAC)
            : const Color(0xFF166534);
      case EventParticipantStatus.pending:
        backgroundColor = isDark
            ? const Color(0xFF3F2A13)
            : const Color(0xFFFEF3C7);
        foregroundColor = isDark
            ? const Color(0xFFFCD34D)
            : const Color(0xFF92400E);
      case EventParticipantStatus.declined:
        backgroundColor = isDark ? AppColors.dangerSubtleDark : AppColors.dangerSubtleLight;
        foregroundColor = isDark ? AppColors.dangerTextDark : AppColors.dangerTextLight;
      case EventParticipantStatus.unknown:
        backgroundColor = isDark ? AppColors.surfaceElevatedDark : AppColors.borderLight;
        foregroundColor = isDark ? AppColors.borderSubtleLight : AppColors.textSubtleDark;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          status.label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: foregroundColor,
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
              color: isDark ? AppColors.borderSubtleDark : const Color(0xFFD9DEE8),
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
                      color: isDark ? const Color(0xFF132033) : AppColors.primarySubtleLight,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? const Color(0xFF1E3A5F) : AppColors.primaryBorderLight,
                      ),
                    ),
                    child: Text(
                      skill,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.primaryBright,
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
