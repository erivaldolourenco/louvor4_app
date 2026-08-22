import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/ui/app_feedback.dart';
import '../../../../core/ui/widgets/fade_slide_in.dart';
import '../../../../core/ui/widgets/reference_audio_player.dart';
import '../../../../core/ui/widgets/standard_section_app_bar.dart';
import '../../../../core/utils/url_utils.dart';
import '../../../../core/utils/youtube_utils.dart';
import '../../../song_categories/data/impl/song_categories_repository_impl.dart';
import '../../../song_categories/domain/entities/song_category_entity.dart';
import '../../../song_categories/presentation/widgets/category_filter_sheet.dart';
import '../../data/impl/songs_repository_impl.dart';

// M3: Card.outlined "sutil" — fundo surface-container, borda outline-variant,
// sem elevação/sombra, 12dp de raio (padrão de canto do Card no Material 3).
const double _cardRadius = 12;

ShapeBorder _outlinedCardShape(ColorScheme cs) => RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(_cardRadius),
  side: BorderSide(color: cs.outlineVariant),
);

Future<void> openSongDetailPage(
  BuildContext context, {
  String? songId,
  required String title,
  required String artist,
  String? musicKey,
  String? bpm,
  String? album,
  String? youTubeUrl,
  String? spotifyUrl,
  String? deezerUrl,
  String? coverUrl,
  String? notes,
  String? referenceAudioUrl,
  VoidCallback? onOpenLyrics,
  VoidCallback? onOpenChords,
  VoidCallback? onEdit,
}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => SongDetailPage(
        songId: songId,
        title: title,
        artist: artist,
        musicKey: musicKey,
        bpm: bpm,
        album: album,
        youTubeUrl: youTubeUrl,
        spotifyUrl: spotifyUrl,
        deezerUrl: deezerUrl,
        coverUrl: coverUrl,
        notes: notes,
        referenceAudioUrl: referenceAudioUrl,
        onOpenLyrics: onOpenLyrics,
        onOpenChords: onOpenChords,
        onEdit: onEdit,
      ),
    ),
  );
}

class SongDetailPage extends StatelessWidget {
  final String? songId;
  final String title;
  final String artist;
  final String? musicKey;
  final String? bpm;
  final String? album;
  final String? youTubeUrl;
  final String? spotifyUrl;
  final String? deezerUrl;
  final String? coverUrl;
  final String? notes;
  final String? referenceAudioUrl;
  final VoidCallback? onOpenLyrics;
  final VoidCallback? onOpenChords;
  final VoidCallback? onEdit;

  const SongDetailPage({
    super.key,
    this.songId,
    required this.title,
    required this.artist,
    this.musicKey,
    this.bpm,
    this.album,
    this.youTubeUrl,
    this.spotifyUrl,
    this.deezerUrl,
    this.coverUrl,
    this.notes,
    this.referenceAudioUrl,
    this.onOpenLyrics,
    this.onOpenChords,
    this.onEdit,
  });

  Future<void> _openExternalLink(
    BuildContext context,
    String url,
    String label,
  ) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      AppFeedback.showError('URL inválida.');
      return;
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      AppFeedback.showError('Não foi possível abrir o $label.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final mutedColor = cs.onSurfaceVariant;
    final isDark = theme.brightness == Brightness.dark;

    final normalizedKey = musicKey?.trim();
    final normalizedBpm = bpm?.trim();
    final normalizedAlbum = album?.trim();
    final normalizedNotes = notes?.trim();
    final hasKey = normalizedKey != null && normalizedKey.isNotEmpty;
    final hasBpm = normalizedBpm != null && normalizedBpm.isNotEmpty;
    final hasAlbum = normalizedAlbum != null && normalizedAlbum.isNotEmpty;
    final hasNotes = normalizedNotes != null && normalizedNotes.isNotEmpty;
    final hasYouTube = youTubeUrl != null && youTubeUrl!.trim().isNotEmpty;
    final hasSpotify = spotifyUrl != null && spotifyUrl!.trim().isNotEmpty;
    final hasDeezer = deezerUrl != null && deezerUrl!.trim().isNotEmpty;
    final hasCover = UrlUtils.isValidNetworkUrl(coverUrl);

    int staggerStep = 0;

    return Scaffold(
      appBar: StandardSectionAppBar(
        title: 'Detalhes da Música',
        actions: [
          if (onEdit != null)
            IconButton(
              tooltip: 'Editar música',
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
            // ── 1. Capa, título, artista, metadados e álbum ────────
            FadeSlideIn(
              delay: staggerDelay(staggerStep++),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Capa
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.cardLarge),
                    child: Image.network(
                      hasCover
                          ? coverUrl!
                          : YoutubeUtils.getThumbnail(
                              youTubeUrl,
                              quality: 'hqdefault',
                            ),
                      width: 92,
                      height: 92,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, _) => Image.asset(
                        YoutubeUtils.defaultThumb,
                        width: 92,
                        height: 92,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        if (hasKey || hasBpm) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (hasKey)
                                _MetaChip(
                                  icon: Icons.key_rounded,
                                  iconAsset: 'assets/icons/music-2.svg',
                                  label: normalizedKey,
                                  backgroundColor: cs.tertiaryContainer,
                                  foregroundColor: cs.onTertiaryContainer,
                                ),
                              if (hasKey && hasBpm) const SizedBox(width: 8),
                              if (hasBpm)
                                _MetaChip(
                                  icon: Icons.speed_rounded,
                                  iconAsset: 'assets/icons/time.svg',
                                  label: normalizedBpm,
                                  backgroundColor: isDark
                                      ? AppColors.successSubtleDark
                                      : AppColors.successSubtleLight,
                                  foregroundColor: isDark
                                      ? AppColors.successBright
                                      : AppColors.success,
                                ),
                            ],
                          ),
                        ],
                        if (hasAlbum) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.album_rounded,
                                size: 14,
                                color: mutedColor,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  normalizedAlbum,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: mutedColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── 2. Ações principais (Letra secundária, Cifra primária) ────
            if (onOpenLyrics != null || onOpenChords != null) ...[
              const SizedBox(height: 24),
              FadeSlideIn(
                delay: staggerDelay(staggerStep++),
                child: Row(
                  children: [
                    if (onOpenLyrics != null) ...[
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: onOpenLyrics,
                          style: FilledButton.styleFrom(
                            backgroundColor: cs.secondaryContainer,
                            foregroundColor: cs.onSecondaryContainer,
                            minimumSize: const Size.fromHeight(38),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                              side: BorderSide(
                                color: cs.secondary.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                          icon: SvgPicture.asset(
                            'assets/icons/file-type-corner.svg',
                            width: 20,
                            height: 20,
                            colorFilter: ColorFilter.mode(
                              cs.onSecondaryContainer,
                              BlendMode.srcIn,
                            ),
                          ),
                          label: const Text('Ver letra'),
                        ),
                      ),
                    ],
                    if (onOpenLyrics != null && onOpenChords != null)
                      const SizedBox(width: 10),
                    if (onOpenChords != null) ...[
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: onOpenChords,
                          style: FilledButton.styleFrom(
                            backgroundColor: cs.primary,
                            foregroundColor: cs.onPrimary,
                            minimumSize: const Size.fromHeight(38),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                              side: BorderSide(
                                color: cs.onPrimary.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                          icon: SvgPicture.asset(
                            'assets/icons/file-music.svg',
                            width: 20,
                            height: 20,
                            colorFilter: ColorFilter.mode(
                              cs.onPrimary,
                              BlendMode.srcIn,
                            ),
                          ),
                          label: const Text('Ver cifra'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // ── 3. Observações ────────────────────────────────────
            if (hasNotes) ...[
              const SizedBox(height: 24),
              FadeSlideIn(
                delay: staggerDelay(staggerStep++),
                child: Card.outlined(
                  elevation: 0,
                  color: cs.surfaceContainerLow,
                  margin: EdgeInsets.zero,
                  shape: _outlinedCardShape(cs),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
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
                          normalizedNotes,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: mutedColor,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            // ── 3.5. Categorias (somente dono da música) ────────────
            if (songId != null && onEdit != null) ...[
              const SizedBox(height: 24),
              FadeSlideIn(
                delay: staggerDelay(staggerStep++),
                child: _CategoriesQuickEdit(songId: songId!),
              ),
            ],

            // ── 4. Áudio de referência ──────────────────────────────
            // Idem: substituir o áudio só é permitido ao dono da música.
            if (songId != null) ...[
              const SizedBox(height: 24),
              FadeSlideIn(
                delay: staggerDelay(staggerStep++),
                child: _ReferenceAudioQuickEdit(
                  songId: songId!,
                  initialUrl: referenceAudioUrl,
                  canEdit: onEdit != null,
                ),
              ),
            ],

            // ── 5. Ouvir nas Plataformas (card único com ListTiles) ────
            if (hasYouTube || hasSpotify || hasDeezer) ...[
              const SizedBox(height: 24),
              FadeSlideIn(
                delay: staggerDelay(staggerStep++),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ouvir nas plataformas',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card.outlined(
                      clipBehavior: Clip.antiAlias,
                      elevation: 0,
                      color: cs.surfaceContainerLow,
                      margin: EdgeInsets.zero,
                      shape: _outlinedCardShape(cs),
                      child: Column(
                        children: [
                          if (hasYouTube) ...[
                            _PlatformTile(
                              label: 'Abrir no YouTube',
                              leading: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: AppColors.youtube,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.badge,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                              onTap: () => _openExternalLink(
                                context,
                                youTubeUrl!,
                                'YouTube',
                              ),
                            ),
                            if (hasSpotify || hasDeezer)
                              const Divider(height: 1),
                          ],
                          if (hasSpotify) ...[
                            _PlatformTile(
                              label: 'Abrir no Spotify',
                              leading: SvgPicture.asset(
                                'assets/icons/icon-spotify.svg',
                                width: 28,
                                height: 28,
                                colorFilter: ColorFilter.mode(
                                  isDark
                                      ? AppColors.spotifyDark
                                      : AppColors.spotifyLight,
                                  BlendMode.srcIn,
                                ),
                              ),
                              onTap: () => _openExternalLink(
                                context,
                                spotifyUrl!,
                                'Spotify',
                              ),
                            ),
                            if (hasDeezer) const Divider(height: 1),
                          ],
                          if (hasDeezer)
                            _PlatformTile(
                              label: 'Abrir no Deezer',
                              leading: SvgPicture.asset(
                                'assets/icons/icon-deezer.svg',
                                width: 28,
                                height: 28,
                                colorFilter: const ColorFilter.mode(
                                  AppColors.deezer,
                                  BlendMode.srcIn,
                                ),
                              ),
                              onTap: () =>
                                  _openExternalLink(context, deezerUrl!, 'Deezer'),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Platform tile (YouTube, Spotify, Deezer)
// ---------------------------------------------------------------------------

class _PlatformTile extends StatelessWidget {
  final Widget leading;
  final String label;
  final VoidCallback onTap;

  const _PlatformTile({
    required this.leading,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListTile(
      leading: leading,
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      trailing: SvgPicture.asset(
        'assets/icons/external-link.svg',
        width: 18,
        height: 18,
        colorFilter: ColorFilter.mode(cs.onSurfaceVariant, BlendMode.srcIn),
      ),
      onTap: onTap,
    );
  }
}

// ---------------------------------------------------------------------------
// Atalho de categorização
// ---------------------------------------------------------------------------

class _CategoriesQuickEdit extends StatefulWidget {
  final String songId;

  const _CategoriesQuickEdit({required this.songId});

  @override
  State<_CategoriesQuickEdit> createState() => _CategoriesQuickEditState();
}

class _CategoriesQuickEditState extends State<_CategoriesQuickEdit> {
  final _songsRepo = SongsRepositoryImpl();
  final _categoriesRepo = SongCategoriesRepositoryImpl();

  bool _isLoading = true;
  bool _isOpeningPicker = false;
  List<SongCategoryEntity> _categories = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final song = await _songsRepo.getSongById(widget.songId);
      if (!mounted) return;
      setState(() {
        _categories = song.categories;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
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
      title: 'Categorizar música',
      subtitle: 'Selecione uma ou mais categorias para esta música.',
      applyLabel: 'Salvar',
    );
    if (result == null || !mounted) return;

    try {
      await _songsRepo.updateSongCategories(widget.songId, result.toList());
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
                label: Text(_categories.isEmpty ? 'Adicionar' : 'Categorias'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isLoading)
          SizedBox(
            height: 28,
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: mutedColor,
                ),
              ),
            ),
          )
        else if (_categories.isEmpty)
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
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
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

class _ReferenceAudioQuickEdit extends StatefulWidget {
  final String songId;
  final String? initialUrl;
  final bool canEdit;

  const _ReferenceAudioQuickEdit({
    required this.songId,
    required this.initialUrl,
    required this.canEdit,
  });

  @override
  State<_ReferenceAudioQuickEdit> createState() =>
      _ReferenceAudioQuickEditState();
}

class _ReferenceAudioQuickEditState extends State<_ReferenceAudioQuickEdit> {
  final _songsRepo = SongsRepositoryImpl();
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
      await _songsRepo.uploadReferenceAudio(widget.songId, path);
      final updated = await _songsRepo.getSongById(widget.songId);
      if (!mounted) return;
      setState(() {
        _currentUrl = updated.referenceAudioUrl;
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

// ---------------------------------------------------------------------------
// Chips
// ---------------------------------------------------------------------------

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String? iconAsset;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  const _MetaChip({
    required this.icon,
    this.iconAsset,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: foregroundColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconAsset != null
              ? SvgPicture.asset(
                  iconAsset!,
                  width: 16,
                  height: 16,
                  colorFilter: ColorFilter.mode(
                    foregroundColor,
                    BlendMode.srcIn,
                  ),
                )
              : Icon(icon, size: 16, color: foregroundColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
