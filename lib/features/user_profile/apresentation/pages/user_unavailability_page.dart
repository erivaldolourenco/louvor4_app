import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:louvor4_app/core/ui/app_feedback.dart';
import 'package:louvor4_app/core/ui/widgets/app_async_states.dart';
import 'package:louvor4_app/core/ui/widgets/primary_add_fab.dart';
import 'package:louvor4_app/core/ui/widgets/standard_section_app_bar.dart';
import 'package:louvor4_app/features/user_profile/apresentation/cubit/user_unavailability_cubit.dart';
import 'package:louvor4_app/features/user_profile/apresentation/cubit/user_unavailability_state.dart';
import 'package:louvor4_app/features/user_profile/apresentation/widgets/add_user_unavailability_sheet.dart';
import 'package:louvor4_app/features/user_profile/apresentation/widgets/user_unavailability_card.dart';
import 'package:louvor4_app/features/user_profile/data/impl/user_unavailability_repository_impl.dart';
import 'package:louvor4_app/features/user_profile/data/user_unavailability_repository.dart';
import 'package:louvor4_app/features/user_profile/domain/entities/user_unavailability_entity.dart';

class UserUnavailabilityPage extends StatelessWidget {
  static const routeName = '/indisponibilidades';

  const UserUnavailabilityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<UserUnavailabilityRepository>(
      create: (_) => UserUnavailabilityRepositoryImpl(),
      child: BlocProvider(
        create: (context) => UserUnavailabilityCubit(
          context.read<UserUnavailabilityRepository>(),
        )..load(),
        child: const _UserUnavailabilityView(),
      ),
    );
  }
}

class _UserUnavailabilityView extends StatelessWidget {
  const _UserUnavailabilityView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserUnavailabilityCubit, UserUnavailabilityState>(
      builder: (context, state) {
        final count = state.items.length;
        final subtitle = count == 1
            ? '1 período cadastrado'
            : '$count períodos cadastrados';

        return Scaffold(
          appBar: StandardSectionAppBar(
            title: 'Indisponibilidades',
            subtitle: subtitle,
          ),
          floatingActionButton: PrimaryAddFab(
            heroTag: 'user-unavailability-fab',
            onPressed: () => _openCreateSheet(context),
          ),
          body: SafeArea(
            child: Builder(
              builder: (context) {
                if (state.isInitialLoading) {
                  return const AppLoadingState();
                }

                if (state.status == UserUnavailabilityStatus.error) {
                  return AppErrorState(
                    message:
                        state.errorMessage ??
                        'Não foi possível carregar suas indisponibilidades.',
                    onRetry: () =>
                        context.read<UserUnavailabilityCubit>().load(),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () =>
                      context.read<UserUnavailabilityCubit>().load(),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    children: [
                      if (state.status == UserUnavailabilityStatus.empty)
                        const Padding(
                          padding: EdgeInsets.only(top: 56),
                          child: AppEmptyState(
                            icon: Icons.event_available_rounded,
                            title: 'Nenhum período cadastrado',
                            description:
                                'Quando surgir um compromisso, adicione aqui para manter seus projetos atualizados.',
                          ),
                        )
                      else
                        ...state.items.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: UserUnavailabilityCard(
                              item: item,
                              projects: state.projects,
                              isDeleting: state.isDeleting(item.id),
                              onDelete: () => _confirmDelete(context, item),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _openCreateSheet(BuildContext context) async {
    await showAddUserUnavailabilitySheet(context);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    UserUnavailabilityEntity item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir indisponibilidade?'),
        content: Text(
          'Esse período será removido da sua lista e deixará de bloquear sua participação relacionada.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final cubit = context.read<UserUnavailabilityCubit>();
    final success = await cubit.delete(item);
    if (!context.mounted) return;

    if (success) {
      AppFeedback.showSuccess('Indisponibilidade excluída com sucesso.');
      return;
    }

    AppFeedback.showError(
      cubit.state.actionErrorMessage ??
          'Não foi possível excluir a indisponibilidade.',
    );
  }
}
