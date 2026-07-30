import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/ui/app_feedback.dart';
import '../../../../core/ui/widgets/app_buttons.dart';
import '../../../../core/ui/widgets/app_inline_error_message.dart';
import '../../../../core/ui/widgets/app_text_area_theme.dart';
import '../../../../core/ui/widgets/standard_section_app_bar.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/music_projects_repository.dart';
import '../../domain/entities/create_project_event_batch_input.dart';
import '../cubit/create_project_event_batch_cubit.dart';

Future<bool?> openCreateProjectEventBatchPage(
  BuildContext context, {
  required String projectId,
  required MusicProjectsRepository repository,
}) {
  return Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => CreateProjectEventBatchPage(
        projectId: projectId,
        repository: repository,
      ),
    ),
  );
}

class CreateProjectEventBatchPage extends StatelessWidget {
  final String projectId;
  final MusicProjectsRepository repository;

  const CreateProjectEventBatchPage({
    super.key,
    required this.projectId,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CreateProjectEventBatchCubit(repository),
      child: _CreateProjectEventBatchView(projectId: projectId),
    );
  }
}

class _CreateProjectEventBatchView extends StatefulWidget {
  final String projectId;

  const _CreateProjectEventBatchView({required this.projectId});

  @override
  State<_CreateProjectEventBatchView> createState() =>
      _CreateProjectEventBatchViewState();
}

class _CreateProjectEventBatchViewState
    extends State<_CreateProjectEventBatchView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _timeController = TextEditingController();
  final _locationController = TextEditingController();

  final List<DateTime> _selectedDates = [];
  TimeOfDay? _selectedTime;
  String? _datesError;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _timeController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cubit = context.read<CreateProjectEventBatchCubit>();
    final state = context.watch<CreateProjectEventBatchCubit>().state;

    return Scaffold(
      appBar: const StandardSectionAppBar(
        title: 'Novo Evento em Lote',
        subtitle: 'Crie o mesmo evento em várias datas de uma vez',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _titleController,
                  enabled: !state.isSubmitting,
                  maxLength: 80,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    hintText: 'Ex: Culto Domingo',
                    prefixIcon: Icon(Icons.title_rounded),
                  ),
                  validator: (value) {
                    final text = (value ?? '').trim();
                    if (text.isEmpty) return 'Informe o título do evento.';
                    if (text.length < 3) {
                      return 'O título deve ter ao menos 3 caracteres.';
                    }
                    if (text.length > 80) {
                      return 'O título deve ter no máximo 80 caracteres.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                AppTextAreaTheme(
                  child: TextFormField(
                    controller: _descriptionController,
                    enabled: !state.isSubmitting,
                    maxLength: 500,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Descrição',
                      hintText: 'Descrição do evento (opcional)',
                      prefixIcon: Icon(Icons.notes_rounded),
                      alignLabelWithHint: true,
                    ),
                    validator: (value) {
                      final text = (value ?? '').trim();
                      if (text.length > 500) {
                        return 'A descrição deve ter no máximo 500 caracteres.';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 12),
                _DatesField(
                  dates: _selectedDates,
                  enabled: !state.isSubmitting,
                  errorText: _datesError,
                  onAddDate: _pickDate,
                  onRemoveDate: (date) {
                    setState(() {
                      _selectedDates.remove(date);
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _timeController,
                  enabled: !state.isSubmitting,
                  readOnly: true,
                  onTap: state.isSubmitting ? null : _pickTime,
                  decoration: const InputDecoration(
                    labelText: 'Hora',
                    hintText: 'Selecione',
                    prefixIcon: Icon(Icons.schedule_rounded),
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'Informe a hora.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _locationController,
                  enabled: !state.isSubmitting,
                  maxLength: 120,
                  decoration: const InputDecoration(
                    labelText: 'Local',
                    hintText: 'Ex: Igreja Central',
                    prefixIcon: Icon(Icons.place_outlined),
                  ),
                  validator: (value) {
                    final text = (value ?? '').trim();
                    if (text.isEmpty) return 'Informe o local do evento.';
                    if (text.length > 120) {
                      return 'O local deve ter no máximo 120 caracteres.';
                    }
                    return null;
                  },
                ),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  AppInlineErrorMessage(message: state.errorMessage!),
                ],
                const SizedBox(height: 22),
                AppPrimaryButton(
                  onPressed: state.isSubmitting ? null : () => _submit(cubit),
                  child: state.isSubmitting
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.onPrimary,
                          ),
                        )
                      : Text(
                          _selectedDates.length > 1
                              ? 'Adicionar ${_selectedDates.length} eventos'
                              : 'Adicionar eventos',
                        ),
                ),
                const SizedBox(height: 10),
                AppSecondaryButton(
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

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      selectableDayPredicate: (day) =>
          !_selectedDates.any((d) => _isSameDay(d, day)),
    );

    if (!mounted || selected == null) return;
    setState(() {
      _selectedDates.add(selected);
      _selectedDates.sort();
      _datesError = null;
    });
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _pickTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );

    if (!mounted || selected == null) return;
    setState(() {
      _selectedTime = selected;
      _timeController.text =
          '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _submit(CreateProjectEventBatchCubit cubit) async {
    final formValid = _formKey.currentState!.validate();
    setState(() {
      _datesError = _selectedDates.isEmpty
          ? 'Selecione pelo menos uma data.'
          : null;
    });
    if (!formValid || _selectedDates.isEmpty || _selectedTime == null) return;

    final dateFormatter = DateFormat('yyyy-MM-dd');
    final startTime =
        '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';

    final success = await cubit.submit(
      projectId: widget.projectId,
      input: CreateProjectEventBatchInput(
        title: _titleController.text,
        description: _descriptionController.text,
        dates: _selectedDates.map(dateFormatter.format).toList(),
        startTime: startTime,
        location: _locationController.text,
      ),
    );

    if (!mounted) return;
    if (success) {
      AppFeedback.showSuccess('Eventos criados com sucesso.');
      Navigator.of(context).pop(true);
    } else if (cubit.state.errorMessage != null) {
      AppFeedback.showError(cubit.state.errorMessage!);
    }
  }
}

class _DatesField extends StatelessWidget {
  final List<DateTime> dates;
  final bool enabled;
  final String? errorText;
  final VoidCallback onAddDate;
  final ValueChanged<DateTime> onRemoveDate;

  const _DatesField({
    required this.dates,
    required this.enabled,
    required this.errorText,
    required this.onAddDate,
    required this.onRemoveDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: errorText != null ? cs.error : cs.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(AppRadius.textarea),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_repeat_rounded, color: cs.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Datas',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: enabled ? onAddDate : null,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Adicionar data'),
              ),
            ],
          ),
          if (dates.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 2, bottom: 4),
              child: Text(
                'Nenhuma data selecionada.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: dates
                    .map(
                      (date) => Chip(
                        label: Text(formatDate(date)),
                        onDeleted: enabled ? () => onRemoveDate(date) : null,
                      ),
                    )
                    .toList(),
              ),
            ),
          if (errorText != null)
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 4),
              child: Text(
                errorText!,
                style: theme.textTheme.bodySmall?.copyWith(color: cs.error),
              ),
            ),
        ],
      ),
    );
  }
}
