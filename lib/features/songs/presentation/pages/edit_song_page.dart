import 'package:flutter/material.dart';

import '../../../../core/ui/app_feedback.dart';
import '../../../../core/ui/widgets/app_form_sheet.dart';
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
  final _keyController = TextEditingController();
  final _bpmController = TextEditingController();
  final _youTubeUrlController = TextEditingController();
  final _notesController = TextEditingController();
  final _artistFocusNode = FocusNode();
  final _repo = SongsRepositoryImpl();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _loadSong();
  }

  @override
  void dispose() {
    _artistController.dispose();
    _titleController.dispose();
    _keyController.dispose();
    _bpmController.dispose();
    _youTubeUrlController.dispose();
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
      _keyController.text = song.key;
      _bpmController.text = song.bpm ?? '';
      _youTubeUrlController.text = song.youTubeUrl;
      _notesController.text = song.notes ?? '';

      _onFormChanged();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _artistFocusNode.requestFocus();
      });
    } catch (e) {
      AppFeedback.showError(e.toString().replaceFirst('Exception: ', ''));
      if (mounted) {
        Navigator.of(context).pop(false);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onFormChanged() {
    final valid =
        SongValidators.validateArtist(_artistController.text) == null &&
        SongValidators.validateTitle(_titleController.text) == null &&
        SongValidators.validateKey(_keyController.text) == null &&
        SongValidators.validateBpm(_bpmController.text) == null &&
        SongValidators.validateYouTubeUrl(_youTubeUrlController.text) == null;

    if (valid != _isFormValid) {
      setState(() => _isFormValid = valid);
    }
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
      youTubeUrl: _youTubeUrlController.text.trim(),
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
      if (mounted) {
        setState(() => _isSaving = false);
      }
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
                        keyController: _keyController,
                        bpmController: _bpmController,
                        youTubeUrlController: _youTubeUrlController,
                        notesController: _notesController,
                        artistFocusNode: _artistFocusNode,
                        onChanged: _onFormChanged,
                      ),
                      const SizedBox(height: 22),
                      FilledButton(
                        style: appPrimaryPillButtonStyle(context),
                        onPressed: _isSaving || !_isFormValid ? null : _save,
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Salvar alterações'),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        style: appSecondaryPillButtonStyle(context),
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
