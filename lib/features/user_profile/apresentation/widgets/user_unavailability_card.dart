import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:louvor4_app/core/ui/widgets/app_card_surface.dart';
import 'package:louvor4_app/features/music_projects/domain/entities/music_project_entity.dart';
import 'package:louvor4_app/features/user_profile/domain/entities/user_unavailability_entity.dart';

class UserUnavailabilityCard extends StatelessWidget {
  final UserUnavailabilityEntity item;
  final List<MusicProjectEntity> projects;
  final bool isDeleting;
  final VoidCallback onDelete;

  const UserUnavailabilityCard({
    super.key,
    required this.item,
    required this.projects,
    required this.isDeleting,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final period = _buildPeriodLabel();
    final mappedProjects = _resolveProjects();
    final subtitleColor = theme.brightness == Brightness.dark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return AppCardSurface(
      radius: 24,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.dark
                      ? const Color(0xFF172554)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.event_busy_rounded,
                  color: Color(0xFF0166FF),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      period,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: subtitleColor,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filledTonal(
                tooltip: 'Excluir indisponibilidade',
                onPressed: isDeleting ? null : onDelete,
                icon: isDeleting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: item.appliesToAllProjects
                ? const [
                    _ProjectChip(
                      label: 'Todos os projetos',
                      icon: Icons.public_rounded,
                      highlighted: true,
                    ),
                  ]
                : mappedProjects.isEmpty
                ? const [
                    _ProjectChip(
                      label: 'Projetos não encontrados',
                      icon: Icons.folder_off_rounded,
                    ),
                  ]
                : mappedProjects
                      .map(
                        (project) => _ProjectChip(
                          label: project.name,
                          icon: _iconForProjectType(project.type),
                        ),
                      )
                      .toList(growable: false),
          ),
        ],
      ),
    );
  }

  String _buildPeriodLabel() {
    final dateFormat = DateFormat('dd MMM yyyy', 'pt_BR');
    final start = DateTime(
      item.startDate.year,
      item.startDate.month,
      item.startDate.day,
    );
    final end = DateTime(
      item.endDate.year,
      item.endDate.month,
      item.endDate.day,
    );
    if (start == end) {
      return dateFormat.format(start);
    }
    return '${dateFormat.format(start)} até ${dateFormat.format(end)}';
  }

  List<MusicProjectEntity> _resolveProjects() {
    final byId = {for (final project in projects) project.id: project};
    return item.projectIds
        .map((projectId) => byId[projectId])
        .whereType<MusicProjectEntity>()
        .toList(growable: false);
  }

  static IconData _iconForProjectType(MusicProjectType type) {
    switch (type) {
      case MusicProjectType.band:
        return Icons.groups_rounded;
      case MusicProjectType.ministry:
        return Icons.auto_awesome_rounded;
      case MusicProjectType.singer:
        return Icons.mic_rounded;
      case MusicProjectType.unknown:
        return Icons.music_note_rounded;
    }
  }
}

class _ProjectChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool highlighted;

  const _ProjectChip({
    required this.label,
    required this.icon,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = highlighted
        ? const Color(0xFF0166FF)
        : isDark
        ? const Color(0xFF0F172A)
        : const Color(0xFFF8FBFF);
    final foregroundColor = highlighted
        ? Colors.white
        : isDark
        ? const Color(0xFFE2E8F0)
        : const Color(0xFF1E3A8A);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: highlighted
              ? const Color(0xFF0166FF)
              : isDark
              ? const Color(0xFF334155)
              : const Color(0xFFD6E4FF),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foregroundColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: foregroundColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
