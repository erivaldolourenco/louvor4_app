import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/ui/widgets/app_buttons.dart';
import '../../../../core/ui/widgets/standard_section_app_bar.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/events_repository.dart';
import '../../domain/entities/event_detail_entity.dart';
import '../../domain/entities/update_event_input_entity.dart';
import '../cubit/edit_event_cubit.dart';

Future<bool?> openEditEventPage(
  BuildContext context, {
  required EventDetailEntity event,
  required EventsRepository repository,
}) {
  return Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => EditEventPage(event: event, repository: repository),
    ),
  );
}

class EditEventPage extends StatelessWidget {
  final EventDetailEntity event;
  final EventsRepository repository;

  const EditEventPage({
    super.key,
    required this.event,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return BlocProvider(
      create: (_) => EditEventCubit(repository)..startEditing(),
      child: _EditEventView(event: event),
    );
  }
}

class _EditEventView extends StatefulWidget {
  final EventDetailEntity event;

  const _EditEventView({required this.event});

  @override
  State<_EditEventView> createState() => _EditEventViewState();
}

class _EditEventViewState extends State<_EditEventView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _dateController;
  late final TextEditingController _timeController;
  late final TextEditingController _locationController;

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(
      widget.event.date.year,
      widget.event.date.month,
      widget.event.date.day,
    );
    _selectedTime = _parseTime(widget.event.time);

    _titleController = TextEditingController(text: widget.event.title);
    _descriptionController = TextEditingController(
      text: widget.event.description ?? '',
    );
    _dateController = TextEditingController(text: formatDate(_selectedDate));
    _timeController = TextEditingController(
      text: _formatTimeOfDay(_selectedTime),
    );
    _locationController = TextEditingController(
      text: widget.event.location ?? '',
    );
  }

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
    final cs = Theme.of(context).colorScheme;
    final cubit = context.read<EditEventCubit>();
    final state = context.watch<EditEventCubit>().state;

    return Scaffold(
      appBar: const StandardSectionAppBar(
        title: 'Editar Evento',
        subtitle: 'Atualize os dados do evento atual',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
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
                TextFormField(
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
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _dateController,
                        enabled: !state.isSubmitting,
                        readOnly: true,
                        onTap: state.isSubmitting ? null : _pickDate,
                        decoration: const InputDecoration(
                          labelText: 'Data',
                          hintText: 'Selecione',
                          prefixIcon: Icon(Icons.calendar_month_rounded),
                        ),
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'Informe a data.';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
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
                    ),
                  ],
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
                  _InlineErrorMessage(message: state.errorMessage!),
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
                      : const Text('Salvar alterações'),
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
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );

    if (!mounted || selected == null) return;
    setState(() {
      _selectedDate = DateTime(selected.year, selected.month, selected.day);
      _dateController.text = formatDate(_selectedDate);
    });
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (!mounted || selected == null) return;
    setState(() {
      _selectedTime = selected;
      _timeController.text = _formatTimeOfDay(selected);
    });
  }

  Future<void> _submit(EditEventCubit cubit) async {
    if (!_formKey.currentState!.validate()) return;

    final description = _descriptionController.text.trim();
    final success = await cubit.submit(
      eventId: widget.event.id,
      input: UpdateEventInputEntity(
        title: _titleController.text.trim(),
        description: description.isEmpty ? null : description,
        startDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
        startTime:
            '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
        location: _locationController.text.trim(),
      ),
    );

    if (!mounted || !success) return;
    Navigator.of(context).pop(true);
  }

  TimeOfDay _parseTime(String value) {
    final sanitized = formatTime(value);
    final parts = sanitized.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class _InlineErrorMessage extends StatelessWidget {
  final String message;

  const _InlineErrorMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(color: cs.error.withValues(alpha: 0.35)),
      ),
      child: Text(
        message,
        style: TextStyle(color: cs.error, fontWeight: FontWeight.w600),
      ),
    );
  }
}
