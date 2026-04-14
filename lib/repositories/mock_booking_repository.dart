import '../data/mock_data.dart';
import '../models/booking.dart';
import 'booking_repository.dart';

/// Implementacja mock — dane w pamięci, bez połączenia sieciowego.
/// Używa statycznej listy żeby wszystkie instancje widziały te same dane.
/// Zamień na HttpBookingRepository żeby podłączyć prawdziwe API.
class MockBookingRepository implements BookingRepository {
  // Statyczna lista persystuje przez cały czas życia aplikacji
  static final List<Booking> _extraBookings = [];

  /// Resetuje dodatkowe rezerwacje (np. przy wylogowaniu / zmianie konta)
  static void reset() => _extraBookings.clear();

  @override
  Future<List<Booking>> getInitial(DateTime today) async {
    final base = initialBookings(today);
    // Łączymy bazowe dane mock z tymi stworzonymi w trakcie sesji
    final all = [...base, ..._extraBookings];
    return all;
  }

  @override
  Future<void> create(Booking booking) async {
    // Zapisz jeśli jeszcze nie ma
    if (!_extraBookings.any((b) => b.id == booking.id)) {
      _extraBookings.add(booking);
    }
  }

  @override
  Future<void> cancel(String bookingId) async {
    _extraBookings.removeWhere((b) => b.id == bookingId);
  }

  @override
  Future<void> update(Booking booking) async {
    final idx = _extraBookings.indexWhere((b) => b.id == booking.id);
    if (idx >= 0) _extraBookings[idx] = booking;
  }
}
