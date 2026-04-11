import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/auth_service.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tryAutoSignIn();
  }

  // Próbuje przywrócić poprzednią sesję bez ekranu wyboru konta
  Future<void> _tryAutoSignIn() async {
    // Na Web Google Sign-In wymaga dodatkowej konfiguracji —
    // od razu pokazujemy ekran logowania bez próby auto-logowania.
    if (kIsWeb) {
      setState(() => _loading = false);
      return;
    }
    final ok = await AuthService.instance.tryAutoSignIn();
    if (ok && mounted) {
      _navigateToMain();
    } else if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _handleSignIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await AuthService.instance.signIn();
      if (user != null && mounted) {
        _navigateToMain();
      } else if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Logowanie anulowane';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Błąd logowania: $e';
        });
      }
    }
  }

  void _navigateToMain() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 3),

              // ── Logo ─────────────────────────────────────────
              Center(
                child: SvgPicture.asset(
                  'assets/images/Tugio.svg',
                  height: 64,
                ),
              ),
              const SizedBox(height: 24),

              // ── Tagline ──────────────────────────────────────
              const Text(
                'Zarezerwuj wizytę\nw kilka sekund',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Zarządzaj swoimi rezerwacjami\nw jednym miejscu',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.black54),
              ),

              const Spacer(flex: 2),

              // ── Przycisk logowania ───────────────────────────
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else ...[
                OutlinedButton(
                  onPressed: kIsWeb ? null : _handleSignIn,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    side: BorderSide(
                      color: kIsWeb ? Colors.black12 : Colors.black26,
                    ),
                    backgroundColor: kIsWeb ? Colors.grey.shade100 : Colors.white,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.login,
                          color: kIsWeb
                              ? Colors.grey
                              : Colors.indigo.shade600,
                          size: 22),
                      const SizedBox(width: 12),
                      Text(
                        kIsWeb
                            ? 'Google Sign-In (tylko na urządzeniu)'
                            : 'Zaloguj się przez Google',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: kIsWeb ? Colors.grey : null,
                        ),
                      ),
                    ],
                  ),
                ),

                // Na Web: przycisk demo zamiast Google Sign-In
                if (kIsWeb) ...[
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _navigateToMain,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow_rounded, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Wejdź w trybie demo',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Google Sign-In działa na urządzeniu mobilnym lub emulatorze.\nWeb wymaga dodatkowej konfiguracji Firebase.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11.5, color: Colors.black38),
                  ),
                ],
              ],

              // ── Błąd ────────────────────────────────────────
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ],

              const SizedBox(height: 56),
            ],
          ),
        ),
      ),
    );
  }
}
