import 'package:flutter/material.dart';
import '../models/service.dart';
import '../models/booking.dart';
import '../utils/date_helpers.dart';
import 'date_navigator.dart';

class SlotsPanel extends StatelessWidget {
  final Service service;
  final DateTime selectedDate;
  final List<Booking> bookings;
  final String navigatorTitle;
  final void Function(String slot) onSlotTap;
  final void Function(DragEndDetails) onHorizontalDragEnd;
  final VoidCallback onPreviousDate;
  final VoidCallback onNextDate;

  const SlotsPanel({
    super.key,
    required this.service,
    required this.selectedDate,
    required this.bookings,
    required this.navigatorTitle,
    required this.onSlotTap,
    required this.onHorizontalDragEnd,
    required this.onPreviousDate,
    required this.onNextDate,
  });

  Booking? _bookingForSlot(String time) {
    final parts = time.split(':');
    final slotStart = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
    for (final b in bookings) {
      if (sameDateTime(b.start, slotStart)) return b;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: onHorizontalDragEnd,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth < 300 ? 2 : 3;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DateNavigator(
                title: navigatorTitle,
                onPrevious: onPreviousDate,
                onNext: onNextDate,
              ),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: service.slots.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  mainAxisExtent: 52,
                ),
                itemBuilder: (context, index) {
                  final slot = service.slots[index];
                  return _SlotTile(
                    slot: slot,
                    booking: _bookingForSlot(slot),
                    onTap: () => onSlotTap(slot),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SlotTile extends StatelessWidget {
  final String slot;
  final Booking? booking;
  final VoidCallback onTap;

  const _SlotTile({
    required this.slot,
    required this.booking,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isFree = booking == null;
    final isInquiry = booking?.status == BookingStatus.inquiry;

    final Color bg;
    final Color border;
    final String statusText;
    final IconData icon;

    if (isFree) {
      bg = Colors.indigo.withOpacity(0.08);
      border = Colors.indigo;
      statusText = 'Free';
      icon = Icons.add_circle_outline;
    } else if (isInquiry) {
      bg = Colors.orange.withOpacity(0.14);
      border = Colors.orange;
      statusText = 'Inquiry';
      icon = Icons.hourglass_top;
    } else {
      bg = Colors.green.withOpacity(0.14);
      border = Colors.green;
      statusText = 'Booked';
      icon = Icons.check_circle_outline;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: 1.1),
          ),
          child: Column(
            children: [
              Text(
                slot,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                ),
              ),
//              const Spacer(),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.72),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 11, color: border),
                    const SizedBox(width: 3),
                    Text(
                      statusText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9.8,
                        fontWeight: FontWeight.w700,
                        color: border,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}