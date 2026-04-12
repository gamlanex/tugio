enum BookingStatus {
  inquiry,   // zapytanie ofertowe
  booked,    // potwierdzona natychmiastowo
  pending,   // wysłana, czeka na potwierdzenie właściciela
}

class Booking {
  final String id;
  final String service;
  final DateTime start;
  final int durationMinutes;
  BookingStatus status;
  String? note;
  final bool importedFromDeviceCalendar;
  final bool isAllDay;
  /// Kiedy rezerwacja weszła w stan [BookingStatus.pending]
  final DateTime? pendingSince;

  /// Imię/nazwa pracownika wybranego przy rezerwacji (np. 'Krysia')
  final String? staffName;
  /// ID usługodawcy — pozwala wyświetlić szczegóły przy tapnięciu rezerwacji
  final String? providerId;

  Booking({
    required this.id,
    required this.service,
    required this.start,
    required this.durationMinutes,
    required this.status,
    this.note,
    this.importedFromDeviceCalendar = false,
    this.isAllDay = false,
    this.pendingSince,
    this.staffName,
    this.providerId,
  });

  DateTime get end => start.add(Duration(minutes: durationMinutes));

  String get timeText {
    if (isAllDay) return 'Cały dzień';
    return '${_two(start.hour)}:${_two(start.minute)} - ${_two(end.hour)}:${_two(end.minute)}';
  }

  static String _two(int v) => v.toString().padLeft(2, '0');
}