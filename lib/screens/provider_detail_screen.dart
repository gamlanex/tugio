import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/provider.dart';
import '../services/rating_service.dart';
import '../utils/provider_avatar.dart';

class ProviderDetailScreen extends StatefulWidget {
  final ServiceProvider provider;
  final String? userId; // przekaż uid zalogowanego użytkownika

  const ProviderDetailScreen({
    super.key,
    required this.provider,
    this.userId,
  });

  @override
  State<ProviderDetailScreen> createState() => _ProviderDetailScreenState();
}

class _ProviderDetailScreenState extends State<ProviderDetailScreen> {
  // ── Stan oceny ────────────────────────────────────────────
  int _hoverRating = 0;   // gwiazdka pod palcem
  int _savedRating = 0;   // zatwierdzona ocena
  bool _isSending = false;
  String? _feedbackMsg;   // komunikat po wysłaniu

  Future<void> _submitRating(int stars) async {
    if (_isSending) return;
    setState(() {
      _savedRating = stars;
      _isSending = true;
      _feedbackMsg = null;
    });

    try {
      await RatingService.submitRating(
        providerId: widget.provider.id,
        userId: widget.userId ?? 'anonymous',
        rating: stars,
      );
      if (mounted) {
        setState(() => _feedbackMsg = 'Dziękujemy za ocenę!');
      }
    } on RatingException catch (e) {
      if (mounted) {
        setState(() {
          _savedRating = 0;
          _feedbackMsg = 'Błąd: ${e.message}';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _savedRating = 0;
          _feedbackMsg = 'Nie udało się wysłać oceny.';
        });
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // ── Akcje zewnętrzne ──────────────────────────────────────
  Future<void> _openMaps() async {
    final uri = Uri.parse(
      'https://maps.google.com/?q=${widget.provider.lat},${widget.provider.lng}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _callPhone() async {
    if (widget.provider.phone == null) return;
    final uri = Uri.parse('tel:${widget.provider.phone}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openWebsite() async {
    if (widget.provider.website == null) return;
    var url = widget.provider.website!;
    if (!url.startsWith('http')) url = 'https://$url';
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final color = serviceTypeColor(widget.provider.serviceType);
    final icon = serviceTypeIcon(widget.provider.serviceType);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // ── Gradientowy nagłówek ───────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: color,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withOpacity(0.95),
                      color.withOpacity(0.7),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 32),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: Colors.white, size: 42),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.provider.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.provider.serviceType,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                          if (widget.provider.rating != null) ...[
                            const SizedBox(width: 10),
                            Icon(Icons.star_rounded,
                                color: Colors.amber.shade300, size: 15),
                            const SizedBox(width: 3),
                            Text(
                              widget.provider.rating!.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Szybkie akcje ────────────────────────────
                  Row(
                    children: [
                      if (widget.provider.phone != null)
                        _ActionChip(
                          icon: Icons.phone_rounded,
                          label: 'Zadzwoń',
                          color: color,
                          onTap: _callPhone,
                        ),
                      if (widget.provider.phone != null)
                        const SizedBox(width: 10),
                      _ActionChip(
                        icon: Icons.map_rounded,
                        label: 'Mapa',
                        color: color,
                        onTap: _openMaps,
                      ),
                      if (widget.provider.website != null) ...[
                        const SizedBox(width: 10),
                        _ActionChip(
                          icon: Icons.language_rounded,
                          label: 'Strona',
                          color: color,
                          onTap: _openWebsite,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Opis ─────────────────────────────────────
                  if (widget.provider.description != null) ...[
                    _SectionCard(
                      title: 'O usługodawcy',
                      child: Text(
                        widget.provider.description!,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // ── Kontakt i adres ──────────────────────────
                  _SectionCard(
                    title: 'Kontakt i adres',
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: Icons.location_on_rounded,
                          color: color,
                          text: widget.provider.address,
                        ),
                        if (widget.provider.phone != null) ...[
                          const SizedBox(height: 10),
                          _InfoRow(
                            icon: Icons.phone_rounded,
                            color: color,
                            text: widget.provider.phone!,
                          ),
                        ],
                        if (widget.provider.website != null) ...[
                          const SizedBox(height: 10),
                          _InfoRow(
                            icon: Icons.language_rounded,
                            color: color,
                            text: widget.provider.website!,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Mini mapa ────────────────────────────────
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: SizedBox(
                      height: 180,
                      child: Stack(
                        children: [
                          FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(
                                  widget.provider.lat, widget.provider.lng),
                              initialZoom: 15,
                              interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.none,
                              ),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.test_1',
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(widget.provider.lat,
                                        widget.provider.lng),
                                    width: 40,
                                    height: 40,
                                    child: Icon(
                                      Icons.location_pin,
                                      color: color,
                                      size: 40,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Positioned.fill(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(onTap: _openMaps),
                            ),
                          ),
                          Positioned(
                            right: 10,
                            bottom: 10,
                            child: GestureDetector(
                              onTap: _openMaps,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.92),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.open_in_new,
                                        size: 13, color: color),
                                    const SizedBox(width: 4),
                                    Text('Otwórz w Mapach',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: color,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Godziny otwarcia ─────────────────────────
                  if (widget.provider.openingHours.isNotEmpty) ...[
                    _SectionCard(
                      title: 'Godziny otwarcia',
                      child: Column(
                        children: widget.provider.openingHours.entries.map((e) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    e.key,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  e.value,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // ── Ocena użytkownika ─────────────────────────
                  _SectionCard(
                    title: 'Twoja ocena',
                    child: _RatingWidget(
                      savedRating: _savedRating,
                      hoverRating: _hoverRating,
                      isSending: _isSending,
                      feedbackMsg: _feedbackMsg,
                      accentColor: color,
                      onHover: (v) => setState(() => _hoverRating = v),
                      onRate: _submitRating,
                    ),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Przycisk Zarezerwuj ──────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: color,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.calendar_month_rounded),
            label: const Text(
              'Pokaż kalendarz',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Widget gwiazdek ───────────────────────────────────────────────────────────

class _RatingWidget extends StatelessWidget {
  final int savedRating;
  final int hoverRating;
  final bool isSending;
  final String? feedbackMsg;
  final Color accentColor;
  final ValueChanged<int> onHover;
  final ValueChanged<int> onRate;

  const _RatingWidget({
    required this.savedRating,
    required this.hoverRating,
    required this.isSending,
    required this.feedbackMsg,
    required this.accentColor,
    required this.onHover,
    required this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    final displayRating = hoverRating > 0 ? hoverRating : savedRating;
    final labels = ['', 'Słabo', 'Ujdzie', 'Dobrze', 'Bardzo dobrze', 'Świetnie!'];

    return Column(
      children: [
        // Gwiazdki
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final star = i + 1;
            final filled = star <= displayRating;
            return GestureDetector(
              onTap: isSending || savedRating > 0 ? null : () => onRate(star),
              child: MouseRegion(
                onEnter: savedRating == 0 ? (_) => onHover(star) : null,
                onExit: savedRating == 0 ? (_) => onHover(0) : null,
                child: AnimatedScale(
                  scale: filled ? 1.18 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    child: Icon(
                      filled ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 36,
                      color: filled ? Colors.amber : Colors.grey.shade400,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 6),

        // Etykieta / spinner / komunikat
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isSending
              ? SizedBox(
                  key: const ValueKey('spinner'),
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: accentColor,
                  ),
                )
              : feedbackMsg != null
                  ? Text(
                      key: const ValueKey('feedback'),
                      feedbackMsg!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: feedbackMsg!.startsWith('Błąd') ||
                                feedbackMsg!.startsWith('Nie')
                            ? Colors.red.shade600
                            : accentColor,
                      ),
                    )
                  : Text(
                      key: ValueKey(displayRating),
                      displayRating > 0
                          ? labels[displayRating]
                          : 'Dotknij gwiazdkę, żeby ocenić',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
        ),
      ],
    );
  }
}

// ── Pomocnicze widgety ────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _InfoRow(
      {required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13.5, height: 1.4),
          ),
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionChip(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
