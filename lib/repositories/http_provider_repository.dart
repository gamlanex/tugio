import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/provider.dart';
import 'provider_repository.dart';

/// Implementacja HTTP — łączy się z prawdziwym API (lub Mockoon).
/// Zamień MockProviderRepository na tę klasę żeby używać API.
class HttpProviderRepository implements ProviderRepository {
  final String _base = AppConfig.apiBaseUrl;

  @override
  Future<List<ServiceProvider>> getSubscribed() async {
    final uri = Uri.parse('$_base/providers?subscribed=true');
    final response =
        await http.get(uri).timeout(AppConfig.requestTimeout);

    if (response.statusCode != 200) {
      throw Exception('GET /providers failed: ${response.statusCode}');
    }

    final List<dynamic> json = jsonDecode(response.body);
    return json.map((e) => _fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> subscribe(ServiceProvider provider) async {
    final uri = Uri.parse('$_base/providers/${provider.id}/subscribe');
    final response = await http
        .post(uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'userId': 'current'}))
        .timeout(AppConfig.requestTimeout);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('POST /subscribe failed: ${response.statusCode}');
    }
  }

  @override
  Future<void> unsubscribe(String providerId) async {
    final uri = Uri.parse('$_base/providers/$providerId/subscribe');
    final response = await http
        .delete(uri)
        .timeout(AppConfig.requestTimeout);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('DELETE /subscribe failed: ${response.statusCode}');
    }
  }

  // ─── mapowanie JSON → model ───────────────────────────────
  ServiceProvider _fromJson(Map<String, dynamic> j) {
    return ServiceProvider(
      id: j['id'] as String,
      name: j['name'] as String,
      serviceType: j['serviceType'] as String,
      address: j['address'] as String,
      lat: (j['lat'] as num).toDouble(),
      lng: (j['lng'] as num).toDouble(),
      slots: List<String>.from(j['slots'] ?? []),
      confirmationSlots: List<String>.from(j['confirmationSlots'] ?? []),
      slotStaff: (j['slotStaff'] as Map<String, dynamic>? ?? {}).map(
        (k, v) => MapEntry(k, List<String>.from(v as List)),
      ),
      isSubscribed: j['isSubscribed'] as bool? ?? true,
      rating: (j['rating'] as num?)?.toDouble(),
      description: j['description'] as String?,
      phone: j['phone'] as String?,
      website: j['website'] as String?,
      openingHours: (j['openingHours'] as Map<String, dynamic>? ?? {}).map(
        (k, v) => MapEntry(k, v as String),
      ),
    );
  }
}
