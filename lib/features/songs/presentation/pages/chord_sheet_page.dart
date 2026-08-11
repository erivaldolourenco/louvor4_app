import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/ui/app_feedback.dart';
import '../../../../core/ui/widgets/fade_slide_in.dart';
import '../../../../core/ui/widgets/standard_section_app_bar.dart';
import '../../data/impl/songs_repository_impl.dart';
import '../../domain/entities/chord_sheet_entity.dart';
import '../utils/chord_sheet_pdf_builder.dart';
import '../widgets/chord_anchor_editor.dart';
import '../widgets/chord_sheet_editor.dart';
import '../widgets/chord_sheet_view.dart';

enum _ChordSheetEditMode { lyrics, chords }

enum _ChordSheetMenuAction {
  editLyrics,
  editChords,
  exportPdf,
  toggleCollaborativeEditing,
  delete,
}

class ChordSheetPage extends StatefulWidget {
  final String songId;
  final String title;
  final String artist;
  final String? initialKey;
  final int? initialBpm;
  final bool canEdit;

  /// Se `true`, libera ações exclusivas do dono da cifra: remover a cifra e
  /// ativar/desativar a edição colaborativa. Diferente de [canEdit], que só
  /// libera editar o conteúdo (letra/acordes) — um colaborador com permissão
  /// concedida (ou um admin do projeto, quando a cifra colaborativa está
  /// ativa) pode ter `canEdit: true` sem ter `canManageSharing: true`.
  final bool canManageSharing;

  const ChordSheetPage({
    super.key,
    required this.songId,
    required this.title,
    required this.artist,
    this.initialKey,
    this.initialBpm,
    this.canEdit = true,
    this.canManageSharing = true,
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
  String? _selectedSectionId;

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
    _selectedSectionId = null;
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
    _selectedSectionId = null;
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
      _selectedSectionId = null;
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
    if (!widget.canManageSharing) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover cifra?'),
        content: const Text(
          'Essa ação apaga a cifra cadastrada para esta música.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
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

  Future<void> _onExportPdf() async {
    final chordSheet = _savedChordSheet;
    if (chordSheet == null) return;

    AppFeedback.showInfo('Gerando PDF da cifra...');
    try {
      final bytes = await buildChordSheetPdf(
        title: widget.title,
        artist: widget.artist,
        chordSheet: chordSheet,
      );

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/cifra_${widget.songId}.pdf');
      await file.writeAsBytes(bytes, flush: true);
      if (!mounted) return;

      final box = context.findRenderObject() as RenderBox?;
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject: 'Cifra de ${widget.title}',
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      );
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(
          'Não foi possível exportar a cifra em PDF: ${e.toString().replaceFirst('Exception: ', '')}',
        );
      }
    }
  }

  Future<void> _onToggleCollaborativeEditing() async {
    if (!widget.canManageSharing) return;
    final isEnabled = _savedChordSheet?.editPermission ?? false;
    final turningOn = !isEnabled;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          turningOn
              ? 'Ativar cifra colaborativa'
              : 'Desativar cifra colaborativa',
        ),
        content: Text(
          turningOn
              ? 'A cifra desta música vai ficar editável pelos membros de '
                    'qualquer evento em que ela for adicionada. Você pode '
                    'desativar isso quando quiser.'
              : 'Outros membros não vão poder editar mais a cifra desta '
                    'música.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(turningOn ? 'Ativar' : 'Desativar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final confirmedValue = await _repo.updateChordSheetEditPermission(
        widget.songId,
        turningOn,
      );
      if (!mounted) return;
      setState(() {
        _savedChordSheet =
            _savedChordSheet?.copyWith(editPermission: confirmedValue) ??
            ChordSheetEntity.empty(
              originalKey: widget.initialKey,
              bpm: widget.initialBpm,
            ).copyWith(editPermission: confirmedValue);
      });
      AppFeedback.showSuccess(
        confirmedValue
            ? 'Agora outros membros podem editar a cifra desta música.'
            : 'A cifra desta música não é mais editável por outros.',
      );
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _onMenuActionSelected(_ChordSheetMenuAction action) {
    switch (action) {
      case _ChordSheetMenuAction.editLyrics:
        _startEditingLyrics();
        break;
      case _ChordSheetMenuAction.editChords:
        _startEditingChords();
        break;
      case _ChordSheetMenuAction.exportPdf:
        _onExportPdf();
        break;
      case _ChordSheetMenuAction.toggleCollaborativeEditing:
        _onToggleCollaborativeEditing();
        break;
      case _ChordSheetMenuAction.delete:
        _confirmDelete();
        break;
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
      backgroundColor: cs.primary,
      foregroundColor: cs.onPrimary,
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
          onTap: () =>
              editFullLyricsText(context, draft, () => setState(() {})),
        ),
        SpeedDialChild(
          child: const Icon(Icons.add_rounded),
          label: 'Adicionar seção',
          backgroundColor: cs.secondaryContainer,
          foregroundColor: cs.onSecondaryContainer,
          labelStyle: theme.textTheme.labelLarge?.copyWith(color: cs.onSurface),
          labelBackgroundColor: cs.surfaceContainerHigh,
          onTap: () => setState(() {
            _selectedSectionId = addLyricsSection(
              draft,
              () {},
              afterSectionId: _selectedSectionId,
            );
          }),
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
      floatingActionButton:
          _mode == _ChordSheetEditMode.lyrics && _draft != null
          ? _buildLyricsFab(context, _draft!)
          : null,
      appBar: StandardSectionAppBar(
        title: widget.title,
        subtitle: widget.artist,
        actions: showToolbar
            ? [
                if (!_isEditing && (_hasLyricsContent || showEditActions))
                  PopupMenuButton<_ChordSheetMenuAction>(
                    tooltip: 'Ações da cifra',
                    color: cs.surface,
                    icon: const Icon(Icons.more_vert_rounded),
                    enabled: !busy,
                    onSelected: _onMenuActionSelected,
                    itemBuilder: (context) => [
                      if (_hasLyricsContent && showEditActions) ...[
                        const PopupMenuItem(
                          value: _ChordSheetMenuAction.editChords,
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.music_note_rounded),
                            title: Text('Cifrar'),
                          ),
                        ),
                      ],
                      if (showEditActions)
                        PopupMenuItem(
                          value: _ChordSheetMenuAction.editLyrics,
                          child: const ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.edit_rounded),
                            title: Text('Editar letra'),
                          ),
                        ),
                      if (_hasLyricsContent) ...[
                        const PopupMenuItem(
                          value: _ChordSheetMenuAction.exportPdf,
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.picture_as_pdf_outlined),
                            title: Text('Exportar PDF'),
                          ),
                        ),
                      ],
                      if (widget.canManageSharing) ...[
                        PopupMenuItem(
                          value:
                              _ChordSheetMenuAction.toggleCollaborativeEditing,
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              _savedChordSheet?.editPermission ?? false
                                  ? Icons.handshake_rounded
                                  : Icons.handshake_outlined,
                            ),
                            title: Text(
                              _savedChordSheet?.editPermission ?? false
                                  ? 'Desativar cifra colaborativa'
                                  : 'Ativar cifra colaborativa',
                            ),
                          ),
                        ),
                      ],
                      if (_hasLyricsContent && widget.canManageSharing) ...[
                        PopupMenuItem(
                          value: _ChordSheetMenuAction.delete,
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              Icons.delete_outline_rounded,
                              color: cs.error,
                            ),
                            title: Text(
                              'Remover cifra',
                              style: TextStyle(color: cs.error),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
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
                          selectedSectionId: _selectedSectionId,
                          onSelectSection: (id) =>
                              setState(() => _selectedSectionId = id),
                        )
                      : _mode == _ChordSheetEditMode.chords && _draft != null
                      ? ChordAnchorEditor(
                          draft: _draft!,
                          onChanged: () => setState(() {}),
                        )
                      : !_hasLyricsContent
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
            SvgPicture.asset(
              'assets/icons/file-music.svg',
              width: 30,
              height: 30,
              colorFilter: ColorFilter.mode(
                cs.onSurfaceVariant,
                BlendMode.srcIn,
              ),
            ),
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
