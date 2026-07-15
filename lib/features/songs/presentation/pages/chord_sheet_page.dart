import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

import '../../../../core/ui/app_feedback.dart';
import '../../../../core/ui/widgets/fade_slide_in.dart';
import '../../../../core/ui/widgets/standard_section_app_bar.dart';
import '../../data/impl/songs_repository_impl.dart';
import '../../domain/entities/chord_sheet_entity.dart';
import '../widgets/chord_anchor_editor.dart';
import '../widgets/chord_sheet_editor.dart';
import '../widgets/chord_sheet_view.dart';

enum _ChordSheetEditMode { lyrics, chords }

class ChordSheetPage extends StatefulWidget {
  final String songId;
  final String title;
  final String artist;
  final String? initialKey;
  final int? initialBpm;
  final bool canEdit;

  const ChordSheetPage({
    super.key,
    required this.songId,
    required this.title,
    required this.artist,
    this.initialKey,
    this.initialBpm,
    this.canEdit = true,
  });

  @override
  State<ChordSheetPage> createState() => _ChordSheetPageState();
}

class _ChordSheetPageState extends State<ChordSheetPage> {
  final _repo = SongsRepositoryImpl();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDeleting = false;
  _ChordSheetEditMode? _mode;
  String? _errorMessage;
  ChordSheetEntity? _savedChordSheet;
  EditableChordSheet? _draft;

  bool get _isEditing => _mode != null;

  bool get _hasLyricsContent =>
      _savedChordSheet != null && _savedChordSheet!.sections.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _draft?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final chordSheet = await _repo.getChordSheet(widget.songId);
      if (!mounted) return;
      setState(() {
        _savedChordSheet = chordSheet;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _startEditingLyrics() {
    if (!widget.canEdit) return;
    _draft = EditableChordSheet.fromEntity(
      _savedChordSheet ??
          ChordSheetEntity.empty(
            originalKey: widget.initialKey,
            bpm: widget.initialBpm,
          ),
    );
    setState(() => _mode = _ChordSheetEditMode.lyrics);
  }

  void _startEditingChords() {
    if (!widget.canEdit || !_hasLyricsContent) return;
    _draft = EditableChordSheet.fromEntity(_savedChordSheet!);
    setState(() => _mode = _ChordSheetEditMode.chords);
  }

  void _cancelEditing() {
    _draft?.dispose();
    _draft = null;
    setState(() => _mode = null);
  }

  Future<void> _save() async {
    if (!widget.canEdit || _draft == null) return;
    final mode = _mode;
    final entity = _draft!.toEntity();
    setState(() => _isSaving = true);
    try {
      final saved = await _repo.saveChordSheet(widget.songId, entity);
      if (!mounted) return;
      _draft?.dispose();
      _draft = null;
      setState(() {
        _savedChordSheet = saved;
        _isSaving = false;
        _mode = null;
      });
      AppFeedback.showSuccess(
        mode == _ChordSheetEditMode.chords
            ? 'Cifra atualizada com sucesso.'
            : 'Letra atualizada com sucesso.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      AppFeedback.showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover cifra?'),
        content: const Text('Essa ação apaga a cifra cadastrada para esta música.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _isDeleting = true);
    try {
      await _repo.deleteChordSheet(widget.songId);
      if (!mounted) return;
      setState(() {
        _savedChordSheet = null;
        _isDeleting = false;
      });
      AppFeedback.showSuccess('Cifra removida com sucesso.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      AppFeedback.showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Widget _tonalIconButton({
    required BuildContext context,
    required String tooltip,
    required IconData icon,
    required VoidCallback? onPressed,
    required Color background,
    required Color foreground,
  }) {
    return IconButton.filledTonal(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        disabledBackgroundColor: background.withValues(alpha: 0.4),
        disabledForegroundColor: foreground.withValues(alpha: 0.4),
        shape: const CircleBorder(),
      ),
      icon: Icon(icon, size: 18),
      onPressed: onPressed,
    );
  }

  Widget _buildLyricsFab(BuildContext context, EditableChordSheet draft) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SpeedDial(
      heroTag: 'chord_sheet_fab',
      icon: Icons.add_rounded,
      activeIcon: Icons.close_rounded,
      backgroundColor: cs.primaryContainer,
      foregroundColor: cs.onPrimaryContainer,
      shape: const CircleBorder(),
      elevation: 4,
      children: [
        SpeedDialChild(
          child: Icon(
            draft.sections.isEmpty
                ? Icons.content_paste_rounded
                : Icons.edit_note_rounded,
          ),
          label: draft.sections.isEmpty
              ? 'Colar letra completa'
              : 'Editar letra completa',
          backgroundColor: cs.secondaryContainer,
          foregroundColor: cs.onSecondaryContainer,
          labelStyle: theme.textTheme.labelLarge?.copyWith(color: cs.onSurface),
          labelBackgroundColor: cs.surfaceContainerHigh,
          onTap: () => editFullLyricsText(
            context,
            draft,
            () => setState(() {}),
          ),
        ),
        SpeedDialChild(
          child: const Icon(Icons.add_rounded),
          label: 'Adicionar seção',
          backgroundColor: cs.secondaryContainer,
          foregroundColor: cs.onSecondaryContainer,
          labelStyle: theme.textTheme.labelLarge?.copyWith(color: cs.onSurface),
          labelBackgroundColor: cs.surfaceContainerHigh,
          onTap: () => addLyricsSection(draft, () => setState(() {})),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final showToolbar = !_isLoading && _errorMessage == null;
    final showEditActions = showToolbar && widget.canEdit;
    final busy = _isSaving || _isDeleting;

    return Scaffold(
      floatingActionButton: _mode == _ChordSheetEditMode.lyrics && _draft != null
          ? _buildLyricsFab(context, _draft!)
          : null,
      appBar: StandardSectionAppBar(
        title: widget.title,
        subtitle: widget.artist,
        actions: showToolbar
            ? [
                if (showEditActions && !_isEditing) ...[
                  if (_hasLyricsContent) ...[
                    _tonalIconButton(
                      context: context,
                      tooltip: 'Remover cifra',
                      icon: Icons.delete_outline_rounded,
                      onPressed: busy ? null : _confirmDelete,
                      background: cs.errorContainer,
                      foreground: cs.onErrorContainer,
                    ),
                    const SizedBox(width: 6),
                    _tonalIconButton(
                      context: context,
                      tooltip: 'Cifrar',
                      icon: Icons.music_note_rounded,
                      onPressed: busy ? null : _startEditingChords,
                      background: cs.tertiaryContainer,
                      foreground: cs.onTertiaryContainer,
                    ),
                    const SizedBox(width: 6),
                  ],
                  _tonalIconButton(
                    context: context,
                    tooltip: 'Editar letra',
                    icon: Icons.edit_rounded,
                    onPressed: busy ? null : _startEditingLyrics,
                    background: cs.primaryContainer,
                    foreground: cs.onPrimaryContainer,
                  ),
                ],
                if (showEditActions && _isEditing) ...[
                  _tonalIconButton(
                    context: context,
                    tooltip: 'Cancelar',
                    icon: Icons.close_rounded,
                    onPressed: busy ? null : _cancelEditing,
                    background: cs.surfaceContainerHighest,
                    foreground: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  _tonalIconButton(
                    context: context,
                    tooltip: _mode == _ChordSheetEditMode.chords
                        ? 'Salvar cifra'
                        : 'Salvar letra',
                    icon: Icons.check_rounded,
                    onPressed: busy ? null : _save,
                    background: cs.primaryContainer,
                    foreground: cs.onPrimaryContainer,
                  ),
                ],
                const SizedBox(width: 8),
              ]
            : null,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
              )
            : FadeSlideIn(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _mode == _ChordSheetEditMode.lyrics && _draft != null
                      ? LyricsSectionsEditor(
                          draft: _draft!,
                          onChanged: () => setState(() {}),
                        )
                      : _mode == _ChordSheetEditMode.chords && _draft != null
                      ? ChordAnchorEditor(
                          draft: _draft!,
                          onChanged: () => setState(() {}),
                        )
                      : _savedChordSheet == null
                      ? _EmptyChordSheet(canEdit: widget.canEdit)
                      : ChordSheetView(chordSheet: _savedChordSheet!),
                ),
              ),
      ),
    );
  }
}

class _EmptyChordSheet extends StatelessWidget {
  final bool canEdit;

  const _EmptyChordSheet({required this.canEdit});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.piano_rounded, size: 30, color: cs.onSurfaceVariant),
            const SizedBox(height: 10),
            Text(
              'Nenhuma cifra cadastrada',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              canEdit
                  ? 'Toque em editar letra para começar a cadastrar a cifra desta música.'
                  : 'Esta música ainda não tem cifra cadastrada.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
