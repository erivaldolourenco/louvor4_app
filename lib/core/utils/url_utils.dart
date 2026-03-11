class UrlUtils {
  static bool isValidNetworkUrl(String? value) {
    if (value == null) return false;
    final text = value.trim();
    if (text.isEmpty) return false;

    final uri = Uri.tryParse(text);
    if (uri == null) return false;
    if ((uri.scheme != 'http' && uri.scheme != 'https') || uri.host.isEmpty) {
      return false;
    }

    return true;
  }
}
