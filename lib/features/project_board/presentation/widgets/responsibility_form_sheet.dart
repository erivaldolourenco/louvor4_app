import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/ui/app_feedback.dart';
import '../../../../core/ui/widgets/app_buttons.dart';
import '../../../../core/ui/widgets/app_form_sheet.dart';
import '../../../../core/ui/widgets/app_inline_error_message.dart';
import '../../domain/entities/responsibility_entity.dart';
import '../cubit/project_board_cubit.dart';

/// Cria ou edita o nome/descrição de uma responsabilidade.
/// Retorna a responsabilidade salva (ou `null` se cancelado).
Future<ResponsibilityEntity?> showResponsibilityFormSheet(
  BuildContext context, {
  required ProjectBoardCubit cubit,
  ResponsibilityEntity? responsibility,
}) {
  return showModalBottomSheet<ResponsibilityEntity>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.bottomSheet),
      ),
    ),
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: ResponsibilityFormSheet(responsibility: responsibility),
    ),
  );
}

class ResponsibilityFormSheet extends StatefulWidget {
  final ResponsibilityEntity? responsibility;

  const ResponsibilityFormSheet({super.key, this.responsibility});

  @override
  State<ResponsibilityFormSheet> createState() =>
      _ResponsibilityFormSheetState();
}

class _ResponsibilityFormSheetState extends State<ResponsibilityFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  bool get _isEditing => widget.responsibility != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.responsibility?.name ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.responsibility?.description ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit(ProjectBoardCubit cubit) async {
    if (!_formKey.currentState!.validate()) return;

    final saved = await cubit.save(
      existing: widget.responsibility,
      name: _nameController.text,
      description: _descriptionController.text,
    );

    if (!mounted) return;
    if (saved != null) {
      Navigator.of(context).pop(saved);
    } else if (cubit.state.actionErrorMessage != null) {
      AppFeedback.showError(cubit.state.actionErrorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cubit = context.read<ProjectBoardCubit>();
    final state = context.watch<ProjectBoardCubit>().state;
    final isSaving = state.isSaving;

    return AppFormSheet(
      title: _isEditing ? 'Editar responsabilidade' : 'Nova responsabilidade',
      subtitle: _isEditing
          ? 'Altere o nome e a descrição desta responsabilidade.'
          : 'Ex.: Direção musical, Som, Mídia. Depois de criar, você define quem vai cuidar dela.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameController,
              enabled: !isSaving,
              autofocus: !_isEditing,
              maxLength: ProjectBoardCubit.maxNameLength,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nome',
                hintText: 'Ex: Direção musical',
                prefixIcon: Icon(Icons.assignment_ind_outlined),
              ),
              validator: (value) {
                final text = (value ?? '').trim();
                if (text.isEmpty) return 'Informe o nome da responsabilidade.';
                if (text.length > ProjectBoardCubit.maxNameLength) {
                  return 'Use no máximo ${ProjectBoardCubit.maxNameLength} caracteres.';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              enabled: !isSaving,
              maxLength: ProjectBoardCubit.maxDescriptionLength,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
                hintText: 'O que essa pessoa faz',
                prefixIcon: Icon(Icons.notes_rounded),
                alignLabelWithHint: true,
              ),
            ),
            if (state.actionErrorMessage != null) ...[
              const SizedBox(height: 12),
              AppInlineErrorMessage(message: state.actionErrorMessage!),
            ],
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: AppSecondaryButton(
                    onPressed: isSaving
                        ? null
                        : () => Navigator.of(context).maybePop(),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppPrimaryButton(
                    onPressed: isSaving ? null : () => _submit(cubit),
                    child: isSaving
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: cs.onPrimary,
                            ),
                          )
                        : Text(_isEditing ? 'Salvar' : 'Criar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
