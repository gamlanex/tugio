import 'package:flutter/material.dart';
import '../../../services/local_auth_service.dart';
import '../../../l10n/app_strings.dart';
import '../../../main.dart' show languageNotifier, setAppLanguage;
import '../../pin_setup_screen.dart';

class SecuritySettingsSheet extends StatefulWidget {
  const SecuritySettingsSheet({super.key});

  @override
  State<SecuritySettingsSheet> createState() => _SecuritySettingsSheetState();
}

class _SecuritySettingsSheetState extends State<SecuritySettingsSheet> {
  AppStrings get s => AppStrings.of(context);

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
        reason: s.biometricConfirmationPrompt,
      );
      if (!mounted) return;
      if (result != BiometricResult.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result == BiometricResult.notAvailable
                ? s.biometricUnavailable
                : s.biometricVerificationFailed),
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
            Text(s.securityTitle,
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
                  title: s.biometricLabel,
                  subtitle: _biometricEnabled ? s.biometricEnabled : s.biometricDisabled,
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
                title: s.pinLabel,
                subtitle: _pinEnabled ? s.pinSet : s.pinNotSet,
                trailing: TextButton(
                  onPressed: _setupOrChangePin,
                  child: Text(_pinEnabled ? s.pinChangeButton : s.pinSetupButton,
                      style: const TextStyle(color: Colors.indigo)),
                ),
              ),
              if (_pinEnabled) ...[
                const Divider(height: 1),
                SettingsRow(
                  icon: Icons.remove_circle_outline,
                  title: s.removePinLabel,
                  subtitle: s.removePinSubtitle,
                  trailing: TextButton(
                    onPressed: _removePin,
                    child: Text(s.removePinButton,
                        style: const TextStyle(color: Colors.red)),
                  ),
                ),
              ],

              const Divider(height: 1),

              // ── Język ─────────────────────────────────────────
              ValueListenableBuilder<String>(
                valueListenable: languageNotifier,
                builder: (_, lang, __) => SettingsRow(
                  icon: Icons.language_rounded,
                  title: s.languageLabel,
                  subtitle: lang == 'en' ? s.languageEnglish : s.languagePolish,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _LangChip(
                        label: 'PL',
                        selected: lang == 'pl',
                        onTap: () { setAppLanguage('pl'); },
                      ),
                      const SizedBox(width: 6),
                      _LangChip(
                        label: 'EN',
                        selected: lang == 'en',
                        onTap: () { setAppLanguage('en'); },
                      ),
                    ],
                  ),
                ),
              ),

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
                        s.securityInfo,
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

// ── Language chip (PL / EN) ───────────────────────────────────────────────────
class _LangChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LangChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? Colors.indigo
              : Colors.indigo.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? Colors.indigo : Colors.indigo.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : Colors.indigo.shade600,
          ),
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
