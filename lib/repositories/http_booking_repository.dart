import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/booking.dart';
import 'booking_repository.dart';

/// Implementacja HTTP — łączy się z prawdziwym API (lub Mockoon).
/// Zamień MockBookingRepository na tę klasę żeby używać API.
class HttpBookingRepository implements BookingRepository {
  final String _base = AppConfig.apiBaseUrl;

  @override
  Future<List<Booking>> getInitial(DateTime today) async {
    final uri = Uri.parse('$_base/bookings?userId=current');
    final response =
        await http.get(uri).timeout(AppConfig.requestTimeout);

    if (response.statusCode != 200) {
      throw Exception('GET /bookings failed: ${response.statusCode}');
    }

    final List<dynamic> json = jsonDecode(response.body);
    return json.map((e) => _fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> create(Booking booking) async {
    final uri = Uri.parse('$_base/bookings');
    final response = await http
        .post(uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(_toJson(booking)))
        .timeout(AppConfig.requestTimeout);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('POST /bookings failed: ${response.statusCode}');
    }
  }

  @override
  Future<void> cancel(String bookingId) async {
    final uri = Uri.parse('$_base/bookings/$bookingId');
    final response =
        await http.delete(uri).timeout(AppConfig.requestTimeout);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('DELETE /bookings/$bookingId failed: ${response.statusCode}');
    }
  }

  @override
  Future<void> update(Booking booking) async {
    final uri = Uri.parse('$_base/bookings/${booking.id}');
    final response = await http
        .put(uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(_toJson(booking)))
        .timeout(AppConfig.requestTimeout);

    if (response.statusCode != 200) {
      throw Exception('PUT /bookings/${booking.id} failed: ${response.statusCode}');
    }
  }

  // ─── mapowanie JSON → model ───────────────────────────────
  Booking _fromJson(Map<String, dynamic> j) {
    return Booking(
      id: j['id'] as String,
      service: j['service'] as String,
      start: DateTime.parse(j['start'] as String),
      durationMinutes: j['durationMinutes'] as int,
      status: _statusFromString(j['status'] as String? ?? 'booked'),
      note: j['note'] as String?,
      staffName: j['staffName'] as String?,
      providerId: j['providerId'] as String?,
      pendingSince: j['pendingSince'] != null
          ? DateTime.parse(j['pendingSince'] as String)
          : null,
    );
  }

  Map<String, dynamic> _toJson(Booking b) => {
        'id': b.id,
        'service': b.service,
        'start': b.start.toIso8601String(),
        'durationMinutes': b.durationMinutes,
        'status': b.status.name,
        if (b.note != null) 'note': b.note,
        if (b.staffName != null) 'staffName': b.staffName,
        if (b.providerId != null) 'providerId': b.providerId,
        if (b.pendingSince != null)
          'pendingSince': b.pendingSince!.toIso8601String(),
      };

  BookingStatus _statusFromString(String s) {
    switch (s) {
      case 'pending':
        return BookingStatus.pending;
      case 'inquiry':
        return BookingStatus.inquiry;
      default:
        return BookingStatus.booked;
    }
  }
}
