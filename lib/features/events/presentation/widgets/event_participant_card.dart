import 'package:flutter/material.dart';
import 'package:louvor4_app/core/ui/widgets/app_cached_network_image.dart';
import 'package:louvor4_app/features/events/domain/entities/event_participant_entity.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';

class EventParticipantCard extends StatelessWidget {
  final String name;
  final String skill;
  final EventParticipantStatus status;
  final String? profileImage;
  final VoidCallback? onTap;
  final bool showDivider;

  const EventParticipantCard({
    super.key,
    required this.name,
    required this.skill,
    required this.status,
    this.profileImage,
    this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final badge = _statusBadge(cs, theme.brightness == Brightness.dark);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: CircleAvatar(
            backgroundColor: cs.primaryContainer,
            backgroundImage: profileImage != null
                ? appCachedImageProvider(profileImage)
                : null,
            child: profileImage == null
                ? Icon(Icons.person, color: cs.primary)
                : null,
          ),
          title: Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(skill, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: badge.backgroundColor,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              badge.label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: badge.foregroundColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 72,
            endIndent: 16,
            color: cs.outlineVariant.withValues(alpha: 0.5),
          ),
      ],
    );
  }

  _ParticipantStatusBadge _statusBadge(ColorScheme cs, bool isDark) {
    switch (status) {
      case EventParticipantStatus.accepted:
        return _ParticipantStatusBadge(
          label: 'Aceito',
          backgroundColor: cs.primaryContainer,
          foregroundColor: cs.onPrimaryContainer,
        );
      case EventParticipantStatus.pending:
        return _ParticipantStatusBadge(
          label: 'Pendente',
          backgroundColor: isDark
              ? AppColors.warningSubtleDark
              : AppColors.warningSubtleLight,
          foregroundColor: isDark
              ? AppColors.warningTextDark
              : AppColors.warningTextLight,
        );
      case EventParticipantStatus.declined:
        return _ParticipantStatusBadge(
          label: 'Recusado',
          backgroundColor: isDark
              ? AppColors.dangerSubtleDark
              : AppColors.dangerSubtleLight,
          foregroundColor: isDark
              ? AppColors.dangerTextDark
              : AppColors.dangerTextLight,
        );
      case EventParticipantStatus.unknown:
        return _ParticipantStatusBadge(
          label: 'Sem status',
          backgroundColor: cs.surfaceContainer,
          foregroundColor: cs.onSurfaceVariant,
        );
    }
  }
}

class _ParticipantStatusBadge {
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  const _ParticipantStatusBadge({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });
}
