import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/ui/app_feedback.dart';
import '../../../../core/ui/widgets/app_form_sheet.dart';
import '../../../../core/ui/widgets/standard_section_app_bar.dart';
import '../../data/music_projects_repository.dart';
import '../../domain/entities/create_music_project_input.dart';
import '../../domain/entities/music_project_entity.dart';
import '../cubit/create_music_project_cubit.dart';
import '../cubit/create_music_project_state.dart';

Future<MusicProjectEntity?> openCreateMusicProjectPage(
  BuildContext context, {
  required MusicProjectsRepository repository,
}) {
  return Navigator.of(context).push<MusicProjectEntity>(
    MaterialPageRoute(
      builder: (_) => CreateMusicProjectPage(repository: repository),
    ),
  );
}

class CreateMusicProjectPage extends StatelessWidget {
  final MusicProjectsRepository repository;

  const CreateMusicProjectPage({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CreateMusicProjectCubit(repository),
      child: const _CreateMusicProjectView(),
    );
  }
}

class _CreateMusicProjectView extends StatefulWidget {
  const _CreateMusicProjectView();

  @override
  State<_CreateMusicProjectView> createState() =>
      _CreateMusicProjectViewState();
}

class _CreateMusicProjectViewState extends State<_CreateMusicProjectView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  MusicProjectType? _selectedType;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CreateMusicProjectCubit>().state;
    final cubit = context.read<CreateMusicProjectCubit>();

    return Scaffold(
      appBar: const StandardSectionAppBar(
        title: 'Criar Projeto',
        subtitle: 'Defina o nome e o tipo do seu projeto musical',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _FieldLabel(label: 'Nome do projeto'),
                TextFormField(
                  controller: _nameController,
                  enabled: !state.isSubmitting,
                  decoration: appFormFieldDecoration(
                    context,
                    hintText: 'Ex: Louvor Sede',
                    prefixIcon: Icons.music_note_rounded,
                  ),
                  validator: (value) {
                    final text = (value ?? '').trim();
                    if (text.isEmpty) return 'Informe o nome do projeto.';
                    if (text.length < 2) {
                      return 'O nome deve ter no mínimo 2 caracteres.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                const _FieldLabel(label: 'Tipo'),
                DropdownButtonFormField<MusicProjectType>(
                  initialValue: _selectedType,
                  items: const [
                    DropdownMenuItem(
                      value: MusicProjectType.band,
                      child: Text('Banda'),
                    ),
                    DropdownMenuItem(
                      value: MusicProjectType.ministry,
                      child: Text('Ministério'),
                    ),
                    DropdownMenuItem(
                      value: MusicProjectType.singer,
                      child: Text('Cantor'),
                    ),
                  ],
                  onChanged: state.isSubmitting
                      ? null
                      : (value) => setState(() => _selectedType = value),
                  decoration: appFormFieldDecoration(
                    context,
                    hintText: 'Selecione o tipo',
                    prefixIcon: Icons.category_outlined,
                  ),
                  validator: (value) {
                    if (value == null) return 'Selecione o tipo do projeto.';
                    return null;
                  },
                ),
                const SizedBox(height: 22),
                FilledButton(
                  style: appPrimaryPillButtonStyle(context),
                  onPressed: state.isSubmitting ? null : () => _submit(cubit),
                  child: state.isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Criar projeto'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  style: appSecondaryPillButtonStyle(context),
                  onPressed: state.isSubmitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Pular'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit(CreateMusicProjectCubit cubit) async {
    if (!_formKey.currentState!.validate() || _selectedType == null) return;

    final project = await cubit.submit(
      CreateMusicProjectInput(
        name: _nameController.text.trim(),
        type: _selectedType!,
      ),
    );

    if (!mounted || project == null) {
      final state = cubit.state;
      if (state.status == CreateMusicProjectStatus.error) {
        if (state.errorStatusCode == 409 &&
            (state.errorMessage?.trim().isNotEmpty ?? false)) {
          AppFeedback.showInfo(state.errorMessage!);
        } else {
          AppFeedback.showError('Não foi possível criar o projeto.');
        }
      }
      return;
    }

    Navigator.of(context).pop(project);
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
      ),
    );
  }
}
