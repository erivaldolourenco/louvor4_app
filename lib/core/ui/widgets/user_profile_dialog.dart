import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:louvor4_app/features/events/domain/entities/event_participant_entity.dart';

import '../../theme/app_radius.dart';
import '../../utils/skill_icon.dart';
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
  String? eventSkillIconKey,
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
      eventSkillIconKey: eventSkillIconKey,
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
  final String? eventSkillIconKey;
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
    this.eventSkillIconKey,
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
    final cs = theme.colorScheme;
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
                          color: cs.primaryContainer,
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
                                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                      color: cs.primary,
                                      fontWeight: FontWeight.w700,
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
                        color: cs.shadow.withValues(alpha: 0.18),
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
                    fontWeight: FontWeight.w700,
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
                  _ProfileInfoPill(
                    value: normalizedEventSkill,
                    iconKey: widget.eventSkillIconKey,
                  ),
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
          fontWeight: FontWeight.w700,
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
    final cs = theme.colorScheme;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: cs.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ProfileInfoPill extends StatelessWidget {
  final String value;
  final String? iconKey;

  const _ProfileInfoPill({required this.value, this.iconKey});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: cs.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconKey != null) ...[
              SvgPicture.asset(
                skillIconAsset(iconKey),
                width: 16,
                height: 16,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
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
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    late final Color backgroundColor;
    late final Color foregroundColor;

    switch (status) {
      case EventParticipantStatus.accepted:
        backgroundColor = cs.primaryContainer;
        foregroundColor = cs.onPrimaryContainer;
      case EventParticipantStatus.pending:
        backgroundColor = cs.secondaryContainer;
        foregroundColor = cs.onSecondaryContainer;
      case EventParticipantStatus.declined:
        backgroundColor = cs.errorContainer;
        foregroundColor = cs.onErrorContainer;
      case EventParticipantStatus.unknown:
        backgroundColor = cs.surfaceContainer;
        foregroundColor = cs.onSurfaceVariant;
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
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
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
              color: cs.outlineVariant,
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
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: cs.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      skill,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
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
