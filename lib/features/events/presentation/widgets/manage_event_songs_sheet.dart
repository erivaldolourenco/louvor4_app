import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:louvor4_app/features/medleys/data/impl/medley_repository_impl.dart';
import 'package:louvor4_app/features/medleys/domain/entities/medley_entity.dart';
import 'package:louvor4_app/features/songs/domain/entities/song_entity.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../core/ui/app_feedback.dart';
import '../../../../core/ui/widgets/app_buttons.dart';
import '../../../../core/ui/widgets/app_inline_error_message.dart';
import '../../../../core/utils/youtube_utils.dart';
import '../../data/events_repository.dart';
import '../cubit/manage_event_songs_cubit.dart';
import '../cubit/manage_event_songs_state.dart';

Future<bool?> showManageEventSongsSheet(
  BuildContext context, {
  required String eventId,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return BlocProvider(
        create: (_) => ManageEventSongsCubit(
          context.read<EventsRepository>(),
          MedleyRepositoryImpl(),
        )..load(),
        child: _ManageEventSongsSheet(eventId: eventId),
      );
    },
  );
}

class _ManageEventSongsSheet extends StatefulWidget {
  final String eventId;

  const _ManageEventSongsSheet({required this.eventId});

  @override
  State<_ManageEventSongsSheet> createState() => _ManageEventSongsSheetState();
}

class _ManageEventSongsSheetState extends State<_ManageEventSongsSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _medleysLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    setState(() {}); // refresh search hint for the active tab
    if (_tabController.index == 1 && !_medleysLoaded && mounted) {
      _medleysLoaded = true;
      context.read<ManageEventSongsCubit>().loadMedleys();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final titleColor = theme.textTheme.titleLarge?.color;
    final subtitleColor = theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.78);

    return Padding(
      padding: EdgeInsets.only(
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Material(
        color: cs.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.cardLarge),
        ),
        child: SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: BlocConsumer<ManageEventSongsCubit, ManageEventSongsState>(
              listenWhen: (prev, curr) =>
                  prev.status != curr.status &&
                  curr.status == ManageEventSongsStatus.success,
              listener: (context, state) {
                AppFeedback.showSuccess('Adicionado ao repertório com sucesso.');
                Navigator.of(context).pop(true);
              },
              builder: (context, state) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle
                      Center(
                        child: Container(
                          width: 42,
                          height: 5,
                          decoration: BoxDecoration(
                            color: cs.outlineVariant,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Adicionar ao repertório',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Selecione músicas avulsas ou medleys para adicionar ao evento.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: subtitleColor),
                      ),
                      const SizedBox(height: 16),
                      // Search — same style as the Músicas screen, shared by both tabs
                      _RepertoireSearchField(
                        controller: _searchController,
                        isMedleysTab: _tabController.index == 1,
                        searchQuery: _searchQuery,
                        onSearchChanged: (v) =>
                            setState(() => _searchQuery = v),
                        onClearSearch: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                      const SizedBox(height: 12),
                      // Tab bar
                      _SheetTabBar(controller: _tabController),
                      const SizedBox(height: 14),
                      // Error banner
                      if (state.errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AppInlineErrorMessage(message: state.errorMessage!),
                        ),
                      // Tab content — each tab subscribes to the cubit directly
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _SongsTab(searchQuery: _searchQuery),
                            _MedleysTab(searchQuery: _searchQuery),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Submit button — own BlocBuilder to always read fresh state
                      BlocBuilder<ManageEventSongsCubit, ManageEventSongsState>(
                        builder: (context, btnState) {
                          final cubit =
                              context.read<ManageEventSongsCubit>();
                          return AnimatedBuilder(
                            animation: _tabController,
                            builder: (context, _) {
                              final isMedleysTab =
                                  _tabController.index == 1;
                              final count = isMedleysTab
                                  ? btnState.selectedMedleyIds.length
                                  : btnState.selectedSongIds.length;
                              final enabled =
                                  !btnState.isSubmitting && count > 0;

                              return AppPrimaryButton(
                                onPressed: enabled
                                    ? () => isMedleysTab
                                        ? cubit.submitMedleys(widget.eventId)
                                        : cubit.submit(widget.eventId)
                                    : null,
                                child: btnState.isSubmitting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        isMedleysTab
                                            ? 'Adicionar Medley${count != 1 ? 's' : ''} ($count)'
                                            : 'Adicionar Selecionadas ($count)',
                                      ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Search field (same style as the Músicas screen), shared across tabs
// ---------------------------------------------------------------------------

class _RepertoireSearchField extends StatelessWidget {
  final TextEditingController controller;
  final bool isMedleysTab;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;

  const _RepertoireSearchField({
    required this.controller,
    required this.isMedleysTab,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      onChanged: onSearchChanged,
      decoration: InputDecoration(
        hintText: isMedleysTab
            ? 'Buscar medley...'
            : 'Buscar por título ou artista...',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded),
                onPressed: onClearSearch,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.25),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.25),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab bar styled (matches event detail page style)
// ---------------------------------------------------------------------------

class _SheetTabBar extends StatelessWidget {
  final TabController controller;

  const _SheetTabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? cs.onPrimaryContainer : cs.primary;
    const tabs = [
      (assetPath: 'assets/icons/music.svg', label: 'Músicas'),
      (assetPath: 'assets/icons/disc-album.svg', label: 'Medleys'),
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
          labelColor: activeColor,
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
                        i == activeIndex ? activeColor : cs.onSurfaceVariant,
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

// ---------------------------------------------------------------------------
// Songs tab
// ---------------------------------------------------------------------------

class _SongsTab extends StatelessWidget {
  final String searchQuery;

  const _SongsTab({required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    final subtitleColor =
        Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.78);

    return BlocBuilder<ManageEventSongsCubit, ManageEventSongsState>(
      builder: (context, state) {
        final cubit = context.read<ManageEventSongsCubit>();

        final filteredSongs = state.songs.where((song) {
          final query = searchQuery.toLowerCase();
          return song.title.toLowerCase().contains(query) ||
              song.artist.toLowerCase().contains(query);
        }).toList();

        return state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : state.songs.isEmpty
            ? const _EmptySongsState()
            : filteredSongs.isEmpty
            ? Center(
                child: Text(
                  'Nenhuma música encontrada.',
                  style: TextStyle(color: subtitleColor),
                ),
              )
            : ListView.builder(
                itemCount: filteredSongs.length,
                itemBuilder: (context, index) {
                  final song = filteredSongs[index];
                  return _SelectableSongCard(
                    song: song,
                    isSelected: state.selectedSongIds.contains(song.id),
                    enabled: !state.isSubmitting,
                    onTap: song.id == null
                        ? null
                        : () => cubit.toggleSong(song.id!),
                  );
                },
              );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Medleys tab
// ---------------------------------------------------------------------------

class _MedleysTab extends StatelessWidget {
  final String searchQuery;

  const _MedleysTab({required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    final subtitleColor =
        Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.78);

    return BlocBuilder<ManageEventSongsCubit, ManageEventSongsState>(
      builder: (context, state) {
        final cubit = context.read<ManageEventSongsCubit>();

        if (state.isLoadingMedleys) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.medleys.isEmpty) {
          return const _EmptyMedleysState();
        }

        final query = searchQuery.toLowerCase();
        final filteredMedleys = state.medleys
            .where((medley) => medley.name.toLowerCase().contains(query))
            .toList();

        if (filteredMedleys.isEmpty) {
          return Center(
            child: Text(
              'Nenhum medley encontrado.',
              style: TextStyle(color: subtitleColor),
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredMedleys.length,
          itemBuilder: (context, index) {
            final medley = filteredMedleys[index];
            final id = medley.id;
            return _SelectableMedleyCard(
              medley: medley,
              isSelected: id != null && state.selectedMedleyIds.contains(id),
              enabled: !state.isSubmitting,
              onTap: id == null ? null : () => cubit.toggleMedley(id),
            );
          },
        );
      },
    );
  }
}

class _SelectableMedleyCard extends StatelessWidget {
  final MedleyEntity medley;
  final bool isSelected;
  final bool enabled;
  final VoidCallback? onTap;

  const _SelectableMedleyCard({
    required this.medley,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final titleColor = theme.textTheme.titleMedium?.color;
    final subtitleColor =
        theme.textTheme.bodySmall?.color?.withValues(alpha: 0.78);
    final count = medley.items.length;

    return Opacity(
      opacity: enabled ? 1 : 0.72,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.card),
            onTap: enabled ? onTap : null,
            child: Ink(
              decoration: BoxDecoration(
                color: isSelected ? cs.primaryContainer : cs.surface,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(
                  color: isSelected ? cs.primary : cs.outlineVariant,
                  width: isSelected ? 1.6 : 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: cs.secondaryContainer,
                        borderRadius: BorderRadius.circular(
                          AppRadius.thumbnail,
                        ),
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          'assets/icons/disc-album.svg',
                          width: 32,
                          height: 32,
                          colorFilter: ColorFilter.mode(
                            cs.onSecondaryContainer,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            medley.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: titleColor,
                            ),
                          ),
                          if (medley.description != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              medley.description!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: 13,
                                color: subtitleColor,
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                              border: Border.all(
                                color: cs.outlineVariant,
                              ),
                            ),
                            child: Text(
                              '$count ${count == 1 ? 'música' : 'músicas'}',
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: subtitleColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Checkbox(
                      value: isSelected,
                      onChanged:
                          enabled && onTap != null ? (_) => onTap!() : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Song card (unchanged visual)
// ---------------------------------------------------------------------------

class _SelectableSongCard extends StatelessWidget {
  final SongEntity song;
  final bool isSelected;
  final bool enabled;
  final VoidCallback? onTap;

  const _SelectableSongCard({
    required this.song,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = theme.textTheme.titleMedium?.color;
    final subtitleColor =
        theme.textTheme.bodySmall?.color?.withValues(alpha: 0.78);

    return Opacity(
      opacity: enabled ? 1 : 0.72,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.card),
            onTap: enabled ? onTap : null,
            child: Ink(
              decoration: BoxDecoration(
                color: isSelected ? cs.primaryContainer : cs.surface,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(
                  color: isSelected ? cs.primary : cs.outlineVariant,
                  width: isSelected ? 1.6 : 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      child: Image.network(
                        YoutubeUtils.getThumbnail(song.youTubeUrl),
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 72,
                          height: 72,
                          color: cs.surfaceContainerLow,
                          child: Icon(
                            Icons.music_note_rounded,
                            color: subtitleColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: titleColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: subtitleColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _MetaBadge(
                                iconAsset: 'assets/icons/music-2.svg',
                                label: song.key,
                                backgroundColor: cs.tertiaryContainer
                                    .withValues(alpha: 0.85),
                                foregroundColor: cs.onTertiaryContainer,
                                borderColor: cs.tertiary.withValues(
                                  alpha: 0.25,
                                ),
                              ),
                              if (song.bpm != null && song.bpm!.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                _MetaBadge(
                                  iconAsset: 'assets/icons/time.svg',
                                  label: song.bpm!,
                                  backgroundColor: isDark
                                      ? AppColors.successSubtleDark
                                      : AppColors.successSubtleLight,
                                  foregroundColor: isDark
                                      ? AppColors.successBright
                                      : AppColors.success,
                                  borderColor: (isDark
                                          ? AppColors.successBright
                                          : AppColors.success)
                                      .withValues(alpha: 0.25),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Checkbox(
                      value: isSelected,
                      onChanged:
                          enabled && onTap != null ? (_) => onTap!() : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared widgets
// ---------------------------------------------------------------------------

class _MetaBadge extends StatelessWidget {
  final String iconAsset;
  final String label;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;

  const _MetaBadge({
    required this.iconAsset,
    required this.label,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg =
        foregroundColor ?? Theme.of(context).textTheme.bodySmall?.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor ?? cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: borderColor ?? cs.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            iconAsset,
            width: 14,
            height: 14,
            colorFilter: ColorFilter.mode(
              fg ?? cs.onSurfaceVariant,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: fg,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySongsState extends StatelessWidget {
  const _EmptySongsState();

  @override
  Widget build(BuildContext context) {
    final titleColor = Theme.of(context).textTheme.titleMedium?.color;
    final subtitleColor =
        Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.78);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.library_music_outlined, size: 44, color: subtitleColor),
            const SizedBox(height: 10),
            Text(
              'Nenhuma música cadastrada',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: titleColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Cadastre músicas na sua biblioteca para adicioná-las ao evento.',
              textAlign: TextAlign.center,
              style: TextStyle(color: subtitleColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyMedleysState extends StatelessWidget {
  const _EmptyMedleysState();

  @override
  Widget build(BuildContext context) {
    final titleColor = Theme.of(context).textTheme.titleMedium?.color;
    final subtitleColor =
        Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.78);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/icons/disc-album.svg',
              width: 44,
              height: 44,
              colorFilter: ColorFilter.mode(
                subtitleColor ?? Theme.of(context).colorScheme.onSurfaceVariant,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Nenhum medley cadastrado',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: titleColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Crie medleys na sua biblioteca para adicioná-los ao evento.',
              textAlign: TextAlign.center,
              style: TextStyle(color: subtitleColor),
            ),
          ],
        ),
      ),
    );
  }
}
