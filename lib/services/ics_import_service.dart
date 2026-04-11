import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import '../models/booking.dart';

/// Importuje eventy z pliku .ics wybranego przez użytkownika.
/// Działa na wszystkich platformach (web, Android, iOS, desktop).
class IcsImportService {
  IcsImportService._();
  static final IcsImportService instance = IcsImportService._();

  /// Otwiera dialog wyboru pliku .ics i zwraca sparsowane Booking'i.
  /// Rzuca [IcsImportCancelledException] jeśli użytkownik anulował wybór.
  /// Rzuca [IcsParseException] jeśli plik jest nieprawidłowy.
  Future<List<Booking>> pickAndImport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['ics', 'ical'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      throw IcsImportCancelledException();
    }

    final bytes = result.files.first.bytes;
    if (bytes == null) throw IcsParseException('Nie udało się odczytać pliku');

    final text = utf8.decode(bytes, allowMalformed: true);
    return _parseIcs(text);
  }

  List<Booking> _parseIcs(String text) {
    // Rozwiń linie kontynuowane (RFC 5545: linia zaczyna się od spacji/tabulatora)
    final unfolded = text.replaceAll(RegExp(r'\r?\n[ \t]'), '');
    final lines = unfolded.split(RegExp(r'\r?\n'));

    final bookings = <Booking>[];
    bool inEvent = false;

    String? uid;
    DateTime? dtStart;
    DateTime? dtEnd;
    String? summary;
    bool allDay = false;

    for (final rawLine in lines) {
      final line = rawLine.trim();

      if (line == 'BEGIN:VEVENT') {
        inEvent = true;
        uid = null;
        dtStart = null;
        dtEnd = null;
        summary = null;
        allDay = false;
        continue;
      }

      if (line == 'END:VEVENT') {
        inEvent = false;
        if (dtStart != null && summary != null) {
          final duration = dtEnd != null
              ? dtEnd!.difference(dtStart!).inMinutes
              : (allDay ? 24 * 60 : 60);
          final safeUid = uid ??
              'ics:${dtStart!.millisecondsSinceEpoch}:$summary';

          bookings.add(Booking(
            id: 'device:$safeUid',
            service: summary!,
            start: dtStart!,
            durationMinutes: duration > 0 ? duration : 60,
            status: BookingStatus.booked,
            note: 'Imported from .ics',
            importedFromDeviceCalendar: true,
            isAllDay: allDay,
          ));
        }
        continue;
      }

      if (!inEvent) continue;

      // Rozdziel klucz od wartości (uwzględnij parametry: DTSTART;TZID=...)
      final colonIdx = line.indexOf(':');
      if (colonIdx < 0) continue;
      final keyPart = line.substring(0, colonIdx).toUpperCase();
      final value = line.substring(colonIdx + 1);

      // Nazwa własności (bez parametrów)
      final propName = keyPart.split(';').first;

      switch (propName) {
        case 'UID':
          uid = value;

        case 'SUMMARY':
          summary = _unescapeIcs(value);

        case 'DTSTART':
          final parsed = _parseDateTime(keyPart, value);
          if (parsed != null) {
            dtStart = parsed.$1;
            allDay = parsed.$2;
          }

        case 'DTEND':
        case 'DUE':
          final parsed = _parseDateTime(keyPart, value);
          if (parsed != null) dtEnd = parsed.$1;
      }
    }

    return bookings;
  }

  /// Parsuje wartość DTSTART/DTEND.
  /// Zwraca (DateTime, isAllDay) lub null jeśli nie można sparsować.
  (DateTime, bool)? _parseDateTime(String keyPart, String value) {
    // Całodniowy event: DTSTART;VALUE=DATE:20250410 lub DTSTART:20250410
    final isDate = keyPart.contains('VALUE=DATE') && !keyPart.contains('DATE-TIME');
    final cleanVal = value.replaceAll(RegExp(r'[^0-9TZ+\-]'), '');

    // Format: 20250410T090000Z  lub  20250410T090000+0200  lub  20250410
    try {
      if (cleanVal.length == 8) {
        // Całodniowy: YYYYMMDD
        final y = int.parse(cleanVal.substring(0, 4));
        final m = int.parse(cleanVal.substring(4, 6));
        final d = int.parse(cleanVal.substring(6, 8));
        return (DateTime(y, m, d), true);
      }

      if (cleanVal.length >= 15) {
        final y = int.parse(cleanVal.substring(0, 4));
        final mo = int.parse(cleanVal.substring(4, 6));
        final d = int.parse(cleanVal.substring(6, 8));
        final h = int.parse(cleanVal.substring(9, 11));
        final mi = int.parse(cleanVal.substring(11, 13));
        final s = int.parse(cleanVal.substring(13, 15));

        DateTime dt;
        if (value.endsWith('Z')) {
          // UTC — konwertuj do lokalnego
          dt = DateTime.utc(y, mo, d, h, mi, s).toLocal();
        } else {
          // Czas lokalny (strefa z TZID lub bez)
          dt = DateTime(y, mo, d, h, mi, s);
        }
        return (dt, isDate);
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  String _unescapeIcs(String value) {
    return value
        .replaceAll(r'\n', '\n')
        .replaceAll(r'\N', '\n')
        .replaceAll(r'\,', ',')
        .replaceAll(r'\;', ';')
        .replaceAll(r'\\', '\\');
  }
}

class IcsImportCancelledException implements Exception {
  @override
  String toString() => 'Import anulowany';
}

class IcsParseException implements Exception {
  final String message;
  IcsParseException(this.message);
  @override
  String toString() => 'Błąd parsowania ICS: $message';
}
