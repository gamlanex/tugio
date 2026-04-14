import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../utils/date_helpers.dart';

class WeekCalendarView extends StatelessWidget {
  final List<DateTime> weekDays;
  final DateTime selectedDate;
  final List<Booking> bookings;
  final double zoom;
  final ScrollController scrollController;
  final void Function(Booking) onBookingTap;
  final void Function(DateTime day) onDayTap;
  final List<String> freeSlots;
  final List<String> confirmationSlots;
  final int slotDurationMinutes;
  final void Function(String slot, DateTime day)? onSlotTap;
  final double viewHeight;

  const WeekCalendarView({
    super.key,
    required this.weekDays,
    required this.selectedDate,
    required this.bookings,
    required this.zoom,
    required this.scrollController,
    required this.onBookingTap,
    required this.onDayTap,
    this.freeSlots = const [],
    this.confirmationSlots = const [],
    this.slotDurationMinutes = 60,
    this.onSlotTap,
    this.viewHeight = 520,
  });

  static const int _startHour = 7;
  static const int _endHour = 21;

  /// Buduje Positioned widgety dla jednej listy slotów.
  /// [isConfirmation] = true → pomarańczowe, false → niebieskie.
  List<Widget> _buildSlotWidgets(
    List<String> slots,
    DateTime day,
    List<Booking> dayBookings,
    double rowHeight, {
    required bool isConfirmation,
  }) {
    final result = <Widget>[];
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

      final top = ((hour - _startHour) * 60 + minute) / 60 * rowHeight;
      final height = slotDurationMinutes / 60 * rowHeight;
      final minH = height < 12 ? 12.0 : height;

      result.add(
        Positioned(
          top: top + 1,
          left: 3,
          right: 3,
          height: minH - 2,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onSlotTap != null ? () => onSlotTap!(slot, day) : null,
            child: Container(
              decoration: BoxDecoration(
                color: isConfirmation
                    ? Colors.orange.withOpacity(0.10)
                    : Colors.blue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isConfirmation
                      ? Colors.orange.withOpacity(0.45)
                      : Colors.blue.withOpacity(0.4),
                  width: 1,
                ),
              ),
              child: minH >= 18
                  ? Center(
                      child: Text(
                        slot,
                        style: TextStyle(
                          fontSize: 7.5,
                          fontWeight: FontWeight.w700,
                          color: isConfirmation
                              ? Colors.orange.shade700
                              : Colors.blue.shade700,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        ),
      );
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final double rowHeight = 38 * zoom;
    const double headerHeight = 52;
    final totalRows = _endHour - _startHour;

    // Budujemy wiersz nagłówków (wspólny kod dla sticky + siatki)
    Widget buildHeader() => Row(
          children: [
            const SizedBox(width: 52),
            ...weekDays.map((day) {
              final selected = sameDay(day, selectedDate);
              final isToday = sameDay(day, DateTime.now());
              return Expanded(
                child: InkWell(
                  onTap: () => onDayTap(day),
                  child: Container(
                    height: headerHeight,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: isToday
                          ? Colors.indigo.withOpacity(0.15)
                          : selected
                              ? Colors.indigo.withOpacity(0.08)
                              : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isToday
                            ? Colors.indigo
                            : selected
                                ? Colors.indigo.withOpacity(0.4)
                                : Colors.transparent,
                        width: isToday ? 1.8 : 1,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            weekdayShort(day.weekday),
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: isToday
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                              color: isToday
                                  ? Colors.indigo.shade700
                                  : null,
                            ),
                          ),
                          // Numer dnia — bez kółka, bieżący dzień = indigo + pogrubiony
                          Text(
                            '${day.day}',
                            style: TextStyle(
                              fontWeight: (isToday || selected)
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              fontSize: isToday ? 15 : null,
                              color: isToday ? Colors.indigo : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        );

    // Wysokość siatki = min(treść, dostępne miejsce) — bez białego ekranu po zoom-out.
    final double contentHeight = totalRows * rowHeight;
    final double maxGridHeight = viewHeight - headerHeight - 8;
    final double gridHeight = contentHeight < maxGridHeight ? contentHeight : maxGridHeight;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
          // ── nagłówki dni — STICKY (nie scrollują) ────────
          buildHeader(),
          const SizedBox(height: 8),

          // ── siatka — scrollowana osobno ──────────────────
          SizedBox(
            height: gridHeight,
            child: SingleChildScrollView(
              controller: scrollController,
              child: SizedBox(
                height: contentHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  // kolumna godzin
                  SizedBox(
                    width: 52,
                    child: Column(
                      children: List.generate(totalRows, (i) {
                        final hour = _startHour + i;
                        return SizedBox(
                          height: rowHeight,
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              '${hour.toString().padLeft(2, '0')}:00',
                              style: TextStyle(
                                  fontSize: 10.5,
                                  color: Colors.grey.shade600),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  // kolumna każdego dnia
                  ...weekDays.map((day) {
                    final dayBookings = bookings
                        .where(
                            (b) => sameDay(b.start, day) && !b.isAllDay)
                        .toList();

                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // 1. Linie godzinowe (NAJNIŻEJ) ───────
                            ...List.generate(totalRows, (i) {
                              return Positioned(
                                top: i * rowHeight,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: rowHeight,
                                  decoration: BoxDecoration(
                                    border: Border(
                                      top: BorderSide(
                                          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
                                          width: 0.8),
                                    ),
                                  ),
                                ),
                              );
                            }),

                            // 2a. Sloty natychmiastowe (niebieskie) ──
                            ..._buildSlotWidgets(
                                freeSlots, day, dayBookings, rowHeight,
                                isConfirmation: false),
                            // 2b. Sloty do potwierdzenia (pomarańczowe)
                            ..._buildSlotWidgets(
                                confirmationSlots, day, dayBookings, rowHeight,
                                isConfirmation: true),

                            // 3. Rezerwacje (NA WIERZCHU) ──────────
                            ...dayBookings.map((booking) {
                              final top =
                                  ((booking.start.hour - _startHour) *
                                              60 +
                                          booking.start.minute) /
                                      60 *
                                      rowHeight;
                              final height =
                                  booking.durationMinutes / 60 * rowHeight;
                              final minHeight = 18 * zoom;
                              final blockHeight =
                                  height < minHeight ? minHeight : height;
                              final isPending =
                                  booking.status == BookingStatus.pending;
                              final color =
                                  booking.status == BookingStatus.booked
                                      ? Colors.green
                                      : Colors.orange;

                              // Rotacja: włącz gdy blok wyższy niż ~szerokość kolumny (≈36px)
                              // Dzięki temu tekst korzysta z całej wysokości bloku
                              final rotateText = blockHeight > 36;

                              return Positioned(
                                top: top,
                                left: 3,
                                right: 3,
                                height: blockHeight,
                                child: InkWell(
                                  onTap: () => onBookingTap(booking),
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      // pending = tylko delikatna ramka, brak wypełnienia
                                      color: isPending
                                          ? Colors.transparent
                                          : color.withOpacity(0.55),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                      border: isPending
                                          ? Border.all(
                                              color: Colors.orange.withOpacity(0.7),
                                              width: 1.0,
                                            )
                                          : null,
                                    ),
                                    child: rotateText
                                        ? Align(
                                            alignment: Alignment.centerLeft,
                                            child: RotatedBox(
                                              // 270° = tekst czytany od dołu do góry
                                              quarterTurns: 3,
                                              child: SizedBox(
                                                // jawna szerokość = dostępna wysokość bloku
                                                // dzięki temu Flutter wie gdzie uciąć i dodać "..."
                                                width: blockHeight - 6,
                                                child: Text(
                                                  booking.service,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 8.5,
                                                    fontWeight: FontWeight.w600,
                                                    height: 1.0,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          )
                                        : Text(
                                            booking.service,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 8.5,
                                              fontWeight: FontWeight.w600,
                                              height: 1.0,
                                            ),
                                          ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),         // SingleChildScrollView
        ),           // SizedBox(gridHeight)
      ],             // Column children
    );               // Column
  }
}
