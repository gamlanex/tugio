import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/provider.dart';
import '../models/booking.dart';
import '../models/calendar_view_mode.dart';
import '../models/service_option.dart';
import '../repositories/booking_repository.dart';
import '../repositories/mock_booking_repository.dart';
import '../repositories/mock_provider_repository.dart';
import '../repositories/provider_repository.dart';
import '../services/auth_service.dart';
import '../services/calendar_sync_service.dart';
import '../services/device_calendar_service.dart';
import '../services/google_calendar_service.dart' show GoogleCalendarNotSignedInException;
import '../services/ics_import_service.dart';
import '../utils/date_helpers.dart';
import '../utils/provider_avatar.dart';
import '../main.dart' show themeModeNotifier, useMockNotifier, authStateNotifier, AuthState;
import '../repositories/http_booking_repository.dart';
import '../repositories/http_provider_repository.dart';
import '../widgets/booking_bottom_sheet.dart';
import '../widgets/booking_detail_sheet.dart';
import '../widgets/section_card.dart';
import '../widgets/staff_picker_sheet.dart';
import '../widgets/calendar_panel.dart';
import '../services/local_auth_service.dart';
import 'subscribed_providers_screen.dart';
import 'pin_setup_screen.dart';
import 'service_type_screen.dart';
import 'provider_detail_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

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
  ServiceProvider? _selectedProvider; // null podczas ładowania danych
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

  // ─── widoczność slotów rezerwacji ─────────────────────────
  bool _showSlots = true;

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
      _selectedProvider = _providers.first;
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
      // do device calendar, więc tutaj tylko logujemy cicho
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

  /// Formatuje czas oczekiwania od [since] do teraz (np. "2h 15min", "45min")
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

  /// Import pliku .ics (web i desktop) — wyświetla dialog wyboru pliku.
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
        // Usuń poprzednio zaimportowane z .ics (zachowaj te z device kalendarza)
        _myBookings.removeWhere(
          (b) => b.importedFromDeviceCalendar && b.note == 'Imported from .ics',
        );
        _myBookings.addAll(imported);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Zaimportowano ${imported.length} eventów z kalendarza'),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      }
    } on IcsImportCancelledException {
      // użytkownik anulował — nic nie robimy
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

  /// Wywoływane po tapnięciu slotu — pokazuje duży bottom sheet rezerwacji.
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

    // ── Krok 1: wybór pracownika (jeśli jest więcej niż jeden) ──
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

    // ── Krok 2: wybór usługi ─────────────────────────────────
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
          forceConfirmation: isConfirmationSlot,
          staffName: chosenStaff);
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

    // Wyślij do API — czekamy na potwierdzenie
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
      return; // nie dodajemy lokalnie jeśli API odrzuciło
    }

    // API potwierdziło — aktualizujemy UI
    if (mounted) {
      setState(() {
        _myBookings.add(booking);
        _bookingsExpanded = true;
      });
    }
  }

  Future<void> _showCancelDialog(Booking booking) async {
    // Znajdź dostawcę powiązanego z rezerwacją
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
      // Wyślij DELETE do API — czekamy na potwierdzenie
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
        return; // nie usuwamy lokalnie jeśli API odrzuciło
      }

      // API potwierdziło — aktualizujemy UI
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
      builder: (ctx) => _AddBookingSheet(
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
                content:
                    Text('Zasubskrybowano: ${provider.name}'),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Przełącza między danymi Mock a prawdziwym API i przeładowuje dane.
  Future<void> _toggleDataSource() async {
    final switchToApi = useMockNotifier.value; // true = teraz mock → idziemy na API
    useMockNotifier.value = !switchToApi;

    setState(() {
      if (switchToApi) {
        _providerRepo = HttpProviderRepository();
        _bookingRepo = HttpBookingRepository();
      } else {
        _providerRepo = MockProviderRepository();
        _bookingRepo = MockBookingRepository();
      }
      // Czyścimy stan — zaraz przeładujemy z nowego źródła
      _providers.clear();
      _myBookings.clear();
      _selectedProvider = null;
      _deviceCalendarLoaded = false;
    });

    try {
      await _loadInitialData();
    } catch (e) {
      if (!mounted) return;
      // Coś poszło nie tak z API — wróć do mocków
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

  // ── Zabezpieczenia — PIN i biometria ─────────────────────────────────────

  Future<void> _openSecuritySettings() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _SecuritySettingsSheet(),
    );
  }

  // ─── build ───────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // Dane ładowane async — pokaż spinner zanim się załadują
    if (_selectedProvider == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final provider = _selectedProvider!;
    final user = AuthService.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: SvgPicture.asset('assets/images/Tugio.svg', height: 34),
        actions: [
          // Szukaj usług — przycisk w AppBar
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: FilledButton.icon(
              onPressed: _openServiceTypePicker,
              icon: const Icon(Icons.search, size: 18),
              label: const Text('Szukaj usług',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          // Na web: przycisk importu .ics jako backup gdy nie ma logowania
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
                    // ── Przełącznik skórki ──────────────────────
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
                    // ── Przełącznik Mock / API ──────────────────
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
              // ── Wybór usługodawcy (zwijany) ────────────────
              _CollapsibleSection(
                title: 'Moi usługodawcy',
                subtitle: provider.name,
                expanded: _providersExpanded,
                onToggle: () => setState(
                    () => _providersExpanded = !_providersExpanded),
                child: _buildProviderSelectorContent(),
              ),
              const SizedBox(height: 8),

              // ── Nadchodzące rezerwacje (zwijane) ───────────
              _buildUpcomingBookings(),

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
                  showSlots: _showSlots,
                  onToggleSlots: () =>
                      setState(() => _showSlots = !_showSlots),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ─── zawartość wyboru usługodawcy — grid z poziomym scrollem ───
  Widget _buildProviderSelectorContent() {
    // Karta usługodawcy
    Widget providerCard(ServiceProvider p) {
      final selected = p.id == _selectedProvider?.id;
      return InkWell(
        onTap: () => setState(() => _selectedProvider = p),
        onDoubleTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProviderDetailScreen(
              provider: p,
              userId: AuthService.instance.currentUser?.email,
            ),
          ),
        ),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 148,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              width: 1.4,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ProviderAvatar(serviceType: p.serviceType, radius: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
              Text(
                p.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      p.serviceType,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 10.5, color: Colors.grey.shade600),
                    ),
                  ),
                  if (p.rating != null) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.star,
                        size: 10, color: Colors.amber.shade600),
                    Text(
                      p.rating!.toStringAsFixed(1),
                      style: TextStyle(
                          fontSize: 10.5, color: Colors.grey.shade700),
                    ),
                  ],
                ],
              ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Przy ≤ 4 usługodawcach: zwykły Wrap (nie potrzeba scrolla)
    if (_providers.length <= 4) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _providers.map(providerCard).toList(),
      );
    }

    // Przy > 4: grid 2 wiersze × N kolumn, poziomy scroll
    // Dzielimy na 2 wiersze: górny = parzyste indeksy, dolny = nieparzyste
    const double rowH = 58;
    const double gap = 8;

    final topRow = <ServiceProvider>[];
    final bottomRow = <ServiceProvider>[];
    for (var i = 0; i < _providers.length; i++) {
      (i.isEven ? topRow : bottomRow).add(_providers[i]);
    }

    return SizedBox(
      height: rowH * 2 + gap,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: topRow
                  .map((p) => Padding(
                        padding: const EdgeInsets.only(right: gap),
                        child: SizedBox(height: rowH, child: providerCard(p)),
                      ))
                  .toList(),
            ),
            SizedBox(height: gap),
            Row(
              children: bottomRow
                  .map((p) => Padding(
                        padding: const EdgeInsets.only(right: gap),
                        child: SizedBox(height: rowH, child: providerCard(p)),
                      ))
                  .toList(),
            ),
          ],
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
      child: _CollapsibleSection(
        title: 'Nadchodzące rezerwacje',
        subtitle: '${upcoming.length} zaplanowanych',
        expanded: _bookingsExpanded,
        onToggle: () =>
            setState(() => _bookingsExpanded = !_bookingsExpanded),
        child: Column(
          children: upcoming.take(5).map((booking) {
            final isPending = booking.status == BookingStatus.pending;
            final isBooked = booking.status == BookingStatus.booked;
            final color = isPending
                ? Colors.orange
                : isBooked
                    ? Colors.green
                    : Colors.orange; // inquiry

            IconData statusIcon;
            String statusLabel;
            if (isPending) {
              statusIcon = Icons.hourglass_top_rounded;
              statusLabel = 'Oczekuje';
            } else if (isBooked) {
              statusIcon = Icons.check_circle_rounded;
              statusLabel = 'Potwierdzona';
            } else {
              statusIcon = Icons.help_outline_rounded;
              statusLabel = 'Inquiry';
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.07),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.3), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // ── ikona statusu ──────────────────────────
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: color.withOpacity(0.15),
                        child: Icon(statusIcon, color: color, size: 18),
                      ),
                      const SizedBox(width: 12),
                      // ── info ──────────────────────────────────
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.service,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                            if (booking.staffName != null) ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.person_rounded,
                                      size: 11, color: Colors.teal.shade600),
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
                                  fontSize: 12, color: Colors.grey.shade600),
                            ),
                            // Licznik czasu oczekiwania dla pending
                            if (isPending && booking.pendingSince != null) ...[
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Icon(Icons.schedule_rounded,
                                      size: 11, color: Colors.orange.shade600),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Czeka ${_formatWaitTime(booking.pendingSince!)}',
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
                      // ── status chip ───────────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // ── przycisk anulowania ───────────────────
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        color: Colors.red.shade400,
                        tooltip: 'Odwołaj',
                        onPressed: () => _showCancelDialog(booking),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  // ── symulacja potwierdzenia (tylko dla pending) ──
                  if (isPending) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green.shade700,
                          side: BorderSide(color: Colors.green.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.check_circle_outline, size: 16),
                        label: const Text('Symuluj potwierdzenie',
                            style: TextStyle(fontSize: 12)),
                        onPressed: () {
                          setState(() {
                            booking.status = BookingStatus.booked;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '✅ Rezerwacja "${booking.service}" potwierdzona!'),
                              backgroundColor: Colors.green.shade700,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Zwijana sekcja z jedną linią nagłówka i chevronem
// ─────────────────────────────────────────────────────────────────────────────
class _CollapsibleSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  const _CollapsibleSection({
    required this.title,
    required this.subtitle,
    required this.expanded,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
          // ── nagłówek (zawsze widoczny) ────────────────────
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                        if (!expanded)
                          Text(subtitle,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.keyboard_arrow_down,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45)),
                  ),
                ],
              ),
            ),
          ),
          // ── zawartość (zwijana) ───────────────────────────
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: child,
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

// ─── pomocniczy wiersz w dialogu ─────────────────────────────────────────────
class _DialogRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _DialogRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.indigo.shade400),
        const SizedBox(width: 8),
        Flexible(
          child: Text(text,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom sheet — wybór sposobu dodania rezerwacji
// ─────────────────────────────────────────────────────────────────────────────
class _AddBookingSheet extends StatelessWidget {
  final VoidCallback onExistingProvider;
  final VoidCallback onNewProvider;

  const _AddBookingSheet({
    required this.onExistingProvider,
    required this.onNewProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── uchwyt ──────────────────────────────────────────
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Dodaj rezerwację',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Wybierz usługodawcę',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 20),

          // ── opcja 1 — istniejący usługodawca ──────────────
          _OptionTile(
            icon: Icons.people_outline,
            color: Colors.indigo,
            title: 'Z moich usługodawców',
            subtitle: 'Wybierz z listy zasubskrybowanych',
            onTap: onExistingProvider,
          ),
          const SizedBox(height: 12),

          // ── opcja 2 — nowy usługodawca ────────────────────
          _OptionTile(
            icon: Icons.add_location_alt_outlined,
            color: Colors.teal,
            title: 'Znajdź nowego usługodawcę',
            subtitle: 'Szukaj w pobliżu na mapach Google',
            onTap: onNewProvider,
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25), width: 1),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.14),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black54)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color.withOpacity(0.6)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom sheet — Zabezpieczenia (PIN + biometria)
// ─────────────────────────────────────────────────────────────────────────────
class _SecuritySettingsSheet extends StatefulWidget {
  const _SecuritySettingsSheet();

  @override
  State<_SecuritySettingsSheet> createState() => _SecuritySettingsSheetState();
}

class _SecuritySettingsSheetState extends State<_SecuritySettingsSheet> {
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool _pinEnabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final canBio = await LocalAuthService.instance.canUseBiometrics();
    // canAndShouldUseBiometric: sprawdza preferencję I rejestrację sprzętową
    final bioOn = await LocalAuthService.instance.canAndShouldUseBiometric();
    final pinOn = await LocalAuthService.instance.isPinEnabled();

    // Auto-wyłącz preferencję jeśli biometria zniknęła z systemu
    if (!canBio && await LocalAuthService.instance.isBiometricEnabled()) {
      await LocalAuthService.instance.setBiometricEnabled(false);
    }

    if (!mounted) return;
    setState(() {
      _biometricAvailable = canBio;
      _biometricEnabled = bioOn;
      _pinEnabled = pinOn;
      _loading = false;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      // Przy włączaniu: wymagaj potwierdzenia biometrią zanim zapiszemy ustawienie.
      // Zapobiega aktywowaniu gdy telefon ma sprzęt, ale biometria nie jest zarejestrowana.
      final result = await LocalAuthService.instance.authenticateBiometric(
        reason: 'Potwierdź tożsamość aby włączyć odblokowanie biometryczne',
      );
      if (!mounted) return;
      if (result != BiometricResult.success) {
        // Pokaż komunikat — nie włączaj
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result == BiometricResult.notAvailable
                ? 'Biometria niedostępna lub niezarejestrowana w systemie'
                : 'Weryfikacja nieudana — biometria nie została włączona'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return; // nie zmieniaj stanu
      }
    }
    await LocalAuthService.instance.setBiometricEnabled(value);
    if (mounted) setState(() => _biometricEnabled = value);
  }

  Future<void> _setupOrChangePin() async {
    final mode = _pinEnabled ? PinSetupMode.change : PinSetupMode.setup;
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PinSetupScreen(mode: mode)),
    );
    if (ok == true && mounted) {
      setState(() => _pinEnabled = true);
    }
  }

  Future<void> _removePin() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => const PinSetupScreen(mode: PinSetupMode.remove)),
    );
    if (ok == true && mounted) {
      setState(() => _pinEnabled = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Zabezpieczenia',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface)),
            const SizedBox(height: 20),

            if (_loading)
              const Center(child: CircularProgressIndicator())
            else ...[
              // ── Biometria ──────────────────────────────────────
              if (_biometricAvailable) ...[
                _SettingsRow(
                  icon: Icons.fingerprint,
                  title: 'Odcisk palca',
                  subtitle: _biometricEnabled ? 'Włączony' : 'Wyłączony',
                  trailing: Switch(
                    value: _biometricEnabled,
                    onChanged: _toggleBiometric,
                    activeColor: Colors.indigo,
                  ),
                ),
                const Divider(height: 1),
              ],

              // ── PIN ────────────────────────────────────────────
              _SettingsRow(
                icon: Icons.pin_outlined,
                title: 'Kod PIN',
                subtitle: _pinEnabled ? 'Ustawiony' : 'Nie ustawiony',
                trailing: TextButton(
                  onPressed: _setupOrChangePin,
                  child: Text(_pinEnabled ? 'Zmień' : 'Ustaw',
                      style: const TextStyle(color: Colors.indigo)),
                ),
              ),
              if (_pinEnabled) ...[
                const Divider(height: 1),
                _SettingsRow(
                  icon: Icons.remove_circle_outline,
                  title: 'Usuń PIN',
                  subtitle: 'Wyłącz logowanie kodem',
                  trailing: TextButton(
                    onPressed: _removePin,
                    child: const Text('Usuń',
                        style: TextStyle(color: Colors.red)),
                  ),
                ),
              ],

              const SizedBox(height: 8),

              // ── Informacja ─────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        size: 16,
                        color: cs.onSurface.withOpacity(0.5)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'PIN i biometria blokują aplikację po ${5} minutach w tle. '
                        'Sesja wygasa po 30 dniach — wówczas wymagane pełne logowanie.',
                        style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withOpacity(0.55),
                            height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 22, color: Colors.indigo.shade400),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withOpacity(0.55))),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
