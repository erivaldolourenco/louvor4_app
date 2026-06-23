import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/ui/widgets/app_buttons.dart';
import '../../../../core/ui/widgets/app_form_sheet.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/events_repository.dart';
import '../../domain/entities/event_detail_entity.dart';
import '../../domain/entities/update_event_input_entity.dart';
import '../cubit/edit_event_cubit.dart';
import '../cubit/edit_event_state.dart';

Future<bool?> showEditEventSheet(
  BuildContext context, {
  required EventDetailEntity event,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return RepositoryProvider.value(
        value: context.read<EventsRepository>(),
        child: BlocProvider(
          create: (ctx) =>
              EditEventCubit(ctx.read<EventsRepository>())..startEditing(),
          child: _EditEventSheet(event: event),
        ),
      );
    },
  );
}

class _EditEventSheet extends StatefulWidget {
  final EventDetailEntity event;

  const _EditEventSheet({required this.event});

  @override
  State<_EditEventSheet> createState() => _EditEventSheetState();
}

class _EditEventSheetState extends State<_EditEventSheet> {
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
    final cubit = context.read<EditEventCubit>();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: BlocBuilder<EditEventCubit, EditEventState>(
        builder: (context, state) {
          final cs = Theme.of(context).colorScheme;
          return AppFormSheet(
            title: 'Editar evento',
            subtitle:
                'Atualize titulo, descricao, data, hora e local do evento.',
            icon: Icons.edit_calendar_rounded,
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
                      labelText: 'Titulo',
                      hintText: 'Ex: Culto Domingo',
                      prefixIcon: Icon(Icons.title_rounded),
                    ),
                    validator: (value) {
                      final text = (value ?? '').trim();
                      if (text.isEmpty) return 'Informe o titulo do evento.';
                      if (text.length < 3) {
                        return 'O titulo deve ter ao menos 3 caracteres.';
                      }
                      if (text.length > 80) {
                        return 'O titulo deve ter no maximo 80 caracteres.';
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
                      labelText: 'Descricao',
                      hintText: 'Descricao do evento (opcional)',
                      prefixIcon: Icon(Icons.notes_rounded),
                      alignLabelWithHint: true,
                    ),
                    validator: (value) {
                      final text = (value ?? '').trim();
                      if (text.length > 500) {
                        return 'A descricao deve ter no maximo 500 caracteres.';
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
                        return 'O local deve ter no maximo 120 caracteres.';
                      }
                      return null;
                    },
                  ),
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    _InlineErrorMessage(message: state.errorMessage!),
                  ],
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: AppSecondaryButton(
                          onPressed: state.isSubmitting
                              ? null
                              : () => Navigator.of(context).maybePop(false),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppPrimaryButton(
                          onPressed: state.isSubmitting
                              ? null
                              : () => _submit(cubit),
                          child: state.isSubmitting
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: cs.onPrimary,
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
        },
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
