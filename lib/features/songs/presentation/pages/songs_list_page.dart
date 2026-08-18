import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/ui/app_feedback.dart';
import '../../../../core/ui/widgets/app_async_states.dart';
import '../../../../core/ui/widgets/circular_icon_action_button.dart';
import '../../../../core/ui/widgets/primary_add_fab.dart';
import '../../../../core/ui/widgets/song_list_card.dart';
import '../../../../core/ui/widgets/standard_section_app_bar.dart';
import '../../../medleys/data/impl/medley_repository_impl.dart';
import '../../../medleys/domain/entities/medley_entity.dart';
import '../../../medleys/presentation/cubit/medley_cubit.dart';
import '../../../medleys/presentation/cubit/medley_state.dart';
import '../../../medleys/presentation/widgets/medley_card.dart';
import '../../../medleys/presentation/widgets/medley_form_sheet.dart';
import '../../../song_categories/domain/entities/song_category_entity.dart';
import '../../../song_categories/presentation/widgets/category_filter_sheet.dart';
import '../../data/impl/songs_repository_impl.dart';
import '../../domain/entities/external_music_entity.dart';
import '../../domain/entities/song_entity.dart';
import 'chord_sheet_page.dart';
import 'create_song_page.dart';
import 'edit_song_page.dart';
import 'lyrics_page.dart';
import 'search_external_music_page.dart';
import 'song_detail_page.dart';

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
  String? _deletingSongId;
  String? _deletingMedleyId;
  final Set<String> _selectedCategoryFilterIds = {};

  List<SongCategoryEntity> _availableFilterCategories(
    List<MedleyEntity> medleys,
  ) {
    final byId = <String, SongCategoryEntity>{};
    for (final song in _songs) {
      for (final category in song.categories) {
        byId[category.id] = category;
      }
    }
    for (final medley in medleys) {
      for (final category in medley.categories) {
        byId[category.id] = category;
      }
    }
    final categories = byId.values.toList();
    categories.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return categories;
  }

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
    final created = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const CreateSongPage()));
    if (created == true) await _loadSongs(silent: true, force: true);
  }

  Future<void> _goToSearchExternal(ExternalMusicProvider provider) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SearchExternalMusicPage(provider: provider),
      ),
    );
    if (created == true) await _loadSongs(silent: true, force: true);
  }

  Future<void> _goToEdit(String songId) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EditSongPage(songId: songId)),
    );
    if (updated == true) await _loadSongs(silent: true, force: true);
  }

  void _goToLyrics(SongEntity song) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LyricsPage(
          songId: song.id!,
          title: song.title,
          artist: song.artist,
        ),
      ),
    );
  }

  void _goToChords(SongEntity song) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChordSheetPage(
          songId: song.id!,
          title: song.title,
          artist: song.artist,
          initialKey: song.key,
          initialBpm: int.tryParse(song.bpm ?? ''),
        ),
      ),
    );
  }

  Future<bool> _confirmDeleteSong(SongEntity song) async {
    if (song.id == null) return false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Excluir "${song.title}"?'),
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Theme.of(ctx).colorScheme.error,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Esta ação não pode ser desfeita.',
                style: TextStyle(
                  color: Theme.of(ctx).colorScheme.error,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;
    return _deleteSong(song);
  }

  Future<bool> _deleteSong(SongEntity song) async {
    final id = song.id!;
    setState(() => _deletingSongId = id);
    try {
      await _repo.deleteSong(id);
      if (!mounted) return true;
      setState(() {
        _songs = _songs.where((s) => s.id != id).toList();
        _deletingSongId = null;
      });
      AppFeedback.showSuccess('Música excluída com sucesso.');
      return true;
    } catch (e) {
      if (!mounted) return false;
      setState(() => _deletingSongId = null);
      AppFeedback.showError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  Future<void> _openCategoryFilterSheet() async {
    final result = await showCategoryFilterSheet(
      context,
      categories: _availableFilterCategories(
        context.read<MedleyCubit>().state.medleys,
      ),
      initiallySelectedIds: _selectedCategoryFilterIds,
    );

    if (result == null || !mounted) return;
    setState(() {
      _selectedCategoryFilterIds
        ..clear()
        ..addAll(result);
    });
  }

  // ------ Medley actions ------

  void _openCreateMedley() {
    openMedleyFormPage(context, songs: _songs);
  }

  void _openEditMedley(MedleyEntity medley) {
    openMedleyFormPage(context, songs: _songs, medley: medley);
  }

  Future<bool> _confirmDeleteMedley(MedleyEntity medley) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remover "${medley.name}"?'),
        content: const Text('Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirmed != true || medley.id == null || !mounted) return false;
    setState(() => _deletingMedleyId = medley.id);
    final cubit = context.read<MedleyCubit>();
    final ok = await cubit.deleteMedley(medley.id!);
    if (!mounted) return ok;
    setState(() => _deletingMedleyId = null);
    if (ok) {
      AppFeedback.showSuccess('Medley removido com sucesso.');
    } else {
      AppFeedback.showError(
        cubit.state.actionError ?? 'Erro ao remover medley.',
      );
    }
    return ok;
  }

  // ------ Build ------

  @override
  Widget build(BuildContext context) {
    final onSongsTab = _tabController.index == 0;
    final medleys = context.select((MedleyCubit c) => c.state.medleys);
    final medleyCount = medleys.length;
    final subtitle = onSongsTab
        ? '${_songs.length} ${_songs.length == 1 ? 'canção' : 'canções'}'
        : '$medleyCount ${medleyCount == 1 ? 'medley' : 'medleys'}';
    final availableFilterCategories = _availableFilterCategories(medleys);

    return Scaffold(
      appBar: StandardSectionAppBar(
        title: 'Músicas',
        subtitle: subtitle,
        actions: [
          if (availableFilterCategories.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Badge(
                isLabelVisible: _selectedCategoryFilterIds.isNotEmpty,
                smallSize: 9,
                child: CircularIconActionButton(
                  tooltip: 'Filtrar por categoria',
                  onPressed: _openCategoryFilterSheet,
                  assetPath: 'assets/icons/settings-2.svg',
                  iconColor: Theme.of(context).colorScheme.onPrimaryContainer,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  borderColor: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _buildFab(onSongsTab),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SizedBox(
              height: 46,
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 6),
                  hintText: onSongsTab
                      ? 'Buscar por título ou artista...'
                      : 'Buscar medley...',
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.input),
                    borderSide: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.outlineVariant.withValues(alpha: 0.25),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.input),
                    borderSide: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.outlineVariant.withValues(alpha: 0.25),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.input),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
          _SongsTabBar(controller: _tabController),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildSongsTab(), _buildMedleysTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildFab(bool onSongsTab) {
    if (onSongsTab) {
      final cs = Theme.of(context).colorScheme;
      final theme = Theme.of(context);
      return SpeedDial(
        heroTag: 'songs_fab',
        activeIcon: Icons.close_rounded,
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        children: [
          SpeedDialChild(
            child: SvgPicture.asset(
              'assets/icons/file-pen-line.svg',
              width: 22,
              height: 22,
              colorFilter: ColorFilter.mode(
                cs.onSecondaryContainer,
                BlendMode.srcIn,
              ),
            ),
            label: 'Adicionar Manualmente',
            backgroundColor: cs.secondaryContainer,
            foregroundColor: cs.onSecondaryContainer,
            labelStyle: theme.textTheme.labelLarge?.copyWith(
              color: cs.onSurface,
            ),
            labelBackgroundColor: cs.surfaceContainerHigh,
            onTap: _goToCreate,
          ),
          SpeedDialChild(
            child: SvgPicture.asset(
              'assets/icons/icon-spotify.svg',
              width: 22,
              height: 22,
              colorFilter: ColorFilter.mode(
                cs.onSecondaryContainer,
                BlendMode.srcIn,
              ),
            ),
            label: 'Buscar no Spotify',
            backgroundColor: cs.secondaryContainer,
            foregroundColor: cs.onSecondaryContainer,
            labelStyle: theme.textTheme.labelLarge?.copyWith(
              color: cs.onSurface,
            ),
            labelBackgroundColor: cs.surfaceContainerHigh,
            onTap: () => _goToSearchExternal(ExternalMusicProvider.spotify),
          ),
          SpeedDialChild(
            child: SvgPicture.asset(
              'assets/icons/icon-deezer.svg',
              width: 22,
              height: 22,
              colorFilter: ColorFilter.mode(
                cs.onSecondaryContainer,
                BlendMode.srcIn,
              ),
            ),
            label: 'Buscar no Deezer',
            backgroundColor: cs.secondaryContainer,
            foregroundColor: cs.onSecondaryContainer,
            labelStyle: theme.textTheme.labelLarge?.copyWith(
              color: cs.onSurface,
            ),
            labelBackgroundColor: cs.surfaceContainerHigh,
            onTap: () => _goToSearchExternal(ExternalMusicProvider.deezer),
          ),
        ],
        child: SvgPicture.asset(
          'assets/icons/music.svg',
          width: 24,
          height: 24,
          colorFilter: ColorFilter.mode(cs.onPrimary, BlendMode.srcIn),
        ),
      );
    }
    return PrimaryAddFab(
      heroTag: 'medley_fab',
      iconAsset: 'assets/icons/disc-album.svg',
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
                  iconWidget: SvgPicture.asset(
                    'assets/icons/music.svg',
                    width: 56,
                    height: 56,
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).colorScheme.onSurfaceVariant,
                      BlendMode.srcIn,
                    ),
                  ),
                  title: 'Sua biblioteca está silenciosa',
                  description:
                      'Você ainda não adicionou nenhuma música ao seu repertório pessoal.',
                ),
              ),
            ),
          ],
        ),
      );
    }

    final filteredSongs = _songs.where((song) {
      final query = _searchQuery.toLowerCase();
      final matchesQuery =
          song.title.toLowerCase().contains(query) ||
          song.artist.toLowerCase().contains(query);
      final matchesCategory =
          _selectedCategoryFilterIds.isEmpty ||
          song.categories.any(
            (category) => _selectedCategoryFilterIds.contains(category.id),
          );
      return matchesQuery && matchesCategory;
    }).toList();

    return RefreshIndicator(
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
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'Nenhuma música encontrada\npara "$_searchQuery"'
                            : 'Nenhuma música encontrada\npara os filtros selecionados',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 90),
              itemBuilder: (_, index) {
                final song = filteredSongs[index];
                return SongListCard(
                  title: song.title,
                  artist: song.artist,
                  musicKey: song.key,
                  youTubeUrl: song.youTubeUrl,
                  spotifyUrl: song.spotifyUrl,
                  deezerUrl: song.deezerUrl,
                  coverUrl: song.coverUrl,
                  hasAudio: song.referenceAudioUrl?.isNotEmpty == true,
                  onTap: () => openSongDetailPage(
                    context,
                    songId: song.id,
                    title: song.title,
                    artist: song.artist,
                    musicKey: song.key,
                    bpm: song.bpm,
                    album: song.album,
                    youTubeUrl: song.youTubeUrl,
                    spotifyUrl: song.spotifyUrl,
                    deezerUrl: song.deezerUrl,
                    coverUrl: song.coverUrl,
                    notes: song.notes,
                    referenceAudioUrl: song.referenceAudioUrl,
                    onOpenLyrics: song.id == null
                        ? null
                        : () => _goToLyrics(song),
                    onOpenChords: song.id == null
                        ? null
                        : () => _goToChords(song),
                    onEdit: song.id == null ? null : () => _goToEdit(song.id!),
                  ),
                  onDelete: (song.id == null || _deletingSongId != null)
                      ? null
                      : () => _confirmDeleteSong(song),
                  isRemoving: song.id != null && _deletingSongId == song.id,
                  dismissKey: song.id,
                );
              },
              itemCount: filteredSongs.length,
            ),
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
          return const _MedleysEmpty();
        }

        final query = _searchQuery.toLowerCase();
        final filteredMedleys = state.medleys.where((medley) {
          final matchesQuery = medley.name.toLowerCase().contains(query);
          final matchesCategory =
              _selectedCategoryFilterIds.isEmpty ||
              medley.categories.any(
                (category) => _selectedCategoryFilterIds.contains(category.id),
              );
          return matchesQuery && matchesCategory;
        }).toList();

        return RefreshIndicator(
          onRefresh: () => context.read<MedleyCubit>().loadMedleys(),
          child: filteredMedleys.isEmpty
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
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Nenhum medley encontrado\npara "$_searchQuery"'
                                : 'Nenhum medley encontrado\npara os filtros selecionados',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                  itemCount: filteredMedleys.length,
                  itemBuilder: (_, i) {
                    final medley = filteredMedleys[i];
                    return MedleyCard(
                      medley: medley,
                      onEdit: () => _openEditMedley(medley),
                      onDelete: (medley.id == null || _deletingMedleyId != null)
                          ? null
                          : () => _confirmDeleteMedley(medley),
                      isRemoving:
                          medley.id != null && _deletingMedleyId == medley.id,
                      dismissKey: medley.id,
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
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: isDark ? 0.35 : 0.55),
        ),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: cs.primaryContainer,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: cs.primary.withValues(alpha: 0.4)),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        dividerColor: Colors.transparent,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        labelColor: isDark ? cs.onPrimaryContainer : cs.primary,
        unselectedLabelColor: cs.onSurfaceVariant,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14.5,
        ),
        tabs: const [
          Tab(text: 'Músicas'),
          Tab(text: 'Medleys'),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Medleys empty state
// ---------------------------------------------------------------------------

class _MedleysEmpty extends StatelessWidget {
  const _MedleysEmpty();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/icons/disc-album.svg',
              width: 56,
              height: 56,
              colorFilter: ColorFilter.mode(
                cs.onSurfaceVariant,
                BlendMode.srcIn,
              ),
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
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
