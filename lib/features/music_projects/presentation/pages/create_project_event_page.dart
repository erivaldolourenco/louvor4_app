import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/ui/app_feedback.dart';
import '../../../../core/ui/widgets/app_form_sheet.dart';
import '../../../../core/ui/widgets/standard_section_app_bar.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/music_projects_repository.dart';
import '../../domain/entities/create_project_event_input.dart';
import '../cubit/create_project_event_cubit.dart';

Future<bool?> openCreateProjectEventPage(
  BuildContext context, {
  required String projectId,
  required MusicProjectsRepository repository,
}) {
  return Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => CreateProjectEventPage(
        projectId: projectId,
        repository: repository,
      ),
    ),
  );
}

class CreateProjectEventPage extends StatelessWidget {
  final String projectId;
  final MusicProjectsRepository repository;

  const CreateProjectEventPage({
    super.key,
    required this.projectId,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CreateProjectEventCubit(repository),
      child: _CreateProjectEventView(projectId: projectId),
    );
  }
}

class _CreateProjectEventView extends StatefulWidget {
  final String projectId;

  const _CreateProjectEventView({required this.projectId});

  @override
  State<_CreateProjectEventView> createState() => _CreateProjectEventViewState();
}

class _CreateProjectEventViewState extends State<_CreateProjectEventView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _locationController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CreateProjectEventCubit>();
    final state = context.watch<CreateProjectEventCubit>().state;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: const StandardSectionAppBar(
        title: 'Novo Evento',
        subtitle: 'Adicione um evento ao projeto atual',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SectionLabel(label: 'Título'),
                TextFormField(
                  controller: _titleController,
                  enabled: !state.isSubmitting,
                  maxLength: 80,
                  style: const TextStyle(fontSize: 15),
                  decoration: appFormFieldDecoration(
                    hintText: 'Ex: Culto Domingo',
                    prefixIcon: Icons.title_rounded,
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
                const SizedBox(height: 14),
                const _SectionLabel(label: 'Descrição'),
                TextFormField(
                  controller: _descriptionController,
                  enabled: !state.isSubmitting,
                  maxLength: 500,
                  minLines: 3,
                  maxLines: 5,
                  decoration: appFormFieldDecoration(
                    hintText: 'Descrição do evento (opcional)',
                    prefixIcon: Icons.notes_rounded,
                    alignLabelWithHint: true,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  validator: (value) {
                    final text = (value ?? '').trim();
                    if (text.length > 500) {
                      return 'A descrição deve ter no máximo 500 caracteres.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionLabel(label: 'Data'),
                          TextFormField(
                            controller: _dateController,
                            enabled: !state.isSubmitting,
                            readOnly: true,
                            onTap: state.isSubmitting ? null : _pickDate,
                            decoration: appFormFieldDecoration(
                              hintText: 'Selecione',
                              prefixIcon: Icons.calendar_month_rounded,
                            ),
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return 'Informe a data.';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionLabel(label: 'Hora'),
                          TextFormField(
                            controller: _timeController,
                            enabled: !state.isSubmitting,
                            readOnly: true,
                            onTap: state.isSubmitting ? null : _pickTime,
                            decoration: appFormFieldDecoration(
                              hintText: 'Selecione',
                              prefixIcon: Icons.schedule_rounded,
                            ),
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return 'Informe a hora.';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const _SectionLabel(label: 'Local'),
                TextFormField(
                  controller: _locationController,
                  enabled: !state.isSubmitting,
                  maxLength: 120,
                  decoration: appFormFieldDecoration(
                    hintText: 'Ex: Igreja Central',
                    prefixIcon: Icons.place_outlined,
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
                  _InlineErrorMessage(message: state.errorMessage!),
                ],
                const SizedBox(height: 22),
                FilledButton(
                  style: appPrimaryPillButtonStyle(),
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
                      : const Text('Adicionar evento'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  style: appSecondaryPillButtonStyle(),
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
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );

    if (!mounted || selected == null) return;
    setState(() {
      _selectedDate = selected;
      _dateController.text = formatDate(selected);
    });
  }

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

  Future<void> _submit(CreateProjectEventCubit cubit) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _selectedTime == null) return;

    final dateFormatter = DateFormat('yyyy-MM-dd');
    final startTime =
        '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';

    final success = await cubit.submit(
      projectId: widget.projectId,
      input: CreateProjectEventInput(
        title: _titleController.text,
        description: _descriptionController.text,
        startDate: dateFormatter.format(_selectedDate!),
        startTime: startTime,
        location: _locationController.text,
      ),
    );

    if (!mounted) return;
    if (success) {
      AppFeedback.showSuccess(
        'Evento criado com sucesso. Crie outro evento ou feche para voltar.',
      );
      Navigator.of(context).pop(true);
    } else if (cubit.state.errorMessage != null) {
      AppFeedback.showError(cubit.state.errorMessage!);
    }
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF111827),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFF991B1B),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
