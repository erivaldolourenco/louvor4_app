import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'app_cached_network_image.dart';
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
    return SliverAppBar(
      expandedHeight: 64,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.scaffoldDark,
      foregroundColor: Colors.white,
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
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
        ],
      ),
      actions: actions,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (UrlUtils.isValidNetworkUrl(backgroundImageUrl))
              AppCachedNetworkImage(imageUrl: backgroundImageUrl!, fit: BoxFit.cover)
            else
              Container(
                color: AppColors.scaffoldDark,
                child: const Center(
                  child: Icon(Icons.multitrack_audio_rounded, color: Colors.white70, size: 58),
                ),
              ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x8A000000), Color(0xCC000000)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
