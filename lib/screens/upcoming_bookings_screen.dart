import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../models/provider.dart';
import '../utils/date_helpers.dart';
import '../utils/provider_avatar.dart' show serviceTypeIcon, serviceTypeColor;
import '../widgets/booking_detail_sheet.dart';
import '../l10n/app_strings.dart';

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
    // Brak providerId = rezerwacja lokalna / zaimportowana, nie przypisana do dostawcy
    return null;
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
    final s = AppStrings.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(s.cancelBookingTitle),
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
            child: Text(s.leave),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.cancelBookingConfirmButton),
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
        SnackBar(content: Text(AppStrings.of(context).bookingCancelled)),
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
        title: Text(AppStrings.of(context).upcomingBookingsTitle),
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
                  provider: _providerFor(booking),
                  onTap: () => _openDetail(booking),
                );
              },
            ),
    );
  }

  Widget _buildEmpty() {
    final s = AppStrings.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_available_outlined,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            s.noUpcomingBookings,
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
  final ServiceProvider? provider;

  const _BookingCard({
    required this.booking,
    required this.cardColor,
    required this.onTap,
    this.provider,
  });

  Color get _statusColor {
    switch (booking.status) {
      case BookingStatus.pending:
      case BookingStatus.inquiry:
        return Colors.orange;
      case BookingStatus.booked:
        return Colors.green;
      default:
        return Colors.blueGrey;
    }
  }

  String _statusLabel(AppStrings s) {
    switch (booking.status) {
      case BookingStatus.pending:  return s.statusPending;
      case BookingStatus.inquiry:  return s.statusInquiry;
      case BookingStatus.booked:   return s.statusBooked;
      default:                     return s.statusUnknown;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final color = _statusColor;
    final hasPhoto = provider?.avatarImageUrl != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 88,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                blurRadius: 14,
                color: Colors.black.withOpacity(0.05),
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(17),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Zdjęcie po lewej — pełna wysokość karty ─────
                SizedBox(
                  width: 80,
                  child: hasPhoto
                      ? Image.network(
                          provider!.avatarImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _PhotoFallback(
                              serviceType: provider?.serviceType ?? booking.service),
                        )
                      : _PhotoFallback(
                          serviceType: provider?.serviceType ?? booking.service),
                ),
                // ── Treść ────────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Tytuł + chip statusu
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
                                _statusLabel(s),
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: color),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Dostawca
                        if (provider != null) ...[
                          Text(
                            provider!.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 3),
                        ],
                        // Pracownik
                        if (booking.staffName != null) ...[
                          Row(children: [
                            Icon(Icons.person_rounded,
                                size: 11, color: Colors.teal.shade600),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(booking.staffName!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.teal.shade700)),
                            ),
                          ]),
                          const SizedBox(height: 3),
                        ],
                        // Data i godzina
                        Row(children: [
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
                        ]),
                      ],
                    ),
                  ),
                ),
                // Chevron
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Icon(Icons.chevron_right_rounded,
                      color: Colors.grey.shade400, size: 22),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Placeholder dla zdjęcia — ikona dopasowana do specjalności ───────────────
class _PhotoFallback extends StatelessWidget {
  final String serviceType;
  const _PhotoFallback({required this.serviceType});

  @override
  Widget build(BuildContext context) {
    final color = serviceTypeColor(serviceType);
    final icon  = serviceTypeIcon(serviceType);
    return Container(
      color: color.withOpacity(0.1),
      child: Center(
        child: Icon(icon, size: 34, color: color.withOpacity(0.55)),
      ),
    );
  }
}
