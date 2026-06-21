import 'package:flutter/material.dart';
import 'package:louvor4_app/core/ui/widgets/app_cached_network_image.dart';
import 'package:louvor4_app/core/ui/widgets/app_card_surface.dart';
import 'package:louvor4_app/features/events/domain/entities/event_participant_entity.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';

class EventParticipantCard extends StatelessWidget {
  final String name;
  final String skill;
  final EventParticipantStatus status;
  final String? profileImage;
  final VoidCallback? onTap;

  const EventParticipantCard({
    super.key,
    required this.name,
    required this.skill,
    required this.status,
    this.profileImage,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = theme.textTheme.titleMedium?.color;
    final subtitleColor = theme.textTheme.bodySmall?.color?.withValues(
      alpha: 0.78,
    );
    final badge = _statusBadge(theme);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: AppCardSurface(
            radius: 15,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: isDark
                      ? AppColors.primarySubtleDark
                      : AppColors.primarySubtleLight,
                  backgroundImage: profileImage != null
                      ? appCachedImageProvider(profileImage)
                      : null,
                  child: profileImage == null
                      ? const Icon(Icons.person, color: AppColors.primary)
                      : null,
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                        ),
                      ),
                      Text(
                        skill,
                        style: theme.textTheme.bodySmall?.copyWith(color: subtitleColor),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  _ParticipantStatusBadge _statusBadge(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    switch (status) {
      case EventParticipantStatus.accepted:
        return _ParticipantStatusBadge(
          label: 'Aceito',
          backgroundColor: isDark
              ? AppColors.successSubtleDark
              : const Color(0xFFDCFCE7),
          foregroundColor: isDark
              ? const Color(0xFF86EFAC)
              : const Color(0xFF166534),
        );
      case EventParticipantStatus.pending:
        return _ParticipantStatusBadge(
          label: 'Pendente',
          backgroundColor: isDark
              ? AppColors.warningSubtleDark
              : const Color(0xFFFEF3C7),
          foregroundColor: isDark
              ? const Color(0xFFFCD34D)
              : const Color(0xFF92400E),
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
          backgroundColor: isDark
              ? AppColors.surfaceElevatedDark
              : AppColors.borderLight,
          foregroundColor: isDark
              ? AppColors.borderSubtleLight
              : AppColors.textSubtleDark,
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
