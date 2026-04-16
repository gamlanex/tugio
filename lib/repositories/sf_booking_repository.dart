// ─────────────────────────────────────────────────────────────────────────────
// SfBookingRepository — rezerwacje z Salesforce
//
// Salesforce object: Booking__c (custom object)
// Pola do skonfigurowania w SF:
//   Id               → booking.id
//   Name             → booking.service
//   Start__c         → booking.start          (DateTime)
//   Duration__c      → booking.durationMinutes (Number)
//   Status__c        → booking.status          (Picklist: booked/pending/inquiry)
//   Note__c          → booking.note            (Text)
//   Staff_Name__c    → booking.staffName       (Text)
//   Provider__c      → booking.providerId      (Lookup → Provider__c)
//   Pending_Since__c → booking.pendingSince    (DateTime)
//
// UWAGA: Jeśli w Salesforce masz inne nazwy pól, zmień mapowanie
//        w metodach _fromSf() i _toSf() na dole pliku.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import '../config/app_config.dart';
import '../models/booking.dart';
import '../services/language_service.dart';
import '../services/salesforce_auth_service.dart';
import 'booking_repository.dart';

class SfBookingRepository implements BookingRepository {
  final _sf = SalesforceAuthService.instance;
  final String _object = 'Booking__c';

  // Pola które pobieramy z SF (SOQL SELECT)
  static const String _fields =
      'Id, Name, Start__c, Duration__c, Status__c, '
      'Note__c, Staff_Name__c, Provider__c, Pending_Since__c';

  @override
  Future<List<Booking>> getInitial(DateTime today) async {
    // Pobierz rezerwacje od dziś - 30 dni żeby mieć też historię
    final from = today.subtract(const Duration(days: 30)).toIso8601String();

    final query = Uri.encodeComponent(
      "SELECT $_fields FROM $_object "
      "WHERE Start__c >= $from "
      "ORDER BY Start__c ASC "
      "LIMIT 200",
    );

    final uri = Uri.parse('${AppConfig.sfApiBase}/query?q=$query');
    final response = await _sf.get(uri);

    if (response.statusCode != 200) {
      throw Exception('SF GET bookings failed (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final records = data['records'] as List<dynamic>? ?? [];
    return records.map((r) => _fromSf(r as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> create(Booking booking) async {
    final uri = Uri.parse('${AppConfig.sfApiBase}/sobjects/$_object');
    final response = await _sf.post(uri, body: _toSf(booking));

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('SF POST booking failed (${response.statusCode}): ${response.body}');
    }
  }

  @override
  Future<void> cancel(String bookingId) async {
    // W Salesforce DELETE usuwa rekord — jeśli wolisz zmienić status, użyj patch
    final uri = Uri.parse('${AppConfig.sfApiBase}/sobjects/$_object/$bookingId');
    final response = await _sf.delete(uri);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('SF DELETE booking failed (${response.statusCode}): ${response.body}');
    }
  }

  @override
  Future<void> update(Booking booking) async {
    // Salesforce PATCH nie zwraca body — 204 = sukces
    final uri = Uri.parse(
        '${AppConfig.sfApiBase}/sobjects/$_object/${booking.id}');
    final response = await _sf.patch(uri, body: _toSf(booking));

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('SF PATCH booking failed (${response.statusCode}): ${response.body}');
    }
  }

  // ─── Mapowanie SF → model ─────────────────────────────────────────────────

  Booking _fromSf(Map<String, dynamic> r) {
    return Booking(
      id:              r['Id'] as String,
      service:         r['Name'] as String? ?? LanguageService.instance.text(pl: '(brak nazwy)', en: '(no name)'),
      start:           DateTime.parse(r['Start__c'] as String),
      durationMinutes: (r['Duration__c'] as num?)?.toInt() ?? 60,
      status:          _statusFrom(r['Status__c'] as String?),
      note:            r['Note__c'] as String?,
      staffName:       r['Staff_Name__c'] as String?,
      providerId:      r['Provider__c'] as String?,
      pendingSince:    r['Pending_Since__c'] != null
                         ? DateTime.tryParse(r['Pending_Since__c'] as String)
                         : null,
    );
  }

  // ─── Mapowanie model → SF ─────────────────────────────────────────────────

  Map<String, dynamic> _toSf(Booking b) => {
    'Name':            b.service,
    'Start__c':        b.start.toUtc().toIso8601String(),
    'Duration__c':     b.durationMinutes,
    'Status__c':       b.status.name,
    if (b.note != null)         'Note__c':         b.note,
    if (b.staffName != null)    'Staff_Name__c':   b.staffName,
    if (b.providerId != null)   'Provider__c':     b.providerId,
    if (b.pendingSince != null) 'Pending_Since__c': b.pendingSince!.toUtc().toIso8601String(),
  };

  BookingStatus _statusFrom(String? s) {
    switch (s?.toLowerCase()) {
      case 'pending':  return BookingStatus.pending;
      case 'inquiry':  return BookingStatus.inquiry;
      default:         return BookingStatus.booked;
    }
  }
}
