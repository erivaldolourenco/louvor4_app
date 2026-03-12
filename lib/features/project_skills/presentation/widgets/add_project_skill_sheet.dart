import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/ui/app_feedback.dart';
import '../../../../core/ui/widgets/app_form_sheet.dart';
import '../state/project_skills_cubit.dart';
import '../state/project_skills_state.dart';

class AddProjectSkillSheet extends StatefulWidget {
  const AddProjectSkillSheet({super.key});

  @override
  State<AddProjectSkillSheet> createState() => _AddProjectSkillSheetState();
}

class _AddProjectSkillSheetState extends State<AddProjectSkillSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProjectSkillsCubit>();
    final state = context.watch<ProjectSkillsCubit>().state;
    final isSubmitting = state.submission == ProjectSkillsSubmission.creating;

    return AppFormSheet(
      title: 'Nova função',
      subtitle:
          'Cadastre uma nova função musical disponível para uso nas escalas.',
      icon: Icons.music_note_rounded,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _FieldLabel(label: 'Nome da função'),
            TextFormField(
              controller: _nameController,
              enabled: !isSubmitting,
              decoration: appFormFieldDecoration(
                context,
                hintText: 'Ex: Guitarra, Vocal, Teclado',
                prefixIcon: Icons.music_note_rounded,
              ),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Informe o nome da função.';
                }
                return null;
              },
            ),
            if (state.actionErrorMessage != null) ...[
              const SizedBox(height: 12),
              _InlineError(message: state.actionErrorMessage!),
            ],
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: appSecondaryPillButtonStyle(context),
                    onPressed: isSubmitting
                        ? null
                        : () => Navigator.of(context).maybePop(false),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: appPrimaryPillButtonStyle(context),
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) {
                              return;
                            }
                            final success = await cubit.createSkill(
                              _nameController.text,
                            );
                            if (!mounted) return;
                            if (success) {
                              Navigator.of(this.context).pop(true);
                            } else if (cubit.state.actionErrorMessage != null) {
                              AppFeedback.showError(
                                cubit.state.actionErrorMessage!,
                              );
                            }
                          },
                    child: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Adicionar função'),
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

class _InlineError extends StatelessWidget {
  final String message;

  const _InlineError({required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF3F1114) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFCA5A5),
        ),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
