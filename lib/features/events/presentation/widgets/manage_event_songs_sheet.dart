import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:louvor4_app/features/songs/domain/entities/song_entity.dart';

import '../../../../core/ui/app_feedback.dart';
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
          create: (ctx) => ManageEventSongsCubit(ctx.read<EventsRepository>())..load(),
          child: _ManageEventSongsSheet(eventId: eventId),
        ),
      );
    },
  );
}

class _ManageEventSongsSheet extends StatelessWidget {
  final String eventId;

  const _ManageEventSongsSheet({required this.eventId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Material(
        color: Colors.white,
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
                            color: const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Nova música',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Selecione uma ou mais músicas do seu catálogo para adicionar ao evento.',
                        style: TextStyle(fontSize: 14, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 18),
                      if (state.errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _InlineErrorMessage(message: state.errorMessage!),
                        ),
                      Expanded(
                        child: state.isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : state.songs.isEmpty
                            ? const _EmptySongsState()
                            : ListView.builder(
                                itemCount: state.songs.length,
                                itemBuilder: (context, index) {
                                  final song = state.songs[index];
                                  final isSelected =
                                      state.selectedSongIds.contains(song.id);
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
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: state.isSubmitting || !state.hasSelection
                              ? null
                              : () => cubit.submit(eventId),
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
                color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF2563EB)
                      : const Color(0xFFE2E8F0),
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
                          color: const Color(0xFFE2E8F0),
                          child: const Icon(
                            Icons.music_note_rounded,
                            color: Color(0xFF64748B),
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
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _MetaBadge(
                                icon: Icons.piano_rounded,
                                label: song.key,
                              ),
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
                      onChanged: enabled && onTap != null ? (_) => onTap!() : null,
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
  final IconData icon;
  final String label;

  const _MetaBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF64748B)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
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
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.library_music_outlined,
              size: 44,
              color: Color(0xFF94A3B8),
            ),
            SizedBox(height: 10),
            Text(
              'Nenhuma música cadastrada',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Cadastre músicas na sua biblioteca para adicioná-las ao repertório do evento.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B)),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFF991B1B),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
