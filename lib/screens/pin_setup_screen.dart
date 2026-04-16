// ─────────────────────────────────────────────────────────────────────────────
// PinSetupScreen — ustawianie / zmiana / usuwanie 4-cyfrowego PIN
//
// Tryby: setup (nowy PIN), change (zmiana → najpierw stary PIN), remove (usuń)
// Używany z Navigator.push, zwraca true po sukcesie.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../services/local_auth_service.dart';

enum PinSetupMode { setup, change, remove }

class PinSetupScreen extends StatefulWidget {
  final PinSetupMode mode;

  const PinSetupScreen({super.key, this.mode = PinSetupMode.setup});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  // Kroki:
  //  'verify'  — weryfikacja starego PIN (tylko tryb change/remove)
  //  'enter'   — wprowadź nowy PIN
  //  'confirm' — potwierdź nowy PIN
  AppStrings get s => AppStrings.of(context);

  late String _step;
  String _pin = '';
  String _firstPin = '';
  String? _error;

  static const _pinLength = 4;

  @override
  void initState() {
    super.initState();
    _step = (widget.mode == PinSetupMode.setup) ? 'enter' : 'verify';
  }

  String get _title {
    if (widget.mode == PinSetupMode.remove) return s.pinRemoveTitle;
    if (widget.mode == PinSetupMode.change) return s.pinChangeTitle;
    return s.pinSetupTitle;
  }

  String get _instruction {
    switch (_step) {
      case 'verify':
        return widget.mode == PinSetupMode.remove
            ? s.pinVerifyRemoveInstruction
            : s.pinVerifyInstruction;
      case 'enter':
        return s.pinEnterInstruction;
      case 'confirm':
        return s.pinConfirmInstruction;
      default:
        return '';
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
      await _handlePinComplete(newPin);
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _handlePinComplete(String pin) async {
    switch (_step) {
      case 'verify':
        final result = await LocalAuthService.instance.verifyPin(pin);
        if (result.isSuccess) {
          setState(() {
            _pin = '';
            _error = null;
            _step =
                widget.mode == PinSetupMode.remove ? 'done_remove' : 'enter';
          });
          if (widget.mode == PinSetupMode.remove) {
            await _doRemove();
          }
        } else if (result.isTooManyAttempts) {
          _showError(s.pinTooManyAttempts);
        } else {
          _showError(s.pinIncorrectAttempts(result.remainingAttempts));
        }
        break;

      case 'enter':
        setState(() {
          _firstPin = pin;
          _pin = '';
          _step = 'confirm';
        });
        break;

      case 'confirm':
        if (pin == _firstPin) {
          await LocalAuthService.instance.setupPin(pin);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(s.pinSetSuccess),
                  backgroundColor: Colors.green),
            );
            Navigator.pop(context, true);
          }
        } else {
          setState(() {
            _pin = '';
            _firstPin = '';
            _step = 'enter';
          });
          _showError(s.pinMismatch);
        }
        break;
    }
  }

  Future<void> _doRemove() async {
    await LocalAuthService.instance.removePin();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(s.pinRemovedSuccess),
            backgroundColor: Colors.orange),
      );
      Navigator.pop(context, true);
    }
  }

  void _showError(String msg) {
    setState(() {
      _pin = '';
      _error = msg;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(_title,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 48),

            // ── Instrukcja ───────────────────────────────────────
            Text(
              _instruction,
              style: TextStyle(
                  fontSize: 16,
                  color: cs.onSurface.withOpacity(0.75),
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 36),

            // ── Wskaźnik cyfr ────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pinLength, (i) {
                final isFilled = i < _pin.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: isFilled ? 18 : 16,
                  height: isFilled ? 18 : 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled ? Colors.indigo : Colors.transparent,
                    border: isFilled
                        ? null
                        : Border.all(
                            color: cs.onSurface.withOpacity(0.35), width: 2),
                  ),
                );
              }),
            ),

            // ── Błąd ─────────────────────────────────────────────
            if (_error != null) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(_error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: cs.error, fontSize: 13)),
              ),
            ],

            const Spacer(),

            // ── Klawiatura numeryczna ────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 56),
              child: Column(
                children: [
                  ...['123', '456', '789'].map((row) => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: row.split('').map((d) {
                          return _Btn(
                              label: d,
                              onTap: () => _onDigit(d),
                              cs: cs);
                        }).toList(),
                      )),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const SizedBox(width: 72, height: 72),
                      _Btn(label: '0', onTap: () => _onDigit('0'), cs: cs),
                      _Btn(
                        label: '⌫',
                        onTap: _onBackspace,
                        cs: cs,
                        isIcon: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final ColorScheme cs;
  final bool isIcon;

  const _Btn(
      {required this.label,
      required this.onTap,
      required this.cs,
      this.isIcon = false});

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
            child: isIcon
                ? Icon(Icons.backspace_outlined,
                    size: 26, color: cs.onSurface.withOpacity(0.8))
                : Text(label,
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
