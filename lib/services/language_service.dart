import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LanguageService {
  LanguageService._();
  static final LanguageService instance = LanguageService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _keyLanguage = 'app_language';
  static const _supported = {'pl', 'en'};

  final ValueNotifier<String> notifier = ValueNotifier<String>('pl');

  String get languageCode => notifier.value;
  bool get isEnglish => languageCode == 'en';

  Future<void> initialize() async {
    try {
      final saved = await _storage.read(key: _keyLanguage);
      if (saved != null && _supported.contains(saved)) {
        notifier.value = saved;
      }
    } catch (_) {
      // Keep the default language if secure storage is temporarily unavailable.
    }
  }

  Future<void> setLanguage(String languageCode) async {
    final next = _supported.contains(languageCode) ? languageCode : 'pl';
    notifier.value = next;
    try {
      await _storage.write(key: _keyLanguage, value: next);
    } catch (_) {
      // The UI should still switch even if persisting the preference fails.
    }
  }

  String text({required String pl, required String en}) => isEnglish ? en : pl;

  String serviceTypeLabel(String value, {String? id}) {
    final key = (id == null || id.isEmpty ? value : id).trim().toLowerCase();
    switch (key) {
      case 'haircut':
      case 'fryzjer':
        return text(pl: 'Fryzjer', en: 'Hairdresser');
      case 'psychology':
      case 'psycholog':
        return text(pl: 'Psycholog', en: 'Psychologist');
      case 'personal_trainer':
      case 'trener personalny':
        return text(pl: 'Trener personalny', en: 'Personal trainer');
      case 'dentist':
      case 'dentysta':
        return text(pl: 'Dentysta', en: 'Dentist');
      case 'cosmetician':
      case 'kosmetyczka':
        return text(pl: 'Kosmetyczka', en: 'Beautician');
      case 'doctor':
      case 'lekarz':
        return text(pl: 'Lekarz', en: 'Doctor');
      case 'physio':
      case 'fizjoterapeuta':
        return text(pl: 'Fizjoterapeuta', en: 'Physiotherapist');
      case 'dietitian':
      case 'dietetyk':
        return text(pl: 'Dietetyk', en: 'Dietitian');
      case 'massage':
      case 'masaż':
      case 'masaz':
        return text(pl: 'Masaż', en: 'Massage');
      case 'cardiologist':
      case 'kardiolog':
        return text(pl: 'Kardiolog', en: 'Cardiologist');
      case 'pediatrician':
      case 'pediatra':
        return text(pl: 'Pediatra', en: 'Pediatrician');
      case 'vet':
      case 'weterynarz':
        return text(pl: 'Weterynarz', en: 'Veterinarian');
      case 'tutor':
      case 'korepetycje':
        return text(pl: 'Korepetycje', en: 'Tutoring');
      case 'mechanic':
      case 'mechanik':
        return text(pl: 'Mechanik', en: 'Mechanic');
      case 'cleaning':
      case 'sprzątanie':
      case 'sprzatanie':
        return text(pl: 'Sprzątanie', en: 'Cleaning');
      case 'plumber':
      case 'hydraulik':
        return text(pl: 'Hydraulik', en: 'Plumber');
      case 'photographer':
      case 'fotograf':
        return text(pl: 'Fotograf', en: 'Photographer');
      case 'it_support':
      case 'wsparcie it':
        return text(pl: 'Wsparcie IT', en: 'IT support');
      case 'lawyer':
      case 'prawnik':
        return text(pl: 'Prawnik', en: 'Lawyer');
      case 'accountant':
      case 'księgowy':
      case 'ksiegowy':
        return text(pl: 'Księgowy', en: 'Accountant');
      case 'other':
      case 'inne':
        return text(pl: 'Inne', en: 'Other');
      default:
        return value;
    }
  }
}
