import 'package:flutter/material.dart';
import 'package:louvor4_app/core/ui/widgets/app_cached_network_image.dart';
import 'package:louvor4_app/core/ui/widgets/app_card_surface.dart';
import 'package:louvor4_app/core/ui/widgets/spring_tap.dart';
import 'package:louvor4_app/features/events/domain/entities/event_participant_entity.dart';
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
    final cs = theme.colorScheme;
    final badge = _statusBadge(cs);

    final cardBody = SpringTap(
      onTap: onTap,
      pressedScale: 0.97,
      borderRadius: BorderRadius.circular(AppRadius.cardHero),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: cs.primaryContainer,
              backgroundImage: profileImage != null
                  ? appCachedImageProvider(profileImage)
                  : null,
              child: profileImage == null
                  ? Icon(Icons.person, color: cs.primary)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    skill,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
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
          ],
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: appCardDecoration(context, radius: AppRadius.cardHero),
        child: cardBody,
      ),
    );
  }

  _ParticipantStatusBadge _statusBadge(ColorScheme cs) {
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
          backgroundColor: cs.tertiaryContainer,
          foregroundColor: cs.onTertiaryContainer,
        );
      case EventParticipantStatus.declined:
        return _ParticipantStatusBadge(
          label: 'Recusado',
          backgroundColor: cs.errorContainer,
          foregroundColor: cs.onErrorContainer,
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
