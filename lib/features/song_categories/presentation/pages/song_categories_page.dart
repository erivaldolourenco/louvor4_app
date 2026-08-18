import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/ui/app_feedback.dart';
import '../../../../core/ui/widgets/app_async_states.dart';
import '../../../../core/ui/widgets/app_card_surface.dart';
import '../../../../core/ui/widgets/circular_icon_action_button.dart';
import '../../../../core/ui/widgets/primary_add_fab.dart';
import '../../../../core/ui/widgets/standard_section_app_bar.dart';
import '../../data/impl/song_categories_repository_impl.dart';
import '../../data/song_categories_repository.dart';
import '../../domain/entities/song_category_entity.dart';
import '../cubit/song_categories_cubit.dart';
import '../cubit/song_categories_state.dart';
import '../widgets/song_category_form_sheet.dart';

class SongCategoriesPage extends StatelessWidget {
  static const routeName = '/song-categories';

  const SongCategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<SongCategoriesRepository>(
      create: (_) => SongCategoriesRepositoryImpl(),
      child: BlocProvider(
        create: (context) =>
            SongCategoriesCubit(context.read<SongCategoriesRepository>())
              ..load(),
        child: const _SongCategoriesView(),
      ),
    );
  }
}

class _SongCategoriesView extends StatelessWidget {
  const _SongCategoriesView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SongCategoriesCubit, SongCategoriesState>(
      builder: (context, state) {
        final cubit = context.read<SongCategoriesCubit>();
        final count = state.categories.length;
        final subtitle = count == 0
            ? 'Organize seu repertório por categoria'
            : count == 1
            ? '1 categoria cadastrada'
            : '$count categorias cadastradas';

        return Scaffold(
          appBar: StandardSectionAppBar(
            title: 'Categorias',
            subtitle: subtitle,
          ),
          floatingActionButton: PrimaryAddFab(
            heroTag: 'song-categories-fab',
            iconAsset: 'assets/icons/tag-plus.svg',
            onPressed: () => _openCreateSheet(context, cubit),
          ),
          body: SafeArea(
            child: Builder(
              builder: (context) {
                if (state.isInitialLoading) {
                  return const AppLoadingState();
                }

                if (state.status == SongCategoriesStatus.failure &&
                    state.categories.isEmpty) {
                  return AppErrorState(
                    message:
                        state.errorMessage ??
                        'Não foi possível carregar as categorias.',
                    onRetry: () => cubit.load(),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => cubit.load(silent: true),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    children: [
                      if (state.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 56),
                          child: AppEmptyState(
                            icon: Icons.sell_outlined,
                            iconWidget: SvgPicture.asset(
                              'assets/icons/tag.svg',
                              width: 56,
                              height: 56,
                              colorFilter: ColorFilter.mode(
                                Theme.of(context).iconTheme.color ??
                                    Theme.of(context).colorScheme.onSurfaceVariant,
                                BlendMode.srcIn,
                              ),
                            ),
                            title: 'Nenhuma categoria criada',
                            description:
                                'Crie categorias como Adoração ou Natal para organizar o seu repertório.',
                            action: FilledButton.icon(
                              onPressed: () =>
                                  _openCreateSheet(context, cubit),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Criar primeira categoria'),
                            ),
                          ),
                        )
                      else
                        ...state.categories.map(
                          (category) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _SongCategoryCard(category: category),
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

  Future<void> _openCreateSheet(
    BuildContext context,
    SongCategoriesCubit cubit,
  ) async {
    final success = await showSongCategoryFormSheet(context, cubit: cubit);
    if (success == true && context.mounted) {
      AppFeedback.showSuccess('Categoria criada com sucesso.');
    }
  }
}

class _SongCategoryCard extends StatelessWidget {
  final SongCategoryEntity category;

  const _SongCategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SongCategoriesCubit>();
    final state = context.watch<SongCategoriesCubit>().state;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final titleColor = theme.textTheme.titleMedium?.color;
    final isDeleting = state.isDeletingCategory(category.id);

    final decoration = appCardDecoration(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: decoration.borderRadius,
        boxShadow: decoration.boxShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: decoration.copyWith(boxShadow: const []),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/icons/tag.svg',
                      width: 24,
                      height: 24,
                      colorFilter: ColorFilter.mode(
                        cs.onPrimaryContainer,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    category.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                if (isDeleting)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else ...[
                  CircularIconActionButton(
                    tooltip: 'Editar categoria',
                    onPressed: () => _showEditSheet(context, cubit, category),
                    assetPath: 'assets/icons/square-pen.svg',
                    iconColor: cs.onPrimaryContainer,
                    backgroundColor: cs.primaryContainer,
                    borderColor: cs.primary.withValues(alpha: 0.3),
                  ),
                  const SizedBox(width: 6),
                  CircularIconActionButton(
                    tooltip: 'Excluir categoria',
                    onPressed: () => _onDelete(context, cubit, category),
                    assetPath: 'assets/icons/trash-2.svg',
                    iconColor: cs.onErrorContainer,
                    backgroundColor: cs.errorContainer,
                    borderColor: cs.error.withValues(alpha: 0.3),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showEditSheet(
    BuildContext context,
    SongCategoriesCubit cubit,
    SongCategoryEntity category,
  ) async {
    final success = await showSongCategoryFormSheet(
      context,
      cubit: cubit,
      category: category,
    );
    if (success == true && context.mounted) {
      AppFeedback.showSuccess('Categoria atualizada com sucesso.');
    }
  }

  Future<void> _onDelete(
    BuildContext context,
    SongCategoriesCubit cubit,
    SongCategoryEntity category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final cs = Theme.of(context).colorScheme;
        return AlertDialog(
          title: const Text('Excluir categoria'),
          content: Text(
            'Deseja excluir a categoria "${category.name}"? Essa ação não poderá ser desfeita.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(backgroundColor: cs.error),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    final deleted = await cubit.deleteCategory(category);
    if (!context.mounted) return;

    if (deleted) {
      AppFeedback.showSuccess('Categoria excluída com sucesso.');
    } else if (cubit.state.actionErrorMessage != null) {
      AppFeedback.showError(cubit.state.actionErrorMessage!);
    }
  }
}
