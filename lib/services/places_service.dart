// PlacesService — Overpass API (OpenStreetMap) — BEZ klucza API
// Zwraca prawdziwe miejsca (POI) z okolicy podanej lokalizacji.

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/provider.dart';
import 'language_service.dart';

class PlacesService {
  // Mapowanie typów usług na tagi OSM
  static const Map<String, String> _osmAmenity = {
    'Fryzjer':           'hairdresser',
    'Psycholog':         'psychotherapist',
    'Trener personalny': 'sports_centre',
    'Dentysta':          'dentist',
    'Kosmetyczka':       'beauty',
    'Lekarz':            'doctors',
    'Fizjoterapeuta':    'physiotherapist',
    'Dietetyk':          'dietitian',
    'Masaż':             'massage',
  };

  static const Map<String, String> _osmShop = {
    'Fryzjer': 'hairdresser',
    'Kosmetyczka': 'beauty',
  };

  /// Szuka miejsc w pobliżu [lat]/[lng] przez Overpass API.
  /// Fallback na mock jeśli sieć niedostępna lub brak wyników.
  static Future<List<ServiceProvider>> searchNearby({
    required double lat,
    required double lng,
    required String? serviceType,
    double radiusMeters = 3000,
  }) async {
    final effectiveType = serviceType ?? LanguageService.instance.text(pl: 'Inne', en: 'Other');
    final amenityTag = _osmAmenity[effectiveType];
    final shopTag    = _osmShop[effectiveType];

    // Budujemy zapytanie Overpass QL
    // Szukamy zarówno node/way/relation z odpowiednim tagiem
    final queries = <String>[];
    if (amenityTag != null) {
      queries.add('node["amenity"="$amenityTag"](around:$radiusMeters,$lat,$lng);');
      queries.add('way["amenity"="$amenityTag"](around:$radiusMeters,$lat,$lng);');
    }
    if (shopTag != null) {
      queries.add('node["shop"="$shopTag"](around:$radiusMeters,$lat,$lng);');
      queries.add('way["shop"="$shopTag"](around:$radiusMeters,$lat,$lng);');
    }
    // Fallback dla nieznanych typów — szukamy po nazwie kategorii w tagu name
    if (queries.isEmpty) {
      queries.add(
          'node["amenity"](around:$radiusMeters,$lat,$lng);');
    }

    final overpassQuery = '[out:json][timeout:15];(${queries.join('')});out center 20;';
    final uri = Uri.parse('https://overpass-api.de/api/interpreter');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'data': overpassQuery},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        final elements = json['elements'] as List<dynamic>? ?? [];

        if (elements.isNotEmpty) {
          final providers = <ServiceProvider>[];
          for (final el in elements) {
            final tags = el['tags'] as Map<String, dynamic>? ?? {};
            final name = tags['name']?.toString();
            if (name == null || name.isEmpty) continue;

            // Wydobądź współrzędne (node vs way)
            double? eLat, eLng;
            if (el['type'] == 'node') {
              eLat = (el['lat'] as num?)?.toDouble();
              eLng = (el['lon'] as num?)?.toDouble();
            } else {
              final center = el['center'] as Map<String, dynamic>?;
              eLat = (center?['lat'] as num?)?.toDouble();
              eLng = (center?['lon'] as num?)?.toDouble();
            }
            if (eLat == null || eLng == null) continue;

            final phone = tags['phone']?.toString() ??
                tags['contact:phone']?.toString();
            final website = tags['website']?.toString() ??
                tags['contact:website']?.toString();

            // Buduj adres z tagów OSM
            final address = _formatAddress(tags, el);

            providers.add(ServiceProvider(
              id: 'osm_${el['id']}',
              name: name,
              serviceType: effectiveType,
              address: address,
              lat: eLat,
              lng: eLng,
              slots: const [],
              phone: phone,
              website: website,
              rating: null,
            ));
          }

          if (providers.isNotEmpty) return providers;
        }
      }
    } catch (_) {
      // sieć niedostępna — fallback
    }

    // ─── fallback: dane mock (zawsze działa offline) ──────────────
    return _mockResults(effectiveType, lat, lng);
  }

  static String _formatAddress(Map<String, dynamic> tags, dynamic el) {
    final street  = tags['addr:street']?.toString() ?? '';
    final housenr = tags['addr:housenumber']?.toString() ?? '';
    final city    = tags['addr:city']?.toString() ?? '';

    if (street.isNotEmpty && housenr.isNotEmpty && city.isNotEmpty) {
      return LanguageService.instance.isEnglish
          ? '$street $housenr, $city'
          : 'ul. $street $housenr, $city';
    }
    if (street.isNotEmpty && city.isNotEmpty) {
      return '$street, $city';
    }
    if (city.isNotEmpty) return city;
    return tags['name']?.toString() ?? '';
  }

  static List<ServiceProvider> _mockResults(
      String serviceType, double lat, double lng) {
    final names = <String, List<Map<String, String?>>>{
      'Fryzjer': [
        {'name': 'Studio Cuts', 'phone': '+48 601 111 222'},
        {'name': LanguageService.instance.text(pl: 'Fryzjer Excellent', en: 'Excellent Hairdresser'), 'phone': null},
        {'name': 'Hair by Marta', 'phone': '+48 602 333 444'},
      ],
      'Psycholog': [
        {'name': LanguageService.instance.text(pl: 'Gabinet Psychologiczny', en: 'Psychology Office'), 'phone': '+48 789 111 222'},
        {'name': LanguageService.instance.text(pl: 'Centrum Terapii', en: 'Therapy Center'), 'phone': null},
        {'name': 'Mind & Soul', 'phone': '+48 790 555 666'},
      ],
      'Trener personalny': [
        {'name': 'FitZone Studio', 'phone': '+48 512 111 222'},
        {'name': 'Power Training', 'phone': null},
        {'name': 'Active Life', 'phone': '+48 513 333 444'},
      ],
      'Dentysta': [
        {'name': 'Dental Clinic Plus', 'phone': '+48 22 111 22 33'},
        {'name': LanguageService.instance.text(pl: 'Uśmiech Dentist', en: 'Smile Dentist'), 'phone': '+48 22 444 55 66'},
        {'name': 'White Smile', 'phone': null},
      ],
    };
    final list = names[serviceType] ?? [
      {'name': '${LanguageService.instance.serviceTypeLabel(serviceType)} 1', 'phone': '+48 600 000 001'},
      {'name': '${LanguageService.instance.serviceTypeLabel(serviceType)} 2', 'phone': null},
      {'name': '${LanguageService.instance.serviceTypeLabel(serviceType)} 3', 'phone': '+48 600 000 003'},
    ];

    return List.generate(list.length, (i) {
      return ServiceProvider(
        id: 'demo_${serviceType}_$i',
        name: list[i]['name']!,
        serviceType: serviceType,
        address: LanguageService.instance.text(pl: 'ul. Przykładowa ${i * 3 + 1} (demo)', en: 'Sample St ${i * 3 + 1} (demo)'),
        lat: lat + (i - 1) * 0.006,
        lng: lng + (i - 1) * 0.006,
        slots: const [],
        phone: list[i]['phone'],
        rating: 4.0 + i * 0.2,
      );
    });
  }
}
