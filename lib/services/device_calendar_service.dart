import 'package:device_calendar_plus/device_calendar_plus.dart' as dc;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/booking.dart';

class DeviceCalendarService {
  DeviceCalendarService._();
  static final DeviceCalendarService instance = DeviceCalendarService._();

  Future<PermissionResult> requestPermission() async {
    // Kalendarz urządzenia niedostępny na Web
    if (kIsWeb) return PermissionResult.denied;

    final current = await dc.DeviceCalendar.instance.hasPermissions();
    if (current == dc.CalendarPermissionStatus.granted) {
      return PermissionResult.granted;
    }

    final requested = await dc.DeviceCalendar.instance.requestPermissions();
    if (requested == dc.CalendarPermissionStatus.granted) {
      return PermissionResult.granted;
    }

    return PermissionResult.denied;
  }

  Future<List<Booking>> fetchEvents(DateTime from, DateTime to) async {
    // Kalendarz urządzenia niedostępny na Web — zwróć pustą listę
    if (kIsWeb) return [];

    final permissionResult = await requestPermission();
    if (permissionResult == PermissionResult.denied) {
      throw DeviceCalendarPermissionDeniedException();
    }

    final calendars = await dc.DeviceCalendar.instance.listCalendars();
    final calendarIds = calendars
        .map((c) => c.id)
        .whereType<String>()
        .toList();

    if (calendarIds.isEmpty) return [];

    final events = await dc.DeviceCalendar.instance.listEvents(
      from,
      to,
      calendarIds: calendarIds,
    );

    final result = <Booking>[];

    for (final e in events) {
      final start = e.startDate;
      final end = e.endDate;
      if (start == null || end == null) continue;

      final duration = end.difference(start).inMinutes;
      if (duration <= 0) continue;

      final title = (e.title != null && e.title!.trim().isNotEmpty)
          ? e.title!.trim()
          : 'Event z kalendarza';

      final id =
          'device:${e.instanceId ?? e.eventId ?? '${start.millisecondsSinceEpoch}:$title'}';

      final bool allDay = (e.isAllDay == true) ||
          (start.hour == 0 &&
              start.minute == 0 &&
              end.hour == 0 &&
              end.minute == 0 &&
              duration >= 24 * 60);

      result.add(
        Booking(
          id: id,
          service: title,
          start: start,
          durationMinutes: duration,
          status: BookingStatus.booked,
          note: 'Imported from device calendar',
          importedFromDeviceCalendar: true,
          isAllDay: allDay,
        ),
      );
    }

    return result;
  }
}

enum PermissionResult { granted, denied }

class DeviceCalendarPermissionDeniedException implements Exception {
  @override
  String toString() => 'Brak zgody na odczyt kalendarza urządzenia';
}