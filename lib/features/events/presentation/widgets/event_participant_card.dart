import 'package:flutter/material.dart';
import 'package:louvor4_app/core/ui/widgets/app_cached_network_image.dart';
import 'package:louvor4_app/core/ui/widgets/app_card_surface.dart';
import 'package:louvor4_app/features/events/domain/entities/event_participant_entity.dart';

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
                      ? const Color(0xFF172554)
                      : const Color(0xFFEFF6FF),
                  backgroundImage: profileImage != null
                      ? appCachedImageProvider(profileImage)
                      : null,
                  child: profileImage == null
                      ? const Icon(Icons.person, color: Color(0xFF0166FF))
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
                        style: TextStyle(color: subtitleColor, fontSize: 12),
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
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge.label,
                    style: TextStyle(
                      color: badge.foregroundColor,
                      fontSize: 11,
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
              ? const Color(0xFF123227)
              : const Color(0xFFDCFCE7),
          foregroundColor: isDark
              ? const Color(0xFF86EFAC)
              : const Color(0xFF166534),
        );
      case EventParticipantStatus.pending:
        return _ParticipantStatusBadge(
          label: 'Pendente',
          backgroundColor: isDark
              ? const Color(0xFF3F2A13)
              : const Color(0xFFFEF3C7),
          foregroundColor: isDark
              ? const Color(0xFFFCD34D)
              : const Color(0xFF92400E),
        );
      case EventParticipantStatus.declined:
        return _ParticipantStatusBadge(
          label: 'Recusado',
          backgroundColor: isDark
              ? const Color(0xFF3F1114)
              : const Color(0xFFFEE2E2),
          foregroundColor: isDark
              ? const Color(0xFFFCA5A5)
              : const Color(0xFF991B1B),
        );
      case EventParticipantStatus.unknown:
        return _ParticipantStatusBadge(
          label: 'Sem status',
          backgroundColor: isDark
              ? const Color(0xFF1E293B)
              : const Color(0xFFE2E8F0),
          foregroundColor: isDark
              ? const Color(0xFFCBD5E1)
              : const Color(0xFF475569),
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
