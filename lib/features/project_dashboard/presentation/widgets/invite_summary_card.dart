import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/ui/widgets/app_card_surface.dart';
import '../../domain/entities/project_statistics_entities.dart';
import 'dashboard_format.dart';

class InviteSummaryCard extends StatelessWidget {
  final InviteCountsEntity totals;

  const InviteSummaryCard({super.key, required this.totals});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return AppCardSurface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'Enviados',
                  value: totals.sent,
                  color: cs.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  label: 'Aceitos',
                  value: totals.accepted,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'Recusados',
                  value: totals.declined,
                  color: cs.error,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  label: 'Pendentes',
                  value: totals.pending,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Taxa de aceitação',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                DashboardFormat.percent(totals.acceptanceRate),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: totals.acceptanceRate.clamp(0, 1).toDouble(),
              minHeight: 8,
              color: AppColors.success,
              backgroundColor: cs.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$value',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
