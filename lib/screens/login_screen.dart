// ─────────────────────────────────────────────────────────────────────────────
// LoginScreen — ekran logowania
//
// Metody logowania:
//  1. Email + hasło  → ApiAuthService (POST /auth/login)
//  2. Google Sign-In → Google OAuth + ApiAuthService (POST /auth/google)
//
// Link "Zarejestruj się" otwiera RegisterScreen.
// Na web: tylko tryb demo (Google Sign-In wymaga dodatkowej konfiguracji).
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/auth_service.dart';
import '../main.dart' show authStateNotifier, AuthState, useMockNotifier;
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtr = TextEditingController();
  final _passCtr = TextEditingController();

  bool _loading = false;
  bool _showPass = false;
  String? _error;

  @override
  void dispose() {
    _emailCtr.dispose();
    _passCtr.dispose();
    super.dispose();
  }

  // ── Logowanie email/hasło ──────────────────────────────────────────────────

  Future<void> _loginWithEmail() async {
    if (!_formKey.currentState!.validate()) return;
    _setLoading(true);

    final result = await AuthService.instance.signInWithEmail(
      _emailCtr.text.trim(),
      _passCtr.text,
      useMock: useMockNotifier.value,
    );
    _handleResult(result);
  }

  // ── Logowanie Google ───────────────────────────────────────────────────────

  Future<void> _loginWithGoogle() async {
    _setLoading(true);
    final result = await AuthService.instance
        .signInWithGoogle(useMock: useMockNotifier.value);
    _handleResult(result);
  }

  void _handleResult(AuthResult result) {
    if (!mounted) return;
    if (result.success) {
      authStateNotifier.value = AuthState.authenticated;
    } else {
      setState(() {
        _loading = false;
        _error = result.error;
      });
    }
  }

  void _setLoading(bool v) {
    if (mounted) setState(() => _loading = v);
  }

  void _openRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 56),

                // ── Logo ──────────────────────────────────────────
                Center(
                  child: SvgPicture.asset('assets/images/Tugio.svg',
                      height: 60),
                ),
                const SizedBox(height: 28),

                // ── Tagline ───────────────────────────────────────
                Text(
                  s.loginTagline,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      height: 1.3),
                ),
                const SizedBox(height: 8),
                Text(
                  s.loginDescription,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14,
                      color: cs.onSurface.withOpacity(0.55)),
                ),

                const SizedBox(height: 40),

                // ── Formularz email ───────────────────────────────
                if (!kIsWeb) ...[
                  TextFormField(
                    controller: _emailCtr,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: s.emailLabel,
                      prefixIcon:
                          const Icon(Icons.email_outlined, size: 20),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return s.emailRequired;
                      if (!v.contains('@')) return s.emailInvalid;
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passCtr,
                    obscureText: !_showPass,
                    decoration: InputDecoration(
                      labelText: s.passwordLabel,
                      prefixIcon:
                          const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                            _showPass
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 20),
                        onPressed: () =>
                            setState(() => _showPass = !_showPass),
                      ),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? s.passwordRequired : null,
                  ),
                  const SizedBox(height: 16),

                  // ── Przycisk email ─────────────────────────────
                  FilledButton(
                    onPressed: _loading ? null : _loginWithEmail,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(s.loginButton,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                  ),

                  const SizedBox(height: 20),

                  // ── Separator ──────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                          child: Divider(
                              color: cs.onSurface.withOpacity(0.2))),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(s.or,
                            style: TextStyle(
                                color: cs.onSurface.withOpacity(0.45),
                                fontSize: 13)),
                      ),
                      Expanded(
                          child: Divider(
                              color: cs.onSurface.withOpacity(0.2))),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Przycisk Google ────────────────────────────
                  OutlinedButton(
                    onPressed: _loading ? null : _loginWithGoogle,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      side: BorderSide(
                          color: cs.onSurface.withOpacity(0.25)),
                      backgroundColor: isDark
                          ? cs.surfaceContainerHighest
                          : Colors.white,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.login,
                            color: Colors.indigo.shade600, size: 20),
                        const SizedBox(width: 10),
                        Text(s.googleLoginButton,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],

                // ── Tryb Web ──────────────────────────────────────
                if (kIsWeb) ...[
                  ElevatedButton(
                    onPressed: () =>
                        authStateNotifier.value = AuthState.authenticated,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.play_arrow_rounded, size: 22),
                        const SizedBox(width: 8),
                        Text(s.demoModeButton,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.webGoogleSigninInfo,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 11.5,
                        color: cs.onSurface.withOpacity(0.38)),
                  ),
                ],

                // ── Błąd ──────────────────────────────────────────
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: cs.errorContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(_error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: cs.onErrorContainer, fontSize: 13)),
                  ),
                ],

                const SizedBox(height: 32),

                // ── Link rejestracja ──────────────────────────────
                if (!kIsWeb)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(s.noAccountText + ' ',
                          style: TextStyle(
                              color: cs.onSurface.withOpacity(0.6),
                              fontSize: 14)),
                      GestureDetector(
                        onTap: _openRegister,
                        child: Text(
                          s.registerLink,
                          style: const TextStyle(
                            color: Colors.indigo,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
