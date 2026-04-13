import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../utils/date_helpers.dart';

class MonthCalendarView extends StatelessWidget {
  final DateTime selectedDate;
  final List<Booking> bookings;
  final void Function(DateTime day) onDayTap;
  final double maxHeight;
  final List<String> freeSlots;
  final List<String> confirmationSlots;
  final int slotDurationMinutes;

  const MonthCalendarView({
    super.key,
    required this.selectedDate,
    required this.bookings,
    required this.onDayTap,
    this.maxHeight = 600,
    this.freeSlots = const [],
    this.confirmationSlots = const [],
    this.slotDurationMinutes = 60,
  });

  // Godziny widoczne w widoku dnia (7:00–21:00)
  static const int _startHour = 7;
  static const int _endHour = 21;

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final gridStart = firstOfMonth.subtract(
      Duration(days: firstOfMonth.weekday - 1),
    );
    final days = List.generate(42, (i) => gridStart.add(Duration(days: i)));

    const double targetCellHeight = 72.0;
    const double headerHeight = 28.0;
    const double rowSpacing = 6.0;
    const int rowCount = 6;

    final totalGridH =
        rowCount * targetCellHeight + (rowCount - 1) * rowSpacing;
    final totalH = headerHeight + totalGridH;
    final scale = (totalH > maxHeight) ? (maxHeight / totalH) : 1.0;
    final cellHeight = targetCellHeight * scale;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth =
            constraints.maxWidth > 0 ? constraints.maxWidth : 300.0;
        final cellWidth = (availableWidth - 6 * rowSpacing) / 7;
        final aspectRatio = cellWidth / cellHeight;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── nagłówki dni tygodnia ──────────────────────
            SizedBox(
              height: headerHeight,
              child: Row(
                children: List.generate(7, (i) {
                  return Expanded(
                    child: Center(
                      child: Text(
                        weekdayShort(i + 1),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // ── siatka dni ────────────────────────────────
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: days.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: rowSpacing,
                crossAxisSpacing: rowSpacing,
                childAspectRatio: aspectRatio,
              ),
              itemBuilder: (context, index) {
                final day = days[index];
                final isCurrentMonth = day.month == selectedDate.month;
                final isSelected = sameDay(day, selectedDate);
                final isToday = sameDay(day, DateTime.now());

                final dayBookings = bookings
                    .where((b) => sameDay(b.start, day))
                    .toList()
                  ..sort((a, b) => a.start.compareTo(b.start));
                final visibleBars = dayBookings.take(2).toList();

                // Wolne sloty dla tego dnia (nieobsadzone)
                final dayFreeSlots = isCurrentMonth
                    ? _freeSlotsForDay(freeSlots, day, dayBookings)
                    : <_SlotPos>[];
                final dayConfirmSlots = isCurrentMonth
                    ? _freeSlotsForDay(confirmationSlots, day, dayBookings,
                        isConfirmation: true)
                    : <_SlotPos>[];
                final hasFreeSlots =
                    dayFreeSlots.isNotEmpty || dayConfirmSlots.isNotEmpty;
                final hasOnlyConfirm =
                    dayFreeSlots.isEmpty && dayConfirmSlots.isNotEmpty;

                return InkWell(
                  onTap: () => onDayTap(day),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isToday
                          ? Colors.indigo.withOpacity(0.13)
                          : isSelected
                              ? Colors.indigo.withOpacity(0.08)
                              : hasFreeSlots && isCurrentMonth
                                  ? (hasOnlyConfirm
                                      ? Colors.orange.withOpacity(0.04)
                                      : Colors.blue.withOpacity(0.04))
                                  : isCurrentMonth
                                      ? Theme.of(context).colorScheme.surface
                                      : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isToday
                            ? Colors.indigo
                            : isSelected
                                ? Colors.indigo.withOpacity(0.5)
                                : Theme.of(context).colorScheme.outlineVariant,
                        width: isToday ? 1.6 : 1,
                      ),
                    ),
                    // Stack bez paddingu — kółeczka pozycjonowane względem całej komórki
                    child: Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        // ── treść komórki z paddingiem ───────
                        Positioned.fill(
                          child: ClipRect(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                4, 3,
                                hasFreeSlots && isCurrentMonth ? 12 : 4,
                                2,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  // Numer dnia
                                  Text(
                                    '${day.day}',
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontWeight: (isToday || isSelected)
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      fontSize: 11,
                                      color: isToday
                                          ? Colors.indigo
                                          : isCurrentMonth
                                              ? Theme.of(context).colorScheme.onSurface
                                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.35),
                                      height: 1.1,
                                    ),
                                  ),
                                  // Paseczki rezerwacji — Flexible zapobiega overflow
                                  if (visibleBars.isNotEmpty)
                                    Flexible(
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: visibleBars.map((b) {
                                            final isPending =
                                                b.status == BookingStatus.pending;
                                            final color =
                                                b.status == BookingStatus.booked
                                                    ? Colors.green
                                                    : Colors.orange;
                                            return Container(
                                              height: 5,
                                              margin: const EdgeInsets.only(bottom: 2),
                                              decoration: BoxDecoration(
                                                color: isPending
                                                    ? Colors.transparent
                                                    : color.withOpacity(0.85),
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                                border: isPending
                                                    ? Border.all(
                                                        color: Colors.orange
                                                            .withOpacity(0.6),
                                                        width: 0.8,
                                                      )
                                                    : null,
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // ── kółeczka — tuż przy prawej krawędzi komórki ──
                        if (hasFreeSlots && isCurrentMonth)
                          Positioned(
                            top: 5,
                            bottom: 5,
                            right: 3,
                            width: 6,
                            child: _SlotDots(
                              slots: [...dayFreeSlots, ...dayConfirmSlots],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  /// Zwraca pozycje środków wolnych slotów jako ułamek [0,1] zakresu dnia.
  List<_SlotPos> _freeSlotsForDay(
    List<String> slots,
    DateTime day,
    List<Booking> dayBookings, {
    bool isConfirmation = false,
  }) {
    final result = <_SlotPos>[];
    final totalMinutes = (_endHour - _startHour) * 60.0;

    for (final slot in slots) {
      final parts = slot.split(':');
      if (parts.length < 2) continue;
      final hour = int.tryParse(parts[0]) ?? -1;
      final minute = int.tryParse(parts[1]) ?? 0;
      if (hour < _startHour || hour >= _endHour) continue;

      final slotStart = DateTime(day.year, day.month, day.day, hour, minute);
      final slotEnd = slotStart.add(Duration(minutes: slotDurationMinutes));

      final isOccupied = dayBookings.any(
        (b) => b.start.isBefore(slotEnd) && b.end.isAfter(slotStart),
      );
      if (isOccupied) continue;

      final midMinutes = (hour - _startHour) * 60.0 +
          minute +
          slotDurationMinutes / 2.0;
      final fraction = (midMinutes / totalMinutes).clamp(0.0, 1.0);
      result.add(_SlotPos(fraction, isConfirmation: isConfirmation));
    }
    return result;
  }
}

// ─── Model pozycji slotu (ułamek 0–1 w zakresie dnia) ────────────────────────
class _SlotPos {
  final double fraction;       // środek slotu jako ułamek wysokości komórki
  final bool isConfirmation;   // true = pomarańczowe, false = niebieskie
  const _SlotPos(this.fraction, {this.isConfirmation = false});
}

// ─── Mikro-kółeczka po prawej, proporcjonalne do czasu ───────────────────────
class _SlotDots extends StatelessWidget {
  final List<_SlotPos> slots;
  const _SlotDots({super.key, required this.slots});

  static const double _d = 4.0;   // średnica kółka
  static const double _minGap = 5.0; // minimalny odstęp między środkami

  /// Rozsuwamy kółeczka zachowując powiązanie z kolorem.
  List<_SlotPos> _spread(List<_SlotPos> input, double totalH) {
    if (input.isEmpty) return input;
    // Sortujemy po frakcji zachowując isConfirmation
    final sorted = [...input]..sort((a, b) => a.fraction.compareTo(b.fraction));
    final outY = sorted.map((s) => s.fraction * totalH).toList();

    for (var i = 1; i < outY.length; i++) {
      if (outY[i] - outY[i - 1] < _minGap) {
        outY[i] = outY[i - 1] + _minGap;
      }
    }
    final overflow = outY.last + _d / 2 - totalH;
    if (overflow > 0) {
      for (var i = 0; i < outY.length; i++) {
        outY[i] = (outY[i] - overflow).clamp(_d / 2, totalH - _d / 2);
      }
    }
    // Składamy z powrotem — przechowujemy nową pozycję + kolor
    return List.generate(
      sorted.length,
      (i) => _SlotPos(outY[i] / totalH, isConfirmation: sorted[i].isConfirmation),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final h = constraints.maxHeight;
      final spread = _spread(slots, h);

      return Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          for (final s in spread)
            Positioned(
              top: s.fraction * h - _d / 2,
              right: 0,
              height: _d,
              child: Container(
                width: _d,
                height: _d,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: s.isConfirmation
                        ? Colors.orange.shade500
                        : Colors.blue.shade500,
                    width: 1.2,
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }
}
