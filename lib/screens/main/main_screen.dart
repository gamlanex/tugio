import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../models/provider.dart';
import '../../models/booking.dart';
import '../../models/calendar_view_mode.dart';
import '../../models/service_option.dart';
import '../../repositories/booking_repository.dart';
import '../../repositories/mock_booking_repository.dart';
import '../../repositories/mock_provider_repository.dart';
import '../../repositories/provider_repository.dart';
import '../../services/auth_service.dart';
import '../../services/calendar_sync_service.dart';
import '../../services/device_calendar_service.dart';
import '../../services/google_calendar_service.dart' show GoogleCalendarNotSignedInException;
import '../../services/ics_import_service.dart';
import '../../utils/date_helpers.dart';
import '../../utils/provider_avatar.dart';
import '../../main.dart' show themeModeNotifier, useMockNotifier, authStateNotifier, AuthState;
import '../../repositories/http_booking_repository.dart';
import '../../repositories/http_provider_repository.dart';
import '../../widgets/booking_bottom_sheet.dart';
import '../../widgets/booking_detail_sheet.dart';
import '../../widgets/section_card.dart';
import '../../widgets/staff_picker_sheet.dart';
import '../../widgets/calendar_panel.dart';
import '../../services/local_auth_service.dart';
import '../subscribed_providers_screen.dart';
import '../pin_setup_screen.dart';
import '../service_type_screen.dart';
import '../provider_detail_screen.dart';
import 'widgets/bookings_section.dart';
import 'widgets/providers_section.dart';
import 'widgets/add_booking_sheet.dart';
import 'widgets/security_settings_sheet.dart';

export 'widgets/bookings_section.dart';
export 'widgets/providers_section.dart';
export 'widgets/collapsible_section.dart';
export 'widgets/add_booking_sheet.dart';
export 'widgets/security_settings_sheet.dart';

class MainScreen extends StatefulWidget {
  /// Gdy true (np. po nawigacji z HomeScreen), AppBar pokazuje przycisk powrotu.
  final bool showBackButton;
  /// ID dostawcy który ma być wybrany po załadowaniu (null = pierwszy z listy).
  final String? initialProviderId;

  const MainScreen({
    super.key,
    this.showBackButton = false,
    this.initialProviderId,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // ─── repozytoria (dynamicznie wybierane: Mock lub HTTP) ───
  ProviderRepository _providerRepo = MockProviderRepository();
  BookingRepository _bookingRepo = MockBookingRepository();

  // ─── lista usługodawców ───────────────────────────────────
  final List<ServiceProvider> _providers = [];

  // ─── rezerwacje ───────────────────────────────────────────
  final List<Booking> _myBookings = [];

  // ─── aktualny wybór ───────────────────────────────────────
  ServiceProvider? _selectedProvider;
  late DateTime _selectedDate;
  CalendarViewMode _calendarMode = CalendarViewMode.day;

  // ─── zoom ─────────────────────────────────────────────────
  double _dayZoom = 1.0;
  double _weekZoom = 1.0;

  // ─── kontrolery ──────────────────────────────────────────
  final ScrollController _dayScrollController = ScrollController();
  final ScrollController _weekScrollController = ScrollController();

  // ─── kalendarz urządzenia ────────────────────────────────
  bool _deviceCalendarLoaded = false;
  bool _importInProgress = false;

  // ─── stan zwijanych sekcji ────────────────────────────────
  bool _providersExpanded = false;
  bool _bookingsExpanded = false;

  // ─── filtr kalendarza (cykliczny) ─────────────────────────
  CalendarFilter _calendarFilter = CalendarFilter.all;

  // ─────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    final providers = await _providerRepo.getSubscribed();
    final bookings = await _bookingRepo.getInitial(_selectedDate);
    if (!mounted) return;
    setState(() {
      _providers.addAll(providers);
      // Jeśli przekazano initialProviderId, ustaw tego dostawcę jako wybranego.
      if (widget.initialProviderId != null) {
        _selectedProvider = _providers.firstWhere(
          (p) => p.id == widget.initialProviderId,
          orElse: () => _providers.first,
        );
      } else {
        _selectedProvider = _providers.first;
      }
      _myBookings.addAll(bookings);
    });
    await _loadDeviceCalendarEvents();
  }

  @override
  void dispose() {
    _dayScrollController.dispose();
    _weekScrollController.dispose();
    super.dispose();
  }

  // ─── synchronizacja kalendarza ────────────────────────────
  Future<void> _loadDeviceCalendarEvents() async {
    if (_deviceCalendarLoaded || _importInProgress) return;
    _importInProgress = true;
    try {
      final imported =
          await CalendarSyncService.instance.fetchEvents(_selectedDate);
      if (mounted) {
        setState(() {
          _myBookings.removeWhere((b) => b.importedFromDeviceCalendar);
          _myBookings.addAll(imported);
          _deviceCalendarLoaded = true;
        });
      }
    } on GoogleCalendarNotSignedInException {
      // Nie jesteśmy zalogowani — CalendarSyncService obsługuje fallback
    } on DeviceCalendarPermissionDeniedException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Brak zgody na odczyt kalendarza urządzenia')),
        );
      }
    } catch (e) {
      debugPrint('Calendar sync error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd kalendarza: $e'),
            duration: const Duration(seconds: 8),
          ),
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

  /// Formatuje czas oczekiwania od [since] do teraz
  String _formatWaitTime(DateTime since) {
    final diff = DateTime.now().difference(since);
    if (diff.inMinutes < 1) return 'chwilę';
    if (diff.inHours < 1) return '${diff.inMinutes} min';
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    return m > 0 ? '${h}h ${m}min' : '${h}h';
  }

  // ─── nawigacja "Dziś" ─────────────────────────────────────
  void _handleTodayPressed() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (_selectedDate == today) return;
    setState(() => _selectedDate = today);
    _reloadDeviceCalendarEvents();
  }

  /// Import pliku .ics (web i desktop)
  Future<void> _importIcsFile() async {
    try {
      final imported = await IcsImportService.instance.pickAndImport();
      if (!mounted) return;

      if (imported.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plik .ics nie zawiera żadnych eventów')),
        );
        return;
      }

      setState(() {
        _myBookings.removeWhere(
          (b) => b.importedFromDeviceCalendar && b.note == 'Imported from .ics',
        );
        _myBookings.addAll(imported);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Zaimportowano ${imported.length} eventów z kalendarza'),
            action: SnackBarAction(label: 'OK', onPressed: () {}),
          ),
        );
      }
    } on IcsImportCancelledException {
      // użytkownik anulował
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd importu: $e')),
        );
      }
    }
  }

  // ─── nawigacja po dacie ───────────────────────────────────
  Future<void> _shiftDate(int direction) async {
    setState(() {
      switch (_calendarMode) {
        case CalendarViewMode.day:
          _selectedDate = _selectedDate.add(Duration(days: direction));
        case CalendarViewMode.week:
          _selectedDate = _selectedDate.add(Duration(days: 7 * direction));
        case CalendarViewMode.month:
          _selectedDate = DateTime(
            _selectedDate.year,
            _selectedDate.month + direction,
            _selectedDate.day,
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

  // ─── logika rezerwacji ────────────────────────────────────
  Future<void> _handleSlotTap(String time, DateTime day) async {
    final parts = time.split(':');
    final start = DateTime(
      day.year, day.month, day.day,
      int.parse(parts[0]), int.parse(parts[1]),
    );

    final alreadyExists = _myBookings.any((b) => sameDateTime(b.start, start));
    if (alreadyExists) return;

    final isConfirmationSlot =
        _selectedProvider!.confirmationSlots.contains(time);

    final staffList = _selectedProvider!.slotStaff[time] ?? [];
    String? chosenStaff;

    if (staffList.length == 1) {
      chosenStaff = staffList.first;
    } else if (staffList.length > 1) {
      chosenStaff = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) => StaffPickerSheet(
          staffList: staffList,
          time: time,
          providerName: _selectedProvider!.name,
        ),
      );
      if (chosenStaff == null || !mounted) return;
    }

    final chosenService = await showModalBottomSheet<ServiceOption>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BookingBottomSheet(
        provider: _selectedProvider!,
        time: time,
        day: day,
        staffName: chosenStaff,
      ),
    );

    if (chosenService != null && mounted) {
      _createBooking(time, day, chosenService,
          forceConfirmation: isConfirmationSlot, staffName: chosenStaff);
    }
  }

  Future<void> _createBooking(String time, DateTime day, ServiceOption service,
      {bool forceConfirmation = false, String? staffName}) async {
    final parts = time.split(':');
    final start = DateTime(
      day.year, day.month, day.day,
      int.parse(parts[0]), int.parse(parts[1]),
    );

    final isPending = forceConfirmation || service.requiresConfirmation;
    final now = DateTime.now();

    final booking = Booking(
      id: '${_selectedProvider!.id}_${start.millisecondsSinceEpoch}',
      service: service.name,
      start: start,
      durationMinutes: service.durationMinutes,
      status: isPending ? BookingStatus.pending : BookingStatus.booked,
      note: isPending ? 'Oczekuje na potwierdzenie' : null,
      pendingSince: isPending ? now : null,
      staffName: staffName,
      providerId: _selectedProvider!.id,
    );

    try {
      await _bookingRepo.create(booking);
    } catch (e) {
      debugPrint('BookingRepository.create error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd tworzenia rezerwacji: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
      return;
    }

    if (mounted) {
      setState(() {
        _myBookings.add(booking);
        _bookingsExpanded = true;
      });
    }
  }

  Future<void> _showCancelDialog(Booking booking) async {
    final provider = booking.providerId != null
        ? _providers.firstWhere(
            (p) => p.id == booking.providerId,
            orElse: () => _selectedProvider!,
          )
        : _selectedProvider!;

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
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Odwołać rezerwację?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${booking.service}\n${booking.timeText}'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Powód (opcjonalnie)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
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
      try {
        await _bookingRepo.cancel(booking.id);
      } catch (e) {
        debugPrint('BookingRepository.cancel error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Błąd anulowania rezerwacji: $e'),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
        return;
      }

      if (mounted) {
        setState(() {
          booking.note = controller.text.trim();
          _myBookings.removeWhere((b) => b.id == booking.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              controller.text.trim().isEmpty
                  ? 'Rezerwacja odwołana'
                  : 'Rezerwacja odwołana: ${controller.text.trim()}',
            ),
          ),
        );
      }
    }
  }

  // ─── helpers ─────────────────────────────────────────────
  String _toolbarTitle() {
    switch (_calendarMode) {
      case CalendarViewMode.day:
        return formatDate(_selectedDate);
      case CalendarViewMode.week:
        final monday =
            _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
        final sunday = monday.add(const Duration(days: 6));
        return '${shortDate(monday)} – ${shortDate(sunday)}';
      case CalendarViewMode.month:
        return '${monthName(_selectedDate.month)} ${_selectedDate.year}';
    }
  }

  void _handleDayTap(DateTime day) {
    setState(() {
      _selectedDate = DateTime(day.year, day.month, day.day);
      _calendarMode = CalendarViewMode.day;
    });
    _reloadDeviceCalendarEvents();
  }

  // ─── flow dodawania rezerwacji ────────────────────────────
  void _showAddBookingSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => AddBookingSheet(
        onExistingProvider: () {
          Navigator.pop(ctx);
          _openSubscribedProviders();
        },
        onNewProvider: () {
          Navigator.pop(ctx);
          _openServiceTypePicker();
        },
      ),
    );
  }

  void _openSubscribedProviders() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubscribedProvidersScreen(
          providers: _providers,
          selectedProvider: _selectedProvider!,
          selectedDate: _selectedDate,
          bookings: _myBookings,
          onProviderSelected: (provider) {
            setState(() => _selectedProvider = provider);
          },
          onBookingCreated: (booking) {
            setState(() => _myBookings.add(booking));
          },
          onBookingCancelled: (bookingId) {
            setState(() => _myBookings.removeWhere((b) => b.id == bookingId));
          },
        ),
      ),
    );
  }

  void _openServiceTypePicker() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ServiceTypeScreen(
          onProviderSubscribed: (provider) {
            setState(() {
              _providers.add(provider);
              _selectedProvider = provider;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Zasubskrybowano: ${provider.name}'),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Przełącza między danymi Mock a prawdziwym API i przeładowuje dane.
  Future<void> _toggleDataSource() async {
    final switchToApi = useMockNotifier.value;
    useMockNotifier.value = !switchToApi;

    setState(() {
      if (switchToApi) {
        _providerRepo = HttpProviderRepository();
        _bookingRepo = HttpBookingRepository();
      } else {
        _providerRepo = MockProviderRepository();
        _bookingRepo = MockBookingRepository();
      }
      _providers.clear();
      _myBookings.clear();
      _selectedProvider = null;
      _deviceCalendarLoaded = false;
    });

    try {
      await _loadInitialData();
    } catch (e) {
      if (!mounted) return;
      useMockNotifier.value = true;
      setState(() {
        _providerRepo = MockProviderRepository();
        _bookingRepo = MockBookingRepository();
        _providers.clear();
        _myBookings.clear();
        _selectedProvider = null;
        _deviceCalendarLoaded = false;
      });
      await _loadInitialData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Błąd połączenia z API: $e\nPrzywrócono tryb Mock.'),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _handleSignOut() async {
    await AuthService.instance.signOut(useMock: useMockNotifier.value);
    authStateNotifier.value = AuthState.unauthenticated;
  }

  Future<void> _openSecuritySettings() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const SecuritySettingsSheet(),
    );
  }

  // ─── build ───────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_selectedProvider == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final provider = _selectedProvider!;
    final user = AuthService.instance.currentUser;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1E1828)
          : const Color(0xFFF3E8FB),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E1828)
            : const Color(0xFFF3E8FB),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset('assets/images/Tugio.svg', height: 28),
            if (provider.name.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                provider.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6A1B9A),
                ),
              ),
            ],
          ],
        ),
        leading: widget.showBackButton
            ? const BackButton()
            : null,
        actions: [
          if (kIsWeb && !AuthService.instance.isSignedIn)
            IconButton(
              tooltip: 'Importuj kalendarz (.ics)',
              icon: const Icon(Icons.upload_file_outlined),
              onPressed: _importIcsFile,
            ),
          IconButton(
            tooltip: 'Odśwież / synchronizuj kalendarz',
            icon: const Icon(Icons.sync),
            onPressed: _reloadDeviceCalendarEvents,
          ),
          // Nasłuchuje obu notifierów jednocześnie
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeModeNotifier,
            builder: (_, themeMode, __) =>
                ValueListenableBuilder<bool>(
              valueListenable: useMockNotifier,
              builder: (_, isMock, __) {
                final isDark = themeMode == ThemeMode.dark;
                return PopupMenuButton<String>(
                  icon: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.indigo.shade100,
                    backgroundImage: user?.photoUrl != null
                        ? NetworkImage(user!.photoUrl!)
                        : null,
                    child: user?.photoUrl == null
                        ? Icon(Icons.person,
                            size: 18, color: Colors.indigo.shade600)
                        : null,
                  ),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      enabled: false,
                      child: Text(
                        user?.name ?? user?.email ?? 'Zalogowany',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'theme',
                      child: Row(
                        children: [
                          Icon(
                            isDark
                                ? Icons.light_mode_outlined
                                : Icons.dark_mode_outlined,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(isDark ? 'Jasna skórka' : 'Ciemna skórka'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'datasource',
                      child: Row(
                        children: [
                          Icon(
                            isMock
                                ? Icons.cloud_outlined
                                : Icons.storage_rounded,
                            size: 18,
                            color: isMock
                                ? Colors.orange.shade700
                                : Colors.green.shade700,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isMock
                                      ? 'Przełącz na API'
                                      : 'Przełącz na Mock',
                                  style: const TextStyle(fontSize: 13),
                                ),
                                Text(
                                  isMock ? 'Teraz: dane lokalne' : 'Teraz: API',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isMock
                                        ? Colors.orange.shade700
                                        : Colors.green.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'security',
                      child: Row(
                        children: [
                          Icon(Icons.security_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Zabezpieczenia'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'signout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, size: 18),
                          SizedBox(width: 8),
                          Text('Wyloguj'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'signout') _handleSignOut();
                    if (value == 'theme') {
                      themeModeNotifier.value =
                          isDark ? ThemeMode.light : ThemeMode.dark;
                    }
                    if (value == 'datasource') _toggleDataSource();
                    if (value == 'security') _openSecuritySettings();
                  },
                );
              },
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // ── Kalendarz ─────────────────────────────────
              SectionCard(
                child: CalendarPanel(
                  calendarMode: _calendarMode,
                  selectedDate: _selectedDate,
                  bookings: _myBookings,
                  dayZoom: _dayZoom,
                  weekZoom: _weekZoom,
                  dayScrollController: _dayScrollController,
                  weekScrollController: _weekScrollController,
                  navigatorTitle: _toolbarTitle(),
                  onModeChanged: (mode) =>
                      setState(() => _calendarMode = mode),
                  onHorizontalDragEnd: _handleHorizontalDragEnd,
                  onDayZoomChanged: (z) => setState(() => _dayZoom = z),
                  onWeekZoomChanged: (z) => setState(() => _weekZoom = z),
                  onBookingTap: _showCancelDialog,
                  onDayTap: _handleDayTap,
                  onPreviousDate: () => _shiftDate(-1),
                  onNextDate: () => _shiftDate(1),
                  freeSlots: provider.slots,
                  confirmationSlots: provider.confirmationSlots,
                  slotDurationMinutes: provider.slotDurationMinutes,
                  slotStaff: provider.slotStaff,
                  onSlotTap: _handleSlotTap,
                  onTodayPressed: _handleTodayPressed,
                  calendarFilter: _calendarFilter,
                  onCycleFilter: () => setState(() {
                    _calendarFilter = CalendarFilter.values[
                      (_calendarFilter.index + 1) % CalendarFilter.values.length
                    ];
                  }),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ─── nadchodzące rezerwacje (zwijane) ────────────────────
  Widget _buildUpcomingBookings() {
    final upcoming = _myBookings
        .where((b) =>
            !b.isAllDay &&
            !b.importedFromDeviceCalendar &&
            b.start.isAfter(DateTime.now()))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));

    if (upcoming.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: BookingsSection(
        bookings: upcoming,
        expanded: _bookingsExpanded,
        onToggle: () =>
            setState(() => _bookingsExpanded = !_bookingsExpanded),
        formatWaitTime: _formatWaitTime,
        onBookingTap: _showCancelDialog,
        onSimulateConfirm: (booking) {
          setState(() => booking.status = BookingStatus.booked);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('✅ Rezerwacja "${booking.service}" potwierdzona!'),
              backgroundColor: Colors.green.shade700,
              duration: const Duration(seconds: 3),
            ),
          );
        },
      ),
    );
  }
}
