import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/ui/app_feedback.dart';
import '../../../../core/ui/widgets/app_buttons.dart';
import '../../../../core/ui/widgets/standard_section_app_bar.dart';
import '../../data/impl/songs_repository_impl.dart';
import '../../domain/entities/song_entity.dart';
import '../utils/song_validators.dart';
import '../widgets/song_form_fields.dart';

class EditSongPage extends StatefulWidget {
  final String songId;

  const EditSongPage({super.key, required this.songId});

  @override
  State<EditSongPage> createState() => _EditSongPageState();
}

class _EditSongPageState extends State<EditSongPage> {
  final _formKey = GlobalKey<FormState>();
  final _artistController = TextEditingController();
  final _titleController = TextEditingController();
  final _albumController = TextEditingController();
  final _keyController = TextEditingController();
  final _bpmController = TextEditingController();
  final _youTubeUrlController = TextEditingController();
  final _spotifyUrlController = TextEditingController();
  final _deezerUrlController = TextEditingController();
  final _notesController = TextEditingController();
  final _artistFocusNode = FocusNode();
  final _repo = SongsRepositoryImpl();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isFormValid = false;

  String? _currentReferenceAudioUrl;
  PlatformFile? _selectedAudioFile;
  String? _coverUrl;

  @override
  void initState() {
    super.initState();
    _loadSong();
  }

  @override
  void dispose() {
    _artistController.dispose();
    _titleController.dispose();
    _albumController.dispose();
    _keyController.dispose();
    _bpmController.dispose();
    _youTubeUrlController.dispose();
    _spotifyUrlController.dispose();
    _deezerUrlController.dispose();
    _notesController.dispose();
    _artistFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadSong() async {
    setState(() => _isLoading = true);

    try {
      final song = await _repo.getSongById(widget.songId);
      _artistController.text = song.artist;
      _titleController.text = song.title;
      _albumController.text = song.album ?? '';
      _keyController.text = song.key;
      _bpmController.text = song.bpm ?? '';
      _youTubeUrlController.text = song.youTubeUrl ?? '';
      _spotifyUrlController.text = song.spotifyUrl ?? '';
      _deezerUrlController.text = song.deezerUrl ?? '';
      _notesController.text = song.notes ?? '';
      _currentReferenceAudioUrl = song.referenceAudioUrl;
      _coverUrl = song.coverUrl;

      _onFormChanged();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _artistFocusNode.requestFocus();
      });
    } catch (e) {
      AppFeedback.showError(e.toString().replaceFirst('Exception: ', ''));
      if (mounted) Navigator.of(context).pop(false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onFormChanged() {
    final valid =
        SongValidators.validateArtist(_artistController.text) == null &&
        SongValidators.validateTitle(_titleController.text) == null &&
        SongValidators.validateKey(_keyController.text) == null &&
        SongValidators.validateBpm(_bpmController.text) == null &&
        SongValidators.validateYouTubeUrl(_youTubeUrlController.text) ==
            null &&
        SongValidators.validateUrl(_spotifyUrlController.text) == null &&
        SongValidators.validateUrl(_deezerUrlController.text) == null;

    if (valid != _isFormValid) setState(() => _isFormValid = valid);
  }

  Future<void> _pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    setState(() => _selectedAudioFile = result.files.first);
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      setState(() => _isFormValid = false);
      return;
    }

    setState(() => _isSaving = true);

    final song = SongEntity(
      id: widget.songId,
      artist: _artistController.text.trim(),
      title: _titleController.text.trim(),
      key: SongValidators.normalizeKey(_keyController.text),
      bpm: _bpmController.text.trim().isEmpty
          ? null
          : _bpmController.text.trim(),
      album: _albumController.text.trim().isEmpty
          ? null
          : _albumController.text.trim(),
      youTubeUrl: _youTubeUrlController.text.trim().isEmpty
          ? null
          : _youTubeUrlController.text.trim(),
      spotifyUrl: _spotifyUrlController.text.trim().isEmpty
          ? null
          : _spotifyUrlController.text.trim(),
      deezerUrl: _deezerUrlController.text.trim().isEmpty
          ? null
          : _deezerUrlController.text.trim(),
      coverUrl: _coverUrl,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    try {
      final updated = await _repo.updateSong(song);

      if (_selectedAudioFile?.path != null) {
        try {
          await _repo.uploadReferenceAudio(
            widget.songId,
            _selectedAudioFile!.path!,
          );
        } catch (e) {
          if (!mounted) return;
          AppFeedback.showError(e.toString().replaceFirst('Exception: ', ''));
          Navigator.of(context).pop(true);
          return;
        }
      }

      if (!mounted) return;
      AppFeedback.showSuccess(
        "Música '${updated.title}' atualizada com sucesso",
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      AppFeedback.showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: const StandardSectionAppBar(
        title: 'Editar Música',
        subtitle: 'Atualize os dados da canção do seu catálogo pessoal',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SongFormFields(
                        artistController: _artistController,
                        titleController: _titleController,
                        albumController: _albumController,
                        keyController: _keyController,
                        bpmController: _bpmController,
                        youTubeUrlController: _youTubeUrlController,
                        spotifyUrlController: _spotifyUrlController,
                        deezerUrlController: _deezerUrlController,
                        notesController: _notesController,
                        artistFocusNode: _artistFocusNode,
                        coverUrl: _coverUrl,
                        onChanged: _onFormChanged,
                      ),

                      // ── Áudio de referência ──────────────────────────
                      const SizedBox(height: 22),
                      _AudioReferenceSection(
                        isDark: isDark,
                        currentUrl: _currentReferenceAudioUrl,
                        selectedFile: _selectedAudioFile,
                        onPickFile: _pickAudioFile,
                        onClearFile: () =>
                            setState(() => _selectedAudioFile = null),
                      ),

                      const SizedBox(height: 22),
                      AppPrimaryButton(
                        onPressed: _isSaving || !_isFormValid ? null : _save,
                        child: _isSaving
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                ),
                              )
                            : const Text('Salvar alterações'),
                      ),
                      const SizedBox(height: 10),
                      AppSecondaryButton(
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.of(context).pop(),
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
// Seção de áudio de referência
// ---------------------------------------------------------------------------

class _AudioReferenceSection extends StatelessWidget {
  final bool isDark;
  final String? currentUrl;
  final PlatformFile? selectedFile;
  final VoidCallback onPickFile;
  final VoidCallback onClearFile;

  const _AudioReferenceSection({
    required this.isDark,
    required this.currentUrl,
    required this.selectedFile,
    required this.onPickFile,
    required this.onClearFile,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final mutedColor = cs.onSurfaceVariant;
    final borderColor = cs.outlineVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Áudio de Referência',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Áudio principal da música para estudo e prática.',
          style: theme.textTheme.bodySmall?.copyWith(color: mutedColor),
        ),
        const SizedBox(height: 12),

        // Player do áudio atual
        if (currentUrl != null) ...[
          _MiniAudioPlayer(url: currentUrl!, isDark: isDark),
          const SizedBox(height: 10),
          Text(
            'Para substituir, selecione um novo arquivo abaixo:',
            style: theme.textTheme.bodySmall?.copyWith(color: mutedColor),
          ),
          SizedBox(height: 10),
        ],

        // Seletor de arquivo
        if (selectedFile != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.input),
              border: Border.all(color: cs.primaryContainer),
            ),
            child: Row(
              children: [
                Icon(Icons.audio_file_rounded, size: 20, color: cs.primary),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    selectedFile!.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.primary,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                GestureDetector(
                  onTap: onClearFile,
                  child: Icon(Icons.close_rounded, size: 18, color: cs.primary),
                ),
              ],
            ),
          )
        else
          GestureDetector(
            onTap: onPickFile,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.input),
                border: Border.all(
                  color: borderColor,
                  style: BorderStyle.solid,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.upload_file_rounded, size: 20, color: mutedColor),
                  const SizedBox(width: 8),
                  Text(
                    'Selecionar arquivo de áudio',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: mutedColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Mini player para exibir o áudio atual
// ---------------------------------------------------------------------------

class _MiniAudioPlayer extends StatefulWidget {
  final String url;
  final bool isDark;

  const _MiniAudioPlayer({required this.url, required this.isDark});

  @override
  State<_MiniAudioPlayer> createState() => _MiniAudioPlayerState();
}

class _MiniAudioPlayerState extends State<_MiniAudioPlayer> {
  late final AudioPlayer _player;
  bool _loading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _init();
  }

  Future<void> _init() async {
    try {
      await _player.setUrl(widget.url);
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _fmt(Duration? d) {
    if (d == null) return '--:--';
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mutedColor = cs.onSurfaceVariant;
    final borderColor = cs.outlineVariant;
    final bgColor = cs.surfaceContainerLow;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(color: borderColor),
      ),
      child: _loading
          ? const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : _hasError
          ? Row(
              children: [
                Icon(Icons.error_outline, size: 16, color: mutedColor),
                const SizedBox(width: 8),
                Text(
                  'Não foi possível carregar o áudio.',
                  style: TextStyle(color: mutedColor, fontSize: 12),
                ),
              ],
            )
          : StreamBuilder<PlayerState>(
              stream: _player.playerStateStream,
              builder: (context, snapshot) {
                final isPlaying = snapshot.data?.playing ?? false;
                final isBuffering =
                    snapshot.data?.processingState ==
                        ProcessingState.buffering ||
                    snapshot.data?.processingState == ProcessingState.loading;

                return StreamBuilder<Duration?>(
                  stream: _player.durationStream,
                  builder: (context, durationSnap) {
                    final duration = durationSnap.data;

                    return StreamBuilder<Duration>(
                      stream: _player.positionStream,
                      builder: (context, posSnap) {
                        final position = posSnap.data ?? Duration.zero;
                        final maxVal =
                            duration?.inMilliseconds.toDouble() ?? 0.0;
                        final curVal = maxVal > 0
                            ? position.inMilliseconds.toDouble().clamp(
                                0.0,
                                maxVal,
                              )
                            : 0.0;

                        return Row(
                          children: [
                            SizedBox(
                              width: 36,
                              height: 36,
                              child: isBuffering
                                  ? const Padding(
                                      padding: EdgeInsets.all(8),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: Icon(
                                        isPlaying
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                        size: 28,
                                        color: cs.primary,
                                      ),
                                      onPressed: () => isPlaying
                                          ? _player.pause()
                                          : _player.play(),
                                    ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 3,
                                  thumbShape: RoundSliderThumbShape(
                                    enabledThumbRadius: 5,
                                  ),
                                  overlayShape: RoundSliderOverlayShape(
                                    overlayRadius: 12,
                                  ),
                                  activeTrackColor: cs.primary,
                                  inactiveTrackColor: borderColor,
                                  thumbColor: cs.primary,
                                  overlayColor: cs.primary.withValues(
                                    alpha: 0.15,
                                  ),
                                ),
                                child: Slider(
                                  value: curVal,
                                  min: 0,
                                  max: maxVal > 0 ? maxVal : 1,
                                  onChanged: maxVal > 0
                                      ? (v) => _player.seek(
                                          Duration(milliseconds: v.toInt()),
                                        )
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${_fmt(position)} / ${_fmt(duration)}',
                              style: TextStyle(fontSize: 11, color: mutedColor),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
