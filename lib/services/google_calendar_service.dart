import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import '../models/booking.dart';
import 'auth_service.dart';
import 'language_service.dart';

/// Pobiera eventy z Google Calendar API v3.
/// Wymaga scope: https://www.googleapis.com/auth/calendar.readonly
/// Działa na wszystkich platformach (Android, Web, iOS, Desktop).
class GoogleCalendarService {
  GoogleCalendarService._();
  static final GoogleCalendarService instance = GoogleCalendarService._();

  static const _base = 'https://www.googleapis.com/calendar/v3';

  /// Pobiera listę wszystkich kalendarzy użytkownika.
  Future<List<String>> _fetchCalendarIds(String token) async {
    final uri = Uri.parse('$_base/users/me/calendarList').replace(
      queryParameters: {
        'showHidden': 'true',
        'showDeleted': 'false',
      },
    );
    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });
    if (response.statusCode == 401) throw GoogleCalendarNotSignedInException();
    if (response.statusCode != 200) {
      debugPrint('CalendarList error ${response.statusCode}: ${response.body}');
      return ['primary'];
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final items = (data['items'] as List?) ?? [];
    final ids = items
        .map((c) => c['id'] as String?)
        .whereType<String>()
        .toList();
    debugPrint('Znalezione kalendarze (${ids.length}): $ids');
    return ids;
  }

  /// Pobiera eventy ze WSZYSTKICH kalendarzy użytkownika.
  /// Rzuca [GoogleCalendarNotSignedInException] gdy brak sesji.
  /// Rzuca [GoogleCalendarApiException] przy błędzie API.
  Future<List<Booking>> fetchEvents(DateTime from, DateTime to) async {
    final token = await AuthService.instance.getAccessToken();
    if (token == null) throw GoogleCalendarNotSignedInException();

    // Pobierz listę wszystkich kalendarzy
    final calendarIds = await _fetchCalendarIds(token);

    final allBookings = <Booking>[];
    final seenIds = <String>{};

    for (final calId in calendarIds) {
      try {
        debugPrint('Pobieranie eventów z kalendarza: $calId');
        final uri = Uri.parse(
          '$_base/calendars/${Uri.encodeComponent(calId)}/events',
        ).replace(
          queryParameters: {
            'timeMin': from.toUtc().toIso8601String(),
            'timeMax': to.toUtc().toIso8601String(),
            'singleEvents': 'true',
            'orderBy': 'startTime',
            'maxResults': '500',
          },
        );

        final response = await http.get(uri, headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        });

        if (response.statusCode == 401) throw GoogleCalendarNotSignedInException();
        if (response.statusCode != 200) {
          debugPrint('Błąd kalendarza $calId: ${response.statusCode}: ${response.body}');
          continue;
        }

        final data = json.decode(response.body) as Map<String, dynamic>;
        final items = (data['items'] as List?) ?? [];

        debugPrint('Kalendarz $calId: znaleziono ${items.length} eventów w zakresie dat');
        for (final item in items) {
          final raw = item as Map<String, dynamic>;
          final title = raw['summary'] ?? LanguageService.instance.text(pl: '(brak tytułu)', en: '(no title)');
          final start = (raw['start'] as Map?)??{};
          final startStr = start['dateTime'] ?? start['date'] ?? '?';
          debugPrint('  -> $title @ $startStr');

          final b = _parseEvent(raw);
          // deduplikacja — ten sam event może być w kilku kalendarzach
          if (b != null && seenIds.add(b.id)) {
            allBookings.add(b);
          }
        }
      } catch (e) {
        if (e is GoogleCalendarNotSignedInException) rethrow;
        // błąd jednego kalendarza nie blokuje reszty
        continue;
      }
    }

    return allBookings;
  }

  Booking? _parseEvent(Map<String, dynamic> item) {
    final summary = (item['summary'] as String?)?.trim();
    if (summary == null || summary.isEmpty) return null;

    final id = item['id'] as String? ??
        DateTime.now().millisecondsSinceEpoch.toString();

    // Czas start
    final startMap = item['start'] as Map<String, dynamic>?;
    if (startMap == null) return null;
    final startStr =
        startMap['dateTime'] as String? ?? startMap['date'] as String?;
    if (startStr == null) return null;
    final isAllDay = startMap['dateTime'] == null;

    // Czas end
    final endMap = item['end'] as Map<String, dynamic>?;
    final endStr =
        endMap?['dateTime'] as String? ?? endMap?['date'] as String?;

    DateTime start;
    DateTime end;
    try {
      start = DateTime.parse(startStr).toLocal();
      end = endStr != null
          ? DateTime.parse(endStr).toLocal()
          : start.add(const Duration(hours: 1));
    } catch (_) {
      return null;
    }

    int duration = end.difference(start).inMinutes;
    // Całodniowe: end jest dniem po starcie (YYYY-MM-DD), duration może wyjść 0
    if (isAllDay && duration <= 0) duration = 24 * 60;
    if (duration <= 0) duration = 60;

    return Booking(
      id: 'gcal:$id',
      service: summary,
      start: start,
      durationMinutes: duration,
      status: BookingStatus.booked,
      note: 'Google Calendar',
      importedFromDeviceCalendar: true,
      isAllDay: isAllDay,
    );
  }
}

class GoogleCalendarNotSignedInException implements Exception {
  @override
  String toString() => LanguageService.instance.text(pl: 'Nie jesteś zalogowany przez Google', en: 'You are not signed in with Google');
}

class GoogleCalendarApiException implements Exception {
  final String message;
  GoogleCalendarApiException(this.message);
  @override
  String toString() => LanguageService.instance.text(pl: 'Błąd Google Calendar API: $message', en: 'Google Calendar API error: $message');
}
