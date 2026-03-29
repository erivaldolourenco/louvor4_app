import 'package:flutter/material.dart';
import 'package:louvor4_app/core/ui/widgets/app_cached_network_image.dart';
import 'package:louvor4_app/core/ui/widgets/app_card_surface.dart';

import '../../domain/entities/event_entity.dart';
import '../pages/event_detail_page.dart';

class EventListCard extends StatelessWidget {
  final EventEntity event;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final bool showTimelineRail;
  final double bottomSpacing;

  const EventListCard({
    super.key,
    required this.event,
    this.isFirstInGroup = false,
    this.isLastInGroup = false,
    this.showTimelineRail = true,
    this.bottomSpacing = 10,
  });

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF0166FF);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final timeDisplay = event.time.length >= 5
        ? event.time.substring(0, 5)
        : event.time;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomSpacing),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showTimelineRail) ...[
              SizedBox(
                width: 22,
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        width: 2,
                        color: isFirstInGroup
                            ? Colors.transparent
                            : (isDark
                                  ? const Color(0xFF475569)
                                  : const Color(0xFFE2E8F0)),
                      ),
                    ),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryBlue,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        width: 2,
                        color: isLastInGroup
                            ? Colors.transparent
                            : (isDark
                                  ? const Color(0xFF475569)
                                  : const Color(0xFFE2E8F0)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: AppCardSurface(
                radius: 16,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EventDetailPage(eventId: event.id),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child:
                              (event.projectImageUrl != null &&
                                  event.projectImageUrl!.isNotEmpty)
                              ? AppCachedNetworkImage(
                                  imageUrl: event.projectImageUrl!,
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  errorWidget: Container(
                                    width: 70,
                                    height: 70,
                                    color: isDark
                                        ? const Color(0xFF1E293B)
                                        : const Color(0xFFEFF6FF),
                                    child: const Icon(
                                      Icons.music_note,
                                      color: primaryBlue,
                                      size: 30,
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 70,
                                  height: 70,
                                  color: isDark
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFFEFF6FF),
                                  child: const Icon(
                                    Icons.music_note,
                                    color: primaryBlue,
                                    size: 30,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                event.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: isDark
                                      ? const Color(0xFFF8FAFC)
                                      : const Color(0xFF1E293B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$timeDisplay • ${event.location ?? 'Local não informado'}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? const Color(0xFFCBD5E1)
                                      : const Color(0xFF475569),
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (event
                                  .participantsProfileImages
                                  .isNotEmpty) ...[
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 22,
                                  child: Stack(
                                    children: List.generate(
                                      event.participantsProfileImages.length > 5
                                          ? 5
                                          : event
                                                .participantsProfileImages
                                                .length,
                                      (index) => Positioned(
                                        left: index * 14.0,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isDark
                                                  ? const Color(0xFF111827)
                                                  : Colors.white,
                                              width: 1.5,
                                            ),
                                          ),
                                          child: CircleAvatar(
                                            radius: 10,
                                            backgroundColor: isDark
                                                ? const Color(0xFF334155)
                                                : const Color(0xFFE2E8F0),
                                            backgroundImage: appCachedImageProvider(
                                              event
                                                  .participantsProfileImages[index],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: isDark
                              ? const Color(0xFF64748B)
                              : const Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
