import 'package:flutter/material.dart';

import '../../../../core/ui/widgets/app_async_states.dart';
import '../../../../core/ui/widgets/standard_section_app_bar.dart';
import '../../data/impl/project_statistics_repository_impl.dart';
import '../../data/project_statistics_repository.dart';
import '../../domain/entities/project_statistics_entities.dart';
import '../widgets/dashboard_format.dart';
import '../widgets/invite_summary_card.dart';
import '../widgets/member_schedule_card.dart';
import '../widgets/month_year_selector.dart';

Future<void> openProjectDashboardPage(
  BuildContext context, {
  required String projectId,
  String? projectName,
}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) =>
          ProjectDashboardPage(projectId: projectId, projectName: projectName),
    ),
  );
}

class ProjectDashboardPage extends StatefulWidget {
  final String projectId;
  final String? projectName;
  final ProjectStatisticsRepository? repository;

  const ProjectDashboardPage({
    super.key,
    required this.projectId,
    this.projectName,
    this.repository,
  });

  @override
  State<ProjectDashboardPage> createState() => _ProjectDashboardPageState();
}

class _ProjectDashboardPageState extends State<ProjectDashboardPage> {
  late final ProjectStatisticsRepository _repository =
      widget.repository ?? ProjectStatisticsRepositoryImpl();

  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _isLoading = true;
  String? _errorMessage;
  ProjectScheduleStatsEntity? _schedules;
  ProjectInviteStatsEntity? _invites;

  // Evita que uma resposta antiga sobrescreva a do período selecionado por último.
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final requestId = ++_requestId;
    final month = DashboardFormat.yearMonth(_selectedMonth);

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _repository.getScheduleStats(widget.projectId, from: month, to: month),
        _repository.getInviteStats(widget.projectId, from: month, to: month),
      ]);
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _schedules = results[0] as ProjectScheduleStatsEntity;
        _invites = results[1] as ProjectInviteStatsEntity;
      });
    } catch (e) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted && requestId == _requestId) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onMonthSelected(DateTime month) {
    if (month == _selectedMonth) return;
    setState(() => _selectedMonth = month);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StandardSectionAppBar(
        title: 'Dashboard',
        subtitle: widget.projectName,
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final hasData = _schedules != null && _invites != null;

    if (!hasData && _isLoading) {
      return const AppLoadingState();
    }
    if (!hasData && _errorMessage != null) {
      return AppErrorState(message: _errorMessage!, onRetry: _load);
    }

    final schedules = _schedules!;
    final invites = _invites!;
    final invitesByMember = {
      for (final m in invites.byMember) m.memberId: m.counts,
    };

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          MonthYearSelector(
            selected: _selectedMonth,
            onChanged: _onMonthSelected,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 4,
            child: _isLoading ? const LinearProgressIndicator() : null,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 12),
          const _SectionTitle(
            title: 'Convites para eventos',
            subtitle: 'Eventos que acontecem no mês selecionado',
          ),
          const SizedBox(height: 10),
          InviteSummaryCard(totals: invites.totals),
          const SizedBox(height: 28),
          const _SectionTitle(
            title: 'Escalas por membro',
            subtitle: 'Convites aceitos, separados por função',
          ),
          const SizedBox(height: 10),
          if (schedules.members.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: AppEmptyState(
                icon: Icons.event_busy_rounded,
                title: 'Nenhuma escala neste mês',
                description:
                    'Quando os membros aceitarem convites para eventos, eles aparecem aqui.',
              ),
            )
          else
            for (final member in schedules.members)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: MemberScheduleCard(
                  stats: member,
                  invites: invitesByMember[member.memberId],
                ),
              ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _SectionTitle({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}
