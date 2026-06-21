import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:louvor4_app/features/medleys/data/impl/medley_repository_impl.dart';
import 'package:louvor4_app/features/medleys/domain/entities/medley_entity.dart';
import 'package:louvor4_app/features/songs/domain/entities/song_entity.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../core/ui/app_feedback.dart';
import '../../../../core/ui/widgets/app_form_sheet.dart';
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
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = theme.textTheme.titleLarge?.color;
    final subtitleColor = theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.78);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Material(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
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
                            color: isDark
                                ? AppColors.borderSubtleDark
                                : AppColors.borderSubtleLight,
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
                      // Tab bar
                      _SheetTabBar(controller: _tabController, isDark: isDark),
                      const SizedBox(height: 14),
                      // Error banner
                      if (state.errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _InlineErrorMessage(message: state.errorMessage!),
                        ),
                      // Tab content — each tab subscribes to the cubit directly
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _SongsTab(
                              searchController: _searchController,
                              searchQuery: _searchQuery,
                              onSearchChanged: (v) =>
                                  setState(() => _searchQuery = v),
                              onClearSearch: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            ),
                            const _MedleysTab(),
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

                              return SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  style: appPrimaryPillButtonStyle(context),
                                  onPressed: enabled
                                      ? () => isMedleysTab
                                          ? cubit.submitMedleys(
                                              widget.eventId,
                                            )
                                          : cubit.submit(widget.eventId)
                                      : null,
                                  child: btnState.isSubmitting
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          isMedleysTab
                                              ? 'Adicionar Medley${count != 1 ? 's' : ''} ($count)'
                                              : 'Adicionar Selecionadas ($count)',
                                        ),
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
// Tab bar styled (matches event detail page style)
// ---------------------------------------------------------------------------

class _SheetTabBar extends StatelessWidget {
  final TabController controller;
  final bool isDark;

  const _SheetTabBar({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller.animation ?? controller,
      builder: (context, _) {
        final idx = controller.animation?.value.round() ?? controller.index;
        return Container(
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceElevatedDark : AppColors.borderLight,
            borderRadius: BorderRadius.circular(AppRadius.input),
          ),
          child: TabBar(
            controller: controller,
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.input),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
                  blurRadius: isDark ? 14 : 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            splashFactory: NoSplash.splashFactory,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            tabs: [
              _TabLabel(label: 'Músicas', selected: idx == 0, isDark: isDark),
              _TabLabel(label: 'Medleys', selected: idx == 1, isDark: isDark),
            ],
          ),
        );
      },
    );
  }
}

class _TabLabel extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isDark;

  const _TabLabel({
    required this.label,
    required this.selected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tab(
      height: 38,
      child: Text(
        label,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          color: selected
              ? theme.colorScheme.primary
              : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Songs tab
// ---------------------------------------------------------------------------

class _SongsTab extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;

  const _SongsTab({
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onClearSearch,
  });

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

        return Column(
          children: [
            Builder(
              builder: (context) {
                final cs = Theme.of(context).colorScheme;
                return TextField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Buscar por título ou artista...',
                    hintStyle: TextStyle(color: cs.onSurfaceVariant),
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: onClearSearch,
                          )
                        : null,
                    filled: true,
                    fillColor: cs.surfaceContainerLow,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.input),
                      borderSide: BorderSide(color: cs.outlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.input),
                      borderSide: BorderSide(color: cs.outlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.input),
                      borderSide: BorderSide(color: cs.primary, width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.input),
                      borderSide: BorderSide(color: cs.error),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.input),
                      borderSide: BorderSide(color: cs.error, width: 1.5),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Expanded(
              child: state.isLoading
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
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Medleys tab
// ---------------------------------------------------------------------------

class _MedleysTab extends StatelessWidget {
  const _MedleysTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ManageEventSongsCubit, ManageEventSongsState>(
      builder: (context, state) {
        final cubit = context.read<ManageEventSongsCubit>();

        if (state.isLoadingMedleys) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.medleys.isEmpty) {
          return const _EmptyMedleysState();
        }

        return ListView.builder(
          itemCount: state.medleys.length,
          itemBuilder: (context, index) {
            final medley = state.medleys[index];
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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
                color: isSelected
                    ? (isDark
                          ? AppColors.primarySubtleDark
                          : AppColors.primarySubtleLight)
                    : (isDark ? AppColors.surfaceDark : Colors.white),
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark
                            ? AppColors.borderStrongDark
                            : AppColors.borderLight),
                  width: isSelected ? 1.6 : 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceElevatedDark
                            : AppColors.surfaceSubtleLight,
                        borderRadius: BorderRadius.circular(AppRadius.input),
                      ),
                      child: Icon(
                        Icons.queue_music_rounded,
                        color: isSelected
                            ? AppColors.primary
                            : subtitleColor,
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
                              fontWeight: FontWeight.w800,
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
                              color: isDark
                                  ? AppColors.scaffoldDark
                                  : AppColors.surfaceElevatedLight,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.borderSubtleDark
                                    : AppColors.borderLight,
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
                color: isSelected
                    ? (isDark
                          ? AppColors.primarySubtleDark
                          : AppColors.primarySubtleLight)
                    : (isDark ? AppColors.surfaceDark : Colors.white),
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark
                            ? AppColors.borderStrongDark
                            : AppColors.borderLight),
                  width: isSelected ? 1.6 : 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        YoutubeUtils.getThumbnail(song.youTubeUrl),
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 72,
                          height: 72,
                          color: isDark
                              ? AppColors.surfaceElevatedDark
                              : AppColors.borderLight,
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
                              fontWeight: FontWeight.w800,
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
  final IconData? icon;
  final String label;

  const _MetaBadge({this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodySmall?.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? AppColors.scaffoldDark : AppColors.surfaceElevatedLight,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: isDark ? AppColors.borderSubtleDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor?.withValues(alpha: 0.78)),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: textColor,
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
            Icon(Icons.queue_music_rounded, size: 44, color: subtitleColor),
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

class _InlineErrorMessage extends StatelessWidget {
  final String message;

  const _InlineErrorMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.dangerSubtleDark : AppColors.dangerSubtleLight,
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(
          color: isDark ? AppColors.dangerBorderDark : AppColors.dangerBorderLight,
        ),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: isDark ? AppColors.dangerTextDark : AppColors.dangerTextLight,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
