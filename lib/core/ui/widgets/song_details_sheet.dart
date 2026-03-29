import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_feedback.dart';
import 'app_card_surface.dart';

Future<void> showSongDetailsModal(
  BuildContext context, {
  required String title,
  required String artist,
  String? musicKey,
  String? bpm,
  required String youTubeUrl,
  String? notes,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return SongDetailsSheet(
        title: title,
        artist: artist,
        musicKey: musicKey,
        bpm: bpm,
        youTubeUrl: youTubeUrl,
        notes: notes,
      );
    },
  );
}

class SongDetailsSheet extends StatelessWidget {
  final String title;
  final String artist;
  final String? musicKey;
  final String? bpm;
  final String youTubeUrl;
  final String? notes;

  const SongDetailsSheet({
    super.key,
    required this.title,
    required this.artist,
    this.musicKey,
    this.bpm,
    required this.youTubeUrl,
    this.notes,
  });

  Future<void> _openYouTube(BuildContext context) async {
    final uri = Uri.tryParse(youTubeUrl);
    if (uri == null) {
      AppFeedback.showError('URL do YouTube inválida.');
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      AppFeedback.showError('Não foi possível abrir o YouTube.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleColor = theme.textTheme.titleLarge?.color;
    final subtitleColor = theme.textTheme.bodyMedium?.color?.withValues(
      alpha: 0.78,
    );
    final normalizedKey = musicKey?.trim();
    final normalizedBpm = bpm?.trim();
    final normalizedNotes = notes?.trim();
    final hasKey = normalizedKey != null && normalizedKey.isNotEmpty;
    final hasBpm = normalizedBpm != null && normalizedBpm.isNotEmpty;
    final hasNotes = normalizedNotes != null && normalizedNotes.isNotEmpty;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.82,
          ),
          child: AppCardSurface(
            radius: 28,
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: titleColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            artist,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w600,
                              color: subtitleColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Fechar',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                AppCardSurface(
                  radius: 20,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tom e BPM',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (!hasKey && !hasBpm)
                        Text(
                          'Sem informações adicionais de tom ou BPM.',
                          style: TextStyle(color: subtitleColor, height: 1.45),
                        )
                      else
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            if (hasKey)
                              _MetaBadge(label: 'Tom: $normalizedKey'),
                            if (hasBpm) _MetaBadge(label: '$normalizedBpm BPM'),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: AppCardSurface(
                    radius: 20,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Observações',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Text(
                              hasNotes
                                  ? normalizedNotes
                                  : 'Esta música não possui observações.',
                              style: TextStyle(
                                color: subtitleColor,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: youTubeUrl.trim().isEmpty
                      ? null
                      : () => _openYouTube(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE11D48),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: const Icon(Icons.ondemand_video_rounded),
                  label: const Text(
                    'Abrir no YouTube',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  final String label;

  const _MetaBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF172554) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
