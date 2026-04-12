import '../models/booking.dart';

/// Abstrakcyjne repozytorium rezerwacji.
/// Mock → podmień na implementację HTTP żeby podłączyć API.
abstract class BookingRepository {
  /// Zwraca inicjalną listę rezerwacji (np. demo/seed).
  Future<List<Booking>> getInitial(DateTime today);

  /// Tworzy nową rezerwację.
  Future<void> create(Booking booking);

  /// Anuluje rezerwację o podanym id.
  Future<void> cancel(String bookingId);

  /// Aktualizuje istniejącą rezerwację (np. zmiana statusu).
  Future<void> update(Booking booking);
}
