import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/provider.dart';
import '../models/booking.dart';
import '../repositories/booking_repository.dart';
import '../repositories/mock_booking_repository.dart';
import '../repositories/mock_provider_repository.dart';
import '../repositories/provider_repository.dart';
import '../repositories/http_booking_repository.dart';
import '../repositories/http_provider_repository.dart';
import '../services/auth_service.dart';
import '../utils/date_helpers.dart';
import '../main.dart' show themeModeNotifier, useMockNotifier, authStateNotifier, AuthState;
import 'main/main_screen.dart';
import 'subscribed_providers_screen.dart';
import 'service_type_screen.dart';
import 'upcoming_bookings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ProviderRepository _providerRepo = MockProviderRepository();
  BookingRepository _bookingRepo = MockBookingRepository();

  List<ServiceProvider> _providers = [];
  List<Booking> _bookings = [];
  bool _isLoading = true;
  ServiceProvider? _selectedProvider;

  @override
  void initState() {
    super.initState();
    _loadData();
    useMockNotifier.addListener(_onSourceToggled);
  }

  @override
  void dispose() {
    useMockNotifier.removeListener(_onSourceToggled);
    super.dispose();
  }

  void _onSourceToggled() {
    final isMock = useMockNotifier.value;
    setState(() {
      _providerRepo = isMock ? MockProviderRepository() : HttpProviderRepository();
      _bookingRepo  = isMock ? MockBookingRepository()  : HttpBookingRepository();
    });
    _loadData();
  }

  Future<void> _loadData({bool showSpinner = true}) async {
    if (!mounted) return;
    if (showSpinner) setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final providers = await _providerRepo.getSubscribed();
      final bookings  = await _bookingRepo.getInitial(today);
      if (!mounted) return;
      setState(() {
        _providers = List.from(providers);
        _bookings  = List.from(bookings);
        // Zachowaj wybranego dostawcę jeśli nadal jest na liście,
        // w przeciwnym razie wybierz pierwszego.
        final stillExists = _selectedProvider != null &&
            _providers.any((p) => p.id == _selectedProvider!.id);
        if (!stillExists) {
          _selectedProvider = _providers.isNotEmpty ? _providers.first : null;
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd ładowania danych: $e')),
      );
    }
  }

  // ── computed ────────────────────────────────────────────────
  List<Booking> get _upcoming => _bookings
      .where((b) {
        if (b.isAllDay || b.importedFromDeviceCalendar) return false;
        // Pokazuj rezerwacje które są dziś lub w przyszłości
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final bookingDay = DateTime(b.start.year, b.start.month, b.start.day);
        return !bookingDay.isBefore(today);
      })
      .toList()
    ..sort((a, b) => a.start.compareTo(b.start));



  // ── callbacki z sub-ekranów ─────────────────────────────────
  void _onProviderSelected(ServiceProvider p) {
    setState(() => _selectedProvider = p);
  }

  void _onBookingCreated(Booking b) {
    setState(() => _bookings.add(b));
  }

  void _onBookingCancelled(String id) {
    setState(() => _bookings.removeWhere((b) => b.id == id));
  }

  void _onProviderSubscribed(ServiceProvider p) {
    // Zapisz w repozytorium — dzięki statycznej liście MockProviderRepository
    // kolejne wywołanie _loadData() też zobaczy tego dostawcę.
    _providerRepo.subscribe(p);
    setState(() {
      if (!_providers.any((x) => x.id == p.id)) _providers.add(p);
      _selectedProvider = p;
    });
  }

  // ── nawigacja ────────────────────────────────────────────────
  void _openProviders() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubscribedProvidersScreen(
          providers: _providers,
          selectedProvider: _selectedProvider ?? (_providers.isNotEmpty ? _providers.first : null),
          selectedDate: DateTime.now(),
          bookings: _bookings,
          onProviderSelected: _onProviderSelected,
          onBookingCreated: _onBookingCreated,
          onBookingCancelled: _onBookingCancelled,
          onProviderSubscribed: _onProviderSubscribed,
        ),
      ),
    ).then((_) => _loadData(showSpinner: false));
  }

  void _openUpcomingBookings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UpcomingBookingsScreen(
          bookings: _upcoming,
          providers: _providers,
          onCancel: (id) => _onBookingCancelled(id),
        ),
      ),
    ).then((_) => _loadData(showSpinner: false));
  }

  void _openCalendar() {
    // Po powrocie z kalendarza przeładuj dane — tam mogły powstać nowe rezerwacje
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MainScreen(
          showBackButton: true,
          initialProviderId: _selectedProvider?.id,
        ),
      ),
    ).then((_) => _loadData(showSpinner: false));
  }

  // ── build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        // Pusty leading tej samej szerokości co actions (48px) — balansuje logo
        leading: const SizedBox(width: 48),
        title: SvgPicture.asset('assets/images/Tugio.svg', height: 44),
        actions: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeModeNotifier,
            builder: (_, themeMode, __) => ValueListenableBuilder<bool>(
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
                      child: Row(children: [
                        Icon(isDark
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined, size: 18),
                        const SizedBox(width: 8),
                        Text(isDark ? 'Jasna skórka' : 'Ciemna skórka'),
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'datasource',
                      child: Row(children: [
                        Icon(
                          isMock ? Icons.cloud_outlined : Icons.storage_rounded,
                          size: 18,
                          color: isMock
                              ? Colors.orange.shade700
                              : Colors.green.shade700,
                        ),
                        const SizedBox(width: 8),
                        Text(isMock ? 'Przełącz na API' : 'Przełącz na Mock'),
                      ]),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'signout',
                      child: Row(children: [
                        Icon(Icons.logout, size: 18),
                        SizedBox(width: 8),
                        Text('Wyloguj'),
                      ]),
                    ),
                  ],
                  onSelected: (v) {
                    if (v == 'signout') {
                      AuthService.instance
                          .signOut(useMock: useMockNotifier.value);
                      authStateNotifier.value = AuthState.unauthenticated;
                    }
                    if (v == 'theme') {
                      themeModeNotifier.value =
                          isDark ? ThemeMode.light : ThemeMode.dark;
                    }
                    if (v == 'datasource') {
                      useMockNotifier.value = !isMock;
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: RefreshIndicator(
                onRefresh: _loadData,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isLandscape = constraints.maxWidth > constraints.maxHeight;
                    final isDark = Theme.of(context).brightness == Brightness.dark;

                    // Dostępna przestrzeń po odjęciu paddingów (14 góra + 14 dół)
                    final availH = constraints.maxHeight - 28;
                    final availW = constraints.maxWidth - 28; // 14 lewo + 14 prawo

                    // Portrait:
                    //   topH    = górna połowa - gap/2       → kafelek t1 (Nadchodzące)
                    //   bottomH = dolna połowa - gap/2       → kafelki t0 i t2 obok siebie
                    // Landscape: wszystkie 3 obok siebie, stretch
                    final double gap = 10;
                    final double topH    = (availH - gap) * 0.50;
                    final double bottomH = (availH - gap) * 0.50;

                    _HomeTile makeTile(Color accent, Color bgLight, Color bgDark,
                        IconData ic, String ttl, VoidCallback tap,
                        Widget Function(double, bool) contentBuilder) {
                      return _HomeTile(
                        accentColor: accent,
                        bgColor: isDark ? bgDark : bgLight,
                        icon: ic,
                        title: ttl,
                        onTap: tap,
                        child: contentBuilder,
                      );
                    }

                    final tileUpcoming = makeTile(
                        const Color(0xFF00897B), const Color(0xFFE6F4F1), const Color(0xFF152220),
                        Icons.event_available_rounded, 'Nadchodzące\nrezerwacje',
                        _openUpcomingBookings, _upcomingContent);
                    final tileProviders = makeTile(
                        const Color(0xFF3949AB), const Color(0xFFEEF0FB), const Color(0xFF1A1C2E),
                        Icons.people_rounded, 'Moi usługodawcy',
                        _openProviders, _providersContent);
                    final tileCalendar = makeTile(
                        const Color(0xFF6A1B9A), const Color(0xFFF3E8FB), const Color(0xFF1E1828),
                        Icons.calendar_month_rounded, 'Kalendarz\nrezerwacji',
                        _openCalendar, _calendarContent);

                    if (isLandscape) {
                      // Landscape: 3 kolumny, wypełniają całą wysokość
                      return Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: tileUpcoming),
                            SizedBox(width: gap),
                            Expanded(child: tileProviders),
                            SizedBox(width: gap),
                            Expanded(child: tileCalendar),
                          ],
                        ),
                      );
                    }

                    // Portrait:
                    //   Górna połowa  → Nadchodzące rezerwacje (pełna szerokość)
                    //   Dolna połowa  → Usługodawcy | Kalendarz (pół na pół)
                    final halfW = (availW - gap) / 2;
                    return Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          SizedBox(
                            height: topH,
                            width: double.infinity,
                            child: tileUpcoming,
                          ),
                          SizedBox(height: gap),
                          SizedBox(
                            height: bottomH,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(width: halfW, child: tileProviders),
                                SizedBox(width: gap),
                                SizedBox(width: halfW, child: tileCalendar),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
    );
  }

  // ── zawartość kafelków ────────────────────────────────────────
  // Każda metoda przyjmuje availableH — wysokość obszaru content (z LayoutBuilder).
  // Elementy listy są dodawane dopóki się mieszczą; jeśli nie wszystkie — na dole "+ x więcej".

  // Stałe wysokości elementów (px) — empiryczne dla fontSize 10.5–12
  static const double _kHeader = 48.0;   // duża liczba (32) + etykieta (12) + odstęp
  static const double _kRow    = 18.0;   // jedna linijka listy (tekst + padding bottom 4)
  static const double _kMore   = 16.0;   // "+ x więcej / innych"
  static const double _kGap    =  8.0;   // SizedBox(height: 8) przed listą
  static const double _kLabel  = 14.0;   // "Wybrany:" label
  static const double _kSmGap  =  4.0;   // mały gap

  Widget _providersContent(double availableH, bool isDark) {
    final count = _providers.length;
    const accentColor = Color(0xFF3949AB);
    final labelClr = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final subClr   = isDark ? Colors.grey.shade400 : Colors.grey.shade500;
    final rowClr   = isDark ? Colors.grey.shade300 : Colors.grey.shade700;

    // Ile dostawców (poza wybranym) można pokazać w pozostałym miejscu?
    // Stałe: header + gap8 + "Wybrany:" label + gap2 + wybrany row
    double used = _kHeader + _kGap + _kLabel + _kSmGap + _kRow;
    // Pozostali dostawcy (bez wybranego)
    final others = _providers
        .where((p) => p.id != _selectedProvider?.id)
        .toList();
    int visibleOthers = 0;
    for (int i = 0; i < others.length; i++) {
      final needed = _kRow + (i == 0 ? _kGap : 0.0);
      final moreNeeded = (i < others.length - 1) ? _kMore : 0.0;
      if (used + needed + moreNeeded <= availableH) {
        used += needed;
        visibleOthers++;
      } else {
        break;
      }
    }
    final hiddenOthers = others.length - visibleOthers;

    final items = <Widget>[
      Text(
        '$count',
        style: const TextStyle(
            fontSize: 32, fontWeight: FontWeight.w800,
            color: accentColor, height: 1),
      ),
      Text(
        count == 1 ? 'usługodawca' : 'usługodawców',
        style: TextStyle(fontSize: 12, color: labelClr, fontWeight: FontWeight.w500),
      ),
      if (_selectedProvider != null) ...[
        const SizedBox(height: 8),
        Text('Wybrany:', style: TextStyle(fontSize: 10, color: subClr)),
        const SizedBox(height: 2),
        Row(children: [
          const Icon(Icons.person_pin_rounded, size: 12, color: accentColor),
          const SizedBox(width: 3),
          Expanded(
            child: Text(
              _selectedProvider!.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11.5,
                  fontWeight: FontWeight.w700, color: accentColor, height: 1.2),
            ),
          ),
        ]),
      ],
      if (visibleOthers > 0) ...[
        const SizedBox(height: 8),
        ...others.take(visibleOthers).map((p) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(children: [
            Icon(Icons.circle, size: 5, color: subClr),
            const SizedBox(width: 4),
            Expanded(
              child: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10.5, color: rowClr)),
            ),
          ]),
        )),
      ],
      if (hiddenOthers > 0) ...[
        const SizedBox(height: 4),
        Text('+ $hiddenOthers innych', style: TextStyle(fontSize: 10.5, color: subClr)),
      ],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: items,
    );
  }

  Widget _upcomingContent(double availableH, bool isDark) {
    final upcoming = _upcoming;
    final count = upcoming.length;
    const accentColor = Color(0xFF00897B);
    final labelClr = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final subClr   = isDark ? Colors.grey.shade400 : Colors.grey.shade500;
    final rowClr   = isDark ? Colors.grey.shade300 : Colors.grey.shade700;

    // Ile rezerwacji zmieści się po headerze?
    double used = _kHeader;
    int visible = 0;
    for (int i = 0; i < upcoming.length; i++) {
      final needed = _kRow + (i == 0 ? _kGap : 0.0);
      final moreNeeded = (i < upcoming.length - 1) ? _kMore : 0.0;
      if (used + needed + moreNeeded <= availableH) {
        used += needed;
        visible++;
      } else {
        break;
      }
    }
    final hidden = count - visible;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$count',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800,
                color: accentColor, height: 1)),
        Text(count == 1 ? 'rezerwacja' : 'rezerwacji',
            style: TextStyle(fontSize: 12, color: labelClr, fontWeight: FontWeight.w500)),
        if (visible > 0) ...[
          const SizedBox(height: 8),
          ...upcoming.take(visible).map((b) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(padding: const EdgeInsets.only(top: 4),
                  child: Icon(Icons.circle, size: 5, color: subClr)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${b.service}  ${shortDate(b.start)} ${b.timeText}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10.5, color: rowClr, height: 1.35),
                ),
              ),
            ]),
          )),
        ],
        if (hidden > 0) ...[
          const SizedBox(height: 4),
          Text('+ $hidden więcej', style: TextStyle(fontSize: 10.5, color: subClr)),
        ],
      ],
    );
  }

  Widget _calendarContent(double availableH, bool isDark) {
    final now = DateTime.now();
    const accentColor = Color(0xFF6A1B9A);
    final labelClr = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final subClr   = isDark ? Colors.grey.shade400 : Colors.grey.shade500;
    final rowClr   = isDark ? Colors.grey.shade300 : Colors.grey.shade700;
    final todayBookings = _upcoming
        .where((b) =>
            b.start.year == now.year &&
            b.start.month == now.month &&
            b.start.day == now.day)
        .toList();

    // Stałe: header (dzień + miesiąc) + gap8
    // Na dole zawsze jest "Dodaj rezerwację" — rezerwujemy na to miejsce
    const double kAddRow = 18.0;  // "Dodaj rezerwację" row
    const double kGapBeforeAdd = 6.0;
    double used = _kHeader + _kGap + kGapBeforeAdd + kAddRow;
    int visible = 0;
    for (int i = 0; i < todayBookings.length; i++) {
      final needed = _kRow;
      final moreNeeded = (i < todayBookings.length - 1) ? _kMore : 0.0;
      if (used + needed + moreNeeded <= availableH) {
        used += needed;
        visible++;
      } else {
        break;
      }
    }
    final hidden = todayBookings.length - visible;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('${now.day}',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800,
                color: accentColor, height: 1)),
        Text('${monthName(now.month)} ${now.year}',
            style: TextStyle(fontSize: 12, color: labelClr, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        if (todayBookings.isEmpty)
          Text('Brak wizyt\nna dziś',
              style: TextStyle(fontSize: 11, color: subClr, height: 1.4))
        else ...[
          ...todayBookings.take(visible).map((b) => Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(children: [
              Padding(padding: const EdgeInsets.only(top: 3),
                  child: Icon(Icons.circle, size: 5, color: subClr)),
              const SizedBox(width: 4),
              Expanded(
                child: Text('${b.timeText}  ${b.service}',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10.5,
                        color: rowClr, fontWeight: FontWeight.w500)),
              ),
            ]),
          )),
          if (hidden > 0) ...[
            const SizedBox(height: 4),
            Text('+ $hidden więcej', style: TextStyle(fontSize: 10.5, color: subClr)),
          ],
        ],
        const SizedBox(height: 6),
        Row(children: [
          Icon(Icons.add_circle_outline, size: 11, color: accentColor.withOpacity(0.7)),
          const SizedBox(width: 3),
          Text('Dodaj rezerwację',
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: labelClr)),
        ]),
      ],
    );
  }

}

// ─────────────────────────────────────────────────────────────────────────────
// Kafelek Home — wypełnia całą przydzieloną wysokość, przycina nadmiar
// ─────────────────────────────────────────────────────────────────────────────
class _HomeTile extends StatelessWidget {
  final Color accentColor;
  final Color bgColor;
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Widget Function(double availableHeight, bool isDark) child;

  const _HomeTile({
    required this.accentColor,
    required this.bgColor,
    required this.icon,
    required this.title,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accentColor.withOpacity(0.18), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          // SizedBox.expand wypełnia przestrzeń narzuconą przez rodzica (SizedBox w gridzie)
          child: SizedBox.expand(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ikona
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(icon, color: accentColor, size: 18),
                  ),
                  const SizedBox(height: 5),
                  // tytuł
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: accentColor.withOpacity(0.9),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 5),
                  // separator
                  Container(height: 1, color: accentColor.withOpacity(0.12)),
                  const SizedBox(height: 6),
                  // treść — Expanded z LayoutBuilder, żeby znać dostępną wysokość
                  Expanded(
                    child: LayoutBuilder(
                      builder: (ctx, cons) {
                        final isDark = Theme.of(ctx).brightness == Brightness.dark;
                        return child(cons.maxHeight, isDark);
                      },
                    ),
                  ),
                  // strzałka na dole
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Icon(Icons.arrow_forward_rounded,
                          color: accentColor, size: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
