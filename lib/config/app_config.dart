/// Centralna konfiguracja aplikacji.
class AppConfig {
  AppConfig._();

  // ─────────────────────────────────────────────────────────────────────────
  // SALESFORCE — wklej swoje dane tutaj
  // ─────────────────────────────────────────────────────────────────────────

  /// URL instancji Salesforce (sandbox lub produkcja).
  /// Sandbox:    'https://twojafirma--sandbox.sandbox.my.salesforce.com'
  /// Produkcja:  'https://twojafirma.my.salesforce.com'
  static const String sfInstanceUrl =
      'https://reserity--gamlanexqa.sandbox.my.salesforce.com';

  /// Endpoint do wymiany tokenów.
  /// Sandbox → test.salesforce.com, Produkcja → login.salesforce.com
  static const String sfTokenUrl =
      'https://test.salesforce.com/services/oauth2/token';

  /// Wersja Salesforce API.
  static const String sfApiVersion = 'v59.0';

  /// Consumer Key z Connected App w Salesforce.
  static const String sfConsumerKey = '';

  /// Consumer Secret z Connected App w Salesforce.
  static const String sfConsumerSecret = '';

  /// Refresh Token uzyskany przy autoryzacji OAuth.
  static const String sfRefreshToken = '';

  // ─────────────────────────────────────────────────────────────────────────
  // STARE API (Mockoon) — zostawione dla trybu mock
  // ─────────────────────────────────────────────────────────────────────────

  /// Adres Mockoon do testów lokalnych (używany tylko gdy useMock=true).
  static const String mockApiBaseUrl = 'http://192.168.50.206:3000';

  /// Alias dla kompatybilności wstecznej — wskazuje na mockApiBaseUrl.
  static const String apiBaseUrl = mockApiBaseUrl;

  /// Timeout pojedynczego żądania HTTP.
  static const Duration requestTimeout = Duration(seconds: 15);

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ───────────────────────────────────────────────────────────────────�
  /// Bazowy endpoint REST API Salesforce, np.
  /// https://instance.my.salesforce.com/services/data/v59.0
  static String get sfApiBase => '$sfInstanceUrl/services/data/$sfApiVersion';
}
