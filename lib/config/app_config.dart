/// Centralna konfiguracja aplikacji.
/// Zmień [apiBaseUrl] na adres IP swojego serwera/Mockoon.
class AppConfig {
  AppConfig._();

  /// Adres bazowy API. Ustaw IP swojego telefonu/komputera w sieci lokalnej.
  /// Przykład Mockoon lokalnie:  'http://10.0.2.2:3000'  (emulator Android)
  /// Przykład fizyczny telefon:  'http://192.168.1.100:3000'
  static const String apiBaseUrl = 'http://192.168.50.206:3000';

  /// Timeout pojedynczego żądania HTTP.
  static const Duration requestTimeout = Duration(seconds: 10);
}
