import 'package:flutter/material.dart';
import '../../../services/local_auth_service.dart';
import '../../pin_setup_screen.dart';

class SecuritySettingsSheet extends StatefulWidget {
  const SecuritySettingsSheet({super.key});

  @override
  State<SecuritySettingsSheet> createState() => _SecuritySettingsSheetState();
}

class _SecuritySettingsSheetState extends State<SecuritySettingsSheet> {
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool _pinEnabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final canBio = await LocalAuthService.instance.canUseBiometrics();
    final bioOn = await LocalAuthService.instance.canAndShouldUseBiometric();
    final pinOn = await LocalAuthService.instance.isPinEnabled();

    if (!canBio && await LocalAuthService.instance.isBiometricEnabled()) {
      await LocalAuthService.instance.setBiometricEnabled(false);
    }

    if (!mounted) return;
    setState(() {
      _biometricAvailable = canBio;
      _biometricEnabled = bioOn;
      _pinEnabled = pinOn;
      _loading = false;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      final result = await LocalAuthService.instance.authenticateBiometric(
        reason: 'Potwierdź tożsamość aby włączyć odblokowanie biometryczne',
      );
      if (!mounted) return;
      if (result != BiometricResult.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result == BiometricResult.notAvailable
                ? 'Biometria niedostępna lub niezarejestrowana w systemie'
                : 'Weryfikacja nieudana — biometria nie została włączona'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }
    await LocalAuthService.instance.setBiometricEnabled(value);
    if (mounted) setState(() => _biometricEnabled = value);
  }

  Future<void> _setupOrChangePin() async {
    final mode = _pinEnabled ? PinSetupMode.change : PinSetupMode.setup;
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PinSetupScreen(mode: mode)),
    );
    if (ok == true && mounted) {
      setState(() => _pinEnabled = true);
    }
  }

  Future<void> _removePin() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => const PinSetupScreen(mode: PinSetupMode.remove)),
    );
    if (ok == true && mounted) {
      setState(() => _pinEnabled = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Zabezpieczenia',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface)),
            const SizedBox(height: 20),

            if (_loading)
              const Center(child: CircularProgressIndicator())
            else ...[
              if (_biometricAvailable) ...[
                SettingsRow(
                  icon: Icons.fingerprint,
                  title: 'Odcisk palca',
                  subtitle: _biometricEnabled ? 'Włączony' : 'Wyłączony',
                  trailing: Switch(
                    value: _biometricEnabled,
                    onChanged: _toggleBiometric,
                    activeColor: Colors.indigo,
                  ),
                ),
                const Divider(height: 1),
              ],

              SettingsRow(
                icon: Icons.pin_outlined,
                title: 'Kod PIN',
                subtitle: _pinEnabled ? 'Ustawiony' : 'Nie ustawiony',
                trailing: TextButton(
                  onPressed: _setupOrChangePin,
                  child: Text(_pinEnabled ? 'Zmień' : 'Ustaw',
                      style: const TextStyle(color: Colors.indigo)),
                ),
              ),
              if (_pinEnabled) ...[
                const Divider(height: 1),
                SettingsRow(
                  icon: Icons.remove_circle_outline,
                  title: 'Usuń PIN',
                  subtitle: 'Wyłącz logowanie kodem',
                  trailing: TextButton(
                    onPressed: _removePin,
                    child: const Text('Usuń',
                        style: TextStyle(color: Colors.red)),
                  ),
                ),
              ],

              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: cs.onSurface.withOpacity(0.5)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'PIN i biometria blokują aplikację po ${5} minutach w tle. '
                        'Sesja wygasa po 30 dniach — wówczas wymagane pełne logowanie.',
                        style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withOpacity(0.55),
                            height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 22, color: Colors.indigo.shade400),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withOpacity(0.55))),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
