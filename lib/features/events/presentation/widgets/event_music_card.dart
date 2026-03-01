import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/utils/youtube_utils.dart';

class EventMusicCard extends StatelessWidget {

  final String title;
  final String artist;
  final String musicKey;
  final String? youtubeUrl;
  const EventMusicCard({super.key, required this.title, required this.artist, required this.musicKey, this.youtubeUrl,});

  Future<void> _launchYoutube() async {
    if (youtubeUrl == null || youtubeUrl!.isEmpty) return;

    final Uri url = Uri.parse(youtubeUrl!);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // Opcional: Mostrar um alerta caso o link seja inválido
      debugPrint('Não foi possível abrir o link: $youtubeUrl');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none, // Permite que o badge do tom saia um pouco da borda
            children: [
              // 1. O CONTAINER DA CAPA (THUMBNAIL)
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    // Aqui usamos a função que você trouxe do Angular adaptada para Dart
                    image: youtubeUrl != null && youtubeUrl!.isNotEmpty
                        ? NetworkImage(YoutubeUtils.getThumbnail(youtubeUrl))
                        : const AssetImage('assets/images/default-cover.png') as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // 2. O BADGE DO TOM DA MÚSICA (KEY)
              Positioned(
                top: -5,
                right: -5,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0166FF), // Seu azul #0166ff
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Text(
                    musicKey,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(artist, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
          ),
          if (youtubeUrl != null && youtubeUrl!.isNotEmpty)
            IconButton(
              onPressed: _launchYoutube,
              icon: const Icon(
                Icons.play_circle_filled,
                color: Color(0xFFFF0000),
                size: 32,
              ),
            ),
        ],
      ),
    );
  }
}