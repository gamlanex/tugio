import '../data/mock_data.dart';
import '../models/provider.dart';
import 'provider_repository.dart';

/// Implementacja mock — dane z mock_data.dart, bez połączenia sieciowego.
/// Zamień na HttpProviderRepository żeby podłączyć prawdziwe API.
class MockProviderRepository implements ProviderRepository {
  // Lokalna kopia — naśladuje stan serwera
  final List<ServiceProvider> _providers =
      mockProviders.where((p) => p.isSubscribed).toList();

  @override
  Future<List<ServiceProvider>> getSubscribed() async {
    // Symulacja opóźnienia sieciowego (odkomentuj przy testach UI)
    // await Future.delayed(const Duration(milliseconds: 300));
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
