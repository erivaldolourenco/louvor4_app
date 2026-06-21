import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/ui/app_feedback.dart';
import '../../../../core/ui/widgets/app_form_sheet.dart';
import '../../../../core/utils/skill_icon.dart';
import '../../domain/entities/project_skill_entity.dart';
import '../state/project_skills_cubit.dart';
import '../state/project_skills_state.dart';

class AddProjectSkillSheet extends StatefulWidget {
  final ProjectSkillEntity? skill;

  const AddProjectSkillSheet({super.key, this.skill});

  bool get isEditing => skill != null;

  @override
  State<AddProjectSkillSheet> createState() => _AddProjectSkillSheetState();
}

class _AddProjectSkillSheetState extends State<AddProjectSkillSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  String? _selectedIconKey;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.skill?.name ?? '');
    _selectedIconKey = widget.skill?.iconKey;
  }

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
    final isEditing = widget.isEditing;

    return AppFormSheet(
      title: isEditing ? 'Editar função' : 'Nova função',
      subtitle: isEditing
          ? 'Altere o nome ou o ícone da função.'
          : 'Cadastre uma nova função musical disponível para uso nas escalas.',
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
            const SizedBox(height: 20),
            const _FieldLabel(label: 'Ícone'),
            _IconPickerGrid(
              selectedKey: _selectedIconKey,
              onSelect: (key) => setState(() => _selectedIconKey = key),
              enabled: !isSubmitting,
            ),
            if (_selectedIconKey == null && state.actionErrorMessage == null) ...[
              const SizedBox(height: 6),
              Text(
                'Selecione um ícone para a função.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
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
                            if (!_formKey.currentState!.validate()) return;
                            if (_selectedIconKey == null) {
                              setState(() {});
                              return;
                            }

                            final bool success;
                            if (isEditing) {
                              success = await cubit.updateSkill(
                                widget.skill!,
                                _nameController.text,
                                iconKey: _selectedIconKey,
                              );
                            } else {
                              success = await cubit.createSkill(
                                _nameController.text,
                                iconKey: _selectedIconKey,
                              );
                            }

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
                        : Text(isEditing ? 'Salvar alterações' : 'Adicionar função'),
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

class _IconPickerGrid extends StatelessWidget {
  final String? selectedKey;
  final ValueChanged<String> onSelect;
  final bool enabled;

  const _IconPickerGrid({
    required this.selectedKey,
    required this.onSelect,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final icons = skillIconLabels.entries.toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: icons.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.9,
      ),
      itemBuilder: (context, index) {
        final key = icons[index].key;
        final label = icons[index].value;
        final isSelected = selectedKey == key;

        return GestureDetector(
          onTap: enabled ? () => onSelect(key) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark
                        ? AppColors.primarySubtleDark
                        : AppColors.primarySubtleLight)
                  : (isDark
                        ? AppColors.surfaceElevatedDark
                        : AppColors.surfaceElevatedLight),
              borderRadius: BorderRadius.circular(AppRadius.input),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : (isDark
                          ? AppColors.borderSubtleDark
                          : AppColors.borderLight),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  skillIconAsset(key),
                  width: 32,
                  height: 32,
                  colorFilter: ColorFilter.mode(
                    isSelected
                        ? AppColors.primary
                        : (isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight),
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.primary
                        : (isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
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
        color: isDark ? AppColors.dangerSubtleDark : AppColors.dangerSubtleLight,
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(
          color: isDark ? AppColors.dangerBorderDark : AppColors.dangerBorderLight,
        ),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: isDark ? AppColors.dangerTextDark : AppColors.dangerTextLight,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
