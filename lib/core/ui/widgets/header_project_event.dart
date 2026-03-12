import 'package:flutter/material.dart';

import '../../utils/url_utils.dart';

class HeaderProjectEvent extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final String? backgroundImageUrl;
  final Widget? backgroundOverlay;

  const HeaderProjectEvent({
    super.key,
    required this.title,
    this.actions,
    this.backgroundImageUrl,
    this.backgroundOverlay,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 86,
      pinned: true,
      stretch: true,
      backgroundColor: const Color(0xFF0F172A),
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: 20,
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 24,
        ),
      ),
      actions: actions,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (UrlUtils.isValidNetworkUrl(backgroundImageUrl))
              Image.network(backgroundImageUrl!, fit: BoxFit.cover)
            else
              Container(
                color: const Color(0xFF0F172A),
                child: const Center(
                  child: Icon(
                    Icons.multitrack_audio_rounded,
                    color: Colors.white70,
                    size: 58,
                  ),
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
            // ignore: use_null_aware_elements
            if (backgroundOverlay case final overlay?) overlay,
          ],
        ),
      ),
    );
  }
}
