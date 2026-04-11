import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../utils/date_helpers.dart';

class DayCalendarView extends StatelessWidget {
  final DateTime selectedDate;
  final List<Booking> bookings;
  final double zoom;
  final ScrollController scrollController;
  final void Function(Booking) onBookingTap;
  final List<String> freeSlots;
  final List<String> confirmationSlots;
  final int slotDurationMinutes;
  /// Callback wywoływany gdy użytkownik tapnie wolny slot.
  /// Jeśli null, slot jest wyświetlany ale nie jest klikalny.
  final void Function(String slot)? onSlotTap;
  /// Wysokość obszaru scrollowanego kalendarza (bez nagłówków całodniowych).
  final double viewHeight;

  const DayCalendarView({
    super.key,
    required this.selectedDate,
    required this.bookings,
    required this.zoom,
    required this.scrollController,
    required this.onBookingTap,
    this.freeSlots = const [],
    this.confirmationSlots = const [],
    this.slotDurationMinutes = 60,
    this.onSlotTap,
    this.viewHeight = 520,
  });

  static const int _startHour = 7;
  static const int _endHour = 21;
  static const double _timeColumnWidth = 56;

  bool get _isToday {
    final now = DateTime.now();
    return selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;
  }

  /// Czerwona linia pokazująca aktualny czas (tylko dla dnia dzisiejszego).
  Widget _buildNowLine(double hourRowHeight) {
    final now = DateTime.now();
    if (now.hour < _startHour || now.hour >= _endHour) {
      return const SizedBox.shrink();
    }
    final top = ((now.hour - _startHour) * 60 + now.minute) / 60 * hourRowHeight;
    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Container(
              height: 1.5,
              color: Colors.red.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds slot widgets for the day view.
  /// [isConfirmation] = true → pomarańczowe, false → niebieskie.
  List<Widget> _buildSlotWidgets(
    List<String> slots,
    List<Booking> timedBookings,
    double hourRowHeight, {
    required bool isConfirmation,
  }) {
    final result = <Widget>[];
    for (final slot in slots) {
      final parts = slot.split(':');
      if (parts.length < 2) continue;
      final hour = int.tryParse(parts[0]) ?? -1;
      final minute = int.tryParse(parts[1]) ?? 0;
      if (hour < _startHour || hour >= _endHour) continue;

      final slotStart = DateTime(
        selectedDate.year, selectedDate.month, selectedDate.day, hour, minute,
      );
      final slotEnd = slotStart.add(Duration(minutes: slotDurationMinutes));
      final isOccupied = timedBookings.any(
        (b) => b.start.isBefore(slotEnd) && b.end.isAfter(slotStart),
      );
      if (isOccupied) continue;

      final top = ((hour - _startHour) * 60 + minute) / 60 * hourRowHeight;
      final height = slotDurationMinutes / 60 * hourRowHeight;
      final showLabel = height >= 36;
      final showHint = height >= 52;

      result.add(
        Positioned(
          top: top + 2,
          left: 0,
          right: 0,
          height: height - 4,
          child: Align(
            alignment: Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onSlotTap != null ? () => onSlotTap!(slot) : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: isConfirmation
                          ? Colors.orange.withOpacity(0.10)
                          : Colors.blue.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isConfirmation
                            ? Colors.orange.withOpacity(0.50)
                            : Colors.blue.withOpacity(0.5),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          isConfirmation
                              ? Icons.hourglass_top_rounded
                              : Icons.add_circle_outline,
                          size: 12,
                          color: isConfirmation
                              ? Colors.orange.shade700
                              : Colors.blue.shade700,
                        ),
                        const SizedBox(width: 3),
                        if (showLabel)
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  slot,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: isConfirmation
                                        ? Colors.orange.shade800
                                        : Colors.blue.shade800,
                                    height: 1.1,
                                  ),
                                ),
                                if (showHint)
                                  Text(
                                    isConfirmation
                                        ? 'Wyślij prośbę'
                                        : 'Zarezerwuj',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: isConfirmation
                                          ? Colors.orange.shade600
                                          : Colors.blue.shade600,
                                      height: 1.2,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final double hourRowHeight = 64 * zoom;
    final totalHours = _endHour - _startHour;
    final totalHeight = totalHours * hourRowHeight;

    final allDayBookings = bookings
        .where((b) => sameDay(b.start, selectedDate) && b.isAllDay)
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));

    final timedBookings = bookings
        .where((b) => sameDay(b.start, selectedDate) && !b.isAllDay)
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (allDayBookings.isNotEmpty) ...[
          const Text(
            'Cały dzień',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 8),
          ...allDayBookings.map((booking) {
            final color = booking.status == BookingStatus.booked
                ? Colors.green
                : Colors.orange;
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 6),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color, width: 1.1),
              ),
              child: Text(
                booking.service,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
            );
          }),
          const SizedBox(height: 12),
        ],
        SizedBox(
          height: viewHeight,
          child: SingleChildScrollView(
            controller: scrollController,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── kolumna godzin ──────────────────────────────
                SizedBox(
                  width: _timeColumnWidth,
                  height: totalHeight,
                  child: Column(
                    children: List.generate(totalHours, (i) {
                      final hour = _startHour + i;
                      return SizedBox(
                        height: hourRowHeight,
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            '${hour.toString().padLeft(2, '0')}:00',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                // ── siatka z eventami ───────────────────────────
                Expanded(
                  child: Container(
                    height: totalHeight,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFD),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Stack(
                      children: [
                        // 1. Linie godzinowe (NAJNIŻEJ) ───────────
                        // Linia "teraz" (tylko dla dnia dzisiejszego)
                        if (_isToday) _buildNowLine(hourRowHeight),
                        ...List.generate(totalHours, (i) {
                          return Positioned(
                            top: i * hourRowHeight,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: hourRowHeight,
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: Colors.grey.shade300,
                                    width: 1,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),

                        // 2. Wolne sloty (niebieskie, pół-szerokości, prawa strona)
                        ..._buildSlotWidgets(freeSlots, timedBookings, hourRowHeight, isConfirmation: false),
                        ..._buildSlotWidgets(confirmationSlots, timedBookings, hourRowHeight, isConfirmation: true),

                        // 3. Rezerwacje (NA WIERZCHU) ──────────────
                        ...timedBookings.map((booking) {
                          final startMinutes =
                              (booking.start.hour - _startHour) * 60 +
                                  booking.start.minute;
                          final top = startMinutes / 60 * hourRowHeight;
                          final rawHeight =
                              booking.durationMinutes / 60 * hourRowHeight;
                          final blockHeight =
                              rawHeight < 34 ? 34.0 : rawHeight;

                          final isPending =
                              booking.status == BookingStatus.pending;
                          final color =
                              booking.status == BookingStatus.booked
                                  ? Colors.green
                                  : Colors.orange;

                          final showTime = blockHeight >= 52;
                          final showStatus = blockHeight >= 68;

                          return Positioned(
                            top: top,
                            left: 10,
                            right: 10,
                            height: blockHeight,
                            child: InkWell(
                              onTap: () => onBookingTap(booking),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  // pending = transparentne, tylko pomarańczowa ramka
                                  color: isPending
                                      ? Colors.transparent
                                      : color.withOpacity(0.20),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isPending
                                        ? Colors.orange.withOpacity(0.7)
                                        : color,
                                    width: 1.0,
                                  ),
                                ),
                                child: ClipRect(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        booking.service,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12.5,
                                          height: 1.0,
                                        ),
                                      ),
                                      if (showTime) ...[
                                        const SizedBox(height: 3),
                                        Text(
                                          booking.timeText,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            height: 1.0,
                                          ),
                                        ),
                                      ],
                                      if (showStatus) ...[
                                        const SizedBox(height: 3),
                                        Text(
                                          isPending
                                              ? 'Oczekuje'
                                              : booking.status ==
                                                      BookingStatus.booked
                                                  ? 'Potwierdzona'
                                                  : 'Inquiry',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: color,
                                            height: 1.0,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
