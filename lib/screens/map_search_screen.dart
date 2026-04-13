// Mapa oparta na OpenStreetMap (flutter_map + latlong2) — bez klucza API

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/provider.dart';
import '../services/places_service.dart';

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
  static const LatLng _defaultCenter = LatLng(52.2297, 21.0122);

  final MapController _mapController = MapController();
  List<ServiceProvider> _results = [];
  ServiceProvider? _selectedResult;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _search();
  }

  Future<void> _search() async {
    setState(() {
      _loading = true;
      _error = null;
      _results = [];
      _selectedResult = null;
    });

    try {
      final providers = await PlacesService.searchNearby(
        lat: _defaultCenter.latitude,
        lng: _defaultCenter.longitude,
        serviceType: widget.serviceType,
      );
      setState(() {
        _results = providers;
        _loading = false;
      });

      if (providers.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 300));
        _fitMarkers(providers);
      }
    } catch (e) {
      setState(() {
        _error = 'Błąd wyszukiwania: $e';
        _loading = false;
      });
    }
  }

  void _fitMarkers(List<ServiceProvider> providers) {
    if (providers.isEmpty) return;
    final points =
        providers.map((p) => LatLng(p.lat, p.lng)).toList();
    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(60),
      ),
    );
  }

  void _showProviderDetails(ServiceProvider provider) {
    setState(() => _selectedResult = provider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _ProviderDetailSheet(
        provider: provider,
        onSubscribe: () {
          Navigator.pop(ctx);
          provider.isSubscribed = true;
          widget.onProviderSubscribed(provider);
        },
      ),
    );
  }

  List<Marker> get _markers => _results.map((provider) {
        final isSelected = _selectedResult?.id == provider.id;
        return Marker(
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
        );
      }).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Szukaj: ${widget.serviceTypeLabel}'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Szukaj ponownie',
            onPressed: _search,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Mapa OpenStreetMap ───────────────────────────
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: const MapOptions(
                    initialCenter: _defaultCenter,
                    initialZoom: 13,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.test_1',
                    ),
                    MarkerLayer(markers: _markers),
                  ],
                ),
                if (_loading)
                  const Center(child: CircularProgressIndicator()),
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
                // atrybucja OSM (wymagana przez licencję)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '© OpenStreetMap contributors',
                      style: TextStyle(fontSize: 9),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Lista wyników ──────────────────────────────
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                  child: Text(
                    '${_results.length} wyników w pobliżu',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
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

// ─────────────────────────────────────────────────────────────────────────────
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
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55)),
                  ),
                ],
              ),
            ),
            if (provider.rating != null) ...[
              Icon(Icons.star, size: 13, color: Colors.amber.shade600),
              const SizedBox(width: 3),
              Text(
                provider.rating!.toStringAsFixed(1),
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600),
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

// ─────────────────────────────────────────────────────────────────────────────
class _ProviderDetailSheet extends StatelessWidget {
  final ServiceProvider provider;
  final VoidCallback onSubscribe;

  const _ProviderDetailSheet({
    required this.provider,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).padding.bottom;
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
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.indigo.withOpacity(0.12),
                child: Text(
                  provider.name[0],
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
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
                    Text(provider.serviceType,
                        style: TextStyle(
                            fontSize: 13, color: cs.onSurface.withOpacity(0.55))),
                    if (provider.rating != null) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.star,
                              size: 14, color: Colors.amber.shade600),
                          const SizedBox(width: 4),
                          Text(provider.rating!.toStringAsFixed(1),
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.location_on_outlined,
                  size: 16, color: Colors.grey.shade500),
              const SizedBox(width: 6),
              Expanded(
                child: Text(provider.address,
                    style: TextStyle(
                        fontSize: 13, color: cs.onSurface.withOpacity(0.65))),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Dostępne godziny:',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withOpacity(0.65)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: provider.slots.map((slot) {
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: Colors.indigo.withOpacity(0.3), width: 1),
                ),
                child: Text(
                  slot,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.indigo.shade700,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onSubscribe,
              icon: const Icon(Icons.add),
              label: const Text('Subskrybuj i dodaj do moich'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.indigo,
                padding: const EdgeInsets.symmetric(vertical: 14),
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
