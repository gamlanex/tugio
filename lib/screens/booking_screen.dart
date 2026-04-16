import 'package:flutter/material.dart';
import '../models/service.dart';
import '../models/booking.dart';
import '../models/calendar_view_mode.dart';
import '../data/mock_data.dart';
import '../services/device_calendar_service.dart';
import '../utils/date_helpers.dart';
import '../utils/extensions.dart';
import '../widgets/section_card.dart';
import '../widgets/services_carousel.dart';
import '../widgets/slots_panel.dart';
import '../widgets/calendar_panel.dart';
import '../l10n/app_strings.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  // ─── dane ───────────────────────────────────────────────
  final List<Service> services = initialServices;
  final List<Booking> myBookings = [];

  late Service selectedService;
  late DateTime selectedDate;
  CalendarViewMode calendarMode = CalendarViewMode.day;

  // ─── zoom ───────────────────────────────────────────────
  double _dayZoom = 1.0;
  double _weekZoom = 1.0;

  // ─── kontrolery ─────────────────────────────────────────
  late final PageController _servicePageController;
  final ScrollController _dayScrollController = ScrollController();
  final ScrollController _weekScrollController = ScrollController();

  // ─── kalendarz urządzenia ───────────────────────────────
  bool _deviceCalendarLoaded = false;
  bool _importInProgress = false;

  // ────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    selectedService = services.first;
    final now = DateTime.now();
    selectedDate = DateTime(now.year, now.month, now.day);
    _servicePageController = PageController(initialPage: 0);
    myBookings.addAll(initialBookings(selectedDate));

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadDeviceCalendarEvents();
    });
  }

  @override
  void dispose() {
    _servicePageController.dispose();
    _dayScrollController.dispose();
    _weekScrollController.dispose();
    super.dispose();
  }

  // ─── kalendarz urządzenia ───────────────────────────────
  Future<void> _loadDeviceCalendarEvents() async {
    if (_deviceCalendarLoaded || _importInProgress) return;
    _importInProgress = true;

    try {
      final from = DateTime(selectedDate.year, selectedDate.month - 1, 1, 0, 0);
      final to = DateTime(selectedDate.year, selectedDate.month + 2, 0, 23, 59);

      final imported = await DeviceCalendarService.instance.fetchEvents(from, to);

      setState(() {
        myBookings.removeWhere((b) => b.importedFromDeviceCalendar);
        myBookings.addAll(imported);
        _deviceCalendarLoaded = true;
      });
    } on DeviceCalendarPermissionDeniedException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.of(context).deviceCalendarPermissionDenied),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.of(context).calendarSyncError(e.toString()))),
        );
      }
    } finally {
      _importInProgress = false;
    }
  }

  Future<void> _reloadDeviceCalendarEvents() async {
    setState(() => _deviceCalendarLoaded = false);
    await _loadDeviceCalendarEvents();
  }

  // ─── nawigacja po dacie ─────────────────────────────────
  Future<void> _shiftDate(int direction) async {
    setState(() {
      switch (calendarMode) {
        case CalendarViewMode.day:
          selectedDate = selectedDate.add(Duration(days: direction));
        case CalendarViewMode.week:
          selectedDate = selectedDate.add(Duration(days: 7 * direction));
        case CalendarViewMode.month:
          selectedDate = DateTime(
            selectedDate.year,
            selectedDate.month + direction,
            selectedDate.day,
          );
      }
    });
    await _reloadDeviceCalendarEvents();
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 150) return;
    _shiftDate(velocity < 0 ? 1 : -1);
  }

  // ─── logika rezerwacji ───────────────────────────────────
  void _createInquiry(String time) {
    final parts = time.split(':');
    final start = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );

    final alreadyExists = myBookings.any((b) => sameDateTime(b.start, start));
    if (alreadyExists) return;

    setState(() {
      myBookings.add(
        Booking(
          id: '${selectedService.name}_${start.millisecondsSinceEpoch}',
          service: selectedService.name,
          start: start,
          durationMinutes: 60,
          status: BookingStatus.inquiry,
        ),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.of(context).inquiryCreated(selectedService.name, time))),
    );
  }

  void _confirmInquiryFromLan(String bookingId) {
    final booking = myBookings.where((b) => b.id == bookingId).firstOrNull;
    if (booking == null) return;
    setState(() => booking.status = BookingStatus.booked);
  }

  Future<void> _showCancelDialog(Booking booking) async {
    final controller = TextEditingController();
    final s = AppStrings.of(context);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final sd = AppStrings.of(ctx);
        return AlertDialog(
          title: Text(sd.cancelBookingTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${booking.service}\n${booking.timeText}'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: sd.cancelBookingReasonPlaceholder,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(sd.no),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(sd.cancelBookingConfirmButton),
            ),
          ],
        );
      },
    );

    if (result == true) {
      setState(() {
        booking.note = controller.text.trim();
        myBookings.removeWhere((b) => b.id == booking.id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              controller.text.trim().isEmpty
                  ? s.bookingCancelled
                  : s.bookingCancelledWithReason(controller.text.trim()),
            ),
          ),
        );
      }
    }
  }

  // ─── helpers ─────────────────────────────────────────────
  String _toolbarTitle() {
    switch (calendarMode) {
      case CalendarViewMode.day:
        return formatDate(selectedDate);
      case CalendarViewMode.week:
        final monday =
        selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
        final sunday = monday.add(const Duration(days: 6));
        return '${shortDate(monday)} – ${shortDate(sunday)}';
      case CalendarViewMode.month:
        return '${monthName(selectedDate.month)} ${selectedDate.year}';
    }
  }

  void _handleDayTap(DateTime day) {
    setState(() {
      selectedDate = DateTime(day.year, day.month, day.day);
      calendarMode = CalendarViewMode.day;
    });
    _reloadDeviceCalendarEvents();
  }

  // ─── build ───────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,



        title: Container(          // ← to wstaw jako title
//          height: 36,
//          color: Colors.red,
          child: SvgPicture.asset(
            'assets/images/Tugio.svg',
            height: 36,
            fit: BoxFit.contain,
          ),
        ),

        actions: [
          IconButton(
            tooltip: 'Demo: LAN confirm',
            icon: const Icon(Icons.wifi),
            onPressed: () {
              final inquiry = myBookings
                  .where((b) => b.status == BookingStatus.inquiry)
                  .firstOrNull;
              if (inquiry != null) {
                _confirmInquiryFromLan(inquiry.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(AppStrings.of(context).bookingConfirmedSimulated('inquiry'))),
                );
              }
            },
          ),
          IconButton(
            tooltip: 'Reload calendar',
            icon: const Icon(Icons.sync),
            onPressed: _reloadDeviceCalendarEvents,
          ),
        ],
      ),
      body: SafeArea(
        child: isPortrait ? _buildPortrait(s) : _buildLandscape(s),
      ),
    );
  }

  // ─── layouty ─────────────────────────────────────────────
  Widget _buildPortrait(AppStrings s) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          SectionCard(
            title: s.servicesTitle,
            child: ServicesCarousel(
              services: services,
              selectedService: selectedService,
              pageController: _servicePageController,
              onServiceChanged: (svc) => setState(() => selectedService = svc),
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: s.freeSlotsForDate(formatDate(selectedDate)),
            child: _buildSlotsPanel(),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: s.myCalendarTitle,
            child: _buildCalendarPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildLandscape(AppStrings s) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: ScrollableSection(
              title: s.servicesTitle,
              child: ServicesCarousel(
                services: services,
                selectedService: selectedService,
                pageController: _servicePageController,
                onServiceChanged: (svc) => setState(() => selectedService = svc),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: ScrollableSection(
              title: s.freeSlotsForDate(formatDate(selectedDate)),
              child: _buildSlotsPanel(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: ScrollableSection(
              title: s.myCalendarTitle,
              child: _buildCalendarPanel(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotsPanel() {
    return SlotsPanel(
      service: selectedService,
      selectedDate: selectedDate,
      bookings: myBookings,
      navigatorTitle: formatDate(selectedDate),
      onSlotTap: (slot) {
        final parts = slot.split(':');
        final slotStart = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
        final existing =
            myBookings.where((b) => sameDateTime(b.start, slotStart)).firstOrNull;
        if (existing == null) {
          _createInquiry(slot);
        } else {
          _showCancelDialog(existing);
        }
      },
      onHorizontalDragEnd: _handleHorizontalDragEnd,
      onPreviousDate: () => _shiftDate(-1),
      onNextDate: () => _shiftDate(1),
    );
  }

  Widget _buildCalendarPanel() {
    return CalendarPanel(
      calendarMode: calendarMode,
      selectedDate: selectedDate,
      bookings: myBookings,
      dayZoom: _dayZoom,
      weekZoom: _weekZoom,
      dayScrollController: _dayScrollController,
      weekScrollController: _weekScrollController,
      navigatorTitle: _toolbarTitle(),
      onModeChanged: (mode) => setState(() => calendarMode = mode),
      onHorizontalDragEnd: _handleHorizontalDragEnd,
      onDayZoomChanged: (z) => setState(() => _dayZoom = z),
      onWeekZoomChanged: (z) => setState(() => _weekZoom = z),
      onBookingTap: _showCancelDialog,
      onDayTap: _handleDayTap,
      onPreviousDate: () => _shiftDate(-1),
      onNextDate: () => _shiftDate(1),
      freeSlots: selectedService.slots,        // ← DODAJ
      slotDurationMinutes: 60,
    );
  }
}