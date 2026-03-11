class SongValidators {
  static final RegExp _keyRegex = RegExp(r'^[A-G](#|b)?m?$');
  static final RegExp _bpmRegex = RegExp(r'^\d{1,3}$');

  static String? validateArtist(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Informe o artista.';
    if (text.length < 3) return 'O artista deve ter pelo menos 3 caracteres.';
    return null;
  }

  static String? validateTitle(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Informe o título da música.';
    if (text.length < 3) return 'O título deve ter pelo menos 3 caracteres.';
    return null;
  }

  static String? validateKey(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Informe o tom da música.';
    if (!_keyRegex.hasMatch(text)) {
      return 'Tom inválido. Use C, D, E, F, G, A ou B com #, b e/ou m (ex: C#m, Eb, Em).';
    }
    return null;
  }

  static String? validateBpm(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    if (!_bpmRegex.hasMatch(text)) {
      return 'BPM inválido. Use apenas números (até 3 dígitos).';
    }
    return null;
  }

  static String? validateYouTubeUrl(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Informe a URL do YouTube.';

    final uri = Uri.tryParse(text);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return 'Informe uma URL válida.';
    }

    return null;
  }

  static String normalizeKey(String value) {
    final text = value.trim();
    if (text.isEmpty) return text;

    final first = text[0].toUpperCase();
    final rest = text.length > 1 ? text.substring(1) : '';
    return '$first${rest.replaceAll('M', 'm')}';
  }
}
