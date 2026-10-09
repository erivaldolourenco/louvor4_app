const responsibilityMonthNames = [
  'Janeiro',
  'Fevereiro',
  'Março',
  'Abril',
  'Maio',
  'Junho',
  'Julho',
  'Agosto',
  'Setembro',
  'Outubro',
  'Novembro',
  'Dezembro',
];

String _two(int value) => value.toString().padLeft(2, '0');

/// 05/10
String formatShortDate(DateTime date) =>
    '${_two(date.day)}/${_two(date.month)}';

/// 05/10/2026
String formatFullDate(DateTime date) =>
    '${_two(date.day)}/${_two(date.month)}/${date.year}';

/// "01/10 a 31/10" (com ano quando os anos diferem ou não é o ano atual).
String formatPeriod(DateTime start, DateTime end) {
  final now = DateTime.now();
  final showYear = start.year != end.year || start.year != now.year;
  final format = showYear ? formatFullDate : formatShortDate;
  return '${format(start)} a ${format(end)}';
}

DateTime firstDayOfMonth(DateTime month) => DateTime(month.year, month.month);

DateTime lastDayOfMonth(DateTime month) =>
    DateTime(month.year, month.month + 1, 0);

bool isWholeMonth(DateTime start, DateTime end) =>
    start == firstDayOfMonth(start) && end == lastDayOfMonth(start);

DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);
