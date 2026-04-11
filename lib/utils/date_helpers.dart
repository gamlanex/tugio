bool sameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

bool sameDateTime(DateTime a, DateTime b) {
  return sameDay(a, b) && a.hour == b.hour && a.minute == b.minute;
}

String formatDate(DateTime d) {
  return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}

String shortDate(DateTime d) {
  return '${d.day}.${d.month}';
}

String weekdayShort(int weekday) {
  const map = ['Pn', 'Wt', 'Śr', 'Cz', 'Pt', 'Sb', 'Nd'];
  return map[weekday - 1];
}

String monthName(int month) {
  const names = [
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
  return names[month - 1];
}