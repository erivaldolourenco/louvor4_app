import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:louvor4_app/core/ui/widgets/app_cached_network_image.dart';
import 'package:louvor4_app/core/ui/widgets/app_card_surface.dart';
import 'package:louvor4_app/core/ui/widgets/spring_tap.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../domain/entities/event_entity.dart';
import '../pages/event_detail_page.dart';

class EventListCard extends StatelessWidget {
  final EventEntity event;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final bool showTimelineRail;
  final double bottomSpacing;
  final bool isNext;

  const EventListCard({
    super.key,
    required this.event,
    this.isFirstInGroup = false,
    this.isLastInGroup = false,
    this.showTimelineRail = true,
    this.bottomSpacing = 10,
    this.isNext = false,
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
                radius: AppRadius.cardHero,
                color: isDark ? cs.surfaceContainerLow : cs.surfaceContainerLowest,
                borderColor: isNext ? cs.primary : cs.outlineVariant,
                boxShadow: isNext
                    ? [
                        BoxShadow(
                          color: cs.primary.withValues(
                            alpha: isDark ? 0.22 : 0.16,
                          ),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
                child: SpringTap(
                  pressedScale: 0.97,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EventDetailPage(eventId: event.id),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(
                                AppRadius.thumbnail,
                              ),
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
                                          Icons.music_note_rounded,
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
                                        Icons.music_note_rounded,
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
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          color: cs.onSurface,
                                          fontWeight: FontWeight.w700,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    (event.description?.isNotEmpty ?? false)
                                        ? '$timeDisplay • ${event.description}'
                                        : timeDisplay,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontSize: 13,
                                      color: cs.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (event
                                          .participantsProfileImages
                                          .isNotEmpty ||
                                      event.participantsCount > 0 ||
                                      event.repertoireCount > 0) ...[
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      height: 24,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child:
                                                event
                                                    .participantsProfileImages
                                                    .isNotEmpty
                                                ? Stack(
                                                    children: List.generate(
                                                      event
                                                                  .participantsProfileImages
                                                                  .length >
                                                              5
                                                          ? 5
                                                          : event
                                                                .participantsProfileImages
                                                                .length,
                                                      (index) => Positioned(
                                                        left: index * 14.0,
                                                        child: Container(
                                                          decoration: BoxDecoration(
                                                            shape:
                                                                BoxShape.circle,
                                                            border: Border.all(
                                                              color:
                                                                  cs.surface,
                                                              width: 1.5,
                                                            ),
                                                          ),
                                                          child: CircleAvatar(
                                                            radius: 11,
                                                            backgroundColor: isDark
                                                                ? cs
                                                                      .surfaceContainerLow
                                                                : cs
                                                                      .outlineVariant,
                                                            backgroundImage: appCachedImageProvider(
                                                              event
                                                                  .participantsProfileImages[index],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                : const SizedBox.shrink(),
                                          ),
                                          if (event.participantsCount > 0) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 7,
                                                vertical: 3,
                                              ),
                                              decoration: BoxDecoration(
                                                color: cs.surfaceContainerHigh,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      AppRadius.pill,
                                                    ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  SvgPicture.asset(
                                                    'assets/icons/users-round.svg',
                                                    width: 13,
                                                    height: 13,
                                                    colorFilter: ColorFilter.mode(
                                                      cs.primary,
                                                      BlendMode.srcIn,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${event.participantsCount}',
                                                    style: theme
                                                        .textTheme
                                                        .labelMedium
                                                        ?.copyWith(
                                                          color: cs.primary,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                          if (event.repertoireCount > 0) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 7,
                                                vertical: 3,
                                              ),
                                              decoration: BoxDecoration(
                                                color: cs.surfaceContainerHigh,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      AppRadius.pill,
                                                    ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  SvgPicture.asset(
                                                    'assets/icons/music.svg',
                                                    width: 13,
                                                    height: 13,
                                                    colorFilter: ColorFilter.mode(
                                                      cs.primary,
                                                      BlendMode.srcIn,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${event.repertoireCount}',
                                                    style: theme
                                                        .textTheme
                                                        .labelMedium
                                                        ?.copyWith(
                                                          color: cs.primary,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: cs.onSurfaceVariant,
                            ),
                          ],
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
