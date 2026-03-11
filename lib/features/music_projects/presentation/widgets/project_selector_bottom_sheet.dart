import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/ui/app_feedback.dart';
import '../../../../core/utils/url_utils.dart';
import '../../domain/entities/music_project_entity.dart';
import '../cubit/project_cubit.dart';
import '../cubit/project_state.dart';
import '../utils/music_project_ui_utils.dart';

Future<MusicProjectEntity?> showProjectSelector(BuildContext context) async {
  final cubit = context.read<ProjectCubit>();

  if (cubit.state.status == ProjectStatus.initial) {
    cubit.loadProjects();
  }

  return showModalBottomSheet<MusicProjectEntity>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return BlocProvider.value(
        value: cubit,
        child: SafeArea(
          child: BlocBuilder<ProjectCubit, ProjectState>(
            builder: (context, state) {
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
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFEFF6FF),
                          child: Icon(
                            Icons.add_rounded,
                            color: Color(0xFF0166FF),
                          ),
                        ),
                        title: const Text('Adicionar Novo Projeto'),
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          AppFeedback.showSuccess(
                            'Criação de projeto será implementada em breve.',
                          );
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
                                  duration: const Duration(milliseconds: 160),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? const Color(0xFFEFF6FF)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    leading: CircleAvatar(
                                      backgroundColor: const Color(0xFFEFF6FF),
                                      backgroundImage:
                                          UrlUtils.isValidNetworkUrl(
                                            project.profileImage,
                                          )
                                          ? NetworkImage(project.profileImage!)
                                          : null,
                                      child:
                                          !UrlUtils.isValidNetworkUrl(
                                            project.profileImage,
                                          )
                                          ? const Icon(
                                              Icons.multitrack_audio_rounded,
                                              color: Color(0xFF0166FF),
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
                                    ),
                                    trailing: isActive
                                        ? const Icon(
                                            Icons.check_circle,
                                            color: Color(0xFF0166FF),
                                          )
                                        : null,
                                    onTap: () {
                                      cubit.selectProject(project);
                                      Navigator.of(sheetContext).pop(project);
                                    },
                                  ),
                                );
                              }),
                              const Divider(height: 24),
                              ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Color(0xFFEFF6FF),
                                  child: Icon(
                                    Icons.add_rounded,
                                    color: Color(0xFF0166FF),
                                  ),
                                ),
                                title: const Text('Adicionar Novo Projeto'),
                                onTap: () {
                                  Navigator.of(sheetContext).pop();
                                  AppFeedback.showSuccess(
                                    'Criação de projeto será implementada em breve.',
                                  );
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
