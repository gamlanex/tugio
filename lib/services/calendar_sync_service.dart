import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/booking.dart';
import 'auth_service.dart';
import 'device_calendar_service.dart';
import 'google_calendar_service.dart';

/// Serwis synchronizacji kalendarza.
/// Łączy eventy z Google Calendar API i systemowego kalendarza urządzenia,
/// deduplikuje je i zwraca jako listę [Booking].
///
/// Aby podłączyć prawdziwe API: podmień implementację wewnętrznych serwisów
/// (GoogleCalendarService, DeviceCalendarService) lub nadpisz [fetchEvents].
class CalendarSyncService {
  CalendarSyncService._();
  static final CalendarSyncService instance = CalendarSyncService._();

  /// Pobiera eventy z kalendarza w zakresie ±2 miesiące od [around].
  /// Automatycznie wykrywa źródło (Google / systemowy / oba / nic)
  /// na podstawie stanu logowania i platformy.
  Future<List<Booking>> fetchEvents(DateTime around) async {
    final from = DateTime(around.year, around.month - 1, 1, 0, 0);
    final to = DateTime(around.year, around.month + 2, 0, 23, 59);

    if (AuthService.instance.isSignedIn && !kIsWeb) {
      return _fetchMobileSignedIn(from, to);
    } else if (AuthService.instance.isSignedIn) {
      // Web: tylko Google Calendar API
      return GoogleCalendarService.instance.fetchEvents(from, to);
    } else if (!kIsWeb) {
      // Niezalogowany na mobilnym: systemowy kalendarz
      return DeviceCalendarService.instance.fetchEvents(from, to);
    }
    return [];
  }

  /// Zalogowany na mobilnym: łączy Google + Device Calendar z deduplikacją.
  Future<List<Booking>> _fetchMobileSignedIn(
      DateTime from, DateTime to) async {
    final googleEvents =
        await GoogleCalendarService.instance.fetchEvents(from, to);

    List<Booking> deviceEvents = [];
    try {
      deviceEvents =
          await DeviceCalendarService.instance.fetchEvents(from, to);
    } on DeviceCalendarPermissionDeniedException {
      // brak zgody na systemowy — używamy tylko Google
    } catch (_) {}

    // Deduplikacja: jeśli event z systemu ma taki sam tytuł i czas start
    // co event z Google API — pomijamy duplikat systemowy.
    final googleKeys = <String>{};
    for (final b in googleEvents) {
      googleKeys.add('${b.service}|${b.start.toIso8601String()}');
    }
    final uniqueDevice = deviceEvents.where((b) {
      final key = '${b.service}|${b.start.toIso8601String()}';
      return !googleKeys.contains(key);
    }).toList();

    return [...googleEvents, ...uniqueDevice];
  }
}
