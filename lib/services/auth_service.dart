// ─────────────────────────────────────────────────────────────────────────────
// AuthService — fasada logowania
//
// Łączy trzy warstwy:
//  • Google Sign-In     → dostęp do Google Calendar (OAuth access token)
//  • ApiAuthService     → JWT dla backendu Tugio (email/hasło lub Google)
//  • LocalAuthService   → odcisk palca i PIN (szybkie odblokowanie)
//
// Publiczny interfejs jest kompatybilny wstecz — istniejący kod (main_screen,
// calendar_sync_service, subscribed_providers_screen) działa bez zmian.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:google_sign_in/google_sign_in.dart';
import 'api_auth_service.dart';
import 'local_auth_service.dart';
import 'language_service.dart';
import '../models/app_user.dart';

export 'api_auth_service.dart' show AuthResult;
export 'local_auth_service.dart' show BiometricResult, PinResult;

class AuthService {
  static final AuthService instance = AuthService._();
  AuthService._();

  // Google Sign-In tylko do kalendarza
  final _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
      'https://www.googleapis.com/auth/calendar.readonly',
    ],
  );

  GoogleSignInAccount? _googleAccount;
  bool _isLocked = false;

  // ── Publiczny stan ─────────────────────────────────────────────────────────

  AppUser? get currentUser => ApiAuthService.instance.currentUser;
  bool get isSignedIn => currentUser != null;          // backward compat
  bool get isAuthenticated => currentUser != null;
  bool get isLocked => _isLocked;

  // ── Inicjalizacja przy starcie app ─────────────────────────────────────────

  Future<void> initialize() async {
    await ApiAuthService.instance.loadStoredSession();
    if (isAuthenticated) {
      // Cicha próba przywrócenia sesji Google (dla kalendarza)
      try {
        _googleAccount = await _googleSignIn.signInSilently();
      } catch (_) {}
    }
  }

  /// Sprawdza czy aplikacja powinna przejść do ekranu blokady.
  Future<bool> checkNeedsLocalAuth() async {
    if (!isAuthenticated) return false;
    return await LocalAuthService.instance.needsLocalAuth;
  }

  void lock() => _isLocked = true;
  void unlock() => _isLocked = false;

  // ── Logowanie ──────────────────────────────────────────────────────────────

  Future<AuthResult> signInWithEmail(String email, String password,
      {bool useMock = false}) async {
    final result =
        await ApiAuthService.instance.loginWithEmail(email, password, useMock);
    if (result.success) _isLocked = false;
    return result;
  }

  Future<AuthResult> register(String name, String email, String password,
      {bool useMock = false}) async {
    return await ApiAuthService.instance.register(name, email, password, useMock);
  }

  /// Logowanie Google: otwiera picker kont, wymienia token z backendem.
  Future<AuthResult> signInWithGoogle({bool useMock = false}) async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return AuthResult.error(LanguageService.instance.text(pl: 'Logowanie anulowane', en: 'Sign-in cancelled'));
      _googleAccount = account;

      String idToken = '';
      try {
        final auth = await account.authentication;
        idToken = auth.idToken ?? '';
      } catch (_) {}

      final result = await ApiAuthService.instance.loginWithGoogle(
        googleIdToken: idToken,
        email: account.email,
        name: account.displayName ?? account.email,
        photoUrl: account.photoUrl,
        useMock: useMock,
      );
      if (result.success) _isLocked = false;
      return result;
    } catch (e) {
      return AuthResult.error(LanguageService.instance.text(pl: 'Błąd Google Sign-In: $e', en: 'Google Sign-In error: $e'));
    }
  }

  // Backward compat — używany w login_screen.dart
  Future<bool> tryAutoSignIn({bool useMock = false}) async {
    await initialize();
    return isAuthenticated;
  }

  // Backward compat alias
  Future<AuthResult> signIn({bool useMock = false}) =>
      signInWithGoogle(useMock: useMock);

  // ── Odblokowanie (biometria / PIN) ─────────────────────────────────────────

  Future<BiometricResult> unlockWithBiometric() async {
    final result = await LocalAuthService.instance.authenticateBiometric();
    if (result == BiometricResult.success) _isLocked = false;
    return result;
  }

  Future<PinResult> unlockWithPin(String pin) async {
    final result = await LocalAuthService.instance.verifyPin(pin);
    if (result.isSuccess) _isLocked = false;
    return result;
  }

  // ── Wylogowanie ────────────────────────────────────────────────────────────

  Future<void> signOut({bool useMock = false}) async {
    await ApiAuthService.instance.logout(useMock);
    // Lokalny auth NIE jest kasowany przy wylogowaniu z konta —
    // usuwany jest dopiero gdy użytkownik jawnie usuwa PIN/biometrię
    // lub całkowicie usuwa aplikację.
    // Uzasadnienie: przy kolejnym logowaniu na to samo konto PIN powinien
    // nadal działać; jeśli zaloguje się inny użytkownik — clearLocalAuth().
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    _googleAccount = null;
    _isLocked = false;
  }

  /// Wywołaj gdy zaloguje się INNY użytkownik — czyści PIN/biometrię.
  Future<void> clearLocalAuth() async {
    await LocalAuthService.instance.clearAll();
  }

  // ── Google Calendar (dostęp do access token) ───────────────────────────────

  /// Używane przez GoogleCalendarService.
  Future<String?> getAccessToken() async {
    try {
      GoogleSignInAccount? account = _googleAccount;
      account ??= await _googleSignIn.signInSilently();
      if (account == null) return null;
      _googleAccount = account;
      final auth = await account.authentication;
      return auth.accessToken;
    } catch (_) {
      return null;
    }
  }
}
