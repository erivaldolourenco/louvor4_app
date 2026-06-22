import 'package:flutter/material.dart';
import 'package:louvor4_app/core/ui/widgets/app_cached_network_image.dart';
import 'package:louvor4_app/core/ui/widgets/app_card_surface.dart';

import '../../../../../core/theme/app_radius.dart';
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
    final theme = Theme.of(context);
  final cs = theme.colorScheme;
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
                                  ? cs.onSurfaceVariant
                                  : cs.outlineVariant),
                      ),
                    ),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cs.primary,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        width: 2,
                        color: isLastInGroup
                            ? Colors.transparent
                            : (isDark
                                  ? cs.onSurfaceVariant
                                  : cs.outlineVariant),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: AppCardSurface(
                radius: AppRadius.card,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.card),
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
                          borderRadius: BorderRadius.circular(AppRadius.input),
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
                                        ? cs.surfaceContainer
                                        : cs.primaryContainer,
                                    child: Icon(
                                      Icons.music_note,
                                      color: cs.primary,
                                      size: 30,
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 70,
                                  height: 70,
                                  color: isDark
                                      ? cs.surfaceContainer
                                      : cs.primaryContainer,
                                  child: Icon(
                                    Icons.music_note,
                                    color: cs.primary,
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
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: isDark
                                      ? cs.surfaceContainer
                                      : cs.surfaceContainer,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$timeDisplay • ${event.location ?? 'Local não informado'}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 13,
                                  color: isDark
                                      ? cs.outlineVariant
                                      : cs.onSurfaceVariant,
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
                                              color: cs.surface,
                                              width: 1.5,
                                            ),
                                          ),
                                          child: CircleAvatar(
                                            radius: 10,
                                            backgroundColor: isDark
                                                ? cs.surfaceContainerLow
                                                : cs.outlineVariant,
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
                              ? cs.onSurfaceVariant
                              : cs.onSurfaceVariant,
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
