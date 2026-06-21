import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:louvor4_app/core/ui/widgets/app_cached_network_image.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/utils/url_utils.dart';
import '../../data/impl/music_projects_repository_impl.dart';
import '../../domain/entities/music_project_entity.dart';
import '../cubit/project_cubit.dart';
import '../cubit/project_state.dart';
import '../pages/create_music_project_page.dart';
import '../utils/music_project_ui_utils.dart';

Future<MusicProjectEntity?> showProjectSelector(BuildContext context) async {
  final cubit = context.read<ProjectCubit>();
  final repository = MusicProjectsRepositoryImpl();

  cubit.loadProjects();

  return showModalBottomSheet<MusicProjectEntity>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.bottomSheet)),
    ),
    builder: (sheetContext) {
      return BlocProvider.value(
        value: cubit,
        child: SafeArea(
          child: BlocBuilder<ProjectCubit, ProjectState>(
            builder: (context, state) {
              final theme = Theme.of(context);
    final cs = theme.colorScheme;
              final subtitleColor = theme.textTheme.bodyMedium?.color
                  ?.withValues(alpha: 0.75);

              if (state.status == ProjectStatus.loading) {
                return const SizedBox(
                  height: 240,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (state.status == ProjectStatus.failure) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selecionar projeto',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(state.errorMessage ?? 'Erro ao carregar projetos.'),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () => cubit.loadProjects(force: true),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                );
              }

              final projects = state.projects;
              final activeId = state.activeProject?.id;

              return Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                      child: Row(
                        children: [
                          Text(
                            'Selecionar projeto',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    if (projects.isEmpty)
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: cs.primaryContainer,
                          child: Icon(
                            Icons.add_rounded,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        title: const Text('Adicionar Novo Projeto'),
                        onTap: () async {
                          final createdProject =
                              await openCreateMusicProjectPage(
                                context,
                                repository: repository,
                              );
                          if (createdProject == null || !context.mounted) {
                            return;
                          }

                          cubit.upsertProject(createdProject);
                          if (!sheetContext.mounted) return;
                          Navigator.of(sheetContext).pop(createdProject);
                        },
                      )
                    else
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ...projects.map((project) {
                                final isActive = activeId == project.id;
                                return AnimatedContainer(
                                  duration: Duration(milliseconds: 160),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? (cs.primaryContainer)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(AppRadius.input),
                                  ),
                                  child: ListTile(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppRadius.input),
                                    ),
                                    leading: CircleAvatar(
                                      backgroundColor: cs.primaryContainer,
                                      backgroundImage:
                                          UrlUtils.isValidNetworkUrl(
                                            project.profileImage,
                                          )
                                          ? appCachedImageProvider(
                                              project.profileImage,
                                            )
                                          : null,
                                      child:
                                          !UrlUtils.isValidNetworkUrl(
                                            project.profileImage,
                                          )
                                          ? Icon(
                                              Icons.multitrack_audio_rounded,
                                              color: cs.primary,
                                            )
                                          : null,
                                    ),
                                    title: Text(
                                      project.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      MusicProjectUiUtils.typeLabel(
                                        project.type,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: subtitleColor),
                                    ),
                                    trailing: isActive
                                        ? Icon(
                                            Icons.check_circle,
                                            color: theme.colorScheme.primary,
                                          )
                                        : null,
                                    onTap: () {
                                      cubit.selectProject(project);
                                      Navigator.of(sheetContext).pop(project);
                                    },
                                  ),
                                );
                              }),
                              Divider(height: 24),
                              ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: cs.primaryContainer,
                                  child: Icon(
                                    Icons.add_rounded,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                title: const Text('Adicionar Novo Projeto'),
                                onTap: () async {
                                  final createdProject =
                                      await openCreateMusicProjectPage(
                                        context,
                                        repository: repository,
                                      );
                                  if (createdProject == null ||
                                      !context.mounted) {
                                    return;
                                  }

                                  cubit.upsertProject(createdProject);
                                  if (!sheetContext.mounted) return;
                                  Navigator.of(
                                    sheetContext,
                                  ).pop(createdProject);
                                },
                              ),
                            ],
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
