import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/ui/app_feedback.dart';
import '../../../../core/ui/widgets/header_project_event.dart';
import '../../data/impl/music_projects_repository_impl.dart';
import '../../domain/entities/music_project_entity.dart';
import 'edit_music_project_page.dart';
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

class _MusicProjectOverviewPageState extends State<MusicProjectOverviewPage>
    with SingleTickerProviderStateMixin {
  final _repository = MusicProjectsRepositoryImpl();
  late final TabController _tabController;

  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  MusicProjectEntity? _project;
  bool _isAdmin = false;
  String? _memberRole;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadOverview();
  }

  @override
  void didUpdateWidget(covariant MusicProjectOverviewPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projectId != widget.projectId) {
      _tabController.index = 0;
      _loadOverview();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  Future<void> _onEditProject() async {
    final updated = await openEditMusicProjectPage(
      context,
      projectId: widget.projectId,
      repository: _repository,
    );
    if (updated != true || !mounted) return;

    await _loadOverview();
    if (!mounted) return;
    AppFeedback.showSuccess('Projeto atualizado com sucesso.');
  }

  void _onOpenDashboard() {
    AppFeedback.showSuccess('Dashboard do projeto será implementado em breve.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildBody());
  }

  Widget _buildBody() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
          HeaderProjectEvent(
            title: project.name,
            actions: [
              if (_isAdmin)
                PopupMenuButton<String>(
                  color: isDark ? const Color(0xFF111827) : Colors.white,
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
            backgroundImageUrl: project.profileImage,
            backgroundOverlay: Positioned(
              left: 20,
              right: 20,
              bottom: 22,
              child: Text(
                MusicProjectUiUtils.typeLabel(project.type),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ];
      },
      body: Column(
        children: [
          Container(
            color: theme.scaffoldBackgroundColor,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: _ProjectTabs(controller: _tabController),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                ProjectEventsTab(
                  key: ValueKey('events-${project.id}'),
                  projectId: project.id,
                  isAdmin: _isAdmin,
                  fallbackImageUrl: project.profileImage,
                  repository: _repository,
                ),
                ProjectMembersTab(
                  key: ValueKey('members-${project.id}'),
                  projectId: project.id,
                  canManageMembers: _isAdmin,
                  repository: _repository,
                ),
                ProjectSkillsPage(
                  key: ValueKey('skills-${project.id}'),
                  projectId: project.id,
                  initialRole: projectRoleFromString(_memberRole),
                  initialProjectName: project.name,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectTabs extends StatelessWidget {
  final TabController controller;

  const _ProjectTabs({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final inactiveColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    const tabs = [
      (
        assetPath: 'assets/icons/calendar-fold.svg',
        label: 'Eventos',
        color: Color(0xFF2563EB),
      ),
      (
        assetPath: 'assets/icons/users-round.svg',
        label: 'Membros',
        color: Color(0xFF059669),
      ),
      (
        assetPath: 'assets/icons/wrench.svg',
        label: 'Funções',
        color: Color(0xFFD97706),
      ),
    ];

    return AnimatedBuilder(
      animation: controller.animation ?? controller,
      builder: (context, child) {
        final activeIndex =
            controller.animation?.value.round() ?? controller.index;

        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(14),
          ),
          child: TabBar(
            controller: controller,
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: indexColor(
                activeIndex,
                isDark: isDark,
                fallbackDark: const Color(0xFF111827),
                fallbackLight: Colors.white,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? const Color(0x26000000)
                      : const Color(0x18000000),
                  blurRadius: isDark ? 12 : 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            splashFactory: NoSplash.splashFactory,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            tabs: [
              for (var index = 0; index < tabs.length; index++)
                Tab(
                  height: 44,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        tabs[index].assetPath,
                        width: 18,
                        height: 18,
                        colorFilter: ColorFilter.mode(
                          index == activeIndex
                              ? tabs[index].color
                              : inactiveColor,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          tabs[index].label,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: index == activeIndex
                                ? tabs[index].color
                                : inactiveColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Color indexColor(
    int index, {
    required bool isDark,
    required Color fallbackDark,
    required Color fallbackLight,
  }) {
    const activeBackgroundsLight = [
      Color(0xFFEFF6FF),
      Color(0xFFECFDF5),
      Color(0xFFFFF7ED),
    ];
    const activeBackgroundsDark = [
      Color(0xFF172554),
      Color(0xFF052E2B),
      Color(0xFF3F2A13),
    ];

    if (index < 0 || index > 2) {
      return isDark ? fallbackDark : fallbackLight;
    }

    return isDark
        ? activeBackgroundsDark[index]
        : activeBackgroundsLight[index];
  }
}
