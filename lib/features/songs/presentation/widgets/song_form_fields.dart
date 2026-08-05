import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/ui/widgets/app_cached_network_image.dart';
import '../../../../core/ui/widgets/app_text_area_theme.dart';
import '../../../../core/utils/url_utils.dart';
import '../utils/song_validators.dart';

class SongFormFields extends StatelessWidget {
  final TextEditingController artistController;
  final TextEditingController titleController;
  final TextEditingController albumController;
  final TextEditingController keyController;
  final TextEditingController bpmController;
  final TextEditingController youTubeUrlController;
  final TextEditingController spotifyUrlController;
  final TextEditingController deezerUrlController;
  final TextEditingController notesController;
  final FocusNode artistFocusNode;
  final FocusNode? keyFocusNode;
  final String? coverUrl;
  final VoidCallback onChanged;

  const SongFormFields({
    super.key,
    required this.artistController,
    required this.titleController,
    required this.albumController,
    required this.keyController,
    required this.bpmController,
    required this.youTubeUrlController,
    required this.spotifyUrlController,
    required this.deezerUrlController,
    required this.notesController,
    required this.artistFocusNode,
    this.keyFocusNode,
    this.coverUrl,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasCover = UrlUtils.isValidNetworkUrl(coverUrl);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasCover) ...[
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.thumbnail),
              child: AppCachedNetworkImage(
                imageUrl: coverUrl!,
                width: 96,
                height: 96,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
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
          controller: albumController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Álbum (opcional)',
            prefixIcon: Icon(Icons.album_outlined),
          ),
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: keyController,
          focusNode: keyFocusNode,
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
            labelText: 'URL YouTube (opcional)',
            prefixIcon: Icon(Icons.ondemand_video_rounded),
          ),
          validator: SongValidators.validateYouTubeUrl,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: spotifyUrlController,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'URL Spotify (opcional)',
            prefixIcon: Icon(Icons.graphic_eq_rounded),
          ),
          validator: SongValidators.validateUrl,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: deezerUrlController,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'URL Deezer (opcional)',
            prefixIcon: Icon(Icons.album_rounded),
          ),
          validator: SongValidators.validateUrl,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 12),
        AppTextAreaTheme(
          child: TextFormField(
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
        ),
      ],
    );
  }
}
