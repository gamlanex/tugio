import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../utils/date_helpers.dart';

class PendingBookingsScreen extends StatefulWidget {
  final List<Booking> bookings;
  final void Function(Booking booking) onConfirm;
  final void Function(String bookingId) onCancel;

  const PendingBookingsScreen({
    super.key,
    required this.bookings,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<PendingBookingsScreen> createState() => _PendingBookingsScreenState();
}

class _PendingBookingsScreenState extends State<PendingBookingsScreen> {
  late List<Booking> _bookings;

  @override
  void initState() {
    super.initState();
    _bookings = List.from(widget.bookings);
  }

  Future<void> _confirmBooking(Booking booking) async {
    setState(() => booking.status = BookingStatus.booked);
    widget.onConfirm(booking);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Rezerwacja "${booking.service}" potwierdzona!'),
        backgroundColor: Colors.green.shade700,
      ),
    );
  }

  Future<void> _cancelBooking(Booking booking) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Odwołać rezerwację?'),
        content: Text('${booking.service}\n${booking.timeText}'),
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
      setState(() => _bookings.removeWhere((b) => b.id == booking.id));
      widget.onCancel(booking.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rezerwacja odwołana')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF2A1E18) : const Color(0xFFFBEDE6);
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Oczekujące na potwierdzenie'),
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
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) =>
                  _PendingCard(
                    booking: _bookings[index],
                    onConfirm: () => _confirmBooking(_bookings[index]),
                    onCancel: () => _cancelBooking(_bookings[index]),
                  ),
            ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Żadna rezerwacja nie oczekuje\nna potwierdzenie',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
                height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _PendingCard({
    required this.booking,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final waitDiff = booking.pendingSince != null
        ? DateTime.now().difference(booking.pendingSince!)
        : null;

    final waitText = waitDiff == null
        ? null
        : waitDiff.inHours < 1
            ? 'Czeka ${waitDiff.inMinutes} min'
            : 'Czeka ${waitDiff.inHours}h ${waitDiff.inMinutes % 60}min';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2E201A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200, width: 1.2),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            color: Colors.orange.withOpacity(0.08),
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── nagłówek ─────────────────────────────────────
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.orange.shade50,
                  child: Icon(Icons.hourglass_top_rounded,
                      color: Colors.orange.shade700, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.service,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      if (booking.staffName != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.person_rounded,
                                size: 12, color: Colors.teal.shade600),
                            const SizedBox(width: 3),
                            Text(
                              booking.staffName!,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.teal.shade700),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              size: 12, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            '${formatDate(booking.start)} · ${booking.timeText}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      if (waitText != null) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.schedule_rounded,
                                size: 12, color: Colors.orange.shade600),
                            const SizedBox(width: 4),
                            Text(
                              waitText,
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
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Text(
                    'Oczekuje',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.orange.shade700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // ── przyciski akcji ────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Odwołaj',
                        style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade600,
                      side: BorderSide(color: Colors.red.shade300),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onConfirm,
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Potwierdź',
                        style: TextStyle(fontSize: 13)),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
