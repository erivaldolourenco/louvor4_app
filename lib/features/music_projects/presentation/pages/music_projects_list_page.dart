import 'package:flutter/material.dart';

import '../../../../core/ui/app_feedback.dart';
import '../../../../core/utils/url_utils.dart';
import '../../../../core/ui/widgets/app_async_states.dart';
import '../../../../core/ui/widgets/app_card_surface.dart';
import '../../../../core/ui/widgets/standard_section_app_bar.dart';
import '../../data/impl/music_projects_repository_impl.dart';
import '../../domain/entities/music_project_entity.dart';
import '../widgets/music_project_type_badge.dart';
import 'music_project_overview_page.dart';

class MusicProjectsListPage extends StatefulWidget {
  const MusicProjectsListPage({super.key});

  @override
  State<MusicProjectsListPage> createState() => _MusicProjectsListPageState();
}

class _MusicProjectsListPageState extends State<MusicProjectsListPage> {
  final _repository = MusicProjectsRepositoryImpl();

  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  String? _selectedProjectId;
  List<MusicProjectEntity> _projects = const [];

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = null;
      });
    }

    try {
      final projects = await _repository.getUserMusicProjects();
      if (!mounted) return;
      setState(() {
        _projects = projects;
        _hasError = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
      if (silent) {
        AppFeedback.showError(_errorMessage ?? 'Erro ao carregar projetos.');
      }
    } finally {
      if (mounted && !silent) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openProject(MusicProjectEntity project) {
    setState(() => _selectedProjectId = project.id);
  }

  Future<void> _goToCreateProjectPlaceholder() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const _CreateProjectPlaceholderPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedProjectId != null) {
      return MusicProjectOverviewPage(
        projectId: _selectedProjectId!,
        embedded: true,
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const StandardSectionAppBar(
        title: 'Selecionar projeto',
        subtitle: 'Escolha um projeto para acompanhar eventos e detalhes',
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const AppLoadingState();
    }

    if (_hasError && _projects.isEmpty) {
      return AppErrorState(
        message: _errorMessage ?? 'Não foi possível carregar seus projetos.',
        onRetry: _loadProjects,
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: RefreshIndicator(
        onRefresh: _loadProjects,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            if (_projects.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppEmptyState(
                  icon: Icons.folder_open_rounded,
                  title: 'Nenhum projeto encontrado',
                  description:
                      'Você ainda não possui projetos musicais cadastrados.',
                ),
              ),
            ..._projects.map(
              (project) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ProjectSelectableCard(
                  project: project,
                  onTap: () => _openProject(project),
                ),
              ),
            ),
            _CreateProjectCard(onTap: _goToCreateProjectPlaceholder),
          ],
        ),
      ),
    );
  }
}

class _ProjectSelectableCard extends StatelessWidget {
  final MusicProjectEntity project;
  final VoidCallback onTap;

  const _ProjectSelectableCard({required this.project, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleColor = theme.textTheme.titleMedium?.color;
    final chevronColor = theme.iconTheme.color?.withValues(alpha: 0.62);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          decoration: appCardDecoration(context, radius: 16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: UrlUtils.isValidNetworkUrl(project.profileImage)
                      ? Image.network(
                          project.profileImage!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _avatarFallback(),
                        )
                      : _avatarFallback(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: titleColor,
                            ),
                      ),
                      const SizedBox(height: 6),
                      MusicProjectTypeBadge(type: project.type),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, color: chevronColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _avatarFallback([BuildContext? context]) {
    final isDark = context != null
        ? Theme.of(context).brightness == Brightness.dark
        : false;
    return Container(
      width: 56,
      height: 56,
      color: isDark ? const Color(0xFF172554) : const Color(0xFFEFF6FF),
      child: const Icon(
        Icons.multitrack_audio_rounded,
        color: Color(0xFF0166FF),
        size: 24,
      ),
    );
  }
}

class _CreateProjectCard extends StatelessWidget {
  final VoidCallback onTap;

  const _CreateProjectCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
          decoration: appCardDecoration(
            context,
            radius: 16,
            borderColor: isDark
                ? const Color(0xFF3B82F6)
                : const Color(0xFF94A3B8),
            color: Theme.of(context).cardColor,
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF172554)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Icon(Icons.add_rounded, color: Color(0xFF0166FF)),
              ),
              const SizedBox(width: 10),
              Text(
                'Criar novo projeto',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateProjectPlaceholderPage extends StatelessWidget {
  const _CreateProjectPlaceholderPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar Projeto')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.construction_rounded,
                size: 46,
                color: Color(0xFF94A3B8),
              ),
              const SizedBox(height: 10),
              Text(
                'Criação de projeto será implementada em breve.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
