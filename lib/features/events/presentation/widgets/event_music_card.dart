import 'package:flutter/material.dart';
import 'package:louvor4_app/core/ui/widgets/app_card_surface.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/utils/youtube_utils.dart';

class EventMusicCard extends StatelessWidget {
  final String eventSongId;
  final String title;
  final String artist;
  final String musicKey;
  final String addedBy;
  final String? youtubeUrl;
  final bool canRemove;
  final bool isRemoving;
  final VoidCallback? onRemove;
  const EventMusicCard({
    super.key,
    required this.eventSongId,
    required this.title,
    required this.artist,
    required this.musicKey,
    required this.addedBy,
    this.youtubeUrl,
    this.canRemove = false,
    this.isRemoving = false,
    this.onRemove,
  });

  Future<void> _launchYoutube() async {
    if (youtubeUrl == null || youtubeUrl!.isEmpty) return;

    final Uri url = Uri.parse(youtubeUrl!);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // Opcional: Mostrar um alerta caso o link seja inválido
      debugPrint('Não foi possível abrir o link: $youtubeUrl');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = theme.textTheme.titleMedium?.color;
    final subtitleColor = theme.textTheme.bodySmall?.color?.withValues(
      alpha: 0.78,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCardSurface(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip
                  .none, // Permite que o badge do tom saia um pouco da borda
              children: [
                // 1. O CONTAINER DA CAPA (THUMBNAIL)
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      // Aqui usamos a função que você trouxe do Angular adaptada para Dart
                      image: youtubeUrl != null && youtubeUrl!.isNotEmpty
                          ? NetworkImage(YoutubeUtils.getThumbnail(youtubeUrl))
                          : const AssetImage('assets/images/default-cover.png')
                                as ImageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // 2. O BADGE DO TOM DA MÚSICA (KEY)
                Positioned(
                  top: -5,
                  right: -5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0166FF),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isDark ? const Color(0xFF111827) : Colors.white,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      musicKey,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: titleColor,
                    ),
                  ),
                  Text(
                    artist,
                    style: TextStyle(color: subtitleColor, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Text(
                      'Por: ${_toCapitalizedWords(addedBy)}',
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (youtubeUrl != null && youtubeUrl!.isNotEmpty)
              IconButton(
                onPressed: _launchYoutube,
                icon: const Icon(
                  Icons.play_circle_filled,
                  color: Color(0xFFFF0000),
                  size: 32,
                ),
              ),
            if (canRemove)
              isRemoving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      onPressed: onRemove,
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Color(0xFFB3261E),
                      ),
                    ),
          ],
        ),
      ),
    );
  }

  String _toCapitalizedWords(String value) {
    final words = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty);

    return words
        .map(
          (word) => word.length == 1
              ? word.toUpperCase()
              : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}
