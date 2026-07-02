import 'package:flutter/material.dart';

import '../../../../core/ui/app_feedback.dart';
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
                IconButton(
                  tooltip: atMinFontSize
                      ? 'Tamanho mínimo atingido'
                      : 'Diminuir fonte',
                  onPressed: atMinFontSize ? null : _decreaseFontSize,
                  icon: const Icon(Icons.text_decrease_rounded),
                ),
                IconButton(
                  tooltip: atMaxFontSize
                      ? 'Tamanho máximo atingido'
                      : 'Aumentar fonte',
                  onPressed: atMaxFontSize ? null : _increaseFontSize,
                  icon: const Icon(Icons.text_increase_rounded),
                ),
                if (showEditActions) ...[
                  if (_isEditing)
                    IconButton(
                      tooltip: 'Cancelar',
                      onPressed: _isSaving ? null : _cancelEditing,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  IconButton(
                    tooltip: _isEditing ? 'Salvar letra' : 'Editar letra',
                    onPressed: _isSaving
                        ? null
                        : (_isEditing ? _saveLyrics : _startEditing),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            _isEditing ? Icons.check_rounded : Icons.edit_rounded,
                          ),
                  ),
                ],
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
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: cs.error),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _load,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
              )
            : Padding(
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
                    : SingleChildScrollView(
                        child: Text(
                          _savedLyrics.isEmpty
                              ? 'Nenhuma letra cadastrada.'
                              : _savedLyrics,
                          style: TextStyle(
                            color: _savedLyrics.isEmpty
                                ? cs.onSurfaceVariant
                                : cs.onSurface,
                            fontStyle: _savedLyrics.isEmpty
                                ? FontStyle.italic
                                : FontStyle.normal,
                            fontSize: _fontSize,
                            height: 1.6,
                          ),
                        ),
                      ),
              ),
      ),
    );
  }
}
