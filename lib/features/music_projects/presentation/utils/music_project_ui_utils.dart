import '../../domain/entities/music_project_entity.dart';

class MusicProjectUiUtils {
  static String typeLabel(MusicProjectType type) {
    switch (type) {
      case MusicProjectType.ministry:
        return 'Ministério';
      case MusicProjectType.band:
        return 'Banda';
      case MusicProjectType.singer:
        return 'Cantor(a)';
      case MusicProjectType.unknown:
        return 'Projeto';
    }
  }

  static String formatEventDateTime(DateTime date, String time) {
    const months = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];

    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    final normalizedTime = time.trim().isEmpty ? '--:--' : time.trim();
    return '$day $month, $normalizedTime';
  }
}
