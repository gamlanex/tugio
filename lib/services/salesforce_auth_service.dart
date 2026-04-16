// ─────────────────────────────────────────────────────────────────────────────
// SalesforceAuthService
//
// Obsługuje OAuth 2.0 Refresh Token Flow dla Salesforce.
//
// Jak działa:
//   1. Przy pierwszym zapytaniu wymienia refresh token → access token
//   2. Access token jest cache'owany w pamięci (ważny ~2h)
//   3. Gdy Salesforce zwróci 401 — automatycznie odświeża token i ponawia
//   4. Refresh token nie wygasa (chyba że admin go odwoła)
//
// Użycie:
//   final token = await SalesforceAuthService.instance.getAccessToken();
//   headers: {'Authorization': 'Bearer $token'}
//
//   // Lub gotowe headers:
//   final headers = await SalesforceAuthService.instance.authHeaders();
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class SalesforceAuthService {
  static final SalesforceAuthService instance = SalesforceAuthService._();
  SalesforceAuthService._();

  String? _accessToken;
  DateTime? _tokenExpiry;

  /// Zwraca ważny access token — odświeża jeśli wygasł lub brakuje.
  Future<String> getAccessToken() async {
    if (_isTokenValid()) return _accessToken!;
    await _refresh();
    return _accessToken!;
  }

  /// Gotowe nagłówki HTTP z Bearer tokenem i Content-Type.
  Future<Map<String, String>> authHeaders() async {
    final token = await getAccessToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// Wywołuje request z automatycznym retry po 401.
  /// Użyj zamiast http.get/post żeby nie martwić się o wygaśnięcie tokenu.
  Future<http.Response> get(Uri uri) async {
    final headers = await authHeaders();
    final response = await http.get(uri, headers: headers)
        .timeout(AppConfig.requestTimeout);

    if (response.statusCode == 401) {
      // Token wygasł w trakcie — wymuś odświeżenie i spróbuj raz jeszcze
      await _refresh();
      final retryHeaders = await authHeaders();
      return http.get(uri, headers: retryHeaders)
          .timeout(AppConfig.requestTimeout);
    }
    return response;
  }

  Future<http.Response> post(Uri uri, {Object? body}) async {
    final headers = await authHeaders();
    final response = await http
        .post(uri, headers: headers, body: body != null ? jsonEncode(body) : null)
        .timeout(AppConfig.requestTimeout);

    if (response.statusCode == 401) {
      await _refresh();
      final retryHeaders = await authHeaders();
      return http.post(uri, headers: retryHeaders,
              body: body != null ? jsonEncode(body) : null)
          .timeout(AppConfig.requestTimeout);
    }
    return response;
  }

  Future<http.Response> patch(Uri uri, {Object? body}) async {
    final headers = await authHeaders();
    final response = await http
        .patch(uri, headers: headers, body: body != null ? jsonEncode(body) : null)
        .timeout(AppConfig.requestTimeout);

    if (response.statusCode == 401) {
      await _refresh();
      final retryHeaders = await authHeaders();
      return http.patch(uri, headers: retryHeaders,
              body: body != null ? jsonEncode(body) : null)
          .timeout(AppConfig.requestTimeout);
    }
    return response;
  }

  Future<http.Response> delete(Uri uri) async {
    final headers = await authHeaders();
    final response = await http.delete(uri, headers: headers)
        .timeout(AppConfig.requestTimeout);

    if (response.statusCode == 401) {
      await _refresh();
      final retryHeaders = await authHeaders();
      return http.delete(uri, headers: retryHeaders)
          .timeout(AppConfig.requestTimeout);
    }
    return response;
  }

  // ── Internals ──────────────────────────────────────────────────────────────

  bool _isTokenValid() {
    if (_accessToken == null || _tokenExpiry == null) return false;
    // Odśwież 5 minut przed wygaśnięciem żeby uniknąć race condition
    return DateTime.now().isBefore(
      _tokenExpiry!.subtract(const Duration(minutes: 5)),
    );
  }

  Future<void> _refresh() async {
    final response = await http.post(
      Uri.parse(AppConfig.sfTokenUrl),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type':    'refresh_token',
        'client_id':     AppConfig.sfConsumerKey,
        'client_secret': AppConfig.sfConsumerSecret,
        'refresh_token': AppConfig.sfRefreshToken,
      },
    ).timeout(AppConfig.requestTimeout);

    if (response.statusCode != 200) {
      throw Exception(
        'Salesforce token refresh failed (${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    _accessToken = data['access_token'] as String;

    // Salesforce nie zwraca expires_in — standardowo access token żyje ~2h
    _tokenExpiry = DateTime.now().add(const Duration(hours: 2));
  }

  /// Wymuś odświeżenie tokenu (np. po błędzie 401 z zewnątrz).
  Future<void> forceRefresh() => _refresh();
}
