import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../main.dart' show authStateNotifier, AuthState, useMockNotifier;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtr = TextEditingController();
  final _emailCtr = TextEditingController();
  final _passCtr = TextEditingController();
  final _confirmCtr = TextEditingController();

  bool _loading = false;
  bool _showPass = false;
  bool _showConfirm = false;
  String? _error;

  @override
  void dispose() {
    _nameCtr.dispose();
    _emailCtr.dispose();
    _passCtr.dispose();
    _confirmCtr.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await AuthService.instance.register(
      _nameCtr.text.trim(),
      _emailCtr.text.trim(),
      _passCtr.text,
      useMock: useMockNotifier.value,
    );

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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Utwórz konto',
            style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Imię ────────────────────────────────────────
                _Field(
                  controller: _nameCtr,
                  label: 'Imię i nazwisko',
                  icon: Icons.person_outline,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Podaj imię' : null,
                ),
                const SizedBox(height: 14),

                // ── Email ───────────────────────────────────────
                _Field(
                  controller: _emailCtr,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Podaj email';
                    if (!v.contains('@')) return 'Nieprawidłowy email';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // ── Hasło ───────────────────────────────────────
                _Field(
                  controller: _passCtr,
                  label: 'Hasło',
                  icon: Icons.lock_outline,
                  obscure: !_showPass,
                  suffix: IconButton(
                    icon: Icon(
                        _showPass ? Icons.visibility_off : Icons.visibility,
                        size: 20),
                    onPressed: () => setState(() => _showPass = !_showPass),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Podaj hasło';
                    if (v.length < 8) return 'Minimum 8 znaków';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // ── Potwierdź hasło ─────────────────────────────
                _Field(
                  controller: _confirmCtr,
                  label: 'Potwierdź hasło',
                  icon: Icons.lock_outline,
                  obscure: !_showConfirm,
                  suffix: IconButton(
                    icon: Icon(
                        _showConfirm ? Icons.visibility_off : Icons.visibility,
                        size: 20),
                    onPressed: () =>
                        setState(() => _showConfirm = !_showConfirm),
                  ),
                  validator: (v) => v != _passCtr.text
                      ? 'Hasła nie są identyczne'
                      : null,
                ),

                const SizedBox(height: 28),

                // ── Przycisk ────────────────────────────────────
                FilledButton(
                  onPressed: _loading ? null : _submit,
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
                      : const Text('Utwórz konto',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                ),

                // ── Błąd ────────────────────────────────────────
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: cs.errorContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(_error!,
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(color: cs.onErrorContainer, fontSize: 13)),
                  ),
                ],

                const SizedBox(height: 28),

                // ── Link do logowania ───────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Masz już konto? ',
                        style: TextStyle(
                            color: cs.onSurface.withOpacity(0.6),
                            fontSize: 14)),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        'Zaloguj się',
                        style: TextStyle(
                          color: Colors.indigo,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Pomocniczy widget pola formularza ────────────────────────────────────────

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffix;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
    this.validator,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
