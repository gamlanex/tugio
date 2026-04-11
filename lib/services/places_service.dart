// PlacesService — korzysta z Nominatim (OpenStreetMap) — BEZ klucza API
// Dokumentacja: https://nominatim.org/release-docs/latest/api/Search/

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/provider.dart';

class PlacesService {
  // Mapowanie typów usług na tagi OSM (amenity / shop / leisure)
  static const Map<String, String> _osmTags = {
    'Fryzjer': 'hairdresser',
    'Psycholog': 'psychotherapist',
    'Trener personalny': 'sports_centre',
    'Dentysta': 'dentist',
    'Kosmetyczka': 'beauty',
    'Lekarz': 'doctors',
    'Fizjoterapeuta': 'physiotherapist',
    'Dietetyk': 'dietitian',
    'Masaż': 'massage',
  };

  /// Szuka miejsc w pobliżu podanej lokalizacji przez Nominatim.
  /// Jeśli Nominatim nie zwróci wyników, fallback na dane demo.
  static Future<List<ServiceProvider>> searchNearby({
    required double lat,
    required double lng,
    required String serviceType,
    double radiusMeters = 3000,
  }) async {
    final tag = _osmTags[serviceType] ?? serviceType.toLowerCase();

    // Nominatim search — szuka po nazwie kategorii w pobliżu
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/search'
      '?q=${Uri.encodeComponent(serviceType)}'
      '&format=json'
      '&addressdetails=1'
      '&limit=15'
      '&viewbox=${lng - 0.05},${lat + 0.05},${lng + 0.05},${lat - 0.05}'
      '&bounded=1',
    );

    try {
      final response = await http.get(
        uri,
        headers: {
          // Nominatim wymaga User-Agent z nazwą aplikacji
          'User-Agent': 'TugioApp/1.0 (flutter)',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          return data.map((r) {
            return ServiceProvider(
              id: 'osm_${r['place_id']}',
              name: r['display_name']?.toString().split(',').first ?? serviceType,
              serviceType: serviceType,
              address: _formatAddress(r['address']),
              lat: double.tryParse(r['lat'].toString()) ?? lat,
              lng: double.tryParse(r['lon'].toString()) ?? lng,
              slots: _defaultSlots(),
              rating: null, // Nominatim nie zwraca ocen
            );
          }).toList();
        }
      }
    } catch (_) {
      // sieć niedostępna — użyj danych demo
    }

    // ─── fallback: dane demo (zawsze działa) ──────────────
    return _mockResults(serviceType, lat, lng);
  }

  static String _formatAddress(dynamic address) {
    if (address == null) return '';
    final road = address['road'] ?? address['pedestrian'] ?? '';
    final city = address['city'] ?? address['town'] ?? address['village'] ?? '';
    if (road.isNotEmpty && city.isNotEmpty) return '$road, $city';
    if (city.isNotEmpty) return city.toString();
    return '';
  }

  static List<String> _defaultSlots() =>
      ['09:00', '10:00', '11:00', '14:00', '15:00', '16:00'];

  static List<ServiceProvider> _mockResults(
      String serviceType, double lat, double lng) {
    final names = <String, List<String>>{
      'Fryzjer': ['Studio Cuts', 'Fryzjer Excellent', 'Hair by Marta'],
      'Psycholog': ['Gabinet Psychologiczny', 'Centrum Terapii', 'Mind & Soul'],
      'Trener personalny': ['FitZone Studio', 'Power Training', 'Active Life'],
      'Dentysta': ['Dental Clinic Plus', 'Uśmiech Dentist', 'White Smile'],
      'Kosmetyczka': ['Beauty Studio', 'Salon Kosmetyczny', 'Glow Beauty'],
      'Lekarz': ['Przychodnia Centralna', 'Gabinet Lekarski', 'Klinika Zdrowie'],
      'Fizjoterapeuta': ['FizjoPlus', 'Ruch i Zdrowie', 'Rehabilitacja Pro'],
      'Dietetyk': ['Dieta i Zdrowie', 'NutriExpert', 'Zdrowe Odżywianie'],
      'Masaż': ['Relax Studio', 'MasażExpert', 'Zen Massage'],
    };
    final list =
        names[serviceType] ?? ['$serviceType 1', '$serviceType 2', '$serviceType 3'];

    return List.generate(list.length, (i) {
      return ServiceProvider(
        id: 'demo_${serviceType}_$i',
        name: list[i],
        serviceType: serviceType,
        address: 'ul. Przykładowa ${i * 3 + 1}, Warszawa (demo)',
        lat: lat + (i - 1) * 0.006,
        lng: lng + (i - 1) * 0.006,
        slots: _defaultSlots(),
        rating: 4.0 + i * 0.2,
      );
    });
  }
}
