import 'package:flutter/material.dart';
import '../../../models/booking.dart';
import '../../../utils/date_helpers.dart';
import '../../../l10n/app_strings.dart';

class BookingsSection extends StatelessWidget {
  final List<Booking> bookings;
  final bool expanded;
  final VoidCallback onToggle;
  final String Function(DateTime) formatWaitTime;
  final void Function(Booking) onBookingTap;
  final void Function(Booking) onSimulateConfirm;

  const BookingsSection({
    super.key,
    required this.bookings,
    required this.expanded,
    required this.onToggle,
    required this.formatWaitTime,
    required this.onBookingTap,
    required this.onSimulateConfirm,
  });

  static Color _bookingColor(Booking b) {
    if (b.status == BookingStatus.pending) return Colors.orange;
    if (b.status == BookingStatus.booked) return Colors.green;
    return Colors.orange;
  }

  static IconData _bookingIcon(Booking b) {
    if (b.status == BookingStatus.pending) return Icons.hourglass_top_rounded;
    if (b.status == BookingStatus.booked) return Icons.check_circle_rounded;
    return Icons.help_outline_rounded;
  }

  static String _bookingLabel(Booking b, AppStrings s) {
    if (b.status == BookingStatus.pending) return s.statusPending;
    if (b.status == BookingStatus.booked) return s.statusBooked;
    return s.statusInquiry;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
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
                  Expanded(
                    child: Text(
                      s.upcomingBookingsTitle,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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

          // ── Pełna lista (rozwinięta) ──────────────────────
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                children: bookings.take(5).map((booking) {
                  final isPending = booking.status == BookingStatus.pending;
                  final color = _bookingColor(booking);

                  return InkWell(
                    onTap: () => onBookingTap(booking),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: color.withOpacity(0.3), width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: color.withOpacity(0.15),
                                child: Icon(_bookingIcon(booking),
                                    color: color, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      booking.service,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700),
                                    ),
                                    if (booking.staffName != null) ...[
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(Icons.person_rounded,
                                              size: 11,
                                              color: Colors.teal.shade600),
                                          const SizedBox(width: 3),
                                          Text(
                                            booking.staffName!,
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.teal.shade700,
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ],
                                    const SizedBox(height: 2),
                                    Text(
                                      '${formatDate(booking.start)} · ${booking.timeText}',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600),
                                    ),
                                    if (isPending &&
                                        booking.pendingSince != null) ...[
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          Icon(Icons.schedule_rounded,
                                              size: 11,
                                              color: Colors.orange.shade600),
                                          const SizedBox(width: 3),
                                          Text(
                                            s.waitTime(formatWaitTime(booking.pendingSince!)),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.orange.shade700,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  _bookingLabel(booking, s),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                color: Colors.red.shade400,
                                tooltip: s.cancelBookingTooltip,
                                onPressed: () => onBookingTap(booking),
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                          if (isPending) ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.green.shade700,
                                  side: BorderSide(
                                      color: Colors.green.shade300),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                  visualDensity: VisualDensity.compact,
                                ),
                                icon: const Icon(
                                    Icons.check_circle_outline,
                                    size: 16),
                                label: Text(s.simulateConfirmation,
                                    style: TextStyle(fontSize: 12)),
                                onPressed: () => onSimulateConfirm(booking),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
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
}
