import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/ui/app_feedback.dart';
import '../../../../core/ui/widgets/app_buttons.dart';
import '../../../../core/ui/widgets/app_circular_action_button.dart';
import '../../../../core/ui/widgets/app_text_area_theme.dart';
import '../../../../core/ui/widgets/standard_section_app_bar.dart';
import '../../../../core/utils/url_utils.dart';
import '../../../../core/utils/youtube_utils.dart';
import '../../../../features/songs/domain/entities/song_entity.dart';
import '../../domain/entities/create_medley_input_entity.dart';
import '../../domain/entities/medley_entity.dart';
import '../cubit/medley_cubit.dart';

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

Future<void> openMedleyFormPage(
  BuildContext context, {
  required List<SongEntity> songs,
  MedleyEntity? medley,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: context.read<MedleyCubit>(),
        child: _MedleyFormPage(songs: songs, medley: medley),
      ),
    ),
  );
}

Future<void> showMedleyFormSheet(
  BuildContext context, {
  required List<SongEntity> songs,
  MedleyEntity? medley,
}) => openMedleyFormPage(context, songs: songs, medley: medley);

// ---------------------------------------------------------------------------
// Draft item model (local to this page)
// ---------------------------------------------------------------------------

class _DraftItem {
  final String draftId;
  final SongEntity song;
  final String key;
  final String? notes;
  final int sequence;

  const _DraftItem({
    required this.draftId,
    required this.song,
    required this.key,
    this.notes,
    required this.sequence,
  });

  _DraftItem copyWith({String? key, String? notes, int? sequence}) {
    return _DraftItem(
      draftId: draftId,
      song: song,
      key: key ?? this.key,
      notes: notes ?? this.notes,
      sequence: sequence ?? this.sequence,
    );
  }
}

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

class _MedleyFormPage extends StatefulWidget {
  final List<SongEntity> songs;
  final MedleyEntity? medley;

  const _MedleyFormPage({required this.songs, this.medley});

  @override
  State<_MedleyFormPage> createState() => _MedleyFormPageState();
}

class _MedleyFormPageState extends State<_MedleyFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late List<_DraftItem> _draftItems;

  bool get _isEditing => widget.medley != null;

  @override
  void initState() {
    super.initState();
    final m = widget.medley;
    _nameCtrl = TextEditingController(text: m?.name ?? '');
    _descCtrl = TextEditingController(text: m?.description ?? '');
    _draftItems = m == null
        ? []
        : m.items
              .map(
                (item) => _DraftItem(
                  draftId: item.id ?? '${item.songId}_${item.sequence}',
                  song: SongEntity(
                    id: item.songId,
                    title: item.songTitle ?? '',
                    artist: item.songArtist ?? '',
                    key: item.key ?? '',
                    youTubeUrl: item.youTubeUrl ?? '',
                  ),
                  key: item.key ?? '',
                  notes: item.notes,
                  sequence: item.sequence,
                ),
              )
              .toList();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  int _nextSequence() {
    if (_draftItems.isEmpty) return 1;
    return _draftItems.map((i) => i.sequence).reduce((a, b) => a > b ? a : b) + 1;
  }

  Future<void> _addSong() async {
    final song = await _showSongPicker(context, widget.songs);
    if (!mounted || song == null) return;

    final config = await _showItemConfig(
      context,
      song: song,
      initialKey: song.key,
      nextSequence: _nextSequence(),
    );
    if (!mounted || config == null) return;

    setState(() {
      _draftItems = [
        ..._draftItems,
        _DraftItem(
          draftId: '${song.id}_${DateTime.now().millisecondsSinceEpoch}',
          song: song,
          key: config.key,
          notes: config.notes,
          sequence: config.sequence,
        ),
      ];
    });
  }

  Future<void> _editItem(_DraftItem item) async {
    final config = await _showItemConfig(
      context,
      song: item.song,
      initialKey: item.key,
      initialNotes: item.notes ?? '',
      nextSequence: item.sequence,
    );
    if (!mounted || config == null) return;

    setState(() {
      _draftItems = _draftItems
          .map(
            (d) => d.draftId == item.draftId
                ? d.copyWith(key: config.key, notes: config.notes, sequence: config.sequence)
                : d,
          )
          .toList();
    });
  }

  void _removeItem(String draftId) {
    setState(() {
      _draftItems = _draftItems.where((d) => d.draftId != draftId).toList();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_draftItems.isEmpty) {
      AppFeedback.showError('Adicione pelo menos uma música ao medley.');
      return;
    }

    final input = CreateMedleyInputEntity(
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      items: _draftItems
          .map(
            (d) => CreateMedleyItemInputEntity(
              songId: d.song.id ?? '',
              key: d.key,
              notes: d.notes?.isEmpty == true ? null : d.notes,
              sequence: d.sequence,
            ),
          )
          .toList(),
    );

    final cubit = context.read<MedleyCubit>();
    final bool success;

    if (_isEditing) {
      success = await cubit.updateMedley(widget.medley!.id!, input);
    } else {
      success = await cubit.createMedley(input);
    }

    if (!mounted) return;

    if (success) {
      AppFeedback.showSuccess(
        _isEditing ? 'Medley atualizado com sucesso.' : 'Medley criado com sucesso.',
      );
      Navigator.of(context).pop();
    } else {
      AppFeedback.showError(cubit.state.actionError ?? 'Erro ao salvar medley.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActioning = context.select(
      (MedleyCubit c) => c.state.isActioning,
    );
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: StandardSectionAppBar(
        title: _isEditing ? 'Editar Medley' : 'Novo Medley',
        subtitle: _isEditing
            ? 'Altere as músicas e informações do medley.'
            : 'Monte uma sequência de músicas para usar nas escalas.',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  enabled: !isActioning,
                  decoration: InputDecoration(
                    labelText: 'Nome do medley',
                    hintText: 'Ex: Abertura do culto',
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(12),
                      child: SvgPicture.asset(
                        'assets/icons/disc.svg',
                        width: 20,
                        height: 20,
                        colorFilter: ColorFilter.mode(
                          theme.iconTheme.color ?? theme.colorScheme.onSurfaceVariant,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                  validator: (v) {
                    if ((v ?? '').trim().length < 3) return 'Mínimo de 3 caracteres.';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                AppTextAreaTheme(
                  child: TextFormField(
                    controller: _descCtrl,
                    enabled: !isActioning,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Descrição (opcional)',
                      hintText: 'Uma breve descrição...',
                      alignLabelWithHint: true,
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Músicas do medley',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ),
                    Text(
                      '${_draftItems.length} ${_draftItems.length == 1 ? 'música' : 'músicas'}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (_draftItems.isNotEmpty) ...[
                  ..._draftItems.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    return _DraftItemTile(
                      item: item,
                      index: idx + 1,
                      isDark: isDark,
                      onEdit: isActioning ? null : () => _editItem(item),
                      onRemove: isActioning ? null : () => _removeItem(item.draftId),
                    );
                  }),
                  const SizedBox(height: 8),
                ],

                AppSecondaryButton(
                  onPressed: isActioning ? null : _addSong,
                  icon: Icons.add_rounded,
                  height: 48,
                  child: const Text('Adicionar Música'),
                ),

                const SizedBox(height: 22),

                AppPrimaryButton(
                  onPressed: isActioning ? null : _save,
                  child: isActioning
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(_isEditing ? 'Salvar alterações' : 'Criar Medley'),
                ),
                const SizedBox(height: 10),
                AppSecondaryButton(
                  onPressed: isActioning ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Draft item tile
// ---------------------------------------------------------------------------

class _DraftItemTile extends StatelessWidget {
  final _DraftItem item;
  final int index;
  final bool isDark;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;

  const _DraftItemTile({
    required this.item,
    required this.index,
    required this.isDark,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final imageUrl = UrlUtils.isValidNetworkUrl(item.song.coverUrl)
        ? item.song.coverUrl!
        : YoutubeUtils.getThumbnail(item.song.youTubeUrl, quality: 'default');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: isDark ? 0.35 : 0.55),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.badge),
                  child: Image.network(
                    imageUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 48,
                      height: 48,
                      color: cs.surfaceContainerHigh,
                      child: Icon(
                        Icons.music_note_rounded,
                        size: 20,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: -6,
                  top: -6,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: cs.surfaceContainerLow,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$index',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: cs.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _MiniTag(label: 'Tom: ${item.key}'),
                    if (item.notes != null && item.notes!.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      _MiniTag(label: item.notes!),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AppCircularActionButton(
            onPressed: onEdit,
            assetPath: 'assets/icons/settings-2.svg',
            iconColor: onEdit != null ? cs.primary : cs.onSurfaceVariant,
            backgroundColor: onEdit != null ? cs.primaryContainer : cs.surfaceContainerLow,
            borderColor: onEdit != null ? cs.primary.withValues(alpha: 0.3) : cs.outlineVariant,
          ),
          const SizedBox(width: 8),
          AppCircularActionButton(
            onPressed: onRemove,
            assetPath: 'assets/icons/trash-2.svg',
            iconColor: onRemove != null ? cs.error : cs.onSurfaceVariant,
            backgroundColor: onRemove != null ? cs.errorContainer : cs.surfaceContainerLow,
            borderColor: onRemove != null ? cs.error.withValues(alpha: 0.3) : cs.outlineVariant,
          ),
        ],
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String label;

  const _MiniTag({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
      ),
    );
  }
}


// ---------------------------------------------------------------------------
// Song picker sheet
// ---------------------------------------------------------------------------

Future<SongEntity?> _showSongPicker(
  BuildContext context,
  List<SongEntity> songs,
) async {
  return showModalBottomSheet<SongEntity>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.85,
    ),
    builder: (_) => _SongPickerSheet(songs: songs),
  );
}

class _SongPickerSheet extends StatefulWidget {
  final List<SongEntity> songs;

  const _SongPickerSheet({required this.songs});

  @override
  State<_SongPickerSheet> createState() => _SongPickerSheetState();
}

class _SongPickerSheetState extends State<_SongPickerSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final filtered = widget.songs.where((s) {
      final q = _query.toLowerCase();
      return s.title.toLowerCase().contains(q) ||
          s.artist.toLowerCase().contains(q);
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.bottomSheet)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              children: [
                Text(
                  'Selecionar música',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Buscar por título ou artista...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: cs.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  borderSide: BorderSide(color: cs.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  borderSide: BorderSide(color: cs.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  borderSide: BorderSide(
                    color: cs.primary,
                    width: 1.4,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Builder(
                      builder: (context) => Text(
                        _query.isEmpty ? 'Nenhuma música no catálogo.' : 'Nenhuma música encontrada.',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ),
                  )
                : Builder(
                    builder: (context) {
                      final cs = Theme.of(context).colorScheme;
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => Divider(
                          height: 1,
                          color: cs.outlineVariant,
                        ),
                        itemBuilder: (ctx, i) {
                          final song = filtered[i];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 4,
                            ),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(AppRadius.card),
                              child: Image.network(
                                UrlUtils.isValidNetworkUrl(song.coverUrl)
                                    ? song.coverUrl!
                                    : YoutubeUtils.getThumbnail(
                                        song.youTubeUrl,
                                        quality: 'default',
                                      ),
                                width: 42,
                                height: 42,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  width: 42,
                                  height: 42,
                                  color: cs.surfaceContainerLow,
                                  child: Icon(
                                    Icons.music_note_rounded,
                                    color: cs.onSurfaceVariant,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              song.title,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              song.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: cs.primaryContainer,
                                borderRadius: BorderRadius.circular(AppRadius.badge),
                              ),
                              child: Text(
                                song.key,
                                style: Theme.of(ctx).textTheme.labelMedium?.copyWith(
                                  color: cs.primary,
                                ),
                              ),
                            ),
                            onTap: () => Navigator.of(ctx).pop(song),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Item config dialog (key + notes)
// ---------------------------------------------------------------------------

typedef _ItemConfig = ({String key, String? notes, int sequence});

Future<_ItemConfig?> _showItemConfig(
  BuildContext context, {
  required SongEntity song,
  required String initialKey,
  String initialNotes = '',
  required int nextSequence,
}) async {
  return showDialog<_ItemConfig>(
    context: context,
    builder: (ctx) => _ItemConfigDialog(
      songTitle: song.title,
      songArtist: song.artist,
      youTubeUrl: song.youTubeUrl,
      initialKey: initialKey,
      initialNotes: initialNotes,
      initialSequence: nextSequence,
    ),
  );
}

class _ItemConfigDialog extends StatefulWidget {
  final String songTitle;
  final String songArtist;
  final String? youTubeUrl;
  final String initialKey;
  final String initialNotes;
  final int initialSequence;

  const _ItemConfigDialog({
    required this.songTitle,
    required this.songArtist,
    required this.youTubeUrl,
    required this.initialKey,
    required this.initialNotes,
    required this.initialSequence,
  });

  @override
  State<_ItemConfigDialog> createState() => _ItemConfigDialogState();
}

class _ItemConfigDialogState extends State<_ItemConfigDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _keyCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _sequenceCtrl;

  static final _keyRegex = RegExp(r'^[A-G](#|b)?m?$');

  @override
  void initState() {
    super.initState();
    _keyCtrl = TextEditingController(text: widget.initialKey);
    _notesCtrl = TextEditingController(text: widget.initialNotes);
    _sequenceCtrl = TextEditingController(text: '${widget.initialSequence}');
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    _notesCtrl.dispose();
    _sequenceCtrl.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration({String? hint, int maxLines = 1}) {
    final cs = Theme.of(context).colorScheme;
    final radius = maxLines > 1 ? AppRadius.textarea : AppRadius.input;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: cs.onSurfaceVariant),
      filled: true,
      fillColor: cs.surfaceContainerLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(color: cs.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(color: cs.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(color: cs.error, width: 1.5),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: 14,
        vertical: maxLines > 1 ? 10 : 12,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final thumbnailUrl = YoutubeUtils.getThumbnail(widget.youTubeUrl);
    final hasThumb = widget.youTubeUrl != null && widget.youTubeUrl!.isNotEmpty;

    return Dialog(
      backgroundColor: cs.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Thumbnail header ──────────────────────────────────────────
            SizedBox(
              height: 160,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  hasThumb
                      ? Image.network(
                          thumbnailUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const _ThumbFallback(),
                        )
                      : const _ThumbFallback(),
                  // gradient
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.75),
                        ],
                      ),
                    ),
                  ),
                  // title + artist
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 14,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.songTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        if (widget.songArtist.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.songArtist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 13,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // close button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: cs.shadow.withValues(alpha: 0.35),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.of(context).pop(),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(Icons.close_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Campos ────────────────────────────────────────────────────
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sequência
                    Text(
                      'Sequência *',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _sequenceCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: _fieldDecoration(hint: 'Ex: 1, 2, 3…'),
                      validator: (v) {
                        final n = int.tryParse((v ?? '').trim());
                        if (n == null || n < 1) return 'Informe um número maior que 0.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Tom
                    Text(
                      'Tom *',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _keyCtrl,
                      autocorrect: false,
                      decoration: _fieldDecoration(hint: 'Ex: C, D#, Ebm, Am'),
                      validator: (v) {
                        if ((v ?? '').trim().isEmpty) return 'Tom é obrigatório.';
                        if (!_keyRegex.hasMatch(v!.trim())) {
                          return 'Use A–G com # ou b e/ou m. Ex: C#m';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Observações
                    Text(
                      'Observações (opcional)',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _notesCtrl,
                      maxLines: 3,
                      decoration: _fieldDecoration(hint: 'Ex: Entrar no refrão...', maxLines: 3),
                    ),
                  ],
                ),
              ),
            ),

            // ── Ações ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: AppSecondaryButton(
                      onPressed: () => Navigator.of(context).pop(),
                      height: 48,
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppPrimaryButton(
                      onPressed: () {
                        if (!_formKey.currentState!.validate()) return;
                        final notes = _notesCtrl.text.trim();
                        Navigator.of(context).pop<_ItemConfig>((
                          sequence: int.parse(_sequenceCtrl.text.trim()),
                          key: _keyCtrl.text.trim(),
                          notes: notes.isEmpty ? null : notes,
                        ));
                      },
                      height: 48,
                      child: const Text('Confirmar'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThumbFallback extends StatelessWidget {
  const _ThumbFallback();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.primaryContainer,
      child: Center(
        child: Icon(Icons.music_note_rounded, color: cs.primary, size: 48),
      ),
    );
  }
}

