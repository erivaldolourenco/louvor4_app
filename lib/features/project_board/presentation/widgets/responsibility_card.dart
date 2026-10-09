import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/ui/widgets/app_cached_network_image.dart';
import '../../../../core/ui/widgets/app_card_surface.dart';
import '../../../../core/ui/widgets/spring_tap.dart';
import '../../domain/entities/responsibility_entity.dart';
import 'responsibility_dates.dart';

/// Card retangular de uma responsabilidade, exibido no carrossel horizontal
/// do Mural. Tem largura fixa; a altura vem do carrossel
/// ([ResponsibilityCard.height]).
class ResponsibilityCard extends StatelessWidget {
  static const double width = 172;
  static const double height = 212;

  final ResponsibilityEntity responsibility;
  final String? currentUserId;
  final bool canManage;
  final bool isDeleting;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ResponsibilityCard({
    super.key,
    required this.responsibility,
    required this.currentUserId,
    required this.canManage,
    required this.onTap,
    this.isDeleting = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final current = responsibility.current;
    final next = responsibility.next;
    final last = responsibility.last;
    final isMine =
        current != null &&
        currentUserId != null &&
        current.userId == currentUserId;
    final avatarImage = appCachedImageProvider(current?.profileImage);

    final String? secondaryLine;
    if (next != null) {
      final isMyNext = currentUserId != null && next.userId == currentUserId;
      secondaryLine =
          'Próximo: ${isMyNext ? 'você' : next.firstName} (a partir de ${formatShortDate(next.startDate)})';
    } else if (current == null && last != null) {
      secondaryLine =
          'Último: ${last.firstName} até ${formatShortDate(last.endDate)}';
    } else {
      secondaryLine = null;
    }

    return SizedBox(
      width: ResponsibilityCard.width,
      child: DecoratedBox(
        decoration: appCardDecoration(
          context,
          radius: AppRadius.cardLarge,
          borderColor: isMine ? cs.primary.withValues(alpha: 0.55) : null,
        ),
        child: SpringTap(
          onTap: isDeleting ? null : onTap,
          pressedScale: 0.97,
          borderRadius: BorderRadius.circular(AppRadius.cardLarge),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 4, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: current == null
                          ? cs.surfaceContainerHigh
                          : cs.primaryContainer,
                      backgroundImage: avatarImage,
                      child: avatarImage == null
                          ? Icon(
                              current == null
                                  ? Icons.person_search_rounded
                                  : Icons.person_rounded,
                              color: current == null
                                  ? cs.onSurfaceVariant
                                  : cs.onPrimaryContainer,
                            )
                          : null,
                    ),
                    const Spacer(),
                    _trailing(cs),
                  ],
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Text(
                    responsibility.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (current == null)
                        Text(
                          'Sem responsável',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      else ...[
                        if (isMine)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: cs.primaryContainer,
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                            child: Text(
                              'Você',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: cs.onPrimaryContainer,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        else
                          Text(
                            current.accountDeleted
                                ? 'Conta excluída'
                                : current.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        const SizedBox(height: 2),
                        Text(
                          isMine
                              ? 'até ${formatShortDate(current.endDate)}'
                              : formatPeriod(
                                  current.startDate,
                                  current.endDate,
                                ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (secondaryLine != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          secondaryLine,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _trailing(ColorScheme cs) {
    if (isDeleting) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (!canManage) return const SizedBox.shrink();
    return PopupMenuButton<String>(
      tooltip: 'Ações',
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      icon: Icon(Icons.more_vert_rounded, color: cs.onSurfaceVariant),
      onSelected: (value) {
        if (value == 'edit') onEdit?.call();
        if (value == 'delete') onDelete?.call();
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit_outlined),
            title: Text('Editar'),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete_outline, color: cs.error),
            title: Text('Excluir', style: TextStyle(color: cs.error)),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}
