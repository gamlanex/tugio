import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'language_service.dart';

/// Serwis oceniania usługodawców.
/// Wysyła POST na endpoint API z oceną 1–5.
class RatingService {
  /// Wysyła ocenę gwiazdkową dla danego usługodawcy.
  ///
  /// [providerId] – identyfikator usługodawcy
  /// [userId]     – identyfikator zalogowanego użytkownika
  /// [rating]     – ocena od 1 do 5
  ///
  /// Rzuca [RatingException] jeśli serwer zwróci błąd.
  static Future<void> submitRating({
    required String providerId,
    required String userId,
    required int rating,
  }) async {
    assert(rating >= 1 && rating <= 5, LanguageService.instance.text(pl: 'Ocena musi być w zakresie 1-5', en: 'Rating must be between 1 and 5'));

    final uri = Uri.parse(
        '${AppConfig.apiBaseUrl}/providers/$providerId/ratings');

    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'userId': userId,
            'rating': rating,
            'timestamp': DateTime.now().toUtc().toIso8601String(),
          }),
        )
        .timeout(
          AppConfig.requestTimeout,
          onTimeout: () => throw RatingException(LanguageService.instance.text(pl: 'Przekroczono czas oczekiwania', en: 'Request timed out')),
        );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw RatingException(
        LanguageService.instance.text(pl: 'Błąd serwera (${response.statusCode}): ${response.body}', en: 'Server error (${response.statusCode}): ${response.body}'),
      );
    }
  }
}

class RatingException implements Exception {
  final String message;
  const RatingException(this.message);

  @override
  String toString() => 'RatingException: $message';
}
