// ─────────────────────────────────────────────────────────────────────────────
// AppStrings — centralne tłumaczenia PL / EN
//
// Użycie w widgetach:
//   final s = AppStrings.of(context);
//   Text(s.login)
//
// Przełączanie języka:
//   languageNotifier.value = 'en';  // lub 'pl'
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

// Globalny notifier — importuj z main.dart
// Tutaj tylko typedef żeby uniknąć circular import
typedef LanguageNotifier = ValueNotifier<String>;

abstract class AppStrings {
  /// Zwraca tłumaczenia dla aktualnego języka z kontekstu.
  static AppStrings of(BuildContext context) {
    final notifier = _LanguageNotifierScope.of(context);
    return notifier == 'en' ? EnStrings() : PlStrings();
  }

  // ── Ogólne ────────────────────────────────────────────────────────────────
  String get appName;
  String get cancel;
  String get leave;
  String get close;
  String get save;
  String get retry;
  String get ok;
  String get yes;
  String get no;
  String get or;
  String get loading;
  String get error;
  String get minutes; // "min"
  String get aFewMoments; // "chwilę" / "a moment"
  String get currencySuffix; // "zł" / "PLN"

  // ── Nawigacja / toolbar ───────────────────────────────────────────────────
  String get today;
  String get day;
  String get week;
  String get month;
  String get allDay;

  // ── Statusy rezerwacji ────────────────────────────────────────────────────
  String get statusBooked;
  String get statusPending;
  String get statusInquiry;
  String get statusAwaitingConfirmation;
  String get statusUnknown;

  // ── Logowanie ─────────────────────────────────────────────────────────────
  String get loginTagline;
  String get loginDescription;
  String get emailLabel;
  String get passwordLabel;
  String get emailRequired;
  String get emailInvalid;
  String get passwordRequired;
  String get loginButton;
  String get googleLoginButton;
  String get demoModeButton;
  String get webGoogleSigninInfo;
  String get noAccountText;
  String get registerLink;

  // ── Rejestracja ───────────────────────────────────────────────────────────
  String get createAccountTitle;
  String get fullNameLabel;
  String get fullNameRequired;
  String get passwordMinLength;
  String get confirmPasswordLabel;
  String get passwordMismatch;
  String get createAccountButton;
  String get alreadyHaveAccount;
  String get signinLink;

  // ── PIN / blokada ─────────────────────────────────────────────────────────
  String get pinSetupTitle;
  String get pinChangeTitle;
  String get pinRemoveTitle;
  String get pinVerifyRemoveInstruction;
  String get pinVerifyInstruction;
  String get pinEnterInstruction;
  String get pinConfirmInstruction;
  String get pinTooManyAttempts;
  String get pinMismatch;
  String get pinSetSuccess;
  String get pinRemovedSuccess;
  String pinIncorrectAttempts(int remaining);
  String get biometricLockedOut;
  String get biometricUnavailableLock;
  String get unlockBiometricButton;
  String get unlockApp;
  String get signinDifferently;
  String pinIncorrectRemaining(int remaining);

  // ── Zabezpieczenia ────────────────────────────────────────────────────────
  String get securityTitle;
  String get biometricLabel;
  String get biometricEnabled;
  String get biometricDisabled;
  String get pinLabel;
  String get pinNotSet;
  String get pinSet;
  String get pinSetupButton;
  String get pinChangeButton;
  String get removePinLabel;
  String get removePinSubtitle;
  String get removePinButton;
  String get biometricConfirmationPrompt;
  String get biometricUnavailable;
  String get biometricVerificationFailed;
  String get securityInfo;

  // ── Język ─────────────────────────────────────────────────────────────────
  String get languageLabel;
  String get languagePolish;
  String get languageEnglish;

  // ── Motyw ─────────────────────────────────────────────────────────────────
  String get lightMode;
  String get darkMode;
  String get switchToApi;
  String get switchToMock;
  String get currentLocalData;
  String get currentApi;
  String get securitySettings;
  String get logout;
  String get importCalendarTooltip;
  String get refreshCalendarTooltip;

  // ── Błędy / komunikaty ────────────────────────────────────────────────────
  String get dataLoadingError;
  String get deviceCalendarPermissionDenied;
  String calendarSyncError(String e);
  String get icsFileNoEvents;
  String icsImportSuccess(int count);
  String icsImportError(String e);
  String apiConnectionError(String e);
  String bookingCreationError(String e);
  String bookingCancellationError(String e);
  String get bookingCancelled;
  String bookingCancelledWithReason(String reason);
  String providerSubscribed(String name);
  String bookingConfirmedSimulated(String service);

  // ── Rezerwacje ────────────────────────────────────────────────────────────
  String get cancelBookingTitle;
  String get cancelBookingReasonLabel;
  String get upcomingBookingsTitle;
  String get noUpcomingBookings;
  String get waitingSince;
  String waitTime(String time);
  String get simulateConfirmation;
  String get cancelBookingTooltip;
  String get addBookingTitle;
  String get chooseProviderSubtitle;
  String get existingProviderTitle;
  String get existingProviderSubtitle;
  String get newProviderTitle;
  String get newProviderSubtitle;
  String get bookButton;
  String get sendRequestButton;
  String get requiresConfirmation;
  String get instantBooking;
  String get chooseServiceLabel;

  // ── Usługodawcy ───────────────────────────────────────────────────────────
  String get myProvidersTitle;
  String get addProvidersTooltip;
  String get noProviders;
  String get findAddProviderButton;
  String get myBookingsLabel;
  String freeSlotsForDate(String date);
  String get providerDetailsTip;
  String get fullDetailsButton;
  String get callButton;
  String get mapButton;
  String get slotAlreadyBooked;
  String get cancelBookingConfirmButton;

  // ── Ekran główny ──────────────────────────────────────────────────────────
  String get upcomingBookingsTileTitle;
  String get myProvidersTileTitle;
  String get bookingCalendarTileTitle;
  String get noUpcomingBookingsTile;
  String get noBookingsToday;
  String get addBookingLink;
  String get loggedInDefault;
  String get selectedProviderLabel;
  String providerCountLabel(int count); // "usługodawca" / "usługodawców"
  String bookingCountLabel(int count);  // "rezerwacja" / "rezerwacji"
  String moreOthers(int count);         // "+ 3 innych"
  String moreItems(int count);          // "+ 2 więcej"
  String dataLoadError(String e);

  // ── Szczegóły usługodawcy ─────────────────────────────────────────────────
  String get aboutProviderTitle;
  String get contactAddressTitle;
  String get openingHoursTitle;
  String get userRatingTitle;
  String get showCalendarButton;
  String get openInMapsButton;
  String get websiteButton;
  String get googleCalendarEventNote;
  String get ratingPoor;
  String get ratingFair;
  String get ratingGood;
  String get ratingVeryGood;
  String get ratingExcellent;
  String get ratingTapToRate;
  String get ratingThanks;
  String ratingError(String msg);
  String get ratingErrorSendFailed;

  // ── Mapa / wyszukiwanie ───────────────────────────────────────────────────
  String get searchResultsLoading;
  String searchResultsCount(int count);
  String get gpsFixedLabel;
  String get gpsNotFixedLabel;
  String get noResults;
  String get searchTooltip;
  String get myLocationTooltip;
  String get inviteDialogTitle;
  String get inviteMessage;
  String get openSmsButton;
  String get smsOpenFailed;
  String get providerNotInTugio;
  String get inviteButton;
  String get noPhoneLabel;

  // ── Wybór kategorii ───────────────────────────────────────────────────────
  String get chooseServiceTitle;
  String get whatAreYouLookingFor;
  String get chooseCategorySubtitle;
  String get categoriesLoadError;

  // ── Kalendarz ─────────────────────────────────────────────────────────────
  String get sendRequestHint;
  String get bookHint;
  String get googleCalendarSource;
  String get importInfo;

  // ── Filtr kalendarza ──────────────────────────────────────────────────────
  String get calendarFilterAllTooltip;
  String get calendarFilterNoSlotsTooltip;
  String get calendarFilterOnlyMineTooltip;

  // ── Sekcje ekranu rezerwacji ──────────────────────────────────────────────
  String get servicesTitle;
  String get myCalendarTitle;
  String inquiryCreated(String service, String time);
  String get cancelBookingReasonPlaceholder;

  // ── Oczekujące rezerwacje ─────────────────────────────────────────────────
  String get pendingBookingsTitle;
  String get noPendingBookings;
  String get confirmBookingButton;
  String bookingConfirmedMessage(String service);
  String get pendingStatusLabel;
  String waitMinutes(int minutes);
  String waitHoursMinutes(int hours, int minutes);

  // ── Wybór pracownika ──────────────────────────────────────────────────────
  String selectPersonTitle(String time);

  // ── Nazwy usług (mock) ────────────────────────────────────────────────────
  String get svcHaircutWomen;
  String get svcHaircutWomenDesc;
  String get svcHaircutMen;
  String get svcHaircutMenDesc;
  String get svcHairColoring;
  String get svcHairColoringDesc;
  String get svcHairStyling;
  String get svcHairStylingDesc;
  String get svcPsychologyConsultation;
  String get svcPsychologyConsultationDesc;
  String get svcTherapySession;
  String get svcTherapySessionDesc;
  String get svcCouplesTherapy;
  String get svcCouplesTherapyDesc;
  String get svcPersonalTraining;
  String get svcPersonalTrainingDesc;
  String get svcPostureAnalysis;
  String get svcPostureAnalysisDesc;
  String get svcNutritionConsultation;
  String get svcNutritionConsultationDesc;
  String get svcStandardVisit;
  String svcStandardVisitDesc(String providerName);
  String get svcUrgentVisit;
  String get svcUrgentVisitDesc;
}

// ─────────────────────────────────────────────────────────────────────────────
// POLSKI
// ─────────────────────────────────────────────────────────────────────────────
class PlStrings extends AppStrings {
  @override String get appName => 'Tugio';
  @override String get cancel => 'Anuluj';
  @override String get leave => 'Zostaw';
  @override String get close => 'Zamknij';
  @override String get save => 'Zapisz';
  @override String get retry => 'Spróbuj ponownie';
  @override String get ok => 'OK';
  @override String get yes => 'Tak';
  @override String get no => 'Nie';
  @override String get or => 'lub';
  @override String get loading => 'Ładowanie...';
  @override String get error => 'Błąd';
  @override String get minutes => 'min';
  @override String get aFewMoments => 'chwilę';
  @override String get currencySuffix => 'zł';

  @override String get today => 'Dziś';
  @override String get day => 'Dzień';
  @override String get week => 'Tydz.';
  @override String get month => 'Mies.';
  @override String get allDay => 'Cały dzień';

  @override String get statusBooked => 'Potwierdzona';
  @override String get statusPending => 'Oczekuje';
  @override String get statusInquiry => 'Zapytanie';
  @override String get statusAwaitingConfirmation => 'Oczekuje na potwierdzenie';
  @override String get statusUnknown => 'Nieznany';

  @override String get loginTagline => 'Zarezerwuj wizytę\nw kilka sekund';
  @override String get loginDescription => 'Zarządzaj rezerwacjami w jednym miejscu';
  @override String get emailLabel => 'Email';
  @override String get passwordLabel => 'Hasło';
  @override String get emailRequired => 'Podaj email';
  @override String get emailInvalid => 'Nieprawidłowy email';
  @override String get passwordRequired => 'Podaj hasło';
  @override String get loginButton => 'Zaloguj się';
  @override String get googleLoginButton => 'Zaloguj się przez Google';
  @override String get demoModeButton => 'Wejdź w trybie demo';
  @override String get webGoogleSigninInfo => 'Google Sign-In działa na urządzeniu mobilnym lub emulatorze.';
  @override String get noAccountText => 'Nie masz konta?';
  @override String get registerLink => 'Zarejestruj się';

  @override String get createAccountTitle => 'Utwórz konto';
  @override String get fullNameLabel => 'Imię i nazwisko';
  @override String get fullNameRequired => 'Podaj imię';
  @override String get passwordMinLength => 'Minimum 8 znaków';
  @override String get confirmPasswordLabel => 'Potwierdź hasło';
  @override String get passwordMismatch => 'Hasła nie są identyczne';
  @override String get createAccountButton => 'Utwórz konto';
  @override String get alreadyHaveAccount => 'Masz już konto?';
  @override String get signinLink => 'Zaloguj się';

  @override String get pinSetupTitle => 'Ustaw PIN';
  @override String get pinChangeTitle => 'Zmień PIN';
  @override String get pinRemoveTitle => 'Usuń PIN';
  @override String get pinVerifyRemoveInstruction => 'Wpisz aktualny PIN, aby go usunąć';
  @override String get pinVerifyInstruction => 'Wpisz aktualny PIN';
  @override String get pinEnterInstruction => 'Wpisz nowy PIN (4 cyfry)';
  @override String get pinConfirmInstruction => 'Potwierdź nowy PIN';
  @override String get pinTooManyAttempts => 'Zbyt wiele prób. Zaloguj się ponownie.';
  @override String get pinMismatch => 'Piny się różnią — zacznij od nowa';
  @override String get pinSetSuccess => 'PIN został ustawiony';
  @override String get pinRemovedSuccess => 'PIN został usunięty';
  @override String pinIncorrectAttempts(int r) => 'Nieprawidłowy PIN ($r prób)';
  @override String get biometricLockedOut => 'Czytnik zablokowany. Wpisz PIN lub zaloguj się inaczej.';
  @override String get biometricUnavailableLock => 'Biometria niedostępna. Wpisz PIN.';
  @override String get unlockBiometricButton => 'Odblokuj odciskiem palca';
  @override String get unlockApp => 'Odblokuj aplikację';
  @override String get signinDifferently => 'Zaloguj się inaczej';
  @override String pinIncorrectRemaining(int r) => 'Nieprawidłowy PIN. Pozostało prób: $r';

  @override String get securityTitle => 'Zabezpieczenia';
  @override String get biometricLabel => 'Odcisk palca';
  @override String get biometricEnabled => 'Włączony';
  @override String get biometricDisabled => 'Wyłączony';
  @override String get pinLabel => 'Kod PIN';
  @override String get pinNotSet => 'Nie ustawiony';
  @override String get pinSet => 'Ustawiony';
  @override String get pinSetupButton => 'Ustaw';
  @override String get pinChangeButton => 'Zmień';
  @override String get removePinLabel => 'Usuń PIN';
  @override String get removePinSubtitle => 'Wyłącz logowanie kodem';
  @override String get removePinButton => 'Usuń';
  @override String get biometricConfirmationPrompt => 'Potwierdź tożsamość aby włączyć odblokowanie biometryczne';
  @override String get biometricUnavailable => 'Biometria niedostępna lub niezarejestrowana w systemie';
  @override String get biometricVerificationFailed => 'Weryfikacja nieudana — biometria nie została włączona';
  @override String get securityInfo => 'PIN i biometria blokują aplikację po 5 minutach w tle. Sesja wygasa po 30 dniach — wówczas wymagane pełne logowanie.';

  @override String get languageLabel => 'Język';
  @override String get languagePolish => 'Polski';
  @override String get languageEnglish => 'English';

  @override String get lightMode => 'Jasna skórka';
  @override String get darkMode => 'Ciemna skórka';
  @override String get switchToApi => 'Przełącz na API';
  @override String get switchToMock => 'Przełącz na Mock';
  @override String get currentLocalData => 'Teraz: dane lokalne';
  @override String get currentApi => 'Teraz: API';
  @override String get securitySettings => 'Zabezpieczenia';
  @override String get logout => 'Wyloguj';
  @override String get importCalendarTooltip => 'Importuj kalendarz (.ics)';
  @override String get refreshCalendarTooltip => 'Odśwież / synchronizuj kalendarz';

  @override String get dataLoadingError => 'Błąd ładowania danych';
  @override String get deviceCalendarPermissionDenied => 'Brak zgody na odczyt kalendarza urządzenia';
  @override String calendarSyncError(String e) => 'Błąd kalendarza: $e';
  @override String get icsFileNoEvents => 'Plik .ics nie zawiera żadnych eventów';
  @override String icsImportSuccess(int count) => 'Zaimportowano $count eventów z kalendarza';
  @override String icsImportError(String e) => 'Błąd importu: $e';
  @override String apiConnectionError(String e) => 'Błąd połączenia z API: $e\nPrzywrócono tryb Mock.';
  @override String bookingCreationError(String e) => 'Błąd tworzenia rezerwacji: $e';
  @override String bookingCancellationError(String e) => 'Błąd anulowania rezerwacji: $e';
  @override String get bookingCancelled => 'Rezerwacja odwołana';
  @override String bookingCancelledWithReason(String r) => 'Rezerwacja odwołana: $r';
  @override String providerSubscribed(String name) => 'Zasubskrybowano: $name';
  @override String bookingConfirmedSimulated(String s) => '✅ Rezerwacja "$s" potwierdzona!';

  @override String get cancelBookingTitle => 'Odwołać rezerwację?';
  @override String get cancelBookingReasonLabel => 'Powód (opcjonalnie)';
  @override String get upcomingBookingsTitle => 'Nadchodzące rezerwacje';
  @override String get noUpcomingBookings => 'Brak nadchodzących rezerwacji';
  @override String get waitingSince => 'Czeka';
  @override String waitTime(String t) => 'Czeka $t';
  @override String get simulateConfirmation => 'Symuluj potwierdzenie';
  @override String get cancelBookingTooltip => 'Odwołaj';
  @override String get addBookingTitle => 'Dodaj rezerwację';
  @override String get chooseProviderSubtitle => 'Wybierz usługodawcę';
  @override String get existingProviderTitle => 'Z moich usługodawców';
  @override String get existingProviderSubtitle => 'Wybierz z listy zasubskrybowanych';
  @override String get newProviderTitle => 'Znajdź nowego usługodawcę';
  @override String get newProviderSubtitle => 'Szukaj w pobliżu na mapach';
  @override String get bookButton => 'Zarezerwuj';
  @override String get sendRequestButton => 'Wyślij prośbę';
  @override String get requiresConfirmation => 'Wymaga potwierdzenia';
  @override String get instantBooking => 'Natychmiastowa';
  @override String get chooseServiceLabel => 'Wybierz usługę';

  @override String get myProvidersTitle => 'Moi usługodawcy';
  @override String get addProvidersTooltip => 'Dodaj nowych usługodawców';
  @override String get noProviders => 'Nie masz jeszcze usługodawców';
  @override String get findAddProviderButton => 'Znajdź i dodaj usługodawcę';
  @override String get myBookingsLabel => 'Moje rezerwacje';
  @override String freeSlotsForDate(String d) => 'Wolne sloty — $d';
  @override String get providerDetailsTip => 'Dwukrotnie dotknij aby zobaczyć szczegóły';
  @override String get fullDetailsButton => 'Pełne detale';
  @override String get callButton => 'Zadzwoń';
  @override String get mapButton => 'Mapa';
  @override String get slotAlreadyBooked => 'W tym terminie masz już rezerwację';
  @override String get cancelBookingConfirmButton => 'Odwołaj';

  @override String get upcomingBookingsTileTitle => 'Nadchodzące\nrezerwacje';
  @override String get myProvidersTileTitle => 'Moi usługodawcy';
  @override String get bookingCalendarTileTitle => 'Kalendarz\nrezerwacji';
  @override String get noUpcomingBookingsTile => 'Brak nadchodzących\nrezerwacji';
  @override String get noBookingsToday => 'Brak wizyt\nna dziś';
  @override String get addBookingLink => 'Dodaj rezerwację';
  @override String get loggedInDefault => 'Zalogowany';
  @override String get selectedProviderLabel => 'Wybrany:';
  @override String providerCountLabel(int count) => count == 1 ? 'usługodawca' : 'usługodawców';
  @override String bookingCountLabel(int count) => count == 1 ? 'rezerwacja' : 'rezerwacji';
  @override String moreOthers(int count) => '+ $count innych';
  @override String moreItems(int count) => '+ $count więcej';
  @override String dataLoadError(String e) => 'Błąd ładowania danych: $e';

  @override String get aboutProviderTitle => 'O usługodawcy';
  @override String get contactAddressTitle => 'Kontakt i adres';
  @override String get openingHoursTitle => 'Godziny otwarcia';
  @override String get userRatingTitle => 'Twoja ocena';
  @override String get showCalendarButton => 'Pokaż kalendarz';
  @override String get websiteButton => 'Strona';
  @override String get googleCalendarEventNote => 'Event z Google Calendar — edytuj go bezpośrednio w kalendarzu.';
  @override String get openInMapsButton => 'Otwórz w Mapach';
  @override String get ratingPoor => 'Słabo';
  @override String get ratingFair => 'Ujdzie';
  @override String get ratingGood => 'Dobrze';
  @override String get ratingVeryGood => 'Bardzo dobrze';
  @override String get ratingExcellent => 'Świetnie!';
  @override String get ratingTapToRate => 'Dotknij gwiazdkę, żeby ocenić';
  @override String get ratingThanks => 'Dziękujemy za ocenę!';
  @override String ratingError(String msg) => 'Błąd: $msg';
  @override String get ratingErrorSendFailed => 'Nie udało się wysłać oceny.';

  @override String get searchResultsLoading => 'Szukam w pobliżu...';
  @override String searchResultsCount(int n) => '$n wyników w pobliżu';
  @override String get gpsFixedLabel => 'Twoja lokalizacja';
  @override String get gpsNotFixedLabel => 'Lokalizacja domyślna';
  @override String get noResults => 'Brak wyników w pobliżu.\nSpróbuj inną kategorię.';
  @override String get searchTooltip => 'Szukaj ponownie';
  @override String get myLocationTooltip => 'Moja lokalizacja';
  @override String get inviteDialogTitle => 'Zaproś do Tugio';
  @override String get inviteMessage =>
      'Chcę umówić wizytę. Zapraszam Cię do Tugio — systemu do zarządzania rezerwacjami. '
      'Zarejestruj się tutaj: https://tugio.app/register';
  @override String get openSmsButton => 'Otwórz SMS';
  @override String get smsOpenFailed => 'Nie można otworzyć aplikacji SMS';
  @override String get providerNotInTugio => 'Usługodawca nie należy do Tugio. Zaproś go, żeby umówić wizytę.';
  @override String get inviteButton => 'Zaproś do Tugio';
  @override String get noPhoneLabel => 'Brak numeru telefonu — nie można zaprosić';

  @override String get chooseServiceTitle => 'Wybierz typ usługi';
  @override String get whatAreYouLookingFor => 'Czego szukasz?';
  @override String get chooseCategorySubtitle => 'Wybierz kategorię, a pokażemy Ci usługodawców w Twojej okolicy.';
  @override String get categoriesLoadError => 'Nie udało się pobrać kategorii.\nSprawdź połączenie.';

  @override String get sendRequestHint => 'Wyślij prośbę';
  @override String get bookHint => 'Zarezerwuj';
  @override String get googleCalendarSource => 'Google Calendar';
  @override String get importInfo => 'Event z Google Calendar — edytuj go bezpośrednio w kalendarzu.';
  @override String get calendarFilterAllTooltip => 'Wszystko (kliknij: ukryj sloty)';
  @override String get calendarFilterNoSlotsTooltip => 'Bez wolnych slotów (kliknij: tylko moje wizyty)';
  @override String get calendarFilterOnlyMineTooltip => 'Tylko moje wizyty (kliknij: pokaż wszystko)';
  @override String get servicesTitle => 'Usługi';
  @override String get myCalendarTitle => 'Mój kalendarz';
  @override String inquiryCreated(String service, String time) => 'Zapytanie utworzone: $service, $time';
  @override String get cancelBookingReasonPlaceholder => 'Opis / powód';
  @override String get pendingBookingsTitle => 'Oczekujące na potwierdzenie';
  @override String get noPendingBookings => 'Żadna rezerwacja nie oczekuje\nna potwierdzenie';
  @override String get confirmBookingButton => 'Potwierdź';
  @override String bookingConfirmedMessage(String service) => '✅ Rezerwacja "$service" potwierdzona!';
  @override String get pendingStatusLabel => 'Oczekuje';
  @override String waitMinutes(int minutes) => 'Czeka $minutes min';
  @override String waitHoursMinutes(int hours, int minutes) => 'Czeka ${hours}h ${minutes}min';
  @override String selectPersonTitle(String time) => 'Wybierz osobę — $time';

  @override String get svcHaircutWomen => 'Strzyżenie damskie';
  @override String get svcHaircutWomenDesc => 'Mycie, strzyżenie i stylizacja włosów.';
  @override String get svcHaircutMen => 'Strzyżenie męskie';
  @override String get svcHaircutMenDesc => 'Klasyczne lub nowoczesne strzyżenie.';
  @override String get svcHairColoring => 'Koloryzacja';
  @override String get svcHairColoringDesc => 'Pełna koloryzacja lub odrosty z pielęgnacją.';
  @override String get svcHairStyling => 'Modelowanie';
  @override String get svcHairStylingDesc => 'Blow-dry, fale lub prostowanie.';
  @override String get svcPsychologyConsultation => 'Konsultacja indywidualna';
  @override String get svcPsychologyConsultationDesc => 'Pierwsza wizyta, diagnoza i omówienie celów terapii.';
  @override String get svcTherapySession => 'Sesja terapeutyczna';
  @override String get svcTherapySessionDesc => 'Regularna sesja terapii indywidualnej.';
  @override String get svcCouplesTherapy => 'Terapia par';
  @override String get svcCouplesTherapyDesc => 'Sesja dla par — komunikacja i relacje.';
  @override String get svcPersonalTraining => 'Trening personalny';
  @override String get svcPersonalTrainingDesc => 'Indywidualny plan ćwiczeń dostosowany do Twoich celów.';
  @override String get svcPostureAnalysis => 'Analiza postawy';
  @override String get svcPostureAnalysisDesc => 'Ocena biomechaniki i korygowanie wad postawy.';
  @override String get svcNutritionConsultation => 'Konsultacja dietetyczna';
  @override String get svcNutritionConsultationDesc => 'Plan żywieniowy wspierający Twój trening.';
  @override String get svcStandardVisit => 'Wizyta standardowa';
  @override String svcStandardVisitDesc(String p) => 'Standardowa wizyta u $p.';
  @override String get svcUrgentVisit => 'Wizyta pilna';
  @override String get svcUrgentVisitDesc => 'Szybka konsultacja w trybie pilnym.';
}

// ─────────────────────────────────────────────────────────────────────────────
// ENGLISH
// ─────────────────────────────────────────────────────────────────────────────
class EnStrings extends AppStrings {
  @override String get appName => 'Tugio';
  @override String get cancel => 'Cancel';
  @override String get leave => 'Keep';
  @override String get close => 'Close';
  @override String get save => 'Save';
  @override String get retry => 'Try again';
  @override String get ok => 'OK';
  @override String get yes => 'Yes';
  @override String get no => 'No';
  @override String get or => 'or';
  @override String get loading => 'Loading...';
  @override String get error => 'Error';
  @override String get minutes => 'min';
  @override String get aFewMoments => 'a moment';
  @override String get currencySuffix => 'PLN';

  @override String get today => 'Today';
  @override String get day => 'Day';
  @override String get week => 'Week';
  @override String get month => 'Month';
  @override String get allDay => 'All day';

  @override String get statusBooked => 'Confirmed';
  @override String get statusPending => 'Pending';
  @override String get statusInquiry => 'Inquiry';
  @override String get statusAwaitingConfirmation => 'Awaiting confirmation';
  @override String get statusUnknown => 'Unknown';

  @override String get loginTagline => 'Book an appointment\nin a few seconds';
  @override String get loginDescription => 'Manage bookings in one place';
  @override String get emailLabel => 'Email';
  @override String get passwordLabel => 'Password';
  @override String get emailRequired => 'Enter email';
  @override String get emailInvalid => 'Invalid email';
  @override String get passwordRequired => 'Enter password';
  @override String get loginButton => 'Sign In';
  @override String get googleLoginButton => 'Sign in with Google';
  @override String get demoModeButton => 'Enter demo mode';
  @override String get webGoogleSigninInfo => 'Google Sign-In works on a mobile device or emulator.';
  @override String get noAccountText => "Don't have an account?";
  @override String get registerLink => 'Sign up';

  @override String get createAccountTitle => 'Create account';
  @override String get fullNameLabel => 'Full name';
  @override String get fullNameRequired => 'Enter name';
  @override String get passwordMinLength => 'Minimum 8 characters';
  @override String get confirmPasswordLabel => 'Confirm password';
  @override String get passwordMismatch => "Passwords don't match";
  @override String get createAccountButton => 'Create account';
  @override String get alreadyHaveAccount => 'Already have an account?';
  @override String get signinLink => 'Sign in';

  @override String get pinSetupTitle => 'Set PIN';
  @override String get pinChangeTitle => 'Change PIN';
  @override String get pinRemoveTitle => 'Remove PIN';
  @override String get pinVerifyRemoveInstruction => 'Enter current PIN to remove it';
  @override String get pinVerifyInstruction => 'Enter current PIN';
  @override String get pinEnterInstruction => 'Enter new PIN (4 digits)';
  @override String get pinConfirmInstruction => 'Confirm new PIN';
  @override String get pinTooManyAttempts => 'Too many attempts. Sign in again.';
  @override String get pinMismatch => "PINs don't match – start over";
  @override String get pinSetSuccess => 'PIN set successfully';
  @override String get pinRemovedSuccess => 'PIN removed';
  @override String pinIncorrectAttempts(int r) => 'Incorrect PIN ($r attempts left)';
  @override String get biometricLockedOut => 'Reader locked. Enter PIN or sign in differently.';
  @override String get biometricUnavailableLock => 'Biometrics unavailable. Enter PIN.';
  @override String get unlockBiometricButton => 'Unlock with fingerprint';
  @override String get unlockApp => 'Unlock app';
  @override String get signinDifferently => 'Sign in differently';
  @override String pinIncorrectRemaining(int r) => 'Incorrect PIN. Attempts remaining: $r';

  @override String get securityTitle => 'Security';
  @override String get biometricLabel => 'Fingerprint';
  @override String get biometricEnabled => 'Enabled';
  @override String get biometricDisabled => 'Disabled';
  @override String get pinLabel => 'PIN Code';
  @override String get pinNotSet => 'Not set';
  @override String get pinSet => 'Set';
  @override String get pinSetupButton => 'Set up';
  @override String get pinChangeButton => 'Change';
  @override String get removePinLabel => 'Remove PIN';
  @override String get removePinSubtitle => 'Disable PIN login';
  @override String get removePinButton => 'Remove';
  @override String get biometricConfirmationPrompt => 'Confirm identity to enable biometric unlock';
  @override String get biometricUnavailable => 'Biometrics unavailable or not registered';
  @override String get biometricVerificationFailed => 'Verification failed – biometric not enabled';
  @override String get securityInfo => 'PIN and biometrics lock the app after 5 minutes in background. Session expires after 30 days – then full login required.';

  @override String get languageLabel => 'Language';
  @override String get languagePolish => 'Polski';
  @override String get languageEnglish => 'English';

  @override String get lightMode => 'Light theme';
  @override String get darkMode => 'Dark theme';
  @override String get switchToApi => 'Switch to API';
  @override String get switchToMock => 'Switch to Mock';
  @override String get currentLocalData => 'Now: local data';
  @override String get currentApi => 'Now: API';
  @override String get securitySettings => 'Security';
  @override String get logout => 'Log out';
  @override String get importCalendarTooltip => 'Import calendar (.ics)';
  @override String get refreshCalendarTooltip => 'Refresh / sync calendar';

  @override String get dataLoadingError => 'Data loading error';
  @override String get deviceCalendarPermissionDenied => 'Device calendar read permission denied';
  @override String calendarSyncError(String e) => 'Calendar error: $e';
  @override String get icsFileNoEvents => '.ics file contains no events';
  @override String icsImportSuccess(int count) => 'Imported $count events from calendar';
  @override String icsImportError(String e) => 'Import error: $e';
  @override String apiConnectionError(String e) => 'API connection error: $e\nRestored mock mode.';
  @override String bookingCreationError(String e) => 'Booking creation error: $e';
  @override String bookingCancellationError(String e) => 'Booking cancellation error: $e';
  @override String get bookingCancelled => 'Booking cancelled';
  @override String bookingCancelledWithReason(String r) => 'Booking cancelled: $r';
  @override String providerSubscribed(String name) => 'Subscribed: $name';
  @override String bookingConfirmedSimulated(String s) => '✅ Booking "$s" confirmed!';

  @override String get cancelBookingTitle => 'Cancel booking?';
  @override String get cancelBookingReasonLabel => 'Reason (optional)';
  @override String get upcomingBookingsTitle => 'Upcoming bookings';
  @override String get noUpcomingBookings => 'No upcoming bookings';
  @override String get waitingSince => 'Waiting';
  @override String waitTime(String t) => 'Waiting $t';
  @override String get simulateConfirmation => 'Simulate confirmation';
  @override String get cancelBookingTooltip => 'Cancel';
  @override String get addBookingTitle => 'Add booking';
  @override String get chooseProviderSubtitle => 'Choose provider';
  @override String get existingProviderTitle => 'From my providers';
  @override String get existingProviderSubtitle => 'Choose from subscribed list';
  @override String get newProviderTitle => 'Find new provider';
  @override String get newProviderSubtitle => 'Search nearby on map';
  @override String get bookButton => 'Book';
  @override String get sendRequestButton => 'Send request';
  @override String get requiresConfirmation => 'Requires confirmation';
  @override String get instantBooking => 'Instant';
  @override String get chooseServiceLabel => 'Choose service';

  @override String get myProvidersTitle => 'My providers';
  @override String get addProvidersTooltip => 'Add new providers';
  @override String get noProviders => "You don't have providers yet";
  @override String get findAddProviderButton => 'Find and add provider';
  @override String get myBookingsLabel => 'My bookings';
  @override String freeSlotsForDate(String d) => 'Available slots – $d';
  @override String get providerDetailsTip => 'Double-tap to see details';
  @override String get fullDetailsButton => 'Full details';
  @override String get callButton => 'Call';
  @override String get mapButton => 'Map';
  @override String get slotAlreadyBooked => 'You already have a booking at this time';
  @override String get cancelBookingConfirmButton => 'Cancel booking';

  @override String get upcomingBookingsTileTitle => 'Upcoming\nbookings';
  @override String get myProvidersTileTitle => 'My providers';
  @override String get bookingCalendarTileTitle => 'Booking\ncalendar';
  @override String get noUpcomingBookingsTile => 'No upcoming\nbookings';
  @override String get noBookingsToday => 'No visits\ntoday';
  @override String get addBookingLink => 'Add booking';
  @override String get loggedInDefault => 'Logged in';
  @override String get selectedProviderLabel => 'Selected:';
  @override String providerCountLabel(int count) => count == 1 ? 'provider' : 'providers';
  @override String bookingCountLabel(int count) => count == 1 ? 'booking' : 'bookings';
  @override String moreOthers(int count) => '+ $count others';
  @override String moreItems(int count) => '+ $count more';
  @override String dataLoadError(String e) => 'Error loading data: $e';

  @override String get aboutProviderTitle => 'About provider';
  @override String get contactAddressTitle => 'Contact & address';
  @override String get openingHoursTitle => 'Opening hours';
  @override String get userRatingTitle => 'Your rating';
  @override String get showCalendarButton => 'Show calendar';
  @override String get websiteButton => 'Website';
  @override String get googleCalendarEventNote => 'Google Calendar event — edit it directly in your calendar.';
  @override String get openInMapsButton => 'Open in Maps';
  @override String get ratingPoor => 'Poor';
  @override String get ratingFair => 'Fair';
  @override String get ratingGood => 'Good';
  @override String get ratingVeryGood => 'Very good';
  @override String get ratingExcellent => 'Excellent!';
  @override String get ratingTapToRate => 'Tap a star to rate';
  @override String get ratingThanks => 'Thank you for rating!';
  @override String ratingError(String msg) => 'Error: $msg';
  @override String get ratingErrorSendFailed => 'Failed to send rating.';

  @override String get searchResultsLoading => 'Searching nearby...';
  @override String searchResultsCount(int n) => '$n results nearby';
  @override String get gpsFixedLabel => 'Your location';
  @override String get gpsNotFixedLabel => 'Default location';
  @override String get noResults => 'No results nearby.\nTry another category.';
  @override String get searchTooltip => 'Search again';
  @override String get myLocationTooltip => 'My location';
  @override String get inviteDialogTitle => 'Invite to Tugio';
  @override String get inviteMessage =>
      'I want to book an appointment. I invite you to Tugio – a booking management system. '
      'Register here: https://tugio.app/register';
  @override String get openSmsButton => 'Open SMS';
  @override String get smsOpenFailed => 'Cannot open SMS app';
  @override String get providerNotInTugio => "Provider is not in Tugio. Invite them to book an appointment.";
  @override String get inviteButton => 'Invite to Tugio';
  @override String get noPhoneLabel => 'No phone number – cannot invite';

  @override String get chooseServiceTitle => 'Choose service type';
  @override String get whatAreYouLookingFor => 'What are you looking for?';
  @override String get chooseCategorySubtitle => "Choose a category and we'll show you providers in your area.";
  @override String get categoriesLoadError => 'Failed to load categories.\nCheck your connection.';

  @override String get sendRequestHint => 'Send request';
  @override String get bookHint => 'Book';
  @override String get googleCalendarSource => 'Google Calendar';
  @override String get importInfo => 'Event from Google Calendar – edit it directly in your calendar.';
  @override String get calendarFilterAllTooltip => 'All (tap: hide slots)';
  @override String get calendarFilterNoSlotsTooltip => 'No free slots (tap: only my bookings)';
  @override String get calendarFilterOnlyMineTooltip => 'Only my bookings (tap: show all)';
  @override String get servicesTitle => 'Services';
  @override String get myCalendarTitle => 'My Calendar';
  @override String inquiryCreated(String service, String time) => 'Inquiry created: $service, $time';
  @override String get cancelBookingReasonPlaceholder => 'Description / reason';
  @override String get pendingBookingsTitle => 'Awaiting confirmation';
  @override String get noPendingBookings => 'No bookings are awaiting\nconfirmation';
  @override String get confirmBookingButton => 'Confirm';
  @override String bookingConfirmedMessage(String service) => '✅ Booking "$service" confirmed!';
  @override String get pendingStatusLabel => 'Pending';
  @override String waitMinutes(int minutes) => 'Waiting $minutes min';
  @override String waitHoursMinutes(int hours, int minutes) => 'Waiting ${hours}h ${minutes}min';
  @override String selectPersonTitle(String time) => 'Choose person — $time';

  @override String get svcHaircutWomen => "Women's haircut";
  @override String get svcHaircutWomenDesc => 'Wash, cut and hair styling.';
  @override String get svcHaircutMen => "Men's haircut";
  @override String get svcHaircutMenDesc => 'Classic or modern haircut.';
  @override String get svcHairColoring => 'Hair coloring';
  @override String get svcHairColoringDesc => 'Full color or roots with care.';
  @override String get svcHairStyling => 'Hair styling';
  @override String get svcHairStylingDesc => 'Blow-dry, waves or straightening.';
  @override String get svcPsychologyConsultation => 'Individual consultation';
  @override String get svcPsychologyConsultationDesc => 'First visit, diagnosis and therapy goals.';
  @override String get svcTherapySession => 'Therapy session';
  @override String get svcTherapySessionDesc => 'Regular individual therapy session.';
  @override String get svcCouplesTherapy => 'Couples therapy';
  @override String get svcCouplesTherapyDesc => 'Session for couples – communication and relationships.';
  @override String get svcPersonalTraining => 'Personal training';
  @override String get svcPersonalTrainingDesc => 'Individual exercise plan tailored to your goals.';
  @override String get svcPostureAnalysis => 'Posture analysis';
  @override String get svcPostureAnalysisDesc => 'Biomechanics assessment and posture correction.';
  @override String get svcNutritionConsultation => 'Nutrition consultation';
  @override String get svcNutritionConsultationDesc => 'Nutrition plan supporting your training.';
  @override String get svcStandardVisit => 'Standard visit';
  @override String svcStandardVisitDesc(String p) => 'Standard visit at $p.';
  @override String get svcUrgentVisit => 'Urgent visit';
  @override String get svcUrgentVisitDesc => 'Quick urgent consultation.';
}

// ─────────────────────────────────────────────────────────────────────────────
// InheritedWidget — pozwala AppStrings.of(context) działać w całym drzewie
// ─────────────────────────────────────────────────────────────────────────────
class _LanguageNotifierScope extends InheritedWidget {
  final String language;

  const _LanguageNotifierScope({
    required this.language,
    required super.child,
  });

  static String of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_LanguageNotifierScope>();
    return scope?.language ?? 'pl';
  }

  @override
  bool updateShouldNotify(_LanguageNotifierScope old) =>
      language != old.language;
}

/// Owiń MaterialApp tym widgetem żeby AppStrings.of(context) działało.
class LanguageScope extends StatelessWidget {
  final ValueNotifier<String> notifier;
  final Widget child;

  const LanguageScope({
    super.key,
    required this.notifier,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: notifier,
      builder: (_, lang, __) => _LanguageNotifierScope(
        language: lang,
        child: child,
      ),
    );
  }
}
