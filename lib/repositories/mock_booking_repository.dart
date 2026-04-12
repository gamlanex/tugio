import '../data/mock_data.dart';
import '../models/booking.dart';
import 'booking_repository.dart';

/// Implementacja mock — dane w pamięci, bez połączenia sieciowego.
/// Zamień na HttpBookingRepository żeby podłączyć prawdziwe API.
class MockBookingRepository implements BookingRepository {
  @override
  Future<List<Booking>> getInitial(DateTime today) async {
    return initialBookings(today);
  }

  @override
  Future<void> create(Booking booking) async {
    // Mock: nic nie robi — stan zarządzany lokalnie w ekranie
  }

  @override
  Future<void> cancel(String bookingId) async {
    // Mock: nic nie robi — stan zarządzany lokalnie w ekranie
  }

  @override
  Future<void> update(Booking booking) async {
    // Mock: nic nie robi — stan zarządzany lokalnie w ekranie
  }
}
