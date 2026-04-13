import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ServiceType — typ usługi pobierany z API
//
// Serwer zwraca:
//   {
//     "id": "haircut",
//     "name": "Fryzjer",
//     "iconUrl": "http://192.168.50.206:3000/icons/haircut.svg",
//     "colorHex": "#9C27B0"
//   }
//
// iconUrl wskazuje na plik SVG hostowany na serwerze Tugio.
// Aplikacja pobiera SVG przy pierwszym użyciu i cachuje go lokalnie
// (flutter_cache_manager) — przy kolejnych uruchomieniach działa offline.
//
// Fallback kolejność:
//   1. Lokalny cache (działa offline)
//   2. Pobranie z serwera
//   3. Pierwsza litera nazwy (jeśli serwer niedostępny i brak cache)
// ─────────────────────────────────────────────────────────────────────────────

class ServiceType {
  final String id;
  final String name;

  /// URL do pliku SVG na serwerze Tugio, np.:
  /// "http://api.tugio.app/icons/haircut.svg"
  /// Może być null dla starych wpisów bez ikony.
  final String? iconUrl;

  /// Kolor tła kafelka w formacie hex, np. "#9C27B0".
  final String? colorHex;

  const ServiceType({
    required this.id,
    required this.name,
    this.iconUrl,
    this.colorHex,
  });

  factory ServiceType.fromJson(Map<String, dynamic> json) => ServiceType(
        id: json['id'] as String,
        name: json['name'] as String,
        iconUrl: json['iconUrl'] as String?,
        colorHex: json['colorHex'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconUrl': iconUrl,
        'colorHex': colorHex,
      };

  /// Kolor kafelka — fallback na szary jeśli brak lub niepoprawny hex.
  Color get color => ServiceTypeColors.resolve(colorHex);

  /// Inicjał do wyświetlenia gdy brak SVG lub ładowanie w toku.
  String get initial =>
      name.isNotEmpty ? name[0].toUpperCase() : '?';

  /// Kategoria "Inne" — specjalny fallback bez filtrowania po typie.
  static const ServiceType other = ServiceType(
    id: 'other',
    name: 'Inne',
    iconUrl: null,
    colorHex: '#607D8B',
  );

  bool get isOther => id == 'other';
}

// ── Parsowanie kolorów hex ────────────────────────────────────────────────────

class ServiceTypeColors {
  ServiceTypeColors._();

  static const Color _fallback = Color(0xFF607D8B);

  static Color resolve(String? hex) {
    if (hex == null || hex.isEmpty) return _fallback;
    try {
      final cleaned = hex.replaceAll('#', '');
      final value = int.parse(
        cleaned.length == 6 ? 'FF$cleaned' : cleaned,
        radix: 16,
      );
      return Color(value);
    } catch (_) {
      return _fallback;
    }
  }
}
