import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const TugioApp());
}

class TugioApp extends StatelessWidget {
  const TugioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tugio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFFF6F7FB),
      ),
      home: const LoginScreen(),
    );
  }
}
