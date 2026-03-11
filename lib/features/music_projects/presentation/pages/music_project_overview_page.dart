import 'package:flutter/material.dart';

import '../../../../core/ui/app_feedback.dart';
import '../../../../core/utils/url_utils.dart';
import '../../data/impl/music_projects_repository_impl.dart';
import '../../domain/entities/music_project_entity.dart';
import '../utils/music_project_ui_utils.dart';
import '../widgets/project_events_tab.dart';
import '../widgets/project_members_tab.dart';
import '../../../project_skills/domain/entities/project_role.dart';
import '../../../project_skills/presentation/pages/project_skills_page.dart';

class MusicProjectOverviewPage extends StatefulWidget {
  final String projectId;
  final bool embedded;

  const MusicProjectOverviewPage({
    super.key,
    required this.projectId,
    this.embedded = false,
  });

  @override
  State<MusicProjectOverviewPage> createState() =>
      _MusicProjectOverviewPageState();
}

class _MusicProjectOverviewPageState extends State<MusicProjectOverviewPage> {
  final _repository = MusicProjectsRepositoryImpl();

  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  MusicProjectEntity? _project;
  bool _isAdmin = false;
  String? _memberRole;
  int _activeTab = 0;

  @override
  void initState() {
    super.initState();
    _loadOverview();
  }

  @override
  void didUpdateWidget(covariant MusicProjectOverviewPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projectId != widget.projectId) {
      _activeTab = 0;
      _loadOverview();
    }
  }

  Future<void> _loadOverview() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _repository.getProjectById(widget.projectId),
        _repository.getMemberRole(widget.projectId),
      ]);

      if (!mounted) return;

      final project = results[0] as MusicProjectEntity;
      final role = (results[1] as String).toUpperCase();

      setState(() {
        _project = project;
        _isAdmin = role == 'ADMIN' || role == 'OWNER';
        _memberRole = role;
        _hasError = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onEditProject() {
    AppFeedback.showSuccess('Edição de projeto será implementada em breve.');
  }

  void _onOpenDashboard() {
    AppFeedback.showSuccess('Dashboard do projeto será implementado em breve.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError || _project == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 46,
                color: Color(0xFF64748B),
              ),
              const SizedBox(height: 10),
              Text(
                _errorMessage ?? 'Não foi possível carregar o projeto.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _loadOverview,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    final project = _project!;

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverAppBar(
            expandedHeight: 110,
            pinned: true,
            stretch: true,
            backgroundColor: Colors.black,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: false,
            title: Text(
              project.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 24,
              ),
            ),
            actions: [
              if (_isAdmin)
                PopupMenuButton<String>(
                  color: Colors.white,
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: Colors.white,
                  ),
                  onSelected: (value) {
                    if (value == 'edit') _onEditProject();
                    if (value == 'dashboard') _onOpenDashboard();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Editar Projeto'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'dashboard',
                      child: Row(
                        children: [
                          Icon(Icons.bar_chart_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Dashboard'),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsetsDirectional.only(
                start: 20,
                bottom: 16,
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  UrlUtils.isValidNetworkUrl(project.profileImage)
                      ? Image.network(
                          project.profileImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _headerFallback(),
                        )
                      : _headerFallback(),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x8A000000), Color(0xCC000000)],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 22,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF22C55E),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          MusicProjectUiUtils.typeLabel(project.type),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(76),
              child: Container(
                color: const Color(0xFFF5F7F9),
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: _ProjectTabs(
                  activeIndex: _activeTab,
                  onChange: (index) => setState(() => _activeTab = index),
                ),
              ),
            ),
          ),
        ];
      },
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: _activeTab == 0
            ? ProjectEventsTab(
                key: ValueKey('events-${project.id}'),
                projectId: project.id,
                isAdmin: _isAdmin,
                fallbackImageUrl: project.profileImage,
                repository: _repository,
              )
            : _activeTab == 1
            ? ProjectMembersTab(
                key: ValueKey('members-${project.id}'),
                projectId: project.id,
                canManageMembers: _isAdmin,
                repository: _repository,
              )
            : ProjectSkillsPage(
                key: ValueKey('skills-${project.id}'),
                projectId: project.id,
                initialRole: projectRoleFromString(_memberRole),
                initialProjectName: project.name,
              ),
      ),
    );
  }

  Widget _headerFallback() {
    return Container(
      color: const Color(0xFF0F172A),
      child: const Center(
        child: Icon(
          Icons.multitrack_audio_rounded,
          color: Colors.white70,
          size: 58,
        ),
      ),
    );
  }
}

class _ProjectTabs extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onChange;

  const _ProjectTabs({required this.activeIndex, required this.onChange});

  @override
  Widget build(BuildContext context) {
    const tabs = [
      (icon: Icons.calendar_month_rounded, label: 'Eventos'),
      (icon: Icons.groups_2_rounded, label: 'Membros'),
      (icon: Icons.build_circle_rounded, label: 'Funções'),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final active = index == activeIndex;
          final tab = tabs[index];

          return Expanded(
            child: GestureDetector(
              onTap: () => onChange(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: active
                      ? const [
                          BoxShadow(
                            color: Color(0x18000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      tab.icon,
                      size: 18,
                      color: active
                          ? const Color(0xFF0166FF)
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tab.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: active
                            ? const Color(0xFF0166FF)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
