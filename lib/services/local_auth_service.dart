// ─────────────────────────────────────────────────────────────────────────────
// LocalAuthService — odcisk palca (biometric) + PIN
//
// PIN jest hashowany SHA-256 z solą przed zapisem.
// Ustawienia (czy biometria / PIN są włączone) również w secure storage.
// Limit nieudanych prób PIN: 5 — po przekroczeniu wymagane pełne logowanie.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:flutter/services.dart';

class LocalAuthService {
  static final LocalAuthService instance = LocalAuthService._();
  LocalAuthService._();

  final _localAuth = LocalAuthentication();
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _keyBiometricEnabled = 'la_biometric_enabled';
  static const _keyPinEnabled = 'la_pin_enabled';
  static const _keyPinHash = 'la_pin_hash';
  static const _keyPinAttempts = 'la_pin_attempts';
  static const _pinSalt = 'tugio_pin_v1';
  static const maxPinAttempts = 5;

  // ── Dostępność sprzętowa ───────────────────────────────────────────────────

  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// True jeśli na urządzeniu są ZAREJESTROWANE biometrie (nie tylko sprzęt).
  /// canCheckBiometrics = obecność sprzętu, getAvailableBiometrics = rejestracja.
  /// Oba warunki muszą być spełnione.
  Future<bool> canUseBiometrics() async {
    try {
      final supported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      final enrolled = await _localAuth.getAvailableBiometrics();
      debugPrint('[LocalAuth] isDeviceSupported=$supported '
          'canCheckBiometrics=$canCheck '
          'getAvailableBiometrics=$enrolled');
      if (!supported) return false;
      if (!canCheck) return false;
      return enrolled.isNotEmpty;
    } catch (e) {
      debugPrint('[LocalAuth] canUseBiometrics ERROR: $e');
      return false;
    }
  }

  /// True TYLKO gdy biometria jest:
  ///  1. włączona przez użytkownika w ustawieniach Tugio, ORAZ
  ///  2. faktycznie zarejestrowana na urządzeniu w tej chwili.
  Future<bool> canAndShouldUseBiometric() async {
    try {
      if (!await isBiometricEnabled()) return false;
      return await canUseBiometrics(); // już sprawdza enrollment
    } catch (_) {
      return false;
    }
  }

  // ── Odczyt ustawień ────────────────────────────────────────────────────────

  Future<bool> isBiometricEnabled() async {
    final v = await _storage.read(key: _keyBiometricEnabled);
    return v == 'true';
  }

  Future<bool> isPinEnabled() async {
    final v = await _storage.read(key: _keyPinEnabled);
    return v == 'true';
  }

  Future<bool> get needsLocalAuth async {
    return await isBiometricEnabled() || await isPinEnabled();
  }

  // ── Biometria ─────────────────────────────────────────────────────────────

  Future<BiometricResult> authenticateBiometric(
      {String reason = 'Odblokuj aplikację Tugio'}) async {
    try {
      // Weryfikacja sprzętowa przed wywołaniem promptu systemowego.
      if (!await canUseBiometrics()) return BiometricResult.notAvailable;

      debugPrint('[LocalAuth] authenticateBiometric: wywołuję authenticate()');
      final ok = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,   // NIE zezwalaj na fallback do PIN systemu
          stickyAuth: true,
        ),
      );
      debugPrint('[LocalAuth] authenticate() zwrócił: $ok');
      return ok ? BiometricResult.success : BiometricResult.failed;
    } on PlatformException catch (e) {
      if (e.code == auth_error.notAvailable ||
          e.code == auth_error.notEnrolled) {
        return BiometricResult.notAvailable;
      }
      if (e.code == auth_error.lockedOut ||
          e.code == auth_error.permanentlyLockedOut) {
        return BiometricResult.lockedOut;
      }
      return BiometricResult.failed;
    }
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(
        key: _keyBiometricEnabled, value: enabled.toString());
  }

  // ── PIN ────────────────────────────────────────────────────────────────────

  Future<void> setupPin(String pin) async {
    await _storage.write(key: _keyPinHash, value: _hash(pin));
    await _storage.write(key: _keyPinEnabled, value: 'true');
    await _storage.write(key: _keyPinAttempts, value: '0');
  }

  Future<PinResult> verifyPin(String pin) async {
    final stored = await _storage.read(key: _keyPinHash);
    if (stored == null) return PinResult.notSet;

    final attemptsStr = await _storage.read(key: _keyPinAttempts) ?? '0';
    int attempts = int.tryParse(attemptsStr) ?? 0;

    if (attempts >= maxPinAttempts) return PinResult.tooManyAttempts;

    if (_hash(pin) == stored) {
      await _storage.write(key: _keyPinAttempts, value: '0');
      return PinResult.success;
    }

    attempts++;
    await _storage.write(key: _keyPinAttempts, value: '$attempts');
    final remaining = maxPinAttempts - attempts;
    if (remaining <= 0) return PinResult.tooManyAttempts;
    return PinResult.wrong(remaining);
  }

  Future<int> remainingPinAttempts() async {
    final v = await _storage.read(key: _keyPinAttempts) ?? '0';
    return maxPinAttempts - (int.tryParse(v) ?? 0);
  }

  Future<void> removePin() async {
    await _storage.delete(key: _keyPinHash);
    await _storage.write(key: _keyPinEnabled, value: 'false');
    await _storage.write(key: _keyPinAttempts, value: '0');
  }

  // ── Czyszczenie (przy wylogowaniu) ─────────────────────────────────────────

  Future<void> clearAll() async {
    await _storage.delete(key: _keyBiometricEnabled);
    await _storage.delete(key: _keyPinEnabled);
    await _storage.delete(key: _keyPinHash);
    await _storage.delete(key: _keyPinAttempts);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _hash(String pin) {
    final bytes = utf8.encode('$_pinSalt:$pin');
    return sha256.convert(bytes).toString();
  }
}

// ── Result types ─────────────────────────────────────────────────────────────

enum BiometricResult { success, failed, notAvailable, lockedOut }

class PinResult {
  final bool isSuccess;
  final bool isNotSet;
  final bool isTooManyAttempts;
  final int remainingAttempts;

  const PinResult._({
    required this.isSuccess,
    this.isNotSet = false,
    this.isTooManyAttempts = false,
    this.remainingAttempts = 0,
  });

  static const success = PinResult._(isSuccess: true, remainingAttempts: 5);
  static const notSet = PinResult._(isSuccess: false, isNotSet: true);
  static const tooManyAttempts =
      PinResult._(isSuccess: false, isTooManyAttempts: true);

  factory PinResult.wrong(int remaining) =>
      PinResult._(isSuccess: false, remainingAttempts: remaining);
}
