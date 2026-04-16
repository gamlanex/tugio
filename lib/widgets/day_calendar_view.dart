import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../utils/date_helpers.dart';
import '../l10n/app_strings.dart';

/// Opisuje pozycję rezerwacji w układzie kolumnowym (dla nakładających się eventów).
class _EventLayout {
  final Booking booking;
  final int columnIndex;
  final int totalColumns;

  const _EventLayout(this.booking, this.columnIndex, this.totalColumns);
}

class DayCalendarView extends StatelessWidget {
  final DateTime selectedDate;
  final List<Booking> bookings;
  final double zoom;
  final ScrollController scrollController;
  final void Function(Booking) onBookingTap;
  final List<String> freeSlots;
  final List<String> confirmationSlots;
  final int slotDurationMinutes;
  /// Pracownicy dostępni na dany slot (np. ['Krysia', 'Basia']).
  final Map<String, List<String>> slotStaff;
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
    this.slotStaff = const {},
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

  /// Oblicza układ kolumnowy dla nakładających się rezerwacji.
  /// Każda rezerwacja dostaje [columnIndex] i [totalColumns] — pozwala
  /// wyświetlić nakładające się eventy obok siebie zamiast jeden na drugim.
  static List<_EventLayout> _computeEventLayouts(List<Booking> events) {
    if (events.isEmpty) return [];

    // Posortuj wg czasu początku
    final sorted = List<Booking>.from(events)
      ..sort((a, b) => a.start.compareTo(b.start));

    // Dla każdego eventu wyznacz kolumnę — pierwsza wolna kolumna w danym czasie
    final List<int> colEndMinutes = []; // kiedy dana kolumna jest wolna
    final List<int> colAssignment = List.filled(sorted.length, 0);

    for (int i = 0; i < sorted.length; i++) {
      final startMin = sorted[i].start.hour * 60 + sorted[i].start.minute;
      final endMin = startMin + sorted[i].durationMinutes.clamp(1, 24 * 60);

      // Znajdź pierwszą wolną kolumnę
      int col = 0;
      while (col < colEndMinutes.length && colEndMinutes[col] > startMin) {
        col++;
      }
      if (col == colEndMinutes.length) {
        colEndMinutes.add(endMin);
      } else {
        colEndMinutes[col] = endMin;
      }
      colAssignment[i] = col;
    }

    // Dla każdego eventu oblicz totalColumns = maks. kolumna+1 wśród wszystkich
    // eventów, które nakładają się z nim w czasie (= "szerokość grupy")
    final List<int> totalCols = List.filled(sorted.length, 1);
    for (int i = 0; i < sorted.length; i++) {
      final aStart = sorted[i].start.hour * 60 + sorted[i].start.minute;
      final aEnd = aStart + sorted[i].durationMinutes.clamp(1, 24 * 60);
      int maxCol = colAssignment[i];
      for (int j = 0; j < sorted.length; j++) {
        if (i == j) continue;
        final bStart = sorted[j].start.hour * 60 + sorted[j].start.minute;
        final bEnd = bStart + sorted[j].durationMinutes.clamp(1, 24 * 60);
        if (aStart < bEnd && aEnd > bStart) {
          if (colAssignment[j] > maxCol) maxCol = colAssignment[j];
        }
      }
      totalCols[i] = maxCol + 1;
    }

    return List.generate(
      sorted.length,
      (i) => _EventLayout(sorted[i], colAssignment[i], totalCols[i]),
    );
  }

  /// Builds slot widgets for the day view.
  /// [isConfirmation] = true → pomarańczowe, false → niebieskie.
  List<Widget> _buildSlotWidgets(
    List<String> slots,
    List<Booking> timedBookings,
    double hourRowHeight, {
    required bool isConfirmation,
    required AppStrings s,
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
      final showLabel = height >= 22;
      final showHint = height >= 40;
      final staff = slotStaff[slot] ?? []; // lista pracowników na ten slot

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
                                if (staff.isNotEmpty && showLabel)
                                  Text(
                                    staff.length == 1
                                        ? staff.first
                                        : staff.length == 2
                                            ? '${staff[0]} · ${staff[1]}'
                                            : '${staff[0]}, +${staff.length - 1}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w600,
                                      color: isConfirmation
                                          ? Colors.orange.shade700
                                          : Colors.blue.shade700,
                                      height: 1.2,
                                    ),
                                  )
                                else if (showHint)
                                  Text(
                                    isConfirmation
                                        ? s.sendRequestHint
                                        : s.bookHint,
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
    final s = AppStrings.of(context);
    final totalHours = _endHour - _startHour;
    // Minimalna wysokość wiersza gwarantująca czytelny tekst w komórkach.
    // zoom=1.0 → "dopasuj do ekranu", ale nigdy poniżej _minHourRowHeight.
    // zoom=1.0 → każda godzina zajmuje dokładnie viewHeight/totalHours px
    // → cały dzień mieści się na ekranie bez scrollowania.
    // minZoom=1.0 w ZoomListener gwarantuje, że nie zejdziemy poniżej.
    final double hourRowHeight = (viewHeight / totalHours) * zoom;
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
          Text(
            s.allDay,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
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
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
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
                                    color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),

                        // 2. Wolne sloty (niebieskie, pół-szerokości, prawa strona)
                        ..._buildSlotWidgets(freeSlots, timedBookings, hourRowHeight, isConfirmation: false, s: s),
                        ..._buildSlotWidgets(confirmationSlots, timedBookings, hourRowHeight, isConfirmation: true, s: s),

                        // 3. Rezerwacje z układem kolumnowym (NA WIERZCHU) ───
                        ..._computeEventLayouts(timedBookings).expand(
                          (layout) sync* {
                            final containerWidth =
                                MediaQuery.sizeOf(context).width -
                                    _timeColumnWidth -
                                    32; // przybliżona szerokość kontenera
                            const edgeMargin = 8.0;
                            const colGap = 3.0;
                            final usableWidth = containerWidth - edgeMargin * 2;
                            final colWidth =
                                (usableWidth - colGap * (layout.totalColumns - 1)) /
                                    layout.totalColumns;
                            final eventLeft = edgeMargin +
                                layout.columnIndex * (colWidth + colGap);

                            final startMinutes =
                                (layout.booking.start.hour - _startHour) * 60 +
                                    layout.booking.start.minute;
                            final top = startMinutes / 60 * hourRowHeight;
                            final rawHeight =
                                layout.booking.durationMinutes / 60 * hourRowHeight;
                            final blockHeight = rawHeight < 34 ? 34.0 : rawHeight;

                            final isPending =
                                layout.booking.status == BookingStatus.pending;
                            final color =
                                layout.booking.status == BookingStatus.booked
                                    ? Colors.green
                                    : Colors.orange;

                            final showTime = blockHeight >= 52;
                            final showStatus = blockHeight >= 68;

                            yield Positioned(
                              top: top,
                              left: eventLeft,
                              width: colWidth,
                              height: blockHeight,
                              child: InkWell(
                                onTap: () => onBookingTap(layout.booking),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isPending
                                        ? Colors.transparent
                                        : color.withOpacity(0.20),
                                    borderRadius: BorderRadius.circular(12),
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
                                          layout.booking.service,
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
                                            layout.booking.timeText,
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
                                                ? s.statusPending
                                                : layout.booking.status ==
                                                        BookingStatus.booked
                                                    ? s.statusBooked
                                                    : s.statusInquiry,
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
                          },
                        ),
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
