import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/ui/widgets/app_buttons.dart';
import '../../../../core/ui/widgets/app_cached_network_image.dart';
import '../../../../core/ui/widgets/app_form_sheet.dart';
import '../../../../core/ui/widgets/app_inline_error_message.dart';
import '../../../music_projects/data/music_projects_repository.dart';
import '../../../music_projects/domain/entities/project_member_entity.dart';
import '../../data/responsibilities_repository.dart';
import '../../domain/entities/responsibility_entity.dart';
import 'responsibility_dates.dart';

/// Adiciona um responsável por um período. Retorna `true` se salvou.
Future<bool?> showAssignmentFormSheet(
  BuildContext context, {
  required ResponsibilitiesRepository repository,
  required MusicProjectsRepository projectsRepository,
  required String projectId,
  required ResponsibilityEntity responsibility,
  required List<ResponsibilityAssignmentEntity> history,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.bottomSheet),
      ),
    ),
    builder: (_) => AssignmentFormSheet(
      repository: repository,
      projectsRepository: projectsRepository,
      projectId: projectId,
      responsibility: responsibility,
      history: history,
    ),
  );
}

enum _PeriodMode { month, custom }

class AssignmentFormSheet extends StatefulWidget {
  final ResponsibilitiesRepository repository;
  final MusicProjectsRepository projectsRepository;
  final String projectId;
  final ResponsibilityEntity responsibility;
  final List<ResponsibilityAssignmentEntity> history;

  const AssignmentFormSheet({
    super.key,
    required this.repository,
    required this.projectsRepository,
    required this.projectId,
    required this.responsibility,
    required this.history,
  });

  @override
  State<AssignmentFormSheet> createState() => _AssignmentFormSheetState();
}

class _AssignmentFormSheetState extends State<AssignmentFormSheet> {
  List<ProjectMemberEntity> _members = const [];
  bool _loadingMembers = true;
  String? _memberId;
  _PeriodMode _mode = _PeriodMode.month;
  late DateTime _month;
  DateTimeRange? _customRange;
  bool _submitted = false;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _month = _suggestedMonth();
    _loadMembers();
  }

  /// Mês seguinte ao fim do último período (continuação do rodízio);
  /// sem histórico, ou se o último já acabou há tempo, o mês atual.
  DateTime _suggestedMonth() {
    final currentMonth = firstDayOfMonth(DateTime.now());
    if (widget.history.isEmpty) return currentMonth;
    final latestEnd = widget.history
        .map((a) => a.endDate)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    final next = DateTime(latestEnd.year, latestEnd.month + 1);
    return next.isAfter(currentMonth) ? next : currentMonth;
  }

  Future<void> _loadMembers() async {
    try {
      final members = await widget.projectsRepository.getProjectMembers(
        widget.projectId,
      );
      if (!mounted) return;
      setState(() {
        _members =
            members
                .where((m) => m.status == ProjectMemberStatus.active)
                .toList()
              ..sort(
                (a, b) => a.fullName.toLowerCase().compareTo(
                  b.fullName.toLowerCase(),
                ),
              );
        _loadingMembers = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingMembers = false;
        _errorMessage = 'Não foi possível carregar os membros do projeto.';
      });
    }
  }

  DateTimeRange? get _selectedRange {
    if (_mode == _PeriodMode.month) {
      return DateTimeRange(start: _month, end: lastDayOfMonth(_month));
    }
    return _customRange;
  }

  /// Aviso quando o novo período começa durante um período existente
  /// (a API encerra o anterior no dia anterior ao novo início).
  String? get _overlapNotice {
    final range = _selectedRange;
    if (range == null) return null;
    for (final a in widget.history) {
      if (a.startDate.isBefore(range.start) &&
          !a.endDate.isBefore(range.start)) {
        final dayBefore = range.start.subtract(const Duration(days: 1));
        return 'O período de ${a.fullName} será encerrado em ${formatShortDate(dayBefore)}.';
      }
    }
    return null;
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 5),
      initialDateRange:
          _customRange ??
          DateTimeRange(start: _month, end: lastDayOfMonth(_month)),
      helpText: 'Período da responsabilidade',
      saveText: 'Confirmar',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _customRange = DateTimeRange(
        start: dateOnly(picked.start),
        end: dateOnly(picked.end),
      );
    });
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);
    final range = _selectedRange;
    if (_memberId == null || range == null) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      await widget.repository.assignMember(
        widget.projectId,
        widget.responsibility.id,
        memberId: _memberId!,
        startDate: range.start,
        endDate: range.end,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final overlapNotice = _overlapNotice;

    return AppFormSheet(
      title: 'Adicionar responsável',
      subtitle:
          'Quem vai cuidar de "${widget.responsibility.name}" e por quanto tempo.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_loadingMembers)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _memberId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Membro',
                prefixIcon: _memberId == null
                    ? const Icon(Icons.person_outline_rounded)
                    : null,
                errorText: _submitted && _memberId == null
                    ? 'Escolha o membro responsável.'
                    : null,
              ),
              items: _members
                  .map(
                    (member) => DropdownMenuItem<String>(
                      value: member.id,
                      child: Row(
                        children: [
                          _MemberAvatar(member: member),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              member.fullName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _isSaving
                  ? null
                  : (value) => setState(() => _memberId = value),
            ),
          const SizedBox(height: 18),
          Text(
            'Período',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          SegmentedButton<_PeriodMode>(
            segments: const [
              ButtonSegment(
                value: _PeriodMode.month,
                label: Text('Mês inteiro'),
                icon: Icon(Icons.calendar_month_rounded),
              ),
              ButtonSegment(
                value: _PeriodMode.custom,
                label: Text('Datas'),
                icon: Icon(Icons.date_range_rounded),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: _isSaving
                ? null
                : (selection) => setState(() => _mode = selection.first),
          ),
          const SizedBox(height: 12),
          if (_mode == _PeriodMode.month)
            _MonthSelector(
              month: _month,
              enabled: !_isSaving,
              onChanged: (month) => setState(() => _month = month),
            )
          else
            OutlinedButton.icon(
              onPressed: _isSaving ? null : _pickCustomRange,
              icon: const Icon(Icons.event_rounded),
              label: Text(
                _customRange == null
                    ? 'Escolher datas'
                    : '${formatFullDate(_customRange!.start)} a ${formatFullDate(_customRange!.end)}',
              ),
            ),
          if (_submitted && _selectedRange == null) ...[
            const SizedBox(height: 6),
            Text(
              'Escolha as datas de início e fim.',
              style: theme.textTheme.bodySmall?.copyWith(color: cs.error),
            ),
          ] else if (overlapNotice != null) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    overlapNotice,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            AppInlineErrorMessage(message: _errorMessage!),
          ],
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: AppSecondaryButton(
                  onPressed: _isSaving
                      ? null
                      : () => Navigator.of(context).maybePop(false),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppPrimaryButton(
                  onPressed: _isSaving || _loadingMembers ? null : _submit,
                  child: _isSaving
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.onPrimary,
                          ),
                        )
                      : const Text('Adicionar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  final DateTime month;
  final bool enabled;
  final ValueChanged<DateTime> onChanged;

  const _MonthSelector({
    required this.month,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadius.textarea),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Mês anterior',
            onPressed: enabled
                ? () => onChanged(DateTime(month.year, month.month - 1))
                : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '${responsibilityMonthNames[month.month - 1]} de ${month.year}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${formatShortDate(month)} a ${formatShortDate(lastDayOfMonth(month))}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Próximo mês',
            onPressed: enabled
                ? () => onChanged(DateTime(month.year, month.month + 1))
                : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

/// Foto do membro (ou a inicial, quando ele não tem foto).
class _MemberAvatar extends StatelessWidget {
  final ProjectMemberEntity member;

  const _MemberAvatar({required this.member});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final image = appCachedImageProvider(member.profileImage);
    final initial = member.fullName.isNotEmpty
        ? member.fullName.characters.first.toUpperCase()
        : '?';

    return CircleAvatar(
      radius: 14,
      backgroundColor: cs.primaryContainer,
      backgroundImage: image,
      child: image == null
          ? Text(
              initial,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: cs.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            )
          : null,
    );
  }
}
