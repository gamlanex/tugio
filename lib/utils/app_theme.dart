import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
//  Paleta kolorów – jedno miejsce dla całej aplikacji
// ─────────────────────────────────────────────────────────────

class AppColors {
  AppColors._();

  // Seed / brand
  static const Color seed = Color(0xFF3F51B5); // indigo

  // Tło ekranów
  static const Color backgroundLight = Color(0xFFF6F7FB);
  static const Color backgroundDark = Color(0xFF121318);

  // Powierzchnie kart
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E2028);

  // Kolory slotów
  static const Color slotInstant = Colors.blue; // natychmiastowa rezerwacja
  static const Color slotConfirmation = Colors.orange; // wymaga potwierdzenia

  // Statusy rezerwacji
  static const Color statusBooked = Colors.blue;
  static const Color statusPending = Colors.orange;
  static const Color statusInquiry = Colors.grey;

  // Kolory typów usług
  static const Map<String, Color> serviceTypeColors = {
    'Fryzjer': Color(0xFF8B5CF6),       // fioletowy
    'Psycholog': Color(0xFF0D9488),     // teal
    'Trener': Color(0xFFF97316),        // pomarańczowy
    'Dentysta': Color(0xFF3B82F6),      // niebieski
    'Lekarz': Color(0xFFEF4444),        // czerwony
    'Kosmetyczka': Color(0xFF22C55E),   // zielony
    'Masażysta': Color(0xFF84CC16),     // limonkowy
    'Fizjoterapeuta': Color(0xFFEC4899), // różowy
  };

  static Color forServiceType(String serviceType) =>
      serviceTypeColors[serviceType] ?? seed;
}

// ─────────────────────────────────────────────────────────────
//  Gotowe ThemeData
// ─────────────────────────────────────────────────────────────

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: AppColors.seed,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.backgroundLight,
        cardColor: AppColors.surfaceLight,
        cardTheme: CardThemeData(
          color: AppColors.surfaceLight,
          elevation: 1,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: AppColors.seed,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.backgroundDark,
        cardColor: AppColors.surfaceDark,
        cardTheme: CardThemeData(
          color: AppColors.surfaceDark,
          elevation: 1,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
}
