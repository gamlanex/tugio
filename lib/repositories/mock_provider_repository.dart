import '../data/mock_data.dart';
import '../models/provider.dart';
import 'provider_repository.dart';

/// Implementacja mock — dane w pamięci, bez połączenia sieciowego.
/// Używa statycznej listy żeby wszystkie instancje widziały te same dane.
/// Zamień na HttpProviderRepository żeby podłączyć prawdziwe API.
class MockProviderRepository implements ProviderRepository {
  // Statyczna lista — persystuje przez cały czas życia aplikacji,
  // dzielona między wszystkimi instancjami (jak MockBookingRepository).
  static final List<ServiceProvider> _providers =
      mockProviders.where((p) => p.isSubscribed).toList();

  /// Resetuje listę do stanu początkowego (np. przy wylogowaniu).
  static void reset() {
    _providers
      ..clear()
      ..addAll(mockProviders.where((p) => p.isSubscribed));
  }

  @override
  Future<List<ServiceProvider>> getSubscribed() async {
    return List.unmodifiable(_providers);
  }

  @override
  Future<void> subscribe(ServiceProvider provider) async {
    provider.isSubscribed = true;
    if (!_providers.any((p) => p.id == provider.id)) {
      _providers.add(provider);
    }
  }

  @override
  Future<void> unsubscribe(String providerId) async {
    _providers.removeWhere((p) => p.id == providerId);
  }
}
