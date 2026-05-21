import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/ui/widgets/app_form_sheet.dart';
import '../../../../features/songs/domain/entities/song_entity.dart';
import '../../domain/entities/create_medley_input_entity.dart';
import '../../domain/entities/medley_entity.dart';
import '../cubit/medley_cubit.dart';

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

Future<void> showMedleyFormSheet(
  BuildContext context, {
  required List<SongEntity> songs,
  MedleyEntity? medley,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.93,
    ),
    builder: (ctx) => BlocProvider.value(
      value: context.read<MedleyCubit>(),
      child: _MedleyFormSheet(songs: songs, medley: medley),
    ),
  );
}

// ---------------------------------------------------------------------------
// Draft item model (local to this sheet)
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

  _DraftItem copyWith({String? key, String? notes}) {
    return _DraftItem(
      draftId: draftId,
      song: song,
      key: key ?? this.key,
      notes: notes ?? this.notes,
      sequence: sequence,
    );
  }
}

// ---------------------------------------------------------------------------
// Form sheet
// ---------------------------------------------------------------------------

class _MedleyFormSheet extends StatefulWidget {
  final List<SongEntity> songs;
  final MedleyEntity? medley;

  const _MedleyFormSheet({required this.songs, this.medley});

  @override
  State<_MedleyFormSheet> createState() => _MedleyFormSheetState();
}

class _MedleyFormSheetState extends State<_MedleyFormSheet> {
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
          sequence: _nextSequence(),
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
          .map((d) => d.draftId == item.draftId ? d.copyWith(key: config.key, notes: config.notes) : d)
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adicione pelo menos uma música ao medley.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'Medley atualizado com sucesso.' : 'Medley criado com sucesso.',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final error = cubit.state.actionError ?? 'Erro ao salvar medley.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActioning = context.select(
      (MedleyCubit c) => c.state.isActioning,
    );
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: AppFormSheet(
        title: _isEditing ? 'Editar Medley' : 'Novo Medley',
        subtitle: _isEditing
            ? 'Altere as músicas e informações do medley.'
            : 'Monte uma sequência de músicas para usar nas escalas.',
        icon: Icons.queue_music_rounded,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name
              _FieldLabel(label: 'Nome do medley *'),
              TextFormField(
                controller: _nameCtrl,
                enabled: !isActioning,
                decoration: appFormFieldDecoration(
                  context,
                  hintText: 'Ex: Abertura do culto',
                  prefixIcon: Icons.title_rounded,
                ),
                validator: (v) {
                  if ((v ?? '').trim().length < 3) return 'Mínimo de 3 caracteres.';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              _FieldLabel(label: 'Descrição (opcional)'),
              TextFormField(
                controller: _descCtrl,
                enabled: !isActioning,
                maxLines: 2,
                decoration: appFormFieldDecoration(
                  context,
                  hintText: 'Uma breve descrição...',
                  alignLabelWithHint: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // Draft items
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Músicas do medley',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ),
                  Text(
                    '${_draftItems.length} ${_draftItems.length == 1 ? 'música' : 'músicas'}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMutedLight,
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

              // Add song button
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.input),
                  ),
                  side: BorderSide(
                    color: isDark
                        ? AppColors.borderSubtleDark
                        : const Color(0xFFD6E4FF),
                  ),
                  foregroundColor: AppColors.primary,
                ),
                onPressed: isActioning ? null : _addSong,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Adicionar Música'),
              ),

              const SizedBox(height: 22),

              // Save button
              FilledButton(
                style: appPrimaryPillButtonStyle(context),
                onPressed: isActioning ? null : _save,
                child: isActioning
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(_isEditing ? 'Salvar alterações' : 'Criar Medley'),
              ),
            ],
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
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.scaffoldDark : AppColors.surfaceElevatedLight,
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.primarySubtleDark
                  : AppColors.primarySubtleLight,
              borderRadius: BorderRadius.circular(AppRadius.badge),
            ),
            child: Center(
              child: Text(
                '$index',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
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
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
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
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.edit_outlined, size: 18),
            color: AppColors.textMutedLight,
            onPressed: onEdit,
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            color: AppColors.dangerBright,
            onPressed: onRemove,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtleLight,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11, color: AppColors.textSubtleDark),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Field label helper
// ---------------------------------------------------------------------------

class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetColor = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    final filtered = widget.songs.where((s) {
      final q = _query.toLowerCase();
      return s.title.toLowerCase().contains(q) ||
          s.artist.toLowerCase().contains(q);
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: sheetColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.bottomSheet)),
      ),
      child: Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.borderSubtleDark : AppColors.borderStrongLight,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              children: [
                const Text(
                  'Selecionar música',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          // Search
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
                fillColor: isDark
                    ? AppColors.scaffoldDark
                    : AppColors.surfaceSubtleLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  borderSide: const BorderSide(
                    color: AppColors.primaryBright,
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
          // List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      _query.isEmpty ? 'Nenhuma música no catálogo.' : 'Nenhuma música encontrada.',
                      style: const TextStyle(color: AppColors.textMutedDark),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      color: isDark
                          ? AppColors.surfaceElevatedDark
                          : AppColors.surfaceSubtleLight,
                    ),
                    itemBuilder: (ctx, i) {
                      final song = filtered[i];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 4,
                        ),
                        leading: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceElevatedDark
                                : AppColors.surfaceSubtleLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.music_note_rounded,
                            color: AppColors.textMutedLight,
                            size: 20,
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
                            color: isDark
                                ? AppColors.primarySubtleDark
                                : AppColors.primarySubtleLight,
                            borderRadius: BorderRadius.circular(AppRadius.badge),
                          ),
                          child: Text(
                            song.key,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        onTap: () => Navigator.of(ctx).pop(song),
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

typedef _ItemConfig = ({String key, String? notes});

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
      initialKey: initialKey,
      initialNotes: initialNotes,
    ),
  );
}

class _ItemConfigDialog extends StatefulWidget {
  final String songTitle;
  final String initialKey;
  final String initialNotes;

  const _ItemConfigDialog({
    required this.songTitle,
    required this.initialKey,
    required this.initialNotes,
  });

  @override
  State<_ItemConfigDialog> createState() => _ItemConfigDialogState();
}

class _ItemConfigDialogState extends State<_ItemConfigDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _keyCtrl;
  late final TextEditingController _notesCtrl;

  static final _keyRegex = RegExp(r'^[A-G](#|b)?m?$');

  @override
  void initState() {
    super.initState();
    _keyCtrl = TextEditingController(text: widget.initialKey);
    _notesCtrl = TextEditingController(text: widget.initialNotes);
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.cardLarge)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Configurar música',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            widget.songTitle,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMutedLight,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tom *',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _keyCtrl,
              autocorrect: false,
              decoration: InputDecoration(
                hintText: 'Ex: C, D#, Ebm, Am',
                filled: true,
                fillColor: isDark
                    ? AppColors.scaffoldDark
                    : AppColors.surfaceElevatedLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.borderSubtleDark
                        : AppColors.borderLight,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.borderSubtleDark
                        : AppColors.borderLight,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  borderSide: const BorderSide(
                    color: AppColors.primaryBright,
                    width: 1.4,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  borderSide: const BorderSide(color: AppColors.dangerBright),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
              validator: (v) {
                if ((v ?? '').trim().isEmpty) return 'Tom é obrigatório.';
                if (!_keyRegex.hasMatch(v!.trim())) {
                  return 'Use A–G com # ou b e/ou m. Ex: C#m';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            const Text(
              'Observações (opcional)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Ex: Entrar no refrão...',
                filled: true,
                fillColor: isDark
                    ? AppColors.scaffoldDark
                    : AppColors.surfaceElevatedLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.borderSubtleDark
                        : AppColors.borderLight,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  borderSide: BorderSide(
                    color: isDark
                        ? AppColors.borderSubtleDark
                        : AppColors.borderLight,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  borderSide: const BorderSide(
                    color: AppColors.primaryBright,
                    width: 1.4,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            final notes = _notesCtrl.text.trim();
            Navigator.of(ctx).pop<_ItemConfig>((
              key: _keyCtrl.text.trim(),
              notes: notes.isEmpty ? null : notes,
            ));
          },
          child: const Text('Confirmar'),
        ),
      ],
    );
  }

  BuildContext get ctx => context;
}
