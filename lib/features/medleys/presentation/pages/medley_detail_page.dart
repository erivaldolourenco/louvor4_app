import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/ui/app_feedback.dart';
import '../../../../core/ui/widgets/app_card_surface.dart';
import '../../../../core/ui/widgets/fade_slide_in.dart';
import '../../../../core/ui/widgets/reference_audio_player.dart';
import '../../../../core/ui/widgets/standard_section_app_bar.dart';
import '../../../../core/utils/youtube_utils.dart';
import '../../../song_categories/data/impl/song_categories_repository_impl.dart';
import '../../../song_categories/domain/entities/song_category_entity.dart';
import '../../../song_categories/presentation/widgets/category_filter_sheet.dart';
import '../../data/impl/medley_repository_impl.dart';
import '../../domain/entities/medley_entity.dart';
import '../../domain/entities/medley_item_entity.dart';

Future<void> openMedleyDetailPage(
  BuildContext context,
  MedleyEntity medley, {
  VoidCallback? onEdit,
}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => MedleyDetailPage(medley: medley, onEdit: onEdit),
    ),
  );
}

class MedleyDetailPage extends StatelessWidget {
  final MedleyEntity medley;
  final VoidCallback? onEdit;

  const MedleyDetailPage({super.key, required this.medley, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final mutedColor = cs.onSurfaceVariant;
    final count = medley.items.length;
    final hasNotes = medley.notes != null && medley.notes!.isNotEmpty;
    final canEdit = onEdit != null;

    int staggerStep = 0;

    return Scaffold(
      appBar: StandardSectionAppBar(
        title: 'Detalhes do Medley',
        actions: [
          if (onEdit != null)
            IconButton(
              tooltip: 'Editar medley',
              icon: SvgPicture.asset(
                'assets/icons/square-pen.svg',
                width: 22,
                height: 22,
                colorFilter: ColorFilter.mode(cs.primary, BlendMode.srcIn),
              ),
              onPressed: onEdit,
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
          children: [
            // ── Header: ícone + nome + descrição ───────────────
            FadeSlideIn(
              delay: staggerDelay(staggerStep++),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/icons/disc-album.svg',
                        width: 32,
                        height: 32,
                        colorFilter: ColorFilter.mode(
                          cs.onSecondaryContainer,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          medley.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (medley.description != null &&
                            medley.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            medley.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: mutedColor,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          count == 1 ? '1 música' : '$count músicas',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: mutedColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Notas ─────────────────────────────────────────
            if (hasNotes) ...[
              const SizedBox(height: 16),
              FadeSlideIn(
                delay: staggerDelay(staggerStep++),
                child: AppCardSurface(
                  radius: AppRadius.cardLarge,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Observações',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        medley.notes!,
                        style: TextStyle(color: mutedColor, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // ── Categorias (somente dono do medley) ────────────
            if (medley.id != null && canEdit) ...[
              const SizedBox(height: 16),
              FadeSlideIn(
                delay: staggerDelay(staggerStep++),
                child: _MedleyCategoriesQuickEdit(
                  medleyId: medley.id!,
                  initialCategories: medley.categories,
                ),
              ),
            ],

            // ── Áudio de referência ─────────────────────────────
            if (medley.id != null) ...[
              const SizedBox(height: 16),
              FadeSlideIn(
                delay: staggerDelay(staggerStep++),
                child: _MedleyReferenceAudioQuickEdit(
                  medleyId: medley.id!,
                  initialUrl: medley.referenceAudioUrl,
                  canEdit: canEdit,
                ),
              ),
            ],

            // ── Lista de músicas ────────────────────────────────
            const SizedBox(height: 16),
            if (count == 0)
              Center(
                child: Text(
                  'Nenhuma música neste medley.',
                  style: TextStyle(color: mutedColor),
                ),
              )
            else
              for (int i = 0; i < medley.items.length; i++) ...[
                FadeSlideIn(
                  delay: staggerDelay(staggerStep++),
                  child: _SongItemCard(item: medley.items[i]),
                ),
                if (i < medley.items.length - 1) const SizedBox(height: 8),
              ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Song item card
// ---------------------------------------------------------------------------

class _SongItemCard extends StatelessWidget {
  final MedleyItemEntity item;

  const _SongItemCard({required this.item});

  Future<void> _openLink(String url, String label) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      AppFeedback.showError('URL do $label inválida.');
      return;
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) AppFeedback.showError('Não foi possível abrir o $label.');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasNotes = item.notes != null && item.notes!.isNotEmpty;
    final hasYouTube = item.youTubeUrl != null && item.youTubeUrl!.isNotEmpty;
    final hasSpotify = item.spotifyUrl != null && item.spotifyUrl!.isNotEmpty;
    final hasDeezer = item.deezerUrl != null && item.deezerUrl!.isNotEmpty;
    final mutedColor = cs.onSurfaceVariant;
    final dividerColor = cs.outlineVariant;
    final thumbnailUrl = YoutubeUtils.getThumbnail(item.youTubeUrl);

    return Container(
      decoration: appCardDecoration(
        context,
        radius: AppRadius.card,
        color: cs.surfaceContainerLow,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : cs.shadow.withValues(alpha: 0.12),
            blurRadius: isDark ? 28 : 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Thumbnail + info ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.badge),
                      child: Image.network(
                        thumbnailUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, _) => Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(AppRadius.badge),
                          ),
                          child: Icon(
                            Icons.music_note_rounded,
                            color: cs.primary,
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primary,
                          borderRadius: BorderRadius.circular(AppRadius.badge),
                        ),
                        child: Text(
                          '${item.sequence}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: cs.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.songTitle ?? '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (item.songArtist != null &&
                          item.songArtist!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.songArtist!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: mutedColor,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (item.key != null && item.key!.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  _KeyChip(label: item.key!),
                ],
              ],
            ),
          ),

          // ── Notas ─────────────────────────────────────────────
          if (hasNotes) ...[
            Divider(height: 1, thickness: 1, color: dividerColor),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notes_rounded, size: 13, color: mutedColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.notes!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: mutedColor,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Links de referência (YouTube/Spotify/Deezer) ───────
          if (hasYouTube || hasSpotify || hasDeezer) ...[
            Divider(height: 1, thickness: 1, color: dividerColor),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Wrap(
                alignment: WrapAlignment.start,
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (hasYouTube)
                    _PlatformLinkPill(
                      label: 'YouTube',
                      iconAsset: 'assets/icons/logo-youtube.svg',
                      color: isDark
                          ? const Color(0xFFFF5252)
                          : const Color(0xFFD32F2F),
                      onTap: () => _openLink(item.youTubeUrl!, 'YouTube'),
                    ),
                  if (hasSpotify)
                    _PlatformLinkPill(
                      label: 'Spotify',
                      iconAsset: 'assets/icons/icon-spotify.svg',
                      color: isDark
                          ? const Color(0xFF1DB954)
                          : const Color(0xFF168A3F),
                      onTap: () => _openLink(item.spotifyUrl!, 'Spotify'),
                    ),
                  if (hasDeezer)
                    _PlatformLinkPill(
                      label: 'Deezer',
                      iconAsset: 'assets/icons/icon-deezer.svg',
                      color: const Color(0xFFA238FF),
                      onTap: () => _openLink(item.deezerUrl!, 'Deezer'),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pílula de link para plataforma (YouTube, Spotify, Deezer)
// ---------------------------------------------------------------------------

class _PlatformLinkPill extends StatelessWidget {
  final String label;
  final String iconAsset;
  final Color color;
  final VoidCallback onTap;

  const _PlatformLinkPill({
    required this.label,
    required this.iconAsset,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              iconAsset,
              width: 14,
              height: 14,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 6),
            SvgPicture.asset(
              'assets/icons/external-link.svg',
              width: 12,
              height: 12,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
          ],
        ),
      ),
    );
  }
}

class _KeyChip extends StatelessWidget {
  final String label;

  const _KeyChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(AppRadius.badge),
        border: Border.all(color: cs.tertiary.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'assets/icons/music-2.svg',
            width: 12,
            height: 12,
            colorFilter: ColorFilter.mode(
              cs.onTertiaryContainer,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: cs.onTertiaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Atalho de categorização
// ---------------------------------------------------------------------------

class _MedleyCategoriesQuickEdit extends StatefulWidget {
  final String medleyId;
  final List<SongCategoryEntity> initialCategories;

  const _MedleyCategoriesQuickEdit({
    required this.medleyId,
    required this.initialCategories,
  });

  @override
  State<_MedleyCategoriesQuickEdit> createState() =>
      _MedleyCategoriesQuickEditState();
}

class _MedleyCategoriesQuickEditState
    extends State<_MedleyCategoriesQuickEdit> {
  final _medleyRepo = MedleyRepositoryImpl();
  final _categoriesRepo = SongCategoriesRepositoryImpl();
  late List<SongCategoryEntity> _categories;
  bool _isOpeningPicker = false;

  @override
  void initState() {
    super.initState();
    _categories = widget.initialCategories;
  }

  Future<void> _openPicker() async {
    setState(() => _isOpeningPicker = true);

    List<SongCategoryEntity> catalog;
    try {
      catalog = await _categoriesRepo.getSongCategories();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isOpeningPicker = false);
      AppFeedback.showError(e.toString().replaceFirst('Exception: ', ''));
      return;
    }

    if (!mounted) return;
    setState(() => _isOpeningPicker = false);

    if (catalog.isEmpty) {
      AppFeedback.showInfo('Você ainda não tem categorias cadastradas.');
      return;
    }

    final result = await showCategoryFilterSheet(
      context,
      categories: catalog,
      initiallySelectedIds: _categories.map((c) => c.id).toSet(),
      title: 'Categorizar medley',
      subtitle: 'Selecione uma ou mais categorias para este medley.',
      applyLabel: 'Salvar',
    );
    if (result == null || !mounted) return;

    try {
      await _medleyRepo.updateMedleyCategories(widget.medleyId, result.toList());
      if (!mounted) return;
      setState(() {
        _categories = catalog
            .where((category) => result.contains(category.id))
            .toList();
      });
      AppFeedback.showSuccess('Categorias atualizadas com sucesso.');
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final mutedColor = cs.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Categorias',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _isOpeningPicker ? null : _openPicker,
              icon: _isOpeningPicker
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.primary,
                      ),
                    )
                  : SvgPicture.asset(
                      'assets/icons/tag-plus.svg',
                      width: 16,
                      height: 16,
                      colorFilter: ColorFilter.mode(
                        cs.primary,
                        BlendMode.srcIn,
                      ),
                    ),
              label: Text(_categories.isEmpty ? 'Adicionar' : 'Editar'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (_categories.isEmpty)
          Text(
            'Nenhuma categoria atribuída.',
            style: theme.textTheme.bodySmall?.copyWith(color: mutedColor),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((category) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: cs.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  category.name,
                  style: TextStyle(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Atalho de áudio de referência
// ---------------------------------------------------------------------------

class _MedleyReferenceAudioQuickEdit extends StatefulWidget {
  final String medleyId;
  final String? initialUrl;
  final bool canEdit;

  const _MedleyReferenceAudioQuickEdit({
    required this.medleyId,
    required this.initialUrl,
    required this.canEdit,
  });

  @override
  State<_MedleyReferenceAudioQuickEdit> createState() =>
      _MedleyReferenceAudioQuickEditState();
}

class _MedleyReferenceAudioQuickEditState
    extends State<_MedleyReferenceAudioQuickEdit> {
  final _medleyRepo = MedleyRepositoryImpl();
  late String? _currentUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.initialUrl;
  }

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );
    final path = (result != null && result.files.isNotEmpty)
        ? result.files.first.path
        : null;
    if (path == null) return;

    setState(() => _isUploading = true);
    try {
      await _medleyRepo.uploadReferenceAudio(widget.medleyId, path);
      final medleys = await _medleyRepo.getUserMedleys();
      if (!mounted) return;
      String? updatedUrl;
      for (final m in medleys) {
        if (m.id == widget.medleyId) {
          updatedUrl = m.referenceAudioUrl;
          break;
        }
      }
      setState(() {
        _currentUrl = updatedUrl;
        _isUploading = false;
      });
      AppFeedback.showSuccess('Áudio de referência atualizado com sucesso.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      AppFeedback.showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.canEdit && _currentUrl == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final mutedColor = cs.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Áudio de referência',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (widget.canEdit)
              TextButton.icon(
                onPressed: _isUploading ? null : _pickAndUpload,
                icon: _isUploading
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.primary,
                        ),
                      )
                    : Icon(
                        Icons.upload_file_rounded,
                        size: 16,
                        color: cs.primary,
                      ),
                label: Text(_currentUrl == null ? 'Adicionar' : 'Substituir'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_currentUrl != null)
          ReferenceAudioPlayer(url: _currentUrl!)
        else
          Text(
            'Nenhum áudio de referência cadastrado.',
            style: theme.textTheme.bodySmall?.copyWith(color: mutedColor),
          ),
      ],
    );
  }
}
