import 'package:flutter/material.dart';
import '../models/provider.dart';
import 'map_search_screen.dart';

class ServiceTypeScreen extends StatelessWidget {
  final void Function(ServiceProvider) onProviderSubscribed;

  const ServiceTypeScreen({
    super.key,
    required this.onProviderSubscribed,
  });

  static const List<_ServiceTypeItem> _types = [
    _ServiceTypeItem('Fryzjer', Icons.content_cut, Colors.purple),
    _ServiceTypeItem('Psycholog', Icons.psychology, Colors.teal),
    _ServiceTypeItem('Trener personalny', Icons.fitness_center, Colors.orange),
    _ServiceTypeItem('Dentysta', Icons.medical_services, Colors.blue),
    _ServiceTypeItem('Kosmetyczka', Icons.spa, Colors.pink),
    _ServiceTypeItem('Lekarz', Icons.local_hospital, Colors.red),
    _ServiceTypeItem('Fizjoterapeuta', Icons.accessibility_new, Colors.green),
    _ServiceTypeItem('Dietetyk', Icons.restaurant, Colors.amber),
    _ServiceTypeItem('Masaż', Icons.self_improvement, Colors.indigo),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('Wybierz typ usługi'),
        centerTitle: true,
        backgroundColor: Colors.white,
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
                if (!isLandscape) ...[
                  const Text(
                    'Czego szukasz?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Wybierz kategorię, a pokażemy Ci usługodawców w Twojej okolicy.',
                    style: TextStyle(
                        fontSize: 13, color: Colors.black54, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                ] else
                  const SizedBox(height: 8),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: childAspectRatio,
                    ),
                    itemCount: _types.length,
                    itemBuilder: (context, index) {
                      final item = _types[index];
                      return _TypeCard(
                        item: item,
                        compact: isLandscape,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MapSearchScreen(
                              serviceType: item.label,
                              onProviderSubscribed: (provider) {
                                onProviderSubscribed(provider);
                                Navigator.popUntil(
                                    context, (route) => route.isFirst);
                              },
                            ),
                          ),
                        ),
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

class _TypeCard extends StatelessWidget {
  final _ServiceTypeItem item;
  final VoidCallback onTap;
  final bool compact;

  const _TypeCard({
    required this.item,
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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
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
            Container(
              width: iconBoxSize,
              height: iconBoxSize,
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(radius * 0.8),
              ),
              child: Icon(item.icon, size: iconSize, color: item.color),
            ),
            SizedBox(height: gap),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                item.label,
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

class _ServiceTypeItem {
  final String label;
  final IconData icon;
  final Color color;

  const _ServiceTypeItem(this.label, this.icon, this.color);
}
