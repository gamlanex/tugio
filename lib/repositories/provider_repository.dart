import '../models/provider.dart';

/// Abstrakcyjne repozytorium usługodawców.
/// Mock → podmień na implementację HTTP żeby podłączyć API.
abstract class ProviderRepository {
  /// Zwraca listę zasubskrybowanych usługodawców.
  Future<List<ServiceProvider>> getSubscribed();

  /// Subskrybuje nowego usługodawcę.
  Future<void> subscribe(ServiceProvider provider);

  /// Odsubskrybowuje usługodawcę.
  Future<void> unsubscribe(String providerId);
}
