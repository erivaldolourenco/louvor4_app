import 'package:flutter/material.dart';

import '../../../../core/ui/widgets/app_form_sheet.dart';
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
        const _FieldLabel(label: 'Artista'),
        TextFormField(
          controller: artistController,
          focusNode: artistFocusNode,
          textInputAction: TextInputAction.next,
          decoration: appFormFieldDecoration(
            context,
            hintText: 'Digite o nome do artista',
            prefixIcon: Icons.mic_external_on_rounded,
          ),
          validator: SongValidators.validateArtist,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 12),
        const _FieldLabel(label: 'Título'),
        TextFormField(
          controller: titleController,
          textInputAction: TextInputAction.next,
          decoration: appFormFieldDecoration(
            context,
            hintText: 'Digite o título da música',
            prefixIcon: Icons.music_note_rounded,
          ),
          validator: SongValidators.validateTitle,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 12),
        const _FieldLabel(label: 'Tom'),
        TextFormField(
          controller: keyController,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.next,
          decoration: appFormFieldDecoration(
            context,
            hintText: 'Ex: C, D#, Em, Ab',
            prefixIcon: Icons.piano_rounded,
          ),
          validator: SongValidators.validateKey,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 12),
        const _FieldLabel(label: 'BPM'),
        TextFormField(
          controller: bpmController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          decoration: appFormFieldDecoration(
            context,
            hintText: 'Opcional',
            prefixIcon: Icons.speed_rounded,
          ),
          validator: SongValidators.validateBpm,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 12),
        const _FieldLabel(label: 'URL YouTube'),
        TextFormField(
          controller: youTubeUrlController,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.next,
          decoration: appFormFieldDecoration(
            context,
            hintText: 'Cole o link do vídeo no YouTube',
            prefixIcon: Icons.ondemand_video_rounded,
          ),
          validator: SongValidators.validateYouTubeUrl,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 12),
        const _FieldLabel(label: 'Observações'),
        TextFormField(
          controller: notesController,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          minLines: 4,
          maxLines: 6,
          decoration: appFormFieldDecoration(
            context,
            hintText: 'Adicione observações, cifra simplificada ou instruções',
            prefixIcon: Icons.notes_rounded,
          ),
          onChanged: (_) => onChanged(),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
      ),
    );
  }
}
