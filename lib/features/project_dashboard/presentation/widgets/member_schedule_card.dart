import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/ui/widgets/app_cached_network_image.dart';
import '../../../../core/ui/widgets/app_card_surface.dart';
import '../../../../core/utils/skill_icon.dart';
import '../../../../core/utils/url_utils.dart';
import '../../domain/entities/project_statistics_entities.dart';
import 'dashboard_format.dart';

class MemberScheduleCard extends StatelessWidget {
  final MemberScheduleStatsEntity stats;

  /// Convites do mesmo membro no período, quando existirem.
  final InviteCountsEntity? invites;

  const MemberScheduleCard({super.key, required this.stats, this.invites});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final invites = this.invites;

    return AppCardSurface(
      radius: AppRadius.card,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(name: stats.fullName, imageUrl: stats.profileImage),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stats.fullName.isEmpty ? 'Membro' : stats.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (invites != null && invites.sent > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${invites.accepted} de ${invites.sent} convites aceitos'
                        ' · ${DashboardFormat.percent(invites.acceptanceRate)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${stats.total}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.primary,
                    ),
                  ),
                  Text(
                    stats.total == 1 ? 'escala' : 'escalas',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (stats.bySkill.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: stats.bySkill
                  .map((skill) => SkillCountChip(skill: skill))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class SkillCountChip extends StatelessWidget {
  final SkillCountEntity skill;
  final bool dense;

  const SkillCountChip({super.key, required this.skill, this.dense = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hasSkill = skill.skillId != null;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: dense ? 4 : 6),
      decoration: BoxDecoration(
        color: hasSkill ? cs.primaryContainer : cs.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: hasSkill ? null : Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (skill.skillIconKey != null) ...[
            SvgPicture.asset(
              skillIconAsset(skill.skillIconKey),
              width: 14,
              height: 14,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            skill.skillName,
            style: theme.textTheme.labelMedium?.copyWith(
              color: hasSkill ? cs.onPrimaryContainer : cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${skill.total}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: hasSkill ? cs.onPrimaryContainer : cs.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final String? imageUrl;

  const _Avatar({required this.name, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (UrlUtils.isValidNetworkUrl(imageUrl)) {
      return CircleAvatar(
        radius: 22,
        backgroundImage: appCachedImageProvider(imageUrl),
      );
    }
    return CircleAvatar(
      radius: 22,
      backgroundColor: cs.primaryContainer,
      child: Text(
        (name.trim().isEmpty ? '?' : name.trim()[0]).toUpperCase(),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: cs.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
