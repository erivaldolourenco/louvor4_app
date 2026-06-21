import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:louvor4_app/core/theme/app_colors.dart';
import 'package:louvor4_app/core/theme/app_radius.dart';
import 'package:louvor4_app/core/ui/app_feedback.dart';
import 'package:louvor4_app/core/ui/widgets/app_form_sheet.dart';
import 'package:louvor4_app/features/music_projects/domain/entities/music_project_entity.dart';
import 'package:louvor4_app/features/user_profile/apresentation/cubit/user_unavailability_cubit.dart';
import 'package:louvor4_app/features/user_profile/apresentation/cubit/user_unavailability_state.dart';
import 'package:louvor4_app/features/user_profile/domain/entities/create_user_unavailability_input_entity.dart';

Future<bool?> showAddUserUnavailabilitySheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: context.read<UserUnavailabilityCubit>(),
      child: const AddUserUnavailabilitySheet(),
    ),
  );
}

class AddUserUnavailabilitySheet extends StatefulWidget {
  const AddUserUnavailabilitySheet({super.key});

  @override
  State<AddUserUnavailabilitySheet> createState() =>
      _AddUserUnavailabilitySheetState();
}

class _AddUserUnavailabilitySheetState
    extends State<AddUserUnavailabilitySheet> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _dateFormat = DateFormat('dd/MM/yyyy');

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isDateRange = false;
  bool _appliesToAllProjects = true;
  final Set<String> _selectedProjectIds = <String>{};

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10),
      locale: const Locale('pt', 'BR'),
    );

    if (picked == null || !mounted) return;

    setState(() {
      _startDate = _normalizeDate(picked);
      if (!_isDateRange) {
        _endDate = _startDate;
      } else if (_endDate != null && _endDate!.isBefore(_startDate!)) {
        _endDate = _startDate;
      }
    });
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final initialDate = _endDate ?? _startDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10),
      locale: const Locale('pt', 'BR'),
    );

    if (picked == null || !mounted) return;

    setState(() {
      _endDate = _normalizeDate(picked);
    });
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    final startDate = _startDate;
    if (startDate == null) {
      AppFeedback.showError('Selecione a data inicial.');
      return;
    }

    final endDate = _isDateRange ? _endDate : startDate;
    if (endDate == null) {
      AppFeedback.showError('Selecione a data final.');
      return;
    }

    if (startDate.isAfter(endDate)) {
      AppFeedback.showError(
        'A data inicial precisa ser menor ou igual a data final.',
      );
      return;
    }

    if (!_appliesToAllProjects && _selectedProjectIds.isEmpty) {
      AppFeedback.showError('Selecione ao menos um projeto.');
      return;
    }

    final cubit = context.read<UserUnavailabilityCubit>();
    final input = CreateUserUnavailabilityInputEntity(
      description: _descriptionController.text.trim(),
      startDate: startDate,
      endDate: endDate,
      appliesToAllProjects: _appliesToAllProjects,
      projectIds: _appliesToAllProjects
          ? const []
          : _selectedProjectIds.toList(growable: false),
    );

    final success = await cubit.create(input);
    if (!mounted) return;

    if (success) {
      _resetForm();
      AppFeedback.showSuccess('Indisponibilidade cadastrada com sucesso.');
      Navigator.of(context).pop(true);
      return;
    }

    AppFeedback.showError(
      cubit.state.actionErrorMessage ??
          'Não foi possível salvar a indisponibilidade.',
    );
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _descriptionController.clear();
    _selectedProjectIds.clear();
    _startDate = null;
    _endDate = null;
    _isDateRange = false;
    _appliesToAllProjects = true;
  }

  DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<UserUnavailabilityCubit>().state;
    final projects = state.projects;
    final isSubmitting =
        state.submission == UserUnavailabilitySubmission.creating;

    return AppFormSheet(
      title: 'Nova indisponibilidade',
      subtitle:
          'Defina o período em que você não poderá participar e aplique para todos os projetos ou apenas alguns deles.',
      icon: Icons.event_busy_rounded,
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _FieldLabel(label: 'Descrição'),
            TextFormField(
              controller: _descriptionController,
              enabled: !isSubmitting,
              minLines: 2,
              maxLines: 4,
              maxLength: 180,
              decoration: appFormFieldDecoration(
                context,
                hintText: 'Ex: Viagem com a família, compromisso profissional',
                prefixIcon: Icons.notes_rounded,
                alignLabelWithHint: true,
              ),
              validator: (value) {
                final text = (value ?? '').trim();
                if (text.isEmpty) {
                  return 'Informe uma descrição.';
                }
                if (text.length < 3) {
                  return 'Use ao menos 3 caracteres.';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            _DateField(
              label: 'Data inicial',
              value: _startDate == null
                  ? 'Selecionar data'
                  : _dateFormat.format(_startDate!),
              icon: Icons.calendar_today_rounded,
              enabled: !isSubmitting,
              onTap: _pickStartDate,
            ),
            const SizedBox(height: 14),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _isDateRange,
              onChanged: isSubmitting
                  ? null
                  : (value) {
                      setState(() {
                        _isDateRange = value;
                        _endDate = value ? _endDate : _startDate;
                      });
                    },
              title: const Text(
                'Período com intervalo',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text(
                'Ative para informar uma data final diferente da inicial.',
              ),
            ),
            if (_isDateRange) ...[
              const SizedBox(height: 6),
              _DateField(
                label: 'Data final',
                value: _endDate == null
                    ? 'Selecionar data'
                    : _dateFormat.format(_endDate!),
                icon: Icons.event_rounded,
                enabled: !isSubmitting,
                onTap: _pickEndDate,
              ),
            ],
            const SizedBox(height: 18),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _appliesToAllProjects,
              onChanged: isSubmitting
                  ? null
                  : (value) {
                      setState(() {
                        _appliesToAllProjects = value;
                        if (value) {
                          _selectedProjectIds.clear();
                        }
                      });
                    },
              title: const Text(
                'Aplicar para todos os projetos',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text(
                'Desative para escolher projetos específicos.',
              ),
            ),
            if (!_appliesToAllProjects) ...[
              const SizedBox(height: 10),
              const _FieldLabel(label: 'Projetos'),
              if (projects.isEmpty)
                const _InlineInfo(
                  message: 'Nenhum projeto disponível para seleção no momento.',
                )
              else
                _ProjectSelectorWrap(
                  projects: projects,
                  selectedProjectIds: _selectedProjectIds,
                  enabled: !isSubmitting,
                  onToggle: (projectId) {
                    setState(() {
                      if (_selectedProjectIds.contains(projectId)) {
                        _selectedProjectIds.remove(projectId);
                      } else {
                        _selectedProjectIds.add(projectId);
                      }
                    });
                  },
                ),
            ],
            if (state.actionErrorMessage != null) ...[
              const SizedBox(height: 16),
              _InlineError(message: state.actionErrorMessage!),
            ],
            const SizedBox(height: 24),
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
                    onPressed: isSubmitting ? null : _submit,
                    child: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Salvar'),
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

class _DateField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.value,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color;
    final mutedColor = theme.brightness == Brightness.dark
        ? AppColors.textMutedDark
        : AppColors.textMutedLight;

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(22),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
        ),
        child: Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: value == 'Selecionar data' ? mutedColor : textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ProjectSelectorWrap extends StatelessWidget {
  final List<MusicProjectEntity> projects;
  final Set<String> selectedProjectIds;
  final bool enabled;
  final ValueChanged<String> onToggle;

  const _ProjectSelectorWrap({
    required this.projects,
    required this.selectedProjectIds,
    required this.enabled,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: projects
          .map((project) {
            final selected = selectedProjectIds.contains(project.id);
            final cs = Theme.of(context).colorScheme;
            return FilterChip(
              label: Text(project.name),
              selected: selected,
              onSelected: enabled ? (_) => onToggle(project.id) : null,
              avatar: Icon(
                _iconForProjectType(project.type),
                size: 18,
                color: selected ? cs.onPrimaryContainer : cs.primary,
              ),
              selectedColor: cs.primaryContainer,
              checkmarkColor: cs.onPrimaryContainer,
              labelStyle: TextStyle(
                color: selected ? cs.onPrimaryContainer : null,
                fontWeight: FontWeight.w600,
              ),
              side: BorderSide(
                color: selected ? cs.primary : cs.outlineVariant,
              ),
            );
          })
          .toList(growable: false),
    );
  }

  IconData _iconForProjectType(MusicProjectType type) {
    switch (type) {
      case MusicProjectType.band:
        return Icons.groups_rounded;
      case MusicProjectType.ministry:
        return Icons.auto_awesome_rounded;
      case MusicProjectType.singer:
        return Icons.mic_rounded;
      case MusicProjectType.unknown:
        return Icons.music_note_rounded;
    }
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

class _InlineInfo extends StatelessWidget {
  final String message;

  const _InlineInfo({required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.scaffoldDark : AppColors.surfaceElevatedLight,
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(
          color: isDark ? AppColors.borderSubtleDark : AppColors.borderStrongLight,
        ),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: isDark ? AppColors.borderSubtleLight : AppColors.textSubtleDark,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
