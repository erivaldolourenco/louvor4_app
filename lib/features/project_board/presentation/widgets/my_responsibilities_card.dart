import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/ui/widgets/app_cached_network_image.dart';
import '../../../../core/ui/widgets/app_card_surface.dart';
import '../../../../core/utils/url_utils.dart';
import '../../domain/entities/my_responsibility_entity.dart';
import 'responsibility_dates.dart';

/// Card "Suas responsabilidades" da tela de Início.
class MyResponsibilitiesCard extends StatelessWidget {
  final List<MyResponsibilityEntity> responsibilities;
  final ValueChanged<MyResponsibilityEntity> onTap;

  const MyResponsibilitiesCard({
    super.key,
    required this.responsibilities,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return DecoratedBox(
      decoration: appCardDecoration(
        context,
        radius: AppRadius.cardHero,
        color: cs.primaryContainer.withValues(alpha: 0.35),
        borderColor: cs.primary.withValues(alpha: 0.35),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/icons/square-kanban.svg',
                    width: 18,
                    height: 18,
                    colorFilter: ColorFilter.mode(cs.primary, BlendMode.srcIn),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Suas responsabilidades',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            for (final item in responsibilities)
              _ResponsibilityRow(item: item, onTap: () => onTap(item)),
          ],
        ),
      ),
    );
  }
}

class _ResponsibilityRow extends StatelessWidget {
  final MyResponsibilityEntity item;
  final VoidCallback onTap;

  const _ResponsibilityRow({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final periodLabel = item.current
        ? 'até ${formatShortDate(item.endDate)}'
        : 'a partir de ${formatShortDate(item.startDate)}';
    final description = item.responsibilityDescription?.trim() ?? '';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 10, 8),
        child: Row(
          children: [
            _ProjectCover(imageUrl: item.projectImage),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.responsibilityName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (description.isNotEmpty)
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: item.current
                    ? cs.primaryContainer
                    : cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                periodLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: item.current
                      ? cs.onPrimaryContainer
                      : cs.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

/// Capa do projeto da responsabilidade, com ícone de fallback quando o
/// projeto não tem imagem.
class _ProjectCover extends StatelessWidget {
  final String? imageUrl;

  const _ProjectCover({required this.imageUrl});

  static const double _size = 44;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fallback = Container(
      width: _size,
      height: _size,
      color: cs.primaryContainer,
      alignment: Alignment.center,
      child: SvgPicture.asset(
        'assets/icons/square-kanban.svg',
        width: 20,
        height: 20,
        colorFilter: ColorFilter.mode(cs.onPrimaryContainer, BlendMode.srcIn),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: UrlUtils.isValidNetworkUrl(imageUrl)
          ? AppCachedNetworkImage(
              imageUrl: imageUrl!,
              width: _size,
              height: _size,
              errorWidget: fallback,
            )
          : fallback,
    );
  }
}
