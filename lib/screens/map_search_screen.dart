// Mapa oparta na OpenStreetMap (flutter_map + latlong2) — bez klucza API
// Kafelki: CartoDB Positron (jasna, czytelna mapa)
// GPS: geolocator — pobiera prawdziwą lokalizację użytkownika

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/provider.dart';
import '../services/places_service.dart';
import '../services/language_service.dart';
import '../l10n/app_strings.dart';

class MapSearchScreen extends StatefulWidget {
  /// Typ usługi przekazywany do API (filtr). null = brak filtra (kategoria "Inne").
  final String? serviceType;

  /// Etykieta wyświetlana w AppBar — zawsze podana, nawet dla "Inne".
  final String serviceTypeLabel;

  final void Function(ServiceProvider) onProviderSubscribed;

  const MapSearchScreen({
    super.key,
    required this.serviceType,
    required this.serviceTypeLabel,
    required this.onProviderSubscribed,
  });

  @override
  State<MapSearchScreen> createState() => _MapSearchScreenState();
}

class _MapSearchScreenState extends State<MapSearchScreen> {
  // Domyślnie Warszawa — nadpisywane po pobraniu GPS
  static const LatLng _defaultCenter = LatLng(52.2297, 21.0122);

  final MapController _mapController = MapController();
  List<ServiceProvider> _results = [];
  ServiceProvider? _selectedResult;
  bool _loading = false;
  String? _error;
  LatLng _center = _defaultCenter;
  bool _locationObtained = false;

  @override
  void initState() {
    super.initState();
    _initLocationAndSearch();
  }

  // ── Lokalizacja ─────────────────────────────────────────────────
  Future<void> _initLocationAndSearch() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final position = await _getLocation();
      if (position != null && mounted) {
        setState(() {
          _center = LatLng(position.latitude, position.longitude);
          _locationObtained = true;
        });
        // Przesuń mapę na GPS
        await Future.delayed(const Duration(milliseconds: 200));
        if (mounted) {
          _mapController.move(_center, 14);
        }
      }
    } catch (_) {
      // GPS niedostępny — używamy domyślnego centrum
    }

    await _search();
  }

  Future<Position?> _getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 8),
      ),
    );
  }

  // ── Wyszukiwanie ──────────────────────────────────────────────
  Future<void> _search() async {
    setState(() {
      _loading = true;
      _error = null;
      _results = [];
      _selectedResult = null;
    });

    try {
      final providers = await PlacesService.searchNearby(
        lat: _center.latitude,
        lng: _center.longitude,
        serviceType: widget.serviceType,
      );
      if (!mounted) return;
      setState(() {
        _results = providers;
        _loading = false;
      });

      if (providers.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) _fitMarkers(providers);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = AppStrings.of(context).apiConnectionError(e.toString());
        _loading = false;
      });
    }
  }

  void _fitMarkers(List<ServiceProvider> providers) {
    if (providers.isEmpty) return;
    // Dodaj też punkt GPS do bounds
    final points = [
      _center,
      ...providers.map((p) => LatLng(p.lat, p.lng)),
    ];
    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(60),
      ),
    );
  }

  // ── SMS zaproszenie ──────────────────────────────────────────
  Future<void> _inviteViaSms(ServiceProvider provider) async {
    // Najpierw zapytaj użytkownika
    final s = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(s.inviteDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              provider.name,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              provider.phone!,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.indigo.withOpacity(0.2)),
              ),
              child: Text(
                s.inviteMessage,
                style: const TextStyle(fontSize: 12.5, height: 1.5),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.sms_rounded, size: 16),
            label: Text(s.openSmsButton),
            style: FilledButton.styleFrom(backgroundColor: Colors.indigo),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final smsText = Uri.encodeComponent(s.inviteMessage);
    // Usuwamy spacje i myślniki z numeru telefonu
    final phone = provider.phone!.replaceAll(RegExp(r'[\s\-]'), '');
    final uri = Uri.parse('sms:$phone?body=$smsText');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.of(context).smsOpenFailed)),
        );
      }
    }
  }

  // ── Znaczniki mapy ────────────────────────────────────────────
  List<Marker> get _markers {
    final markers = <Marker>[];

    // Marker GPS użytkownika
    if (_locationObtained) {
      markers.add(Marker(
        point: _center,
        width: 36,
        height: 36,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.blue, width: 2),
          ),
          child: const Icon(Icons.my_location, size: 18, color: Colors.blue),
        ),
      ));
    }

    // Markery wyników
    for (final provider in _results) {
      final isSelected = _selectedResult?.id == provider.id;
      markers.add(Marker(
        point: LatLng(provider.lat, provider.lng),
        width: 44,
        height: 44,
        child: GestureDetector(
          onTap: () => _showProviderDetails(provider),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            child: Icon(
              Icons.location_pin,
              size: isSelected ? 44 : 36,
              color: isSelected ? Colors.indigo : Colors.red.shade600,
            ),
          ),
        ),
      ));
    }

    return markers;
  }

  void _showProviderDetails(ServiceProvider provider) {
    setState(() => _selectedResult = provider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ProviderDetailSheet(
        provider: provider,
        onSubscribe: () {
          Navigator.pop(ctx);
          provider.isSubscribed = true;
          widget.onProviderSubscribed(provider);
        },
        onInvite: provider.phone != null
            ? () {
                Navigator.pop(ctx);
                _inviteViaSms(provider);
              }
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text('${s.searchTooltip}: ${widget.serviceTypeLabel}'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: s.searchTooltip,
            onPressed: _search,
          ),
          IconButton(
            icon: const Icon(Icons.my_location_rounded),
            tooltip: s.myLocationTooltip,
            onPressed: _initLocationAndSearch,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Mapa CartoDB ─────────────────────────────────────
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: 13,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                      subdomains: const ['a', 'b', 'c', 'd'],
                      userAgentPackageName: 'com.example.test_1',
                    ),
                    MarkerLayer(markers: _markers),
                  ],
                ),
                // ── Loading overlay ──────────────────────────
                if (_loading)
                  Container(
                    color: Colors.black.withOpacity(0.15),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                // ── Błąd ────────────────────────────────────
                if (_error != null)
                  Center(
                    child: Container(
                      margin: const EdgeInsets.all(24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(_error!,
                          style: const TextStyle(color: Colors.red)),
                    ),
                  ),
                // ── Chip lokalizacji ─────────────────────────
                Positioned(
                  top: 10,
                  left: 12,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _locationObtained
                        ? _InfoChip(
                            key: const ValueKey('gps'),
                            icon: Icons.gps_fixed,
                            label: s.gpsFixedLabel,
                            color: Colors.blue,
                          )
                        : _InfoChip(
                            key: const ValueKey('default'),
                            icon: Icons.gps_not_fixed,
                            label: s.gpsNotFixedLabel,
                            color: Colors.grey,
                          ),
                  ),
                ),
                // ── Atrybucja ────────────────────────────────
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black.withOpacity(0.6)
                          : Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '© OpenStreetMap contributors · © CartoDB',
                      style: TextStyle(
                          fontSize: 9,
                          color: isDark ? Colors.white70 : Colors.black54),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Lista wyników ─────────────────────────────────
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _loading
                              ? s.searchResultsLoading
                              : s.searchResultsCount(_results.length),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.55),
                          ),
                        ),
                      ),
                      if (_locationObtained)
                        Row(
                          children: [
                            Icon(Icons.gps_fixed,
                                size: 12, color: Colors.blue.shade600),
                            const SizedBox(width: 4),
                            Text('GPS',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.blue.shade600,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: _results.isEmpty && !_loading
                      ? Center(
                          child: Text(
                            s.noResults,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.45),
                                height: 1.5),
                          ),
                        )
                      : ListView.separated(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _results.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final provider = _results[index];
                            final isSelected =
                                _selectedResult?.id == provider.id;
                            return _ResultTile(
                              provider: provider,
                              isSelected: isSelected,
                              onTap: () {
                                setState(() => _selectedResult = provider);
                                _mapController.move(
                                  LatLng(provider.lat, provider.lng),
                                  15,
                                );
                                _showProviderDetails(provider);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chip info (GPS / domyślna) ──────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip({super.key, required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(blurRadius: 6, color: Colors.black.withOpacity(0.1))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Kafelek wyników ──────────────────────────────────────────────────────────
class _ResultTile extends StatelessWidget {
  final ServiceProvider provider;
  final bool isSelected;
  final VoidCallback onTap;

  const _ResultTile({
    required this.provider,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.indigo.withOpacity(0.08)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.indigo : Colors.transparent,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 8,
              color: Colors.black.withOpacity(0.04),
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.indigo.withOpacity(0.1),
              child: Text(
                provider.name[0],
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.indigo.shade700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.name,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    provider.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.55)),
                  ),
                  if (provider.phone != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.phone_rounded,
                            size: 10, color: Colors.teal.shade600),
                        const SizedBox(width: 3),
                        Text(
                          provider.phone!,
                          style: TextStyle(
                              fontSize: 10.5, color: Colors.teal.shade700),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (provider.rating != null) ...[
              Icon(Icons.star, size: 13, color: Colors.amber.shade600),
              const SizedBox(width: 3),
              Text(
                provider.rating!.toStringAsFixed(1),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(width: 8),
            Icon(Icons.chevron_right,
                size: 20,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35)),
          ],
        ),
      ),
    );
  }
}

// ── Detail sheet ─────────────────────────────────────────────────────────────
class _ProviderDetailSheet extends StatelessWidget {
  final ServiceProvider provider;
  final VoidCallback onSubscribe;
  final VoidCallback? onInvite;

  const _ProviderDetailSheet({
    required this.provider,
    required this.onSubscribe,
    this.onInvite,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final cs = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final hasPhone = provider.phone != null;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Uchwyt
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Nagłówek
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.indigo.withOpacity(0.12),
                child: Text(
                  provider.name[0],
                  style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700,
                    color: Colors.indigo.shade700,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(provider.name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(LanguageService.instance.serviceTypeLabel(provider.serviceType),
                        style: TextStyle(
                            fontSize: 13,
                            color: cs.onSurface.withOpacity(0.55))),
                    if (provider.rating != null) ...[
                      const SizedBox(height: 3),
                      Row(children: [
                        Icon(Icons.star, size: 14, color: Colors.amber.shade600),
                        const SizedBox(width: 4),
                        Text(provider.rating!.toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                      ]),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Adres
          Row(children: [
            Icon(Icons.location_on_outlined,
                size: 16, color: Colors.grey.shade500),
            const SizedBox(width: 6),
            Expanded(
              child: Text(provider.address,
                  style: TextStyle(
                      fontSize: 13, color: cs.onSurface.withOpacity(0.65))),
            ),
          ]),

          // Telefon
          if (hasPhone) ...[
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.phone_rounded, size: 15, color: Colors.teal.shade600),
              const SizedBox(width: 6),
              Text(provider.phone!,
                  style: TextStyle(
                      fontSize: 13, color: Colors.teal.shade700,
                      fontWeight: FontWeight.w600)),
            ]),
          ],

          const SizedBox(height: 14),

          // ── Info: usługodawca poza Tugio ─────────────────────
          Text(
            s.providerNotInTugio,
            style: TextStyle(
                fontSize: 13, color: Colors.grey.shade600, height: 1.4),
          ),
          const SizedBox(height: 16),

          // ── Duży przycisk Zaproś (tylko jeśli ma telefon) ────
          if (hasPhone && onInvite != null)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onInvite,
                icon: const Icon(Icons.sms_rounded, size: 20),
                label: Text(s.inviteButton,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            )
          else
            // Brak telefonu — nie można zaprosić
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: null,
                icon: Icon(Icons.phone_disabled_rounded,
                    size: 18, color: Colors.grey.shade400),
                label: Text(s.noPhoneLabel,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
