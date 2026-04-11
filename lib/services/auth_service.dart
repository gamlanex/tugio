// ─────────────────────────────────────────────────────────────────────────────
// AuthService — Google Sign-In + Google Calendar scope
//
// SETUP — Android:
//   1. google-services.json w android/app/
//   2. SHA-1 zarejestrowany w Firebase Console
//   3. Google Sign-In włączony w Firebase Authentication
//
// SETUP — Web (aby Google Sign-In działał w przeglądarce):
//   1. Firebase Console → Authentication → Sign-in method → Google
//   2. Rozwiń "Web SDK configuration" → skopiuj "Web client ID"
//      (wygląda jak: 123456789-abc...xyz.apps.googleusercontent.com)
//   3. Wklej do web/index.html jako:
//      <meta name="google-signin-client_id" content="TWÓJ_WEB_CLIENT_ID">
//   4. Dodaj http://localhost do "Authorized JavaScript origins"
//      w Google Cloud Console → APIs & Services → Credentials → Web client
// ─────────────────────────────────────────────────────────────────────────────

import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final AuthService instance = AuthService._();
  AuthService._();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
      // Zakres do odczytu kalendarza Google
      'https://www.googleapis.com/auth/calendar.readonly',
    ],
  );

  GoogleSignInAccount? _currentUser;
  GoogleSignInAccount? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;

  /// Próbuje przywrócić poprzednią sesję (bez ekranu wyboru konta).
  Future<bool> tryAutoSignIn() async {
    try {
      final account = await _googleSignIn.signInSilently();
      _currentUser = account;
      return account != null;
    } catch (_) {
      return false;
    }
  }

  /// Otwiera picker Google Sign-In.
  Future<GoogleSignInAccount?> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      _currentUser = account;
      return account;
    } catch (e) {
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
  }

  /// Zwraca aktualny access token OAuth (do wywołań Google Calendar API).
  /// Automatycznie odświeża token jeśli wygasł.
  Future<String?> getAccessToken() async {
    try {
      // Upewnij się, że mamy aktywne konto
      GoogleSignInAccount? account = _currentUser;
      account ??= await _googleSignIn.signInSilently();
      if (account == null) return null;

      // Pobierz (i odśwież jeśli trzeba) tokeny
      final auth = await account.authentication;
      return auth.accessToken;
    } catch (_) {
      return null;
    }
  }
}
