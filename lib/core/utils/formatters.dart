import 'package:intl/intl.dart';

String formatDate(DateTime date) {
  return DateFormat('dd/MM/yyyy').format(date);
}

String formatTime(String time) {
  if (time.length >= 5) return time.substring(0, 5);
  return time;
}