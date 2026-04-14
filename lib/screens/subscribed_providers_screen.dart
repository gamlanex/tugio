import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/provider.dart';
import '../models/booking.dart';
import '../services/auth_service.dart';
import '../utils/date_helpers.dart';
import '../utils/provider_avatar.dart';
import '../widgets/booking_detail_sheet.dart';
import 'provider_detail_screen.dart';
import 'service_type_screen.dart';

class SubscribedProvidersScreen extends StatefulWidget {
  final List<ServiceProvider> providers;
  final ServiceProvider? selectedProvider;
  final DateTime selectedDate;
  final List<Booking> bookings;
  final void Function(ServiceProvider) onProviderSelected;
  final void Function(Booking) onBookingCreated;
  final void Function(String bookingId) onBookingCancelled;
  final void Function(ServiceProvider)? onProviderSubscribed;

  const SubscribedProvidersScreen({
    super.key,
    required this.providers,
    this.selectedProvider,
    required this.selectedDate,
    required this.bookings,
    required this.onProviderSelected,
    required this.onBookingCreated,
    required this.onBookingCancelled,
    this.onProviderSubscribed,
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

  Future<void> _callPhone(ServiceProvider p) async {
    if (p.phone == null) return;
    final uri = Uri.parse('tel:${p.phone}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openMaps(ServiceProvider p) async {
    final uri = Uri.parse('https://maps.google.com/?q=${p.lat},${p.lng}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _openAddNew() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ServiceTypeScreen(
          onProviderSubscribed: (provider) {
            widget.onProviderSubscribed?.call(provider);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Zasubskrybowano: ${provider.name}')),
            );
          },
        ),
      ),
    );
  }

  // Zwraca rezerwację dla danego slotu tego dostawcy (każdy status)
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
      if (!sameDateTime(b.start, slotStart)) continue;
      // Jeśli rezerwacja ma providerId — musi pasować do tego dostawcy
      if (b.providerId != null && b.providerId != provider.id) continue;
      return b;
    }
    return null;
  }

  Future<void> _openBookingDetail(Booking booking, ServiceProvider provider) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => BookingDetailSheet(
        booking: booking,
        provider: booking.importedFromDeviceCalendar ? null : provider,
        onCancel: booking.importedFromDeviceCalendar
            ? null
            : () async {
                Navigator.pop(ctx);
                final confirmed = await _confirmCancel(booking);
                if (confirmed) widget.onBookingCancelled(booking.id);
              },
      ),
    );
  }

  /// Buduje sekcję "Moje rezerwacje" dla danego dostawcy.
  /// Zwraca pustą listę jeśli brak rezerwacji — wtedy sekcja jest pomijana.
  List<Widget> _buildProviderBookings(ServiceProvider provider, {required bool isDark}) {
    final now = DateTime.now();
    final myBookings = widget.bookings
        .where((b) =>
            !b.importedFromDeviceCalendar &&
            b.providerId == provider.id &&
            !b.start.isBefore(DateTime(now.year, now.month, now.day)))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));

    if (myBookings.isEmpty) return [];

    Color _statusColor(BookingStatus s) {
      switch (s) {
        case BookingStatus.booked: return Colors.green;
        case BookingStatus.pending: return Colors.orange;
        case BookingStatus.inquiry: return Colors.orange;
      }
    }
    IconData _statusIcon(BookingStatus s) {
      switch (s) {
        case BookingStatus.booked: return Icons.check_circle_outline;
        case BookingStatus.pending: return Icons.hourglass_top_rounded;
        case BookingStatus.inquiry: return Icons.help_outline_rounded;
      }
    }
    String _statusLabel(BookingStatus s) {
      switch (s) {
        case BookingStatus.booked: return 'Potwierdzona';
        case BookingStatus.pending: return 'Oczekuje';
        case BookingStatus.inquiry: return 'Zapytanie';
      }
    }

    final labelColor = isDark ? Colors.grey.shade400 : Colors.grey.shade700;
    return [
      Text(
        'Moje rezerwacje',
        style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600,
            color: labelColor),
      ),
      const SizedBox(height: 8),
      ...myBookings.map((b) {
        final color = _statusColor(b.status);
        return InkWell(
          onTap: () => _openBookingDetail(b, provider),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.35), width: 1),
            ),
            child: Row(
              children: [
                Icon(_statusIcon(b.status), size: 14, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(b.service,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700)),
                      Text(
                        '${formatDate(b.start)} · ${b.timeText}',
                        style: TextStyle(
                            fontSize: 10.5, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_statusLabel(b.status),
                      style: TextStyle(
                          fontSize: 9, fontWeight: FontWeight.w700,
                          color: color)),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded,
                    size: 16, color: Colors.grey.shade400),
              ],
            ),
          ),
        );
      }),
      const SizedBox(height: 12),
    ];
  }

  Future<bool> _confirmCancel(Booking booking) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Odwołać rezerwację?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(booking.service,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('${formatDate(booking.start)} · ${booking.timeText}',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Zostaw'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Odwołaj'),
          ),
        ],
      ),
    );
    return result == true;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1C2E) : const Color(0xFFEEF0FB);
    final cardColor = isDark ? const Color(0xFF22263A) : Colors.white;
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Moi usługodawcy'),
        centerTitle: true,
        backgroundColor: bgColor,
        elevation: 0,
        leading: const BackButton(),
        actions: [
          IconButton(
            tooltip: 'Dodaj nowych usługodawców',
            onPressed: _openAddNew,
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.indigo,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
      body: widget.providers.isEmpty
          ? _buildEmpty()
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: widget.providers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final provider = widget.providers[index];
          final isExpanded = _picked?.id == provider.id;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: cardColor,
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
                  onTap: () {
                    setState(() {
                      _picked = isExpanded ? null : provider;
                    });
                    if (!isExpanded) {
                      widget.onProviderSelected(provider);
                    }
                  },
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

                // ── rozwinięty panel ─────────────────────────
                if (isExpanded) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Zadzwoń / Mapa ────────────────────────
                        Row(
                          children: [
                            if (provider.phone != null)
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _callPhone(provider),
                                  icon: const Icon(Icons.phone_rounded, size: 16),
                                  label: const Text('Zadzwoń'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                            if (provider.phone != null) const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _openMaps(provider),
                                icon: const Icon(Icons.map_rounded, size: 16),
                                label: const Text('Mapa'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // ── Moje rezerwacje u tego dostawcy ──────
                        ..._buildProviderBookings(provider, isDark: isDark),

                        // ── Wolne sloty na wybraną datę ──────────
                        Text(
                          'Wolne sloty — ${formatDate(widget.selectedDate)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: provider.slots.map((slot) {
                            final existing = _bookingForSlot(provider, slot);
                            final isFree = existing == null;

                            Color color;
                            IconData iconData;
                            if (isFree) {
                              color = Colors.indigo;
                              iconData = Icons.add_circle_outline;
                            } else {
                              switch (existing!.status) {
                                case BookingStatus.booked:
                                  color = Colors.green;
                                  iconData = Icons.check_circle_outline;
                                case BookingStatus.pending:
                                  color = Colors.orange;
                                  iconData = Icons.hourglass_top_rounded;
                                case BookingStatus.inquiry:
                                  color = Colors.orange;
                                  iconData = Icons.help_outline_rounded;
                              }
                            }

                            return InkWell(
                              onTap: isFree
                                  ? () => _bookSlot(provider, slot)
                                  : () => _openBookingDetail(existing!, provider),
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
                                    Icon(iconData, size: 14, color: color),
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

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Nie masz jeszcze usługodawców',
            style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _openAddNew,
            icon: const Icon(Icons.add),
            label: const Text('Znajdź i dodaj usługodawcę'),
            style: FilledButton.styleFrom(backgroundColor: Colors.indigo),
          ),
        ],
      ),
    );
  }
}
