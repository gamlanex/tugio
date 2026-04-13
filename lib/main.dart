import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/lock_screen.dart';
import 'screens/main_screen.dart';
import 'services/auth_service.dart';
import 'utils/app_theme.dart';

// ── Globalny stan motywu ─────────────────────────────────────────────────────
final themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

// ── Globalny stan danych: true = Mock, false = API ───────────────────────────
final useMockNotifier = ValueNotifier<bool>(true);

// ── Stan autoryzacji (steruje AuthGate) ─────────────────────────────────────
enum AuthState { unknown, unauthenticated, locked, authenticated }

final authStateNotifier = ValueNotifier<AuthState>(AuthState.unknown);

// ── Start aplikacji ──────────────────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Sprawdź czy jest zapisana sesja (JWT w secure storage)
  await AuthService.instance.initialize();

  // Wyznacz stan startowy
  final auth = AuthService.instance;
  if (!auth.isAuthenticated) {
    authStateNotifier.value = AuthState.unauthenticated;
  } else {
    final needsLocal = await auth.checkNeedsLocalAuth();
    if (needsLocal) {
      auth.lock();
      authStateNotifier.value = AuthState.locked;
    } else {
      authStateNotifier.value = AuthState.authenticated;
    }
  }

  runApp(const TugioApp());
}

// ── Główna aplikacja ─────────────────────────────────────────────────────────
class TugioApp extends StatelessWidget {
  const TugioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (_, mode, __) => MaterialApp(
        title: 'Tugio',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: mode,
        home: const AuthGate(),
      ),
    );
  }
}

// ── AuthGate — router stanu autoryzacji ─────────────────────────────────────
//
// Nasłuchuje authStateNotifier i renderuje odpowiedni ekran.
// Obsługuje też auto-blokadę po powrocie z tła (WidgetsBindingObserver).
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  DateTime? _pausedAt;

  // Czas w tle po którym aplikacja zostaje zablokowana (jeśli PIN/biometria)
  static const _lockTimeout = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ── Cykl życia aplikacji — auto-blokada ─────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_pausedAt != null &&
          DateTime.now().difference(_pausedAt!) >= _lockTimeout &&
          AuthService.instance.isAuthenticated) {
        final needsLocal =
            await AuthService.instance.checkNeedsLocalAuth();
        if (needsLocal && mounted) {
          AuthService.instance.lock();
          authStateNotifier.value = AuthState.locked;
        }
      }
      _pausedAt = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AuthState>(
      valueListenable: authStateNotifier,
      builder: (_, state, __) {
        switch (state) {
          case AuthState.unknown:
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          case AuthState.unauthenticated:
            return const LoginScreen();
          case AuthState.locked:
            return const LockScreen();
          case AuthState.authenticated:
            return const MainScreen();
        }
      },
    );
  }
}
