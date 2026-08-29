import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/ui/app_feedback.dart';
import '../../../../core/ui/widgets/app_async_states.dart';
import '../../../../core/ui/widgets/standard_section_app_bar.dart';
import '../../data/repositories/notifications_repository_impl.dart';
import '../../domain/entities/notification_item_entity.dart';
import '../../domain/entities/notification_type.dart';
import '../cubit/notifications_cubit.dart';
import '../cubit/notifications_state.dart';
import '../widgets/notification_card.dart';

class AvisosPage extends StatelessWidget {
  static const routeName = '/avisos';

  const AvisosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AvisosView();
  }
}

class StandaloneAvisosPage extends StatelessWidget {
  const StandaloneAvisosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NotificationsCubit(NotificationsRepositoryImpl())..load(),
      child: const AvisosPage(),
    );
  }
}

class _AvisosView extends StatefulWidget {
  const _AvisosView();

  @override
  State<_AvisosView> createState() => _AvisosViewState();
}

class _AvisosViewState extends State<_AvisosView> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final threshold = _scrollController.position.maxScrollExtent - 160;
    if (_scrollController.position.pixels >= threshold) {
      context.read<NotificationsCubit>().loadMore();
    }
  }

  Future<void> _confirmAndDecline(NotificationItemEntity notification) async {
    final isProjectInvite =
        notification.type == NotificationType.projectMemberInvite;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Recusar convite'),
        content: Text(
          isProjectInvite
              ? 'Tem certeza que deseja recusar este convite para participar do projeto?'
              : 'Tem certeza que deseja recusar este convite para participar do evento?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Recusar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    context.read<NotificationsCubit>().declineInvite(notification);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NotificationsCubit, NotificationsState>(
      listenWhen: (previous, current) =>
          previous.actionStatus != current.actionStatus &&
          current.actionMessage != null,
      listener: (context, state) {
        if (state.actionStatus == NotificationsActionStatus.success) {
          AppFeedback.showSuccess(state.actionMessage!);
          return;
        }

        if (state.actionStatus == NotificationsActionStatus.failure) {
          AppFeedback.showError(state.actionMessage!);
        }
      },
      builder: (context, state) {
        final count = state.notifications.length;
        return Scaffold(
          appBar: StandardSectionAppBar(
            title: 'Avisos',
            subtitle: count == 1 ? '1 notificação' : '$count notificações',
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, NotificationsState state) {
    if (state.isInitialLoading) {
      return const AppLoadingState();
    }

    if (state.status == NotificationsStatus.failure &&
        state.notifications.isEmpty) {
      return AppErrorState(
        message: state.errorMessage ?? 'Não foi possível carregar os avisos.',
        onRetry: () => context.read<NotificationsCubit>().load(),
      );
    }

    if (state.isEmpty) {
      final iconColor = Theme.of(context).iconTheme.color;
      return RefreshIndicator(
        onRefresh: () => context.read<NotificationsCubit>().refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 28),
          children: [
            const SizedBox(height: 180),
            AppEmptyState(
              icon: Icons.notifications_none_rounded,
              iconWidget: SvgPicture.asset(
                'assets/icons/bell.svg',
                width: 56,
                height: 56,
                colorFilter: iconColor == null
                    ? null
                    : ColorFilter.mode(iconColor, BlendMode.srcIn),
              ),
              title: 'Nenhum aviso por enquanto',
              description:
                  'Quando houver novidades sobre eventos, projetos ou mensagens, elas aparecerão aqui.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<NotificationsCubit>().refresh(),
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: state.notifications.length + (state.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index >= state.notifications.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final notification = state.notifications[index];
          return NotificationCard(
            notification: notification,
            isAccepting: state.isAccepting(notification.id),
            isDeclining: state.isDeclining(notification.id),
            isDismissing: state.isDismissing(notification.id),
            onAccept: notification.canRespondToInvite
                ? () => context.read<NotificationsCubit>().acceptInvite(
                    notification,
                  )
                : null,
            onDecline: notification.canRespondToInvite
                ? () => _confirmAndDecline(notification)
                : null,
            onDismiss: notification.canRespondToInvite
                ? null
                : () => context.read<NotificationsCubit>().dismissNotification(
                    notification,
                  ),
          );
        },
      ),
    );
  }
}
