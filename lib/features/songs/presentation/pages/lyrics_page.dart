import 'package:flutter/material.dart';

import '../../../../core/ui/app_feedback.dart';
import '../../../../core/ui/widgets/fade_slide_in.dart';
import '../../../../core/ui/widgets/standard_section_app_bar.dart';
import '../../data/impl/songs_repository_impl.dart';

class LyricsPage extends StatefulWidget {
  final String songId;
  final String title;
  final String artist;
  final bool canEdit;

  const LyricsPage({
    super.key,
    required this.songId,
    required this.title,
    required this.artist,
    this.canEdit = true,
  });

  @override
  State<LyricsPage> createState() => _LyricsPageState();
}

class _LyricsPageState extends State<LyricsPage> {
  static const double _minFontSize = 16;
  static const double _maxFontSize = 30;
  static const double _fontSizeStep = 2;

  final _repo = SongsRepositoryImpl();
  final _controller = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;
  String? _errorMessage;
  String _savedLyrics = '';
  double _fontSize = _minFontSize;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final lyrics = await _repo.getSongLyrics(widget.songId);
      if (!mounted) return;
      _savedLyrics = lyrics ?? '';
      _controller.text = _savedLyrics;
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _startEditing() {
    if (!widget.canEdit) return;
    setState(() => _isEditing = true);
  }

  void _cancelEditing() {
    _controller.text = _savedLyrics;
    setState(() => _isEditing = false);
  }

  void _increaseFontSize() {
    setState(() {
      _fontSize = (_fontSize + _fontSizeStep).clamp(_minFontSize, _maxFontSize);
    });
  }

  void _decreaseFontSize() {
    setState(() {
      _fontSize = (_fontSize - _fontSizeStep).clamp(_minFontSize, _maxFontSize);
    });
  }

  Future<void> _saveLyrics() async {
    if (!widget.canEdit) return;
    final lyrics = _controller.text.trim();
    setState(() => _isSaving = true);
    try {
      await _repo.updateSongLyrics(widget.songId, lyrics);
      if (!mounted) return;
      _savedLyrics = lyrics;
      setState(() {
        _isSaving = false;
        _isEditing = false;
      });
      AppFeedback.showSuccess('Letra atualizada com sucesso.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final showToolbar = !_isLoading && _errorMessage == null;
    final showEditActions = showToolbar && widget.canEdit;
    final atMaxFontSize = _fontSize >= _maxFontSize;
    final atMinFontSize = _fontSize <= _minFontSize;

    return Scaffold(
      appBar: StandardSectionAppBar(
        title: widget.title,
        subtitle: widget.artist,
        actions: showToolbar
            ? [
                _tonalIconButton(
                  context: context,
                  tooltip: atMinFontSize
                      ? 'Tamanho mínimo atingido'
                      : 'Diminuir fonte',
                  icon: Icons.text_decrease_rounded,
                  onPressed: atMinFontSize ? null : _decreaseFontSize,
                  background: cs.secondaryContainer,
                  foreground: cs.onSecondaryContainer,
                ),
                const SizedBox(width: 6),
                _tonalIconButton(
                  context: context,
                  tooltip: atMaxFontSize
                      ? 'Tamanho máximo atingido'
                      : 'Aumentar fonte',
                  icon: Icons.text_increase_rounded,
                  onPressed: atMaxFontSize ? null : _increaseFontSize,
                  background: cs.secondaryContainer,
                  foreground: cs.onSecondaryContainer,
                ),
                if (showEditActions) ...[
                  const SizedBox(width: 6),
                  if (_isEditing)
                    _tonalIconButton(
                      context: context,
                      tooltip: 'Cancelar',
                      icon: Icons.close_rounded,
                      onPressed: _isSaving ? null : _cancelEditing,
                      background: cs.surfaceContainerHighest,
                      foreground: cs.onSurfaceVariant,
                    ),
                  if (_isEditing) const SizedBox(width: 6),
                  _tonalIconButton(
                    context: context,
                    tooltip: _isEditing ? 'Salvar letra' : 'Editar letra',
                    icon: _isEditing ? Icons.check_rounded : Icons.edit_rounded,
                    onPressed: _isSaving
                        ? null
                        : (_isEditing ? _saveLyrics : _startEditing),
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
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _isEditing
                      ? TextField(
                          controller: _controller,
                          autofocus: true,
                          expands: true,
                          maxLines: null,
                          textAlignVertical: TextAlignVertical.top,
                          style: TextStyle(
                            color: cs.onSurface,
                            fontSize: _fontSize,
                            height: 1.6,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Digite a letra da música...',
                            filled: false,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                          ),
                        )
                      : _savedLyrics.isEmpty
                      ? _EmptyLyrics(canEdit: widget.canEdit)
                      : SingleChildScrollView(
                          child: Text(
                            _savedLyrics,
                            style: TextStyle(
                              color: cs.onSurface,
                              fontSize: _fontSize,
                              height: 1.6,
                            ),
                          ),
                        ),
                ),
              ),
      ),
    );
  }
}

class _EmptyLyrics extends StatelessWidget {
  final bool canEdit;

  const _EmptyLyrics({required this.canEdit});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lyrics_outlined, size: 30, color: cs.onSurfaceVariant),
          const SizedBox(height: 10),
          Text(
            'Nenhuma letra cadastrada',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            canEdit
                ? 'Toque em editar para adicionar a letra desta música.'
                : 'Esta música ainda não tem letra cadastrada.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
