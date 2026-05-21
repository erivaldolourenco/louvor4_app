import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../utils/youtube_utils.dart';
import 'app_card_surface.dart';
import 'app_circular_action_button.dart';

class SongListCard extends StatelessWidget {
  final String title;
  final String? artist;
  final String? musicKey;
  final String? bpm;
  final String? youTubeUrl;
  final bool isMedley;
  final VoidCallback? onTap;
  final VoidCallback? onOpenYoutube;
  final VoidCallback? onEdit;
  final Future<bool> Function()? onRemove;
  final bool isRemoving;
  final String? dismissKey;

  const SongListCard({
    super.key,
    required this.title,
    this.artist,
    this.musicKey,
    this.bpm,
    this.youTubeUrl,
    this.isMedley = false,
    this.onTap,
    this.onOpenYoutube,
    this.onEdit,
    this.onRemove,
    this.isRemoving = false,
    this.dismissKey,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mutedColor = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    Widget cardContent = AppCardSurface(
      radius: 22,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _Thumbnail(
              youTubeUrl: youTubeUrl,
              isMedley: isMedley,
              isDark: isDark,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (artist != null && artist!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      artist!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600,
                        color: mutedColor,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  _Badges(
                    isMedley: isMedley,
                    musicKey: musicKey,
                    bpm: bpm,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _Actions(
              isMedley: isMedley,
              isRemoving: isRemoving,
              onOpenYoutube: onOpenYoutube,
              onEdit: onEdit,
            ),
          ],
        ),
      ),
    );

    if (onRemove != null) {
      cardContent = Dismissible(
        key: ValueKey(dismissKey ?? title),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) => onRemove!(),
        background: Container(
          decoration: BoxDecoration(
            color: AppColors.danger,
            borderRadius: BorderRadius.circular(22),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
        ),
        child: cardContent,
      );
    }

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: cardContent,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _Thumbnail extends StatelessWidget {
  final String? youTubeUrl;
  final bool isMedley;
  final bool isDark;

  const _Thumbnail({
    required this.youTubeUrl,
    required this.isMedley,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (isMedley) {
      return Container(
        width: 82,
        height: 82,
        decoration: BoxDecoration(
          color: isDark ? AppColors.warningSubtleDark : AppColors.warningSubtleLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: Icon(Icons.queue_music_rounded, color: AppColors.warning, size: 36),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        YoutubeUtils.getThumbnail(youTubeUrl, quality: 'default'),
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
    );
  }
}

class _Badges extends StatelessWidget {
  final bool isMedley;
  final String? musicKey;
  final String? bpm;
  final bool isDark;

  const _Badges({
    required this.isMedley,
    required this.musicKey,
    required this.bpm,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (isMedley) {
      return _Badge(
        label: 'Medley',
        textColor: AppColors.warning,
        backgroundColor: isDark ? AppColors.warningSubtleDark : AppColors.warningSubtleLight,
        borderColor: isDark ? const Color(0xFF78350F) : const Color(0xFFFDE68A),
      );
    }

    return Row(
      children: [
        _Badge(
          label: 'Tom: ${musicKey?.isNotEmpty == true ? musicKey : '-'}',
          isDark: isDark,
        ),
        if (bpm != null && bpm!.isNotEmpty) ...[
          const SizedBox(width: 8),
          _Badge(
            icon: Icons.speed_rounded,
            label: '$bpm BPM',
            isDark: isDark,
          ),
        ],
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color? textColor;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool isDark;

  const _Badge({
    required this.label,
    this.icon,
    this.textColor,
    this.backgroundColor,
    this.borderColor,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ??
        (isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceSubtleLight);
    final border = borderColor ??
        (isDark ? AppColors.borderSubtleDark : AppColors.borderLight);
    final fg = textColor ??
        (isDark ? AppColors.textMutedDark : AppColors.textSubtleDark);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  final bool isMedley;
  final bool isRemoving;
  final VoidCallback? onOpenYoutube;
  final VoidCallback? onEdit;

  const _Actions({
    required this.isMedley,
    required this.isRemoving,
    required this.onOpenYoutube,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    if (isRemoving) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    final hasYoutube = !isMedley && onOpenYoutube != null;
    final hasEdit = onEdit != null;

    if (!hasYoutube && !hasEdit) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasYoutube)
          AppCircularActionButton(
            onPressed: onOpenYoutube,
            assetPath: 'assets/icons/youtube.svg',
            iconColor: const Color(0xFFDC2626),
            backgroundColor: const Color(0xFFFEF2F2),
            borderColor: const Color(0xFFFECACA),
          ),
        if (hasYoutube && hasEdit) const SizedBox(width: 8),
        if (hasEdit)
          AppCircularActionButton(
            onPressed: onEdit,
            assetPath: 'assets/icons/file-music.svg',
            iconColor: AppColors.primary,
            backgroundColor: AppColors.primarySubtleLight,
            borderColor: AppColors.primaryBorderLight,
          ),
      ],
    );
  }
}
