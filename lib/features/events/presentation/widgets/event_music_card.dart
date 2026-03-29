import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:louvor4_app/core/ui/widgets/app_card_surface.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/utils/youtube_utils.dart';

class EventMusicCard extends StatelessWidget {
  final String eventSongId;
  final String title;
  final String artist;
  final String musicKey;
  final int? bpm;
  final String? youtubeUrl;
  final VoidCallback? onTap;
  final bool canRemove;
  final bool isRemoving;
  final Future<bool> Function()? onRemove;

  const EventMusicCard({
    super.key,
    required this.eventSongId,
    required this.title,
    required this.artist,
    required this.musicKey,
    this.bpm,
    this.youtubeUrl,
    this.onTap,
    this.canRemove = false,
    this.isRemoving = false,
    this.onRemove,
  });

  Future<void> _launchYoutube() async {
    if (youtubeUrl == null || youtubeUrl!.isEmpty) return;

    final Uri url = Uri.parse(youtubeUrl!);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
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
    Widget cardContent = AppCardSurface(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: youtubeUrl != null && youtubeUrl!.isNotEmpty
                    ? NetworkImage(YoutubeUtils.getThumbnail(youtubeUrl!))
                    : const AssetImage('assets/images/default-cover.png')
                          as ImageProvider,
                fit: BoxFit.cover,
              ),
            ),
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
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetaChip(
                      label: 'Tom: ${musicKey.isEmpty ? "-" : musicKey}',
                    ),
                    if (bpm != null) _MetaChip(label: '$bpm BPM'),
                  ],
                ),
              ],
            ),
          ),
          if (youtubeUrl != null && youtubeUrl!.isNotEmpty)
            _CircularActionButton(
              onPressed: _launchYoutube,
              assetPath: 'assets/icons/youtube.svg',
              iconColor: const Color(0xFFDC2626),
              backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
              borderColor: isDark
                  ? const Color(0xFF7F1D1D)
                  : const Color(0xFFFECDD3),
            ),
          if (canRemove && isRemoving)
            const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
    );

    if (canRemove && onRemove != null) {
      cardContent = Dismissible(
        key: Key(eventSongId),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) => onRemove!(),
        background: Container(
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFB3261E),
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: const Icon(
            Icons.delete_outline,
            color: Colors.white,
            size: 28,
          ),
        ),
        child: cardContent,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: cardContent,
        ),
      ),
    );
  }
}

class _CircularActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String assetPath;
  final Color iconColor;
  final Color backgroundColor;
  final Color borderColor;

  const _CircularActionButton({
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

class _MetaChip extends StatelessWidget {
  final String label;

  const _MetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final subtitleColor = theme.textTheme.bodySmall?.color?.withValues(
      alpha: 0.78,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: subtitleColor,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
