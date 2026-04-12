import 'package:flutter/material.dart';
import '../models/provider.dart';
import '../models/booking.dart';
import '../services/auth_service.dart';
import '../utils/date_helpers.dart';
import '../utils/provider_avatar.dart';
import 'provider_detail_screen.dart';

class SubscribedProvidersScreen extends StatefulWidget {
  final List<ServiceProvider> providers;
  final ServiceProvider selectedProvider;
  final DateTime selectedDate;
  final List<Booking> bookings;
  final void Function(ServiceProvider) onProviderSelected;
  final void Function(Booking) onBookingCreated;
  final void Function(String bookingId) onBookingCancelled;

  const SubscribedProvidersScreen({
    super.key,
    required this.providers,
    required this.selectedProvider,
    required this.selectedDate,
    required this.bookings,
    required this.onProviderSelected,
    required this.onBookingCreated,
    required this.onBookingCancelled,
  });

  @override
  State<SubscribedProvidersScreen> createState() =>
      _SubscribedProvidersScreenState();
}

class _SubscribedProvidersScreenState
    extends State<SubscribedProvidersScreen> {
  late ServiceProvider? _picked;

  @override
  void initState() {
    super.initState();
    _picked = widget.selectedProvider;
  }

  // Zwraca istniejącą rezerwację dla danego slotu (jeśli jest)
  Booking? _bookingForSlot(ServiceProvider provider, String time) {
    final parts = time.split(':');
    final slotStart = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
    for (final b in widget.bookings) {
      if (sameDateTime(b.start, slotStart)) return b;
    }
    return null;
  }

  void _bookSlot(ServiceProvider provider, String time) {
    final parts = time.split(':');
    final start = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );

    final exists = widget.bookings.any((b) => sameDateTime(b.start, start));
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('W tym terminie masz już rezerwację')),
      );
      return;
    }

    final booking = Booking(
      id: '${provider.id}_${start.millisecondsSinceEpoch}',
      service: provider.name,
      start: start,
      durationMinutes: provider.slotDurationMinutes,
      status: BookingStatus.inquiry,
    );

    widget.onProviderSelected(provider);
    widget.onBookingCreated(booking);

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Inquiry: ${provider.name}, $time'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('Moi usługodawcy'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: widget.providers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final provider = widget.providers[index];
          final isExpanded = _picked?.id == provider.id;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isExpanded
                    ? Colors.indigo
                    : Colors.transparent,
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  blurRadius: 14,
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── nagłówek karty usługodawcy ───────────────
                // single tap = rozwiń/zwiń, double tap = pełna strona
                InkWell(
                  onTap: () => setState(() {
                    _picked = isExpanded ? null : provider;
                  }),
                  onDoubleTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProviderDetailScreen(
                        provider: provider,
                        userId: AuthService.instance.currentUser?.email,
                      ),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        ProviderAvatar(
                          serviceType: provider.serviceType,
                          radius: 24,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      provider.name,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Tooltip(
                                    message: 'Dwukrotnie dotknij aby zobaczyć szczegóły',
                                    child: Icon(Icons.info_outline_rounded,
                                        size: 14,
                                        color: Colors.grey.shade400),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                provider.serviceType,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.location_on_outlined,
                                      size: 12,
                                      color: Colors.grey.shade500),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: Text(
                                      provider.address,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ),
                                  if (provider.rating != null) ...[
                                    const SizedBox(width: 8),
                                    Icon(Icons.star,
                                        size: 12,
                                        color: Colors.amber.shade600),
                                    const SizedBox(width: 2),
                                    Text(
                                      provider.rating!.toStringAsFixed(1),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isExpanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                          color: Colors.grey.shade500,
                        ),
                      ],
                    ),
                  ),
                ),

                // ── sloty ────────────────────────────────────
                if (isExpanded) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Wolne sloty — ${formatDate(widget.selectedDate)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: provider.slots.map((slot) {
                            final existing =
                                _bookingForSlot(provider, slot);
                            final isFree = existing == null;
                            final color =
                                isFree ? Colors.indigo : Colors.green;
                            return InkWell(
                              onTap: isFree
                                  ? () => _bookSlot(provider, slot)
                                  : null,
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: color.withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isFree
                                          ? Icons.add_circle_outline
                                          : Icons.check_circle_outline,
                                      size: 14,
                                      color: color,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      slot,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
