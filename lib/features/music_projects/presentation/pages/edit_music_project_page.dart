import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/ui/widgets/app_cached_network_image.dart';
import '../../../../core/ui/widgets/app_form_sheet.dart';
import '../../../../core/ui/widgets/standard_section_app_bar.dart';
import '../../data/music_projects_repository.dart';
import '../../domain/entities/music_project_entity.dart';
import '../../domain/entities/update_music_project_input.dart';
import '../cubit/edit_music_project_cubit.dart';

Future<bool?> openEditMusicProjectPage(
  BuildContext context, {
  required String projectId,
  required MusicProjectsRepository repository,
}) {
  return Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) =>
          EditMusicProjectPage(projectId: projectId, repository: repository),
    ),
  );
}

class EditMusicProjectPage extends StatelessWidget {
  final String projectId;
  final MusicProjectsRepository repository;

  const EditMusicProjectPage({
    super.key,
    required this.projectId,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return BlocProvider(
      create: (_) => EditMusicProjectCubit(repository)..loadProject(projectId),
      child: const _EditMusicProjectView(),
    );
  }
}

class _EditMusicProjectView extends StatefulWidget {
  const _EditMusicProjectView();

  @override
  State<_EditMusicProjectView> createState() => _EditMusicProjectViewState();
}

class _EditMusicProjectViewState extends State<_EditMusicProjectView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _picker = ImagePicker();
  MusicProjectType? _selectedType;
  XFile? _selectedImage;
  bool _didFillControllers = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cubit = context.read<EditMusicProjectCubit>();
    final state = context.watch<EditMusicProjectCubit>().state;
    final project = state.project;

    if (project != null && !_didFillControllers) {
      _nameController.text = project.name;
      _selectedType = project.type == MusicProjectType.unknown
          ? MusicProjectType.ministry
          : project.type;
      _didFillControllers = true;
    }

    return Scaffold(
      appBar: const StandardSectionAppBar(
        title: 'Editar Projeto',
        subtitle: 'Atualize o nome e o tipo do projeto musical',
      ),
      body: state.isLoadingProject
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ProjectImageCard(
                        project: project,
                        selectedImage: _selectedImage,
                        isBusy: state.isSubmitting,
                        onTap: _pickImage,
                      ),
                      const SizedBox(height: 18),
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
                          if ((value ?? '').trim().isEmpty) {
                            return 'Informe o nome do projeto.';
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
                            child: Text('Cantor(a)'),
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
                          if (value == null) {
                            return 'Selecione o tipo do projeto.';
                          }
                          return null;
                        },
                      ),
                      if (state.errorMessage != null) ...[
                        const SizedBox(height: 12),
                        _InlineErrorMessage(message: state.errorMessage!),
                      ],
                      const SizedBox(height: 22),
                      FilledButton(
                        style: appPrimaryPillButtonStyle(context),
                        onPressed: state.isSubmitting || project == null
                            ? null
                            : () => _submit(cubit, project.id),
                        child: state.isSubmitting
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: cs.onPrimary,
                                ),
                              )
                            : const Text('Salvar alterações'),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        style: appSecondaryPillButtonStyle(context),
                        onPressed: state.isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(false),
                        child: const Text('Cancelar'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Future<void> _submit(EditMusicProjectCubit cubit, String projectId) async {
    if (!_formKey.currentState!.validate() || _selectedType == null) return;

    final updated = await cubit.submitWithOptionalImage(
      input: UpdateMusicProjectInput(
        id: projectId,
        name: _nameController.text.trim(),
        type: _selectedType!,
      ),
      imagePath: _selectedImage?.path,
      imageName: _selectedImage?.name,
    );

    if (!mounted || updated == null) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );

    if (!mounted || image == null) return;
    setState(() => _selectedImage = image);
  }
}

class _ProjectImageCard extends StatelessWidget {
  final MusicProjectEntity? project;
  final XFile? selectedImage;
  final bool isBusy;
  final VoidCallback onTap;

  const _ProjectImageCard({
    required this.project,
    required this.selectedImage,
    required this.isBusy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? cs.outline : cs.outlineVariant;
    final subtitleColor = Theme.of(
      context,
    ).textTheme.bodySmall?.color?.withValues(alpha: 0.78);
    final imageUrl = project?.profileImage?.trim();
    final hasNetworkImage = imageUrl != null && imageUrl.isNotEmpty;
    final hasLocalImage = selectedImage != null;
    final initials = _buildInitials(project?.name ?? 'Projeto');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.bottomSheet),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: isBusy ? null : onTap,
            borderRadius: BorderRadius.circular(999),
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  foregroundImage: hasLocalImage
                      ? FileImage(File(selectedImage!.path))
                      : hasNetworkImage
                      ? appCachedImageProvider(imageUrl)
                      : null,
                  backgroundColor: isDark
                      ? cs.primaryContainer
                      : cs.primaryContainer,
                  child: !hasLocalImage && !hasNetworkImage
                      ? Text(
                          initials,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cs.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: cs.surface, width: 2),
                    ),
                    child: isBusy
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: cs.onPrimary,
                            ),
                          )
                        : Icon(
                            Icons.camera_alt_rounded,
                            size: 16,
                            color: cs.onPrimary,
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toque na imagem para alterar',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: subtitleColor),
          ),
        ],
      ),
    );
  }

  String _buildInitials(String value) {
    final parts = value.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty);
    if (parts.isEmpty) return 'P';
    final chars = parts.take(2).map((e) => e[0].toUpperCase()).join();
    return chars.isEmpty ? 'P' : chars;
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
      ),
    );
  }
}

class _InlineErrorMessage extends StatelessWidget {
  final String message;

  const _InlineErrorMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? cs.errorContainer : cs.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(
          color: cs.error.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: cs.error,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
