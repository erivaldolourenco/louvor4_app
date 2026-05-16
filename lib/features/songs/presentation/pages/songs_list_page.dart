import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/ui/app_feedback.dart';
import '../../../../core/ui/widgets/app_async_states.dart';
import '../../../../core/ui/widgets/app_card_surface.dart';
import '../../../../core/ui/widgets/primary_add_fab.dart';
import '../../../../core/ui/widgets/song_details_sheet.dart';
import '../../../../core/ui/widgets/standard_section_app_bar.dart';
import '../../../../core/utils/youtube_utils.dart';
import '../../../medleys/data/impl/medley_repository_impl.dart';
import '../../../medleys/domain/entities/medley_entity.dart';
import '../../../medleys/presentation/cubit/medley_cubit.dart';
import '../../../medleys/presentation/cubit/medley_state.dart';
import '../../../medleys/presentation/widgets/medley_card.dart';
import '../../../medleys/presentation/widgets/medley_form_sheet.dart';
import '../../data/impl/songs_repository_impl.dart';
import '../../domain/entities/song_entity.dart';
import 'create_song_page.dart';
import 'edit_song_page.dart';

// ---------------------------------------------------------------------------
// Entry point — provides MedleyCubit
// ---------------------------------------------------------------------------

class SongsListPage extends StatelessWidget {
  const SongsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MedleyCubit(MedleyRepositoryImpl()),
      child: const _SongsContent(),
    );
  }
}

// ---------------------------------------------------------------------------
// Main content with tab controller
// ---------------------------------------------------------------------------

class _SongsContent extends StatefulWidget {
  const _SongsContent();

  @override
  State<_SongsContent> createState() => _SongsContentState();
}

class _SongsContentState extends State<_SongsContent>
    with SingleTickerProviderStateMixin {
  // Tab
  late final TabController _tabController;

  // Songs state
  static const Duration _songsCacheInterval = Duration(minutes: 10);
  final SongsRepositoryImpl _repo = SongsRepositoryImpl();
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  List<SongEntity> _songs = const [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime? _lastLoadedAt;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadSongs();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {}); // rebuild FAB + subtitle
    if (_tabController.index == 1) {
      final medleyState = context.read<MedleyCubit>().state;
      if (medleyState.status == MedleyStatus.initial) {
        context.read<MedleyCubit>().loadMedleys();
      }
    }
  }

  // ------ Songs loading ------

  Future<void> _loadSongs({bool silent = false, bool force = false}) async {
    if (!force &&
        _songs.isNotEmpty &&
        _lastLoadedAt != null &&
        DateTime.now().difference(_lastLoadedAt!) < _songsCacheInterval) {
      return;
    }

    if (!silent) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = null;
      });
    }

    try {
      final songs = await _repo.getUserSongs();
      if (!mounted) return;
      setState(() {
        _songs = songs;
        _hasError = false;
        _errorMessage = null;
      });
      _lastLoadedAt = DateTime.now();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
      if (silent) {
        AppFeedback.showError(_errorMessage ?? 'Erro ao carregar músicas.');
      }
    } finally {
      if (mounted && !silent) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _goToCreate() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateSongPage()),
    );
    if (created == true) await _loadSongs(silent: true, force: true);
  }

  Future<void> _goToEdit(String songId) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EditSongPage(songId: songId)),
    );
    if (updated == true) await _loadSongs(silent: true, force: true);
  }

  Future<void> _openYouTube(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      AppFeedback.showError('URL do YouTube inválida.');
      return;
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) AppFeedback.showError('Não foi possível abrir o YouTube.');
  }

  // ------ Medley actions ------

  void _openCreateMedley() {
    showMedleyFormSheet(context, songs: _songs);
  }

  void _openEditMedley(MedleyEntity medley) {
    showMedleyFormSheet(context, songs: _songs, medley: medley);
  }

  void _confirmDeleteMedley(MedleyEntity medley) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Remover "${medley.name}"?',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text('Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB3261E),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final cubit = context.read<MedleyCubit>();
              final ok = await cubit.deleteMedley(medley.id!);
              if (!mounted) return;
              if (ok) {
                AppFeedback.showSuccess('Medley removido com sucesso.');
              } else {
                AppFeedback.showError(
                  cubit.state.actionError ?? 'Erro ao remover medley.',
                );
              }
            },
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }

  // ------ Build ------

  @override
  Widget build(BuildContext context) {
    final onSongsTab = _tabController.index == 0;
    final medleyCount = context.select(
      (MedleyCubit c) => c.state.medleys.length,
    );
    final subtitle = onSongsTab
        ? '${_songs.length} ${_songs.length == 1 ? 'canção catalogada' : 'canções catalogadas'}'
        : '$medleyCount ${medleyCount == 1 ? 'medley' : 'medleys'}';

    return Scaffold(
      appBar: StandardSectionAppBar(title: 'Músicas', subtitle: subtitle),
      floatingActionButton: _buildFab(onSongsTab),
      body: Column(
        children: [
          _SongsTabBar(controller: _tabController),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSongsTab(),
                _buildMedleysTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildFab(bool onSongsTab) {
    if (onSongsTab) {
      return _songs.isNotEmpty
          ? PrimaryAddFab(onPressed: _goToCreate)
          : null;
    }
    return PrimaryAddFab(
      heroTag: 'medley_fab',
      onPressed: _openCreateMedley,
    );
  }

  // ------ Songs tab body ------

  Widget _buildSongsTab() {
    if (_isLoading) return const AppLoadingState();

    if (_hasError && _songs.isEmpty) {
      return AppErrorState(
        message: _errorMessage ?? 'Não foi possível carregar suas músicas.',
        onRetry: () => _loadSongs(force: true),
      );
    }

    if (_songs.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _loadSongs(force: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.62,
              child: Center(
                child: AppEmptyState(
                  icon: Icons.library_music_rounded,
                  title: 'Sua biblioteca está silenciosa',
                  description:
                      'Você ainda não adicionou nenhuma música ao seu repertório pessoal.',
                  action: FilledButton.icon(
                    onPressed: _goToCreate,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Adicionar Primeira Música'),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final filteredSongs = _songs.where((song) {
      final query = _searchQuery.toLowerCase();
      return song.title.toLowerCase().contains(query) ||
          song.artist.toLowerCase().contains(query);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Builder(
            builder: (context) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final borderColor = isDark
                  ? const Color(0xFF243041)
                  : const Color(0xFFDCE3EC);
              final fillColor = isDark ? const Color(0xFF111827) : Colors.white;

              return TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Buscar por título ou artista...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: fillColor,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFF0166FF),
                      width: 1.4,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _loadSongs(force: true),
            child: filteredSongs.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: 60),
                    children: [
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 48,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color
                                  ?.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Nenhuma música encontrada\npara "$_searchQuery"',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color
                                    ?.withValues(alpha: 0.7),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 90),
                    itemBuilder: (_, index) {
                      final song = filteredSongs[index];
                      return _SongCard(
                        song: song,
                        onTap: () => showSongDetailsModal(
                          context,
                          title: song.title,
                          artist: song.artist,
                          musicKey: song.key,
                          bpm: song.bpm,
                          youTubeUrl: song.youTubeUrl,
                          notes: song.notes,
                        ),
                        onOpenYoutube: () => _openYouTube(song.youTubeUrl),
                        onEdit: song.id == null
                            ? null
                            : () => _goToEdit(song.id!),
                      );
                    },
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemCount: filteredSongs.length,
                  ),
          ),
        ),
      ],
    );
  }

  // ------ Medleys tab body ------

  Widget _buildMedleysTab() {
    return BlocBuilder<MedleyCubit, MedleyState>(
      builder: (context, state) {
        if (state.status == MedleyStatus.initial ||
            state.status == MedleyStatus.loading) {
          return const AppLoadingState();
        }
        if (state.status == MedleyStatus.failure && state.medleys.isEmpty) {
          return AppErrorState(
            message:
                state.errorMessage ?? 'Não foi possível carregar seus medleys.',
            onRetry: () => context.read<MedleyCubit>().loadMedleys(),
          );
        }
        if (state.medleys.isEmpty) {
          return _MedleysEmpty(onCreateMedley: _openCreateMedley);
        }
        return RefreshIndicator(
          onRefresh: () => context.read<MedleyCubit>().loadMedleys(),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
            itemCount: state.medleys.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final medley = state.medleys[i];
              return MedleyCard(
                medley: medley,
                onEdit: () => _openEditMedley(medley),
                onDelete: () => _confirmDeleteMedley(medley),
              );
            },
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Pill tab bar
// ---------------------------------------------------------------------------

class _SongsTabBar extends StatelessWidget {
  final TabController controller;

  const _SongsTabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? const Color(0xFF0F172A) : Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: AnimatedBuilder(
        animation: controller.animation ?? controller,
        builder: (context, _) {
          final tabIndex =
              controller.animation?.value.round() ?? controller.index;

          return Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B)
                  : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: controller,
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: isDark ? const Color(0xFF111827) : Colors.white,
                borderRadius: BorderRadius.circular(11),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: isDark ? 0.18 : 0.05,
                    ),
                    blurRadius: isDark ? 14 : 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              splashFactory: NoSplash.splashFactory,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              tabs: [
                Tab(
                  child: Text(
                    'Músicas',
                    style: TextStyle(
                      fontWeight: tabIndex == 0
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 14,
                      color: tabIndex == 0
                          ? (isDark
                                ? const Color(0xFFF8FAFC)
                                : const Color(0xFF0F172A))
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
                Tab(
                  child: Text(
                    'Medleys',
                    style: TextStyle(
                      fontWeight: tabIndex == 1
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 14,
                      color: tabIndex == 1
                          ? (isDark
                                ? const Color(0xFFF8FAFC)
                                : const Color(0xFF0F172A))
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Medleys empty state
// ---------------------------------------------------------------------------

class _MedleysEmpty extends StatelessWidget {
  final VoidCallback onCreateMedley;

  const _MedleysEmpty({required this.onCreateMedley});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.queue_music_rounded,
              size: 56,
              color: Color(0xFF94A3B8),
            ),
            const SizedBox(height: 12),
            Text(
              'Nenhum medley criado',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Monte sequências de músicas para usar nas suas escalas.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onCreateMedley,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Criar Medley'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Song card (unchanged from before)
// ---------------------------------------------------------------------------

class _SongCard extends StatelessWidget {
  final SongEntity song;
  final VoidCallback onTap;
  final VoidCallback onOpenYoutube;
  final VoidCallback? onEdit;

  const _SongCard({
    required this.song,
    required this.onTap,
    required this.onOpenYoutube,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AppCardSurface(
          radius: 22,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    YoutubeUtils.getThumbnail(
                      song.youTubeUrl,
                      quality: 'default',
                    ),
                    width: 82,
                    height: 82,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Image.asset(
                      YoutubeUtils.defaultThumb,
                      width: 82,
                      height: 82,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        song.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF94A3B8),
                            ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _MetaBadge(label: 'Tom: ${song.key}'),
                          if (song.bpm != null && song.bpm!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            _MetaBadge(
                              icon: Icons.speed_rounded,
                              label: '${song.bpm} BPM',
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _CircularSongActionButton(
                      onPressed: onOpenYoutube,
                      assetPath: 'assets/icons/youtube.svg',
                      iconColor: const Color(0xFFDC2626),
                      backgroundColor: const Color(0xFFFEF2F2),
                      borderColor: const Color(0xFFFECACA),
                    ),
                    const SizedBox(width: 8),
                    _CircularSongActionButton(
                      onPressed: onEdit,
                      assetPath: 'assets/icons/file-music.svg',
                      iconColor: onEdit != null
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF94A3B8),
                      backgroundColor: onEdit != null
                          ? const Color(0xFFEFF6FF)
                          : const Color(0xFFF8FAFC),
                      borderColor: onEdit != null
                          ? const Color(0xFFBFDBFE)
                          : const Color(0xFFE2E8F0),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CircularSongActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String assetPath;
  final Color iconColor;
  final Color backgroundColor;
  final Color borderColor;

  const _CircularSongActionButton({
    required this.onPressed,
    required this.assetPath,
    required this.iconColor,
    required this.backgroundColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor),
          ),
          child: Center(
            child: SvgPicture.asset(
              assetPath,
              width: 18,
              height: 18,
              colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  final IconData? icon;
  final String label;

  const _MetaBadge({this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: const Color(0xFF64748B)),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }
}
