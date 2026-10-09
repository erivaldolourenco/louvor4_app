import 'package:intl/intl.dart';

abstract final class DashboardFormat {
  /// "2026-09" -> "set".
  static String shortMonth(String yearMonth) {
    final date = _parse(yearMonth);
    if (date == null) return yearMonth;
    return DateFormat('MMM', 'pt_BR').format(date).replaceAll('.', '');
  }

  /// "2026-09" -> "Setembro de 2026".
  static String longMonth(String yearMonth) {
    final date = _parse(yearMonth);
    if (date == null) return yearMonth;
    final text = DateFormat("MMMM 'de' y", 'pt_BR').format(date);
    return text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
  }

  static String percent(double rate) => '${(rate * 100).round()}%';

  static String yearMonth(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}';

  static DateTime? _parse(String yearMonth) {
    final parts = yearMonth.split('-');
    if (parts.length != 2) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    if (year == null || month == null) return null;
    return DateTime(year, month);
  }
}
