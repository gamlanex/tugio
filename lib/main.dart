import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'utils/app_theme.dart';

// Globalny notifier dla trybu ciemnego/jasnego
final themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

// Globalny notifier dla trybu danych: true = Mock, false = API
final useMockNotifier = ValueNotifier<bool>(true);

void main() {
  runApp(const TugioApp());
}

class TugioApp extends StatelessWidget {
  const TugioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (_, mode, __) => MaterialApp(
        title: 'Tugio',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: mode,
        home: const LoginScreen(),
      ),
    );
  }
}
