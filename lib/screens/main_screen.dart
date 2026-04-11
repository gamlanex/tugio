import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/provider.dart';
import '../models/booking.dart';
import '../models/calendar_view_mode.dart';
import '../data/mock_data.dart';
import '../services/auth_service.dart';
import '../services/device_calendar_service.dart';
import '../services/google_calendar_service.dart';
import '../services/ics_import_service.dart';
import '../utils/date_helpers.dart';
import '../widgets/section_card.dart';
import '../widgets/calendar_panel.dart';
import 'login_screen.dart';
import 'subscribed_providers_screen.dart';
import 'service_type_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // ─── lista usługodawców ───────────────────────────────────
  final List<ServiceProvider> _providers =
      mockProviders.where((p) => p.isSubscribed).toList();

  // ─── rezerwacje ───────────────────────────────────────────
  final List<Booking> _myBookings = [];

  // ─── aktualny wybór ───────────────────────────────────────
  late ServiceProvider _selectedProvider;
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

  // ─────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _selectedProvider = _providers.first;
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _myBookings.addAll(initialBookings(_selectedDate));
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadDeviceCalendarEvents();
    });
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
      final from =
          DateTime(_selectedDate.year, _selectedDate.month - 1, 1, 0, 0);
      final to =
          DateTime(_selectedDate.year, _selectedDate.month + 2, 0, 23, 59);

      List<Booking> imported;

      if (AuthService.instance.isSignedIn && !kIsWeb) {
        // Zalogowany na mobilnym: pobierz z OBU źródeł i połącz
        // Google Calendar API → eventy z zalogowanego konta (np. gmail)
        // Systemowy kalendarz    → eventy ze WSZYSTKICH kont na telefonie (w tym konta służbowe)
        final googleEvents =
            await GoogleCalendarService.instance.fetchEvents(from, to);
        List<Booking> deviceEvents = [];
        try {
          deviceEvents =
              await DeviceCalendarService.instance.fetchEvents(from, to);
        } on DeviceCalendarPermissionDeniedException {
          // brak zgody na systemowy — używamy tylko Google
        } catch (_) {}

        // Deduplikacja: jeśli event z systemu ma taki sam tytuł i czas start
        // co event z Google API — pomijamy duplikat
        final googleKeys = <String>{};
        for (final b in googleEvents) {
          googleKeys.add('${b.service}|${b.start.toIso8601String()}');
        }
        final uniqueDevice = deviceEvents.where((b) {
          final key = '${b.service}|${b.start.toIso8601String()}';
          return !googleKeys.contains(key);
        }).toList();

        imported = [...googleEvents, ...uniqueDevice];
      } else if (AuthService.instance.isSignedIn) {
        // Web: tylko Google Calendar API
        imported =
            await GoogleCalendarService.instance.fetchEvents(from, to);
      } else if (!kIsWeb) {
        // Niezalogowany na mobilnym: systemowy kalendarz
        imported =
            await DeviceCalendarService.instance.fetchEvents(from, to);
      } else {
        imported = [];
      }

      if (mounted) {
        setState(() {
          _myBookings.removeWhere((b) => b.importedFromDeviceCalendar);
          _myBookings.addAll(imported);
          _deviceCalendarLoaded = true;
        });
      }
    } on GoogleCalendarNotSignedInException {
      // Nie jesteśmy zalogowani — próbujemy device calendar (mobile)
      if (!kIsWeb) {
        try {
          final from =
              DateTime(_selectedDate.year, _selectedDate.month - 1, 1, 0, 0);
          final to =
              DateTime(_selectedDate.year, _selectedDate.month + 2, 0, 23, 59);
          final imported =
              await DeviceCalendarService.instance.fetchEvents(from, to);
          if (mounted) {
            setState(() {
              _myBookings.removeWhere((b) => b.importedFromDeviceCalendar);
              _myBookings.addAll(imported);
              _deviceCalendarLoaded = true;
            });
          }
        } on DeviceCalendarPermissionDeniedException {
          // brak zgody — nie pokazuj błędu, po prostu brak importu
        } catch (_) {}
      }
    } on DeviceCalendarPermissionDeniedException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Brak zgody na odczyt kalendarza urządzenia')),
        );
      }
    } catch (e) {
      // Pokaż błąd żeby łatwiej debugować
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

    // Czy tapnięty slot jest pomarańczowy (wymaga potwierdzenia)?
    final isConfirmationSlot =
        _selectedProvider.confirmationSlots.contains(time);

    final chosenService = await showModalBottomSheet<_ServiceOption>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BookingBottomSheet(
        provider: _selectedProvider,
        time: time,
        day: day,
      ),
    );

    if (chosenService != null && mounted) {
      _createBooking(time, day, chosenService,
          forceConfirmation: isConfirmationSlot);
    }
  }

  void _createBooking(String time, DateTime day, _ServiceOption service,
      {bool forceConfirmation = false}) {
    final parts = time.split(':');
    final start = DateTime(
      day.year, day.month, day.day,
      int.parse(parts[0]), int.parse(parts[1]),
    );

    // Pending jeśli: slot jest pomarańczowy LUB wybrana usługa wymaga potwierdzenia
    final isPending = forceConfirmation || service.requiresConfirmation;
    final now = DateTime.now();

    setState(() {
      _myBookings.add(
        Booking(
          id: '${_selectedProvider.id}_${start.millisecondsSinceEpoch}',
          service: service.name,
          start: start,
          durationMinutes: service.durationMinutes,
          status: isPending ? BookingStatus.pending : BookingStatus.booked,
          note: isPending ? 'Oczekuje na potwierdzenie' : null,
          pendingSince: isPending ? now : null,
        ),
      );
      _bookingsExpanded = true;
    });

  }

  Future<void> _showCancelDialog(Booking booking) async {
    // Eventy zaimportowane z kalendarza (Google Calendar / .ics) —
    // nie można ich odwoływać z poziomu aplikacji.
    if (booking.importedFromDeviceCalendar) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.event_outlined,
                  color: Colors.indigo.shade400, size: 22),
              const SizedBox(width: 10),
              const Flexible(child: Text('Event z kalendarza')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                booking.service,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Text(
                booking.timeText,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: Colors.amber.shade200, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: Colors.amber.shade800),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Ten event pochodzi z Twojego Google Calendar. '
                        'Aby go usunąć, edytuj go bezpośrednio w kalendarzu.',
                        style: TextStyle(fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            FilledButton(
              style:
                  FilledButton.styleFrom(backgroundColor: Colors.indigo),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Własna rezerwacja — normalny dialog anulowania
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
            child: const Text('Anuluj'),
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
          selectedProvider: _selectedProvider,
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

  Future<void> _handleSignOut() async {
    await AuthService.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  // ─── build ───────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
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
          PopupMenuButton<String>(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.indigo.shade100,
              backgroundImage: user?.photoUrl != null
                  ? NetworkImage(user!.photoUrl!)
                  : null,
              child: user?.photoUrl == null
                  ? Icon(Icons.person, size: 18, color: Colors.indigo.shade600)
                  : null,
            ),
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Text(
                  user?.displayName ?? user?.email ?? 'Zalogowany',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
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
            },
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
                subtitle: _selectedProvider.name,
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
                  freeSlots: _selectedProvider.slots,
                  confirmationSlots: _selectedProvider.confirmationSlots,
                  slotDurationMinutes: _selectedProvider.slotDurationMinutes,
                  onSlotTap: _handleSlotTap,
                  onTodayPressed: _handleTodayPressed,
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
    Widget providerCard(ServiceProvider provider) {
      final selected = provider.id == _selectedProvider.id;
      return InkWell(
        onTap: () => setState(() => _selectedProvider = provider),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 148,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? Colors.indigo.withOpacity(0.1)
                : const Color(0xFFF4F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? Colors.indigo : Colors.transparent,
              width: 1.4,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                provider.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.indigo : Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.category_outlined,
                      size: 10, color: Colors.grey.shade600),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      provider.serviceType,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 10.5, color: Colors.grey.shade600),
                    ),
                  ),
                  if (provider.rating != null) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.star,
                        size: 10, color: Colors.amber.shade600),
                    Text(
                      provider.rating!.toStringAsFixed(1),
                      style: TextStyle(
                          fontSize: 10.5, color: Colors.grey.shade700),
                    ),
                  ],
                ],
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
        color: Colors.white,
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
                    child: const Icon(Icons.keyboard_arrow_down,
                        color: Colors.black45),
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
// Bottom sheet rezerwacji — duży, prawie pełnoekranowy
// ─────────────────────────────────────────────────────────────────────────────
class _BookingBottomSheet extends StatefulWidget {
  final ServiceProvider provider;
  final String time;
  final DateTime day;

  const _BookingBottomSheet({
    required this.provider,
    required this.time,
    required this.day,
  });

  @override
  State<_BookingBottomSheet> createState() => _BookingBottomSheetState();
}

class _BookingBottomSheetState extends State<_BookingBottomSheet> {
  int _selectedServiceIndex = 0;

  // Mock usługi dla danego usługodawcy z opisami i cenami
  List<_ServiceOption> get _services {
    switch (widget.provider.serviceType) {
      case 'Fryzjer':
        return [
          _ServiceOption('Strzyżenie damskie', 'Mycie, strzyżenie i stylizacja włosów.', 120, 60),
          _ServiceOption('Strzyżenie męskie', 'Klasyczne lub nowoczesne strzyżenie.', 70, 30),
          _ServiceOption('Koloryzacja', 'Pełna koloryzacja lub odrosty z pielęgnacją.', 250, 120,
              requiresConfirmation: true),
          _ServiceOption('Modelowanie', 'Blow-dry, fale lub prostowanie.', 90, 45,
              requiresConfirmation: true),
        ];
      case 'Psycholog':
        return [
          _ServiceOption('Konsultacja indywidualna', 'Pierwsza wizyta, diagnoza i omówienie celów terapii.', 200, 60,
              requiresConfirmation: true),
          _ServiceOption('Sesja terapeutyczna', 'Regularna sesja terapii indywidualnej.', 180, 50),
          _ServiceOption('Terapia par', 'Sesja dla par — komunikacja i relacje.', 300, 90,
              requiresConfirmation: true),
        ];
      case 'Trener personalny':
        return [
          _ServiceOption('Trening personalny', 'Indywidualny plan ćwiczeń dostosowany do Twoich celów.', 150, 60),
          _ServiceOption('Analiza postawy', 'Ocena biomechaniki i korygowanie wad postawy.', 120, 45,
              requiresConfirmation: true),
          _ServiceOption('Konsultacja dietetyczna', 'Plan żywieniowy wspierający Twój trening.', 100, 40),
        ];
      default:
        return [
          _ServiceOption('Wizyta standardowa', 'Standardowa wizyta u ${widget.provider.name}.', 150, 60),
          _ServiceOption('Wizyta pilna', 'Szybka konsultacja w trybie pilnym.', 200, 30,
              requiresConfirmation: true),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = _services;
    final selected = services[_selectedServiceIndex];
    final endTime = _addMinutes(widget.time, selected.durationMinutes);

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      builder: (ctx, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF6F7FB),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // ── uchwyt ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),

              // ── treść scrollowana ────────────────────────────
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    // Nagłówek — usługodawca
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 12,
                            color: Colors.black.withOpacity(0.05),
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52, height: 52,
                            decoration: BoxDecoration(
                              color: Colors.indigo.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.store_rounded,
                                color: Colors.indigo, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.provider.name,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(height: 3),
                                Text(widget.provider.serviceType,
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600)),
                                if (widget.provider.rating != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.star_rounded,
                                          color: Colors.amber.shade600,
                                          size: 15),
                                      const SizedBox(width: 3),
                                      Text(
                                        widget.provider.rating!
                                            .toStringAsFixed(1),
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Termin
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.indigo.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.indigo.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              color: Colors.indigo, size: 18),
                          const SizedBox(width: 10),
                          Text(formatDate(widget.day),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(width: 20),
                          const Icon(Icons.access_time_rounded,
                              color: Colors.indigo, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            '${widget.time} – $endTime',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Nagłówek sekcji usług
                    const Text('Wybierz usługę',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),

                    // Lista usług
                    ...services.asMap().entries.map((entry) {
                      final i = entry.key;
                      final svc = entry.value;
                      final isSelected = i == _selectedServiceIndex;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedServiceIndex = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.indigo.withOpacity(0.07)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.indigo
                                  : Colors.black12,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Radio indicator
                              Container(
                                width: 20, height: 20,
                                margin: const EdgeInsets.only(top: 1),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.indigo
                                        : Colors.black26,
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? Center(
                                        child: Container(
                                          width: 10, height: 10,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.indigo,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(svc.name,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                                color: isSelected
                                                    ? Colors.indigo.shade800
                                                    : Colors.black87,
                                              )),
                                        ),
                                        Text(
                                          '${svc.price} zł',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                            color: isSelected
                                                ? Colors.indigo
                                                : Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(svc.description,
                                        style: TextStyle(
                                            fontSize: 12.5,
                                            color: Colors.grey.shade600,
                                            height: 1.4)),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(Icons.timer_outlined,
                                            size: 13,
                                            color: Colors.grey.shade500),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${svc.durationMinutes} min',
                                          style: TextStyle(
                                              fontSize: 11.5,
                                              color: Colors.grey.shade500),
                                        ),
                                        const SizedBox(width: 10),
                                        // Badge: natychmiastowa / wymaga potwierdzenia
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: svc.requiresConfirmation
                                                ? Colors.orange.withOpacity(0.12)
                                                : Colors.green.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                svc.requiresConfirmation
                                                    ? Icons.hourglass_top_rounded
                                                    : Icons.bolt_rounded,
                                                size: 11,
                                                color: svc.requiresConfirmation
                                                    ? Colors.orange.shade700
                                                    : Colors.green.shade700,
                                              ),
                                              const SizedBox(width: 3),
                                              Text(
                                                svc.requiresConfirmation
                                                    ? 'Wymaga potwierdzenia'
                                                    : 'Natychmiastowa',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: svc.requiresConfirmation
                                                      ? Colors.orange.shade700
                                                      : Colors.green.shade700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),

                    // Adres
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 15, color: Colors.grey.shade500),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(widget.provider.address,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 80), // miejsce na przycisk
                  ],
                ),
              ),

              // ── przyciski (przyklejone na dole) ─────────────
              Container(
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  // viewInsets = klawiatura, padding.bottom = pasek nawigacji
                  16 +
                      MediaQuery.of(context).viewInsets.bottom +
                      MediaQuery.of(context).padding.bottom,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 16,
                      color: Colors.black.withOpacity(0.07),
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Podsumowanie ceny
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(selected.name,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.black54),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              Text('${selected.price} zł',
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.indigo)),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.timer_outlined,
                                size: 14,
                                color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text('${selected.durationMinutes} min',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Przyciski obok siebie na pełnej szerokości
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: Colors.black26),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () => Navigator.pop(ctx, null),
                            child: const Text('Anuluj',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black54)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: selected.requiresConfirmation
                                  ? Colors.orange.shade700
                                  : Colors.indigo,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () => Navigator.pop(ctx, selected),
                            icon: Icon(
                              selected.requiresConfirmation
                                  ? Icons.send_rounded
                                  : Icons.check_rounded,
                              size: 18,
                            ),
                            label: Text(
                              selected.requiresConfirmation
                                  ? 'Wyślij prośbę'
                                  : 'Zarezerwuj',
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _addMinutes(String time, int minutes) {
    final parts = time.split(':');
    final dt = DateTime(0, 0, 0, int.parse(parts[0]), int.parse(parts[1]));
    final end = dt.add(Duration(minutes: minutes));
    return '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
  }
}

class _ServiceOption {
  final String name;
  final String description;
  final int price;
  final int durationMinutes;
  /// true = usługa wymaga potwierdzenia ze strony właściciela
  final bool requiresConfirmation;
  const _ServiceOption(
      this.name, this.description, this.price, this.durationMinutes,
      {this.requiresConfirmation = false});
}
