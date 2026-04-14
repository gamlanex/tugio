import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../models/provider.dart';
import '../utils/date_helpers.dart';
import '../widgets/booking_detail_sheet.dart';

class UpcomingBookingsScreen extends StatefulWidget {
  final List<Booking> bookings;
  final List<ServiceProvider> providers;
  final void Function(String bookingId) onCancel;

  const UpcomingBookingsScreen({
    super.key,
    required this.bookings,
    required this.providers,
    required this.onCancel,
  });

  @override
  State<UpcomingBookingsScreen> createState() => _UpcomingBookingsScreenState();
}

class _UpcomingBookingsScreenState extends State<UpcomingBookingsScreen> {
  late List<Booking> _bookings;

  @override
  void initState() {
    super.initState();
    _bookings = List.from(widget.bookings);
  }

  ServiceProvider? _providerFor(Booking booking) {
    if (booking.providerId != null) {
      try {
        return widget.providers.firstWhere((p) => p.id == booking.providerId);
      } catch (_) {}
    }
    // Fallback: jeśli rezerwacja nie ma providerId (np. mock), użyj pierwszego z listy
    return widget.providers.isNotEmpty ? widget.providers.first : null;
  }

  Future<void> _openDetail(Booking booking) async {
    final provider = _providerFor(booking);
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
                await _confirmCancel(booking);
              },
      ),
    );
  }

  Future<void> _confirmCancel(Booking booking) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Odwołać rezerwację?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(booking.service,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('${formatDate(booking.start)} · ${booking.timeText}',
                style: TextStyle(
                    fontSize: 13, color: Colors.grey.shade600)),
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

    if (result == true && mounted) {
      setState(() {
        _bookings.removeWhere((b) => b.id == booking.id);
      });
      widget.onCancel(booking.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rezerwacja odwołana')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A2A27) : const Color(0xFFE6F4F1);
    final cardColor = isDark ? const Color(0xFF1E2E2B) : Colors.white;
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Nadchodzące rezerwacje'),
        centerTitle: true,
        backgroundColor: bgColor,
        elevation: 0,
        leading: const BackButton(),
      ),
      body: _bookings.isEmpty
          ? _buildEmpty()
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _bookings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final booking = _bookings[index];
                return _BookingCard(
                  booking: booking,
                  cardColor: cardColor,
                  onTap: () => _openDetail(booking),
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
          Icon(Icons.event_available_outlined,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Brak nadchodzących rezerwacji',
            style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Karta rezerwacji — styl spójny z ekranem, tap otwiera BookingDetailSheet
// ─────────────────────────────────────────────────────────────────────────────
class _BookingCard extends StatelessWidget {
  final Booking booking;
  final Color cardColor;
  final VoidCallback onTap;

  const _BookingCard({
    required this.booking,
    required this.cardColor,
    required this.onTap,
  });

  Color get _statusColor {
    switch (booking.status) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.inquiry:
        return Colors.orange;
      case BookingStatus.booked:
        return Colors.green;
      default:
        return Colors.blueGrey;
    }
  }

  IconData get _statusIcon {
    switch (booking.status) {
      case BookingStatus.pending:
        return Icons.hourglass_top_rounded;
      case BookingStatus.inquiry:
        return Icons.hourglass_top_rounded;
      case BookingStatus.booked:
        return Icons.check_circle_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  String get _statusLabel {
    switch (booking.status) {
      case BookingStatus.pending:
        return 'Oczekuje';
      case BookingStatus.inquiry:
        return 'Zapytanie';
      case BookingStatus.booked:
        return 'Potwierdzona';
      default:
        return 'Nieznany';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: color.withOpacity(0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 14,
                color: Colors.black.withOpacity(0.05),
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Ikona statusu
                CircleAvatar(
                  radius: 22,
                  backgroundColor: color.withOpacity(0.12),
                  child: Icon(_statusIcon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                // Nazwa + data
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tytuł + chip
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              booking.service,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _statusLabel,
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: color),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      if (booking.staffName != null) ...[
                        Row(
                          children: [
                            Icon(Icons.person_rounded,
                                size: 11, color: Colors.teal.shade600),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                booking.staffName!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.teal.shade700),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                      ],
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              size: 11, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '${formatDate(booking.start)} · ${booking.timeText}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.grey.shade600),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Chevron → otwiera szczegóły
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey.shade400,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
