import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/ui/widgets/app_buttons.dart';
import '../../../../core/ui/widgets/app_card_surface.dart';
import '../../domain/entities/notification_item_entity.dart';

class NotificationCard extends StatelessWidget {
  final NotificationItemEntity notification;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onDismiss;
  final bool isAccepting;
  final bool isDeclining;
  final bool isDismissing;

  const NotificationCard({
    super.key,
    required this.notification,
    this.onAccept,
    this.onDecline,
    this.onDismiss,
    this.isAccepting = false,
    this.isDeclining = false,
    this.isDismissing = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hasActions = notification.canRespondToInvite;
    final canDismiss = !notification.canRespondToInvite && onDismiss != null;
    final isBusy = isAccepting || isDeclining || isDismissing;
    final subtitleColor = theme.textTheme.bodyMedium?.color?.withValues(
      alpha: 0.78,
    );
    final highlightColor = notification.isRead
        ? cs.surface
        : cs.primaryContainer.withValues(alpha: 0.22);
    final badgeColor = notification.isRead ? cs.onSurfaceVariant : cs.primary;

    return AppCardSurface(
      radius: AppRadius.cardLarge,
      color: highlightColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    notification.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (!notification.isRead)
                  Padding(
                    padding: EdgeInsets.only(top: canDismiss ? 12 : 4),
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: badgeColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                if (canDismiss)
                  IconButton(
                    tooltip: 'Fechar notificação',
                    onPressed: isBusy ? null : onDismiss,
                    icon: isDismissing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.close_rounded),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              notification.message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: subtitleColor,
                height: 1.35,
              ),
            ),
            SizedBox(height: 10),
            Text(
              _formatDateTime(notification.createdAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (hasActions) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: AppSecondaryButton(
                      onPressed: isBusy ? null : onDecline,
                      height: 44,
                      child: isDeclining
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Recusar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppPrimaryButton(
                      onPressed: isBusy ? null : onAccept,
                      height: 44,
                      child: isAccepting
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: cs.onPrimary,
                              ),
                            )
                          : const Text('Aceitar'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime value) {
    return DateFormat("dd/MM/yyyy 'às' HH:mm", 'pt_BR').format(value.toLocal());
  }
}
