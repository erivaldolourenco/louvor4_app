import 'package:flutter/material.dart';

import '../../../../core/ui/app_feedback.dart';
import '../../../../core/ui/widgets/app_buttons.dart';
import '../../../../core/ui/widgets/app_cached_network_image.dart';
import '../../../../core/ui/widgets/standard_section_app_bar.dart';
import '../../../../core/utils/url_utils.dart';
import '../../data/impl/songs_repository_impl.dart';
import '../../domain/entities/external_music_entity.dart';
import '../../domain/entities/song_entity.dart';
import '../utils/song_validators.dart';
import '../widgets/song_form_fields.dart';

class CreateSongPage extends StatefulWidget {
  final ExternalMusicEntity? prefill;

  const CreateSongPage({super.key, this.prefill});

  @override
  State<CreateSongPage> createState() => _CreateSongPageState();
}

class _CreateSongPageState extends State<CreateSongPage> {
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
  final _keyFocusNode = FocusNode();
  final _repo = SongsRepositoryImpl();

  bool _isSaving = false;
  bool _isFormValid = false;

  String? _prefillCoverUrl;

  bool get _isPrefilled => widget.prefill != null;

  @override
  void initState() {
    super.initState();
    final prefill = widget.prefill;
    if (prefill != null) {
      _artistController.text = prefill.artist;
      _titleController.text = prefill.title;
      if (prefill.bpm != null) {
        _bpmController.text = prefill.bpm.toString();
      }
      _albumController.text = prefill.album ?? '';
      _prefillCoverUrl = prefill.coverUrl;
      _spotifyUrlController.text = prefill.spotifyUrl ?? '';
      _deezerUrlController.text = prefill.deezerUrl ?? '';
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _onFormChanged();
      (_isPrefilled ? _keyFocusNode : _artistFocusNode).requestFocus();
    });
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
    _keyFocusNode.dispose();
    super.dispose();
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
      coverUrl: _prefillCoverUrl,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
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
                if (_isPrefilled) ...[
                  _PrefillBanner(coverUrl: _prefillCoverUrl),
                  const SizedBox(height: 16),
                ],
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
                  keyFocusNode: _keyFocusNode,
                  coverUrl: _prefillCoverUrl,
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
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        )
                      : const Text('Adicionar Música'),
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

class _PrefillBanner extends StatelessWidget {
  final String? coverUrl;

  const _PrefillBanner({this.coverUrl});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasCover = UrlUtils.isValidNetworkUrl(coverUrl);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          if (hasCover) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AppCachedNetworkImage(
                imageUrl: coverUrl!,
                width: 40,
                height: 40,
              ),
            ),
            const SizedBox(width: 12),
          ] else ...[
            Icon(Icons.auto_awesome_rounded, color: cs.onSecondaryContainer),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              'Artista, título, capa, BPM e links preenchidos automaticamente. '
              'Confirme o tom e revise os links antes de salvar.',
              style: TextStyle(color: cs.onSecondaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}
