import 'package:flutter/material.dart';
import '../../../models/provider.dart';
import '../../../utils/provider_avatar.dart';

class ProvidersSection extends StatelessWidget {
  final List<ServiceProvider> providers;
  final ServiceProvider selectedProvider;
  final bool expanded;
  final VoidCallback onToggle;
  final void Function(ServiceProvider) onProviderSelected;
  final void Function(ServiceProvider) onProviderDetail;

  const ProvidersSection({
    super.key,
    required this.providers,
    required this.selectedProvider,
    required this.expanded,
    required this.onToggle,
    required this.onProviderSelected,
    required this.onProviderDetail,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            color: Colors.black.withOpacity(0.06),
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Nagłówek z chevronem ──────────────────────────
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Moi usługodawcy',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.keyboard_arrow_down,
                        color: cs.onSurface.withOpacity(0.45)),
                  ),
                ],
              ),
            ),
          ),

          // ── Siatka usługodawców (rozwinięta) ─────────────────
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: _buildGrid(context),
            ),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    Widget providerCard(ServiceProvider p) {
      final selected = p.id == selectedProvider.id;
      final cs = Theme.of(context).colorScheme;
      return InkWell(
        onTap: () => onProviderSelected(p),
        onDoubleTap: () => onProviderDetail(p),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 148,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? cs.primary.withOpacity(0.1)
                : cs.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? cs.primary : Colors.transparent,
              width: 1.4,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ProviderAvatar(serviceType: p.serviceType, radius: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: selected ? cs.primary : cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            p.serviceType,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 10.5,
                                color: Colors.grey.shade600),
                          ),
                        ),
                        if (p.rating != null) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.star,
                              size: 10, color: Colors.amber.shade600),
                          Text(
                            p.rating!.toStringAsFixed(1),
                            style: TextStyle(
                                fontSize: 10.5,
                                color: Colors.grey.shade700),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (providers.length <= 4) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: providers.map(providerCard).toList(),
      );
    }

    const double rowH = 58;
    const double gap = 8;
    final topRow = <ServiceProvider>[];
    final bottomRow = <ServiceProvider>[];
    for (var i = 0; i < providers.length; i++) {
      (i.isEven ? topRow : bottomRow).add(providers[i]);
    }

    return SizedBox(
      height: rowH * 2 + gap,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: topRow
                  .map((p) => Padding(
                        padding: const EdgeInsets.only(right: gap),
                        child: SizedBox(height: rowH, child: providerCard(p)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: gap),
            Row(
              children: bottomRow
                  .map((p) => Padding(
                        padding: const EdgeInsets.only(right: gap),
                        child: SizedBox(height: rowH, child: providerCard(p)),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
