import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../models/calendar_view_mode.dart';
import '../utils/date_helpers.dart';
import 'date_navigator.dart';
import 'day_calendar_view.dart';
import 'week_calendar_view.dart';
import 'month_calendar_view.dart';
import 'zoom_listener.dart';

/// Tryb filtrowania kalendarza — cyklicznie przełączany jednym przyciskiem.
enum CalendarFilter {
  /// Pokazuj wszystko: wolne sloty + rezerwacje + eventy z kalendarza urządzenia.
  all,
  /// Ukryj wolne sloty — pokazuj tylko rezerwacje i eventy z kalendarza.
  noSlots,
  /// Tylko moje wizyty — ukryj sloty i eventy zaimportowane z kalendarza.
  onlyMine,
}

class CalendarPanel extends StatelessWidget {
  final CalendarViewMode calendarMode;
  final DateTime selectedDate;
  final List<Booking> bookings;
  final double dayZoom;
  final double weekZoom;
  final ScrollController dayScrollController;
  final ScrollController weekScrollController;
  final void Function(CalendarViewMode) onModeChanged;
  final void Function(DragEndDetails) onHorizontalDragEnd;
  final void Function(double zoom) onDayZoomChanged;
  final void Function(double zoom) onWeekZoomChanged;
  final void Function(Booking) onBookingTap;
  final void Function(DateTime day) onDayTap;
  final VoidCallback onPreviousDate;
  final VoidCallback onNextDate;
  final String navigatorTitle;
  final List<String> freeSlots;
  final int slotDurationMinutes;
  /// Callback gdy użytkownik tapnie wolny slot (slot, dzień).
  final void Function(String slot, DateTime day)? onSlotTap;
  /// Callback przycisku "Dziś" — przeskakuje do dnia dzisiejszego.
  final VoidCallback? onTodayPressed;
  /// Sloty wymagające potwierdzenia — pokazywane jako pomarańczowe.
  final List<String> confirmationSlots;
  /// Pracownicy dostępni na dany slot — widoczne w widoku dnia.
  final Map<String, List<String>> slotStaff;
  /// Aktywny filtr kalendarza — cyklicznie przełączany jednym przyciskiem.
  final CalendarFilter calendarFilter;
  /// Callback cyklicznego przełącznika filtra.
  final VoidCallback? onCycleFilter;

  const CalendarPanel({
    super.key,
    required this.calendarMode,
    required this.selectedDate,
    required this.bookings,
    required this.dayZoom,
    required this.weekZoom,
    required this.dayScrollController,
    required this.weekScrollController,
    required this.onModeChanged,
    required this.onHorizontalDragEnd,
    required this.onDayZoomChanged,
    required this.onWeekZoomChanged,
    required this.onBookingTap,
    required this.onDayTap,
    required this.onPreviousDate,
    required this.onNextDate,
    required this.navigatorTitle,
    this.freeSlots = const [],
    this.slotDurationMinutes = 60,
    this.onSlotTap,
    this.onTodayPressed,
    this.confirmationSlots = const [],
    this.slotStaff = const {},
    this.calendarFilter = CalendarFilter.all,
    this.onCycleFilter,
  });

  List<DateTime> get _weekDays {
    final monday = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  @override
  Widget build(BuildContext context) {
    // Dynamiczna wysokość widoku.
    // W landscape ekran jest krótki — używamy większego % i niższego minimum.
    final size = MediaQuery.sizeOf(context);
    final isLandscape = size.width > size.height;
    final screenH = size.height;
    final viewHeight = isLandscape
        ? (screenH * 0.88).clamp(240.0, 800.0)
        : (screenH * 0.62).clamp(360.0, 800.0);

    // Filtrowanie zgodnie z aktywnym trybem.
    final showSlots = calendarFilter == CalendarFilter.all;
    final effectiveBookings = calendarFilter == CalendarFilter.onlyMine
        ? bookings.where((b) => !b.importedFromDeviceCalendar).toList()
        : bookings;
    final effectiveSlots = showSlots ? freeSlots : const <String>[];
    final effectiveConfirmation = showSlots ? confirmationSlots : const <String>[];
    final effectiveStaff = showSlots ? slotStaff : const <String, List<String>>{};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CalendarToolbar(
          calendarMode: calendarMode,
          selectedDate: selectedDate,
          navigatorTitle: navigatorTitle,
          onModeChanged: onModeChanged,
          onPrevious: onPreviousDate,
          onNext: onNextDate,
          onToday: onTodayPressed,
          calendarFilter: calendarFilter,
          onCycleFilter: onCycleFilter,
        ),
        const SizedBox(height: 12),
        if (calendarMode == CalendarViewMode.day)
          ZoomListener(
            scrollController: dayScrollController,
            initialZoom: dayZoom,
            onZoomChanged: onDayZoomChanged,
            onHorizontalDragEnd: onHorizontalDragEnd,
            minZoom: 0.4,
            maxZoom: 4.0,
            child: DayCalendarView(
              selectedDate: selectedDate,
              bookings: effectiveBookings,
              zoom: dayZoom,
              scrollController: dayScrollController,
              onBookingTap: onBookingTap,
              freeSlots: effectiveSlots,
              confirmationSlots: effectiveConfirmation,
              slotDurationMinutes: slotDurationMinutes,
              slotStaff: effectiveStaff,
              viewHeight: viewHeight,
              onSlotTap: (calendarFilter == CalendarFilter.all) && onSlotTap != null
                  ? (slot) => onSlotTap!(slot, selectedDate)
                  : null,
            ),
          ),
        if (calendarMode == CalendarViewMode.week)
          ZoomListener(
            scrollController: weekScrollController,
            initialZoom: weekZoom,
            onZoomChanged: onWeekZoomChanged,
            onHorizontalDragEnd: onHorizontalDragEnd,
            minZoom: 0.7,
            maxZoom: 6.0,
            child: WeekCalendarView(
              weekDays: _weekDays,
              selectedDate: selectedDate,
              bookings: effectiveBookings,
              zoom: weekZoom,
              scrollController: weekScrollController,
              onBookingTap: onBookingTap,
              onDayTap: onDayTap,
              freeSlots: effectiveSlots,
              confirmationSlots: effectiveConfirmation,
              slotDurationMinutes: slotDurationMinutes,
              viewHeight: viewHeight,
              onSlotTap: calendarFilter == CalendarFilter.all ? onSlotTap : null,
            ),
          ),
        if (calendarMode == CalendarViewMode.month)
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragEnd: onHorizontalDragEnd,
            child: MonthCalendarView(
              selectedDate: selectedDate,
              bookings: effectiveBookings,
              onDayTap: onDayTap,
              maxHeight: viewHeight,
              freeSlots: effectiveSlots,
              confirmationSlots: effectiveConfirmation,
              slotDurationMinutes: slotDurationMinutes,
            ),
          ),
      ],
    );
  }
}

class _CalendarToolbar extends StatelessWidget {
  final CalendarViewMode calendarMode;
  final DateTime selectedDate;
  final String navigatorTitle;
  final void Function(CalendarViewMode) onModeChanged;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback? onToday;
  final CalendarFilter calendarFilter;
  final VoidCallback? onCycleFilter;

  const _CalendarToolbar({
    required this.calendarMode,
    required this.selectedDate,
    required this.navigatorTitle,
    required this.onModeChanged,
    required this.onPrevious,
    required this.onNext,
    this.onToday,
    this.calendarFilter = CalendarFilter.all,
    this.onCycleFilter,
  });

  /// Czy dzień dzisiejszy jest widoczny w bieżącym widoku.
  bool get _isTodayVisible {
    final today = DateTime.now();
    switch (calendarMode) {
      case CalendarViewMode.day:
        return selectedDate.year == today.year &&
            selectedDate.month == today.month &&
            selectedDate.day == today.day;
      case CalendarViewMode.week:
        final monday =
            selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
        final sunday = monday.add(const Duration(days: 6));
        return !today.isBefore(
                DateTime(monday.year, monday.month, monday.day)) &&
            !today.isAfter(DateTime(sunday.year, sunday.month, sunday.day,
                23, 59, 59));
      case CalendarViewMode.month:
        return selectedDate.year == today.year &&
            selectedDate.month == today.month;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DateNavigator(
          title: navigatorTitle,
          onPrevious: onPrevious,
          onNext: onNext,
          onToday: onToday,
          isToday: _isTodayVisible,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            // ── Przełącznik widok dnia/tygodnia/miesiąca ──────
            Expanded(
              child: SegmentedButton<CalendarViewMode>(
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  ),
                  textStyle: WidgetStateProperty.all(
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                segments: const [
                  ButtonSegment(
                    value: CalendarViewMode.day,
                    label: Text('Dzień', maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  ButtonSegment(
                    value: CalendarViewMode.week,
                    label: Text('Tydz.', maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  ButtonSegment(
                    value: CalendarViewMode.month,
                    label: Text('Mies.', maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
                selected: {calendarMode},
                onSelectionChanged: (value) => onModeChanged(value.first),
              ),
            ),
            // ── Cykliczny filtr kalendarza (all → noSlots → onlyMine → …) ──
            const SizedBox(width: 8),
            Tooltip(
              message: switch (calendarFilter) {
                CalendarFilter.all      => 'Wszystko (kliknij: ukryj sloty)',
                CalendarFilter.noSlots  => 'Bez wolnych slotów (kliknij: tylko moje wizyty)',
                CalendarFilter.onlyMine => 'Tylko moje wizyty (kliknij: pokaż wszystko)',
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: switch (calendarFilter) {
                    CalendarFilter.all      => Theme.of(context).colorScheme.primaryContainer,
                    CalendarFilter.noSlots  => Theme.of(context).colorScheme.surfaceVariant,
                    CalendarFilter.onlyMine => Theme.of(context).colorScheme.tertiaryContainer,
                  },
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: onCycleFilter,
                  icon: Icon(
                    switch (calendarFilter) {
                      CalendarFilter.all      => Icons.event_available_rounded,
                      CalendarFilter.noSlots  => Icons.event_busy_rounded,
                      CalendarFilter.onlyMine => Icons.bookmark_rounded,
                    },
                    size: 20,
                    color: switch (calendarFilter) {
                      CalendarFilter.all      => Theme.of(context).colorScheme.onPrimaryContainer,
                      CalendarFilter.noSlots  => Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      CalendarFilter.onlyMine => Theme.of(context).colorScheme.onTertiaryContainer,
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}