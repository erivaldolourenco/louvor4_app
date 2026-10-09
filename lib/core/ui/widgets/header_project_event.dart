import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'app_cached_network_image.dart';
import '../../theme/app_radius.dart';
import '../../utils/url_utils.dart';

class HeaderProjectEvent extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final String? backgroundImageUrl;

  /// `true` quando o header já está colapsado no tamanho fixo (a imagem de
  /// capa não está mais visível, só o fundo `cs.surface`) — nesse caso o
  /// texto precisa de uma cor escura para continuar legível.
  final bool isCollapsed;

  /// Quando informado, o título fica centralizado com um chevron para baixo
  /// e vira clicável (ex.: abrir o seletor de projeto).
  final VoidCallback? onTitleTap;

  const HeaderProjectEvent({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.backgroundImageUrl,
    this.isCollapsed = false,
    this.onTitleTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final foregroundColor = isCollapsed ? cs.onSurface : cs.onPrimary;
    final isTappable = onTitleTap != null;
    final titleText = Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.titleMedium?.copyWith(
        color: foregroundColor,
        fontWeight: FontWeight.w700,
        fontSize: 20,
      ),
    );
    final titleColumn = Column(
      crossAxisAlignment: isTappable
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isTappable)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: titleText),
              const SizedBox(width: 4),
              SvgPicture.asset(
                'assets/icons/chevron-down.svg',
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(foregroundColor, BlendMode.srcIn),
              ),
            ],
          )
        else
          titleText,
        if (subtitle != null)
          Text(
            subtitle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: foregroundColor.withValues(alpha: 0.85),
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
    return SliverAppBar(
      expandedHeight: 64,
      pinned: true,
      stretch: true,
      backgroundColor: cs.surface,
      foregroundColor: foregroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: isTappable,
      titleSpacing: 20,
      title: isTappable
          ? InkWell(
              onTap: onTitleTap,
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: titleColumn,
              ),
            )
          : titleColumn,
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
