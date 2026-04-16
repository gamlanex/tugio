import '../services/language_service.dart';

bool sameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

bool sameDateTime(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day && a.hour == b.hour && a.minute == b.minute;
}

String formatDate(DateTime d) {
  final day = d.day.toString().padLeft(2, '0');
  final month = d.month.toString().padLeft(2, '0');
  final year = d.year.toString();
  return LanguageService.instance.isEnglish
      ? '$month/$day/$year'
      : '$day.$month.$year';
}

String shortDate(DateTime d) {
  return LanguageService.instance.isEnglish
      ? '${d.month}/${d.day}'
      : '${d.day}.${d.month}';
}

String weekdayShort(int weekday) {
  const pl = ['Pn', 'Wt', 'Śr', 'Cz', 'Pt', 'Sb', 'Nd'];
  const en = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final names = LanguageService.instance.isEnglish ? en : pl;
  return names[weekday - 1];
}

String monthName(int month) {
  const pl = [
    'Styczeń',
    'Luty',
    'Marzec',
    'Kwiecień',
    'Maj',
    'Czerwiec',
    'Lipiec',
    'Sierpień',
    'Wrzesień',
    'Październik',
    'Listopad',
    'Grudzień',
  ];
  const en = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  final names = LanguageService.instance.isEnglish ? en : pl;
  return names[month - 1];
}
