import 'package:flutter/material.dart';

import 'app_cached_network_image.dart';
import '../../theme/app_radius.dart';
import '../../utils/url_utils.dart';

class HeaderProjectEvent extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final String? backgroundImageUrl;

  const HeaderProjectEvent({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.backgroundImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return SliverAppBar(
      expandedHeight: 64,
      pinned: true,
      stretch: true,
      backgroundColor: cs.surface,
      foregroundColor: cs.onPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: 20,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              color: cs.onPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onPrimary.withValues(alpha: 0.85),
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
      actions: actions,
      flexibleSpace: ClipRRect(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppRadius.cardLarge),
          bottomRight: Radius.circular(AppRadius.cardLarge),
        ),
        child: FlexibleSpaceBar(
          background: Stack(
            fit: StackFit.expand,
            children: [
              if (UrlUtils.isValidNetworkUrl(backgroundImageUrl))
                AppCachedNetworkImage(
                  imageUrl: backgroundImageUrl!,
                  fit: BoxFit.cover,
                )
              else
                Container(
                  color: cs.primaryContainer,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cs.primary.withValues(alpha: 0.12),
                      ),
                      child: Icon(
                        Icons.multitrack_audio_rounded,
                        color: cs.onPrimaryContainer.withValues(alpha: 0.7),
                        size: 40,
                      ),
                    ),
                  ),
                ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      cs.primary.withValues(alpha: 0.0),
                      cs.scrim.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
