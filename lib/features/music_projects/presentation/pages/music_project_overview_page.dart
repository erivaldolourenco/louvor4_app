import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_radius.dart';
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
import '../../../user_profile/apresentation/cubit/user_cubit.dart';

class MusicProjectOverviewPage extends StatefulWidget {
  final String projectId;
  final bool embedded;
  final VoidCallback? onLeaveProject;
  final VoidCallback? onDeleteProject;

  const MusicProjectOverviewPage({
    super.key,
    required this.projectId,
    this.embedded = false,
    this.onLeaveProject,
    this.onDeleteProject,
  });

  @override
  State<MusicProjectOverviewPage> createState() =>
      _MusicProjectOverviewPageState();
}

class _MusicProjectOverviewPageState extends State<MusicProjectOverviewPage>
    with SingleTickerProviderStateMixin {
  final _repository = MusicProjectsRepositoryImpl();
  late final TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  MusicProjectEntity? _project;
  bool _isAdmin = false;
  String? _memberRole;
  bool _headerCollapsed = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController.addListener(_handleScroll);
    _loadOverview();
  }

  void _handleScroll() {
    final collapsed = _scrollController.offset > 4;
    if (collapsed != _headerCollapsed) {
      setState(() => _headerCollapsed = collapsed);
    }
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
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
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

  Future<void> _onDeleteProject() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _DeleteProjectDialog(projectName: _project?.name ?? ''),
    );
    if (confirmed != true || !mounted) return;

    try {
      await _repository.deleteProject(widget.projectId);
      if (!mounted) return;
      AppFeedback.showSuccess('Projeto excluído com sucesso.');
      if (widget.onDeleteProject != null) {
        widget.onDeleteProject!();
      } else {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildBody());
  }

  Widget _buildBody() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

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
              Icon(
                Icons.cloud_off_rounded,
                size: 46,
                color: cs.onSurfaceVariant,
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
      controller: _scrollController,
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          HeaderProjectEvent(
            title: project.name,
            subtitle: MusicProjectUiUtils.typeLabel(project.type),
            isCollapsed: _headerCollapsed,
            actions: [
              if (_isAdmin)
                PopupMenuButton<String>(
                  color: cs.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: _headerCollapsed ? cs.onSurface : Colors.white,
                  ),
                  onSelected: (value) {
                    if (value == 'edit') _onEditProject();
                    if (value == 'dashboard') _onOpenDashboard();
                    if (value == 'delete') _onDeleteProject();
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem<String>(
                      value: 'dashboard',
                      padding: EdgeInsets.zero,
                      child: ListTile(
                        leading: const Icon(Icons.bar_chart_rounded),
                        title: const Text('Dashboard'),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        dense: true,
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'edit',
                      padding: EdgeInsets.zero,
                      child: ListTile(
                        leading: const Icon(Icons.edit_rounded),
                        title: const Text('Editar Projeto'),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        dense: true,
                      ),
                    ),
                    if (_memberRole == 'OWNER')
                      PopupMenuItem<String>(
                        value: 'delete',
                        padding: EdgeInsets.zero,
                        child: ListTile(
                          leading: Icon(
                            Icons.delete_outline_rounded,
                            color: cs.error,
                          ),
                          title: Text(
                            'Excluir Projeto',
                            style: TextStyle(color: cs.error),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          dense: true,
                        ),
                      ),
                  ],
                ),
            ],
            backgroundImageUrl: project.profileImage,
          ),
        ];
      },
      body: Column(
        children: [
          _ProjectTabs(controller: _tabController),
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
                  currentUserId: context.read<UserCubit>().state.user?.id,
                  onLeaveProject: widget.onLeaveProject,
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

class _DeleteProjectDialog extends StatefulWidget {
  final String projectName;

  const _DeleteProjectDialog({required this.projectName});

  @override
  State<_DeleteProjectDialog> createState() => _DeleteProjectDialogState();
}

class _DeleteProjectDialogState extends State<_DeleteProjectDialog> {
  final _controller = TextEditingController();
  bool _canConfirm = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() => _canConfirm = _controller.text == 'excluir');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.errorContainer,
              borderRadius: BorderRadius.circular(AppRadius.badge),
            ),
            child: Icon(Icons.warning_amber_rounded, color: cs.error, size: 22),
          ),
          const SizedBox(width: 12),
          Text(
            'Excluir projeto',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 14, color: cs.onSurface, height: 1.5),
              children: [
                const TextSpan(text: 'Esta ação é '),
                TextSpan(
                  text: 'irreversível',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: cs.error,
                  ),
                ),
                const TextSpan(text: '. O projeto '),
                TextSpan(
                  text: widget.projectName,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const TextSpan(
                  text:
                      ' será removido permanentemente, incluindo todos os eventos e histórico associados.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Digite excluir para confirmar',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'excluir',
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _canConfirm ? () => Navigator.of(context).pop(true) : null,
          style: FilledButton.styleFrom(
            backgroundColor: _canConfirm ? cs.error : null,
          ),
          child: const Text('Confirmar exclusão'),
        ),
      ],
    );
  }
}

class _ProjectTabs extends StatelessWidget {
  final TabController controller;

  const _ProjectTabs({required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const tabs = [
      (assetPath: 'assets/icons/calendar-fold.svg', label: 'Eventos'),
      (assetPath: 'assets/icons/users-round.svg', label: 'Membros'),
      (assetPath: 'assets/icons/wrench.svg', label: 'Funções'),
    ];

    return AnimatedBuilder(
      animation: controller.animation ?? controller,
      builder: (context, _) {
        final activeIndex =
            controller.animation?.value.round() ?? controller.index;

        return TabBar(
          controller: controller,
          indicator: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding: const EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 6,
          ),
          dividerColor: Colors.transparent,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          labelColor: cs.primary,
          unselectedLabelColor: cs.onSurfaceVariant,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
          tabs: [
            for (var i = 0; i < tabs.length; i++)
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      tabs[i].assetPath,
                      width: 18,
                      height: 18,
                      colorFilter: ColorFilter.mode(
                        i == activeIndex ? cs.primary : cs.onSurfaceVariant,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        tabs[i].label,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
