import 'package:flutter/material.dart';

import '../../../../core/ui/app_feedback.dart';
import '../../../../core/ui/widgets/app_form_sheet.dart';
import '../../../../core/ui/widgets/standard_section_app_bar.dart';
import '../../data/impl/songs_repository_impl.dart';
import '../../domain/entities/song_entity.dart';
import '../utils/song_validators.dart';
import '../widgets/song_form_fields.dart';

class CreateSongPage extends StatefulWidget {
  const CreateSongPage({super.key});

  @override
  State<CreateSongPage> createState() => _CreateSongPageState();
}

class _CreateSongPageState extends State<CreateSongPage> {
  final _formKey = GlobalKey<FormState>();
  final _artistController = TextEditingController();
  final _titleController = TextEditingController();
  final _keyController = TextEditingController();
  final _bpmController = TextEditingController();
  final _youTubeUrlController = TextEditingController();
  final _artistFocusNode = FocusNode();
  final _repo = SongsRepositoryImpl();

  bool _isSaving = false;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _artistFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _artistController.dispose();
    _titleController.dispose();
    _keyController.dispose();
    _bpmController.dispose();
    _youTubeUrlController.dispose();
    _artistFocusNode.dispose();
    super.dispose();
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
      artist: _artistController.text.trim(),
      title: _titleController.text.trim(),
      key: SongValidators.normalizeKey(_keyController.text),
      bpm: _bpmController.text.trim().isEmpty
          ? null
          : _bpmController.text.trim(),
      youTubeUrl: _youTubeUrlController.text.trim(),
    );

    try {
      final created = await _repo.createSong(song);
      if (!mounted) return;

      AppFeedback.showSuccess(
        "Música '${created.title}' adicionada com sucesso",
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
        title: 'Nova Música',
        subtitle: 'Adicione uma canção ao seu catálogo pessoal',
      ),
      body: SafeArea(
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
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Adicionar Música'),
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
