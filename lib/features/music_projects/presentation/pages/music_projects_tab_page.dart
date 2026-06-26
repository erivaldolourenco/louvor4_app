import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/ui/app_feedback.dart';
import '../cubit/project_cubit.dart';
import '../cubit/project_state.dart';
import '../widgets/project_selector_bottom_sheet.dart';
import 'music_project_overview_page.dart';

class MusicProjectsTabPage extends StatelessWidget {
  final VoidCallback? onGoHome;

  const MusicProjectsTabPage({super.key, this.onGoHome});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectCubit, ProjectState>(
      builder: (context, state) {
        final activeProject = state.activeProject;

        if (activeProject == null) {
          return _EmptyProjectSelection(
            onOpenSelector: () => showProjectSelector(context),
          );
        }

        return MusicProjectOverviewPage(
          key: ValueKey(activeProject.id),
          projectId: activeProject.id,
          embedded: true,
          onLeaveProject: () {
            AppFeedback.showSuccess('Você saiu do projeto com sucesso.');
            context.read<ProjectCubit>().loadProjects(force: true);
            onGoHome?.call();
          },
          onDeleteProject: () {
            context.read<ProjectCubit>().loadProjects(force: true);
            onGoHome?.call();
          },
        );
      },
    );
  }
}

class _EmptyProjectSelection extends StatelessWidget {
  final VoidCallback onOpenSelector;

  const _EmptyProjectSelection({required this.onOpenSelector});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final subtitleColor = theme.textTheme.bodyMedium?.color?.withValues(
      alpha: 0.78,
    );

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.folder_open_rounded,
                size: 54,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(height: 10),
              Text(
                'Selecione um projeto',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Escolha um projeto para visualizar eventos, membros e funções.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: subtitleColor),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: onOpenSelector,
                icon: const Icon(Icons.swap_horiz_rounded),
                label: const Text('Selecionar Projeto'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
