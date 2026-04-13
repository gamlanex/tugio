// ─────────────────────────────────────────────────────────────────────────────
// LockScreen — ekran blokady (PIN + odcisk palca)
//
// Wyświetlany gdy:
//  • aplikacja wróciła z tła po czasie > konfigurowanego progu (domyślnie 5 min)
//  • użytkownik ma skonfigurowany PIN lub biometrię
//
// Zachowanie:
//  • Jeśli biometria włączona → automatycznie uruchamia prompt przy wejściu
//  • Jeśli PIN włączony → widoczna klawiatura numeryczna
//  • Po wyczerpaniu prób PIN → wymagane pełne logowanie
//  • "Zaloguj się inaczej" → czyści sesję i wraca na LoginScreen
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/local_auth_service.dart';
import '../main.dart' show authStateNotifier, AuthState, useMockNotifier;

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String _pin = '';
  bool _biometricEnabled = false;
  bool _pinEnabled = false;
  bool _loading = false;
  String? _error;

  static const _pinLength = 4;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // canAndShouldUseBiometric() sprawdza zarówno preferencję użytkownika
    // jak i to, czy biometria jest faktycznie zarejestrowana w systemie.
    // Chroni przed sytuacją gdy użytkownik usunął Face ID/odcisk palca
    // z ustawień systemowych po włączeniu biometrii w Tugio.
    final bio = await LocalAuthService.instance.canAndShouldUseBiometric();
    final pin = await LocalAuthService.instance.isPinEnabled();
    if (!mounted) return;
    setState(() {
      _biometricEnabled = bio;
      _pinEnabled = pin;
    });
    if (bio) {
      // Krótkie opóźnienie żeby ekran się wyrenderował
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) _tryBiometric();
    }
  }

  Future<void> _tryBiometric() async {
    setState(() => _loading = true);
    final result = await AuthService.instance.unlockWithBiometric();
    if (!mounted) return;
    setState(() => _loading = false);

    switch (result) {
      case BiometricResult.success:
        authStateNotifier.value = AuthState.authenticated;
        break;
      case BiometricResult.lockedOut:
        setState(() =>
            _error = 'Czytnik zablokowany. Wpisz PIN lub zaloguj się inaczej.');
        break;
      case BiometricResult.notAvailable:
        setState(
            () => _error = 'Biometria niedostępna. Wpisz PIN.');
        break;
      case BiometricResult.failed:
        // Użytkownik odrzucił — nic nie robimy, PIN nadal dostępny
        break;
    }
  }

  Future<void> _onDigit(String digit) async {
    if (_pin.length >= _pinLength) return;
    final newPin = _pin + digit;
    setState(() {
      _pin = newPin;
      _error = null;
    });

    if (newPin.length == _pinLength) {
      await Future.delayed(const Duration(milliseconds: 120));
      if (!mounted) return;
      _verifyPin(newPin);
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _verifyPin(String pin) async {
    setState(() => _loading = true);
    final result = await AuthService.instance.unlockWithPin(pin);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _pin = '';
    });

    if (result.isSuccess) {
      authStateNotifier.value = AuthState.authenticated;
    } else if (result.isTooManyAttempts) {
      setState(() =>
          _error = 'Zbyt wiele błędnych prób. Zaloguj się ponownie.');
    } else {
      setState(() {
        final rem = result.remainingAttempts;
        _error = 'Nieprawidłowy PIN. Pozostało prób: $rem';
      });
    }
  }

  Future<void> _signOutAndGoToLogin() async {
    await AuthService.instance.signOut(useMock: useMockNotifier.value);
    authStateNotifier.value = AuthState.unauthenticated;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final user = AuthService.instance.currentUser;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 48),

            // ── Awatar i dane użytkownika ────────────────────────
            _buildUserHeader(cs, user),

            const Spacer(),

            // ── Wskaźnik PIN ─────────────────────────────────────
            if (_pinEnabled) ...[
              _PinDots(filled: _pin.length, total: _pinLength),
              const SizedBox(height: 16),

              // ── Komunikat błędu ─────────────────────────────────
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: cs.error, fontSize: 13, height: 1.4),
                  ),
                ),

              const SizedBox(height: 20),

              // ── Klawiatura numeryczna ───────────────────────────
              _PinPad(
                onDigit: _loading ? null : _onDigit,
                onBackspace: _loading ? null : _onBackspace,
                onBiometric:
                    (_biometricEnabled && !_loading) ? _tryBiometric : null,
              ),
            ] else if (_biometricEnabled) ...[
              // Tylko biometria bez PIN
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: cs.error, fontSize: 13, height: 1.4),
                  ),
                ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loading ? null : _tryBiometric,
                icon: const Icon(Icons.fingerprint, size: 28),
                label: const Text('Odblokuj odciskiem palca',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // ── Link "Zaloguj się inaczej" ───────────────────────
            TextButton(
              onPressed: _signOutAndGoToLogin,
              child: Text(
                'Zaloguj się inaczej',
                style: TextStyle(
                    color: cs.onSurface.withOpacity(0.55), fontSize: 14),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader(ColorScheme cs, AppUser? user) {
    return Column(
      children: [
        // Awatar
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.indigo.shade100,
            shape: BoxShape.circle,
          ),
          child: user?.photoUrl != null
              ? ClipOval(
                  child: Image.network(user!.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _initialsWidget(user.initials, cs)))
              : _initialsWidget(user?.initials ?? '?', cs),
        ),
        const SizedBox(height: 12),
        Text(
          user?.name ?? '',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          user?.email ?? '',
          style: TextStyle(
              fontSize: 13, color: cs.onSurface.withOpacity(0.55)),
        ),
        const SizedBox(height: 24),
        Text(
          'Odblokuj aplikację',
          style: TextStyle(
              fontSize: 15,
              color: cs.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _initialsWidget(String initials, ColorScheme cs) {
    return Center(
      child: Text(
        initials,
        style: TextStyle(
            color: Colors.indigo.shade700,
            fontSize: 26,
            fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ── PIN dots indicator ────────────────────────────────────────────────────────

class _PinDots extends StatelessWidget {
  final int filled;
  final int total;

  const _PinDots({required this.filled, required this.total});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final isFilled = i < filled;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: isFilled ? 16 : 14,
          height: isFilled ? 16 : 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? Colors.indigo : Colors.transparent,
            border: isFilled
                ? null
                : Border.all(
                    color: cs.onSurface.withOpacity(0.4), width: 2),
          ),
        );
      }),
    );
  }
}

// ── PIN numpad ────────────────────────────────────────────────────────────────

class _PinPad extends StatelessWidget {
  final void Function(String)? onDigit;
  final VoidCallback? onBackspace;
  final VoidCallback? onBiometric;

  const _PinPad({this.onDigit, this.onBackspace, this.onBiometric});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 56),
      child: Column(
        children: [
          ...rows.map((row) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: row
                    .map((d) => _DigitButton(
                          label: d,
                          onTap: onDigit != null ? () => onDigit!(d) : null,
                          cs: cs,
                        ))
                    .toList(),
              )),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Biometria lub placeholder
              if (onBiometric != null)
                _IconButton(
                    icon: Icons.fingerprint, onTap: onBiometric, cs: cs)
              else
                const SizedBox(width: 72, height: 72),
              _DigitButton(
                  label: '0',
                  onTap: onDigit != null ? () => onDigit!('0') : null,
                  cs: cs),
              _IconButton(
                  icon: Icons.backspace_outlined,
                  onTap: onBackspace,
                  cs: cs),
            ],
          ),
        ],
      ),
    );
  }
}

class _DigitButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final ColorScheme cs;

  const _DigitButton(
      {required this.label, required this.onTap, required this.cs});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(36),
          onTap: onTap,
          child: Center(
            child: Text(label,
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w400,
                    color: cs.onSurface)),
          ),
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final ColorScheme cs;

  const _IconButton(
      {required this.icon, required this.onTap, required this.cs});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(36),
          onTap: onTap,
          child: Center(
            child: Icon(icon,
                size: 28, color: cs.onSurface.withOpacity(onTap != null ? 0.8 : 0.3)),
          ),
        ),
      ),
    );
  }
}
