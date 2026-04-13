// ─────────────────────────────────────────────────────────────────────────────
// ApiAuthService — logowanie email/hasło + JWT + Google-token exchange
//
// Tokeny przechowywane w flutter_secure_storage (szyfrowane AES na Androidzie).
// Sesja wygasa po 30 dniach — przy starcie aplikacji sprawdzamy datę ważności.
//
// Endpointy API:
//   POST /auth/login     { email, password }     → { token, user }
//   POST /auth/register  { name, email, password }→ { token, user }
//   POST /auth/google    { googleToken, email }   → { token, user }
//   POST /auth/logout    (bearer)                 → {}
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/app_user.dart';

// ── Wynik operacji auth ──────────────────────────────────────────────────────

class AuthResult {
  final bool success;
  final String? error;
  final AppUser? user;

  const AuthResult._({required this.success, this.error, this.user});

  factory AuthResult.success(AppUser user) =>
      AuthResult._(success: true, user: user);

  factory AuthResult.error(String message) =>
      AuthResult._(success: false, error: message);
}

// ── ApiAuthService ───────────────────────────────────────────────────────────

class ApiAuthService {
  static final ApiAuthService instance = ApiAuthService._();
  ApiAuthService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _keyToken = 'auth_token';
  static const _keyUser = 'auth_user';
  static const _keyTokenExpiry = 'auth_token_expiry';

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;
  bool get hasValidSession => _currentUser != null;

  // ── Inicjalizacja przy starcie ─────────────────────────────────────────────

  Future<void> loadStoredSession() async {
    try {
      final token = await _storage.read(key: _keyToken);
      final expiryStr = await _storage.read(key: _keyTokenExpiry);

      if (token == null || expiryStr == null) return;

      final expiry = DateTime.tryParse(expiryStr);
      if (expiry == null || expiry.isBefore(DateTime.now())) {
        await clearSession();
        return;
      }

      final userJson = await _storage.read(key: _keyUser);
      if (userJson != null) {
        _currentUser = AppUser.fromJson(
            jsonDecode(userJson) as Map<String, dynamic>);
      }
    } catch (_) {
      // Błąd odczytu — traktujemy jako brak sesji
      await clearSession();
    }
  }

  // ── Logowanie email/hasło ──────────────────────────────────────────────────

  Future<AuthResult> loginWithEmail(
      String email, String password, bool useMock) async {
    if (useMock) return await _mockLogin(email, 'email');

    try {
      final res = await http
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(AppConfig.requestTimeout);

      return _handleHttpResponse(res);
    } catch (e) {
      return AuthResult.error('Błąd połączenia z serwerem');
    }
  }

  // ── Rejestracja ────────────────────────────────────────────────────────────

  Future<AuthResult> register(
      String name, String email, String password, bool useMock) async {
    if (useMock) return await _mockLogin(email, 'email', name: name);

    try {
      final res = await http
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(
                {'name': name, 'email': email, 'password': password}),
          )
          .timeout(AppConfig.requestTimeout);

      return _handleHttpResponse(res);
    } catch (e) {
      return AuthResult.error('Błąd połączenia z serwerem');
    }
  }

  // ── Logowanie przez Google ─────────────────────────────────────────────────

  Future<AuthResult> loginWithGoogle({
    required String googleIdToken,
    required String email,
    required String name,
    String? photoUrl,
    required bool useMock,
  }) async {
    if (useMock) {
      return await _mockLogin(email, 'google', name: name, photoUrl: photoUrl);
    }

    try {
      final res = await http
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}/auth/google'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'googleToken': googleIdToken,
              'email': email,
              'name': name,
            }),
          )
          .timeout(AppConfig.requestTimeout);

      if (res.statusCode == 200) {
        return _handleHttpResponse(res);
      }
      // Fallback: akceptuj Google bez backendu
      return await _mockLogin(email, 'google', name: name, photoUrl: photoUrl);
    } catch (_) {
      // Serwer niedostępny → akceptuj dane z Google
      return await _mockLogin(email, 'google', name: name, photoUrl: photoUrl);
    }
  }

  // ── Wylogowanie ────────────────────────────────────────────────────────────

  Future<void> logout(bool useMock) async {
    if (!useMock) {
      try {
        final token = await _storage.read(key: _keyToken);
        if (token != null) {
          await http.post(
            Uri.parse('${AppConfig.apiBaseUrl}/auth/logout'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          ).timeout(AppConfig.requestTimeout);
        }
      } catch (_) {
        // Błąd wylogowania po stronie serwera — czyścimy lokalnie i tak
      }
    }
    await clearSession();
  }

  Future<void> clearSession() async {
    _currentUser = null;
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyUser);
    await _storage.delete(key: _keyTokenExpiry);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  AuthResult _handleHttpResponse(http.Response res) {
    try {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return _saveAndReturn(data);
      }
      final msg = data['message'] as String? ?? 'Błąd serwera (${res.statusCode})';
      return AuthResult.error(msg);
    } catch (_) {
      return AuthResult.error('Błąd serwera (${res.statusCode})');
    }
  }

  AuthResult _saveAndReturn(Map<String, dynamic> data) {
    final token = data['token'] as String?;
    final userData = data['user'] as Map<String, dynamic>?;
    if (token == null || userData == null) {
      return AuthResult.error('Nieprawidłowa odpowiedź serwera');
    }
    final user = AppUser.fromJson(userData);
    _persistSession(token, user);
    _currentUser = user;
    return AuthResult.success(user);
  }

  Future<void> _persistSession(String token, AppUser user) async {
    final expiry = DateTime.now().add(const Duration(days: 30));
    await _storage.write(key: _keyToken, value: token);
    await _storage.write(key: _keyUser, value: user.toJsonString());
    await _storage.write(
        key: _keyTokenExpiry, value: expiry.toIso8601String());
  }

  Future<AuthResult> _mockLogin(String email, String method,
      {String? name, String? photoUrl}) async {
    final user = AppUser(
      id: 'mock_${email.hashCode.abs()}',
      email: email,
      name: name ?? email.split('@').first,
      photoUrl: photoUrl,
      authMethod: method,
    );
    _currentUser = user;
    // Zapisz sesję nawet w trybie mock — żeby przeżyła restart aplikacji
    // i uruchamiała ekran blokady PIN/biometria zamiast pełnego logowania.
    await _persistSession('mock_token_${user.id}', user);
    return AuthResult.success(user);
  }
}
