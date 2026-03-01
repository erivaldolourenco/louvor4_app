class YoutubeUtils {
  static const String defaultThumb = 'assets/images/default-cover.png';

  /// Extrai o ID do vídeo do YouTube
  static String? extractVideoId(String? videoUrl) {
    if (videoUrl == null || videoUrl.isEmpty) return null;

    // Caso já seja o ID puro
    if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(videoUrl)) {
      return videoUrl;
    }

    final regExp = RegExp(
        r'^.*(youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|shorts\/|\&v=)([^#\&\?]{11}).*');

    final match = regExp.firstMatch(videoUrl);
    return match?.group(2);
  }

  /// Retorna a URL da thumbnail
  static String getThumbnail(String? videoUrl, {String quality = 'mqdefault'}) {
    final videoId = extractVideoId(videoUrl);
    if (videoId == null) return defaultThumb;

    // Qualidades: default, mqdefault, hqdefault, sddefault, maxresdefault
    return 'https://img.youtube.com/vi/$videoId/$quality.jpg';
  }
}