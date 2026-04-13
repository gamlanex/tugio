import 'package:flutter/material.dart';
import '../models/provider.dart';
import '../models/service_type.dart';
import '../repositories/service_type_repository.dart';
import '../repositories/mock_service_type_repository.dart';
import '../repositories/http_service_type_repository.dart';
import '../widgets/cached_svg_icon.dart';
import '../main.dart' show useMockNotifier;
import 'map_search_screen.dart';

class ServiceTypeScreen extends StatefulWidget {
  final void Function(ServiceProvider) onProviderSubscribed;

  const ServiceTypeScreen({
    super.key,
    required this.onProviderSubscribed,
  });

  @override
  State<ServiceTypeScreen> createState() => _ServiceTypeScreenState();
}

class _ServiceTypeScreenState extends State<ServiceTypeScreen> {
  late final ServiceTypeRepository _repo;
  List<ServiceType> _types = [];
  bool _loading = true;
  String? _error;
  String? _errorDetail;

  @override
  void initState() {
    super.initState();
    _repo = useMockNotifier.value
        ? MockServiceTypeRepository()
        : HttpServiceTypeRepository();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _errorDetail = null;
    });
    try {
      final types = await _repo.getAll();
      if (mounted) setState(() => _types = types);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Nie udało się pobrać kategorii.\nSprawdź połączenie.';
          _errorDetail = e.toString();
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openSearch(ServiceType type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapSearchScreen(
          serviceType: type.isOther ? null : type.name,
          serviceTypeLabel: type.name,
          onProviderSubscribed: (provider) {
            widget.onProviderSubscribed(provider);
            Navigator.popUntil(context, (route) => route.isFirst);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wybierz typ usługi'),
        centerTitle: true,
        elevation: 0,
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          final isLandscape = orientation == Orientation.landscape;
          final crossAxisCount = isLandscape ? 5 : 3;
          final childAspectRatio = isLandscape ? 1.3 : 0.95;

          return Padding(
            padding: EdgeInsets.all(isLandscape ? 10 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Nagłówek ───────────────────────────────────
                if (!isLandscape) ...[
                  const Text(
                    'Czego szukasz?',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Wybierz kategorię, a pokażemy Ci usługodawców w Twojej okolicy.',
                    style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurface.withOpacity(0.55),
                        height: 1.4),
                  ),
                  const SizedBox(height: 20),
                ] else
                  const SizedBox(height: 8),

                // ── Siatka ─────────────────────────────────────
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? _ErrorView(message: _error!, detail: _errorDetail, onRetry: _load)
                          : GridView.builder(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: childAspectRatio,
                              ),
                              itemCount: _types.length,
                              itemBuilder: (context, index) {
                                final type = _types[index];
                                return _TypeCard(
                                  type: type,
                                  compact: isLandscape,
                                  onTap: () => _openSearch(type),
                                );
                              },
                            ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Karta kategorii ───────────────────────────────────────────────────────────

class _TypeCard extends StatelessWidget {
  final ServiceType type;
  final VoidCallback onTap;
  final bool compact;

  const _TypeCard({
    required this.type,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconBoxSize = compact ? 38.0 : 56.0;
    final iconSize = compact ? 20.0 : 28.0;
    final fontSize = compact ? 10.5 : 12.0;
    final gap = compact ? 6.0 : 10.0;
    final radius = compact ? 12.0 : 18.0;
    final color = type.color;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              blurRadius: 12,
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Ikona SVG z cache (fallback: litera) ───────────
            Container(
              width: iconBoxSize,
              height: iconBoxSize,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(radius * 0.8),
              ),
              child: Center(
                child: CachedSvgIcon(
                  iconUrl: type.iconUrl,
                  size: iconSize,
                  color: color,
                  fallbackLetter: type.initial,
                ),
              ),
            ),
            SizedBox(height: gap),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                type.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widok błędu z przyciskiem retry ──────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final String? detail;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, this.detail, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 48, color: cs.onSurface.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: cs.onSurface.withOpacity(0.6),
                  fontSize: 14,
                  height: 1.5),
            ),
            if (detail != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.errorContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  detail!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: cs.onSurface.withOpacity(0.45),
                      fontSize: 11,
                      height: 1.4,
                      fontFamily: 'monospace'),
                ),
              ),
            ],
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Spróbuj ponownie'),
            ),
          ],
        ),
      ),
    );
  }
}
