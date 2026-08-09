import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
    final iconColor =
        Theme.of(context).iconTheme.color ??
        Theme.of(context).colorScheme.onSurfaceVariant;

    Widget svgPrefixIcon(String asset) => Padding(
      padding: const EdgeInsets.all(12),
      child: SvgPicture.asset(
        asset,
        width: 20,
        height: 20,
        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
      ),
    );

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
          decoration: InputDecoration(
            labelText: 'Artista',
            prefixIcon: svgPrefixIcon('assets/icons/mic-vocal.svg'),
          ),
          validator: SongValidators.validateArtist,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: titleController,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Título',
            prefixIcon: svgPrefixIcon('assets/icons/disc.svg'),
          ),
          validator: SongValidators.validateTitle,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: albumController,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Álbum (opcional)',
            prefixIcon: svgPrefixIcon('assets/icons/disc-3.svg'),
          ),
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: keyController,
          focusNode: keyFocusNode,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Tom',
            hintText: 'Ex: C, D#, Em, Ab',
            prefixIcon: svgPrefixIcon('assets/icons/music-2.svg'),
          ),
          validator: SongValidators.validateKey,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: bpmController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'BPM (opcional)',
            prefixIcon: svgPrefixIcon('assets/icons/time.svg'),
          ),
          validator: SongValidators.validateBpm,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: youTubeUrlController,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'URL YouTube (opcional)',
            prefixIcon: svgPrefixIcon('assets/icons/logo-youtube.svg'),
          ),
          validator: SongValidators.validateYouTubeUrl,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: spotifyUrlController,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'URL Spotify (opcional)',
            prefixIcon: svgPrefixIcon('assets/icons/icon-spotify.svg'),
          ),
          validator: SongValidators.validateUrl,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: deezerUrlController,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'URL Deezer (opcional)',
            prefixIcon: svgPrefixIcon('assets/icons/icon-deezer.svg'),
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
