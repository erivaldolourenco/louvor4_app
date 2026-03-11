import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/project_cubit.dart';
import '../cubit/project_state.dart';
import '../widgets/project_selector_bottom_sheet.dart';
import 'music_project_overview_page.dart';

class MusicProjectsTabPage extends StatelessWidget {
  const MusicProjectsTabPage({super.key});

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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.folder_open_rounded,
                size: 54,
                color: Color(0xFF94A3B8),
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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF64748B),
                ),
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
