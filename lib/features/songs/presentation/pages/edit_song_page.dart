import 'package:flutter/material.dart';

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
