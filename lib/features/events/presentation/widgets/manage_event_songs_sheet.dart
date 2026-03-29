import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:louvor4_app/features/songs/domain/entities/song_entity.dart';

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
      return RepositoryProvider.value(
        value: context.read<EventsRepository>(),
        child: BlocProvider(
          create: (ctx) =>
              ManageEventSongsCubit(ctx.read<EventsRepository>())..load(),
          child: _ManageEventSongsSheet(eventId: eventId),
        ),
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

class _ManageEventSongsSheetState extends State<_ManageEventSongsSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = theme.textTheme.titleLarge?.color;
    final subtitleColor = theme.textTheme.bodyMedium?.color?.withValues(
      alpha: 0.78,
    );

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Material(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.82,
            ),
            child: BlocConsumer<ManageEventSongsCubit, ManageEventSongsState>(
              listenWhen: (previous, current) =>
                  previous.status != current.status &&
                  current.status == ManageEventSongsStatus.success,
              listener: (context, state) {
                AppFeedback.showSuccess('Músicas adicionadas ao repertório.');
                Navigator.of(context).pop(true);
              },
              builder: (context, state) {
                final cubit = context.read<ManageEventSongsCubit>();

                final filteredSongs = state.songs.where((song) {
                  final query = _searchQuery.toLowerCase();
                  final title = song.title.toLowerCase();
                  final artist = song.artist.toLowerCase();
                  return title.contains(query) || artist.contains(query);
                }).toList();

                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 5,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Nova música',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Selecione uma ou mais músicas do seu catálogo para adicionar ao evento.',
                        style: TextStyle(fontSize: 14, color: subtitleColor),
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _searchController,
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
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
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (state.errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _InlineErrorMessage(
                            message: state.errorMessage!,
                          ),
                        ),
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
                                  final isSelected = state.selectedSongIds
                                      .contains(song.id);
                                  return _SelectableSongCard(
                                    song: song,
                                    isSelected: isSelected,
                                    enabled: !state.isSubmitting,
                                    onTap: song.id == null
                                        ? null
                                        : () => cubit.toggleSong(song.id!),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: appPrimaryPillButtonStyle(context),
                          onPressed: state.isSubmitting || !state.hasSelection
                              ? null
                              : () => cubit.submit(widget.eventId),
                          child: state.isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Adicionar Selecionadas (${state.selectedSongIds.length})',
                                ),
                        ),
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
    final subtitleColor = theme.textTheme.bodySmall?.color?.withValues(
      alpha: 0.78,
    );
    return Opacity(
      opacity: enabled ? 1 : 0.72,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: enabled ? onTap : null,
            child: Ink(
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark
                          ? const Color(0xFF172554)
                          : const Color(0xFFEFF6FF))
                    : (isDark ? const Color(0xFF111827) : Colors.white),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF2563EB)
                      : (isDark
                            ? const Color(0xFF243041)
                            : const Color(0xFFE2E8F0)),
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
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFE2E8F0),
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
                            style: TextStyle(
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
                      onChanged: enabled && onTap != null
                          ? (_) => onTap!()
                          : null,
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
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
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
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
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
    final subtitleColor = Theme.of(
      context,
    ).textTheme.bodySmall?.color?.withValues(alpha: 0.78);
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
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Cadastre músicas na sua biblioteca para adicioná-las ao repertório do evento.',
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
        color: isDark ? const Color(0xFF3F1114) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFCA5A5),
        ),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
