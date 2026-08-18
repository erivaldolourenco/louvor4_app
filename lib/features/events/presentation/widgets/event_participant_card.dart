import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:louvor4_app/core/ui/widgets/app_cached_network_image.dart';
import 'package:louvor4_app/core/ui/widgets/app_card_surface.dart';
import 'package:louvor4_app/core/ui/widgets/spring_tap.dart';
import 'package:louvor4_app/core/utils/skill_icon.dart';
import 'package:louvor4_app/features/events/domain/entities/event_participant_entity.dart';
import '../../../../../core/theme/app_extra_colors.dart';
import '../../../../../core/theme/app_radius.dart';

class EventParticipantCard extends StatelessWidget {
  final String name;
  final String skill;
  final String? skillIconKey;
  final EventParticipantStatus status;
  final String? profileImage;
  final bool canAddSong;
  final VoidCallback? onTap;

  const EventParticipantCard({
    super.key,
    required this.name,
    required this.skill,
    this.skillIconKey,
    required this.status,
    this.profileImage,
    this.canAddSong = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final extraColors = theme.extension<AppExtraColors>()!;
    final badge = _statusBadge(cs);
    final cardBorderColor = cs.outlineVariant.withValues(
      alpha: isDark ? 0.35 : 0.55,
    );

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
            if (skillIconKey != null) ...[
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: cardBorderColor),
                ),
                child: CircleAvatar(
                  backgroundColor: extraColors.iconBadgeSurface,
                  child: SvgPicture.asset(
                    skillIconAsset(skillIconKey),
                    width: 22,
                    height: 22,
                  ),
                ),
              ),
            ],
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
                  if (skill.isNotEmpty || canAddSong) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (skill.isNotEmpty)
                          _ParticipantTag(
                            label: skill,
                            backgroundColor: cs.surfaceContainer,
                            foregroundColor: cs.onSurfaceVariant,
                          ),
                        if (canAddSong)
                          _ParticipantTag(
                            label: 'Música',
                            iconAsset: 'assets/icons/circle-plus.svg',
                            backgroundColor: cs.secondaryContainer,
                            foregroundColor: cs.onSecondaryContainer,
                          ),
                      ],
                    ),
                  ],
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

class _ParticipantTag extends StatelessWidget {
  final String label;
  final String? iconAsset;
  final Color backgroundColor;
  final Color foregroundColor;

  const _ParticipantTag({
    required this.label,
    this.iconAsset,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconAsset != null) ...[
            SvgPicture.asset(
              iconAsset!,
              width: 12,
              height: 12,
              colorFilter: ColorFilter.mode(foregroundColor, BlendMode.srcIn),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
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
