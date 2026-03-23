import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../../core/storage/hive_service.dart';

class AuthService {
  final HiveService _hiveService;
  final LocalAuthentication _localAuth;

  AuthService(this._hiveService, this._localAuth);

  // Use the authBox for quick PIN lookup
  // In a real app, this could also sync with a backend later
  Future<bool> registerPin(String pin) async {
    final bytes = utf8.encode(pin);
    final hashedPin = sha256.convert(bytes).toString();
    await _hiveService.authBox.put('user_pin', hashedPin);
    return true;
  }

  Future<bool> verifyPin(String pin) async {
    final storedHash = _hiveService.authBox.get('user_pin');
    if (storedHash == null) return false;
    final bytes = utf8.encode(pin);
    final hashedPin = sha256.convert(bytes).toString();
    return hashedPin == storedHash;
  }

  Future<bool> hasRegisteredPin() async {
    return _hiveService.authBox.containsKey('user_pin');
  }

  Future<bool> authenticateWithBiometrics() async {
    final isAvailable = await _localAuth.canCheckBiometrics;
    final isDeviceSupported = await _localAuth.isDeviceSupported();

    if (!isAvailable || !isDeviceSupported) {
      return false; // Fallback to PIN
    }

    try {
      return await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access patient records',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }
}

final localAuthProvider = Provider((ref) => LocalAuthentication());

final authServiceProvider = Provider<AuthService>((ref) {
  final hiveService = ref.watch(hiveServiceProvider);
  final localAuth = ref.watch(localAuthProvider);
  return AuthService(hiveService, localAuth);
});
