import 'package:flutter/material.dart';

import '../utils/song_validators.dart';

class SongFormFields extends StatelessWidget {
  final TextEditingController artistController;
  final TextEditingController titleController;
  final TextEditingController keyController;
  final TextEditingController bpmController;
  final TextEditingController youTubeUrlController;
  final TextEditingController notesController;
  final FocusNode artistFocusNode;
  final VoidCallback onChanged;

  const SongFormFields({
    super.key,
    required this.artistController,
    required this.titleController,
    required this.keyController,
    required this.bpmController,
    required this.youTubeUrlController,
    required this.notesController,
    required this.artistFocusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: artistController,
          focusNode: artistFocusNode,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Artista',
            prefixIcon: Icon(Icons.mic_external_on_rounded),
          ),
          validator: SongValidators.validateArtist,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: titleController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Título',
            prefixIcon: Icon(Icons.music_note_rounded),
          ),
          validator: SongValidators.validateTitle,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: keyController,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Tom',
            hintText: 'Ex: C, D#, Em, Ab',
            prefixIcon: Icon(Icons.piano_rounded),
          ),
          validator: SongValidators.validateKey,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: bpmController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'BPM (opcional)',
            prefixIcon: Icon(Icons.speed_rounded),
          ),
          validator: SongValidators.validateBpm,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: youTubeUrlController,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'URL YouTube',
            prefixIcon: Icon(Icons.ondemand_video_rounded),
          ),
          validator: SongValidators.validateYouTubeUrl,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: notesController,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          minLines: 4,
          maxLines: 6,
          decoration: const InputDecoration(
            labelText: 'Observações',
            hintText: 'Cifra simplificada, instruções de arranjo...',
            alignLabelWithHint: true,
            prefixIcon: Icon(Icons.notes_rounded),
          ),
          onChanged: (_) => onChanged(),
        ),
      ],
    );
  }
}

